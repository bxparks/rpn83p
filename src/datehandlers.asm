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
    ld hl, OP1+1 ; skip type byte
    bcall(_DayOfWeekIso) ; A=[1,7]
    bcall(_ConvertAToOP1)
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

mDateLikeToEpochSecondsHandler:
    call closeInputAndRecallRpnDateLikeOrOffsetX ; OP1=X=RpnDateLike or Offset
    call checkOp1Date ; ZF=1 if RpnDate
    jr z, mDateLikeToEpochSecondsHandlerDate
    call checkOp1DateTime ; ZF=1 if RpnDateTime
    jr z, mDateLikeToEpochSecondsHandlerDateTime
    call checkOp1Offset ; ZF=1 if RpnOffset
    jr z, mDateLikeToEpochSecondsHandlerOffset
    call checkOp1OffsetDateTime ; ZF=1 if RpnOffsetDateTime
    jr z, mDateLikeToEpochSecondsHandlerOffsetDateTime
    bcall(_ErrDataType)
mDateLikeToEpochSecondsHandlerDate:
    bcall(_RpnDateToEpochSeconds) ; OP1=epochSeconds
    jr mDateLikeToEpochSecondsHandlerEnd
mDateLikeToEpochSecondsHandlerDateTime:
    bcall(_RpnDateTimeToEpochSeconds) ; OP1=epochSeconds
    jr mDateLikeToEpochSecondsHandlerEnd
mDateLikeToEpochSecondsHandlerOffset:
    bcall(_RpnOffsetToSeconds) ; OP1=seconds
    jr mDateLikeToEpochSecondsHandlerEnd
mDateLikeToEpochSecondsHandlerOffsetDateTime:
    bcall(_RpnOffsetDateTimeToEpochSeconds) ; OP1=epochSeconds
    ; [[fallthrough]]
mDateLikeToEpochSecondsHandlerEnd:
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

; Input: A, B: nameId; C: altNameId
mEpochUnixNameSelector:
    ld a, (epochType)
    cp epochTypeUnix
    jr z, mEpochUnixNameSelectorAlt
    ld a, b
    ret
mEpochUnixNameSelectorAlt:
    ld a, c
    ret

;-----------------------------------------------------------------------------

mEpochNtpHandler:
    bcall(_SelectNtpEpochDate)
    ret

; Input: A, B: nameId; C: altNameId
mEpochNtpNameSelector:
    ld a, (epochType)
    cp epochTypeNtp
    jr z, mEpochNtpNameSelectorAlt
    ld a, b
    ret
mEpochNtpNameSelectorAlt:
    ld a, c
    ret

;-----------------------------------------------------------------------------

mEpochGpsHandler:
    bcall(_SelectGpsEpochDate)
    ret

; Input: A, B: nameId; C: altNameId
mEpochGpsNameSelector:
    ld a, (epochType)
    cp epochTypeGps
    jr z, mEpochGpsNameSelectorAlt
    ld a, b
    ret
mEpochGpsNameSelectorAlt:
    ld a, c
    ret

;-----------------------------------------------------------------------------

mEpochTiosHandler:
    bcall(_SelectTiosEpochDate)
    ret

; Input: A, B: nameId; C: altNameId
mEpochTiosNameSelector:
    ld a, (epochType)
    cp epochTypeTios
    jr z, mEpochTiosNameSelectorAlt
    ld a, b
    ret
mEpochTiosNameSelectorAlt:
    ld a, c
    ret

;-----------------------------------------------------------------------------

mEpochCustomHandler:
    bcall(_SelectCustomEpochDate)
    ret

; Input: A, B: nameId; C: altNameId
mEpochCustomNameSelector:
    ld a, (epochType)
    cp epochTypeCustom
    jr z, mEpochCustomNameSelectorAlt
    ld a, b
    ret
mEpochCustomNameSelectorAlt:
    ld a, c
    ret

;-----------------------------------------------------------------------------
; DATE > EPCH > Row 2
;-----------------------------------------------------------------------------

mEpochSetCustomHandler:
    call closeInputAndRecallRpnDateX ; OP1=X=RpnDate{}
    bcall(_SetCustomEpochDate)
    ret

mEpochGetCustomHandler:
    call closeInputAndRecallNone
    bcall(_GetCustomEpochDate)
    jp pushToX

;-----------------------------------------------------------------------------
; DATE > ZONE > Row1
;-----------------------------------------------------------------------------

mSetTimeZoneHandler:
    call closeInputAndRecallRpnOffsetX
    bcall(_SetTimeZone)
    ret

mGetTimeZoneHandler:
    call closeInputAndRecallNone
    bcall(_GetTimeZone)
    jp pushToX

;-----------------------------------------------------------------------------
; Other DATE functions
;-----------------------------------------------------------------------------

; DATE > Row1
mNowHandler:
mConvertTimeZoneHandler:

; DATE > DUR > Row1
mDurationToSecondsHandler:
mSecondsToDurationHandler:

; DATE > JUL > Row1
mDateTimeToJulianHandler:
mJulianToDateTimeHandler:
mDateTimeToModifiedJulianHandler:
mModifiedJulianToDateTimeHandler:

; DATE > ISO > Row1
mDateToIsoWeekDayHandler:
mIsoWeekDayToDateHandler:

    jp mNotYetHandler
