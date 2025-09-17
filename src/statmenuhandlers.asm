;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; STAT menu handlers.
;
; Every handler is given the following input parameters:
;   - HL:u16=menuId
;   - CF:bool
;       - 0 indicates 'onEnter' event into group
;       - 1 indicates 'onExit' event from group
;
; References:
;   - HP-42S Owner's Manual, Ch. 15
;   - https://en.wikipedia.org/wiki/Algorithms_for_calculating_variance
;   - https://en.wikipedia.org/wiki/Simple_linear_regression
;   - https://en.wikipedia.org/wiki/Covariance_and_correlation
;-----------------------------------------------------------------------------

; Description: Initialize the STAT modes.
coldInitStat:
    jr mStatAllModeHandler ; default AllSigma mode

;-----------------------------------------------------------------------------
; STAT Menu handlers.
;-----------------------------------------------------------------------------

mStatPlusHandler:
    call closeInputAndRecallXY ; validates X,Y are Real, OP1,OP2 not used
    bcall(_StatSigmaPlus)
    ld c, statRegN
    bcall(_RclStatRegNN) ; OP1=R[sigmaN]
    bcall(_ReplaceStackX)
    res rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

mStatMinusHandler:
    call closeInputAndRecallXY ; validates X is Real, OP1 not used
    bcall(_StatSigmaMinus)
    ld c, statRegN
    bcall(_RclStatRegNN) ; OP1=R[sigmaN]
    bcall(_ReplaceStackX)
    res rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

; Description: Set STAT mode to ALL.
mStatAllModeHandler:
    ld a, rpntrue
    ld (statAllEnabled), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Set STAT mode to LINEAR.
mStatLinearModeHandler:
    xor a
    ld (statAllEnabled), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mStatAllModeNameSelector:
    ld a, (statAllEnabled)
    or a ; CF=0; if A==0: ZF=1
    ret z
    scf
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mStatLinearModeNameSelector:
    ld a, (statAllEnabled)
    or a ; CF=0; if A==0: ZF=1
    ret nz
    scf
    ret

mStatClearHandler:
    call closeInputAndRecallNone
    bcall(_ClearStatRegs)
    ld a, errorCodeStatCleared
    ld (handlerCode), a
    ret

;-----------------------------------------------------------------------------

; Description: Calculate the Sum of X and Y into X and Y registers.
mStatSumHandler:
    call closeInputAndRecallNone
    bcall(_StatSum) ; OP1=Ysum; OP2=Xsum
    bcall(_PushOp1Op2ToStackXY)
    ret

; Description: Calculate the average of X and Y into X and Y registers.
mStatMeanHandler:
    call closeInputAndRecallNone
    ld ix, cfitModelLinear ; use linear model for simple statistics
    bcall(_StatMean)
    bcall(_PushOp1Op2ToStackXY)
    ret

; Description: Calculate the weighted mean of X and Y.
; Output:
;   Y: Mean of Y weighted by X = Sum(X,Y) / Sum(X)
;   X: Mean of X weighted by Y = Sum(X,Y) / Sum(Y)
mStatWeightedMeanHandler:
    call closeInputAndRecallNone
    ld ix, cfitModelLinear ; use linear model for simple statistics
    bcall(_StatWeightedMean) ; OP1=WeightedY, OP2=WeightedX
    bcall(_PushOp1Op2ToStackXY)
    ret

; Description: Return the number of items entered. Mostly for convenience.
mStatNHandler:
    jr mStatRegNHandler

;-----------------------------------------------------------------------------

; Description: Return the value of statRegX register.
mStatRegXHandler:
    ld c, statRegX
    jr recallStatReg

; Description: Return the value of statRegX2 register.
mStatRegX2Handler:
    ld c, statRegX2
    jr recallStatReg

; Description: Return the value of statRegY register.
mStatRegYHandler:
    ld c, statRegY
    jr recallStatReg

; Description: Return the value of statRegY2 register.
mStatRegY2Handler:
    ld c, statRegY2
    jr recallStatReg

; Description: Return the value of statRegXY register.
mStatRegXYHandler:
    ld c, statRegXY
    jr recallStatReg

; Description: Return the value of statRegN register.
mStatRegNHandler:
    ld c, statRegN
    jr recallStatReg

; Description: Return the value of statRegLnX register.
mStatRegLnXHandler:
    ld c, statRegLnX
    jr recallStatReg

; Description: Return the value of statRegLnX2 register.
mStatRegLnX2Handler:
    ld c, statRegLnX2
    jr recallStatReg

; Description: Return the value of statRegLnY register.
mStatRegLnYHandler:
    ld c, statRegLnY
    jr recallStatReg

; Description: Return the value of statRegLnY2 register.
mStatRegLnY2Handler:
    ld c, statRegLnY2
    jr recallStatReg

; Description: Return the value of statRegLnXLnY register.
mStatRegLnXLnYHandler:
    ld c, statRegLnXLnY
    jr recallStatReg

; Description: Return the value of statRegXLnY register.
mStatRegXLnYHandler:
    ld c, statRegXLnY
    jr recallStatReg

; Description: Return the value of statRegYLnX register.
mStatRegYLnXHandler:
    ld c, statRegYLnX
    ; [fallthrough]]

; Description: Recall the statReg specified by the C register.
; Input: C:u8=registerIndex
; Output: OP1=registerValue
recallStatReg:
    push bc ; statck=[registerIndex]
    call closeInputAndRecallNone
    pop bc ; stack=[]; C=registerIndex
    bcall(_RclStatRegNN)
    bcall(_PushToStackX)
    ret

;-----------------------------------------------------------------------------

; Description: Calculate the population standard deviation.
; Output:
;   - OP1:Real=PDEV<Y>
;   - OP2:Real=PDEV<X>
; Destroys: A, OP2, OP3, OP4
mStatPopSdevHandler:
    call closeInputAndRecallNone
    ld ix, cfitModelLinear ; use linear model for simple statistics
    bcall(_StatStdDev)
    bcall(_PushOp1Op2ToStackXY)
    ret

; Description: Calculate the sample standard deviation.
; Output:
;   - OP1:Real=SDEV<Y>
;   - OP2:Real=SDEV<X>
; Destroys: A, OP2, OP3, OP4
mStatSampleSdevHandler:
    call closeInputAndRecallNone
    ld ix, cfitModelLinear ; use linear model for simple statistics
    bcall(_StatSampleStdDev)
    bcall(_PushOp1Op2ToStackXY)
    ret

; Description: Calculate the population covariance. PCOV<X,Y> = <XY> - <X><Y>.
; See https://en.wikipedia.org/wiki/Sample_mean_and_covariance
; Output:
;   - OP1: PCOV<X,Y>
; Destroys: A, OP2, OP3, OP4
mStatPopCovHandler:
    call closeInputAndRecallNone
    ld ix, cfitModelLinear ; use linear model for simple statistics
    bcall(_StatCovariance)
    bcall(_PushToStackX)
    ret

; Description: Calculate the sample covariance. SCOV<X,Y> = (N/(N-1)) PCOV(X,Y).
; See https://en.wikipedia.org/wiki/Sample_mean_and_covariance
; Output:
;   - OP1: SCOV<X,Y>
; Destroys: A, OP2, OP3, OP4
mStatSampleCovHandler:
    call closeInputAndRecallNone
    ld ix, cfitModelLinear ; use linear model for simple statistics
    bcall(_StatSampleCovariance)
    bcall(_PushToStackX)
    ret
