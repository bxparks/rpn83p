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

; Description: Convert the u40 referenced by HL to a floating point number in
; OP1.
; Input: HL: pointer to u40 (must not be OP2)
; Output: OP1: floating point equivalent of u40(HL)
; Destroys: A, B, C, DE
; Preserves: HL, OP2
ConvertU40ToOP1:
    push hl
    bcall(_PushRealO2) ; FPS=[OP2 saved]
    bcall(_OP1Set0)
    pop hl
    push hl
    ld de, 4
    add hl, de ; HL points to most significant byte
    ld b, 5
convertU40ToOP1Loop:
    ld a, (hl)
    dec hl
    push bc
    call AddAToOP1
    pop bc
    djnz convertU40ToOP1Loop
    bcall(_PopRealO2) ; FPS=[]; OP2=OP2 saved
    pop hl
    ret

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

;------------------------------------------------------------------------------

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

; Description: Divide HL by BC
; Input: HL:dividend; BC=divisor
; Output: HL:quotient; DE:remainder
; Destroys: A, HL
; Preserves: BC
divHLByBC:
    ld de, 0 ; remainder=0
    ld a, 16 ; loop counter
divHLByBCLoop:
    ; NOTE: This loop could be made slightly faster by calling `scf` first then
    ; doing an `adc hl, hl` to shift a `1` into bit0 of HL. Then the `inc e`
    ; below is not required, but rather a `dec e` is required in the
    ; `divHLByBCZero` code path. Rearranging the code below would remove an
    ; extra 'jr' instruction. But I think the current code is more readable and
    ; maintainable, so let's keep it like this for now.
    add hl, hl
    ex de, hl ; DE=dividend/quotient; HL=remainder
    adc hl, hl ; shift CF into remainder
    ; remainder will never overflow, so CF=0 always here
    sbc hl, bc ; if remainder(DE) < divisor(BC): CF=1
    jr c, divHLByBCZero
divHLByBCOne:
    inc e ; set bit 0 of quotient
    jr divHLByBCNextBit
divHLByBCZero:
    add hl, bc ; add back divisor
divHLByBCNextBit:
    ex de, hl ; DE=remainder; HL=dividend/quotient
    dec a
    jr nz, divHLByBCLoop
    ret

;------------------------------------------------------------------------------

; Description: Clear the u40 pointed by HL.
; Input: HL: pointer to u40
; Destroys: none
clearU40:
    push hl
    push bc
clearU40AltEntry:
    ld bc, $0500 ; B=5; C=0
clearU40Loop:
    ld (hl), c
    inc hl
    djnz clearU40Loop
    pop bc
    pop hl
    ret

; Description: Clear the u40 pointed by BC.
; Input: BC: pointer to u40
; Destroys: none
clearU40BC:
    push hl
    push bc
    ld h, b
    ld l, c
    jr clearU40AltEntry

;------------------------------------------------------------------------------

; Description: Set u40 pointed by HL to value in A.
; Input:
;   - A: u8
;   - HL: pointer to u40
; Output:
;   - (HL)=A
; Preserves: all
setU40ToA:
    call clearU40
    ld (hl), a
    ret

; Description: Set u40 pointed by HL to u16 value in BC.
; Input:
;   - BC: u16
;   - HL: pointer to u40
; Output:
;   - u40(HL)=BC
; Preserves: all
setU40ToBC:
    push af
    push hl
    ld (hl), c
    inc hl
    ld (hl), b
    inc hl
    xor a
    ld (hl), a
    inc hl
    ld (hl), a
    inc hl
    ld (hl), a
    pop hl
    pop af
    ret

; Description: Set u40 pointed by HL to u24 value in ABC.
; Input:
;   - A: u8
;   - BC: u16
;   - HL: pointer to u40
; Output:
;   - u40(HL)=ABC
; Preserves: all
setU40ToABC:
    push af
    push hl
    ld (hl), c
    inc hl
    ld (hl), b
    inc hl
    ld (hl), a
    inc hl
    xor a
    ld (hl), a
    inc hl
    ld (hl), a
    pop hl
    pop af
    ret

;------------------------------------------------------------------------------

