;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2025 Brian T. Park
;
; RpnDuration functions in Flash Page 1.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Change the sign of the Duration. Same as chsDuration() on Page 2
; copied to Page 1.
; Input:
;   - HL:(Duration*)=duration
; Output:
;   - (*HL)=-(*HL)
; Destroys: A
; Preserves: BC, DE, HL
chsDurationPageOne:
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


