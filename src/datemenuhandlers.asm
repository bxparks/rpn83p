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

; Description: Enter the string in HL into the input buffer at position
; `cursorInputPos`, updating various flags. If `cursorInputPos` is at the end
; of the `inputBuf`, then the string is appended. Similar to
; enterNumberCharacter() which enters a single character.
; Input:
;   - HL:(const char*)=string to be inserted
;   - rpnFlagsEditing=whether we are already in Edit mode
; Output:
;   - CF=0 if successful
;   - rpnFlagsEditing set
;   - dirtyFlagsInput set
;   - (cursorInputPos) updated if successful
; Destroys: all
enterString:
    ; TVM menus goes into input mode.
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ; If not in input editing mode: lift stack and go into edit mode
    bit rpnFlagsEditing, (iy + rpnFlags)
    jr nz, enterStringIfEditing
enterStringIfNonEditing: ; not in Editing mode
    ; Lift the stack, unless disabled.
    push hl ; preserve HL
    call liftStackIfEnabled
    pop hl
    ; Go into editing mode.
    bcall(_ClearInputBuf) ; preserves HL
    set rpnFlagsEditing, (iy + rpnFlags)
enterStringIfEditing: ; in Editing mode
    call insertStringInputBuf ; CF=0 if successful
    ret

;-----------------------------------------------------------------------------
; DATE > D (Date) > Row 1
;-----------------------------------------------------------------------------

mDateErr:
    bcall(_ErrDataType)

mDateCreateHandler:
    ld hl, strDatePrefix
    jp enterString

strDatePrefix:
    .db "D{", 0

mDateToEpochDaysHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1=X=RpnDateLike{}
    cp rpnObjectTypeDate ; ZF=1 if RpnDate
    jr z, mDateToEpochDaysHandlerDoDateTime
    cp rpnObjectTypeDate ; ZF=1 if RpnDateTime
    jr z, mDateToEpochDaysHandlerDoDateTime
    cp rpnObjectTypeOffsetDateTime ; ZF=1 if RpnOffsetDateTime
    jr z, mDateToEpochDaysHandlerDoOffsetDateTime
    jr mDateErr
mDateToEpochDaysHandlerDoOffsetDateTime:
    bcall(_ConvertRpnOffsetDateTimeToUtc)
    ; [[fallthrough]]
mDateToEpochDaysHandlerDoDateTime:
    ; [[fallthrough]]
mDateToEpochDaysHandlerDoDate:
    bcall(_RpnDateToEpochDays) ; OP1=epochDays
    jp replaceStackX

mEpochDaysToDateHandler:
    call closeInputAndRecallX ; OP1=X=epochDays
    bcall(_EpochDaysToRpnDate) ; OP1=Date(epochDays)
    jp replaceStackX

mDateToEpochSecondsHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1=X=RpnDateLike{}
    cp rpnObjectTypeDate ; ZF=1 if RpnDate
    jr z, mDateToEpochSecondsHandlerDoDate
    cp rpnObjectTypeDateTime ; ZF=1 if RpnDateTime
    jr z, mDateToEpochSecondsHandlerDoDateTime
    cp rpnObjectTypeOffsetDateTime ; ZF=1 if RpnOffsetDateTime
    jr z, mDateToEpochSecondsHandlerDoOffsetDateTime
    jr mDateErr
mDateToEpochSecondsHandlerDoOffsetDateTime:
    bcall(_RpnOffsetDateTimeToEpochSeconds) ; OP1=epochSeconds
    jp replaceStackX
mDateToEpochSecondsHandlerDoDateTime:
    bcall(_RpnDateTimeToEpochSeconds) ; OP1=epochSeconds
    jp replaceStackX
mDateToEpochSecondsHandlerDoDate:
    bcall(_RpnDateToEpochSeconds) ; OP1=epochSeconds
    jp replaceStackX

mEpochSecondsToDateHandler:
    call closeInputAndRecallX ; OP1=X=epochSeconds
    bcall(_EpochSecondsToRpnDate) ; OP1=Date(epochSeconds)
    jp replaceStackX

