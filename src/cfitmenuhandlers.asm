;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; CFIT menu handlers, as well as lower level curve fitting routines.
;
; TODO: Consider spliting the lower level routines into a cfit.asm file.
;
; References:
;   - HP-42S Owner's Manual, Ch. 15
;   - https://en.wikipedia.org/wiki/Algorithms_for_calculating_variance
;   - https://en.wikipedia.org/wiki/Simple_linear_regression
;-----------------------------------------------------------------------------

; Curve fit model parameters for various curve fitting algorithms. The
; equivalent C-struct is:
;
;   struct CurveFitModel {
;       uint8_t modelIndX;
;       uint8_t modelIndX2;
;       uint8_t modelIndY;
;       uint8_t modelIndY2;
;       uint8_t modelIndXY;
;       uint8_t modelIndN;
;       void *modelIndXToXPrime;
;       void *modelIndXPrimeToX;
;       void *modelIndYToYPrime;
;       void *modelIndYPrimeToY;
;       void *modelIndMPrimeToM;
;       void *modelIndBPrimeToB;
;   };
;
modelIndX equ 0
modelIndX2 equ 1
modelIndY equ 2
modelIndY2 equ 3
modelIndXY equ 4
modelIndN equ 5
modelIndXToXPrime equ 6
modelIndXPrimeToX equ 8
modelIndYToYPrime equ 10
modelIndYPrimeToY equ 12
modelIndMPrimeToM equ 14
modelIndBPrimeToB equ 16

; Model parameters for Linear curve fitting.
;   y = b + m x
cfitModelLinear:
    .db statRegX
    .db statRegX2
    .db statRegY
    .db statRegY2
    .db statRegXY
    .db statRegN
    .dw convertLinearXToXPrime
    .dw convertLinearXPrimeToX
    .dw convertLinearYToYPrime
    .dw convertLinearYPrimeToY
    .dw convertLinearMPrimeToM
    .dw convertLinearBPrimeToB

; Model parameters for Logarithmic curve fitting.
;   y = b + m ln x
;   y = b + m x', where
;       x' = ln x
cfitModelLog:
    .db statRegLnX
    .db statRegLnX2
    .db statRegY
    .db statRegY2
    .db statRegYLnX
    .db statRegN
    .dw convertLogXToXPrime
    .dw convertLogXPrimeToX
    .dw convertLogYToYPrime
    .dw convertLogYPrimeToY
    .dw convertLogMPrimeToM
    .dw convertLogBPrimeToB

; Model parameters for Exponential curve fitting.
;   y = b e^(m x)
;   ln y = ln b + m x
;   y' = b' + m x, where
;       y' = ln y
;       b' = ln b
cfitModelExp:
    .db statRegX
    .db statRegX2
    .db statRegLnY
    .db statRegLnY2
    .db statRegXLnY
    .db statRegN
    .dw convertExpXToXPrime
    .dw convertExpXPrimeToX
    .dw convertExpYToYPrime
    .dw convertExpYPrimeToY
    .dw convertExpMPrimeToM
    .dw convertExpBPrimeToB

; Model parameters for Power curve fitting.
;   y = b x^m
;   ln y = ln b + m ln x
;   y' = b' + m x', where
;       y' = ln y
;       b' = ln b
;       x' = ln x
cfitModelPower:
    .db statRegLnX
    .db statRegLnX2
    .db statRegLnY
    .db statRegLnY2
    .db statRegLnXLnY
    .db statRegN
    .dw convertPowerXToXPrime
    .dw convertPowerXPrimeToX
    .dw convertPowerYToYPrime
    .dw convertPowerYPrimeToY
    .dw convertPowerMPrimeToM
    .dw convertPowerBPrimeToB

; Array of pointers to CurveFitModel structs. The equivalent C data object is:
;
; struct CurveFitModel *cfitModelList[4] = {
;   &cfitModelLinear,
;   &cfitModelLog,
;   &cfitModelExp,
;   &cfitModelPower,
; };
curveFitModelLinear equ 0
curveFitModelLog equ 1
curveFitModelExp equ 2
curveFitModelPower equ 3
cfitModelList:
    .dw cfitModelLinear
    .dw cfitModelLog
    .dw cfitModelExp
    .dw cfitModelPower

