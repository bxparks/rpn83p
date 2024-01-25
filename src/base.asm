;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Routines to convert between TI-OS floating point numbers in OP1 or OP2
; to the u32 integers required by the BASE functions in baseops.asm.
;-----------------------------------------------------------------------------

initBase:
    res rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ld a, 10
    ld (baseNumber), a
    xor a
    ld (baseCarryFlag), a
    ld a, 32
    ld (baseWordSize), a
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

;-----------------------------------------------------------------------------

; Description: Check if the given u32 fits in the given WSIZE.
; Input:
;   - HL: u32
;   - C: u32StatusCode
;   - (baseWordSize): current word size
; Output:
;   - C: u32StatusCodeTooBig bit set if u32 is too big for baseWordSize
; Destroys: A, B, C
; Preserves: DE, HL
checkU32FitsWsize:
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

;-----------------------------------------------------------------------------
; Entry point of BASE operation from basehandlers.asm. This indirection layer
; becomes the API to the lower-level baseops.asm routines, allowing us to move
; baseops.asm to another flash page more easily.
;-----------------------------------------------------------------------------

; Description: Calculate the bitwise-and between the integers in OP1 and OP2.
; Input: OP1, OP2
; Output: OP1: result as a floating number
bitwiseAnd:
    call convertOP1OP2ToUxx ; HL=OP3=u32(OP1); DE=OP4=u32(OP2)
    call truncToWordSize
    ex de, hl
    call truncToWordSize
    ex de, hl
    call andU32U32 ; HL=OP3 AND OP4
    call truncToWordSize
    jp convertU32ToOP1 ; OP1=float(OP3)

; Description: Calculate the bitwise-or between the integers in OP1 and OP2.
; Input: OP1, OP2
; Output: OP1: result as a floating number
bitwiseOr:
    call convertOP1OP2ToUxx ; HL=OP3=u32(OP1); DE=OP4=u32(OP2)
    call truncToWordSize
    ex de, hl
    call truncToWordSize
    ex de, hl
    call orU32U32 ; HL=OP3=OP3 OR OP4
    call truncToWordSize
    jp convertU32ToOP1 ; OP1=float(OP3)

; Description: Calculate the bitwise-xor between the integers in OP1 and OP2.
; Input: OP1, OP2
; Output: OP1: result as a floating number
bitwiseXor:
    call convertOP1OP2ToUxx ; HL=OP3=u32(OP1); DE=OP4=u32(OP2)
    call truncToWordSize
    ex de, hl
    call truncToWordSize
    ex de, hl
    call xorU32U32 ; HL=OP3=OP3 XOR OP4
    call truncToWordSize
    jp convertU32ToOP1 ; OP1=float(OP3)

; Description: Calculate the bitwise-not of OP1
; Input: OP1
; Output: OP1: result as a floating number
bitwiseNot:
    call convertOP1ToUxx ; HL=OP3=u32(OP1)
    call truncToWordSize
    call notU32 ; OP3=NOT(OP3)
    call truncToWordSize
    jp convertU32ToOP1 ; OP1=float(OP3)

; Description: Calculate the bitwise-neg of OP1
; Input: OP1
; Output: OP1: result as a floating number
bitwiseNeg:
    call convertOP1ToUxx ; HL=OP3=u32(OP1)
    call truncToWordSize
    call negU32 ; OP3=NEG(OP3)
    call truncToWordSize
    jp convertU32ToOP1 ; OP1=float(OP3)

;-----------------------------------------------------------------------------

baseShiftLeftLogical:
    call convertOP1ToUxx ; HL=OP3=u32(OP1)
    call shiftLeftLogicalUxx ; OP3=shiftLeftLogical(OP3)
    call storeCarryFlag
    jp convertU32ToOP1 ; OP1=float(OP3)

baseShiftRightLogical:
    call convertOP1ToUxx ; HL=OP3=u32(OP1)
    call shiftRightLogicalUxx ; OP3=shiftRightLogical(OP3)
    call storeCarryFlag
    jp convertU32ToOP1 ; OP1=float(OP3)

baseShiftRightArithmetic:
    call convertOP1ToUxx ; HL=OP3=u32(OP1)
    call shiftRightArithmeticUxx ; OP3=shiftRightArithmetic(OP3)
    call storeCarryFlag
    jp convertU32ToOP1 ; OP1=float(OP3)

baseShiftLeftLogicalN:
    call convertOP1OP2ToUxxN ; HL=OP3=u32(OP1); A=u8(OP2); ZF=1 if A==0
    ret z
    ld b, a
