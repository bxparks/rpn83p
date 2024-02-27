;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; RpnOffsetDateTime functions.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Convert the RpnOffsetDateTime{} record in OP1 to relative
; epochSeconds.
; Input: OP1/OP2:RpnOffsetDateTime=input
; Output: OP1:real
; Destroys: all, OP1-OP6
RpnOffsetDateTimeToEpochSeconds:
    ; push OP1/OP2 onto the FPS, which has the side-effect of removing the
    ; 2-byte gap between OP1 and OP2
    call PushRpnObject1 ; FPS=[rpnOffsetDateTime]; HL=rpnOffsetDateTime
    ex de, hl ; DE=rpnOffsetDateTime
    call reserveRaw9 ; FPS=[rpnOffsetDateTime,reserved]; HL=reserved
    ; convert DateTime to dateTimeSeconds
    inc de ; DE=offsetDateTime, skip type byte
    call offsetDateTimeToEpochSeconds ; HL:(i40*)=reserved=epochSeconds
    ; copy back to OP1
    call popRaw9Op1 ; FPS=[rpnOffsetDateTime]; HL=OP1=epochSeconds
    call dropRpnObject ; FPS=[]
    jp ConvertI40ToOP1 ; OP1=float(OP1)

; Description: Convert OffsetDateTime{} to relative epochSeconds.
; Input:
;   - DE:(const OffsetDateTime*)=dateTime, must not be OPx
;   - HL:(i40*)=resultSeconds, must not be OPx
; Output:
;   - DE=DE+sizeof(OffsetDateTime)
;   - (*HL):i40=resultSeconds
; Destroys: OP4-OP6
; Preserves: HL
offsetDateTimeToEpochSeconds:
    ; convert DateTime to relative epochSeconds
    call dateTimeToEpochSeconds ; HL=dateTimeSeconds; DE+=sizeof(DateTime)
    ; convert localEpochSeconds to utcEpochSeconds
    call localEpochSecondsToUtcEpochSeconds ; HL=utcEpochSeconds; DE+=2
    ret

;-----------------------------------------------------------------------------

; Description: Convert the relative epochSeconds to an RpnOffsetDateTime{}
; record.
; Input: OP1:Real=epochSeconds
; Output: OP1:RpnOffsetDateTime
; Destroys: all, OP1-OP6
EpochSecondsToRpnOffsetDateTime:
    ; get relative epochSeconds
    call ConvertOP1ToI40 ; OP1=i40(epochSeconds)
epochSecondsToRpnOffsetDateTimeAlt:
    ; reserve RpnObject on FPS
    call reserveRpnObject ; FPS=[rpnOffsetDateTime]; HL=rpnOffsetDateTime
    ex de, hl ; DE=rpnOffsetDateTime
    call pushRaw9Op1 ; FPS=[rpnOffsetDateTime,epochSeconds]; HL=epochSeconds
    ; convert to RpnOffsetDateTime
    ex de, hl ; DE=epochSeconds; HL=rpnOffsetDateTime
    ld a, rpnObjectTypeOffsetDateTime
    ld (hl), a
    inc hl ; HL=rpnOffsetDateTime+1=offsetDateTime
    ; select the currently selected TZ offset
    ld bc, timeZone
    call epochSecondsToOffsetDateTime ; HL=HL+sizeof(OffsetDateTime)
    ; clean up FPS
    call dropRaw9
    jp PopRpnObject1 ; OP1=RpnOffsetDateTime

; Description: Convert the relative epochSeconds to an OffsetDateTime{} with
; the given Offset{}.
; Input:
;   - BC:(const Offset*)=offset
;   - DE:(const i40*)=epochSeconds, must not be an OPx
;   - HL:(OffsetDateTime*)=offsetDateTime, must not be an OPx
; Output:
;   - BC=offset+2
;   - (*HL)=offsetDateTime updated
;   - HL=HL+sizeof(OffsetDateTime)
; Destroys: all, OP1-OP6
; Preserves: DE
epochSecondsToOffsetDateTime:
    push de ; stack=[epochSeconds]
    push bc ; stack=[epochSeconds,offset]
    push hl ; stack=[epochSeconds,offset,offsetDateTime]
    ; convert utcEpochSeconds to localEpochSeconds
    ex de, hl ; HL=utcEpochSeconds
    ld e, c
    ld d, b ; DE=offset
    call utcEpochSecondsToLocalEpochSeconds ; HL=localEpochSeconds; DE+=2
    ; convert localEpochSeconds to DateTime
    ex de, hl ; DE=localEpochSeconds
    pop hl ; stack=[epochSeconds,offset]; HL=offsetDateTime
    call epochSecondsToDateTime ; HL=offsetDateTime+sizeof(DateTime)
    ; copy the given offset into OffsetDateTime.offset
    pop bc ; stack=[epochSeconds]; BC=offset
    ld a, (bc)
    inc bc
    ld (hl), a
    inc hl
    ld a, (bc)
    inc bc
    ld (hl), a
    inc hl ; HL=HL+sizeof(OffsetDateTime)
    pop de ; stack=[]; DE=epochSeconds
    ret

