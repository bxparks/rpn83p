;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Routines related to timezones. Timezones are implemented as fixed UTC offsets
; although it is probably possible to support IANA TZDB in the future, with a
; lot of work.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Set the current time zone to the Offset{} or Real given in OP1.
; If a Real is given, it is converted into an Offset{}, then stored.
; Input: OP1:RpnOffset{} or Real
; Output: none
; Destroys: BC, HL
SetTimeZone:
    ld hl, OP1
    ld a, (hl)
    and $1f
    inc hl
    cp rpnObjectTypeOffset
    jr z, setTimeZoneForOffset
    cp rpnObjectTypeReal
    jr z, setTimeZoneForReal
setTimeZoneErr:
    bcall(_ErrDataType)
setTimeZoneForReal:
    ; convert OP1 to RpnOffset
    ld hl, OP3
    call offsetHourToOffset
setTimeZoneForOffset:
    ld c, (hl)
    inc hl
    ld b, (hl)
    ld (timeZone), bc
    ret

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
