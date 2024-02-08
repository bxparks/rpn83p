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
    ld de, OP1+1
    ld hl, OP3 ; cannot be OP2
    call hmToSeconds ; HL=OP3=(i40*)=seconds
    call ConvertI40ToOP1 ; OP1=float(OP3); HL cannot be OP2
    ret

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

; Description: Convert Offset(hh,mm) to i40 seconds.
; Input:
;   - DE:(Offset*)=offsetPointer
;   - HL:(i40*)=result
; Output:
;   - (*HL):i40 updated
;   - DE=DE+2
; Destroys: A, DE
; Preserves: BC, HL
hmToSeconds:
    ex de, hl ; DE=result; HL=offsetPointer
    call isOffsetPos ; ZF=1 if zero or positive
    ex de, hl ; DE=offsetPointer; HL=result
    jr z, hmToSecondsPos
hmToSecondsNeg:
    ex de, hl ; DE=result; HL=offsetPointer
    call chsOffset ; change sign of Offset
    ex de, hl ; DE=offsetPointer; HL=result
    call hmToSecondsPos
    call negU40
    ret

; Description: Convert (hh,mm) into seconds.
; Input:
;   - DE:(Offset*)=offset
;   - HL:(u40*)=result
; Output:
;   - DE=DE+2
;   - (*HL) updated
; Destroys: A
; Preserves: BC
hmToSecondsPos:
    ; read hour
    ld a, (de)
    inc de
    call setU40ToA ; u40(*HL)=A
    ; multiply by 60
    ld a, 60
    call multU40ByA ; HL=result=HL*60
    ; add minute
    ld a, (de)
    inc de
    call addU40ByA ; HL=HL+A
    ; multiply by 60
    ld a, 60
    jp multU40ByA ; HL=HL*60

;-----------------------------------------------------------------------------
; RpnOffsetDateTime functions.
;-----------------------------------------------------------------------------

; Description: Convert the RpnDateTime{} record in OP1 to epochSeconds relative
; to the current epochDate.
; Input: OP1/OP2:RpnOffsetDateTime=input
; Output: OP1:real
; Destroys: all, OP1-OP6
RpnOffsetDateTimeToEpochSeconds:
    call shrinkOp2ToOp1PageOne
    ld hl, OP1
    call convertToOffsetDateTime ; preserves HL
    call dateTimeToEpochSeconds ; OP3=dateTimeSeconds
    ;
    ld de, OP1+rpnObjectTypeDateTimeSizeOf ; DE:(Offset*)
    ld hl, OP4
    call hmToSeconds ; OP4:i40=offsetSeconds
    ;
    ld hl, OP3
    ld de, OP4
    call subU40U40 ; HL:(u40*)=OP3=dateTimeSeconds-offsetSeconds
    jp ConvertI40ToOP1 ; OP1=float(OP3)

; Description: Convert the current epochSeconds (relative to the current
; epochDate) to an RpnOffsetDateTime{} record.
; Input: OP1: float(epochSeconds)
; Output: OP1: RpnDateTime
; Destroys: all, OP1-OP6
EpochSecondsToRpnOffsetDateTime:
    ; get relative epochSeconds
    call ConvertOP1ToI40 ; OP1=i40(epochSeconds)
    ; convert relative epochSeconds to internal epochSeconds
    ld hl, epochDate
    ld de, OP2
    call dateToInternalEpochDays ; DE=OP2=epochDays
    ex de, hl ; HL=OP2=epochDays
    call convertU40DaysToU40Seconds ; HL=OP2=epochSeconds
    ld de, OP1
    call addU40U40 ; HL=OP2=internal epochSeconds
    ; convert internal epochSeconds to RpnDateTime
    ld hl, OP2
    ld de, OP1
    ld a, rpnObjectTypeOffsetDateTime
    ld (de), a
    inc de
    call internalEpochSecondsToDateTime ; DE=OP1+sizeof(RpnDateTime)
    ; Convert RpnDateTime to RpnOffsetDateTime. This uses 10 bytes, which
    ; fits inside OP1 which is 11 bytes big.
    ; TODO: Implement the Offset calcualtion. For now, just set them to 0.
    xor a
    ld (de), a
    inc de
    ld (de), a
    jp expandOp1ToOp2PageOne
