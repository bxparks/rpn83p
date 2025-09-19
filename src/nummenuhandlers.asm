;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023-2025 Brian T. Park
;
; NUM handlers.
;
; Every handler is given the following input parameters:
;   - HL:u16=menuId
;   - CF:bool
;       - 0 indicates 'onEnter' event into group
;       - 1 indicates 'onExit' event from group
;-----------------------------------------------------------------------------

; Description: Calculate the X percent of Y.
; Input:
;   - Y:Real|RpnDenominate
;   - X:Real
; Output:
;   - Y:Real|RpnDenominate=unchanged
;   - X:Real|RpnDenominate=Y*(X%)
mPercentHandler:
    call closeInputAndRecallUniversalXY ; CP1=Y; CP3=X
    call checkOp3Real ; ZF=1 if real
    jr nz, mPercentHandlerErr
    call checkOp1Denominate ; ZF=1 if denominate
    jr z, mPercentHandlerDoDenominate
    cp rpnObjectTypeReal
    jr z, mPercentHandlerDoReal
mPercentHandlerErr:
    bcall(_ErrDataType)
mPercentHandlerDoReal:
    call op3ToOp2
    bcall(_PercentFunction) ; OP1=Y*X/100
    bcall(_ReplaceStackX)
    ret
mPercentHandlerDoDenominate:
    bcall(_RpnDenominatePercent)
    bcall(_ReplaceStackX)
    ret

;-----------------------------------------------------------------------------

; Description: Calculate the change from Y to X as a percentage of Y. The
; resulting percentage can be given to the '%' menu key to get the delta
; change, then the '+' command will retrieve the original X.
; Input:
;   - Y:Real|RpnDenominate
;   - X:Real|RpnDenominate
; Output:
;   - Y:Real|RpnDenominate=unchanged
;   - X:Real=100*(X-Y)/Y
mPercentChangeHandler:
    call closeInputAndRecallUniversalXY ; CP1=Y; CP2=X
    call checkOp1Op3BothRealOrBothDenominate ; ZF=1 if true
    jr nz, mPercentChangeHandlerErr
    call checkOp1Real ; ZF=1 if true
    jr nz, mPercentChangeHandlerBothDenominate
    ; both Real
    call op3ToOp2
    bcall(_PercentChangeFunction) ; OP1:Real=100*(X-Y)/Y
    bcall(_ReplaceStackX)
    ret
mPercentChangeHandlerBothDenominate:
    bcall(_RpnDenominatePercentChange) ; OP1:Real=100*(X-Y)/Y
    bcall(_ReplaceStackX)
    ret
mPercentChangeHandlerErr:
    bcall(_ErrDataType)

;-----------------------------------------------------------------------------

; Description: Calculate the Great Common Divisor.
mGcdHandler:
    call closeInputAndRecallXY
    call validatePosIntGcdLcm
    bcall(_GcdFunction) ; OP1=gcd(OP1,OP2)
    bcall(_ReplaceStackXY)
    ret

; Description: Validate that X and Y are positive (> 0) integers.
; Input: OP1=Y; OP2=X
; Output: OP1=Y; OP2=X
; Throws: ErrDomain exception upon failure.
validatePosIntGcdLcm:
    call op1ExOp2
    call validatePosIntGcdLcmCommon ; neat trick, calls the tail of itself
    call op1ExOp2
validatePosIntGcdLcmCommon:
    bcall(_CkOP1FP0) ; if OP1 >= 0: ZF=1
    jr z, validatePosIntGcdLcmError
    bcall(_CkPosInt)
    ret z
validatePosIntGcdLcmError:
    bcall(_ErrDomain) ; throw exception

;-----------------------------------------------------------------------------

; Description: Calculate the Lowest Common Multiple.
mLcmHandler:
    call closeInputAndRecallXY
    call validatePosIntGcdLcm
    bcall(_LcdFunction) ; OP1=lcd(OP1,OP2)
    bcall(_ReplaceStackXY) ; X = lcm(X, Y)
    ret

;-----------------------------------------------------------------------------

; Description: Determine if the integer in X is a prime number and returns 1 if
; prime, or the lowest prime factor (>1) if not a prime. X must be in the range
; of [2, 2^32-1].
;
; Input: X: Number to check
; Output:
;   - stack lifted
;   - Y=original X
;   - X=1 if prime
;   - X=prime factor, if not a prime
; Throws: Err: Domain if X is not an integer in the range of [2, 2^32)
mPrimeHandler:
    call closeInputAndRecallX
    bcall(_PrimeFactor)
    bcall(_RunIndicOff) ; disable run indicator
    ; Instead of replacing the original X, push the prime factor into the RPN
    ; stack. This allows the user to press '/' to get the next candidate prime
    ; factor, which can be processed through 'PRIM` again. Running through this
    ; multiple times until a '1' is returns allows all prime factors to be
    ; discovered.
    bcall(_PushToStackX)
    ret

;-----------------------------------------------------------------------------

; mAbsHandler(X) -> Abs(X)
mAbsHandler:
    call closeInputAndRecallUniversalX
    cp rpnObjectTypeReal
    jr z, mAbsHandlerDoReal
    cp rpnObjectTypeDenominate
    jr z, mAbsHandlerDoDenominate
    bcall(_ErrDataType)
