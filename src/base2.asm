;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Routines to convert between TI-OS floating point numbers in OP1 or OP2
; to the u32 integers required by the BASE functions in integer32.asm.
;
; Capitalized labels are intended to be exported to the branch table on flash
; page 0. Lowercased labels are intended to be local to the current flash page.
;-----------------------------------------------------------------------------

InitBase:
    res rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ld a, 10
    ld (baseNumber), a
    xor a
    ld (baseCarryFlag), a
    ld a, 32
    ld (baseWordSize), a
    ret

;-----------------------------------------------------------------------------
; Helper routines related to baseWordSize.
;-----------------------------------------------------------------------------

; Description: Truncate the u32(HL) to the number of bits given by
; (baseWordSize).
; Input:
;   - HL:(u32*)=input
;   - (baseWordSize)=8, 16, 24, 32
; Output:
;   - HL=(u32*) or (u24*) or (u16*) or (u8)
; Destroys: A
; Preserves: HL
truncToWordSize:
    push hl
    inc hl
    inc hl
    inc hl
    call getWordSizeIndex
    sub 3
    neg ; [u8,u16,u24,u32] -> [3,2,1,0]
    jr truncToWordSizeEntry
truncToWordSizeLoop:
    ld (hl), 0
    dec hl
    dec a
truncToWordSizeEntry:
    jr nz, truncToWordSizeLoop
truncWordSizeExit:
    pop hl
    ret

;-----------------------------------------------------------------------------
; Entry points of BASE operations from basehandlers.asm. This layer knows about
; OP1, OP2, and baseWordSize. It calls down to integer32.asm which contains
; low-level routines which are independent of TI-OS related parameters.
;
; TODO: We should be able to move base.asm and integer32.asm together into a
; different flash page.
;-----------------------------------------------------------------------------

; Description: Calculate the bitwise-and between the integers in OP1 and OP2.
; Input: OP1, OP2
; Output: OP1: result as a floating number
BitwiseAnd:
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
BitwiseOr:
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
BitwiseXor:
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
BitwiseNot:
    call convertOP1ToUxx ; HL=OP3=u32(OP1)
    call truncToWordSize
    call notU32 ; OP3=NOT(OP3)
    call truncToWordSize
    jp convertU32ToOP1 ; OP1=float(OP3)

; Description: Calculate the bitwise-neg of OP1
; Input: OP1
; Output: OP1: result as a floating number
BitwiseNeg:
    call convertOP1ToUxx ; HL=OP3=u32(OP1)
    call truncToWordSize
    call negU32 ; OP3=NEG(OP3)
    call truncToWordSize
    jp convertU32ToOP1 ; OP1=float(OP3)

;-----------------------------------------------------------------------------

BaseShiftLeftLogical:
    call convertOP1ToUxx ; HL=OP3=u32(OP1)
    call shiftLeftLogicalUxx ; OP3=shiftLeftLogical(OP3)
    call storeCarryFlag
    jp convertU32ToOP1 ; OP1=float(OP3)

; Description: Call the appropriate shiftLeftLogicalLeftUXX() depending on
; (baseWordSize).
; Input:
;   - HL:(u32*)=input
; Output:
;   - (*HL) shifted left
;   - CF=bit 7 of the most significant byte of input
; Destroys: A
shiftLeftLogicalUxx:
    call getWordSizeIndex
    or a
    jp z, shiftLeftLogicalU8
    dec a
    jp z, shiftLeftLogicalU16
    dec a
    jp z, shiftLeftLogicalU24
    jp shiftLeftLogicalU32

;-----------------------------------------------------------------------------

BaseShiftRightLogical:
    call convertOP1ToUxx ; HL=OP3=u32(OP1)
    call shiftRightLogicalUxx ; OP3=shiftRightLogical(OP3)
    call storeCarryFlag
    jp convertU32ToOP1 ; OP1=float(OP3)

; Description: Call the appropriate shiftRightLogicalUXX() depending on
; (baseWordSize).
; Input:
;   - HL:(u32*)=input
; Output:
;   - (*HL) shifted right
;   - CF=bit 0 of the least signficant byte of input
; Destroys: A
shiftRightLogicalUxx:
    call getWordSizeIndex
    or a
    jp z, shiftRightLogicalU8
    dec a
    jp z, shiftRightLogicalU16
    dec a
    jp z, shiftRightLogicalU24
    jp shiftRightLogicalU32

;-----------------------------------------------------------------------------

BaseShiftRightArithmetic:
    call convertOP1ToUxx ; HL=OP3=u32(OP1)
    call shiftRightArithmeticUxx ; OP3=shiftRightArithmetic(OP3)
    call storeCarryFlag
    jp convertU32ToOP1 ; OP1=float(OP3)

