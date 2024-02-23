;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Functions related to parsing the inputBuf into a floating point number.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
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

;------------------------------------------------------------------------------

; Description: Parse the object in inputBuf into OP1. This routine assumes that
; the app was in edit mode when this was called, so assumes that the inputBuf
; is valid. If the app was not in edit mode, this routine should NOT have been
; called.
;
; The inputBufFlagsClosedEmpty flag is set if the inputBuf was an empty string
; before being closed. The flag is used by functions which do not consume any
; value from the RPN stack, but simply push a value or two onto the X or Y
; registers (e.g. PI, E, or various TVM functions, various STAT functions). If
; the user had pressed CLEAR, to clear the input buffer, then it doesn't make
; sense for these functions to lift the empty string (i.e. 0) up when pushing
; the new values. These functions call pushToX() or pushToXY() which checks if
; the inputBuf was closed when empty. If empty, pushToX() or pushToXY() will
; *not* lift the stack, but simply replace the "0" in the X register with the
; new value. This flag is cleared if the inputBuf was not in edit mode, with
; the assumption that new X or Y values should lift the stack.
;
; Input:
;   - inputBuf:PascalString
; Output:
;   - OP1/OP2:RpnObject
;   - A: rpnObjectType
;   - inputBufFlagsClosedEmpty: set if inputBuf was an empty string when closed
;   - inputBuf cleared to empty string
; Throws:
;   - Err:Syntax if there is a syntax error
; Destroys: all, OP1, OP2, OP4
ParseAndClearInputBuf:
    ld hl, inputBuf
    ld a, (hl) ; A=stringSize
    or a
    jr nz, parseAndClearInputBufNonEmpty
parseAndClearInputBufEmpty:
    set inputBufFlagsClosedEmpty, (iy + inputBufFlags)
    call op1Set0PageOne
    jp ClearInputBuf
parseAndClearInputBufNonEmpty:
    res inputBufFlagsClosedEmpty, (iy + inputBufFlags)
    ld a, LlBrace ; A='{'
    call findChar ; CF=1 if found
    jr c, parseAndClearInputBufRecord
    call parseInputBufNumber ; OP1/OP2=real or complex
    jp ClearInputBuf
parseAndClearInputBufRecord:
    call parseInputBufRecord ; OP1/OP2:record
    jp ClearInputBuf

;------------------------------------------------------------------------------

; Description: Return the number of digits which are accepted or displayed for
; the given (baseWordSize) and (baseNumber).
;   - real mode: inputBufFloatMaxLen
;   - complex mode: inputBufComplexMaxLen
;   - record mode: inputBufRecordMaxLen
;   - BASE 2: inputMaxLen = baseWordSize
;       - 8 -> 8
;       - 16 -> 16
;       - 24 -> 24
;       - 32 -> 32
;   - BASE 8: inputMaxLen = ceil(baseWordSize / 3)
;       - 8 -> 3 (0o377)
;       - 16 -> 6 (0o177 777)
;       - 24 -> 8 (0o77 777 777)
;       - 32 -> 11 (0o37 777 777 777)
;   - BASE 10: inputMaxLen = ceil(log10(2^baseWordSize))
;       - 8 -> 3 (255)
;       - 16 -> 5 (65 535)
;       - 24 -> 8 (16 777 215)
;       - 32 -> 10 (4 294 967 295)
;   - BASE 16: inputMaxLen = baseWordSize / 4
;       - 8 -> 2 (0xff)
;       - 16 -> 4 (0xff ff)
;       - 24 -> 6 (0xff ff ff)
;       - 32 -> 8 (0xff ff ff ff)
;
; This version uses a lookup table to make the above transformations. Another
; way is to use a series of nested if-then-else statements (i.e. a series of
; 'cp' and 'jr nz' statements in assembly language). The nested if-then-else
; actually turned out to be about 80 bytes *smaller*. However, the if-then-else
; version is so convoluted that it is basically unreadable and unmaintainable.
; Use the lookup table implementation instead even though it takes up slightly
; more space.
;
; Input: rpnFlagsBaseModeEnabled, (baseWordSize), (baseNumber).
; Output: A: inputMaxLen
; Destroys: A
; Preserves: BC, DE, HL
getInputMaxLen:
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    jr nz, getInputMaxLenBaseMode
    ; In normal floating point input mode, i.e. not BASE mode.
    ; Check for various object types.
    ld hl, inputBuf
    call checkComplexDelimiterP ; CF=1 if complex
    jr c, getInputMaxLenComplex
    call checkRecordDelimiterP ; CF=1 if record
    jr c, getInputMaxLenRecord
