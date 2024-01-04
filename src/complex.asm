;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Universal Arithmetic operations, supporting both real and complex arguments.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; RPN object types.
;-----------------------------------------------------------------------------

; Description: Return the rpnObjectType of OP1/OP2.
; Input: OP1
; Output: A=C=rpnObjectType
; Destroys: A
getOp1RpnObjectType:
    ld a, (OP1)
    and $1f
    ld c, a
    ret

; Description: Same as CkOP1Cplx() OS routine without the bcall() overhead.
; Input: OP1
; Output: ZF=1 if complex
; Destroys: A
checkOp1Complex:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeComplex
    ret

; Description: Check if either OP1 or OP3 is complex.
; Input: OP1, OP3
; Output: ZF=1 if either parameter is complex
; Destroys: A
checkOp1OrOP3Complex:
    call checkOp1Complex ; ZF=1 if complex
    ret z
    ; [[fallthrough]]

; Description: Same as checkOp1Complex() for OP3.
; Input: OP1
; Output: ZF=1 if complex
; Destroys: A
checkOp3Complex:
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeComplex
    ret

;-----------------------------------------------------------------------------

; Description: Convert a real number in OP1 to a complex number in OP1/OP2 by
; setting the OP2 to 0, and setting the objectType to complex. If already a
; complex number, do nothing.
; Input: OP1
; Output: OP1/OP2
; Destroys: A
convertOp1ToCp1:
    call checkOp1Complex ; ZF=1 if complex
    ret z
    call op2Set0
    ; [[fallthrough]]

; Description: Convert real numbers in OP1 and OP2 into a complex number.
; Destroys: A
mergeOp1Op2ToCp1:
    ld a, (OP1)
    or rpnObjectTypeComplex
    ld (OP1), a
    ld a, (OP2)
    or rpnObjectTypeComplex
    ld (OP2), a
    ret

; Description: Convert the complex number in OP1 and OP2 into 2 real numbers.
; Destroys: A
splitCp1ToOp1Op2:
    ld a, (OP1)
    and ~rpnObjectTypeComplex
    ld (OP1), a
    ld a, (OP2)
    and ~rpnObjectTypeComplex
    ld (OP2), a
    ret

; Description: Convert a complex number to real if the imaginary part is zero.
; Do nothing if already a real.
convertCp1ToOp1:
    call checkOp1Complex ; ZF-1 if complex
    ret nz
    bcall(_CkOP2FP0) ; ZF=1 if im(CP1)==0
    jr z, splitCp1ToOp1Op2
    ret

;-----------------------------------------------------------------------------

; Description: Convert a real number in OP3 to a complex number in OP3/OP4 by
; setting the OP4 to 0, and setting the objectType to complex. If already a
; complex number, do nothing.
; Input: OP3
; Output: OP3/OP4
; Destroys: A
convertOp3ToCp3:
    call checkOp3Complex ; ZF=1 if complex
    ret z
    call op4Set0
    ; [[fallthrough]]

; Description: Convert real numbers in OP3 and OP4 into a complex number in OP3.
; Destroys: A
mergeOp3Op4ToCp3:
    ld a, (OP3)
    or rpnObjectTypeComplex
    ld (OP3), a
    ld a, (OP4)
    or rpnObjectTypeComplex
    ld (OP4), a
    ret

; Description: Convert the complex number in OP3 and OP4 into 2 real numbers.
; Destroys: A
splitCp3ToOp3Op4:
    ld a, (OP3)
    and ~rpnObjectTypeComplex
    ld (OP3), a
    ld a, (OP4)
    and ~rpnObjectTypeComplex
    ld (OP4), a
    ret

;-----------------------------------------------------------------------------
; Complex result modes.
;-----------------------------------------------------------------------------

; Description: Initialize the number result modes to "real results only".
initNumResultMode:
    ld a, numResultModeReal
    ld (numResultMode), a
    ret

; Description: Update the TI-OS 'fmtFlags' from the 'numResult' variable in
; RPN83P.
updateNumResultMode:
    ld a, (numResultMode)
    cp numResultModeComplex
    jr z, updateNumResultModeComplex
    set fmtReal, (iy + fmtFlags)
    res fmtRect, (iy + fmtFlags)
    res fmtPolar, (iy + fmtFlags)
    ret
