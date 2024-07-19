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
;   HL: pointer to MenuNode that was activated (ignored)
mNullHandler:
    ret

; Description: Handler for menu item which has not been implemented. Prints an
; "Err: Not Yet" error message.
; Input:
;   HL: pointer to MenuNode that was activated (ignored)
mNotYetHandler:
    ld a, errorCodeNotYet
    ld (handlerCode), a
    ret

; Description: Default handler for MenuGroup nodes. This handler currently does
; nothing. The 'chdir' functionality is now handled by dispatchMenuNode()
; because it needs to send an 'onExit' to the current node, and an 'onEnter'
; event to the selected node.
; Input:
;   HL: pointer to MenuNode that was activated (ignored)
;   CF: 0 indicates on 'onEnter' event into group; 1 indicates onExit event
;   from group
mGroupHandler:
    ret

;-----------------------------------------------------------------------------
; Handlers for the various menu nodes generated by compilemenu.py.
;-----------------------------------------------------------------------------

; Description: Show Help pages.
mHelpHandler:
    bcall(_ProcessHelpCommands)
    ret

;-----------------------------------------------------------------------------
; Children nodes of MATH menu.
;-----------------------------------------------------------------------------

; Description: Calculate X^3.
mCubeHandler:
    call closeInputAndRecallUniversalX
    call universalCube
    jp replaceX

; Description: Calculate the cubic root of X, X^(1/3).
mCubeRootHandler:
    call closeInputAndRecallUniversalX
    call universalCubeRoot
    jp replaceX

; Description: Calculate the X root of Y, Y^(1/X).
mXRootYHandler:
    call closeInputAndRecallUniversalXY ; CP1=Y; CP3=X
    call universalXRootY
    jp replaceXY

; Description: Calculate the angle of the (X, Y) in x-y plane. The y-axis must
; be pushed into the RPN stack first, then the x-axis. This order is consistent
; with the the `>POL` conversion function.
;
; The first version used bcall(_ATan2), but it does not seem produce the
; correct results.
;
; The second version used bcall(_RToP), but it has an overflow and underflow
; bug when r^2=x^2+y^2 is too large, which limits |r| to ~<7.1e63 and ~>1e-64.
;
; The third version uses ATan2() again, but sets an undocumented parameter to
; fix the bug. Apparently, the D register must be set to 0 to get the
; documented behavior. See
; https://wikiti.brandonw.net/index.php?title=83Plus:BCALLs:40D8 for more
; details. Although that page refers to ATan2Rad(), but a similar thing happens
; for ATan2().
mAtan2Handler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    ld d, 0 ; set undocumented parameter for ATan2()
    bcall(_ATan2) ; OP1=angle
    jp replaceXY

;-----------------------------------------------------------------------------

; Description: TwoPow(X) = 2^X
mTwoPowHandler:
    call closeInputAndRecallUniversalX
    call universalTwoPow
    jp replaceX

; Description: Log2(X)=log(X)/log(2)
mLog2Handler:
    call closeInputAndRecallUniversalX
    call universalLog2
    jp replaceX

; Description: LogBase(Y,X)=log(Y)/log(X)
mLogBaseHandler:
    call closeInputAndRecallUniversalXY ; CP1=Y; CP3=X
    call universalLogBase
    jp replaceXY

; Description: Calculate e^x-1 without round off errors around x=0.
mExpMinusOneHandler:
    call closeInputAndRecallX
    bcall(_ExpMinusOne)
    jp replaceX

; Description: Calculate ln(1+x) without round off errors around x=0.
mLnOnePlusHandler:
    call closeInputAndRecallX
    bcall(_LnOnePlus)
    jp replaceX

;-----------------------------------------------------------------------------
; Children nodes of NUM menu.
;-----------------------------------------------------------------------------

; mPercentHandler(Y, X) -> (Y, Y*(X/100))
; Description: Calculate the X percent of Y.
mPercentHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    bcall(_FPMult) ; OP1=OP1*OP2=X*Y
    call op2Set100
    bcall(_FPDiv) ; OP1=X*Y/100
    jp replaceX

