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

; Description: Addition for real, complex, and RpnObject.
; Input:
;   - OP1/OP2: Y
;   - OP3/OP4: X
; Output:
;   - OP1/OP2: Y+X
universalAdd:
    ; perform double-dispatch based on type of OP1 and OP3
    call getOp1RpnObjectType ; A=type; HL=OP1
    ; OP1=real
    cp rpnObjectTypeReal ; ZF=1 if Real
    jr z, universalAddRealPlusObject
    ; OP1=complex
    cp rpnObjectTypeComplex ; ZF=1 if Complex
    jp z, universalAddComplexPlusObject
    ; OP1=Date
    cp rpnObjectTypeDate ; ZF=1 if Date
    jp z, universalAddDatePlusObject
    ; OP1=Time
    cp rpnObjectTypeTime ; ZF=1 if Time
    jp z, universalAddTimePlusObject
    ; OP1=DateTime
    cp rpnObjectTypeDateTime ; ZF=1 if DateTime
    jp z, universalAddDateTimePlusObject
    ; OP1=Offset
    cp rpnObjectTypeOffset ; ZF=1 if Offset
    jp z, universalAddOffsetPlusObject
    ; OP1=OffsetDateTime
    cp rpnObjectTypeOffsetDateTime ; ZF=1 if OffsetDateTime
    jp z, universalAddOffsetDateTimePlusObject
    ; OP1=DayOfWeek
    cp rpnObjectTypeDayOfWeek ; ZF=1 if DayOfWeek
    jp z, universalAddDayOfWeekPlusObject
    ; OP1=Duration
    cp rpnObjectTypeDuration ; ZF=1 if Duration
    jp z, universalAddDurationPlusObject
    ; OP1=Denominate
    cp rpnObjectTypeDenominate ; ZF=1 if Duration
    jp z, universalAddDenominatePlusObject
    jp universalAddErr
; Real+object
universalAddRealPlusObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalAddRealPlusReal
    cp rpnObjectTypeComplex
    jr z, universalAddRealPlusComplex
    cp rpnObjectTypeDate
    jr z, universalAddRealPlusDate
    cp rpnObjectTypeTime
    jr z, universalAddRealPlusTime
    cp rpnObjectTypeDateTime
    jr z, universalAddRealPlusDateTime
    cp rpnObjectTypeOffset
    jr z, universalAddRealPlusOffset
    cp rpnObjectTypeOffsetDateTime
    jr z, universalAddRealPlusOffsetDateTime
    cp rpnObjectTypeDayOfWeek
    jr z, universalAddRealPlusDayOfWeek
    cp rpnObjectTypeDuration
    jr z, universalAddRealPlusDuration
    ; Real+Denominate not supported
    jr universalAddErr
universalAddRealPlusReal:
    call op3ToOp2
    bcall(_FPAdd) ; OP1=Y+X
    ret
universalAddRealPlusComplex:
    call convertOp1ToCp1
    bcall(_PushOP1) ; FPS=[Y]
    call cp3ToCp1 ; OP1/OP2=OP3/OP4
    call convertOp1ToCp1
    bcall(_CAdd) ; OP1/OP2 += FPS[OP1/OP2]; FPS=[]
    ret
universalAddRealPlusDate:
    bcall(_AddRpnDateByDays) ; OP1=days(OP1)+Date(OP3)
    ret
universalAddRealPlusTime:
    bcall(_AddRpnTimeBySeconds) ; OP1=days(OP1)+Time(OP3)
    ret
universalAddRealPlusDateTime:
    bcall(_AddRpnDateTimeBySeconds) ; OP1=seconds(OP1)+DateTime(OP3)
    ret
universalAddRealPlusOffset:
    bcall(_AddRpnOffsetByHours) ; OP1=hours(OP1)+Offset(OP3)
    ret
universalAddRealPlusOffsetDateTime:
    bcall(_AddRpnOffsetDateTimeBySeconds) ; OP1=seconds(OP1)+OffsetDateTime(OP3)
    ret