;-----------------------------------------------------------------------------
; DATE > D (Date) > Row 2
;-----------------------------------------------------------------------------

; Handle CVTZ (Convert TimeZone) function for D, DT, and DZ menus.
mDateConvertToTimeZoneHandler:
    call closeInputAndRecallUniversalXY ; CP1=Y; CP3=X
    bcall(_ConvertRpnDateLikeToTimeZone) ; OP1=DateLike*TZ
    jp replaceStackX

mDateToDayOfWeekHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1=X=RpnDateLike{}
    bcall(_RpnDateToDayOfWeek) ; OP1:RpnDayOfWeek
    jp replaceStackX

mDateExtractYearHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1=X=RpnDateLike{}
    bcall(_RpnDateExtractYear)
    jp replaceStackX

mDateExtractMonthHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1=X=RpnDateLike{}
    bcall(_RpnDateExtractMonth)
    jp replaceStackX

mDateExtractDayHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1=X=RpnDateLike{}
    bcall(_RpnDateExtractDay)
    jp replaceStackX

;-----------------------------------------------------------------------------
; DATE > D (Date) > Row 3
;-----------------------------------------------------------------------------

; See Generic Date handlers.

;-----------------------------------------------------------------------------
; DATE > T (Time) > Row 1
;-----------------------------------------------------------------------------

mTimeErr:
    bcall(_ErrDataType)

mTimeCreateHandler:
    ld hl, strTimePrefix
    jp enterString

strTimePrefix:
    .db "T{", 0

mTimeToSecondsHandler:
    call closeInputAndRecallRpnDateRelatedX ; OP1==dateRelatedObject; A=type
    cp rpnObjectTypeTime ; ZF=1 if RpnDateTime
    jr nz, mTimeErr
    bcall(_RpnTimeToSeconds) ; OP1=epochSeconds
    jp replaceStackX

mSecondsToTimeHandler:
    call closeInputAndRecallX ; OP1=X=seconds
    bcall(_SecondsToRpnTime) ; OP1=Time(seconds)
    jp replaceStackX

;-----------------------------------------------------------------------------
; DATE > T (Time) > Row 2
;-----------------------------------------------------------------------------

mTimeExtractHourHandler:
    call closeInputAndRecallRpnDateRelatedX ; OP1=X=RpnDateRelated{}
    cp rpnObjectTypeTime
    jr z, mTimeExtractHourHandlerDoTime
    cp rpnObjectTypeDateTime
    jr z, mTimeExtractHourHandlerDoDateTime
    cp rpnObjectTypeOffsetDateTime
    jr z, mTimeExtractHourHandlerDoOffsetDateTime
    jr mTimeErr
mTimeExtractHourHandlerDoOffsetDateTime:
    bcall(_RpnOffsetDateTimeExtractDateTime) ; OP1=datetime
    ; [[fallthrough]]
mTimeExtractHourHandlerDoDateTime:
    bcall(_RpnDateTimeExtractTime) ; OP1=time
    ; [[fallthrough]]
mTimeExtractHourHandlerDoTime:
    bcall(_RpnTimeExtractHour) ; OP1=time.hour()
    jp replaceStackX

mTimeExtractMinuteHandler:
    call closeInputAndRecallRpnDateRelatedX ; OP1=X=RpnDateRelated{}
    cp rpnObjectTypeTime
    jr z, mTimeExtractMinuteHandlerDoTime
    cp rpnObjectTypeDateTime
    jr z, mTimeExtractMinuteHandlerDoDateTime
    cp rpnObjectTypeOffsetDateTime
    jr z, mTimeExtractMinuteHandlerDoOffsetDateTime
    jr mTimeErr
mTimeExtractMinuteHandlerDoOffsetDateTime:
    bcall(_RpnOffsetDateTimeExtractDateTime) ; OP1=datetime
    ; [[fallthrough]]
mTimeExtractMinuteHandlerDoDateTime:
    bcall(_RpnDateTimeExtractTime) ; OP1=time
    ; [[fallthrough]]
mTimeExtractMinuteHandlerDoTime:
    bcall(_RpnTimeExtractMinute) ; OP1=time.minute()
    jp replaceStackX

