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

mStatPopSdevHandler:
    call closeInputBuf
    call mStatPopSdevCommon ; OP1=PDEV<Y>, OP2=PDEV<X>
    jp replaceXYWithOP1OP2

; Description: Calculate the sample standard deviation.
; Output:
;   OP1: SDEV<Y>
;   OP2: SDEV<X>
; TODO: The calculation for X and Y are essentially identical. We should be
; able to extract that into a common routine to save memory.
mStatSampleSdevHandler:
    call closeInputBuf
    ld a, statRegN
    call rclNN ; OP1=N
    bcall(_PushRealO1)
    bcall(_Minus1)
    bcall(_OP1ToOP2)
    bcall(_PopRealO1) ; OP1=N, OP2=N-1
    bcall(_FPDiv) ; OP1=N/(N-1)
    bcall(_SqRoot) ; OP1=sqrt(N/(N-1))
    bcall(_OP1ToOP4) ; OP4=sqrt(N/(N-1))

    call mStatPopSdevCommon ; OP1=PDEV<Y>, OP2=PDEV<X>
    bcall(_OP2ToOP5) ; OP5=PDEV<X> saved
    bcall(_OP4ToOP2) ; OP2=sqrt(N/(N-1))
    bcall(_FPMult) ; OP1=SDEV<Y>
    bcall(_OP1ExOP5) ; OP1=PDEV<X>
    bcall(_OP4ToOP2) ; OP2=sqrt(N/(N-1))
    bcall(_FPMult) ; OP1=SDEV<X>
    bcall(_OP5ToOP2) ; OP2=SDEV<Y>
    bcall(_OP1ExOP2) ; OP1=SDEV<Y>, OP2=SDEV<X>
    jp replaceXYWithOP1OP2

; Description: Calculate the population standard deviation.
; Output:
;   OP1: PDEV<Y>
;   OP2: PDEV<X>
; TODO: The algorithms for PDEV<X> and PDEV<Y> are identical. We should be able
; to extract that into a common routine to save memory.
mStatPopSdevCommon:
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
    bcall(_SqRoot) ; OP1=PDEV<X>
    bcall(_PushRealO1)
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
    bcall(_FPSub)
    bcall(_SqRoot) ; OP1=PDEV<Y>
    ;
    bcall(_PopRealO2) ; OP2=PDEV<X>
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
