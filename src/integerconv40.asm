;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Functions to convert between TI-OS floating point and u40/i40 integers.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; u40 or i40 to OP1
;------------------------------------------------------------------------------

; Description: Convert the i40 in OP1 to floating point number in OP1.
; Input: OP1:i40
; Output: OP1: floating point equivalent of u40
; Destroys: all
; Preserves: OP2-OP6
ConvertI40ToOP1:
    ld hl, OP1
    call isPosU40 ; ZF=1 if positive or zero
    jr z, ConvertU40ToOP1
    call negU40 ; U40=-U40
    call ConvertU40ToOP1
    bcall(_InvOP1S) ; invert the sign
    ret

; Description: Convert the u40 in OP1 to a floating point number in OP1. This
; is similar to the convertU32ToOP1() function.
; Input: OP1:u40
; Output: OP1: floating point equivalent of u40
; Destroys: A, B, C, DE, HL
; Preserves: OP2-OP6
ConvertU40ToOP1:
    call pushRaw9Op1 ; FPS=[raw9]; HL=raw9
    push hl ; stack=[FPSraw9]
    bcall(_PushRealO2) ; FPS=[raw9, OP2]
    bcall(_OP1Set0)
    pop hl ; stack=[]; HL=FPSraw9
    ; set up loop
    ld de, 4
    add hl, de ; HL points to most significant byte
    ld b, 5
convertU40ToOP1Loop:
    ld a, (hl)
    dec hl
    bcall(_AddAToOP1) ; preserves BC, HL
    djnz convertU40ToOP1Loop
    ;
    bcall(_PopRealO2) ; FPS=[OP1]; OP2=OP2
    call dropRaw9
    ret

;------------------------------------------------------------------------------
; OP1 to u40 or i40
;------------------------------------------------------------------------------

; Bit flags of the u40StatusCode.
;   - u40StatusCodeNegative and u40StatusCodeTooBig are usually fatal errors
;   which throw an exception.
;   - u40StatusCodeHasFrac is sometimes a non-fatal error, because the
;   operation will truncate to integer before continuing with the calculation.
;   - u40StatusCodeFatalMask can be used to check only the fatal codes using a
;   bitwise-and
u40StatusCodeNegative equ 0
u40StatusCodeTooBig equ 1
u40StatusCodeHasFrac equ 7
u40StatusCodeFatalMask equ $03

; Description: Convert OP1 to an i40 integer, throwing an Err:Domain if OP1 is
; not in the range of (-2^39,+2^39).
; Input:
;   - OP1: *signed* 40-bit integer as a floating point number
; Output:
;   - OP1: converted to a i40
;   - C: u40StatusCode
; Destroys: A, B, C, DE, HL
; Preserves: OP2-OP6
ConvertOP1ToI40:
    ld a, (OP1)
    bit 7, a ; ZF=0 if negative
    jr z, convertOP1ToI40Pos
    ; Handle negative by changing the sign of the floating point, converting it
    ; to U40, then doing a two's complement to get an i40.  Strictly speaking,
    ; this code does not handle the smallest negative value of -2^39, but
    ; that's beyond the normal usage of this function, so it's not worth
    ; spending effort to handle that special case.
    res 7, a
    ld (OP1), a
    call convertOP1ToI40Pos ; OP1=u40(OP1)
    ld hl, OP1
    call negU40 ; two's complement
    ret
convertOP1ToI40Pos:
    ; check overflow of postive i40
    bcall(_PushRealO2)
    call op2Set2Pow39PageTwo
    bcall(_CpOP1OP2) ; if OP1 >= 2^39: CF=0
    jr nc, convertOP1ToU40Error
    bcall(_PopRealO2)
    ; [[fallthrough]]

;------------------------------------------------------------------------------

; Description: Convert OP1 to a u40 integer, throwing an Err:Domain exception
; if OP1 is:
; - not in the range of [0, 2^40), or
; - is negative, or
; - contains fractional part.
;
; See convertOP1ToU40NoCheck() to convert to U40 without throwing.
;
; Input:
;   - OP1: unsigned 40-bit integer as a floating point number
; Output:
;   - OP1: converted to a u40
;   - C: u40StatusCode
; Destroys: A, B, C, DE, HL
; Preserves: OP2-OP6
ConvertOP1ToU40:
    call convertOP1ToU40StatusCode ; OP3=u40(OP1); C=u40StatusCode
    ld a, c
    or a
    ret z
