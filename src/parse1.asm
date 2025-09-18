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

; Description: Parse the string in inputBuf into an object in OP1. Various
; subroutines will throw Err:Syntax or Err:Invalid when it detects something
; wrong.
;
; The `inputBufFlagsClosedEmpty` flag is set if the inputBuf was an empty string
; before being closed. The flag is used by functions which do not consume any
; value from the RPN stack, but simply push a value or two onto the X or Y
; registers (e.g. PI, E, or various TVM functions, various STAT functions). If
; the user had pressed CLEAR, to clear the input buffer, then it doesn't make
; sense for these functions to lift the empty string (i.e. 0) up when pushing
; the new values. These functions call PushToStackX() or PushOp1Op2ToStackXY()
; which checks if the inputBuf was closed when empty. If empty, PushToStackX()
; or PushOp1Op2ToStackXY() will *not* lift the stack, but simply replace the
; "0" in the X register with the new value. This flag is cleared if the
; inputBuf was not in edit mode, with the assumption that new X or Y values
; should lift the stack.
;
; This routine calls ClearInputBuf() before returning to the closeInput()
; routine. It would be cleaner to move the ClearInputBuf() to closeInput() to
; avoid the duplication in this routine. But closeInput() is on Flash Page 0,
; and ClearInputBuf() is on Flash Page 1, so placing the ClearInputBuf() here
; prevents an expensive bcall() overhead.
;
; Input:
;   - inputBuf:PascalString
; Output:
;   - OP1/OP2:RpnObject
;   - inputBuf cleared to empty string if successful
;   - inputBufFlagsClosedEmpty: set if inputBuf was an empty string when closed
;   - rpnFlagsLiftEnabled: 0 if inputBuf was empty, 1 otherwise
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
    res rpnFlagsLiftEnabled, (iy + rpnFlags)
    call op1Set0PageOne
    jp ClearInputBuf
parseAndClearInputBufNonEmpty:
    res inputBufFlagsClosedEmpty, (iy + inputBufFlags)
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ; add NUL terminator to inputBuf to simplify parsing
    ld hl, inputBuf
    call preparePascalStringForParsing ; preserves HL
    ; Check for '{' which identifies a Record type
    ld a, LlBrace ; A='{'
    call findChar ; CF=1 if found; HL preserved
    jr c, parseAndClearInputBufRecord
    ; Check for ':'  which identifies a modifier.
    ld a, ':' ; A=':'
    call findChar ; CF=1 if found; HL preserved
    jr c, parseAndClearInputBufTaggedNumber
    ; Check for DHMS which identifies a compact Duration.
    call checkCompactDuration ; CF=1 if compact Duration
    jr c, parseAndClearInputBufCompactDuration
    ; Everything else should be a Real or a Complex number.
    call parseInputBufNumber ; OP1/OP2=real or complex
    jp ClearInputBuf ; see note above
parseAndClearInputBufRecord:
    call parseInputBufRecord ; OP1/OP2:record
    jp ClearInputBuf ; see note above
parseAndClearInputBufTaggedNumber:
    call parseInputBufTaggedNumber ; OP1/OP2:real
    jp ClearInputBuf ; see note above
parseAndClearInputBufCompactDuration:
    call parseInputBufCompactDuration ; OP1/OP2:real
    jp ClearInputBuf ; see note above

;------------------------------------------------------------------------------
; Parsing real and complex numbers.
;------------------------------------------------------------------------------

; Description: Parse the input buffer into a real or complex number in OP1/OP2.
; Input:
;   - HL:(PascalString*)=inputBuf
; Output:
;   - OP1/OP2: real or complex number
; Destroys: all registers, OP1-OP5 (due to SinCosRad())
; Throws: Err:Syntax if there is a parsing error
parseInputBufNumber:
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
; Input:
;   - HL:(PascalString*)=inputBuf
; Output:
;   - OP1/OP2=rpnObject (e.g. RpnDate, RpnDateTime, RpnOffsetDateTime)
; Uses: parseBuf
; Destroys: all
; Throws:
;   - Err:Syntax if the syntax is incorrect
;   - Err:Invalid if there's a programming logic error
parseInputBufRecord:
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
    ; Implement type inference for naked records (i.e. without a prefix tag
    ; like `{2024,3,14}`, `{2,30}`) to one of the date object types, by mapping
    ; the number of arguments within the curly braces to a specific object
    ; type. For example, if there are 2 arugments, we infer the type to be a
    ; TimeZone object. If there are 3 arguments, we infer the type to be a Date
    ; object.
    ;
    ; A naked record with a single argument could be inferred to be a DayOfWeek
    ; object. But a DayOfWeek is almost always an *output* object, returned by
    ; the DOW menu command. It is unlikely that a user will need to *input* a
    ; DayOfWeek object. So we do *not* support a single-argument naked record
    ; for now. It may be used in the future to map to another object type.
    call countCommas ; A=numCommas, preserves HL
    cp 1
    jr z, parseInputBufOffset
    cp 2 ; could be Date or Time, I think Date is more convenient
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
    ex de, hl ; DE=inputBuf
    ld a, rpnObjectTypeOffset
    call setOp1RpnObjectTypePageOne ; HL=OP1+sizeof(type)
    push hl ; stack=[offsetPointer]
    ex de, hl ; DE=offsetPointer; HL=inputBuf
    call parseOffset
    pop hl ; stack=[]; HL=offsetPointer
    bcall(_ValidateOffset)
    ret
