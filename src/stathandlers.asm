;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Basic STAT handlers and lower level routines.
;
; TODO: Consider extracting the lower level routines into a separate stat.asm
; file.
;
; References:
;   - HP-42S Owner's Manual, Ch. 15
;   - https://en.wikipedia.org/wiki/Algorithms_for_calculating_variance
;   - https://en.wikipedia.org/wiki/Simple_linear_regression
;   - https://en.wikipedia.org/wiki/Covariance_and_correlation
;-----------------------------------------------------------------------------

; Direct register indexes for various STAT components.
statRegX equ 11
statRegX2 equ 12
statRegY equ 13
statRegY2 equ 14
statRegXY equ 15
statRegN equ 16
statRegLnX equ 17
statRegLnX2 equ 18
statRegLnY equ 19
statRegLnY2 equ 20
statRegLnXLnY equ 21
statRegXLnY equ 22
statRegYLnX equ 23

;-----------------------------------------------------------------------------

; Description: Initialize the STAT modes.
initStat:
    jp mStatAllModeHandler ; default AllSigma mode

;-----------------------------------------------------------------------------
; STAT Menu handlers.
;-----------------------------------------------------------------------------

mStatPlusHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call statSigmaPlus
    ld a, statRegN
    call rclNN ; OP1=R[sigmaN]
    call replaceX
    res rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

mStatMinusHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call statSigmaMinus
    ld a, statRegN
    call rclNN ; OP1=R[sigmaN]
    call replaceX
    res rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

; Description: Set STAT mode to ALL.
mStatAllModeHandler:
    set rpnFlagsAllStatEnabled, (iy + rpnFlags)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Set STAT mode to LINEAR.
mStatLinearModeHandler:
    res rpnFlagsAllStatEnabled, (iy + rpnFlags)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Select the display name of 'ALL<Sigma>'.
; Input:
;   - A: nameId
;   - B: base (2, 8, 10, 16)
;   - C: altNameId
mStatAllModeNameSelector:
    bit rpnFlagsAllStatEnabled, (iy + rpnFlags)
    ret z
    ld a, c
    ret

; Description: Select the display name of 'LIN<Sigma>'.
mStatLinearModeNameSelector:
    bit rpnFlagsAllStatEnabled, (iy + rpnFlags)
    ret nz
    ld a, c
    ret

mStatClearHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call clearStatRegs
    ld a, errorCodeStatCleared
    jp setHandlerCode

;-----------------------------------------------------------------------------

; Description: Calculate the Sum of X and Y into X and Y registers.
mStatSumHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, statRegY
    call rclNN ; OP1=Ysum
    ld a, statRegX
    call rclNNToOP2 ; OP2=Xsum
    jp pushXY

; Description: Calculate the average of X and Y into X and Y registers.
mStatMeanHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld ix, cfitModelLinear ; use linear model for simple statistics
    call statMean
    jp pushXY

; Description: Calculate the weighted mean of X and Y.
; Output:
;   Y: Mean of Y weighted by X = Sum(X,Y) / Sum(X)
;   X: Mean of X weighted by Y = Sum(X,Y) / Sum(Y)
mStatWeightedMeanHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld ix, cfitModelLinear ; use linear model for simple statistics
    call statWeightedMean ; OP1=WeightedY, OP2=WeightedX
    jp pushXY

; Description: Return the number of items entered. Mostly for convenience.
mStatNHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, statRegN
    call rclNN
    jp pushX

;-----------------------------------------------------------------------------

; Description: Calculate the population standard deviation.
; Output:
;   OP1: PDEV<Y>
;   OP2: PDEV<X>
; Destroys: A, OP2, OP3, OP4
mStatPopSdevHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld ix, cfitModelLinear ; use linear model for simple statistics
    call statStdDev
    jp pushXY

; Description: Calculate the sample standard deviation.
; Output:
;   OP1: SDEV<Y>
;   OP2: SDEV<X>
; Destroys: A, OP2, OP3, OP4
mStatSampleSdevHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld ix, cfitModelLinear ; use linear model for simple statistics
    call statVariance ; OP1=VAR(Y), OP2=VAR(X)
    ; Multiply each VAR(x) with N/(N-1)
    bcall(_PushRealO2) ; FPS=VAR(X)
    call statFactorPopToSampleOP2 ; OP2=N/(N-1)
    bcall(_OP2ToOP4)
    bcall(_FPMult) ; OP1=SVAR(Y)
    call exchangeFPSOP1 ; OP1=VAR(X); FPS=SVAR(Y)
    bcall(_OP4ToOP2) ; OP2=N/(N-1)
    bcall(_FPMult) ; OP1=SVAR(X)
    bcall(_PopRealO2) ; OP2=SVAR(Y)
    bcall(_OP1ExOP2) ; OP1=SVAR(Y), OP2=SVAR(X)
    call statStdDevAltEntry
    jp pushXY

