;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023-2025 Brian T. Park
;
; Routines for STAT functions.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Add the X and Y data point to the stat registers.
; TODO: Use OP1 and OP2 as input parameters, instead of RclStackX and
; RclStackY. This would decouple this routine from the RPN stack, which allows
; easier migration to Flash Page 1 if necessary. But we would still have a
; dependency to the stat registers through StoStatRegNN() and RclStatRegNN().
; Destroys: OP1, OP2, OP4
StatSigmaPlus:
    bcall(_RclStackX)
    bcall(_PushRealO1) ; FPS=[X]
    ld c, statRegX
    bcall(_StoAddStatRegNN)

    bcall(_FPSquare) ; OP1=X^2
    ld c, statRegX2
    bcall(_StoAddStatRegNN)

    bcall(_RclStackY)
    bcall(_PushRealO1) ; FPS=[X,Y]
    ld c, statRegY
    bcall(_StoAddStatRegNN)

    bcall(_FPSquare) ; OP1=Y^2
    ld c, statRegY2
    bcall(_StoAddStatRegNN)

    bcall(_PopRealO2) ; FPS=[X]; OP2=Y
    bcall(_PopRealO1) ; FPS=[]; OP1=X
    bcall(_FPMult)
    ld c, statRegXY
    bcall(_StoAddStatRegNN)

    ld c, statRegN
    bcall(_RclStatRegNN)
    bcall(_Plus1)
    ld c, statRegN
    bcall(_StoStatRegNN)

    ; Check if we need to update the extended STAT registers.
    ld a, (statAllEnabled)
    or a
    ret z
    ; [[fallthrough]]

statSigmaPlusLogX:
    ; Update lnX registers.
    bcall(_RclStackX)
    bcall(_PushRealO1) ; FPS=[X]
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
    bcall(_PushRealO1) ; FPS=[X,lnX]
    ld c, statRegLnX
    bcall(_StoAddStatRegNN)
    ;
    bcall(_FPSquare) ; OP1=(lnX)^2
    ld c, statRegLnX2
    bcall(_StoAddStatRegNN)
    ; [[fallthrough]]

statSigmaPlusLogY:
    ; Update lnY registers
    bcall(_RclStackY)
    bcall(_PushRealO1) ; FPS=[X,lnX,Y]
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
    bcall(_PushRealO1) ; FPS=[X,lnX,Y,lnY]
    ld c, statRegLnY
    bcall(_StoAddStatRegNN)
    ;
    bcall(_FPSquare) ; OP1=(lnY)^2
    ld c, statRegLnY2
    bcall(_StoAddStatRegNN)

    ; Update XlnY, YlnY, lnXlnY
    bcall(_PopRealO4) ; FPS=[X,lnX,Y]; OP4=lnY
    bcall(_PopRealO1) ; FPS=[X,lnX]; OP1=Y
    bcall(_PopRealO2) ; FPS=[X]; OP2=lnX
    bcall(_FPMult) ; OP1=YlnX
    ld c, statRegYLnX
    bcall(_StoAddStatRegNN)
    ;
    bcall(_PopRealO1) ; FPS=[]; OP1=X
    bcall(_OP2ExOP4) ; OP2=lnY, OP4=lnX
    bcall(_FPMult) ; OP1=XlnY
    ld c, statRegXLnY
    bcall(_StoAddStatRegNN)
    ;
    bcall(_OP4ToOP1) ; OP1=lnX, OP2=lnY
    bcall(_FPMult) ; OP1=lnXlnY
    ld c, statRegLnXLnY
    bcall(_StoAddStatRegNN)
    ret

;-----------------------------------------------------------------------------