; Description: Add 2 u40 integers.
; Input:
;   - HL: pointer to result u40 integer in little-endian format.
;   - DE: pointer to operand u40 integer in little-endian format.
; Output:
;   - (HL) += (DE)
;   - CF=carry flag
; Destroys: A
; Preserves: BC, DE, HL, (DE)
addU40U40:
    push bc
    push de
    push hl
    ex de, hl
    ld b, 5
    or a ; CF=0
addU40U40Loop:
    ld a, (de)
    adc a, (hl)
    ld (de), a
    inc de
    inc hl
    djnz addU40U40Loop
    pop hl
    pop de
    pop bc
    ret

; Description: Add u40 to u40, u40(HL) += u40(IX)
; Output:
;   - (HL) += (IX)
;   - CF=carry flag
; Destroys: A
; Preserves: BC, DE, HL, (BC), IX
addU40U40IX:
    ; ex ix, de
    push ix
    push de
    pop ix
    pop de
    call addU40U40
    ; ex ix, de
    push ix
    push de
    pop ix
    pop de
    ret

;------------------------------------------------------------------------------

; Description: Subtract 2 u40 integers.
; Input:
;   - HL: pointer to result u40 integer in little-endian format.
;   - DE: pointer to operand u40 integer in little-endian format.
; Output:
;   - (HL) -= (DE)
;   - CF=carry flag
; Destroys: A
; Preserves: BC, DE, HL, (DE)
subU40U40:
    push bc
    push de
    push hl
    ex de, hl
    ld b, 5
    or a ; CF=0
subU40U40Loop:
    ld a, (de)
    sbc a, (hl)
    ld (de), a
    inc de
    inc hl
    djnz subU40U40Loop
    pop hl
    pop de
    pop bc
    ret

;------------------------------------------------------------------------------

; Description: Multiply u40 by u40, u40(HL) *= u40(DE). This algorithm is
; similar to the u16*u16 algorithm in
; https://tutorials.eeems.ca/Z80ASM/part4.htm, except that this implements a
; u40*u40.
; Input:
;   - HL: pointer to result u40
;   - DE: pointer to operand u40
; Output:
;   - u40(HL) *= u40(DE)
;   - CF: carry flag set if result overflowed u40
;   - A: most significant byte of u40 result (for symmetry with multU32U32())
; Destroys: A, IX
; Preserves: BC, DE, HL, (DE)
multU40U40:
    push bc ; save BC
    push hl
    pop ix ; IX=original HL
    ; Create temporary 6-byte buffer on the stack, and set it to 0.
    ld hl, 0
    push hl
    push hl
    push hl
    add hl, sp ; (HL) = (SP) = result
    ; Set up loop of 32.
    ld b, 40
    ld c, 0 ; carry flag
multU40U40Loop:
    call shiftLeftLogicalU40 ; (HL) *= 2
    jr nc, multU40U40LoopContinue
    set 0, c ; set carry bit in C register
multU40U40LoopContinue:
    ex de, hl
    call rotateLeftCircularU40; (DE) *= 2, preserving (DE) after 40 iterations
    ex de, hl
    jr nc, multU40U40NoMult
    call addU40U40IX ; (HL) += (IX)
    jr nc, multU40U40NoMult
    set 0, c ; set carry bit in C register
multU40U40NoMult:
    djnz multU40U40Loop
multU40U40End:
    ; transfer carry flag in C to CF
    ld a, c
    rra ; CF=bit0 of C
    ; copy u40(SP) to u40(original HL)
    push ix
    pop hl ; HL=IX=destination pointer
    ; extract the u40 at the top of the stack
    pop bc
    ld (hl), c
    inc hl
    ld (hl), b
    inc hl
    pop bc
    ld (hl), c
    inc hl
    ld (hl), b
    inc hl
    pop bc
    ld (hl), c ; copy the 5th byte only
    ld a, c
    ; restore HL
    dec hl
    dec hl
    dec hl
    dec hl
    ; restore BC
    pop bc
    ret

;------------------------------------------------------------------------------

