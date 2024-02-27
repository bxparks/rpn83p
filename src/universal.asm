;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Universal mathematical operations, supporting various RpnObject types (real,
; complex, Date, DateTime, Offset, OffsetDateTime, etc.)
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Arithmetic operations.
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
    call checkOp1Time ; ZF=1 if Time
    jr z, universalAddTimePlusSeconds
    call checkOp3Time ; ZF=1 if Time
    jr z, universalAddSecondsPlusTime
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
    ;
    call checkOp1DayOfWeek ; ZF=1 if DayOfWeek
    jr z, universalAddDayOfWeekPlusDays
    call checkOp3DayOfWeek ; ZF=1 if DayOfWeek
    jr z, universalAddDaysPlusDayOfWeek
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
universalAddTimePlusSeconds:
    call checkOp3Real
    jr nz, universalAddErr
    bcall(_AddRpnTimeBySeconds) ; OP1=Time(OP1)+days(OP3)
    ret
universalAddSecondsPlusTime:
    call checkOp1Real
    jr nz, universalAddErr
    bcall(_AddRpnTimeBySeconds) ; OP1=days(OP1)+Time(OP3)
    ret
universalAddDatePlusDays:
    call checkOp3Real
    jr nz, universalAddErr
    bcall(_AddRpnDateByDays) ; OP1=Date(OP1)+days(OP3)
    ret
universalAddDaysPlusDate:
    call checkOp1Real
    jr nz, universalAddErr
    bcall(_AddRpnDateByDays) ; OP1=days(OP1)+Date(OP3)
    ret
universalAddDateTimePlusSeconds:
    call checkOp3Real
    jr nz, universalAddErr
    bcall(_AddRpnDateTimeBySeconds) ; OP1=DateTime(OP1)+seconds(OP3)
    ret
universalAddSecondsPlusDateTime:
    call checkOp1Real
    jr nz, universalAddErr
    bcall(_AddRpnDateTimeBySeconds) ; OP1=seconds(OP1)+DateTime(OP3)
    ret
universalAddOffsetDateTimePlusSeconds:
    call checkOp3Real
    jr nz, universalAddErr
    bcall(_AddRpnOffsetDateTimeBySeconds) ; OP1=OffsetDateTime(OP1)+seconds(OP3)
    ret
universalAddSecondsPlusOffsetDateTime:
    call checkOp1Real
    jr nz, universalAddErr
    bcall(_AddRpnOffsetDateTimeBySeconds) ; OP1=seconds(OP1)+OffsetDateTime(OP3)
    ret
universalAddDayOfWeekPlusDays:
    call checkOp3Real
    jr nz, universalAddErr
    bcall(_AddRpnDayOfWeekByDays) ; OP1=DayOfWeek(OP1)+days(OP3)
    ret
universalAddDaysPlusDayOfWeek:
    call checkOp1Real
    jr nz, universalAddErr
    bcall(_AddRpnDayOfWeekByDays) ; OP1=days(OP1)+DayOfWeek(OP3)
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
    call checkOp1Time ; ZF=1 if Time
    jr z, universalSubTimeMinusObject
    call checkOp1Date ; ZF=1 if Date
    jr z, universalSubDateMinusObject
    call checkOp1DateTime ; ZF=1 if DateTime
    jr z, universalSubDateTimeMinusObject
    call checkOp1OffsetDateTime ; ZF=1 if OffsetDateTime
    jr z, universalSubOffsetDateTimeMinusObject
    call checkOp1DayOfWeek ; ZF=1 if DayOfWeek
    jr z, universalSubDayOfWeekMinusObject
    ; cannot support (OP1-OP3) for any other data type
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
universalSubTimeMinusObject:
    call checkOp3Real
    jr z, universalSubTimeMinusDays
    call checkOp3Time
    jr z, universalSubTimeMinusTime
    jr universalSubErr
universalSubTimeMinusDays:
universalSubTimeMinusTime:
    bcall(_SubRpnTimeByRpnTimeOrSeconds)
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
;
universalSubDayOfWeekMinusObject:
    call checkOp3Real
    jr z, universalSubDayOfWeekMinusDays
    call checkOp3DayOfWeek
    jr z, universalSubDayOfWeekMinusDayOfWeek
    jr universalSubErr
universalSubDayOfWeekMinusDays:
universalSubDayOfWeekMinusDayOfWeek:
    bcall(_SubRpnDayOfWeekByRpnDayOfWeekOrDays)
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
    bcall(_ConvertRpnDateTimeToTimeZoneAsOffset)
    ret
