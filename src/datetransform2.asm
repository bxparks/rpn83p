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
    ; BC=numBytesToClear; DE=offsetToBytesToClear
    ld bc, rpnObjectTypeOffsetDateTimeSizeOf-rpnObjectTypeDateTimeSizeOf
    ld de, rpnObjectTypeDateTimeSizeOf-rpnObjectTypeSizeOf
    jr transformToOffsetDateTimeClear
transformToOffsetDateTimeFromDate:
    ; BC=numBytesToClear; DE=offsetToBytesToClear
    ld bc, rpnObjectTypeOffsetDateTimeSizeOf-rpnObjectTypeDateSizeOf
    ld de, rpnObjectTypeDateSizeOf-rpnObjectTypeSizeOf
transformToOffsetDateTimeClear:
    ld a, rpnObjectTypeOffsetDateTime
    call setHLRpnObjectTypePageTwo ; HL+=sizeof(type)
    add hl, de ; HL=pointerToClearArea
    ld e, l
    ld d, h ; DE=HL=pointerToClearArea
    inc de ; DE=HL+1
    ld (hl), 0 ; clear the first byte
    dec bc ; first byte already cleared
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
    push hl
    ld a, rpnObjectTypeDate
    call setHLRpnObjectTypePageTwo ; HL+=rpnObjectTypeSizeOf
    pop hl
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
    call setHLRpnObjectTypePageTwo ; HL+=rpnObjectTypeSizeOf
    ; Move Time field into the beginning of the RpnObject. We can use the LDIR
    ; instruction because the sizeof(Date) > sizeof(Time), so no overlap
    ; occurs.
    ex de, hl ; DE=destPointer
    ld hl, rpnObjectTypeDateSizeOf-rpnObjectTypeSizeOf
    add hl, de ; HL=srcPointer=timePointer
    ld bc, rpnObjectTypeTimeSizeOf-rpnObjectTypeSizeOf
    ldir ; shift Time fields
    ; clean up stack
    pop hl ; stack=[BC,DE]; HL=rpnTime
    pop de ; stack=[BC]; DE=restored
    pop bc ; stack=[]; BC=restored
    ret
