;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Set the current time zone to the Offset{} given in OP1.
; Input: OP1:Offset{}
; Output: none
SetTimeZone:
    ld hl, OP1
    ld a, (hl)
    inc hl
    cp rpnObjectTypeOffset
    jr nz, setTimeZoneErr
    ld a, (hl)
    inc hl
    ld (timeZone), a
    ld a, (hl)
    inc hl
    ld (timeZone+1), a
    ret
setTimeZoneErr:
    bcall(_ErrDataType)

; Description: Get the current time zone in OP1.
; Input: OP1:Offset{}
; Output: none
GetTimeZone:
    ld hl, OP1
    ld a, rpnObjectTypeOffset
    ld (hl), a
    inc hl
    ;
    ld a, (timeZone)
    ld (hl), a
    inc hl
    ld a, (timeZone+1)
    ld (hl), a
    inc hl
    ret
