;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; CFIT menu handlers.
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
;-----------------------------------------------------------------------------

coldInitCfit:
    jp mCfitLinearHandler ; default Linear curve fit

; Description: Forecast Y from X.
mCfitForcastYHandler:
    call closeInputAndRecallX ; OP1=x
    bcall(_CfitForcastY)
    bcall(_ReplaceStackX)
    ret

; Description: Forecast X from Y.
mCfitForcastXHandler:
    call closeInputAndRecallX ; OP1=y
    bcall(_CfitForcastX)
    bcall(_ReplaceStackX)
    ret

; Description: Calculate the least square fit slope into X register.
mCfitSlopeHandler:
    call closeInputAndRecallNone
    bcall(_CfitSlope)
    bcall(_PushToStackX)
    ret

; Description: Calculate the least square fit intercept into X register.
mCfitInterceptHandler:
    call closeInputAndRecallNone
    bcall(_CfitIntercept)
    bcall(_PushToStackX)
    ret

; Description: Calculate the correlation coefficient into X register.
mCfitCorrelationHandler:
    call closeInputAndRecallNone
    bcall(_CfitCorrelation)
    bcall(_PushToStackX)
    ret

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
    bcall(_CfitBestFit) ; OP1=correlation
    bcall(_PushToStackX) ; push the |corr| to the stack to notify the user
    ret
