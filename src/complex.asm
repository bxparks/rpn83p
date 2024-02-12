;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Universal Arithmetic operations, supporting both real and complex arguments.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; RPN object types. TODO: Move to rpnobject.asm.
;-----------------------------------------------------------------------------

; Description: Return the rpnObjectType of OP1/OP2.
; Input: OP1
; Output: A=rpnObjectType
; Destroys: A
getOp1RpnObjectType:
    ld a, (OP1)
    and $1f
    ret

;-----------------------------------------------------------------------------

; Description: Check that OP1 is a Real number.
; Input: OP1
; Output: ZF=1 if real
; Destroys: A
checkOp1Real:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeReal
    ret

; Description: Check that OP3 is a Real number.
; Input: OP3
; Output: ZF=1 if real
; Destroys: A
checkOp3Real:
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeReal
    ret

; Description: Check that both OP1 and OP3 are Real.
; Input: OP1, OP3
; Output: ZF=1 if both are real, ZF=0 otherwise
; Destroys: A
checkOp1AndOp3Real:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeReal
    ret nz
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeReal
    ret

;-----------------------------------------------------------------------------

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
checkOp1OrOp3Complex:
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

; Description: Check if OP1 is an RpnDate.
; Output: ZF=1 if RpnDate
checkOp1Date:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeDate
    ret

; Description: Check if OP3 is an RpnDate.
; Output: ZF=1 if RpnDate
checkOp3Date:
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeDate
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnDateTime.
; Output: ZF=1 if RpnDateTime
checkOp1DateTime:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeDateTime
    ret

; Description: Check if OP3 is an RpnDateTime.
; Output: ZF=1 if RpnDateTime
checkOp3DateTime:
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeDateTime
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnOffset.
; Output: ZF=1 if RpnOffset
checkOp1Offset:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeOffset
    ret

; Description: Check if OP3 is an RpnOffset.
; Output: ZF=1 if RpnOffset
checkOp3Offset:
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeOffset
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnOffsetDateTime.
; Output: ZF=1 if RpnOffsetDateTime
checkOp1OffsetDateTime:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeOffsetDateTime
    ret

; Description: Check if OP3 is an RpnOffsetDateTime.
; Output: ZF=1 if RpnOffsetDateTime
checkOp3OffsetDateTime:
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeOffsetDateTime
    ret

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

;-----------------------------------------------------------------------------
; Arithmetic operations.
; TODO: Move the following universal routines to a different file, since they
; now support more than real and complex numbers. Maybe universal.asm, or
; arithmetic.asm, algebraic.asm, transcendental.asm, etc.
;-----------------------------------------------------------------------------

; Description: Addition for real, complex, Date, and DateTime objects.
; Input:
;   - OP1/OP2: Y
;   - OP3/OP4: X
; Output:
;   - OP1/OP2: Y+X
universalAdd:
    call checkOp1AndOp3Real ; ZF=1 if real
    jr z, universalAddReal
    ;
    call checkOp1OrOp3Complex ; ZF=1 if complex
    jr z, universalAddComplex
    ;
    call checkOp1Date ; ZF=1 if Date
    jr z, universalAddDatePlusDays
    call checkOp3Date ; ZF=1 if Date
    jr z, universalAddDaysPlusDate
    ;
    call checkOp1DateTime ; ZF=1 if DateTime
    jr z, universalAddDateTimePlusSeconds
    call checkOp3DateTime ; ZF=1 if DateTime
    jr z, universalAddSecondsPlusDateTime
    ;
    call checkOp1OffsetDateTime ; ZF=1 if OffsetDateTime
    jr z, universalAddOffsetDateTimePlusSeconds
    call checkOp3OffsetDateTime ; ZF=1 if OffsetDateTime
    jr z, universalAddSecondsPlusOffsetDateTime
universalAddErr:
    ; throw Err:DataType if nothing matches
    bcall(_ErrDataType)
universalAddReal:
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
universalAddDatePlusDays:
    call checkOp3Real
    jr nz, universalAddErr
    bcall(_AddRpnDateByDays) ; OP1=Date(OP1)+days(OP3)
    ret
universalAddDaysPlusDate:
    call checkOp3Date
    jr nz, universalAddErr
    bcall(_AddRpnDateByDays) ; OP1=Date(OP1)+days(OP3)
    ret