; Description: Call the appropriate shiftRightArithmeticUXX() depending on
; (baseWordSize).
; Input:
;   - HL:(u32*)=input
; Output:
;   - (*HL) shifted right
;   - CF=bit 0 of the least signficant byte of input
; Destroys: A
shiftRightArithmeticUxx:
    call getWordSizeIndex
    or a
    jp z, shiftRightArithmeticU8
    dec a
    jp z, shiftRightArithmeticU16
    dec a
    jp z, shiftRightArithmeticU24
    jp shiftRightArithmeticU32

;-----------------------------------------------------------------------------

BaseShiftLeftLogicalN:
    call convertOP1OP2ToUxxN ; HL=OP3=u32(OP1); A=u8(OP2); ZF=1 if A==0
    ret z
    ld b, a
baseShiftLeftLogicalNLoop:
    call shiftLeftLogicalUxx; (OP3)=shiftLeftLogical(OP3)
    djnz baseShiftLeftLogicalNLoop
    call storeCarryFlag
    jp convertU32ToOP1 ; OP1=float(OP3)

;-----------------------------------------------------------------------------

BaseShiftRightLogicalN:
    call convertOP1OP2ToUxxN ; HL=OP3=u32(OP1); A=u8(OP2); ZF=1 if A==0
    ret z
    ld b, a
baseShiftRightLogicalNLoop:
    call shiftRightLogicalUxx; (OP3)=shiftRightLogical(OP3)
    djnz baseShiftRightLogicalNLoop
    call storeCarryFlag
    jp convertU32ToOP1 ; OP1=float(OP3)

;-----------------------------------------------------------------------------

BaseRotateLeftCircular:
    call convertOP1ToUxx ; HL=OP3=u32(OP1)
    call rotateLeftCircularUxx ; OP3=rotateLeftCircular(OP3)
    call storeCarryFlag
    jp convertU32ToOP1 ; OP1=float(OP3)

; Description: Call the appropriate rotateLeftCircularUXX() depending on
; (baseWordSize).
; Input:
;   - HL:(u32*)=input
; Output:
;   - (*HL) rotated left
;   - CF=bit 7 of most significant byte of input
; Destroys: A
rotateLeftCircularUxx:
    call getWordSizeIndex
    or a
    jp z, rotateLeftCircularU8
    dec a
    jp z, rotateLeftCircularU16
    dec a
    jp z, rotateLeftCircularU24
    jp rotateLeftCircularU32

;-----------------------------------------------------------------------------

BaseRotateRightCircular:
    call convertOP1ToUxx ; HL=OP3=u32(OP1)
    call rotateRightCircularUxx ; OP3=rotateRightCircular(OP3)
    call storeCarryFlag
    jp convertU32ToOP1 ; OP1=float(OP3)

; Description: Call the appropriate rotateRightCircularUXX() depending on
; (baseWordSize).
; Input:
;   - HL:(u32*)=input
; Output:
;   - (*HL) rotated right
;   - CF=bit 0 of least significant byte of input
; Destroys: A
rotateRightCircularUxx:
    call getWordSizeIndex
    or a
    jp z, rotateRightCircularU8
    dec a
    jp z, rotateRightCircularU16
    dec a
    jp z, rotateRightCircularU24
    jp rotateRightCircularU32

;-----------------------------------------------------------------------------

BaseRotateLeftCarry:
    call convertOP1ToUxx ; HL=OP3=u32(OP1)
    call recallCarryFlag ; CF=(baseCarryFlag)
    call rotateLeftCarryUxx ; OP3=rotateLeftCarry(OP3)
    call storeCarryFlag ; (baseCarryFlag)=CF
    jp convertU32ToOP1 ; OP1=float(OP3)

; Description: Call the appropriate rotateLeftCarryUXX() depending on
; (baseWordSize).
; Input:
;   - HL:(u32*)=input
;   - CF=existing carry flag
; Output:
;   - (*HL) rotated left
;   - CF=most significant bit of the input
; Destroys: A, C
rotateLeftCarryUxx:
    rl c ; save CF
    call getWordSizeIndex
    or a
    jp z, rotateLeftCarryU8Alt
    dec a
    jp z, rotateLeftCarryU16Alt
    dec a
    jp z, rotateLeftCarryU24Alt
    call rotateLeftCarryU32Alt

;-----------------------------------------------------------------------------

BaseRotateRightCarry:
    call convertOP1ToUxx ; HL=OP3=u32(OP1)
    call recallCarryFlag ; CF=(baseCarryFlag)
    call rotateRightCarryUxx ; OP3=rotateRightCarry(OP3)
    call storeCarryFlag ; (baseCarryFlag)=CF
    jp convertU32ToOP1 ; OP1=float(OP3)

