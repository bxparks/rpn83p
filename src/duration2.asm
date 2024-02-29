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
