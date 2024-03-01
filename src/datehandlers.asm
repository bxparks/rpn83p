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
    cp rpnObjectTypeDuration ; ZF=1 if RpnDuration
    jr z, mDateRelatedToSecondsHandlerDuration
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
    jr mDateRelatedToSecondsHandlerEnd
mDateRelatedToSecondsHandlerDuration:
    bcall(_RpnDurationToSeconds) ; OP1=seconds
    ; [[fallthrough]]
mDateRelatedToSecondsHandlerEnd:
    jp replaceX

mSecondsToDurationHandler:
    call closeInputAndRecallX ; OP1=X=seconds
    bcall(_SecondsToRpnDuration) ; OP1=Duration(seconds)
    jp replaceX

mSecondsToTimeHandler:
    call closeInputAndRecallX ; OP1=X=seconds
    bcall(_SecondsToRpnTime) ; OP1=Time(seconds)
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
; DATE > Row 3
;-----------------------------------------------------------------------------

mHoursToTimeZoneHandler:
    call closeInputAndRecallX ; OP1=X=hours
    bcall(_HoursToRpnOffset) ; OP1=RpnOffset(hours)
    jp replaceX

mTimeZoneToHoursHandler:
    call closeInputAndRecallRpnOffsetX ; A=rpnObjectType; OP1=X
    bcall(_RpnOffsetToHours) ; OP1=hours
    jp replaceX

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

mEpochY2kHandler:
    bcall(_SelectY2kEpochDate)
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mEpochY2kNameSelector:
    ld a, (epochType)
    cp epochTypeY2k
    jr z, mEpochY2kNameSelectorAlt
    or a ; CF=0
    ret
mEpochY2kNameSelectorAlt:
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
; DATE > Row 3 (RTC related)
;-----------------------------------------------------------------------------

mRtcGetNowHandler:
    ld a, (isTi83Plus)
    or a
    jr nz, mRtcNoClockErr
    ;
    call closeInputAndRecallNone
    bcall(_RtcGetNow)
    jp pushToX

mRtcNoClockErr:
    ld a, errorCodeNoClock
    ld (handlerCode), a
    ret

mRtcGetNowDzHandler:
    ld a, (isTi83Plus)
    or a
    jr nz, mRtcNoClockErr
    ;
    call closeInputAndRecallNone
    bcall(_RtcGetOffsetDateTime)
    jp pushToX

mRtcSetTimeZoneHandler:
    ld a, (isTi83Plus)
    or a
    jr nz, mRtcNoClockErr
    ;
    call closeInputAndRecallRpnOffsetX
    bcall(_RtcSetTimeZone)
    ld a, errorCodeTzStored
    ld (handlerCode), a
    ret

mRtcGetTimeZoneHandler:
    ld a, (isTi83Plus)
    or a
    jr nz, mRtcNoClockErr
    ;
    call closeInputAndRecallNone
    bcall(_RtcGetTimeZone)
    jp pushToX

mRtcSetClockHandler:
    ld a, (isTi83Plus)
    or a
    jr nz, mRtcNoClockErr
    ;
    call closeInputAndRecallRpnOffsetDateTimeX ; A=rpnObjectType; OP1=X
    bcall(_RtcSetClock)
    ld a, errorCodeClockSet
    ld (handlerCode), a
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
