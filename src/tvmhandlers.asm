;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; TVM menu handlers. The equations and algorithms to calculate N, i, PV, PMT,
; and FV as a function of the other 4 variables are described in detail in the
; TVM.md document.
;
; The handling of rpnFlagsTvmCalculate is a bit tricky so let's write it down
; for posterity:
;
; - If any TVM variable or parameter is Stored, then set the
; rpnFlagsTvmCalculate flag, causing the next TVM button to Calculate. This
; includes the BEG and END which set or clear the tvmIsBegin flag.
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

; Description: Reset all of the TVM variables. This is performed only when
; RestoreAppState() fails.
initTvm:
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    bcall(_TvmClear)
    ; [[fallthrough]]

; Description: Reset the TVM Solver status. This is always done at App start.
initTvmSolver:
    xor a
    ld (tvmSolverIsRunning), a
    ret

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
    bcall(_StoTvmN)
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmNGet:
    bcall(_RclTvmN)
    call pushX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret
mTvmNCalculate:
    bcall(_TvmCalculateN)
    bcall(_StoTvmN)
    call pushX
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
    bcall(_TvmCalcIPPFromIYR)
    call op1ToOp2 ; OP2=IYR/N=i
    call op1SetM1 ; OP1=-1
    bcall(_CpOP1OP2) ; if -1<i: CF=1 (valid)
    jr c, mTvmIYRSet
    bcall(_ErrDomain)
mTvmIYRSet:
    call rclX
    bcall(_StoTvmIYR)
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmIYRGet:
    bcall(_RclTvmIYR)
    call pushX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret
mTvmIYRCalculate:
    call clearDisplayedErrorCode
    call tvmIYRCalculate ; A=handlerCode; OP1=result
    ld (handlerCode), a
    cp errorCodeTvmCalculated
    ret nz
    bcall(_StoTvmIYR)
    call pushX
    ret

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
tvmIYRCalculateSolveLoop:
    ; tvmSolve() can be called with 2 values of A:
    ; - A=tvmSolverResultSingleStep to restart from the last loop, or
    ; - A=anything else to start the root solver from the beginning,
    bcall(_TvmSolve) ; A=tvmSolverResultXxx, guaranteed non-zero
    cp tvmSolverResultFound
    jr nz, tvmIYRCalculateCheckNoSolution
    ; Found!
    ld a, errorCodeTvmCalculated
    jr tvmIYRCalculateEnd
tvmIYRCalculateCheckNoSolution:
    cp tvmSolverResultNoSolution
    jr nz, tvmIYRCalculateCheckNotFound
    ; Cannot have a solution
    ld a, errorCodeTvmNoSolution
    jr tvmIYRCalculateEnd
tvmIYRCalculateCheckNotFound:
    cp tvmSolverResultNotFound
    jr nz, tvmIYRCalculateCheckIterMax
    ; root not found
    ld a, errorCodeTvmNotFound
    jr tvmIYRCalculateEnd
tvmIYRCalculateCheckIterMax:
    cp tvmSolverResultIterMaxed
    jr nz, tvmIYRCalculateCheckBreak
    ; root not found after max iterations
    ld a, errorCodeTvmIterations
    jr tvmIYRCalculateEnd
tvmIYRCalculateCheckBreak:
    cp tvmSolverResultBreak
    jr nz, tvmIYRCalculateCheckSingleStep
    ; user hit ON/EXIT
    ld a, errorCodeBreak
    jr tvmIYRCalculateEnd
tvmIYRCalculateCheckSingleStep:
    cp tvmSolverResultSingleStep
    jr nz, tvmIYRCalculateStatusUnknown
    ; single-step debugging mode: render display and wait for key
    push af ; preserve A==tvmSolverResultSingleStep
    set dirtyFlagsStack, (iy + dirtyFlags)
    call displayAll
    ; Pause and wait for button press.
    ; If QUIT or OFF then TvmSolver will be reset upon app start.
    bcall(_GetKey)
    pop af
    jr tvmIYRCalculateSolveLoop
