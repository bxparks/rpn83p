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

; Description: Divide HL by C
; Input: HL=dividend; C=divisor
; Output: HL=quotient; A=remainder
; Destroys: A, HL
; Preserves: BC, DE
divHLByC:
    push bc
    xor a ; A=remainder
    ld b, 16
divHLByCLoop:
    add hl, hl
    rla
    jr c, divHLByCOne ; remainder overflowed, so must substract
    cp c ; if remainder(A) < divisor(C): CF=1
    jr c, divHLByCZero
divHLByCOne:
    sub c
    inc l ; set bit 0 of quotient
divHLByCZero:
    djnz divHLByCLoop
    pop bc
    ret
