;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; TVM menu handlers.
;
; Every handler is given the following input parameters:
;   - HL:(MenuNode*)=currentMenuNode
;   - CF:bool
;       - 0 indicates 'onEnter' event into group
;       - 1 indicates 'onExit' event from group
;
; The equations and algorithms to calculate N, i, PV, PMT, and FV as a function
; of the other 4 variables are described in detail in the TVM.md document.
;
; The handling of rpnFlagsTvmCalculate is a bit tricky so let's write it down
; for posterity:
;
; - If any TVM variable or parameter is Stored, then set the
; rpnFlagsTvmCalculate flag, causing the next TVM button to Calculate. This
; includes the BEG and END menu buttons.
;
; - If a `2ND` menu button is invoked, causing a recall of the specified TVM
; variable, then clear the rpnFlagsTvmCalculate flag, causing the next TVM
; button to Store. This makes sense because a value was just recalled into the
; X register.
;
; - If a TVM menu button performed a Calculate, then keep the
; rpnFlagsTvmCalculate flag set, so that another TVM menu button performs
; another Calculate.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; TVM handlers are invoked by the menu buttons.
;-----------------------------------------------------------------------------

mTvmNHandler:
    call closeInput
    ; Check if '2ND N' pressed.
    bit rpnFlagsSecondKey, (iy + rpnFlags)
    jr nz, mTvmNGet
    ; Check if N needs to be calculated.
    bit rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr nz, mTvmNCalculate
    ; save the inputBuf value
    call rclX
    call validateOp1Real
    bcall(_StoTvmN)
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmNGet:
    bcall(_RclTvmN)
    call pushToX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret
mTvmNCalculate:
    bcall(_TvmCalculateN)
    bcall(_StoTvmN)
    call pushToX
    ld a, errorCodeTvmCalculated
    ld (handlerCode), a
    ret

;-----------------------------------------------------------------------------

; Description: Clear any error code on the display if it exists.
; The TVM Solver is a bit slow, 2-3 seconds. During that time, the errorCode
; from the previous command will be displayed, which is a bit confusing. Let's
; remove the previous error code before running the long subroutine. NOTE: It
; might be reasonable to do this before all commands, but we have to be a
; little careful because the CLEAR command behaves slightly differently if
; there an errorcode is currently being displayed. The CLEAR command simply
; clears the current errorCode if it exists, without doing anything else, so
; the logic is a bit tricky.
; Destroys: A
clearDisplayedErrorCode:
    ld a, (errorCode)
    or a
    ret z
    xor a
    bcall(_SetErrorCode)
    jp displayAll

mTvmIYRHandler:
    call closeInput
    ; Check if '2ND I%YR' pressed.
    bit rpnFlagsSecondKey, (iy + rpnFlags)
    jr nz, mTvmIYRGet
    ; Check if I%YR needs to be calculated.
    bit rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr nz, mTvmIYRCalculate
    ; save the inputBuf value
    call rclX
    call validateOp1Real
    bcall(_TvmCalcIPPFromIYR)
    call op1ToOp2 ; OP2=IYR/N=i
    call op1SetM1 ; OP1=-1
    bcall(_CpOP1OP2) ; if -1<i: CF=1 (valid)
    jr nc, mTvmIYRErr
    call rclX
    bcall(_StoTvmIYR)
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmIYRGet:
    bcall(_RclTvmIYR)
    call pushToX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret
mTvmIYRCalculate:
    call clearDisplayedErrorCode
    call tvmIYRCalculate ; A=handlerCode; OP1=result
    ld (handlerCode), a
    cp errorCodeTvmCalculated
    jr z, mTvmIYRCalculateFound
    cp errorCodeTvmCalculatedMultiple
    jr z, mTvmIYRCalculateFound
    ret
mTvmIYRCalculateFound:
    bcall(_StoTvmIYR)
    call pushToX
    ret
mTvmIYRErr:
    bcall(_ErrDomain)

; Description: Call the tvmSolver() as often as necessary (e.g. during
; debugging single step) to arrive a solution, or determine that there is no
; solution. Interest rate does not have a closed-form solution, so requires
; solving the root of an equation.
; Output:
;   - A: handlerCoder
;   - OP1: IYR solution if A==errorCodeCalculated
; Destroys: all
tvmIYRCalculate:
    ld a, rpntrue
    ld (tvmSolverIsRunning), a ; set 'isRunning' flag
    bcall(_RunIndicOn)
    xor a ; A=0=tvmSolverResultContinue
