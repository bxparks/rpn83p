;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;-----------------------------------------------------------------------------

; Storage register indexes for various STAT components.
statRegX equ 11
statRegX2 equ 12
statRegY equ 13
statRegY2 equ 14
statRegXY equ 15
statRegN equ 16

;-----------------------------------------------------------------------------
; STAT Menu handlers.
;-----------------------------------------------------------------------------

mStatPlusHandler:
    call closeInputBuf
    call statSigmaPlus
    ld a, statRegN
    call rclNN ; OP1=R[sigmaN]
    res rpnFlagsLiftEnabled, (iy + rpnFlags)
    jp replaceX

mStatMinusHandler:
    call closeInputBuf
    call statSigmaMinus
    ld a, statRegN
    call rclNN ; OP1=R[sigmaN]
    res rpnFlagsLiftEnabled, (iy + rpnFlags)
    jp replaceX

; Description: Initialize the STAT functions.
initStat:
    ; [[fallthrough]]

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
mClearStatHandler:
    call closeInputBuf
    call clearStatRegs
    ld a, errorCodeStatCleared
    jp setHandlerCode

;-----------------------------------------------------------------------------

; Description: Calculate the Sum of X and Y into X and Y registers.
mStatSumHandler:
    call closeInputBuf
    ld a, statRegY
    call rclNN ; OP1=Ysum
    ld a, statRegX
    call rclNNToOP2 ; OP2=Xsum
    jp pushXY

; Description: Calculate the average of X and Y into X and Y registers.
mStatMeanHandler:
    call closeInputBuf
    call statMean
    jp pushXY

; Description: Calculate the average of X and Y into OP1 and OP2 registers.
; Output:
;   OP1=<Y>
;   OP2=<X>
statMean:
    ld a, statRegX
    call rclNN
    ld a, statRegN
    call rclNNToOP2
    bcall(_FPDiv) ; OP1=Xmean
    bcall(_PushRealO1)
    ;
    ld a, statRegY
    call rclNN
    ld a, statRegN
    call rclNNToOP2
    bcall(_FPDiv) ; OP1=<Y>
    bcall(_PopRealO2) ; OP2=<X>
    ret

; Description: Calculate the weighted mean of X and Y.
; Output:
;   Y: Mean of Y weighted by X = Sum(X,Y) / Sum(X)
;   X: Mean of X weighted by Y = Sum(X,Y) / Sum(Y)
mStatWeightedMeanHandler:
    call closeInputBuf
    call statWeightedMean ; OP1=WeightedY, OP2=WeightedX
    jp pushXY

; Description: Calculate the weighted mean of Y and X into OP1 and OP2,
; respectively.
; Output:
;   OP1: Mean of Y weighted by X = Sum(X,Y) / Sum(X)
;   OP2: Mean of X weighted by Y = Sum(X,Y) / Sum(Y)
statWeightedMean:
    ld a, statRegXY
    call rclNN
    bcall(_PushRealO1) ; FPS=SumXY
    ld a, statRegY
    call rclNNToOP2
    bcall(_FPDiv) ; OP1=SumXY/SumY
    ;
    call exchangeFPSOP1 ; OP1=SumXY, FPS=SumXY/SumY
    ld a, statRegX
    call rclNNToOP2 ; OP2=SumX
    bcall(_FPDiv) ; OP1=SumXY/SumX=WeightedY
    bcall(_PopRealO2); OP2=SumXY/SumY=WeightedX
    ret

; Description: Return the number of items entered. Mostly for convenience.
mStatNHandler:
    call closeInputBuf
    ld a, statRegN
    call rclNN
    jp pushX

;-----------------------------------------------------------------------------

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
; Output:
;   OP1: PDEV<Y>
;   OP2: PDEV<X>
; Destroys: A, OP2, OP3, OP4
mStatPopSdevHandler:
    call closeInputBuf
    call statStdDev
    jp pushXY

; Description: Calculate the sample standard deviation.
; Output:
;   OP1: SDEV<Y>
;   OP2: SDEV<X>
; Destroys: A, OP2, OP3, OP4
mStatSampleSdevHandler:
    call closeInputBuf
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

