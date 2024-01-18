;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;-----------------------------------------------------------------------------

mLeapYearHandler:
    call closeInputAndRecallX ; OP1=X=year
    bcall(_IsLeap) ; OP1=0 or 1
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

mEpochDaystoDateHandler:
    call closeInputAndRecallX ; OP1=X=epochDays
    ld hl, OP3
    bcall(_ConvertOP1ToI40) ; OP3=i40(X)
    ; TODO: Replace below with EpochDaysToDate().
    bcall(_ConvertI40ToOP1) ; OP1=float(i40(X))
    ret

;-----------------------------------------------------------------------------

; DATE/Row1
mNowHandler:
mConvertTimeZoneHandler:

; DATE/ZONE/Row1
mZoneOffsetUTCHandler:
mZoneOffsetSetHandler:
mZoneOffsetGetHandler:

; DATE/EPCH/Row1
mDateTimeToEpochSecondsHandler:
mEpochSecondstoDateTimeHandler:

; DATE/EPCH/Row2
mEpochUnixHandler:
mEpochNTPHandler:
mEpochGPSHandler:
mEpochSetCustomHandler:
mEpochGetCustomHandler:

; DATE/D.FN/Row1
mDayOfWeekHandler:

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
