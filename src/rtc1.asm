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
; Output: OP1:real=seconds relative to current epochDate.
RtcGetNow:
    ld hl, OP1
    call getRtcNowAsEpochSeconds ; HL=OP1=epochSeconds
    jp ConvertI40ToOP1

RtcGetTime:
    ld hl, OP1
    call getRtcNowAsEpochSeconds ; HL=OP1=epochSeconds
    ; Convert to RpnOffsetDateTime using current offset
    call epochSecondsToRpnOffsetDateTimeAlt ; OP1=RpnOffsetDateTime
    ; Convert to RpnTime
    ld hl, OP1
    call convertToTime ; HL=(RpnTime*)=rpnTime
    ret

RtcGetDate:
    ld hl, OP1
    call getRtcNowAsEpochSeconds ; HL=OP1=epochSeconds
    ; Convert to RpnOffsetDateTime using current offset
    call epochSecondsToRpnOffsetDateTimeAlt ; OP1=RpnOffsetDateTime
    ; Convert RpnOffsetDateTime to RpnDate.
    ld hl, OP1
    call convertToDate ; HL=(RpnDate*)=rpnDate
    ret

; Description: Retrieve the current RTC as an OffsetDateTime using the current
; timeZone.
; Input: none
; Output: OP1:(OffsetDateTime*)=current datetime
RtcGetOffsetDateTime:
    ld hl, OP1
    call getRtcNowAsEpochSeconds ; HL=OP1=epochSeconds
    ; Convert to RpnOffsetDateTime using current offset
    jp epochSecondsToRpnOffsetDateTimeAlt ; OP1=RpnOffsetDateTime

;-----------------------------------------------------------------------------

; Description: Retrieve current RTC as internal epochSeconds.
; Input: HL:(i40*)=pointer to rtcSeconds
; Output: (*HL) updated
; Destroys: A, DE
; Preserves: HL
getRtcNowAsEpochSeconds:
    push hl ; stack=[rtcSeconds]
    ; Read epochSeconds (relative TIOS epoch) from 45h-48h ports to OP1.
    ; See https://wikiti.brandonw.net/index.php?title=83Plus:Ports:45
    ; TODO: Use INIR instruction.
    in a, (45h)
    ld (hl), a
    inc hl
    in a, (46h)
    ld (hl), a
    inc hl
    in a, (47h)
    ld (hl), a
    inc hl
    in a, (48h)
    ld (hl), a
    inc hl
    ld (hl), 0
    pop hl ; stack=[]; HL=rtcSeconds
    ; Convert rtcSeconds to internal epochSeconds
    ld de, tiosEpochDate ; DE=Date{1997,1,1}
    call convertRelativeToInternalEpochSeconds ; HL=rtcSeconds
    ; Convert to relative epochSeconds relative to current timeZone
    ld de, epochDate ; DE=(Date*)=current epochDate
    jp convertInternalToRelativeEpochSeconds ; HL=rtcSeconds

;-----------------------------------------------------------------------------

; Description: Set the RTC time zone to the Offset{} given in OP1.
; Input: OP1:RpnOffset{}
; Output: none
RtcSetTimeZone:
    ld hl, OP1
    ld a, (hl)
    inc hl
    cp rpnObjectTypeOffset
    jr nz, rtcSetTimeZoneErr
    ld c, (hl)
    inc hl
    ld b, (hl)
    ld (rtcTimeZone), bc
    ret
rtcSetTimeZoneErr:
    bcall(_ErrDataType)

; Description: Get the RTC time zone into OP1.
; Input: OP1:RpnOffset{}
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

; Description: Set the RTC date, time, and timezone.
RtcSetClock:
    ret