universalAddRealPlusDayOfWeek:
    bcall(_AddRpnDayOfWeekByDays) ; OP1=days(OP1)+DayOfWeek(OP3)
    ret
universalAddRealPlusDuration:
    bcall(_AddRpnDurationBySeconds) ; OP1=seconds(OP1)+Duration(OP3)
    ret
; Complex + object
universalAddComplexPlusObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalAddComplexPlusReal
    cp rpnObjectTypeComplex
    jr z, universalAddComplexPlusComplex
    jr universalAddErr
universalAddComplexPlusReal:
universalAddComplexPlusComplex:
    jr universalAddRealPlusComplex
; Date + object
universalAddDatePlusObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalAddDatePlusReal
    cp rpnObjectTypeDuration
    jr z, universalAddDatePlusDuration
    jr universalAddErr
universalAddDatePlusReal:
    bcall(_AddRpnDateByDays) ; OP1=Date(OP1)+days(OP3)
    ret
universalAddDatePlusDuration:
    bcall(_AddRpnDateByDuration) ; OP1=Date(OP1)+duration(OP3)
    ret
; Located in the middle to support 'jr' instructions.
universalAddErr:
    bcall(_ErrDataType)
; Time + object
universalAddTimePlusObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalAddTimePlusReal
    cp rpnObjectTypeDuration
    jr z, universalAddTimePlusDuration
    jr universalAddErr
universalAddTimePlusReal:
    bcall(_AddRpnTimeBySeconds) ; OP1=Time(OP1)+seconds(OP3)
    ret
universalAddTimePlusDuration:
    bcall(_AddRpnTimeByDuration) ; OP1=Time(OP1)+Duration(OP3)
    ret
; DateTime + object
universalAddDateTimePlusObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalAddDateTimePlusReal
    cp rpnObjectTypeDuration
    jr z, universalAddDateTimePlusDuration
    jr universalAddErr
universalAddDateTimePlusReal:
    bcall(_AddRpnDateTimeBySeconds) ; OP1=DateTime(OP1)+seconds(OP3)
    ret
universalAddDateTimePlusDuration:
    bcall(_AddRpnDateTimeByRpnDuration) ; OP1=DateTime(OP1)+duration(OP3)
    ret
; Offset + object
universalAddOffsetPlusObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalAddOffsetPlusReal
    cp rpnObjectTypeDuration
    jr z, universalAddOffsetPlusDuration
    jr universalAddErr
universalAddOffsetPlusReal:
    bcall(_AddRpnOffsetByHours) ; OP1=Offset(OP1)+hours(OP3)
    ret
universalAddOffsetPlusDuration:
    bcall(_AddRpnOffsetByDuration) ; OP1=Offset(OP1)+duration(OP3)
    ret
; OffsetDateTime + object
universalAddOffsetDateTimePlusObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalAddOffsetDateTimePlusReal
    cp rpnObjectTypeDuration
    jr z, universalAddOffsetDateTimePlusDuration
    jr universalAddErr
universalAddOffsetDateTimePlusReal:
    bcall(_AddRpnOffsetDateTimeBySeconds) ; OP1=ODT(OP1)+duration(OP3)
    ret
universalAddOffsetDateTimePlusDuration:
    bcall(_AddRpnOffsetDateTimeByDuration) ; OP1=ODT(OP1)+duration(OP3)
    ret
; DayOfWeek + object
universalAddDayOfWeekPlusObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalAddDayOfWeekPlusReal
    jr universalAddErr
universalAddDayOfWeekPlusReal:
    bcall(_AddRpnDayOfWeekByDays) ; OP1=DayOfWeek(OP1)+days(OP3)
    ret
; Duration + object
universalAddDurationPlusObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalAddDurationPlusReal
    cp rpnObjectTypeTime
    jr z, universalAddDurationPlusTime
    cp rpnObjectTypeDate
    jr z, universalAddDurationPlusDate
    cp rpnObjectTypeDateTime
    jr z, universalAddDurationPlusDateTime
    cp rpnObjectTypeOffset
    jr z, universalAddDurationPlusOffset
    cp rpnObjectTypeOffsetDateTime
    jr z, universalAddDurationPlusOffsetDateTime
    cp rpnObjectTypeDuration
    jr z, universalAddDurationPlusDuration
    jp universalAddErr
