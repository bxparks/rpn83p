;-----------------------------------------------------------------------------
; Predefined Menu handlers.
;-----------------------------------------------------------------------------

; Description: Null handler. Does nothing.
; Input:
;   A: nodeId of the select menu item (ignored)
;   HL: pointer to MenuNode that was activated (ignored)
mNullHandler: ; do nothing
    ret

; Description: Null handler. Does nothing.
; Input:
;   A: nodeId of the select menu item (ignored)
;   HL: pointer to MenuNode that was activated (ignored)
mNotYetHandler:
    ld a, errorCodeNotYet
    jp setErrorCode

; Description: General handler for menu nodes of type "MenuGroup". Selecting
; this should cause the menuGroupId to be set to this item, and the
; menuStripIndex to be set to 0
; Input:
;   A: nodeId of the select menu item
;   HL: pointer to MenuNode that was activated (ignored)
; Output: (menuGroupId) and (menuStripIndex) updated
; Destroys: A
mGroupHandler:
    ld (menuGroupId), a
    xor a
    ld (menuStripIndex), a
    set rpnFlagsMenuDirty, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------
; Handlers for the various menu nodes generated by compilemenu.py.
;-----------------------------------------------------------------------------

mHelpHandler:
    ld b, 0 ; B = pageNumber
mHelpHandlerLoop:
    ld a, b ; A = pageNumber
    call displayPage
mHelpHandlerGetKey:
    bcall(_GetKey) ; pause, destroys: A, DE, HL
    res onInterrupt, (IY+onFlags) ; reset flag set by ON button
mHelpHandlerCheckExit:
    or a ; A == ON
    jr z, mHelpHandlerExit
    cp kClear ; A == CLEAR
    jr z, mHelpHandlerExit
    cp kMath ; A == MATH
    jr z, mHelpHandlerExit
    cp kLeft ; A == LEFT
    jr z, mHelpHandlerPrevPageMaybe
    cp kUp ; A == UP
    jr z, mHelpHandlerPrevPageMaybe
    jr mHelpHandlerNextPage ; everything else to the next page
mHelpHandlerPrevPageMaybe:
    ; go to prev page if not already at page 0
    ld a, b
    or a
    jr z, mHelpHandlerGetKey
mHelpHandlerPrevPage:
    dec b
    jr mHelpHandlerLoop

mHelpHandlerNextPage:
    ; any other key goes to the next the page
    inc b
    ld a, b
    cp helpPageCount
    jr nz, mHelpHandlerLoop
mHelpHandlerExit:
    ; force rerendering of normal calculator display
    bcall(_ClrLCDFull)
    set rpnFlagsStackDirty, (iy + rpnFlags)
    ld a, errorCodeCount ; guaranteed to trigger rendering
    ld (errorCodeDisplayed), a
    call initDisplay
    call initMenu
    ret

; Description: Display the help page given by pageNumber in A.
; Input: A: pageNumber
; Destroys: none
displayPage:
    push af
    push bc
    push de
    push hl

    bcall(_ClrLCDFull)

    ; Calculate the pointer to the help page string
    ld hl, helpPages ; HL = (char**)
    add a, a ; A = 2 * pageNumber (i.e. max page number = 127)
    ld e, a
    ld d, 0 ; DE = string offset
    add hl, de ; HL = (char**)
    ld e, (hl)
    inc hl
    ld d, (hl) ; DE = (char*)(HL)
    ex de, hl ; HL = (char*)

    call displayString

    pop hl
    pop de
    pop bc
    pop af
    ret

; Description: Display the page given by HL.
; Input: HL: string using small font
; Destroys: none
displayString:
    push hl
    ld hl, 0
    ld (PenCol), hl
    pop hl ; HL= (char*)
    call vPutS
    ret

; Array of (char*) pointers to strings.
helpPageCount equ 3
helpPages:
    .dw msgHelpPage0
    .dw msgHelpPage1
    .dw msgHelpPage2

; TODO: Move this to the end of the assembly source code if the size of the
; binary becomes close to the 8 kB limit.

