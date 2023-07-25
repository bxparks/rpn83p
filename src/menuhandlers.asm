;-----------------------------------------------------------------------------
; Handlers for the various menu nodes generated by compilemenu.py.
;-----------------------------------------------------------------------------

mHelpHandler:
    jp mNotYetHandler

;-----------------------------------------------------------------------------
; Children nodes of NUM menu.
;-----------------------------------------------------------------------------

; mCubeHandler(X) -> X^3
; Description: Calculate X^3.
mCubeHandler:
    call closeInputBuf
    call rclX
    bcall(_Cube)
    call replaceX
    ret

; mCubeRootHandler(X) -> X^(1/3)
; Description: Calculate the cubic root of X. The SDK documentation has the OP1
; and OP2 flipped.
mCubeRootHandler:
    call closeInputBuf
    call rclX
    bcall(_OP1ToOP2)
    bcall(_OP1Set3)
    bcall(_XRootY)
    call replaceX
    ret

; mPercentHandler(Y, X) -> (Y, Y*(X/100))
; Description: Calculate the X percent of Y.
mPercentHandler:
    call closeInputBuf
    call rclX
    ld hl, constHundred
    bcall(_Mov9ToOP2)
    bcall(_FPDiv)
    bcall(_OP1ToOP2)
    call rclY
    bcall(_FPMult)
    call replaceX
    ret

; mAtan2Handler(Y, X) -> atan2(Y + Xi)
;
; Description: Calculate the angle of the (Y, X) number in complex plane.
; Use bcall(_RToP) instead of bcall(_ATan2) because ATan2 does not seem produce
; the correct results. There must be something wrong with the documentation.
; (It turns out that the documentation does not describe the necessary values
; of the D register which must be set before calling this. Normally D should be
; set to 0. See https://wikiti.brandonw.net/index.php?title=83Plus:BCALLs:40D8
; for more details. Although that page refers to ATan2Rad(), I suspect a
; similar thing is happening for ATan2().)
;
; The real part (i.e. x-axis) is assumed to be entered first, then the
; imaginary part (i.e. y-axis). They becomes stored in the RPN stack variables
; with X and Y flipped, which is bit confusing.
mAtan2Handler:
    call closeInputBuf
    call rclX ; imaginary
    bcall(_OP1ToOP2)
    call rclY ; OP1=Y (real), OP2=X (imaginary)
    bcall(_RToP) ; complex to polar
    bcall(_OP2ToOP1) ; OP2 contains the angle with range of (-pi, pi]
    call replaceXY
    ret

;-----------------------------------------------------------------------------

; mAbsHandler(X) -> Abs(X)
mAbsHandler:
    call closeInputBuf
    call rclX
    bcall(_ClrOP1S) ; clear sign bit of OP1
    call replaceX
    ret

; mSignHandler(X) -> Sign(X)
mSignHandler:
    call closeInputBuf
    call rclX
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
    call replaceX
    ret

mModHandler:
    call closeInputBuf
    call rclX
    bcall(_OP1ToOP2) ; OP2 = X
    bcall(_OP1ToOP4) ; OP4 = X
    call rclY ; OP1 = Y
    bcall(_FPDiv) ; OP1 = OP1/OP2 = Y/X
    bcall(_Intgr) ; OP1 = floor(OP1)
    bcall(_OP4ToOP2) ; OP2 = X
    bcall(_FPMult) ; OP1 = floor(Y/X) * X
    bcall(_OP1ToOP2) ; OP2 = X
    call rclY ; OP1 = Y
    bcall(_FPSub) ; OP1 = Y - floor(Y/X) * X
    call replaceXY
    ret

mMinHandler:
    call closeInputBuf
    call rclX
    bcall(_OP1ToOP2)
    call rclY
    bcall(_Min)
    call replaceXY
    ret

