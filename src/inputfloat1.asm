;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Functions related to parsing a floating point number.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;------------------------------------------------------------------------------

; Description: Parse the floating point number at HL.
; Input:
;   - HL:(const char*)=floatingPointString
; Output:
;   - OP1: floating point number
;   - HL=points to character just after the number
;   - CF: 0 if empty string, 1 non-empty
; Destroys: A, BC, DE, HL
parseFloat:
    call clearParseBuf
    call clearFloatBuf ; OP1=0.0
    ; Check for an emtpy string.
    ld a, (hl)
    call isValidScientificDigit ; CF=1 if valid
    ret nc
    call findDecimalPoint ; A=i8(decimalPointPos)
    call extractMantissaExponent ; extract mantissa exponent to floatBuf
    call extractMantissaSign ; extract mantissa sign to floatBuf
    call parseMantissa ; parse mantissa digits from inputBuf into parseBuf
    call extractMantissa ; convert mantissa digits in parseBuf to floatBuf
    call extractExponent ; extract exponent from inputBuf to floatBuf
    push hl
    ld hl, floatBuf
    call move9ToOp1PageOne
    pop hl ; HL=points to char after floatPointString
    scf ; CF=1
    ret

;-----------------------------------------------------------------------------

; Description: Clear parseBuf by setting all digits to the character '0', and
; setting size to 0. The trailing '0' characters make it easy to construct the
; floating point number.
; Input: parseBuf
; Output: parseBuf initialized to '0's, and set to 0-length
; Destroys: A, B
; Preserves: HL
clearParseBuf:
    push hl
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
    pop hl
    ret

; Description: Set floatBuf and OP1 to 0.0.
; Destroys: A, DE
; Preserves: HL
clearFloatBuf:
    push hl
    bcall(_OP1Set0)
    ld de, floatBuf
    bcall(_MovFrOP1)
    pop hl
    ret

;------------------------------------------------------------------------------

; Bit flags used by findDecimalPoint().
findDecimalPointLeadingFound equ 0 ; set if leading (non-zero) digit found
findDecimalPointDotFound equ 1; set if decimal point found

; Description: Find the position of the decimal point of the given number
; string. If the input string is effectively 0, then position of 1 is returned
; so that the final floating point number has an exponent of $80, which is the
; canonical representation of 0.0 in the TI-OS.
;
; The returned value is the number of places the the decimal point needs to be
; shifted to get back the original value after the mantissa is normalized with
; the leading non-zero digit immediately to the right of the decimal place. The
; normalized mantissa lies in the interval [0.1, 1.0). The shift can be a
; negative number for values less than 0.1.
;
; A string that has no leading digit will always parse to 0, for example "0" or
; "0.00" or "000.00". This condition will be detected and the position is
; returned as 1, so that the final floating point number has an exponent of $80
; (i.e. 0) which is the canonical representation of 0.0 in the TI-OS.
;
; For example, the following unnormalized number strings should return the
; indicated decimal point position:
;
;   - "0" -> .0, 1
;   - "00.000" -> .0, 1
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
; int8_t findDecimalPoint(const char *s) {
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
;           leadingFound = true;
;           if (dotFound) break;
;           pos++;
;       }
;   }
;   return (leadingFound ? pos : 1);
;
; Input: HL: pointer to floating point C-string
; Output: A: decimalPointPos, signed integer
; Destroys: A, BC, DE
; Preservers: HL
findDecimalPoint:
    push hl
    xor a
    ld c, a ; pos
    ld d, a ; flags
findDecimalPointLoop:
    ld a, (hl)
    inc hl
    ; check valid floating point digit (excludes 'E')
    call isValidFloatDigit; if valid: CF=1
    jr nc, findDecimalPointEnd
    ; ignore and skip '-'
    cp signChar
    jr z, findDecimalPointLoop
    ; check for '.'
    cp '.'
    jr nz, findDecimalPointCheckZero
    set findDecimalPointDotFound, d
    jr findDecimalPointLoop