universalAddDateTimePlusSeconds:
    call checkOp3Real
    jr nz, universalAddErr
    bcall(_AddRpnDateTimeBySeconds) ; OP1=DateTime(OP1)+seconds(OP3)
    ret
universalAddSecondsPlusDateTime:
    call checkOp3DateTime
    jr nz, universalAddErr
    bcall(_AddRpnDateTimeBySeconds) ; OP1=DateTime(OP1)+seconds(OP3)
    ret
universalAddOffsetDateTimePlusSeconds:
    call checkOp3Real
    jr nz, universalAddErr
    bcall(_AddRpnOffsetDateTimeBySeconds) ; OP1=OffsetDateTime(OP1)+seconds(OP3)
    ret
universalAddSecondsPlusOffsetDateTime:
    call checkOp3OffsetDateTime
    jr nz, universalAddErr
    bcall(_AddRpnOffsetDateTimeBySeconds) ; OP1=OffsetDateTime(OP1)+seconds(OP3)
    ret

; Description: Subtractions for real, complex, and Date objects.
; Input:
;   - OP1/OP2: Y
;   - OP3/OP4: X
; Output:
;   - OP1/OP2: Y-X
universalSub:
    call checkOp1AndOp3Real ; ZF=1 if both are Real
    jr z, universalSubReal
    ;
    call checkOp1OrOp3Complex ; ZF=1 if either are complex
    jr z, universalSubComplex
    ;
    call checkOp1Date ; ZF=1 if Date
    jr z, universalSubDateMinusObject
    call checkOp1DateTime ; ZF=1 if DateTime
    jr z, universalSubDateTimeMinusObject
    call checkOp1OffsetDateTime ; ZF=1 if OffsetDateTime
    jr z, universalSubOffsetDateTimeMinusObject
    ;
    call checkOp3Date ; ZF=1 if Date
    jr z, universalSubErr ; cannot subtract a Date
    call checkOp3DateTime ; ZF=1 if DateTime
    jr z, universalSubErr ; cannot subtract a DateTime
    call checkOp3Offset ; ZF=1 if Offset
    jr z, universalSubErr ; cannot subtract an Offset
    call checkOp3OffsetDateTime ; ZF=1 if OffsetDateTime
    jr z, universalSubErr ; cannot subtract an OffsetDateTime
universalSubErr:
    bcall(_ErrDataType)
universalSubReal:
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
;
universalSubDateMinusObject:
    call checkOp3Real
    jr z, universalSubDateMinusDays
    call checkOp3Date
    jr z, universalSubDateMinusDate
    jr universalSubErr
universalSubDateMinusDays:
universalSubDateMinusDate:
    bcall(_SubRpnDateByRpnDateOrDays)
    ret
;
universalSubDateTimeMinusObject:
    call checkOp3Real
    jr z, universalSubDateTimeMinusSeconds
    call checkOp3DateTime
    jr z, universalSubDateTimeMinusDateTime
    jr universalSubErr
universalSubDateTimeMinusSeconds:
universalSubDateTimeMinusDateTime:
    bcall(_SubRpnDateTimeByRpnDateTimeOrSeconds)
    ret
;
universalSubOffsetDateTimeMinusObject:
    call checkOp3Real
    jr z, universalSubOffsetDateTimeMinusSeconds
    call checkOp3OffsetDateTime
    jr z, universalSubOffsetDateTimeMinusOffsetDateTime
    jr universalSubErr
universalSubOffsetDateTimeMinusSeconds:
universalSubOffsetDateTimeMinusOffsetDateTime:
    bcall(_SubRpnOffsetDateTimeByRpnOffsetDateTimeOrSeconds)
    ret

; Description: Multiplication for real and complex numbers.
; Input:
;   - OP1/OP2: Y
;   - OP3/OP4: X
; Output:
;   - OP1/OP2: Y*X
universalMult:
    call checkOp1AndOp3Real ; ZF=1 if real
    jr z, universalMultReal
    ;
    call checkOp1OrOp3Complex ; ZF=1 if complex
    jr z, universalMultComplex
    ;
    call checkOp1DateTime ; ZF=1 if DateTime
    jr z, universalMultDateTimeByTimeZone
    ;
    call checkOp3DateTime ; ZF=1 if DateTime
    jr z, universalMultTimeZoneByDateTime
    ;
    call checkOp1OffsetDateTime ; ZF=1 if OffsetDateTime
    jr z, universalMultOffsetDateTimeByTimeZone
    ;
    call checkOp3OffsetDateTime ; ZF=1 if OffsetDateTime
    jr z, universalMultTimeZoneByOffsetDateTime
    jr universalMultErr