; mPercentChangeHandler(Y, X) -> (Y, 100*(X-Y)/Y)
; Description: Calculate the change from Y to X as a percentage of Y. The
; resulting percentage can be given to the '%' menu key to get the delta
; change, then the '+' command will retrieve the original X.
mPercentChangeHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    bcall(_PushRealO1) ; FPS=[Y]
    bcall(_InvSub) ; OP1=X-Y
    bcall(_PopRealO2) ; FPS=[]; OP2=Y
    bcall(_FPDiv) ; OP1=(X-Y)/Y
    call op2Set100
    bcall(_FPMult) ; OP1=100*(X-Y)/Y
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
mGcdHandler:
    call closeInputAndRecallXY
    call validatePosIntGcdLcm
    call gcdOp1Op2 ; OP1=gcd(OP1,OP2)
    jp replaceXY

; Description: Validate that X and Y are positive (> 0) integers. Calls
; ErrDomain exception upon failure.
; Input: OP1=Y; OP2=X
; Output: OP1=Y; OP2=X
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

; Description: Calculate the Great Common Divisor.
;
; TODO: To reduce code size and programming time, this uses the TI-OS floating
; point operations to calculate (a mod b). It would probably be a LOT faster to
; use native Z-80 assembly to implement the (a mod b). At the time that I wrote
; this, the integer32.asm or the integer40.asm routines had not been written
; yet. I could probably use those integer routines to make this a LOT faster.
; However, the GCD algorithm is very efficient and does not take too many
; iterations. So I'm not sure it's worth changing this over to the integer
; routines.
;
; Input: OP1, OP2
; Output: OP1 = GCD(OP1, OP2)
; Destroys: OP1, OP2, OP3
gcdOp1Op2:
    bcall(_CkOP2FP0) ; while b != 0
    ret z
    bcall(_PushRealO2) ; FPS=[b]; (t = b)
    call modOp1Op2 ; (a mod b)
    bcall(_OP1ToOP2) ; b = (a mod b)
    bcall(_PopRealO1) ; FPS=[]; (a = t)
    jr gcdOp1Op2

; Description: Calculate the Lowest Common Multiple using the following:
; LCM(Y, X) = Y * X / GCD(Y, X)
;           = Y * (X / GCD(Y,X))
mLcmHandler:
    call closeInputAndRecallXY
    call validatePosIntGcdLcm
    call lcdOp1Op2 ; OP1=lcd(OP1,OP2)
    jp replaceXY ; X = lcm(X, Y)

lcdOp1Op2:
    bcall(_PushRealO1) ; FPS=[Y]
    bcall(_PushRealO2) ; FPS=[Y,X]
    call gcdOp1Op2 ; OP1 = gcd()
    bcall(_OP1ToOP2) ; OP2 = gcd()
    bcall(_PopRealO1) ; FPS=[Y]; OP1 = X
    bcall(_FPDiv) ; OP1 = X / gcd
    bcall(_PopRealO2) ; FPS=[]; OP2 = Y
    bcall(_FPMult) ; OP1 = Y * (X / gcd)
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
;   - "Err: Domain" if X is not an integer in the range of [2, 2^32).
mPrimeHandler:
    call closeInputAndRecallX
    bcall(_PrimeFactor)
    bcall(_RunIndicOff) ; disable run indicator
    ; Instead of replacing the original X, push the prime factor into the RPN
    ; stack. This allows the user to press '/' to get the next candidate prime
    ; factor, which can be processed through 'PRIM` again. Running through this
    ; multiple times until a '1' is returns allows all prime factors to be
    ; discovered.
    jp pushToX

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
    bcall(_PushRealO1) ; FPS=[OP1]
    bcall(_PushRealO2) ; FPS=[OP1,OP2]
    bcall(_FPDiv) ; OP1 = OP1/OP2
    bcall(_Intgr) ; OP1 = floor(OP1/OP2)
    bcall(_PopRealO2) ; FPS=[OP1]; OP2 = OP2
    bcall(_FPMult) ; OP1 = floor(OP1/OP2) * OP2
    bcall(_OP1ToOP2) ; OP2 = floor(OP1/OP2) * OP2
    bcall(_PopRealO1) ; FPS=[]; OP1 = OP1
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

