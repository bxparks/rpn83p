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

; Description: Same as checkOp1Complex() for OP3.
; Input: OP1
; Output: ZF=1 if complex
; Destroys: A
checkOp3Complex:
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeComplex
    ret

; Description: Check if either OP1 or OP3 are complex.
; Input: OP1, OP3
; Output: ZF=1 if either parameters is complex
; Destroys: A
checkOp1OrOP3Complex:
    ld a, (OP1)
    ld b, a
    ld a, (OP3)
    or b
    and $1F
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
    call checkOp1Complex
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
    call checkOp1Complex
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
    call checkOp3Complex
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

; Description: Convert the complex number into either (a,b) or (r,theta),
; dependingon the complexMode.
; Input: CP1=complex
; Output:
;   - OP1,OP2=(a,b) or (r,theta)
;   - CF=1 if error; 0 if no error
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

; Description: Convert complex number into polar-rad form.
; Input: CP1: complex number
; Output: OP1: r; OP2: theta(radian)
complexToPolarRad:
    call splitCp1ToOp1Op2 ; OP1=Re(X); OP2=Im(X)
    ld a, (iy + trigFlags)
    push af ; stack=[trigFlags]
    res trigDeg, (iy + trigFlags)
    jr complexToPolarCommon

; Description: Convert complex number into polar-rad form.
; Input: CP1: complex number
; Output: OP1: r; OP2: theta(deg)
complexToPolarDeg:
    call splitCp1ToOp1Op2 ; OP1=Re(X); OP2=Im(X)
    ld a, (iy + trigFlags)
    push af ; stack=[trigFlags]
    set trigDeg, (iy + trigFlags)
    ; [[fallthrough]]

; Description: Common fragment of complexToPolarRad() and complexToPolarDeg().
; Currently, this routine overflows at a pretty low number of a and b for the
; complex number (a+bi) because the TI-OS RToP() function overflows when
; r^2=a^2+b^ becomes >= 1e128. So RToP() limits a and b to about 7.07e63.
;
; TODO: I think it would be fairly easy to write own version of RToP() which
; would extend the range to close to 7.07e99. That implementation would use the
; more robust formula: r^2 = a^2(1+(b/a)^2) = b^2((a/b)^2+1), depending on
; whether a > b or b > a. We would still have an overflow problem when r >=
; 1e100, since it cannot be displayed using normal floating point format.
complexToPolarCommon:
    ld hl, complexToPolarHandleException
    ; set up exception trap to reset trigFlags
    call APP_PUSH_ERRORH
    bcall(_RToP) ; OP1=r; OP2=theta; throws exception when r^2=a^2+b^2>=1e128
    call APP_POP_ERRORH
    ; Reset the original trigFlags
    pop af ; stack=[]; A=trigFlags
    ld (iy + trigFlags), a
    or a ; CF=0
    ret

complexToPolarHandleException:
    call op1Set0 ; OP1=0.0
    call op2Set0 ; OP2=0.0
    ; Reset the original trigFlags
    pop af ; stack=[]; A=trigFlags
    ld (iy + trigFlags), a
    scf ; CF=1
    ret

;-----------------------------------------------------------------------------

; Description: Convert the (a,b) or (r,theta) (depending on complexMode) to a
; complex number.
; dependingon the complexMode.
; Input: OP1,OP2=(a,b) or (r,theta)
; Output:
;   - CP1=complex
;   - CF=1 on error; CF=0 if ok
complexFromReals:
    ld a, (complexMode)
    cp a, complexModeRad
    jr z, complexFromPolarRad
    cp a, complexModeDeg
    jr z, complexFromPolarDeg
    ; Everything else, assume Rect
    call mergeOp1Op2ToCp1
    or a ; CF=0
    ret

complexFromPolarRad:
    ld a, (iy + trigFlags)
    push af ; stack=[trigFlags]
    res trigDeg, (iy + trigFlags)
    jr complexFromPolarCommon

complexFromPolarDeg:
    ld a, (iy + trigFlags)
    push af ; stack=[trigFlags]
    set trigDeg, (iy + trigFlags)
    ; [[fallthrough]]

