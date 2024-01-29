;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Functions related to parsing the inputBuf into a Date or DateTime record.
;
; This is on Flash Page 1. Labels with Capital letters are intended to be
; exported to other flash pages and should be placed in the branch table on
; Flash Page 0. Labels with lowercase letters are intended to be private so do
; not need a branch table entry.
;------------------------------------------------------------------------------

; Description: Parse a data record of the form "{yyyy,mm,dd}" into an Date{} or
; DateTime{} record type.
; Input:
;   - HL: charPointer, C-string pointer
;   - DE: pointer to buffer that can hold a Date{} or DateTime{}
; Output:
;   - A: rpnObjectTypeDate or rpnObjectTypeDateTime
;   - (DE): Date{} or DateTime{}
;   - DE=DE+4 or DE+7
;   - HL=points to character after last '}'
; Throws: Err:Syntax if there is a syntax error
; Destroys: all
parseDateOrDateTime:
    call parseLeftBrace ; '{'
    call parseU16D4 ; year
    call parseComma
    call parseU8D2 ; month
    call parseComma
    call parseU8D2 ; day
    ; check if the next character is ',' or '}'
    ld a, (hl)
    cp ','
    jr z, parseDateTime
    ; terminate with just a Date
    call parseRightBrace ; '}'
    ld a, rpnObjectTypeDate
    ret
parseDateTime:
    call parseComma
    call parseU8D2 ; hour
    call parseComma
    call parseU8D2 ; minute
    call parseComma
    call parseU8D2 ; second
    call parseRightBrace ; '}'
    ld a, rpnObjectTypeDateTime
    ret

;------------------------------------------------------------------------------

parseDateErr:
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

; Description: Parse up to 4 decimal digits at HL to a U16 at DE.
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

; Description: Parse up to 2 decimal digits at HL to a U8 at DE.
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
