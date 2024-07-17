;-----------------------------------------------------------------------------
; Various implementations of the mod(u32,u16) function.
;
; The RESTORING division algorithm is fairly straightforward. See for example,
; https://tutorials.eeems.ca/Z80ASM/part4.htm.

; The NONRESTORING algorithm is more obscure. The Wikipedia entry
; (https://en.wikipedia.org/wiki/Division_algorithm#Non-restoring_division) is
; impenetrable. A better explanation is the flowchart in this StackOverflow
; (https://stackoverflow.com/questions/12133810) post. However, there is a
; complexity when trying to implement that flowchart into a Z80 processor: the
; remainder (HL) requires an extra bit (17 bits total, instead of 16 bits) in
; addition to the Carry Flag (CF). So the extra bit of information gets encoded
; into 2 separate code paths, one for positive remainder and one for negative
; remainder. The resulting implementation looks twice as complex as the
; flowchart, but it's actually implementing the same thing.
;
; Benchmarks:
;   - MOD_HLIX_BY_BC_RESTORING_MONOLITH (original): 20.5 s
;   - MOD_HLIX_BY_BC_RESTORING_MONOLITH (remove 'jp'): 20.4 s
;   - MOD_HLIX_BY_BC_RESTORING_UNROLLED: 19.5 s
;   - MOD_HLIX_BY_BC_RESTORING_CHUNK8: 17.4 s
;   - MOD_DEIX_BY_BC_RESTORING_CHUNK8: 15.6 s
;   - MOD_DEIX_BY_BC_RESTORING_CHUNK8_REGA: 14.9 s
;   - MOD_DEIX_BY_BC_RESTORING_CHUNK8_REGA_TAILLOOP: 15.8 s
;   - MOD_DEIX_BY_BC_RESTORING_CHUNK8_REGA_UNROLLED: 13.4 s
;
;   - MOD_HLIX_BY_BC_NONRESTORING_MONOLITH: 18.9 s
;   - MOD_DEIX_BY_BC_NONRESTORING_CHUNK8: 14.4 s
;   - MOD_DEIX_BY_BC_NONRESTORING_CHUNK8_REGA: 13.7 s
;   - MOD_DEIX_BY_BC_NONRESTORING_CHUNK8_REGA_UNROLLED: 11.8 s
;   - MOD_DEIX_BY_BC_NONRESTORING_CALC84MANIAC: 11.9 s
;-----------------------------------------------------------------------------

#ifdef MOD_HLIX_BY_BC_RESTORING_MONOLITH
; Description: Calculate mod(u32,u16), i.e. the remainder when a u32 dividend
; is divided by a u16 divisor.
; Input:
;   - DE:u16=high 16 bits of u32 dividend
;   - IX:u16=low 16 bits of u32 dividend
;   - BC:u16=divisor
; Output:
;   - HL:u16=remainder
; Destroys: A, DE, IX
modDEIXByBC:
    ex de, hl
    call modHLIXByBC
    ex de, hl
    ret

; Description: Calculate mod(u32,u16), i.e. the remainder when a u32 dividend
; is divided by a u16 divisor.
; Input:
;   - HL:u16=high 16 bits of u32 dividend
;   - IX:u16=low 16 bits of u32 dividend
;   - BC:u16=divisor
; Output:
;   - DE:u16=remainder
; Destroys: A, HL, IX
modHLIXByBC:
    ld de, 0 ; DE=remainder
    ld a, 32
modHLIXByBCLoop:
    add ix, ix
    adc hl, hl
    ex de, hl ; HL=remainder; DE=dividend
    adc hl, hl
    jr c, modHLIXByBCOverflow ; remainder overflowed, so subtract
    sbc hl, bc ; remainder -= divisor
    jp nc, modHLIXByBCNextBit
    add hl, bc ; revert the subtraction
modHLIXByBCNextBit:
    ex de, hl ; DE=remainder; HL=dividend
    dec a
    jp nz, modHLIXByBCLoop
    ret
modHLIXByBCOverflow:
    or a ; reset CF
    sbc hl, bc ; remainder -= divisor
    jp modHLIXByBCNextBit
#endif

;-----------------------------------------------------------------------------

#ifdef MOD_HLIX_BY_BC_RESTORING_UNROLLED
; Description: Calculate mod(u32,u16), i.e. the remainder when a u32 dividend
; is divided by a u16 divisor.
; Input:
;   - DE:u16=high 16 bits of u32 dividend
;   - IX:u16=low 16 bits of u32 dividend
;   - BC:u16=divisor
; Output:
;   - HL:u16=remainder
; Destroys: A, DE, IX
modDEIXByBC:
    ex de, hl
    call modHLIXByBC
    ex de, hl
    ret

; Description: Calculate mod(u32,u16), i.e. the remainder when a u32 dividend
; is divided by a u16 divisor.
; Input:
;   - HL:u16=high 16 bits of u32 dividend
;   - IX:u16=low 16 bits of u32 dividend
;   - BC:u16=divisor
; Output:
;   - DE:u16=remainder
; Destroys: A, HL, IX
modHLIXByBC:
    ld de, 0 ; DE=remainder
    call modHLIXByBCSansSpill
    ; if divisor < $8000: spill into carry cannot occur
    bit 7, b
    jr nz, modHLIXByBCWithSpill
    ; [[fallthrough]]
modHLIXByBCSansSpill:
    ld a, 16
modHLIXByBCSansSpillLoop:
    add ix, ix
    adc hl, hl
    ex de, hl ; HL=remainder; DE=dividend
    adc hl, hl
    sbc hl, bc ; remainder -= divisor
    jp nc, modHLIXByBCSansSpillNextBit
    add hl, bc ; revert the subtraction
modHLIXByBCSansSpillNextBit:
    ex de, hl ; DE=remainder; HL=dividend
    dec a
    jp nz, modHLIXByBCSansSpillLoop
    ret
;
modHLIXByBCWithSpill:
    ld a, 16
modHLIXByBCWithSpillLoop:
    add ix, ix
    adc hl, hl
    ex de, hl ; HL=remainder; DE=dividend
    adc hl, hl
    jr c, modHLIXByBCWithSpillOverflow ; remainder overflowed, so subtract
    sbc hl, bc ; remainder -= divisor
    jp nc, modHLIXByBCWithSpillNextBit
    add hl, bc ; revert the subtraction
modHLIXByBCWithSpillNextBit:
    ex de, hl ; DE=remainder; HL=dividend
    dec a
    jp nz, modHLIXByBCWithSpillLoop
    ret
modHLIXByBCWithSpillOverflow:
    or a ; reset CF
    sbc hl, bc ; remainder -= divisor
    ; duplicate modHLIXByBCWithSpillNextBit to save a 'jp'
    ex de, hl ; DE=remainder; HL=dividend
    dec a
    jp nz, modHLIXByBCWithSpillLoop
    ret
#endif

;-----------------------------------------------------------------------------

#ifdef MOD_HLIX_BY_BC_RESTORING_CHUNK8
; Description: Calculate mod(u32,u16), i.e. the remainder when a u32 dividend
; is divided by a u16 divisor.
; Input:
;   - DE:u16=high 16 bits of u32 dividend
;   - IX:u16=low 16 bits of u32 dividend
;   - BC:u16=divisor
; Output:
;   - HL:u16=remainder
; Destroys: A, DE, IX
modDEIXByBC:
    ex de, hl
    call modHLIXByBC
    ex de, hl
    ret

; Description: Calculate mod(u32,u16), i.e. the remainder when a u32 dividend
; is divided by a u16 divisor.
; Input:
;   - HL:u16=high 16 bits of u32 dividend
;   - IX:u16=low 16 bits of u32 dividend
;   - BC:u16=divisor
; Output:
;   - DE:u16=remainder
; Destroys: A, HL, IX
modHLIXByBC:
    ld de, 0 ; DE=remainder
    call modHLIXByBC8
    ld h, l
    call modHLIXByBC8
    push ix
    pop hl
    call modHLIXByBC8
    ld h, l
    ; [[fallthrough]]
; Input: H:u8=high 8 bits of the shifted dividend
; Output: DE:u16=remainder
modHLIXByBC8:
    ld a, 8
modHLIXByBCLoop:
    sla h
    ex de, hl ; HL=remainder; DE=dividend
    adc hl, hl
    jr c, modHLIXByBCOverflow ; remainder overflowed, so subtract
    sbc hl, bc ; remainder -= divisor
    jp nc, modHLIXByBCNextBit
    add hl, bc ; revert the subtraction
modHLIXByBCNextBit:
    ex de, hl ; DE=remainder; HL=dividend
    dec a
    jp nz, modHLIXByBCLoop
    ret
modHLIXByBCOverflow:
    or a ; reset CF
    sbc hl, bc ; remainder -= divisor
    jp modHLIXByBCNextBit
#endif

;-----------------------------------------------------------------------------

#ifdef MOD_DEIX_BY_BC_RESTORING_CHUNK8
; Description: Calculate mod(u32,u16), i.e. the remainder when a u32 dividend
; is divided by a u16 divisor.
; Input:
;   - DE:u16=high 16 bits of u32 dividend
;   - IX:u16=low 16 bits of u32 dividend
;   - BC:u16=divisor
; Output:
;   - HL:u16=remainder
; Destroys: A, DE, IX
modDEIXByBC:
    ld hl, 0 ; HL=remainder
    call modDEIXByBC8
    ld d, e
    call modDEIXByBC8
    push ix
    pop de
    call modDEIXByBC8
    ld d, e
    ; [[fallthrough]]
; Input: D:u8=high 8 bits of the shifted dividend
; Output: HL:u16=remainder
modDEIXByBC8:
    ld a, 8
modDEIXByBCLoop:
    sla d
    adc hl, hl
    jr c, modDEIXByBCOverflow ; remainder overflowed, so subtract
    sbc hl, bc ; remainder -= divisor
    jp nc, modDEIXByBCNextBit
    add hl, bc ; revert the subtraction
modDEIXByBCNextBit:
    dec a
    jp nz, modDEIXByBCLoop
    ret
modDEIXByBCOverflow:
    or a ; reset CF
    sbc hl, bc ; remainder -= divisor
    dec a
    jp nz, modDEIXByBCLoop
    ret
#endif

;-----------------------------------------------------------------------------

#ifdef MOD_DEIX_BY_BC_RESTORING_CHUNK8_REGA
; Description: Calculate mod(u32,u16), i.e. the remainder when a u32 dividend
; is divided by a u16 divisor.
; Input:
;   - DE:u16=high 16 bits of u32 dividend
;   - IX:u16=low 16 bits of u32 dividend
;   - BC:u16=divisor
; Output:
;   - HL:u16=remainder
; Destroys: A, DE, IX
modDEIXByBC:
    ld hl, 0 ; HL=remainder
    ld a, d
    call modDEIXByBC8
    ld a, e
    call modDEIXByBC8
    push ix
    pop de
    ld a, d
    call modDEIXByBC8
    ld a, e
    ; [[fallthrough]]
; Input: A:u8=high 8 bits of the shifted dividend
; Output: HL:u16=remainder
modDEIXByBC8:
    ld d, 8
modDEIXByBCLoop:
    rla
    adc hl, hl
    jr c, modDEIXByBCOverflow ; remainder overflowed, so subtract
    sbc hl, bc ; remainder -= divisor
    jp nc, modDEIXByBCNextBit
    add hl, bc ; revert the subtraction
modDEIXByBCNextBit:
    dec d
    jp nz, modDEIXByBCLoop
    ret
modDEIXByBCOverflow:
    or a ; reset CF
    sbc hl, bc ; remainder -= divisor
    dec d
    jp nz, modDEIXByBCLoop
    ret
#endif

;-----------------------------------------------------------------------------

#ifdef MOD_DEIX_BY_BC_RESTORING_CHUNK8_REGA_TAILLOOP
; Description: Calculate mod(u32,u16), i.e. the remainder when a u32 dividend
; is divided by a u16 divisor.
; Input:
;   - DE:u16=high 16 bits of u32 dividend
;   - IX:u16=low 16 bits of u32 dividend
;   - BC:u16=divisor
; Output:
;   - HL:u16=remainder
; Destroys: A, DE, IX
modDEIXByBC:
    ld hl, 0 ; HL=remainder
    ld a, d
    call modDEIXByBC8
    ld a, e
    call modDEIXByBC8
    push ix
    pop de
    ld a, d
    call modDEIXByBC8
    ld a, e
    ; [[fallthrough]]
; Input: A:u8=high 8 bits of the shifted dividend
; Output: HL:u16=remainder
modDEIXByBC8:
    call modDEIXByBCTail4
modDEIXByBCTail4:
    call modDEIXByBCTail2
modDEIXByBCTail2:
    call modDEIXByBCTail1
modDEIXByBCTail1:
    rla
    adc hl, hl
    jr c, modDEIXByBCOverflow ; remainder overflowed, so subtract
    sbc hl, bc ; remainder -= divisor
    ret nc
    add hl, bc ; revert the subtraction
    ret
modDEIXByBCOverflow:
    or a ; reset CF
    sbc hl, bc ; remainder -= divisor
    ret
#endif

;-----------------------------------------------------------------------------

#ifdef MOD_DEIX_BY_BC_RESTORING_CHUNK8_REGA_UNROLLED
; Description: Calculate mod(u32,u16), i.e. the remainder when a u32 dividend
; is divided by a u16 divisor.
; Input:
;   - DE:u16=high 16 bits of u32 dividend
;   - IX:u16=low 16 bits of u32 dividend
;   - BC:u16=divisor
; Output:
;   - HL:u16=remainder
; Destroys: A, DE, IX
modDEIXByBC:
    ld hl, 0 ; HL=remainder
    ld a, d
    call modDEIXByBC8
    ld a, e
    call modDEIXByBC8
    push ix
    pop de
    ld a, d
    call modDEIXByBC8
    ld a, e
    ; [[fallthrough]]
; Input: A:u8=high 8 bits of the shifted dividend
; Output: HL:u16=remainder
modDEIXByBC8:
    rla
    adc hl, hl
    jr c, modDEIXByBCBit0Overflow ; remainder overflowed, so subtract
    sbc hl, bc ; remainder -= divisor
    jp nc, modDEIXByBCBit1
    add hl, bc ; revert the subtraction
    jp modDEIXByBCBit1
modDEIXByBCBit0Overflow:
    or a ; reset CF
    sbc hl, bc ; remainder -= divisor
    ;
modDEIXByBCBit1:
    rla
    adc hl, hl
    jr c, modDEIXByBCBit1Overflow ; remainder overflowed, so subtract
    sbc hl, bc ; remainder -= divisor
    jp nc, modDEIXByBCBit2
    add hl, bc ; revert the subtraction
    jp modDEIXByBCBit2
modDEIXByBCBit1Overflow:
    or a ; reset CF
    sbc hl, bc ; remainder -= divisor
    ;
modDEIXByBCBit2:
    rla
    adc hl, hl
    jr c, modDEIXByBCBit2Overflow ; remainder overflowed, so subtract
    sbc hl, bc ; remainder -= divisor
    jp nc, modDEIXByBCBit3
    add hl, bc ; revert the subtraction
    jp modDEIXByBCBit3
modDEIXByBCBit2Overflow:
    or a ; reset CF
    sbc hl, bc ; remainder -= divisor
    ;
modDEIXByBCBit3:
    rla
    adc hl, hl
    jr c, modDEIXByBCBit3Overflow ; remainder overflowed, so subtract
    sbc hl, bc ; remainder -= divisor
    jp nc, modDEIXByBCBit4
    add hl, bc ; revert the subtraction
    jp modDEIXByBCBit4
modDEIXByBCBit3Overflow:
    or a ; reset CF
    sbc hl, bc ; remainder -= divisor
    ;
modDEIXByBCBit4:
    rla
    adc hl, hl
    jr c, modDEIXByBCBit4Overflow ; remainder overflowed, so subtract
    sbc hl, bc ; remainder -= divisor
    jp nc, modDEIXByBCBit5
    add hl, bc ; revert the subtraction
    jp modDEIXByBCBit5
modDEIXByBCBit4Overflow:
    or a ; reset CF
    sbc hl, bc ; remainder -= divisor
    ;
modDEIXByBCBit5:
    rla
    adc hl, hl
    jr c, modDEIXByBCBit5Overflow ; remainder overflowed, so subtract
    sbc hl, bc ; remainder -= divisor
    jp nc, modDEIXByBCBit6
    add hl, bc ; revert the subtraction
    jp modDEIXByBCBit6
modDEIXByBCBit5Overflow:
    or a ; reset CF
    sbc hl, bc ; remainder -= divisor
    ;
modDEIXByBCBit6:
    rla
    adc hl, hl
    jr c, modDEIXByBCBit6Overflow ; remainder overflowed, so subtract
    sbc hl, bc ; remainder -= divisor
    jp nc, modDEIXByBCBit7
    add hl, bc ; revert the subtraction
    jp modDEIXByBCBit7
modDEIXByBCBit6Overflow:
    or a ; reset CF
    sbc hl, bc ; remainder -= divisor
    ;
modDEIXByBCBit7:
    rla
    adc hl, hl
    jr c, modDEIXByBCBit7Overflow ; remainder overflowed, so subtract
    sbc hl, bc ; remainder -= divisor
    jp nc, modDEIXByBCBit8
    add hl, bc ; revert the subtraction
    jp modDEIXByBCBit8
modDEIXByBCBit7Overflow:
    or a ; reset CF
    sbc hl, bc ; remainder -= divisor
    ;
modDEIXByBCBit8:
    ret
#endif

;============================================================================

#ifdef MOD_HLIX_BY_BC_NONRESTORING_MONOLITH
; Description: Calculate mod(u32,u16), i.e. the remainder when a u32 dividend
; is divided by a u16 divisor.
; Input:
;   - DE:u16=high 16 bits of u32 dividend
;   - IX:u16=low 16 bits of u32 dividend
;   - BC:u16=divisor
; Output:
;   - HL:u16=remainder
; Destroys: A, DE, IX
modDEIXByBC:
    ex de, hl
    call modHLIXByBC
    ex de, hl
    ret

; Description: Calculate mod(u32,u16), i.e. the remainder when a u32 dividend
; is divided by a u16 divisor.
; Input:
;   - HL:u16=high 16 bits of u32 dividend
;   - IX:u16=low 16 bits of u32 dividend
;   - BC:u16=divisor
; Output:
;   - DE:u16=remainder
; Destroys: A, HL, IX
modHLIXByBC:
    ld de, 0 ; DE=remainder
    ld a, 32
    or a ; CF=0
modHLIXByBCLoop:
    jp c, modHLIXByBCNeg
modHLIXByBCPos:
    add ix, ix
    adc hl, hl
    ex de, hl ; HL=remainder; DE=dividend
    adc hl, hl
    jr c, modHLIXByBCPosOverflow
    sbc hl, bc ; remainder -= divisor
    ex de, hl ; HL=dividend; DE=remainder
    dec a
    jp nz, modHLIXByBCLoop
    jp modHLIXByBCEnd
modHLIXByBCPosOverflow:
    or a ; CF=0
    sbc hl, bc ; remainder -= divisor
    ex de, hl ; HL=dividend; DE=remainder
    dec a
    jp nz, modHLIXByBCPos
    or a ; always clear CF
    jp modHLIXByBCEnd
modHLIXByBCNeg:
    add ix, ix
    adc hl, hl
    ex de, hl ; HL=remainder; DE=dividend
    adc hl, hl
    jp c, modHLIXByBCNegOverflow
modHLIXByBCNegPos:
    ; Left-shift of A generated CF=0. Add M will always generate a negative
    ; remainder.
    add hl, bc ; remainder += divisor
    ex de, hl ; HL=dividend; DE=remainder
    dec a
    jp nz, modHLIXByBCNeg
    scf ; set the CF=1 before returning to indicate negative remainder
    jp modHLIXByBCEnd
modHLIXByBCNegOverflow:
    ; Left-shift of A generated CF=1. Add M, then look at the CF again. If it
    ; transitions to a 1 again, then the resulting remainder becomes positive,
    ; so set CF=0 for the next iteration.
    add hl, bc ; remainder += divisor
    ex de, hl ; HL=dividend; DE=remainder
    ccf ; CF=0 if positive, 1 if negative
    dec a
    jp nz, modHLIXByBCLoop
    ; [[fallthrough]]
modHLIXByBCEnd:
    ; if the remainder is negative, restore it
    ret nc
    ex de, hl
    add hl, bc
    ex de, hl
    ret
#endif

;-----------------------------------------------------------------------------

#ifdef MOD_DEIX_BY_BC_NONRESTORING_CHUNK8
; Description: Calculate mod(u32,u16), i.e. the remainder when a u32 dividend
; is divided by a u16 divisor.
; Input:
;   - DE:u16=high 16 bits of u32 dividend
;   - IX:u16=low 16 bits of u32 dividend
;   - BC:u16=divisor
; Output:
;   - HL:u16=remainder
; Destroys: A, DE, IX
modDEIXByBC:
    ld hl, 0 ; HL=remainder
    or a ; CF=0
    call modDEIXByBC8
    ld d, e
    call modDEIXByBC8
    push ix
    pop de
    call modDEIXByBC8
    ld d, e
    call modDEIXByBC8
    ; if the remainder is negative, restore it
    ret nc
    add hl, bc
    ret
; Description: Process an 8-bit chunk of the dividend.
; Input:
;   - D:u8=8-bit chunks of the dividend
; Output:
;   - HL:u16=remainder
;   - CF=1 if remainder is negative
modDEIXByBC8:
    ld a, 8
modDEIXByBC8Loop:
    jp c, modDEIXByBC8Neg
modDEIXByBC8Pos:
    sla d
    adc hl, hl
    jp c, modDEIXByBC8PosOverflow
    sbc hl, bc ; remainder -= divisor
    dec a
    jp nz, modDEIXByBC8Loop
    ret
modDEIXByBC8PosOverflow:
    ; Left-shift of A generated CF=1. Subtract M will always produce a positive
    ; remainder.
    or a
    sbc hl, bc ; remainder -= divisor
    dec a
    jp nz, modDEIXByBC8Pos
    or a ; set CF=0 before returning to indicate positive remainder
    ret
modDEIXByBC8Neg:
    sla d
    adc hl, hl
    jp c, modDEIXByBC8NegOverflow
    ; Left-shift of A generated CF=0. Add M will always generate a negative
    ; remainder.
    add hl, bc ; remainder += divisor
    dec a
    jp nz, modDEIXByBC8Neg
    scf ; set CF=1 returning to indicate negative remainder
    ret
modDEIXByBC8NegOverflow:
    ; Left-shift of A generated CF=1. Add M generates a positive remainder
    ; if CF=1 (which cascades to change the implicit sign bit to 0), or a
    ; negative remainder if CF=0 (retains the implicit sign bit of 1). We can
    ; capture both conditions by inverting the CF using CCF.
    add hl, bc ; remainder += divisor
    ccf
    dec a
    jp nz, modDEIXByBC8Loop
    ret
#endif

;-----------------------------------------------------------------------------

#ifdef MOD_DEIX_BY_BC_NONRESTORING_CHUNK8_REGA
; Description: Calculate mod(u32,u16), i.e. the remainder when a u32 dividend
; is divided by a u16 divisor.
; Input:
;   - DE:u16=high 16 bits of u32 dividend
;   - IX:u16=low 16 bits of u32 dividend
;   - BC:u16=divisor
; Output:
;   - HL:u16=remainder
; Destroys: A, D
; Preserves: BC, E, IX
modDEIXByBC:
    ld hl, 0 ; HL=remainder
    or a ; CF=0
    ld a, d
    call modDEIXByBC8
    ld a, e
    call modDEIXByBC8
    push ix
    pop de
    ld a, d
    call modDEIXByBC8
    ld a, e
    call modDEIXByBC8
    ; if the remainder is negative, restore it
    ret nc
    add hl, bc
    ret
; Description: Process an 8-bit chunk of the dividend.
; Input:
;   - A:u8=8-bit chunks of the dividend
; Output:
;   - HL:u16=remainder
;   - CF=1 if remainder is negative
; Destroys: D
modDEIXByBC8:
    ld d, 8
modDEIXByBC8Loop:
    jp c, modDEIXByBC8Neg
modDEIXByBC8Pos:
    ; We are here if the remainder A is positive.
    rla
    adc hl, hl
    jp c, modDEIXByBC8PosOverflow
    sbc hl, bc ; remainder -= divisor
    dec d
    jp nz, modDEIXByBC8Loop
    ret
modDEIXByBC8PosOverflow:
    ; Left-shift of A generated CF=1. Subtract M will always produce a positive
    ; remainder.
    or a
    sbc hl, bc ; remainder -= divisor
    dec d
    jp nz, modDEIXByBC8Pos
    or a ; set CF=0 before returning to indicate positive remainder
    ret
modDEIXByBC8Neg:
    ; We are here if the remainder A is negative.
    rla
    adc hl, hl
    jp c, modDEIXByBC8NegOverflow
    ; Left-shift of A generated CF=0. Add M will always generate a negative
    ; remainder.
    add hl, bc ; remainder += divisor
    dec d
    jp nz, modDEIXByBC8Neg
    scf ; set CF=1 before returning to indicate negative remainder
    ret
modDEIXByBC8NegOverflow:
    ; Left-shift of A generated CF=1. Add M generates a positive remainder
    ; if CF=1 (which cascades to change the implicit sign bit to 0), or a
    ; negative remainder if CF=0 (retains the implicit sign bit of 1). We can
    ; capture both conditions by inverting the CF using CCF.
    add hl, bc ; remainder += divisor
    ccf
    dec d
    jp nz, modDEIXByBC8Loop
    ret
#endif

;-----------------------------------------------------------------------------

#ifdef MOD_DEIX_BY_BC_NONRESTORING_CHUNK8_REGA_UNROLLED
; Description: Calculate mod(u32,u16), i.e. the remainder when a u32 dividend
; is divided by a u16 divisor.
; Input:
;   - DE:u16=high 16 bits of u32 dividend
;   - IX:u16=low 16 bits of u32 dividend
;   - BC:u16=divisor
; Output:
;   - HL:u16=remainder
; Destroys: AF
; Preserves: BC, DE, IX
modDEIXByBC:
    ld hl, 0 ; HL=remainder
    or a ; CF=0
    ld a, d
    call modDEIXByBC8
    ld a, e
    call modDEIXByBC8
    push ix
    pop de
    ld a, d
    call modDEIXByBC8
    ld a, e
    call modDEIXByBC8
    ; if the remainder is negative, restore it
    ret nc
    add hl, bc
    ret
; Description: Process an 8-bit chunk of the dividend with the 8 loop
; iterations unrolled for performance.
; Input:
;   - A:u8=8-bit chunks of the dividend
; Output:
;   - HL:u16=remainder
modDEIXByBC8:
modDEIXByBC8Bit0:
    jp c, modDEIXByBC8Bit0Neg
modDEIXByBC8Bit0Pos:
    rla
    adc hl, hl
    jp c, modDEIXByBC8Bit0PosOverflow
    sbc hl, bc ; remainder -= divisor
    jp modDEIXByBC8Bit1
modDEIXByBC8Bit0PosOverflow:
    or a
    sbc hl, bc ; remainder -= divisor
    jp modDEIXByBC8Bit1Pos
modDEIXByBC8Bit0Neg:
    rla
    adc hl, hl
    jp c, modDEIXByBC8Bit0NegOverflow
    add hl, bc ; remainder += divisor
    jp modDEIXByBC8Bit1Neg
modDEIXByBC8Bit0NegOverflow:
    add hl, bc ; remainder += divisor
    ccf
;
modDEIXByBC8Bit1:
    jp c, modDEIXByBC8Bit1Neg
modDEIXByBC8Bit1Pos:
    rla
    adc hl, hl
    jp c, modDEIXByBC8Bit1PosOverflow
    sbc hl, bc ; remainder -= divisor
    jp modDEIXByBC8Bit2
modDEIXByBC8Bit1PosOverflow:
    or a
    sbc hl, bc ; remainder -= divisor
    jp modDEIXByBC8Bit2Pos
modDEIXByBC8Bit1Neg:
    rla
    adc hl, hl
    jp c, modDEIXByBC8Bit1NegOverflow
    add hl, bc ; remainder += divisor
    jp modDEIXByBC8Bit2Neg
modDEIXByBC8Bit1NegOverflow:
    add hl, bc ; remainder += divisor
    ccf
;
modDEIXByBC8Bit2:
    jp c, modDEIXByBC8Bit2Neg
modDEIXByBC8Bit2Pos:
    rla
    adc hl, hl
    jp c, modDEIXByBC8Bit2PosOverflow
    sbc hl, bc ; remainder -= divisor
    jp modDEIXByBC8Bit3
modDEIXByBC8Bit2PosOverflow:
    or a
    sbc hl, bc ; remainder -= divisor
    jp modDEIXByBC8Bit3Pos
modDEIXByBC8Bit2Neg:
    rla
    adc hl, hl
    jp c, modDEIXByBC8Bit2NegOverflow
    add hl, bc ; remainder += divisor
    jp modDEIXByBC8Bit3Neg
modDEIXByBC8Bit2NegOverflow:
    add hl, bc ; remainder += divisor
    ccf
;
modDEIXByBC8Bit3:
    jp c, modDEIXByBC8Bit3Neg
modDEIXByBC8Bit3Pos:
    rla
    adc hl, hl
    jp c, modDEIXByBC8Bit3PosOverflow
    sbc hl, bc ; remainder -= divisor
    jp modDEIXByBC8Bit4
modDEIXByBC8Bit3PosOverflow:
    or a
    sbc hl, bc ; remainder -= divisor
    jp modDEIXByBC8Bit4Pos
modDEIXByBC8Bit3Neg:
    rla
    adc hl, hl
    jp c, modDEIXByBC8Bit3NegOverflow
    add hl, bc ; remainder += divisor
    jp modDEIXByBC8Bit4Neg
modDEIXByBC8Bit3NegOverflow:
    add hl, bc ; remainder += divisor
    ccf
;
modDEIXByBC8Bit4:
    jp c, modDEIXByBC8Bit4Neg
modDEIXByBC8Bit4Pos:
    rla
    adc hl, hl
    jp c, modDEIXByBC8Bit4PosOverflow
    sbc hl, bc ; remainder -= divisor
    jp modDEIXByBC8Bit5
modDEIXByBC8Bit4PosOverflow:
    or a
    sbc hl, bc ; remainder -= divisor
    jp modDEIXByBC8Bit5Pos
modDEIXByBC8Bit4Neg:
    rla
    adc hl, hl
    jp c, modDEIXByBC8Bit4NegOverflow
    add hl, bc ; remainder += divisor
    jp modDEIXByBC8Bit5Neg
modDEIXByBC8Bit4NegOverflow:
    add hl, bc ; remainder += divisor
    ccf
;
modDEIXByBC8Bit5:
    jp c, modDEIXByBC8Bit5Neg
modDEIXByBC8Bit5Pos:
    rla
    adc hl, hl
    jp c, modDEIXByBC8Bit5PosOverflow
    sbc hl, bc ; remainder -= divisor
    jp modDEIXByBC8Bit6
modDEIXByBC8Bit5PosOverflow:
    or a
    sbc hl, bc ; remainder -= divisor
    jp modDEIXByBC8Bit6Pos
modDEIXByBC8Bit5Neg:
    rla
    adc hl, hl
    jp c, modDEIXByBC8Bit5NegOverflow
    add hl, bc ; remainder += divisor
    jp modDEIXByBC8Bit6Neg
modDEIXByBC8Bit5NegOverflow:
    add hl, bc ; remainder += divisor
    ccf
;
modDEIXByBC8Bit6:
    jp c, modDEIXByBC8Bit6Neg
modDEIXByBC8Bit6Pos:
    rla
    adc hl, hl
    jp c, modDEIXByBC8Bit6PosOverflow
    sbc hl, bc ; remainder -= divisor
    jp modDEIXByBC8Bit7
modDEIXByBC8Bit6PosOverflow:
    or a
    sbc hl, bc ; remainder -= divisor
    jp modDEIXByBC8Bit7Pos
modDEIXByBC8Bit6Neg:
    rla
    adc hl, hl
    jp c, modDEIXByBC8Bit6NegOverflow
    add hl, bc ; remainder += divisor
    jp modDEIXByBC8Bit7Neg
modDEIXByBC8Bit6NegOverflow:
    add hl, bc ; remainder += divisor
    ccf
;
modDEIXByBC8Bit7:
    jp c, modDEIXByBC8Bit7Neg
modDEIXByBC8Bit7Pos:
    rla
    adc hl, hl
    jp c, modDEIXByBC8Bit7PosOverflow
    sbc hl, bc ; remainder -= divisor
    ret
modDEIXByBC8Bit7PosOverflow:
    or a
    sbc hl, bc ; remainder -= divisor
    or a ; always clear CF
    ret
modDEIXByBC8Bit7Neg:
    rla
    adc hl, hl
    jp c, modDEIXByBC8Bit7NegOverflow
    add hl, bc ; remainder += divisor
    scf
    ret
modDEIXByBC8Bit7NegOverflow:
    add hl, bc ; remainder += divisor
    ccf
;
    ret
#endif

#ifdef MOD_DEIX_BY_BC_NONRESTORING_CALC84MANIAC
; Description: Calculate mod(u32,u16), i.e. the remainder when a u32 dividend is
; divided by a u16 divisor.
; Input:
;   - DE:u16=high 16 bits of u32 dividend
;   - IX:u16=low 16 bits of u32 dividend
;   - BC:u16=divisor
; Output:
;   - HL:u16=remainder
; Destroys: AF, DE
modDEIXByBC:
   ld hl, 0 ; HL=remainder
   scf ; Initialize input CF
   call modBCIter16
   push ix
   pop de
; Process the dividend bits in DE
; Input: HL=remainder, DE=dividend bits, CF is set
; Output: HL=remainder, A=0, CF is set
modBCIter16:
   ld a, d
   call modBCIter8
   ld a, e
; Process the dividend bits in A
; Input: HL=remainder, A=dividend bits, CF is set
; Output: HL=remainder, A=0, CF is set
modBCIter8:
   ; CF is set only on the first iteration
modBCPositiveLoop:
   adc a, a ; Always sets CF when the result is zero
   ret z
modBCPositiveContinue:
   adc hl, hl
   jr c, modBCOverflow ; remainder overflowed, so subtract
modBCNoOverflow:
   sbc hl, bc ; HL(remainder) -= divisor
   jp nc, modBCPositiveLoop
modBCNegativeLoop:
   add a, a
   jr z, modBCNegativeEnd
modBCNegativeContinue:
   adc hl, hl
   jr nc, modBCUnderflow ; remainder underflowed, so add
   add hl, bc ; HL(remainder) += divisor
   jp nc, modBCNegativeLoop
   add a, a ; Always sets CF when the result is zero
   ret z
   adc hl, hl
   jp nc, modBCNoOverflow
modBCOverflow:
   or a ;reset CF
   sbc hl, bc ; HL(remainder) -= divisor
   add a, a ; Always sets CF when the result is zero
   jp nz, modBCPositiveContinue
   ret
;
modBCUnderflow:
   add hl, bc ; HL(remainder) += divisor
   add a, a
   jp nz, modBCNegativeContinue
modBCNegativeEnd:
   add hl, bc ; Restore remainder, always sets CF
   ret
#endif
