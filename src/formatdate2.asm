;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Formatting routines for various Date objects (RpnDate, RpnTime, RpnDateTime,
; RpnOffset, RpnOffsetDateTime).
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Format the Date Record in HL to DE.
; Input:
;   - HL:(const RpnDate*)=rpnDate
;   - DE:(char*)
; Output:
;   - HL: incremented to next record field
;   - DE: points to NUL char at end of string
FormatDate:
    ld a, (formatRecordMode)
    cp a, formatRecordModeString
    jr z, formatRpnDateString
    ; [[fallthrough]]

formatRpnDateRaw:
    inc hl ; skip type byte
formatDateRaw:
    ; 'print 'D'
    ld a, 'D'
    ld (de), a
    inc de
    ; print '{'
    ld a, LlBrace
    ld (de), a
    inc de
    ;
    call formatYearMonthDay
    ; print '}'
    ld a, LrBrace
    ld (de), a
    inc de
    ; add NUL
    xor a
    ld (de), a ; add NUL terminator
    ret

formatRpnDateString:
    inc hl ; skip type byte
formatDateString:
    ; print 'year'
    ld c, (hl)
    inc hl
    ld b, (hl)
    inc hl
    call formatU16ToD4
    ; print '-' (hyphen)
    ld a, Shyphen
    ld (de), a
    inc de
    ; print 'month'
    ld a, (hl)
    inc hl
    call formatU8ToD2Fixed
    ; print '-' (hyphen)
    ld a, Shyphen
    ld (de), a
    inc de
    ; print 'day'
    ld a, (hl)
    inc hl
    call formatU8ToD2Fixed
    ; add NUL
    xor a
    ld (de), a ; add NUL terminator
    ret

;-----------------------------------------------------------------------------

; Description: Format the Time Record in HL to DE.
; Input:
;   - HL:(const RpnTime*)=time
;   - DE:(char*)
; Output:
;   - HL: incremented to next record field
;   - DE: points to NUL char at end of string
FormatTime:
    ld a, (formatRecordMode)
    cp a, formatRecordModeString
    jr z, formatRpnTimeString
    ; [[fallthrough]]

formatRpnTimeRaw:
    inc hl ; skip type byte
formatTimeRaw:
    ; 'print 'T'
    ld a, 'T'
    ld (de), a
    inc de
    ; print '{'
    ld a, LlBrace
    ld (de), a
    inc de
    ;
    call formatHourMinuteSecond
    ; print '}'
    ld a, LrBrace
    ld (de), a
    inc de
    ; add NUL
    xor a
    ld (de), a
    ret

formatRpnTimeString:
    inc hl ; skip type byte
formatTimeString:
    ; hour
    ld a, (hl)
    inc hl
    call formatU8ToD2Fixed
    ; print ':'
    ld a, ':'
    ld (de), a
    inc de
    ; minute
    ld a, (hl)
    inc hl
    call formatU8ToD2Fixed
    ; print ':'
    ld a, ':'
    ld (de), a
    inc de
    ; second
    ld a, (hl)
    inc hl
    call formatU8ToD2Fixed
    ; add NUL
    xor a
    ld (de), a
    ret

;-----------------------------------------------------------------------------

; Description: Format the DateTime Record in HL to DE.
; Input:
;   - HL:(const RpnDateTime*)
;   - DE:(char*)
; Output:
;   - HL: incremented to next record field
;   - DE: points to NUL char at end of string
FormatDateTime:
    ld a, (formatRecordMode)
    cp a, formatRecordModeString
    jr z, formatRpnDateTimeString
    ; [[fallthrough]]

formatRpnDateTimeRaw:
    inc hl
formatDateTimeRaw:
    ; 'print 'DT'
    ld a, 'D'
    ld (de), a
    inc de
    ld a, 'T'
    ld (de), a
    inc de
    ; print '{'
    ld a, LlBrace
    ld (de), a
    inc de
    ;
    call formatYearMonthDay
    ; print ','
    ld a, ','
    ld (de), a
    inc de
    ;
    call formatHourMinuteSecond
    ; print '}'
    ld a, LrBrace
    ld (de), a
    inc de
    ; add NUL
    xor a
    ld (de), a ; add NUL terminator
    ret

formatRpnDateTimeString:
    inc hl ; skip type byte
formatDateTimeString:
    call formatDateString
    ; print a space
    ld a, ' '
    ld (de), a
    inc de
    ;
    call formatTimeString
    ret

;-----------------------------------------------------------------------------

