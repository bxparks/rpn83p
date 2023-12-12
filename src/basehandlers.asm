;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; BASE menu handlers.
;-----------------------------------------------------------------------------

; Description: Group handler for BASE menu group.
; Input:
;   - CF=1: handle onExit() event
;   - CF=0: handle onEnter() event
mBaseHandler:
    push af ; preserve the C flag
    ; must call closeInputXxx() before modifying rpnFlagsBaseModeEnabled
    call closeInputAndRecallNone
    pop af
    jr c, mBaseHandlerOnExit
    ; handle onEnter()
    set rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    jr mBaseHandlerEnd
mBaseHandlerOnExit:
    ; handle onExit()
    res rpnFlagsBaseModeEnabled, (iy + rpnFlags)
mBaseHandlerEnd:
    set dirtyFlagsStatus, (iy + dirtyFlags)
    set dirtyFlagsStack, (iy + dirtyFlags)
    ret

mHexHandler:
    call closeInputAndRecallNone
    ld a, 16
    jr setBaseNumber

mDecHandler:
    call closeInputAndRecallNone
    ld a, 10
    jr setBaseNumber

mOctHandler:
    call closeInputAndRecallNone
    ld a, 8
    jr setBaseNumber

mBinHandler:
    call closeInputAndRecallNone
    ld a, 2
    ; [[fallthrough]]

; Description: Set the (baseNumber) to the value in A. Set various dirty flags.
; Destroys: none
setBaseNumber:
    set dirtyFlagsStatus, (iy + dirtyFlags)
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

; Description: Dispatch to the appropriate handler for the current baseWordSize.
; Input:
;   - HL: pointer to handlers (usually 4 entries)
;   - (baseWordSize): current word size, 8, 16, 24, 32
; Output:
;   - jumps to the appropriate handler (can be invoked using a 'call')
;   - throws exception if (baseWordSize) is not validf
; Destroys: A
;baseDispatcher:
;    call getWordSizeIndex
;    ld e, a
;    ld d, 0
;    add hl, de
;    ld a, (hl)
;    inc hl
;    ld h, (hl)
;    ld l, a ; HL=(HL+baseOffset)
;    jp (hl)

;-----------------------------------------------------------------------------

mBitwiseAndHandler:
    call recallXYAsU32 ; HL=OP3=u32(Y); DE=OP4=u32(X)
    call truncToWordSize
    ex de, hl
    call truncToWordSize
    ex de, hl
    call andU32U32 ; HL = OP3 = OP3 AND OP4
    call truncToWordSize
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

;-----------------------------------------------------------------------------

mBitwiseOrHandler:
    call recallXYAsU32 ; HL=OP3=u32(Y); DE=OP4=u32(X)
    call truncToWordSize
    ex de, hl
    call truncToWordSize
    ex de, hl
    call orU32U32 ; HL = OP3 = OP3 OR OP4
    call truncToWordSize
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

mBitwiseXorHandler:
    call recallXYAsU32 ; HL=OP3=u32(Y); DE=OP4=u32(X)
    call truncToWordSize
    ex de, hl
    call truncToWordSize
    ex de, hl
    call xorU32U32 ; HL = OP3 = OP3 XOR OP4
    call truncToWordSize
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

mBitwiseNotHandler:
    call recallXAsU32 ; HL=OP3=u32(X)
    call truncToWordSize
    call notU32 ; OP3 = NOT(OP3)
    call truncToWordSize
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceX

mBitwiseNegHandler:
    call recallXAsU32 ; HL=OP3=u32(X)
    call truncToWordSize
    call negU32 ; OP3 = NEG(OP3), 2's complement negation
    call truncToWordSize
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceX

;-----------------------------------------------------------------------------

mShiftLeftLogicalHandler:
    call recallXAsU32 ; HL=OP3=u32(X)
    call shiftLeftLogical ; OP3 = (OP3 << 1)
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceX

mShiftRightLogicalHandler:
    call recallXAsU32 ; HL=OP3=u32(X)
    call shiftRightLogical ; OP3 = (OP3 >> 1)
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceX

mShiftRightArithmeticHandler:
    call recallXAsU32 ; HL=OP3=u32(X)
    call shiftRightArithmetic ; OP3 = signed(OP3 >> 1)
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceX

mShiftLeftLogicalNHandler:
    call recallXYAsU32N ; HL=OP3=u32(Y); DE=OP4=u32(X)
    jp z, replaceXY
mShiftLeftLogicalNLoop:
    call shiftLeftLogical ; OP3 = (OP3 << 1)
    djnz mShiftLeftLogicalNLoop
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

mShiftRightLogicalNHandler:
    call recallXYAsU32N ; HL=OP3=u32(Y); DE=OP4=u32(X)
    jp z, replaceXY
mShiftRightLogicalNLoop:
    call shiftRightLogical ; OP3 = (OP3 >> 1)
    djnz mShiftRightLogicalNLoop
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

;-----------------------------------------------------------------------------

mRotateLeftCircularHandler:
    call recallXAsU32 ; HL=OP3=u32(X)
    call rotateLeftCircular; OP3 = rotLeftCircular(OP3)
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceX

mRotateRightCircularHandler:
    call recallXAsU32 ; HL=OP3=u32(X)
    call rotateRightCircular; OP3 = rotRightCircular(OP3)
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceX

mRotateLeftCarryHandler:
    call recallXAsU32 ; HL=OP3=u32(X)
    call recallCarryFlag
    call rotateLeftCarry; OP3 = rotLeftCarry(OP3)
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceX

mRotateRightCarryHandler:
    call recallXAsU32 ; HL=OP3=u32(X)
    call recallCarryFlag
    call rotateRightCarry; OP3 = rotRightCarry(OP3)
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceX

mRotateLeftCircularNHandler:
    call recallXYAsU32N ; HL=OP3=u32(Y); DE=OP4=u32(X)
    jp z, replaceXY
mRotateLeftCircularNLoop:
    call rotateLeftCircular; OP3 = rotLeftCircular(OP3)
    djnz mRotateLeftCircularNLoop
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

mRotateRightCircularNHandler:
    call recallXYAsU32N ; HL=OP3=u32(Y); DE=OP4=u32(X)
    jp z, replaceXY
mRotateRightCircularNLoop:
    call rotateRightCircular; OP3 = rotRightCircular(OP3)
    djnz mRotateRightCircularNLoop
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

mRotateLeftCarryNHandler:
    call recallXYAsU32N ; HL=OP3=u32(Y); DE=OP4=u32(X)
    jp z, replaceXY
    call recallCarryFlag
mRotateLeftCarryNLoop:
    call rotateLeftCarry; OP3 = rotLeftCarry(OP3)
    djnz mRotateLeftCarryNLoop
    call storeCarryFlag
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

mRotateRightCarryNHandler:
    call recallXYAsU32N ; HL=OP3=u32(Y); DE=OP4=u32(X)
    jp z, replaceXY
    call recallCarryFlag
mRotateRightCarryNLoop:
    call rotateRightCarry; HL=OP3=rotRightCarry(OP3)
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
;   - throws Err:Domain if X is not an integer in [0, 2^32)
; Destroys: A, BC, DE, HL
recallXAsU32:
    call closeInputAndRecallX ; OP1=X
    ld hl, OP3
    call convertOP1ToU32AllowFrac ; OP3=u32(X)
    ret

; Description: Recall X and Y and convert them into u32 integers.
; Input: X, Y
; Output:
;   - HL=OP3=u32(Y)
;   - DE=OP4=u32(X)
; Destroys: A, BC, DE, HL
recallXYAsU32:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    ld hl, OP3
    call convertOP1ToU32AllowFrac ; OP3=u32(Y)
    ld hl, OP4
    call convertOP2ToU32AllowFrac ; OP4=u32(X)
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
recallXYAsU32N:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    ld hl, OP3
    call convertOP1ToU32AllowFrac ; OP3=u32(Y)
    ld hl, OP4
    call convertOP2ToU32AllowFrac ; OP4=u32(X)
    ld a, (baseWordSize)
    call cmpU32U8
    jr nc, recallXYAsU32NError
    ld hl, OP3
    ld de, OP4
    ld b, a ; B=u8(X)
    or a ; set ZF=1 if u8(X)==0
    ret
recallXYAsU32NError:
    bcall(_ErrDomain) ; throw exception if X >= baseWordSize

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