updateNumResultModeComplex:
    res fmtReal, (iy + fmtFlags)
    set fmtRect, (iy + fmtFlags)
    res fmtPolar, (iy + fmtFlags)
    ret

; Description: Check if numResultMode is complex.
; Output: ZF=1 if numResultMode==numResultModeComplex
checkNumResultModeComplex:
    ld a, (numResultMode)
    cp numResultModeComplex
    ret

;-----------------------------------------------------------------------------
; Complex display modes.
;-----------------------------------------------------------------------------

; Description: Sanitize the current complex display mode.
updateComplexMode:
    ld a, (complexMode)
    cp a, complexModeRect
    ret z
    cp a, complexModeRad
    ret z
    cp a, complexModeDeg
    ret z
    ; [[fallthrough]]

; Description: Initialize the complex display mode.
initComplexMode:
    ld a, complexModeRect
    ld (complexMode), a
    ret

;-----------------------------------------------------------------------------
; Conversion bewteen complex and reals.
;-----------------------------------------------------------------------------

; Description: Convert the complex number in CP1 to either (a,b) or (r,theta)
; in OP1/OP2, depending on the complexMode.
; Input: CP1=complex
; Output:
;   - OP1,OP2=(a,b) or (r,theta)
;   - CF=1 if error; 0 if no error
; Destroys: all
complexToReals:
    ld a, (complexMode)
    cp a, complexModeRad
    jr z, complexToPolarRad
    cp a, complexModeDeg
    jr z, complexToPolarDeg
    ; Everything else, assume Rect
    call splitCp1ToOp1Op2
    or a ; CF=0
    ret

; Description: Convert the (a,b) or (r,theta) (depending on complexMode) to a
; complex number in CP1.
; Input: OP1,OP2=(a,b) or (r,theta)
; Output:
;   - CP1=complex
;   - CF=1 on error; CF=0 if ok
; Destroys: all
realsToComplex:
    ld a, (complexMode)
    cp a, complexModeRad
    jp z, polarRadToComplex
    cp a, complexModeDeg
    jp z, polarDegToComplex
    ; Everything else, assume Rect
    call mergeOp1Op2ToCp1
    or a ; CF=0
    ret

;-----------------------------------------------------------------------------
; Complex rectangular and polar conversions. We create custom implementations,
; instead of using the built-in RToP() and PToR() TI-OS functions, for two
; reasons:
; 1) The OS functions are buggy. For example, RToP() overflows internally when
; it calculators r^2 = a^2 + b^2. For example, it throws an exception when
; a=b=7.1e63 (1/sqrt(2)*10^64).
; 2) The output of the OS routines depend on the 'trigFlags' global parameter,
; but our routines must be deterministic, instead of changing its results
; depending on the DEG or RAD modes.
;-----------------------------------------------------------------------------

; Description: Convert complex number into polar-rad form.
; It looks like Cabs() does *not* throw an Err:Overflow exception when the
; exponent becomes >=100. An 'r' of >=1E100 can be returned and will be
; displayed on the screen in polar mode.
;
; Input: CP1: Z, complex number
; Output: OP1,OP2: (r, thetaRad)
; Destroys: all, OP1-OP5
complexToPolarRad:
    ; Cabs() does not seem to suffer the internal overflow and underflow
    ; problems of RToP(). This implementation also uses fewer bcall() which is
    ; very expensive, so I think this is the winner.
    bcall(_PushOP1) ; FPS=[Z]
    call op1ExOp2 ; OP1=Im(Z)=y; OP2=Re(Z)=x
    ld d, 0 ; set undocumented parameter for ATan2Rad()
    bcall(_ATan2Rad) ; OP1=Angle(Z), destroys OP1-OP5
    call op1ToOp3 ; OP3=Angle(Z)
    bcall(_PopOP1) ; FPS=[]; CP1=Z
    bcall(_PushRealO3) ; FPS=[Angle(Z)]
    bcall(_CAbs) ; OP1=Cabs(Z); destroys OP1-OP4
    bcall(_PopRealO2) ; FPS=[]; OP2=Angle(Z)
    ret

; Description: Convert complex number into polar-degree form.
; Input: CP1: Z, complex number
; Output: OP1,OP2: (r, thetaDeg)
; Destroys: all
complexToPolarDeg:
    call complexToPolarRad ; OP1=abs(Z); OP2=radian(Z)
    bcall(_PushRealO1) ; FPS=[abs(Z)]
    call op2ToOp1 ; OP1=radian(Z)
    bcall(_RToD) ; OP1=degree(Z)
    call op1ToOp2 ; OP2=degree(Z)
    bcall(_PopRealO1) ; FPS=[]; OP1=abs(Z)
    ret

