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

; Description: Format the number in OP1 to a NUL terminated string that shows
; all significant digits, suitable for a SHOW function.
; Input:
;   - OP1/OP2: real, complex, or integer number
;   - DE: pointer to output string buffer
; Output:
;   - (DE): string buffer updated and NUL terminated
;   - DE: points to the character after the NUL
; Destroys: all, OP1-OP6
formShowable:
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    jr nz, formShowableBase
    call checkOp1Complex ; if complex: ZF=1
    jr z, formShowableComplex
formShowableReal:
    call formRealString
    jr formShowableEnd
formShowableBase:
    call formBaseString
    jr formShowableEnd
formShowableComplex:
    call formComplexString
formShowableEnd:
    xor a
    ld (de), a ; terminate with NUL
    inc de
    ret

;------------------------------------------------------------------------------

; Description: Format the number in OP1 in BASE mode. Currently, only BIN mode
; has special formatting. The others (DEC, HEX, OCT) format the integer as a
; decimal integer, which is consistent with the HP-42S. The longest string
; produced by this routine is 32 characters when the BASE mode is BIN and WSIZ
; is 32.
;
; Input:
;   - OP1: an integer represented as a floating point number
;   - DE: bufPointer
; Output:
;   - (DE): contains the integer rendered as an integer string
;   - DE: updated
; Destroys: A, B, C, DE, HL, OP2-OP6
formBaseString:
    ; Check for complex number, and use Complex formatting.
    call checkOp1Complex
    jr z, formComplexString
    ; Check for negative number, and use Real formatting.
    push de
    bcall(_CkOP1Pos) ; if OP1>=0: ZF=1
    pop de
    jp nz, formRealString
    ; Check for DEC, HEX, OCT and use Real formatting.
    ld a, (baseNumber)
    cp 10
    jp z, formRealString
    cp 16
    jp z, formRealString
    cp 8
    jp z, formRealString
    ; [[fallthrough]]

formBinString:
    push de ; stack=[bufPointer]
    ; Check if OP1 fits in the current baseWordSize.
    ld hl, OP3
    call convertOP1ToU32StatusCode ; HL=OP3=u32(OP1); C=u32StatusCode
    call checkU32FitsWsize ; C=u32StatusCode
    ; Check for too big.
    bit u32StatusCodeTooBig, c
    pop de ; stack=[]; DE=bufPointer
    jp nz, formRealString
    ; Check for negative. This shouldn't happen because it should have been
    ; caught earlier, so I guess this is just defensive programming against
    ; future refatoring.
    bit u32StatusCodeNegative, c
    jp nz, formRealString
    ; We are here if OP1 is a positive integer < 2^WSIZ.
    push de ; stack=[bufPointer]
    ; Move u32(OP3) to OP1, to free up OP3.
    call move9ToOp1
    ; Convert to a 32-digit binary string at OP4.
    ld hl, OP1
    ld de, OP4
    call convertU32ToBinString ; DE points to a 32-character string + NUL.
    ; Find the beginning of the binary string, depending on baseWordSize.
    ld a, 32
    ld hl, baseWordSize
    sub (hl)
    ld e, a
    ld d, 0 ; DE=32-baseWordSize
    ld hl, OP4
    add hl, de ; HL=pointer to beginning of binary string
    pop de ; stack=[]; DE=bufPointer
    jp reformatBaseTwoString

;------------------------------------------------------------------------------

; Format the complex number in OP1/OP2 into the string buffer pointed by DE.
; Input:
;   - OP1/OP2=Z, complex number
;   - DE: pointer to output string buffer
; Output:
;   - (DE): string buffer updated and NUL terminated
;   - DE: points to the next character
; Destroys: all, OP1-OP6
formComplexString:
    ; Determine the complex display mode.
    ld a, (complexMode)
    cp a, complexModeRect
    jr z, formComplexRectString
    cp a, complexModeRad
    jr z, formComplexRadString
    cp a, complexModeDeg
    jr z, formComplexDegString
    ; [[falltrhough]]

; Description: Format the complex number in rectangular form.
; Input: DE: stringPointer
; Output: DE: updated
formComplexRectString:
    call splitCp1ToOp1Op2 ; OP1=Re(Z); OP2=Im(Z)
    ; Format real part
    push de
    bcall(_PushRealO2) ; FPS=[Im(Z)]
    pop de
    call formRealString ; DE updated
    ; Add " i "
    ld hl, msgShowComplexRectSpacer
    bcall(_StrCopy)
    ; Format imaginary part
    push de
    bcall(_PopRealO1) ; FPS=[]; OP1=Im(Z)
    pop de
    jr formRealString

