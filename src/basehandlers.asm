;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; BASE menu handlers.
;-----------------------------------------------------------------------------

mBaseHandler:
    push af ; preserve the C flag
    call closeInputBuf ; must call before modifying rpnFlagsBaseModeEnabled
    pop af
    jr c, mBaseHandlerOnExit
    set rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    jr mBaseHandlerEnd
mBaseHandlerOnExit:
    res rpnFlagsBaseModeEnabled, (iy + rpnFlags)
mBaseHandlerEnd:
    set dirtyFlagsBaseMode, (iy + dirtyFlags)
    set dirtyFlagsStack, (iy + dirtyFlags)
    ret

mHexHandler:
    call closeInputBuf
    ld a, 16
    jr setBaseNumber

mDecHandler:
    call closeInputBuf
    ld a, 10
    jr setBaseNumber

mOctHandler:
    call closeInputBuf
    ld a, 8
    jr setBaseNumber

mBinHandler:
    call closeInputBuf
    ld a, 2
    ; [[fallthrough]]

; Description: Set the (baseNumber) to the value in A. Set dirty flag.
; Destroys: none
setBaseNumber:
    set dirtyFlagsBaseMode, (iy + dirtyFlags)
    set dirtyFlagsStack, (iy + dirtyFlags)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ld (baseNumber), a
    ret

;-----------------------------------------------------------------------------

mDecNameSelector:
    ld b, 10
    jr mBaseNameSelector

mHexNameSelector:
    ld b, 16
    jr mBaseNameSelector

mOctNameSelector:
    ld b, 8
    jr mBaseNameSelector

mBinNameSelector:
    ld b, 2
    ; [[fallthrough]]

; Description: Select the display name of 'DEC', 'HEX', 'OCT', and 'BIN' menus.
; Input:
;   - A: nameId
;   - B: base (2, 8, 10, 16)
;   - C: altNameId
;   - HL: pointer to MenuNode
; Output:
;   - A: either A or C
; Destroys: D
mBaseNameSelector:
    ld d, a ; D=nameId, C=altNameId
    ld a, (baseNumber)
    cp b
    ld a, d
    ret nz
    ld a, c
    ret

;-----------------------------------------------------------------------------

mBitwiseAndHandler:
    call recallU32XY ; HL=OP3=u32(Y); DE=OP4=u32(X)
    call andU32U32 ; HL = OP3 = OP3 AND OP4
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

mBitwiseOrHandler:
    call recallU32XY ; HL=OP3=u32(Y); DE=OP4=u32(X)
    call orU32U32 ; HL = OP3 = OP3 OR OP4
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

mBitwiseXorHandler:
    call recallU32XY ; HL=OP3=u32(Y); DE=OP4=u32(X)
    call xorU32U32 ; HL = OP3 = OP3 XOR OP4
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

mBitwiseNotHandler:
    call recallU32X ; HL=OP3=u32(X)
    call notU32 ; OP3 = NOT(OP3)
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceX

mBitwiseNegHandler:
    call recallU32X ; HL=OP3=u32(X)
    call negU32 ; OP3 = NEG(OP3), 2's complement negation
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceX

;-----------------------------------------------------------------------------

mShiftLeftLogicalHandler:
    call recallU32X ; HL=OP3=u32(X)
    call shiftLeftLogicalU32 ; OP3 = (OP3 << 1)
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceX

mShiftRightLogicalHandler:
    call recallU32X ; HL=OP3=u32(X)
    call shiftRightLogicalU32 ; OP3 = (OP3 >> 1)
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceX

mShiftRightArithmeticHandler:
    call recallU32X ; HL=OP3=u32(X)
    call shiftRightArithmeticU32 ; OP3 = signed(OP3 >> 1)
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceX

mShiftLeftLogicalNHandler:
    call recallU32XYForN ; HL=OP3=u32(Y); DE=OP4=u32(X)
    jp z, replaceXY
mShiftLeftLogicalNLoop:
    call shiftLeftLogicalU32 ; OP3 = (OP3 << 1)
    djnz mShiftLeftLogicalNLoop
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

mShiftRightLogicalNHandler:
    call recallU32XYForN ; HL=OP3=u32(Y); DE=OP4=u32(X)
    jp z, replaceXY
mShiftRightLogicalNLoop:
    call shiftRightLogicalU32 ; OP3 = (OP3 >> 1)
    djnz mShiftRightLogicalNLoop
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

