;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Set epochType and epochDate to UNIX (1970-01-01).
SelectUnixEpochDate:
    ld a, epochTypeUnix
    ld (epochType), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ld hl, unixDate
    jr setEpochDate

; Description: Set epochType and epochDate to NTP (1900-01-01).
SelectNtpEpochDate:
    ld a, epochTypeNtp
    ld (epochType), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ld hl, ntpDate
    jr setEpochDate

; Description: Set epochType and epochDate to GPS (1980-01-06).
SelectGpsEpochDate:
    ld a, epochTypeGps
    ld (epochType), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ld hl, gpsDate
    jr setEpochDate

; Description: Set epochType and epochDate to TIOS epoch (1997-01-01).
SelectTiosEpochDate:
    ld a, epochTypeTios
    ld (epochType), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ld hl, tiosDate
    jr setEpochDate

; Description: Set epochType and epochDate to the custom epochDate.
SelectCustomEpochDate:
    ld a, epochTypeCustom
    ld (epochType), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ld hl, epochDateCustom
    jr setEpochDate

;-----------------------------------------------------------------------------

; Description: Set the reference epoch to the date given in OP1.
; Input: OP1: RpnDate{}
; Output: (epochDate) updated
SetCustomEpochDate:
    call checkOp1DatePageOne ; ZF=1 if CP1 is an RpnDate
    jr nz, setCustomEpochDateErr
    ld hl, OP1+1
    call setEpochDateCustom
    jr SelectCustomEpochDate ; automatically select the Custom epoch date
setCustomEpochDateErr:
    bcall(_ErrDataType)

; Description: Get the reference epoch date into OP1.
; Input: none
; Output: OP1=epochDate
GetCustomEpochDate:
    ld de, OP1
    ld a, rpnObjectTypeDate
    ld (de), a
    inc de
    ld hl, epochDateCustom
    ld bc, 4
    ldir
    ret

;-----------------------------------------------------------------------------

; Description: Copy the Date{} pointed by HL to (epochDateCustom).
; Input: HL:Date{}
; Output: (epochDate) updated
; Destroys: all
; Preserves: A
setEpochDateCustom:
    ld de, epochDateCustom
    ld bc, 4
    ldir
    ret

; Description: Copy the Date{} pointed by HL to (epochDate).
; Input: HL:Date{}
; Output: (epochDate) updated
; Destroys: all
; Preserves: A
setEpochDate:
    ld de, epochDate
    ld bc, 4
    ldir
    ret

;-----------------------------------------------------------------------------

unixDate:
    .dw 1970
    .db 1
    .db 1
ntpDate:
    .dw 1900
    .db 1
    .db 1
gpsDate:
    .dw 1980
    .db 1
    .db 6
tiosDate:
    .dw 1997
    .db 1
    .db 1
y2kDate:
    .dw 2000
    .db 1
    .db 1
