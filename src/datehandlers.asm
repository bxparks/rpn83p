;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;-----------------------------------------------------------------------------

mLeapYearHandler:
    call closeInputAndRecallX ; OP1=X=year
    bcall(_IsLeap) ; OP1=0 or 1
    jp replaceX

mDayOfWeekHandler:
    call closeInputAndRecallRpnDateX ; OP1=X=RpnDate
    ld hl, OP1+1 ; skip type byte
    bcall(_DayOfWeekIso) ; A=[1,7]
    bcall(_ConvertAToOP1)
    jp replaceX

mDateToEpochDaysHandler:
    call closeInputAndRecallRpnDateX ; OP1=X=RpnDate
    bcall(_RpnDateToEpochDays) ; OP1=float(days)
    jp replaceX

mEpochDaysToDateHandler:
    call closeInputAndRecallX ; OP1=X=epochDays
    bcall(_EpochDaysToRpnDate) ; OP1=Date(epochDays)
    jp replaceX

mDateTimeToEpochSecondsHandler:
    call closeInputAndRecallRpnDateX ; OP1=X=RpnDate
    ld hl, OP1
    bcall(_ConvertToDateTime) ; preserves HL
    bcall(_RpnDateTimeToEpochSeconds) ; OP3=i40(seconds)
    jp replaceX

mEpochSecondsToDateTimeHandler:
    call closeInputAndRecallX ; OP1=X=epochSeconds
    bcall(_EpochSecondsToRpnDateTime) ; OP1=DateTime(epochSeconds)
    jp replaceX

;-----------------------------------------------------------------------------
; DATE/EPCH/Row2
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

mEpochSetCustomHandler:
    call closeInputAndRecallRpnDateX ; OP1=X=RpnDate{}
    bcall(_SetCustomEpochDate)
    ret

mEpochGetCustomHandler:
    call closeInputAndRecallNone
    bcall(_GetCustomEpochDate)
    jp pushToX

;-----------------------------------------------------------------------------
; Other DATE functions
;-----------------------------------------------------------------------------

; DATE/Row1
mNowHandler:
mConvertTimeZoneHandler:

; DATE/ZONE/Row1
mZoneOffsetUTCHandler:
mZoneOffsetSetHandler:
mZoneOffsetGetHandler:

; DATE/DUR/Row1
mDurationToSecondsHandler:
mSecondsToDurationHandler:

; DATE/JUL/Row1
mDateTimeToJulianHandler:
mJulianToDateTimeHandler:
mDateTimeToModifiedJulianHandler:
mModifiedJulianToDateTimeHandler:

; DATE/ISO/Row1
mDateToIsoWeekDayHandler:
mIsoWeekDayToDateHandler:

    jp mNotYetHandler
