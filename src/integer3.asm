;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2025 Brian T. Park
;
; Integer functions operating on u16 stored in registers. Similar to
; integer.asm but on Flash Page 3.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;------------------------------------------------------------------------------

; Description: Non-destructive compare of (HL-DE). Same as bcall(_CpHLDE)
; without the overhead of the bcall().
; Input: HL, DE
; Output:
;   - CF=1,ZF=0 if HL<DE
;   - CF=0,ZF=1 if HL==DE
;   - CF=0,ZF=0 if HL>DE
cpHLDEPageThree:
    or a ; CF=0
    push hl
    sbc hl, de
    pop hl
    ret
