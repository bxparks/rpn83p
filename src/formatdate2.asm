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
    call formatU16BCToFixed4
    ; print '-' (hyphen)
    ld a, Shyphen
    ld (de), a
    inc de
    ; print 'month'
    ld a, (hl)
    inc hl
    call formatU8AToFixed2
    ; print '-' (hyphen)
    ld a, Shyphen
    ld (de), a
    inc de
    ; print 'day'
    ld a, (hl)
    inc hl
    call formatU8AToFixed2
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
    call formatU8AToFixed2
    ; print ':'
    ld a, ':'
    ld (de), a
    inc de
    ; minute
    ld a, (hl)
    inc hl
    call formatU8AToFixed2
    ; print ':'
    ld a, ':'
    ld (de), a
    inc de
    ; second
    ld a, (hl)
    inc hl
    call formatU8AToFixed2
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
    call formatU8AToFixed2
    ; print ':'
    ld a, ':'
    ld (de), a
    inc de
    ; minute
    ld a, c
    call formatU8AToFixed2
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

; Description: Format the OffsetDateTime Record in HL to DE.
; Input:
;   - HL:(const RpnOffsetDateTime*)
;   - DE:(char*)=destBuf
; Output:
;   - HL: incremented to next record field
;   - DE: points to NUL char at end of string
FormatDayOfWeek:
    ld a, (formatRecordMode)
    cp a, formatRecordModeString
    jr z, formatRpnDayOfWeekString
    ; [[fallthrough]]

formatRpnDayOfWeekRaw:
    inc hl ; skip type byte
formatDayOfWeekRaw:
    ; print "DW{"
    ld a, 'D'
    ld (de), a
    inc de
    ld a, 'W'
    ld (de), a
    inc de
    ld a, LlBrace
    ld (de), a
    inc de
    ; print the single ISO day of week number [1-7]
    ld a, (hl)
    ex de, hl ; HL=destBuf
    call FormatAToString ; HL=string(A)
    ex de, hl ; DE=destBuf
    ; print '}'
    ld a, LrBrace
    ld (de), a
    inc de
    ; add NUL
    xor a
    ld (de), a
    ret

formatRpnDayOfWeekString:
    inc hl ; skip type byte
formatDayOfWeekString:
    ld a, (hl) ; A=dayOfWeek
    ; check range
    or a
    jr z, formatDayOfWeekStringErr
    cp dayOfWeekStringsLen
    jr nc, formatDayOfWeekStringErr
formatDayOfWeekStringConvert:
    ; convert to human readable string
    ld hl, dayOfWeekStrings
    push de
    call getStringPageTwo ; HL:(const char*)=string
    pop de
    jp copyCStringPageTwo
formatDayOfWeekStringErr:
    ld a, 0
    jr formatDayOfWeekStringConvert

; ISO DayOfWeek ranges from 1-7, starting on Monday
dayOfWeekStringsLen equ 8
dayOfWeekStrings:
    .dw dayOfWeekStringErr ; 0
    .dw dayOfWeekStringMon ; 1
    .dw dayOfWeekStringTue ; 2
    .dw dayOfWeekStringWed ; 3
    .dw dayOfWeekStringThu ; 4
    .dw dayOfWeekStringFri ; 5
    .dw dayOfWeekStringSat ; 6
    .dw dayOfWeekStringSun ; 7

dayOfWeekStringErr:
    .db "<Err>", 0
dayOfWeekStringMon:
    .db "Mon", 0
dayOfWeekStringTue:
    .db "Tue", 0
dayOfWeekStringWed:
    .db "Wed", 0
dayOfWeekStringThu:
    .db "Thu", 0
dayOfWeekStringFri:
    .db "Fri", 0
dayOfWeekStringSat:
    .db "Sat", 0