getInputMaxLenNormal:
    ; default
    ld a, inputBufFloatMaxLen
    ret
getInputMaxLenComplex:
    ld a, inputBufComplexMaxLen
    ret
getInputMaxLenRecord:
    ld a, inputBufRecordMaxLen
    ret
getInputMaxLenBaseMode:
    ; If BASE mode, the maximum number of digits depends on baseNumber and
    ; baseWordSize.
    push de
    push hl
    call getBaseNumberIndex ; A=baseNumberIndex
    sla a
    sla a ; A=baseNumberIndex * 4
    ld e, a
    call getWordSizeIndexPageOne ; A=wordSizeIndex
    add a, e ; A=4*baseNumberIndex+wordSizeIndex
    ld e, a
    ld d, 0
    ld hl, wordSizeDigitsArray
    add hl, de
    ld a, (hl) ; A=maxLen
    pop hl
    pop de
    ret

; List of the inputDigit limit of the inputBuf for each (baseNumber) and
; (baseWordSize). Each group of 4 represents the inputDigits for wordSizes (8,
; 16, 24, 32) respectively.
wordSizeDigitsArray:
    .db 8, 16, 24, 32 ; base 2
    .db 3, 6, 8, 11 ; base 8
    .db 3, 5, 8, 10 ; base 10
    .db 2, 4, 6, 8 ; base 16

;------------------------------------------------------------------------------

; Description: Check if the 'E' character exists in the last floating point
; number in the inputBuf by scanning backwards from the end of the string. If
; the EE character exists, then return the number of digits in the exponent.
; Input: inputBuf
; Output:
;   - CF=1 if exponent exists
;   - A: eeLen, number of EE digits if exponent exists
; Destroys: BC, HL
; Preserves: DE
CheckInputBufEE:
    ld hl, inputBuf
    ld c, (hl) ; C=len
    ld b, 0 ; BC=len
    inc hl ; skip past len byte
    add hl, bc ; HL=pointer to end of string
    ; check for len==0
    ld a, c ; A=len
    or a ; if len==0: ZF=0
    ret z
    ld c, b ; C=0
    ld b, a ; B=counter
checkInputBufEELoop:
    ; Loop backwards from end of string and update inputBufState flags
    dec hl
    ld a, (hl)
    call isNumberDelimiterPageOne ; ZF=1 if delimiter
    jr z, checkInputBufEENone
    call isComplexDelimiterPageOne ; ZF=1 if complex delimiter
    jr z, checkInputBufEENone
    cp Lexponent
    jr z, checkInputBufEEFound
    cp '.'
    jr z, checkInputBufEENone
    call isValidUnsignedDigit ; if valid: CF=1
    jr nc, checkInputBufEEContinue
    ; if inside EE digit: increment eeLen
    inc c ; eeLen++
checkInputBufEEContinue:
    ; Loop until we reach the start of string
    djnz checkInputBufEELoop
checkInputBufEENone:
    or a ; CF=0
    ret
checkInputBufEEFound:
    scf ; CF=1 to indicate 'E' found
    ld a, c ; A=eeLen
    ret

;------------------------------------------------------------------------------

; Description: Check if the most recent floating number has a negative sign
; that can be mutated by the CHS (+/-) button, by scanning backwards from the
; end of the string. Return the position of the sign in B.
; Input: inputBuf
; Output:
;   - A: inputBufChsPos, the position where a sign character can be added or
;   removed (i.e. after an 'E', after the complex delimiter, or at the start of
;   the buffer if empty)
; Destroys: BC, HL
; Preserves: DE
CheckInputBufChs:
    ld hl, inputBuf
    ld c, (hl) ; C=len
    ld b, 0 ; BC=len
    inc hl ; skip past len byte
    add hl, bc ; HL=pointer to end of string
    ; check for len==0
    ld a, c ; A=len
    or a ; if len==0: ZF=0
    ret z
    ld b, a
