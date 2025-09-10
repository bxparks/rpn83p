;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Low-level formatting routines.
;
; Capitalized labels are intended to be exported to the branch table on flash
; page 0. Lowercased labels are intended to be local to the current flash page.
;-----------------------------------------------------------------------------

; Description: Convert A into an Ascii Char ('0'-'9','A'-'F').
; Destroys: A
convertAToCharPageTwo:
    cp 10
    jr c, convertAToCharPageTwoDecimal
    sub 10
    add a, 'A'
    ret
convertAToCharPageTwoDecimal:
    add a, '0'
    ret

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

;-----------------------------------------------------------------------------

; Description: Format integer A to a string of 1 to 3 digits, with the leading
; '0' suppressed, and append at the string buffer pointed by HL.
; Input:
;   - A:u8=input
;   - HL:(char*)=stringBuf
; Output:
;   - HL=points to NUL at end of string
; Destroys: A, B, C, HL
; Preserves: DE
suppressLeadingZero equ 0 ; bit 0 of D
FormatAToString:
    push de
    set suppressLeadingZero, d
    ; Divide by 100
    ld b, 100
    call divideAByB
    or a
    jr z, formatAToStringTen ; skip hundred's leading zero
    ; print non-zero hundred's digit
    call convertAToCharPageTwo
    ld (hl), a
    inc hl
    res suppressLeadingZero, d
formatAToStringTen:
    ; Divide by 10
    ld a, b
    ld b, 10
    call divideAByB
    or a
    jr nz, formatAToStringTenPrint
    ; Check if ten's zero should be suppressed before printing.
    bit suppressLeadingZero, d ; if suppressLeadingZero: ZF=0
    jr nz, formatAToStringOne
formatAToStringTenPrint:
    call convertAToCharPageTwo
    ld (hl), a
    inc hl
formatAToStringOne:
    ; Extract the 1
    ld a, b
    call convertAToCharPageTwo
    ; always print the last digit regardless of suppressLeadingZero
    ld (hl), a
    inc hl
    ; NUL terminate
    xor a
    ld (hl), a
    pop de
    ret

; Description: Return A / B using repeated substraction.
; Input:
;   - A: numerator
;   - B: denominator
; Output: A = A/B (quotient); B=A%B (remainder)
; Destroys: C
divideAByB:
    ld c, 0
divideAByBLoop:
    sub b
    jr c, divideAByBLoopEnd
    inc c
    jr divideAByBLoop
divideAByBLoopEnd:
    add a, b ; undo the last subtraction
    ld b, a
    ld a, c
    ret
