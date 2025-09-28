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
    bcall(_LiftStackIfEnabled)
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
    bcall(_ReplaceStackX)
    ret

mEpochDaysToDateHandler:
    call closeInputAndRecallX ; OP1=X=epochDays
    bcall(_EpochDaysToRpnDate) ; OP1=Date(epochDays)
    bcall(_ReplaceStackX)
    ret

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
    bcall(_ReplaceStackX)
    ret
mDateToEpochSecondsHandlerDoDateTime:
    bcall(_RpnDateTimeToEpochSeconds) ; OP1=epochSeconds
    bcall(_ReplaceStackX)
    ret
mDateToEpochSecondsHandlerDoDate:
    bcall(_RpnDateToEpochSeconds) ; OP1=epochSeconds
    bcall(_ReplaceStackX)
    ret

mEpochSecondsToDateHandler:
    call closeInputAndRecallX ; OP1=X=epochSeconds
    bcall(_EpochSecondsToRpnDate) ; OP1=Date(epochSeconds)
    bcall(_ReplaceStackX)
    ret

;-----------------------------------------------------------------------------
; DATE > D (Date) > Row 2
;-----------------------------------------------------------------------------

; Handle CVTZ (Convert TimeZone) function for D, DT, and DZ menus.
mDateConvertToTimeZoneHandler:
    call closeInputAndRecallUniversalXY ; CP1=Y; CP3=X
    bcall(_ConvertRpnDateLikeToTimeZone) ; OP1=DateLike*TZ
    bcall(_ReplaceStackX)
    ret

mDateToDayOfWeekHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1=X=RpnDateLike{}
    bcall(_RpnDateToDayOfWeek) ; OP1:RpnDayOfWeek
    bcall(_ReplaceStackX)
    ret

mDateExtractYearHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1=X=RpnDateLike{}
    bcall(_RpnDateExtractYear)
    bcall(_ReplaceStackX)
    ret

mDateExtractMonthHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1=X=RpnDateLike{}
    bcall(_RpnDateExtractMonth)
    bcall(_ReplaceStackX)
    ret

mDateExtractDayHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1=X=RpnDateLike{}
    bcall(_RpnDateExtractDay)
    bcall(_ReplaceStackX)
    ret

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
    bcall(_ReplaceStackX)
    ret

mSecondsToTimeHandler:
    call closeInputAndRecallX ; OP1=X=seconds
    bcall(_SecondsToRpnTime) ; OP1=Time(seconds)
    bcall(_ReplaceStackX)
    ret

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
    bcall(_ReplaceStackX)
    ret

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
    bcall(_ReplaceStackX)
    ret

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
    bcall(_ReplaceStackX)
    ret

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
    bcall(_ReplaceStackX)
    ret

mDateTimeToEpochSecondsHandler:
    jp mDateToEpochSecondsHandler

mEpochSecondsToDateTimeHandler:
    call closeInputAndRecallX ; OP1=X=epochSeconds
    bcall(_EpochSecondsToRpnDateTime) ; OP1=DateTime(epochSeconds)
    bcall(_ReplaceStackX)
    ret

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
    bcall(_ReplaceStackX)
    ret

mDateTimeExtractTimeHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1==dateLikeObject; A=type
    cp rpnObjectTypeDateTime ; ZF=1 if RpnDateTime
    jr nz, mDateTimeErr
    bcall(_RpnDateTimeExtractTime) ; OP1=RpnTime
    bcall(_ReplaceStackX)
    ret

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
    bcall(_ReplaceStackX)
    ret

mOffsetToHoursHandler:
    call closeInputAndRecallRpnOffsetX ; A=rpnObjectType; OP1=X
    bcall(_RpnOffsetToHours) ; OP1=hours
    bcall(_ReplaceStackX)
    ret

mHoursToOffsetHandler:
    call closeInputAndRecallX ; OP1=X=hours
    bcall(_HoursToRpnOffset) ; OP1=RpnOffset(hours)
    bcall(_ReplaceStackX)
    ret

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
    bcall(_ReplaceStackX)
    ret

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
    bcall(_ReplaceStackX)
    ret

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
    bcall(_ReplaceStackX)
    ret

mOffsetDateTimeToEpochSecondsHandler:
    jp mDateToEpochSecondsHandler

mEpochSecondsToOffsetDateTimeUTCHandler:
    call closeInputAndRecallX ; OP1=X=epochSeconds
    bcall(_EpochSecondsToRpnOffsetDateTimeUTC) ; OP1=UTCDateTime(epochSeconds)
    bcall(_ReplaceStackX)
    ret

