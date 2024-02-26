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
    call parseRightBrace ; '}'
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
    call parseRightBrace ; '}'
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
    call parseRightBrace ; '}'
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
    call parseRightBrace ; '}'
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
    call parseRightBrace ; '}'
    ret

; Description: Parse a string of the form "{hh,mm,dd}" into a DayOfWeek{}
; record.
; Input:
;   - HL:(char*)=charPointer
;   - DE:(DayOfWeek*)=dowPointer
; Output:
;   - (*DE):DayOfWeek filled
;   - DE=DE+1
;   - HL=points to character after last '}'
; Throws: Err:Syntax if there is a syntax error
; Destroys: all
parseDayOfWeek:
    call parseLeftBrace ; '{'
    call parseU8D2 ; dayOfWeek
    call parseRightBrace ; '}'
    ret

;------------------------------------------------------------------------------

recordTagTypeUnknown equ 0
recordTagTypeDate equ 1
recordTagTypeTime equ 2
recordTagTypeDateTime equ 3
recordTagTypeOffset equ 4
recordTagTypeOffsetDateTime equ 5
recordTagTypeDayOfWeek equ 6

; Description: Parse the record tag letters before the '{' to determine the
; RpnRecord tag. The valid tags are:
;   - T (Time)
;   - TZ (Offset)
;   - D (Date)
;   - DT (DateTime)
;   - DZ (OffsetDateTime).
;   - DW (DayOfWeek)
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
    ; check for D, DT, DZ, DW
    cp 'D'
    jr z, parseRecordTagD
    jr parseDateErr
parseRecordTagD:
    ld a, (hl)
    inc hl
    cp 'T'
    jr z, parseRecordTagDT
    cp 'Z'
    jr z, parseRecordTagDZ
    cp 'W'
    jr z, parseRecordTagDW
    cp '{'
    jr nz, parseDateErr
    ; Just a simple 'D'
    dec hl
    ld a, recordTagTypeDate
    ret
parseRecordTagDT:
    ld a, (hl)
    inc hl
    cp '{'
    jr nz, parseDateErr
    dec hl
    ld a, recordTagTypeDateTime
    ret
parseRecordTagDZ:
    ld a, (hl)
    inc hl
    cp '{'
    jr nz, parseDateErr
    dec hl
    ld a, recordTagTypeOffsetDateTime
    ret
parseRecordTagDW:
    ld a, (hl)
    inc hl
    cp '{'
    jr nz, parseDateErr
    dec hl
    ld a, recordTagTypeDayOfWeek
    ret
parseRecordTagT:
    ld a, (hl)
    inc hl
    cp 'Z'
    jr z, parseRecordTagTZ
    cp '{'
    jr nz, parseDateErr
    ; Just a simple 'T'
    dec hl
    ld a, recordTagTypeTime
    ret
parseRecordTagTZ:
    ld a, (hl)
    inc hl
    cp '{'
    jr nz, parseDateErr
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

parseDateErr: ; TODO: Rename this 'parseSyntaxErr'
    bcall(_ErrSyntax)

; Description: Parse an expected '{' character,
parseLeftBrace:
    ld a, (hl)
    inc hl
    cp LlBrace
    jr nz, parseDateErr
    ret

; Description: Parse an expected '}' character,
parseRightBrace:
    ld a, (hl)
    inc hl
    cp LrBrace
    jr nz, parseDateErr
    ret

; Description: Parse an expected ',' character. Otherwise, throw Err:Syntax.
; Input: HL
; Output: HL
parseComma:
    ld a, (hl)
    inc hl
    cp ','
    jr nz, parseDateErr
    ret

; Description: Parse up to 4 decimal digits at HL to a u16 at DE.
; Input:
;   - DE:u16Pointer
;   - HL:charPointer
; Output:
;   - (DE): u16, little endian
;   - DE: incremented by 2 bytes
;   - HL: incremented by 0-4 characters to the next char
; Destroys: A, HL
; Preserves: BC
parseU16D4:
    ; first character must be valid digit
    ld a, (hl)
    call isValidUnsignedDigit ; CF=1 is valid
    jr nc, parseDateErr
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

; Description: Parse up to 2 decimal digits at HL to a u8 at DE.
; Input:
;   - DE: destPoint
;   - HL: charPointer
; Output:
;   - (DE): u8
;   - DE: incremented by 1 byte
;   - HL: incremented by 0-2 characters to the next char
; Destroys: A
parseU8D2:
    ; first character must be valid digit
    ld a, (hl)
    call isValidUnsignedDigit ; CF=1 is valid
    jr nc, parseDateErr
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
;   - DE: destPoint
;   - HL: charPointer
; Output:
;   - (DE): i8
;   - DE: incremented by 1 byte
;   - HL: incremented by 0-3 characters to the next char
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
