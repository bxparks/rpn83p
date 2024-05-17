;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Convert u32 to string.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Routines related to Hex strings.
;-----------------------------------------------------------------------------

; Description: Format the U32 with its status code to a HEX string suitable for
; displaying on the screen using a maximum of 16 digits.
; Input:
;   - HL:(u32*)=inputNumber
;   - DE:(char*)=destString, buffer of at least 12 bytes (8 hex digits + 3
;   spaces + NUL)
;   - C:u8=statusCode
; Output:
;   - (DE) C-string representation of u32, truncated as necessary
; Destroys: A, BC, HL
; Preserves: DE
FormatCodedU32ToHexString:
    ; Check for errors
    bit u32StatusCodeTooBig, c
    jp nz, copyInvalidMessage
    bit u32StatusCodeNegative, c
    jp nz, copyNegativeMessage
    ;
    push bc ; stack=[C=u32StatusCode]
    ; Convert u32 into a hex string.
    call FormatU32ToHexString ; preseves DE=destString
    ex de, hl ; HL=destString
    ; Truncate to baseWordSize
    call truncateHexStringToWordSize ; preserves HL; BC=strLen
    ; Reformat digits in groups of 2.
    call groupHexDigits ; preserves HL
    ; Append frac indicator
    pop bc ; stack=[destString,inputNumber]; C=u32StatusCode
    call appendHasFracPageTwo ; preserves BC, DE, HL
    ex de, hl ; DE=destString
    ret

;-----------------------------------------------------------------------------

hexNumberWidth equ 8 ; 4 bits * 8 = 32 bits

; Description: Converts 32-bit unsigned integer referenced by HL to a hex
; string in buffer referenced by DE.
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

; Description: Truncate the HEX string on the left, leaving the correct number
; of digits on the right that should be displayed given the current
; baseWordSize.
; Input:
;   - HL:(char*)=hexString
; Output:
;   - (HL) updated
;   - BC:u16=displayLen
; Destroys: A, BC, DE
; Preserves: HL
truncateHexStringToWordSize:
    ld a, (baseWordSize)
    srl a
    srl a ; A=displayLen=baseWordSize/4=8,6,4,2
    ;
    ld c, a
    ld b, 0 ; BC=displayLen
    sub 8
    neg ; A=truncLen=8-displayLen
    ret z
    ; [[fallthrough]]

; Description: Truncate string to the left.
; Input:
;   - A:u8=truncLen
;   - BC:displayLen
;   - HL:(char*)=string
; Output:
;   - (HL) string shifted to left by truncLen, terminated with NUL
truncateStringToDisplayLen:
    push hl ; stack=[hexString]
    push bc ; stack=[hexString,displayLen]
    ex de, hl ; DE=hexString
    ld l, a
    ld h, 0
    add hl, de ; HL=hexString+truncLen
    ldir
    ; NUL terminate
    xor a
    ld (de), a
    pop bc ; stack=[hexString]; BC=displayLen
    pop hl ; stack=[]; HL=hexString
    ret

;-----------------------------------------------------------------------------

; Description: Group the hex string into groups of 2 digits starting from
; the least significant digits on the right. This is done in-situ, so the
; buffer must be at least 12 bytes long (8 digits + 3 spaces + 1 NUL).
; Input:
;   - HL:(char*)=inputString
;   - BC:u8=strLen, must be multiple of 2
; Output:
;   - (HL) grouped in 2 digits
; Destroys: BC, DE
; Preserves: HL
groupHexDigits:
    ld a, c
    dec a
    srl a ; A=numExtraSpaces=(strLen-1)/2
    ret z
    ; move pointers to end of digits
    push hl ; stack=[inputString]
    add hl, bc
    ld e, l
    ld d, h
    ; move dest pointer DE by number of expected spaces
    add a, e
    ld e, a
    ld a, d
    adc a, 0
    ld d, a
    ; add NUL terminator, since we are looping backwards
    xor a
    ld (de), a
    dec de
    dec hl