tvmIYRCalculateSingleStepLoop:
    ; TvmSolve() can be called with 2 values of A:
    ; - A=tvmSolverResultSingleStep to restart from the last loop, or
    ; - A=anything else to start the root solver from the beginning.
    bcall(_TvmSolve) ; A=tvmSolverResultXxx, guaranteed non-zero
    ; If Single Step is active, TvmSolve() yields for each iteration. It is
    ; called it again to continue its iteration until an appropriate status
    ; codes is returned.
    cp tvmSolverResultSingleStep
    jr z, tvmIYRCalculateSingleStep
    ;
    cp tvmSolverResultFound
    jr z, tvmIYRCalculateFound
    cp tvmSolverResultNotFound
    jr z, tvmIYRCalculateNotFound
    cp tvmSolverResultNoSolution
    jr z, tvmIYRCalculateNoSolution
    cp tvmSolverResultIterMaxed
    jr z, tvmIYRCalculateIterMaxed
    cp tvmSolverResultBreak
    jr z, tvmIYRCalculateBreak
    ; anything else is a programming error
    jr tvmIYRCalculateStatusUnknown
    ;
tvmIYRCalculateSingleStep:
    call tvmIYRCalculateShowSingleStep
    jr tvmIYRCalculateSingleStepLoop
tvmIYRCalculateFound:
    ; Return a slightly different error code if only one of the 2 solutions
    ; was found.
    ld a, (tvmSolverSolutions) ; A=numSignChanges
    cp 2
    jr z, tvmIYRCalculateFoundMultiple
    ld a, errorCodeTvmCalculated
    jr tvmIYRCalculateEnd
tvmIYRCalculateFoundMultiple:
    ld a, errorCodeTvmCalculatedMultiple
    jr tvmIYRCalculateEnd
tvmIYRCalculateNotFound:
    ld a, errorCodeTvmNotFound
    jr tvmIYRCalculateEnd
tvmIYRCalculateNoSolution:
    ld a, errorCodeTvmNoSolution
    jr tvmIYRCalculateEnd
tvmIYRCalculateIterMaxed:
    ld a, errorCodeTvmIterations
    jr tvmIYRCalculateEnd
tvmIYRCalculateBreak:
    ld a, errorCodeBreak
    jr tvmIYRCalculateEnd
tvmIYRCalculateStatusUnknown: ; should never happen, so return Invalid
    ld a, errorCodeInvalid
tvmIYRCalculateEnd:
    ; Do final single step if debug is enabled. Clean up various flags.
    ; If there is an exception, the exception handler needs to perform the
    ; clean up too! See mainscanner.asm/processMainCommandsHandleException().
    ; TODO: I think we can install a nested exception handler and perform that
    ; clean up here.
    push af
    bcall(_RunIndicOff)
    bcall(_TvmSolveCheckDebugEnabled) ; CF=1 if TVM debug enabled
    call c, tvmIYRCalculateShowSingleStep
    xor a
    ld (tvmSolverIsRunning), a ; clear 'isRunning' flag
    pop af
    ret

tvmIYRCalculateShowSingleStep:
    ; single-step debugging mode: render display and wait for key
    push af ; preserve A==tvmSolverResultSingleStep
    bcall(_PushRealO1)
    set dirtyFlagsStack, (iy + dirtyFlags)
    call displayAll
    ; Pause and wait for button press.
    ; If QUIT or OFF then TvmSolver will be reset upon app start.
    bcall(_GetKey)
    bcall(_PopRealO1)
    pop af
    ret

;-----------------------------------------------------------------------------

mTvmPVHandler:
    call closeInput
    ; Check if '2ND PV' pressed.
    bit rpnFlagsSecondKey, (iy + rpnFlags)
    jr nz, mTvmPVGet
    ; Check if PV needs to be calculated.
    bit rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr nz, mTvmPVCalculate
    ; save the inputBuf value
    call rclX
    call validateOp1Real
    bcall(_StoTvmPV)
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmPVGet:
    bcall(_RclTvmPV)
    call pushToX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret
mTvmPVCalculate:
    bcall(_TvmCalculatePV)
    bcall(_StoTvmPV)
    call pushToX
    ld a, errorCodeTvmCalculated
    ld (handlerCode), a
    ret

;-----------------------------------------------------------------------------

mTvmPMTHandler:
    call closeInput
    ; Check if '2ND PMT' pressed.
    bit rpnFlagsSecondKey, (iy + rpnFlags)
    jr nz, mTvmPMTGet
    ; Check if PMT needs to be calculated.
    bit rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr nz, mTvmPMTCalculate
    ; save the inputBuf value
    call rclX
    call validateOp1Real
    bcall(_StoTvmPMT)
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmPMTGet:
    bcall(_RclTvmPMT)
    call pushToX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret
mTvmPMTCalculate:
    bcall(_TvmCalculatePMT)
    bcall(_StoTvmPMT)
    call pushToX
    ld a, errorCodeTvmCalculated
    ld (handlerCode), a
    ret

;-----------------------------------------------------------------------------

mTvmFVHandler:
    call closeInput
    ; Check if '2ND FV' pressed.
    bit rpnFlagsSecondKey, (iy + rpnFlags)
    jr nz, mTvmFVGet
    ; Check if FV needs to be calculated.
    bit rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr nz, mTvmFVCalculate
    ; save the inputBuf value
    call rclX
    call validateOp1Real
    bcall(_StoTvmFV)
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmFVGet:
    bcall(_RclTvmFV)
    call pushToX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret
mTvmFVCalculate:
    bcall(_TvmCalculateFV)
    bcall(_StoTvmFV)
    call pushToX
    ld a, errorCodeTvmCalculated
    ld (handlerCode), a
    ret

;-----------------------------------------------------------------------------

; Description: Set or get P/YR to X.
; If the PYR is updated, then CYR also set to the same value because that's the
; most common case. Users can go back and change the CYR if needed. This is
; also how the "Financial..." app on the TI-OS works.
mTvmPYRHandler:
    call closeInput
    ; Check if '2ND PYR' pressed.
    bit rpnFlagsSecondKey, (iy + rpnFlags)
    jr nz, mTvmPYRGet
    ; save the inputBuf value in OP1
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call rclX
    call validateOp1Real
    bcall(_PosNo0Int) ; if posnonzeroint(x): ZF=1
    jr z, mTvmPYRHandlerSet
    bcall(_ErrDomain)
mTvmPYRHandlerSet:
    bcall(_StoTvmPYR)
    bcall(_StoTvmCYR) ; set CYR=PYR if PYR is changed
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmPYRGet:
    bcall(_RclTvmPYR)
    call pushToX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret

; Description: Select menu name. Display a dot if the PYR is different than 12,
; which is almost always the default.
; Output: CF=0 for normal, CF=1 or alternate
; Preserves: BC, DE (must be preserved)
mTvmPYRNameSelector:
    push bc
    push de
    bcall(_RclTvmPYR)
    call op2Set12
    bcall(_CpOP1OP2) ; ZF=1 if OP1==OP2
    pop de
    pop bc
    jr nz, mTvmPYRNameSelectorAlt
    or a ; CF=0
    ret
mTvmPYRNameSelectorAlt:
    scf
    ret

;-----------------------------------------------------------------------------

; Description: Set or get C/YR to X.
mTvmCYRHandler:
    call closeInput
    ; Check if '2ND CYR' pressed.
    bit rpnFlagsSecondKey, (iy + rpnFlags)
    jr nz, mTvmCYRGet
    ; save the inputBuf value in OP1
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call rclX
    call validateOp1Real
    bcall(_PosNo0Int) ; if posnonzeroint(x): ZF=1
    jr z, mTvmCYRHandlerSet
    bcall(_ErrDomain)
mTvmCYRHandlerSet:
    bcall(_StoTvmCYR)
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmCYRGet:
    bcall(_RclTvmCYR)
    call pushToX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret

; Description: Select menu name. Display a dot if the CYR is different than 12,
; which is almost always the default.
; Output: CF=0 for normal, CF=1 or alternate
; Preserves: BC, DE (must be preserved)
mTvmCYRNameSelector:
    push bc
    push de
    bcall(_RclTvmCYR)
    call op2Set12
    bcall(_CpOP1OP2) ; ZF=1 if OP1==OP2
    pop de
    pop bc
    jr nz, mTvmCYRNameSelectorAlt
    or a ; CF=0
    ret
