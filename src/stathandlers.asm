;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
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

; Curve fit model indexes for various curve fitting algorithms. The equivalent
; C-struct is:
;
;   struct CurveFitModel {
;       uint8_t statIndX;
;       uint8_t statIndX2;
;       uint8_t statIndY;
;       uint8_t statIndY2;
;       uint8_t statIndXY;
;       uint8_t statIndN;
;       void *statIndXToXPrime;
;       void *statIndXPrimeToX;
;       void *statIndYToYPrime;
;       void *statIndYPrimeToY;
;       void *statIndMToMPrime;
;       void *statIndMPrimeToM;
;       void *statIndBToBPrime;
;       void *statIndBPrimeToB;
;   };
;
statIndX equ 0
statIndX2 equ 1
statIndY equ 2
statIndY2 equ 3
statIndXY equ 4
statIndN equ 5
statIndXToXPrime equ 6
statIndXPrimeToX equ 8
statIndYToYPrime equ 10
statIndYPrimeToY equ 12
statIndMToMPrime equ 14
statIndMPrimeToM equ 16
statIndBToBPrime equ 18
statIndBPrimeToB equ 20

; Model parameters for Linear curve fitting.
;   y = b + m x
statModelLinear:
    .db statRegX
    .db statRegX2
    .db statRegY
    .db statRegY2
    .db statRegXY
    .db statRegN
    .dw statLinearXToXPrime
    .dw statLinearXPrimeToX
    .dw statLinearYToYPrime
    .dw statLinearYPrimeToY
    .dw statLinearMToMPrime
    .dw statLinearMPrimeToM
    .dw statLinearBToBPrime
    .dw statLinearBPrimeToB

; Model parameters for Logarithmic curve fitting.
;   y = b + m ln x
;   y = b + m x', where
;       x' = ln x
statModelLog:
    .db statRegLnX
    .db statRegLnX2
    .db statRegY
    .db statRegY2
    .db statRegYLnX
    .db statRegN
    .dw statLogXToXPrime
    .dw statLogXPrimeToX
    .dw statLogYToYPrime
    .dw statLogYPrimeToY
    .dw statLogMToMPrime
    .dw statLogMPrimeToM
    .dw statLogBToBPrime
    .dw statLogBPrimeToB

; Model parameters for Exponential curve fitting.
;   y = b e^(m x)
;   ln y = ln b + m x
;   y' = b' + m x, where
;       y' = ln y
;       b' = ln b
statModelExp:
    .db statRegX
    .db statRegX2
    .db statRegLnY
    .db statRegLnY2
    .db statRegXLnY
    .db statRegN
    .dw statExpXToXPrime
    .dw statExpXPrimeToX
    .dw statExpYToYPrime
    .dw statExpYPrimeToY
    .dw statExpMToMPrime
    .dw statExpMPrimeToM
    .dw statExpBToBPrime
    .dw statExpBPrimeToB

; Model parameters for Power curve fitting.
;   y = b x^m
;   ln y = ln b + m ln x
;   y' = b' + m x', where
;       y' = ln y
;       b' = ln b
;       x' = ln x
statModelPower:
    .db statRegLnX
    .db statRegLnX2
    .db statRegLnY
    .db statRegLnY2
    .db statRegLnXLnY
    .db statRegN
    .dw statPowerXToXPrime
    .dw statPowerXPrimeToX
    .dw statPowerYToYPrime
    .dw statPowerYPrimeToY
    .dw statPowerMToMPrime
    .dw statPowerMPrimeToM
    .dw statPowerBToBPrime
    .dw statPowerBPrimeToB

; Array of pointers to CurveFitModel structs. The equivalent C data object is:
;
; struct CurveFitModel *statModelList[4] = {
;   &statModelLinear,
;   &statModelLog,
;   &statModelExp,
;   &statModelPower,
; };
curveFitModelLinear equ 0
curveFitModelLog equ 1
curveFitModelExp equ 2
curveFitModelPower equ 3
statModelList:
    .dw statModelLinear
    .dw statModelLog
    .dw statModelExp
    .dw statModelPower

;-----------------------------------------------------------------------------