; Description: Divide u40(HL) by u40(DE), remainder in u40(BC). This is an
; expanded u40 version of the "Fast 8-bit division" given in
; https://tutorials.eeems.ca/Z80ASM/part4.htm and
; https://wikiti.brandonw.net/index.php?title=Z80_Routines:Math:Division#32.2F16_division
;
; Input:
;   - HL: pointer to u40 dividend
;   - DE: pointer to u40 divisor
;   - BC: pointer to empty u40, used as remainder
; Output:
;   - HL: pointer to u40 quotient
;   - DE: divisor, unchanged
;   - BC: pointer to u40 remainder
;   - CF: 0 (division always clears the carry flag)
; Destroys: A
divU40U40:
    call clearU40BC ; clear remainder, dividend will shift into this
    ld a, 40 ; iterate for 40 bits of a u40
divU40U40Loop:
    push af ; save A loop counter
    call shiftLeftLogicalU40 ; dividend(HL) <<= 1; CF=left-most-bit
    push hl ; save HL=dividend/quotient
    ld l, c
    ld h, b ; HL=BC=remainder
    call rotateLeftCarryU40 ; rotate CF into remainder
    ;
    call cmpU40U40 ; if remainder(HL) < divisor(DE): CF=1
    jr c, divU40U40QuotientZero
divU40U40QuotientOne:
    call subU40U40 ; remainder(HL) -= divisor(DE)
    pop hl ; HL=dividend/quotient
    ; Set bit 0 of byte 0 of quotient
    set 0, (hl)
    jr divU40U40NextBit
divU40U40QuotientZero:
    pop hl ; HL=dividend/quotient
divU40U40NextBit:
    pop af
    dec a
    jr nz, divU40U40Loop
    ret

;------------------------------------------------------------------------------

; Description: Compare u40(HL) to u40(DE), returning CF=1 if u40(HL) < u40(DE),
; and ZF=1 if u40(HL) == u40(DE). The order of the parameters is the same as
; subU40U40().
; Input:
;   - HL: pointer to u40 = arg1
;   - DE: pointer to u40 = arg2
; Output:
;   - CF=1 if (HL) < (DE)
;   - ZF=1 if (HL) == (DE)
; Destroys: A
; Preserves: BC, DE, HL
cmpU40U40:
    push hl
    push de
    push bc
    ; start from most significant byte
    ld bc, 5
    add hl, bc
    ex de, hl
    add hl, bc ; HL=arg2; DE=arg1
    ; start with the most significant byte
    ld b, c ; B=5
cmpU40U40Loop:
    dec hl
    dec de
    ld a, (de)
    cp (hl) ; if arg1[i]<arg2[i]: CF=1,ZF=0; if arg1[i]==arg2[i]: ZF=1
    jr nz, cmpU40U40End
    djnz cmpU40U40Loop
cmpU40U40End:
    pop bc
    pop de
    pop hl
    ret

; Description: Shift left logical the u40 pointed by HL.
; Input:
;   - HL: pointer to u40
; Output:
;   - HL: pointer to result
;   - CF: bit 7 of most significant byte of input
; Destroys: A
; Preserves: HL
shiftLeftLogicalU40:
    push hl
    sla (hl) ; CF=bit7
    inc hl
    rl (hl) ; rotate left through CF
    inc hl
    rl (hl) ; rotate left through CF
    inc hl
    rl (hl) ; rotate left through CF
    inc hl
    rl (hl) ; rotate left through CF
    pop hl
    ret

; Description: Rotate left circular the u40 pointed by HL.
; Input:
;   - HL: pointer to u40
; Output:
;   - HL: pointer to result
;   - CF: bit 7 of most significant byte of input
; Destroys: A
; Preserves: HL
rotateLeftCircularU40:
    push hl
    sla (hl) ; start with the least significant byte
    inc hl
    rl (hl)
    inc hl
    rl (hl)
    inc hl
    rl (hl)
    inc hl
    rl (hl)
    pop hl
    ret nc
    inc (hl) ; transfer the bit 7 of byte4 into bit 0 of byte0
    ret

; Description: Rotate left carry of U40(HL).
; (baseWordSize).
; Input:
;   - HL: pointer to u40
;   - CF: the existing carry flag in bit 0
; Output:
;   - HL: pointer to result
;   - CF: most significant bit of the input
; Destroys: none
rotateLeftCarryU40:
    push hl
    rl (hl) ; start with the least signficant byte
    inc hl
    rl (hl)
    inc hl
    rl (hl)
    inc hl
    rl (hl)
    inc hl
    rl (hl)
    pop hl
    ret
