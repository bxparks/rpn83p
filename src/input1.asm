;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Functions related to entering into and editing characters in the inputBuf.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;------------------------------------------------------------------------------

; Description: Initialize variables and flags related to the input buffer.
; Input: none
; Output:
;   - inputBuf set to empty
;   - rpnFlagsEditing reset
; Destroys: A
ColdInitInputBuf:
    res rpnFlagsEditing, (iy + rpnFlags)
    ; [[fallthrough]]

; Description: Clear the inputBuf.
; Input: none
; Output:
;   - inputBuf cleared
;   - cursorInputPos=0
;   - dirtyFlagsInput set
; Destroys: none
ClearInputBuf:
    push af
    xor a
    ld (inputBuf), a
    ld (cursorInputPos), a
    set dirtyFlagsInput, (iy + dirtyFlags)
    pop af
    ret

; Description: Insert character at cursorInputPos into inputBuf.
; Input:
;   - A:char=insertChar
;   - cursorInputPos:u8=insertPosition
; Output:
;   - dirtyFlagsInput always set
;   - CF=0 if successful
;   - (cursorInputPos)+=1 if successful
; Destroys: all
InsertCharInputBuf:
    ld c, a ; C=insertChar
    call getInputMaxLen ; A=inputMaxLen
    cp inputBufCapacity ; if inputMaxLen>=inputBufCapacity: CF=0
    jr c, insertCharInputBufContinue
    ld a, inputBufCapacity ; A=min(inputMaxLen,inputBufCapacity)
insertCharInputBufContinue:
    ld b, a ; B=inputMaxLen
    ld a, (cursorInputPos) ; A=insertPosition
    ld hl, inputBuf
    set dirtyFlagsInput, (iy + dirtyFlags)
    call InsertAtPos ; CF=0 if successful
    ret c
    ; always increment the cursor
    ld hl, cursorInputPos
    inc (hl)
    ret

; Description: Delete one character to the left of cursorInputPos from inputBuf
; if possible. If already empty, do nothing.
; Input:
;   - cursorInputPos
; Output:
;   - inputBuf shortened by one character
;   - cursorInputPos-=1
; Destroys: A, BC, DE, HL
DeleteCharInputBuf:
    ld a, (cursorInputPos)
    or a
    ret z ; do nothing if cursor at start of inputBuf
    ld c, a ; BC=cursorInputPos
    ld b, 0
    ld hl, inputBuf
    ld a, (hl) ; A=inputBufLen
    or a
    ret z ; do nothing if buffer empty
    ; shorten string by one
    dec (hl) ; inputBufLen-=1
    add hl, bc ; HL=inputBuf+cursorInputPos-1
    ld e, l
    ld d, h ; DE=inputBuf+cursorInputPos-1
    inc hl ; HL=inputBuf+cursorInputPos
    sub c ; A=len-pos; ZF=1 if no bytes need to be moved
    jr z, deleteCharInputBufUpdate
    ld c, a ; C=numByte
    ldir
deleteCharInputBufUpdate:
    ; update cursor as well
    ld hl, cursorInputPos
    dec (hl) ; cursorInputPos-=1
    set dirtyFlagsInput, (iy + dirtyFlags)
    ret

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
    ; Scan backwards from end of string to determine eeLen
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
; Input:
;   - inputBuf
; Output:
;   - A:u8=inputBufChsPos, the position where a sign character can be added or
;   removed (i.e. after an 'E', after the complex delimiter, or at the start of
;   the buffer if empty)
; Destroys: BC, HL
; Preserves: DE
CheckInputBufChs:
    ld hl, inputBuf
    ld c, (hl) ; C=len
    ld b, 0 ; BC=len
    ; check for len==0
    ld a, c ; A=len
    or a ; if len==0: ZF=0
    ret z
    ;
    inc hl ; skip past len byte
    add hl, bc ; HL=pointer to end of string
    ld b, a ; B=len
checkInputBufChsLoop:
    ; Scan backwards from end of string to determine inputBufChsPos
    dec hl
    ld a, (hl)
    cp Lexponent ; ZF=1 if EE char detected
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
    ; Scan backwards from end of string to determine existence of decimal point.
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

;-----------------------------------------------------------------------------
; Entering complex numbers into the inputBuf.
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

; Description: Return ZF=1 if A is a complex number delimiter (LimagI, Langle,
; Ldegree). Same as isComplexDelimiter().
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

; Description: Return ZF=1 if A is a real or complex number delimiter: '{', ','
; or '}'.
; Input: A: char
; Output: ZF=1 if delimiter
; Destroys: none
isNumberDelimiterPageOne:
    cp LlBrace ; '{'
    ret z
    cp LrBrace ; '}'
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
