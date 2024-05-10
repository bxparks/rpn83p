;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; RPN object types. Basically the same as rpnobject.asm but in Flash Page 2.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Get rpnObjectType.
;-----------------------------------------------------------------------------

; Description: Return the rpnObjectType of OP1/OP2.
; Input: OP1
; Output: A=rpnObjectType; HL=OP1
; Destroys: A, HL
getOp1RpnObjectTypePageTwo:
    ld hl, OP1
    jr getHLRpnObjectTypePageTwo

; Description: Return the rpnObjectType of OP3/OP4.
; Input: OP3
; Output: A=rpnObjectType; HL=OP3
; Destroys: A, HL
getOp3RpnObjectTypePageTwo:
    ld hl, OP3
    ; [[fallthrough]]

; Description: Return the rpnObjectType of HL.
; Input: HL:(RpnObject*)
; Output: A=rpnObjectType
; Destroys: A
; Preserves: HL
getHLRpnObjectTypePageTwo:
    ld a, (hl)
    and rpnObjectTypeMask
    ret

;-----------------------------------------------------------------------------
; Set rpnObjectType.
;-----------------------------------------------------------------------------

; Description: Set the rpnObjectType of OP1/OP2 to A.
; Input: A=rpnObjectType
; Output: HL=OP1+1
; Destroys: HL
; Preserves: A, BC, DE
setOp1RpnObjectTypePageTwo:
    ld hl, OP1
    jr setHLRpnObjectTypePageTwo

; Description: Return the rpnObjectType of OP3/OP4.
; Input: A=rpnObjectType
; Output: HL=OP3+1
; Destroys: HL
; Preserves: A, BC, DE
setOp3RpnObjectTypePageTwo:
    ld hl, OP3
    ; [[fallthrough]]

; Description: Set the rpnObjectType of HL to A.
; Input: A=rpnObjectType
; Output: HL+=1
; Destroys: HL
; Preserves: A, BC, DE
setHLRpnObjectTypePageTwo:
    ld (hl), a
    inc hl
    ret

;-----------------------------------------------------------------------------
; Complex numbers.
;-----------------------------------------------------------------------------

; Description: Same as CkOP1Cplx() OS routine without the bcall() overhead.
; Input: OP1
; Output: ZF=1 if complex
; Destroys: A
checkOp1ComplexPageTwo:
    ld a, (OP1)
    and rpnObjectTypeMask
    cp rpnObjectTypeComplex
    ret

;-----------------------------------------------------------------------------
; Date related objects.
;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnTime.
; Output: ZF=1 if RpnTime
checkOp1TimePageTwo:
    ld a, (OP1)
    and rpnObjectTypeMask
    cp rpnObjectTypeTime
    ret

; Description: Check if OP3 is an RpnTime.
; Output: ZF=1 if RpnTime
checkOp3TimePageTwo:
    ld a, (OP3)
    and rpnObjectTypeMask
    cp rpnObjectTypeTime
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is a RpnDate.
; Output: ZF=1 if RpnDate
checkOp1DatePageTwo:
    ld a, (OP1)
    and rpnObjectTypeMask
    cp rpnObjectTypeDate
    ret

; Description: Check if OP3 is a RpnDate.
; Output: ZF=1 if RpnDate
checkOp3DatePageTwo:
    ld a, (OP3)
    and rpnObjectTypeMask
    cp rpnObjectTypeDate
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is a RpnDateTime.
; Output: ZF=1 if RpnDateTime
checkOp1DateTimePageTwo:
    ld a, (OP1)
    and rpnObjectTypeMask
    cp rpnObjectTypeDateTime
    ret

; Description: Check if OP3 is a RpnDateTime.
; Output: ZF=1 if RpnDateTime
checkOp3DateTimePageTwo:
    ld a, (OP3)
    and rpnObjectTypeMask
    cp rpnObjectTypeDateTime
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is a RpnOffset.
; Output: ZF=1 if RpnOffset
checkOp1OffsetPageTwo:
    ld a, (OP1)
    and rpnObjectTypeMask
    cp rpnObjectTypeOffset
    ret

; Description: Check if OP3 is a RpnOffset.
; Output: ZF=1 if RpnOffset
checkOp3OffsetPageTwo:
    ld a, (OP3)
    and rpnObjectTypeMask
    cp rpnObjectTypeOffset
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is a RpnOffsetDateTime.
; Output: ZF=1 if RpnOffsetDateTime
checkOp1OffsetDateTimePageTwo:
    ld a, (OP1)
    and rpnObjectTypeMask
    cp rpnObjectTypeOffsetDateTime
    ret

; Description: Check if OP3 is a RpnOffsetDateTime.
; Output: ZF=1 if RpnOffsetDateTime
checkOp3OffsetDateTimePageTwo:
    ld a, (OP3)
    and rpnObjectTypeMask
    cp rpnObjectTypeOffsetDateTime
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnDayOfWeek.
; Output: ZF=1 if RpnDayOfWeek
checkOp1DayOfWeekPageTwo:
    ld a, (OP1)
    and rpnObjectTypeMask
    cp rpnObjectTypeDayOfWeek
    ret

; Description: Check if OP3 is an RpnDayOfWeek.
; Output: ZF=1 if RpnDayOfWeek
checkOp3DayOfWeekPageTwo:
    ld a, (OP3)
    and rpnObjectTypeMask
    cp rpnObjectTypeDayOfWeek
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnDuration.
; Output: ZF=1 if RpnDuration
checkOp1DurationPageTwo:
    ld a, (OP1)
    and rpnObjectTypeMask
    cp rpnObjectTypeDuration
    ret

; Description: Check if OP3 is an RpnDuration.
; Output: ZF=1 if RpnDuration
checkOp3DurationPageTwo:
    ld a, (OP3)
    and rpnObjectTypeMask
    cp rpnObjectTypeDuration
    ret
