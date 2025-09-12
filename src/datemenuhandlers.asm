;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; DATE menu handlers.
;
; Every handler is given the following input parameters:
;   - HL:u16=menuId
;   - CF:bool
;       - 0 indicates 'onEnter' event into group
;       - 1 indicates 'onExit' event from group
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; DATE > D (Date) > Row 1
;-----------------------------------------------------------------------------

mDateErr:
    bcall(_ErrDataType)

mDateCreateHandler:
    ret

mDateToEpochDaysHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1=X=RpnDateLike{}
    cp rpnObjectTypeDate ; ZF=1 if RpnDateTime
    jr nz, mDateErr
    bcall(_RpnDateToEpochDays) ; OP1=epochDays
    jp replaceX

mEpochDaysToDateHandler:
    call closeInputAndRecallX ; OP1=X=epochDays
    bcall(_EpochDaysToRpnDate) ; OP1=Date(epochDays)
    jp replaceX

mDateToEpochSecondsHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1=X=RpnDateLike{}
    cp rpnObjectTypeDate ; ZF=1 if RpnDateTime
    jr nz, mDateErr
    bcall(_RpnDateToEpochSeconds) ; OP1=epochSeconds
    jp replaceX

mEpochSecondsToDateHandler:
    call closeInputAndRecallX ; OP1=X=epochSeconds
    bcall(_EpochSecondsToRpnDate) ; OP1=Date(epochSeconds)
    jp replaceX

;-----------------------------------------------------------------------------
; DATE > D (Date) > Row 2
;-----------------------------------------------------------------------------

mDateToDayOfWeekHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1=X=RpnDateLike{}
    cp rpnObjectTypeDate ; ZF=1 if RpnDateTime
    jr nz, mDateErr
    bcall(_RpnDateToDayOfWeek) ; OP1:RpnDayOfWeek
    jp replaceX

;-----------------------------------------------------------------------------
; DATE > T (Time) > Row 1
;-----------------------------------------------------------------------------

mTimeErr:
    bcall(_ErrDataType)

mTimeCreateHandler:
    ret

mTimeToSecondsHandler:
    call closeInputAndRecallRpnDateRelatedX ; OP1==dateRelatedObject; A=type
    cp rpnObjectTypeTime ; ZF=1 if RpnDateTime
    jr nz, mTimeErr
    bcall(_RpnTimeToSeconds) ; OP1=epochSeconds
    jp replaceX

mSecondsToTimeHandler:
    call closeInputAndRecallX ; OP1=X=seconds
    bcall(_SecondsToRpnTime) ; OP1=Time(seconds)
    jp replaceX

;-----------------------------------------------------------------------------
; DATE > DT (DateTime) > Row 1
;-----------------------------------------------------------------------------

mDateTimeErr:
    bcall(_ErrDataType)

mDateTimeCreateHandler:
    ret

mDateTimeToEpochDaysHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1==dateLikeObject; A=type
    cp rpnObjectTypeDateTime ; ZF=1 if RpnDateTime
    jr nz, mDateTimeErr
    bcall(_RpnDateTimeToEpochDays) ; OP1=epochDays
    jp replaceX

mEpochDaysToDateTimeHandler:
    call closeInputAndRecallX ; OP1=X=epochDays
    bcall(_EpochDaysToRpnDateTime) ; OP1=DateTime(epochDays)
    jp replaceX

mDateTimeToEpochSecondsHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1==dateLikeObject; A=type
    cp rpnObjectTypeDateTime ; ZF=1 if RpnDateTime
    jr nz, mDateTimeErr
    bcall(_RpnDateTimeToEpochSeconds) ; OP1=epochSeconds
    jp replaceX

mEpochSecondsToDateTimeHandler:
    call closeInputAndRecallX ; OP1=X=epochSeconds
    bcall(_EpochSecondsToRpnDateTime) ; OP1=DateTime(epochSeconds)
    jp replaceX

;-----------------------------------------------------------------------------
; DATE > DT (DateTime) > Row 2
;-----------------------------------------------------------------------------

mDateTimeExtractDateHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1==dateLikeObject; A=type
    cp rpnObjectTypeDateTime ; ZF=1 if RpnDateTime
    jr nz, mDateTimeErr
    bcall(_RpnDateTimeExtractDate) ; OP1=RpnDate
    jp replaceX

mDateTimeExtractTimeHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1==dateLikeObject; A=type
    cp rpnObjectTypeDateTime ; ZF=1 if RpnDateTime
    jr nz, mDateTimeErr
    bcall(_RpnDateTimeExtractTime) ; OP1=RpnTime
    jp replaceX

;-----------------------------------------------------------------------------
; DATE > TZ (Offset) > Row 1
;-----------------------------------------------------------------------------

mOffsetErr:
    bcall(_ErrDataType)

mOffsetCreateHandler:
    ret

mOffsetToSecondsHandler:
    call closeInputAndRecallRpnDateRelatedX ; OP1==dateRelatedObject; A=type
    cp rpnObjectTypeOffset ; ZF=1 if RpnDateTime
    jr nz, mOffsetErr
    bcall(_RpnOffsetToSeconds) ; OP1=seconds
    jp replaceX

mOffsetToHoursHandler:
    call closeInputAndRecallRpnOffsetX ; A=rpnObjectType; OP1=X
    bcall(_RpnOffsetToHours) ; OP1=hours
    jp replaceX

mHoursToOffsetHandler:
    call closeInputAndRecallX ; OP1=X=hours
    bcall(_HoursToRpnOffset) ; OP1=RpnOffset(hours)
    jp replaceX

;-----------------------------------------------------------------------------
; DATE > DZ (OffsetDateTime) > Row 1
;-----------------------------------------------------------------------------

mOffsetDateTimeErr:
    bcall(_ErrDataType)

mOffsetDateTimeCreateHandler:
    ret

mOffsetDateTimeToEpochSecondsHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1==dateLikeObject; A=type
    cp rpnObjectTypeOffsetDateTime ; ZF=1 if RpnOffsetDateTime
    jr nz, mOffsetDateTimeErr
    bcall(_RpnOffsetDateTimeToEpochSeconds) ; OP1=epochSeconds
    jp replaceX

mEpochSecondsToAppDateTimeHandler:
    call closeInputAndRecallX ; OP1=X=epochSeconds
    ld bc, appTimeZone
    bcall(_EpochSecondsToRpnOffsetDateTime) ; OP1=OffsetDateTime(epochSeconds)
    jp replaceX

mEpochSecondsToUTCDateTimeHandler:
    call closeInputAndRecallX ; OP1=X=epochSeconds
    bcall(_EpochSecondsToRpnOffsetDateTimeUTC) ; OP1=UTCDateTime(epochSeconds)
    jp replaceX

;-----------------------------------------------------------------------------
; DATE > DZ (OffsetDateTime) > Row 2
;-----------------------------------------------------------------------------

mOffsetDateTimeExtractDateHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1==dateLikeObject; A=type
    cp rpnObjectTypeOffsetDateTime ; ZF=1 if RpnOffsetDateTime
    jr nz, mOffsetDateTimeErr
    bcall(_RpnOffsetDateTimeExtractDate) ; OP1=RpnDate
    jp replaceX

mOffsetDateTimeExtractTimeHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1==dateLikeObject; A=type
    cp rpnObjectTypeOffsetDateTime ; ZF=1 if RpnOffsetDateTime
    jr nz, mOffsetDateTimeErr
    bcall(_RpnOffsetDateTimeExtractTime) ; OP1=RpnDate
    jp replaceX

mOffsetDateTimeExtractDateTimeHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1==dateLikeObject; A=type
    cp rpnObjectTypeOffsetDateTime ; ZF=1 if RpnOffsetDateTime
    jr nz, mOffsetDateTimeErr
    bcall(_RpnOffsetDateTimeExtractDateTime) ; OP1=RpnDate
    jp replaceX

mOffsetDateTimeExtractOffsetHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1==dateLikeObject; A=type
    cp rpnObjectTypeOffsetDateTime ; ZF=1 if RpnOffsetDateTime
    jr nz, mOffsetDateTimeErr
    bcall(_RpnOffsetDateTimeExtractOffset) ; OP1=RpnOffset
    jp replaceX

