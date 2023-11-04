;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Handlers for menu items.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Predefined Menu handlers.
;-----------------------------------------------------------------------------

; Description: Null item handler. Does nothing.
; Input:
;   A: nodeId of the select menu item (ignored)
;   HL: pointer to MenuNode that was activated (ignored)
mNullHandler:
    ret

; Description: Handler for menu item which has not been implemented. Prints an
; "Err: Not Yet" error message.
; Input:
;   A: nodeId of the select menu item (ignored)
;   HL: pointer to MenuNode that was activated (ignored)
mNotYetHandler:
    ld a, errorCodeNotYet
    jp setHandlerCode

; Description: Default handler for menu nodes of type "MenuGroup".
; Input:
;   A: nodeId of the select menu item
;   HL: pointer to MenuNode that was activated (ignored)
;   CF: 0 upon entry into group; 1 upon exit from group
mGroupHandler:
    ret

;-----------------------------------------------------------------------------
; Handlers for the various menu nodes generated by compilemenu.py.
;-----------------------------------------------------------------------------

mHelpHandler:
    bcall(_processHelp) ; use bcall() to invoke HELP handler on Page 1
    ret

;-----------------------------------------------------------------------------
; Children nodes of MATH menu.
;-----------------------------------------------------------------------------

; mCubeHandler(X) -> X^3
; Description: Calculate X^3.
mCubeHandler:
    call closeInputAndRecallX
    bcall(_Cube)
    jp replaceX

; mCubeRootHandler(X) -> X^(1/3)
; Description: Calculate the cubic root of X. The SDK documentation has the OP1
; and OP2 flipped.
mCubeRootHandler:
    call closeInputAndRecallX
    bcall(_OP1ToOP2) ; OP2=X
    bcall(_OP1Set3) ; OP1=3
    bcall(_XRootY) ; OP2^(1/OP1), SDK documentation is incorrect
    jp replaceX

; mXRootYHandler(X,Y) -> Y^(1/X)
; Description: Calculate the X root of Y. The SDK documentation has the OP1
; and OP2 flipped.
mXRootYHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    bcall(_OP1ExOP2) ; OP1=X, OP2=Y
    bcall(_XRootY) ; OP2^(1/OP1), SDK documentation is incorrect
    jp replaceXY

; mAtan2Handler(Y, X) -> atan2(Y + Xi)
;
; Description: Calculate the angle of the (Y, X) number in complex plane.
; Use bcall(_RToP) instead of bcall(_ATan2) because ATan2 does not seem produce
; the correct results. There must be something wrong with the documentation.
;
; (It turns out that the documentation does not describe the necessary values
; of the D register which must be set before calling this. Apparently the D
; register should be set to 0. See
; https://wikiti.brandonw.net/index.php?title=83Plus:BCALLs:40D8 for more
; details. Although that page refers to ATan2Rad(), I suspect a similar thing
; is happening for ATan2().)
;
; The real part (i.e. x-axis) is assumed to be entered first, then the
; imaginary part (i.e. y-axis). They becomes stored in the RPN stack variables
; with X and Y flipped, which is bit confusing.
mAtan2Handler:
    call closeInputAndRecallXY ; OP1=Y=real; OP2=X=imaginary
    bcall(_RToP) ; complex to polar
    bcall(_OP2ToOP1) ; OP2 contains the angle with range of (-pi, pi]
    jp replaceXY

;-----------------------------------------------------------------------------

; Calculate e^x-1 without round off errors around x=0.
mExpMinusOneHandler:
    call closeInputAndRecallX
    call expMinusOne
    jp replaceX

; Calculate ln(1+x) without round off errors around x=0.
mLnOnePlusHandler:
    call closeInputAndRecallX
    call lnOnePlus
    jp replaceX

; Alog2(X) = 2^X
mAlog2Handler:
    call closeInputAndRecallX
    bcall(_OP1ToOP2) ; OP2 = X
    bcall(_OP1Set2) ; OP1 = 2
    bcall(_YToX) ; OP1 = 2^X
    jp replaceX

; Log2(X) = log_base_2(X) = log(X)/log(2)
mLog2Handler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    bcall(_OP1Set2) ; OP2 = 2
    bcall(_LnX) ; OP1 = ln(2)
    bcall(_PushRealO1); FPS = ln(2)
    call rclX ; OP1 = X
    bcall(_LnX) ; OP1 = ln(X)
    bcall(_PopRealO2) ; OP2 = ln(2)
    bcall(_FPDiv) ; OP1 = ln(X) / ln(2)
    jp replaceX