parseInputBufDate:
    ex de, hl ; DE=inputBuf
    ld a, rpnObjectTypeDate
    call setOp1RpnObjectTypePageOne ; HL=OP1+sizeof(type)
    push hl ; stack=[datePointer]
    ex de, hl ; DE=datePointer; HL=inputBuf
    call parseDate
    pop hl ; stack=[]; HL=datePointer
    bcall(_ValidateDate)
    ret
parseInputBufTime:
    ex de, hl ; DE=inputBuf
    ld a, rpnObjectTypeTime
    call setOp1RpnObjectTypePageOne ; HL=OP1+sizeof(type)
    push hl ; stack=[timePointer]
    ex de, hl ; DE=timePointer; HL=inputBuf
    call parseTime
    pop hl ; stack=[]; HL=timePointer
    bcall(_ValidateTime)
    ret
parseInputBufDateTime:
    ex de, hl ; DE=inputBuf
    ld a, rpnObjectTypeDateTime
    call setOp1RpnObjectTypePageOne ; HL=OP1+sizeof(type)
    push hl ; stack=[dateTimePointer]
    ex de, hl ; DE=dateTimePointer; HL=inputBuf
    call parseDateTime
    pop hl ; stack=[]; HL=dateTimePointer
    bcall(_ValidateDateTime)
    ret
parseInputBufOffsetDateTime:
    ex de, hl ; DE=inputBuf
    ld a, rpnObjectTypeOffsetDateTime
    call setOp1RpnObjectTypePageOne ; HL=OP1+sizeof(type)
    push hl ; stack=[offsetDateTimePointer]
    ex de, hl ; DE=offsetDateTimePointer; HL=inputBuf
    call parseOffsetDateTime
    pop hl ; stack=[]; HL=offsetDateTimePointer
    bcall(_ValidateOffsetDateTime)
    call expandOp1ToOp2PageOne ; sizeof(OffsetDateTime)>9
    ret
parseInputBufDayOfWeek:
    ex de, hl ; DE=inputBuf
    ld a, rpnObjectTypeDayOfWeek
    call setOp1RpnObjectTypePageOne ; HL=OP1+sizeof(type)
    push hl ; stack=[dayOfWeekPointer]
    ex de, hl ; DE=offsetDateTimePointer; HL=inputBuf
    call parseDayOfWeek
    pop hl ; stack=[]; HL=dayOfWeekPointer
    bcall(_ValidateDayOfWeek)
    ret
parseInputBufDuration:
    ex de, hl ; DE=inputBuf
    ld a, rpnObjectTypeDuration
    call setOp1RpnObjectTypePageOne ; HL=OP1+sizeof(type)
    push hl ; stack=[durationPointer]
    ex de, hl ; DE=durationPointer; HL=inputBuf
    call parseDuration
    pop hl ; stack=[]; HL=durationPointer
    bcall(_ValidateDuration)
    ret

;-----------------------------------------------------------------------------
; Parse integers with ':' modifiers into RpnDuration object.
; Accepted values are:
;   - nn:D - Duration.days
;   - nn:H - Duration.hours
;   - nn:M - Duration.minutes
;   - nn:S - Duration.seconds
;-----------------------------------------------------------------------------

