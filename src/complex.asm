;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Routines related to complex numbers.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Conversions from real numbers in OP1/OP2 to complex numbers in CP1.
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
    call checkOp1Real
    jr nz, convertErr
    call op2Set0
    bcall(_RectToComplex)
    ret

; Description: Convert a complex number to real if the imaginary part is zero.
; Do nothing if already a real.
convertCp1ToOp1:
    call checkOp1Complex ; ZF-1 if complex
    ret nz
    bcall(_CkOP2FP0) ; ZF=1 if im(CP1)==0
    ret nz
    bcall(_ComplexToRect)
    ret

; Description: Convert a real number in OP3 to a complex number in OP3/OP4 by
; setting the OP4 to 0, and setting the objectType to complex. If already a
; complex number, do nothing.
; Input: OP3
; Output: OP3/OP4
; Destroys: A
convertOp3ToCp3:
    call checkOp3Complex ; ZF=1 if complex
    ret z
    call checkOp3Real
    jr nz, convertErr
    call op4Set0
    bcall(_Rect3ToComplex3)
    ret

; Description: Throw an Err:DataType exception.
convertErr:
    bcall(_ErrDataType)

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
; Conversion bewteen complex and reals, to handle the '2ND LINK' function.
;-----------------------------------------------------------------------------

; Description: Convert the complex number in CP1 to either (a,b) or (r,theta)
; in OP1/OP2, depending on the complexMode.
; Input: CP1=complex
; Output: OP1,OP2=(a,b) or (r,theta)
; Destroys: all
complexToReals:
    ld a, (complexMode)
    cp a, complexModeRad
    jr nz, complexToRealsCheckDeg
    bcall(_ComplexToPolarRad)
    ret
complexToRealsCheckDeg:
    cp a, complexModeDeg
    jr nz, complexToRealsRect
    bcall(_ComplexToPolarDeg)
    ret
complexToRealsRect:
    bcall(_ComplexToRect)
    ret

; Description: Convert the (a,b) or (r,theta) (depending on complexMode) to a
; complex number in CP1.
; Input: OP1,OP2=(a,b) or (r,theta)
; Output: CP1=complex
; Destroys: all
realsToComplex:
    ld a, (complexMode)
    cp a, complexModeRad
    jr nz, realsToComplexCheckDeg
    bcall(_PolarRadToComplex)
    ret
realsToComplexCheckDeg:
    cp a, complexModeDeg
    jr nz, realsToComplexRect
    bcall(_PolarDegToComplex)
    ret
realsToComplexRect:
    bcall(_RectToComplex)
    ret

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
    bcall(_ComplexToRect) ; OP1=Re(Z); OP2=Im(Z)
    ret

; Description: Extract the imaginary part of complex(OP1/OP2).
; Output: OP1=Im(OP1/OP2)
complexImag:
    call checkOp1Complex ; ZF=1 if complex
    jr nz, complexDataTypeErr
    bcall(_ComplexToRect) ; OP1=Re(Z); OP2=Im(Z)
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