;-----------------------------------------------------------------------------
coldInitCfit:
    jp mCfitLinearHandler ; default Linear curve fit

; Description: Forecast Y from X.
mCfitForcastYHandler:
    call closeInputAndRecallX ; OP1=x
    ld a, (curveFitModel)
    call selectCfitModel
    call convertXToXPrime ; OP1=xprime
    bcall(_PushRealO1) ; FPS=[xprime]
    call fitLeastSquare ; OP1=intercept, OP2=slope
    call exchangeFPSOP1 ; FPS=[intercept]; OP1=xprime
    bcall(_FPMult) ; OP1=slope*xprime
    bcall(_PopRealO2) ; FPS=[]; OP2=intercept
    bcall(_FPAdd) ; OP1=yprime=slope*xprime + intercept
    call convertYPrimeToY ; OP1=y
    jp replaceX

; Description: Forecast X from Y.
mCfitForcastXHandler:
    call closeInputAndRecallX ; OP1=y
    ld a, (curveFitModel)
    call selectCfitModel
    call convertYToYPrime ; OP1=yprime
    bcall(_PushRealO1) ; FPS=[yprime]
    call fitLeastSquare ; OP1=intercept,OP2=slope
    call exchangeFPSOP2 ; FPS=[slope]; OP2=yprime
    bcall(_InvSub) ; OP1=y-intercept
    bcall(_PopRealO2) ; FPS=[]; OP2=slope
    bcall(_FPDiv) ; OP1=xprime=(y-intercept) / slope
    call convertXPrimeToX ; OP1=x
    jp replaceX

; Description: Calculate the least square fit slope into X register.
mCfitSlopeHandler:
    call closeInputAndRecallNone
    ld a, (curveFitModel)
    call selectCfitModel
    call fitLeastSquare ; OP1=intercept,OP2=slope
    bcall(_OP1ExOP2)
    call convertMPrimeToM
    jp pushToX

; Description: Calculate the least square fit intercept into X register.
mCfitInterceptHandler:
    call closeInputAndRecallNone
    ld a, (curveFitModel)
    call selectCfitModel
    call fitLeastSquare ; OP1=intercept,OP2=slope
    call convertBPrimeToB
    jp pushToX

; Description: Calculate the correlation coefficient into X register.
mCfitCorrelationHandler:
    call closeInputAndRecallNone
    ld a, (curveFitModel)
    call selectCfitModel
    call statCorrelation
    jp pushToX

;-----------------------------------------------------------------------------

mCfitLinearHandler:
    ld a, curveFitModelLinear
    ld (curveFitModel), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mCfitLinearNameSelector:
    ld a, (curveFitModel)
    cp curveFitModelLinear
    jr z, mCfitLinearNameSelectorAlt
    or a ; CF=0
    ret
mCfitLinearNameSelectorAlt:
    scf
    ret

;-----------------------------------------------------------------------------

mCfitLogHandler:
    ld a, curveFitModelLog
    ld (curveFitModel), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mCfitLogNameSelector:
    ld a, (curveFitModel)
    cp curveFitModelLog
    jr z, mCfitLogNameSelectorAlt
    or a ; CF=0
    ret
mCfitLogNameSelectorAlt:
    scf
    ret

;-----------------------------------------------------------------------------

mCfitExpHandler:
    ld a, curveFitModelExp
    ld (curveFitModel), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mCfitExpNameSelector:
    ld a, (curveFitModel)
    cp curveFitModelExp
    jr z, mCfitExpNameSelectorAlt
    or a ; CF=0
    ret
mCfitExpNameSelectorAlt:
    scf
    ret

;-----------------------------------------------------------------------------

mCfitPowerHandler:
    ld a, curveFitModelPower
    ld (curveFitModel), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mCfitPowerNameSelector:
    ld a, (curveFitModel)
    cp curveFitModelPower
    jr z, mCfitPowerNameSelectorAlt
    or a ; CF=0
    ret
mCfitPowerNameSelectorAlt:
    scf
    ret

;-----------------------------------------------------------------------------