; Description: Initialize the STAT modes.
initStat:
    call mStatLinearModeHandler
    call mStatLinearFitHandler
    ret

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
    ld ix, statModelLinear
    call statMean
    jp pushXY

; Description: Calculate the weighted mean of X and Y.
; Output:
;   Y: Mean of Y weighted by X = Sum(X,Y) / Sum(X)
;   X: Mean of X weighted by Y = Sum(X,Y) / Sum(Y)
mStatWeightedMeanHandler:
    call closeInputBuf
    ld ix, statModelLinear
    call statWeightedMean ; OP1=WeightedY, OP2=WeightedX
    jp pushXY

; Description: Return the number of items entered. Mostly for convenience.
mStatNHandler:
    call closeInputBuf
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
    ld ix, statModelLinear
    call statStdDev
    jp pushXY

; Description: Calculate the sample standard deviation.
; Output:
;   OP1: SDEV<Y>
;   OP2: SDEV<X>
; Destroys: A, OP2, OP3, OP4
mStatSampleSdevHandler:
    call closeInputBuf
    ld ix, statModelLinear
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
    ld ix, statModelLinear
    call statCovariance
    jp pushX

; Description: Calculate the sample covariance. SCOV<X,Y> = (N/(N-1)) PCOV(X,Y).
; See https://en.wikipedia.org/wiki/Sample_mean_and_covariance
; Output:
;   - OP1: SCOV<X,Y>
; Destroys: A, OP2, OP3, OP4
mStatSampleCovHandler:
    call closeInputBuf
    ld ix, statModelLinear
    call statCovariance ; OP1=PCOV(X,Y)
    call statFactorPopToSampleOP2 ; OP2=N/(N-1)
    bcall(_FPMult); OP1=SCOV(X,Y)
    jp pushX

;-----------------------------------------------------------------------------
; Curve fitting handlers and routines.
;-----------------------------------------------------------------------------

; Description: Forecast Y from X.
mStatForcastYHandler:
    call closeInputBuf
    ld a, (curveFitModel)
    call statSelectCurveFitModel
    call rclX ; OP1=X
    call convertXToXPrime
    bcall(_PushRealO1) ; FPS=X
    call statLeastSquareFit ; OP1=intercept,OP2=slope
    call exchangeFPSOP1 ; OP1=X, FPS=intercept
    bcall(_FPMult) ; OP1=slope*X
    bcall(_PopRealO2) ; OP2=intercept
    bcall(_FPAdd) ; OP1=slope*X + intercept
    call convertYPrimeToY
    jp replaceX

; Description: Forecast X from Y.
mStatForcastXHandler:
    call closeInputBuf
    ld a, (curveFitModel)
    call statSelectCurveFitModel
    call rclX ; OP1=X=y
    call convertYToYPrime
    bcall(_PushRealO1) ; FPS=y
    call statLeastSquareFit ; OP1=intercept,OP2=slope
    call exchangeFPSOP2 ; OP2=y, FPS=slope
    bcall(_InvSub) ; OP1=y-intercept
    bcall(_PopRealO2) ; OP2=slope
    bcall(_FPDiv) ; OP1=(y-intercept) / slope = x
    call convertXPrimeToX
    jp replaceX

; Description: Calculate the least square fit slope into X register.
mStatSlopeHandler:
    call closeInputBuf
    ld a, (curveFitModel)
    call statSelectCurveFitModel
    call statLeastSquareFit ; OP1=intercept,OP2=slope
    bcall(_OP1ExOP2)
    call convertMPrimeToM
    jp pushX

; Description: Calculate the least square fit intercept into X register.
mStatInterceptHandler:
    call closeInputBuf
    ld a, (curveFitModel)
    call statSelectCurveFitModel
    call statLeastSquareFit ; OP1=intercept,OP2=slope
    call convertBPrimeToB
    jp pushX

; Description: Calculate the correlation coefficient into X register.
mStatCorrelationHandler:
    call closeInputBuf
    ld a, (curveFitModel)
    call statSelectCurveFitModel
    call statCorrelation
    jp pushX

;-----------------------------------------------------------------------------

