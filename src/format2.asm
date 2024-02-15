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
