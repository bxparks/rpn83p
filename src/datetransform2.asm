;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Routines that transforms a date-related object (Date, DateTime,
; OffsetDateTime) to another date-related object, mostly by extending or
; truncating fields.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Convert RpnDate or RpnDateTime to RpnOffsetDateTime. The
; conversion is done in situ.
; Input: HL:RpnDate or RpnDateTime
; Output; HL:RpnOffsetDateTime
; Destroys: A
; Preserves: BC, DE, HL
; Throws: Err:DateType if input is the wrong type
transformToOffsetDateTime:
    ; check if already RpnOffsetDateTime
    call getHLRpnObjectTypePageTwo ; A=type
    cp rpnObjectTypeOffsetDateTime
    ret z
    ;
    push hl
    push de
    push bc
    ; check if RpnDateTime
    cp rpnObjectTypeDateTime
    jr z, transformToOffsetDateTimeFromDateTime
    ; check if RpnDate
    cp rpnObjectTypeDate
    jr z, transformToOffsetDateTimeFromDate
    bcall(_ErrDataType)
transformToOffsetDateTimeFromDateTime:
    ld bc, rpnObjectTypeDateTimeSizeOf
    jr transformToOffsetDateTimeClear
transformToOffsetDateTimeFromDate:
    ld bc, rpnObjectTypeDateSizeOf
transformToOffsetDateTimeClear:
    ld a, rpnObjectTypeOffsetDateTime
    ld (hl), a ; rpnType=OffsetDateTime
    add hl, bc ; HL=pointerToClearArea
    ex de, hl ; DE=pointerToClearArea
    ld hl, rpnObjectTypeOffsetDateTimeSizeOf
    scf; CF=1
    sbc hl, bc ; HL=numBytesToClear=rpnObjectTypeOffsetDateTimeSizeOf-sizeOf-1
    ;
    ld c, l
    ld b, h ; BC=numBytesToClear
    ld l, e
    ld h, d ; HL=pointerToClearArea
    inc de ; DE=HL+1
    ld (hl), 0 ; clear the first byte
    ldir ; clear the rest
    ;
    pop bc
    pop de
    pop hl
    ret

; Description: Convert RpnDateTime, RpnOffsetDateTime to RpnDate.
; Input: HL:(RpnDateTime*) or (RpnOffsetDateTime*)
; Output: HL:(RpnDate*)=rpnDate
; Destroys: A
; Preserves: BC, DE, HL
; Throws: Err:DateType if input is the wrong type
transformToDate:
    call getHLRpnObjectTypePageTwo ; A=type
    cp rpnObjectTypeTime
    ret z
    cp rpnObjectTypeDateTime
    jr z, transformToDateConvert
    cp rpnObjectTypeOffsetDateTime
    jr z, transformToDateConvert
    bcall(_ErrDataType)
transformToDateConvert:
    ld a, rpnObjectTypeDate
    ld (hl), a
    ret

; Description: Convert RpnDateTime, RpnOffsetDateTime to RpnTime.
; Input: HL:(RpnDateTime*) or (RpnOffsetDateTime*)
; Output: HL:(RpnTime*)=rpnTime
; Destroys: A
; Preserves: BC, DE, HL
; Throws: Err:DateType if input is the wrong type
transformToTime:
    call getHLRpnObjectTypePageTwo ; A=type
    cp rpnObjectTypeTime
    ret z
    cp rpnObjectTypeDateTime
    jr z, transformToTimeConvert
    cp rpnObjectTypeOffsetDateTime
    jr z, transformToTimeConvert
    bcall(_ErrDataType)
transformToTimeConvert:
    push bc ; stack=[BC]
    push de ; stack=[BC,DE]
    push hl ; stack=[BC,DE,rpnTime]
    ld a, rpnObjectTypeTime
    ld (hl), a
    ; move pointers to last Time field
    ld de, rpnObjectTypeDateTimeSizeOf-1
    add hl, de ; HL=last byte of old Time object
    ld e, l
    ld d, h
    dec de
    dec de
    dec de
    dec de ; DE=last byte of new Time object
    ld bc, 3
    lddr ; shift Time fields by 4 bytes to the left
    ; clean up stack
    pop hl ; stack=[BC,DE]; HL=rpnTime
    pop de ; stack=[BC]; DE=restored
    pop bc ; stack=[]; BC=restored
    ret
