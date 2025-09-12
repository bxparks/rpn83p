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

; Description: Convert the RpnDateTime to the timeZone specified by
; RpnOffset or Real.
; Input:
;   - OP1:(RpnDateTime|RpnOffset|Real)
;   - OP3:(RpnDateTime|RpnOffset|Real)
;   - one of OP1 or OP3 must be the RpnDateTime
; Output:
;   - OP1:RpnOffsetDatetime
; Throws: ErrDateType if the other is not a Real or RpnOffset
; Destroys: all, OP3-OP6
ConvertRpnDateTimeToTimeZone:
    call checkOp1DateTimePageTwo ; ZF=1 if CP1 is an RpnDateTime
    jr z, convertRpnDateTimeToObject
    call cp1ExCp3PageTwo ; CP1=rpnDateTime; CP3=rpnObject
    call checkOp1DateTimePageTwo ; ZF=1 if CP1 is an RpnDateTime
    jr z, convertRpnDateTimeToObject
    ; neither of OP1 nor OP3 is an RpnDateTime
    bcall(_ErrDataType)
convertRpnDateTimeToObject:
    ; Here CP1=rpnDateTime; CP3=rpnObject
    call ExtendRpnDateTimeToOffsetDateTime ; OP1=RpnOffsetDateTime
    jp convertRpnOffsetDateTimeToTimeZoneAltEntry

;-----------------------------------------------------------------------------

; Description: Convert the RpnOffsetDateTime to the timeZone specified by
; RpnOffset or Real.
; Input:
;   - OP1:(RpnOffsetDateTime|RpnOffset|Real)
;   - OP3:(RpnOffsetDateTime|RpnOffset|Real)
;   - one of OP1 or OP3 must be the RpnDateTime
; Output:
;   - OP1:RpnOffsetDatetime
; Throws: ErrDateType if the types don't match
; Destroys: all, OP3-OP6
ConvertRpnOffsetDateTimeToTimeZone:
    call checkOp1OffsetDateTimePageTwo ; ZF=1 if CP1 is an RpnOffsetDateTime
    jr z, convertRpnOffsetDateTimeToObject
    call cp1ExCp3PageTwo
    call checkOp1OffsetDateTimePageTwo ; ZF=1 if CP1 is an RpnOffsetDateTime
    jr z, convertRpnOffsetDateTimeToObject
    ; neither of OP1 nor OP3 is an RpnOffsetDateTime
    bcall(_ErrDataType)
convertRpnOffsetDateTimeToTimeZoneAltEntry:
convertRpnOffsetDateTimeToObject:
    ; OP1:RpnOffsetDateTime; OP3:RpnObject
    call checkOp3RealPageTwo
    jr z, convertRpnOffsetDateTimeToReal
    call checkOp3OffsetPageTwo
    jr z, convertRpnOffsetDateTimeToOffset
    bcall(_ErrDataType)
convertRpnOffsetDateTimeToReal:
    ; Convert Real to RpnOffset
    call PushRpnObject1 ; FPS=[rpnOffsetDateTime]
    call op3ToOp1PageTwo ; OP1=real
    call HoursToRpnOffset ; OP1=rpnOffset
    call op1ToOp3PageTwo ; OP3=rpnOffset
    call PopRpnObject1 ; FPS=[]; CP1=rpnOffsetDateTime
    ; [[fallthrough]]

; Description: Convert the RpnOffsetDateTime (OP1) to the timeZone specified by
; RpnOffset (OP3).
; Input:
;   - OP1:RpnOffsetDateTime
;   - OP3:RpnOffset
; Output:
;   - OP1; RpnOffsetDatetime
; Destroys: all, OP3-OP6
convertRpnOffsetDateTimeToOffset:
    ; CP1=rpnOffsetDateTime; CP3=rpnOffset
    call PushRpnObject1 ; FPS=[rpnOffsetDateTime]; HL=rpnOffsetDateTime
    skipRpnObjectTypeHL ; HL=offsetDateTime
    ex de, hl ; DE=offsetDateTime
    ;
    call pushRaw9Op3 ; FPS=[rpnOffsetDateTime,rpnOffset]; HL=rpnOffset
    skipRpnObjectTypeHL ; HL=offset
    push hl ; stack=[offset]
    ; convert OffsetDateTime to epochSeconds
    call reserveRaw9 ; FPS=[rpnOffsetDateTime,rpnOffset,epochSeconds]
    call offsetDateTimeToEpochSeconds ; HL=epochSeconds
    ; convert to OffsetDateTime
    ex de, hl ; DE=epochSeconds
    pop bc ; stack=[]; BC=offset
    ld a, rpnObjectTypeOffsetDateTime
    call setOp1RpnObjectTypePageTwo ; HL=OP1+sizeof(type)
    call epochSecondsToOffsetDateTime ; (HL)=offsetDateTime
    call expandOp1ToOp2PageTwo
    ; clean up FPS
    call dropRaw9 ; FPS=[rpnOffsetDateTime,rpnOffset]
    call dropRaw9 ; FPS=[rpnOffsetDateTime]
    jp dropRpnObject ; FPS=[]