; Real*(Real|Complex)
universalMultReal:
    call checkOp3Real ; ZF=1 if real
    jr z, universalMultRealReal
    call checkOp3Complex ; ZF1 if complex
    jr nz, universalMultErr
    ; Real*Complex
    call cp1ExCp3 ; CP1=complex; CP3=real
    jr universalMultComplexReal
universalMultRealReal:
    ; Real*Real
    call op3ToOp2
    bcall(_FPMult) ; OP1=Y*X
    ret
; Complex*(Real|Complex)
universalMultComplex:
    call checkOp1Complex
    jr z, universalMultComplexSomething
    call cp1ExCp3 ; CP1:Complex; CP3:something
universalMultComplexSomething:
    call checkOp3Real
    jr z, universalMultComplexReal
    call checkOp3Complex
    jr z, universalMultComplexComplex
    jr universalMultErr
universalMultComplexComplex:
    ; Complex*Complex
    bcall(_PushOP1) ; FPS=[Y]
    call cp3ToCp1 ; OP1/OP2=OP3/OP4
    bcall(_CMult) ; OP1/OP2 = FPS[OP1/OP2] * OP1/OP2; FPS=[]
    ret
universalMultComplexReal:
    ; Complex*Real
    bcall(_CMltByReal) ; CP1=CP1*OP3
    ret
; Placed in the middle, so that 'jr' can be used instead of 'jp'.
universalMultErr:
    bcall(_ErrDataType)
; DateTime*(Offset|Real)
universalMultDateTimeByTimeZone:
    call checkOp3Offset
    jr z, universalMultDateTimeByOffset
    call checkOp3Real
    jr z, universalMultDateTimeByReal
    jr universalMultErr
universalMultDateTimeByOffset:
    bcall(_ConvertRpnDateTimeToOffset)
    ret
universalMultDateTimeByReal:
    bcall(_ConvertRpnDateTimeToReal)
    ret
; (Offset|Real)*DateTime
universalMultTimeZoneByDateTime:
    call checkOp1Offset
    jr z, universalMultOffsetByDateTime
    call checkOp1Real
    jr z, universalMultRealByDateTime
    jr universalMultErr
universalMultOffsetByDateTime:
    bcall(_ConvertRpnDateTimeToOffset)
    ret
universalMultRealByDateTime:
    bcall(_ConvertRpnDateTimeToReal)
    ret
; OffsetDateTime*(Offset|Real)
universalMultOffsetDateTimeByTimeZone:
    call checkOp3Offset
    jr z, universalMultOffsetDateTimeByOffset
    call checkOp3Real
    jr z, universalMultOffsetDateTimeByReal
    jr universalMultErr
universalMultOffsetDateTimeByOffset:
    bcall(_ConvertRpnOffsetDateTimeToOffset)
    ret
universalMultOffsetDateTimeByReal:
    bcall(_ConvertRpnOffsetDateTimeToReal)
    ret
; (Offset|Real)*OffsetDateTime
universalMultTimeZoneByOffsetDateTime:
    call checkOp1Offset
    jr z, universalMultOffsetByOffsetDateTime
    call checkOp1Real
    jr z, universalMultRealByOffsetDateTime
    jr universalMultErr
universalMultOffsetByOffsetDateTime:
    bcall(_ConvertRpnOffsetDateTimeToOffset)
    ret
universalMultRealByOffsetDateTime:
    bcall(_ConvertRpnOffsetDateTimeToReal)
    ret

; Description: Division for real and complex numbers.
; Input:
;   - OP1/OP2: Y
;   - OP3/OP4: X
; Output:
;   - OP1/OP2: Y/X
universalDiv:
    call checkOp1Real ; ZF=1 if real
    jr z, universalDivReal
    call checkOp1Complex ; ZF=1 if complex
    jr z, universalDivComplex
universalDivErr:
    bcall(_ErrDataType)
universalDivReal:
    call checkOp3Real ; ZF=1 if real
    jr z, universalDivRealReal
    call checkOp3Complex ; ZF=1 if complex
    jr nz, universalDivErr
universalDivRealComplex:
    call convertOp1ToCp1
    bcall(_PushOP1)
    call cp3ToCp1
    bcall(_CDiv)
    ret