mStatLinearFitHandler:
    ld a, curveFitModelLinear
    ld (curveFitModel), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

mStatLinearFitNameSelector:
    ld b, a
    ld a, (curveFitModel)
    cp curveFitModelLinear
    ld a, b
    ret nz
    ld a, c
    ret

;-----------------------------------------------------------------------------

mStatLogFitHandler:
    ld a, curveFitModelLog
    ld (curveFitModel), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

mStatLogFitNameSelector:
    ld b, a
    ld a, (curveFitModel)
    cp curveFitModelLog
    ld a, b
    ret nz
    ld a, c
    ret

;-----------------------------------------------------------------------------

mStatExpFitHandler:
    ld a, curveFitModelExp
    ld (curveFitModel), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

mStatExpFitNameSelector:
    ld b, a
    ld a, (curveFitModel)
    cp curveFitModelExp
    ld a, b
    ret nz
    ld a, c
    ret

;-----------------------------------------------------------------------------

mStatPowerFitHandler:
    ld a, curveFitModelPower
    ld (curveFitModel), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

mStatPowerFitNameSelector:
    ld b, a
    ld a, (curveFitModel)
    cp curveFitModelPower
    ld a, b
    ret nz
    ld a, c
    ret

;-----------------------------------------------------------------------------

mStatBestFitHandler:
    jp mNotYetHandler

;-----------------------------------------------------------------------------
; Low-level stats routines.
;-----------------------------------------------------------------------------

; Description: Add the X and Y data point to the stat registers.
; Destroys: OP1, OP2, OP4
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
    call stoNN

    ; Check if we need to update the extended STAT registers.
    bit rpnFlagsAllStatEnabled, (iy + rpnFlags)
    ret z

statSigmaPlusLogX:
    ; Update lnX registers.
    call rclX
    bcall(_CkOP1Pos) ; if OP1 > 0: ZF=1
    jr z, statSigmaPlusLogXNormal
    bcall(_OP1Set0) ; set lnX=0.0
    jr statSigmaPlusLogXZero
statSigmaPlusLogXNormal:
    bcall(_PushRealO1) ; FPST=X
    bcall(_LnX) ; OP1=lnX
statSigmaPlusLogXZero:
    bcall(_PushRealO1)
    bcall(_PushRealO1) ; FPST=FPS1=lnX
    ld a, statRegLnX
    call stoPlusNN
    ;
    bcall(_PopRealO1) ; OP1=lnX
    bcall(_FPSquare) ; OP1=(lnX)^2
    ld a, statRegLnX2
    call stoPlusNN

statSigmaPlusLogY:
    ; Update lnY registers
    call rclY
    bcall(_CkOP1Pos) ; if OP1 > 0: ZF=1
    jr z, statSigmaPlusLogYNormal
    bcall(_OP1Set0) ; set lnY=0.0
    jr statSigmaPlusLogYZero
statSigmaPlusLogYNormal:
    bcall(_PushRealO1) ; FPST=Y
    bcall(_LnX) ; OP1=lnY
statSigmaPlusLogYZero:
    bcall(_PushRealO1)
    bcall(_PushRealO1) ; FPST=FPS1=lnY
    ld a, statRegLnY
    call stoPlusNN
    ;
    bcall(_PopRealO1) ; OP1=lnY
    bcall(_FPSquare) ; OP1=(lnY)^2
    ld a, statRegLnY2
    call stoPlusNN

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
    call stoPlusNN
    ;
    bcall(_PopRealO1) ; OP1=X
    bcall(_OP2ExOP4) ; OP2=lnY, OP4=lnX
    bcall(_FPMult) ; OP1=XlnY
    ld a, statRegXLnY
    call stoPlusNN
    ;
    bcall(_OP4ToOP1) ; OP1=lnX, OP2=lnY
    bcall(_FPMult) ; OP1=lnXlnY
    ld a, statRegLnXLnY
    call stoPlusNN
    ret

;-----------------------------------------------------------------------------

; Description: Subtract the X and Y data point from the stat registers.
; Destroys: OP1, OP2, OP4
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
    call stoNN

    ; Check if we need to update the extended STAT registers.
    bit rpnFlagsAllStatEnabled, (iy + rpnFlags)
    ret z

