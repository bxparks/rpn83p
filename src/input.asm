;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Functions related to parsing the inputBuf into a floating point number.
;------------------------------------------------------------------------------

; Description: Close the inputBuf by parsing its content into the X register.
; If the app is *not* in edit mode, do nothing.
;
; The 'rpnFlagsLiftEnabled' flag is set if the inputBuf was filled with
; characters when closed. It is cleared if the inputBuf was an empty string
; when it was closed. This turns out to the behavior of Classic HP RPN
; calculators, where the user expects a function like PI to *replace* the "0"
; that was parsed from an empty string, but expects the stack to lift if the
; "0" was parsed from an explicitly entered "0" character.
;
; The calling handler can override the rpnFlagsLiftEnabled flag as necessary.
; For example, ENTER or Sigma+ will disable stack lift so that the next number
; entry will clobber the X value.
;
; Most button and menu handlers should probably use the various
; closeInputAndRecallXxx() instead, to transfer the X or Y parameters into the
; CP1 or CP2 variables. This decouples the implementations of those handlers
; from the RPN stack, and making them easier move to different Flash Pages if
; needed.
;
; Input:
;   - rpnFlagsEditing: indicates if inputBuf needs to be parsed
;   - inputBuf: input buffer
; Output:
;   - X register: set to inputBuf if edited, otherwise unchanged
;   - OP1=X if edited, otherwise unchanged (use X register instead)
;   - inputBuf cleared to empty string
;   - rpnFlagsLiftEnabled: cleared if inputBuf was empty, set otherwise
;   - rpnFlagsEditing: always cleared
; Destroys: all, OP1, OP2, OP3, OP4, OP5
closeInput:
    bit rpnFlagsEditing, (iy + rpnFlags)
    ret z
closeInputEditing:
    bcall(_ParseAndClearInputBuf) ; CP1=rpnObject; rpnFlagsLiftEnabled updated
    bcall(_StoStackX)
    res rpnFlagsEditing, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------

; Description: Close the input buffer, and don't set OP1 to anything.
; Output:
;   - rpnFlagsTvmCalculate: cleared
;   - inputBuf cleared to empty string
;   - rpnFlagsLiftEnabled: cleared if inputBuf was empty, set otherwise
;   - rpnFlagsEditing: always cleared
; Destroys: all, OP1, OP2, OP3, OP4, OP5
closeInputAndRecallNone:
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr closeInput

; Description: Close the input buffer, and recall real X into OP1.
; Output:
;   - OP1:Real=X
;   - A:u8=rpnObjectType
;   - rpnFlagsTvmCalculate: cleared
;   - inputBuf cleared to empty string
;   - rpnFlagsLiftEnabled: cleared if inputBuf was empty, set otherwise
;   - rpnFlagsEditing: always cleared
; Destroys: all, OP1, OP2, OP3, OP4, OP5
closeInputAndRecallX:
    call closeInput
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    bcall(_RclStackX) ; A=objectType; OP1=X
    cp rpnObjectTypeReal
    ret z
    bcall(_ErrDataType)

; Description: Close the input buffer, and recall real values into OP1=Y and
; OP2=X.
; Output:
;   - OP1:Real=Y
;   - OP2:Real=X
;   - A:u8=rpnObjectTypeY
;   - rpnFlagsTvmCalculate: cleared
;   - inputBuf cleared to empty string
;   - rpnFlagsLiftEnabled: cleared if inputBuf was empty, set otherwise
;   - rpnFlagsEditing: always cleared
; Destroys: all, OP1, OP2, OP3, OP4, OP5
closeInputAndRecallXY:
    call closeInput
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    bcall(_RclStackXY) ; CP1=Y; CP3=X
    call validateOp3Real ; throws Err:DataType if not
    call validateOp1Real ; throws Err:DataType if not
    jp op3ToOp2 ; OP2=Real(X)