#ifdef USE_RTOP_WITH_SCALING
; Description: Scale OP1,OP2 by the max(|OP1|,|OP2|). NOTE: Maybe it's easier
; to just call the CAbs() and Angle() functions separately, instead of trying
; to work around the bug/limitation of RToP().
; Input: OP1=a,OP2=b
; Output: OP3=scale=max(|OP1|,|OP2|,1.0)
complexNormalize:
    bcall(_AbsO1O2Cp) ; if Abs(OP1)>=Abs(OP2): CF=0
    jr nc, complexNormalizeOP1Bigger
    ; OP2 bigger
    call op2ToOp3 ; OP3=scale
    jr complexNormalizeCheckScale
complexNormalizeOP1Bigger:
    call op1ToOP3 ; OP3=scale
complexNormalizeCheckScale:
    ; Check the scaling factor for zer0
    call checkOp3FP0 ; if zero: ZF=1
    jr nz, complexNormalizeCheckReduce
    bcall(_OP3Set1) ; OP3=1.0
complexNormalizeCheckReduce:
    call clearOp3Sign ; OP3=scale=max(|a|,|b|,1.0)
    ; Reduce OP1,OP2 by scale. Sorry for all the stack juggling.
    bcall(_PushRealO3) ; FPS=[scale]
    bcall(_PushRealO3) ; FPS=[scale,scale]
    bcall(_PushRealO2) ; FPS=[scale,scale,b]
    call op3ToOp2 ; OP2=scale
    bcall(_FPDiv) ; OP1=a/scale
    call exchangeFPSOP1 ; FPS=[scale,scale,a/scale]; OP1=b
    call exchangeFPSFPS ; FPS=[scale,a/scale,scale]
    bcall(_PopRealO2) ; FPS=[scale,a/scale]; OP2=scale
    bcall(_FPDiv) ; OP1=b/scale
    call op1ToOp2 ; OP2=/b/scale
    bcall(_PopRealO1) ; FPS=[scale]; OP1=a/scale
    bcall(_PopRealO3) ; FPS=[]; OP3=scale
    ret
#endif

;-----------------------------------------------------------------------------

; Description: Convert polar radian form (OP1,OP2)=(r,radian) to a complex
; number in CP1.
; Input: OP1,OP2=(r,thetaRad)
; Output: CP1=(a+bi)
polarRadToComplex:
    bcall(_PushRealO1) ; FPS=[r]
    call op2ToOp1 ; OP1=rad
    bcall(_SinCosRad) ; OP1=sin(rad); OP2=cos(rad)
    call op1ExOp2 ; OP1=cos(rad); OP2=sin(rad)
    bcall(_PopRealO3) ; FPS=[]; OP3=r
    bcall(_CMltByReal) ; OP1=r*cos(rad); OP2=r*sin(rad)
    jp mergeOp1Op2ToCp1 ; CP1=(OP1,OP2)

; Description: Convert polar degree form (OP1,OP2)=(r,degree) to a complex
; number in CP1.
; Input: OP1,OP2=(r,thetaDeg)
; Output: CP1=(a+bi)
polarDegToComplex:
    bcall(_PushRealO1) ; FPS=[r]
    call op2ToOp1 ; OP1=thetaDeg
    bcall(_DToR) ; OP1=thetaRad
    bcall(_SinCosRad) ; OP1=sin(rad); OP2=cos(rad)
    call op1ExOp2 ; OP1=cos(rad); OP2=sin(rad)
    bcall(_PopRealO3) ; FPS=[]; OP3=r
    bcall(_CMltByReal) ; OP1=r*cos(rad); OP2=r*sin(rad)
    jp mergeOp1Op2ToCp1 ; CP1=(OP1,OP2)

;-----------------------------------------------------------------------------
; Complex misc operations. To avoid confusing the user, these throw an
; Err:DataType if the argument is not complex. In other words, these are not
; "universal" routines which operate on both types.
;-----------------------------------------------------------------------------

complexDataTypeErr:
    bcall(_ErrDataType)