mClearCarryFlagHandler:
    or a ; CF=0
    jr storeCarryFlag

mSetCarryFlagHandler:
    scf ; CF=1
    jr storeCarryFlag

mGetCarryFlagHandler:
    call closeInputAndRecallNone
    set dirtyFlagsStatus, (iy + dirtyFlags)
    call recallCarryFlag
    jr c, mGetCarryFlagHandlerPush1
    bcall(_OP1Set0)
    jp pushX
mGetCarryFlagHandlerPush1:
    bcall(_OP1Set1)
    jp pushX

;-----------------------------------------------------------------------------

; Description: Prompt for the new base word size, like FIX or STO. Allowed
; values are 8, 16, 24, 32. Throw Err:Argument if outside of that list.
mSetWordSizeHandler:
    call closeInputAndRecallNone
    ld hl, msgWordSizePrompt
    call startArgParser
    call processArgCommands ; CF=0 if canceled; (argModified), (argValue)
    ret nc ; do nothing if canceled
    ld a, (argValue)
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

msgWordSizePrompt:
    .db "WSIZ", 0

mGetWordSizeHandler:
    call closeInputAndRecallNone
    ld a, (baseWordSize)
    bcall(_ConvertAToOP1PageOne)
    jp pushX

;-----------------------------------------------------------------------------

mBitwiseAddHandler:
    call recallXYAsU32 ; HL=OP3=u32(Y); DE=OP4=u32(X)
    call truncToWordSize
    call addUxxUxx ; OP3(Y) += OP4(X)
    call storeCarryFlag
    call truncToWordSize
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

mBitwiseSubtHandler:
    call recallXYAsU32 ; HL=OP3=u32(Y); DE=OP4=u32(X)
    call truncToWordSize
    call subUxxUxx ; OP3(Y) -= OP4(X)
    call storeCarryFlag
    call truncToWordSize
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

mBitwiseMultHandler:
    call recallXYAsU32 ; HL=OP3=u32(Y); DE=OP4=u32(X)
    call truncToWordSize
    call multUxxUxx ; OP3(Y) *= OP4(X)
    call storeCarryFlag
    call truncToWordSize
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
    push bc
    ; convert HL=quotient into OP2
    call convertU32ToOP1
    bcall(_OP1ToOP2) ; OP2=quotient
    ; convert BC=remainder into OP1
    pop hl
    call convertU32ToOP1 ; OP1=remainder
    jp replaceXYWithOP1OP2 ; Y=remainder, X=quotient

; Output:
;   - HL=quotient
;   - BC=remainder
baseDivHandlerCommon:
    call recallXYAsU32 ; HL=OP3=u32(Y); DE=OP4=u32(X)
    call truncToWordSize
    ex de, hl ; HL=OP4
    call testU32 ; check if X==0
    ex de, hl
    jr z,  baseDivHandlerDivByZero
    ld bc, OP5 ; BC=remainder
    call divUxxUxx ; HL=OP3=quotient, DE=OP4=divisor, BC=OP5=remainder
    call storeCarryFlag ; CF=0 always
    call truncToWordSize
    ret
baseDivHandlerDivByZero:
    bcall(_ErrDivBy0) ; throw 'Div By 0' exception

;-----------------------------------------------------------------------------

mReverseBitHandler:
    call recallXAsU32 ; HL=OP3=u32(X)
    call truncToWordSize
    call reverseBits
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceX

mCountBitHandler:
    call recallXAsU32 ; HL=OP3=u32(X)
    call truncToWordSize
    call countU32Bits
    call setU32ToA
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceX

mSetBitHandler:
    call recallXYAsU32N ; HL=OP3=u32(Y); DE=OP4=u32(X)
    ld a, (de)
    ld c, a
    call setU32Bit
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

mClearBitHandler:
    call recallXYAsU32N ; HL=OP3=u32(Y); DE=OP4=u32(X)
    ld a, (de)
    ld c, a
    call clearU32Bit
    call convertU32ToOP1 ; OP1 = float(OP3)
    jp replaceXY

mGetBitHandler:
    call recallXYAsU32N ; HL=OP3=u32(Y); DE=OP4=u32(X)
    ld a, (de)
    ld c, a
    call getU32Bit
    bcall(_ConvertAToOP1PageOne)
    jp replaceXY
