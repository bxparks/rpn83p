;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Format the Date Record in HL to DE.
; Input:
;   - HL:(const Date*)=date
;   - DE:(char*)
; Output:
;   - HL: incremented to next record field
;   - DE: points to NUL char at end of string
FormatDateRecord:
    inc hl ; skip type byte
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

; Description: Format the Time Record in HL to DE.
; Input:
;   - HL:(const Time*)=time
;   - DE:(char*)
; Output:
;   - HL: incremented to next record field
;   - DE: points to NUL char at end of string
FormatTimeRecord:
    inc hl ; skip type byte
    ; 'print 'D'
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
    ld (de), a ; add NUL terminator
    ret

; Description: Format the DateTime Record in HL to DE.
; Input:
;   - HL:(const DateTime*)
;   - DE:(char*)
; Output:
;   - HL: incremented to next record field
;   - DE: points to NUL char at end of string
FormatDateTimeRecord:
    inc hl ; skip type byte
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

; Description: Format the Offset Record in HL to DE. Eventually, an actual
; TimeZone object may be created. For now, the Offset object will take the
; place of the TimeZone object.
; Input:
;   - HL:(const Offset*)
;   - DE:(char*)
; Output:
;   - HL: incremented to next record field
;   - DE: points to NUL char at end of string
FormatOffsetRecord:
    inc hl ; skip type byte
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

; Description: Format the OffsetDateTime Record in HL to DE.
; Input:
;   - HL:(const OffsetDateTime*)
;   - DE:(char*)
; Output:
;   - HL: incremented to next record field
;   - DE: points to NUL char at end of string
FormatOffsetDateTimeRecord:
    inc hl ; skip type byte
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

; Description: Format the u8 in A to 2 digits in DE. Leading zero is
; suppressed.
; Input:
;   - A:u8
;   - DE:(char*)=destPointer
; Output: DE=DE+2
; Destroys: A, BC, DE
; Preserves: HL
formatU8ToD2:
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

;-----------------------------------------------------------------------------

; Description: Reverses the chars of the string referenced by HL.
; Input:
;   - HL:(char*)
;   - B:numChars
; Output: string in (HL) reversed
; Destroys: A, B, DE, HL
reverseStringPageTwo:
    ; test for 0-length string
    ld a, b
    or a
    ret z
    ; find end of string
    ld e, b
    ld d, 0
    ex de, hl
    add hl, de
    ex de, hl ; DE = DE + B = end of string
    dec de
    ; set up loop
    srl b ; B = num / 2
    ret z ; NOTE: Failing to check for this zero took 2 days to debug!
reverseStringPageTwoLoop:
    ld a, (de)
    ld c, (hl)
    ld (hl), a
    ld a, c
    ld (de), a
    inc hl
    dec de
    djnz reverseStringPageTwoLoop
    ret