; LogBase(Y, X) = log_base_X(Y) = log(Y)/log(X)
mLogBaseHandler:
    call closeInputAndRecallX
    bcall(_LnX) ; OP1 = ln(X)
    bcall(_PushRealO1); FPS = ln(X)
    call rclY ; OP1 = Y
    bcall(_LnX) ; OP1 = ln(Y)
    bcall(_PopRealO2) ; OP2 = ln(X)
    bcall(_FPDiv) ; OP1 = ln(Y) / ln(X)
    jp replaceXY

;-----------------------------------------------------------------------------
; Children nodes of NUM menu.
;-----------------------------------------------------------------------------

; mPercentHandler(Y, X) -> (Y, Y*(X/100))
; Description: Calculate the X percent of Y.
mPercentHandler:
    call closeInputAndRecallX
    call op2Set100
    bcall(_FPDiv)
    bcall(_OP1ToOP2)
    call rclY
    bcall(_FPMult)
    jp replaceX

; mPercentChangeHandler(Y, X) -> (Y, 100*(X-Y)/Y)
; Description: Calculate the change from Y to X as a percentage of Y. The
; resulting percentage can be given to the '%' menu key to get the delta
; change, then the '+' command will retrieve the original X.
mPercentChangeHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call rclY
    bcall(_OP1ToOP2) ; OP2 = Y
    bcall(_PushRealO1) ; FPS = Y
    call rclX ; OP1 = X
    bcall(_FPSub) ; OP1 = X - Y
    bcall(_PopRealO2) ; OP2 = Y
    bcall(_FPDiv) ; OP1 = (X-Y)/Y
    call op2Set100
    bcall(_FPMult) ; OP1 = 100*(X-Y)/Y
    jp replaceX

;-----------------------------------------------------------------------------

; Description: Implement the Euclidean algorithm for the Greatest Common
; Divisor (GCD) as described in
; https://en.wikipedia.org/wiki/Euclidean_algorithm:
;
; function gcd(a, b)
;    while b != 0
;        t := b
;        b := a mod b
;        a := t
;    return a
;
; TODO: To reduce code size and programming time, this uses the TI-OS floating
; point operations to calculate (a mod b). It would probably be a LOT faster to
; use native Z-80 assembly to implement the (a mod b). However, that requires
; writing an integer division routine that takes a 32-bit and a 16-bit
; arguments, producing a 32-bit result. It's probably available somewhere on
; the internet, but I'm going to punt on that for now.
mGcdHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call validatePosIntGcdLcm
    call gcdOp1Op2 ; OP1 = gcd()
    jp replaceXY ; X = OP1

; Description: Validate that X and Y are positive (> 0) integers. Calls
; ErrDomain exception upon failure.
; Output:
;   - OP1 = Y
;   - OP2 = X
validatePosIntGcdLcm:
    call rclX
    bcall(_CkOP1FP0)
    jr z, validatePosIntGcdLcmError
    bcall(_CkPosInt) ; if OP1 >= 0: ZF=1
    jr nz, validatePosIntGcdLcmError
    bcall(_OP1ToOP2) ; OP2=X=b
    call rclY ; OP1=Y=a
    bcall(_CkOP1FP0) ; if OP1 >= 0: ZF=1
    jr z, validatePosIntGcdLcmError
    bcall(_CkPosInt)
    ret z
validatePosIntGcdLcmError:
    bcall(_ErrDomain) ; throw exception

; Description: Calculate the Great Common Divisor.
; Input: OP1, OP2
; Output: OP1 = GCD(OP1, OP2)
; Destroys: OP1, OP2, OP3
gcdOp1Op2:
    bcall(_CkOP2FP0) ; while b != 0
    ret z
    bcall(_PushRealO2) ; t = b
    call modOp1Op2 ; (a mod b)
    bcall(_OP1ToOP2) ; b = (a mod b)
    bcall(_PopRealO1) ; a = t
    jr gcdOp1Op2