checkInputBufChsLoop:
    ; Loop backwards from end of string and update inputBufState flags
    dec hl
    ld a, (hl)
    cp Lexponent
    jr z, checkInputBufChsEnd
    call isComplexDelimiterPageOne ; ZF=1 if complex delimiter
    jr z, checkInputBufChsEnd
    call isNumberDelimiterPageOne ; ZF=1 if number delimiter
    jr z, checkInputBufChsEnd
    djnz checkInputBufChsLoop
checkInputBufChsEnd:
    ld a, b
    ret

;------------------------------------------------------------------------------

; Description: Check if the right most floating point number already has a
; decimal point.
; Input: inputBuf
; Output: CF=1 if the last floating point number has a decimal point
; Destroys: A, BC, HL
; Preserves: DE
CheckInputBufDecimalPoint:
    ld hl, inputBuf
    ld c, (hl) ; C=len
    ld b, 0 ; BC=len
    inc hl ; skip past len byte
    add hl, bc ; HL=pointer to end of string
    ; check for len==0
    ld a, c ; A=len
    or a ; if len==0: ZF=0
    jr z, checkInputBufDecimalPointNone
    ld b, a ; B=len
checkInputBufDecimalPointLoop:
    ; Loop backwards from end of string and update inputBufState flags
    dec hl
    ld a, (hl)
    cp '.'
    jr z, checkInputBufDecimalPointFound
    call isNumberDelimiterPageOne ; ZF=1 if delimiter
    jr z, checkInputBufDecimalPointNone
    call isComplexDelimiterPageOne ; ZF=1 if complex delimiter
    jr z, checkInputBufDecimalPointNone
    djnz checkInputBufDecimalPointLoop
checkInputBufDecimalPointNone:
    or a
    ret
checkInputBufDecimalPointFound:
    scf
    ret

;------------------------------------------------------------------------------

; Description: Check if the inputBuf is a data structure, i.e. contains a left
; or right curly brace '{', and count the nesting level. Positive for open left
; curly, negative for close right curly.
; Input: inputBuf
; Output:
;   - CF=1 if the inputBuf contains a data structure
;   - A:i8=braceLevel if CF=1
; Destroys: A, DE, BC, HL
CheckInputBufRecord:
    ld hl, inputBuf
    ld b, (hl) ; C=len
    inc hl ; skip past len byte
    ; check for len==0
    ld a, b ; A=len
    or a ; if len==0: ZF=0
    jr z, checkInputBufRecordNone
    ld c, 0 ; C=braceLevel
    ld d, rpnfalse ; D=isBrace
checkInputBufRecordLoop:
    ; Loop forwards and update brace level.
    ld a, (hl)
    inc hl
    cp LlBrace
    jr nz, checkInputBufRecordCheckRbrace
    inc c ; braceLevel++
    ld d, rpntrue
checkInputBufRecordCheckRbrace:
    cp LrBrace
    jr nz, checkInputBufRecordCheckTermination
    dec c ; braceLevel--
    ld d, rpntrue
checkInputBufRecordCheckTermination:
    djnz checkInputBufRecordLoop
checkInputBufRecordFound:
    ld a, d ; A=isBrace
    or a
    ret z
    ld a, c
    scf
    ret
checkInputBufRecordNone:
    or a ; CF=0
    ret

;------------------------------------------------------------------------------

; Description: Parse the input buffer into a real or complex number in OP1/OP2.
; Input: inputBuf filled with keyboard characters
; Output: OP1/OP2: real or complex number
; Destroys: all registers, OP1-OP5 (due to SinCosRad())
; Throws: Err:Syntax if there is a parsing error
parseInputBufNumber:
    call initInputBufForParsing ; HL=inputBuf
    inc hl ; skip length byte
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    jr nz, parseBaseInteger
    ; parse a real or real component
    call parseFloat ; OP1=float; CF=0 if empty string
    rl b ; B[0]=first.isNonEmpty=CF
    call parseComplexDelimiter ; if complex delimiter: CF=1, A=delimiter
    ; Verify no trailing characters
    jr nc, parseInputBufTermination ; destroys A
