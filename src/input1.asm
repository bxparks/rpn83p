;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Functions related to parsing the inputBuf into a floating point number.
;
; This is now on Flash Page 1. Labels with Capital letters are intended to be
; exported to other flash pages and should be placed in the branch table on
; Flash Page 0. Labels with lowercase letters are intended to be private so do
; not need a branch table entry.
;------------------------------------------------------------------------------

; Description: Initialize variables and flags related to the input buffer.
; Output:
;   - inputBuf set to empty
;   - rpnFlagsEditing reset
; Destroys: A
InitInputBuf:
    res rpnFlagsEditing, (iy + rpnFlags)
    ; [[fallthrough]]

; Description: Clear the inputBuf.
; Input: inputBuf
; Output:
;   - inputBuf cleared
;   - inputBufEEPos set to 0
;   - inputBufEELen set to 0
;   - dirtyFlagsInput set
; Destroys: none
ClearInputBuf:
    push af
    xor a
    ld (inputBuf), a
    ld (inputBufEEPos), a
    ld (inputBufEELen), a
    res inputBufFlagsDecPnt, (iy + inputBufFlags)
    res inputBufFlagsEE, (iy + inputBufFlags)
    set dirtyFlagsInput, (iy + dirtyFlags)
    pop af
    ret

; Description: Append character to inputBuf.
; Input:
;   A: character to be appended
; Output:
;   - CF set when append fails
;   - dirtyFlagsInput set
; Destroys: all
AppendInputBuf:
    ld c, a ; C=char
    call GetWordSizeDigits ; A=maxDigits
    cp inputBufCapacity ; if maxDigits>=inputBufCapacity: CF=0
    jr c, appendInputBufContinue
    ld a, inputBufCapacity ; A=min(maxDigits,inputBufCapacity)
appendInputBufContinue:
    ld b, a ; B=maxDigits
    ld a, c ; A=char
    ld hl, inputBuf
    set dirtyFlagsInput, (iy + dirtyFlags)
    jp AppendString

; Description: Close the input buffer by parsing the input, then copying the
; float value into X. If not in edit mode, no need to parse the inputBuf, the X
; register is not changed. Almost all functions/commands in RPN83P will call
; this function through the closeInput() function.
;
; This function determines 2 flags which affect the stack lift:
;
; - rpnFlagsLiftEnabled: *Always* set after this call. It is up to the calling
; handler to override this default and disable it if necessary (e.g. ENTER, or
; Sigma+).
; - inputBufFlagsClosedEmpty: Set if the inputBuf was an empty string before
; being closed. This flag is cleared if the inputBuf was *not* in edit mode to
; begin with.
;
; The rpnFlagsLiftEnabled is used by the next manual entry of a number (digits
; 0-9 usualy, sometimes A-F in hexadecimal mode). Usually, the next manual
; number entry lifts the stack, but this flag can be used to disable that.
; (e.g. ENTER will disable the lift of the next number).
;
; The inputBufFlagsClosedEmpty flag is used by functions which do not consume
; any value from the RPN stack, but simply push a value or two onto the X or Y
; registers (e.g. PI, E, or various TVM functions, various STAT functions). If
; the user had pressed CLEAR, to clear the input buffer, then it doesn't make
; sense for these functions to lift the empty string (i.e. 0) up when pushing
; the new values. These functions call pushX() or pushXY() which checks if the
; inputBuf was closed when empty. If empty, pushX() or pushXY() will *not* lift
; the stack, but simply replace the "0" in the X register with the new value.
; This flag is cleared if the inputBuf was not in edit mode, with the
; assumption that new X or Y values should lift the stack.
;
; Input:
;   - inputBuf: input buffer
; Output:
;   - rpnFlagsLiftEnabled: always set
;   - inputBufFlagsClosedEmpty: set if inputBuf was an empty string when closed
;   - inputBuf cleared to empty string
;   - OP1: value of inputBuf
; Destroys: all, OP1, OP2, OP4
CloseInputBuf:
    ld a, (inputBuf)
    or a
    jr z, closeInputBufEmpty
    ; inputBuf not empty
    res inputBufFlagsClosedEmpty, (iy + inputBufFlags)
    jr closeInputBufContinue
closeInputBufEmpty:
    set inputBufFlagsClosedEmpty, (iy + inputBufFlags)
closeInputBufContinue:
    call parseNum
    jp ClearInputBuf

;------------------------------------------------------------------------------