; Description: Calculate the ComplexConjugate of(OP1/OP2).
; Output: OP1/OP2=conj(OP1/OP2)
complexConj:
    call checkOp1Complex ; ZF=1 if complex
    jr nz, complexDataTypeErr
    bcall(_Conj) ; X=conj(X)
    ret

; Description: Extract the real part of complex(OP1/OP2).
; Output: OP1=Re(OP1/OP2)
complexReal:
    call checkOp1Complex ; ZF=1 if complex
    jr nz, complexDataTypeErr
    jp splitCp1ToOp1Op2 ; OP1=Re(Z); OP2=Im(Z)

; Description: Extract the imaginary part of complex(OP1/OP2).
; Output: OP1=Im(OP1/OP2)
complexImag:
    call checkOp1Complex ; ZF=1 if complex
    jr nz, complexDataTypeErr
    call splitCp1ToOp1Op2 ; OP1=Re(Z); OP2=Im(Z)
    jp op2ToOp1 ; OP1=Im(Z)

; Description: Return the magnitude or absolute value 'r' of the complex
; number.
; Input: CP1: complex number
; Output: OP1: abs(Z) or abs(X)
complexAbs:
    call checkOp1Complex ; ZF=1 if complex
    jr nz, complexDataTypeErr
    bcall(_CAbs); OP1=Cabs(CP1)
    ret

; Description: Return the angle (argument) of the complex number. This function
; returns the angle in the unit specified by the trigonometric mode (RAD, DEG).
; This makes CANG the *only* complex function to depend on the trigonometric
; mode. This seemed to make sense because the CARG function is so similar to
; the ATN2 function.
;
; Another alternative was to use the complex display mode, and return radians in
; PRAD mode, and degrees in PDEG mode. But for RECT, the only thing that made
; sense was to return radians which seemed confusing. Also, the CANG function
; becomes the only complex function that depends on how complex numbers are
; rendered. This seemed likely to cause even more problems if keystroke
; programming is added later, because the behavior of the program now depends
; on how something is *displayed* on the screen.
;
; A second alternatve was to always return radians for CANG. But that meant
; that the screen would show DEG to indicate degree mode, but CANG always
; return radians. And that seemed more confusing than letting CANG depend on
; the trigonometric mode.
;
; Input:
;   - CP1: complex number
;   - (trigFlags): RAD, DEG
complexAngle:
    call checkOp1Complex ; ZF=1 if complex
    jr nz, complexDataTypeErr
    ; calculate angle in radians
    call op1ExOp2 ; OP1=Im(Z)=y; OP2=Re(Z)=x
    ld d, 0 ; set undocumented parameter for ATan2()
    bcall(_ATan2) ; OP1=radian(Z), destroys OP1-OP5
    ret

;-----------------------------------------------------------------------------
; Arithmetic operations.
;-----------------------------------------------------------------------------

; Description: Addition for real and complex numbers.
; Input:
;   - OP1/OP2: Y
;   - OP3/OP4: X
; Output:
;   - OP1/OP2: Y+X
universalAdd:
    call checkOp1OrOP3Complex ; ZF=1 if complex
    jr z, universalAddComplex
    ; X and Y are real numbers.
    call op3ToOp2
    bcall(_FPAdd) ; OP1=Y+X
    ret
universalAddComplex:
    call convertOp1ToCp1
    bcall(_PushOP1) ; FPS=[Y]
    call cp3ToCp1 ; OP1/OP2=OP3/OP4
    call convertOp1ToCp1
    bcall(_CAdd) ; OP1/OP2 += FPS[OP1/OP2]; FPS=[]
    ret

; Description: Subtractions for real and complex numbers.
; Input:
;   - OP1/OP2: Y
;   - OP3/OP4: X
; Output:
;   - OP1/OP2: Y-X
universalSub:
    call checkOp1OrOP3Complex ; ZF=1 if complex
    jr z, universalSubComplex
    ; X and Y are real numbers.
    call op3ToOp2
    bcall(_FPSub) ; OP1=Y-X
    ret
universalSubComplex:
    call convertOp1ToCp1
    bcall(_PushOP1) ; FPS=[Y]
    call cp3ToCp1 ; OP1/OP2=OP3/OP4
    call convertOp1ToCp1
    bcall(_CSub) ; OP1/OP2 = FPS[OP1/OP2] - OP1/OP2; FPS=[]
    ret