universalAddDurationPlusReal:
    bcall(_AddRpnDurationBySeconds) ; OP1=Duration(OP1)+seconds(OP3)
    ret
universalAddDurationPlusDuration:
    bcall(_AddRpnDurationByRpnDuration) ; OP1+=OP3
    ret
universalAddDurationPlusTime:
    jr universalAddTimePlusDuration
universalAddDurationPlusDate:
    jp universalAddDatePlusDuration
universalAddDurationPlusDateTime:
    jr universalAddDateTimePlusDuration
universalAddDurationPlusOffset:
    jr universalAddOffsetPlusDuration
universalAddDurationPlusOffsetDateTime:
    jr universalAddOffsetDateTimePlusDuration
; Denominate + object
universalAddDenominatePlusObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeDenominate
    jr z, universalAddDenominatePlusDenominate
    ; Denominate+Real not supported
    jp universalAddErr
universalAddDenominatePlusDenominate:
    bcall(_AddRpnDenominateByDenominate) ; OP1=Denominate(OP1)+Denominate(OP3)
    ret

; Description: Subtractions for real, complex, and Date objects.
; Input:
;   - OP1/OP2: Y
;   - OP3/OP4: X
; Output:
;   - OP1/OP2: Y-X
universalSub:
    ; perform double-dispatch based on type of OP1 and OP3
    call getOp1RpnObjectType ; A=type; HL=OP1
    ; OP1=real
    cp rpnObjectTypeReal ; ZF=1 if Real
    jr z, universalSubRealMinusObject
    ; OP1=complex
    cp rpnObjectTypeComplex ; ZF=1 if Complex
    jr z, universalSubComplexMinusObject
    ; OP1=Date
    cp rpnObjectTypeDate; ZF=1 if Date
    jr z, universalSubDateMinusObject
    ; OP1=Time
    cp rpnObjectTypeTime ; ZF=1 if Time
    jr z, universalSubTimeMinusObject
    ; OP1=DateTime
    cp rpnObjectTypeDateTime ; ZF=1 if DateTime
    jp z, universalSubDateTimeMinusObject
    ; OP1=Offset
    cp rpnObjectTypeOffset ; ZF=1 if Offset
    jp z, universalSubOffsetMinusObject
    ; OP1=OffsetDateTime
    cp rpnObjectTypeOffsetDateTime ; ZF=1 if OffsetDateTime
    jp z, universalSubOffsetDateTimeMinusObject
    ; OP1=DayOfWeek
    cp rpnObjectTypeDayOfWeek ; ZF=1 if DayOfWeek
    jp z, universalSubDayOfWeekMinusObject
    ; OP1=Duration
    cp rpnObjectTypeDuration ; ZF=1 if Duration
    jp z, universalSubDurationMinusObject
    ; OP1=Denominate
    cp rpnObjectTypeDenominate ; ZF=1 if Denominate
    jp z, universalSubDenominateMinusObject
    jr universalSubErr
; Real - object
universalSubRealMinusObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalSubRealMinusReal
    cp rpnObjectTypeComplex
    jr z, universalSubRealMinusComplex
    cp rpnObjectTypeDuration
    jr z, universalSubRealMinusDuration
    jr universalSubErr
universalSubRealMinusReal:
    call op3ToOp2
    bcall(_FPSub) ; OP1=Y-X
    ret
universalSubRealMinusComplex:
    jr universalSubComplexMinusComplex
universalSubRealMinusDuration:
    bcall(_SubSecondsByRpnDuration)
    ret
; Complex - object
universalSubComplexMinusObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalSubComplexMinusReal
    cp rpnObjectTypeComplex
    jr z, universalSubComplexMinusComplex
    jr universalSubErr
