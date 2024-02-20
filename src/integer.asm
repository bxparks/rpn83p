;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Integer functions operating on u16 stored in registers.
;------------------------------------------------------------------------------

; Description: Non-destructive compare of (HL-DE). Same as bcall(_CpHLDE)
; without the overhead of the bcall().
; Input: HL, DE
; Output:
;   - CF=1,ZF=0 if HL<DE
;   - CF=0,ZF=1 if HL==DE
;   - CF=0,ZF=0 if HL>DE
cpHLDE:
    or a ; CF=0
    push hl
    sbc hl, de
    pop hl
    ret

; Description: Non-destructive compare of (HL-BC).
; Input: HL, DE
; Output:
;   - CF=1,ZF=0 if HL<BC
;   - CF=0,ZF=1 if HL==BC
;   - CF=0,ZF=0 if HL>BC
cpHLBC:
    or a ; CF=0
    push hl
    sbc hl, bc
    pop hl
    ret