; Description: Multiplication for real and complex numbers.
; Input:
;   - OP1/OP2: Y
;   - OP3/OP4: X
; Output:
;   - OP1/OP2: Y*X
universalMult:
    call checkOp1OrOP3Complex ; ZF=1 if complex
    jr z, universalMultComplex
    ; X and Y are real numbers.
    call op3ToOp2
    bcall(_FPMult) ; OP1=Y*X
    ret
universalMultComplex:
    call convertOp1ToCp1
    bcall(_PushOP1) ; FPS=[Y]
    call cp3ToCp1 ; OP1/OP2=OP3/OP4
    call convertOp1ToCp1
    ; TODO: If one of the arguments is real, then we could use CMltByReal() for
    ; a little bit of efficiency, probably.
    bcall(_CMult) ; OP1/OP2 = FPS[OP1/OP2] * OP1/OP2; FPS=[]
    ret

; Description: Division for real and complex numbers.
; Input:
;   - OP1/OP2: Y
;   - OP3/OP4: X
; Output:
;   - OP1/OP2: Y/X
universalDiv:
    call checkOp1OrOP3Complex ; ZF=1 if complex
    jr z, universalDivComplex
    ; X and Y are real numbers.
    call op3ToOp2
    bcall(_FPDiv) ; OP1=Y/X
    ret
universalDivComplex:
    call convertOp1ToCp1
    bcall(_PushOP1) ; FPS=[Y]
    call cp3ToCp1 ; OP1/OP2=OP3/OP4
    call convertOp1ToCp1
    ; TODO: If the divisor is real, then we could use CDivByReal() for a little
    ; bit of efficiency, probably.
    bcall(_CDiv) ; OP1/OP2 = FPS[OP1/OP2] / OP1/OP2; FPS=[]
    ret

;-----------------------------------------------------------------------------

; Description: Change sign for real and complex numbers.
; Input:
;   - OP1/OP2: Y
; Output:
;   - OP1/OP2: -Y
universalChs:
    call checkOp1Complex ; ZF=1 if complex
    jr z, universalChsComplex
    ; X is a real number
    bcall(_InvOP1S)
    ret
universalChsComplex:
    bcall(_InvOP1SC)
    ret

;-----------------------------------------------------------------------------
; Alegbraic functions.
;-----------------------------------------------------------------------------

; Description: Reciprocal for real and complex numbers.
; Input: OP1/OP2: X
; Output: OP1/OP2: 1/X
universalRecip:
    call checkOp1Complex ; ZF=1 if complex
    jr z, universalRecipComplex
    ; X is a real number
    bcall(_FPRecip)
    ret
universalRecipComplex:
    bcall(_CRecip)
    ret

; Description: Square for real and complex numbers.
; Input: OP1/OP2: X
; Output: OP1/OP2: X^2
universalSquare:
    call checkOp1Complex ; ZF=1 if complex
    jr z, universalSquareComplex
    ; X is a real number
    bcall(_FPSquare)
    ret
universalSquareComplex:
    bcall(_CSquare)
    ret

; Description: Square root for real and complex numbers.
; Input: OP1/OP2: X; numResultMode
; Output: OP1/OP2: sqrt(X)
universalSqRoot:
    call checkOp1Complex ; ZF=1 if complex
    jr z, universalSqRootComplex
    ; X is a real number
    call checkNumResultModeComplex ; ZF=1 if complex
    jr nz, universalSqRootNumResultModeReal
    ; The argument is real but the result could be complex, so we calculate the
    ; complex result and chop off the imaginary part if it's zero. I think this
    ; hack would be unnecessary if we had access to the UnOPExec() function of
    ; the OS, but spasm-ng does not provide the list of constants for the
    ; various functions, so we can't use UnOPExec().
    call convertOp1ToCp1
    bcall(_CSqRoot)
    jp convertCp1ToOp1 ; chop off the imaginary part if zero
universalSqRootNumResultModeReal:
    bcall(_SqRoot)
    ret
universalSqRootComplex:
    bcall(_CSqRoot)
    ret

; Description: Calculate X^3 for real and complex numbers. For some reason, the
; TI-OS provides a Cube() function for reals, but not for complex. Which is
; strange because it provides both a Csquare() and Square() function.
; Input: OP1/OP2: X
; Output: OP1/OP2: X^3
; Destroys: all, OP1-OP6
universalCube:
    call checkOp1Complex ; ZF=1 if complex
    jr z, universalCubeComplex
    ; X is real
    bcall(_Cube)
    ret