; Description: Close the input buffer, and recall the RpnObject X to CP1.
; Output:
;   - CP1:RpnObject=X
;   - A:u8=rpnObjectType
;   - rpnFlagsTvmCalculate: cleared
;   - inputBuf cleared to empty string
;   - rpnFlagsLiftEnabled: cleared if inputBuf was empty, set otherwise
;   - rpnFlagsEditing: always cleared
; Destroys: all, OP1, OP2, OP3, OP4, OP5
closeInputAndRecallUniversalX:
    call closeInput
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    bcall(_RclStackX)
    ret

; Description: Close the input buffer, and recall the RpnObject X and Y into
; CP1=Y and CP3=X.
; Output:
;   - CP1:RpnObject=Y
;   - CP3:RpnObject=X
;   - A:u8=rpnObjectTypeY
;   - rpnFlagsTvmCalculate: cleared
;   - inputBuf cleared to empty string
;   - rpnFlagsLiftEnabled: cleared if inputBuf was empty, set otherwise
;   - rpnFlagsEditing: always cleared
; Destroys: all, OP1, OP2, OP3, OP4, OP5
closeInputAndRecallUniversalXY:
    call closeInput
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    bcall(_RclStackXY) ; CP1=Y; CP3=X
    ret

;-----------------------------------------------------------------------------

; Description: Close the input buffer, parse RpnDate{} record, place it into
; CP1.
; Output:
;   - CP1:RpnDate=rpnDate
;   - A:u8=rpnObjectType
;   - rpnFlagsTvmCalculate: cleared
;   - inputBuf cleared to empty string
;   - rpnFlagsLiftEnabled: cleared if inputBuf was empty, set otherwise
;   - rpnFlagsEditing: always cleared
; Destroys: all, OP1, OP2, OP3, OP4, OP5
closeInputAndRecallRpnDateX:
    call closeInput
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    bcall(_RclStackX) ; A=objectType
    cp rpnObjectTypeDate
    ret z
    bcall(_ErrDataType)

; Description: Close the input buffer, validate RpnOffset{}, and place it into
; CP1.
;   - CP1:RpnOffset=rpnOffset
;   - A:u8=rpnObjectType
;   - rpnFlagsTvmCalculate: cleared
;   - inputBuf cleared to empty string
;   - rpnFlagsLiftEnabled: cleared if inputBuf was empty, set otherwise
;   - rpnFlagsEditing: always cleared
; Destroys: all, OP1, OP2, OP3, OP4, OP5
closeInputAndRecallRpnOffsetX:
    call closeInput
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    bcall(_RclStackX) ; A=objectType
    cp rpnObjectTypeOffset
    ret z
    bcall(_ErrDataType)

; Description: Close the input buffer, validate RpnOffset{} or Real, and place
; it into CP1.
; Output:
;   - CP1:RpnOffset|Real=rpnOffset
;   - A:u8=rpnObjectType
;   - rpnFlagsTvmCalculate: cleared
;   - inputBuf cleared to empty string
;   - rpnFlagsLiftEnabled: cleared if inputBuf was empty, set otherwise
;   - rpnFlagsEditing: always cleared
; Destroys: all, OP1, OP2, OP3, OP4, OP5
closeInputAndRecallRpnOffsetOrRealX:
    call closeInput
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    bcall(_RclStackX) ; A=objectType
    cp rpnObjectTypeOffset
    ret z
    cp rpnObjectTypeReal
    ret z
    bcall(_ErrDataType)

; Description: Close the input buffer, parse RpnOffsetDateTime{} record, place
; it into CP1.
; Output:
;   - CP1:RpnOffsetDateTime=rpnOffsetDateTime
;   - A:u8=rpnObjectType
;   - rpnFlagsTvmCalculate: cleared
;   - inputBuf cleared to empty string
;   - rpnFlagsLiftEnabled: cleared if inputBuf was empty, set otherwise
;   - rpnFlagsEditing: always cleared
; Destroys: all, OP1, OP2, OP3, OP4, OP5
closeInputAndRecallRpnOffsetDateTimeX:
    call closeInput
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    bcall(_RclStackX) ; A=objectType
    cp rpnObjectTypeOffsetDateTime
    ret z
    bcall(_ErrDataType)