; Description: Common fragment of complexFromPolarRad() and
; complexFromPolarDeg().
complexFromPolarCommon:
    ld hl, complexFromPolarHandleException
    ; set up exception trap to reset trigFlags
    call APP_PUSH_ERRORH
    bcall(_PToR) ; OP1=Re(z); OP2=Im(z)
    call APP_POP_ERRORH
    call mergeOp1Op2ToCp1 ; CP1=(OP1,OP2)
    ; Reset the original trigFlags
    pop af ; stack=[]; A=trigFlags
    ld (iy + trigFlags), a
    or a ; CF=0
    ret

complexFromPolarHandleException:
    call op1Set0 ; OP1=0.0
    call op2Set0 ; OP2=0.0
    call mergeOp1Op2ToCp1
    ; Reset the original trigFlags
    pop af ; stack=[]; A=trigFlags
    ld (iy + trigFlags), a
    scf ; CF=1
    ret


;-----------------------------------------------------------------------------
; Complex misc operations.
;-----------------------------------------------------------------------------

; Description: Calculate the ComplexConjugate of(OP1/OP2).
; Output: OP1/OP2=conj(OP1/OP2)
complexConj:
    call checkOp1Complex
    ret nz ; do nothing if not complex
    bcall(_Conj) ; X=conj(X)
    ret

; Description: Extract the real part of complex(OP1/OP2).
; Output: OP1=Re(OP1/OP2)
complexReal:
    call checkOp1Complex
    ret nz ; do nothing if not complex
    jp splitCp1ToOp1Op2 ; OP1=Re(X); OP2=Im(X)

; Description: Extract the imaginary part of complex(OP1/OP2).
; Output: OP1=Im(OP1/OP2)
complexImag:
    call checkOp1Complex
    ret nz ; do nothing if not complex
    call splitCp1ToOp1Op2 ; OP1=Re(X); OP2=Im(X)
    jp op2ToOp1 ; OP1=Im(X)

; Description: Return the magnitude or absolute value 'r' of the complex
; number.
; Input: CP1: complex number
complexAbs:
    call checkOp1Complex
    jr z, complexAbsCabs
    ; real X
    bcall(_ClrOP1S) ; clear sign bit of OP1
    ret
complexAbsCabs:
    bcall(_CAbs); OP1/OP2=Cabs(OP1/OP2)
    ret

; Description: Return the angle (argument) of the complex number.
; Input:
;   - CP1: complex number
;   - (trigFlags): trigDeg determines RAD or DEG mode of the result
complexAngle:
    call checkOp1Complex
    jr z, complexAngleComplex
    call op2Set0 ; Im(X)=0
    call mergeOp1Op2ToCp1 ; OP1/OP2=complex(OP1,OP2)
    ; [[fallthrough]]
complexAngleComplex:
    bcall(_Angle) ; OP1=CAngle(OP1/OP2)
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
    call checkOp1OrOP3Complex
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
    call checkOp1OrOP3Complex
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
    call checkOp1OrOP3Complex
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
    call checkOp1OrOP3Complex
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
    call checkOp1Complex
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

; Description: Power function (Y^X) for real and complex numbers.
; Input:
;   - OP1/OP2: Y
;   - OP3/OP4: X
;   - numResultMode
; Output:
;   - OP1/OP2: Y^X
universalPow:
    call checkOp1OrOP3Complex
    jr z, universalPowComplex
    ; X and Y are real numbers. Amazingly, YToX() will return a complex number
    ; when necessary, even if X and Y are real. We don't need to hack like
    ; universalSqRoot().
    call op3ToOp2
    bcall(_YToX) ; OP1=Y/X
    ret
universalPowComplex:
    call convertOp1ToCp1
    bcall(_PushOP1) ; FPS=[Y]
    call cp3ToCp1 ; OP1/OP2=OP3/OP4=X
    call convertOp1ToCp1
    bcall(_CYtoX) ; OP1/OP2=(FPS)^(CP1); FPS=[]
    ret