universalDivRealReal:
    call op3ToOp2
    bcall(_FPDiv) ; OP1=Y/X
    ret
universalDivComplex:
    call checkOp3Real
    jr z, universalDivComplexReal
    call checkOp3Complex
    jr nz, universalDivErr
universalDivComplexComplex:
    bcall(_PushOP1) ; FPS=[Y]
    call cp3ToCp1 ; OP1/OP2=OP3/OP4
    bcall(_CDiv) ; OP1/OP2 = FPS[OP1/OP2] / OP1/OP2; FPS=[]
    ret
universalDivComplexReal:
    bcall(_CDivByReal) ; CP1=CP1/OP3
    ret

;-----------------------------------------------------------------------------

; Description: Change sign for real and complex numbers.
; Input:
;   - OP1/OP2: Y
; Output:
;   - OP1/OP2: -Y
universalChs:
    call checkOp1Real ; ZF=1 if real
    jr z, universalChsReal
    call checkOp1Complex ; ZF=1 if complex
    jr z, universalChsComplex
universalChsErr:
    bcall(_ErrDataType)
universalChsReal:
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
    call checkOp1Real ; ZF=1 if real
    jr z, universalRecipReal
    call checkOp1Complex ; ZF=1 if complex
    jr z, universalRecipComplex
universalRecipErr:
    bcall(_ErrDataType)
universalRecipReal:
    bcall(_FPRecip)
    ret
universalRecipComplex:
    bcall(_CRecip)
    ret

; Description: Square for real and complex numbers.
; Input: OP1/OP2: X
; Output: OP1/OP2: X^2
universalSquare:
    call checkOp1Real ; ZF=1 if real
    jr z, universalSquareReal
    call checkOp1Complex ; ZF=1 if complex
    jr z, universalSquareComplex
universalSquareErr:
    bcall(_ErrDataType)
universalSquareReal:
    bcall(_FPSquare)
    ret
universalSquareComplex:
    bcall(_CSquare)
    ret

; Description: Square root for real and complex numbers.
; Input: OP1/OP2: X; numResultMode
; Output: OP1/OP2: sqrt(X)
universalSqRoot:
    call checkOp1Real ; ZF=1 if complex
    jr z, universalSqRootReal
    call checkOp1Complex ; ZF=1 if complex
    jr z, universalSqRootComplex
universalSqRootErr:
    bcall(_ErrDataType)
universalSqRootReal:
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
    call checkOp1Real ; ZF=1 if real
    jr z, universalCubeReal
    call checkOp1Complex ; ZF=1 if complex
    jr z, universalCubeComplex
universalCubeErr:
    bcall(_ErrDataType)
universalCubeReal:
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
    call checkOp1Real ; ZF=1 if real
    jr z, universalCubeRootReal
    call checkOp1Complex ; ZF=1 if complex
    jr z, universalCubeRootComplex
universalCubeRootErr:
    bcall(_ErrDataType)
universalCubeRootReal:
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
    call checkOp1Real ; ZF=1 if real
    jr z, universalPowReal
    call checkOp1Complex ; ZF=1 if complex
    jr z, universalPowComplex
universalPowErr:
    bcall(_ErrDataType)
universalPowReal:
    call checkOp3Real
    jr z, universalPowRealReal
    call checkOp3Complex
    jr nz, universalPowErr
universalPowRealComplex:
    call convertOp1ToCp1
    jr universalPowComplexComplex
universalPowRealReal:
    ; Both X and Y are real. Now check if numResultMode is Real or Complex.
    call checkNumResultModeComplex ; ZF=1 if complex
    jr nz, universalPowNumResultModeReal
    ; Both are real, but the result could be complex, so we calculate the
    ; complex result, and chop off the imaginary part if it's zero.
    call convertOp1ToCp1
    call universalPowComplexReal
    jp convertCp1ToOp1
universalPowNumResultModeReal:
    call op3ToOp2 ; OP2=X
    bcall(_YToX) ; OP1=OP1^OP2=Y^X
    ret
universalPowComplex:
    call checkOp3Real
    jr z, universalPowComplexReal
    call checkOp3Complex
    jr nz, universalPowErr
universalPowComplexComplex:
    bcall(_PushOP1) ; FPS=[Y]
    call cp3ToCp1 ; CP1=OP3/OP4=X
    bcall(_CYtoX) ; CP1=(FPS)^(CP1)=Y^X; FPS=[]
    ret