universalMultDateTimeByReal:
    bcall(_ConvertRpnDateTimeToTimeZoneAsReal)
    ret
; (Offset|Real)*DateTime
universalMultTimeZoneByDateTime:
    call checkOp1Offset
    jr z, universalMultOffsetByDateTime
    call checkOp1Real
    jr z, universalMultRealByDateTime
    jr universalMultErr
universalMultOffsetByDateTime:
    bcall(_ConvertRpnDateTimeToTimeZoneAsOffset)
    ret
universalMultRealByDateTime:
    bcall(_ConvertRpnDateTimeToTimeZoneAsReal)
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
    bcall(_ConvertRpnOffsetDateTimeToTimeZoneAsReal)
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
    bcall(_ConvertRpnOffsetDateTimeToTimeZoneAsReal)
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

; Description: Reciprocal for real and complex numbers. For record types (e.g.
; DateTime, OffsetDateTime), it causes splitting of the objects into smaller
; compoments.
; Input:
;    - OP1/OP2:RpnObject=X
; Output:
;   - OP1/OP2:RpnObject=1/X or Split(X)
;   - A:u8=numRetValues (1 for Real,Complex; 2 for DateTime,OffsetDateTime)
universalRecip:
    call getOp1RpnObjectType ; A=rpnObjectType
    cp rpnObjectTypeReal ; ZF=1 if real
    jr z, universalRecipReal
    cp rpnObjectTypeComplex ; ZF=1 if complex
    jr z, universalRecipComplex
    cp rpnObjectTypeDateTime ; ZF=1 if RpnDateTime
    jr z, universalRecipDateTime
    cp rpnObjectTypeOffsetDateTime ; ZF=1 if RpnOffsetDateTime
    jr z, universalRecipOffsetDateTime
universalRecipErr:
    bcall(_ErrDataType)
universalRecipReal:
    bcall(_FPRecip)
    ld a, 1
    ret
universalRecipComplex:
    bcall(_CRecip)
    ld a, 1
    ret
universalRecipDateTime:
    bcall(_SplitRpnDateTime) ; CP1=RpnTime; CP3=RpnDate
    ld a, 2
    ret
universalRecipOffsetDateTime:
    bcall(_SplitRpnOffsetDateTime) ; CP1=RpnOffset; CP3=RpnDateTime
    ld a, 2
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

;-----------------------------------------------------------------------------

; Description: Power function (Y^X) for real and complex numbers. Also
; overloaded for Date, DateTime, and Offset types to implement the
; Merge(Y,X)->X functionality.
; Input:
;   - OP1/OP2:RpnObject=Y
;   - OP3/OP4:RpnObject=X
;   - numResultMode
; Output:
;   - OP1/OP2:RpnObject=Y^X (for real or complex) or Merge(Y,X) for Date-related
universalPow:
    call getOp1RpnObjectType ; A=rpnObjectType
    cp rpnObjectTypeReal ; ZF=1 if real
    jr z, universalPowReal
    cp rpnObjectTypeComplex ; ZF=1 if complex
    jr z, universalPowComplex
    cp rpnObjectTypeTime ; ZF=1 if RpnTime
    jr z, universalPowTime
    cp rpnObjectTypeDate ; ZF=1 if RpnDate
    jr z, universalPowDate
    cp rpnObjectTypeOffset ; ZF=1 if RpnOffset
    jr z, universalPowOffset
    cp rpnObjectTypeDateTime ; ZF=1 if RpnDateTime
    jr z, universalPowDateTime
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
;
universalPowTime:
    call checkOp3Date ; ZF=1 if OP3=RpnDate
    jr nz, universalPowErr
    bcall(_MergeRpnDateWithRpnTime) ; OP1=rpnDateTime
    ret
universalPowDate:
    call checkOp3Time ; ZF=1 if OP3=RpnTime
    jr nz, universalPowErr
    bcall(_MergeRpnDateWithRpnTime) ; OP1=rpnDateTime
    ret
universalPowOffset:
    call checkOp3DateTime ; ZF=1 if OP3=RpnDateTime
    jr nz, universalPowErr
    bcall(_MergeRpnDateTimeWithRpnOffset) ; OP1=rpnOffsetDateOffset
    ret
universalPowDateTime:
    call checkOp3Offset ; ZF=1 if OP3=RpnOffset
    jr nz, universalPowErr
    bcall(_MergeRpnDateTimeWithRpnOffset) ; OP1=rpnOffsetDateTime
    ret

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