parseInputBufNumberComplex:
    ; parse the imaginary component
    ld c, a ; C=delimiter
    push bc ; stack=[delimiter/first.isNonEmpty]
    push hl
    bcall(_PushRealO1) ; FPS=[first]
    pop hl
    call parseFloat ; OP1=second; CF=0 if empty string
    pop bc ; stack=[]; B[0]=second.isNonEmpty; C=delimiter
    rl b ; B[1]=first.isNonEmpty; B[0]=second.isNonEmpty=CF
    ; Check trailing characters
    call parseInputBufTermination ; destroys A
    ; Now we are at the extraction stage.
parseInputBufNumberExtraction:
    ; Check for solitary imaginary 'i'.
    ld a, b
    and $3 ; B[1]=first.isNonEmpty; B[0]=second.isNonEmpty
    ld a, c ; A=delimiter
    jr nz, parseInputBufNonEmptyImaginary
    ; We are here if both the real and imaginary components were empty strings.
    ; Check if the complex delimiter was a 'i'. If so, set the imaginary
    ; component to 1, so that a solitary 'i' is interpreted as just '0i1'
    ; instead of '0i0'.
    cp LimagI
    jr nz, parseInputBufNonEmptyImaginary
    push af ; stack=[delimiter]
    bcall(_OP1Set1) ; OP1=1.0
    pop af ; stack=[]; A=dlimiter
parseInputBufNonEmptyImaginary:
    push af ;stack=[delimiter]
    call op1ToOp2PageOne ; OP2=second
    bcall(_PopRealO1) ; FPS=[]; OP1=first; OP2=second
    pop af ; stack=[]; A=delimiter
    ; convert 2 real numbers in OP1/OP2 into a complex number
    cp Langle
    jp z, PolarRadToComplex
    cp Ldegree
    jp z, PolarDegToComplex
    jp RectToComplex

; Description: Verify that we have reached the end of inputBuf indicated by a
; NUL character.
; Input: HL:(char*)=stringPointer
; Destroys: A
; Throws: Err:Syntax if there are trailing characters
parseInputBufTermination:
    ld a, (hl)
    or a
    ret z
    bcall(_ErrSyntax)

;------------------------------------------------------------------------------

; Description: Parse the integer (base 2, 8, 10, 16) at HL.
; Input: HL: pointer to C string of an integer
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

; Description: Parse the baseNumber in the C-string given by HL. The base mode
; be 2, 8 or 16. This subroutine will actually supports any baseNumber <= 36
; probably (10 numerals and 26 letters).
; Input:
;   - HL: pointer to C string
;   - A: base mode (2, 8, 10, 16)
; Output: OP1: floating point value
; Destroys: all
parseNumBase:
    push hl
    bcall(_SetXXOP1) ; OP1 = A = base
    bcall(_OP1ToOP4) ; OP4 = base
    bcall(_OP1Set0)
    pop hl
parseNumBaseLoop:
    ; get next digit
    ld a, (hl)
    inc hl
    or a
    ret z ; return on NUL
    push hl
    ; multiply by 'base' before adding the next digit
    push af
    bcall(_OP4ToOP2) ; OP2 = base
    bcall(_FPMult) ; OP1 *= base; destroys OP3
    pop af
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
    bcall(_SetXXOP2) ; OP2 = A = digit value
    bcall(_FPAdd) ; OP1 += OP2
    pop hl
    jr parseNumBaseLoop

;------------------------------------------------------------------------------

; Description: Initialize the inputBuf for parsing by adding a NUL terminator
; to the Pascal string. The capacity of inputBuf is one character larger than
; necessary to hold the extra NUL character.
; Input: inputBuf
; Output:
;   - inputBuf with NUL terminator
;   - HL=inputBuf
; Destroys: A, DE, HL
initInputBufForParsing:
    ld hl, inputBuf
    push hl
    ld e, (hl)
    xor a
    ld d, a
    inc hl ; skip len byte
    add hl, de ; HL=pointerToNUL
    ld (hl), a
    pop hl
    ret

;-----------------------------------------------------------------------------
; Parsing complex numbers.
;-----------------------------------------------------------------------------

