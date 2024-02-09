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
; Preserves: BC, DE, HL
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

; Description: Convert the RpnOffsetDateTime{} record in OP1 to epochSeconds
; relative to the current epochDate.
; Input: OP1/OP2:RpnOffsetDateTime=input
; Output: OP1:real
; Destroys: all, OP1-OP6
RpnOffsetDateTimeToEpochSeconds:
    ; push OP1/OP2 onto the FPS, which has the side-effect of removing the
    ; 2-byte gap between OP1 and OP2
    call PushRpnObject1 ; FPS=[rpnOffsetDateTime]; HL=rpnOffsetDateTime
    ex de, hl ; DE=rpnOffsetDateTime
    call pushRaw9Op2 ; FPS=[rpnOffsetDateTime,epochSeconds]; HL=epochSeconds
    ; convert DateTime to epochSeconds, then offset to epochSeconds
    inc de ; DE=offsetDateTime, skip type byte
    ex de, hl ; DE=dateTimeSeconds; HL=offsetDateTime
    call dateTimeToEpochSeconds ; DE=dateTimeSeconds; HL+=sizeof(DateTime)
    push de ; stack=[dateTimeSeconds]
    ; convert Offset to seconds
    ex de, hl ; DE=offset
    ld hl, OP1 ; HL=OP1=offsetSeconds
    call offsetToSeconds ; HL=offsetSeconds; DE+=sizeof(Offset)
    ; add offsetSeconds to dateTimeSeconds
    ex de, hl ; DE=offsetSeconds
    pop hl ; stack=[]; HL=dateTimeSeconds
    call subU40U40 ; HL=epochSeconds=dateTimeSeconds-offsetSeconds
    ; copy back to OP1
    call popRaw9Op1 ; FPS=[rpnOffsetDateTime]; DE=OP1=epochSeconds
    call dropRpnObject ; FPS=[]
    jp ConvertI40ToOP1 ; OP1=float(OP1)

; Description: Convert the current epochSeconds (relative to the current
; epochDate) to an RpnOffsetDateTime{} record.
; Input: OP1: float(epochSeconds)
; Output: OP1: RpnDateTime
; Destroys: all, OP1-OP6
EpochSecondsToRpnOffsetDateTime:
    ; get relative epochSeconds
    call ConvertOP1ToI40 ; OP1=i40(epochSeconds)
    ; reserve 2 slots on the FPS, using RpnObject to reserve 18 bytes
    call PushRpnObject1 ; FPS=[rpnOffsetDateTime]; HL=rpnDateTime
    ex de, hl ; DE=rpnDateTime
    call pushRaw9Op1 ; FPS=[rpnOffsetDateTime,epochSeconds]; HL=epochSeconds
    ; convert to RpnDateTime
    ld a, rpnObjectTypeOffsetDateTime
    ld (de), a
    inc de ; DE=rpnOffsetDateTime+1=offsetDateTime
    call epochSecondsToDateTime ; DE=DE+sizeof(DateTime)
    ; TODO: Implement the Offset calculation. For now, just set them to 0.
    ; Convert RpnDateTime to RpnOffsetDateTime. This uses 10 bytes, which
    ; fits inside OP1 which is 11 bytes big.
    xor a
    ld (de), a
    inc de
    ld (de), a
    ; clean up FPS
    call dropRaw9
    jp PopRpnObject1 ; OP1=RpnOffsetDateTime
