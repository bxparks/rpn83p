;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;-----------------------------------------------------------------------------

mLeapYearHandler:
    call closeInputAndRecallX ; OP1=X=year
    bcall(_IsLeap) ; OP1=0 or 1
    jp replaceX

mDayOfWeekHandler:
    call closeInputAndRecallDateX ; OP1=X=DateRecord
    ld hl, OP1
    bcall(_DayOfWeekIso) ; A=[1,7]
    bcall(_ConvertAToOP1)
    jp replaceX

mDateToEpochDaysHandler:
    call closeInputAndRecallDateX ; OP1=X=DateRecord
    ;
    ld hl, OP1
    ld de, OP3
    bcall(_DateToEpochDays) ; OP3=i40(days)
    ;
    ld hl, OP3
    bcall(_ConvertI40ToOP1) ; OP1=float(days)
    jp replaceX

mEpochDaysToDateHandler:
    call closeInputAndRecallX ; OP1=X=epochDays
    ;
    ld hl, OP3
    bcall(_ConvertOP1ToI40) ; OP3=i40(X)
    ;
    ld hl, OP3
    ld de, OP1
    bcall(_EpochDaysToDate) ; DE=OP1=DateRecord(u40(epochDays))
    jp replaceX

mDateTimeToEpochSecondsHandler:
    call closeInputAndRecallDateX ; OP1=X=DateRecord
    ld hl, OP1
    ld de, OP3
    bcall(_DateTimeToEpochSeconds) ; OP3=i40(seconds)
    ld hl, OP3
    bcall(_ConvertI40ToOP1) ; OP1=float(seconds)
    jp replaceX

mEpochSecondstoDateTimeHandler:
    jp mNotYetHandler

;-----------------------------------------------------------------------------

; DATE/Row1
mNowHandler:
mConvertTimeZoneHandler:

; DATE/ZONE/Row1
mZoneOffsetUTCHandler:
mZoneOffsetSetHandler:
mZoneOffsetGetHandler:

; DATE/EPCH/Row2
mEpochUnixHandler:
mEpochNTPHandler:
mEpochGPSHandler:
mEpochSetCustomHandler:
mEpochGetCustomHandler:

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