; Description: Subtract the X and Y data point from the stat registers.
; TODO: Use OP1 and OP2 as input parameters, instead of RclStackX and
; RclStackY. This would decouple this routine from the RPN stack, which allows
; easier migration to Flash Page 1 if necessary. But we would still have a
; dependency to the stat registers through StoStatRegNN() and RclStatRegNN().
; Destroys: OP1, OP2, OP4
StatSigmaMinus:
    bcall(_RclStackX)
    bcall(_PushRealO1) ; FPS=[X]
    ld c, statRegX
    bcall(_StoSubStatRegNN)

    bcall(_FPSquare) ; OP1=X^2
    ld c, statRegX2
    bcall(_StoSubStatRegNN)

    bcall(_RclStackY)
    bcall(_PushRealO1) ; FPS=[X,Y]
    ld c, statRegY
    bcall(_StoSubStatRegNN)

    bcall(_FPSquare) ; OP1=Y^2
    ld c, statRegY2
    bcall(_StoSubStatRegNN)

    bcall(_PopRealO2) ; FPS=[X]; OP2=Y
    bcall(_PopRealO1) ; FPS=[]; OP1=X
    bcall(_FPMult)
    ld c, statRegXY
    bcall(_StoSubStatRegNN)

    ld c, statRegN
    bcall(_RclStatRegNN)
    bcall(_Minus1)
    ld c, statRegN
    bcall(_StoStatRegNN)

    ; Check if we need to update the extended STAT registers.
    ld a, (statAllEnabled)
    or a
    ret z
    ; [[fallthrough]]

statSigmaMinusLogX:
    ; Update lnX registers.
    bcall(_RclStackX)
    bcall(_PushRealO1) ; FPS=[X]
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
    bcall(_PushRealO1) ; FPS=[X,lnX]
    ld c, statRegLnX
    bcall(_StoSubStatRegNN)
    ;
    bcall(_FPSquare) ; OP1=(lnX)^2
    ld c, statRegLnX2
    bcall(_StoSubStatRegNN)
    ; [[fallthrough]]

statSigmaMinusLogY:
    ; Update lnY registers
    bcall(_RclStackY)
    bcall(_PushRealO1) ; FPS=[X,lnX,Y]
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
    bcall(_PushRealO1) ; FPS=[X,lnX,Y,lnY]
    ld c, statRegLnY
    bcall(_StoSubStatRegNN)
    ;
    bcall(_FPSquare) ; OP1=(lnY)^2
    ld c, statRegLnY2
    bcall(_StoSubStatRegNN)

    ; Update XlnY, YlnY, lnXlnY
    bcall(_PopRealO4) ; FPS=[X,lnX,Y]; OP4=lnY
    bcall(_PopRealO1) ; FPS=[X,lnX]; OP1=Y
    bcall(_PopRealO2) ; FPS=[X]; OP2=lnX
    bcall(_FPMult) ; OP1=YlnX
    ld c, statRegYLnX
    bcall(_StoSubStatRegNN)
    ;
    bcall(_PopRealO1) ; FPS=[]; OP1=X
    bcall(_OP2ExOP4) ; OP2=lnY, OP4=lnX
    bcall(_FPMult) ; OP1=XlnY
    ld c, statRegXLnY
    bcall(_StoSubStatRegNN)
    ;
    bcall(_OP4ToOP1) ; OP1=lnX, OP2=lnY
    bcall(_FPMult) ; OP1=lnXlnY
    ld c, statRegLnXLnY
    bcall(_StoSubStatRegNN)
    ret

;-----------------------------------------------------------------------------

; Description: Calculate the Sum of X and Y into X and Y registers.
; Output:
;   - OP1=Ysum
;   - OP2=Xsum
StatSum:
    ld c, statRegY
    bcall(_RclStatRegNN) ; OP1=Ysum
    ld c, statRegX
    bcall(_RclStatRegNNToOP2) ; OP2=Xsum
    ret

;-----------------------------------------------------------------------------

; Description: Calculate the average of X and Y into OP1 and OP2 registers.
; Input:
;   - IX=pointer to list of stat registers (e.g. cfitModelLinear, cfitModelExp)
; Output:
;   - OP1=<Y>
;   - OP2=<X>
StatMean:
    ld c, (ix + modelIndX)
    bcall(_RclStatRegNN)
    ld c, (ix + modelIndN)
    bcall(_RclStatRegNNToOP2)
    bcall(_FPDiv) ; OP1=<X>
    bcall(_PushRealO1) ; FPS=[<X>]
    ;
    ld c, (ix + modelIndY)
    bcall(_RclStatRegNN)
    bcall(_FPDiv) ; OP1=<Y>
    bcall(_PopRealO2) ; FPS=[]; OP2=<X>
    ret

