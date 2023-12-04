;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;-----------------------------------------------------------------------------

; DATE/Row1
mNowHandler:
mConvertTimeZoneHandler:

; DATE/ZONE/Row1
mZoneOffsetUTCHandler:
mZoneOffsetSetHandler:
mZoneOffsetGetHandler:

; DATE/EPCH/Row1
mDateToEpochDaysHandler:
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
mLeapYearHandler:

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