universalSubComplexMinusReal:
universalSubComplexMinusComplex:
    call convertOp1ToCp1
    bcall(_PushOP1) ; FPS=[Y]
    call cp3ToCp1 ; OP1/OP2=OP3/OP4
    call convertOp1ToCp1
    bcall(_CSub) ; OP1/OP2 = FPS[OP1/OP2] - OP1/OP2; FPS=[]
    ret
; Date - object
universalSubDateMinusObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalSubDateMinusDays
    cp rpnObjectTypeDate
    jr z, universalSubDateMinusDate
    cp rpnObjectTypeDuration
    jr z, universalSubDateMinusDuration
    jr universalSubErr
universalSubDateMinusDays:
universalSubDateMinusDate:
universalSubDateMinusDuration:
    bcall(_SubRpnDateByObject)
    ret
; Located in the middle to support 'jr' instructions.
universalSubErr:
    bcall(_ErrDataType)
; Time - object
universalSubTimeMinusObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalSubTimeMinusReal
    cp rpnObjectTypeTime
    jr z, universalSubTimeMinusTime
    cp rpnObjectTypeDuration
    jr z, universalSubTimeMinusDuration
    jr universalSubErr
universalSubTimeMinusReal:
universalSubTimeMinusTime:
universalSubTimeMinusDuration:
    bcall(_SubRpnTimeByObject)
    ret
; DateTime - object
universalSubDateTimeMinusObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalSubDateTimeMinusReal
    cp rpnObjectTypeDateTime
    jr z, universalSubDateTimeMinusDateTime
    cp rpnObjectTypeDuration
    jr z, universalSubDateTimeMinusDuration
    jr universalSubErr
universalSubDateTimeMinusReal:
universalSubDateTimeMinusDateTime:
universalSubDateTimeMinusDuration:
    bcall(_SubRpnDateTimeByObject)
    ret
; Offset - object
universalSubOffsetMinusObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalSubOffsetMinusReal
    cp rpnObjectTypeOffset
    jr z, universalSubOffsetMinusOffset
    cp rpnObjectTypeDuration
    jr z, universalSubOffsetMinusDuration
    jr universalSubErr
universalSubOffsetMinusReal:
universalSubOffsetMinusOffset:
universalSubOffsetMinusDuration:
    bcall(_SubRpnOffsetByObject)
    ret
; OffsetDateTime - object
universalSubOffsetDateTimeMinusObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalSubOffsetDateTimeMinusReal
    cp rpnObjectTypeOffsetDateTime
    jr z, universalSubOffsetDateTimeMinusOffsetDateTime
    cp rpnObjectTypeDuration
    jr z, universalSubOffsetDateTimeMinusDuration
    jr universalSubErr
universalSubOffsetDateTimeMinusReal:
universalSubOffsetDateTimeMinusOffsetDateTime:
universalSubOffsetDateTimeMinusDuration:
    bcall(_SubRpnOffsetDateTimeByObject)
    ret
; DayOfWeek - object
universalSubDayOfWeekMinusObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalSubDayOfWeekMinusReal
    cp rpnObjectTypeDayOfWeek
    jr z, universalSubDayOfWeekMinusDayOfWeek
    jr universalSubErr
universalSubDayOfWeekMinusReal:
universalSubDayOfWeekMinusDayOfWeek:
    bcall(_SubRpnDayOfWeekByRpnDayOfWeekOrDays)
    ret
; Duration - object
universalSubDurationMinusObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalSubDurationMinusReal
    cp rpnObjectTypeDuration
    jr z, universalSubDurationMinusDuration
    jr universalSubErr
universalSubDurationMinusReal:
universalSubDurationMinusDuration:
    bcall(_SubRpnDurationByRpnDurationOrSeconds)
    ret
; Denominate - object
universalSubDenominateMinusObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeDenominate
    jr z, universalSubDenominateMinusDenominate
    jp universalSubErr
universalSubDenominateMinusDenominate:
    bcall(_SubRpnDenominateByDenominate) ; OP1-=OP3
    ret

