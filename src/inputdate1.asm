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

; Description: Parse a data record of the form "{yyyy,mm,dd}" into a Date data
; record type.
; Input:
;   - HL: charPointer, C-string pointer
;   - DE: destPointer
; Output:
;   - (DE): DateRecord
;   - DE=DE+4
;   - HL=HL+12
; Throws: Err:Syntax if there is a syntax error
; Destroys: all
parseDate:
    ld a, (hl) ; should be '{'
    inc hl
    ; check for beginning '{'
    cp LlBrace
    jr nz, parseDateErr
    ; parse yyyy
    call parseU16D4
    ; check for ','
    ld a, (hl)
    inc hl
    cp ','
    jr nz, parseDateErr
    ; parse mm
    call parseU8D2
    ; check for ','
    ld a, (hl)
    inc hl
    cp ','
    jr nz, parseDateErr
    ; parse dd
    call parseU8D2
    ; check for '}'
    ld a, (hl)
    inc hl
    cp LrBrace
    jr nz, parseDateErr
    ret

parseDateErr:
    bcall(_ErrSyntax)

; Description: Parse up to 4 decimal digits at HL to a U16 at DE.
; Input:
;   - DE: destPoint
;   - HL: charPointer
; Output:
;   - (DE): u16, little endian
;   - DE: incremented by 2 bytes
;   - HL: incremented by 0-4 characters
; Destroys: A, HL
; Preserves: BC
parseU16D4:
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
;   - HL: incremented by 0-2 characters
parseU8D2:
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