groupHexDigitsLoop:
    ldd
    jp po, groupHexDigitsEnd ; if BC==0: PV=0=po (odd)
    ld a, c
    and $01 ; ZF=1 every 2 digits
    jr nz, groupHexDigitsLoop
    ; add a space
    ld a, ' '
    ld (de), a
    dec de
    jr groupHexDigitsLoop
groupHexDigitsEnd:
    pop hl ; stack=[]; HL=inputString
    ret

;-----------------------------------------------------------------------------
; Routines related to Octal strings.
;-----------------------------------------------------------------------------

; Description: Format the U32 with its status code to a HEX string suitable for
; displaying on the screen using a maximum of 16 digits.
; Input:
;   - HL:(u32*)=inputNumber
;   - DE:(char*)=destString, buffer of at least 12 bytes (8 hex digits + 3
;   spaces + NUL)
;   - C:u8=statusCode
; Output:
;   - (DE) C-string representation of u32, truncated as necessary
; Destroys: A, BC, HL
; Preserves: DE
FormatCodedU32ToOctString:
    ; Check for errors
    bit u32StatusCodeTooBig, c
    jp nz, copyInvalidMessage
    bit u32StatusCodeNegative, c
    jp nz, copyNegativeMessage
    ;
    push bc ; stack=[C=u32StatusCode]
    ; Convert u32 into a hex string.
    call FormatU32ToOctString ; preseves DE=destString
    ex de, hl ; HL=destString
    ; truncate to baseWordSize
    call truncateOctStringToWordSize
    ; TODO: group in 3's
    ; Append frac indicator
    pop bc ; stack=[destString,inputNumber]; C=u32StatusCode
    call appendHasFracPageTwo ; preserves BC, DE, HL
    ex de, hl ; DE=destString
    ret

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

; Description: Truncate the OCT string on the left, leaving the correct number
; of digits on the right that should be displayed given the current
; baseWordSize.
; Input:
;   - HL:(char*)=octString
; Output:
;   - (HL) updated
;   - BC:u16=displayLen
; Destroys: A, BC, DE
; Preserves: HL
truncateOctStringToWordSize:
    call displayableOctDigits ; A=displayLen
    ld c, a
    ld b, 0 ; BC=displayLen
    sub 11
    neg ; A=truncLen=11-displayLen
    ret z
    jr truncateStringToDisplayLen

; Description: Get the number of displayable OCT digits for the current
; baseWordSize: {8: 3, 16: 6, 24: 8, 32: 11}
; Output: A:u8=displayLen
; Destroys: A
displayableOctDigits:
    ld a, (baseWordSize)
    cp 8
    jr z, displayableOctDigits8
    cp 16
    jr z, displayableOctDigits16
    cp 24
    jr z, displayableOctDigits24
    jr displayableOctDigits32
displayableOctDigits8:
    ld a, 3
    ret
displayableOctDigits16:
    ld a, 6
    ret
displayableOctDigits24:
    ld a, 8
    ret
displayableOctDigits32:
    ld a, 11
    ret

;-----------------------------------------------------------------------------
; Routines related to Binary strings.
;-----------------------------------------------------------------------------

; Description: Format the U32 with its status code to a BIN string suitable for
; displaying on the screen using a maximum of 16 digits.
; Input:
;   - HL:(u32*)=inputNumber
;   - DE:(char*)=destString, buffer of at least 33 bytes (32 binary digits plus
;   NUL)
;   - C:u8=statusCode
; Output:
;   - (DE) C-string representation of u32, truncated as necessary
; Destroys: A, BC, HL
; Preserves: DE
FormatCodedU32ToBinString:
    ; Check for errors
    bit u32StatusCodeTooBig, c
    jp nz, copyInvalidMessage
    bit u32StatusCodeNegative, c
    jp nz, copyNegativeMessage
    ;
    push bc ; stack=[C=u32StatusCode]
    ; Convert HL=u32 into a base-2 string.
    call FormatU32ToBinString ; DE=destString
    ex de, hl ; HL=destString
    ; Truncate leading digits to fit display
    call truncateBinDigits ; HL=destString; A=strLen
    ; Reformat digits in groups of 4.
    call groupBinDigits ; HL=destString; preserves HL
    ; Append frac indicator
    pop bc ; stack=[destString,inputNumber]; C=u32StatusCode
    call appendHasFracPageTwo ; preserves BC, DE, HL
    ; Convert to small font equivalents.
    call convertBinDigitsToSmallFont ; preserves AF, HL
    ex de, hl ; DE=destString
    ret