mTimeExtractSecondHandler:
    call closeInputAndRecallRpnDateRelatedX ; OP1=X=RpnDateRelated{}
    cp rpnObjectTypeTime
    jr z, mTimeExtractSecondHandlerDoTime
    cp rpnObjectTypeDateTime
    jr z, mTimeExtractSecondHandlerDoDateTime
    cp rpnObjectTypeOffsetDateTime
    jr z, mTimeExtractSecondHandlerDoOffsetDateTime
    jr mTimeErr
mTimeExtractSecondHandlerDoOffsetDateTime:
    bcall(_RpnOffsetDateTimeExtractDateTime) ; OP1=datetime
    ; [[fallthrough]]
mTimeExtractSecondHandlerDoDateTime:
    bcall(_RpnDateTimeExtractTime) ; OP1=time
    ; [[fallthrough]]
mTimeExtractSecondHandlerDoTime:
    bcall(_RpnTimeExtractSecond) ; OP1=time.minute()
    jp replaceStackX

;-----------------------------------------------------------------------------
; DATE > DT (DateTime) > Row 1
;-----------------------------------------------------------------------------

mDateTimeErr:
    bcall(_ErrDataType)

mDateTimeCreateHandler:
    ld hl, strDateTimePrefix
    jp enterString

strDateTimePrefix:
    .db "DT{", 0

mDateTimeToEpochDaysHandler:
    jp mDateToEpochDaysHandler

mEpochDaysToDateTimeHandler:
    call closeInputAndRecallX ; OP1=X=epochDays
    bcall(_EpochDaysToRpnDateTime) ; OP1=DateTime(epochDays)
    jp replaceStackX

mDateTimeToEpochSecondsHandler:
    jp mDateToEpochSecondsHandler

mEpochSecondsToDateTimeHandler:
    call closeInputAndRecallX ; OP1=X=epochSeconds
    bcall(_EpochSecondsToRpnDateTime) ; OP1=DateTime(epochSeconds)
    jp replaceStackX

;-----------------------------------------------------------------------------
; DATE > DT (DateTime) > Row 2
;-----------------------------------------------------------------------------

mDateTimeConvertToTimeZoneHandler:
    jp mDateConvertToTimeZoneHandler

mDateTimeToDayOfWeekHandler:
    jp mDateToDayOfWeekHandler

mDateTimeExtractDateHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1==dateLikeObject; A=type
    cp rpnObjectTypeDateTime ; ZF=1 if RpnDateTime
    jr nz, mDateTimeErr
    bcall(_RpnDateTimeExtractDate) ; OP1=RpnDate
    jp replaceStackX

mDateTimeExtractTimeHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1==dateLikeObject; A=type
    cp rpnObjectTypeDateTime ; ZF=1 if RpnDateTime
    jr nz, mDateTimeErr
    bcall(_RpnDateTimeExtractTime) ; OP1=RpnTime
    jp replaceStackX

;-----------------------------------------------------------------------------
; DATE > TZ (Offset) > Row 1
;-----------------------------------------------------------------------------

mOffsetErr:
    bcall(_ErrDataType)

mOffsetCreateHandler:
    ld hl, strOffsetPrefix
    jp enterString

strOffsetPrefix:
    .db "TZ{", 0

mOffsetToSecondsHandler:
    call closeInputAndRecallRpnDateRelatedX ; OP1==dateRelatedObject; A=type
    cp rpnObjectTypeOffset ; ZF=1 if RpnDateTime
    jr nz, mOffsetErr
    bcall(_RpnOffsetToSeconds) ; OP1=seconds
    jp replaceStackX

mOffsetToHoursHandler:
    call closeInputAndRecallRpnOffsetX ; A=rpnObjectType; OP1=X
    bcall(_RpnOffsetToHours) ; OP1=hours
    jp replaceStackX

mHoursToOffsetHandler:
    call closeInputAndRecallX ; OP1=X=hours
    bcall(_HoursToRpnOffset) ; OP1=RpnOffset(hours)
    jp replaceStackX