; Description: Multiplication for real and complex numbers.
; Input:
;   - OP1/OP2: Y
;   - OP3/OP4: X
; Output:
;   - OP1/OP2: Y*X
universalMult:
    ; perform double-dispatch based on type of OP1 and OP3
    call getOp1RpnObjectType ; A=type; HL=OP1
    ; OP1=real
    cp rpnObjectTypeReal ; ZF=1 if real
    jr z, universalMultRealByObject
    ; OP1=complex
    cp rpnObjectTypeComplex ; ZF=1 if complex
    jr z, universalMultComplexByObject
    ; OP1=Offset
    cp rpnObjectTypeOffset ; ZF=1 if Offset
    jr z, universalMultOffsetByObject
    ; OP1=Date
    cp rpnObjectTypeDate ; ZF=1 if Date
    jr z, universalMultDateByObject
    ; OP1=DateTime
    cp rpnObjectTypeDateTime ; ZF=1 if DateTime
    jr z, universalMultDateTimeByObject
    ; OP1=OffsetDateTime
    cp rpnObjectTypeOffsetDateTime ; ZF=1 if OffsetDateTime
    jr z, universalMultOffsetDateTimeByObject
    ; TODO: Implement Duration*Real and Real*Duration
    ; OP1=Denominate
    cp rpnObjectTypeDenominate ; ZF=1 if Denominate
    jp z, universalMultDenominateByObject
    jr universalMultErr
; Real * object
universalMultRealByObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalMultRealByReal
    cp rpnObjectTypeComplex
    jr z, universalMultRealByComplex
    cp rpnObjectTypeDate
    jr z, universalMultRealByDate
    cp rpnObjectTypeDateTime
    jr z, universalMultRealByDateTime
    cp rpnObjectTypeOffsetDateTime
    jr z, universalMultRealByOffsetDateTime
    cp rpnObjectTypeDenominate
    jr z, universalMultRealByDenominate
    jr universalMultErr
universalMultRealByReal:
    call op3ToOp2
    bcall(_FPMult) ; OP1=Y*X
    ret
universalMultRealByComplex:
    call cp1ExCp3 ; CP1=complex; CP3=real
    jr universalMultComplexByReal
universalMultRealByDate: ; Real * Date
    bcall(_ConvertRpnDateLikeToTimeZone)
    ret
universalMultRealByDateTime: ; Real * DateTime
    bcall(_ConvertRpnDateLikeToTimeZone)
    ret
universalMultRealByOffsetDateTime: ; Real * OffsetDateTime
    bcall(_ConvertRpnDateLikeToTimeZone)
    ret
universalMultRealByDenominate:
    bcall(_MultRpnDenominateByReal)
    ret
; Complex * object
universalMultComplexByObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalMultComplexByReal
    cp rpnObjectTypeComplex
    jr z, universalMultComplexByComplex
    jr universalMultErr
universalMultComplexByComplex:
    ; Complex*Complex
    bcall(_PushOP1) ; FPS=[Y]
    call cp3ToCp1 ; OP1/OP2=OP3/OP4
    bcall(_CMult) ; OP1/OP2 = FPS[OP1/OP2] * OP1/OP2; FPS=[]
    ret
universalMultComplexByReal:
    bcall(_CMltByReal) ; CP1=CP1*OP3
    ret
; Placed in the middle, so that 'jr' can be used instead of 'jp'.
universalMultErr:
    bcall(_ErrDataType)
; Date * object
universalMultDateByObject:
    bcall(_ConvertRpnDateLikeToTimeZone)
    ret
; DateTime * object
universalMultDateTimeByObject:
    bcall(_ConvertRpnDateLikeToTimeZone)
    ret
; Offset * object
universalMultOffsetByObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeDateTime
    jr z, universalMultOffsetByDateTime
    cp rpnObjectTypeOffsetDateTime
    jr z, universalMultOffsetByOffsetDateTime
    jr universalMultErr
universalMultOffsetByDate: ; Offset * RpnDate
    bcall(_ConvertRpnDateLikeToTimeZone)
    ret
