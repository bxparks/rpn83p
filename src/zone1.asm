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
; Input: OP1:RpnOffset{}
; Output: none
; Destroys: BC, HL
SetTimeZone:
    ld hl, OP1
    ld a, (hl)
    inc hl
    cp rpnObjectTypeOffset
    jr nz, setTimeZoneErr
    ld c, (hl)
    inc hl
    ld b, (hl)
    ld (timeZone), bc
    ret
setTimeZoneErr:
    bcall(_ErrDataType)

; Description: Get the current time zone into OP1.
; Input: OP1:RpnOffset{}
; Output: none
; Destroys: BC, HL
GetTimeZone:
    ld hl, OP1
    ld a, rpnObjectTypeOffset
    ld (hl), a
    inc hl
    ;
    ld bc, (timeZone)
    ld (hl), c
    inc hl
    ld (hl), b
    ret
