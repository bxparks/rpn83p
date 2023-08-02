;------------------------------------------------------------------------------
; Functions related to parsing the inputBuf into a floating point number.
;------------------------------------------------------------------------------

; Description: Initialize variables and flags related to the input buffer.
; Output:
;   - inputBuf set to empty
;   - rpnFlagsEditing reset
; Destroys: A
initInputBuf:
    res rpnFlagsEditing, (iy + rpnFlags)
    ; [[fallthrough]]

; Function: Clear the inputBuf.
; Input: inputBuf
; Output:
;   - inputBuf cleared
;   - inputBufEEPos set to 0
;   - inputBufEELen set to 0
;   - inputBufFlagsInputDirty set
; Destroys: none
clearInputBuf:
    push af
    xor a
    ld (inputBuf), a
    ld (inputBufEEPos), a
    ld (inputBufEELen), a
    res inputBufFlagsDecPnt, (iy + inputBufFlags)
    res inputBufFlagsEE, (iy + inputBufFlags)
    set inputBufFlagsInputDirty, (iy + inputBufFlags)
    pop af
    ret

; Function: Append character to inputBuf.
; Input:
;   A: character to be appended
; Output:
;   - CF set when append fails
;   - inputBufFlagsInputDirty set
; Destroys: all
appendInputBuf:
    ld hl, inputBuf
    ld b, inputBufMax
    set inputBufFlagsInputDirty, (iy + inputBufFlags)
    jp appendString

;------------------------------------------------------------------------------

initArgBuf:
    res rpnFlagsArgMode, (iy + rpnFlags)
    ; [[fallthrough]]

clearArgBuf:
    xor a
    ld (argBuf), a
    res rpnFlagsArgMode, (iy + rpnFlags)
    ret

; Input: A: character to append
; Destroys: B, HL
appendArgBuf:
    set inputBufFlagsInputDirty, (iy + inputBufFlags)
    ld hl, argBuf
    ld b, a
    ld a, (hl)
    cp argBufSizeMax
    ret nc ; limit total number of characters
    ld a, b
    ld b, argBufMax
    jp appendString

; Description: Convert (0 to 2 digit) argBuf into a binary number.
; Input: argBuf
; Output: A: value of argBuf
; Destroys: A, B, C, HL
parseArgBuf:
    ld hl, argBuf
    ld b, (hl) ; B = argBufSize
    inc hl
    ; check for 0 digit
    ld a, b
    or a
    ret z
    ; A = current sum
    xor a
    ; check for 1 digit
    dec b
    jr z, parseArgBufOneDigit
parseArgBufTwoDigits:
    call parseArgBufOneDigit
    ; C = C * 10 = C * (2 * 5)
    ld c, a
    add a, a
    add a, a
    add a, c ; A = 5 * C
    add a, a
parseArgBufOneDigit:
    ld c, a
    ld a, (hl)
    inc hl
    sub '0'
    add a, c
    ret ; A = current sum

;------------------------------------------------------------------------------

; Function: Parse the input buffer into the parseBuf.
; Input: inputBuf filled with keyboard characters
; Output: OP1: floating point number
; Destroys: all registers?
parseNum:
    call parseNumInit
    call checkZero
    ret z
    call calcDPPos
    call extractMantissaExponent ; extract mantissa exponent to floatBuf
    call extractMantissaSign ; extract mantissa sign to floatBuf
    call parseMantissa ; parse mantissa digits from inputBuf into parseBuf
    call extractMantissa ; copy mantissa digits from parseBuf into floatBuf
    call parseExponent ; parse EE digits from inputBuf
    call addExponent ; add EE exponent to floatBuf exponent
    call copyFloatToOP1 ; copy floatBuf to OP1
    ret

;------------------------------------------------------------------------------

; Function: Initialize the parseBuf.
; Input: none
; Output: (parseBuf) cleared
; Destroys: all
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

; Function: Set floatBuf to 0.0.
clearFloatBuf:
    bcall(_OP1Set0)
    ld de, floatBuf
    bcall(_MovFrOP1)
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
    cp signChar
    jr z, checkZeroContinue
    cp '.'
    jr z, checkZeroContinue
    ret ; returns with ZF=0
checkZeroContinue:
    inc hl
    djnz checkZeroLoop
    xor a ; set ZF=1
    ret

;------------------------------------------------------------------------------

; Function: Parse the mantissa digits from inputBuf into parseBuf, ignoring
; negative sign, leading zeros, the decimal point, and the EE symbol. For
; example:
;   - "0.1" produces "1"
;   - "-001.2" produces "12"
;   - "23E-1" produces "23"
; Input: inputBuf
; Output: parseBuf filled with mantissa digits
; Destroys: all registers
parseMantissaLeadingFound equ 0 ; bit to set when lead digit found
parseMantissa:
    ld hl, inputBuf
    ld a, (hl) ; A = inputBufSize
    or a
    ret z
    ld b, a ; B = inputBufSize
    res parseMantissaLeadingFound, c
    inc hl