; Description: Select the best curve fit model with the highest absolute value
; of the correlation coefficient.
; Output:
;   (curveFitModel)=best curve fit model
;   X=abs(corr(best))
; Destroys: OP1, OP2, OP3, (maybe OP4?), OP5, OP6
mCfitBestHandler:
    call closeInputAndRecallNone
    ; check Linear fit
    ld a, curveFitModelLinear
    call selectCfitModel
    call statCorrelation
    bcall(_OP1ToOP5) ; OP5=corr(best)
    ld b, curveFitModelLinear
    push bc ; stack=[linearModel]
    ; check Log fit
    ld a, curveFitModelLog
    call selectCfitModel
    call statCorrelation
    bcall(_OP1ToOP2) ; OP2=corr(log)
    bcall(_OP1ToOP6) ; OP6=corr(log)
    bcall(_OP5ToOP1) ; OP1=corr(best)
    bcall(_AbsO1O2Cp) ; if abs(corr(log)) > abs(corr(linear)): CF=1
    jr nc, mCfitBestCheckExp
    bcall(_OP6ToOP5) ; OP5=corr(log)
    pop bc
    ld b, curveFitModelLog
    push bc ; stack=[logModel]
mCfitBestCheckExp:
    ld a, curveFitModelExp
    call selectCfitModel
    call statCorrelation
    bcall(_OP1ToOP2) ; OP2=corr(exp)
    bcall(_OP1ToOP6) ; OP6=corr(exp)
    bcall(_OP5ToOP1) ; OP1=corr(best)
    bcall(_AbsO1O2Cp) ; if abs(corr(exp)) > abs(corr(best)): CF=1
    jr nc, mCfitBestCheckPower
    bcall(_OP6ToOP5) ; OP5=corr(exp)
    pop bc
    ld b, curveFitModelExp
    push bc ; stack=[expModel]
mCfitBestCheckPower:
    ld a, curveFitModelPower
    call selectCfitModel
    call statCorrelation
    bcall(_OP1ToOP2) ; OP2=corr(power)
    bcall(_OP1ToOP6) ; OP6=corr(power)
    bcall(_OP5ToOP1) ; OP1=corr(best)
    bcall(_AbsO1O2Cp) ; if abs(corr(power)) > abs(corr(best)): CF=1
    jr nc, mCfitBestSelect
    bcall(_OP6ToOP5) ; OP5=corr(power)
    pop bc
    ld b, curveFitModelPower
    push bc ; stack=[powerModel]
mCfitBestSelect:
    ; B=best model
    ; OP5=best correlation
    pop af ; A=best model
    ld (curveFitModel), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    bcall(_OP5ToOP1) ; OP1=abs(corr(best))
    jp pushToX ; push the |corr| to the stack to notify the user

;-----------------------------------------------------------------------------

; Description: Select the curve fit model.
; Input: A: curveFitModel index [0-3]
; Output: IX: pointer to curve fit indirection indexes
; Destroys: A, DE, HL
selectCfitModel:
    add a, a ; A*=2
    ld e, a
    ld d, 0
    ld hl, cfitModelList
    add hl, de
    ld e, (hl)
    inc hl
    ld d, (hl)
    push de ; DE=(cfitModelList + 2*A)
    pop ix
    ret

;-----------------------------------------------------------------------------

; Description: Calculate the least square fit.
; Input:
;   IX=pointer to list of stat registers (e.g. cfitModelLinear, cfitModelExp)
; Output:
;   OP1=SLOP(X,Y) = CORR(X,Y) (StdDev(Y)/StdDev(X))
;                 = COV(X,Y) / StdDev(X)^2 (this works when StdDev(Y)==0)
;   OP2=YINT(X,,Y) = <Y> - SLOP(X,Y) * <X>
;
; Either Population or Sample can be used, because the N/(N-1) terms cancel
; out. See https://en.wikipedia.org/wiki/Simple_linear_regression
fitLeastSquare:
    ; Calculate slope.
    call statStdDev ; OP1=PDEV(Y), OP2=PDEV(X)
    bcall(_OP2ToOP1)
    bcall(_FPMult) ; OP1=StdDev(X)^2
    bcall(_PushRealO1) ; FPS=[StdDev(X)^2]
    call statCovariance ; OP1=COV(X,Y)
    bcall(_PopRealO2) ; FPS=[]; OP2=StdDev(X)^2
    bcall(_FPDiv) ; OP1=SLOP=COV(X,Y) / StdDev(X)^2
    bcall(_PushRealO1) ; FPS=[slope]

    ; Calculate intercept.
    bcall(_PushRealO1) ; FPS=[slope,slope]
    call statMean; OP1=<Y>, OP2=<X>
    call exchangeFPSOP1 ; FPS=[slope,<Y>]; OP1=SLOP
    bcall(_FPMult) ; OP1=SLOP * <X>
    bcall(_PopRealO2) ; FPS=[slope]; OP2=<Y>
    bcall(_InvSub) ; OP1 = -SLOP * <X> + <Y> = intercept

    bcall(_PopRealO2) ; FPS=[]; OP2=slope
    ret