; Description: Set the complex delimiter to the character encoded by A. There
; are 3 complex number delimiters: LimagI (RECT), Langle (PRAD), Ldegree
; (PDEG). This routine converts them to other delimiters depending on the value
; of the targetDelimiter.
;
; The algorithm is as follows:
; - if delimiter==LimagI:
;     - if targetDelimiter==LimagI: do nothing
;     - if targetDelimiter==targetDelimiter
; - if delimiter in (Langle, Ldegree):
;     - if targetDelimiter==LimagI: delimiter=LimagI
;     - if targetDelimiter==(Langle,Ldegree): toggle to the other
; - if no delimiter: do nothing
;
; Input:
;   - A: targetDelimiter
;   - inputBuf
; Output:
;   - inputBuf updated
;   - CF: 1 if complex delimiter found, 0 if not found
; Destroys: A, BC, HL
; Preserves: DE
SetComplexDelimiter:
    ld c, a ; C=targetDelimiter
    ld hl, inputBuf
    ld b, (hl) ; B=len
    inc hl ; skip len byte
    ; Check for len==0
    ld a, b
    or a ; CF=0
    ret z
setComplexDelimiterLoop:
    ; Find the complex delimiter, if any
    ld a, (hl)
    inc hl
    cp LimagI
    jr z, setComplexDelimiterFromImagI
    cp Langle
    jr z, setComplexDelimiterFromAngle
    cp Ldegree
    jr z, setComplexDelimiterFromDegree
    ; Loop until end of buffer
    djnz setComplexDelimiterLoop
    or a; CF=0
    ret
setComplexDelimiterFromImagI:
    dec hl
    ld a, c
    jr setComplexDelimiterToTarget
setComplexDelimiterFromDegree:
    dec hl
    ld a, c ; A=targetDelimiter
    cp LimagI
    jr z, setComplexDelimiterToTarget
    ld a, Langle ; toggle
    jr setComplexDelimiterToTarget
setComplexDelimiterFromAngle:
    dec hl
    ld a, c ; A=targetDelimiter
    cp LimagI
    jr z, setComplexDelimiterToTarget
    ld a, Ldegree ; toggle
setComplexDelimiterToTarget:
    ld (hl), a
    scf
    ret

; Description: Parse the optional complex number delimiter (LimagI, Langle, or
; Ldegree).
; Input:
;   - HL:(char*)=numberString
; Output:
;   - CF: 1 if the next char is complex number delimiter, 0 otherwise
;   - A: delimiter char (LimagI, Langle, or Ldegree)
;   - HL: pointer to character after the delimiter
; Destroys: A, HL
parseComplexDelimiter:
    ld a, (hl)
    inc hl
    call isComplexDelimiterPageOne ; if delimiter: ZF=1
    jr z, parseComplexDelimiterFound
    dec hl ; push back the non-matching char
    or a ; CF=0
    ret
parseComplexDelimiterFound:
    scf ; CF=1
    ret

; Description: Check if complex delimiter exists in the given Pascal string.
; Input: HL: pointer to pascal string
; Output: CF=1 if complex, 0 otherwise
; Destroys: A, B
; Preserves: HL
checkComplexDelimiterP:
    push hl
    ld a, (hl) ; A=len
    inc hl
    or a ; ZF=0 if len==0; CF=0
    jr z, checkComplexDelimiterPNot
    ld b, a
checkComplexDelimiterPLoop:
    ld a, (hl)
    inc hl
    call isComplexDelimiterPageOne
    jr z, checkComplexDelimiterPFound
    djnz checkComplexDelimiterPLoop
checkComplexDelimiterPNot:
    pop hl
    or a ; CF=0
    ret
checkComplexDelimiterPFound:
    pop hl
    scf ; CF=1
    ret

; Description: Return ZF=1 if A is a complex number delimiter. Same as
; isComplexDelimiter().
; Input: A: char
; Output: ZF=1 if delimiter
; Destroys: none
isComplexDelimiterPageOne:
    cp LimagI
    ret z
    cp Langle
    ret z
    cp Ldegree
    ret

