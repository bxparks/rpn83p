;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Low-level formatting routines.
;
; Capitalized labels are intended to be exported to the branch table on flash
; page 0. Lowercased labels are intended to be local to the current flash page.
;-----------------------------------------------------------------------------

; Description: Convert A to a string of 1 to 3 digits, with the leading '0'
; suppressed, and append at the string buffer pointed by HL. NUL terminated.
; Input: HL: pointer to string buffer
; Output: HL: pointer to NUL terminator at end of string
; Destroys: A, B, C, HL
; Preserves: DE
suppressLeadingZero equ 0 ; bit 0 of D
ConvertAToString:
    push de
    set suppressLeadingZero, d
    ; Divide by 100
    ld b, 100
    call divideAByB
    or a
    jr z, convertAToStringTen ; skip hundred's leading zero
    ; print non-zero hundred's digit
    call convertAToCharPageOne
    ld (hl), a
    inc hl
    res suppressLeadingZero, d
convertAToStringTen:
    ; Divide by 10
    ld a, b
    ld b, 10
    call divideAByB
    or a
    jr nz, convertAToStringTenPrint
    ; Check if ten's zero should be suppressed before printing.
    bit suppressLeadingZero, d ; if suppressLeadingZero: ZF=0
    jr nz, convertAToStringOne
convertAToStringTenPrint:
    call convertAToCharPageOne
    ld (hl), a
    inc hl
convertAToStringOne:
    ; Extract the 1
    ld a, b
    call convertAToCharPageOne
    ; always print the last digit regardless of suppressLeadingZero
    ld (hl), a
    inc hl
    ; ld (hl), 0 ; NUL terminated
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

; Description: Convert A into an Ascii Char ('0'-'9','A'-'F').
; Destroys: A
convertAToCharPageOne:
    cp 10
    jr c, convertAToCharPageOneDecimal
    sub 10
    add a, 'A'
    ret
convertAToCharPageOneDecimal:
    add a, '0'
    ret
