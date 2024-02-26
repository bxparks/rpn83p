;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; RPN object types.
;-----------------------------------------------------------------------------

; Description: Return the rpnObjectType of OP1/OP2.
; Input: OP1
; Output: A=rpnObjectType
; Destroys: A
getOp1RpnObjectType:
    ld a, (OP1)
    and $1f
    ret

;-----------------------------------------------------------------------------

; Description: Check that OP1 is a Real number.
; Input: OP1
; Output: ZF=1 if real
; Destroys: A
checkOp1Real:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeReal
    ret

; Description: Check that OP3 is a Real number.
; Input: OP3
; Output: ZF=1 if real
; Destroys: A
checkOp3Real:
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeReal
    ret

; Description: Check that both OP1 and OP3 are Real.
; Input: OP1, OP3
; Output: ZF=1 if both are real, ZF=0 otherwise
; Destroys: A
checkOp1AndOp3Real:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeReal
    ret nz
    ld a, (OP3)
    and $1f
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

; Description: Same as CkOP1Cplx() OS routine without the bcall() overhead.
; Input: OP1
; Output: ZF=1 if complex
; Destroys: A
checkOp1Complex:
    ld a, (OP1)
    and $1f
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
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeComplex
    ret

; Description: Check if OP1 is either Real or Complex.
; Input: OP1/OP2
; Output: ZF=1 if Real or Complex
; Destroys: A
checkOp1RealOrComplex:
    ld a, (OP1)
    and $1f
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
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeTime
    ret

; Description: Check if OP3 is an RpnTime.
; Output: ZF=1 if RpnTime
checkOp3Time:
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeTime
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnDate.
; Output: ZF=1 if RpnDate
checkOp1Date:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeDate
    ret

; Description: Check if OP3 is an RpnDate.
; Output: ZF=1 if RpnDate
checkOp3Date:
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeDate
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnDateTime.
; Output: ZF=1 if RpnDateTime
checkOp1DateTime:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeDateTime
    ret

; Description: Check if OP3 is an RpnDateTime.
; Output: ZF=1 if RpnDateTime
checkOp3DateTime:
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeDateTime
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnOffset.
; Output: ZF=1 if RpnOffset
checkOp1Offset:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeOffset
    ret

; Description: Check if OP3 is an RpnOffset.
; Output: ZF=1 if RpnOffset
checkOp3Offset:
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeOffset
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnOffsetDateTime.
; Output: ZF=1 if RpnOffsetDateTime
checkOp1OffsetDateTime:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeOffsetDateTime
    ret

; Description: Check if OP3 is an RpnOffsetDateTime.
; Output: ZF=1 if RpnOffsetDateTime
checkOp3OffsetDateTime:
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeOffsetDateTime
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnDayOfWeek.
; Output: ZF=1 if RpnDayOfWeek
checkOp1DayOfWeek:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeDayOfWeek
    ret

; Description: Check if OP3 is an RpnDayOfWeek.
; Output: ZF=1 if RpnDayOfWeek
checkOp3DayOfWeek:
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeDayOfWeek
    ret