; Description: Format the RpnOffset Record in HL to DE. Eventually, an actual
; TimeZone object may be created. For now, the Offset object will take the
; place of the TimeZone object.
; Input:
;   - HL:(const RpnOffset*)
;   - DE:(char*)
; Output:
;   - HL: incremented to next record field
;   - DE: points to NUL char at end of string
FormatOffset:
    ld a, (formatRecordMode)
    cp a, formatRecordModeString
    jr z, formatRpnOffsetString
    ; [[fallthrough]]

formatRpnOffsetRaw:
    inc hl ; skip type byte
formatOffsetRaw:
    ; 'print 'TZ'
    ld a, 'T'
    ld (de), a
    inc de
    ld a, 'Z'
    ld (de), a
    inc de
    ; print '{'
    ld a, LlBrace
    ld (de), a
    inc de
    ; format fields
    call formatOffsetHourMinute
    ; print '}'
    ld a, LrBrace
    ld (de), a
    inc de
    ; add NUL
    xor a
    ld (de), a ; add NUL terminator
    ret

formatRpnOffsetString:
    inc hl ; skip type byte
formatOffsetString:
    ld b, (hl) ; B=hour
    inc hl
    ld c, (hl) ; C=minute
    inc hl
    call isHmComponentsPos ; ZF=1 if zero or positive
    jr z, formatOffsetStringPos
    ; negative Offset
    call chsHmComponents
    ld a, Sdash
    jr formatOffsetStringSign
formatOffsetStringPos:
    ld a, SplusSign
formatOffsetStringSign:
    ld (de), a
    inc de
    ; hour
    ld a, b
    call formatU8ToD2Fixed
    ; print ':'
    ld a, ':'
    ld (de), a
    inc de
    ; minute
    ld a, c
    call formatU8ToD2Fixed
    ; add NUL
    xor a
    ld (de), a
    ret

;-----------------------------------------------------------------------------

; Description: Format the OffsetDateTime Record in HL to DE.
; Input:
;   - HL:(const RpnOffsetDateTime*)
;   - DE:(char*)
; Output:
;   - HL: incremented to next record field
;   - DE: points to NUL char at end of string
FormatOffsetDateTime:
    ld a, (formatRecordMode)
    cp a, formatRecordModeString
    jr z, formatRpnOffsetDateTimeString
    ; [[fallthrough]]

formatRpnOffsetDateTimeRaw:
    inc hl ; skip type byte
formatOffsetDateTimeRaw:
    ; 'print 'DZ'. Eventually, this might become a ZonedDateTime but for now,
    ; we will use the OffsetDateTime and print it as 'DZ'.
    ld a, 'D'
    ld (de), a
    inc de
    ld a, 'Z'
    ld (de), a
    inc de
    ; print '{'
    ld a, LlBrace
    ld (de), a
    inc de
    ;
    call formatYearMonthDay
    ; print ','
    ld a, ','
    ld (de), a
    inc de
    ;
    call formatHourMinuteSecond
    ; print ','
    ld a, ','
    ld (de), a
    inc de
    ;
    call formatOffsetHourMinute
    ; print '}'
    ld a, LrBrace
    ld (de), a
    inc de
    ; add NUL
    xor a
    ld (de), a ; add NUL terminator
    ret

formatRpnOffsetDateTimeString:
    inc hl ; skip type byte
formatOffsetDateTimeString:
    call formatDateTimeString
    call formatOffsetString
    ret

;-----------------------------------------------------------------------------
; Lower-level formatting routines.
;-----------------------------------------------------------------------------

; Description: Format year,month,day of HL record to C string in DE.
; Input:
;   - HL:(const Date*)
;   - DE:(char*)
; Output:
;   - HL: incremented to next record field
;   - DE: points to char after last char, no NUL
formatYearMonthDay:
    ; print 'year'
    ld c, (hl)
    inc hl
    ld b, (hl)
    inc hl
    call formatU16ToD4
    ; print ','
    ld a, ','
    ld (de), a
    inc de
    ; print 'month'
    ld a, (hl)
    inc hl
    call formatU8ToD2
    ; print ','
    ld a, ','
    ld (de), a
    inc de
    ; print 'day'
    ld a, (hl)
    inc hl
    call formatU8ToD2
    ret