;-----------------------------------------------------------------------------

mRotateLeftCircularHandler:
    call recallU32X ; HL=OP3=u32(X)
    call rotateLeftCircularU32; OP3 = rotLeftCircular(OP3)
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceX

mRotateRightCircularHandler:
    call recallU32X ; HL=OP3=u32(X)
    call rotateRightCircularU32; OP3 = rotRightCircular(OP3)
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceX

mRotateLeftCarryHandler:
    call recallU32X ; HL=OP3=u32(X)
    call recallCarryFlag
    call rotateLeftCarryU32; OP3 = rotLeftCarry(OP3)
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceX

mRotateRightCarryHandler:
    call recallU32X ; HL=OP3=u32(X)
    call recallCarryFlag
    call rotateRightCarryU32; OP3 = rotRightCarry(OP3)
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceX

mRotateLeftCircularNHandler:
    call recallU32XYForN ; HL=OP3=u32(Y); DE=OP4=u32(X)
    jp z, replaceXY
mRotateLeftCircularNLoop:
    call rotateLeftCircularU32; OP3 = rotLeftCircular(OP3)
    djnz mRotateLeftCircularNLoop
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

mRotateRightCircularNHandler:
    call recallU32XYForN ; HL=OP3=u32(Y); DE=OP4=u32(X)
    jp z, replaceXY
mRotateRightCircularNLoop:
    call rotateRightCircularU32; OP3 = rotRightCircular(OP3)
    djnz mRotateRightCircularNLoop
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

mRotateLeftCarryNHandler:
    call recallU32XYForN ; HL=OP3=u32(Y); DE=OP4=u32(X)
    jp z, replaceXY
    call recallCarryFlag
mRotateLeftCarryNLoop:
    call rotateLeftCarryU32; OP3 = rotLeftCarry(OP3)
    djnz mRotateLeftCarryNLoop
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

mRotateRightCarryNHandler:
    call recallU32XYForN ; HL=OP3=u32(Y); DE=OP4=u32(X)
    jp z, replaceXY
    call recallCarryFlag
mRotateRightCarryNLoop:
    call rotateRightCarryU32; HL=OP3=rotRightCarry(OP3)
    djnz mRotateRightCarryNLoop
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

;-----------------------------------------------------------------------------

; Description: Recall X and convert into a u32 integer.
; Input: X
; Output:
;   - OP3=u32(X)
;   - HL=OP3
; Destroys: A, BC, DE, HL
recallU32X:
    call closeInputAndRecallX ; OP1=X
    ld hl, OP3
    call convertOP1ToU32 ; OP3=u32(X)
    ret

; Description: Recall X and Y and convert them into u32 integers.
; Input: X, Y
; Output:
;   - HL=OP3=u32(Y)
;   - DE=OP4=u32(X)
; Destroys: A, BC, DE, HL
recallU32XY:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    ld hl, OP3
    call convertOP1ToU32 ; OP3=u32(Y)
    ld hl, OP4
    call convertOP2ToU32 ; OP4=u32(X)
    ld hl, OP3
    ld de, OP4
    ret

; Description: Recall X and Y for SLn, SRn, RLn, RRn, RLCn, RRCn. Verify that X
; (i.e. n) is an integer between [0, WSIZE).
; Input: X, Y
; Output:
;   - HL=OP3=u32(Y)
;   - DE=OP4=u32(X)
;   - A=B=U8(X), verified to be an int in [0, WSIZE).
;   - ZF=1 if B==0
; Destroys: A, BC, DE, HL
recallU32XYForN:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    ld hl, OP3
    call convertOP1ToU32 ; OP3=u32(Y)
    ld hl, OP4
    call convertOP2ToU32 ; OP4=u32(X)
    ld a, (baseWordSize)
    call cmpU32U8
    jr nc, recallU32XYForNError
    ld hl, OP3
    ld de, OP4
    ld b, a ; B=u8(X)
    or a ; set ZF=1 if u8(X)==0
    ret
recallU32XYForNError:
    bjump(_ErrDomain) ; throw exception if X >= baseWordSize

;-----------------------------------------------------------------------------

