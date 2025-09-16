;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Routines related to the application timezone.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Set the appTimeZone to the Offset{} or Real given in OP1. If a
; Real is given, it is converted into an Offset{}, then stored.
; Input: OP1:RpnOffset{} or Real
; Output: (appTimeZone) updated
; Destroys: BC, HL, OP3
SetAppTimeZone:
    call getOp1RpnObjectTypePageTwo ; A=type; HL=OP1
    skipRpnObjectTypeHL
    cp rpnObjectTypeOffset
    jr z, setAppTimeZoneForOffset
    cp rpnObjectTypeReal
    jr z, setAppTimeZoneForReal
setAppTimeZoneErr:
    bcall(_ErrDataType)
setAppTimeZoneForReal:
    ; convert OP1 to Offset in OP3
    ld hl, OP3
    call offsetHourToOffset ; HL:(Offset*)=OP3
setAppTimeZoneForOffset:
    ld c, (hl)
    inc hl
    ld b, (hl)
    ld (appTimeZone), bc
    ret

; Description: Get the appTimeZone into OP1.
; Input: (appTimeZone)
; Output: OP1:RpnOffset{}
; Destroys: BC, HL
GetAppTimeZone:
    ld a, rpnObjectTypeOffset
    call setOp1RpnObjectTypePageTwo ; HL=OP1+sizeof(type)
    ld bc, (appTimeZone)
    ld (hl), c
    inc hl
    ld (hl), b
    ret
