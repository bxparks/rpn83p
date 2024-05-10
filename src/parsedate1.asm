;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Functions related to parsing the inputBuf into a Date or DateTime record.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;------------------------------------------------------------------------------

; Description: Parse a string of the form "{yyyy,mm,dd}" into a Date{} record.
; Input:
;   - HL:(char*)=charPointer
;   - DE:(Date*) or (Datetime*)=dateOrDateTimePointer
; Output:
;   - (*DE):Date filled
;   - DE=DE+4
;   - HL=points to character after last '}'
; Throws: Err:Syntax if there is a syntax error
; Destroys: all
parseDate:
    call parseLeftBrace ; '{'
    call parseU16D4 ; year
    call parseComma
    call parseU8D2 ; month
    call parseComma
    call parseU8D2 ; day
    call parseRightBraceOrNul ; '}'
    ret

; Description: Parse a string of the form "{hh,mm,dd}" into a Time{} record.
; Input:
;   - HL:(char*)=charPointer
;   - DE:(Time*)=timePointer
; Output:
;   - (*DE):Time filled
;   - DE=DE+3
;   - HL=points to character after last '}'
; Throws: Err:Syntax if there is a syntax error
; Destroys: all
parseTime:
    call parseLeftBrace ; '{'
    call parseU8D2 ; hour
    call parseComma
    call parseU8D2 ; minute
    call parseComma
    call parseU8D2 ; second
    call parseRightBraceOrNul ; '}'
    ret

; Description: Parse a string of the form "{yyyy,MM,dd,hh,mm,dd}" into a
; DateTime{} record.
; Input:
;   - HL:(char*)=charPointer
;   - DE:(DateTime*)=dateTimePointer
; Output:
;   - (*DE):DateTime filled
;   - DE=DE+7
;   - HL=points to character after last '}'
; Throws: Err:Syntax if there is a syntax error
; Destroys: all
parseDateTime:
    call parseLeftBrace ; '{'
    call parseU16D4 ; year
    call parseComma
    call parseU8D2 ; month
    call parseComma
    call parseU8D2 ; day
    call parseComma
    call parseU8D2 ; hour
    call parseComma
    call parseU8D2 ; minute
    call parseComma
    call parseU8D2 ; second
    call parseRightBraceOrNul ; '}'
    ret

; Description: Parse a data record of the form "{hh,dd}" representing an offset
; from UTC into an Offset{} record.
; Input:
;   - HL:(*char)=charPointer
;   - DE:(*Offset)=offsetPointer
; Output:
;   - (*DE):Offset filled
;   - DE=DE+2
;   - HL=points to character after '}'
; Throws: Err:Syntax if there is a syntax err
; Destroys: all
parseOffset:
    call parseLeftBrace ; '{'
    call parseI8D2 ; hour
    call parseComma
    call parseI8D2 ; min
    call parseRightBraceOrNul ; '}'
    ret

; Description: Parse a string of the form "{yyyy,MM,dd,hh,mm,dd,ohh,odd}" into
; an OffsetDateTime{} record.
; Input:
;   - HL:(char*)=charPointer
;   - DE:(OffsetDateTime*)=offsetDateTimePointer
; Output:
;   - (*DE):OffsetDateTime filled
;   - DE=DE+9
;   - HL=points to character after last '}'
; Throws: Err:Syntax if there is a syntax error
; Destroys: all
parseOffsetDateTime:
    call parseLeftBrace ; '{'
    call parseU16D4 ; year
    call parseComma
    call parseU8D2 ; month
    call parseComma
    call parseU8D2 ; day
    call parseComma
    call parseU8D2 ; hour
    call parseComma
    call parseU8D2 ; minute
    call parseComma
    call parseU8D2 ; second
    call parseComma
    call parseI8D2 ; offset hour
    call parseComma
    call parseI8D2 ; offset minute
    call parseRightBraceOrNul ; '}'
    ret

; Description: Parse a string of the form "{dow}" into a DayOfWeek{}
; record.
; Input:
;   - HL:(char*)=charPointer
;   - DE:(DayOfWeek*)=dowPointer
; Output:
;   - (*DE):DayOfWeek filled
;   - DE=DE+sizeof(DayOfWeek)
;   - HL=points to character after last '}'
; Throws: Err:Syntax if there is a syntax error
; Destroys: all
parseDayOfWeek:
    call parseLeftBrace ; '{'
    call parseU8D2 ; dayOfWeek
    call parseRightBraceOrNul ; '}'
    ret

