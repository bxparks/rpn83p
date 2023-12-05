;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Low-level routines for manipulating Pascal strings, similar to pstring.asm
; but located in Flash Page 1.
;
; This is now on Flash Page 1. Labels with Capital letters are intended to be
; exported to other flash pages and should be placed in the branch table on
; Flash Page 0. Labels with lowercase letters are intended to be private so do
; not need a branch table entry.
;-----------------------------------------------------------------------------

; Description: Append character to pascal-string buffer.
; Input:
;   A: character to be appended
;   HL: pascal string pointer
;   B: maxSize
; Output: CF set when append fails
; Destroys: all
appendStringFP1:
    ld c, a ; C = char
    ld a, (hl) ; A = bufSize
    cp b
    jr nz, appendStringFP1NotFull
    ; buffer full, set CF
    scf
    ret
appendStringFP1NotFull:
    ; Go to end of string
    inc a
    ld (hl), a
    ld d, 0
    ld e, a
    add hl, de
    ld (hl), c
    or a ; clear CF
    ret