; Description: Calculate the Lowest Common Multiple using the following:
; LCM(Y, X) = Y * X / GCD(Y, X)
;           = Y * (X / GCD(Y,X))
mLcmHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call validatePosIntGcdLcm

    bcall(_PushRealO1) ; FPS = OP1 = Y
    bcall(_PushRealO2) ; FPS = OP2 = X
    call gcdOp1Op2 ; OP1 = gcd()
    bcall(_OP1ToOP2) ; OP2 = gcd()
    bcall(_PopRealO1) ; OP1 = X
    bcall(_FPDiv) ; OP1 = X / gcd
    bcall(_PopRealO2) ; OP2 = Y
    bcall(_FPMult) ; OP1 = Y * (X / gcd)

    jp replaceXY ; X = lcm(X, Y)

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
;   - "Err: Domain" if X is not an integer in the range of [2, 2^32).
mPrimeHandler:
    call closeInputAndRecallX
    ; Check 0
    bcall(_CkOP1FP0)
    jp z, mPrimeHandlerError
    ; Check 1
    bcall(_OP2Set1) ; OP2 = 1
    bcall(_CpOP1OP2) ; if OP1==1: ZF=1
    jp z, mPrimeHandlerError
    bcall(_OP1ToOP4) ; save OP4 = X
    ; Check integer >= 0
    bcall(_CkPosInt) ; if OP1 >= 0: ZF=1
    jp nz, mPrimeHandlerError
    ; Check unsigned 32-bit integer, i.e. < 2^32.
    call op2Set2Pow32 ; if OP1 >= 2^32: CF=0
    bcall(_CpOP1OP2)
    jp nc, mPrimeHandlerError

    bcall(_PushRealO1) ; save original X
    ; Choose one of the various primeFactorXXX() routines.
    ; OP1=1 if prime, or its smallest prime factor (>1) otherwise
#ifdef USE_PRIME_FACTOR_FLOAT
    call primeFactorFloat
#else
    #ifdef USE_PRIME_FACTOR_INT
        call primeFactorInt
    #else
        call primeFactorMod
    #endif
#endif
    bcall(_RunIndicOff) ; disable run indicator

    ; Instead of replacing the original X, push the prime factor into the RPN
    ; stack. This allows the user to press '/' to get the next candidate prime
    ; factor, which can be processed through 'PRIM` again. Running through this
    ; multiple times until a '1' is returns allows all prime factors to be
    ; discovered.
    bcall(_OP1ToOP2) ; OP2=prime factor
    bcall(_PopRealO1) ; OP1=original X
    jp replaceXWithOP1OP2

mPrimeHandlerError:
    bcall(_ErrDomain) ; throw exception

;-----------------------------------------------------------------------------

#ifdef DEBUG
; Description: Test modU32U16().
; Uses:
;   - OP1=Y
;   - OP2=X
;   - OP3=u32(Y)
;   - OP4=u32(X)
mPrimeModHandler:
    call closeInputAndRecallXY ; OP2 = X; OP1 = Y
    ld hl, OP3
    call convertOP1ToU32 ; OP3=u32(Y)
    bcall(_OP2ToOP1)
    ld hl, OP4
    call convertOP1ToU32 ; OP4=u32(X)
    ;
    ld e, (hl)
    inc hl
    ld d, (hl) ; DE=u16(X)
    ;
    ld hl, OP3
    call modU32U16 ; BC=remainder=Y mod X
    ld hl, OP3
    call setU32ToBC ; u32(OP3)=BC
    call convertU32ToOP1 ; OP1=float(OP3)
    jp replaceXY
#endif

;-----------------------------------------------------------------------------

; mAbsHandler(X) -> Abs(X)
mAbsHandler:
    call closeInputAndRecallX
    bcall(_ClrOP1S) ; clear sign bit of OP1
    jp replaceX

; mSignHandler(X) -> Sign(X)
mSignHandler:
    call closeInputAndRecallX
    bcall(_CkOP1FP0) ; check OP1 is float 0
    jr z, mSignHandlerSetZero
    bcall(_CkOP1Pos) ; check OP1 > 0
    jr z, mSignHandlerSetOne
mSignHandlerSetNegOne:
    bcall(_OP1Set1)
    bcall(_InvOP1S)
    jr mSignHandlerStoX
mSignHandlerSetOne:
    bcall(_OP1Set1)
    jr mSignHandlerStoX
mSignHandlerSetZero:
    bcall(_OP1Set0)
mSignHandlerStoX:
    jp replaceX

; Description: Calculate (Y mod X), where Y and X could be floating point
; numbers. There does not seem to be a built-in function to calculator this, so
; it is implemented as (Y mod X) = Y - X*floor(Y/X).
; Destroys: OP1, OP2, OP3
mModHandler:
    call closeInputAndRecallXY ; OP2 = X; OP1 = Y
    call modOp1Op2 ; OP1 = (OP1 mod OP2)
    jp replaceXY