; Description: Transfer the carry flag (CF) to bit 0 of (baseCarryFlag).
; Input: CF
; Output: (baseCarryFlag)
; Destroys: A
storeCarryFlag:
    rla ; shift CF into bit-0
    and $1
    ld (baseCarryFlag), a
    set dirtyFlagsBaseMode, (iy + dirtyFlags)
    ret

; Description: Transfer bit 0 of (baseCarryFlag) into the carry flag CF.
; Input: (baseCarryFlag)
; Output: CF
; Destroys: A
recallCarryFlag:
    ld a, (baseCarryFlag)
    rra ; shift bit 0 into CF
    ret

mClearCarryFlagHandler:
    or a ; CF=0
    call storeCarryFlag
    ret

mSetCarryFlagHandler:
    scf ; CF=1
    call storeCarryFlag
    ret

mGetCarryFlagHandler:
    call closeInputBuf
    set dirtyFlagsBaseMode, (iy + dirtyFlags)
    call recallCarryFlag
    jr c, mGetCarryFlagHandlerPush1
    bcall(_OP1Set0)
    jp pushX
mGetCarryFlagHandlerPush1:
    bcall(_OP1Set1)
    jp pushX

;-----------------------------------------------------------------------------

mSetWordSizeHandler:
    jp mNotYetHandler

mGetWordSizeHandler:
    call closeInputBuf
    ld a, (baseWordSize)
    call convertU8ToOP1
    jp pushX

;-----------------------------------------------------------------------------

mBitwiseAddHandler:
    call recallU32XY ; HL=OP3=u32(Y); DE=OP4=u32(X)
    call addU32U32 ; OP3(Y) += OP4(X)
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

mBitwiseSubtHandler:
    call recallU32XY ; HL=OP3=u32(Y); DE=OP4=u32(X)
    call subU32U32 ; OP3(Y) -= OP4(X)
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

mBitwiseMultHandler:
    call recallU32XY ; HL=OP3=u32(Y); DE=OP4=u32(X)
    call multU32U32 ; OP3(Y) *= OP4(X)
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

; Description: Calculate bitwise x/y.
; Output:
;   - X=quotient
;   - remainder thrown away
mBitwiseDivHandler:
    call baseDivHandlerCommon ; HL=quotient, BC=remainder
    call convertU32ToOP1 ; OP1 = quotient
    jp replaceXY

; Description: Calculate bitwise div(x, y) -> (y/x, y % x).
; Output:
;   - X=remainder
;   - Y=quotient
mBitwiseDiv2Handler:
    call baseDivHandlerCommon ; HL=quotient, BC=remainder
    ; convert remainder into OP2
    push hl
    ld l, c
    ld h, b
    call convertU32ToOP1 ; OP1=remainder
    bcall(_OP1ToOP2) ; OP2=remainder
    ; convert quotient into OP1
    pop hl
    call convertU32ToOP1 ; OP1 = quotient
    jp replaceXYWithOP1OP2 ; Y=quotient, X=remainder

baseDivHandlerCommon:
    call recallU32XY ; HL=OP3=u32(Y); DE=OP4=u32(X)
    ex de, hl ; HL=OP4
    call testU32 ; check if X==0
    ex de, hl
    jr z,  baseDivHandlerDivByZero
    ld bc, OP5 ; BC=remainder
    call divU32U32 ; HL=OP3=quotient, DE=OP4=divisor, BC=OP5=remainder
    jp storeCarryFlag ; CF=0 always
baseDivHandlerDivByZero:
    bjump(_ErrDivBy0) ; throw 'Div By 0' exception

;-----------------------------------------------------------------------------

mReverseBitHandler:
    call recallU32X ; HL=OP3=u32(X)
    call reverseU32
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceX

mCountBitHandler:
    call recallU32X ; HL=OP3=u32(X)
    call countU32Bits
    call setU32ToA
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceX

mSetBitHandler:
    call recallU32XYForN ; HL=OP3=u32(Y); DE=OP4=u32(X)
    ld a, (de)
    ld c, a
    call setU32Bit
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

mClearBitHandler:
    call recallU32XYForN ; HL=OP3=u32(Y); DE=OP4=u32(X)
    ld a, (de)
    ld c, a
    call clearU32Bit
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

mGetBitHandler:
    call recallU32XYForN ; HL=OP3=u32(Y); DE=OP4=u32(X)
    ld a, (de)
    ld c, a
    call getU32Bit
    call convertU8ToOP1
    jp replaceXY