; Description: Return ZF=1 if A is a real or complex number delimiter.
; Input: A: char
; Output: ZF=1 if delimiter
; Destroys: none
isNumberDelimiterPageOne:
    cp LlBrace ; '{'
    ret z
    cp ','
    ret

; Description: Check if the data record delimiter '{' exists in the given
; Pascal string.
; Input: HL: pointer to pascal string
; Output: CF=1 if record type, 0 otherwise
; Destroys: A, B
; Preserves: HL
checkRecordDelimiterP:
    push hl
    ld a, (hl) ; A=len
    inc hl
    or a ; ZF=0 if len==0; CF=0
    jr z, checkRecordDelimiterPNot
    ld b, a
checkRecordDelimiterPLoop:
    ld a, (hl)
    inc hl
    cp '{'
    jr z, checkRecordDelimiterPFound
    djnz checkRecordDelimiterPLoop
checkRecordDelimiterPNot:
    pop hl
    or a ; CF=0
    ret
checkRecordDelimiterPFound:
    pop hl
    scf ; CF=1
    ret

;-----------------------------------------------------------------------------
; Parsing tagged Records (e.g. "D{2000,1,1}").
;-----------------------------------------------------------------------------

; Description: Parse the inputBuf containing a Record into OP1.
; Input: inputBuf
; Output: OP1/OP2=rpnObject (e.g. RpnDate, RpnDateTime, RpnOffsetDateTime)
; Uses: parseBuf
; Destroys: all
; Throws:
;   - Err:Syntax if the syntax is incorrect
;   - Err:Invalid if there's a programming logic error
parseInputBufRecord:
    call initInputBufForParsing ; HL=inputBuf
    inc hl ; skip len byte
    ; Check if we have a naked Record starting with '{'.
    ld a, (hl)
    cp '{'
    jr z, parseInputBufRecordNaked
parseInputBufRecordTagged:
    call parseRecordTag ; A=recordTagTypeXxx, or throws Err:Syntax
    cp recordTagTypeDate
    jr z, parseInputBufDate
    cp recordTagTypeTime
    jr z, parseInputBufTime
    cp recordTagTypeDateTime
    jr z, parseInputBufDateTime
    cp recordTagTypeOffset
    jr z, parseInputBufOffset
    cp recordTagTypeOffsetDateTime
    jr z, parseInputBufOffsetDateTime
    bcall(_ErrInvalid) ; should never happen
parseInputBufRecordNaked:
    ; Naked records cannot support Time because it has the same number of
    ; commas as a Date.
    call countCommas ; A=numCommas, preserves HL
    cp 1
    jr z, parseInputBufOffset
    cp 2
    jr z, parseInputBufDate
    cp 5
    jr z, parseInputBufDateTime
    cp 7
    jr z, parseInputBufOffsetDateTime
parseInputBufRecordErr:
    bcall(_ErrSyntax)
parseInputBufOffset:
    ld de, OP1
    ld a, rpnObjectTypeOffset
    ld (de), a
    inc de
    push de
    call parseOffset
    pop hl ; HL=OP1+1
    bcall(_ValidateOffset)
    ret
parseInputBufDate:
    ld de, OP1
    ld a, rpnObjectTypeDate
    ld (de), a
    inc de ; skip type byte
    push de
    call parseDate
    pop hl ; HL=OP1+1
    bcall(_ValidateDate)
    ret
parseInputBufTime:
    ld de, OP1
    ld a, rpnObjectTypeTime
    ld (de), a
    inc de ; skip type byte
    push de
    call parseTime
    pop hl ; HL=OP1+1
    bcall(_ValidateTime)
    ret
parseInputBufDateTime:
    ld de, OP1
    ld a, rpnObjectTypeDateTime
    ld (de), a
    inc de ; skip type byte
    push de
    call parseDateTime
    pop hl ; HL=OP1+1
    bcall(_ValidateDateTime)
    ret
parseInputBufOffsetDateTime:
    ld de, OP1
    ld a, rpnObjectTypeOffsetDateTime
    ld (de), a
    inc de ; skip type byte
    push de
    call parseOffsetDateTime
    pop hl ; HL=OP1+1
    bcall(_ValidateOffsetDateTime)
    call expandOp1ToOp2PageOne ; sizeof(OffsetDateTime)>9
    ret