; Description: Parse a string of the form "{days,hours,minutes,seconds}" into a
; Duration{} record.
; Input:
;   - HL:(char*)=string
;   - DE:(Duration*)=duration
; Output:
;   - (*DE):Duration filled
;   - DE=DE+sizeof(Duration)
;   - HL=points to character after last '}'
; Throws: Err:Syntax if there is a syntax error
; Destroys: all
parseDuration:
    call parseLeftBrace ; '{'
    call parseI16D4 ; days
    call parseComma
    call parseI8D2 ; hours
    call parseComma
    call parseI8D2 ; minutes
    call parseComma
    call parseI8D2 ; seconds
    call parseRightBraceOrNul ; '}'
    ret

;------------------------------------------------------------------------------

recordTagTypeUnknown equ 0
recordTagTypeDate equ 1
recordTagTypeTime equ 2
recordTagTypeDateTime equ 3
recordTagTypeOffset equ 4
recordTagTypeOffsetDateTime equ 5
recordTagTypeDayOfWeek equ 6
recordTagTypeDuration equ 7

; Description: Parse the record tag letters before the '{' to determine the
; RpnRecord tag. The valid tags are:
;   - T (Time)
;   - TZ (Offset)
;   - D (Date)
;   - DT (DateTime)
;   - DZ (OffsetDateTime)
;   - DW (DayOfWeek)
;   - DR (Duration)
; Input:
;   - HL:(char*)=charPointer
; Output:
;   - A:u8=tagType
;   - HL=points to '{'
; Throws:
;   - Err:Syntax if invalid
parseRecordTag:
    ld a, (hl)
    inc hl
    ; check for T, TZ
    cp 'T'
    jr z, parseRecordTagT
    ; check for D, DT, DZ, DW, DR
    cp 'D'
    jr z, parseRecordTagD
    jr parseDateSyntaxErrr
parseRecordTagD:
    ld a, (hl)
    inc hl
    cp 'T'
    jr z, parseRecordTagDT
    cp 'Z'
    jr z, parseRecordTagDZ
    cp 'W'
    jr z, parseRecordTagDW
    cp 'R'
    jr z, parseRecordTagDR
    cp '{'
    jr nz, parseDateSyntaxErrr
    ; Just a simple 'D'
    dec hl
    ld a, recordTagTypeDate
    ret
parseRecordTagDT:
    ld a, (hl)
    inc hl
    cp '{'
    jr nz, parseDateSyntaxErrr
    dec hl
    ld a, recordTagTypeDateTime
    ret
parseRecordTagDZ:
    ld a, (hl)
    inc hl
    cp '{'
    jr nz, parseDateSyntaxErrr
    dec hl
    ld a, recordTagTypeOffsetDateTime
    ret
parseRecordTagDW:
    ld a, (hl)
    inc hl
    cp '{'
    jr nz, parseDateSyntaxErrr
    dec hl
    ld a, recordTagTypeDayOfWeek
    ret
parseRecordTagDR:
    ld a, (hl)
    inc hl
    cp '{'
    jr nz, parseDateSyntaxErrr
    dec hl
    ld a, recordTagTypeDuration
    ret
parseRecordTagT:
    ld a, (hl)
    inc hl
    cp 'Z'
    jr z, parseRecordTagTZ
    cp '{'
    jr nz, parseDateSyntaxErrr
    ; Just a simple 'T'
    dec hl
    ld a, recordTagTypeTime
    ret
parseRecordTagTZ:
    ld a, (hl)
    inc hl
    cp '{'
    jr nz, parseDateSyntaxErrr
    dec hl
    ld a, recordTagTypeOffset
    ret

;------------------------------------------------------------------------------

; Description: Count the number of commas in the input string that is supposed
; to contains a record containing '{' and '}'.
; Input: HL:(*char)=charPointer to C-string
; Output: A:u8=count
; Destroys: none
countCommas:
    push hl
    push bc
    ld b, 0
countCommasLoop:
    ld a, (hl)
    or a
    jr z, countCommasEnd
    inc hl
    cp ','
    jr nz, countCommasLoop
    inc b
    jr countCommasLoop
countCommasEnd:
    ld a, b
    pop bc
    pop hl
    ret

;------------------------------------------------------------------------------

parseDateSyntaxErrr:
    bcall(_ErrSyntax)

; Description: Parse an expected '{' character.
parseLeftBrace:
    ld a, (hl)
    inc hl
    cp LlBrace
    jr nz, parseDateSyntaxErrr
    ret

; Description: Parse an expected '}' character or the NUL terminator.
; Output: HL points to the char after the '}', or points to the NUL terminator
parseRightBraceOrNul:
    ld a, (hl)
    or a
    ret z ; HL=points to the NUL
    inc hl
    cp LrBrace
    ret z ; HL=points to the character the '}'
    jr parseDateSyntaxErrr

; Description: Parse an expected ',' character. Otherwise, throw Err:Syntax.
; Input: HL
; Output: HL
parseComma:
    ld a, (hl)
    inc hl
    cp ','
    jr nz, parseDateSyntaxErrr
    ret

