;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Routines for the SHOW function, which shows all 14 digits of a TI-OS floating
; point number. If the number is an integer, it is shown as a 14-digit integer.
; If the number is floating point, then it is shown in scientific notation with
; 14 significant digits.
;
; This is placed in Flash Page 0. I had hoped that it could be placed in Flash
; Page 1, but it needs too many routines from base.asm.
;------------------------------------------------------------------------------

; Function: Convert the number in OP1 with all available digits, suitable for a
; SHOW function.
; Input: OP1: floating point number
; Output: OP3: string rendering of OP1 as a C-string
; Destroys: all, OP1-OP6
formShowable:
    bcall(_CkOp1FP0)
    jr nz, convertOP1ToShowStringNonZero
    ld de, OP3
    ld a, '0'
    ld (de), a
    inc de
    xor a
    ld (de), a
    ret
convertOP1ToShowStringNonZero:
    bcall(_PushRealO1) ; FPS=[OP1]
    bcall(_ClrOP1S) ; clear sign bit of OP1
    ld hl, const1E14
    ld de, OP2
    ld bc, 9
    ldir ; OP2=1e14
    bcall(_CpOP1OP2) ; if OP1 >= OP2: CF=0
    jr nc, convertOP1ToShowStringFloat
    ; Check for integer
    bcall(_CkPosInt) ; if OP1 int >= 0: ZF=1
    jr z, convertOP1ToShowStringInt
convertOP1ToShowStringFloat:
    bcall(_PopRealO1) ; FPS=[]
    jp convertOP1ToSciString
convertOP1ToShowStringInt:
    bcall(_PopRealO1) ; FPS=[]
    jp convertOP1ToIntString

const1E14: ; 10^14, EXP=$80+14=$8E
    .db $00, $8E, $10, $00, $00, $00, $00, $00, $00

; Description: Convert the floating point number in OP1 to a string using
; scientific notation. Prints all 14-digits in the mantissa.
; Input: OP1: floating point number
; Output: OP3: string of floating point rendered in scientific notation
; Destroys: A, B, C, DE, HL
convertOP1ToSciString:
    ld de, OP3
    ld hl, OP1
    ld b, 14 ; 14 digit mantissa in BCD format
    ld a, (hl)
    inc hl
    rla ; CF=bit7 of floating point object type T
    jr nc, convertOP1ToSciStringDigits
    ld a, '-'
    ld (de), a
    inc de
convertOP1ToSciStringDigits:
    ; Save the exponent
    ld a, (hl)
    inc hl
    push af ; stack=[EXP]
    ; Always print the very first digit of mantissa.
    ld a, (hl)
    inc hl
    ld c, a ; C=BCD digit saved
    ; Extract first digit and print
    srl a
    srl a
    srl a
    srl a
    call convertAToChar
    ; Push the position of the last non-zero trailing digit in the mantissa.
    ; I need an extra copy of DE, but I'm out of registers, so use the stack.
    ; If I try to use IX, transferring from DE to IX requires the stack anyway,
    ; so might as well just use the stack.
    push de ; stack=[EXP, lastNonZeroDE]
    ld (de), a
    inc de
    ld a, '.'
    ; Continue with the second digits and onwards
    jr convertOP1ToSciStringLoopAltEntry
convertOP1ToSciStringLoop:
    ld a, (hl)
    inc hl
    ld c, a ; C=BCD digit saved
    ; print the first digit
    srl a
    srl a
    srl a
    srl a
    jr z, convertOP1ToSciStringMaintainLastDE1
    ; non-zero digit, so increment the last known non-zero DE
    ex (sp), hl
    ld h, d
    ld l, e
    ex (sp), hl ; stack=[EXP, lastNonZeroDE]
convertOP1ToSciStringMaintainLastDE1:
    call convertAToChar
convertOP1ToSciStringLoopAltEntry:
    ld (de), a
    inc de
    dec b
    jr z, convertOP1ToSciStringExp
    ; print the second digit
    ld a, c ; A=BCD digit
    and $0F
    jr z, convertOP1ToSciStringMaintainLastDE2
    ; non-zero digit, so increment the last known non-zero DE
    ex (sp), hl
    ld h, d
    ld l, e
    ex (sp), hl ; stack=[EXP, lastNonZeroDE]
convertOP1ToSciStringMaintainLastDE2:
    call convertAToChar
    ld (de), a
    inc de
    djnz convertOP1ToSciStringLoop
convertOP1ToSciStringExp:
    pop de ; stack=[EXP]; DE=lastNonZeroDE
    inc de ; move past the last non-zero trailing digit
    ; print the Exponent in scientific notation
    ld a, Lexponent
    ld (de), a
    inc de
    pop af ; stack=[]; A=EXP
    sub 128
    jr nc, convertOP1ToSciStringPosExp
    ld c, a
    ld a, '-'
    ld (de), a
    inc de
    ld a, c
    neg
convertOP1ToSciStringPosExp:
    call convertAToDecDE
    ; Terminate C-string with NUL
    xor a
    ld (de), a
    ret

; Description: Convert A to 1 to 3 digits at the buffer pointed by DE.
; This is a copy of convertAToDec() function for Flash Page 1.
; TODO: This can probably be written to be faster and smaller.
; Input:
;   - A: u8 integer
;   - DE: pointer to string buffer
; Output: DE incremented to the char after the digits
; Destroys: A, B, C, DE
convertAToDecDE:
convertAToDecDE100:
    ld b, 100
    call divideAByB
    or a
    jr z, convertAToDecDE10
    call convertAToChar
    ld (de), a
    inc de
convertAToDecDE10:
    ld a, b
    ld b, 10
    call divideAByB
    or a
    jr z, convertAToDecDE1
    call convertAToChar
    ld (de), a
    inc de
convertAToDecDE1:
    ld a, b
    call convertAToChar
    ld (de), a
    inc de
    ret

; Description: Convert the integer in OP1 to an integer string.
; This routine assumes that:
; - OP1 is not zero (but can be negative)
; - abs(OP1) is an integer < 10^14 (i.e. 14 digits or less)
; No validation of the EXP parameter is performed.
; Input: OP1: an integer represented as a floating point number
; Output: OP3: integer string
; Destroys: A, B, C, DE, HL
convertOP1ToIntString:
    ld de, OP3
    ld hl, OP1
    ld a, (hl)
    inc hl
    rla ; CF=bit7 of floating point object type T
    jr nc, convertOP1ToIntStringDigits
    ld a, '-'
    ld (de), a
    inc de
convertOP1ToIntStringDigits:
    ld a, (hl) ; A=EXP
    inc hl
    sub a, 127
    ld b, a ; B=EXP-127=number of integer digits to print
convertOP1ToIntStringLoop:
    ld a, (hl)
    inc hl
    ld c, a ; C=BCD digit saved
    ; print the first digit
    srl a
    srl a
    srl a
    srl a
    call convertAToChar
    ld (de), a
    inc de
    dec b
    jr z, convertOP1ToIntStringEnd
    ; print the second digit
    ld a, c ; A=BCD digit
    and $0F
    call convertAToChar
    ld (de), a
    inc de
    djnz convertOP1ToIntStringLoop
convertOP1ToIntStringEnd:
    ; Terminate C-string with NUL
    xor a
    ld (de), a
    ret