;-----------------------------------------------------------------------------
; DATE > DR (Duration) > Row 1
;-----------------------------------------------------------------------------

mDurationErr:
    bcall(_ErrDataType)

mDurationCreateHandler:
    ret

mDurationToSecondsHandler:
    call closeInputAndRecallRpnDateRelatedX ; OP1==dateRelatedObject; A=type
    cp rpnObjectTypeDuration
    jr nz, mDurationErr
    bcall(_RpnDurationToSeconds) ; OP1=seconds
    jp replaceX

mSecondsToDurationHandler:
    call closeInputAndRecallX ; OP1=X=seconds
mSecondsToDurationHandlerAltEntry:
    bcall(_SecondsToRpnDuration) ; OP1=Duration(seconds)
    jp replaceX

mMinutesToDurationHandler:
    call closeInputAndRecallX ; OP1=X=seconds
mMinutesToDurationHandlerAltEntry:
    bcall(_OP2Set60) ; OP2=60
    bcall(_FPMult)
    jr mSecondsToDurationHandlerAltEntry

mHoursToDurationHandler:
    call closeInputAndRecallX ; OP1=X=seconds
mHoursToDurationHandlerAltEntry:
    bcall(_OP2Set60) ; OP2=60
    bcall(_FPMult)
    jr mMinutesToDurationHandlerAltEntry

mDaysToDurationHandler:
    call closeInputAndRecallX ; OP1=X=seconds
    call op2Set24 ; OP2=24
    bcall(_FPMult)
    jr mHoursToDurationHandlerAltEntry

;-----------------------------------------------------------------------------
; DATE > DW (DayOfWeek) > Row 1
;-----------------------------------------------------------------------------

mDayOfWeekErr:
    bcall(_ErrDataType)

mDayOfWeekCreateHandler:
    ret

mDayOfWeekToIsoNumberHandler:
    call closeInputAndRecallRpnDateRelatedX ; OP1=rpnDayOfWeek; A=rpnObjectType
    cp rpnObjectTypeDayOfWeek
    jr nz, mDayOfWeekErr
    bcall(_RpnDayOfWeekToIsoNumber) ; OP1=iso dayofweek
    jp replaceX

mIsoNumberToDayOfWeekHandler:
    call closeInputAndRecallX ; OP1=X=isoNumber
    bcall(_IsoNumberToRpnDayOfWeek) ; OP1=rpnDayOfWeek
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
; DATE > DOPS > Row 1
;-----------------------------------------------------------------------------

; Handles Real, Date, DateTime, and OffsetDateTime.
mIsDateLeapHandler:
mIsDateTimeLeapHandler:
mIsOffsetDateTimeLeapHandler:
mGenericDateIsLeapHandler:
    call closeInputAndRecallUniversalX ; OP1=X=Real|Date-like
mGenericDateIsYearLeapHandlerAltEntry:
    cp rpnObjectTypeReal
    jr z, isRealLeap
    cp rpnObjectTypeDate
    jr z, isObjectLeap
    cp rpnObjectTypeDateTime
    jr z, isObjectLeap
    cp rpnObjectTypeOffsetDateTime
    jr z, isObjectLeap
    bcall(_ErrDataType)
isRealLeap:
    bcall(_IsYearLeap)
    jp replaceX
isObjectLeap:
    bcall(_IsDateLeap)
    jp replaceX

; Handles DateTime and OffsetDateTime.
mDateShrinkToNothingHandler:
mDateTimeShrinkToDateHandler:
mOffsetDateTimeShrinkToDateTimeHandler:
mGenericDateShrinkHandler:
    call closeInputAndRecallRpnDateLikeX ; A=rpnObjectType
mGenericDateShrinkHandlerAltEntry:
    cp rpnObjectTypeDateTime ; ZF=1 if RpnDateTime
    jr z, dateShrinkRpnDateTime
    cp rpnObjectTypeOffsetDateTime ; ZF=1 if RpnOffsetDateTime
    jr z, dateShrinkRpnOffsetDateTime
    bcall(_ErrDataType)
