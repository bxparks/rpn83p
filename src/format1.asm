;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Format the u16 in BC to 4 digits in DE.
; Input: BC:u16; DE:destPointer
; Output: DE=DE+4
; Destroys: A, BC
; Preserves: HL
FormatU16ToD4:
    push hl ; stack=[HL]
    push de ; stack=[HL,origDestPointer]
    ld l, c
    ld h, b
    ld b, 4
    ld c, 10
formatU16ToD4Loop:
    call divHLByC ; HL=quotient; A=remainder; preserves BC
    call convertAToCharPageOne ; A=digit
    ld (de), a
    inc de
    djnz formatU16ToD4Loop
    ; reverse the digits
    ex de, hl ; HL=newDestPointer
    ex (sp), hl ; stack=[HL,newDestPointer], HL=origDestPointer
    ld b, 4
    call reverseStringPageOne
    pop de ; stack=[HL]; DE=newDestPointer
    pop hl ; stack=[]; HL=orig HL
    ret

; Description: Format the u16 in BC to 4 digits in DE.
; Input: A:u8; DE:destPointer
; Output: DE=DE+2
; Destroys: A, BC
; Preserves: HL
FormatU8ToD2:
    push hl
    ld l, a
    ld h, 0
    ld c, 10
    ; digit0
    call divHLByC ; HL=quotient; A=remainder; preserves BC
    call convertAToCharPageOne ; A=digit
    inc de
    ld (de), a
    ; digit1
    call divHLByC ; HL=quotient; A=remainder; preserves BC
    call convertAToCharPageOne ; A=digit
    dec de
    ld (de), a
    ; Set DE to just after the 2 digits
    inc de
    inc de ; DE=newDestPointer
    pop hl
    ret

; Description: Format the Date Record in HL to DE.
; Input:
;   - HL: dateRecordPointer
;   - DE: stringBufPointer
; Output:
;   (DE): updated, no NUL
;   DE: points to char after last digit
FormatDateRecord:
    inc hl ; skip type byte
    ; print '{'
    ld a, LlBrace
    ld (de), a
    inc de
    ; print 'year'
    ld c, (hl)
    inc hl
    ld b, (hl)
    inc hl
    call FormatU16ToD4
    ; print ','
    ld a, ','
    ld (de), a
    inc de
    ; print 'month'
    ld a, (hl)
    inc hl
    call FormatU8ToD2
    ; print ','
    ld a, ','
    ld (de), a
    inc de
    ; print 'day'
    ld a, (hl)
    inc hl
    call FormatU8ToD2
    ; print '}'
    ld a, LrBrace
    ld (de), a
    inc de
    ret

;-----------------------------------------------------------------------------

; Description: Reverses the chars of the string referenced by HL.
; Input:
;   - HL: pointer to array of characters
;   - B: number of characters
; Output: string in (HL) reversed
; Destroys: A, B, DE, HL
reverseStringPageOne:
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
reverseStringPageOneLoop:
    ld a, (de)
    ld c, (hl)
    ld (hl), a
    ld a, c
    ld (de), a
    inc hl
    dec de
    djnz reverseStringPageOneLoop
    ret