; Description: Internal helper routine to calculate OP1 = (OP1 mod OP2) = OP1 -
; OP2 * floor(OP1/OP2). Used by mModHandler and mGcdHandler. There does not
; seem to be a built-in function to calculate this.
; Destroys: OP1, OP2, OP3
modOp1Op2:
    bcall(_PushRealO1) ; FPS = OP1
    bcall(_PushRealO2) ; FPS = OP2
    bcall(_FPDiv) ; OP1 = OP1/OP2
    bcall(_Intgr) ; OP1 = floor(OP1/OP2)
    bcall(_PopRealO2) ; OP2 = OP2
    bcall(_FPMult) ; OP1 = floor(OP1/OP2) * OP2
    bcall(_OP1ToOP2) ; OP2 = floor(OP1/OP2) * OP2
    bcall(_PopRealO1) ; OP1 = OP1
    bcall(_FPSub) ; OP1 = OP1 - floor(OP1/OP2) * OP2
    bcall(_RndGuard) ; force integer results if OP1 and OP2 were integers
    ret

mMinHandler:
    call closeInputAndRecallXY
    bcall(_Min)
    jp replaceXY

mMaxHandler:
    call closeInputAndRecallXY
    bcall(_Max)
    jp replaceXY

;-----------------------------------------------------------------------------

mIntPartHandler:
    call closeInputAndRecallX
    bcall(_Trunc) ; convert to int part, truncating towards 0.0, preserving sign
    jp replaceX

mFracPartHandler:
    call closeInputAndRecallX
    bcall(_Frac) ; convert to frac part, preserving sign
    jp replaceX

mFloorHandler:
    call closeInputAndRecallX
    bcall(_Intgr) ; convert to integer towards -Infinity
    jp replaceX

mCeilHandler:
    call closeInputAndRecallX
    bcall(_InvOP1S) ; invert sign
    bcall(_Intgr) ; convert to integer towards -Infinity
    bcall(_InvOP1S) ; invert sign
    jp replaceX

mNearHandler:
    call closeInputAndRecallX
    bcall(_Int) ; round to nearest integer, irrespective of sign
    jp replaceX

;-----------------------------------------------------------------------------
; Children nodes of PROB menu.
;-----------------------------------------------------------------------------

; Calculate the Permutation function:
; P(y, x) = P(n, r) = n!/(n-r)! = n(n-1)...(n-r+1)
;
; TODO: (n,r) are limited to [0.255]. It should be relatively easy to extended
; the range to [0,65535].
mPermHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call validatePermComb

    ; Do the calculation. Set initial Result to 1 so that P(N, 0) = 1.
    bcall(_OP1Set1)
    ld a, e ; A = X
    or a
    jr z, mPermHandlerEnd
    ; Loop x times, multiple by (y-i)
    ld b, a ; B = X, C = Y
mPermHandlerLoop:
    push bc
    ld l, c ; L = C = Y
    ld h, 0 ; HL = Y
    bcall(_SetXXXXOP2)
    bcall(_FPMult)
    pop bc
    dec c
    djnz mPermHandlerLoop
mPermHandlerEnd:
    jp replaceXY

;-----------------------------------------------------------------------------

; Calculate the Combintation function:
; C(y, x) = C(n, r) = n!/(n-r)!/r! = n(n-1)...(n-r+1)/(r)(r-1)...(1).
;
; TODO: (n,r) are limited to [0.255]. It should be relatively easy to extended
; the range to [0,65535].
;
; TODO: This algorithm below is a variation of the algorithm used for P(n,r)
; above, with a division operation inside the loop that corresponds to each
; term of the `r!` divisor. However, the division can cause intermediate result
; to be non-integral. Eventually the final answer will be an integer, but
; that's not guaranteed until the end of the loop. I think it should be
; possible to rearrange the order of these divisions so that the intermediate
; results are always integral.
mCombHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call validatePermComb

    ; Do the calculation. Set initial Result to 1 C(N, 0) = 1.
    bcall(_OP1Set1)
    ld a, e ; A = X
    or a
    jr z, mCombHandlerEnd
    ; Loop X times, multiple by (Y-i), divide by i.
    ld b, a ; B = X, C = Y