msgHelpPage0:
    .db "RPN83P v0.0 ", "(2023", Shyphen, "07", Shyphen, "27)", Senter
    .db Senter
    .db "R", LdownArrow, " : (", Senter
    .db "R", LupArrow, " : 2ND {", Senter
    .db "X<>Y", ": )", Senter
    .db "LastX", ": 2ND ANS", Senter
    .db Senter
    .db Senter
    .db SlBrack, "1/3", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage1:
    .db "RPN83P v0.0 ", "(2023", Shyphen, "07", Shyphen, "27)", Senter
    .db Senter
    .db "EE: 2ND EE or ,", Senter
    .db "+/-: (-)", Senter
    .db "<-: DEL", Senter
    .db "ClrX: CLEAR", Senter
    .db Senter
    .db Senter
    .db SlBrack, "2/3", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage2:
    .db "RPN83P v0.0 ", "(2023", Shyphen, "07", Shyphen, "27)", Senter
    .db Senter
    .db "Menu Home: MATH", Senter
    .db "Menu Prev: Up", Senter
    .db "Menu Next: Down", Senter
    .db "Menu Back: Left or ON", Senter
    .db "Quit App: 2ND QUIT", Senter
    .db Senter
    .db SlBrack, "3/3", SrBrack, " Any key to return.", Senter
    .db 0

;-----------------------------------------------------------------------------
; Children nodes of MATH menu.
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
    call rclX ; OP1=X
    bcall(_OP1ToOP2) ; OP2=X
    bcall(_OP1Set3) ; OP1=3
    bcall(_XRootY) ; OP2^OP1
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

; Alog2(X) = 2^X
mAlog2Handler:
    call closeInputBuf
    call rclX ; OP1 = X
    bcall(_OP1ToOP2) ; OP2 = X
    bcall(_OP1Set2) ; OP1 = 2
    bcall(_YToX) ; OP1 = 2^X
    call replaceX
    ret

; Log2(X) = log_base_2(X) = log(X)/log(2)
mLog2Handler:
    call closeInputBuf
    bcall(_OP1Set2) ; OP2 = 2
    bcall(_LnX) ; OP1 = ln(2)
    bcall(_PushRealO1); FPS = ln(2)
    call rclX ; OP1 = X
    bcall(_LnX) ; OP1 = ln(X)
    bcall(_PopRealO2) ; OP2 = ln(2)
    bcall(_FPDiv) ; OP1 = ln(X) / ln(2)
    call replaceX
    ret

; LogBase(Y, X) = log_base_X(Y) = log(Y)/log(X)
mLogBaseHandler:
    call closeInputBuf
    call rclX ; OP1 = X
    bcall(_LnX) ; OP1 = ln(X)
    bcall(_PushRealO1); FPS = ln(X)
    call rclY ; OP1 = Y
    bcall(_LnX) ; OP1 = ln(Y)
    bcall(_PopRealO2) ; OP2 = ln(X)
    bcall(_FPDiv) ; OP1 = ln(Y) / ln(X)
    call replaceXY
    ret

;-----------------------------------------------------------------------------
; Children nodes of NUM menu.
;-----------------------------------------------------------------------------

; mPercentHandler(Y, X) -> (Y, Y*(X/100))
; Description: Calculate the X percent of Y.
mPercentHandler:
    call closeInputBuf
    call rclX
    call op2Set100
    bcall(_FPDiv)
    bcall(_OP1ToOP2)
    call rclY
    bcall(_FPMult)
    call replaceX
    ret

; mDeltaPercentHandler(Y, X) -> (Y, 100*(X-Y)/Y)
; Description: Calculate the change from Y to X as a percentage of Y. The
; resulting percentage can be given to the '%' menu key to get the delta
; change, then the '+' command will retrieve the original X.
mDeltaPercentHandler:
    call closeInputBuf
    call rclY
    bcall(_OP1ToOP2) ; OP2 = Y
    bcall(_PushRealO1) ; FPS = Y
    call rclX ; OP1 = X
    bcall(_FPSub) ; OP1 = X - Y
    bcall(_PopRealO2) ; OP2 = Y
    bcall(_FPDiv) ; OP1 = (X-Y)/Y
    call op2Set100
    bcall(_FPMult) ; OP1 = 100*(X-Y)/Y
    call replaceX
    ret

mLcmHandler:
mGcdHandler:
mPrimeHandler:
    jp mNotYetHandler

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

; Calculate the Permutation function:
; P(y, x) = P(n, r) = n!/(n-r)! = n(n-1)...(n-r+1)
;
; TODO: (n,r) are limited to [0.255]. It should be relatively easy to extended
; the range to [0,65535].
mPermHandler:
    call closeInputBuf
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
    call replaceXY
    ret

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
    call replaceXY
    ret

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
    bcall(_CkOP1FP0)
    ret z ; ok if OP1==0
    bcall(_CkPosInt)
    jr nz, validatePermCombError ; error if OP1 <= 0
    ld hl, 256
    bcall(_SetXXXXOP2) ; OP2=256
    bcall(_CpOP1OP2)
    ret c ; ok if OP1 < 255
