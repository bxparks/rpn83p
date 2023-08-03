; Routines to handle calculations in different bases (2, 8, 10, 16).

initBase:
    ld a, 10
    ld (baseMode), a
    ret

;-----------------------------------------------------------------------------

; Description: Convert floating point OP1 (assumed to be an integer between
; [0, 2^32-1] to a 32-bit binary number.
; Input: OP1: unsigned 32-bit integer as a floating point number
; Output: OP3: 32-bit integer, little endian
; Destroys: A, B, DE, HL
convertOP1ToU32OP3:
    ; initialize sum variable OP3
    ld hl, 0
    ld (OP3), hl
    ld (OP3+2), hl

    ; test for OP1==0
    bcall(_CkOP1FP0)
    ret z

    ; extract number of decimal digits
    ld hl, OP1+1 ; exponent byte
    ld a, (hl)
    sub $7F ; A = exponent + 1 = num digits in mantissa
    ld b, a ; B = num digits in mantissa
    inc hl ; HL = pointer to mantissa
    jr convertOP1ToU32LoopEntry

convertOP1ToU32Loop:
    call calcOP3Times10
convertOP1ToU32LoopEntry:
    ; get next 2 digits of mantissa
    ld a, (hl)
    inc hl

    ; Process first mantissa digit
    ld c, a ; C = A (saved)
    srl a
    srl a
    srl a
    srl a
    call convertOP1ToU32AddAToOP3

    ; check number of mantissa digits
    djnz convertOP1ToU32SecondDigit
    ret

convertOP1ToU32SecondDigit:
    ; Process second mantissa digit
    call calcOP3Times10
    ld a, c
    and a, $0F
    call convertOP1ToU32AddAToOP3
    djnz convertOP1ToU32Loop
    ret

; Description: Add the value in A to the u32 in OP3.
; Output: OP3 += A
; Destroys: OP3, OP2
convertOP1ToU32AddAToOP3:
    push hl
    ld hl, OP2 ; HL = OP2
    call clearU32 ; OP2 = 0
    ld (hl), a ; OP2 = A
    ld de, OP3
    call calcU32PlusU32 ; OP3=OP2 + A; HL=OP2
    pop hl
    ret

; Description: OP3 = 10*OP3
; Destroys: OP4
; Preserves: all registers
calcOP3Times10:
    push de
    push hl ; HL = OP1 mantissa
    ld de, OP4
    ld hl, OP3
    call calcU32Times10 ; OP4 = 10 * OP3
    ex de, hl ; DE = OP3; HL = OP4
    call copyU32 ; OP3 = 10 * OP3
    pop hl
    pop de
    ret

;-----------------------------------------------------------------------------
; Routines related to U32 stored as 4 bytes in little endian format.
;-----------------------------------------------------------------------------

; Description: Calculate (DE) = u32(HL) * 10.
; Input:
;   - HL: pointer to a u32 integer, little-endian format
;   - DE: pointer to destination u32
; Output: DE = HL * 10
; Destroys: none
calcU32Times10:
    push af
    call copyU32 ; (DE) = (HL)
    ; (DE) = 5 * (DE)
    ex de, hl ; HL = destination, DE = original
    call calcU32Times2 ; (HL) *= 2
    call calcU32Times2 ; (HL) *= 2
    ex de, hl
    call  calcU32PlusU32 ; (DE) = 5*(HL)
    ; (DE) = 10*(HL)
    ex de, hl
    call calcU32Times2 ; (HL) *= 2
    ex de, hl ; (DE) = (HL)
    pop af
    ret

; Description: Calculate (HL) = u32(HL) * 2.
; Input: HL: pointer to a u32 integer in little-endian format.
; Output: u32 pointed by HL is doubled
; Destroys: none
calcU32Times2:
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

; Description: Calculate (DE) = u32(DE) + u32(HL).
; Input:
;   - HL: pointer to a u32 integer in little-endian format.
;   - DE: pointer to destinatioin u32 integer in little-endian format.
; Output:
;   - (DE) += (HL)
; Destroys: A
; Preserves: DE, HL, (HL)
calcU32PlusU32:
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