universalCubeComplex:
    call cp1ToCp5 ; CP5=CP1
    bcall(_Csquare) ; CP1=CP1^2
    bcall(_PushOP1) ; FPS=[CP1^2]
    call cp5ToCp1 ; CP1=CP5
    bcall(_CMult) ; CP1=CP1^3; FPS=[]
    ret

; Description: Calculate CBRT(X)=X^(1/3) for real and complex numbers.
; Input: OP1/OP2: X
; Output: OP1/OP2: X^(1/3)
universalCubeRoot:
    call checkOp1Complex ; ZF=1 if complex
    jr z, universalCubeRootComplex
    ; X is real, the result will always be real
    bcall(_OP1ToOP2) ; OP2=X
    bcall(_OP1Set3) ; OP1=3
    bcall(_XRootY) ; OP2^(1/OP1), SDK documentation is incorrect
    ret
universalCubeRootComplex:
    call cp1ToCp3 ; CP3=CP1
    bcall(_OP1Set3) ; OP1=3
    call convertOp1ToCp1 ; CP1=(3i0)
    bcall(_PushOP1) ; FPS=[3i0]
    call cp3Tocp1 ; CP1=CP3
    bcall(_CXrootY) ; CP1=CP1^(1/3); FPS=[]
    ret

; Description: Power function (Y^X) for real and complex numbers.
; Input:
;   - OP1/OP2: Y
;   - OP3/OP4: X
;   - numResultMode
; Output:
;   - OP1/OP2: Y^X
universalPow:
    call checkOp1OrOP3Complex ; ZF=1 if complex
    jr z, universalPowComplex
    ; Both X and Y are real. Now check if numResultMode is Real or Complex.
    call checkNumResultModeComplex ; ZF=1 if complex
    jr nz, universalPowNumResultModeReal
    ; Both are real, but the result could be complex, so we calculate the
    ; complex result, and chop off the imaginary part if it's zero.
    call universalPowComplex ; awesome assembly trick, calling our own tail
    jp convertCp1ToOp1
universalPowNumResultModeReal:
    call op3ToOp2 ; OP2=X
    bcall(_YToX) ; OP1=OP1^OP2=Y^X
    ret
universalPowComplex:
    call convertOp1ToCp1
    bcall(_PushOP1) ; FPS=[Y]
    call cp3ToCp1 ; CP1=OP3/OP4=X
    call convertOp1ToCp1
    bcall(_CYtoX) ; CP1=(FPS)^(CP1)=Y^X; FPS=[]
    ret

; Description: Calculate XRootY(Y)=Y^(1/X) for real and complex numbers.
; Input:
;   - OP1/OP2: Y
;   - OP3/OP4: X
;   - numResultMode
; Output: OP1/OP2: Y^(1/X)
universalXRootY:
    call checkOp1OrOP3Complex ; ZF=1 if complex
    jr z, universalXRootYComplex
    ; Both X and Y are real. Now check if numResultMode is Real or Complex.
    call checkNumResultModeComplex ; ZF=1 if complex
    jr nz, universalXRootYNumResultModeReal
    ; Both are real, but the result could be complex, so we calculate the
    ; complex result, and chop off the imaginary part if it's zero.
    call universalXRootYComplex ; awesome assembly trick, calling our own tail
    jp convertCp1ToOp1 ; chop off the imaginary part if zero
universalXRootYNumResultModeReal:
    call op1ToOp2 ; OP2=Y
    call op3ToOp1 ; OP1=X
    bcall(_XRootY) ; OP1=OP2^(1/OP1), SDK documentation is incorrect
    ret
universalXRootYComplex:
    call convertOp1ToCp1
    call convertOp3ToCp3
    bcall(_PushOp3) ; FPS=[X]
    bcall(_CXrootY) ; CP1=CP1^(1/FPS)=Y^(1/X); FPS=[]
    ret

;-----------------------------------------------------------------------------
; Transcendentals
;-----------------------------------------------------------------------------

; Description: Log for real and complex numbers.
; Input: OP1/OP2: X; numResultMode
; Output: OP1/OP2: Log(X) (base 10)
universalLog:
    call checkOp1Complex ; ZF=1 if complex
    jr z, universalLogComplex
    ; X is a real number
    call checkNumResultModeComplex ; ZF=1 if complex
    jr nz, universalLogNumResultModeReal
    ; The argument is real but the result could be complex, so we calculate the
    ; complex result and chop off the imaginary part if it's zero. I think this
    ; hack would be unnecessary if we had access to the UnOPExec() function of
    ; the OS, but spasm-ng does not provide the list of constants for the
    ; various functions, so we can't use UnOPExec().
    call convertOp1ToCp1
    bcall(_CLog)
    call convertCp1ToOp1 ; chop off the imaginary part if zero
    ret
