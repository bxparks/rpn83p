;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Integer functions operating on u16 stored in registers.
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
cpHLDEPageOne:
    or a ; CF=0
    push hl
    sbc hl, de
    pop hl
    ret

;------------------------------------------------------------------------------

; Description: Add A to HL.
; Input: HL, A
; Output: HL+=A
; Destroys: A
; Preserves: BC, DE
addHLByA:
    add a, l
    ld l, a
    ld a, 0
    adc a, h
    ld h, a
    ret

;------------------------------------------------------------------------------

; Description: Multiply HL by 10.
; Input: HL
; Output: HL=10*HL
; Preserves: all
multHLBy10:
    push de
    add hl, hl ; HL=2*HL
    ld d, h
    ld e, l
    add hl, hl ; HL=4*HL
    add hl, hl ; HL=8*HL
    add hl, de ; HL=10*HL
    pop de
    ret

;------------------------------------------------------------------------------

; Description: Multiply A by 10.
; Input: A
; Output: A
; Destroys: none
multABy10:
    push bc
    add a, a
    ld c, a ; C=2*A
    add a, a
    add a, a ; A=8*A
    add a, c ; A=10*A
    pop bc
    ret
