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

; Description: Multiply HL by BC, overflow ignored.
; Input: HL
; Output: HL*=BC
; Preserves: BC, DE
; Destroys: A
multHLByBC:
    push de
    ex de, hl ; DE=X
    ld hl, 0 ; sum=0
    ld a, 16
multHLByBCLoop:
    add hl, hl ; sum*=2; CF=0
    rl e
    rl d ; shiftLeft(DE)
    jr nc, multHLByBCNoMult
    add hl, bc ; sum+=X
multHLByBCNoMult:
    dec a
    jr nz, multHLByBCLoop
    pop de
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

; Description: Divide HL by C
; Input: HL:dividend; C=divisor
; Output: HL:quotient; A:remainder
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