universalLogNumResultModeReal:
    bcall(_LogX)
    ret
universalLogComplex:
    bcall(_CLog)
    ret

; Description: TenPow(X)=10^X for real and complex numbers.
; Input: OP1/OP2: X
; Output: OP1/OP2: 10^X
universalTenPow:
    call checkOp1Complex ; ZF=1 if complex
    jr z, universalTenPowComplex
    ; X is a real number
    bcall(_TenX)
    ret
universalTenPowComplex:
    bcall(_CTenX)
    ret

; Description: Ln for real and complex numbers.
; Input: OP1/OP2: X; numResultMode
; Output: OP1/OP2: Ln(X)
universalLn:
    call checkOp1Complex ; ZF=1 if complex
    jr z, universalLnComplex
    ; X is a real number
    call checkNumResultModeComplex ; ZF=1 if complex
    jr nz, universalLnNumResultModeReal
    ; The argument is real but the result could be complex, so we calculate the
    ; complex result and chop off the imaginary part if it's zero. I think this
    ; hack would be unnecessary if we had access to the UnOPExec() function of
    ; the OS, but spasm-ng does not provide the list of constants for the
    ; various functions, so we can't use UnOPExec().
    call convertOp1ToCp1
    bcall(_CLN)
    jp convertCp1ToOp1 ; chop off the imaginary part if zero
universalLnNumResultModeReal:
    bcall(_LnX)
    ret
universalLnComplex:
    bcall(_CLN)
    ret

; Description: Exp for real and complex numbers.
; Input: OP1/OP2: X
; Output: OP1/OP2: e^X
universalExp:
    call checkOp1Complex ; ZF=1 if complex
    jr z, universalExpComplex
    ; X is a real number
    bcall(_EtoX)
    ret
universalExpComplex:
    bcall(_CEtoX)
    ret

; Description: TwoPow(X)=2^X for real and complex numbers.
; Input: OP1/OP2: X
; Output: OP1/OP2: 2^X
universalTwoPow:
    call checkOp1Complex ; ZF=1 if complex
    jr z, universalTwoPowComplex
    ; X is a real number
    call op1ToOp2 ; OP2 = X
    bcall(_OP1Set2) ; OP1 = 2
    bcall(_YToX) ; OP1=OP1^OP2=2^X
    ret
universalTwoPowComplex:
    bcall(_OP3Set2) ; OP3=2
    call convertOp3ToCp3 ; CP3=2i0
    bcall(_PushOp3) ; FPS=[2i0]
    bcall(_CYtoX) ; CP1=FPS^CP1=2^(X); FPS=[]
    ret

; Description: Log2(X) = log_base_2(X) = log(X)/log(2)
; Input: OP1/OP2: X; numResultMode
; Output: OP1/OP2: log2(X)
universalLog2:
    call universalLn ; CP1=ln(X)
    bcall(_PushOP1) ; FPS=[ln(X)]
    bcall(_OP1Set2) ; OP1=2.0
    bcall(_LnX) ; OP1=ln(2.0) ; TODO: Precalculate ln(2)
    call op1ToOp3 ; OP3=ln(2.0)
    bcall(_PopOP1) ; FPS=[]; CP1=ln(x)
    jp universalDiv ; CP1=CP1/ln(2)

; Description: LogB(X) = log(X)/log(B).
; Input:
;   - OP1/OP2: X
;   - OP3/OP4: B
; Output: OP1/OP2: LogB(X)
universalLogBase:
    bcall(_PushOP3) ; FPS=[B]
    call universalLn ; CP1=ln(X)
    bcall(_PopOP3) ; FPS=[]; CP3=B
    bcall(_PushOP1) ; FPS=[ln(X)]
    call cp3ToCp1 ; CP1=B
    call universalLn ; CP1=ln(B)
    call cp1ToCp3 ; CP3=ln(B)
    bcall(_PopOP1) ; FPS=[]; CP1=ln(X)
    jp universalDiv ; CP1=CP1/CP3
