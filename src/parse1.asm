;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Functions related to parsing the inputBuf into various RpnObject types.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;------------------------------------------------------------------------------

; Description: Parse the object in inputBuf into OP1. Early versions of this
; routine assumed that the input routines (in input.asm and input1.asm)
; rejected syntatically or semantically invalid characters in inputBuf, so this
; routine could be somewhat lazy about checking for syntax or semantics.
; However, with the addition of tagged Record types (e.g. Date and Time), the
; input subsystem cannot check for all possible errors, so these parsing
; routines must now be more stringent. Various routines will throw Err:Syntax
; or Err:Invalid when it detects something wrong.
;
; The `inputBufFlagsClosedEmpty` flag is set if the inputBuf was an empty string
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
;   - A:u8=rpnObjectType
;   - inputBufFlagsClosedEmpty: set if inputBuf was an empty string when closed
;   - inputBuf cleared to empty string if successful
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

;------------------------------------------------------------------------------
; Parsing real and complex numbers.
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

;------------------------------------------------------------------------------
; Parsing BASE numbers.
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

;-----------------------------------------------------------------------------
; Parsing tagged Records (Date, Time, DateTime, Offset, OffsetDateTime).
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
    cp recordTagTypeDayOfWeek
    jr z, parseInputBufDayOfWeek
    cp recordTagTypeDuration
    jp z, parseInputBufDuration
    bcall(_ErrInvalid) ; should never happen
parseInputBufRecordNaked:
    ; Naked records cannot support Time because it has the same number of
    ; commas as a Date.
    call countCommas ; A=numCommas, preserves HL
    cp 1
    jr z, parseInputBufOffset
    cp 2
    jr z, parseInputBufDate
    cp 3
    jr z, parseInputBufDuration
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
parseInputBufDayOfWeek:
    ld de, OP1
    ld a, rpnObjectTypeDayOfWeek
    ld (de), a
    inc de ; skip type byte
    push de
    call parseDayOfWeek
    pop hl ; HL=OP1+1
    bcall(_ValidateDayOfWeek)
    ret
parseInputBufDuration:
    ld de, OP1
    ld a, rpnObjectTypeDuration
    ld (de), a
    inc de ; skip type byte
    push de
    call parseDuration
    pop hl ; HL=OP1+1
    bcall(_ValidateDuration)
    ret