universalMultOffsetByDateTime: ; Offset * RpnDateTime
    bcall(_ConvertRpnDateLikeToTimeZone)
    ret
universalMultOffsetByOffsetDateTime: ; Offset * RpnOffsetDateTime
    bcall(_ConvertRpnDateLikeToTimeZone)
    ret
; OffsetDateTime * object
universalMultOffsetDateTimeByObject:
    bcall(_ConvertRpnDateLikeToTimeZone)
    ret
; Denominate * object
universalMultDenominateByObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalMultDenominateByReal
    jr universalMultErr
universalMultDenominateByReal:
    bcall(_MultRpnDenominateByReal)
    ret

; Description: Division for real and complex numbers.
; Input:
;   - OP1/OP2: Y
;   - OP3/OP4: X
; Output:
;   - OP1/OP2: Y/X
universalDiv:
    ; perform double-dispatch based on type of OP1 and OP3
    call getOp1RpnObjectType ; A=type; HL=OP1
    cp rpnObjectTypeReal ; ZF=1 if real
    jr z, universalDivRealByObject
    cp rpnObjectTypeComplex ; ZF=1 if complex
    jr z, universalDivComplexByObject
    ; TODO: Implement Duration/Real
    ; OP1=Denominate
    cp rpnObjectTypeDenominate ; ZF=1 if Denominate
    jp z, universalDivDenominateByObject
    jr universalDivErr
; real / object
universalDivRealByObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal ; ZF=1 if real
    jr z, universalDivRealByReal
    cp rpnObjectTypeComplex ; ZF=1 if complex
    jr z, universalDivRealByComplex
    jr universalDivErr
universalDivRealByReal:
    call op3ToOp2
    bcall(_FPDiv) ; OP1=Y/X
    ret
universalDivRealByComplex:
    call convertOp1ToCp1
    bcall(_PushOP1)
    call cp3ToCp1
    bcall(_CDiv)
    ret
; Placed in the middle to support 'jr' instead of 'jp'.
universalDivErr:
    bcall(_ErrDataType)
; complex / object
universalDivComplexByObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalDivComplexByReal
    cp rpnObjectTypeComplex
    jr z, universalDivComplexByComplex
    jr universalDivErr
universalDivComplexByReal:
    bcall(_CDivByReal) ; CP1=CP1/OP3
    ret
universalDivComplexByComplex:
    bcall(_PushOP1) ; FPS=[Y]
    call cp3ToCp1 ; OP1/OP2=OP3/OP4
    bcall(_CDiv) ; OP1/OP2 = FPS[OP1/OP2] / OP1/OP2; FPS=[]
    ret
; Denominate / object
universalDivDenominateByObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalDivDenominateByReal
    cp rpnObjectTypeDenominate
    jr z, universalDivDenominateByDenominate
    jr universalDivErr
universalDivDenominateByReal:
    bcall(_DivRpnDenominateByReal)
    ret
universalDivDenominateByDenominate:
    bcall(_DivRpnDenominateByDenominate)
    ret

;-----------------------------------------------------------------------------

; Description: Change sign for real and complex numbers.
; Input:
;   - CP1:(Real|Complex|RpnDuration)=X
; Output:
;   - CP1:(Real|Complex|RpnDuration)=-X
universalChs:
    call getOp1RpnObjectType ; A=type; HL=OP1
    cp rpnObjectTypeReal ; ZF=1 if real
    jr z, universalChsReal
    cp rpnObjectTypeComplex ; ZF=1 if complex
    jr z, universalChsComplex
    cp rpnObjectTypeDuration ; ZF=1 if RpnDuration
    jr z, universalChsDuration
    cp rpnObjectTypeDenominate ; ZF=1 if RpnDenominate
    jr z, universalChsDenominate
universalChsErr:
    bcall(_ErrDataType)
universalChsReal:
    bcall(_InvOP1S)
    ret
universalChsComplex:
    bcall(_InvOP1SC)
    ret
universalChsDuration:
    bcall(_ChsRpnDuration)
    ret
