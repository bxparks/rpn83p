;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Routines to convert between TI-OS floating point numbers in OP1 or OP2
; to the u32 integers required by the BASE functions in integer32.asm.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Convert real OP1 to u32.
;-----------------------------------------------------------------------------

; Description: Similar to convertOP1ToU32(), but don't throw if there is a
; fractional part.
; Input:
;   - OP1:real=input
; Output:
;   - OP1:u32=output
;   - C:u8=u32StatusCode
;   - HL=OP1
; Destroys: A, B, C, DE, HL
; Preserves: OP2-OP6
convertOP1ToU32AllowFrac:
    call ConvertOP1ToU32StatusCode ; OP1=u32(OP1); C=u32StatusCode
    ld a, c
    and u32StatusCodeFatalMask
    ret z
    bcall(_ErrDomain) ; throw exception

; Description: Similar to convertOP2ToU32(), but don't throw if there is a
; fractional part.
; Input:
;   - OP2:real=input
; Output:
;   - OP2:u32=output
;   - C:u8=u32StatusCode
;   - HL=OP2
; Destroys: A, B, C, DE, HL
; Preserves: OP1, OP3-OP6
convertOP2ToU32AllowFrac:
    call op1ExOp2PageTwo
    call convertOP1ToU32AllowFrac
    call op1ExOp2PageTwo
    ld hl, OP2
    ret

; Description: Convert real OP1 to a u32, throwing an Err:Domain exception if
; OP1 is:
; - not in the range of [0, 2^32), or
; - is negative, or
; - contains fractional part.
;
; See convertOP1ToU32NoCheck() to convert to U32 without throwing.
;
; Input:
;   - OP1:real=input
; Output:
;   - OP1:u32=output
;   - C:u8=u32StatusCode
;   - HL=OP1
; Destroys: A, B, C, DE, HL
; Preserves: OP2-OP6
convertOP1ToU32:
    call ConvertOP1ToU32StatusCode ; OP1=u32(OP1); C=u32StatusCode
    ld a, c
    or a
    ret z
    bcall(_ErrDomain) ; throw exception

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

; Description: Convert OP1 to U32 with u32StatusCode. This routine allows the
; calling code to handle various error conditions with more flexibility.
; Input:
;   - OP1=input
; Output:
;   - OP1:u32=result
;   - C:u8=u32StatusCode
;   - HL=OP1
; Destroys: A, B, C, DE, HL
; Preserves: OP2-OP6
ConvertOP1ToU32StatusCode:
    ld c, 0 ; u32StatusCode
    push bc ; stack=[u32StatusCode]
    bcall(_PushRealO2) ; FPS=[OP2 saved]
    ; check negative
    bcall(_CkOP1Pos) ; if OP1<0: ZF=0
    jr nz, convertOP1ToU32StatusCodeNegative
    ; check too big
    call op2Set2Pow32PageTwo
    bcall(_CpOP1OP2) ; if OP1 >= 2^32: CF=0
    jr nc, convertOP1ToU32StatusCodeTooBig
    ; check has fraction
    bcall(_CkPosInt) ; if OP1>=0 and OP1 is int: ZF=1
    jr nz, convertOP1ToU32StatusCodeHasFrac
convertOP1ToU32StatusCodeValid:
    ; valid, so convert to u32
    bcall(_PopRealO2) ; FPS=[]; OP2=restored
    call convertOP1ToU32NoCheck
    pop bc ; stack=[]; C=u32StatusCode
    ld hl, OP1
    ret
convertOP1ToU32StatusCodeNegative:
    bcall(_PopRealO2) ; FPS=[]; OP2=restored
    pop bc ; stack=[u32]; C=u32StatusCode
    set u32StatusCodeNegative, c
    ld hl, OP1
    ret
convertOP1ToU32StatusCodeTooBig:
    bcall(_PopRealO2) ; FPS=[]; OP2=restored
    pop bc ; stack=[result]; C=u32StatusCode
    set u32StatusCodeTooBig, c
    ld hl, OP1
    ret
convertOP1ToU32StatusCodeHasFrac:
    bcall(_PopRealO2) ; FPS=[]; OP2=restored
    pop bc ; stack=[u32]; C=u32StatusCode
    set u32StatusCodeHasFrac, c
    push bc
    call convertOP1ToU32NoCheck ; HL=OP1
    pop bc
    ret