; Description: Close the input buffer, parse a date-like object (RpnDate,
; RpnDateTime, or RpnOffsetDateTime), place it into CP1.
; Output:
;   - CP1:Rpn{Date-like}=rpnDateLike
;   - A:u8=rpnObjectType
;   - rpnFlagsTvmCalculate: cleared
;   - inputBuf cleared to empty string
;   - rpnFlagsLiftEnabled: cleared if inputBuf was empty, set otherwise
;   - rpnFlagsEditing: always cleared
; Destroys: all, OP1, OP2, OP3, OP4, OP5
closeInputAndRecallRpnDateLikeX:
    call closeInput
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    bcall(_RclStackX) ; A=objectType
    cp rpnObjectTypeDate
    ret z
    cp rpnObjectTypeDateTime
    ret z
    cp rpnObjectTypeOffsetDateTime
    ret z
    bcall(_ErrDataType)

; Description: Close and parse the input buffer, place the value into OP1, and
; return successfully if the input was a date-related object: RpnDate, RpnTime,
; RpnDateTime, RpnOffset, RpnOffsetDateTime, RpnDayOfWeek.
; Output:
;   - CP1:Rpn{Date-related}=rpnDateRelated
;   - A:u8=rpnObjectType
;   - rpnFlagsTvmCalculate: cleared
;   - inputBuf cleared to empty string
;   - rpnFlagsLiftEnabled: cleared if inputBuf was empty, set otherwise
;   - rpnFlagsEditing: always cleared
; Destroys: all, OP1, OP2, OP3, OP4, OP5
closeInputAndRecallRpnDateRelatedX:
    call closeInput
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    bcall(_RclStackX) ; A=objectType
    cp rpnObjectTypeDate
    ret z
    cp rpnObjectTypeTime
    ret z
    cp rpnObjectTypeDateTime
    ret z
    cp rpnObjectTypeOffset
    ret z
    cp rpnObjectTypeOffsetDateTime
    ret z
    cp rpnObjectTypeDuration
    ret z
    cp rpnObjectTypeDayOfWeek
    ret z
    bcall(_ErrDataType)

;-----------------------------------------------------------------------------

; Description: Close the input buffer, and recall X (Real or RpnDenominate)
; into CP1.
; Output:
;   - CP1:Real|RpnDenominate=X
;   - A=rpnObjectType
;   - rpnFlagsTvmCalculate: cleared
;   - inputBuf cleared to empty string
;   - rpnFlagsLiftEnabled: cleared if inputBuf was empty, set otherwise
;   - rpnFlagsEditing: always cleared
; Destroys: all, OP1, OP2, OP3, OP4, OP5
; Throws: Err:DataType
closeInputAndRecallDenominateX:
    call closeInput
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    bcall(_RclStackX) ; A=objectType
    ; Allow Real
    cp rpnObjectTypeReal
    ret z
    ; Allow RpnDenominate
    cp rpnObjectTypeDenominate
    ret z
    ; Unexpected type
    bcall(_ErrDataType)

;------------------------------------------------------------------------------
; Low-level helpers.
;------------------------------------------------------------------------------

; Description: Insert string at HL into inputBuf. If the string is too long,
; characters that do fit are inserted, and the rest of the string is ignore.
; This function cannot be in input1.asm (Flash Page 1) because HL points
; to strings on Flash Page 0.
; Input:
;   - HL:(const char*)=string
;   - cursorInputPos:u8=insertPosition
; Output:
;   - dirtyFlagsInput always set
;   - CF=0 if successful
;   - (cursorInputPos)+=len(string) if successful
; Destroys: all
insertStringInputBuf:
    ld a, (hl)
    or a
    ret z ; NUL terminator
    inc hl
    push hl
    bcall(_InsertCharInputBuf) ; CF=1 if error; destroys HL
    pop hl
    ret c ; return on error (e.g. reached end of inputBuf)
    jr insertStringInputBuf
