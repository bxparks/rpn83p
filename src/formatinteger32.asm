;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Convert u32 to string.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Routines related to Hex strings.
;-----------------------------------------------------------------------------

hexNumberWidth equ 8 ; 4 bits * 8 = 32 bits

; Description: Converts 32-bit unsigned integer referenced by HL to a hex
; string in buffer referenced by DE.
; TODO: It might be possible to combine formatU32ToHexString(),
; formatU32ToOctString(), and formatU32ToBinString() into a single routine.
;
; Input:
;   - HL: pointer to 32-bit unsigned integer
;   - DE: pointer to a C-string buffer of at least 9 bytes (8 digits plus NUL
;   terminator). This will usually be one of the OPx registers each of them
;   being 11 bytes long.
; Output:
;   - (DE): C-string representation of u32 as hexadecimal
; Destroys: A
; Preserves: BC, DE, HL
formatU32ToHexString:
    push bc
    push hl
    push de

    ld b, hexNumberWidth
formatU32ToHexStringLoop:
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
    djnz formatU32ToHexStringLoop
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
; Preserves: BC, DE, HL
formatU32ToOctString:
    push bc
    push hl
    push de

    ld b, octNumberWidth
formatU32ToOctStringLoop:
    ld a, (hl)
    and $07 ; last 3 bits
    add a, '0' ; convert to octal
    ld (de), a
    inc de
    call shiftRightLogicalU32
    call shiftRightLogicalU32
    call shiftRightLogicalU32
    djnz formatU32ToOctStringLoop
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

binNumberWidth equ 32

; Description: Converts 32-bit unsigned integer referenced by HL to a binary
; string in buffer referenced by DE.
; Input:
;   - HL: pointer to 32-bit unsigned integer
;   - DE: pointer to a C-string buffer of at least 33 bytes (32 binary digits
;   plus NUL terminator). This will usually be 3 consecutive OPx registers,
;   each 11 bytes long, for a total of 33 bytes.
; Output:
;   - (DE): C-string representation of u32 as binary digits
; Destroys: A
; Preserves: BC, DE, HL
formatU32ToBinString:
    push bc
    push hl
    push de

    ld b, binNumberWidth ; 14 bits maximum
formatU32ToBinStringLoop:
    ld a, (hl)
    and $01 ; last bit
    add a, '0' ; convert to '0' or '1'
    ld (de), a
    inc de
    call shiftRightLogicalU32
    djnz formatU32ToBinStringLoop
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

;-----------------------------------------------------------------------------
; Routines related to Dec strings (as integers).
;-----------------------------------------------------------------------------

decNumberWidth equ 10 ; 2^32 needs 10 digits

; Description: Converts 32-bit unsigned integer referenced by HL to a hex
; string in buffer referenced by DE.
; Input:
;   - HL: pointer to 32-bit unsigned integer
;   - DE: pointer to a C-string buffer of at least 11 bytes (10 digits plus NUL
;   terminator). This will usually be one of the OPx registers each of them
;   being 11 bytes long.
; Output:
;   - (DE): C-string representation of u32 as hexadecimal
; Destroys: A
; Preserves: BC, DE, HL
formatU32ToDecString:
    push bc
    push hl
    push de ; push destination buffer last
    ld b, decNumberWidth
formatU32ToDecStringLoop:
    ; convert to decimal integer, but the characters are in reverse order
    push de
    ld d, 10
    call divU32ByD ; u32(HL)=quotient, D=10, E=remainder
    ld a, e
    call convertAToChar
    pop de
    ld (de), a
    inc de
    djnz formatU32ToDecStringLoop
    xor a
    ld (de), a ; NUL termination

    ; truncate trailing '0' digits, and reverse the string
    pop hl ; HL = destination string pointer
    push hl
    ld b, decNumberWidth
    call truncateTrailingZeros ; B=length of new string
    call reverseString ; reverse the characters

    pop de
    pop hl
    pop bc
    ret

;-----------------------------------------------------------------------------

; Description: Truncate the trailing zero-digits. This assumes that the number
; is in reverse digit format, so the trailing zeros are the leading zeros. If
; the string is all '0' digits, then the final string is a string with a single
; "0".
; Input:
;   - HL=pointer to NUL terminated string
;   - B=length of string, can be 0
; Output:
;   - u32(HL)=string with truncated zeros
;   - B=new length of string
; Destroys: A, B
; Preserves: C, DE, HL
truncateTrailingZeros:
    ld a, b
    or a
    ret z
    push hl
    push de
    ld e, b
    ld d, 0
    add hl, de ; HL points to NUL at end of string
truncateTrailingZerosLoop:
    dec hl
    ld a, (hl)
    cp '0'
    jr nz, truncateTrailingZerosEnd
    djnz truncateTrailingZerosLoop
    ; If we get to here, all digits were '0', and there is only on digit
    ; remaining. So set the new length to be 1.
    inc b
truncateTrailingZerosEnd:
    inc hl
    ld (hl), 0 ; insert new NUL terminator just after the last non-zero-digit
    pop de
    pop hl
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

    srl b ; B = num / 2
    ret z ; NOTE: Failing to check for this zero took 2 days to debug!
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