findDecimalPointCheckZero:
    ; check for '0' && !leadingFound
    cp '0'
    jr nz, findDecimalPointNormalDigit
    bit findDecimalPointLeadingFound, d
    jr nz, findDecimalPointNormalDigit
    ; decrement pos if dot found
    bit findDecimalPointDotFound, d
    jr z, findDecimalPointLoop
    dec c
    jr findDecimalPointLoop
findDecimalPointNormalDigit:
    set findDecimalPointLeadingFound, d
    bit findDecimalPointDotFound, d
    jr nz, findDecimalPointEnd
    inc c
    jr findDecimalPointLoop
findDecimalPointEnd:
    pop hl
    ld a, c
    bit findDecimalPointLeadingFound, d
    ret nz
    ld a, 1 ; if no leading digit found: return pos=1
    ret

;-----------------------------------------------------------------------------

; Description: Set the exponent from the mantissa. The mantissaExp =
; decimalPointPos - 1. But the floating exponent is shifted by $80.
;   mantissaExponent = decimalPointPos - 1
;   floatingExponent = mantissaExponent + $80
;                    = decimalPointPos + $7F
;
; Input: A: decimalPointPos (from findDecimalPoint())
; Output: floatBufExp = decimalPointPos + $7F
; Destroys: A
extractMantissaExponent:
    add a, $7F
    ld (floatBufExp), a
    ret

; Description: Extract mantissa sign from the first character of the given
; string, and transfer it to the sign bit of the floatBuf.
; Input: HL: NUL terminated C-string
; Output: (floatBuf) sign set
; Destroys: none
; Preserves: HL
extractMantissaSign:
    ld a, (hl) ; A will be NUL if an empty string
    cp signChar
    ret nz ; '-' not found at first character
    push hl
    ld hl, floatBufType
    set 7, (hl)
    pop hl
    ret

; Description: Extract the normalized mantissa digits from parseBuf to
; floatBuf, 2 digits per byte. If the mantissa is an empty string or
; effectively 0, do nothing.
; Input: parseBuf
; Output: floatBuf updated
; Destroys: A, BC, DE
; Preserves: HL
extractMantissa:
    push hl
    ld hl, parseBuf
    ld a, (hl)
    or a
    jr z, extractMantissaEnd ; if mantissa is effectively 0 or "", do nothing
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
extractMantissaEnd:
    pop hl
    ret

;-----------------------------------------------------------------------------

; Description: Parse the mantissa digits from inputBuf into parseBuf, ignoring
; negative sign, leading zeros, the decimal point, and the EE symbol. For
; example:
;   - "0.0" produces ""
;   - "-00.00" produces ""
;   - "0.1" produces "1"
;   - "-001.2" produces "12"
;   - "23E-1" produces "23"
; Input:
;   - HL:(char*)=inputBuf
;   - parseBuf: Pascal string, initially set to empty string
; Output:
;   - parseBuf: filled with mantissa digits or an empty string if all 0
; Destroys: A, BC, DE
; Preserves: HL
parseMantissaLeadingFound equ 0 ; bit to set when lead digit found
parseMantissa:
    res parseMantissaLeadingFound, c
    push hl
parseMantissaLoop:
    ld a, (hl)
    inc hl
    call isValidFloatDigit ; if valid: CF=1
    jr nc, parseMantissaEnd
    cp signChar
    jr z, parseMantissaLoop
    cp '.'
    jr z, parseMantissaLoop
    cp '0'
    jr nz, parseMantissaNormalDigit
    ; Ignore '0' before a leading digit.
    bit parseMantissaLeadingFound, c
    jr z, parseMantissaLoop
parseMantissaNormalDigit:
    ; A: char to append
    set parseMantissaLeadingFound, c
    call appendParseBuf ; preserves BC, HL
    jr parseMantissaLoop
parseMantissaEnd:
    pop hl
    ret

; Description: Append character in A to parseBuf
; Input:
;   - A: character to be appended
; Output:
;   - CF set when append fails
; Destroys: A, DE
; Preserves: BC, HL
appendParseBuf:
    push hl
    push bc
    ld hl, parseBuf
    ld b, parseBufCapacity
    call AppendString
    pop bc
    pop hl
    ret