baseShiftLeftLogicalNLoop:
    call shiftLeftLogicalUxx; (OP3)=shiftLeftLogical(OP3)
    djnz baseShiftLeftLogicalNLoop
    call storeCarryFlag
    jp convertU32ToOP1 ; OP1=float(OP3)

baseShiftRightLogicalN:
    call convertOP1OP2ToUxxN ; HL=OP3=u32(OP1); A=u8(OP2); ZF=1 if A==0
    ret z
    ld b, a
baseShiftRightLogicalNLoop:
    call shiftRightLogicalUxx; (OP3)=shiftRightLogical(OP3)
    djnz baseShiftRightLogicalNLoop
    call storeCarryFlag
    jp convertU32ToOP1 ; OP1=float(OP3)

;-----------------------------------------------------------------------------

baseRotateLeftCircular:
    call convertOP1ToUxx ; HL=OP3=u32(OP1)
    call rotateLeftCircularUxx ; OP3=rotateLeftCircular(OP3)
    call storeCarryFlag
    jp convertU32ToOP1 ; OP1=float(OP3)

baseRotateRightCircular:
    call convertOP1ToUxx ; HL=OP3=u32(OP1)
    call rotateRightCircularUxx ; OP3=rotateRightCircular(OP3)
    call storeCarryFlag
    jp convertU32ToOP1 ; OP1=float(OP3)

baseRotateLeftCarry:
    call convertOP1ToUxx ; HL=OP3=u32(OP1)
    call recallCarryFlag ; CF=(baseCarryFlag)
    call rotateLeftCarryUxx ; OP3=rotateLeftCarry(OP3)
    call storeCarryFlag ; (baseCarryFlag)=CF
    jp convertU32ToOP1 ; OP1=float(OP3)

baseRotateRightCarry:
    call convertOP1ToUxx ; HL=OP3=u32(OP1)
    call recallCarryFlag ; CF=(baseCarryFlag)
    call rotateRightCarryUxx ; OP3=rotateRightCarry(OP3)
    call storeCarryFlag ; (baseCarryFlag)=CF
    jp convertU32ToOP1 ; OP1=float(OP3)

;-----------------------------------------------------------------------------

baseRotateLeftCircularN:
    call convertOP1OP2ToUxxN ; HL=OP3=u32(OP1); A=u8(OP2); ZF=1 if A==0
    ret z
    ld b, a
    call recallCarryFlag ; CF=(baseCarryFlag)
baseRotateLeftCircularNLoop:
    call rotateLeftCircularUxx ; OP3=rotateLeftCircular(OP3)
    djnz baseRotateLeftCircularNLoop
    call storeCarryFlag
    jp convertU32ToOP1 ; OP1=float(OP3)

baseRotateRightCircularN:
    call convertOP1OP2ToUxxN ; HL=OP3=u32(OP1); A=u8(OP2); ZF=1 if A==0
    ret z
    ld b, a
    call recallCarryFlag ; CF=(baseCarryFlag)
baseRotateRightCircularNLoop:
    call rotateRightCircularUxx ; OP3=rotateRightCircular(OP3)
    djnz baseRotateRightCircularNLoop
    call storeCarryFlag
    jp convertU32ToOP1 ; OP1=float(OP3)

baseRotateLeftCarryN:
    call convertOP1OP2ToUxxN ; HL=OP3=u32(OP1); A=u8(OP2); ZF=1 if A==0
    ret z
    ld b, a
    call recallCarryFlag ; CF=(baseCarryFlag)
baseRotateLeftCarryNLoop:
    call rotateLeftCarryUxx ; OP3=rotateLeftCarry(OP3)
    djnz baseRotateLeftCarryNLoop
    call storeCarryFlag
    jp convertU32ToOP1 ; OP1=float(OP3)

baseRotateRightCarryN:
    call convertOP1OP2ToUxxN ; HL=OP3=u32(OP1); A=u8(OP2); ZF=1 if A==0
    ret z
    ld b, a
    call recallCarryFlag ; CF=(baseCarryFlag)
baseRotateRightCarryNLoop:
    call rotateRightCarryUxx ; OP3=rotateRightCarry(OP3)
    djnz baseRotateRightCarryNLoop
    call storeCarryFlag
    jp convertU32ToOP1 ; OP1=float(OP3)

;-----------------------------------------------------------------------------

