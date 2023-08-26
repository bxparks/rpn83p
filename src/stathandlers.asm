;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; STAT Menu handlers.
;-----------------------------------------------------------------------------

mStatPlusHandler:
mStatMinusHandler:
mStatSumHandler:
mStatMeanHandler:
mStatSdevHandler:
    jp mNotYetHandler

mStatCalcXHandler:
mStatCalcYHandler:
mStatSlopeHandler:
mStatInterceptHandler:
mStatCorrelationHandler:
    jp mNotYetHandler

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

mStatAllRegsHandler:
mStatLinearRegsHandler:
mStatClearHandler:
mClearStatHandler:
    jp mNotYetHandler

mStatAllRegsNameSelector:
mStatLinearRegsNameSelector:
    ret
