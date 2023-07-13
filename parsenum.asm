;------------------------------------------------------------------------------
; Functions related to parsing the inputBuf into a floating point number.
;------------------------------------------------------------------------------

; Function: Parse the input buffer into the parseBuf.
; Input: inputBuf filled with keyboard characters
; Output: parseBuf filled
; Destroys: all registers?
parseNum:
    call parseNumInit
    call checkZero
    ret z
    call calcDPPos
    call debugSignedA ; Display the decimal point pos. TODO: Remove.
    call extractExponent
    call extractSign
    call extractMantissa ; extract digits into parseBuf
    call copyMantissa ; copy digits into floatBuf
    call copyFloatToOP1 ; copy floatBuf to OP1
    call debugOP1
    ret

; Function: Initialize the parseBuf.
; Input: none
; Output: (parseBuf) cleared
; Destroys: A, HL
parseNumInit:
    call clearParseBuf
    call clearFloatBuf
    ret

; Function: Clear parseBuf by setting all digits to the character '0', and
; setting size to 0. The trailing '0' characters make it easy to construct the
; floating point number.
clearParseBuf:
    xor a
    ld hl, parseBuf
    ld (hl), a
    ld a, '0'
    ld b, parseBufMax
    inc hl
clearParseBufLoop:
    ld (hl), a
    inc hl
    djnz clearParseBufLoop
    ret

; Function: Clear floatBuf by setting every to $00.
clearFloatBuf:
    ld b, floatBufSizeOf
    ld hl, floatBuf
clearFloatLoop:
    ld (hl), a
    inc hl
    djnz clearFloatLoop
    ret

;------------------------------------------------------------------------------

; Function: Check if the inputBuf is effectively '0'. In other words, if
; the inputBuf is composed of characters only in the set ['-', '.', '0'], then
; it is effectively zero. Otherwise, not zero.
; Input: inputBuf
; Output: Z set if zero, otherwise not set
; Destroys: A, B, HL
checkZero:
    ld hl, inputBuf
    ld a, (hl) ; A = inputBufSize
    ; Check for empty
    or a
    ret z
    ; Check for any characters other than 0, '-', '.'
    inc hl
    ld b, a
checkZeroLoop:
    ld a, (hl)
    cp '0'
    jr z, checkZeroContinue
    cp '-'
    jr z, checkZeroContinue
    cp '.'
    jr z, checkZeroContinue
    ret ; returns with Z=0
checkZeroContinue:
    inc hl
    djnz checkZeroLoop
    xor a ; set Z=1
    ret

;------------------------------------------------------------------------------

; Function: Extract the mantissa digits from inputBuf into parseBuf, ignoring
; negative sign, leading zeros, and even the decimal point. For example, "0.1"
; produces "1", and "-001.2" produces "12".
; Input: inputBuf
; Output: parseBuf filled with mantissa digits
; Destroys: all registers
extractMantissaLeadingFound equ 0 ; bit to set when lead digit found
extractMantissa:
    ld hl, inputBuf
    ld a, (hl) ; A = inputBufSize
    or a
    ret z
    ld b, a ; B = inputBufSize
    res extractMantissaLeadingFound, c
    inc hl
extractMantissaLoop:
    ld a, (hl)
    cp '-'
    jr z, extractMantissaContinue
    cp '.'
    jr z, extractMantissaContinue
    cp '0'
    jr nz, extractMantissaNormalDigit
    ; Check if we found leading digit.
    bit extractMantissaLeadingFound, c
    jr z, extractMantissaContinue
extractMantissaNormalDigit:
    set extractMantissaLeadingFound, c
    push hl
    push bc
    call appendParseBuf
    pop bc
    pop hl
extractMantissaContinue:
    inc hl
    djnz extractMantissaLoop
    ret

;------------------------------------------------------------------------------