;-----------------------------------------------------------------------------

binNumberWidth equ 32

; Description: Converts 32-bit unsigned integer referenced by HL to a binary
; string in buffer referenced by DE.
; Input:
;   - HL:(u32*)
;   - DE:(char*)=stringPointer, at least 33 bytes (32 binary digits plus NUL)
; Output:
;   - (DE) formatted 32-digit string, NUL terminated
; Destroys: A
; Preserves: BC, DE, HL
FormatU32ToBinString:
    push bc
    push hl
    push de
    ; prepare loop
    ld b, binNumberWidth
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
    ;
    pop de
    pop hl
    pop bc
    ret

;------------------------------------------------------------------------------

maxBinDisplayDigits equ 16

; Description: Truncate in situ the upper digits of the formatted base-2 string
; depending on baseWordSize .
;
; 1) Calculate the effective number of digits that can be displayed is
; `strLen = min(baseWordSize, maxBinDisplayDigits)`.
; 2) Scan all digits above strLen and look for a '1'. If a '1' exists at digit
; >= strLen, remember this situation.
; 3) Shift all lower digits to the left, truncating the upper digits.
; 4) If non-zero digits were truncatedthen replace the left most character with
; an Lellipsis character to indicate truncation.
;
; Input:
;   - HL:(char*)=inputString=u32 as string (32 characters)
; Output:
;   - HL:(char*)=inputString
;   - (HL) truncated (shifted left)
;   - A:u8=displayLen=8 or 16
; Destroys: A, BC, DE
; Preserves: HL
truncateBinDigits:
    ; compute displayLen
    ld a, (baseWordSize)
    cp maxBinDisplayDigits ; if baseWordSize < maxBinDisplayDigits: CF=1
    jr c, truncateBinDigitsCalcTruncationLen
    ld a, maxBinDisplayDigits ; displayLen=min(baseWordSize,maxBinDisplayDigits)
truncateBinDigitsCalcTruncationLen:
    ; A=displayLen=8 or 16
    push af ; stack=[displayLen]
    sub 32 ; max number of digits
    neg ; A=truncationLen=(32-displayLen)=16 or 24
    ; Check leading digits to determine if truncation causes overflow
    ld b, a
    ld c, 0 ; C=foundOneDigit:boolean
    push hl ; stack=[displayLen, inputString]
truncateBinDigitsCheckOverflow:
    ld a, (hl)
    inc hl ; HL=left most digit of the truncated string.
    sub '0'
    or c ; check for a non-zero digit
    ld c, a
    djnz truncateBinDigitsCheckOverflow
    ; If a 'non-zerodigit found, replace left most displayed char with ellipsis
    jr z, truncateBinDigitsShiftLeft ; if C=0: ZF=1, indicating no overflow
    ld a, Lellipsis
    ld (hl), a
truncateBinDigitsShiftLeft:
    ; Shift displayable chars to left
    pop de ; stack=[displayLen]; DE=inputString
    pop af ; A=displayLen
    push de ; stack=[inputString]
    ld c, a
    ld b, 0 ; BC=displayLen
    ldir ; shift
    ex de, hl
    ld (hl), b ; NUL terminate the new string
    ex de, hl
    pop hl ; stack=[]; HL=inputString
    ret

;------------------------------------------------------------------------------

; Description: Group the binary string into groups of 4 digits starting from
; the least significant digits on the right. This is done in-situ, so the
; buffer must be at least 40 bytes long (32 digits + 7 spaces + 1 NUL).
; Input:
;   - A:u8=strLen, must be multiple of 4
;   - HL:(char*)=inputString
; Output:
;   - (HL)=groupedString
; Destroys: AF, BC, DE
; Preserves: HL
groupBinDigits:
    or a
    ret z ; ret if strLen==0
    push hl
    ld b, 0
    ld c, a ; BC=strLen=numCharToShift
    ; move pointer to the end of string
    add hl, bc
    ld e, l
    ld d, h
    ; numSpaces=(strLen-1)/4
    dec a
    srl a
    srl a
    ; move dest pointer DE by number of expected spaces
    add a, e
    ld e, a
    ld a, d
    adc a, 0
    ld d, a
    ; nul terminate the destString, since we are looping backwards
    xor a
    ld (de), a
    dec de
    dec hl
