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
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    call bitwiseAnd ; OP1=X AND Y
    jp replaceXY

mBitwiseOrHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    call bitwiseOr ; OP1=X OR Y
    jp replaceXY

mBitwiseXorHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    call bitwiseXor ; OP1=X XOR Y
    jp replaceXY

mBitwiseNotHandler:
    call closeInputAndRecallX ; OP1=X
    call bitwiseNot ; OP1=NOT(X)
    jp replaceX

mBitwiseNegHandler:
    call closeInputAndRecallX ; OP1=X
    call bitwiseNeg ; OP1=NEG(X)
    jp replaceX

;-----------------------------------------------------------------------------

mShiftLeftLogicalHandler:
    call closeInputAndRecallX ; OP1=X
    call baseShiftLeftLogical ; OP1=shiftLeftLogical(OP1)
    jp replaceX

mShiftRightLogicalHandler:
    call closeInputAndRecallX ; OP1=X
    call baseShiftRightLogical ; OP1=shiftRightLogical(OP1)
    jp replaceX

mShiftRightArithmeticHandler:
    call closeInputAndRecallX ; OP1=X
    call baseShiftRightArithmetic ; OP1=shiftRightArithmetic(OP1)
    jp replaceX

mShiftLeftLogicalNHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    call baseShiftLeftLogicalN ; OP1=shiftLeftLogical(OP1,OP2)
    jp replaceXY

mShiftRightLogicalNHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    call baseShiftRightLogicalN ; OP1=shiftLeftLogical(OP1,OP2)
    jp replaceXY

;-----------------------------------------------------------------------------

mRotateLeftCircularHandler:
    call closeInputAndRecallX ; OP1=X
    call baseRotateLeftCircular; OP3=rotateLeftCircular(OP3)
    jp replaceX

mRotateRightCircularHandler:
    call closeInputAndRecallX ; OP1=X
    call baseRotateRightCircular; OP1=rotateRightCircular(OP1)
    jp replaceX

mRotateLeftCarryHandler:
    call closeInputAndRecallX ; OP1=X
    call baseRotateLeftCarry ; OP1=rotateLeftCarry(OP1)
    jp replaceX

mRotateRightCarryHandler:
    call closeInputAndRecallX ; OP1=X
    call baseRotateRightCarry ; OP1=rotateRightCarry(OP1)
    jp replaceX

;-----------------------------------------------------------------------------

mRotateLeftCircularNHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    call baseRotateLeftCircularN
    jp replaceXY

mRotateRightCircularNHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    call baseRotateRightCircularN
    jp replaceXY

mRotateLeftCarryNHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    call baseRotateLeftCarryN
    jp replaceXY

mRotateRightCarryNHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    call baseRotateRightCarryN
    jp replaceXY

;-----------------------------------------------------------------------------

mClearCarryFlagHandler:
    or a ; CF=0
    jp storeCarryFlag

mSetCarryFlagHandler:
    scf ; CF=1
    jp storeCarryFlag

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

; TODO: Rename these arithmetic operations mBaseXxxHandler.

mBitwiseAddHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    call bitwiseAdd ; OP1+=OP2
    jp replaceXY

mBitwiseSubtHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    call bitwiseSub ; OP1-=OP2
    jp replaceXY

mBitwiseMultHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    call bitwiseMult ; OP1*=OP2
    jp replaceXY

; Description: Calculate bitwise x/y.
; Output:
;   - X=quotient
;   - remainder thrown away
mBitwiseDivHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    call bitwiseDiv ; OP1=OP1/OP2
    jp replaceXY

; Description: Calculate bitwise div(x, y) -> (y/x, y % x).
; Output:
;   - X=remainder
;   - Y=quotient
mBitwiseDiv2Handler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    call bitwiseDiv2 ; OP1=remainder; OP2=quotient
    jp replaceXYWithOP1OP2 ; Y=remainder, X=quotient

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

;-----------------------------------------------------------------------------
; Recall X or Y as U32.
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
    call cmpU32WithA
    jr nc, recallXYAsU32NError
    ld hl, OP3
    ld de, OP4
    ld b, a ; B=u8(X)
    or a ; set ZF=1 if u8(X)==0
    ret
recallXYAsU32NError:
    bcall(_ErrDomain) ; throw exception if X >= baseWordSize