; Description: Calculate the population covariance. PCOV<X,Y> = <XY> - <X><Y>.
; See https://en.wikipedia.org/wiki/Sample_mean_and_covariance
; Output:
;   - OP1: PCOV<X,Y>
; Destroys: A, OP2, OP3, OP4
mStatPopCovHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld ix, cfitModelLinear ; use linear model for simple statistics
    call statCovariance
    jp pushX

; Description: Calculate the sample covariance. SCOV<X,Y> = (N/(N-1)) PCOV(X,Y).
; See https://en.wikipedia.org/wiki/Sample_mean_and_covariance
; Output:
;   - OP1: SCOV<X,Y>
; Destroys: A, OP2, OP3, OP4
mStatSampleCovHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld ix, cfitModelLinear ; use linear model for simple statistics
    call statCovariance ; OP1=PCOV(X,Y)
    call statFactorPopToSampleOP2 ; OP2=N/(N-1)
    bcall(_FPMult); OP1=SCOV(X,Y)
    jp pushX

;-----------------------------------------------------------------------------
; Low-level stats routines.
;-----------------------------------------------------------------------------

; Description: Add the X and Y data point to the stat registers.
; Destroys: OP1, OP2, OP4
statSigmaPlus:
    call rclX
    bcall(_PushRealO1) ; FPST=X
    ld a, statRegX
    call stoAddNN

    bcall(_FPSquare) ; OP1=X^2
    ld a, statRegX2
    call stoAddNN

    call rclY
    bcall(_PushRealO1) ; FPST=Y
    ld a, statRegY
    call stoAddNN

    bcall(_FPSquare) ; OP1=Y^2
    ld a, statRegY2
    call stoAddNN

    bcall(_PopRealO2) ; OP2=Y
    bcall(_PopRealO1) ; OP1=X
    bcall(_FPMult)
    ld a, statRegXY
    call stoAddNN

    ld a, statRegN
    call rclNN
    bcall(_Plus1)
    ld a, statRegN
    call stoNN

    ; Check if we need to update the extended STAT registers.
    bit rpnFlagsAllStatEnabled, (iy + rpnFlags)
    ret z

statSigmaPlusLogX:
    ; Update lnX registers.
    call rclX
    bcall(_PushRealO1) ; FPST=X
    bcall(_CkOP1Pos) ; if OP1 >= 0: ZF=1
    jr nz, statSigmaPlusLogXZero
    bcall(_CkOP1FP0) ; if OP1 == 0: ZF=1
    jr nz, statSigmaPlusLogXNormal
statSigmaPlusLogXZero:
    bcall(_OP1Set0) ; set lnX=0.0
    jr statSigmaPlusLogXContinue
statSigmaPlusLogXNormal:
    bcall(_LnX) ; OP1=lnX
statSigmaPlusLogXContinue:
    bcall(_PushRealO1) ; FPST=lnX
    ld a, statRegLnX
    call stoAddNN
    ;
    bcall(_FPSquare) ; OP1=(lnX)^2
    ld a, statRegLnX2
    call stoAddNN

statSigmaPlusLogY:
    ; Update lnY registers
    call rclY
    bcall(_PushRealO1) ; FPST=Y
    bcall(_CkOP1Pos) ; if OP1 >= 0: ZF=1
    jr nz, statSigmaPlusLogYZero
    bcall(_CkOP1FP0) ; if OP1 == 0: ZF=1
    jr nz, statSigmaPlusLogYNormal
statSigmaPlusLogYZero:
    bcall(_OP1Set0) ; set lnY=0.0
    jr statSigmaPlusLogYContinue
statSigmaPlusLogYNormal:
    bcall(_LnX) ; OP1=lnY
