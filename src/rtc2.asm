;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Routines related to the real time clock (RTC), which is available only the
; 84_ and 84+SE.
;
; TODO: Check for 83+ and 83+SE, and return an error message to the user.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

RtcInit:
    ; set RTC timezone to UTC initially
    ld hl, 0
    ld (rtcTimeZone), hl
    ret

;-----------------------------------------------------------------------------

; Description: Retrieve the current RTC as seconds relative to the current
; epochDate.
; Input: none
; Output: OP1:real=epochSeconds
RtcGetNow:
    ld hl, OP1
    call getRtcNowAsEpochSeconds ; HL=OP1=epochSeconds
    jp ConvertI40ToOP1

; Description: Retrieve the current RTC as a Time object.
; Input: none
; Output: OP1:Time=currentTime
RtcGetTime:
    ld hl, OP1
    call getRtcNowAsEpochSeconds ; HL=OP1=epochSeconds
    ; Convert to RpnOffsetDateTime using current offset
    ld bc, appTimeZone
    call epochSecondsToRpnOffsetDateTimeAlt ; OP1=RpnOffsetDateTime
    ; Transform to RpnTime
    ld hl, OP1
    call transformToTime ; HL=(RpnTime*)=rpnTime
    ret

; Description: Retrieve the current RTC as a Date object.
; Input: none
; Output: OP1:RpnDate=currentDate
RtcGetDate:
    ld hl, OP1
    call getRtcNowAsEpochSeconds ; HL=OP1=epochSeconds
    ; Convert to RpnOffsetDateTime using current offset
    ld bc, appTimeZone
    call epochSecondsToRpnOffsetDateTimeAlt ; OP1=RpnOffsetDateTime
    ; Transform RpnOffsetDateTime to RpnDate.
    ld hl, OP1
    call transformToDate ; HL=(RpnDate*)=rpnDate
    ret

; Description: Retrieve the current RTC as an OffsetDateTime using the
; appTimeZone.
; Input: none
; Output: OP1:RpnOffsetDateTime=offsetDateTime
RtcGetAppDateTime:
    ld hl, OP1
    call getRtcNowAsEpochSeconds ; HL=OP1=epochSeconds
    ; Convert to RpnOffsetDateTime using current appTimeZone
    ld bc, appTimeZone
    jp epochSecondsToRpnOffsetDateTimeAlt ; OP1=RpnOffsetDateTime

; Description: Retrieve the current RTC as an OffsetDateTime using UTC
; timezone.
; Input: none
; Output: OP1:OffsetDateTime=utcDateTime
RtcGetUTCDateTime:
    ld hl, OP1
    call getRtcNowAsEpochSeconds ; HL=OP1=epochSeconds
    ; Convert to RpnDateTime using UTC timezone
    call epochSecondsToRpnDateTimeAlt ; OP1=RpnDateTime
    ; Transform RpnDateTime to RpnOffsetDateTime w/ UTC timezone
    ld hl, OP1
    call transformToOffsetDateTime ; HL=(RpnOffsetDateTime*)=utcDateTime
    call expandOp1ToOp2PageTwo ; handle 2-byte gap between OP1 and OP2
    ret

;-----------------------------------------------------------------------------

; Description: Set the RTC time zone to the Offset{} or Real given in OP1.
; If a Real is given, it is converted into an Offset{}, then stored.
; Input: OP1:RpnOffset{} or Real
; Output: none
RtcSetTimeZone:
    ld hl, OP1
    ld a, (hl)
    and $1f
    inc hl
    cp rpnObjectTypeOffset
    jr z, rtcSetTimeZoneForOffset
    cp rpnObjectTypeReal
    jr z, rtcSetTimeZoneForReal
rtcSetTimeZoneErr:
    bcall(_ErrDataType)
rtcSetTimeZoneForReal:
    ; convert OP1 to RpnOffset
    ld hl, OP3
    call offsetHourToOffset
rtcSetTimeZoneForOffset:
    ld c, (hl)
    inc hl
    ld b, (hl)
    ld (rtcTimeZone), bc
    ret

; Description: Get the RTC time zone into OP1.
; Input: OP1:RpnOffset
; Output: none
RtcGetTimeZone:
    ld hl, OP1
    ld a, rpnObjectTypeOffset
    ld (hl), a
    inc hl
    ;
    ld bc, (rtcTimeZone)
    ld (hl), c
    inc hl
    ld (hl), b
    ret

