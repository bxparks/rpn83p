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
; TODO: It might be possible to combine FormatU32ToHexString(),
; FormatU32ToOctString(), and FormatU32ToBinString() into a single routine.
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
FormatU32ToHexString:
    push bc
    push hl
    push de

    ld b, hexNumberWidth
formatU32ToHexStringLoop:
    ; convert to hexadecimal, but the characters are in reverse order
    ld a, (hl)
    and $0F ; last 4 bits
    call convertAToCharPageTwo
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
    call reverseStringPageTwo

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
FormatU32ToOctString:
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
    call reverseStringPageTwo

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
FormatU32ToBinString:
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
    call reverseStringPageTwo

    pop de
    pop hl
    pop bc
    ret

;------------------------------------------------------------------------------

; Description: Truncate upper digits depending on baseWordSize. The effective
; number of digits that can be displayed is `strLen = min(baseWordSize, 12)`.
; Then scan all digits above strLen and look for a '1'. If a '1' exists at
; digit >= strLen, replace the left most digit of the truncated string with an
; Lellipsis character.
;
; Input:
;   - HL:(char*)=inputString=u32 as string (32 characters)
; Output:
;   - HL:(char*)=truncatedString
;   - A:u8=displayLen=8 or 16
; Destroys: A, BC
maxBinDisplayDigits equ 16
TruncateBinDigits:
    ld a, (baseWordSize)
    cp maxBinDisplayDigits ; if baseWordSize < maxBinDisplayDigits: CF=1
    jr c, truncateBinDigitsContinue
    ld a, maxBinDisplayDigits ; displayLen=min(baseWordSize,maxBinDisplayDigits)
truncateBinDigitsContinue:
    ; A=displayLen=8 or 16
    push af ; stack=[displayLen]
    sub 32
    neg ; A=numLeadingdigits=32-strLen=16 or 24
    ; Check leading digits to determine if truncation causes overflow
    ld b, a
    ld c, 0 ; C=foundOneDigit:boolean
truncateBinDigitsCheckOverflow:
    ld a, (hl)
    inc hl ; HL=left most digit of the truncated string.
    sub '0'
    or c ; check for a '1' digit
    ld c, a
    djnz truncateBinDigitsCheckOverflow
    jr z, truncateBinDigitsNoOverflow ; if C=0: ZF=1, indicating no overflow
    ; Replace left most digit with ellipsis symbol to indicate overflow.
    ld a, Lellipsis
    ld (hl), a
truncateBinDigitsNoOverflow:
    pop af ; stack=[]; A=displayLen
    ret

;------------------------------------------------------------------------------

; Description: Format the binary string into groups of 4 digits.
; Input:
;   - HL:(char*), <= 16 digits.
;   - A:u8=strLen
;   - DE:(char*)=string buffer of >= 20 bytes (including NUL string). Must not
;   overlap with HL.
; Output:
;   - DE:(char*)=formattedString
; Destroys: A, BC
; Preserves: DE, HL
FormatBinDigits: ; TODO: Rename to ReformatBinDigits().
    push de
    push hl
    ld b, 0
    ld c, a
formatBinDigitsLoop:
    ldi
    jp po, formatBinDigitsEnd ; if BC==0: PV=0=po (odd)
    ld a, c
    and $03 ; every group of 4 digits (right justified), add a space
    jr nz, formatBinDigitsLoop
    ld a, ' '
    ld (de), a
    inc de
    jr formatBinDigitsLoop
formatBinDigitsEnd:
    xor a
    ld (de), a ; terminating NUL
    pop hl
    pop de
    ret

; Description: Convert large font characters to small font characters which
; look better in small font:
;   - Lellipsis -> Sleft
;   - Lspace -> SFourSpaces
;
; Input: HL:(char*)
; Output: (HL)=convertedString
; Destroys: A
ConvertBinDigitsToSmallFont:
    push hl
    jr convertBinDigitsToSmallFontLoopEntry
convertBinDigitsToSmallFontLoop:
    inc hl
convertBinDigitsToSmallFontLoopEntry:
    ld a, (hl)
    or a
    jr z, convertBinDigitsToSmallFontEnd
    ;
    cp Lellipsis
    jr nz, convertBinDigitsToSmallFontCheckSpace
    ld a, Sleft
    ld (hl), a
    jr convertBinDigitsToSmallFontLoop
convertBinDigitsToSmallFontCheckSpace:
    cp Lspace
    jr nz, convertBinDigitsToSmallFontLoop
    ld a, SFourSpaces
    ld (hl), a
    jr convertBinDigitsToSmallFontLoop
convertBinDigitsToSmallFontEnd:
    pop hl
    ret

;------------------------------------------------------------------------------

; Description: Reformat the base-2 string in groups of 4, 2 groups per line.
; The source string is probably at OP4. The destination string is probably OP3,
; which is 11 bytes before OP4. The original string is a maximum of 32
; characters long. The formatted string adds 2 characters per line, for a
; maximum of 8 characters, which is less than the 11 bytes that OP3 is before
; OP4. Therefore the formatting can be done in-situ because at every point in
; the iteration, the resulting string does not affect the upcoming digits.
;
; The maximum length of the final string is 4 lines * 10 bytes = 40 bytes,
; which is smaller than the 44 bytes available using OP3-OP6.
;
; Input:
;   - HL:(char*)=source base-2 string (probably OP4)
;   - DE:(char*)=destination string buffer (sometimes OP3)
; Output:
;   - (DE): base-2 string formatted in lines of 8 digits, in 2 groups of 4
;   digits
;   - DE updated
ReformatBaseTwoString:
    call getWordSizeIndex
    inc a ; A=baseWordSize/8=number of bytes
    ld b, a
reformatBaseTwoStringLoop:
    push bc
    ld bc, 4
    ldir
    ld a, ' '
    ld (de), a
    inc de
    ;
    ld bc, 4
    ldir
    ld a, Lenter
    ld (de), a
    inc de
    ;
    pop bc
    djnz reformatBaseTwoStringLoop
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
FormatU32ToDecString:
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
    call convertAToCharPageTwo
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
    call reverseStringPageTwo

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