mCombHandlerLoop:
    push bc
    ld l, c ; L = C = Y
    ld h, 0 ; HL = Y
    bcall(_SetXXXXOP2) ; OP2 = Y
    bcall(_FPMult)
    pop bc
    push bc
    ld l, b ; L = B = X
    ld h, 0 ; HL = X
    bcall(_SetXXXXOP2) ; OP2 = X
    bcall(_FPDiv)
    pop bc
    dec c
    djnz mCombHandlerLoop
mCombHandlerEnd:
    jp replaceXY

;-----------------------------------------------------------------------------

; Validate the n and r parameters of P(n,r) and C(n,r):
;   - n, r are integers in the range of [0,255]
;   - n >= r
; Output:
;   - C: Y
;   - E: X
; Destroys: A, BC, DE, HL
validatePermComb:
    ; Validate X
    call rclX
    call validatePermCombParam
    ; Validate Y
    call rclY
    call validatePermCombParam

    ; Convert X and Y into integers
    bcall(_ConvOP1) ; OP1 = Y
    push de ; save Y
    bcall(_OP1ToOP2) ; OP2 = Y
    call rclX
    bcall(_ConvOP1) ; E = X
    pop bc ; C = Y
    ; Check that Y >= X
    ld a, c ; A = Y
    cp e ; Y - X
    jr c, validatePermCombError
    ret

; Validate OP1 is an integer in the range of [0, 255].
validatePermCombParam:
    bcall(_CkPosInt) ; if OP1 >= 0: ZF=1
    jr nz, validatePermCombError
    ld hl, 256
    bcall(_SetXXXXOP2) ; OP2=256
    bcall(_CpOP1OP2)
    ret c ; ok if OP1 < 255
validatePermCombError:
    bcall(_ErrDomain) ; throw exception

;-----------------------------------------------------------------------------

; mFactorialHandler(X) -> X!
; Description: Calculate the factorial of X.
mFactorialHandler:
    call closeInputAndRecallX
    bcall(_Factorial)
    jp replaceX

;-----------------------------------------------------------------------------

; mRandomHandler() -> rand()
; Description: Generate a random number [0,1) into the X register.
mRandomHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    bcall(_Random)
    jp pushX

;-----------------------------------------------------------------------------

; mRandomSeedHandler(X) -> None
; Description: Set X as the Random() seed.
mRandomSeedHandler:
    call closeInputAndRecallX
    bcall(_StoRand)
    ret

;-----------------------------------------------------------------------------
; Children nodes of UNIT menu.
;-----------------------------------------------------------------------------

mFToCHandler:
    call closeInputAndRecallX
    ld a, 32
    bcall(_SetXXOP2) ; OP2 = 32
    bcall(_FPSub) ; OP1 = X - 32
    ld a, $18
    bcall(_OP2SetA) ; OP2 = 1.8
    bcall(_FPDiv) ; OP1 = (X - 32) / 1.8
    jp replaceX

mCToFHandler:
    call closeInputAndRecallX
    ld a, $18
    bcall(_OP2SetA) ; OP2 = 1.8
    bcall(_FPMult) ; OP1 = X * 1.8
    ld a, 32
    bcall(_SetXXOP2) ; OP2 = 32
    bcall(_FPAdd) ; OP1 = 1.8*X + 32
    jp replaceX

mInhgToHpaHandler:
    call closeInputAndRecallX
    call op2SetHpaPerInhg
    bcall(_FPMult)
    jp replaceX

mHpaToInhgHandler:
    call closeInputAndRecallX
    call op2SetHpaPerInhg
    bcall(_FPDiv)
    jp replaceX

;-----------------------------------------------------------------------------

mMiToKmHandler:
    call closeInputAndRecallX
    call op2SetKmPerMi
    bcall(_FPMult)
    jp replaceX

mKmToMiHandler:
    call closeInputAndRecallX
    call op2SetKmPerMi
    bcall(_FPDiv)
    jp replaceX

mFtToMHandler:
    call closeInputAndRecallX
    call op2SetMPerFt
    bcall(_FPMult)
    jp replaceX

mMToFtHandler:
    call closeInputAndRecallX
    call op2SetMPerFt
    bcall(_FPDiv)
    jp replaceX

;-----------------------------------------------------------------------------

mInToCmHandler:
    call closeInputAndRecallX
    call op2SetCmPerIn
    bcall(_FPMult)
    jp replaceX

mCmToInHandler:
    call closeInputAndRecallX
    call op2SetCmPerIn
    bcall(_FPDiv)
    jp replaceX

