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
;   - dirtyFlagsInput set
; Destroys: none
ClearInputBuf:
    push af
    xor a
    ld (inputBuf), a
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
    call getInputMaxLen ; A=inputMaxLen
    cp inputBufCapacity ; if inputMaxLen>=inputBufCapacity: CF=0
    jr c, appendInputBufContinue
    ld a, inputBufCapacity ; A=min(inputMaxLen,inputBufCapacity)
appendInputBufContinue:
    ld b, a ; B=inputMaxLen
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
    call parseInputBuf ; OP1=float
    jp ClearInputBuf

;------------------------------------------------------------------------------

; Description: Check various characteristics of the characters in the inputBuf
; by scanning backwards from the end of the string. The following conditions
; are checked:
;   - inputBufStateDecimalPoint: set if decimal point exists
;   - inputBufStateEE: set if exponent 'E' character exists
;   - inputBufStateComplex: set if complex number
;   - inputBufEEPos: pos of char after 'E', or the first character of the
;   number component if no 'E'
;   - inputBufEELen: number of EE digits if inputBufStateEE is set
; Input: inputBuf
; Output:
;   - C: inputBufState flags updated
;   - D: inputBufEEPos, pos of char after 'E' or at start of number
;   - E: inputBufEELen, number of EE digits if inputBufStateEE is set
; Destroys: BC, DE, HL
; Preserves: AF
GetInputBufState:
    push af
    ld hl, inputBuf
    ld c, (hl) ; C=len
    ld b, 0 ; BC=len
    inc hl ; skip past len byte
    add hl, bc ; HL=pointer to end of string
    ; swap B and C
    ld a, c ; A=len
    ld c, b ; C=inputBufState=0
    ld b, a ; B=len
    ; check for len==0
    or a ; if len==0: ZF=0
    jr z, getInputBufStateEnd
    ; D=inputBufEEPos=0; E=inputBufEELen=0
    ld de, 0
getInputBufStateLoop:
    ; Loop backwards from end of string and update inputBufState flags
    dec hl
    ld a, (hl)
    ; check for '0'-'9'
    call isValidUnsignedDigit ; if valid: CF=1
    jr nc, getInputBufStateCheckDecimalPoint
    ; if not EE: increment inputBufEELen
    bit inputBufStateEE, c
    jr nz, getInputBufStateCheckDecimalPoint
    inc e ; inputBufEELen++
getInputBufStateCheckDecimalPoint:
    cp '.'
    jr nz, getInputBufStateCheckEE
    set inputBufStateDecimalPoint, c
getInputBufStateCheckEE:
    cp Lexponent
    jr nz, getInputBufStateCheckTermination
    set inputBufStateEE, c
    ld d, b ; inputBufEEPos=B
getInputBufStateCheckTermination:
    cp LimagI
    jr z, getInputBufStateComplex
    cp Langle
    jr z, getInputBufStateComplex
    cp Ltheta
    jr z, getInputBufStateComplex
    ; Loop until we reach the start of string
    djnz getInputBufStateLoop
    jr getInputBufStateEnd
getInputBufStateComplex:
    set inputBufStateComplex, c
getInputBufStateEnd:
    ; If no 'E', set inputBufEEPos to the start of current number, which could
    ; be the imaginary or angle part of a complex number.
    bit inputBufStateEE, c
    jr nz, getInputBufStateReturn
    ld d, b
getInputBufStateReturn:
    pop af
    ret

;------------------------------------------------------------------------------

; Description: Parse the input buffer into OP1.
; Input: inputBuf filled with keyboard characters
; Output: OP1: floating point number
; Destroys: all registers
parseInputBuf:
    call parseNumInit ; OP1=0.0
    call checkZero ; ZF=1 if inputBuf is zero
    ret z
    ld hl, inputBuf
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    jr nz, parseBaseInteger
    ; [[fallthrough]]

; Description: Parse the floating point number at HL.
; Input: HL: pointer to a Pascal string of a floating point number
; Output: OP1: floating point number
; Destroys: all
parseFloat:
    ld hl, inputBuf
    inc hl
    call calcDPPos ; A=i8(decimalPointPos)
    call extractMantissaExponent ; extract mantissa exponent to floatBuf
    call extractMantissaSign ; extract mantissa sign to floatBuf
    call parseMantissa ; parse mantissa digits from inputBuf into parseBuf
    call extractMantissa ; copy mantissa digits from parseBuf into floatBuf
    xor a ; A=inputBufOffset=0
    call findExponent ; A=offsetToExponent; CF=1 if found
    jr nc, parseFloatNoExponent
    call parseExponent ; A=exponentValue of inputBuf)
    call addExponent ; add EE exponent to floatBuf exponent