convertOP1ToU40Error:
    bcall(_ErrDomain) ; throw exception

; Description: Convert OP1 to u40 with u40StatusCode.
; Input:
;   - OP1: floating point number
; Output:
;   - OP1: converted into u40
;   - C: u40StatusCode
; Destroys: A, B, C, DE
; Preserves: OP2-OP6
convertOP1ToU40StatusCode:
    ld c, 0 ; u40StatusCode
    push bc ; stack=[u40StatusCode]
    bcall(_PushRealO2) ; FPS=[OP2 saved]
    ; check negative
    bcall(_CkOP1Pos) ; if OP1<0: ZF=0
    jr nz, convertOP1ToU40StatusCodeNegative
    ; check too big
    call op2Set2Pow40PageTwo
    bcall(_CpOP1OP2) ; if OP1 >= 2^40: CF=0
    jr nc, convertOP1ToU40StatusCodeTooBig
    ; check has fraction
    bcall(_CkPosInt) ; if OP1>=0 and OP1 is int: ZF=1
    jr nz, convertOP1ToU40StatusCodeHasFrac
convertOP1ToU40StatusCodeValid:
    bcall(_PopRealO2) ; FPS=[]; OP2=restored
    call convertOP1ToU40NoCheck
    pop bc ; stack=[]; C=u40StatusCode
    ret
convertOP1ToU40StatusCodeNegative:
    bcall(_PopRealO2) ; FPS=[]; OP2=restored
    pop bc ; stack=[u40]; C=u40StatusCode
    set u40StatusCodeNegative, c
    ret
convertOP1ToU40StatusCodeTooBig:
    bcall(_PopRealO2) ; FPS=[]; OP2=restored
    pop bc ; stack=[u40]; C=u40StatusCode
    set u40StatusCodeTooBig, c
    ret
convertOP1ToU40StatusCodeHasFrac:
    bcall(_PopRealO2) ; FPS=[]; OP2=restored
    pop bc ; stack=[u40]; C=u40StatusCode
    set u40StatusCodeHasFrac, c
    push bc
    call convertOP1ToU40NoCheck
    pop bc
    ret

; Description: Convert floating point OP1 to a u40, in situ. This routine
; assume that OP1 is a floating point number between [0, 2^40). Fractional
; digits are ignored when converting to u40 integer. Use ConvertOP1ToU40() to
; perform a validation check that throws an exception.
; Input:
;   - OP1: unsigned 32-bit integer as a floating point number
; Output:
;   - HL=OP1
;   - OP1: converted to a u40
; Destroys: A, BC, DE
; Preserves: OP2-OP6
convertOP1ToU40NoCheck:
    ; initialize the target u40
    call pushRaw9Op1 ; HL=FPSraw9
    call clearU40
    bcall(_CkOP1FP0) ; preserves HL
    jr z, convertOP1ToU40NoCheckEnd
    ; extract number of decimal digits
    ld de, OP1+1 ; exponent byte
    ld a, (de)
    sub $7F ; A = exponent + 1 = num digits in mantissa
    ld b, a ; B = num digits in mantissa
    jr convertOP1ToU40LoopEntry
convertOP1ToU40Loop:
    call multU40By10
convertOP1ToU40LoopEntry:
    ; get next 2 digits of mantissa
    inc de ; DE = pointer to mantissa
    ld a, (de)
    ; Process first mantissa digit
    rrca
    rrca
    rrca
    rrca
    and $0F
    call addU40ByA
    ; check number of mantissa digits
    dec b
    jr z, convertOP1ToU40NoCheckEnd
convertOP1ToU40SecondDigit:
    ; Process second mantissa digit
    call multU40By10
    ld a, (de)
    and $0F
    call addU40ByA
    djnz convertOP1ToU40Loop
convertOP1ToU40NoCheckEnd:
    call popRaw9Op1 ; FPS=[]; HL=OP1=u40(OP1)
    ret