mMilToMicronHandler:
    call closeInputAndRecallX
    call op2SetCmPerIn
    bcall(_FPMult)
    call op2Set10
    bcall(_FPMult)
    jp replaceX

mMicronToMilHandler:
    call closeInputAndRecallX
    call op2SetCmPerIn
    bcall(_FPDiv)
    call op2Set10
    bcall(_FPDiv)
    jp replaceX

;-----------------------------------------------------------------------------

mLbsToKgHandler:
    call closeInputAndRecallX
    call op2SetKgPerLbs
    bcall(_FPMult)
    jp replaceX

mKgToLbsHandler:
    call closeInputAndRecallX
    call op2SetKgPerLbs
    bcall(_FPDiv)
    jp replaceX

mOzToGHandler:
    call closeInputAndRecallX
    call op2SetGPerOz
    bcall(_FPMult)
    jp replaceX

mGToOzHandler:
    call closeInputAndRecallX
    call op2SetGPerOz
    bcall(_FPDiv)
    jp replaceX

;-----------------------------------------------------------------------------

mGalToLHandler:
    call closeInputAndRecallX
    call op2SetLPerGal
    bcall(_FPMult)
    jp replaceX

mLToGalHandler:
    call closeInputAndRecallX
    call op2SetLPerGal
    bcall(_FPDiv)
    jp replaceX

mFlozToMlHandler:
    call closeInputAndRecallX
    call op2SetMlPerFloz
    bcall(_FPMult)
    jp replaceX

mMlToFlozHandler:
    call closeInputAndRecallX
    call op2SetMlPerFloz
    bcall(_FPDiv)
    jp replaceX

;-----------------------------------------------------------------------------

mCalToKjHandler:
    call closeInputAndRecallX
    call op2SetKjPerKcal
    bcall(_FPMult)
    jp replaceX

mKjToCalHandler:
    call closeInputAndRecallX
    call op2SetKjPerKcal
    bcall(_FPDiv)
    jp replaceX

mHpToKwHandler:
    call closeInputAndRecallX
    call op2SetKwPerHp
    bcall(_FPMult)
    jp replaceX

mKwToHpHandler:
    call closeInputAndRecallX
    call op2SetKwPerHp
    bcall(_FPDiv)
    jp replaceX

;-----------------------------------------------------------------------------
; Children nodes of CONV menu.
;-----------------------------------------------------------------------------

mRToDHandler:
    call closeInputAndRecallX
    bcall(_RToD) ; RAD to DEG
    jp replaceX

mDToRHandler:
    call closeInputAndRecallX
    bcall(_DToR) ; DEG to RAD
    jp replaceX

; Polar to Rectangular
; Input:
;   - Y: r
;   - X: theta
; Output:
;   - Y: x
;   - X: y
mPToRHandler:
    call closeInputAndRecallX
    bcall(_OP1ToOP2) ; OP2 = X = theta
    call rclY ; OP1 = Y = r
    bcall(_PToR) ; OP1 = x; OP2 = y (?)
    jp replaceXYWithOP1OP2 ; X=OP2=y; Y=OP1=x

; Rectangular to Polar
; Input:
;   - Y: x
;   - X: y
; Output:
;   - Y: r
;   - X: theta
mRtoPHandler:
    call closeInputAndRecallX
    bcall(_OP1ToOP2) ; OP2 = X = y
    call rclY ; OP1 = Y = x
    bcall(_RToP) ; OP1 = r; OP2 = theta (?)
    jp replaceXYWithOP1OP2 ; X=OP2=theta; Y=OP1=r

;-----------------------------------------------------------------------------