mRoundToFixHandler:
    call closeInputAndRecallX ; OP1=X
    bcall(_RnFx) ; round to FIX/SCI/ENG digits, do nothing if digits==floating
    jp replaceX

mRoundToGuardHandler:
    call closeInputAndRecallX ; OP1=X
    bcall(_RndGuard) ; round to 10 digits, removing guard digits
    jp replaceX

mRoundToNHandler:
    call closeInputAndRecallX ; OP1=X
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
    ld a, (argValue)
    cp 10
    ret nc ; return if argValue>=10 (should never happen with argLenLimit==1)
    ld d, a
    bcall(_Round) ; round to D digits, allowed values: 0-9
    jp replaceX

msgRoundPrompt:
    .db "ROUND", 0

;-----------------------------------------------------------------------------
; Children nodes of PROB menu.
;-----------------------------------------------------------------------------

; Calculate the Permutation function:
; P(Y, X) = P(n, r) = n!/(n-r)! = n(n-1)...(n-r+1)
mPermHandler:
    call closeInputAndRecallXY ; OP1=Y=n; OP2=X=r
    bcall(_ProbPerm)
    jp replaceXY

;-----------------------------------------------------------------------------

; Calculate the Combintation function:
; C(Y, X) = C(n, r) = n!/(n-r)!/r! = n(n-1)...(n-r+1)/(r)(r-1)...(1).
mCombHandler:
    call closeInputAndRecallXY ; OP1=Y=n; OP2=X=r
    bcall(_ProbComb)
    jp replaceXY

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
    call closeInputAndRecallNone
    bcall(_Random)
    jp pushToX

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

; Description: Convert mpg (miles per US gallon) to lkm (Liters per 100 km):
; lkm = 100/[mpg * (km/mile) / (litre/gal)]
mMpgToLkmHandler:
    call closeInputAndRecallX
    call op2SetKmPerMi
    bcall(_FPMult)
    call op2SetLPerGal
    bcall(_FPDiv)
    call op1ToOp2
    call op1Set100
    bcall(_FPDiv)
    jp replaceX

; Description: Convert lkm to mpg: mpg = 100/lkm * (litre/gal) / (km/mile).
mLkmToMpgHandler:
    call closeInputAndRecallX
    call op1ToOp2
    call op1Set100
    bcall(_FPDiv)
    call op2SetLPerGal
    bcall(_FPMult)
    call op2SetKmPerMi
    bcall(_FPDiv)
    jp replaceX

; Description: Convert PSI (pounds per square inch) to kiloPascal.
; P(Pa) = P(psi) * 0.45359237 kg/lbf * (9.80665 m/s^2) / (0.0254 m/in)^2
; P(Pa) = P(psi) * 0.45359237 kg/lbf * (9.80665 m/s^2) / (2.54 cm/in)^2 * 10000
; P(kPa) = P(psi) * 0.45359237 kg/lbf * (9.80665 m/s^2) / (2.54 cm/in)^2 * 10
; See https://en.wikipedia.org/wiki/Pound_per_square_inch.
mPsiToKpaHandler:
    call closeInputAndRecallX
    call op2SetKgPerLbs
    bcall(_FPMult)
    call op2SetStandardGravity
    bcall(_FPMult)
    call op2SetCmPerIn
    bcall(_FPDiv)
    call op2SetCmPerIn
    bcall(_FPDiv)
    call op2Set10
    bcall(_FPMult)
    jp replaceX

; Description: Convert PSI (pounds per square inch) to kiloPascal.
; P(psi) = P(kPa) / 10 * (2.54m/in)^2 / (0.45359237 kg/lbf) / (9.80665 m/s^2)
; See https://en.wikipedia.org/wiki/Pound_per_square_inch.
mKpaToPsiHandler:
    call closeInputAndRecallX
    call op2Set10
    bcall(_FPDiv)
    call op2SetCmPerIn
    bcall(_FPMult)
    call op2SetCmPerIn
    bcall(_FPMult)
    call op2SetStandardGravity
    bcall(_FPDiv)
    call op2SetKgPerLbs
    bcall(_FPDiv)
    jp replaceX