mOffsetDateTimeErr:
    bcall(_ErrDataType)

;-----------------------------------------------------------------------------
; DATE > DZ (OffsetDateTime) > Row 2
;-----------------------------------------------------------------------------

mEpochSecondsToOffsetDateTimeAppHandler:
    call closeInputAndRecallX ; OP1=X=epochSeconds
    ld bc, appTimeZone
    bcall(_EpochSecondsToRpnOffsetDateTime) ; OP1=OffsetDateTime(epochSeconds)
    bcall(_ReplaceStackX)
    ret

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
    bcall(_ReplaceStackX)
    ret

mOffsetDateTimeExtractTimeHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1==dateLikeObject; A=type
    cp rpnObjectTypeOffsetDateTime ; ZF=1 if RpnOffsetDateTime
    jr nz, mOffsetDateTimeErr
    bcall(_RpnOffsetDateTimeExtractTime) ; OP1=RpnDate
    bcall(_ReplaceStackX)
    ret

mOffsetDateTimeExtractDateTimeHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1==dateLikeObject; A=type
    cp rpnObjectTypeOffsetDateTime ; ZF=1 if RpnOffsetDateTime
    jr nz, mOffsetDateTimeErr
    bcall(_RpnOffsetDateTimeExtractDateTime) ; OP1=RpnDate
    bcall(_ReplaceStackX)
    ret

mOffsetDateTimeExtractOffsetHandler:
    call closeInputAndRecallRpnDateLikeX ; OP1==dateLikeObject; A=type
    cp rpnObjectTypeOffsetDateTime ; ZF=1 if RpnOffsetDateTime
    jr nz, mOffsetDateTimeErr
    bcall(_RpnOffsetDateTimeExtractOffset) ; OP1=RpnOffset
    bcall(_ReplaceStackX)
    ret

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
    bcall(_SecondsToRpnDuration) ; OP1=RpnDuration(seconds)
    bcall(_ReplaceStackX)
    ret

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
    bcall(_ReplaceStackX)
    ret

mDurationExtractDayHandler:
    call closeInputAndRecallRpnDateRelatedX ; OP1==dateRelatedObject; A=type
    cp rpnObjectTypeDuration
    jr nz, mDurationErr
    bcall(_RpnDurationExtractDay) ; OP1=day
    bcall(_ReplaceStackX)
    ret

mDurationExtractHourHandler:
    call closeInputAndRecallRpnDateRelatedX ; OP1==dateRelatedObject; A=type
    cp rpnObjectTypeDuration
    jr nz, mDurationErr
    bcall(_RpnDurationExtractHour) ; OP1=hour
    bcall(_ReplaceStackX)
    ret

mDurationExtractMinuteHandler:
    call closeInputAndRecallRpnDateRelatedX ; OP1==dateRelatedObject; A=type
    cp rpnObjectTypeDuration
    jr nz, mDurationErr
    bcall(_RpnDurationExtractMinute) ; OP1=minute
    bcall(_ReplaceStackX)
    ret

mDurationExtractSecondHandler:
    call closeInputAndRecallRpnDateRelatedX ; OP1==dateRelatedObject; A=type
    cp rpnObjectTypeDuration
    jr nz, mDurationErr
    bcall(_RpnDurationExtractSecond) ; OP1=second
    bcall(_ReplaceStackX)
    ret

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

; Mon=1, Sun=7
mDayOfWeekToIsoDowNumberHandler:
    call closeInputAndRecallRpnDateRelatedX ; OP1=rpnDayOfWeek; A=rpnObjectType
    cp rpnObjectTypeDayOfWeek
    jr nz, mDayOfWeekErr
    bcall(_RpnDayOfWeekToIsoDowNumber) ; OP1=isoDowNumber
    bcall(_ReplaceStackX)
    ret

; Mon=1, Sun=7
mIsoDowNumberToDayOfWeekHandler:
    call closeInputAndRecallX ; OP1=X=isoDowNumber
    bcall(_IsoDowNumberToRpnDayOfWeek) ; OP1=rpnDayOfWeek
    bcall(_ReplaceStackX)
    ret

; Sun=0, Sat=6
mDayOfWeekToUnixDowNumberHandler:
    call closeInputAndRecallRpnDateRelatedX ; OP1=rpnDayOfWeek; A=rpnObjectType
    cp rpnObjectTypeDayOfWeek
    jr nz, mDayOfWeekErr
    bcall(_RpnDayOfWeekToUnixDowNumber) ; OP1=unixDowNumber
    bcall(_ReplaceStackX)
    ret