;-----------------------------------------------------------------------------

; Description: Calculate the weighted mean of Y and X into OP1 and OP2,
; respectively.
; Input:
;   - IX=pointer to list of stat registers (e.g. cfitModelLinear, cfitModelExp)
;   - statRegXxx
; Output:
;   - OP1:Real=Mean of Y weighted by X = Sum(X,Y) / Sum(X)
;   - OP2:Real=Mean of X weighted by Y = Sum(X,Y) / Sum(Y)
; Error conditions:
;   - If Sum(X) is 0, then Weighted<Y> is not defined so OP1 is set to
;   9.9999999999999E99 to indicate an error condition
;   - If Sum(Y) is 0, then Weighted<X> is not defined so OP2 is set to
;   9.9999999999999E99 to indicate an error condition
;   - If both Sum(X) and Sum(Y) are 0, then an 'Err: Stat' exception is thrown
StatWeightedMean:
    ld c, (ix + modelIndX)
    bcall(_RclStatRegNN)
    ld c, (ix + modelIndY)
    bcall(_RclStatRegNNToOP2)
    bcall(_CkOP1FP0)
    jr nz, statWeightedMeanWeightedX
    bcall(_CkOP2FP0)
    jr nz, statWeightedMeanWeightedX
statWeightedMeanBothZero:
    bcall(_ErrStat) ; throw exception
statWeightedMeanWeightedX:
    ; OP1=SumX, OP2=SumY
    bcall(_PushRealO1) ; FPS=[SumX]
    ld c, (ix + modelIndXY)
    bcall(_RclStatRegNN) ; OP1=SumXY, OP2=SumY
    bcall(_PushRealO1) ; FPS=[SumX, SumXY]
    bcall(_CkOP2FP0)
    jr z, statWeightedMeanSetWeightedXError
    bcall(_FPDiv) ; OP1=WeightedX=SumXY/SumY
    jr statWeightedMeanWeightedY
statWeightedMeanSetWeightedXError:
    call op1SetMaxFloatPageTwo
statWeightedMeanWeightedY:
    call exchangeFPSOP1PageTwo ; FPS=[SumX, WeightedX]; OP1=SumXY
    call exchangeFPSFPSPageTwo ; FPS=[WeightedX, SumX]; OP1=SumXY
    bcall(_PopRealO2) ; FPS=[WeightedX]; OP1=SumXY, OP2=SumX
    bcall(_CkOP2FP0)
    jr z, statWeightedMeanSetWeightedYError
    bcall(_FPDiv) ; OP1=WeightedY=SumXY/SumX
    jr statWeightedMeanFinish
statWeightedMeanSetWeightedYError:
    call op1SetMaxFloatPageTwo ; OP1=WeightedY
statWeightedMeanFinish:
    bcall(_PopRealO2) ; FPS=[]; OP2=WeightedX
    ret

;-----------------------------------------------------------------------------

; Description: Calculate the population standard deviation.
; Input:
;   - IX=pointer to list of stat registers (e.g. cfitModelLinear, cfitModelExp)
; Output:
;   - OP1=PDEV<Y>
;   - OP2=PDEV<X>
StatStdDev:
    call statVariance ; OP1=VAR(Y), OP2=VAR(X)
statStdDevAltEntry:
    bcall(_PushRealO2) ; FPS=[VAR(X)]
    bcall(_SqRoot) ; OP1=PDEV(Y)
    call exchangeFPSOP1PageTwo ; FPS=[PDEV(Y)]; OP1=VAR(X)
    bcall(_SqRoot) ; OP1=PDEV(X)
    bcall(_PopRealO2) ; FPS=[]; OP2=PDEV(Y)
    bcall(_OP1ExOP2) ; OP1=PDEV(Y), OP2=PDEV(X)
    ret