validatePermCombError:
    bjump(_ErrDomain) ; throw exception

;-----------------------------------------------------------------------------

; mFactorialHandler(X) -> X!
; Description: Calculate the factorial of X.
mFactorialHandler:
    call closeInputBuf
    call rclX
    bcall(_Factorial)
    call replaceX
    ret

;-----------------------------------------------------------------------------

; mRandomHandler() -> rand()
; Description: Generate a random number [0,1) into the X register.
mRandomHandler:
    call closeInputBuf
    bcall(_Random)
    call liftStackNonEmpty
    call stoX
    ret

;-----------------------------------------------------------------------------

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

mInhgToHpaHandler:
    call closeInputBuf
    call rclX
    call op2SetHpaPerInhg
    bcall(_FPMult)
    call replaceX
    ret

mHpaToInhgHandler:
    call closeInputBuf
    call rclX
    call op2SetHpaPerInhg
    bcall(_FPDiv)
    call replaceX
    ret

;-----------------------------------------------------------------------------

mMiToKmHandler:
    call closeInputBuf
    call rclX
    call op2SetKmPerMi
    bcall(_FPMult)
    call replaceX
    ret

mKmToMiHandler:
    call closeInputBuf
    call rclX
    call op2SetKmPerMi
    bcall(_FPDiv)
    call replaceX
    ret

mFtToMHandler:
    call closeInputBuf
    call rclX
    call op2SetMPerFt
    bcall(_FPMult)
    call replaceX
    ret

mMToFtHandler:
    call closeInputBuf
    call rclX
    call op2SetMPerFt
    bcall(_FPDiv)
    call replaceX
    ret

;-----------------------------------------------------------------------------

mInToCmHandler:
    call closeInputBuf
    call rclX
    call op2SetCmPerIn
    bcall(_FPMult)
    call replaceX
    ret

mCmToInHandler:
    call closeInputBuf
    call rclX
    call op2SetCmPerIn
    bcall(_FPDiv)
    call replaceX
    ret

mMilToMicronHandler:
    call closeInputBuf
    call rclX
    call op2SetCmPerIn
    bcall(_FPMult)
    call op2Set10
    bcall(_FPMult)
    call replaceX
    ret

mMicronToMilHandler:
    call closeInputBuf
    call rclX
    call op2SetCmPerIn
    bcall(_FPDiv)
    call op2Set10
    bcall(_FPDiv)
    call replaceX
    ret

;-----------------------------------------------------------------------------

mLbsToKgHandler:
    call closeInputBuf
    call rclX
    call op2SetKgPerLbs
    bcall(_FPMult)
    call replaceX
    ret

mKgToLbsHandler:
    call closeInputBuf
    call rclX
    call op2SetKgPerLbs
    bcall(_FPDiv)
    call replaceX
    ret

mOzToGHandler:
    call closeInputBuf
    call rclX
    call op2SetGPerOz
    bcall(_FPMult)
    call replaceX
    ret

mGToOzHandler:
    call closeInputBuf
    call rclX
    call op2SetGPerOz
    bcall(_FPDiv)
    call replaceX
    ret

;-----------------------------------------------------------------------------

mGalToLHandler:
    call closeInputBuf
    call rclX
    call op2SetLPerGal
    bcall(_FPMult)
    call replaceX
    ret

mLToGalHandler:
    call closeInputBuf
    call rclX
    call op2SetLPerGal
    bcall(_FPDiv)
    call replaceX
    ret

mFlozToMlHandler:
    call closeInputBuf
    call rclX
    call op2SetMlPerFloz
    bcall(_FPMult)
    call replaceX
    ret

mMlToFlozHandler:
    call closeInputBuf
    call rclX
    call op2SetMlPerFloz
    bcall(_FPDiv)
    call replaceX
    ret

;-----------------------------------------------------------------------------

mCalToKjHandler:
    call closeInputBuf
    call rclX
    call op2SetKjPerKcal
    bcall(_FPMult)
    call replaceX
    ret

mKjToCalHandler:
    call closeInputBuf
    call rclX
    call op2SetKjPerKcal
    bcall(_FPDiv)
    call replaceX
    ret

mHpToKwHandler:
    call closeInputBuf
    call rclX
    call op2SetKwPerHp
    bcall(_FPMult)
    call replaceX
    ret