mTvmCYRNameSelectorAlt:
    scf
    ret

;-----------------------------------------------------------------------------

mTvmBeginHandler:
    call closeInput
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld hl, tvmFlags
    set tvmFlagsBegin, (hl)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
; Preserves: BC, DE (must be preserved)
mTvmBeginNameSelector:
    or a ; CF=0
    ld a, (tvmFlags)
    bit tvmFlagsBegin, a
    ret z
    scf
    ret

;-----------------------------------------------------------------------------

mTvmEndHandler:
    call closeInput
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld hl, tvmFlags
    res tvmFlagsBegin, (hl)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
; Preserves: BC, DE (must be preserved)
mTvmEndNameSelector:
    or a ; CF=0
    ld a, (tvmFlags)
    bit tvmFlagsBegin, a
    ret nz
    scf
    ret

;-----------------------------------------------------------------------------

mTvmIYR0Handler:
    call closeInput
    ; Check if '2ND IYR1' pressed.
    bit rpnFlagsSecondKey, (iy + rpnFlags)
    jr nz, mTvmIYR0Get
    ; save the inputBuf value in OP1
    call rclX
    call validateOp1Real
    bcall(_StoTvmIYR0)
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmIYR0Get:
    bcall(_RclTvmIYR0)
    call pushToX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
; Preserves: BC, DE (must be preserved)
mTvmIYR0NameSelector:
    push bc
    push de
    bcall(_RclTvmIYR0Default)
    bcall(_OP1ToOP2)
    bcall(_RclTvmIYR0)
    bcall(_CpOP1OP2) ; ZF=1 if OP1==OP2
    pop de
    pop bc
    jr nz, mTvmIYR0NameSelectorAlt
    or a ; CF=0
    ret
mTvmIYR0NameSelectorAlt:
    scf
    ret

;-----------------------------------------------------------------------------

mTvmIYR1Handler:
    call closeInput
    ; Check if '2ND IYR2' pressed.
    bit rpnFlagsSecondKey, (iy + rpnFlags)
    jr nz, mTvmIYR1Get
    ; save the inputBuf value in OP1
    call rclX
    call validateOp1Real
    bcall(_StoTvmIYR1)
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmIYR1Get:
    bcall(_RclTvmIYR1)
    call pushToX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
; Preserves: BC, DE (must be preserved)
mTvmIYR1NameSelector:
    push bc
    push de
    bcall(_RclTvmIYR1Default)
    bcall(_OP1ToOP2)
    bcall(_RclTvmIYR1)
    bcall(_CpOP1OP2) ; ZF=1 if OP1==OP2
    pop de
    pop bc
    jr nz, mTvmIYR1NameSelectorAlt
    or a ; CF=0
    ret
mTvmIYR1NameSelectorAlt:
    scf
    ret

;-----------------------------------------------------------------------------

mTvmIterMaxHandler:
    call closeInput
    ; Check if '2ND TMAX' pressed.
    bit rpnFlagsSecondKey, (iy + rpnFlags)
    jr nz, mTvmIterMaxGet
    ; save the inputBuf value in OP1
    call rclX
    call validateOp1Real
    bcall(_StoTvmIterMax)
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmIterMaxGet:
    bcall(_RclTvmIterMax)
    call pushToX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
; Preserves: BC, DE (must be preserved)
mTvmIterMaxNameSelector:
    push bc
    push de
    ld a, (tvmIterMax)
    cp tvmSolverDefaultIterMax ; ZF=1 if tmvIterMax==default
    pop de
    pop bc
    jr nz, mTvmIterMaxNameSelectorAlt
    or a ; CF=0
    ret
mTvmIterMaxNameSelectorAlt:
    scf
    ret

;-----------------------------------------------------------------------------

mTvmClearHandler:
    call closeInput
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    bcall(_TvmClear)
    ld a, errorCodeTvmCleared
    ld (handlerCode), a
    ret

mTvmSolverResetHandler:
    call closeInput
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    bcall(_TvmSolverReset)
    ld a, errorCodeTvmSolverReset
    ld (handlerCode), a
    ret