;-----------------------------------------------------------------------------

; Description: Calculate the sample standard deviation.
; Input:
;   - IX=pointer to list of stat registers (e.g. cfitModelLinear, cfitModelExp)
; Output:
;   - OP1=SDEV<Y>
;   - OP2=SDEV<X>
StatSampleStdDev:
    call statVariance ; OP1=VAR(Y), OP2=VAR(X)
    ; Multiply each VAR(x) with N/(N-1)
    bcall(_PushRealO2) ; FPS=[VAR(X)]
    call statFactorPopToSampleOP2 ; OP2=N/(N-1)
    bcall(_OP2ToOP4)
    bcall(_FPMult) ; OP1=SVAR(Y)
    call exchangeFPSOP1PageTwo ; OP1=VAR(X); FPS=[SVAR(Y)]
    bcall(_OP4ToOP2) ; OP2=N/(N-1)
    bcall(_FPMult) ; OP1=SVAR(X)
    bcall(_PopRealO2) ; FPS=[]; OP2=SVAR(Y)
    bcall(_OP1ExOP2) ; OP1=SVAR(Y), OP2=SVAR(X)
    jr statStdDevAltEntry

; Description: Calculate the correction factor (N)/(N-1) to convert population
; to sample statistics.
; Output: OP2=N/(N-1)
; Destroys: A, OP2
; Preserves: OP1
statFactorPopToSampleOP2:
    bcall(_PushRealO1) ; FPS=[OP1 saved]
    ld c, statRegN
    bcall(_RclStatRegNN) ; OP1=N
    bcall(_PushRealO1) ; FPS=[OP1,N]
    bcall(_Minus1)
    bcall(_OP1ToOP2)
    bcall(_PopRealO1) ; FPS=[OP1]; OP1=N, OP2=N-1
    bcall(_FPDiv) ; OP1=N/(N-1)
    bcall(_OP1ToOP2)
    bcall(_PopRealO1) ; FPS=[]; OP1=OP1 saved
    ret

;-----------------------------------------------------------------------------

; Description: Calculate the population variance.
; Var(X) = Sum(X_i^2 - <X>^2) / N = <X^2> - <X>^2
; Input:
;   - IX=pointer to list of stat registers (e.g. cfitModelLinear, cfitModelExp)
; Output:
;   - OP1:Real=VAR<Y>
;   - OP2:Real=VAR<X>
; Destroys: all, OP3
; TODO: The algorithms for VAR<X> and VAR<Y> are identical. We should be able
; to extract that into a common routine to save memory.
statVariance:
    ld c, (ix + modelIndX)
    bcall(_RclStatRegNN)
    ld c, (ix + modelIndN)
    bcall(_RclStatRegNNToOP2)
    bcall(_FPDiv)
    bcall(_FPSquare) ; OP1=<X>^2
    bcall(_PushRealO1) ; FPS=[<X>^2]
    ;
    ld c, (ix + modelIndX2)
    bcall(_RclStatRegNN)
    ld c, (ix + modelIndN)
    bcall(_RclStatRegNNToOP2)
    bcall(_FPDiv) ; OP1=<X^2>
    bcall(_PopRealO2) ; FPS=[]; OP2=<X>^2
    bcall(_FPSub)
    bcall(_PushRealO1) ; FPS=[VAR<X>]
    ;
    ld c, (ix + modelIndY)
    bcall(_RclStatRegNN)
    ld c, (ix + modelIndN)
    bcall(_RclStatRegNNToOP2)
    bcall(_FPDiv)
    bcall(_FPSquare) ; OP1=<Y>^2
    bcall(_PushRealO1) ; FPS=[VAR<X>,<Y>^2]
    ;
    ld c, (ix + modelIndY2)
    bcall(_RclStatRegNN)
    ld c, (ix + modelIndN)
    bcall(_RclStatRegNNToOP2)
    bcall(_FPDiv) ; OP1=<Y^2>
    bcall(_PopRealO2) ; FPS=[VAR<X>]; OP2=<Y>^2
    bcall(_FPSub) ; OP1=VAR(Y)
    ;
    bcall(_PopRealO2) ; FPS=[]; OP2=VAR<X>
    ret