;-----------------------------------------------------------------------------

; Description: Add (RpnOffsetDateTime plus seconds) or (seconds plus
; RpnDateTime).
; Input:
;   - OP1:Union[RpnOffsetDateTime,RpnReal]=rpnOffsetDateTime or seconds
;   - OP3:Union[RpnOffsetDateTime,RpnReal]=rpnOffsetDateTime or seconds
; Output:
;   - OP1:RpnOffsetDateTime=RpnOffsetDateTime+seconds
; Destroys: all, OP1, OP2, OP3-OP6
AddRpnOffsetDateTimeBySeconds:
    call checkOp1OffsetDateTimePageTwo ; ZF=1 if CP1 is an RpnOffsetDateTime
    jr z, addRpnOffsetDateTimeBySecondsAdd
    call cp1ExCp3PageTwo ; CP1=rpnOffsetDateTime; CP3=seconds
addRpnOffsetDateTimeBySecondsAdd:
    ; CP1=rpnOffsetDateTime, CP3=seconds
    ; Push rpnOffsetDateTime to FPS, which also removes the 2-byte gap between
    ; OP1/OP2.
    call PushRpnObject1 ; FPS=[rpnOffsetDateTime]
    push hl ; stack=[rpnOffsetDateTime]
    ; convert OP3 to i40, then push to FPS
    call op3ToOp1PageTwo ; OP1:real=seconds
    call ConvertOP1ToI40 ; OP1:(i40*)=seconds
    call pushRaw9Op1 ; FPS=[rpnOffsetDateTime,seconds]; HL=seconds
    ex (sp), hl ; stack=[seconds]; HL=rpnOffsetDateTime
    ; convert rpnOffsetDateTime to i40 seconds
    ex de, hl ; DE=rpnOffsetDateTime
    inc de ; skip type byte
    ld hl, OP1
    call offsetDateTimeToEpochSeconds ; HL=OP1:(i40*)=offsetDateTimeSeconds
    ; save (Offset*) pointer to original offset
    ld c, e
    ld b, d ; BC=offsetDateTime+sizeof(OffsetDateTime)
    dec bc
    dec bc ; BC:(Offset*)=offset
    ; add seconds + dateSeconds
    ex de, hl ; DE=offsetDateTimeSeconds
    pop hl ; stack=[]; HL=FPS.seconds
    call addU40U40 ; HL=FPS.resultSeconds=offsetDateTimeSeconds+seconds
    ; convert resultSeconds to RpnOffsetDateTime (use FPS to avoid the 2-byte
    ; gap)
    ex de, hl ; DE=resultSeconds
    ; after the call below:
    ;   - FPS=[rpnOffsetDateTime,resultSeconds,resultOffsetDateTime]
    ;   - HL=resultOffsetDatetime
    call reserveRpnObject
    ld a, rpnObjectTypeOffsetDateTime
    ld (hl), a
    inc hl ; HL:(OffsetDateTime*)=newOffsetDateTime
    call epochSecondsToOffsetDateTime ; HL=resultOffsetDateTime+sizeof(ODT)
    ; clean up stack and FPS
    call PopRpnObject1 ; FPS=[rpnOffsetDateTime,resultSeconds]; OP1=result
    call dropRaw9 ; FPS=[rpnOffsetDateTime]
    jp dropRpnObject ; FPS=[]

;-----------------------------------------------------------------------------