; Function: Find the position of the decimal point of the given number string.
; Input: assumes non-empty inputBuf
; Output: A = decimal point position, signed integer
; Destroys: all
;
; The returned value is the number of places the the decimal point needs to be
; shifted to get back the original value after the mantissa is normalized with
; the leading non-zero digit immediately to the right of the decimal place. The
; normalized mantissa lies in the interval [0.1, 1.0). The shift can be a
; negative number for values less than 0.1.
;
; For example, the following unnormalized number strings should return the
; indicated decimal point position:
;
;   - "123.4" ->  .1234, 3
;   - "012" ->  .12, 2
;   - "12" ->  .12, 2
;   - "1.2" ->  .12, 1
;   - ".12" -> .12, 0
;   - "0.123" -> .123, 0
;   - ".012" -> .12, -1
;   - "000.0012" -> .12, -2
;
; Here is the algorithm written in C:
;
; int8_t calcDPPos(const char *s, uint8_t stringSize) {
;   bool leadingFound = false;
;   bool dotFound = false;
;   int_t pos = 0;
;   for (int i = 0; i < stringSize; i++) {
;       char c = s[i];
;       if (c == '-') continue;
;       if (c == '.') {
;           dotFound = true;
;           continue;
;       }
;       // '0' is special only if no leading digit found yet
;       if (c == '0' && !leadingFound) {
;           if (dotFound) {
;               pos--;
;           }
;       } else {
;           // if leading has already been found, treat
;           // '0' just like any other character
;           leadingFound = true;
;           if (!dotFound) {
;               pos++;
;           }
;       }
;   }
;   return pos;
calcDPLeadingFound equ 0 ; set if leading (non-zero) digit found
calcDPDotFound equ 1; set if decimal point found
calcDPPos:
    ld hl, inputBuf
    ld b, (hl) ; stringSize
    xor a
    ld c, a ; pos
    ld d, a ; flags
    inc hl
calcDPLoop:
    ld a, (hl)
    ; ignore and skip '-'
    cp '-'
    jr z, calcDPContinue
    ; check for '.'
    cp '.'
    jr nz, calcDPZero
    set calcDPDotFound, d
    jr calcDPContinue
calcDPZero:
    ; check for '0'
    cp '0'
    jr nz, calcDPNormalDigit
    bit calcDPLeadingFound, d
    jr nz, calcDPNormalDigit
calcDPUpdatePos:
    bit calcDPDotFound, d
    jr z, calcDPContinue
    dec c
    jr calcDPContinue
calcDPNormalDigit:
    set calcDPLeadingFound, d
    bit calcDPDotFound, d
    jr nz, calcDPContinue
    inc c
calcDPContinue:
    inc hl
    djnz calcDPLoop
calcDPEnd:
    ld a, c
    ret

;------------------------------------------------------------------------------

; Function: Append character to parseBuf
; Input:
;   A: character to be appended
; Output: Carry flag set when append fails
; Destroys: A, B, DE, HL
appendParseBuf:
    ld hl, parseBuf
    ld b, parseBufMax
    jp appendString

;------------------------------------------------------------------------------

; Function: Set the exponent: exp = decimalPointPos - 1. But exp is shifted by
; $80, so exp = decimalPointPos - 1 + $80 = deimalPointPos + $7F.
; Input: A: decimalPointPos
; Output: (floatBufExp) = decimalPoint + $7F
; Destroys: A
extractExponent:
    add a, $7F
    ld (floatBufExp), a
    ret

; Function: Transfer the sign to the floatBuf.
; Input: inputBuf
; Output: floatBuf sign set
; Destroys: HL
extractSign:
    ld hl, inputBufFlags
    bit inputBufFlagsManSign, (hl)
    ret z
    ld hl, floatBufType
    set 7, (hl)
    ret

; Function: Copy normalized mantissa digits from parseBuf to floatBuf, 2 digits
; per byte.
; Input: parseBuf
; Output:
; Destroys: A, BC, DE, HL
copyMantissa:
    ld hl, parseBuf
    ld a, (hl)
    or a
    ret z
    inc hl
    ld de, floatBufMan
    ld b, parseBufMax/2
copyMantissaLoop:
    ; Loop 2 digits at a time.
    ld a, (hl)
    sub '0'
    sla a
    sla a
    sla a
    sla a
    ld c, a
    inc hl
    ld a, (hl)
    sub '0'
    or c
    ld (de), a
    inc de
    inc hl
    djnz copyMantissaLoop
    ret

; Function: Copy floatBuf into OP1
copyFloatToOP1:
    ld hl, floatBuf
    bcall(_Mov9ToOP1)
    ret