;------------------------------------------------------------------------------

; Description: Extract the EE exponent digits in HL (inputBuf) to floatBuf. If
; the mantissa (normalized in parseBuf) is effectively 0 or an empty string, do
; nothing.
; Input:
;   - HL:(char*)=floatingPointString
;   - (parseBuf):(char*)=mantissaDigits
; Output:
;   - (floatBuf) updated
;   - HL=points to char after floatingPointString
; Destroys: A, BC, DE
extractExponent:
    ; If the mantissa is effectively 0, then no need to parse the exponent.
    ld a, (parseBuf)
    or a
    ret z ; return if nothing left in parseBuf
    call findExponent ; if found: HL=eeDigit; CF=1
    ret nc
    call parseExponent ; A=exponentValue; HL=points to char after number
    call addExponent ; add A=exponentValue to floatBuf exponent; preserves HL
    ret

; Description: Find the next 'E' character and return the number of exponent
; digits.
; Input:
;   - HL:(const char*)=floatinPointString
; Output:
;   - CF=0 if not found, 1 if found
;   - HL=pointer to the first character after the 'E' symbol if found,
;   or the first character after the floating point number if 'E' not found
; Destroys: BC, DE, HL
findExponent:
    ld a, (hl)
    inc hl
    cp Lexponent
    jr z, findExponentFound
    call isValidFloatDigit ; if isValidFloatDigit(A): CF=1
    jr c, findExponent
    dec hl ; pushback non-floating char
    ret ; CF=0
findExponentFound:
    scf ; CF=1
    ret

; Description: Parse 0 or more digits after the 'E' symbol in the inputBuf,
; allowing for an initial minus sign. If more than 2 digits are entered, the
; characters are parsed, but the carry flag (CF) is set to indicate an error.
; Input:
;   - HL:(const char*)=eeDigits
; Output:
;   - A:i8=exponent
;   - HL=points to character after eeDigits
; Destroys: A, BC, DE, HL
parseExponentFlagIsNeg equ 0 ; set if eeDigits begins with '-' sign
parseExponentFlagSignConsumed equ 1 ; set if at least 1 char parsed
parseExponent:
    xor a
    ld b, a ; B=exponentValue=0
    ld c, a ; C=numDigits=0
    ld d, a ; D=parseExponentFlag=0
parseExponentLoop:
    ; Check for valid char
    ld a, (hl); A==NUL if end of string
    inc hl
    call isValidSignedDigit ; if valid: CF=1
    jr nc, parseExponentEnd
    ; Check for '-'
    cp signChar
    jr nz, parseExponentDigits
parseExponentSetSign:
    bit parseExponentFlagSignConsumed, d
    jr nz, parseExponentErr ; sign already consumed, so a second '-' is illegal
    set parseExponentFlagSignConsumed, d
    set parseExponentFlagIsNeg, d
    jr parseExponentLoop
parseExponentDigits:
    bit parseExponentFlagSignConsumed, d
    ; add incoming eeDigit to exponentValue
    ld e, a ; E=save A
    ld a, b
    call multABy10
    ld b, a ; B=10*B
    ld a, e ; A=restored E
    sub '0'
    add a, b
    ld b, a
    inc c ; C=numDigits++
    jr parseExponentLoop
parseExponentEnd:
    dec hl ; pushback char after exponent
    ld a, c ; A=numDigits
    cp inputBufEEMaxLen+1
    jr nc, parseExponentErr ; if numDigits>inputBufEEMaxLen: error
    bit parseExponentFlagIsNeg, d ; ZF=0 if negative
    ld a, b ; A=exponentValue
    ret z
    neg ; A=-exponentValue
    ret
parseExponentErr:
    bcall(_ErrSyntax)

; Description: Add the exponent in A to the floatBuf exponent.
; Input: A:i8=exponentValue
; Output: (floatBuf exponent) += A
; Destroys: A, B
; Preserves: DE, HL
addExponent:
    push hl
    ld b, a
    ld hl, floatBufExp
    ld a, (hl)
    sub $80
    add a, b ; 2's complement
    add a, $80
    ld (hl), a
    pop hl
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
