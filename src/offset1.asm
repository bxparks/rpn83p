;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; RpnOffset functions.
;-----------------------------------------------------------------------------

; Description: Convert the RpnOffset{} record in OP1 to relative seconds.
; Input: OP1:RpnOffet
; Output: OP1:real
; Destroys: all, OP1-OP4
RpnOffsetToSeconds:
    call pushRaw9Op1 ; FPS=[rpnOffset]; HL=rpnOffset
    inc hl ; HL=offset
    ex de, hl ; DE=offset
    ld hl, OP1
    call offsetToSeconds ; DE=offset+2; HL=OP1=seconds
    call dropRaw9 ; FPS=[]
    jp ConvertI40ToOP1 ; OP1=float(OP1)

;-----------------------------------------------------------------------------

; Description: Return ZF=1 if Offset{} is zero or positive.
; Input: HL=(Offset*)=pointerToOffset
; Output: ZF=1 if zero or positive
; Destroys: A
; Preserves: HL
isOffsetPos:
    ld a, (hl)
    inc hl
    or (hl)
    dec hl
    bit 7, a ; ZF=1 if both sign bits are 0
    ret

; Description: Return ZF=1 if (hh,mm) in BC is zero or positive.
; Input: BC=(hh,mm)
; Output: ZF=1 if zero or positive
; Destroys: A
isHmComponentsPos:
    ld a, b
    or c
    bit 7, a
    ret

;-----------------------------------------------------------------------------

; Description: Change sign of Offset{ohh,omm}.
; Input: HL:(Offset*)=pointerToOffset
; Output: (*HL):Offset=Offset{-ohh,-omm}.
; Destroys: A
; Preserves: HL
chsOffset:
    ld a, (hl)
    neg
    ld (hl), a
    inc hl
    ld a, (hl)
    neg
    ld (hl), a
    dec hl
    ret

;-----------------------------------------------------------------------------

; Description: Convert (hh,mm) to i40 seconds.
; Input:
;   - DE:(Offset*)=offset
;   - HL:(i40*)=seconds
; Output:
;   - DE=DE+2
;   - (*HL):i40 updated
; Destroys: A
; Preserves: BC, HL
offsetToSeconds:
    push bc ; stack=[BC]
    ex de, hl ; DE=seconds; HL=offset
    ld b, (hl)
    inc hl
    ld c, (hl)
    inc hl
    ex de, hl ; DE=offset; HL=seconds
    call isHmComponentsPos ; ZF=1 if zero or positive
    jr z, offsetToSecondsPos
offsetToSecondsNeg:
    ; negate (hh,mm)
    ld a, b
    neg
    ld b, a
    ld a, c
    neg
    ld c, a
    ;
    call hmComponentsToSeconds
    call negU40
    pop bc ; stack=[]; BC=restored
    ret
offsetToSecondsPos:
    call hmComponentsToSeconds
    pop bc ; stack=[]; BC=restored
    ret

; Description: Convert positive (hh,mm) in BC to seconds.
; Input: BC=(hh,mm)
; Output: HL:(u40*)=offsetSeconds
; Preserves: DE, HL
hmComponentsToSeconds:
    ; set hour
    ld a, b
    call setU40ToA ; u40(*HL)=A
    ; multiply by 60
    ld a, 60
    call multU40ByA ; HL=result=HL*60
    ; add minute
    ld a, c
    call addU40ByA ; HL=HL+A
    ; multiply by 60
    ld a, 60
    jp multU40ByA ; HL=HL*60

;-----------------------------------------------------------------------------
; RpnOffsetDateTime functions.
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
    call reserveRaw9 ; FPS=[rpnOffsetDateTime,reserved]
    ; convert DateTime to dateTimeSeconds
    inc de ; DE=offsetDateTime, skip type byte
    call offsetDateTimeToEpochSeconds ; HL=epochSeconds
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
; Preserves: HL
offsetDateTimeToEpochSeconds:
    ; convert DateTime to relative epochSeconds
    call dateTimeToEpochSeconds ; HL=dateTimeSeconds; DE+=sizeof(DateTime)
    push hl ; stack=[dateTimeSeconds]
    ; convert Offset to seconds in OP1
    call reserveRaw9 ; FPS=[offsetSeconds]; HL=offsetSeconds
    call offsetToSeconds ; HL=offsetSeconds; DE+=sizeof(Offset)
    ; add offsetSeconds to dateTimeSeconds
    ex de, hl ; DE=offsetSeconds; HL=offsetDateTime+9
    ex (sp), hl ; stack=[offsetDateTime+7]; HL=datetimeSeconds
    call subU40U40 ; HL=resultSeconds=dateTimeSeconds-offsetSeconds
    ; clean up stack and FPS
    pop de ; stack=[]; DE=offsetDateTime+7
    jp dropRaw9

