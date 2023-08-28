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

mStatAllRegsHandler:
mStatLinearRegsHandler:
    jp mNotYetHandler

mStatAllRegsNameSelector:
mStatLinearRegsNameSelector:
    ret

mStatClearHandler:
mClearStatHandler:
    call closeInputBuf
    call clearStatRegs
    ld a, errorCodeStatCleared
    jp setHandlerCode

;-----------------------------------------------------------------------------

mStatSumHandler:
    call closeInputBuf
    ld a, statRegY
    call rclNN ; OP1=Ysum
    ld a, statRegX
    call rclNNToOP2 ; OP2=Xsum
    jp replaceXYWithOP1OP2

mStatMeanHandler:
    call closeInputBuf
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
    bcall(_FPDiv) ; OP1=Ymean
    bcall(_PopRealO2) ; OP2=Xmean
    jp replaceXYWithOP1OP2

; Description: Average of X, weighted by Y. Sum(XY) / Sum(Y).
mStatWeightedMeanXHandler:
    call closeInputBuf
    ld a, statRegXY
    call rclNN
    ld a, statRegY
    call rclNNToOP2
    bcall(_FPDiv)
    jp replaceX

; Description: Average of Y, weighted by X. Sum(XY) / Sum(X).
mStatWeightedMeanYHandler:
    call closeInputBuf
    ld a, statRegXY
    call rclNN
    ld a, statRegX
    call rclNNToOP2
    bcall(_FPDiv)
    jp replaceX

; Description: Return the number of items entered. Mostly for convenience.
mStatNHandler:
    call closeInputBuf
    ld a, statRegN
    call rclNN
    jp replaceX

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
    call statVariance ; OP1=VAR(Y), OP2=VAR(X)
mStatPopSdevAltEntry:
    bcall(_PushRealO2) ; FPS=VAR(X)
    bcall(_SqRoot) ; OP1=PDEV(Y)
    call exchangeFPSOP1 ; OP1=VAR(X); FPS=PDEV(Y)
    bcall(_SqRoot) ; OP1=PDEV(X)
    bcall(_PopRealO2) ; OP2=PDEV(Y)
    bcall(_OP1ExOP2) ; OP1=PDEV(Y), OP2=PDEV(X)
    jp replaceXYWithOP1OP2

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
    jr mStatPopSdevAltEntry

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
    jp replaceX

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
    jp replaceX

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

mStatCalcXHandler:
mStatCalcYHandler:
mStatSlopeHandler:
mStatInterceptHandler:
mStatCorrelationHandler:
    jp mNotYetHandler

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
    ld a, statRegX
    call stoPlusNN

    call rclY
    ld a, statRegY
    call stoPlusNN

    call rclX
    bcall(_FPSquare)
    ld a, statRegX2
    call stoPlusNN

    call rclY
    bcall(_FPSquare)
    ld a, statRegY2
    call stoPlusNN

    call rclX
    bcall(_OP1ToOP2)
    call rclY
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
    ld a, statRegX
    call stoMinusNN

    call rclY
    ld a, statRegY
    call stoMinusNN

    call rclX
    bcall(_FPSquare)
    ld a, statRegX2
    call stoMinusNN

    call rclY
    bcall(_FPSquare)
    ld a, statRegY2
    call stoMinusNN

    call rclX
    bcall(_OP1ToOP2)
    call rclY
    bcall(_FPMult)
    ld a, statRegXY
    call stoMinusNN

    ld a, statRegN
    call rclNN
    bcall(_Minus1)
    ld a, statRegN
    jp stoNN