parseMantissaLoop:
    ld a, (hl)
    cp Lexponent
    ret z ; terminate loop at "E"
    cp signChar
    jr z, parseMantissaContinue
    cp '.'
    jr z, parseMantissaContinue
    cp '0'
    jr nz, parseMantissaNormalDigit
    ; Check if we found leading digit.
    bit parseMantissaLeadingFound, c
    jr z, parseMantissaContinue
parseMantissaNormalDigit:
    set parseMantissaLeadingFound, c
    push hl
    push bc
    call appendParseBuf
    pop bc
    pop hl
parseMantissaContinue:
    inc hl
    djnz parseMantissaLoop
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
;       if (c == 'E') break; // hit exponent symbol
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
    ; break if EE symbol
    cp Lexponent
    jr z, calcDPEnd
    ; ignore and skip '-'
    cp signChar
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
; Output: CF set when append fails
; Destroys: A, B, DE, HL
appendParseBuf:
    ld hl, parseBuf
    ld b, parseBufMax
    jp appendString

;------------------------------------------------------------------------------

; Function: Set the exponent from the mantissa. The mantissaExp =
; decimalPointPos - 1. But the floating exponent is shifted by $80.
;   mantissaExponent = decimalPointPos - 1
;   floatingExponent = mantissaExponent + $80
;                    = decimalPointPos + $7F
;
; Input: A: decimalPointPos (from calcDPPos())
; Output: floatBufExp = decimalPointPos + $7F
; Destroys: A
extractMantissaExponent:
    add a, $7F
    ld (floatBufExp), a
    ret

; Function: Extract mantissa sign from the first character in the inputBuf.
; Input: inputBuf
; Output: floatBuf sign set
; Destroys: HL
extractMantissaSign:
    ld hl, inputBuf
    ld a, (hl)
    or a
    ret z ; empty string, assume positive
    inc hl
    ld a, (hl)
    cp signChar
    ret nz ; '-' not found at first character
    ld hl, floatBufType
    set 7, (hl)
    ret

; Function: Extract the normalized mantissa digits from parseBuf to floatBuf, 2
; digits per byte.
; Input: parseBuf
; Output:
; Destroys: A, BC, DE, HL
extractMantissa:
    ld hl, parseBuf
    ld a, (hl)
    or a
    ret z
    inc hl
    ld de, floatBufMan
    ld b, parseBufMax/2
extractMantissaLoop:
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
    djnz extractMantissaLoop
    ret

; Function: Copy floatBuf into OP1
copyFloatToOP1:
    ld hl, floatBuf
    bcall(_Mov9ToOP1)
    ret

;-----------------------------------------------------------------------------

; Description: Parse the digits after the 'E' symbol in the inputBuf.
; Input: inputBuf
; Output: A: the exponent, in two's complement form
; Destroys: A, BC, DE, HL
; TODO: Instead of relying on inputBufEEPos and inputBufEELen, scan for 'E' and
; parse out the exponent digits. This would remove the dependency to those 2
; variables, and decouple the parsing routines from the input/editing routines.
parseExponent:
    ld b, 0 ; B=exponent value
    ; Return if no 'E' symbol
    ld a, (inputBufEEPos)
    ld e, a ; E=EEpos
    or a
    ld a, b
    ret z
    ; Return if no digits after 'E'
    ld a, (inputBufEELen)
    ld c, a ; C=EELen
    or a
    ld a, b
    ret z
    ; Check for minus sign
    ld hl, inputBuf
    ld d, 0
    add hl, de
    inc hl ; HL=pointer to first digit of EE
    ld a, (hl)
    cp signChar
    jr z, parseExponentSetSign
    res inputBufFlagsExpSign, (iy+inputBufFlags)
    jr parseExponentDigits
parseExponentSetSign:
    inc hl
    set inputBufFlagsExpSign, (iy+inputBufFlags)
parseExponentDigits:
    ; Convert 1 or 2 digits of the exponent to 2's complement number in A
    ld a, c ; A=EELen
    cp 1
    jr z, parseExponentOneDigit
parseExponentTwoDigits:
    ld a, (hl) ; first of 2 digits
    inc hl
    sub '0'
    ; multiply by 10
    add a, a
    ld c, a ; C=2*A
    add a, a
    add a, a ; A=8*A
    add a, c ; A=10*A
    ld b, a ; save B
parseExponentOneDigit:
    ld a, (hl) ; second of 2 digits,or first of 1 digit
    sub '0'
    add a, b
parseExponentNegIfSign:
    bit inputBufFlagsExpSign, (iy+inputBufFlags)
    ret z
    neg
    ret

; Description: Add the exponent in A to the floatBuf exponent.
; Input: A: EE exponent parsed from inputBuf
; Output: (floatBuf exponent) += A
; Destroys: A, B, HL
addExponent:
    ld b, a
    ld hl, floatBufExp
    ld a, (hl)
    sub $80
    add a, b ; 2's complement
    add a, $80
    ld (hl), a
    ret