; Description: Reciprocal for real and complex numbers.
; Input: OP1/OP2: X
; Output: OP1/OP2: 1/X
universalRecip:
    call checkOp1Complex
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
    call checkOp1Complex
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
    call checkOp1Complex
    jr z, universalSqRootComplex
    ; X is a real number
    call checkNumResultModeComplex ; ZF=1 if complex
    jr nz, universalSqRootNumResultModeReal
    ; If numResultMode==complex, then it's possible for the real argument to
    ; produce a complex result, so we call CSqRoot() instead. But if we call
    ; that with a positive real number, then we want the result to be a real
    ; number as well, not a complex number with an imaginary part of 0. So, we
    ; check for an imaginary==0 and chop off the zero imaginary part. I think
    ; this hack would be unnecessary if we had access to the UnOPExec()
    ; function of the OS, but spasm-ng does not provide the list of constants
    ; for the various functions, so we can't use UnOPExec().
    ; this would be necessary if we
    call convertOp1ToCp1
    bcall(_CSqRoot)
    call convertCp1ToOp1 ; chop off the imaginary part if zero
    ret
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
    call checkOp1Complex
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
    call checkOp1Complex
    jr z, universalCubeRootComplex
    ; X is real
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

; Description: Calculate XRootY(Y)=Y^(1/X) for real and complex numbers.
; Input:
;   - OP1/OP2: Y
;   - OP3/OP4: X
;   - numResultMode
; Output: OP1/OP2: Y^(1/X)
universalXRootY:
    call checkOp1OrOP3Complex
    jr z, universalXRootYComplex
    ; X and Y are real. Amazingly, XRootY() will return a complex result when
    ; necessary. We don't need to add a hack like universalSqRoot().
    call op1ToOp2 ; OP2=Y
    call op3ToOp1 ; OP1=X
    bcall(_XRootY) ; OP2^(1/OP1), SDK documentation is incorrect
    ret
universalXRootYComplex:
    call convertOp1ToCp1
    call convertOp3ToCp3
    bcall(_PushOp3) ; FPS=[CP3]
    bcall(_CXrootY) ; CP1=CP1^(1/CP3); FPS=[]
    ret

;-----------------------------------------------------------------------------
; Transcendentals
;-----------------------------------------------------------------------------

; Description: Log for real and complex numbers.
; Input: OP1/OP2: X; numResultMode
; Output: OP1/OP2: Log(X) (base 10)
universalLog:
    call checkOp1Complex
    jr z, universalLogComplex
    ; X is a real number
    call checkNumResultModeComplex ; ZF=1 if complex
    jr nz, universalLogNumResultModeReal
    ; If numResultMode==complex, then it's possible for the real argument to
    ; produce a complex result, so we call CLog() instead. But if we call that
    ; with a positive real number, then we want the result to be a real number
    ; as well, not a complex number with an imaginary part of 0. So, we check
    ; for an imaginary==0 and chop off the zero imaginary part. I think this
    ; hack would be unnecessary if we had access to the UnOPExec() function of
    ; the OS, but spasm-ng does not provide the list of constants for the
    ; various functions, so we can't use UnOPExec(). this would be necessary if
    ; we
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
    call checkOp1Complex
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
    call checkOp1Complex
    jr z, universalLnComplex
    ; X is a real number
    call checkNumResultModeComplex ; ZF=1 if complex
    jr nz, universalLnNumResultModeReal
    ; If numResultMode==complex, then it's possible for the real argument to
    ; produce a complex result, so we call CLN() instead. But if we call that
    ; with a positive real number, then we want the result to be a real number
    ; as well, not a complex number with an imaginary part of 0. So, we check
    ; for an imaginary==0 and chop off the zero imaginary part. I think this
    ; hack would be unnecessary if we had access to the UnOPExec() function of
    ; the OS, but spasm-ng does not provide the list of constants for the
    ; various functions, so we can't use UnOPExec(). this would be necessary if
    ; we
    call convertOp1ToCp1
    bcall(_CLN)
    call convertCp1ToOp1 ; chop off the imaginary part if zero
    ret
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
    call checkOp1Complex
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
    call checkOp1Complex
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