mKwToHpHandler:
    call closeInputBuf
    call rclX
    call op2SetKwPerHp
    bcall(_FPDiv)
    call replaceX
    ret

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

; Polar to Rectangular
; Input:
;   - stY: r
;   - stX: theta
; Output:
;   - stY: x
;   - stX: y
mPToRHandler:
    call closeInputBuf
    call rclX
    bcall(_OP1ToOP2) ; OP2 = stX = theta
    call rclY ; OP1 = stY = r
    bcall(_PToR) ; OP1 = x; OP2 = y (?)
    call replaceXYWithOP2OP1 ; stX=OP2=y; stY=OP1=x
    ret

; Rectangular to Polar
; Input:
;   - stY: x
;   - stX: y
; Output:
;   - stY: r
;   - stX: theta
mRtoPHandler:
    call closeInputBuf
    call rclX
    bcall(_OP1ToOP2) ; OP2 = stX = y
    call rclY ; OP1 = stY = x
    bcall(_RToP) ; OP1 = r; OP2 = theta (?)
    call replaceXYWithOP2OP1 ; stX=OP2=theta; stY=OP1=r
    ret

;-----------------------------------------------------------------------------

; HR(hh.mmss) = int(hh.mmss) + int(mm.ss)/60 + int(ss.nnnn)/3600
; Destroys: OP1, OP2, OP3, OP4 (temp)
mHmsToHrHandler:
    call closeInputBuf
    call rclX

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

    call replaceX
    ret

; HMS(hh.nnn) = int(hh + (mm + ss.nnn/100)/100 where
;   - mm = int(.nnn* 60)
;   - ss.nnn = frac(.nnn*60)*60
; Destroys: OP1, OP2, OP3, OP4 (temp)
mHrToHmsHandler:
    call closeInputBuf
    call rclX

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

    call replaceX
    ret

;-----------------------------------------------------------------------------
; Children nodes of MODE menu.
;-----------------------------------------------------------------------------

mFixHandler:
    call closeInputBuf
    ld hl, mFixCallback
    ld (argHandler), hl
    ld hl, mFixName
    jr enableArgMode
mFixCallback:
    res fmtExponent, (iy + fmtFlags)
    res fmtEng, (iy + fmtFlags)
    jr saveFormatDigits

mSciHandler:
    call closeInputBuf
    ld hl, mSciCallback
    ld (argHandler), hl
    ld hl, mSciName
    jr enableArgMode
mSciCallback:
    set fmtExponent, (iy + fmtFlags)
    res fmtEng, (iy + fmtFlags)
    jr saveFormatDigits

mEngHandler:
    call closeInputBuf
    ld hl, mEngCallback
    ld (argHandler), hl
    ld hl, mEngName
    jr enableArgMode
mEngCallback:
    set fmtExponent, (iy + fmtFlags)
    set fmtEng, (iy + fmtFlags)
    jr saveFormatDigits

; Description: Enter command argument input mode by prompting the user
; for a numerical parameter.
; Input: HL: argPrompt
; Output:
;   - argPrompt set with C string
;   - argBufSize set to 0
;   - rpnFlagsArgMode set
;   - inputBufFlagsInputDirty set
; Destroys: A, HL
enableArgMode:
    ld (argPrompt), hl
    xor a
    ld (argBufSize), a
    set rpnFlagsArgMode, (iy + rpnFlags)
    set inputBufFlagsInputDirty, (iy + inputBufFlags)
    ret

; Description: Save the (argValue) to (fmtDigits).
; Output:
;   - rpnFlagsStackDirty set
;   - rpnFlagsFloatModeDirty set
;   - fmtDigits updated
; Destroys: A
saveFormatDigits:
    set rpnFlagsStackDirty, (iy + rpnFlags)
    set rpnFlagsFloatModeDirty, (iy + rpnFlags)
    ld a, (argValue)
    cp 10
    jr c, saveFormatDigitsContinue
    ld a, $FF ; variable number of digits, not fixed
saveFormatDigitsContinue:
    ld (fmtDigits), a
    ret

;-----------------------------------------------------------------------------

mRadHandler:
    res trigDeg, (iy + trigFlags)
    set rpnFlagsTrigModeDirty, (iy + rpnFlags)
    ret

mDegHandler:
    set trigDeg, (iy + trigFlags)
    set rpnFlagsTrigModeDirty, (iy + rpnFlags)
    ret

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