statSigmaPlusLogYContinue:
    bcall(_PushRealO1) ; FPST=lnY
    ld a, statRegLnY
    call stoAddNN
    ;
    bcall(_FPSquare) ; OP1=(lnY)^2
    ld a, statRegLnY2
    call stoAddNN

    ; Update XlnY, YlnY, lnXlnY
    ; The FPS contains the following stack elements:
    ;   FPS0=lnY
    ;   FPS1=Y
    ;   FPS2=lnX
    ;   FPS3=X
    bcall(_PopRealO4) ; OP4=lnY
    bcall(_PopRealO1) ; OP1=Y
    bcall(_PopRealO2) ; OP2=lnX
    bcall(_FPMult) ; OP1=YlnX
    ld a, statRegYLnX
    call stoAddNN
    ;
    bcall(_PopRealO1) ; OP1=X
    bcall(_OP2ExOP4) ; OP2=lnY, OP4=lnX
    bcall(_FPMult) ; OP1=XlnY
    ld a, statRegXLnY
    call stoAddNN
    ;
    bcall(_OP4ToOP1) ; OP1=lnX, OP2=lnY
    bcall(_FPMult) ; OP1=lnXlnY
    ld a, statRegLnXLnY
    call stoAddNN
    ret

;-----------------------------------------------------------------------------

; Description: Subtract the X and Y data point from the stat registers.
; Destroys: OP1, OP2, OP4
statSigmaMinus:
    call rclX
    bcall(_PushRealO1) ; FPST=X
    ld a, statRegX
    call stoSubNN

    bcall(_FPSquare) ; OP1=X^2
    ld a, statRegX2
    call stoSubNN

    call rclY
    bcall(_PushRealO1) ; FPST=Y
    ld a, statRegY
    call stoSubNN

    bcall(_FPSquare) ; OP1=Y^2
    ld a, statRegY2
    call stoSubNN

    bcall(_PopRealO2) ; OP2=Y
    bcall(_PopRealO1) ; OP1=X
    bcall(_FPMult)
    ld a, statRegXY
    call stoSubNN

    ld a, statRegN
    call rclNN
    bcall(_Minus1)
    ld a, statRegN
    call stoNN

    ; Check if we need to update the extended STAT registers.
    bit rpnFlagsAllStatEnabled, (iy + rpnFlags)
    ret z

statSigmaMinusLogX:
    ; Update lnX registers.
    call rclX
    bcall(_PushRealO1) ; FPST=X
    bcall(_CkOP1Pos) ; if OP1 >= 0: ZF=1
    jr nz, statSigmaMinusLogXZero
    bcall(_CkOP1FP0) ; if OP1 == 0: ZF=1
    jr nz, statSigmaMinusLogXNormal
statSigmaMinusLogXZero:
    bcall(_OP1Set0) ; set lnX=0.0
    jr statSigmaMinusLogXContinue
statSigmaMinusLogXNormal:
    bcall(_LnX) ; OP1=lnX
statSigmaMinusLogXContinue:
    bcall(_PushRealO1) ; FPST=lnX
    ld a, statRegLnX
    call stoSubNN
    ;
    bcall(_FPSquare) ; OP1=(lnX)^2
    ld a, statRegLnX2
    call stoSubNN

statSigmaMinusLogY:
    ; Update lnY registers
    call rclY
    bcall(_PushRealO1) ; FPST=Y
    bcall(_CkOP1Pos) ; if OP1 >= 0: ZF=1
    jr nz, statSigmaMinusLogYZero
    bcall(_CkOP1FP0) ; if OP1 == 0: ZF=1
    jr nz, statSigmaMinusLogYNormal
statSigmaMinusLogYZero:
    bcall(_OP1Set0) ; set lnY=0.0
    jr statSigmaMinusLogYContinue
statSigmaMinusLogYNormal:
    bcall(_LnX) ; OP1=lnY
statSigmaMinusLogYContinue:
    bcall(_PushRealO1) ; FPST=lnY
    ld a, statRegLnY
    call stoSubNN
    ;
    bcall(_FPSquare) ; OP1=(lnY)^2
    ld a, statRegLnY2
    call stoSubNN

    ; Update XlnY, YlnY, lnXlnY
    ; The FPS contains the following stack elements:
    ;   FPS0=lnY
    ;   FPS1=Y
    ;   FPS2=lnX
    ;   FPS3=X
    bcall(_PopRealO4) ; OP4=lnY
    bcall(_PopRealO1) ; OP1=Y
    bcall(_PopRealO2) ; OP2=lnX
    bcall(_FPMult) ; OP1=YlnX
    ld a, statRegYLnX
    call stoSubNN
    ;
    bcall(_PopRealO1) ; OP1=X
    bcall(_OP2ExOP4) ; OP2=lnY, OP4=lnX
    bcall(_FPMult) ; OP1=XlnY
    ld a, statRegXLnY
    call stoSubNN
    ;
    bcall(_OP4ToOP1) ; OP1=lnX, OP2=lnY
    bcall(_FPMult) ; OP1=lnXlnY
    ld a, statRegLnXLnY
    call stoSubNN
    ret

;-----------------------------------------------------------------------------