statSigmaMinusLogX:
    ; Update lnX registers.
    call rclX
    bcall(_CkOP1Pos) ; if OP1 > 0: ZF=1
    jr z, statSigmaMinusLogXNormal
    bcall(_OP1Set0) ; set lnX=0.0
    jr statSigmaMinusLogXZero
statSigmaMinusLogXNormal:
    bcall(_PushRealO1) ; FPST=X
    bcall(_LnX) ; OP1=lnX
statSigmaMinusLogXZero:
    bcall(_PushRealO1)
    bcall(_PushRealO1) ; FPST=FPS1=lnX
    ld a, statRegLnX
    call stoMinusNN
    ;
    bcall(_PopRealO1) ; OP1=lnX
    bcall(_FPSquare) ; OP1=(lnX)^2
    ld a, statRegLnX2
    call stoMinusNN

    ; Update lnY registers
    call rclY
    bcall(_CkOP1Pos) ; if OP1 > 0: ZF=1
    jr z, statSigmaMinusLogYNormal
    bcall(_OP1Set0) ; set lnY=0.0
    jr statSigmaMinusLogYZero
statSigmaMinusLogYNormal:
    bcall(_PushRealO1) ; FPST=Y
    bcall(_LnX) ; OP1=lnY
statSigmaMinusLogYZero:
    bcall(_PushRealO1)
    bcall(_PushRealO1) ; FPST=FPS1=lnY
    ld a, statRegLnY
    call stoMinusNN
    ;
    bcall(_PopRealO1) ; OP1=lnY
    bcall(_FPSquare) ; OP1=(lnY)^2
    ld a, statRegLnY2
    call stoMinusNN

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
    call stoMinusNN
    ;
    bcall(_PopRealO1) ; OP1=X
    bcall(_OP2ExOP4) ; OP2=lnY, OP4=lnX
    bcall(_FPMult) ; OP1=XlnY
    ld a, statRegXLnY
    call stoMinusNN
    ;
    bcall(_OP4ToOP1) ; OP1=lnX, OP2=lnY
    bcall(_FPMult) ; OP1=lnXlnY
    ld a, statRegLnXLnY
    call stoMinusNN
    ret

;-----------------------------------------------------------------------------

; Description: Calculate the average of X and Y into OP1 and OP2 registers.
; Input:
;   IX=pointer to list of stat registers (e.g. statModelLinear, statModelExp)
; Output:
;   OP1=<Y>
;   OP2=<X>
statMean:
    ld a, (ix + statIndX)
    call rclNN
    ld a, (ix + statIndN)
    call rclNNToOP2
    bcall(_FPDiv) ; OP1=<X>
    bcall(_PushRealO1) ; FPST=<X>
    ;
    ld a, (ix + statIndY)
    call rclNN
    bcall(_FPDiv) ; OP1=<Y>
    bcall(_PopRealO2) ; OP2=<X>
    ret