; Description: Parse a tagged number of the form {nnnn:M}, where M can be one
; of ('D', 'H', 'M', or 'S'). Currently, only Duration type is supported.
; Input:
;   - HL:(PascalString*)=inputBuf
; Output:
;   - OP1:RpnDuration=duration
; Destroys: all
parseInputBufTaggedNumber:
    inc hl ; skip len byte
    ; First parse the tagged number into OP1, as a temp buffer. Currently,
    ; a single signed i16 integer with a modifier suffix is supported.
    ld de, OP1 ; DE=taggedNumber (2-bytes)
    call parseI16D4 ; DE=DE+2
    call parseInputBufColon
    call parseInputBufModifier ; A=modifier
    ; convert taggedNumber to RpnObject
    ld de, OP1
    ld hl, OP2
    call convertTaggedNumberToRpnObject
    call op2ToOp1PageOne
    ret

parseInputBufColon:
    ld a, (hl)
    inc hl
    cp ':'
    ret z
    bcall(_ErrSyntax)

parseInputBufModifier:
    ld a, (hl)
    inc hl
    or a ; ZF=1 if NUL
    ret nz
    bcall(_ErrSyntax)

; Description: Convert the tagged number in DE to an RpnObject in HL.
; Currently, only the RpnDuration object is supported.
; Input:
;   - A:u8=tag
;   - DE:(TaggedNumber*)=taggedNumber
; Output:
;   - HL:(RpnObject*)=rpnObject
; Destroys: all
convertTaggedNumberToRpnObject:
    push hl ; stack=[rpnObject]
    cp 'D'
    jr z, convertTaggedDaysToDuration
    cp 'H'
    jr z, convertTaggedHoursToDuration
    cp 'M'
    jr z, convertTaggedMinutesToDuration
    cp 'S'
    jr z, convertTaggedSecondsToDuration
    bcall(_ErrSyntax)
convertTaggedDaysToDuration:
    ld a, rpnObjectTypeDuration
    call setHLRpnObjectTypePageOne ; HL+=sizeof(type)
    call clearDuration
    ; copy days
    ld a, (de)
    inc de
    ld (hl), a
    inc hl
    ;
    ld a, (de)
    inc de
    ld (hl), a
    jr convertTaggedValidation
convertTaggedHoursToDuration:
    ld a, rpnObjectTypeDuration
    call setHLRpnObjectTypePageOne ; HL+=sizeof(type)
    call clearDuration
    ; copy hours
    inc hl
    inc hl
    ld a, (de)
    inc de
    ld (hl), a
    jr convertTaggedValidation
convertTaggedMinutesToDuration:
    ld a, rpnObjectTypeDuration
    call setHLRpnObjectTypePageOne ; HL+=sizeof(type)
    call clearDuration
    ; copy minutes
    inc hl
    inc hl
    inc hl
    ld a, (de)
    inc de
    ld (hl), a
    jr convertTaggedValidation
convertTaggedSecondsToDuration:
    ld a, rpnObjectTypeDuration
    call setHLRpnObjectTypePageOne ; HL+=sizeof(type)
    call clearDuration
    ; copy seconds
    inc hl
    inc hl
    inc hl
    inc hl
    ld a, (de)
    inc de
    ld (hl), a
    ; [[fallthrough]]
convertTaggedValidation:
    pop hl ; stack=[]; HL=rpnObject
    skipRpnObjectTypeHL ; HL=(Duration*)
    bcall(_ValidateDuration)
    ret

; Description: Clear the duration pointed by HL.
; Input: HL:(Duration*)=duration
; Output: HL=duration=0
; Destroys: none
clearDuration:
    push bc
    push de
    push hl
    ld e, l
    ld d, h
    inc de
    ld (hl), 0
    ld bc, rpnObjectTypeDurationSizeOf-1
    ldir
    pop hl
    pop de
    pop bc
    ret

;-----------------------------------------------------------------------------
; Parse Compact Duration string into an RpnDuration object.
;-----------------------------------------------------------------------------

; Description: Parse a compact Duration string.
; terminator. Then check for 'D', 'H', 'M', 'S', and move the integer into the
; correct position in the Duration object.
; Input:
;   - HL:(PascalString*)=inputBuf
; Output:
;   - OP1:RpnDuration=duration
; Destroys: all
parseInputBufCompactDuration:
    inc hl ; skip len byte
    ; set up target RpnDuration object
    ex de, hl ; DE=inputBuf
    ld hl, OP1 ; HL:RpnDuration
    ld a, rpnObjectTypeDuration
    call setOp1RpnObjectTypePageOne ; HL=OP1+sizeof(type)=duration
    ; Parse the Duration string in compact form
    push hl ; stack=[duration]
    ex de, hl ; DE=Duration; HL=inputBuf
    call parseCompactDuration
    pop hl ; stack=[]; HL=duration
    ; Validate Duration object
    bcall(_ValidateDuration)
    ret