;-----------------------------------------------------------------------------

; Description: Convert US acre (66 ft x 660 ft) to hectare (100 m)^2. See
; https://en.wikipedia.org/wiki/Acre, and
; https://en.wikipedia.org/wiki/Hectare.
; Area(ha) = Area(acre) * 43560 * (0.3048 m/ft)^2 / (100 m)^2
mAcreToHectareHandler:
    call closeInputAndRecallX
    call op2SetSqFtPerAcre
    bcall(_FPMult)
    call op2SetMPerFt
    bcall(_FPMult)
    call op2SetMPerFt
    bcall(_FPMult)
    call op2Set100
    bcall(_FPDiv)
    call op2Set100
    bcall(_FPDiv)
    jp replaceX

; Description: Convert hectare to US acre.
; Area(acre) = Area(ha) * (100 m)^2 / 43560 / (0.3048 m/ft)^2
mHectareToAcreHandler:
    call closeInputAndRecallX
    call op2Set100
    bcall(_FPMult)
    call op2Set100
    bcall(_FPMult)
    call op2SetMPerFt
    bcall(_FPDiv)
    call op2SetMPerFt
    bcall(_FPDiv)
    call op2SetSqFtPerAcre
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

; Polar to Rectangular. The order of arguments is intended to be consistent
; with the HP-42S.
; Input:
;   - Y: theta
;   - X: r
; Output:
;   - Y: y
;   - X: x
mPToRHandler:
    call closeInputAndRecallXY ; OP1=Y=theta; OP2=X=r
    call op1ExOp2  ; OP1=r; OP2=theta
    bcall(_PToR) ; OP1=x; OP2=y
    call op1ExOp2  ; OP1=y; OP2=x
    jp replaceXYWithOP1OP2 ; Y=OP2=y; X=OP1=x

; Rectangular to Polar. The order of arguments is intended to be consistent
; with the HP-42S. Early version used the RToP() TI-OS function, but it has an
; overflow/underflow bug when r^2 becomes too big or small. Instead, use the
; custom rectToPolar() function which does not overflow or underflow.
; Input:
;   - Y: y
;   - X: x
; Output:
;   - Y: theta
;   - X: r
mRToPHandler:
    call closeInputAndRecallXY ; OP1=Y; OP2=X
    call op1ExOp2  ; OP1=x; OP2=y
    call rectToPolar ; OP1=r; OP2=theta
    call op1ExOp2  ; OP1=theta; OP2=r
    jp replaceXYWithOP1OP2 ; Y=OP1=theta; X=OP2=r

;-----------------------------------------------------------------------------

; Description: Convert "hh.mmss" to "hh.ddddd".
; Destroys: OP1, OP2, OP3, OP4 (temp)
mHmsToHrHandler:
    call closeInputAndRecallX
    bcall(_HmsToHr)
    jp replaceX

; Description: Convert "hh.dddd" to "hh.mmss".
; Destroys: OP1, OP2, OP3, OP4 (temp)
mHrToHmsHandler:
    call closeInputAndRecallX
    bcall(_HmsFromHr)
    jp replaceX

;-----------------------------------------------------------------------------
; Children nodes of MODE menu.
;-----------------------------------------------------------------------------

mFixHandler:
    call closeInputAndRecallNone
    ld hl, msgFixPrompt
    call startArgScanner
    call processArgCommands ; ZF=0 if cancelled
    ret nz ; do nothing if cancelled
    res fmtExponent, (iy + fmtFlags)
    res fmtEng, (iy + fmtFlags)
    jr saveFormatDigits

mSciHandler:
    call closeInputAndRecallNone
    ld hl, msgSciPrompt
    call startArgScanner
    call processArgCommands ; ZF=0 if cancelled
    ret nz ; do nothing if cancelled
    set fmtExponent, (iy + fmtFlags)
    res fmtEng, (iy + fmtFlags)
    jr saveFormatDigits

mEngHandler:
    call closeInputAndRecallNone
    ld hl, msgEngPrompt
    call startArgScanner
    call processArgCommands ; ZF=0 if cancelled
    ret nz ; do nothing if cancelled
    set fmtExponent, (iy + fmtFlags)
    set fmtEng, (iy + fmtFlags)
    jr saveFormatDigits

