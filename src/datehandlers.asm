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
    bcall(_DateToEpochDays) ; OP3=u40(days)
    ;
    ld hl, OP3
    bcall(_ConvertU40ToOP1) ; OP1=float(days)
    jp replaceX

;-----------------------------------------------------------------------------

; DATE/Row1
mNowHandler:
mConvertTimeZoneHandler:

; DATE/ZONE/Row1
mZoneOffsetUTCHandler:
mZoneOffsetSetHandler:
mZoneOffsetGetHandler:

; DATE/EPCH/Row1
mEpochDaystoDateHandler:
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