; Description: Calculate the population standard deviation.
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
; Output:
;   OP1: VAR<Y>
;   OP2: VAR<X>
; Destroys: A, OP3
; TODO: The algorithms for VAR<X> and VAR<Y> are identical. We should be able
; to extract that into a common routine to save memory.
statVariance:
    ld a, statRegX
    call rclNN
    ld a, statRegN
    call rclNNToOP2
    bcall(_FPDiv)
    bcall(_FPSquare) ; OP1=<X>^2
    bcall(_PushRealO1)
    ;
    ld a, statRegX2
    call rclNN
    ld a, statRegN
    call rclNNToOP2
    bcall(_FPDiv) ; OP1=<X^2>
    bcall(_PopRealO2) ; OP2=<X>^2
    bcall(_FPSub)
    bcall(_PushRealO1) ; OP1=VAR<X>
    ;
    ld a, statRegY
    call rclNN
    ld a, statRegN
    call rclNNToOP2
    bcall(_FPDiv)
    bcall(_FPSquare) ; OP1=<Y>^2
    bcall(_PushRealO1)
    ;
    ld a, statRegY2
    call rclNN
    ld a, statRegN
    call rclNNToOP2
    bcall(_FPDiv) ; OP1=<Y^2>
    bcall(_PopRealO2) ; OP2=<Y>^2
    bcall(_FPSub) ; OP1=VAR(Y)
    ;
    bcall(_PopRealO2) ; OP2=VAR<X>
    ret

; Description: Calculate the population covariance. PCOV<X,Y> = <XY> - <X><Y>.
; See https://en.wikipedia.org/wiki/Sample_mean_and_covariance
; Output:
;   - OP1: PCOV<X,Y>
; Destroys: A, OP2, OP3, OP4
mStatPopCovHandler:
    call closeInputBuf
    call statCovariance
    jp pushX

; Description: Calculate the sample covariance. SCOV<X,Y> = (N/(N-1)) PCOV(X,Y).
; See https://en.wikipedia.org/wiki/Sample_mean_and_covariance
; Output:
;   - OP1: SCOV<X,Y>
; Destroys: A, OP2, OP3, OP4
mStatSampleCovHandler:
    call closeInputBuf
    call statCovariance ; OP1=PCOV(X,Y)
    call statFactorPopToSampleOP2 ; OP2=N/(N-1)
    bcall(_FPMult); OP1=SCOV(X,Y)
    jp pushX

; Description: Calculate the population covariance of X and Y.
; PCOV(X, Y) = <XY> - <X><Y>).
; See https://en.wikipedia.org/wiki/Covariance_and_correlation
; Output:
;   - OP1: PCOV<X,Y>
; Destroys: A, OP2, OP3, OP4
statCovariance:
    ; Extract N
    ld a, statRegN
    call rclNNToOP2
    bcall(_OP2ToOP4) ; OP4=N
    ; Calculate <XY>
    ld a, statRegXY
    call rclNN
    bcall(_FPDiv) ; OP1=<XY>, uses OP3
    bcall(_PushRealO1) ; FPS=<XY>
    ; Calculate <X>
    ld a, statRegX
    call rclNN
    bcall(_OP4ToOP2) ; OP2=N
    bcall(_FPDiv) ; OP1=<X>
    bcall(_PushRealO1) ; FPS=<X>
    ; Calculate <Y>
    ld a, statRegY
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

;-----------------------------------------------------------------------------

; Description: Forecast Y from X.
mStatForcastYHandler:
    call closeInputBuf
    call rclX ; OP1=X
    bcall(_PushRealO1) ; FPS=X
    call statLinearFit ; OP1=intercept,OP2=slope
    call exchangeFPSOP1 ; OP1=X, FPS=intercept
    bcall(_FPMult) ; OP1=slope*X
    bcall(_PopRealO2) ; OP2=intercept
    bcall(_FPAdd) ; OP1=slope*X + intercept
    jp replaceX

; Description: Forecast X from Y.
mStatForcastXHandler:
    call closeInputBuf
    call rclX ; OP1=X=y
    bcall(_PushRealO1) ; FPS=y
    call statLinearFit ; OP1=intercept,OP2=slope
    call exchangeFPSOP2 ; OP2=y, FPS=slope
    bcall(_InvSub) ; OP1=y-intercept
    bcall(_PopRealO2) ; OP2=slope
    bcall(_FPDiv) ; OP1=(y-intercept) / slope = x
    jp replaceX

; Description: Calculate the least square fit slope into X register.
mStatSlopeHandler:
    call closeInputBuf
    call statLinearFit ; OP1=intercept,OP2=slope
    bcall(_OP1ExOP2)
    jp pushX

; Description: Calculate the least square fit intercept into X register.
mStatInterceptHandler:
    call closeInputBuf
    call statLinearFit ; OP1=intercept,OP2=slope
    jp pushX