dateShrinkRpnDateTime:
    bcall(_TruncateRpnDateTime)
    jp replaceX
dateShrinkRpnOffsetDateTime:
    bcall(_TruncateRpnOffsetDateTime)
    jp replaceX

; Description: Convert Date->DateTime, or DateTime->OffsetDateTime.
; Input:
;   - OP1/OP2:(RpnDate|RpnDateTime)=X
; Output:
;   - OP1/OP2:(RpnDateTime|RpnOffsetDateTime)=dateTime|offsetDateTime
mDateExtendToDateTimeHandler:
mDateTimeExtendToOffsetDateTimeHandler:
mOffsetDateTimeExtendToNothingHandler:
mGenericDateExtendHandler:
    call closeInputAndRecallRpnDateLikeX ; A=rpnObjectType
mGenericDateExtendHandlerAltEntry:
    cp rpnObjectTypeDate ; ZF=1 if RpnDate
    jr z, dateExtendRpnDate
    cp rpnObjectTypeDateTime ; ZF=1 if RpnDateTime
    jr z, dateExtendRpnDateTime
    bcall(_ErrDataType)
dateExtendRpnDate:
    bcall(_ExtendRpnDateToDateTime)
    jp replaceX
dateExtendRpnDateTime:
    bcall(_ExtendRpnDateTimeToOffsetDateTime)
    jp replaceX

; Description: Split/cut an RpnDateTime into a (RpnDate, RpnTime) pair, or an
; RpnOffsetDateTime into a (RpnOffset, RpnDateTime) pair.
; Input:
;   - OP1/OP2:(RpnOffsetDateTime|RpnDateTime)=X
; Output:
;   - OP1/OP2:(RpnOffset|RpnTime)=Split(X)[0]
;   - OP3/OP4:(RpnDateTime|RpnDate)=Split(X)[1]
mDateCutToNothingHandler:
mDateTimeCutToDateHandler:
mOffsetDateTimeCutToDateTimeHandler:
mGenericDateCutHandler:
    call closeInputAndRecallRpnDateLikeX ; A=rpnObjectType
mGenericDateCutHandlerAltEntry:
    cp rpnObjectTypeDateTime ; ZF=1 if RpnDateTime
    jr z, dateCutRpnDateTime
    cp rpnObjectTypeOffsetDateTime ; ZF=1 if RpnOffsetDateTime
    jr z, dateCutRpnOffsetDateTime
    bcall(_ErrDataType)
dateCutRpnDateTime:
    bcall(_SplitRpnDateTime) ; CP1=RpnTime; CP3=RpnDate
    jp replaceXWithCP1CP3
dateCutRpnOffsetDateTime:
    bcall(_SplitRpnOffsetDateTime) ; CP1=RpnOffset; CP3=RpnDateTime
    jp replaceXWithCP1CP3

; Description: Same as handleKeyLink (2ND LINK) but accepts only date-related
; objects. Complex and Real objects not allowed.
; Input:
;   - X:(RpnDate|RpnDateTime)
;   - Y:(RpnDate|RpnDateTime)
; Output:
;   - X:(RpnDateTime|RpnOffsetDateTime)
;   - Y:(RpnDateTime|RpnOffsetDateTime)
mDateLinkToDateTimeHandler:
mDateTimeLinkToOffsetDateTimeHandler:
mOffsetDateTimeLinkToNothingHandler:
mGenericDateLinkHandler:
    call closeInputAndRecallRpnDateRelatedX ; A=rpnObjectType
mGenericDateLinkHandlerAltEntry:
    cp rpnObjectTypeTime ; ZF=1 if RpnTime
    jp z, dateLinkTime
    cp rpnObjectTypeDate ; ZF=1 if RpnDate
    jp z, dateLinkDate
    cp rpnObjectTypeOffset ; ZF=1 if RpnOffset
    jp z, dateLinkOffset
    cp rpnObjectTypeDateTime ; ZF=1 if RpnDateTime
    jp z, dateLinkDateTime
