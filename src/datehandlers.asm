;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; DATE > Row 1
;-----------------------------------------------------------------------------

mLeapYearHandler:
    call closeInputAndRecallX ; OP1=X=year
    bcall(_IsLeap) ; OP1=0 or 1
    jp replaceX

mDayOfWeekHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1=X=RpnDateLike{}
    bcall(_DayOfWeek) ; OP1:RpnDayOfWeek
    jp replaceX

mDateToEpochDaysHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1=X=RpnDateLike{}
    bcall(_RpnDateToEpochDays) ; OP1=float(days)
    jp replaceX

mEpochDaysToDateHandler:
    call closeInputAndRecallX ; OP1=X=epochDays
    bcall(_EpochDaysToRpnDate) ; OP1=Date(epochDays)
    jp replaceX

;-----------------------------------------------------------------------------
; DATE > Row 2
;-----------------------------------------------------------------------------

mDateRelatedToSecondsHandler:
    call closeInputAndRecallRpnDateRelatedX ; OP1==dateRelatedObject; A=type
    cp rpnObjectTypeDate ; ZF=1 if RpnDate
    jr z, mDateRelatedToSecondsHandlerDate
    cp rpnObjectTypeTime ; ZF=1 if RpnDateTime
    jr z, mDateRelatedToSecondsHandlerTime
    cp rpnObjectTypeDateTime ; ZF=1 if RpnDateTime
    jr z, mDateRelatedToSecondsHandlerDateTime
    cp rpnObjectTypeOffset ; ZF=1 if RpnOffset
    jr z, mDateRelatedToSecondsHandlerOffset
    cp rpnObjectTypeOffsetDateTime ; ZF=1 if RpnOffsetDateTime
    jr z, mDateRelatedToSecondsHandlerOffsetDateTime
    bcall(_ErrDataType)
mDateRelatedToSecondsHandlerDate:
    bcall(_RpnDateToEpochSeconds) ; OP1=epochSeconds
    jr mDateRelatedToSecondsHandlerEnd
mDateRelatedToSecondsHandlerTime:
    bcall(_RpnTimeToSeconds) ; OP1=epochSeconds
    jr mDateRelatedToSecondsHandlerEnd
mDateRelatedToSecondsHandlerDateTime:
    bcall(_RpnDateTimeToEpochSeconds) ; OP1=epochSeconds
    jr mDateRelatedToSecondsHandlerEnd
mDateRelatedToSecondsHandlerOffset:
    bcall(_RpnOffsetToSeconds) ; OP1=seconds
    jr mDateRelatedToSecondsHandlerEnd
mDateRelatedToSecondsHandlerOffsetDateTime:
    bcall(_RpnOffsetDateTimeToEpochSeconds) ; OP1=epochSeconds
    ; [[fallthrough]]
mDateRelatedToSecondsHandlerEnd:
    jp replaceX

mSecondsToTimeHandler:
    call closeInputAndRecallX ; OP1=X=seconds
    bcall(_SecondsToRpnTime) ; OP1=Time(seconds)
    jp replaceX

mEpochSecondsToDateHandler:
    call closeInputAndRecallX ; OP1=X=epochSeconds
    bcall(_EpochSecondsToRpnDate) ; OP1=Date(epochSeconds)
    jp replaceX

mEpochSecondsToDateTimeHandler:
    call closeInputAndRecallX ; OP1=X=epochSeconds
    bcall(_EpochSecondsToRpnDateTime) ; OP1=DateTime(epochSeconds)
    jp replaceX

mEpochSecondsToOffsetDateTimeHandler:
    call closeInputAndRecallX ; OP1=X=epochSeconds
    bcall(_EpochSecondsToRpnOffsetDateTime) ; OP1=OffsetDateTime(epochSeconds)
    jp replaceX

;-----------------------------------------------------------------------------
; DATE > EPCH > Row 1
;-----------------------------------------------------------------------------

mEpochUnixHandler:
    bcall(_SelectUnixEpochDate)
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mEpochUnixNameSelector:
    ld a, (epochType)
    cp epochTypeUnix
    jr z, mEpochUnixNameSelectorAlt
    or a ; CF=0
    ret