mOffsetExtractHourHandler:
    call closeInputAndRecallRpnDateRelatedX ; OP1=X=RpnDateRelated{}
    cp rpnObjectTypeOffset
    jr z, mOffsetExtractHourHandlerDoOffset
    cp rpnObjectTypeOffsetDateTime
    jr z, mOffsetExtractHourHandlerDoOffsetDateTime
    jr mOffsetErr
mOffsetExtractHourHandlerDoOffsetDateTime:
    bcall(_RpnOffsetDateTimeExtractOffset) ; OP1=offset
mOffsetExtractHourHandlerDoOffset:
    bcall(_RpnOffsetExtractHour) ; OP1=hour
    jp replaceStackX

mOffsetExtractMinuteHandler:
    call closeInputAndRecallRpnDateRelatedX ; OP1=X=RpnDateRelated{}
    cp rpnObjectTypeOffset
    jr z, mOffsetExtractMinuteHandlerDoOffset
    cp rpnObjectTypeOffsetDateTime
    jr z, mOffsetExtractMinuteHandlerDoOffsetDateTime
    jr mOffsetErr
mOffsetExtractMinuteHandlerDoOffsetDateTime:
    bcall(_RpnOffsetDateTimeExtractOffset) ; OP1=offset
mOffsetExtractMinuteHandlerDoOffset:
    bcall(_RpnOffsetExtractMinute) ; OP1=offset.time
    jp replaceStackX

;-----------------------------------------------------------------------------
; DATE > DZ (OffsetDateTime) > Row 1
;-----------------------------------------------------------------------------

mOffsetDateTimeCreateHandler:
    ld hl, strOffsetDateTimePrefix
    jp enterString

strOffsetDateTimePrefix:
    .db "DZ{", 0

mOffsetDateTimeToEpochDaysHandler:
    jp mDateToEpochDaysHandler

mEpochDaysToOffsetDateTimeHandler:
    call closeInputAndRecallX ; OP1=X=epochDays
    bcall(_EpochDaysToRpnDateTime) ; OP1=DateTime(epochDays)
    jp replaceStackX

mOffsetDateTimeToEpochSecondsHandler:
    jp mDateToEpochSecondsHandler

mEpochSecondsToOffsetDateTimeUTCHandler:
    call closeInputAndRecallX ; OP1=X=epochSeconds
    bcall(_EpochSecondsToRpnOffsetDateTimeUTC) ; OP1=UTCDateTime(epochSeconds)
    jp replaceStackX

mOffsetDateTimeErr:
    bcall(_ErrDataType)

;-----------------------------------------------------------------------------
; DATE > DZ (OffsetDateTime) > Row 2
;-----------------------------------------------------------------------------

mEpochSecondsToOffsetDateTimeAppHandler:
    call closeInputAndRecallX ; OP1=X=epochSeconds
    ld bc, appTimeZone
    bcall(_EpochSecondsToRpnOffsetDateTime) ; OP1=OffsetDateTime(epochSeconds)
    jp replaceStackX

mOffsetDateTimeConvertToTimeZoneHandler:
    jp mDateConvertToTimeZoneHandler

;-----------------------------------------------------------------------------
; DATE > DZ (OffsetDateTime) > Row 3
;-----------------------------------------------------------------------------

mOffsetDateTimeToDayOfWeekHandler:
    jp mDateToDayOfWeekHandler

mOffsetDateTimeExtractDateHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1==dateLikeObject; A=type
    cp rpnObjectTypeOffsetDateTime ; ZF=1 if RpnOffsetDateTime
    jr nz, mOffsetDateTimeErr
    bcall(_RpnOffsetDateTimeExtractDate) ; OP1=RpnDate
    jp replaceStackX

mOffsetDateTimeExtractTimeHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1==dateLikeObject; A=type
    cp rpnObjectTypeOffsetDateTime ; ZF=1 if RpnOffsetDateTime
    jr nz, mOffsetDateTimeErr
    bcall(_RpnOffsetDateTimeExtractTime) ; OP1=RpnDate
    jp replaceStackX

mOffsetDateTimeExtractDateTimeHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1==dateLikeObject; A=type
    cp rpnObjectTypeOffsetDateTime ; ZF=1 if RpnOffsetDateTime
    jr nz, mOffsetDateTimeErr
    bcall(_RpnOffsetDateTimeExtractDateTime) ; OP1=RpnDate
    jp replaceStackX

mOffsetDateTimeExtractOffsetHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1==dateLikeObject; A=type
    cp rpnObjectTypeOffsetDateTime ; ZF=1 if RpnOffsetDateTime
    jr nz, mOffsetDateTimeErr
    bcall(_RpnOffsetDateTimeExtractOffset) ; OP1=RpnOffset
    jp replaceStackX

;-----------------------------------------------------------------------------
; DATE > DZ (OffsetDateTime) > Row 4
;-----------------------------------------------------------------------------

; See Generic Date handlers.

;-----------------------------------------------------------------------------
; DATE > DR (Duration) > Row 1
;-----------------------------------------------------------------------------

mDurationErr:
    bcall(_ErrDataType)

mDurationCreateHandler:
    ld hl, strDurationPrefix
    jp enterString

strDurationPrefix:
    .db "DR{", 0

mSecondsToDurationHandler:
    call closeInputAndRecallX ; OP1=X=seconds
mSecondsToDurationHandlerAltEntry:
    bcall(_SecondsToRpnDuration) ; OP1=Duration(seconds)
    jp replaceStackX

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
; DATE > DR (Duration) > Row 2
;-----------------------------------------------------------------------------

mDurationToSecondsHandler:
    call closeInputAndRecallRpnDateRelatedX ; OP1==dateRelatedObject; A=type
    cp rpnObjectTypeDuration
    jr nz, mDurationErr
    bcall(_RpnDurationToSeconds) ; OP1=seconds
    jp replaceStackX

mDurationExtractDayHandler:
    call closeInputAndRecallRpnDateRelatedX ; OP1==dateRelatedObject; A=type
    cp rpnObjectTypeDuration
    jr nz, mDurationErr
    bcall(_RpnDurationExtractDay) ; OP1=day
    jp replaceStackX

mDurationExtractHourHandler:
    call closeInputAndRecallRpnDateRelatedX ; OP1==dateRelatedObject; A=type
    cp rpnObjectTypeDuration
    jr nz, mDurationErr
    bcall(_RpnDurationExtractHour) ; OP1=hour
    jp replaceStackX

mDurationExtractMinuteHandler:
    call closeInputAndRecallRpnDateRelatedX ; OP1==dateRelatedObject; A=type
    cp rpnObjectTypeDuration
    jr nz, mDurationErr
    bcall(_RpnDurationExtractMinute) ; OP1=minute
    jp replaceStackX

mDurationExtractSecondHandler:
    call closeInputAndRecallRpnDateRelatedX ; OP1==dateRelatedObject; A=type
    cp rpnObjectTypeDuration
    jr nz, mDurationErr
    bcall(_RpnDurationExtractSecond) ; OP1=second
    jp replaceStackX

;-----------------------------------------------------------------------------
; DATE > DW (DayOfWeek) > Row 1
;-----------------------------------------------------------------------------

mDayOfWeekErr:
    bcall(_ErrDataType)

mDayOfWeekCreateHandler:
    ld hl, strDayOfWeekPrefix
    jp enterString

strDayOfWeekPrefix:
    .db "DW{", 0

mDayOfWeekToIsoNumberHandler:
    call closeInputAndRecallRpnDateRelatedX ; OP1=rpnDayOfWeek; A=rpnObjectType
    cp rpnObjectTypeDayOfWeek
    jr nz, mDayOfWeekErr
    bcall(_RpnDayOfWeekToIsoNumber) ; OP1=iso dayofweek
    jp replaceStackX

mIsoNumberToDayOfWeekHandler:
    call closeInputAndRecallX ; OP1=X=isoNumber
    bcall(_IsoNumberToRpnDayOfWeek) ; OP1=rpnDayOfWeek
    jp replaceStackX

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
    jp pushToStackX

