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
    ld hl, unixEpochDate
    jr setCurrentEpochDateVar

; Description: Set epochType and epochDate to NTP (1900-01-01).
SelectNtpEpochDate:
    ld a, epochTypeNtp
    ld (epochType), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ld hl, ntpEpochDate
    jr setCurrentEpochDateVar

; Description: Set epochType and epochDate to GPS (1980-01-06).
SelectGpsEpochDate:
    ld a, epochTypeGps
    ld (epochType), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ld hl, gpsEpochDate
    jr setCurrentEpochDateVar

; Description: Set epochType and epochDate to TIOS epoch (1997-01-01).
SelectTiosEpochDate:
    ld a, epochTypeTios
    ld (epochType), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ld hl, tiosEpochDate
    jr setCurrentEpochDateVar

; Description: Set epochType and epochDate to Y2K epoch (2000-01-01).
SelectY2kEpochDate:
    ld a, epochTypeY2k
    ld (epochType), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ld hl, y2kEpochDate
    jr setCurrentEpochDateVar

; Description: Set epochType and epochDate to the customEpochDate.
SelectCustomEpochDate:
    ld a, epochTypeCustom
    ld (epochType), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ld hl, customEpochDate
    jr setCurrentEpochDateVar

;-----------------------------------------------------------------------------

; Description: Set the reference epoch to the date given in OP1.
; Input: OP1:(RpnDate*)
; Output: (epochDate) updated
SetCustomEpochDate:
    call checkOp1DatePageTwo ; ZF=1 if CP1 is an RpnDate
    jr nz, setCustomEpochDateErr
    ld hl, OP1+rpnObjectTypeSizeOf
    call setCustomEpochDateVar
    jr SelectCustomEpochDate ; automatically select the customEpochDate
setCustomEpochDateErr:
    bcall(_ErrDataType)

; Description: Get the reference epoch date into OP1.
; Input: none
; Output: OP1=epochDate
GetCustomEpochDate:
    ld a, rpnObjectTypeDate
    call setOp1RpnObjectTypePageTwo ; HL+=sizeof(type)
    ex de, hl ; DE=OP1+rpnObjectTypeSizeOf=epochDatePointer
    ld hl, customEpochDate
    ld bc, 4
    ldir
    ret

;-----------------------------------------------------------------------------

; Description: Copy the Date{} pointed by HL to (customEpochDate).
; Input: HL:(Date*)
; Output: (epochDate) updated
; Destroys: all
; Preserves: A
setCustomEpochDateVar:
    ld de, customEpochDate
    ld bc, 4
    ldir
    ret

; Description: Copy the Date{} pointed by HL to (currentEpochDate).
; Input: HL:(Date*)
; Output: (currentEpochDate) updated
; Destroys: all
; Preserves: A
setCurrentEpochDateVar:
    ld de, currentEpochDate
    ld bc, 4
    ldir
    ret

;-----------------------------------------------------------------------------

unixEpochDate:
    .dw 1970
    .db 1
    .db 1
ntpEpochDate:
    .dw 1900
    .db 1
    .db 1
gpsEpochDate:
    .dw 1980
    .db 1
    .db 6
tiosEpochDate:
    .dw 1997
    .db 1
    .db 1
y2kEpochDate:
    .dw 2000
    .db 1
    .db 1
; The custom epoch date can be modified by the user. But it has to have *some*
; factory default value. I select 2050-01-01 because that's the value used in
; my timezone libraries.
defaultCustomEpochDate:
    .dw 2050
    .db 1
    .db 1