msgShowComplexRectSpacer:
    .db " ", LImagI, " ", 0

; Description: Format the complex number in polar radian form.
; Input: DE: stringPointer
; Output: DE: updated
formComplexRadString:
    push de
    call complexRToPRad ; OP1=r; OP2=theta(rad)
    pop de
    ; [[fallthrough]]

; Output: DE: updated
formComplexPolarCommon:
    jr nc, formComplexRadStringOk
    ld hl, msgPrintComplexError ; "<overflow>"
    bcall(_StrCopy)
    ret
formComplexRadStringOk:
    ; Format the magnitude
    push de
    bcall(_PushRealO2) ; FPS=[theta]
    pop de
    call formRealString
    ; Add angle symbol
    ld hl, msgShowComplexPolarSpacer
    bcall(_StrCopy)
    ; Format angle
    push de
    bcall(_PopRealO1) ; FPS=[]; OP1=theta
    pop de
    jr formRealString

; Description: Format the complex number in polar degree form.
formComplexDegString:
    push de
    call complexRToPDeg ; OP1=r; OP2=theta(rad)
    pop de
    call formComplexPolarCommon
    ld a, Ldegree
    ld (de), a
    inc de
    ; add NUL terminator
    xor a
    ld (de), a
    inc de
    ret

msgShowComplexPolarSpacer:
    .db " ", Langle, " ", 0

;------------------------------------------------------------------------------

; Format the real floating value in OP1 into the string buffer pointed by DE.
; The string is *not* terminated with NUL, allowing additional characters to be
; rendered into the buffer. Calls various helper routines:
;   - formFloatString()
;   - formIntString()
; Input:
;   - OP1: floating point number
;   - DE: pointer to output string buffer
; Output:
;   - DE: string buffer updated, points to the next character
; Destroys: OP1, OP2
formRealString:
    push de
    bcall(_CkOp1FP0) ; if OP1==0: ZF=1
    pop de
    jr nz, formRealStringNonZero
    ; Generate just a "0" if zero.
    ld a, '0'
    ld (de), a
    inc de
    ret
formRealStringNonZero:
    push de ; stack=[bufPointer]
    bcall(_PushRealO1) ; FPS=[OP1]
    bcall(_ClrOP1S) ; clear sign bit of OP1
    call op2Set1E14 ; OP2=1E14
    bcall(_CpOP1OP2) ; if OP1 >= OP2: CF=0
    jr nc, formRealStringFloat
    ; Check for integer
    bcall(_CkPosInt) ; if OP1 int >= 0: ZF=1
    jr z, formRealStringInt
formRealStringFloat:
    bcall(_PopRealO1) ; FPS=[]
    pop de ; stack=[]; DE=bufPointer
    jr formSciString
formRealStringInt:
    bcall(_PopRealO1) ; FPS=[]
    pop de ; stack=[]; DE=bufPointer
    jr formIntString

;------------------------------------------------------------------------------

; Description: Format the floating point number in OP1 to a string using
; scientific notation. Prints all 14 digits in the mantissa, excluding trailing
; zeros which are not relevant. The longest string produced by this routine is:
; 14 significant digits, decimal point, mantissa minus sign, 'E', exponent
; minus sign, 2 exponent digits = 20 characters. (I am not actually sure what
; this routine produces if OP1==0.0).
;
; Input:
;   - OP1: floating point number
;   - DE: bufPointer
; Output:
;   - (DE): floating point rendered in scientific notation, no NUL terminator
;   - DE: updated
; Destroys: A, B, C, DE, HL
formSciString:
    ld hl, OP1
    ld b, 14 ; 14 digit mantissa in BCD format
    ld a, (hl)
    inc hl
    rla ; CF=bit7 of floating point object type T
    jr nc, formSciStringDigits
    ld a, '-'
    ld (de), a
    inc de
formSciStringDigits:
    ; Save the exponent
    ld a, (hl) ; A=EXP
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
    jr formSciStringLoopAltEntry