;-----------------------------------------------------------------------------

; Description: Convert the relative epochSeconds to an RpnOffsetDateTime{}
; record.
; Input: OP1:Real=epochSeconds
; Output: OP1:RpnDateTime
; Destroys: all, OP1-OP6
EpochSecondsToRpnOffsetDateTime:
    ; get relative epochSeconds
    call ConvertOP1ToI40 ; OP1=i40(epochSeconds)
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
;   - (*HL)=offsetDateTime updated
;   - HL=HL+sizeof(OffsetDateTime)
; Destroys: all, OP1-OP6
epochSecondsToOffsetDateTime:
    push bc ; stack=[offset]
    push hl ; stack=[offset,offsetDateTime]
    push de ; stack=[offset,offsetDateTime,epochSeconds]
    ; convert offset (BC) to seconds
    call reserveRaw9 ; FPS=[offsetSeconds]; HL=offsetSeconds
    ld e, c
    ld d, b
    call offsetToSeconds ; HL=offsetSeconds updated
    ; shift the epochSeconds to the given Offset
    pop de ; stack=[offset,offsetDateTime]; DE=epochSeconds
    call addU40U40 ; HL=effEpochSeconds=offsetSeconds+epochSeconds
    ; convert effEpochSeconds to DateTime
    ex de, hl ; DE=effEpochSeconds
    pop hl ; stack=[offset]; HL=offsetDateTime
    call epochSecondsToDateTime ; HL=offsetDateTime+sizeof(DateTime)
    ; copy the given offset into OffsetDateTime.offset
    pop bc ; stack=[]; BC=offset
    ld a, (bc)
    inc bc
    ld (hl), a
    inc hl
    ;
    ld a, (bc)
    inc bc
    ld (hl), a
    inc hl
    ; cleanup FPS
    jp dropRaw9 ; FPS=[]

;-----------------------------------------------------------------------------

; Description: Add (RpnOffsetDateTime plus seconds) or (seconds plus
; RpnDateTime).
; Input:
;   - OP1:Union[RpnOffsetDateTime,RpnReal]=rpnOffsetDateTime or seconds
;   - OP3:Union[RpnOffsetDateTime,RpnReal]=rpnOffsetDateTime or seconds
; Output:
;   - OP1:RpnOffsetDateTime=RpnOffsetDateTime+seconds
;   - DE=OP1+sizeof(OffsetDateTime)
; Destroys: OP1, OP2, OP3-OP6
AddRpnOffsetDateTimeBySeconds:
    call checkOp1OffsetDateTimePageOne ; ZF=1 if CP1 is an RpnDateTime
    jr nz, addRpnOffsetDateTimeBySecondsAdd
    call cp1ExCp3PageOne ; CP1=seconds; CP3=RpnDateTime
addRpnOffsetDateTimeBySecondsAdd:
    ; CP1=seconds, CP3=RpnOffsetDateTime
    call ConvertOP1ToI40 ; HL=OP1=u40(seconds)
    call pushRaw9Op1 ; FPS=[seconds]
    push hl ; stack=[seconds]
    ; convert rpnOffsetDateTime to OP1=seconds
    call PushRpnObject3 ; FPS[seconds,rpnOffsetDateTime];
    ex de, hl ; DE=rpnOffsetDateTime
    inc de
    ld hl, OP1
    call offsetDateTimeToEpochSeconds ; HL=OP1=offsetDateTimeSeconds
    ld c, e
    ld b, d ; BC=offsetDateTime+sizeof(OffsetDateTime)
    dec bc
    dec bc ; BC:(Offset*)
    ; add seconds + dateSeconds
    ex de, hl ; DE=offsetDateTimeSeconds
    pop hl ; stack=[]; HL=FPS.seconds
    call addU40U40 ; HL=FPS.resultSeconds=offsetDateTimeSeconds+seconds
    ; convert seconds to RpnOffsetDateTime
    ex de, hl ; DE=resultSeconds
    ld hl, OP1
    ld a, rpnObjectTypeOffsetDateTime
    ld (hl), a
    inc hl ; HL:(OffsetDateTime*)=newOffsetDateTime
    call epochSecondsToOffsetDateTime ; HL=OP1+sizeof(OffsetDateTime)
    ; clean up stack and FPS
    call dropRpnObject
    jp dropRaw9
