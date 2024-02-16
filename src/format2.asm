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
