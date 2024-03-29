;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Convert OffsetDateTime or DateTime to target Offset timeZone.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Convert the RpnDateTime (OP1) to the timeZone specified by
; RpnOffset (OP3).
; Input:
;   - OP1:RpnDateTime or RpnOffset
;   - OP3:RpnOffset or RpnDateTime
; Output:
;   - OP1; RpnOffsetDatetime
; Destroys: all, OP3-OP6
ConvertRpnDateTimeToTimeZoneAsOffset:
    call checkOp1DateTimePageTwo ; ZF=1 if CP1 is an RpnDateTime
    jr z, convertRpnDateTimeToTimeZoneAsOffsetConvert
    call cp1ExCp3PageTwo ; CP1=rpnDateTime; CP3=rpnOffset
convertRpnDateTimeToTimeZoneAsOffsetConvert:
    ; CP1=rpnDateTime; CP3=rpnOffset
    call PushRpnObject1 ; FPS=[rpnDateTime]; HL=rpnDateTime
    inc hl ; HL=dateTime
    ex de, hl ; DE=dateTime
    ;
    call pushRaw9Op3 ; FPS=[rpnDateTime,rpnOffset]; HL=rpnOffset
    inc hl ; HL=offset
    push hl ; stack=[offset]
    ; convert DateTime to epochSeconds
    call reserveRaw9 ; FPS=[rpnDateTime,rpnOffset,epochSeconds]
    call dateTimeToEpochSeconds ; HL=epochSeconds
    ; convert to OffsetDateTime
    ex de, hl ; DE=epochSeconds
    pop bc ; stack=[]; BC=offset
    ld hl, OP1
    ld a, rpnObjectTypeOffsetDateTime
    ld (hl), a
    inc hl
    call epochSecondsToOffsetDateTime ; HL=OP1=offsetDateTime
    call expandOp1ToOp2PageTwo
    ; clean up FPS
    call dropRaw9 ; FPS=[rpnDateTime,rpnOffset]
    call dropRaw9 ; FPS=[rpnDateTime]
    jp dropRpnObject ; FPS=[]

; Description: Convert the RpnDateTime to the timeZone specified as offsetHour
; (e.g. 8.5 for Offset{8,30}).
; Input:
;   - OP1:RpnDateTime or Real
;   - OP3:Real or RpnDateTime
; Output:
;   - OP1; RpnOffsetDatetime
; Destroys: all, OP3-OP6
ConvertRpnDateTimeToTimeZoneAsReal:
    call checkOp1DateTimePageTwo ; ZF=1 if CP1 is an RpnDateTime
    jr z, convertRpnDateTimeToTimeZoneAsRealConvert
    call cp1ExCp3PageTwo ; CP1=rpnDateTime; CP3=offsetHour
convertRpnDateTimeToTimeZoneAsRealConvert:
    call PushRpnObject1 ; FPS=[rpnDateTime]; HL=rpnDateTime
    call op3ToOp1PageTwo ; OP1=offsetHour
    ; convert offsetHour to RpnOffset
    ld hl, OP3
    ld a, rpnObjectTypeOffset
    ld (hl), a
    inc hl
    call offsetHourToOffset ; HL=OP3+1=offset
    ; clean up FPS
    call PopRpnObject1 ; FPS=[]; OP1=rpnDateTime
    jr convertRpnDateTimeToTimeZoneAsOffsetConvert

;-----------------------------------------------------------------------------

; Description: Convert the RpnOffsetDateTime (OP1) to the timeZone specified by
; RpnOffset (OP3).
; Input:
;   - OP1:RpnOffsetDateTime
;   - OP3:RpnOffset
; Output:
;   - OP1; RpnOffsetDatetime
; Destroys: all, OP3-OP6
ConvertRpnOffsetDateTimeToOffset:
    call checkOp1OffsetDateTimePageTwo ; ZF=1 if CP1 is an RpnOffsetDateTime
    jr z, convertRpnOffsetDateTimeToOffsetConvert
    call cp1ExCp3PageTwo ; CP1=rpnOffsetDateTime; CP3=rpnOffset
convertRpnOffsetDateTimeToOffsetConvert:
    ; CP1=rpnOffsetDateTime; CP3=rpnOffset
    call PushRpnObject1 ; FPS=[rpnOffsetDateTime]; HL=rpnOffsetDateTime
    inc hl ; HL=offsetDateTime
    ex de, hl ; DE=offsetDateTime
    ;
    call pushRaw9Op3 ; FPS=[rpnOffsetDateTime,rpnOffset]; HL=rpnOffset
    inc hl ; HL=offset
    push hl ; stack=[offset]
    ; convert OffsetDateTime to epochSeconds
    call reserveRaw9 ; FPS=[rpnOffsetDateTime,rpnOffset,epochSeconds]
    call offsetDateTimeToEpochSeconds ; HL=epochSeconds
    ; convert to OffsetDateTime
    ex de, hl ; DE=epochSeconds
    pop bc ; stack=[]; BC=offset
    ld hl, OP1
    ld a, rpnObjectTypeOffsetDateTime
    ld (hl), a
    inc hl
    call epochSecondsToOffsetDateTime ; HL=OP1=offsetDateTime
    call expandOp1ToOp2PageTwo
    ; clean up FPS
    call dropRaw9 ; FPS=[rpnOffsetDateTime,rpnOffset]
    call dropRaw9 ; FPS=[rpnOffsetDateTime]
    jp dropRpnObject ; FPS=[]

; Description: Convert the RpnOffsetDateTime (OP1) to the timeZone specified by
; (hour,minute) as a floating point number (OP3) (e.g. 8.5 for Offset{8,30}).
; Input:
;   - OP1:RpnOffsetDateTime
;   - OP3:Real
; Output:
;   - OP1; RpnOffsetDatetime
; Destroys: all, OP3-OP6
ConvertRpnOffsetDateTimeToTimeZoneAsReal:
    call checkOp1OffsetDateTimePageTwo ; ZF=1 if CP1 is an RpnOffsetDateTime
    jr z, convertRpnOffsetDateTimeToTimeZoneAsRealConvert
    call cp1ExCp3PageTwo ; CP1=rpnOffsetDateTime; CP3=offsetHour
convertRpnOffsetDateTimeToTimeZoneAsRealConvert:
    call PushRpnObject1 ; FPS=[rpnOffsetDateTime]; HL=rpnOffsetDateTime
    call op3ToOp1PageTwo ; OP1=offsetHour
    ; convert offsetHour to RpnOffset
    ld hl, OP3
    ld a, rpnObjectTypeOffset
    ld (hl), a
    inc hl
    call offsetHourToOffset ; HL=OP3+1=offset
    ; clean up FPS
    call PopRpnObject1 ; FPS=[]; OP1=rpnOffsetDateTime
    jr convertRpnOffsetDateTimeToOffsetConvert