tvmIYRCalculateStatusUnknown:
    ld a, errorCodeTvmNotFound
tvmIYRCalculateEnd:
    push af
    xor a
    ld (tvmSolverIsRunning), a ; clear 'isRunning' flag
    bcall(_RunIndicOff)
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
    bcall(_StoTvmPV)
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmPVGet:
    bcall(_RclTvmPV)
    call pushX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret
mTvmPVCalculate:
    bcall(_TvmCalculatePV)
    bcall(_StoTvmPV)
    call pushX
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
    bcall(_StoTvmPMT)
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmPMTGet:
    bcall(_RclTvmPMT)
    call pushX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret
mTvmPMTCalculate:
    bcall(_TvmCalculatePMT)
    bcall(_StoTvmPMT)
    call pushX
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
    bcall(_StoTvmFV)
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmFVGet:
    bcall(_RclTvmFV)
    call pushX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret
mTvmFVCalculate:
    bcall(_TvmCalculateFV)
    bcall(_StoTvmFV)
    call pushX
    ld a, errorCodeTvmCalculated
    ld (handlerCode), a
    ret

;-----------------------------------------------------------------------------

; Description: Set or get P/YR to X.
mTvmPYRHandler:
    call closeInput
    ; Check if '2ND PYR' pressed.
    bit rpnFlagsSecondKey, (iy + rpnFlags)
    jr nz, mTvmPYRGet
    ; save the inputBuf value in OP1
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call rclX
    bcall(_PosNo0Int) ; if posnonzeroint(x): ZF=1
    jr z, mTvmPYRHandlerSet
    bcall(_ErrDomain)
mTvmPYRHandlerSet:
    bcall(_StoTvmPYR)
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmPYRGet:
    bcall(_RclTvmPYR)
    call pushX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret

;-----------------------------------------------------------------------------

mTvmBeginHandler:
    call closeInput
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, rpntrue
    ld (tvmIsBegin), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Return B if tvmIsBegin is false, C otherwise.
; Input: A, B: normal nameId; C: alt nameId
; Output: A
mTvmBeginNameSelector:
    ld a, (tvmIsBegin)
    or a
    jr nz, mTvmBeginNameSelectorC
    ld a, b
    ret
mTvmBeginNameSelectorC:
    ld a, c
    ret

;-----------------------------------------------------------------------------

mTvmEndHandler:
    call closeInput
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    xor a
    ld (tvmIsBegin), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Return C if tvmIsBegin is false, B otherwise.
; Input:
;   - A, B: normal nameId
;   - C: alt nameId
; Output: A
mTvmEndNameSelector:
    ld a, (tvmIsBegin)
    or a
    jr z, mTvmEndNameSelectorC
    ld a, b
    ret
mTvmEndNameSelectorC:
    ld a, c
    ret

;-----------------------------------------------------------------------------

mTvmIYR0Handler:
    call closeInput
    ; Check if '2ND IYR1' pressed.
    bit rpnFlagsSecondKey, (iy + rpnFlags)
    jr nz, mTvmIYR0Get
    ; save the inputBuf value in OP1
    call rclX
    bcall(_StoTvmIYR0)
    call tvmSolverSetOverrideFlagIYR0
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmIYR0Get:
    bcall(_RclTvmIYR0)
    call pushX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret

; Description: Return B if tvmIsBegin is false, C otherwise.
; Input: A, B: normal nameId; C: alt nameId
; Output: A
mTvmIYR0NameSelector:
    call tvmSolverBitOverrideFlagIYR0
    jr nz, mTvmIYR0NameSelectorC
    ld a, b
    ret
mTvmIYR0NameSelectorC:
    ld a, c
    ret

;-----------------------------------------------------------------------------

mTvmIYR1Handler:
    call closeInput
    ; Check if '2ND IYR2' pressed.
    bit rpnFlagsSecondKey, (iy + rpnFlags)
    jr nz, mTvmIYR1Get
    ; save the inputBuf value in OP1
    call rclX
    bcall(_StoTvmIYR1)
    call tvmSolverSetOverrideFlagIYR1
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmIYR1Get:
    bcall(_RclTvmIYR1)
    call pushX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret

; Description: Return B if tvmIsBegin is false, C otherwise.
; Input: A, B: nameId; C: altNameId
; Output: A
mTvmIYR1NameSelector:
    call tvmSolverBitOverrideFlagIYR1
    jr nz, mTvmIYR1NameSelectorC
    ld a, b
    ret
mTvmIYR1NameSelectorC:
    ld a, c
    ret

;-----------------------------------------------------------------------------

mTvmIterMaxHandler:
    call closeInput
    ; Check if '2ND TMAX' pressed.
    bit rpnFlagsSecondKey, (iy + rpnFlags)
    jr nz, mTvmIterMaxGet
    ; save the inputBuf value in OP1
    call rclX
    bcall(_StoTvmIterMax)
    call tvmSolverSetOverrideFlagIterMax
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmIterMaxGet:
    bcall(_RclTvmIterMax)
    call pushX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret

; Description: Return B if tvmIsBegin is false, C otherwise.
; Input: A, B: normal nameId; C: alt nameId
; Output: A
mTvmIterMaxNameSelector:
    call tvmSolverBitOverrideFlagIterMax
    jr nz, mTvmIterMaxNameSelectorC
    ld a, b
    ret
mTvmIterMaxNameSelectorC:
    ld a, c
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

;-----------------------------------------------------------------------------
; More low-level helper routines, placed at the bottom to avoid clutter in the
; main parts of the file. TODO: Many (all?) of these may be suitable to move to
; tvm.asm in Flash Page 1, because I don't any of these are in performance
; critical paths.
;-----------------------------------------------------------------------------

; Description: Set tvmSolverOverrideFlagIYR0.
; Destroys: HL
tvmSolverSetOverrideFlagIYR0:
    ld hl, tvmSolverOverrideFlags
    set tvmSolverOverrideFlagIYR0, (hl)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Reset tvmSolverOverrideFlagIYR0.
; Destroys: HL
tvmSolverResOverrideFlagIYR0:
    ld hl, tvmSolverOverrideFlags
    res tvmSolverOverrideFlagIYR0, (hl)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Test bit tvmSolverOverrideFlagIYR0.
; Destroys: HL
tvmSolverBitOverrideFlagIYR0:
    ld hl, tvmSolverOverrideFlags
    bit tvmSolverOverrideFlagIYR0, (hl)
    ret

; Description: Set tvmSolverOverrideFlagIYR1.
; Destroys: HL
tvmSolverSetOverrideFlagIYR1:
    ld hl, tvmSolverOverrideFlags
    set tvmSolverOverrideFlagIYR1, (hl)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Reset tvmSolverOverrideFlagIYR1.
; Destroys: HL
tvmSolverResOverrideFlagIYR1:
    ld hl, tvmSolverOverrideFlags
    res tvmSolverOverrideFlagIYR1, (hl)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Test bit tvmSolverOverrideFlagIYR1.
; Destroys: HL
tvmSolverBitOverrideFlagIYR1:
    ld hl, tvmSolverOverrideFlags
    bit tvmSolverOverrideFlagIYR1, (hl)
    ret

; Description: Set tvmSolverOverrideFlagIterMax.
; Destroys: HL
tvmSolverSetOverrideFlagIterMax:
    ld hl, tvmSolverOverrideFlags
    set tvmSolverOverrideFlagIterMax, (hl)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Reset tvmSolverOverrideFlagIterMax.
; Destroys: HL
tvmSolverResOverrideFlagIterMax:
    ld hl, tvmSolverOverrideFlags
    res tvmSolverOverrideFlagIterMax, (hl)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Test bit tvmSolverOverrideFlagIterMax.
; Destroys: HL
tvmSolverBitOverrideFlagIterMax:
    ld hl, tvmSolverOverrideFlags
    bit tvmSolverOverrideFlagIterMax, (hl)
    ret
