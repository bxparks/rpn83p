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

; Input: A, B: nameId; C: altNameId
mDecNameSelector:
    ld a, 10
    jr mBaseNameSelector

; Input: A, B: nameId; C: altNameId
mHexNameSelector:
    ld a, 16
    jr mBaseNameSelector

; Input: A, B: nameId; C: altNameId
mOctNameSelector:
    ld a, 8
    jr mBaseNameSelector

; Input: A, B: nameId; C: altNameId
mBinNameSelector:
    ld a, 2
    ; [[fallthrough]]

; Description: Select the display name of 'DEC', 'HEX', 'OCT', and 'BIN' menus.
; Input:
;   - A: selectedBase (2, 8, 10, 16)
;   - B: nameId
;   - C: altNameId
;   - HL: pointer to MenuNode
; Output:
;   - A: either B or C
; Destroys: HL
mBaseNameSelector:
    ld hl, baseNumber
    cp (hl) ; if selectedBase==(baseNumber): ZF=1
    ld a, b
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
    call baseShiftLeftLogicalN ; OP1=shiftLeftLogicalN(OP1,OP2)
    jp replaceXY

mShiftRightLogicalNHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    call baseShiftRightLogicalN ; OP1=shiftRightLogicalN(OP1,OP2)
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

mBaseAddHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    call baseAdd ; OP1+=OP2
    jp replaceXY

mBaseSubtHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    call baseSub ; OP1-=OP2
    jp replaceXY

mBaseMultHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    call baseMult ; OP1*=OP2
    jp replaceXY

; Description: Calculate base x/y.
; Output:
;   - X=quotient
;   - remainder thrown away
mBaseDivHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    call baseDiv ; OP1=OP1/OP2
    jp replaceXY

; Description: Calculate base div(x, y) -> (y/x, y % x).
; Output:
;   - X=remainder
;   - Y=quotient
mBaseDiv2Handler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    call baseDiv2 ; OP1=remainder; OP2=quotient
    jp replaceXYWithOP1OP2 ; Y=remainder, X=quotient

;-----------------------------------------------------------------------------

mReverseBitHandler:
    call closeInputAndRecallX ; OP1=X
    call baseReverseBits ; OP1=reverseBits(OP1)
    jp replaceX

mCountBitHandler:
    call closeInputAndRecallX ; OP1=X
    call baseCountBits ; OP1=countBits(OP1)
    jp replaceX

mSetBitHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    call baseSetBit ; OP1=setBit(OP1,OP2)
    jp replaceXY

mClearBitHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    call baseClearBit ; OP1=clearBit(OP1,OP2)
    jp replaceXY

mGetBitHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    call baseGetBit ; OP1=bit(OP1,OP2)
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
    call baseGetCarryFlag ; OP1=float(baseCarryFlag)
    jp pushX

;-----------------------------------------------------------------------------

; Description: Prompt for the new base word size, like FIX or STO. Allowed
; values are 8, 16, 24, 32. Throw Err:Argument if outside of that list.
mSetWordSizeHandler:
    call closeInputAndRecallNone
    ld hl, msgWordSizePrompt
    call startArgParser
    call processArgCommands ; CF=0 if cancelled; (argModifier), (argValue)
    ret nz ; do nothing if cancelled
    ld a, (argValue)
    jp baseSetWordSize

msgWordSizePrompt:
    .db "WSIZ", 0

mGetWordSizeHandler:
    call closeInputAndRecallNone
    call baseGetWordSize
    jp pushX