; Description: Calculate the least square linear fit.
; Output:
;   OP1=SLOP(X,Y) = CORR(X,Y) (StdDev(Y)/StdDev(X)).
;   OP2=YINT(X,,Y) = <Y> - SLOP(X,Y) * <X>
;
; Either Population or Sample can be used, because the N/(N-1) terms cancel
; out. See https://en.wikipedia.org/wiki/Simple_linear_regression
statLinearFit:
    ; Calculate slope.
    call statStdDev ; OP1=PDEV(Y), OP2=PDEV(X)
    bcall(_FPDiv) ; OP1=PDEV(Y)/PDEV(X)
    bcall(_PushRealO1)
    call statCorrelation ; OP1=CORR(X,Y)
    bcall(_PopRealO2)
    bcall(_FPMult) ; OP1=SLOP=CORR(X,Y) * StdDev(Y) / StdDev(X)
    bcall(_PushRealO1) ; FPS=slope

    ; Calculate intercept.
    bcall(_PushRealO1) ; FPS=slope again
    call statMean; OP1=<Y>, OP2=<X>
    call exchangeFPSOP1 ; OP1=SLOP, FPS=<Y>
    bcall(_FPMult) ; OP1=SLOP * <X>
    bcall(_PopRealO2) ; OP2 = <Y>
    bcall(_InvSub) ; OP1 = -SLOP * <X> + <Y> = intercept

    bcall(_PopRealO2) ; OP2=slope
    ret

; Description: Calculate the correlation coefficient into X register.
mStatCorrelationHandler:
    call closeInputBuf
    call statCorrelation
    jp pushX

; Description: Calculate the correslation coeficient into OP1.
; R(X,,Y) = COV(X,Y)/StdDev(X)/StdDev(Y).
;
; Either Population or Sample versions can be used, because the N/(N-1) terms
; cancel out. See https://en.wikipedia.org/wiki/Correlation
statCorrelation:
    call statCovariance ; OP1=COV(X, Y)
    bcall(_PushRealO1)
    call statStdDev ; OP1=STDDEV(Y), OP2=STDDEV(X)
    call exchangeFPSOP1 ; OP1=COV(X,Y), FPS=STDDEV(Y)
    bcall(_FPDiv) ; OP1=COV(X,Y)/STDDEV(X)
    bcall(_PopRealO2) ; OP2=STDDEV(Y)
    bcall(_FPDiv) ; OP1=COV(X,Y)/STDDEV(X)/STDDEV(Y)
    ret

;-----------------------------------------------------------------------------

mStatLinFitHandler:
mStatLogFitHandler:
mStatExpFitHandler:
mStatPwrFitHandler:
mStatBestFitHandler:
    jp mNotYetHandler

mStatLinFitNameSelector:
mStatLogFitNameSelector:
mStatExpFitNameSelector:
mStatPwrFitNameSelector:
    ret

;-----------------------------------------------------------------------------

statSigmaPlus:
    call rclX
    bcall(_PushRealO1) ; FPST=X
    ld a, statRegX
    call stoPlusNN

    bcall(_FPSquare) ; OP1=X^2
    ld a, statRegX2
    call stoPlusNN

    call rclY
    bcall(_PushRealO1) ; FPST=Y
    ld a, statRegY
    call stoPlusNN

    bcall(_FPSquare) ; OP1=Y^2
    ld a, statRegY2
    call stoPlusNN

    bcall(_PopRealO2) ; OP2=Y
    bcall(_PopRealO1) ; OP1=X
    bcall(_FPMult)
    ld a, statRegXY
    call stoPlusNN

    ld a, statRegN
    call rclNN
    bcall(_Plus1)
    ld a, statRegN
    jp stoNN

statSigmaMinus:
    call rclX
    bcall(_PushRealO1) ; FPST=X
    ld a, statRegX
    call stoMinusNN

    bcall(_FPSquare) ; OP1=X^2
    ld a, statRegX2
    call stoMinusNN

    call rclY
    bcall(_PushRealO1) ; FPST=Y
    ld a, statRegY
    call stoMinusNN

    bcall(_FPSquare) ; OP1=Y^2
    ld a, statRegY2
    call stoMinusNN

    bcall(_PopRealO2) ; OP2=Y
    bcall(_PopRealO1) ; OP1=X
    bcall(_FPMult)
    ld a, statRegXY
    call stoMinusNN

    ld a, statRegN
    call rclNN
    bcall(_Minus1)
    ld a, statRegN
    jp stoNN