baseAdd:
    call convertOP1OP2ToUxx ; HL=OP3=u32(OP1); DE=OP4=u32(OP2)
    call truncToWordSize
    call addUxxUxx ; OP3+=OP4
    call storeCarryFlag
    call truncToWordSize
    jp convertU32ToOP1 ; OP1=float(OP3)

baseSub:
    call convertOP1OP2ToUxx ; HL=OP3=u32(OP1); DE=OP4=u32(OP2)
    call truncToWordSize
    call subUxxUxx ; OP3-=OP4
    call storeCarryFlag
    call truncToWordSize
    jp convertU32ToOP1 ; OP1=float(OP3)

baseMult:
    call convertOP1OP2ToUxx ; HL=OP3=u32(OP1); DE=OP4=u32(OP2)
    call truncToWordSize
    call multUxxUxx ; OP3*=OP4
    call storeCarryFlag
    call truncToWordSize
    jp convertU32ToOP1 ; OP1=float(OP3)

; Output: OP1=quotient
baseDiv:
    call baseDivCommon
    jp convertU32ToOP1 ; OP1=quotient(OP3)

; Output: OP1=remainder; OP2=quotient
baseDiv2:
    call baseDivCommon ; HL=OP3=quotient; BC=OP5=remainder
    push bc ; stack=[remainder]
    ; convert HL=quotient into OP2
    call convertU32ToOP1
    bcall(_OP1ToOP2) ; OP2=quotient
    ; convert BC=remainder into OP1
    pop hl ; stack=[]; HL=remainder
    jp convertU32ToOP1 ; OP1=remainder

; Input:
;   - OP1=dividend
;   - OP2=divisor
; Output:
;   - HL=OP3=quotient
;   - DE=OP4=divisor
;   - BC=OP5=remainder
;   - (baseCarryFlag)=0
baseDivCommon:
    call convertOP1OP2ToUxx ; HL=OP3=u32(OP1); DE=OP4=u32(OP2)
    call truncToWordSize
    ex de, hl ; HL=OP4
    call testU32 ; check if X==0
    ex de, hl
    jr z,  baseDivByZeroErr
    ld bc, OP5 ; BC=remainder
    call divUxxUxx ; HL=OP3=quotient, DE=OP4=divisor, BC=OP5=remainder
    call storeCarryFlag ; CF=0 always
    jp truncToWordSize
baseDivByZeroErr:
    bcall(_ErrDivBy0) ; throw 'Div By 0' exception

;-----------------------------------------------------------------------------

baseReverseBits:
    call convertOP1ToUxx ; HL=OP3=u32(OP1)
    call truncToWordSize
    call reverseUxxBits
    jp convertU32ToOP1 ; OP1 = float(OP3)

baseCountBits:
    call convertOP1ToUxx ; HL=OP3=u32(OP1)
    call truncToWordSize
    call countU32Bits ; A=countBits(OP3)
    jp convertAToOP1 ; OP1=float(A)

baseSetBit:
    call convertOP1OP2ToUxxN ; HL=OP3=u32(OP1); A=u8(OP2); ZF=1 if A==0
    ld c, a
    call setU32Bit ; OP3=setBit(OP3,C)
    jp convertU32ToOP1 ; OP1=float(OP3)

baseClearBit:
    call convertOP1OP2ToUxxN ; HL=OP3=u32(OP1); A=u8(OP2); ZF=1 if A==0
    ld c, a
    call clearU32Bit ; OP3=clearBit(OP3,C)
    jp convertU32ToOP1 ; OP1=float(OP3)

baseGetBit:
    call convertOP1OP2ToUxxN ; HL=OP3=u32(OP1); A=u8(OP2); ZF=1 if A==0
    ld c, a
    call getU32Bit ; A=1 or 0
    jp convertAToOP1 ; OP1=float(A)

;-----------------------------------------------------------------------------
; Recall and store the Carry Flag.
;-----------------------------------------------------------------------------

; Description: Transfer CF to bit 0 of (baseCarryFlag).
; Input: CF
; Output: (baseCarryFlag)
; Destroys: A
storeCarryFlag:
    rla ; shift CF into bit-0
    and $1
    ld (baseCarryFlag), a
    set dirtyFlagsStatus, (iy + dirtyFlags)
    ret

; Description: Transfer bit 0 of (baseCarryFlag) into CF.
; Input: (baseCarryFlag)
; Output: CF
; Destroys: A
recallCarryFlag:
    ld a, (baseCarryFlag)
    rra ; shift bit 0 into CF
    ret