; Description: Subtract RpnOffsetDateTime minus RpnOffsetDateTime or seconds.
; Input:
;   - OP1:RpnOffsetDateTime=Y
;   - OP3:RpnOffsetDateTime or seconds=X
; Output:
;   - OP1:(RpnOffsetDateTime-seconds) or (RpnOffsetDateTime-RpnOffsetDateTime).
; Destroys: OP1, OP2, OP3-OP6
SubRpnOffsetDateTimeByRpnOffsetDateTimeOrSeconds:
    call checkOp3OffsetDateTimePageTwo ; ZF=1 if type(OP3)==OffsetDateTime
    jr z, subRpnOffsetDateTimeByRpnOffsetDateTime
subRpnOffsetDateTimeBySeconds:
    ; invert the sign of OP3, then call addRpnOffsetDateTimeBySecondsAdd()
    call cp1ExCp3PageTwo
    bcall(_InvOP1S) ; OP1=-OP1
    call cp1ExCp3PageTwo
    jr addRpnOffsetDateTimeBySecondsAdd
subRpnOffsetDateTimeByRpnOffsetDateTime:
    ; save copies of X, Y OffsetDateTime to FPS
    call PushRpnObject1 ; FPS=[Yodt]; HL=Yodt
    push hl ; stack=[Yodt]
    call PushRpnObject3 ; FPS=[Yodt,Xodt]; HL=Xodt
    ; calculate X epochSeconds
    ex de, hl ; DE=Xodt
    inc de ; skip type byte
    call reserveRaw9 ; FPS=[Yodt,Xodt,Xeps]; HL=Xeps
    call offsetDateTimeToEpochSeconds ; HL=Xeps filled
    ; calculate Y epochSeconds
    ex (sp), hl ; stack=[Xeps]; HL=Yodt
    ex de, hl ; DE=Yodt
    inc de ; skip type byte
    call reserveRaw9 ; FPS=[Yodt,Xodt,Xeps,Yeps]; HL=Yeps
    call offsetDateTimeToEpochSeconds ; HL=Yeps filled
    ; subtract Yeps-Xeps
    pop de ; stack=[]; DE=Xeps
    call subU40U40 ; HL=Yeps=Y-X
    ; copy result to OP1
    call popRaw9Op1 ; OP1=Yeps-Xeps
    call ConvertI40ToOP1 ; OP1=float(Y-X)
    ; clean up FPS
    call dropRaw9
    call dropRpnObject
    jp dropRpnObject

;-----------------------------------------------------------------------------

; Description: Convert the utcEpochSeconds to an epochSeconds relative to the
; given Offset, so that when that is converted to Date or DateTime, the result
; is accurate for the given Offset.
; Input:
;   - DE:(Offset*)=offset
;   - HL:(i40*)=utcEpochSeconds
; Output:
;   - DE=offset+2
;   - HL=localEpochSeconds
; Preserves: BC, DE
utcEpochSecondsToLocalEpochSeconds:
    push hl ; stack=[utcEpochSeconds]
    call reserveRaw9 ; FPS=[offset, offsetSeconds]; HL=offsetSeconds
    call offsetToSeconds ; HL=offsetSeconds updated
    ex de, hl ; DE=offsetSeconds; HL=offset+2
    ex (sp), hl ; stack=[offset+2]; HL=utcEpochSeconds
    call addU40U40 ; HL=localEpochSeconds=utcEpochSeconds+offseSeconds
    pop de ; stack=[]; DE=offset+2
    jp dropRaw9

; Description: Convert the localEpochSeconds relative to the given Offset to
; the utcEpochSeconds.
; Input:
;   - DE:(Offset*)=offset
;   - HL:(i40*)=localEpochSeconds
; Output:
;   - DE=offset+2
;   - HL=utcEpochSeconds
; Preserves: BC, DE
localEpochSecondsToUtcEpochSeconds:
    push hl ; stack=[localEpochSeconds]
    call reserveRaw9 ; FPS=[offsetSeconds]; HL=offsetSeconds
    call offsetToSeconds ; HL=offsetSeconds updated
    ex de, hl ; DE=offsetSeconds; HL=offset+2
    ex (sp), hl ; stack=[offset+2]; HL=localEpochSeconds
    call subU40U40 ; HL=utcEpochSeconds=localEpochSeconds-offsetSeconds
    pop de ; stack=[]; DE=offset+2
    jp dropRaw9