;------------------------------------------------------------------------------
; String to binary parsing routines.
;------------------------------------------------------------------------------

; Description: Parse up to 4 decimal digits at HL to a u16 at DE.
; Input:
;   - DE:(u16*)=u16Pointer
;   - HL:(char*)=charPointer
; Output:
;   - (*DE):u16, little endian
;   - DE=incremented by 2 bytes
;   - HL=incremented by 0-4 characters to the next char
; Destroys: A, DE, HL
; Preserves: BC
parseU16D4:
    ; first character must be valid digit
    ld a, (hl)
    call isValidUnsignedDigit ; CF=1 is valid
    jr nc, parseDateSyntaxErrr
    ;
    push bc
    push de ; stack=[destPointer]
    ld de, 0 ; DE=sum
    ld b, 4
parseU16D4Loop:
    ld a, (hl)
    call isValidUnsignedDigit ; CF=1 is valid
    jr nc, parseU16D4End
    inc hl
    sub '0'
    ex de, hl ; HL=sum; DE=charPointer
    call multHLBy10 ; HL*=10
    call addHLByA ; HL+=A
    ex de, hl ; DE=sum=10*sum+A; HL=charPointer
    djnz parseU16D4Loop
parseU16D4End:
    ; Save u16 to destPointer
    ex (sp), hl ; stack=[charPointer]; HL=destPointer
    ld (hl), e
    inc hl
    ld (hl), d
    inc hl
    ex de, hl ; DE=destPointer
    pop hl ; HL= charPointer
    pop bc
    ret

;------------------------------------------------------------------------------

; Description: Parse optional signChar and up to 4 decimal digits at HL to an
; i16 at DE.
; Input:
;   - DE:(i16*)=i16Pointer
;   - HL:(char*)=charPointer
; Output:
;   - (*DE):i16, little endian
;   - DE=incremented by 2 bytes
;   - HL=incremented by 0-5 characters to the next char
; Destroys: A, DE, HL
; Preserves: BC
parseI16D4:
    ; first character must be valid digit or '-'
    ld a, (hl)
    cp signChar
    jr nz, parseU16D4
    ; parse the unsigned part, then negate the result.
    inc hl
    call parseU16D4 ; DE:u16
    push de
    ex de, hl
    dec hl
    dec hl
    call negI16
    ex de, hl
    pop de
    ret

; Description: Negate the i16 pointed by HL.
; Input: HL:(i16*)
; Output: (*HL)=-(*HL)
; Destroys: A
; Preserves: BC, DE, HL
negI16:
    ld a, (hl)
    neg
    ld (hl), a
    inc hl
    ;
    ld a, 0 ; cannot use 'xor a' to preserve CF
    sbc a, (hl)
    ld (hl), a
    dec hl
    ret

;------------------------------------------------------------------------------

; Description: Parse up to 2 decimal digits at HL to a u8 at DE.
; Input:
;   - DE:(u8*)=destPointer
;   - HL:(char*)=charPointer
; Output:
;   - (DE):u8
;   - DE=incremented by 1 byte
;   - HL=incremented by 0-2 characters to the next char
; Destroys: A
parseU8D2:
    ; first character must be valid digit
    ld a, (hl)
    call isValidUnsignedDigit ; CF=1 is valid
    jr nc, parseDateSyntaxErrr
    ;
    push bc
    push de
    ld de, 0 ; DE=sum
    ld b, 2
parseU8D2Loop:
    ld a, (hl)
    call isValidUnsignedDigit ; CF=1 is valid
    jr nc, parseU8D2End
    inc hl
    sub '0'
    ex de, hl
    call multHLBy10 ; sum*=10
    call addHLByA ; HL+=A
    ex de, hl ; DE=sum=10*sum+A; HL=charPointer
    djnz parseU8D2Loop
parseU8D2End:
    ; Save u8 to destPointer
    ex (sp), hl ; stack=[charPointer]; HL=destPointer
    ld (hl), e
    inc hl
    ex de, hl ; DE=destPointer
    pop hl ; HL= charPointer
    pop bc
    ret

; Description: Parse optional negative sign and up to 2 decimal digits at HL to
; an i8 at DE.
; Input:
;   - DE:(i8*)=destPoint
;   - HL:(char*)=charPointer
; Output:
;   - (DE):i8
;   - DE=incremented by 1 byte
;   - HL=incremented by 0-3 characters to the next char
; Destroys: A
parseI8D2:
    ; first character must be valid digit or '-'
    ld a, (hl)
    cp signChar
    jr nz, parseU8D2
    ; parse the unsigned part, then negate the result.
    inc hl
    call parseU8D2
    ; negate the result
    dec de
    ld a, (de)
    neg
    ld (de), a
    inc de
    ret