universalChsDenominate:
    bcall(_ChsRpnDenominate)
    ret

;-----------------------------------------------------------------------------
; Alegbraic functions.
;-----------------------------------------------------------------------------

; Description: Reciprocal for real and complex numbers.
; Input:
;   - OP1/OP2:(Real|Complex)=X
; Output:
;   - OP1/OP2:(Real|Complex)=1/X
universalRecip:
    call getOp1RpnObjectType ; A=type; HL=OP1
    cp rpnObjectTypeReal ; ZF=1 if real
    jr z, universalRecipReal
    cp rpnObjectTypeComplex ; ZF=1 if complex
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
; Input:
;   - OP1/OP2:(Real|Complex)=X
; Output:
;   - OP1/OP2:(Real|Complex)=X^2
universalSquare:
    call getOp1RpnObjectType ; A=type; HL=OP1
    cp rpnObjectTypeReal ; ZF=1 if real
    jr z, universalSquareReal
    cp rpnObjectTypeComplex ; ZF=1 if complex
    jr z, universalSquareComplex
universalSquareErr:
    bcall(_ErrDataType)
universalSquareReal:
    bcall(_FPSquare)
    ret
universalSquareComplex:
    bcall(_CSquare)
    ret

; Description: Square root for real and complex numbers. Perform a Truncate()
; operation for DateTime and OffsetDateTime.
; Input:
;   - OP1/OP2:(Real|Complex|RpnDateTime|RpnOffsetDateTime)=X
;   - numResultMode
; Output:
;   - OP1/OP2:(Real|Complex|RpnDate|RpnDateTime)=sqrt(X)|date|dateTime
universalSqRoot:
    call getOp1RpnObjectType ; A=type; HL=OP1
    cp rpnObjectTypeReal ; ZF=1 if complex
    jr z, universalSqRootReal
    cp rpnObjectTypeComplex ; ZF=1 if complex
    jr z, universalSqRootComplex
    cp rpnObjectTypeDateTime ; ZF=1 if RpnDateTime
    jr z, universalSqRootDateTime
    cp rpnObjectTypeOffsetDateTime ; ZF=1 if RpnOffsetDateTime
    jr z, universalSqRootOffsetDateTime
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
universalSqRootDateTime:
    bcall(_TruncateRpnDateTime)
    ret
universalSqRootOffsetDateTime:
    bcall(_TruncateRpnOffsetDateTime)
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
    bcall(_CSquare) ; CP1=CP1^2
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
    call cp3ToCp1 ; CP1=CP3
    bcall(_CXrootY) ; CP1=CP1^(1/3); FPS=[]
    ret

;-----------------------------------------------------------------------------

; Description: Power function (Y^X) for real and complex numbers.
; Input:
;   - OP1/OP2:RpnObject=Y
;   - OP3/OP4:RpnObject=X
;   - numResultMode
; Output:
;   - OP1/OP2:RpnObject=Y^X (for real or complex)
universalPow:
    call getOp1RpnObjectType ; A=type; HL=OP1
    cp rpnObjectTypeReal ; ZF=1 if real
    jr z, universalPowRealToObject
    cp rpnObjectTypeComplex ; ZF=1 if complex
    jr z, universalPowComplexToObject
universalPowErr:
    bcall(_ErrDataType)
; pow(real,object)=real^object
universalPowRealToObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalPowRealToReal
    cp rpnObjectTypeComplex
    jr z, universalPowRealToComplex
    jr universalPowErr
universalPowRealToReal:
    ; Both X and Y are real. Now check if numResultMode is Real or Complex.
    call checkNumResultModeComplex ; ZF=1 if complex
    jr nz, universalPowNumResultModeReal
    ; Both are real, but the result could be complex, so we calculate the
    ; complex result, and chop off the imaginary part if it's zero.
    call convertOp1ToCp1
    call universalPowComplexToReal
    jp convertCp1ToOp1
universalPowNumResultModeReal:
    call op3ToOp2 ; OP2=X
    bcall(_YToX) ; OP1=OP1^OP2=Y^X
    ret