; HR(hh.mmss) = int(hh.mmss) + int(mm.ss)/60 + int(ss.nnnn)/3600
; Destroys: OP1, OP2, OP3, OP4 (temp)
mHmsToHrHandler:
    call closeInputAndRecallX

    ; Sometimes, the internal floating point value is slightly different than
    ; the displayed value due to rounding errors. For example, a value
    ; displayed as `10` (e.g. `e^(ln(10))`) could actually be `9.9999999999xxx`
    ; internally due to rounding errors. This routine parses out the digits
    ; after the decimal point and interprets them as minutes (mm) and seconds
    ; (ss) components. Any rounding errors will cause incorrect results. To
    ; mitigate this, we round the X value to 10 digits to make sure that the
    ; internal value matches the displayed value.
    bcall(_RndGuard)

    ; Extract the whole 'hh' and push it into the FPS.
    bcall(_OP1ToOP4) ; OP4 = hh.mmss (save in temp)
    bcall(_Trunc) ; OP1 = int(hh.mmss)
    bcall(_PushRealO1) ; FPS = hh

    ; Extract the 'mm' and push it into the FPS.
    bcall(_OP4ToOP1) ; OP1 = hh.mmss
    bcall(_Frac) ; OP1 = .mmss
    call op2Set100
    bcall(_FPMult) ; OP1 = mm.ss
    bcall(_OP1ToOP4) ; OP4 = mm.ss
    bcall(_Trunc) ; OP1 = mm
    bcall(_PushRealO1) ; FPS = mm

    ; Extract the 'ss.nnn' part
    bcall(_OP4ToOP1) ; OP1 = mm.ssnnn
    bcall(_Frac) ; OP1 = .ssnnn
    call op2Set100
    bcall(_FPMult) ; OP1 = ss.nnn

    ; Reassemble in the form of `hh.nnn`.
    ; Extract ss.nnn/60
    bcall(_OP2Set60) ; OP2 = 60
    bcall(_FPDiv) ; OP1 = ss.nnn/60
    ; Extract mm/60
    bcall(_PopRealO2) ; OP1 = mm
    bcall(_FPAdd) ; OP1 = mm + ss.nnn/60
    bcall(_OP2Set60) ; OP2 = 60
    bcall(_FPDiv) ; OP1 = (mm + ss.nnn/60) / 60
    ; Extract the hh.
    bcall(_PopRealO2) ; OP1 = hh
    bcall(_FPAdd) ; OP1 = hh + (mm + ss.nnn/60) / 60

    jp replaceX

