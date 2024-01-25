;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Routines to convert between TI-OS floating point numbers in OP1 or OP2
; to the u32 integers required by the BASE functions in baseops.asm.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Convert TI floating point number to u8 or u32.
;-----------------------------------------------------------------------------

; Bit flags of the u32StatusCode.
;   - u32StatusCodeNegative and u32StatusCodeTooBig are usually fatal errors
;   which throw an exception.
;   - u32StatusCodeHasFrac is sometimes a non-fatal error, because the
;   operation will truncate to integer before continuing with the calculation.
;   - u32StatusCodeFatalMask can be used to check only the fatal codes using a
;   bitwise-and
u32StatusCodeNegative equ 0
u32StatusCodeTooBig equ 1
u32StatusCodeHasFrac equ 7
u32StatusCodeFatalMask equ $03

; Description: Similar to convertOP1ToU32(), but don't throw if there is a
; fractional part.
; Input:
;   - OP1: unsigned 32-bit integer as a floating point number
;   - HL: pointer to a u32 in memory, cannot be OP2
; Output:
;   - HL: OP1 converted to a u32, in little-endian format
; Destroys: A, B, C, DE
; Preserves: HL, OP1, OP2
convertOP1ToU32AllowFrac:
    call convertOP1ToU32StatusCode ; OP3=u32(OP1); C=u32StatusCode
    ld a, c
    and u32StatusCodeFatalMask
    jr nz, convertOP1ToU32Error
    ret

convertOP1ToU32Error:
    bcall(_ErrDomain) ; throw exception

; Description: Similar to convertOP2ToU32(), but don't throw if there is a
; fractional part.
; Input:
;   - OP2: unsigned 32-bit integer as a floating point number
;   - HL: pointer to a u32 in memory, cannot be OP2
; Output:
;   - HL: OP2 converted to a u32, in little-endian format
; Destroys: A, B, C, DE
; Preserves: HL, OP1, OP2
convertOP2ToU32AllowFrac:
    push hl
    bcall(_OP1ExOP2)
    pop hl
    push hl
    call convertOP1ToU32AllowFrac
    bcall(_OP1ExOP2)
    pop hl
    ret

;-----------------------------------------------------------------------------

; Description: Convert OP1 to a U32, throwing an Err:Domain exception if OP1 is:
; - not in the range of [0, 2^32), or
; - is negative, or
; - contains fractional part.
;
; See convertOP1ToU32NoCheck() to convert to U32 without throwing.
;
; Input:
;   - OP1: unsigned 32-bit integer as a floating point number
;   - HL: pointer to a u32 in memory, cannot be OP2
; Output:
;   - HL: OP1 converted to a u32, in little-endian format
;   - C: u32StatusCode
; Destroys: A, B, C, DE
; Preserves: HL, OP1, OP2
convertOP1ToU32:
    call convertOP1ToU32StatusCode ; OP3=u32(OP1); C=u32StatusCode
    ld a, c
    or a
    jr nz, convertOP1ToU32Error
    ret

; Description: Convert OP1 to U32 with u32StatusCode.
; Input:
;   - OP1: floating point number
;   - HL: pointer to u32 in memory, cannot be OP2
; Output:
;   - HL: pointer to u32
;   - C: u32StatusCode
; Destroys: A, B, C, DE
; Preserves: HL, OP1, OP2
convertOP1ToU32StatusCode:
    call clearU32 ; ensure u32=0 even when error conditions are detected
    push hl ; stack=[u32]
    ld c, 0 ; u32StatusCode
    push bc ; stack=[u32, u32StatusCode]
    bcall(_PushRealO2) ; FPS=[OP2 saved]
    ; check negative
    bcall(_CkOP1Pos) ; if OP1<0: ZF=0
    jr z, convertOP1ToU32StatusCodeCheckTooBig
    bcall(_PopRealO2) ; FPS=[]; OP2=OP2 saved
    pop bc ; stack=[u32]; C=u32StatusCode
    pop hl ; stack=[]; HL=u32
    set u32StatusCodeNegative, c
    ret