universalPowRealToComplex:
    call convertOp1ToCp1
    jr universalPowComplexToComplex
; pow(complex,object)=complex^object
universalPowComplexToObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalPowComplexToReal
    cp rpnObjectTypeComplex
    jr z, universalPowComplexToComplex
    jr universalPowErr
universalPowComplexToReal:
    call convertOp3ToCp3 ; CP3=complex(X)
    ; [[fallthrough]]
universalPowComplexToComplex:
    bcall(_PushOP1) ; FPS=[Y]
    call cp3ToCp1 ; CP1=OP3/OP4=X
    bcall(_CYtoX) ; CP1=(FPS)^(CP1)=Y^X; FPS=[]
    ret

; Description: Calculate XRootY(Y)=Y^(1/X) for real and complex numbers.
; Input:
;   - OP1/OP2: Y
;   - OP3/OP4: X
;   - numResultMode
; Output: OP1/OP2: Y^(1/X)
universalXRootY:
    call getOp1RpnObjectType ; A=type; HL=OP1
    cp rpnObjectTypeReal ; ZF=1 if real
    jr z, universalXRootYRealByObject
    cp rpnObjectTypeComplex ; ZF=1 if complex
    jr z, universalXRootYComplexByObject
universalXRootYErr:
    bcall(_ErrDataType)
; xrooty(real,object)=real^(1/object)
universalXRootYRealByObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal ; ZF=1 if real
    jr z, universalXRootYRealByReal
    cp rpnObjectTypeComplex ; ZF1=1 if complex
    jr z, universalXRootYRealByComplex
    jr universalXRootYErr
universalXRootYRealByReal:
    ; Both X and Y are real. Now check if numResultMode is Real or Complex.
    call checkNumResultModeComplex ; ZF=1 if complex
    jr nz, universalXRootYNumResultModeReal
    ; Both are real, but the result could be complex, so we calculate the
    ; complex result, and chop off the imaginary part if it's zero.
    call convertOp1ToCp1
    call universalXRootYComplexByReal
    jp convertCp1ToOp1 ; chop off the imaginary part if zero
universalXRootYNumResultModeReal:
    call op1ToOp2 ; OP2=Y
    call op3ToOp1 ; OP1=X
    bcall(_XRootY) ; OP1=OP2^(1/OP1), SDK documentation is incorrect
    ret
universalXRootYRealByComplex:
    call convertOp1ToCp1
    jr universalXRootYComplexByComplex
; xrooty(complex,object)=complex^(1/object)
universalXRootYComplexByObject:
    call getOp3RpnObjectType ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, universalXRootYComplexByReal
    cp rpnObjectTypeComplex
    jr z, universalXRootYComplexByComplex
    jr universalXRootYErr
universalXRootYComplexByReal:
    call convertOp3ToCp3
    ; [[fallthrough]]
universalXRootYComplexByComplex:
    bcall(_PushOP3) ; FPS=[X]
    bcall(_CXrootY) ; CP1=CP1^(1/FPS)=Y^(1/X); FPS=[]
    ret

;-----------------------------------------------------------------------------
; Transcendentals
;-----------------------------------------------------------------------------

; Description: Log for real and complex numbers. For record types (e.g.
; DateTime, OffsetDateTime), it causes splitting of the objects into smaller
; components.
; Input:
;   - OP1/OP2:(Real|Complex|RpnDateTime|RpnOffsetDateTime)=X
;   - numResultMode
; Output:
;   - OP1/OP2:(Real|Complex|RpnDate|RpnDateTime)=Log(X) (base 10) or Split(X)
;   - A:u8=numRetValues (1 for Real,Complex; 2 for DateTime,OffsetDateTime)
universalLog:
    call getOp1RpnObjectType ; A=type; HL=OP1
    cp rpnObjectTypeReal ; ZF=1 if real
    jr z, universalLogReal
    cp rpnObjectTypeComplex ; ZF=1 if complex
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
    bcall(_EToX)
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
    bcall(_PushOP3) ; FPS=[2i0]
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