;-----------------------------------------------------------------------------

; Description: Convert X to XPrime, according to the model defined by IX.
; Input:
;   IX: curve fit model
;   OP1: X
; Output:
;   OP1: XPrime
; Destroys: HL
convertXToXPrime:
    ld l, (ix + modelIndXToXPrime)
    ld h, (ix + modelIndXToXPrime + 1)
    jp (hl)

; Description: Convert XPrime to X, according to the model defined by IX.
; Input:
;   IX: curve fit model
;   OP1: XPrime
; Output:
;   OP1: X
; Destroys: HL
convertXPrimeToX:
    ld l, (ix + modelIndXPrimeToX)
    ld h, (ix + modelIndXPrimeToX + 1)
    jp (hl)

; Description: Convert Y to YPrime, according to the model defined by IX.
; Input:
;   IX: curve fit model
;   OP1: Y
; Output:
;   OP1: YPrime
; Destroys: HL
convertYToYPrime:
    ld l, (ix + modelIndYToYPrime)
    ld h, (ix + modelIndYToYPrime + 1)
    jp (hl)

; Description: Convert YPrime to Y, according to the model defined by IX.
; Input:
;   IX: curve fit model
;   OP1: YPrime
; Output:
;   OP1: Y
; Destroys: HL
convertYPrimeToY:
    ld l, (ix + modelIndYPrimeToY)
    ld h, (ix + modelIndYPrimeToY + 1)
    jp (hl)

; Description: Convert MPrime to M, according to the model defined by IX.
; Input:
;   IX: curve fit model
;   OP1: MPrime
; Output:
;   OP1: M
; Destroys: HL
convertMPrimeToM:
    ld l, (ix + modelIndMPrimeToM)
    ld h, (ix + modelIndMPrimeToM + 1)
    jp (hl)

; Description: Convert BPrime to B, according to the model defined by IX.
; Input:
;   IX: curve fit model
;   OP1: BPrime
; Output:
;   OP1: B
; Destroys: HL
convertBPrimeToB:
    ld l, (ix + modelIndBPrimeToB)
    ld h, (ix + modelIndBPrimeToB + 1)
    jp (hl)

;-----------------------------------------------------------------------------

; Parameter converters for linear fit.
convertLinearXToXPrime:
convertLinearXPrimeToX:
convertLinearYToYPrime:
convertLinearYPrimeToY:
convertLinearMPrimeToM:
convertLinearBPrimeToB:
    ret

;-----------------------------------------------------------------------------

; Parameter converters for logarithmic fit.
convertLogXToXPrime:
    bcall(_LnX)
    ret
convertLogXPrimeToX:
    bcall(_EToX)
    ret
convertLogYToYPrime:
convertLogYPrimeToY:
convertLogMPrimeToM:
convertLogBPrimeToB:
    ret

;-----------------------------------------------------------------------------

; Parameter converters for exponential fit.
convertExpXToXPrime:
convertExpXPrimeToX:
    ret
convertExpYToYPrime:
    bcall(_LnX)
    ret
convertExpYPrimeToY:
    bcall(_EToX)
    ret
convertExpMPrimeToM:
    ret
convertExpBPrimeToB:
    bcall(_EToX)
    ret

;-----------------------------------------------------------------------------

; Parameter converters for power fit.
convertPowerXToXPrime:
    bcall(_LnX)
    ret
convertPowerXPrimeToX:
    bcall(_EToX)
    ret
convertPowerYToYPrime:
    bcall(_LnX)
    ret
convertPowerYPrimeToY:
    bcall(_EToX)
    ret
convertPowerMPrimeToM:
    ret
convertPowerBPrimeToB:
    bcall(_EToX)
    ret
