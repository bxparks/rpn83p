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

; Description: Negate BC.
; Destroys: A, BC
; Preserves: DE, HL
negBCPageTwo:
    ld a, c
    neg
    ld c, a
    ld a, 0
    sbc a, b
    ld b, a
    ret

; Description: Negate ABC.
; Destroys: ABC
; Preserves: DE, HL
negABCPageTwo:
    push de
    ld d, a ; save A
    ;
    ld a, c
    neg
    ld c, a
    ;
    ld a, 0
    sbc a, b
    ld b, a
    ;
    ld a, 0
    sbc a, d
    ;
    pop de
    ret

;------------------------------------------------------------------------------

; Description: Add A to HL.
; Input: HL, A
; Output: HL+=A
; Destroys: A
; Preserves: BC, DE
addHLByAPageTwo:
    add a, l
    ld l, a
    ld a, 0
    adc a, h
    ld h, a
    ret

;------------------------------------------------------------------------------

; Description: Divide HL by C
; Input: HL:dividend; C=divisor
; Output: HL:quotient; A:remainder
; Destroys: A, HL
; Preserves: BC, DE
divHLByCPageTwo:
    push bc
    xor a ; A=remainder
    ld b, 16
divHLByCPageTwoLoop:
    add hl, hl
    rla
    jr c, divHLByCPageTwoOne ; remainder overflowed, so must substract
    cp c ; if remainder(A) < divisor(C): CF=1
    jr c, divHLByCPageTwoZero
divHLByCPageTwoOne:
    sub c
    inc l ; set bit 0 of quotient
divHLByCPageTwoZero:
    djnz divHLByCPageTwoLoop
    pop bc
    ret

;------------------------------------------------------------------------------

; Description: Multiply HL by BC, overflow ignored.
; Input: HL=X; BC=Y
; Output: HL*=BC
; Preserves: BC, DE
; Destroys: A
multHLByBCPageTwo:
    push de
    ex de, hl ; DE=X
    ld hl, 0 ; sum=0
    ld a, 16
multHLByBCPageTwoLoop:
    add hl, hl ; sum*=2; CF=0
    rl e
    rl d ; shiftLeft(DE)
    jr nc, multHLByBCPageTwoNoMult
    add hl, bc ; sum+=Y
multHLByBCPageTwoNoMult:
    dec a
    jr nz, multHLByBCPageTwoLoop
    pop de
    ret

;------------------------------------------------------------------------------

; Description: Divide D by E, remainder in A.
; Input: D:dividend; E=divisor
; Output: D:quotient; A:remainder
; Destroys: A, DE
; Preserves: BC, HL
divDByEPageTwo:
    push bc
    xor a ; A=remainder
    ld b, 8
divDByEPageTwoLoop:
    sla d
    rla
    jr c, divDByEPageTwoOne ; remainder overflowed, so must substract
    cp e ; if remainder(A) < divisor(E): CF=1
    jr c, divDByEPageTwoZero
divDByEPageTwoOne:
    sub e
    inc d ; set bit 0 of quotient
divDByEPageTwoZero:
    djnz divDByEPageTwoLoop
    pop bc
    ret

;------------------------------------------------------------------------------

; Description: Divide HL by BC
; Input: HL:dividend; BC=divisor
; Output: HL:quotient; DE:remainder
; Destroys: A, HL
; Preserves: BC
divHLByBCPageTwo:
    ld de, 0 ; remainder=0
    ld a, 16 ; loop counter
divHLByBCPageTwoLoop:
    ; NOTE: This loop could be made slightly faster by calling `scf` first then
    ; doing an `adc hl, hl` to shift a `1` into bit0 of HL. Then the `inc e`
    ; below is not required, but rather a `dec e` is required in the
    ; `divHLByBCPageTwoZero` code path. Rearranging the code below would remove
    ; an extra 'jr' instruction. But I think the current code is more readable
    ; and maintainable, so let's keep it like this for now.
    add hl, hl
    ex de, hl ; DE=dividend/quotient; HL=remainder
    adc hl, hl ; shift CF into remainder
    ; remainder will never overflow, so CF=0 always here
    sbc hl, bc ; if remainder(DE) < divisor(BC): CF=1
    jr c, divHLByBCPageTwoZero
divHLByBCPageTwoOne:
    inc e ; set bit 0 of quotient
    jr divHLByBCPageTwoNextBit
divHLByBCPageTwoZero:
    add hl, bc ; add back divisor
divHLByBCPageTwoNextBit:
    ex de, hl ; DE=remainder; HL=dividend/quotient
    dec a
    jr nz, divHLByBCPageTwoLoop
    ret