; Description: Return the baseCarryFlag as OP1.
; Input: (baseCarryFlag)
; Output: OP1=flaot(baseCarryFlag)
baseGetCarryFlag:
    call recallCarryFlag
    jr c, baseGetCarryFlagSet1
    bcall(_OP1Set0)
    ret
baseGetCarryFlagSet1:
    bcall(_OP1Set1)
    ret

;-----------------------------------------------------------------------------

; Description: Set the (baseWordSize) to A. Throws Err:Argument if A is not one
; of (8, 16, 24, 32).
; Input: A=new wordSize
; Output: (baseWordSize)=A
; Destroys: none
baseSetWordSize:
    cp 8
    jr z, setWordSize
    cp 16
    jr z, setWordSize
    cp 24
    jr z, setWordSize
    cp 32
    jr z, setWordSize
    ; throw Err:Argument if not (8,16,24,32)
    bcall(_ErrArgument)
setWordSize:
    ld (baseWordSize), a
    set dirtyFlagsStack, (iy + dirtyFlags)
    ret

; Description: Get the current (baseWordSize) in OP1.
; Input: None
; Output: OP1=float(baseWordSize)
; Destroys; A
baseGetWordSize:
    ld a, (baseWordSize)
    jp convertAToOP1 ; OP1=float(A)

;-----------------------------------------------------------------------------
; Routines related to Hex strings.
;-----------------------------------------------------------------------------

hexNumberWidth equ 8 ; 4 bits * 8 = 32 bits

; Description: Converts 32-bit unsigned integer referenced by HL to a hex
; string in buffer referenced by DE.
; TODO: It might be possible to combine convertU32ToHexString(),
; convertU32ToOctString(), and convertU32ToBinString() into a single routine.
;
; Input:
;   - HL: pointer to 32-bit unsigned integer
;   - DE: pointer to a C-string buffer of at least 9 bytes (8 digits plus NUL
;   terminator). This will usually be one of the OPx registers each of them
;   being 11 bytes long.
; Output:
;   - (DE): C-string representation of u32 as hexadecimal
; Destroys: A
; Preserves: BC, DE, HL
convertU32ToHexString:
    push bc
    push hl
    push de

    ld b, hexNumberWidth
convertU32ToHexStringLoop:
    ; convert to hexadecimal, but the characters are in reverse order
    ld a, (hl)
    and $0F ; last 4 bits
    call convertAToChar
    ld (de), a
    inc de
    call shiftRightLogicalU32
    call shiftRightLogicalU32
    call shiftRightLogicalU32
    call shiftRightLogicalU32
    djnz convertU32ToHexStringLoop
    xor a
    ld (de), a ; NUL termination

    ; reverse the characters
    pop hl ; HL = destination string pointer
    push hl
    ld b, hexNumberWidth
    call reverseString

    pop de
    pop hl
    pop bc
    ret

;-----------------------------------------------------------------------------
; Routines related to Octal strings.
;-----------------------------------------------------------------------------

octNumberWidth equ 11 ; 3 bits * 11 = 33 bits

; Description: Converts 32-bit unsigned integer referenced by HL to a octal
; string in buffer referenced by DE.
; Input:
;   - HL: pointer to 32-bit unsigned integer
;   - DE: pointer to a C-string buffer of at least 12 bytes (11 octal digits
;   plus NUL terminator). This will usually be 2 consecutive OPx registers,
;   each 11 bytes long, for a total of 22 bytes.
; Output:
;   - (DE): C-string representation of u32 as octal digits
; Destroys: A
; Preserves: BC, DE, HL
convertU32ToOctString:
    push bc
    push hl
    push de

    ld b, octNumberWidth
convertU32ToOctStringLoop:
    ld a, (hl)
    and $07 ; last 3 bits
    add a, '0' ; convert to octal
    ld (de), a
    inc de
    call shiftRightLogicalU32
    call shiftRightLogicalU32
    call shiftRightLogicalU32
    djnz convertU32ToOctStringLoop
    xor a
    ld (de), a ; NUL terminator

    ; reverse the octal digits
    pop hl ; HL = destination string pointer
    push hl
    ld b, octNumberWidth
    call reverseString

    pop de
    pop hl
    pop bc
    ret

;-----------------------------------------------------------------------------
; Routines related to Binary strings.
;-----------------------------------------------------------------------------

binNumberWidth equ 32