dateLinkErrDataType:
    bcall(_ErrDataType)
dateLinkTime:
    call cp1ToCp3 ; CP3=X
    call rclY ; CP1=Y; A=rpnObjectType
    cp rpnObjectTypeDate ; ZF=1 if OP3=RpnDate
    jr nz, dateLinkErrDataType
    bcall(_MergeRpnDateWithRpnTime) ; OP1=rpnDateTime
    jp replaceXY
dateLinkDate:
    call cp1ToCp3 ; CP3=X
    call rclY ; CP1=Y; A=rpnObjectType
    cp rpnObjectTypeTime ; ZF=1 if OP3=RpnTime
    jr nz, dateLinkErrDataType
    bcall(_MergeRpnDateWithRpnTime) ; OP1=rpnDateTime
    jp replaceXY
dateLinkOffset:
    call cp1ToCp3 ; CP3=X
    call rclY ; CP1=Y; A=rpnObjectType
    cp rpnObjectTypeDateTime ; ZF=1 if OP3=RpnDateTime
    jr nz, dateLinkErrDataType
    bcall(_MergeRpnDateTimeWithRpnOffset) ; OP1=rpnOffsetDateOffset
    jp replaceXY
dateLinkDateTime:
    call cp1ToCp3 ; CP3=X
    call rclY ; CP1=Y; A=rpnObjectType
    cp rpnObjectTypeOffset ; ZF=1 if OP3=RpnOffset
    jr nz, dateLinkErrDataType
    bcall(_MergeRpnDateTimeWithRpnOffset) ; OP1=rpnOffsetDateTime
    jp replaceXY

;-----------------------------------------------------------------------------
; DATE > CLK > Row 1
;-----------------------------------------------------------------------------

mGetNowHandler:
    ld a, (isRtcAvailable)
    or a
    jr z, noClockErr
    ;
    call closeInputAndRecallNone
    bcall(_RtcGetNow)
    jp pushToX

mGetNowTimeHandler:
    ld a, (isRtcAvailable)
    or a
    jr z, noClockErr
    ;
    call closeInputAndRecallNone
    bcall(_RtcGetTime)
    jp pushToX

mGetNowDateHandler:
    ld a, (isRtcAvailable)
    or a
    jr z, noClockErr
    ;
    call closeInputAndRecallNone
    bcall(_RtcGetDate)
    jp pushToX

mGetNowAppDateTimeHandler:
    ld a, (isRtcAvailable)
    or a
    jr z, noClockErr
    ;
    call closeInputAndRecallNone
    bcall(_RtcGetAppDateTime)
    jp pushToX

mGetNowUTCDateTimeHandler:
    ld a, (isRtcAvailable)
    or a
    jr z, noClockErr
    ;
    call closeInputAndRecallNone
    bcall(_RtcGetUTCDateTime)
    jp pushToX

noClockErr:
    ld a, errorCodeNoClock
    ld (handlerCode), a
    ret

;-----------------------------------------------------------------------------
; DATE > CLK > Row 2
;-----------------------------------------------------------------------------

mSetTimeZoneHandler:
    call closeInputAndRecallRpnOffsetOrRealX ; A=rpnObjectType; OP1=X
    bcall(_SetAppTimeZone)
    ld a, errorCodeTzStored
    ld (handlerCode), a
    ret

mGetTimeZoneHandler:
    call closeInputAndRecallNone
    bcall(_GetAppTimeZone)
    jp pushToX

mSetClockTimeZoneHandler:
    ld a, (isRtcAvailable)
    or a
    jr z, noClockErr
    ;
    call closeInputAndRecallRpnOffsetOrRealX
    bcall(_RtcSetTimeZone)
    ld a, errorCodeTzStored
    ld (handlerCode), a
    ret

mGetClockTimeZoneHandler:
    ld a, (isRtcAvailable)
    or a
    jr z, noClockErr
    ;
    call closeInputAndRecallNone
    bcall(_RtcGetTimeZone)
    jp pushToX

mSetClockHandler:
    ld a, (isRtcAvailable)
    or a
    jr z, noClockErr
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