; Description: Call the appropriate rotateRightCarryUXX() depending on
; (baseWordSize).
; Input:
;   - HL:(u32*)=input
;   - CF=existing carry flag
; Output:
;   - (*HL) rotated right
;   - CF=the least significant bit of input
; Destroys: A, C
rotateRightCarryUxx:
    rl c ; save CF
    call getWordSizeIndex
    or a
    jp z, rotateRightCarryU8Alt
    dec a
    jp z, rotateRightCarryU16Alt
    dec a
    jp z, rotateRightCarryU24Alt
    call rotateRightCarryU32Alt

;-----------------------------------------------------------------------------

BaseRotateLeftCircularN:
    call convertOP1OP2ToUxxN ; HL=OP3=u32(OP1); A=u8(OP2); ZF=1 if A==0
    ret z
    ld b, a
    call recallCarryFlag ; CF=(baseCarryFlag)
baseRotateLeftCircularNLoop:
    call rotateLeftCircularUxx ; OP3=rotateLeftCircular(OP3)
    djnz baseRotateLeftCircularNLoop
    call storeCarryFlag
    jp convertU32ToOP1 ; OP1=float(OP3)

;-----------------------------------------------------------------------------

BaseRotateRightCircularN:
    call convertOP1OP2ToUxxN ; HL=OP3=u32(OP1); A=u8(OP2); ZF=1 if A==0
    ret z
    ld b, a
    call recallCarryFlag ; CF=(baseCarryFlag)
baseRotateRightCircularNLoop:
    call rotateRightCircularUxx ; OP3=rotateRightCircular(OP3)
    djnz baseRotateRightCircularNLoop
    call storeCarryFlag
    jp convertU32ToOP1 ; OP1=float(OP3)

;-----------------------------------------------------------------------------

BaseRotateLeftCarryN:
    call convertOP1OP2ToUxxN ; HL=OP3=u32(OP1); A=u8(OP2); ZF=1 if A==0
    ret z
    ld b, a
    call recallCarryFlag ; CF=(baseCarryFlag)
baseRotateLeftCarryNLoop:
    call rotateLeftCarryUxx ; OP3=rotateLeftCarry(OP3)
    djnz baseRotateLeftCarryNLoop
    call storeCarryFlag
    jp convertU32ToOP1 ; OP1=float(OP3)

;-----------------------------------------------------------------------------

BaseRotateRightCarryN:
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

BaseAdd:
    call convertOP1OP2ToUxx ; HL=OP3=u32(OP1); DE=OP4=u32(OP2)
    call truncToWordSize
    call addUxxUxx ; OP3+=OP4
    call storeCarryFlag
    call truncToWordSize
    jp convertU32ToOP1 ; OP1=float(OP3)

; Description: Call the appropriate addUxxUxx() depending on (baseWordSize).
; Input:
;   - HL:(u32*)
;   - DE:(const u32*)
; Output:
;   - (*HL)+=(*DE)
;   - CF updated
; Destroys: A
; Preserves: BC, DE, HL, (DE)
addUxxUxx:
    call getWordSizeIndex
    or a
    jp z, addU8U8
    dec a
    jp z, addU16U16
    dec a
    jp z, addU24U24
    jp addU32U32

;-----------------------------------------------------------------------------

BaseSub:
    call convertOP1OP2ToUxx ; HL=OP3=u32(OP1); DE=OP4=u32(OP2)
    call truncToWordSize
    call subUxxUxx ; OP3-=OP4
    call storeCarryFlag
    call truncToWordSize
    jp convertU32ToOP1 ; OP1=float(OP3)

; Description: Call the appropriate subUxxUxx() dependingon (baseWordSize).
; Input:
;   - HL:(u32*)
;   - DE:(const u32*)
; Output:
;   - (*HL)-=(*DE)
;   - CF updated
; Destroys: A
; Preserves: BC, DE, HL, (DE)
subUxxUxx:
    call getWordSizeIndex
    or a
    jp z, subU8U8
    dec a
    jp z, subU16U16
    dec a
    jp z, subU24U24
    jp subU32U32

;-----------------------------------------------------------------------------

BaseMult:
    call convertOP1OP2ToUxx ; HL=OP3=u32(OP1); DE=OP4=u32(OP2)
    call truncToWordSize
    call multUxxUxx ; OP3*=OP4
    call storeCarryFlag
    call truncToWordSize
    jp convertU32ToOP1 ; OP1=float(OP3)