; Description: Converts 32-bit unsigned integer referenced by HL to a binary
; string in buffer referenced by DE.
; Input:
;   - HL: pointer to 32-bit unsigned integer
;   - DE: pointer to a C-string buffer of at least 33 bytes (32 binary digits
;   plus NUL terminator). This will usually be 3 consecutive OPx registers,
;   each 11 bytes long, for a total of 33 bytes.
; Output:
;   - (DE): C-string representation of u32 as binary digits
; Destroys: A
; Preserves: BC, DE, HL
convertU32ToBinString:
    push bc
    push hl
    push de

    ld b, binNumberWidth ; 14 bits maximum
convertU32ToBinStringLoop:
    ld a, (hl)
    and $01 ; last bit
    add a, '0' ; convert to '0' or '1'
    ld (de), a
    inc de
    call shiftRightLogicalU32
    djnz convertU32ToBinStringLoop
    xor a
    ld (de), a ; NUL terminator

    ; reverse the binary digits
    pop hl ; HL = destination string pointer
    push hl
    ld b, binNumberWidth
    call reverseString

    pop de
    pop hl
    pop bc
    ret

;-----------------------------------------------------------------------------
; Routines related to Dec strings (as integers).
;-----------------------------------------------------------------------------

decNumberWidth equ 10 ; 2^32 needs 10 digits

; Description: Converts 32-bit unsigned integer referenced by HL to a hex
; string in buffer referenced by DE.
; Input:
;   - HL: pointer to 32-bit unsigned integer
;   - DE: pointer to a C-string buffer of at least 11 bytes (10 digits plus NUL
;   terminator). This will usually be one of the OPx registers each of them
;   being 11 bytes long.
; Output:
;   - (DE): C-string representation of u32 as hexadecimal
; Destroys: A
; Preserves: BC, DE, HL
convertU32ToDecString:
    push bc
    push hl
    push de ; push destination buffer last
    ld b, decNumberWidth
convertU32ToDecStringLoop:
    ; convert to decimal integer, but the characters are in reverse order
    push de
    ld d, 10
    call divU32ByD ; u32(HL)=quotient, D=10, E=remainder
    ld a, e
    call convertAToChar
    pop de
    ld (de), a
    inc de
    djnz convertU32ToDecStringLoop
    xor a
    ld (de), a ; NUL termination

    ; truncate trailing '0' digits, and reverse the string
    pop hl ; HL = destination string pointer
    push hl
    ld b, decNumberWidth
    call truncateTrailingZeros ; B=length of new string
    call reverseString ; reverse the characters

    pop de
    pop hl
    pop bc
    ret

;-----------------------------------------------------------------------------

; Description: Truncate the trailing zero-digits. This assumes that the number
; is in reverse digit format, so the trailing zeros are the leading zeros. If
; the string is all '0' digits, then the final string is a string with a single
; "0".
; Input:
;   - HL=pointer to NUL terminated string
;   - B=length of string, can be 0
; Output:
;   - u32(HL)=string with truncated zeros
;   - B=new length of string
; Destroys: A, B
; Preserves: C, DE, HL
truncateTrailingZeros:
    ld a, b
    or a
    ret z
    push hl
    push de
    ld e, b
    ld d, 0
    add hl, de ; HL points to NUL at end of string
truncateTrailingZerosLoop:
    dec hl
    ld a, (hl)
    cp '0'
    jr nz, truncateTrailingZerosEnd
    djnz truncateTrailingZerosLoop
    ; If we get to here, all digits were '0', and there is only on digit
    ; remaining. So set the new length to be 1.
    inc b
truncateTrailingZerosEnd:
    inc hl
    ld (hl), 0 ; insert new NUL terminator just after the last non-zero-digit
    pop de
    pop hl
    ret

;-----------------------------------------------------------------------------

; Description: Reverses the chars of the string referenced by HL.
; Input:
;   - HL: reference to C-string
;   - B: number of characters
; Output: string in (HL) reversed
; Destroys: A, B, DE, HL
reverseString:
    ; test for 0-length string
    ld a, b
    or a
    ret z

    ld e, b
    ld d, 0
    ex de, hl
    add hl, de
    ex de, hl ; DE = DE + B = end of string
    dec de

    srl b ; B = num / 2
    ret z ; NOTE: Failing to check for this zero took 2 days to debug!
reverseStringLoop:
    ld a, (de)
    ld c, (hl)
    ld (hl), a
    ld a, c
    ld (de), a
    inc hl
    dec de
    djnz reverseStringLoop
    ret