;-----------------------------------------------------------------------------

; Description: Convert floating point OP1 to a u32. This routine assume that
; OP1 is a floating point number between [0, 2^32). Fractional digits are
; ignored when converting to U32 integer. Use convertOP1ToU32() to perform a
; validation check that throws an exception.
; Input:
;   - OP1:real=input
; Output:
;   - OP1:u32=output
;   - HL=OP1
; Destroys: A, BC, DE, HL
; Preserves: OP2-OP6
convertOP1ToU32NoCheck:
    ; initialize the target u32
    call pushRaw9Op1 ; FPS=[result]; HL=result
    call clearU32
    bcall(_CkOP1FP0) ; preserves HL
    jr z, convertOP1ToU32NoCheckEnd
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
    jr z, convertOP1ToU32NoCheckEnd
convertOP1ToU32SecondDigit:
    ; Process second mantissa digit
    call multU32By10
    ld a, (de)
    and $0F
    call addU32ByA
    djnz convertOP1ToU32Loop
convertOP1ToU32NoCheckEnd:
    call popRaw9Op1 ; FPS=[]; HL=OP1=result
    ret

#if 0
; Description: Same as convertOP1ToU32() except using OP2.
; Input:
;   - OP2:real=input
; Output:
;   - OP2:u32=output
;   - C: u32StatusCode
;   - HL=OP2
; Destroys: A, BC, DE, HL
; Preserves: OP2-OP6
convertOP2ToU32:
    call op1ExOp2PageTwo
    call convertOP1ToU32
    call op1ExOp2PageTwo
    ld hl, OP2
    ret
#endif

;-----------------------------------------------------------------------------
; Convert u32 to OP1.
;-----------------------------------------------------------------------------

; Description: Convert the u32 in OP1 to a floating point number in OP1.
; Input:
;   - OP1:u32=input
; Output:
;   - OP1:real=output
;   - HL=OP1
; Destroys: A, B, C, DE, HL
; Preserves: OP2-OP6
convertU32ToOP1:
    call pushRaw9Op1 ; FPS=[input]; HL=input
    push hl ; stack=[input]
    bcall(_PushRealO2) ; FPS=[input, OP2]
    bcall(_OP1Set0)
    pop hl ; stack=[]; HL=input
    ; set up loop
    inc hl
    inc hl
    inc hl ; HL=&input[3]=the most significant byte
    ld b, 4
convertU32ToOP1Loop:
    ld a, (hl)
    dec hl
    bcall(_AddAToOP1) ; preserves BC, HL
    djnz convertU32ToOP1Loop
    ;
    bcall(_PopRealO2) ; FPS=[input]; OP2=restored
    call dropRaw9
    ld hl, OP1
    ret

;-----------------------------------------------------------------------------
; Convert OP1 to uxx (u32, u24, u16, or u8) depending on (baseWordSize).
;-----------------------------------------------------------------------------

; Description: Convert real number in OP1 to (u8,u16,u24,u32) in OP, checking
; for fatal errors.
; Input:
;   - OP1:real
; Output:
;   - OP1:(u8|u16|u24|u32)=output
;   - C:u8=u32StatusCode
;   - HL=OP1
; Destroys: A, B, C, DE, HL
; Throws:
;   - Err:Domain if the resulting integer is too large for (baseWordSize)
convertOP1ToUxx:
    call ConvertOP1ToU32StatusCode ; OP1=u32(OP1); C=u32StatusCode
    call CheckU32FitsWsize ; C=u32StatusCode; preserves HL
    ld a, c
    and u32StatusCodeFatalMask
    ret z
    bcall(_ErrDomain) ; throw exception

; Description: Convert real number in OP1 to (u8,u16,u24,u32) in OP1. This
; version checks if the resulting number fits in the integer size given by
; (baseWordSize), but does NOT throw an exception.
; Input:
;   - OP1:real=input
; Output:
;   - OP1:(u8|u16|u24|u32)=output
;   - C:u8=u32StatusCode
;   - HL=OP1
; Destroys: A, B, C, DE, HL
; Preserves: OP2-OP6
ConvertOP1ToUxxNoFatal:
    call ConvertOP1ToU32StatusCode ; OP1=U32; C=statusCode
    jp CheckU32FitsWsize ; C=u32StatusCode