msgFixPrompt:
    .db "FIX", 0
msgSciPrompt:
    .db "SCI", 0
msgEngPrompt:
    .db "ENG", 0

; Description: Save the (argValue) to (fmtDigits).
; Input: (argValue)
; Output:
;   - dirtyFlagsStack set
;   - dirtyFlagsFloatMode set
;   - fmtDigits updated
; Destroys: A
saveFormatDigits:
    set dirtyFlagsStack, (iy + dirtyFlags)
    set dirtyFlagsStatus, (iy + dirtyFlags)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ld a, (argValue)
    cp 10
    jr c, saveFormatDigitsContinue
    ld a, fmtDigitsFloating ; "floating" number of digits, i.e. not fixed
saveFormatDigitsContinue:
    ld (fmtDigits), a
    ret

;-----------------------------------------------------------------------------

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mFixNameSelector:
    or a ; CF=0
    bit fmtExponent, (iy + fmtFlags)
    ret nz
    scf
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mSciNameSelector:
    or a ; CF=0
    bit fmtExponent, (iy + fmtFlags)
    ret z
    bit fmtEng, (iy + fmtFlags)
    ret nz
    scf
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mEngNameSelector:
    or a ; CF=0
    bit fmtExponent, (iy + fmtFlags)
    ret z
    bit fmtEng, (iy + fmtFlags)
    ret z
    scf
    ret

;-----------------------------------------------------------------------------

mRadHandler:
    res trigDeg, (iy + trigFlags)
    set dirtyFlagsStatus, (iy + dirtyFlags)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

mDegHandler:
    set trigDeg, (iy + trigFlags)
    set dirtyFlagsStatus, (iy + dirtyFlags)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mRadNameSelector:
    or a ; CF=0
    bit trigDeg, (iy + trigFlags)
    ret nz
    scf
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mDegNameSelector:
    or a ; CF=0
    bit trigDeg, (iy + trigFlags)
    ret z
    scf
    ret

;-----------------------------------------------------------------------------

mSetRegSizeHandler:
    call closeInputAndRecallNone
    ld hl, msgRegSizePrompt
    call startArgScanner
    ld a, 3
    ld (argLenLimit), a ; allow 3 digits, to support SIZE=100
    call processArgCommands ; ZF=0 if cancelled
    ret nz ; do nothing if cancelled
    ;
    ld a, (argValue)
    cp regsSizeMax+1 ; CF=0 if argValue>100
    jr nc, setRegSizeHandlerErr
    cp regsSizeMin ; CF=1 if argValue<25
    jr c, setRegSizeHandlerErr
    call resizeRegs ; test (newLen-oldLen) -> ZF,CF flags set
    ; Determine the handler code
    jr z, setRegSizeHandlerUnchanged
    jr nc, setRegSizeHandlerExpanded
setRegSizeHandlerShrunk:
    ld a, errorCodeRegsShrunk
    ld (handlerCode), a
    ret
setRegSizeHandlerExpanded:
    ld a, errorCodeRegsExpanded
    ld (handlerCode), a
    ret
setRegSizeHandlerUnchanged:
    ld a, errorCodeRegsUnchanged
    ld (handlerCode), a
    ret
setRegSizeHandlerErr:
    bcall(_ErrInvalid)

mGetRegSizeHandler:
    call closeInputAndRecallNone
    call lenRegs
    bcall(_ConvertAToOP1) ; OP1=float(A)
    jp pushToX

msgRegSizePrompt:
    .db "RSIZ", 0

;-----------------------------------------------------------------------------

mSetStackSizeHandler:
    call closeInputAndRecallNone
    ld hl, msgStackSizePrompt
    call startArgScanner
    ld a, 1
    ld (argLenLimit), a ; accept only a single digit
    call processArgCommands ; ZF=0 if cancelled
    ret nz ; do nothing if cancelled
    ; validate input
    ld a, (argValue)
    cp stackSizeMax+1 ; CF=0 if argValue>8
    jr nc, setStackSizeHandlerErr
    cp stackSizeMin ; CF=1 if argValue<4
    jr c, setStackSizeHandlerErr
    ; perform the resize
    inc a ; add LastX register
    call resizeStack ; test (newLen-oldLen) -> ZF,CF flags set
    set dirtyFlagsStatus, (iy + dirtyFlags)
    ; Determine the handler code
    jr z, setStackSizeHandlerUnchanged
    jr nc, setStackSizeHandlerExpanded
