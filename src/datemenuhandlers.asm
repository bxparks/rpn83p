;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; DATE menu handlers.
;
; Every handler is given the following input parameters:
;   - HL:u16=targetNodeId
;   - CF:bool
;       - 0 indicates 'onEnter' event into group
;       - 1 indicates 'onExit' event from group
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
    bcall(_RpnDateToDayOfWeek) ; OP1:RpnDayOfWeek
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
    ; Conversion from DateTime -> epochSeconds is disabled because the meaning
    ; of a DateTime is ambiguous. It could be a appDateTime (using the
    ; appTimeZone), or it could be the UTC dateTime (using UTC timezone). We
    ; force the user to always convert the DateTime to an OffsetDateTime with a
    ; timezone Offset.
    ; cp rpnObjectTypeDateTime ; ZF=1 if RpnDateTime
    ; jr z, mDateRelatedToSecondsHandlerDateTime
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
;mDateRelatedToSecondsHandlerDateTime:
;    bcall(_RpnDateTimeToEpochSeconds) ; OP1=epochSeconds
;    jr mDateRelatedToSecondsHandlerEnd
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

;-----------------------------------------------------------------------------
; DATE > Row 3 > EPCH > Row 1
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
; DATE > Row 3 > EPCH > Row 2
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
; DATE > Row 4 (conversions)
;-----------------------------------------------------------------------------

mDateShrinkHandler:
    call closeInputAndRecallRpnDateLikeX ; A=rpnObjectType
mDateShrinkHandlerAlt:
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
mDateExtendHandler:
    call closeInputAndRecallRpnDateLikeX ; A=rpnObjectType
mDateExtendHandlerAlt:
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
mDateCutHandler:
    call closeInputAndRecallRpnDateLikeX ; A=rpnObjectType
mDateCutHandlerAlt:
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
mDateLinkHandler:
    call closeInputAndRecallRpnDateRelatedX ; A=rpnObjectType
mDateLinkHandlerAlt:
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
; DATE > Row 5 (RTC related)
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
; DATE > Row 6 (Various Settings)
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