;-----------------------------------------------------------------------------

; Description: Set the RTC date and time. The input can be a DateTime (which is
; always interpreted as UTC), or an OffsetDateTime (whose UTC offset is
; included).
; Input: OP1:RpnOffsetDateTime=inputDateTime
; Output: real time clock set to epochSeconds defined by inputDateTime
RtcSetClock:
    ; push OP1/OP2 onto the FPS, which has the side-effect of removing the
    ; 2-byte gap between OP1 and OP2
    call PushRpnObject1 ; FPS=[rpnOffsetDateTime]; HL=rpnOffsetDateTime
    ex de, hl ; DE=rpnOffsetDateTime
    ; convert DateTime to dateTimeSeconds
    ld hl, OP1
    inc de ; DE=offsetDateTime, skip type byte
    call offsetDateTimeToEpochSeconds ; HL:(i40*)=OP1=epochSeconds
    ; set the RTC
    call setRtcNowFromEpochSeconds
    ; clean up
    call dropRpnObject ; FPS=[]
    ret

;-----------------------------------------------------------------------------
; Read and write to the RTC ports.
;-----------------------------------------------------------------------------

; Description: Retrieve current RTC date/time as relative epochSeconds.
; Input: HL:(i40*)=rtcSeconds
; Output: (*HL) updated
; Destroys: A, BC, DE
; Preserves: HL
getRtcNowAsEpochSeconds:
    push hl ; stack=[rtcSeconds]
    ; Read epochSeconds (relative TIOS epoch) from 45h-48h ports to OP1.
    ; See https://wikiti.brandonw.net/index.php?title=83Plus:Ports:45
    ld c, 45h
    ld b, 4
getRtcNowAsEpochSecondsLoop:
    ; See https://wikiti.brandonw.net/index.php?title=83Plus:Ports:45
    ; TODO: Do I need to disable interrupts, to prevent non-atomic read of the
    ; 4 bytes?
    in a, (c)
    ld (hl), a
    inc c
    inc hl
    djnz getRtcNowAsEpochSecondsLoop
    ld (hl), 0
    pop hl ; stack=[]; HL=rtcSeconds
    ; Convert rtcSeconds relative to the rtcTimeZone to utcSeconds by
    ; subtracting the seconds(rtcTimeZone).
    ld de, rtcTimeZone
    call localEpochSecondsToUtcEpochSeconds ; HL=utcEpochSeconds
    ; Convert rtcSeconds to internal epochSeconds
    ld de, tiosEpochDate ; DE=Date{1997,1,1}
    call convertRelativeToInternalEpochSeconds ; HL=rtcSeconds
    ; Convert to relative epochSeconds relative to currentEpochDate
    ld de, currentEpochDate ; DE=(Date*)=currentEpochDate
    jp convertInternalToRelativeEpochSeconds ; HL=rtcSeconds

;-----------------------------------------------------------------------------

; Description: Set the current RTC date/time from the given relative
; epochSeconds.
; Input: HL:(i40*)=rtcSeconds
; Output: RTC updated
; DestroysL A, BC, DE
setRtcNowFromEpochSeconds:
    ; convert relative epoch seconds to the epoch seconds used by the RTC
    ; according to its rtcTimeZone.
    ld de, currentEpochDate ; DE=(Date*)=currentEpochDate
    call convertRelativeToInternalEpochSeconds
    ld de, tiosEpochDate ; DE=Date{1997,1,1}
    call convertInternalToRelativeEpochSeconds
    ld de, rtcTimeZone
    call utcEpochSecondsToLocalEpochSeconds ; HL=rtcSeconds
    ; save the rtcSeconds to ports 41h-44h, then to 45h-49h
    ld c, 41h
    ld b, 4
setRtcNowFromEpochSecondsLoop:
    ; See https://wikiti.brandonw.net/index.php?title=83Plus:Ports:40
    ; TODO: Do I need to disable interrupts?
    ld a, (hl)
    out (c), a
    inc c
    inc hl
    djnz setRtcNowFromEpochSecondsLoop
    ; copy the 4-bytes in the staging area to the actual RTC registers
    ld a, 1
    out (40h), a ; set control bit LOW
    ld a, 3
    out (40h), a ; set control bit HIGH to trigger an edge
    ret