dayOfWeekStringSun:
    .db "Sun", 0

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
    call formatU16BCToFlex4
    ; print ','
    ld a, ','
    ld (de), a
    inc de
    ; print 'month'
    ld a, (hl)
    inc hl
    call formatU8AToFlex2
    ; print ','
    ld a, ','
    ld (de), a
    inc de
    ; print 'day'
    ld a, (hl)
    inc hl
    call formatU8AToFlex2
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
    call formatU8AToFlex2
    ; print ','
    ld a, ','
    ld (de), a
    inc de
    ; print 'minute'
    ld a, (hl)
    inc hl
    call formatU8AToFlex2
    ; print ','
    ld a, ','
    ld (de), a
    inc de
    ; print 'second'
    ld a, (hl)
    inc hl
    call formatU8AToFlex2
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
    call formatI8AToFlex2
    ; print ','
    ld a, ','
    ld (de), a
    inc de
    ; print Offset.minute
    ld a, (hl)
    inc hl
    call formatI8AToFlex2
    ret

;-----------------------------------------------------------------------------

; Description: Format the u16 in BC into 4 fixed digits in DE.
; Input:
;   - BC:u16
;   - DE:(char*)=destPointer
; Output: DE=DE+4
; Destroys: A, BC, DE
; Preserves: HL
formatU16BCToFixed4:
    push hl ; stack=[HL]
    push de ; stack=[HL,origDestPointer]
    ld l, c
    ld h, b
    ld b, 4
    ld c, 10
formatU16BCToFixed4Loop:
    call divHLByCPageTwo ; HL=quotient; A=remainder; preserves BC, DE
    call convertAToCharPageTwo ; A=digit
    ld (de), a
    inc de
    djnz formatU16BCToFixed4Loop
    ; reverse the digits
    ex de, hl ; HL=newDestPointer
    ex (sp), hl ; stack=[HL,newDestPointer], HL=origDestPointer
    ld b, 4
    call reverseStringPageTwo
    pop de ; stack=[HL]; DE=newDestPointer
    pop hl ; stack=[]; HL=orig HL
    ret

; Description: Format the u16 in BC using up to 4 digits in DE.
; Input:
;   - BC:u16
;   - DE:(char*)=destPointer
; Output: DE=DE+4
; Destroys: A, BC, DE
; Preserves: HL
formatU16BCToFlex4:
    push hl ; stack=[HL]
    push de ; stack=[HL,origDestPointer]
    ld l, c
    ld h, b
    ld b, 0 ; numDigits=0
    ld c, 10
formatU16BCToFlex4Loop:
    call divHLByCPageTwo ; HL=quotient; A=remainder; preserves BC, DE
    call convertAToCharPageTwo ; A=digit
    ld (de), a
    inc de
    inc b ; numDigits++
    ; check for quotient==0 at the end, to print at least one '0'
    ld a, h
    or l ; ZF=1 if quotient==0
    jr nz, formatU16BCToFlex4Loop
formatU16BCToFlex4Reverse:
    ; reverse the digits, B=numDigits
    ex de, hl ; HL=newDestPointer
    ex (sp), hl ; stack=[HL,newDestPointer], HL=origDestPointer
    call reverseStringPageTwo
    pop de ; stack=[HL]; DE=newDestPointer
    pop hl ; stack=[]; HL=orig HL
    ret

;-----------------------------------------------------------------------------

; Description: Format the u8 in A using up to 2 digits in DE. Leading zero is
; suppressed.
; Input:
;   - A:u8
;   - DE:(char*)=destPointer
; Output: DE=DE+(1 or 2)
; Destroys: A, BC, DE
; Preserves: HL
formatU8AToFlex2:
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
formatU8AToFixed2:
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

; Description: Format the i8 in A using up to 2 digits in DE.
; Input:
;   - A:i8
;   - DE:(char*)=destPointer
; Output: DE=DE+2,3
; Destroys: A, BC
; Preserves: HL
formatI8AToFlex2:
    bit 7, a
    jr z, formatU8AToFlex2
    ; output a '-', then negate, and print the integer.
    push af
    ld a, signChar
    ld (de), a
    inc de
    pop af
    neg
    jr formatU8AToFlex2