universalPowComplexReal:
    call convertOp3ToCp3 ; CP3=complex(X)
    jr universalPowComplexComplex

; Description: Calculate XRootY(Y)=Y^(1/X) for real and complex numbers.
; Input:
;   - OP1/OP2: Y
;   - OP3/OP4: X
;   - numResultMode
; Output: OP1/OP2: Y^(1/X)
universalXRootY:
    call checkOp1Real ; ZF=1 if real
    jr z, universalXRootYReal
    call checkOp1Complex ; ZF=1 if complex
    jr z, universalXRootYComplex
universalXRootYErr:
    bcall(_ErrDataType)
universalXRootYReal:
    call checkOp3Real ; ZF=1 if real
    jr z, universalXRootYRealReal
    call checkOp3Complex ; ZF1=1 if complex
    jr nz, universalXRootYErr
universalXRootYRealComplex:
    call convertOp1ToCp1
    jr universalXRootYComplexComplex
universalXRootYRealReal:
    ; Both X and Y are real. Now check if numResultMode is Real or Complex.
    call checkNumResultModeComplex ; ZF=1 if complex
    jr nz, universalXRootYNumResultModeReal
    ; Both are real, but the result could be complex, so we calculate the
    ; complex result, and chop off the imaginary part if it's zero.
    call convertOp1ToCp1
    call universalXRootYComplexReal
    jp convertCp1ToOp1 ; chop off the imaginary part if zero
universalXRootYNumResultModeReal:
    call op1ToOp2 ; OP2=Y
    call op3ToOp1 ; OP1=X
    bcall(_XRootY) ; OP1=OP2^(1/OP1), SDK documentation is incorrect
    ret
universalXRootYComplex:
    call checkOp3Real
    jr z, universalXRootYComplexReal
    call checkOp3Complex
    jr nz, universalXRootYErr
universalXRootYComplexComplex:
    bcall(_PushOp3) ; FPS=[X]
    bcall(_CXrootY) ; CP1=CP1^(1/FPS)=Y^(1/X); FPS=[]
    ret
universalXRootYComplexReal:
    call convertOp3ToCp3
    jr universalXRootYComplexComplex

;-----------------------------------------------------------------------------
; Transcendentals
;-----------------------------------------------------------------------------

; Description: Log for real and complex numbers.
; Input: OP1/OP2: X; numResultMode
; Output: OP1/OP2: Log(X) (base 10)
universalLog:
    call checkOp1Real ; ZF=1 if real
    jr z, universalLogReal
    call checkOp1Complex ; ZF=1 if complex
    jr z, universalLogComplex
universalLogErr:
    bcall(_ErrDataType)
universalLogReal:
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
    call checkOp1Real ; ZF=1 if real
    jr z, universalTenPowReal
    call checkOp1Complex ; ZF=1 if complex
    jr z, universalTenPowComplex
universalTenPowErr:
    bcall(_ErrDataType)
universalTenPowReal:
    bcall(_TenX)
    ret
universalTenPowComplex:
    bcall(_CTenX)
    ret

; Description: Ln for real and complex numbers.
; Input: OP1/OP2: X; numResultMode
; Output: OP1/OP2: Ln(X)
universalLn:
    call checkOp1Real ; ZF=1 if real
    jr z, universalLnReal
    call checkOp1Complex ; ZF=1 if complex
    jr z, universalLnComplex
universlLnErr:
    bcall(_ErrDataType)
universalLnReal:
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
    call checkOp1Real ; ZF=1 if real
    jr z, universalExpReal
    call checkOp1Complex ; ZF=1 if complex
    jr z, universalExpComplex
universlExpErr:
    bcall(_ErrDataType)
universalExpReal:
    bcall(_EtoX)
    ret
universalExpComplex:
    bcall(_CEtoX)
    ret

; Description: TwoPow(X)=2^X for real and complex numbers.
; Input: OP1/OP2: X
; Output: OP1/OP2: 2^X
universalTwoPow:
    call checkOp1Real ; ZF=1 if real
    jr z, universalTwoPowReal
    call checkOp1Complex ; ZF=1 if complex
    jr z, universalTwoPowComplex
universlTwoPowErr:
    bcall(_ErrDataType)
universalTwoPowReal:
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