; Description: Format hour,minute,second of HL to C string in DE.
; Input:
;   - HL:(const Time*)=time
;   - DE:(char*)
; Output:
;   - HL: incremented to next record field
;   - DE: points to char after last char, no NUL
formatHourMinuteSecond:
    ; print 'hour'
    ld a, (hl)
    inc hl
    call formatU8ToD2
    ; print ','
    ld a, ','
    ld (de), a
    inc de
    ; print 'minute'
    ld a, (hl)
    inc hl
    call formatU8ToD2
    ; print ','
    ld a, ','
    ld (de), a
    inc de
    ; print 'second'
    ld a, (hl)
    inc hl
    call formatU8ToD2
    ret

; Description: Format the (signed) hour and minute components of an Offset
; record in HL to C-string in DE.
; Input:
;   - HL:(const Offset*)
;   - DE:(char*)
; Output:
;   - HL: incremented to next record field
;   - DE: points to char after last char, no NUL
formatOffsetHourMinute:
    ; print Offset.hour
    ld a, (hl)
    inc hl
    call formatI8ToD2
    ; print ','
    ld a, ','
    ld (de), a
    inc de
    ; print Offset.minute
    ld a, (hl)
    inc hl
    call formatI8ToD2
    ret

;-----------------------------------------------------------------------------

; Description: Format the u16 in BC to 4 digits in DE.
; Input:
;   - BC:u16
;   - DE:(char*)=destPointer
; Output: DE=DE+4
; Destroys: A, BC, DE
; Preserves: HL
formatU16ToD4:
    push hl ; stack=[HL]
    push de ; stack=[HL,origDestPointer]
    ld l, c
    ld h, b
    ld b, 4
    ld c, 10
formatU16ToD4Loop:
    call divHLByCPageTwo ; HL=quotient; A=remainder; preserves BC
    call convertAToCharPageTwo ; A=digit
    ld (de), a
    inc de
    djnz formatU16ToD4Loop
    ; reverse the digits
    ex de, hl ; HL=newDestPointer
    ex (sp), hl ; stack=[HL,newDestPointer], HL=origDestPointer
    ld b, 4
    call reverseStringPageTwo
    pop de ; stack=[HL]; DE=newDestPointer
    pop hl ; stack=[]; HL=orig HL
    ret

; Description: Format the u8 in A to 1 or 2 digits in DE. Leading zero is
; suppressed.
; Input:
;   - A:u8
;   - DE:(char*)=destPointer
; Output: DE=DE+(1 or 2)
; Destroys: A, BC, DE
; Preserves: HL
formatU8ToD2: ; TODO: rename this to formatU8ToD2Flex().
    push hl
    ex de, hl ; HL=destPointer
    cp 10
    jr c, formatU8ToD2SingleDigit
formatU8ToD2TwoDigits:
    ld d, a
    ld e, 10
    call divDByEPageTwo ; D=quotient; A=remainder
    ; digit0
    call convertAToCharPageTwo ; A=digit
    inc hl
    ld (hl), a
    ; digit1
    call divDByEPageTwo ; D=quotient; A=remainder
    call convertAToCharPageTwo ; A=digit
    dec hl
    ld (hl), a
    inc hl
    jr formatU8ToD2End
formatU8ToD2SingleDigit:
    call convertAToCharPageTwo ; A=digit
    ld (hl), a
formatU8ToD2End:
    inc hl
    ex de, hl ; DE=destPointer+N
    pop hl
    ret

; Description: Format the u8 in A to exactly 2 digits in DE.
; Input:
;   - A:u8
;   - DE:(char*)=destPointer
; Output: DE=DE+2
; Destroys: A, BC, DE
; Preserves: HL
formatU8ToD2Fixed:
    push hl
    ex de, hl ; HL=destPointer
    ld d, a
    ld e, 10
    call divDByEPageTwo ; D=quotient; A=remainder
    ; digit0
    call convertAToCharPageTwo ; A=digit
    inc hl
    ld (hl), a
    ; digit1
    call divDByEPageTwo ; D=quotient; A=remainder
    call convertAToCharPageTwo ; A=digit
    dec hl
    ld (hl), a
    inc hl
    inc hl
    ex de, hl ; DE=destPointer+2
    pop hl
    ret

; Description: Format the i8 in A to 2 digits in DE.
; Input:
;   - A:i8
;   - DE:(char*)=destPointer
; Output: DE=DE+2,3
; Destroys: A, BC
; Preserves: HL
formatI8ToD2:
    bit 7, a
    jr z, formatU8ToD2
    ; output a '-', then negate, and print the integer.
    push af
    ld a, signChar
    ld (de), a
    inc de
    pop af
    neg
    jr formatU8ToD2