setStackSizeHandlerShrunk:
    ld a, errorCodeStackShrunk
    ld (handlerCode), a
    ret
setStackSizeHandlerExpanded:
    ld a, errorCodeStackExpanded
    ld (handlerCode), a
    ret
setStackSizeHandlerUnchanged:
    ld a, errorCodeStackUnchanged
    ld (handlerCode), a
    ret
setStackSizeHandlerErr:
    bcall(_ErrInvalid)

mGetStackSizeHandler:
    call closeInputAndRecallNone
    call lenStack
    dec a ; remove LastX register
    bcall(_ConvertAToOP1) ; OP1=float(A)
    jp pushToX

msgStackSizePrompt:
    .db "SSIZ", 0

;-----------------------------------------------------------------------------

mCommaEENormalHandler:
    ld a, commaEEModeNormal
    ld (commaEEMode), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mCommaEENormalNameSelector:
    ld a, (commaEEMode)
    cp commaEEModeNormal
    jr z, mCommaEENormalNameSelectorAlt
    or a ; CF=0
    ret
mCommaEENormalNameSelectorAlt:
    scf
    ret

mCommaEESwappedHandler:
    ld a, commaEEModeSwapped
    ld (commaEEMode), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mCommaEESwappedNameSelector:
    ld a, (commaEEMode)
    cp commaEEModeSwapped
    jr z, mCommaEESwappedNameSelectorAlt
    or a ; CF=0
    ret
mCommaEESwappedNameSelectorAlt:
    scf
    ret

;-----------------------------------------------------------------------------

mFormatRecordRawHandler:
    ld a, formatRecordModeRaw
    ld (formatRecordMode), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    set dirtyFlagsStack, (iy + dirtyFlags)
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mFormatRecordRawNameSelector:
    ld a, (formatRecordMode)
    cp formatRecordModeRaw
    jr z, mFormatRecordRawNameSelectorAlt
    or a ; CF=0
    ret
mFormatRecordRawNameSelectorAlt:
    scf
    ret

mFormatRecordStringHandler:
    ld a, formatRecordModeString
    ld (formatRecordMode), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    set dirtyFlagsStack, (iy + dirtyFlags)
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mFormatRecordStringNameSelector:
    ld a, (formatRecordMode)
    cp formatRecordModeString
    jr z, mFormatRecordStringNameSelectorAlt
    or a ; CF=0
    ret
mFormatRecordStringNameSelectorAlt:
    scf
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

mStackDupHandler:
    call closeInputAndRecallNone
    jp liftStack

mStackRollUpHandler:
    call closeInputAndRecallNone
    jp rollUpStack

mStackRollDownHandler:
    jp handleKeyRollDown

mStackExchangeXYHandler:
    jp handleKeyExchangeXY

mStackDropHandler:
    call closeInputAndRecallNone
    jp dropStack

;-----------------------------------------------------------------------------
; Children nodes of CLR menu group (clear functions).
;-----------------------------------------------------------------------------

mClearRegsHandler:
    call closeInputAndRecallNone
    call clearRegs
    ld a, errorCodeRegsCleared
    ld (handlerCode), a
    ret

mClearStackHandler:
    call closeInputAndRecallNone
    jp clearStack

mClearXHandler:
    call closeInputAndRecallNone
    res rpnFlagsLiftEnabled, (iy + rpnFlags) ; disable stack lift
    bcall(_OP1Set0)
    jp stoX

mClearStatHandler:
    jp mStatClearHandler

mClearTvmHandler:
    jp mTvmClearHandler

mClearDisplayHandler:
    bcall(_ClrLCDFull)
    bcall(_ColdInitDisplay)
    bcall(_InitDisplay)
    ret

; mClearVarsHandler:
;    bcall(_ClearVars)
;    ret