; Description: Calculate the average of X and Y into OP1 and OP2 registers.
; Input:
;   IX=pointer to list of stat registers (e.g. cfitModelLinear, cfitModelExp)
; Output:
;   OP1=<Y>
;   OP2=<X>
statMean:
    ld a, (ix + modelIndX)
    call rclNN
    ld a, (ix + modelIndN)
    call rclNNToOP2
    bcall(_FPDiv) ; OP1=<X>
    bcall(_PushRealO1) ; FPST=<X>
    ;
    ld a, (ix + modelIndY)
    call rclNN
    bcall(_FPDiv) ; OP1=<Y>
    bcall(_PopRealO2) ; OP2=<X>
    ret

; Description: Calculate the weighted mean of Y and X into OP1 and OP2,
; respectively.
; Input:
;   IX=pointer to list of stat registers, most likely 'cfitModelLinear'
; Output:
;   OP1: Mean of Y weighted by X = Sum(X,Y) / Sum(X)
;   OP2: Mean of X weighted by Y = Sum(X,Y) / Sum(Y)
; Error conditions:
;   - If Sum(X) is 0, then Weighted<Y> is not defined so OP1 is set to
;   9.9999999999999E99 to indicate an error condition
;   - If Sum(Y) is 0, then Weighted<X> is not defined so OP2 is set to
;   9.9999999999999E99 to indicate an error condition
;   - If both Sum(X) and Sum(Y) are 0, then an 'Err: Stat' exception is thrown
statWeightedMean:
    ld a, (ix + modelIndX)
    call rclNN
    ld a, (ix + modelIndY)
    call rclNNToOP2
    bcall(_CkOP1FP0)
    jr nz, statWeightedMeanWeightedX
    bcall(_CkOP2FP0)
    jr nz, statWeightedMeanWeightedX
statWeightedMeanBothZero:
    bcall(_ErrStat) ; throw exception
statWeightedMeanWeightedX:
    ; OP1=SumX, OP2=SumY
    bcall(_PushRealO1) ; FPS=[SumX]
    ld a, (ix + modelIndXY)
    call rclNN ; OP1=SumXY, OP2=SumY
    bcall(_PushRealO1) ; FPS=[SumX, SumXY]
    bcall(_CkOP2FP0)
    jr z, statWeightedMeanSetWeightedXError
    bcall(_FPDiv) ; OP1=WeightedX=SumXY/SumY
    jr statWeightedMeanWeightedY
statWeightedMeanSetWeightedXError:
    call op1SetMaxFloat
statWeightedMeanWeightedY:
    call exchangeFPSOP1 ; OP1=SumXY, FPS=[SumX, WeightedX]
    call exchangeFPSFPS ; OP1=SumXY. FPS=[WeightedX, SumX]
    bcall(_PopRealO2); OP1=SumXY, OP2=SumX, FPS=[WeightedX]
    bcall(_CkOP2FP0)
    jr z, statWeightedMeanSetWeightedYError
    bcall(_FPDiv) ; OP1=WeightedY=SumXY/SumX
    jr statWeightedMeanFinish
statWeightedMeanSetWeightedYError:
    call op1SetMaxFloat ; OP1=WeightedY
statWeightedMeanFinish:
    bcall(_PopRealO2); OP2=WeightedX
    ret

; Description: Calculate the correction factor (N)/(N-1) to convert population
; to sample statistics.
; Output: OP2=N/(N-1)
; Destroys: A, OP2
; Preserves: OP1
statFactorPopToSampleOP2:
    bcall(_PushRealO1)
    ld a, statRegN
    call rclNN ; OP1=N
    bcall(_PushRealO1)
    bcall(_Minus1)
    bcall(_OP1ToOP2)
    bcall(_PopRealO1) ; OP1=N, OP2=N-1
    bcall(_FPDiv) ; OP1=N/(N-1)
    bcall(_OP1ToOP2)
    bcall(_PopRealO1)
    ret

; Description: Calculate the population standard deviation.
; Input:
;   IX=pointer to list of stat registers (e.g. cfitModelLinear, cfitModelExp)
; Output:
;   OP1=PDEV<Y>
;   OP2=PDEV<X>
statStdDev:
    call statVariance ; OP1=VAR(Y), OP2=VAR(X)
statStdDevAltEntry:
    bcall(_PushRealO2) ; FPS=VAR(X)
    bcall(_SqRoot) ; OP1=PDEV(Y)
    call exchangeFPSOP1 ; OP1=VAR(X); FPS=PDEV(Y)
    bcall(_SqRoot) ; OP1=PDEV(X)
    bcall(_PopRealO2) ; OP2=PDEV(Y)
    bcall(_OP1ExOP2) ; OP1=PDEV(Y), OP2=PDEV(X)
    ret