convertOP1ToU32StatusCodeCheckTooBig:
    call op2Set2Pow32
    bcall(_CpOP1OP2) ; if OP1 >= 2^32: CF=0
    jr c, convertOP1ToU32StatusCodeCheckInt
    bcall(_PopRealO2) ; FPS=[]; OP2=OP2 saved
    pop bc ; stack=[u32]; C=u32StatusCode
    pop hl ; stack=[]; HL=u32
    set u32StatusCodeTooBig, c
    ret
convertOP1ToU32StatusCodeCheckInt:
    bcall(_CkPosInt) ; if OP1>=0 and OP1 is int: ZF=1
    jr z, convertOP1ToU32StatusCodeValid
    bcall(_PopRealO2) ; FPS=[]; OP2=OP2 saved
    pop bc ; stack=[u32]; C=u32StatusCode
    pop hl ; stack=[]; HL=u32
    set u32StatusCodeHasFrac, c
    jr convertOP1ToU32StatusCodeContinue
convertOP1ToU32StatusCodeValid:
    bcall(_PopRealO2) ; FPS=[]; OP2=OP2 saved
    pop bc ; stack=[u32]; C=u32StatusCode
    pop hl ; stack=[]; HL=u32
convertOP1ToU32StatusCodeContinue:
    ; [[fallthrough]]

;-----------------------------------------------------------------------------

; Description: Convert floating point OP1 to a u32. This routine assume that
; OP1 is a floating point number between [0, 2^32). Fractional digits are
; ignored when converting to U32 integer. Use convertOP1ToU32() to perform a
; validation check that throws an exception.
; Input:
;   - OP1: unsigned 32-bit integer as a floating point number
;   - HL: pointer to a u32 in memory, cannot be OP2
; Output:
;   - HL: OP1 converted to a u32, in little-endian format
; Destroys: A, B, DE
; Preserves: HL, C
convertOP1ToU32NoCheck:
    ; initialize the target u32
    call clearU32
    bcall(_CkOP1FP0) ; preserves HL
    ret z
    ; extract number of decimal digits
    ld de, OP1+1 ; exponent byte
    ld a, (de)
    sub $7F ; A = exponent + 1 = num digits in mantissa
    ld b, a ; B = num digits in mantissa
    jr convertOP1ToU32LoopEntry
convertOP1ToU32Loop:
    call multU32By10
convertOP1ToU32LoopEntry:
    ; get next 2 digits of mantissa
    inc de ; DE = pointer to mantissa
    ld a, (de)
    ; Process first mantissa digit
    rrca
    rrca
    rrca
    rrca
    and $0F
    call addU32ByA
    ; check number of mantissa digits
    dec b
    ret z
convertOP1ToU32SecondDigit:
    ; Process second mantissa digit
    call multU32By10
    ld a, (de)
    and $0F
    call addU32ByA
    djnz convertOP1ToU32Loop
    ret

; Description: Same as convertOP1ToU32() except using OP2.
; Input:
;   - OP2: unsigned 32-bit integer as a floating point number
;   - HL: pointer to a u32 in memory, cannot be OP1 or OP2
; Destroys: A, B, C, DE
; Preserves: HL, OP1, OP2
convertOP2ToU32:
    push hl
    bcall(_OP1ExOP2)
    pop hl
    push hl
    call convertOP1ToU32
    bcall(_OP1ExOP2)
    pop hl
    ret

;-----------------------------------------------------------------------------
; Convert U8 or U32 to a TI floating point number.
;-----------------------------------------------------------------------------

; Description: Convert the u32 referenced by HL to a floating point number in
; OP1.
; Input: HL: pointer to u32 (must not be OP2)
; Output: OP1: floating point equivalent of u32(HL)
; Destroys: A, B, C, DE
; Preserves: HL, OP2
convertU32ToOP1:
    push hl
    bcall(_PushRealO2) ; FPS=[OP2 saved]
    bcall(_OP1Set0)
    pop hl

    inc hl
    inc hl
    inc hl ; HL points to most significant byte

    ld a, (hl)
    dec hl
    call addAToOP1

    ld a, (hl)
    dec hl
    call addAToOP1

    ld a, (hl)
    dec hl
    call addAToOP1

    ld a, (hl)
    call addAToOP1

    push hl
    bcall(_PopRealO2) ; FPS=[]; OP2=OP2 saved
    pop hl
    ret