; Description: Calculate the weighted mean of Y and X into OP1 and OP2,
; respectively.
; Input:
;   IX=pointer to list of stat registers (e.g. statModelLinear, statModelExp)
; Output:
;   OP1: Mean of Y weighted by X = Sum(X,Y) / Sum(X)
;   OP2: Mean of X weighted by Y = Sum(X,Y) / Sum(Y)
statWeightedMean:
    ld a, (ix + statIndXY)
    call rclNN
    bcall(_PushRealO1) ; FPS=SumXY
    ld a, (ix + statIndY)
    call rclNNToOP2
    bcall(_FPDiv) ; OP1=SumXY/SumY
    ;
    call exchangeFPSOP1 ; OP1=SumXY, FPS=SumXY/SumY
    ld a, (ix + statIndX)
    call rclNNToOP2 ; OP2=SumX
    bcall(_FPDiv) ; OP1=SumXY/SumX=WeightedY
    bcall(_PopRealO2); OP2=SumXY/SumY=WeightedX
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
;   IX=pointer to list of stat registers (e.g. statModelLinear, statModelExp)
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
;   IX=pointer to list of stat registers (e.g. statModelLinear, statModelExp)
; Output:
;   OP1: VAR<Y>
;   OP2: VAR<X>
; Destroys: A, OP3
; TODO: The algorithms for VAR<X> and VAR<Y> are identical. We should be able
; to extract that into a common routine to save memory.
statVariance:
    ld a, (ix + statIndX)
    call rclNN
    ld a, (ix + statIndN)
    call rclNNToOP2
    bcall(_FPDiv)
    bcall(_FPSquare) ; OP1=<X>^2
    bcall(_PushRealO1)
    ;
    ld a, (ix + statIndX2)
    call rclNN
    ld a, (ix + statIndN)
    call rclNNToOP2
    bcall(_FPDiv) ; OP1=<X^2>
    bcall(_PopRealO2) ; OP2=<X>^2
    bcall(_FPSub)
    bcall(_PushRealO1) ; OP1=VAR<X>
    ;
    ld a, (ix + statIndY)
    call rclNN
    ld a, (ix + statIndN)
    call rclNNToOP2
    bcall(_FPDiv)
    bcall(_FPSquare) ; OP1=<Y>^2
    bcall(_PushRealO1)
    ;
    ld a, (ix + statIndY2)
    call rclNN
    ld a, (ix + statIndN)
    call rclNNToOP2
    bcall(_FPDiv) ; OP1=<Y^2>
    bcall(_PopRealO2) ; OP2=<Y>^2
    bcall(_FPSub) ; OP1=VAR(Y)
    ;
    bcall(_PopRealO2) ; OP2=VAR<X>
    ret

; Description: Calculate the population covariance of X and Y.
; PCOV(X, Y) = <XY> - <X><Y>
; Input:
;   IX=pointer to list of stat registers (e.g. statModelLinear, statModelExp)
; See https://en.wikipedia.org/wiki/Covariance_and_correlation
; Output:
;   OP1: PCOV<X,Y>
; Destroys: A, OP2, OP3, OP4
statCovariance:
    ; Extract N
    ld a, (ix + statIndN)
    call rclNNToOP2
    bcall(_OP2ToOP4) ; OP4=N
    ; Calculate <XY>
    ld a, (ix + statIndXY)
    call rclNN
    bcall(_FPDiv) ; OP1=<XY>, uses OP3
    bcall(_PushRealO1) ; FPS=<XY>
    ; Calculate <X>
    ld a, (ix + statIndX)
    call rclNN
    bcall(_OP4ToOP2) ; OP2=N
    bcall(_FPDiv) ; OP1=<X>
    bcall(_PushRealO1) ; FPS=<X>
    ; Calculate <Y>
    ld a, (ix + statIndY)
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
; Input:
;   IX=pointer to list of stat registers (e.g. statModelLinear, statModelExp)
; Output:
;   OP1=correlation coefficient in the range of [-1, 1].
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

; Description: Calculate the least square fit.
; Input:
;   IX=pointer to list of stat registers (e.g. statModelLinear, statModelExp)
; Output:
;   OP1=SLOP(X,Y) = CORR(X,Y) (StdDev(Y)/StdDev(X)).
;   OP2=YINT(X,,Y) = <Y> - SLOP(X,Y) * <X>
;
; Either Population or Sample can be used, because the N/(N-1) terms cancel
; out. See https://en.wikipedia.org/wiki/Simple_linear_regression
statLeastSquareFit:
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

;-----------------------------------------------------------------------------

; Description: Select the curve fit model.
; Input: A: curveFitModel index [0-3]
; Output: IX: pointer to curve fit indirection indexes
; Destroys: A, DE, HL
statSelectCurveFitModel:
    add a, a ; A*=2
    ld e, a
    ld d, 0
    ld hl, statModelList
    add hl, de
    ld e, (hl)
    inc hl
    ld d, (hl)
    push de ; DE=(statModelList + 2*A)
    pop ix
    ret

; Description: Convert X to XPrime, according to model defined by IX.
; Input:
;   IX: curve fit model
;   OP1: X
; Output:
;   OP1: XPrime
; Destroys: HL
convertXToXPrime:
    ld l, (ix + statIndXToXPrime)
    ld h, (ix + statIndXToXPrime + 1)
    jp (hl)