mAbsHandlerDoReal:
    bcall(_ClrOP1S) ; clear sign bit of OP1
    bcall(_ReplaceStackX)
    ret
mAbsHandlerDoDenominate:
    bcall(_RpnDenominateAbs)
    bcall(_ReplaceStackX)
    ret

;-----------------------------------------------------------------------------

; mSignHandler(X) -> Sign(X)
mSignHandler:
    call closeInputAndRecallUniversalX
    cp rpnObjectTypeReal
    jr z, mSignHandlerDoReal
    cp rpnObjectTypeDenominate
    jr z, mSignHandlerDoDenominate
    bcall(_ErrDataType)
mSignHandlerDoReal:
    bcall(_SignFunction)
    bcall(_ReplaceStackX)
    ret
mSignHandlerDoDenominate:
    bcall(_RpnDenominateSign)
    bcall(_ReplaceStackX)
    ret

;-----------------------------------------------------------------------------

; Description: Calculate (Y mod X), where Y and X could be floating point
; numbers. There does not seem to be a built-in function to calculator this, so
; it is implemented as (Y mod X) = Y - X*floor(Y/X).
; Destroys: OP1, OP2, OP3
mModHandler:
    call closeInputAndRecallXY ; OP2 = X; OP1 = Y
    bcall(_ModFunction) ; OP1 = (OP1 mod OP2)
    bcall(_ReplaceStackXY)
    ret

;-----------------------------------------------------------------------------

mMinHandler:
    call closeInputAndRecallUniversalXY
    call checkOp1Op3BothRealOrBothDenominate ; ZF=1 if true
    jr nz, mMinHandlerErr
    call checkOp1Real ; ZF=1 if true
    jr nz, mMinHandlerBothDenominate
    ; both Real
    call op3ToOp2
    bcall(_Min)
    bcall(_ReplaceStackXY)
    ret
mMinHandlerBothDenominate:
    bcall(_RpnDenominateMin)
    bcall(_ReplaceStackXY)
    ret
mMinHandlerErr:
    bcall(_ErrDataType)

;-----------------------------------------------------------------------------

mMaxHandler:
    call closeInputAndRecallUniversalXY
    call checkOp1Op3BothRealOrBothDenominate ; ZF=1 if true
    jr nz, mMaxHandlerErr
    call checkOp1Real ; ZF=1 if true
    jr nz, mMaxHandlerBothDenominate
    ; both Real
    call op3ToOp2
    bcall(_Max)
    bcall(_ReplaceStackXY)
    ret
mMaxHandlerBothDenominate:
    bcall(_RpnDenominateMax)
    bcall(_ReplaceStackXY)
    ret
mMaxHandlerErr:
    bcall(_ErrDataType)

;-----------------------------------------------------------------------------

mIntPartHandler:
    call closeInputAndRecallX
    bcall(_Trunc) ; convert to int part, truncating towards 0.0, preserving sign
    bcall(_ReplaceStackX)
    ret

;-----------------------------------------------------------------------------

mFracPartHandler:
    call closeInputAndRecallX
    bcall(_Frac) ; convert to frac part, preserving sign
    bcall(_ReplaceStackX)
    ret

;-----------------------------------------------------------------------------

mFloorHandler:
    call closeInputAndRecallX
    bcall(_Intgr) ; convert to integer towards -Infinity
    bcall(_ReplaceStackX)
    ret

;-----------------------------------------------------------------------------

mCeilHandler:
    call closeInputAndRecallX
    bcall(_InvOP1S) ; invert sign
    bcall(_Intgr) ; convert to integer towards -Infinity
    bcall(_InvOP1S) ; invert sign
    bcall(_ReplaceStackX)
    ret

;-----------------------------------------------------------------------------

mNearHandler:
    call closeInputAndRecallX
    bcall(_Int) ; round to nearest integer, irrespective of sign
    bcall(_ReplaceStackX)
    ret

;-----------------------------------------------------------------------------

mRoundToFixHandler:
    call closeInputAndRecallX ; OP1=X
    bcall(_RnFx) ; round to FIX/SCI/ENG digits, do nothing if digits==floating
    bcall(_ReplaceStackX)
    ret

;-----------------------------------------------------------------------------

mRoundToGuardHandler:
    call closeInputAndRecallX ; OP1=X
    bcall(_RndGuard) ; round to 10 digits, removing guard digits
    bcall(_ReplaceStackX)
    ret

;-----------------------------------------------------------------------------

mRoundToNHandler:
    ld hl, msgRoundPrompt
    call startArgScanner
    ld a, 1
    ld (argLenLimit), a ; accept only a single digit
    bcall(_PushRealO1)
    call processArgCommands ; ZF=0 if cancelled; destroys OP1-OP6
    push af
    bcall(_PopRealO1)
    pop af
    ret nz ; do nothing if cancelled
    ; terminate input only when the command is well-formed
    call closeInputAndRecallX ; OP1=X
    ld a, (argValue)
    cp 10
    ret nc ; return if argValue>=10 (should never happen with argLenLimit==1)
    ld d, a
    bcall(_Round) ; round to D digits, allowed values: 0-9
    bcall(_ReplaceStackX)
    ret

msgRoundPrompt:
    .db "ROUND", 0