; Description: Convert OP1, OP2 to u32, u32.
; Input:
;   - OP1, OP2
; Output:
;   - OP1=u32(OP1); OP2=u32(OP2)
;   - HL=OP1; DE=OP2
; Throws:
;   - Err:Domain if the resulting integers are too large for (baseWordSize)
convertOP1OP2ToUxx:
    call convertOP1ToU32AllowFrac ; OP1=u32(OP1); HL=OP1
    call CheckU32FitsWsize ; C=u32StatusCode; preserves HL
    ld a, c
    and u32StatusCodeFatalMask
    jr nz, convertOP1OP2ToUxxErr
    ;
    call convertOP2ToU32AllowFrac ; OP1=u32(OP1); HL=OP2
    call CheckU32FitsWsize ; C=u32StatusCode; preserves HL
    ld a, c
    and u32StatusCodeFatalMask
    jr nz, convertOP1OP2ToUxxErr
    ;
    ld hl, OP1
    ld de, OP2
    ret
convertOP1OP2ToUxxErr:
    bcall(_ErrDomain) ; throw exception

; Description: Convert OP1 to u32(OP1) and OP2 to u32(OP2). Additionally,
; verify that OP2 is < (baseWordSize).
; Input:
;   - OP1, OP2
; Output:
;   - OP1=u32(OP1); OP2=u32(OP2)
;   - HL=OP1; DE=OP2
;   - A=u8(OP2)
;   - ZF=1 if A==0
; Destroys: A, DE, HL
; Throws: Err:Domain if OP2 is >= (baseWordSize)
convertOP1OP2ToUxxN:
    call convertOP1OP2ToUxx ; HL=OP1=u32(OP1); DE=OP2=u32(OP2)
    ; Furthermore, check OP2 against baseWordSize
    ex de, hl ; HL=OP2
    ld a, (baseWordSize)
    call cmpU32WithA ; CF=0 if OP2>=baseWordSize
    jr nc, convertOP1OP2ToUxxNErr
    ld a, (hl) ; A=u8(OP2)
    ex de, hl ; DE=OP2; HL=OP1
    or a ; set ZF=1 if u8(OP2)==0
    ret
convertOP1OP2ToUxxNErr:
    bcall(_ErrDomain) ; throw exception if X >= baseWordSize

;-----------------------------------------------------------------------------
; Routines that query (baseWordSize).
;-----------------------------------------------------------------------------

; Description: Check if the given u32 fits in the given WSIZE.
; Input:
;   - HL:(const u32*)
;   - C: u32StatusCode
;   - (baseWordSize): current word size
; Output:
;   - C: u32StatusCodeTooBig bit set if u32 is too big for baseWordSize
; Destroys: A, B, C
; Preserves: DE, HL
CheckU32FitsWsize:
    call getWordSizeIndex ; A=0,1,2,3
    sub 3 ; A=A-3
    neg ; A=3-A
    ret z ; if A==0 (i.e. wordSize==32): return
    ld b, a ; B=number of upper bytes of u32 to check
    xor a
    push hl
    inc hl
    inc hl
    inc hl
checkU32FitsLoop:
    or (hl)
    dec hl
    jr nz, checkU32FitsWsizeTooBig
    djnz checkU32FitsLoop
checkU32FitsWsizeOk:
    pop hl
    ret
checkU32FitsWsizeTooBig:
    set u32StatusCodeTooBig, c
    pop hl
    ret

; Description: Return the index corresponding to each of the potential values
; of (baseWordSize). For the values of (8, 16, 24, 32) this returns (0, 1, 2,
; 3).
; Input: (baseWordSize)
; Output: A=(baseWordSize)/8-1
; Throws: Err:Domain if not 8, 16, 24, 32.
; Destroys: A
; Preserves: BC, DE, HL
getWordSizeIndex:
    push bc
    ld a, (baseWordSize)
    ld b, a
    and $07 ; 0b0000_0111
    jr nz, getWordSizeIndexErr
    ld a, b
    rrca
    rrca
    rrca
    dec a
    ld b, a
    and $FC ; 0b1111_1100
    ld a, b
    pop bc
    ret z
getWordSizeIndexErr:
    bcall(_ErrDomain)
