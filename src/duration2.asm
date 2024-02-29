;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; RpnDuration functions.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Convert RpnDuration to relative seconds.
; Input: OP1:RpnDuration
; Output: OP1:real
; Destroys: all, OP1-OP4
RpnDurationToSeconds:
    call pushRaw9Op1 ; FPS=[rpnOffset]; HL=rpnOffset
    inc hl ; skip type byte
    ex de, hl ; DE=duration
    ld hl, OP1
    call durationToSeconds ; DE=duration+5; HL=OP1=seconds
    call dropRaw9 ; FPS=[]
    jp ConvertI40ToOP1 ; OP1=float(OP1)

; Description: Convert Duration to relative seconds.
; Input:
;   - DE:(Duration*)=duration
;   - HL:(i40*)=resultSeconds
; Output:
;   - DE=DE+sizeof(Duration)
;   - (*HL):i40=resultSeconds filled
; Destroys: A, OP3-4
; Preserves, BC, HL
durationToSeconds:
    ex de, hl ; HL=duration
    call isDurationNegative ; CF=1 if negative
    ex de, hl ; DE=duration
    jr nc, durationToSecondsPos
    ;
    ex de, hl ; HL=duration
    call chsDuration ; (*HL)=-(*HL)
    ex de, hl ; DE=duration
    call durationToSecondsPos
    ex de, hl ; HL=duration
    call chsDuration ; (*HL)=-(*HL)
    ex de, hl ; DE=duration
    call negU40
    ret

durationToSecondsPos:
    push bc
    call clearU40 ; resultSeconds=0
    ; read days
    ex de, hl
    ld c, (hl)
    inc hl
    ld b, (hl) ; BC=days
    inc hl
    ex de, hl
    call setU40ToBC ; HL=resultSeconds=days
    ld c, e
    ld b, d ; BC=duration, DE and HL will be used to multiply/add U40 numbers
    ld de, OP2 ; buffer for the multiplier or term
    ; multiply then add hours
    ld a, 24
    ex de, hl ; DE=resultSeconds; HL=OP2
    call setU40ToA ; HL=OP2=24
    ex de, hl ; DE=OP2=24; HL=resultSeconds
    call multU40U40 ; HL=resultSeconds=days*24
    ;
    ld a, (bc) ; A=hours
    inc bc
    ex de, hl ; DE=resultSeconds; HL=OP2
    call setU40ToA ; HL=OP2=hours
    ex de, hl ; DE=OP2; HL=resultSeconds
    call addU40U40 ; HL=resultSeconds*24+hours
    ; multiply then add minutes
    ld a, 60
    ex de, hl
    call setU40ToA
    ex de, hl
    call multU40U40 ; HL=resultSeconds=((days*24)+hours)*60
    ;
    ld a, (bc); A=minutes
    inc bc
    ex de, hl
    call setU40ToA
    ex de, hl
    call addU40U40 ; HL=resultSeconds=((days*24)+hours)*60+minutes
    ; multiply then add seconds
    ld a, 60
    ex de, hl
    call setU40ToA
    ex de, hl
    call multU40U40 ; HL=resultSeconds=(((days*24)+hours)*60+minutes)*60
    ;
    ld a, (bc); A=seconds
    inc bc
    ex de, hl
    call setU40ToA
    ex de, hl
    call addU40U40 ; HL=resultSeconds=(((days*24)+hours)*60+minutes)*60)+seconds
    ;
    pop bc
    ret

;-----------------------------------------------------------------------------

; Description: Return CF=1 if Duration is negative. CF=0 if zero or positive.
; Input:
;   - HL:(Duration*)=duration
; Output:
;   - CF=1 if negative, 0 if positive or zero
; Destroys: A
; Preserves: BC, DE, HL
isDurationNegative:
    push hl
    inc hl
    ld a, (hl) ; days
    inc hl
    bit 7, a
    jr nz, isNegativeTrue
    ;
    ld a, (hl) ; hours
    inc hl
    bit 7, a
    jr nz, isNegativeTrue
    ;
    ld a, (hl) ; minutes
    inc hl
    bit 7, a
    jr nz, isNegativeTrue
    ;
    ld a, (hl) ; seconds
    inc hl
    bit 7, a
    jr nz, isNegativeTrue
isNegativeFalse:
    pop hl
    or a
    ret
isNegativeTrue:
    pop hl
    scf
    ret

;-----------------------------------------------------------------------------

; Description: Change the sign of the RpnDuration.
; Input:
;   - OP1:(RpnDuration*)=duration
; Output:
;   - (*OP1)=-(*OP1)
; Destroys: A
; Preserves: BC, DE, HL
ChsRpnDuration:
    ld hl, OP1
    inc hl
    ; [[fallthrough]]

; Description: Change the sign of the Duration.
; Input:
;   - HL:(Duration*)=duration
; Output:
;   - (*HL)=-(*HL)
; Destroys: A
; Preserves: BC, DE, HL
chsDuration:
    push hl
    ld a, (hl)
    neg
    ld (hl), a
    inc hl
    ;
    ld a, 0
    sbc a, (hl)
    ld (hl), a ; days=-days
    inc hl
    ;
    ld a, (hl)
    neg
    ld (hl), a ; hours=-hours
    inc hl
    ;
    ld a, (hl)
    neg
    ld (hl), a ; minutes=-minutes
    inc hl
    ;
    ld a, (hl)
    neg
    ld (hl), a ; seconds=-seconds
    ;
    pop hl
    ret