groupBinDigitsLoop:
    ldd
    jp po, groupBinDigitsEnd ; if BC==0: PV=0=po (odd)
    ld a, c
    and $03 ; ZF=1 every 4 digits
    jr nz, groupBinDigitsLoop
    ; add a space
    ld a, ' '
    ld (de), a
    dec de
    jr groupBinDigitsLoop
groupBinDigitsEnd:
    pop hl
    ret

;------------------------------------------------------------------------------

; Description: Convert large font characters to small font characters which
; look better in small font:
;
;   - Lellipsis -> Sleft
;   - Lspace -> SFourSpaces
;
; Input: HL:(char*)
; Output: (HL)=convertedString
; Destroys: none
; Preserves: AF, BC, DE, HL
convertBinDigitsToSmallFont:
    push af
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
    pop af
    ret

;-----------------------------------------------------------------------------
; Routines related to Dec strings (as integers).
;-----------------------------------------------------------------------------

; Description: Format the U32 with its status code to a DEC string suitable for
; displaying on the screen using a maximum of 10 digits.
; Input:
;   - HL:(u32*)=inputNumber
;   - DE:(char*)=destString, buffer of at least 11 bytes (10 dec digits + NUL)
;   - C:u8=statusCode
; Output:
;   - (DE) C-string representation of u32, truncated as necessary
; Destroys: A, BC, HL
; Preserves: DE
FormatCodedU32ToDecString:
    ; Check for errors
    bit u32StatusCodeTooBig, c
    jp nz, copyInvalidMessage
    bit u32StatusCodeNegative, c
    jp nz, copyNegativeMessage
    ;
    push bc ; stack=[C=u32StatusCode]
    ; Convert u32 into a hex string.
    call FormatU32ToDecString ; preseves DE=destString
    ex de, hl ; HL=destString
    ; Append frac indicator
    pop bc ; stack=[destString,inputNumber]; C=u32StatusCode
    call appendHasFracPageTwo ; preserves BC, DE, HL
    ex de, hl ; DE=destString
    ret

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

;-----------------------------------------------------------------------------
; Common helper routines.
;-----------------------------------------------------------------------------

; Description: Append a '.' at the end of the string if u32StatusCode contains
; u32StatusCodeHasFrac.
; Input:
;   - C:u8=u32StatusCode
;   - HL:(char*)
; Output:
;   - (HL)='.' appended if u32StatusCodehasFrac is enabled
; Destroys: A
; Preserves, BC, DE, HL
appendHasFracPageTwo:
    bit u32StatusCodeHasFrac, c
    ret z
    ld a, '.'
    call appendCStringPageTwo
    ret

;-----------------------------------------------------------------------------

; Description: Append the invalid integer message to the destination buffer.
; Input:
;   - DE:(char*)=dest
; Output:
;   - DE with the "invalid" message
; Destroys: A, BC, HL
; Preserves: DE
copyInvalidMessage:
    push de
    ld hl, msgBaseInvalidPageTwo
    call copyCStringPageTwo
    pop de
    ret

; Indicates number has overflowed the current Base mode.
msgBaseInvalidPageTwo:
    .db "...", 0

; Description: Append the negative integer message to the destination buffer.
; Input:
;   - DE:(char*)=dest
; Output:
;   - DE with the "invalid" message
; Destroys: A, BC, HL
; Preserves: DE
copyNegativeMessage:
    push de
    ld hl, msgBaseNegativePageTwo
    call copyCStringPageTwo
    pop de
    ret

; Indicates number is negative so cannot be rendered in Base mode.
msgBaseNegativePageTwo:
    .db "-", 0