; Description: Call the appropriate multUxxUxx() depending on (baseWordSize).
; Input:
;   - HL:(u32*)
;   - DE:(const u32*)
; Output:
;   - HL*=DE
;   - CF: carry flag set if result overflowed U32
; Destroys: A, IX
; Preserves: BC, DE, HL, (DE)
multUxxUxx:
    call getWordSizeIndex
    or a
    jp z, multU8U8
    dec a
    jp z, multU16U16
    dec a
    jp z, multU24U24
    jp multU32U32

;-----------------------------------------------------------------------------

; Input:
;   - OP1=dividend
;   - OP2=divisor
; Output: OP1=quotient
BaseDiv:
    call baseDivCommon
    jp convertU32ToOP1 ; OP1=quotient(OP3)

; Input:
;   - OP1=dividend
;   - OP2=divisor
; Output: OP1=remainder; OP2=quotient
BaseDiv2:
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
    call divU32U32 ; HL=OP3=quotient, DE=OP4=divisor, BC=OP5=remainder
    call storeCarryFlag ; CF=0 always
    jp truncToWordSize
baseDivByZeroErr:
    bcall(_ErrDivBy0) ; throw 'Div By 0' exception

;-----------------------------------------------------------------------------

BaseReverseBits:
    call convertOP1ToUxx ; HL=OP3=u32(OP1)
    call truncToWordSize
    call reverseUxxBits
    jp convertU32ToOP1 ; OP1 = float(OP3)

; Description: Call the appropriate reverseUXX() depending on the
; (baseWordSize).
; Input: HL:(u32*)=input
; Output: (*HL)=reverseBits(*HL)
; Destroys: A, BC
; Preserves: HL, DE
reverseUxxBits:
    call getWordSizeIndex
    or a
    jp z, reverseU8Bits
    dec a
    jp z, reverseU16Bits
    dec a
    jp z, reverseU24Bits
    jp reverseU32Bits

;-----------------------------------------------------------------------------

BaseCountBits:
    call convertOP1ToUxx ; HL=OP3=u32(OP1)
    call truncToWordSize
    call countU32Bits ; A=countBits(OP3)
    bcall(_ConvertAToOP1) ; OP1=float(A)
    ret

;-----------------------------------------------------------------------------

BaseSetBit:
    call convertOP1OP2ToUxxN ; HL=OP3=u32(OP1); A=u8(OP2); ZF=1 if A==0
    ld c, a
    call setU32Bit ; OP3=setBit(OP3,C)
    jp convertU32ToOP1 ; OP1=float(OP3)

;-----------------------------------------------------------------------------

BaseClearBit:
    call convertOP1OP2ToUxxN ; HL=OP3=u32(OP1); A=u8(OP2); ZF=1 if A==0
    ld c, a
    call clearU32Bit ; OP3=clearBit(OP3,C)
    jp convertU32ToOP1 ; OP1=float(OP3)

;-----------------------------------------------------------------------------

BaseGetBit:
    call convertOP1OP2ToUxxN ; HL=OP3=u32(OP1); A=u8(OP2); ZF=1 if A==0
    ld c, a
    call getU32Bit ; A=1 or 0
    bcall(_ConvertAToOP1) ; OP1=float(A)
    ret

;-----------------------------------------------------------------------------
; Recall and store the Carry Flag.
;-----------------------------------------------------------------------------

; Description: Transfer CF to bit 0 of (baseCarryFlag).
; Input: CF
; Output: (baseCarryFlag)
; Destroys: A
BaseStoreCarryFlag:
storeCarryFlag:
    rla ; shift CF into bit-0
    and $1
    ld (baseCarryFlag), a
    set dirtyFlagsStatus, (iy + dirtyFlags)
    ret

; Description: Return the baseCarryFlag as OP1.
; Input: (baseCarryFlag)
; Output: OP1=flaot(baseCarryFlag)
BaseGetCarryFlag:
    call recallCarryFlag
    jr c, baseGetCarryFlagSet1
    bcall(_OP1Set0)
    ret
baseGetCarryFlagSet1:
    bcall(_OP1Set1)
    ret

; Description: Transfer bit 0 of (baseCarryFlag) into CF.
; Input: (baseCarryFlag)
; Output: CF
; Destroys: A
recallCarryFlag:
    ld a, (baseCarryFlag)
    rra ; shift bit 0 into CF
    ret

;-----------------------------------------------------------------------------
; Word size operations.
;-----------------------------------------------------------------------------

; Description: Set the (baseWordSize) to A. Throws Err:Argument if A is not one
; of (8, 16, 24, 32).
; Input: A=new wordSize
; Output: (baseWordSize)=A
; Destroys: none
BaseSetWordSize:
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
BaseGetWordSize:
    ld a, (baseWordSize)
    bcall(_ConvertAToOP1) ; OP1=float(A)
    ret