; HMS(hh.nnn) = int(hh + (mm + ss.nnn/100)/100 where
;   - mm = int(.nnn* 60)
;   - ss.nnn = frac(.nnn*60)*60
; Destroys: OP1, OP2, OP3, OP4 (temp)
mHrToHmsHandler:
    call closeInputAndRecallX

    ; Extract the whole hh.
    bcall(_OP1ToOP4) ; OP4 = hh.nnn (save in temp)
    bcall(_Trunc) ; OP1 = int(hh.nnn)
    bcall(_PushRealO1) ; FPS = hh

    ; Extract the 'mm' and push it into the FPS
    bcall(_OP4ToOP1) ; OP1 = hh.nnn
    bcall(_Frac) ; OP1 = .nnn
    bcall(_OP2Set60) ; OP2 = 60
    bcall(_FPMult) ; OP1 = mm.nnn
    bcall(_OP1ToOP4) ; OP4 = mm.nnn
    bcall(_Trunc) ; OP1 = mm
    bcall(_PushRealO1) ; FPS = mm

    ; Extract the 'ss.nnn' part
    bcall(_OP4ToOP1) ; OP1 = mm.nnn
    bcall(_Frac) ; OP1 = .nnn
    bcall(_OP2Set60) ; OP2 = 60
    bcall(_FPMult) ; OP1 = ss.nnn

    ; Reassemble in the form of `hh.mmssnnn`.
    ; Extract ss.nnn/100
    call op2Set100
    bcall(_FPDiv) ; OP1 = ss.nnn/100
    ; Extract mm/100
    bcall(_PopRealO2) ; OP1 = mm
    bcall(_FPAdd) ; OP1 = mm + ss.nnn/100
    call op2Set100
    bcall(_FPDiv) ; OP1 = (mm + ss.nnn/100) / 100
    ; Extract the hh.
    bcall(_PopRealO2) ; OP1 = hh
    bcall(_FPAdd) ; OP1 = hh + (mm + ss.nnn/100) / 100

    jp replaceX

;-----------------------------------------------------------------------------
; Children nodes of MODE menu.
;-----------------------------------------------------------------------------

mFixHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld hl, mFixName
    call startArgParser
    call processCommandArg
    ret nc ; do nothing if canceled
    res fmtExponent, (iy + fmtFlags)
    res fmtEng, (iy + fmtFlags)
    jr saveFormatDigits

mSciHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld hl, mSciName
    call startArgParser
    call processCommandArg
    ret nc ; do nothing if canceled
    set fmtExponent, (iy + fmtFlags)
    res fmtEng, (iy + fmtFlags)
    jr saveFormatDigits

mEngHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld hl, mEngName
    call startArgParser
    call processCommandArg
    ret nc ; do nothing if canceled
    set fmtExponent, (iy + fmtFlags)
    set fmtEng, (iy + fmtFlags)
    jr saveFormatDigits

; Description: Save the (argValue) to (fmtDigits).
; Output:
;   - dirtyFlagsStack set
;   - dirtyFlagsFloatMode set
;   - fmtDigits updated
; Destroys: A
saveFormatDigits:
    set dirtyFlagsStack, (iy + dirtyFlags)
    set dirtyFlagsFloatMode, (iy + dirtyFlags)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ld a, (argValue)
    cp 10
    jr c, saveFormatDigitsContinue
    ld a, $FF ; variable number of digits, not fixed
saveFormatDigitsContinue:
    ld (fmtDigits), a
    ret

;-----------------------------------------------------------------------------

; Description: Select the display name of 'FIX' menu.
; Input:
;   - A: nameId
;   - C: altNameId
;   - HL: pointer to MenuNode
; Output:
;   - A: either A or C
mFixNameSelector:
    bit fmtExponent, (iy + fmtFlags)
    ret nz
    ld a, c
    ret

; Description: Select the display name of 'SCI' menu.
; Input:
;   - A: nameId
;   - C: altNameId
;   - HL: pointer to MenuNode
; Output:
;   - A: either A or C
mSciNameSelector:
    bit fmtExponent, (iy + fmtFlags)
    ret z
mSciNameSelectorMaybeOn:
    bit fmtEng, (iy + fmtFlags)
    ret nz
    ld a, c
    ret

; Description: Select the display name of 'ENG' menu.
; Input:
;   - A: nameId
;   - C: altNameId
;   - HL: pointer to MenuNode
; Output:
;   - A: either A or C
mEngNameSelector:
    bit fmtExponent, (iy + fmtFlags)
    ret z
mEngNameSelectorMaybeOn:
    bit fmtEng, (iy + fmtFlags)
    ret z
    ld a, c
    ret

;-----------------------------------------------------------------------------

mRadHandler:
    res trigDeg, (iy + trigFlags)
    set dirtyFlagsTrigMode, (iy + dirtyFlags)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

mDegHandler:
    set trigDeg, (iy + trigFlags)
    set dirtyFlagsTrigMode, (iy + dirtyFlags)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Select the display name of 'RAD' menu.
; Input:
;   - A: nameId
;   - C: altNameId
;   - HL: pointer to MenuNode
; Output:
;   - A: either A or C
mRadNameSelector:
    bit trigDeg, (iy + trigFlags)
    ret nz
    ld a, c
    ret

; Description: Select the display name of 'DEG' menu.
; Input:
;   - A: nameId
;   - C: altNameId
;   - HL: pointer to MenuNode
; Output:
;   - A: either A or C
mDegNameSelector:
    bit trigDeg, (iy + trigFlags)
    ret z
    ld a, c
    ret

;-----------------------------------------------------------------------------
; Children nodes of HYP menu.
;-----------------------------------------------------------------------------

mSinhHandler:
    call closeInputAndRecallX
    bcall(_SinH)
    jp replaceX

mCoshHandler:
    call closeInputAndRecallX
    bcall(_CosH)
    jp replaceX

mTanhHandler:
    call closeInputAndRecallX
    bcall(_TanH)
    jp replaceX

mAsinhHandler:
    call closeInputAndRecallX
    bcall(_ASinH)
    jp replaceX

mAcoshHandler:
    call closeInputAndRecallX
    bcall(_ACosH)
    jp replaceX

mAtanhHandler:
    call closeInputAndRecallX
    bcall(_ATanH)
    jp replaceX

;-----------------------------------------------------------------------------
; Children nodes of STK menu group (stack functions).
;-----------------------------------------------------------------------------

mStackRotUpHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    jp rotUpStack

mStackRotDownHandler:
    jp handleKeyRotDown

mStackExchangeXYHandler:
    jp handleKeyExchangeXY

;-----------------------------------------------------------------------------
; Children nodes of CLR menu group (clear functions).
;-----------------------------------------------------------------------------

mClearRegsHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call clearRegs
    ld a, errorCodeRegsCleared
    jp setHandlerCode

mClearStackHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    jp clearStack

mClearXHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    res rpnFlagsLiftEnabled, (iy + rpnFlags) ; disable stack lift
    bcall(_OP1Set0)
    jp stoX