;-----------------------------------------------------------------------------

; Description: Calculate the population covariance of X and Y.
; PCOV(X, Y) = <XY> - <X><Y>
; See https://en.wikipedia.org/wiki/Covariance_and_correlation
; Input:
;   - IX=pointer to list of stat registers (e.g. cfitModelLinear, cfitModelExp)
; Output:
;   - OP1:Real=PCOV<X,Y>
; Destroys: all, OP2, OP3, OP4
StatCovariance:
    ; Extract N
    ld c, (ix + modelIndN)
    bcall(_RclStatRegNNToOP2)
    bcall(_OP2ToOP4) ; OP4=N
    ; Calculate <XY>
    ld c, (ix + modelIndXY)
    bcall(_RclStatRegNN)
    bcall(_FPDiv) ; OP1=<XY>, uses OP3
    bcall(_PushRealO1) ; FPS=[<XY>]
    ; Calculate <X>
    ld c, (ix + modelIndX)
    bcall(_RclStatRegNN)
    bcall(_OP4ToOP2) ; OP2=N
    bcall(_FPDiv) ; OP1=<X>
    bcall(_PushRealO1) ; FPS=[<XY>,<X>]
    ; Calculate <Y>
    ld c, (ix + modelIndY)
    bcall(_RclStatRegNN)
    bcall(_OP4ToOP2) ; OP2=N
    bcall(_FPDiv) ; OP1=<Y>
    ;
    bcall(_PopRealO2) ; FPS=[<XY>]; OP2=<X>
    bcall(_FPMult) ; OP1=<X><Y>
    ;
    bcall(_PopRealO2) ; FPS=[]; OP2=<XY>
    bcall(_InvSub) ; OP1=-<X><Y> + <XY>
    ret

;-----------------------------------------------------------------------------

; Description: Calculate the sample covariance of X and Y.
; SCOV(X, Y) = (N/(N-1)) PCOV(X, Y).
; See https://en.wikipedia.org/wiki/Covariance_and_correlation
; Input:
;   - IX=pointer to list of stat registers (e.g. cfitModelLinear, cfitModelExp)
; Output:
;   - OP1:Real=SCOV<X,Y>
; Destroys: all, OP2, OP3, OP4
StatSampleCovariance:
    call StatCovariance ; OP1=PCOV(X,Y)
    call statFactorPopToSampleOP2 ; OP2=N/(N-1)
    bcall(_FPMult); OP1=SCOV(X,Y)
    ret

;-----------------------------------------------------------------------------

; Description: Calculate the correlation coeficient into OP1.
; R(X,,Y) = COV(X,Y)/StdDev(X)/StdDev(Y).
; Either Population or Sample versions can be used, because the N/(N-1) terms
; cancel out. See https://en.wikipedia.org/wiki/Correlation.
; Input:
;   - IX=pointer to list of stat registers (e.g. cfitModelLinear, cfitModelExp)
; Output:
;   - OP1=correlation coefficient in the range of [-1, 1].
; Destroys: all
StatCorrelation:
    call StatCovariance ; OP1=COV(X,Y)
    bcall(_PushRealO1) ; FPS=[COV(X,Y)]
    call StatStdDev ; OP1=STDDEV(Y), OP2=STDDEV(X)
    call exchangeFPSOP1PageTwo ; FPS=[STDDEV(Y)]; OP1=COV(X,Y)
    bcall(_FPDiv) ; OP1=COV(X,Y)/STDDEV(X)
    bcall(_PopRealO2) ; FPS=[]; OP2=STDDEV(Y)
    bcall(_FPDiv) ; OP1=COV(X,Y)/STDDEV(X)/STDDEV(Y)
    ret