;-----------------------------------------------------------------------------
; DATE > Generic Date handlers
;-----------------------------------------------------------------------------

; Handle LEAP function for Real, Date, DateTime, and OffsetDateTime.
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
    jp replaceStackX
isObjectLeap:
    bcall(_IsDateLeap)
    jp replaceStackX

;-----------------------------------------------------------------------------

; Handle DSHK for DateTime and OffsetDateTime.
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
    jp replaceStackX
dateShrinkRpnOffsetDateTime:
    bcall(_TruncateRpnOffsetDateTime)
    jp replaceStackX

;-----------------------------------------------------------------------------

; Handle DEXD for Date and DateTime.
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
    jp replaceStackX
dateExtendRpnDateTime:
    bcall(_ExtendRpnDateTimeToOffsetDateTime)
    jp replaceStackX

;-----------------------------------------------------------------------------

; Handle DCUT for DateTime and OffsetDateTime.
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
    jp replaceStackXWithCP1CP3
dateCutRpnOffsetDateTime:
    bcall(_SplitRpnOffsetDateTime) ; CP1=RpnOffset; CP3=RpnDateTime
    jp replaceStackXWithCP1CP3

;-----------------------------------------------------------------------------

; Handle DLNK for Date, DateTime. Same as handleKeyLink (2ND LINK) but accepts
; only date-related objects. Complex and Real objects not allowed.
;
; TODO: I think we could move this into a file on Flash Page 2 (e.g.
; dateops2.asm) to save space on Flash Page 1.
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
    call rclStackY ; CP1=Y; A=rpnObjectType
    cp rpnObjectTypeDate ; ZF=1 if OP3=RpnDate
    jr nz, dateLinkErrDataType
    bcall(_MergeRpnDateWithRpnTime) ; OP1=rpnDateTime
    jp replaceStackXY
dateLinkDate:
    call cp1ToCp3 ; CP3=X
    call rclStackY ; CP1=Y; A=rpnObjectType
    cp rpnObjectTypeTime ; ZF=1 if OP3=RpnTime
    jr nz, dateLinkErrDataType
    bcall(_MergeRpnDateWithRpnTime) ; OP1=rpnDateTime
    jp replaceStackXY
dateLinkOffset:
    call cp1ToCp3 ; CP3=X
    call rclStackY ; CP1=Y; A=rpnObjectType
    cp rpnObjectTypeDateTime ; ZF=1 if OP3=RpnDateTime
    jr nz, dateLinkErrDataType
    bcall(_MergeRpnDateTimeWithRpnOffset) ; OP1=rpnOffsetDateOffset
    jp replaceStackXY
dateLinkDateTime:
    call cp1ToCp3 ; CP3=X
    call rclStackY ; CP1=Y; A=rpnObjectType
    cp rpnObjectTypeOffset ; ZF=1 if OP3=RpnOffset
    jr nz, dateLinkErrDataType
    bcall(_MergeRpnDateTimeWithRpnOffset) ; OP1=rpnOffsetDateTime
    jp replaceStackXY

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
    jp pushToStackX

mGetNowTimeHandler:
    ld a, (isRtcAvailable)
    or a
    jr z, noClockErr
    ;
    call closeInputAndRecallNone
    bcall(_RtcGetTime)
    jp pushToStackX

mGetNowDateHandler:
    ld a, (isRtcAvailable)
    or a
    jr z, noClockErr
    ;
    call closeInputAndRecallNone
    bcall(_RtcGetDate)
    jp pushToStackX

mGetNowOffsetDateTimeHandler:
    ld a, (isRtcAvailable)
    or a
    jr z, noClockErr
    ;
    call closeInputAndRecallNone
    bcall(_RtcGetOffsetDateTime)
    jp pushToStackX

mGetNowOffsetDateTimeUtcHandler:
    ld a, (isRtcAvailable)
    or a
    jr z, noClockErr
    ;
    call closeInputAndRecallNone
    bcall(_RtcGetOffsetDateTimeForUtc)
    jp pushToStackX

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
    jp pushToStackX

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
    jp pushToStackX

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
