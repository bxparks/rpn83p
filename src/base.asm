;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Routines to handle calculations in different bases (2, 8, 10, 16).
;-----------------------------------------------------------------------------

initBase:
    ld a, 10
    ld (baseMode), a
    ret

;-----------------------------------------------------------------------------
; Routines for converting floating point to U32 and back.
;-----------------------------------------------------------------------------

; Description: Convert floating point OP1 (assumed to be an integer between
; [0, 2^32-1] to a 32-bit binary number.
; Input:
;   - OP1: unsigned 32-bit integer as a floating point number
;   - HL: pointer to a u32 in memory
; Output:
;   - HL: OP1 converted to a u32, in little-endian format
; Destroys: A, B, C, DE
; Preserves: HL
convertOP1ToU32:
    ; initialize the target u32
    call clearU32
    bcall(_CkOP1FP0) ; preserves HL
    ret z

    ; extract number of decimal digits
    ld de, OP1+1 ; exponent byte
    ld a, (de)
    sub $7F ; A = exponent + 1 = num digits in mantissa
    ld b, a ; B = num digits in mantissa
    inc de ; DE = pointer to mantissa
    jr convertOP1ToU32LoopEntry

convertOP1ToU32Loop:
    call multU32By10
convertOP1ToU32LoopEntry:
    ; get next 2 digits of mantissa
    ld a, (de)
    inc de

    ; Process first mantissa digit
    ld c, a ; C = A (saved)
    srl a
    srl a
    srl a
    srl a
    call addU32U8

    ; check number of mantissa digits
    djnz convertOP1ToU32SecondDigit
    ret

convertOP1ToU32SecondDigit:
    ; Process second mantissa digit
    call multU32By10
    ld a, c
    and a, $0F
    call addU32U8
    djnz convertOP1ToU32Loop
    ret

;-----------------------------------------------------------------------------

; Description: Convert the u32 referenced by HL to a floating point number in
; OP1.
; Input: HL: pointer to u32
; Ouptut: OP1: floating point equivalent of u32(HL)
; Destroys: A, B
; Preserves: HL
convertU32ToOP1:
    push hl
    bcall(_OP1Set0)
    pop hl

    inc hl
    inc hl
    inc hl ; HL points to most significant byte

    ld a, (hl)
    dec hl
    call convertU8ToOP1

    ld a, (hl)
    dec hl
    call convertU8ToOP1

    ld a, (hl)
    dec hl
    call convertU8ToOP1

    ld a, (hl)
    call convertU8ToOP1

    ret

; Description: Convert the u8 in A to floating point number, and add it to OP1.
; Input:
;   - A: u8 integer
;   - OP1: current floating point value, set to 0.0 to start fresh
; Destroys: A, B
; Preserves: C, HL
convertU8ToOP1:
    push hl
    ld b, 8 ; loop for 8 bits in u8
convertU8ToOP1Loop:
    push bc
    push af
    bcall(_Times2) ; OP1 *= 2
    pop af
    sla a
    jr nc, convertU8ToOP1Check
    push af
    bcall(_Plus1) ; OP1 += 1
    pop af
convertU8ToOP1Check:
    pop bc
    djnz convertU8ToOP1Loop
    pop hl
    ret

;-----------------------------------------------------------------------------
; Routines related to U32 stored as 4 bytes in little endian format.
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
    call multU32By2 ; (HL) *= 2
    call multU32By2 ; (HL) *= 2

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

    call multU32By2 ; (HL) = 2 (HL) = 10 * (original HL)

    pop de
    pop bc
    ret

; Description: Calculate (HL) = u32(HL) * 2.
; Input: HL: pointer to a u32 integer in little-endian format.
; Output: u32 pointed by HL is doubled
; Destroys: none
multU32By2:
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

; Description: Add A to U32 pointed by HL.
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

; Description: Calculate (DE) = u32(DE) + u32(HL).
; Input:
;   - HL: pointer to a u32 integer in little-endian format.
;   - DE: pointer to destination u32 integer in little-endian format.
; Output:
;   - (DE) += (HL)
; Destroys: A
; Preserves: DE, HL, (HL)
addU32U32:
    push hl
    push de

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
    ret

; Description: Copy the u32 integer from HL to DE.
; Input:
;   - HL: pointer to source u32
;   - DE: pointer to destination u32
; Destroys: A
copyU32:
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

; Description: Shift U32 right logical.
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

; Description: Perform binary AND operation.
; Input:
;   - HL: pointer to U32
;   - DE: pointer to U32
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

; Description: Perform binary OR operation.
; Input:
;   - HL: pointer to U32
;   - DE: pointer to U32
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

; Description: Perform binary XOR operation.
; Input:
;   - HL: pointer to U32
;   - DE: pointer to U32
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

; Description: Perform NOT (1's complement) operation.
; Input:
;   - HL: pointer to U32
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

; Description: Perform NEG (2's complement negative) operation.
; Input:
;   - HL: pointer to U32
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
; Routines related to Hex strings.
;-----------------------------------------------------------------------------

hexNumberWidth equ 8 ; 4 bits * 8 = 32 bits

; Description: Converts 32-bit unsigned integer referenced by HL to a hex
; string in buffer referenced by DE.
; TODO: It might be possible to combine convertU32ToHexString(),
; convertU32ToOctString(), and convertU32ToBinString() into a single routine.
;
; Input:
;   - HL: pointer to 32-bit unsigned integer
;   - DE: pointer to a C-string buffer of at least 9 bytes (8 digits plus NUL
;   terminator). This will usually be one of the OPx registers each of them
;   being 11 bytes long.
; Output:
;   - (DE): C-string representation of u32 as hexadecimal
; Destroys: A
convertU32ToHexString:
    push bc
    push hl
    push de

    ld b, hexNumberWidth
convertU32ToHexStringLoop:
    ; convert to hexadecimal, but the characters are in reverse order
    ld a, (hl)
    and $0F ; last 4 bits
    call convertAToChar
    ld (de), a
    inc de
    call shiftRightLogicalU32
    call shiftRightLogicalU32
    call shiftRightLogicalU32
    call shiftRightLogicalU32
    djnz convertU32ToHexStringLoop
    xor a
    ld (de), a ; NUL termination

    ; reverse the characters
    pop hl ; HL = destination string pointer
    push hl
    ld b, hexNumberWidth
    call reverseString

    pop de
    pop hl
    pop bc
    ret

;-----------------------------------------------------------------------------

; Description: Reverses the chars of the string referenced by HL.
; Input:
;   - HL: reference to C-string
;   - B: number of characters
; Output: string in (HL) reversed
; Destroys: A, B, DE, HL
reverseString:
    ; test for 0-length string
    ld a, b
    or a
    ret z

    ld e, b
    ld d, 0
    ex de, hl
    add hl, de
    ex de, hl ; DE = DE + B = end of string
    dec de

    ld a, b
    srl a
    ld b, a ; B = num / 2
reverseStringLoop:
    ld a, (de)
    ld c, (hl)
    ld (hl), a
    ld a, c
    ld (de), a
    inc hl
    dec de
    djnz reverseStringLoop
    ret

;-----------------------------------------------------------------------------
; Routines related to Octal strings.
;-----------------------------------------------------------------------------

octNumberWidth equ 11 ; 3 bits * 11 = 33 bits

; Description: Converts 32-bit unsigned integer referenced by HL to a octal
; string in buffer referenced by DE.
; Input:
;   - HL: pointer to 32-bit unsigned integer
;   - DE: pointer to a C-string buffer of at least 12 bytes (11 octal digits
;   plus NUL terminator). This will usually be 2 consecutive OPx registers,
;   each 11 bytes long, for a total of 22 bytes.
; Output:
;   - (DE): C-string representation of u32 as octal digits
; Destroys: A
convertU32ToOctString:
    push bc
    push hl
    push de

    ld b, octNumberWidth
convertU32ToOctStringLoop:
    ld a, (hl)
    and $07 ; last 3 bits
    add a, '0' ; convert to octal
    ld (de), a
    inc de
    call shiftRightLogicalU32
    call shiftRightLogicalU32
    call shiftRightLogicalU32
    djnz convertU32ToOctStringLoop
    xor a
    ld (de), a ; NUL terminator

    ; reverse the octal digits
    pop hl ; HL = destination string pointer
    push hl
    ld b, octNumberWidth
    call reverseString

    pop de
    pop hl
    pop bc
    ret

;-----------------------------------------------------------------------------
; Routines related to Binary strings.
;-----------------------------------------------------------------------------

binNumberWidth equ 14

; Description: Converts 32-bit unsigned integer referenced by HL to a binary
; string in buffer referenced by DE.
; Input:
;   - HL: pointer to 32-bit unsigned integer
;   - DE: pointer to a C-string buffer of at least 15 bytes (14 binary digits
;   plus NUL terminator). This will usually be 2 consecutive OPx registers,
;   each 11 bytes long, for a total of 22 bytes.
; Output:
;   - (DE): C-string representation of u32 as octal digits
; Destroys: A
convertU32ToBinString:
    push bc
    push hl
    push de

    ld b, binNumberWidth ; 14 bits maximum
convertU32ToBinStringLoop:
    ld a, (hl)
    and $01 ; last bit
    add a, '0' ; convert to '0' or '1'
    ld (de), a
    inc de
    call shiftRightLogicalU32
    djnz convertU32ToBinStringLoop
    xor a
    ld (de), a ; NUL terminator

    ; reverse the binary digits
    pop hl ; HL = destination string pointer
    push hl
    ld b, binNumberWidth
    call reverseString

    pop de
    pop hl
    pop bc
    ret
