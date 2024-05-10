;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; RPN object types.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Get rpnObjectType.
;-----------------------------------------------------------------------------

; Description: Return the rpnObjectType of OP1/OP2.
; Input: OP1
; Output: A=rpnObjectType; HL=OP1
; Destroys: A, HL
getOp1RpnObjectType:
    ld hl, OP1
    jr getHLRpnObjectType

; Description: Return the rpnObjectType of OP3/OP4.
; Input: OP3
; Output: A=rpnObjectType; HL=OP3
; Destroys: A, HL
getOp3RpnObjectType:
    ld hl, OP3
    ; [[fallthrough]

; Description: Return the rpnObjectType of HL.
; Input: HL:(RpnObject*)
; Output: A=rpnObjectType
; Destroys: A
; Preserves: HL
getHLRpnObjectType:
    ld a, (hl)
    and rpnObjectTypeMask
    ret

;-----------------------------------------------------------------------------
; Set rpnObjectType.
;-----------------------------------------------------------------------------

; Description: Set the rpnObjectType of OP1/OP2 to A.
; Input: A=rpnObjectType
; Output: HL=OP1+rpnObjectTypeSizeOf
; Destroys: HL
; Preserves: A, BC, DE
setOp1RpnObjectType:
    ld hl, OP1
    jr setHLRpnObjectType

; Description: Return the rpnObjectType of OP3/OP4.
; Input: A=rpnObjectType
; Output: HL=OP3+rpnObjectTypeSizeOf
; Destroys: HL
; Preserves: A, BC, DE
setOp3RpnObjectType:
    ld hl, OP3
    ; [[fallthrough]]

; Description: Set the rpnObjectType of HL to A.
; Input: A=rpnObjectType
; Output: HL+=1
; Destroys: HL
; Preserves: A, BC, DE
setHLRpnObjectType:
    ld (hl), a
    skipRpnObjectTypeHL
    ret

;-----------------------------------------------------------------------------
; Real numbers.
;-----------------------------------------------------------------------------

; Description: Check that OP1 is a Real number.
; Input: OP1
; Output: ZF=1 if real
; Destroys: A
checkOp1Real:
    call getOp1RpnObjectType
    cp rpnObjectTypeReal
    ret

; Description: Check that OP3 is a Real number.
; Input: OP3
; Output: ZF=1 if real
; Destroys: A
checkOp3Real:
    call getOp3RpnObjectType
    cp rpnObjectTypeReal
    ret

; Description: Check that both OP1 and OP3 are Real.
; Input: OP1, OP3
; Output: ZF=1 if both are real, ZF=0 otherwise
; Destroys: A
checkOp1AndOp3Real:
    call getOp1RpnObjectType
    cp rpnObjectTypeReal
    ret nz
    call getOp3RpnObjectType
    cp rpnObjectTypeReal
    ret

; Description: Verify that X is real.
; Throws: Err:DateType if not
; Destroys: OP1/OP2
validateOp1Real:
    call checkOp1Real
    ret z
    bcall(_ErrDataType)

;-----------------------------------------------------------------------------
; Complex numbers.
;-----------------------------------------------------------------------------

; Description: Same as CkOP1Cplx() OS routine without the bcall() overhead.
; Input: OP1
; Output: ZF=1 if complex
; Destroys: A
checkOp1Complex:
    call getOp1RpnObjectType
    cp rpnObjectTypeComplex
    ret

; Description: Check if either OP1 or OP3 is complex.
; Input: OP1, OP3
; Output: ZF=1 if either parameter is complex
; Destroys: A
checkOp1OrOp3Complex:
    call checkOp1Complex ; ZF=1 if complex
    ret z
    ; [[fallthrough]]

; Description: Same as checkOp1Complex() for OP3.
; Input: OP1
; Output: ZF=1 if complex
; Destroys: A
checkOp3Complex:
    call getOp3RpnObjectType
    cp rpnObjectTypeComplex
    ret

; Description: Check if OP1 is either Real or Complex.
; Input: OP1/OP2
; Output: ZF=1 if Real or Complex
; Destroys: A
checkOp1RealOrComplex:
    call getOp1RpnObjectType
    cp rpnObjectTypeReal
    ret z
    cp rpnObjectTypeComplex
    ret

;-----------------------------------------------------------------------------
; Date related objects.
;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnTime.
; Output: ZF=1 if RpnTime
checkOp1Time:
    call getOp1RpnObjectType
    cp rpnObjectTypeTime
    ret

; Description: Check if OP3 is an RpnTime.
; Output: ZF=1 if RpnTime
checkOp3Time:
    call getOp3RpnObjectType
    cp rpnObjectTypeTime
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnDate.
; Output: ZF=1 if RpnDate
checkOp1Date:
    call getOp1RpnObjectType
    cp rpnObjectTypeDate
    ret

; Description: Check if OP3 is an RpnDate.
; Output: ZF=1 if RpnDate
checkOp3Date:
    call getOp3RpnObjectType
    cp rpnObjectTypeDate
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnDateTime.
; Output: ZF=1 if RpnDateTime
checkOp1DateTime:
    call getOp1RpnObjectType
    cp rpnObjectTypeDateTime
    ret

; Description: Check if OP3 is an RpnDateTime.
; Output: ZF=1 if RpnDateTime
checkOp3DateTime:
    call getOp3RpnObjectType
    cp rpnObjectTypeDateTime
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnOffset.
; Output: ZF=1 if RpnOffset
checkOp1Offset:
    call getOp1RpnObjectType
    cp rpnObjectTypeOffset
    ret

; Description: Check if OP3 is an RpnOffset.
; Output: ZF=1 if RpnOffset
checkOp3Offset:
    call getOp3RpnObjectType
    cp rpnObjectTypeOffset
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnOffsetDateTime.
; Output: ZF=1 if RpnOffsetDateTime
checkOp1OffsetDateTime:
    call getOp1RpnObjectType
    cp rpnObjectTypeOffsetDateTime
    ret

; Description: Check if OP3 is an RpnOffsetDateTime.
; Output: ZF=1 if RpnOffsetDateTime
checkOp3OffsetDateTime:
    call getOp3RpnObjectType
    cp rpnObjectTypeOffsetDateTime
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnDayOfWeek.
; Output: ZF=1 if RpnDayOfWeek
checkOp1DayOfWeek:
    call getOp1RpnObjectType
    cp rpnObjectTypeDayOfWeek
    ret

; Description: Check if OP3 is an RpnDayOfWeek.
; Output: ZF=1 if RpnDayOfWeek
checkOp3DayOfWeek:
    call getOp3RpnObjectType
    cp rpnObjectTypeDayOfWeek
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnDuration.
; Output: ZF=1 if RpnDuration
checkOp1Duration:
    call getOp1RpnObjectType
    cp rpnObjectTypeDuration
    ret

; Description: Check if OP3 is an RpnDuration.
; Output: ZF=1 if RpnDuration
checkOp3Duration:
    call getOp3RpnObjectType
    cp rpnObjectTypeDuration
    ret