parseFloatNoExponent:
    ld hl, floatBuf
    jp move9ToOp1PageOne
    ret

; Description: Parse the integer (base 2, 8, 10, 16) at HL.
; Input: HL: pointer to Pascal string of an integer
; Output: OP1: floating point representation of integer
; Destroys: all
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
; Output:
;   - (parseBuf) cleared
;   - OP1=0.0
; Destroys: all
parseNumInit:
    call clearParseBuf
    call clearFloatBuf ; OP1=0.0
    ; terminate the inputBuf with a NUL sentinel to help parsing logic
    ld hl, inputBuf
    ld e, (hl)
    xor a
    ld d, a
    inc hl ; skip len byte
    add hl, de ; HL=pointerToNUL
    ld (hl), a
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

; Description: Set floatBuf and OP1 to 0.0.
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
; Output: ZF set if zero, otherwise not set
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
; Input: HL: pointer to floating point C-string
; Output: A: decimalPointPos, signed integer
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
; int8_t calcDPPos(const char *s) {
;   bool leadingFound = false;
;   bool dotFound = false;
;   int8_t pos = 0;
;   for (int8_t i=0; ; i++) {
;       char c = s[i];
;       if (!isValidFloatingDigit(c)) break;
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
;       } else { // c!='0' || leadingFound
;           if (dotFound) break;
;           leadingFound = true;
;           pos++;
;       }
;   }
;   return pos;
calcDPLeadingFound equ 0 ; set if leading (non-zero) digit found
calcDPDotFound equ 1; set if decimal point found
calcDPPos:
    xor a
    ld c, a ; pos
    ld d, a ; flags
calcDPLoop:
    ld a, (hl)
    inc hl
    ; check valid floating point digit (excludes 'E')
    call isValidFloatDigit; if valid: CF=1
    jr nc, calcDPEnd
    ; ignore and skip '-'
    cp signChar
    jr z, calcDPLoop
    ; check for '.'
    cp '.'
    jr nz, calcDPCheckZero
    set calcDPDotFound, d
    jr calcDPLoop
calcDPCheckZero:
    ; check for '0' && !leadingFound
    cp '0'
    jr nz, calcDPNormalDigit
    bit calcDPLeadingFound, d
    jr nz, calcDPNormalDigit
    ; decrement pos if dot found
    bit calcDPDotFound, d
    jr z, calcDPLoop
    dec c
    jr calcDPLoop
calcDPNormalDigit:
    bit calcDPDotFound, d
    jr nz, calcDPEnd
    set calcDPLeadingFound, d
    inc c
    jr calcDPLoop
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
; floatBuf, 2 digits per byte.
; Input: parseBuf
; Output: floatBuf updated
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

;-----------------------------------------------------------------------------

; Description: Find the next 'E' character and return the number of exponent
; digits.
; Input:
;   - (inputBuf): input characters and digits, Pascal-string w/ NUL terminator
;   - A: offset into inputBuf (which allows us to parse complex numbers with 2
;   floating point numbers in the inputBuf)
; Output:
;   - CF: 0 if not found, 1 if found
;   - A: offset to the first character after the 'E' symbol
; Destroys: BC, DE, HL
findExponent:
    ld hl, inputBuf
    ld c, (hl) ; C=len
    inc hl ; skip len byte
    ld e, a
    ld d, 0 ; DE=offset
    add hl, de
    ; Calculate length of string to loop over. Return if at end.
    sub c ; A=offset-len
    ret nc ; if offset>=len: no 'E', CF=0
    neg ; A=len-offset, guaranteed > 0
    ld b, a ; B=len-offset
findExponentSearchLoop:
    ld a, (hl)
    inc hl
    inc e ; E=offset++
    cp Lexponent
    jr z, findExponentFound
    ; This algorithm assumes that the Pascal string is *also* terminated with a
    ; NUL, like a C-string. It makes the loop algorithm simpler.
    call isValidFloatDigit ; if isValidFloatDigit(A): CF=1
    ret nc
    djnz findExponentSearchLoop
    ; indicate not found
    or a ; CF=0
    ret
findExponentFound:
    ld a, e ; A=offsetToFirstExponent
    scf
    ret

; Description: Parse the digits after the 'E' symbol in the inputBuf.
; Input:
;   - inputBuf
;   - A: offset to the first character of exponent, just after the 'E'
; Output: A: the exponent, in two's complement form
; Destroys: A, BC, DE, HL
parseExponent:
    ld hl, inputBuf
    inc hl ; skip len byte
    ld e, a ; E=eeDigitOffset
    ld d, 0
    add hl, de ; HL=pointer to first digit of EE
    ; Check for minus sign
    ld a, (hl); A==NUL if end of string
    inc hl
    cp signChar
    jr z, parseExponentSetSign
    ld d, rpnfalse ; D=isEENeg=false
    jr parseExponentDigits
