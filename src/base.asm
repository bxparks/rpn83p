;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Routines to handle calculations in different bases (2, 8, 10, 16).
;-----------------------------------------------------------------------------

initBase:
    res rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ld a, 10
    ld (baseNumber), a
    xor a
    ld (baseCarryFlag), a
    ld a, 32
    ld (baseWordSize), a
    ret

; Description: Return the offset corresponding to each of the potential values
; of (baseWordSize). For the values of (8, 16, 24, 32) this returns (0, 1, 2,
; 3). Throws Err:Domain if not 8, 16, 24, 32.
; Input: (baseWordSize)
; Output: A=(baseWordSize)/8-1
; Destroys: A
getBaseOffset:
    push bc
    ld a, (baseWordSize)
    ld b, a
    and $07 ; 0b0000_0111
    jr nz, getBaseOffsetErr
    ld a, b
    rrca
    rrca
    rrca
    dec a
    ld b, a
    and $FC ; 0b1111_1100
    ld a, b
    pop bc
    ret z
getBaseOffsetErr:
    bcall(_ErrDomain)

;-----------------------------------------------------------------------------
; Routines for converting floating point to U32 and back.
;-----------------------------------------------------------------------------

convertOP1ToU32Error:
    bjump(_ErrDomain) ; throw exception

; Description: Same as convertOP1ToU32NoCheck() but throws an Err:Domain
; exception if OP1 is not in the range of [0, 2^32). Floating point values are
; allowed, but the fractional digits are ignored when converting to U32.
; Input:
;   - OP1: unsigned 32-bit integer as a floating point number
;   - HL: pointer to a u32 in memory
; Output:
;   - HL: OP1 converted to a u32, in little-endian format
; Destroys: A, B, C, DE
; Preserves: HL, OP1, OP2
convertOP1ToU32:
    push hl
    bcall(_PushRealO2)
    call op2Set2Pow32
    bcall(_CpOP1OP2) ; if OP1 >= 2^32: CF=0
    jr nc, convertOP1ToU32Error
    bcall(_CkOP1FP0) ; if OP1 == 0: ZF=1
    jr z, convertOP1ToU32Valid
    bcall(_CkOP1Pos) ; if OP1 > 0: ZF=1
    jr nz, convertOP1ToU32Error
convertOP1ToU32Valid:
    bcall(_PopRealO2)
    pop hl
    ; [[fallthrough]]

; Description: Convert floating point OP1. This routine assume that OP1 is a
; floating point number between [0, 2^32). Fractional digits are ignored when
; converting to U32 integer. Use convertOP1ToU32() to perform a validation
; check that throws an exception.
; Input:
;   - OP1: unsigned 32-bit integer as a floating point number
;   - HL: pointer to a u32 in memory
; Output:
;   - HL: OP1 converted to a u32, in little-endian format
; Destroys: A, B, DE
; Preserves: HL, C
convertOP1ToU32NoCheck:
    ; initialize the target u32
    call clearU32
    bcall(_CkOP1FP0) ; preserves HL
    ret z
    ; extract number of decimal digits
    ld de, OP1+1 ; exponent byte
    ld a, (de)
    sub $7F ; A = exponent + 1 = num digits in mantissa
    ld b, a ; B = num digits in mantissa
    jr convertOP1ToU32LoopEntry
convertOP1ToU32Loop:
    call multU32By10
convertOP1ToU32LoopEntry:
    ; get next 2 digits of mantissa
    inc de ; DE = pointer to mantissa
    ld a, (de)
    ; Process first mantissa digit
    rrca
    rrca
    rrca
    rrca
    and $0F
    call addU32U8
    ; check number of mantissa digits
    dec b
    ret z
convertOP1ToU32SecondDigit:
    ; Process second mantissa digit
    call multU32By10
    ld a, (de)
    and $0F
    call addU32U8
    djnz convertOP1ToU32Loop
    ret

; Description: Same as convertOP1ToU32() except using OP2.
; Input:
;   - OP2: unsigned 32-bit integer as a floating point number
;   - HL: pointer to a u32 in memory
; Destroys: A, B, C, DE
; Preserves: HL, OP1, OP2
convertOP2ToU32:
    push hl
    bcall(_OP1ExOP2)
    pop hl
    push hl
    call convertOP1ToU32
    bcall(_OP1ExOP2)
    pop hl
    ret

;-----------------------------------------------------------------------------

; Description: Convert the u32 referenced by HL to a floating point number in
; OP1.
; Input: HL: pointer to u32 (must not be OP2)
; Output: OP1: floating point equivalent of u32(HL)
; Destroys: A, B, C, DE
; Preserves: HL, OP2
convertU32ToOP1:
    push hl
    bcall(_PushRealO2)
    bcall(_OP1Set0)
    pop hl

    inc hl
    inc hl
    inc hl ; HL points to most significant byte

    ld a, (hl)
    dec hl
    call addU8ToOP1

    ld a, (hl)
    dec hl
    call addU8ToOP1

    ld a, (hl)
    dec hl
    call addU8ToOP1

    ld a, (hl)
    call addU8ToOP1

    push hl
    bcall(_PopRealO2)
    pop hl
    ret

; Description: Convert the u8 in A to floating pointer number in OP1.
; Input:
;   - A: u8 integer
; Output:
;   - OP1: floating point value of A
; Destroys: A, B, DE, OP2
; Preserves: C, HL
convertU8ToOP1:
    push af
    bcall(_OP1Set0)
    pop af
    ; [[fallthrough]]

; Description: Convert the u8 in A to floating point number, and add it to OP1.
; Input:
;   - A: u8 integer
;   - OP1: current floating point value, set to 0.0 to start fresh
; Destroys: A, B, DE, OP2
; Preserves: C, HL
addU8ToOP1:
    push hl
    ld b, 8 ; loop for 8 bits in u8
addU8ToOP1Loop:
    push bc
    push af
    bcall(_Times2) ; OP1 *= 2
    pop af
    sla a
    jr nc, addU8ToOP1Check
    push af
    bcall(_Plus1) ; OP1 += 1
    pop af
addU8ToOP1Check:
    pop bc
    djnz addU8ToOP1Loop
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
convertU32ToDecString:
    push bc
    push hl
    push de ; push destination buffer last
    ld b, decNumberWidth
convertU32ToDecStringLoop:
    ; convert to decimal integer, but the characters are in reverse order
    push de
    ld d, 10
    call divU32U8 ; u32(HL)=quotient, D=10, E=remainder
    ld a, e
    call convertAToChar
    pop de
    ld (de), a
    inc de
    djnz convertU32ToDecStringLoop
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

    ld a, b
    srl a
    ld b, a ; B = num / 2
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