; Description: Parse the input buffer into the parseBuf.
; Input: inputBuf filled with keyboard characters
; Output: OP1: floating point number
; Destroys: all registers
parseNum:
    call parseNumInit
    call checkZero
    ret z
    ld hl, inputBuf
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    jr nz, parseBaseInteger
parseFloat:
    ; Parse floating point.
    call calcDPPos
    call extractMantissaExponent ; extract mantissa exponent to floatBuf
    call extractMantissaSign ; extract mantissa sign to floatBuf
    call parseMantissa ; parse mantissa digits from inputBuf into parseBuf
    call extractMantissa ; copy mantissa digits from parseBuf into floatBuf
    call parseExponent ; parse EE digits from inputBuf
    call addExponent ; add EE exponent to floatBuf exponent
    call copyFloatToOP1 ; copy floatBuf to OP1
    ret

parseBaseInteger:
    ld a, (baseNumber)
    cp 16
    jr z, parseNumBase
    cp 8
    jr z, parseNumBase
    cp 2
    jr z, parseNumBase
    cp 10
    jr z, parseNumBase
    ; all others interpreted as base 10
    ld a, 10
    ld (baseNumber), a
    ; [[fallthrough]]

; Description: Parse the baseNumber in the Pascal-string given by HL. The base
; mode be 2, 8 or 16. This subroutine will actually supports any baseNumber <=
; 36 probably (10 numerals and 26 letters).
; Input:
;   - HL: pointer to Pascal-string
;   - A: base mode (2, 8, 10, 16)
; Output: OP1: floating point value
; Destroys: all
parseNumBase:
    push hl
    bcall(_SetXXOP1) ; OP1 = A = base
    bcall(_OP1ToOP4) ; OP4 = base
    bcall(_OP1Set0)
    pop hl
    ld a, (hl) ; num of digits
    or a
    ret z
    ld b, a ; num digits
parseNumBaseLoop:
    ; multiply by 10 before the next digit
    push bc
    push hl
    bcall(_OP4ToOP2) ; OP2 = base
    bcall(_FPMult) ; OP1 *= base; destroys OP3
    pop hl
    inc hl
    ld a, (hl)
    ; convert char into digit value
    cp 'A'
    jr c, parseNumBase0To9
parseNumBaseAToF:
    sub 'A'
    add a, 10
    jr parseNumBaseAddDigit
parseNumBase0To9:
    sub '0'
parseNumBaseAddDigit:
    push hl
    bcall(_SetXXOP2) ; OP2 = A = digit value
    bcall(_FPAdd) ; OP1 += OP2
    pop hl
    pop bc
    djnz parseNumBaseLoop
    ret

;------------------------------------------------------------------------------

; Description: Initialize the parseBuf.
; Input: none
; Output: (parseBuf) cleared
; Destroys: all
parseNumInit:
    call clearParseBuf
    call clearFloatBuf
    ret

; Description: Clear parseBuf by setting all digits to the character '0', and
; setting size to 0. The trailing '0' characters make it easy to construct the
; floating point number.
clearParseBuf:
    xor a
    ld hl, parseBuf
    ld (hl), a
    ld a, '0'
    ld b, parseBufCapacity
    inc hl
clearParseBufLoop:
    ld (hl), a
    inc hl
    djnz clearParseBufLoop
    ret

; Description: Set floatBuf to 0.0.
clearFloatBuf:
    bcall(_OP1Set0)
    ld de, floatBuf
    bcall(_MovFrOP1)
    ret

;------------------------------------------------------------------------------

; Description: Check if the inputBuf is effectively '0'. In other words, if
; the inputBuf is composed of characters only in the set ['-', '.', '0'], then
; it is effectively zero. Otherwise, not zero.
; Input: inputBuf
; Output: Z set if zero, otherwise not set
; Destroys: A, B, HL
checkZero:
    ld hl, inputBuf
    ld a, (hl) ; A = inputBufLen
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

; Description: Parse the mantissa digits from inputBuf into parseBuf, ignoring
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
    ld a, (hl) ; A = inputBufLen
    or a
    ret z
    ld b, a ; B = inputBufLen
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

; Description: Find the position of the decimal point of the given number
; string.
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

; Description: Append character in A to parseBuf
; Input:
;   - A: character to be appended
; Output:
;   - CF set when append fails
; Destroys: all
appendParseBuf:
    ld hl, parseBuf
    ld b, parseBufCapacity
    jp AppendString

;------------------------------------------------------------------------------

; Description: Set the exponent from the mantissa. The mantissaExp =
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

; Description: Extract mantissa sign from the first character in the inputBuf.
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

; Description: Extract the normalized mantissa digits from parseBuf to
; floatBuf, 2
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
    ld b, parseBufCapacity/2
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

; Description: Copy floatBuf into OP1
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