; Description: Convert the u8 in A to floating pointer number in OP1. This
; supports the full range of A from 0 to 255, compared to the SetXXOP1()
; function in the SDK which supports only integers between 0 and 99.
; Input:
;   - A: u8 integer
; Output:
;   - OP1: floating point value of A
; Destroys: A, B, DE, OP2
; Preserves: C, HL
convertAToOP1:
    push af
    bcall(_OP1Set0)
    pop af
    ; [[fallthrough]]

; Description: Convert the u8 in A to floating point number, and add it to OP1.
; Input:
;   - A: u8 integer
;   - OP1: current floating point value, set to 0.0 to start fresh
; Destroys: A, B, DE, OP2
; Preserves: C, HL
addAToOP1:
    push hl
    ld b, 8 ; loop for 8 bits in u8
addAToOP1Loop:
    push bc
    push af
    bcall(_Times2) ; OP1 *= 2
    pop af
    sla a
    jr nc, addAToOP1Check
    push af
    bcall(_Plus1) ; OP1 += 1
    pop af
addAToOP1Check:
    pop bc
    djnz addAToOP1Loop
    pop hl
    ret

;-----------------------------------------------------------------------------
; Convert OP1 to Uxx (u32, u24, u16, or u8) depending on (baseWordSize).
;-----------------------------------------------------------------------------

; Description: Convert OP1 to u32.
; Input: OP1
; Output:
;   - OP3=u32(OP1)
;   - HL=OP3
convertOP1ToUxx:
    ld hl, OP3
    call convertOP1ToU32StatusCode ; OP3=u32(OP1); C=u32StatusCode
    call checkU32FitsWsize ; C=u32StatusCode
    ld a, c
    and u32StatusCodeFatalMask
    jp nz, convertOP1ToU32Error
    ret

; Description: Convert OP1, OP2 to u32, u32.
; Input: OP1, OP2
; Output:
;   - OP3=u32(OP1); OP4=u32(OP2)
;   - HL=OP3; DE=OP4
convertOP1OP2ToUxx:
    ld hl, OP3
    call convertOP1ToU32AllowFrac ; OP3=u32(OP1)
    call checkU32FitsWsize ; C=u32StatusCode
    ld a, c
    and u32StatusCodeFatalMask
    jp nz, convertOP1ToU32Error
    ;
    ld hl, OP4
    call convertOP2ToU32AllowFrac ; OP4=u32(OP2)
    call checkU32FitsWsize ; C=u32StatusCode
    ld a, c
    and u32StatusCodeFatalMask
    jp nz, convertOP1ToU32Error
    ;
    ld hl, OP3
    ld de, OP4
    ret

; Description: Convert OP1, OP2 to u32, u32.
; Input: OP1, OP2
; Output:
;   - OP3=u32(OP1); OP4=u32(OP2)
;   - HL=OP3; A=u8(OP4)
;   - ZF=1 if A==0
convertOP1OP2ToUxxN:
    call convertOP1OP2ToUxx ; HL=OP3=u32(OP1); DE=OP4=u32(OP2)
    ; Furthermore, check OP4 against baseWordSize
    ex de, hl ; HL=OP4=u32(OP2)
    ld a, (baseWordSize)
    call cmpU32WithA
    jr nc, convertOP1OP2ToUxxErr
    ex de, hl ; HL=OP3=u32(OP1); DE=OP4=u32(OP2)
    ld a, (de) ; A=u8(OP4)
    or a ; set ZF=1 if u8(OP2)==0
    ret
convertOP1OP2ToUxxErr:
    bcall(_ErrDomain) ; throw exception if X >= baseWordSize