formSciStringLoop:
    ld a, (hl)
    inc hl
    ld c, a ; C=BCD digit saved
    ; print the first digit
    srl a
    srl a
    srl a
    srl a
    jr z, formSciStringMaintainLastDE1
    ; non-zero digit, so update the last known non-zero DE on the stack
    ex (sp), hl
    ld h, d
    ld l, e
    ex (sp), hl ; stack=[EXP, new lastNonZeroDE]; HL preserved
formSciStringMaintainLastDE1:
    call convertAToChar
formSciStringLoopAltEntry:
    ld (de), a
    inc de
    dec b
    jr z, formSciStringExp
    ; print the second digit
    ld a, c ; A=BCD digit
    and $0F
    jr z, formSciStringMaintainLastDE2
    ; non-zero digit, so update the last known non-zero DE on the stack
    ex (sp), hl
    ld h, d
    ld l, e
    ex (sp), hl ; stack=[EXP, lastNonZeroDE]
formSciStringMaintainLastDE2:
    call convertAToChar
    ld (de), a
    inc de
    djnz formSciStringLoop
formSciStringExp:
    pop de ; stack=[EXP]; DE=lastNonZeroDE
    inc de ; move past the last non-zero trailing digit
    ; print the Exponent in scientific notation
    ld a, Lexponent
    ld (de), a
    inc de
    pop af ; stack=[]; A=EXP
    sub 128 ; A=exp=EXP-128
    jr nc, formSciStringPosExp
    ; Exponent is negative, so print a '-', then print (-EXP)
    ld c, a
    ld a, '-'
    ld (de), a
    inc de
    ld a, c
    neg ; A=-EXP
formSciStringPosExp:
    ex de, hl
    call convertAToDec ; HL string updated, no NUL termination
    ex de, hl
    ret

;------------------------------------------------------------------------------

; Description: Format the integer in OP1 to an integer string. The longest
; string produced by this routine is 14 characters.
;
; This routine assumes that:
; - OP1 is not zero (but can be negative)
; - abs(OP1) is an integer < 10^14 (i.e. 14 digits or less)
; No validation of the EXP parameter is performed.
;
; Input:
;   - OP1: an integer represented as a floating point number
;   - DE: bufPointer
; Output:
;   - (DE): floating point rendered in scientific notation, no NUL terminator
;   - DE: updated
; Destroys: A, B, C, DE, HL
formIntString:
    ld hl, OP1
    ld a, (hl) ; A=signByte
    inc hl
    rla ; CF=bit7 of floating point object type T
    jr nc, formIntStringDigits
    ld a, '-'
    ld (de), a
    inc de
formIntStringDigits:
    ld a, (hl) ; A=EXP
    inc hl
    sub a, 127
    ld b, a ; B=EXP-127=number of integer digits to print
formIntStringLoop:
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
    ret z
    ; print the second digit
    ld a, c ; A=BCD digit
    and $0F
    call convertAToChar
    ld (de), a
    inc de
    djnz formIntStringLoop
    ret

;------------------------------------------------------------------------------

; Description: Reformat the base-2 string in groups of 4, 2 groups per line.
; The source string is probably at OP4. The destination string is probably OP3,
; which is 11 bytes before OP4. The original string is a maximum of 32
; characters long. The formatted string adds 2 characters per line, for a
; maximum of 8 characters, which is less than the 11 bytes that OP3 is before
; OP4. Therefore the formatting can be done in-situ because at every point in
; the iteration, the resulting string does not affect the upcoming digits.
;
; The maximum length of the final string is 4 lines * 10 bytes = 40 bytes,
; which is smaller than the 44 bytes available using OP3-OP6.
;
; Input:
;   - HL: pointer to source base-2 string (probably OP4)
;   - DE: destination string buffer (sometimes OP3)
; Output:
;   - (DE): base-2 string formatted in lines of 8 digits, in 2 groups of 4
;   digits
;   - DE updated
reformatBaseTwoString:
    call getWordSizeIndex
    inc a ; A=baseWordSize/8=number of bytes
    ld b, a
reformatBaseTwoStringLoop:
    push bc
    ld bc, 4
    ldir
    ld a, ' '
    ld (de), a
    inc de
    ;
    ld bc, 4
    ldir
    ld a, Lenter
    ld (de), a
    inc de
    ;
    pop bc
    djnz reformatBaseTwoStringLoop
    ret