parseExponentSetSign:
    ld a, (hl)
    inc hl
    ld d, rpntrue ; D=isEENeg=true
parseExponentDigits:
    ld b, 0 ; B=exponentValue
    ; process the first digit if any, A==NUL if end of string
    call isValidUnsignedDigit ; if valid: CF=1
    jr nc, parseExponentEnd
    sub '0'
    add a, b
    ld b, a
    ; process the second digit if any
    ld a, (hl) ; second of 2 digits, A==NUL if end of string
    inc hl
    call isValidUnsignedDigit; if valid: CF=1
    jr nc, parseExponentEnd
    ld c, a ; C=save A
    ld a, b
    call multABy10
    ld b, a
    ld a, c ; A=restored C
    sub '0'
    add a, b
    ld b, a
    ; [[fallthrough]]
parseExponentEnd:
    ld a, d ; A=isEENeg
    or a ; if isEENeg: ZF=0
    ld a, b ; A=exponentValue
    ret z
    neg
    ret

; Description: Multiply A by 10.
; Input: A
; Output: A
; Destroys: none
multABy10:
    push bc
    add a, a
    ld c, a ; C=2*A
    add a, a
    add a, a ; A=8*A
    add a, c ; A=10*A
    pop bc
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

;-----------------------------------------------------------------------------

; Description: Check if the character in A is a valid floating point digit
; which may be in scientific notation ('0' to '9', '-', '.', and 'E').
; Input: A: character
; Output: CF=1 if valid, 0 if not
; Destroys: none
isValidScientificDigit:
    cp Lexponent
    jr z, isValidDigitTrue
    ; [[fallthrough]]

; Description: Check if the character in A is a valid floating point digit ('0'
; to '9', '-', '.').
; Input: A: character
; Output: CF=1 if valid, 0 if not
; Destroys: none
isValidFloatDigit:
    cp '.'
    jr z, isValidDigitTrue

; Description: Check if the character in A is a valid signed integer ('0' to
; '9', '-').
; Input: A: character
; Output: CF=1 if valid, 0 if not
; Destroys: none
isValidSignedDigit:
    cp signChar ; '-'
    jr z, isValidDigitTrue
    ; [[fallthrough]]

; Description: Check if the character in A is a valid unsigned integer ('0' to
; '9').
; Input: A: character
; Output: CF=1 if valid, 0 if not
; Destroys: none
isValidUnsignedDigit:
    cp '0' ; if A<'0': CF=1
    jr c, isValidDigitFalse
    cp ':' ; if A<='9': CF=1
    ret c
    ; [[fallthrough]]

isValidDigitFalse:
    or a ; CF=0
    ret
isValidDigitTrue:
    scf ; CF=1
    ret

;-----------------------------------------------------------------------------

; Description: Set the complex indicator to the character encoded by A. There
; are 3 complex number indicators: LimagI (RECT), Langle (PRAD), Ldegree
; (PDEG). This routine converts them to the other characters depending on the
; value of the targetChar.
; Input:
;   - A: targetChar
;       - if LimagI: always set to LimagI
;       - if Langle: toggle or set
;           - if Langle, set to Ldegree
;           - if Ldegree, set to Langle
;           - if LimagI, set to Langle
;       - if not complex, do nothing
;   - inputBuf
; Output:
;   - inputBuf updated
;   - CF: set if complex indicator found, cleared if not found
; Destroys: A, BC, HL
; Preserves: DE
SetComplexChar:
    ld c, a ; C=targetChar
    ld hl, inputBuf
    ld b, (hl) ; B=len
    inc hl ; skip len byte
    ; Check for len==0
    ld a, b
    or a
    ret z
setComplexCharLoop:
    ; Find the complex indicator, if any
    ld a, (hl)
    inc hl
    cp LimagI
    jr z, setComplexCharFromImagI
    cp Langle
    jr z, setComplexCharFromAngle
    cp Ldegree
    jr z, setComplexCharFromDegree
    ; Loop until end of buffer
    djnz setComplexCharLoop
    or a; CF=0
    ret
setComplexCharFromImagI:
    ; [[fallthrough]]
setComplexCharFromDegree:
    dec hl
    ld (hl), c ; unconditional overwrite of targetChar does what we want
    scf
    ret
setComplexCharFromAngle:
    ; We have to toggle the current char if the targetChar is Langle
    dec hl
    ld a, c ; A=targetChar
    cp Langle
    jr nz, setComplexCharFromAngleToTarget
    ld a, Ldegree
setComplexCharFromAngleToTarget:
    ld (hl), a
    scf
    ret
