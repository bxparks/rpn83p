;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Routines related to u32 stored as 4 bytes in little endian format.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Shift and rotate operations.
;-----------------------------------------------------------------------------

; Description: Call the appropriate shiftLeftLogicalLeftUXX() depending on
; (baseWordSize).
shiftLeftLogical:
    call getBaseOffset
    or a
    jr z, shiftLeftLogicalU8
    dec a
    jr z, shiftLeftLogicalU16
    dec a
    jr z, shiftLeftLogicalU24
    ; [[fallthrough]]

; Description: Shift u32(HL) left by one bit. Same calculation as u32(HL) =
; u32(HL) * 2.
; Input:
;   - HL: pointer to a u32 integer in little-endian format.
; Output:
;   - u32 pointed by HL is doubled
;   - CF: bit 7 of the most significant byte of input
; Destroys: none
shiftLeftLogicalU32:
    push hl
    sla (hl) ; CF=bit7
    inc hl
    rl (hl) ; rotate left through CF
    inc hl
    rl (hl) ; rotate left through CF
    inc hl
    rl (hl) ; rotate left through CF
    pop hl
    ret

shiftLeftLogicalU24:
    sla (hl) ; CF=bit7
    inc hl
    rl (hl) ; rotate left through CF
    inc hl
    rl (hl) ; rotate left through CF
    dec hl
    dec hl
    ret

shiftLeftLogicalU16:
    sla (hl) ; CF=bit7
    inc hl
    rl (hl) ; rotate left through CF
    dec hl
    ret

shiftLeftLogicalU8:
    sla (hl) ; CF=bit7
    ret

;-----------------------------------------------------------------------------

; Description: Call the appropriate shiftRightLogicalUXX() depending on
; (baseWordSize).
shiftRightLogical:
    call getBaseOffset
    or a
    jr z, shiftRightLogicalU8
    dec a
    jr z, shiftRightLogicalU16
    dec a
    jr z, shiftRightLogicalU24
    ; [[fallthrough]]

; Description: Shift u32(HL) right logical.
; Input: HL: pointer to u32
; Output:
;   - HL: pointer result
;   - CF: bit 0 of the least signficant byte of input
; Destroys: none
shiftRightLogicalU32:
    inc hl
    inc hl
    inc hl ; HL = byte 3
    srl (hl) ; CF = least significant bit
    dec hl ; HL = byte 2
    rr (hl)
    dec hl ; HL = byte 1
    rr (hl)
    dec hl ; HL = byte 0
    rr (hl)
    ret

shiftRightLogicalU24:
    inc hl
    inc hl ; HL = byte 2
    srl (hl) ; CF = least significant bit
    dec hl ; HL = byte 1
    rr (hl)
    dec hl ; HL = byte 0
    rr (hl)
    ret

shiftRightLogicalU16:
    inc hl ; HL = byte 1
    srl (hl) ; CF = least significant bit
    dec hl ; HL = byte 0
    rr (hl)
    ret

shiftRightLogicalU8:
    srl (hl) ; CF = least significant bit
    ret

;-----------------------------------------------------------------------------

; Description: Call the appropriate shiftRightArithmeticUXX() depending on
; (baseWordSize).
shiftRightArithmetic:
    call getBaseOffset
    or a
    jr z, shiftRightArithmeticU8
    dec a
    jr z, shiftRightArithmeticU16
    dec a
    jr z, shiftRightArithmeticU24
    ; [[fallthrough]]

; Description: shift u32(HL) right arithmetic, duplicating the sign bit.
; Input: HL: pointer to u32
; Output:
;   - HL: pointer result
;   - CF: bit 0 of the least signficant byte of input
; Destroys: none
shiftRightArithmeticU32:
    inc hl
    inc hl
    inc hl ; HL = byte 3
    sra (hl) ; CF = least significant bit
    dec hl ; HL = byte 2
    rr (hl)
    dec hl ; HL = byte 1
    rr (hl)
    dec hl ; HL = byte 0
    rr (hl)
    ret

shiftRightArithmeticU24:
    inc hl
    inc hl ; HL = byte 2
    sra (hl) ; CF = least significant bit
    dec hl ; HL = byte 1
    rr (hl)
    dec hl ; HL = byte 0
    rr (hl)
    ret

shiftRightArithmeticU16:
    inc hl ; HL = byte 1
    sra (hl) ; CF = least significant bit
    dec hl ; HL = byte 0
    rr (hl)
    ret

shiftRightArithmeticU8:
    sra (hl) ; CF = least significant bit
    ret

;-----------------------------------------------------------------------------

; Description: Call the appropriate rotateLeftCircularUXX() depending on
; (baseWordSize).
; Input:
;   - HL: pointer to u32
; Output:
;   - HL: pointer to result
;   - CF: bit 7 of most significant byte of input
rotateLeftCircular:
    call getBaseOffset
    or a
    jr z, rotateLeftCircularU8
    dec a
    jr z, rotateLeftCircularU16
    dec a
    jr z, rotateLeftCircularU24
    ; [[fallthrough]]

; Description: Rotate left circular u32(HL).
; Input:
;   - HL: pointer to u32
; Output:
;   - HL: pointer to result
;   - CF: bit 7 of most significant byte of input
; Destroys: none
rotateLeftCircularU32:
    push hl
    sla (hl) ; start with the least significant byte
    inc hl
    rl (hl)
    inc hl
    rl (hl)
    inc hl
    rl (hl)
    pop hl
    ret nc
    inc (hl) ; transfer the bit 7 of byte 3 into bit 0 of byte 0
    ret

rotateLeftCircularU24:
    sla (hl) ; start with the least significant byte
    inc hl
    rl (hl)
    inc hl
    rl (hl)
    dec hl
    dec hl
    ret nc
    inc (hl) ; transfer the bit 7 of byte 3 into bit 0 of byte 0
    ret

rotateLeftCircularU16:
    sla (hl) ; start with the least significant byte
    inc hl
    rl (hl)
    dec hl
    ret nc
    inc (hl) ; transfer the bit 7 of byte 3 into bit 0 of byte 0
    ret

rotateLeftCircularU8:
    rlc (hl)
    ret

;-----------------------------------------------------------------------------

; Description: Call the appropriate rotateRightCircularUXX() depending on
; (baseWordSize).
rotateRightCircular:
    call getBaseOffset
    or a
    jr z, rotateRightCircularU8
    dec a
    jr z, rotateRightCircularU16
    dec a
    jr z, rotateRightCircularU24
    ; [[fallthrough]]

; Description: Rotate right circular u32(HL).
; Input:
;   - HL: pointer to u32
; Output:
;   - HL: pointer to result
;   - CF: bit 0 of least significant byte of input
; Destroys: none
rotateRightCircularU32:
    push bc
    ld b, (hl) ; save byte 0
    inc hl
    inc hl
    inc hl ; start with byte 3
    rr b ; extract bit 0 of byte 0
    rr (hl)
    dec hl
    rr (hl)
    dec hl
    rr (hl)
    dec hl
    rr (hl) ; CF = bit 0 of byte 0
    pop bc
    ret

rotateRightCircularU24:
    push bc
    ld b, (hl) ; save byte 0
    inc hl
    inc hl ; start with byte 2
    rr b ; extract bit 0 of byte 0
    rr (hl)
    dec hl
    rr (hl)
    dec hl
    rr (hl) ; CF = bit 0 of byte 0
    pop bc
    ret

rotateRightCircularU16:
    push bc
    ld b, (hl) ; save byte 0
    inc hl ; start with byte 1
    rr b ; extract bit 0 of byte 0
    rr (hl)
    dec hl
    rr (hl) ; CF = bit 0 of byte 0
    pop bc
    ret

rotateRightCircularU8:
    rrc (hl)
    ret

;-----------------------------------------------------------------------------

; Description: Call the appropriate rotateLeftCarryUXX() depending on
; (baseWordSize).
; Destroys: A, C
rotateLeftCarry:
    rl c ; save CF
    call getBaseOffset
    or a
    jr z, rotateLeftCarryU8Alt
    dec a
    jr z, rotateLeftCarryU16Alt
    dec a
    jr z, rotateLeftCarryU24Alt
    ; [[fallthrough]]

rotateLeftCarryU32Alt:
    rr c
; Description: Rotate left u32(HL) through carry flag.
; Input:
;   - HL: pointer to u32
;   - CF: the existing carry flag in bit 0
; Output:
;   - HL: pointer to result
;   - CF: most significant bit of the input
; Destroys: none
rotateLeftCarryU32:
    push hl
    rl (hl) ; start with the least signficant byte
    inc hl
    rl (hl)
    inc hl
    rl (hl)
    inc hl
    rl (hl)
    pop hl
    ret

rotateLeftCarryU24Alt:
    rr c
rotateLeftCarryU24:
    rl (hl) ; start with the least signficant byte
    inc hl
    rl (hl)
    inc hl
    rl (hl)
    dec hl
    dec hl
    ret

rotateLeftCarryU16Alt:
    rr c
rotateLeftCarryU16:
    rl (hl) ; start with the least signficant byte
    inc hl
    rl (hl)
    dec hl
    ret

rotateLeftCarryU8Alt:
    rr c
rotateLeftCarryU8:
    rl (hl) ; start with the least signficant byte
    ret

;-----------------------------------------------------------------------------

; Description: Call the appropriate rotateRightCarryUXX() depending on
; (baseWordSize).
; Destroys: A, C
rotateRightCarry:
    rl c ; save CF
    call getBaseOffset
    or a
    jr z, rotateRightCarryU8Alt
    dec a
    jr z, rotateRightCarryU16Alt
    dec a
    jr z, rotateRightCarryU24Alt
    ; [[fallthrough]]

rotateRightCarryU32Alt:
    rr c
; Description: Rotate right u32(HL) through carry flag.
; Input:
;   - HL: pointer to u32
;   - CF: existing carry flag
; Output:
;   - HL: pointer to result
;   - CF: the least significant bit of input
; Destroys: none
rotateRightCarryU32:
    inc hl
    inc hl
    inc hl ; start with byte 3
    rr (hl)
    dec hl
    rr (hl)
    dec hl
    rr (hl)
    dec hl
    rr (hl)
    ret

rotateRightCarryU24Alt:
    rr c
rotateRightCarryU24:
    inc hl
    inc hl ; start with byte 2
    rr (hl)
    dec hl
    rr (hl)
    dec hl
    rr (hl)
    ret

rotateRightCarryU16Alt:
    rr c
rotateRightCarryU16:
    inc hl ; start with byte 1
    rr (hl)
    dec hl
    rr (hl)
    ret

rotateRightCarryU8Alt:
    rr c
rotateRightCarryU8:
    rr (hl)
    ret

;-----------------------------------------------------------------------------
; Arithmetic operations.
;-----------------------------------------------------------------------------

; Description: Calculate (HL) = u32(HL) * 10.
; Input:
;   - HL: pointer to a u32 integer, little-endian format
; Output:
;   - u32(HL) = u32(HL) * 10
; Destroys: A
; Preserves: BC, DE, HL
multU32By10:
    push bc
    push de
    push hl

    ; BCDE = u32(HL), save original (HL). Using (BC, DE) to hold the original
    ; u32(HL) allows this routine to be implemented without the need of a
    ; temporary u32 memory area. That makes the calling code of this routine a
    ; little bit cleaner.
    ld c, (hl)
    inc hl
    ld b, (hl)
    inc hl
    ld e, (hl)
    inc hl
    ld d, (hl)
    pop hl

    ; (HL) = 4 * (HL)
    call shiftLeftLogicalU32 ; (HL) *= 2
    call shiftLeftLogicalU32 ; (HL) *= 2

    ; (HL) += (original HL). This step is quite lengthy because it is using
    ; four 8-bit operations to add two u32 integers. Maybe there's a more
    ; clever way of doing this, for example, allocating 4 bytes on the stack,
    ; then using the 16-bit 'add hl' and 'adc hl' instructions.
    push hl
    ld a, (hl)
    add a, c
    ld (hl), a
    inc hl
    ;
    ld a, (hl)
    adc a, b
    ld (hl), a
    inc hl
    ;
    ld a, (hl)
    adc a, e
    ld (hl), a
    inc hl
    ;
    ld a, (hl)
    adc a, d
    ld (hl), a
    pop hl

    call shiftLeftLogicalU32 ; (HL) = 2 * (HL) = 10 * (original HL)

    pop de
    pop bc
    ret

multUxxUxx:
    call getBaseOffset
    or a
    jr z, multU8U8
    dec a
    jr z, multU16U16
    dec a
    jr z, multU24U24
    ; [[fallthrough]]

; Description: Multiply u32 by u32, u32(HL) *= u32(DE). This algorithm is
; similar to the u16*u16 algorithm in
; https://tutorials.eeems.ca/Z80ASM/part4.htm, except that this implements a
; u32*u32.
; Input:
;   - HL: pointer to result u32
;   - DE: pointer to operand u32
; Output:
;   - u32(HL) *= u32(DE)
;   - CF: carry flag set if result overflowed U32
;   - A: most significant byte of u32 result (used by multU24U24)
; Destroys: A, IX
; Preserves: BC, DE, HL, (DE)
multU32U32:
    push bc ; save BC
    push hl
    pop ix ; IX=original HL
    ; Create temporary 4-byte buffer on the stack, and set it to 0.
    ld hl, 0
    push hl
    push hl
    add hl, sp ; (HL) = (SP) = result
    ; Set up loop of 32.
    ld b, 32
    ld c, 0 ; carry flag
multU32U32Loop:
    call shiftLeftLogicalU32 ; (HL) *= 2
    jr nc, multU32U32LoopContinue
    set 0, c ; set carry bit in C register
multU32U32LoopContinue:
    ex de, hl
    call rotateLeftCircularU32; (DE) *= 2, preserving (DE) after 32 iterations
    ex de, hl
    jr nc, multU32U32NoMult
    call addU32U32IX ; (HL) += (IX)
    jr nc, multU32U32NoMult
    set 0, c ; set carry bit in C register
multU32U32NoMult:
    djnz multU32U32Loop
multU32U32End:
    ; transfer carry flag in C to CF
    ld a, c
    rra ; CF=bit0 of C
    ; copy u32(SP) to u32(original HL)
    push ix
    pop hl ; HL=IX=destination pointer
    ; extract the u32 at the top of the stack
    pop bc
    ld (hl), c
    inc hl
    ld (hl), b
    inc hl
    pop bc
    ld (hl), c
    inc hl
    ld (hl), b
    ld a, b
    ; restore HL
    dec hl
    dec hl
    dec hl
    ; restore BC
    pop bc
    ret

; Description: Multiply u24 by u24, u24(HL) *= u24(DE). This algorithm is
; similar to the u16*u16 algorithm in
; https://tutorials.eeems.ca/Z80ASM/part4.htm, except that this implements a
; u24*u24.
; Input:
;   - HL: pointer to result u24
;   - DE: pointer to operand u24
; Output:
;   - u24(HL) *= u24(DE)
;   - CF: carry flag set if result overflowed u24
; Destroys: A, IX
; Preserves: BC, DE, HL, (DE)
multU24U24:
    call multU32U32
    ret c ; if CF==1: overflowed u32, so return
    or a
    ret z ; if byte 3==0: no overflow of u24, so return with CF=0
    scf ; CF=1 to indicate overflow
    ret

; Description: Multiply u16 by u16, u16(HL) *= u16(DE). This algorithm is
; similar to the u16*u16 algorithm in
; https://tutorials.eeems.ca/Z80ASM/part4.htm, except that this implements a
; u16*u16.
; Input:
;   - HL: pointer to result u16
;   - DE: pointer to operand u16
; Output:
;   - u16(HL) *= u16(DE)
;   - CF: carry flag set if result overflowed u16
; Destroys: A, IX
; Preserves: BC, DE, HL, (DE)
multU16U16:
    call multU32U32
    ret c ; if CF==1: overflowed u32, so return
    inc hl
    inc hl
    or (hl) ; A=byte2 OR byte3
    dec hl
    dec hl
    ret z ; if upper 2 bytes==0: no overflow of u16, so return with CF=0
    scf ; CF=1 to indicate overflow
    ret

; Description: Multiply u8 by u8, u8(HL) *= u8(DE). This algorithm is
; similar to the u8*u8 algorithm in
; https://tutorials.eeems.ca/Z80ASM/part4.htm, except that this implements a
; u8*u8.
; Input:
;   - HL: pointer to result u8
;   - DE: pointer to operand u8
; Output:
;   - u8(HL) *= u8(DE)
;   - CF: carry flag set if result overflowed u8
; Destroys: A, IX
; Preserves: BC, DE, HL, (DE)
; TODO: Implement a more efficient u8*u8 algorithm, instead of calling u32*u32.
multU8U8:
    call multU32U32
    ret c ; if CF==1: overflowed u32, so return
    inc hl
    or (hl)
    inc hl
    or (hl) ; A=byte1 OR byte2 OR byte3
    dec hl
    dec hl
    ret z ; if upper 3 bytes==0: no overflow of u8, so return with CF=0
    scf ; CF=1 to indicate overflow
    ret

;-----------------------------------------------------------------------------

; Description: Add A to u32 pointed by HL.
; Input:
;   - HL: pointer to u32
;   - A: u8 to add
; Output: (HL) += A
; Destroys: none
addU32U8:
    push hl

    add a, (hl)
    ld (hl), a
    inc hl
    ;
    ld a, (hl)
    adc a, 0
    ld (hl), a
    inc hl
    ;
    ld a, (hl)
    adc a, 0
    ld (hl), a
    inc hl
    ;
    ld a, (hl)
    adc a, 0
    ld (hl), a

    pop hl
    ret

addUxxUxx:
    call getBaseOffset
    or a
    jr z, addU8U8
    dec a
    jr z, addU16U16
    dec a
    jr z, addU24U24
    ; [[fallthrough]]

; Description: Calculate u32(HL) += u32(DE)
; Input:
;   - HL: pointer to destination u32 integer in little-endian format.
;   - DE: pointer to operand u32 integer in little-endian format.
; Output:
;   - (HL) += (DE)
;   - CF=carry flag
;   - A=byte 3 of result
; Destroys: A
; Preserves: BC, DE, HL, (DE)
addU32U32:
    push de
    push hl
    ex de, hl

    ld a, (de)
    add a, (hl)
    ld (de), a
    inc de
    inc hl

    ld a, (de)
    adc a, (hl)
    ld (de), a
    inc de
    inc hl

    ld a, (de)
    adc a, (hl)
    ld (de), a
    inc de
    inc hl

    ld a, (de)
    adc a, (hl)
    ld (de), a

    pop hl
    pop de
    ret

; Description: Calculate u24(HL) += u24(DE)
; Input:
;   - HL: pointer to destination u24 integer in little-endian format.
;   - DE: pointer to operand u24 integer in little-endian format.
; Output:
;   - (HL) += (DE)
;   - CF=carry flag
; Destroys: A
; Preserves: BC, DE, HL, (DE)
addU24U24:
    call addU32U32
    ret c
    or a
    ret z
    scf
    ret

; Description: Calculate u16(HL) += u16(DE)
; Input:
;   - HL: pointer to destination u16 integer in little-endian format.
;   - DE: pointer to operand u16 integer in little-endian format.
; Output:
;   - (HL) += (DE)
;   - CF=carry flag
; Destroys: A
; Preserves: BC, DE, HL, (DE)
addU16U16:
    call addU32U32
    ret c
    inc hl
    inc hl
    or (hl)
    dec hl
    dec hl
    ret z
    scf
    ret

; Description: Calculate u8(HL) += u8(DE)
; Input:
;   - HL: pointer to destination u8 integer in little-endian format.
;   - DE: pointer to operand u8 integer in little-endian format.
; Output:
;   - (HL) += (DE)
;   - CF=carry flag
; Destroys: A
; Preserves: BC, DE, HL, (DE)
addU8U8:
    call addU32U32
    ret c
    inc hl
    or (hl)
    inc hl
    or (hl)
    dec hl
    dec hl
    ret z
    scf
    ret

; Description: Add u32 to u32, u32(HL) += u32(IX)
; Output:
;   - (HL) += (IX)
;   - CF=carry flag
; Destroys: A
; Preserves: BC, DE, HL, (BC), IX
addU32U32IX:
    ; ex ix, de
    push ix
    push de
    pop ix
    pop de
    call addU32U32
    ; ex ix, de
    push ix
    push de
    pop ix
    pop de
    ret

;-----------------------------------------------------------------------------

subUxxUxx:
    call getBaseOffset
    or a
    jr z, subU8U8
    dec a
    jr z, subU16U16
    dec a
    jr z, subU24U24
    ; [[fallthrough]]

; Description: Subtract U32 from U32, u32(HL) -= u32(DE).
; Input:
;   - HL: pointer to destination u32 integer in little-endian format.
;   - DE: pointer to operand u32 integer in little-endian format.
; Output:
;   - (HL) -= (DE)
;   - CF: carry flag
;   - A: byte 3 of the result u32
; Destroys: A
; Preserves: BC, DE, HL
subU32U32:
    push de
    push hl
    ex de, hl

    ld a, (de)
    sub a, (hl)
    ld (de), a
    inc de
    inc hl

    ld a, (de)
    sbc a, (hl)
    ld (de), a
    inc de
    inc hl

    ld a, (de)
    sbc a, (hl)
    ld (de), a
    inc de
    inc hl

    ld a, (de)
    sbc a, (hl)
    ld (de), a

    pop hl
    pop de
    ret

; Description: Calculate u24(HL) -= u24(DE)
; Input:
;   - HL: pointer to destination u24 integer in little-endian format.
;   - DE: pointer to operand u24 integer in little-endian format.
; Output:
;   - (HL) -= (DE)
;   - CF=carry flag
; Destroys: A
; Preserves: BC, DE, HL, (DE)
subU24U24:
    call subU32U32
    ret c
    or a
    ret z
    scf
    ret

; Description: Calculate u16(HL) -= u16(DE)
; Input:
;   - HL: pointer to destination u16 integer in little-endian format.
;   - DE: pointer to operand u16 integer in little-endian format.
; Output:
;   - (HL) -= (DE)
;   - CF=carry flag
; Destroys: A
; Preserves: BC, DE, HL, (DE)
subU16U16:
    call subU32U32
    ret c
    inc hl
    inc hl
    or (hl)
    dec hl
    dec hl
    ret z
    scf
    ret

; Description: Calculate u8(HL) -= u8(DE)
; Input:
;   - HL: pointer to destination u8 integer in little-endian format.
;   - DE: pointer to operand u8 integer in little-endian format.
; Output:
;   - (HL) -= (DE)
;   - CF=carry flag
; Destroys: A
; Preserves: BC, DE, HL, (DE)
subU8U8:
    call subU32U32
    ret c
    inc hl
    or (hl)
    inc hl
    or (hl)
    dec hl
    dec hl
    ret z
    scf
    ret

;-----------------------------------------------------------------------------

; Description: Divide u32(HL) by u32(DE), remainder in u32(BC). This is an
; expanded u32 version of the "Fast 8-bit division" given in
; https://tutorials.eeems.ca/Z80ASM/part4.htm and
; https://wikiti.brandonw.net/index.php?title=Z80_Routines:Math:Division#32.2F16_division
;
; Input:
;   - HL: pointer to u32 dividend
;   - DE: pointer to u32 divisor
;   - BC: pointer to empty u32, used as remainder
; Output:
;   - HL: pointer to u32 quotient
;   - DE: divisor, unchanged
;   - BC: pointer to u32 remainder
;   - CF: 0 (division always clears the carry flag)
; Destroys: A
divUxxUxx:
divU32U32:
    call clearU32BC ; clear remainder, dividend will shift into this
    ld a, 32 ; iterate for 32 bits of a u32
divU32U32Loop:
    push af ; save A loop counter
    call shiftLeftLogicalU32 ; dividend(HL) <<= 1
    push hl ; save HL=dividend/quotient
    ld l, c
    ld h, b ; HL=BC=remainder
    call rotateLeftCarryU32 ; rotate CF into remainder
    ;
    call cmpU32U32 ; if remainder(HL) < divisor(DE): CF=1
    jr c, divU32U32QuotientZero
divU32U32QuotientOne:
    call subU32U32 ; remainder(HL) -= divisor(DE)
    pop hl ; HL=dividend/quotient
    ; Set bit 0 of byte 0 of quotient
    set 0, (hl)
    jr divU32U32NextBit
divU32U32QuotientZero:
    pop hl ; HL=dividend/quotient
divU32U32NextBit:
    pop af
    dec a
    jr nz, divU32U32Loop
    ret

;-----------------------------------------------------------------------------

; Description: Divide u32(HL) by u8(D), quotient in HL, remainder in u8(E).
; This is an expanded u32 version of the "Fast 8-bit division" given in
; https://tutorials.eeems.ca/Z80ASM/part4.htm and
; https://wikiti.brandonw.net/index.php?title=Z80_Routines:Math:Division#32.2F16_division
;
; Input:
;   - HL: pointer to u32 dividend
;   - D: u8 divisor
; Output:
;   - HL: pointer to u32 quotient
;   - D: divisor, unchanged
;   - E: u8 remainder
;   - CF: 0 (division always clears the carry flag)
; Destroys: A
; Preserves: BC
divU32U8:
    push bc ; save BC
    ld e, 0 ; clear remainder
    ld b, 32 ; iterate for 32 bits of a u32
divU32U8Loop:
    call shiftLeftLogicalU32 ; dividend(HL) <<= 1
    ld a, e ; A = remainder
    rla ; rotate CF from U32 into dividend/remainder
    ld e, a
    jr c, divU32U8QuotientOne ; remainder overflowed, so must substract
    cp d ; if remainder(A) < divisor(D): CF=1
    jr c, divU32U8QuotientZero
divU32U8QuotientOne:
    sub d
    ld e, a
    set 0, (hl)
divU32U8QuotientZero:
    djnz divU32U8Loop
    pop bc
    or a ; CF=0
    ret

;-----------------------------------------------------------------------------

; Calculate u32 % u16, throwing away the quotient. This is useful for the
; primeFactorXxx() routines which only need to know if a u16 integer is a
; factor of a u32 integer.
; Input:
;   - HL: pointer to U32 dividend
;   - DE: U16 divisor
; Output:
;   - HL: pointer to U32 of 0
;   - DE: unchanged
;   - BC: U16 remainder
modU32U16:
    push de
    ld b, d
    ld c, e ; BC=DE=divisor
    ld de, 0
    ld a, 32
modU32U16Loop:
    call shiftLeftLogicalU32
    rl e
    rl d ; DE=remainder
    ex de, hl ; HL=remainder
    jr c, modU32U16Overflow ; remainder overflowed, so must substract
    or a ; reset CF
    sbc hl, bc ; HL(remainder) -= divisor
    jr nc, modU32U16NextBit
    add hl, bc ; revert the subtraction
    jr modU32U16NextBit
modU32U16Overflow:
    or a ; reset CF
    sbc hl, bc ; HL(remainder) -= divisor
modU32U16NextBit:
    ex de, hl ; DE=remainder
    dec a
    jr nz, modU32U16Loop
    ld c, e
    ld b, d
    pop de
    ret

;-----------------------------------------------------------------------------
; Comparison, copy, and clear operations.
;-----------------------------------------------------------------------------

; Description: Compare u32(HL) to u32(DE), returning CF=1 if u32(HL) < u32(DE),
; and ZF=1 if u32(HL) == u32(DE). The order of the parameters is the same as
; subU32U32().
; Input:
;   - HL: pointer to u32
;   - DE: pointer to u32
; Output:
;   - CF=1 if (HL) < (DE)
;   - ZF=1 if (HL) == (DE)
; Destroys: A
; Preserves: BC, DE, HL
cmpU32U32:
    push hl
    push de

    ; start from most significant byte
    inc hl
    inc hl
    inc hl
    inc de
    inc de
    inc de
    ex de, hl

    ; start with the most significant byte
    ld a, (de)
    cp (hl)
    jr nz, cmpU32U32End

    dec hl
    dec de
    ld a, (de)
    cp (hl)
    jr nz, cmpU32U32End

    dec hl
    dec de
    ld a, (de)
    cp (hl)
    jr nz, cmpU32U32End

    dec hl
    dec de
    ld a, (de)
    cp (hl)

cmpU32U32End:
    pop de
    pop hl
    ret

; Description: Compare u32(HL) with the u8 in A.
; Input:
;   - HL: pointer to u32
;   - A: u8 integer
; Output:
;   - CF=1 if (HL) < A
;   - ZF=1 if (HL) == A
; Destroys: A
; Preserves: BC, DE, HL
cmpU32U8:
    push hl
    push bc
    ld c, a ; save u8(A)
    ld b, (hl) ; save the lowest byte of u32(HL)
    ; Check if any of the upper 3 bytes of u32(HL) are non-zero.
    inc hl
    ld a, (hl)
    or a
    jr nz, cmpU32U8GreaterEqual
    inc hl
    ld a, (hl)
    or a
    jr nz, cmpU32U8GreaterEqual
    inc hl
    ld a, (hl)
    or a
    jr nz, cmpU32U8GreaterEqual
    ; Compare the lowest byte
    ld a, b
    cp c
cmpU32U8GreaterEqual:
    pop bc
    pop hl
    ret

;-----------------------------------------------------------------------------

; Description: Test if u32 pointed by HL is zero.
; Input: HL: pointer to u32
; Destroys: A
testU32:
    push hl
testU32AltEntry:
    ld a, (hl)
    or a
    jr nz, testU32End
    ;
    inc hl
    ld a, (hl)
    or a
    jr nz, testU32End
    ;
    inc hl
    ld a, (hl)
    or a
    jr nz, testU32End
    ;
    inc hl
    ld a, (hl)
    or a
testU32End:
    pop hl
    ret

; Description: Test for if u32 pointed by BC is zero.
; Input: BC: pointer to u32
; Destroys: A
testU32BC:
    push hl
    ld l, c
    ld h, b
    jr testU32AltEntry

;-----------------------------------------------------------------------------

; Description: Copy the u32 integer from HL to DE.
; Input:
;   - HL: pointer to source u32
;   - DE: pointer to destination u32
; Destroys: A
copyU32HLToDE:
    push de
    push hl
    ld a, (hl)
    ld (de), a
    inc hl
    inc de
    ld a, (hl)
    ld (de), a
    inc hl
    inc de
    ld a, (hl)
    ld (de), a
    inc hl
    inc de
    ld a, (hl)
    ld (de), a
    pop hl
    pop de
    ret

;-----------------------------------------------------------------------------

; Description: Clear the u32 pointed by HL.
; Input: HL: pointer to u32
; Destroys: none
clearU32:
    push hl
    push bc
clearU32AltEntry:
    ld bc, $0400 ; B=4; C=0
clearU32Loop:
    ld (hl), c
    inc hl
    djnz clearU32Loop
    pop bc
    pop hl
    ret

; Description: Clear the u32 pointed by BC.
; Input: BC: pointer to u32
; Destroys: none
clearU32BC:
    push hl
    push bc
    ld h, b
    ld l, c
    jr clearU32AltEntry

;-----------------------------------------------------------------------------

; Description: Set u32 pointed by HL to value in A.
; Input:
;   - A: u8
;   - HL: pointer to u32
; Output:
;   - (HL)=A
; Preserves: all
setU32ToA:
    call clearU32
    ld (hl), a
    ret

; Description: Set u32 pointed by HL to u16 value in BC.
; Input:
;   - BC: u16
;   - HL: pointer to u32
; Output:
;   - (HL)=BC
; Preserves: all
setU32ToBC:
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
    pop hl
    pop af
    ret

;-----------------------------------------------------------------------------
; Logical and bitwise operations.
;-----------------------------------------------------------------------------

; Description: Perform binary AND operation, u32(HL) &= u32(DE).
; Input:
;   - HL: pointer to u32
;   - DE: pointer to u32
; Output:
;   - HL: pointer to the result
; Destroys: A
andU32U32:
    push hl
    push de

    ld a, (de)
    and (hl)
    ld (hl), a
    inc hl
    inc de

    ld a, (de)
    and (hl)
    ld (hl), a
    inc hl
    inc de

    ld a, (de)
    and (hl)
    ld (hl), a
    inc hl
    inc de

    ld a, (de)
    and (hl)
    ld (hl), a

    pop de
    pop hl
    ret

;-----------------------------------------------------------------------------

; Description: Perform binary OR operation, u32(HL) |= u32(DE).
; Input:
;   - HL: pointer to u32
;   - DE: pointer to u32
; Output:
;   - HL: pointer to the result
; Destroys: A
orU32U32:
    push hl
    push de

    ld a, (de)
    or (hl)
    ld (hl), a
    inc hl
    inc de

    ld a, (de)
    or (hl)
    ld (hl), a
    inc hl
    inc de

    ld a, (de)
    or (hl)
    ld (hl), a
    inc hl
    inc de

    ld a, (de)
    or (hl)
    ld (hl), a

    pop de
    pop hl
    ret

;-----------------------------------------------------------------------------

; Description: Perform binary XOR operation, u32(HL) ^= u32(DE).
; Input:
;   - HL: pointer to u32
;   - DE: pointer to u32
; Output:
;   - HL: pointer to the result
; Destroys: A
xorU32U32:
    push hl
    push de

    ld a, (de)
    xor (hl)
    ld (hl), a
    inc hl
    inc de

    ld a, (de)
    xor (hl)
    ld (hl), a
    inc hl
    inc de

    ld a, (de)
    xor (hl)
    ld (hl), a
    inc hl
    inc de

    ld a, (de)
    xor (hl)
    ld (hl), a

    pop de
    pop hl
    ret

;-----------------------------------------------------------------------------

; Description: Perform NOT (1's complement) operation, u32(HL) = !u32(HL).
; Input:
;   - HL: pointer to u32
; Output:
;   - HL: pointer to the result
; Destroys: A
notU32:
    push hl

    ld a, (hl)
    cpl
    ld (hl), a
    inc hl

    ld a, (hl)
    cpl
    ld (hl), a
    inc hl

    ld a, (hl)
    cpl
    ld (hl), a
    inc hl

    ld a, (hl)
    cpl
    ld (hl), a

    pop hl
    ret

;-----------------------------------------------------------------------------

; Description: Perform NEG (2's complement negative) operation, u32(HL) =
; -u32(HL).
; Input:
;   - HL: pointer to u32
; Output:
;   - HL: pointer to the result
; Destroys: A
negU32:
    push hl

    ld a, (hl)
    neg
    ld (hl), a
    inc hl

    ld a, 0
    sbc a, (hl)
    ld (hl), a
    inc hl

    ld a, 0
    sbc a, (hl)
    ld (hl), a
    inc hl

    ld a, 0
    sbc a, (hl)
    ld (hl), a

    pop hl
    ret

;-----------------------------------------------------------------------------

; Description: Reverse the bits of u32(HL).
; Input: HL=pointer to u32
; Output: HL=reverse(HL)
; Destroys: A, BC
; Preserves: HL, DE
reverseU32:
    push hl
    ; reverse the bytes
    ld c, (hl)
    inc hl
    ld b, (hl)
    inc hl
    ld a, (hl)
    ld (hl), b
    dec hl
    ld (hl), a
    inc hl
    inc hl
    ld a, (hl)
    ld (hl), c
    dec hl
    dec hl
    dec hl
    ld (hl), a
    ; reverse the bits of each byte
    ld a, (hl)
    call reverseBits
    ld (hl), a
    inc hl
    ld a, (hl)
    call reverseBits
    ld (hl), a
    inc hl
    ld a, (hl)
    call reverseBits
    ld (hl), a
    inc hl
    ld a, (hl)
    call reverseBits
    ld (hl), a
    pop hl
    ret

; Description: Reverse the bits of register A.
; Input: A
; Output: A=reverse(A)
; Destroys: BC
reverseBits:
    ld b, 8
reverseBitsLoop:
    rrca
    rl c
    djnz reverseBitsLoop
    ld a, c
    ret

;-----------------------------------------------------------------------------

; Description: Count the number of bits in u32(HL).
; Input: HL=pointer to u32
; Output: A=number of bits in u32
; Destroys: A, BC
; Preserves, DE, HL
countU32Bits:
    push hl
    ld c, 0
    ld a, (hl)
    call appendCountBits
    inc hl
    ld a, (hl)
    call appendCountBits
    inc hl
    ld a, (hl)
    call appendCountBits
    inc hl
    ld a, (hl)
    call appendCountBits
    pop hl
    ld a, c
    ret

; Description: Count the number of bits in A.
; Output: C+=numBits(A)
; Destroys: A, BC
appendCountBits:
    ld b, 8
countBitsLoop:
    rrca
    jr nc, countBitsNext
    inc c
countBitsNext:
    djnz countBitsLoop
    ret

;-----------------------------------------------------------------------------

; Description: Set bit 'C' of u32(HL).
; Input:
;   - HL=pointer to u32
;   - C=bit number (0-31)
; Output:
;   - HL=pointer to u32
; Destroys: A, B, DE
; Preserves: HL, C
setU32Bit:
    push hl
    call bitMaskU32
    or (hl) ; set bit C
    ld (hl), a
    pop hl
    ret

; Description: Clear bit 'C' of u32(HL).
; Input:
;   - HL=pointer to u32
;   - C=bit number (0-31)
; Output:
;   - HL=pointer to u32
; Destroys: A, B, DE
; Preserves: HL, C
clearU32Bit:
    push hl
    call bitMaskU32
    cpl
    and (hl) ; clear bit C
    ld (hl), a
    pop hl
    ret

; Description: Return the status of bit C of u32(HL).
; Input:
;   - HL=pointer to u32
;   - C=bit number (0-31)
; Output:
;   - HL=pointer to u32
;   - A=1 or 0
; Destroys: A, B, DE
; Preserves: HL, C
getU32Bit:
    push hl
    call bitMaskU32
    and (hl)
    jr z, getU32BitEnd
    ld a, 1
getU32BitEnd:
    pop hl
    ret

; Description: Calculate the offset and mask of bit C of u32(HL).
; Input:
;   - HL=pointer to u32
;   - C=bit number (0-31)
; Output:
;   - HL=pointer to byte offset
;   - A=bit mask
; Destroys: A, B, DE, HL
; Preserves: C
bitMaskU32:
    ld a, c
    and $07
    ld b, a ; lowest 3 bits of C
    ld a, c
    rrca
    rrca
    rrca
    and $03
    ld e, a
    ld d, 0 ; DE=highest 2 bits of C, acting as byte offset
    add hl, de
    ; [[fallthrough]]

; Description: Create a bit mask with bit B set.
; Input: B=bit number (0-7)
; Output: A=bit mask with bit B set
; Destroys: A, B
bitMaskB:
    ld a, b
    or a
    ld a, 1
    ret z
setBitBofALoop:
    rlca
    djnz setBitBofALoop
    ret

;-----------------------------------------------------------------------------
; Word size operations.
;-----------------------------------------------------------------------------

; Description: Truncate the u32(HL) to the number of bits given by
; (baseWordSize).
; Input:
;   - HL=pointer to u32
;   - (baseWordSize)=8, 16, 24, 32
; Output:
;   - HL=pointer to u8, u16, u24, or u32
; Destroys: A
; Preserves: HL
truncToWordSize:
    push hl
    inc hl
    inc hl
    inc hl
    call getBaseOffset
    sub 3
    neg ; [u8,u16,u24,u32] -> [3,2,1,0]
    jr truncToWordSizeEntry
truncToWordSizeLoop:
    ld (hl), 0
    dec hl
    dec a
truncToWordSizeEntry:
    jr nz, truncToWordSizeLoop
truncWordSizeExit:
    pop hl
    ret