mMaxHandler:
    call closeInputBuf
    call rclX
    bcall(_OP1ToOP2)
    call rclY
    bcall(_Max
    call replaceXY
    ret

;-----------------------------------------------------------------------------

mIntPartHandler:
    call closeInputBuf
    call rclX
    bcall(_Trunc) ; convert to int part, truncating towards 0.0, preserving sign
    call replaceX
    ret

mFracPartHandler:
    call closeInputBuf
    call rclX
    bcall(_Frac) ; convert to frac part, preserving sign
    call replaceX
    ret

mFloorHandler:
    call closeInputBuf
    call rclX
    bcall(_Intgr) ; convert to integer towards -Infinity
    call replaceX
    ret

mCeilHandler:
    call closeInputBuf
    call rclX
    bcall(_InvOP1S) ; invert sign
    bcall(_Intgr) ; convert to integer towards -Infinity
    bcall(_InvOP1S) ; invert sign
    call replaceX
    ret

mNearHandler:
    call closeInputBuf
    call rclX
    bcall(_Int) ; round to nearest integer, irrespective of sign
    call replaceX
    ret

;-----------------------------------------------------------------------------
; Children nodes of PROB menu.
;-----------------------------------------------------------------------------

mPermHandler:
mCombHandler:
    jp mNotYetHandler

; mFactorialHandler(X) -> X!
; Description: Calculate the factorial of X.
mFactorialHandler:
    call closeInputBuf
    call rclX
    bcall(_Factorial)
    call replaceX
    ret

; mRandomHandler() -> rand()
; Description: Generate a random number [0,1) into the X register.
mRandomHandler:
    call closeInputBuf
    bcall(_Random)
    call liftStackNonEmpty
    call stoX
    ret

; mRandomSeedHandler(X) -> None
; Description: Set X as the Random() seed.
mRandomSeedHandler:
    call closeInputBuf
    call rclX
    bcall(_StoRand)
    ret

;-----------------------------------------------------------------------------
; Children nodes of UNIT menu.
;-----------------------------------------------------------------------------

mFToCHandler:
    call closeInputBuf
    call rclX
    ld a, 32
    bcall(_SetXXOP2) ; OP2 = 32
    bcall(_FPSub) ; OP1 = X - 32
    ld a, $18
    bcall(_OP2SetA) ; OP2 = 1.8
    bcall(_FPDiv) ; OP1 = (X - 32) / 1.8
    call replaceX
    ret

mCToFHandler:
    call closeInputBuf
    call rclX
    ld a, $18
    bcall(_OP2SetA) ; OP2 = 1.8
    bcall(_FPMult) ; OP1 = X * 1.8
    ld a, 32
    bcall(_SetXXOP2) ; OP2 = 32
    bcall(_FPAdd) ; OP1 = 1.8*X + 32
    call replaceX
    ret

mMiToKmHandler:
    call closeInputBuf
    call rclX
    ld hl, constKmPerMi
    bcall(_Mov9ToOP2)
    bcall(_FPMult)
    call replaceX
    ret

mKmToMiHandler:
    call closeInputBuf
    call rclX
    ld hl, constKmPerMi
    bcall(_Mov9ToOP2)
    bcall(_FPDiv)
    call replaceX
    ret

constKmPerMi:
    .db $00, $80, $16, $09, $34, $40, $00, $00, $00 ; 1.609344 km/mi

;-----------------------------------------------------------------------------
; Children nodes of CONV menu.
;-----------------------------------------------------------------------------

mRToDHandler:
    call closeInputBuf
    call rclX
    bcall(_RToD) ; RAD to DEG
    call replaceX
    ret

mDToRHandler:
    call closeInputBuf
    call rclX
    bcall(_DToR) ; DEG to RAD
    call replaceX
    ret

mHrToHmsHandler:
    ; call closeInputBuf
    ; call rclX
    ; bcall(_DToR) ; DEG to RAD
    ; call replaceX
    jp mNotYetHandler

mHmsToHrHandler:
    ; call closeInputBuf
    ; call rclX
    ; bcall(_DToR) ; DEG to RAD
    ; call replaceX
    jp mNotYetHandler

;-----------------------------------------------------------------------------
; Children nodes of MODE menu.
;-----------------------------------------------------------------------------

mRadHandler:
    res trigDeg, (iy + trigFlags)
    set rpnFlagsTrigDirty, (iy + rpnFlags)
    ret

mDegHandler:
    set trigDeg, (iy + trigFlags)
    set rpnFlagsTrigDirty, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------
; Children nodes of DISP menu.
;-----------------------------------------------------------------------------

mFixHandler:
    ld (argHandler), hl
    ld hl, msgFixLabel
    jr enableArgMode

mSciHandler:
    ld (argHandler), hl
    ld hl, msgSciLabel
    jr enableArgMode

mEngHandler:
    ld (argHandler), hl
    ld hl, msgEngLabel
    ; [[fallthrough]]

; Input: HL: argBuf prompt
enableArgMode:
    ld (argPrompt), hl
    xor a
    ld (argBufSize), a
    set rpnFlagsArgMode, (iy + rpnFlags)
    set inputBufFlagsInputDirty, (iy + inputBufFlags)
    ret

msgFixLabel:
    .db "FIX ", 0

msgSciLabel:
    .db "SCI ", 0

msgEngLabel:
    .db "ENG ", 0

;-----------------------------------------------------------------------------
; Children nodes of HYP menu.
;-----------------------------------------------------------------------------

mSinhHandler:
    call closeInputBuf
    call rclX
    bcall(_SinH)
    call replaceX
    ret

mCoshHandler:
    call closeInputBuf
    call rclX
    bcall(_CosH)
    call replaceX
    ret

mTanhHandler:
    call closeInputBuf
    call rclX
    bcall(_TanH)
    call replaceX
    ret

mAsinhHandler:
    call closeInputBuf
    call rclX
    bcall(_ASinH)
    call replaceX
    ret

mAcoshHandler:
    call closeInputBuf
    call rclX
    bcall(_ACosH)
    call replaceX
    ret

mAtanhHandler:
    call closeInputBuf
    call rclX
    bcall(_ATanH)
    call replaceX
    ret
