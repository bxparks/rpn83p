;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Routines related to u32 stored as 4 bytes in little endian format.
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
    call shiftLeftU32 ; (HL) *= 2
    call shiftLeftU32 ; (HL) *= 2

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

    call shiftLeftU32 ; (HL) = 2 * (HL) = 10 * (original HL)

    pop de
    pop bc
    ret

; Description: Multiply u32 by u32, u32(HL) *= u32(DE). This algorithm is
; similar to the u16*u16 algorithm in
; https://tutorials.eeems.ca/Z80ASM/part4.htm, except that this implements a
; u32*u32.
; Input:
;   - HL: pointer to result u32
;   - DE: pointer to operand u32
; Output:
;   - u32(HL) *= u32(DE)
; Destroys: A
multU32U32:
    ; Create temporary 4-byte buffer on the stack, and set it to 0.
    push bc
    ld bc, 0
    push bc
    push bc
    ;
    ld b, h
    ld c, l ; BC = HL
    ld hl, 0
    add hl, sp ; (HL) = (SP) = result
    ld a, 32
multU32U32Loop:
    call shiftLeftU32 ; (HL) *= 2
    ex de, hl
    call shiftLeftU32 ; (DE) *= 2
    ex de, hl
    jr nc, multU32U32NoMult
    call addU32U32BC ; (HL) += (BC)
multU32U32NoMult:
    dec a
    jr nz, multU32U32Loop
multU32U32End:
    ; copy u32(SP) to u32(original HL)
    ld h, b
    ld l, c
    pop bc
    ld (hl), c
    inc hl
    ld (hl), b
    inc hl
    pop bc
    ld (hl), c
    inc hl
    ld (hl), b
    dec hl
    dec hl
    dec hl
    pop bc
    ret

;-----------------------------------------------------------------------------

; Description: Shift u32(HL) left by one bit. Also calculates u32(HL) = u32(HL)
; * 2.
; Input: HL: pointer to a u32 integer in little-endian format.
; Output:
;   - u32 pointed by HL is doubled
;   - CF: highest bit
; Destroys: none
shiftLeftU32:
    push hl
    or a ; clear CF
    sla (hl) ; CF=bit7
    inc hl
    rl (hl) ; rotate left through CF
    inc hl
    rl (hl) ; rotate left through CF
    inc hl
    rl (hl) ; rotate left through CF
    pop hl
    ret

; Description: Shift u32(HL) right logical.
; Input: HL: pointer to u32
; Destroys: none
shiftRightLogicalU32:
    inc hl
    inc hl
    inc hl ; HL = &buf[3]
    srl (hl) ; CF = least significant bit
    dec hl ; HL = &buf[2]
    rr (hl)
    dec hl ; HL = &buf[1]
    rr (hl)
    dec hl ; HL = &buf[0]
    rr (hl)
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

; Description: Calculate u32(HL) += u32(DE)
; Input:
;   - HL: pointer to destination u32 integer in little-endian format.
;   - DE: pointer to operand u32 integer in little-endian format.
; Output:
;   - (HL) += (DE)
; Preserves: A, BC, DE, HL, (DE)
addU32U32:
    push af
    push hl
    push de
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

    pop de
    pop hl
    pop af
    ret

; Description: Add u32 to u32, u32(HL) += u32(BC)
; Preserves: A, BC, DE, HL, (HL)
addU32U32BC:
    push bc
    push de
    pop bc
    pop de
    call addU32U32
    push bc
    push de
    pop bc
    pop de
    ret

; Description: Subtract U32 from U32, u32(HL) -= u32(DE).
; Input:
;   - HL: pointer to destination u32 integer in little-endian format.
;   - DE: pointer to operand u32 integer in little-endian format.
; Output:
;   - (HL) += (DE)
; Preserves: A, BC, DE, HL, (BC)
subU32U32:
    push af
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
    pop af
    ret

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

; Description: Clear the u32 pointed by HL.
; Input: HL: pointer to u32
; Destroys: none
clearU32:
    push af
    push hl
    xor a
    ld (hl), a
    inc hl
    ld (hl), a
    inc hl
    ld (hl), a
    inc hl
    ld (hl), a
    pop hl
    pop af
    ret

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