mEpochUnixNameSelectorAlt:
    scf
    ret

;-----------------------------------------------------------------------------

mEpochNtpHandler:
    bcall(_SelectNtpEpochDate)
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mEpochNtpNameSelector:
    ld a, (epochType)
    cp epochTypeNtp
    jr z, mEpochNtpNameSelectorAlt
    or a ; CF=0
    ret
mEpochNtpNameSelectorAlt:
    scf
    ret

;-----------------------------------------------------------------------------

mEpochGpsHandler:
    bcall(_SelectGpsEpochDate)
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mEpochGpsNameSelector:
    ld a, (epochType)
    cp epochTypeGps
    jr z, mEpochGpsNameSelectorAlt
    or a
    ret
mEpochGpsNameSelectorAlt:
    scf
    ret

;-----------------------------------------------------------------------------

mEpochTiosHandler:
    bcall(_SelectTiosEpochDate)
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mEpochTiosNameSelector:
    ld a, (epochType)
    cp epochTypeTios
    jr z, mEpochTiosNameSelectorAlt
    or a ; CF=0
    ret
mEpochTiosNameSelectorAlt:
    scf
    ret

;-----------------------------------------------------------------------------

mEpochCustomHandler:
    bcall(_SelectCustomEpochDate)
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mEpochCustomNameSelector:
    ld a, (epochType)
    cp epochTypeCustom
    jr z, mEpochCustomNameSelectorAlt
    or a ; CF=0
    ret
mEpochCustomNameSelectorAlt:
    scf
    ret

;-----------------------------------------------------------------------------
; DATE > EPCH > Row 2
;-----------------------------------------------------------------------------

mEpochSetCustomHandler:
    call closeInputAndRecallRpnDateX ; OP1=X=RpnDate{}
    bcall(_SetCustomEpochDate)
    ld a, errorCodeEpochStored
    ld (handlerCode), a
    ret

mEpochGetCustomHandler:
    call closeInputAndRecallNone
    bcall(_GetCustomEpochDate)
    jp pushToX

;-----------------------------------------------------------------------------
; RTC > Row 1
;-----------------------------------------------------------------------------

mRtcGetNowHandler:
    call closeInputAndRecallNone
    bcall(_RtcGetNow)
    jp pushToX

mRtcGetDateHandler:
    call closeInputAndRecallNone
    bcall(_RtcGetDate)
    jp pushToX

mRtcGetTimeHandler:
    call closeInputAndRecallNone
    bcall(_RtcGetTime)
    jp pushToX

mRtcGetOffsetDateTimeHandler:
    call closeInputAndRecallNone
    bcall(_RtcGetOffsetDateTime)
    jp pushToX


;-----------------------------------------------------------------------------
; RTC > Row 2
;-----------------------------------------------------------------------------

mSetTimeZoneHandler:
    call closeInputAndRecallRpnOffsetX ; A=rpnObjectType; OP1=X
    bcall(_SetTimeZone)
    ld a, errorCodeTzStored
    ld (handlerCode), a
    ret

mGetTimeZoneHandler:
    call closeInputAndRecallNone
    bcall(_GetTimeZone)
    jp pushToX

mRtcSetTimeZoneHandler:
    call closeInputAndRecallRpnOffsetX
    bcall(_RtcSetTimeZone)
    ld a, errorCodeTzStored
    ld (handlerCode), a
    ret

mRtcGetTimeZoneHandler:
    call closeInputAndRecallNone
    bcall(_RtcGetTimeZone)
    jp pushToX

mRtcSetClockHandler:
    call closeInputAndRecallRpnOffsetDateTimeX ; A=rpnObjectType; OP1=X
    bcall(_RtcSetClock)
    ret

;-----------------------------------------------------------------------------
; Other DATE functions
;-----------------------------------------------------------------------------

; DATE > JUL > Row 1
;mDateTimeToJulianHandler:
;mJulianToDateTimeHandler:
;mDateTimeToModifiedJulianHandler:
;mModifiedJulianToDateTimeHandler:

; DATE > ISO > Row 1
;mDateToIsoWeekDayHandler:
;mIsoWeekDayToDateHandler:
