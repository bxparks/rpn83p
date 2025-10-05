;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; BASE menu handlers.
;
; Every handler is given the following input parameters:
;   - DE:(void*):address of handler
;   - HL:u16=newMenuId
; If the handler is a MenuGroup, then it also gets the following:
;   - BC:u16=oldMenuId
;   - CF:bool
;       - 0 indicates 'onEnter' event into group
;       - 1 indicates 'onExit' event from group
;-----------------------------------------------------------------------------

; Description: Group handler for BASE menu group and its subgroups.
;
; - OnEnter, it enables the 'rpnFlagsBaseModeEnabled' flag so that the display
; is rendered in the appropriate DEC, BIN, OCT, or HEX modes.
; - OnExit, it disables the 'rpnFlagsBaseModeEnabled' so that the display is
; rendered normally.
; - In either case, the input buffer is terminated ONLY if a transition occurs
; from a BASE to a non-BASE menu group. For example, if the user goes from a
; 'BASE' to 'BASE > ROTS', then the input buf should remain open.
;
; Input:
;   - BC=prevMenuGroupId
;   - HL=targetMenuGroupId
;   - CF=1: handle onExit() event
;   - CF=0: handle onEnter() event
mBaseHandler:
mBaseLogicHandler:
mBaseRotateHandler:
mBaseBitsHandler:
mBaseFunctionsHandler:
mBaseConfigsHandler: ; BCFS could also mean "Base Carry Flag and Word Size"
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

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mDecNameSelector:
    ld a, 10
    jr mBaseNameSelector

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mHexNameSelector:
    ld a, 16
    jr mBaseNameSelector

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mOctNameSelector:
    ld a, 8
    jr mBaseNameSelector

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mBinNameSelector:
    ld a, 2
    ; [[fallthrough]]

; Description: Select the menu name of 'DEC', 'HEX', 'OCT', and 'BIN' menus.
; Input:
;   - A: selectedBase (2, 8, 10, 16)
; Output:
;   - CF=0 or 1
; Destroys: HL
; Output: CF=0 for normal, CF=1 or alternate
mBaseNameSelector:
    ld hl, baseNumber
    cp (hl) ; if selectedBase==(baseNumber): ZF=1
    jr z, mBaseNameSelectorAlt
    or a ; CF=0
    ret
mBaseNameSelectorAlt:
    scf
    ret

;-----------------------------------------------------------------------------

mBitwiseAndHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    bcall(_BitwiseAnd) ; OP1=X AND Y
    bcall(_ReplaceStackXY)
    ret

mBitwiseOrHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    bcall(_BitwiseOr) ; OP1=X OR Y
    bcall(_ReplaceStackXY)
    ret

mBitwiseXorHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    bcall(_BitwiseXor) ; OP1=X XOR Y
    bcall(_ReplaceStackXY)
    ret

mBitwiseNotHandler:
    call closeInputAndRecallX ; OP1=X
    bcall(_BitwiseNot) ; OP1=NOT(X)
    bcall(_ReplaceStackX)
    ret

mBitwiseNegHandler:
    call closeInputAndRecallX ; OP1=X
    bcall(_BitwiseNeg) ; OP1=NEG(X)
    bcall(_ReplaceStackX)
    ret

;-----------------------------------------------------------------------------

mShiftLeftLogicalHandler:
    call closeInputAndRecallX ; OP1=X
    bcall(_BaseShiftLeftLogical) ; OP1=shiftLeftLogical(OP1)
    bcall(_ReplaceStackX)
    ret

mShiftRightLogicalHandler:
    call closeInputAndRecallX ; OP1=X
    bcall(_BaseShiftRightLogical) ; OP1=shiftRightLogical(OP1)
    bcall(_ReplaceStackX)
    ret

mShiftRightArithmeticHandler:
    call closeInputAndRecallX ; OP1=X
    bcall(_BaseShiftRightArithmetic) ; OP1=shiftRightArithmetic(OP1)
    bcall(_ReplaceStackX)
    ret

mShiftLeftLogicalNHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    bcall(_BaseShiftLeftLogicalN) ; OP1=shiftLeftLogicalN(OP1,OP2)
    bcall(_ReplaceStackXY)
    ret

mShiftRightLogicalNHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    bcall(_BaseShiftRightLogicalN) ; OP1=shiftRightLogicalN(OP1,OP2)
    bcall(_ReplaceStackXY)
    ret

;-----------------------------------------------------------------------------

mRotateLeftCircularHandler:
    call closeInputAndRecallX ; OP1=X
    bcall(_BaseRotateLeftCircular) ; OP3=rotateLeftCircular(OP3)
    bcall(_ReplaceStackX)
    ret

mRotateRightCircularHandler:
    call closeInputAndRecallX ; OP1=X
    bcall(_BaseRotateRightCircular) ; OP1=rotateRightCircular(OP1)
    bcall(_ReplaceStackX)
    ret

mRotateLeftCarryHandler:
    call closeInputAndRecallX ; OP1=X
    bcall(_BaseRotateLeftCarry) ; OP1=rotateLeftCarry(OP1)
    bcall(_ReplaceStackX)
    ret

mRotateRightCarryHandler:
    call closeInputAndRecallX ; OP1=X
    bcall(_BaseRotateRightCarry) ; OP1=rotateRightCarry(OP1)
    bcall(_ReplaceStackX)
    ret

;-----------------------------------------------------------------------------

mRotateLeftCircularNHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    bcall(_BaseRotateLeftCircularN)
    bcall(_ReplaceStackXY)
    ret

mRotateRightCircularNHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    bcall(_BaseRotateRightCircularN)
    bcall(_ReplaceStackXY)
    ret

mRotateLeftCarryNHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    bcall(_BaseRotateLeftCarryN)
    bcall(_ReplaceStackXY)
    ret

mRotateRightCarryNHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    bcall(_BaseRotateRightCarryN)
    bcall(_ReplaceStackXY)
    ret

;-----------------------------------------------------------------------------

mBaseAddHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    bcall(_BaseAdd) ; OP1+=OP2
    bcall(_ReplaceStackXY)
    ret

mBaseSubtHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    bcall(_BaseSub) ; OP1-=OP2
    bcall(_ReplaceStackXY)
    ret

mBaseMultHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    bcall(_BaseMult) ; OP1*=OP2
    bcall(_ReplaceStackXY)
    ret

; Description: Calculate base x/y.
; Output:
;   - X=quotient
;   - remainder thrown away
mBaseDivHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    bcall(_BaseDiv) ; OP1=OP1/OP2
    bcall(_ReplaceStackXY)
    ret

; Description: Calculate base div(x, y) -> (y/x, y % x).
; Output:
;   - X=remainder
;   - Y=quotient
mBaseDiv2Handler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    bcall(_BaseDiv2) ; OP1=remainder; OP2=quotient
    bcall(_ReplaceStackXYWithOP1OP2) ; Y=remainder, X=quotient
    ret

;-----------------------------------------------------------------------------

mReverseBitHandler:
    call closeInputAndRecallX ; OP1=X
    bcall(_BaseReverseBits) ; OP1=reverseBits(OP1)
    bcall(_ReplaceStackX)
    ret

mCountBitHandler:
    call closeInputAndRecallX ; OP1=X
    bcall(_BaseCountBits) ; OP1=countBits(OP1)
    bcall(_ReplaceStackX)
    ret

mClearBitHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    bcall(_BaseClearBit) ; OP1=clearBit(OP1,OP2)
    bcall(_ReplaceStackXY)
    ret

mSetBitHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    bcall(_BaseSetBit) ; OP1=setBit(OP1,OP2)
    bcall(_ReplaceStackXY)
    ret

mGetBitHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    bcall(_BaseGetBit) ; OP1=bit(OP1,OP2)
    bcall(_ReplaceStackXY)
    ret

;-----------------------------------------------------------------------------

mClearCarryFlagHandler:
    or a ; CF=0
    bcall(_BaseStoreCarryFlag)
    ret

mSetCarryFlagHandler:
    scf ; CF=1
    bcall(_BaseStoreCarryFlag)
    ret

mGetCarryFlagHandler:
    call closeInputAndRecallNone
    bcall(_BaseGetCarryFlag) ; OP1=float(baseCarryFlag)
    bcall(_PushToStackX)
    ret

;-----------------------------------------------------------------------------

; Description: Prompt for the new base word size, like FIX or STO. Allowed
; values are 8, 16, 24, 32.
; Throws: Err:Argument if outside of that list.
mSetWordSizeHandler:
    ld hl, msgWordSizePrompt
    call startArgScanner
    call processArgCommands ; CF=0 if cancelled; (argModifier), (argValue)
    ret nz ; do nothing if cancelled
    ld a, (argValue)
    bcall(_BaseSetWordSize)
    ret

msgWordSizePrompt:
    .db "WSIZ", 0

mGetWordSizeHandler:
    call closeInputAndRecallNone
    bcall(_BaseGetWordSize)
    bcall(_PushToStackX)
    ret
