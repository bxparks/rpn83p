;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Integer functions operating on u40 or i40 stored in RAM.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
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

; Description: Copy U40 from HL to DE.
; Destroys: none
copyU40:
    push bc
    push de
    push hl
    ld bc, 5
    ldir
    pop hl
    pop de
    pop bc
    ret

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

; Description: Add A to u40 pointed by HL.
; Input:
;   - HL: pointer to u40
;   - A: u8 to add
; Output: (HL) += A
; Destroys: none
addU40ByA:
    push hl
    push bc
    ld bc, $500 ; B=5; C=0
    add a, (hl)
    jr addU40ByALoopEntry
addU40ByALoop:
    ld a, (hl)
    adc a, c ; C=0
addU40ByALoopEntry:
    ld (hl), a
    inc hl
    djnz addU40ByALoop
    pop bc
    pop hl
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

; Description: Calculate (HL) = u40(HL) * 10.
; Input:
;   - HL: pointer to a u40 integer, little-endian format
; Output:
;   - u40(HL) = u40(HL) * 10
; Destroys: A
; Preserves: BC, DE, HL
multU40By10:
    push bc
    push de
    push hl
    ; Create 6 bytes of temp U40 on the stack
    ld de, 0
    push de
    push de
    push de ; SP=tempU40
    ; copy inputU40 to tempU40
    ex de, hl ; DE=inputU40
    add hl, sp ; HL=tempU40
    ex de, hl ; DE=tempU40; HL=inputU40
    ld bc, 5
    push de
    push hl
    ldir ; tempU40=inputU40
    pop hl
    pop de
    ; (HL) = 4 * (HL)
    call shiftLeftLogicalU40 ; (HL) *= 2
    call shiftLeftLogicalU40 ; (HL) *= 2
    call addU40U40 ; (HL) += input40
    call shiftLeftLogicalU40 ; (HL)=2*(HL)=10*inputU40
    ; Remove temp U40 on stack
    pop bc
    pop bc
    pop bc
    ; Restore registers
    pop hl
    pop de
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
; Preserves: BC, DE, HL
divU40U40:
    call clearU40BC ; clear remainder, dividend will shift into this
    ld a, 40 ; iterate for 40 bits of a u40
divU40U40Loop:
    push af ; stack=[loopCounter]
    call shiftLeftLogicalU40 ; dividend(HL) <<= 1; CF=left-most-bit
    push hl ; stack=[loopCounter, dividend/quotient]
    ld l, c
    ld h, b ; HL=BC=remainder
    call rotateLeftCarryU40 ; rotate CF into remainder
    ;
    call cmpU40U40 ; if remainder(HL) < divisor(DE): CF=1
    jr c, divU40U40QuotientZero
divU40U40QuotientOne:
    call subU40U40 ; remainder(HL) -= divisor(DE)
    pop hl ; stack=[loopCounter]; HL=dividend/quotient
    ; Set bit 0 of byte 0 of quotient
    set 0, (hl)
    jr divU40U40NextBit
divU40U40QuotientZero:
    pop hl ; stack=[loopCounter]; HL=dividend/quotient
divU40U40NextBit:
    pop af ; stack=[]; A=loopCounter
    dec a
    jr nz, divU40U40Loop
    ret

;------------------------------------------------------------------------------

; Description: Perform the two's complement of the u40 integer pointed by HL.
; Input: HL:u40 pointer
; Output: HL:neg(HL)
; Destroys: A
; Preserves: BC, DE, HL
negU40:
    push hl
    push bc
    ld a, (hl)
    neg
    ld (hl), a
    ld b, 4
negU40Loop:
    inc hl
    ld a, 0 ; cannot use 'xor a' because we need to preserve CF
    sbc a, (hl)
    ld (hl), a
    djnz negU40Loop
    pop bc
    pop hl
    ret

; Description: Return ZF=1 if u40 is positive or zero, i.e. the most
; significant bit is not set.
; Input: HL:u40 pointer
; Destroys: none
isPosU40:
    push bc
    push hl
    ld bc, 4
    add hl, bc
    bit 7, (hl) ; ZF=0 if negative
    pop hl
    pop bc
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