; Sun=0, Sat=6
mUnixDowNumberToDayOfWeekHandler:
    call closeInputAndRecallX ; OP1=X=unixDowNumber
    bcall(_UnixDowNumberToRpnDayOfWeek) ; OP1=rpnDayOfWeek
    bcall(_ReplaceStackX)
    ret

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
    bcall(_PushToStackX)
    ret

;-----------------------------------------------------------------------------
; DATE > Generic Date handlers
;-----------------------------------------------------------------------------

; Handle LEAP function for Real, Date, DateTime, and OffsetDateTime.
mIsDateLeapHandler:
mIsDateTimeLeapHandler:
mIsOffsetDateTimeLeapHandler:
mGenericDateIsLeapHandler:
    call closeInputAndRecallUniversalX ; OP1=X=Real|Date-like
    bcall(_GenericDateIsLeap) ; OP1:Real=0 or 1
    bcall(_ReplaceStackX)
    ret

;-----------------------------------------------------------------------------

; Handle DSHK for DateTime and OffsetDateTime.
mDateShrinkToNothingHandler:
mDateTimeShrinkToDateHandler:
mOffsetDateTimeShrinkToDateTimeHandler:
mGenericDateShrinkHandler:
    call closeInputAndRecallRpnDateLikeX ; A=rpnObjectType
mGenericDateShrinkHandlerAltEntry:
    bcall(_GenericDateShrink)
    bcall(_ReplaceStackX)
    ret

;-----------------------------------------------------------------------------

; Handle DEXD for Date and DateTime.
mDateExtendToDateTimeHandler:
mDateTimeExtendToOffsetDateTimeHandler:
mOffsetDateTimeExtendToNothingHandler:
mGenericDateExtendHandler:
    call closeInputAndRecallRpnDateLikeX ; A=rpnObjectType
mGenericDateExtendHandlerAltEntry:
    bcall(_GenericDateExtend)
    bcall(_ReplaceStackX)
    ret

;-----------------------------------------------------------------------------

; Handle DCUT for DateTime and OffsetDateTime.
mDateCutToNothingHandler:
mDateTimeCutToDateHandler:
mOffsetDateTimeCutToDateTimeHandler:
mGenericDateCutHandler:
    call closeInputAndRecallRpnDateLikeX ; A=rpnObjectType
mGenericDateCutHandlerAltEntry:
    bcall(_GenericDateCut)
    ; CP1=X=RpnTime|RpnDateTime; CP3=Y=RpnDateTime|RpnOffset
    bcall(_ReplaceStackXWithCP1CP3)
    ret

;-----------------------------------------------------------------------------

; Handle DLNK for Date, DateTime. Same as handleKeyLink (2ND LINK) but accepts
; only date-related objects. Complex and Real objects not allowed.
mDateLinkToDateTimeHandler:
mDateTimeLinkToOffsetDateTimeHandler:
mOffsetDateTimeLinkToNothingHandler:
mGenericDateLinkHandler:
    call closeInputAndRecallUniversalXY ; A=rpnObjectType; CP1=Y; CP3=X
mGenericDateLinkHandlerAltEntry:
    bcall(_GenericDateLink) ; CP1=RpnDateTime|RpnOffsetDateTime
    bcall(_ReplaceStackXY)
    ret

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
    bcall(_PushToStackX)
    ret

mGetNowTimeHandler:
    ld a, (isRtcAvailable)
    or a
    jr z, noClockErr
    ;
    call closeInputAndRecallNone
    bcall(_RtcGetTime)
    bcall(_PushToStackX)
    ret

mGetNowDateHandler:
    ld a, (isRtcAvailable)
    or a
    jr z, noClockErr
    ;
    call closeInputAndRecallNone
    bcall(_RtcGetDate)
    bcall(_PushToStackX)
    ret

mGetNowOffsetDateTimeHandler:
    ld a, (isRtcAvailable)
    or a
    jr z, noClockErr
    ;
    call closeInputAndRecallNone
    bcall(_RtcGetOffsetDateTime)
    bcall(_PushToStackX)
    ret

mGetNowOffsetDateTimeUtcHandler:
    ld a, (isRtcAvailable)
    or a
    jr z, noClockErr
    ;
    call closeInputAndRecallNone
    bcall(_RtcGetOffsetDateTimeForUtc)
    bcall(_PushToStackX)
    ret

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
    bcall(_PushToStackX)
    ret

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
    bcall(_PushToStackX)
    ret

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