; Description: Calculate the population variance.
; Var(X) = Sum(X_i^2 - <X>^2) / N = <X^2> - <X>^2
; Input:
;   IX=pointer to list of stat registers (e.g. cfitModelLinear, cfitModelExp)
; Output:
;   OP1: VAR<Y>
;   OP2: VAR<X>
; Destroys: A, OP3
; TODO: The algorithms for VAR<X> and VAR<Y> are identical. We should be able
; to extract that into a common routine to save memory.
statVariance:
    ld a, (ix + modelIndX)
    call rclNN
    ld a, (ix + modelIndN)
    call rclNNToOP2
    bcall(_FPDiv)
    bcall(_FPSquare) ; OP1=<X>^2
    bcall(_PushRealO1)
    ;
    ld a, (ix + modelIndX2)
    call rclNN
    ld a, (ix + modelIndN)
    call rclNNToOP2
    bcall(_FPDiv) ; OP1=<X^2>
    bcall(_PopRealO2) ; OP2=<X>^2
    bcall(_FPSub)
    bcall(_PushRealO1) ; OP1=VAR<X>
    ;
    ld a, (ix + modelIndY)
    call rclNN
    ld a, (ix + modelIndN)
    call rclNNToOP2
    bcall(_FPDiv)
    bcall(_FPSquare) ; OP1=<Y>^2
    bcall(_PushRealO1)
    ;
    ld a, (ix + modelIndY2)
    call rclNN
    ld a, (ix + modelIndN)
    call rclNNToOP2
    bcall(_FPDiv) ; OP1=<Y^2>
    bcall(_PopRealO2) ; OP2=<Y>^2
    bcall(_FPSub) ; OP1=VAR(Y)
    ;
    bcall(_PopRealO2) ; OP2=VAR<X>
    ret

; Description: Calculate the population covariance of X and Y.
; PCOV(X, Y) = <XY> - <X><Y>
; See https://en.wikipedia.org/wiki/Covariance_and_correlation
; Input:
;   IX=pointer to list of stat registers (e.g. cfitModelLinear, cfitModelExp)
; Output:
;   OP1: PCOV<X,Y>
; Destroys: A, OP2, OP3, OP4
statCovariance:
    ; Extract N
    ld a, (ix + modelIndN)
    call rclNNToOP2
    bcall(_OP2ToOP4) ; OP4=N
    ; Calculate <XY>
    ld a, (ix + modelIndXY)
    call rclNN
    bcall(_FPDiv) ; OP1=<XY>, uses OP3
    bcall(_PushRealO1) ; FPS=<XY>
    ; Calculate <X>
    ld a, (ix + modelIndX)
    call rclNN
    bcall(_OP4ToOP2) ; OP2=N
    bcall(_FPDiv) ; OP1=<X>
    bcall(_PushRealO1) ; FPS=<X>
    ; Calculate <Y>
    ld a, (ix + modelIndY)
    call rclNN
    bcall(_OP4ToOP2) ; OP2=N
    bcall(_FPDiv) ; OP1=<Y>
    ;
    bcall(_PopRealO2) ; OP2=<X>
    bcall(_FPMult) ; OP1=<X><Y>
    ;
    bcall(_PopRealO2) ; OP2=<XY>
    bcall(_InvSub) ; OP1=-<X><Y> + <XY>
    ret

; Description: Calculate the correslation coeficient into OP1.
; R(X,,Y) = COV(X,Y)/StdDev(X)/StdDev(Y).
; Either Population or Sample versions can be used, because the N/(N-1) terms
; cancel out. See https://en.wikipedia.org/wiki/Correlation.
; Input:
;   IX=pointer to list of stat registers (e.g. cfitModelLinear, cfitModelExp)
; Output:
;   OP1=correlation coefficient in the range of [-1, 1].
statCorrelation:
    call statCovariance ; OP1=COV(X, Y)
    bcall(_PushRealO1)
    call statStdDev ; OP1=STDDEV(Y), OP2=STDDEV(X)
    call exchangeFPSOP1 ; OP1=COV(X,Y), FPS=STDDEV(Y)
    bcall(_FPDiv) ; OP1=COV(X,Y)/STDDEV(X)
    bcall(_PopRealO2) ; OP2=STDDEV(Y)
    bcall(_FPDiv) ; OP1=COV(X,Y)/STDDEV(X)/STDDEV(Y)
    ret