; Description: Convert XPrime to X, according to model defined by IX.
; Input:
;   IX: curve fit model
;   OP1: XPrime
; Output:
;   OP1: X
; Destroys: HL
convertXPrimeToX:
    ld l, (ix + statIndXPrimeToX)
    ld h, (ix + statIndXPrimeToX + 1)
    jp (hl)

; Description: Convert Y to YPrime, according to model defined by IX.
; Input:
;   IX: curve fit model
;   OP1: Y
; Output:
;   OP1: YPrime
; Destroys: HL
convertYToYPrime:
    ld l, (ix + statIndYToYPrime)
    ld h, (ix + statIndYToYPrime + 1)
    jp (hl)

; Description: Convert YPrime to Y, according to model defined by IX.
; Input:
;   IX: curve fit model
;   OP1: YPrime
; Output:
;   OP1: Y
; Destroys: HL
convertYPrimeToY:
    ld l, (ix + statIndYPrimeToY)
    ld h, (ix + statIndYPrimeToY + 1)
    jp (hl)

; Description: Convert M to MPrime, according to model defined by IX.
; Input:
;   IX: curve fit model
;   OP1: M
; Output:
;   OP1: MPrime
; Destroys: HL
convertMToMPrime:
    ld l, (ix + statIndMToMPrime)
    ld h, (ix + statIndMToMPrime + 1)
    jp (hl)

; Description: Convert MPrime to M, according to model defined by IX.
; Input:
;   IX: curve fit model
;   OP1: MPrime
; Output:
;   OP1: M
; Destroys: HL
convertMPrimeToM:
    ld l, (ix + statIndMPrimeToM)
    ld h, (ix + statIndMPrimeToM + 1)
    jp (hl)

; Description: Convert B to BPrime, according to model defined by IX.
; Input:
;   IX: curve fit model
;   OP1: B
; Output:
;   OP1: BPrime
; Destroys: HL
convertBToBPrime:
    ld l, (ix + statIndBToBPrime)
    ld h, (ix + statIndBToBPrime + 1)
    jp (hl)

; Description: Convert BPrime to B, according to model defined by IX.
; Input:
;   IX: curve fit model
;   OP1: BPrime
; Output:
;   OP1: B
; Destroys: HL
convertBPrimeToB:
    ld l, (ix + statIndBPrimeToB)
    ld h, (ix + statIndBPrimeToB + 1)
    jp (hl)

;-----------------------------------------------------------------------------

; Parameter converters for linear fit.
statLinearXToXPrime:
statLinearXPrimeToX:
statLinearYToYPrime:
statLinearYPrimeToY:
statLinearMToMPrime:
statLinearMPrimeToM:
statLinearBToBPrime:
statLinearBPrimeToB:
    ret

;-----------------------------------------------------------------------------

; Parameter converters for logarithmic fit.
statLogXToXPrime:
    bcall(_LnX)
    ret
statLogXPrimeToX:
    bcall(_EToX)
    ret
statLogYToYPrime:
statLogYPrimeToY:
statLogMToMPrime:
statLogMPrimeToM:
statLogBToBPrime:
statLogBPrimeToB:
    ret

;-----------------------------------------------------------------------------

; Parameter converters for exponential fit.
statExpXToXPrime:
statExpXPrimeToX:
    ret
statExpYToYPrime:
    bcall(_LnX)
    ret
statExpYPrimeToY:
    bcall(_EToX)
    ret
statExpMToMPrime:
statExpMPrimeToM:
statExpBToBPrime:
    ret
statExpBPrimeToB:
    bcall(_EToX)
    ret

;-----------------------------------------------------------------------------

; Parameter converters for power fit.
statPowerXToXPrime:
    bcall(_LnX)
    ret
statPowerXPrimeToX:
    bcall(_EToX)
    ret
statPowerYToYPrime:
    bcall(_LnX)
    ret
statPowerYPrimeToY:
    bcall(_EToX)
    ret
statPowerMToMPrime:
statPowerMPrimeToM:
statPowerBToBPrime:
    ret
statPowerBPrimeToB:
    bcall(_EToX)
    ret
