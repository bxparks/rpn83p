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
; Output: HL=OP1+rpnObjectTypeSizeOf
; Destroys: HL
; Preserves: A, BC, DE
setOp1RpnObjectTypePageTwo:
    ld hl, OP1
    jr setHLRpnObjectTypePageTwo

; Description: Return the rpnObjectType of OP3/OP4.
; Input: A=rpnObjectType
; Output: HL=OP3+rpnObjectTypeSizeOf
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
    skipRpnObjectTypeHL
    ret

;-----------------------------------------------------------------------------
; Complex numbers.
;-----------------------------------------------------------------------------

; Description: Same as CkOP1Cplx() OS routine without the bcall() overhead.
; Input: OP1
; Output: ZF=1 if complex
; Destroys: A
checkOp1ComplexPageTwo:
    call getOp1RpnObjectTypePageTwo
    cp rpnObjectTypeComplex
    ret

;-----------------------------------------------------------------------------
; Date related objects.
;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnTime.
; Output: ZF=1 if RpnTime
checkOp1TimePageTwo:
    call getOp1RpnObjectTypePageTwo
    cp rpnObjectTypeTime
    ret

; Description: Check if OP3 is an RpnTime.
; Output: ZF=1 if RpnTime
checkOp3TimePageTwo:
    call getOp3RpnObjectTypePageTwo
    cp rpnObjectTypeTime
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is a RpnDate.
; Output: ZF=1 if RpnDate
checkOp1DatePageTwo:
    call getOp1RpnObjectTypePageTwo
    cp rpnObjectTypeDate
    ret

; Description: Check if OP3 is a RpnDate.
; Output: ZF=1 if RpnDate
checkOp3DatePageTwo:
    call getOp3RpnObjectTypePageTwo
    cp rpnObjectTypeDate
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is a RpnDateTime.
; Output: ZF=1 if RpnDateTime
checkOp1DateTimePageTwo:
    call getOp1RpnObjectTypePageTwo
    cp rpnObjectTypeDateTime
    ret

; Description: Check if OP3 is a RpnDateTime.
; Output: ZF=1 if RpnDateTime
checkOp3DateTimePageTwo:
    call getOp3RpnObjectTypePageTwo
    cp rpnObjectTypeDateTime
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is a RpnOffset.
; Output: ZF=1 if RpnOffset
checkOp1OffsetPageTwo:
    call getOp1RpnObjectTypePageTwo
    cp rpnObjectTypeOffset
    ret

; Description: Check if OP3 is a RpnOffset.
; Output: ZF=1 if RpnOffset
checkOp3OffsetPageTwo:
    call getOp3RpnObjectTypePageTwo
    cp rpnObjectTypeOffset
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is a RpnOffsetDateTime.
; Output: ZF=1 if RpnOffsetDateTime
checkOp1OffsetDateTimePageTwo:
    call getOp1RpnObjectTypePageTwo
    cp rpnObjectTypeOffsetDateTime
    ret

; Description: Check if OP3 is a RpnOffsetDateTime.
; Output: ZF=1 if RpnOffsetDateTime
checkOp3OffsetDateTimePageTwo:
    call getOp3RpnObjectTypePageTwo
    cp rpnObjectTypeOffsetDateTime
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnDayOfWeek.
; Output: ZF=1 if RpnDayOfWeek
checkOp1DayOfWeekPageTwo:
    call getOp1RpnObjectTypePageTwo
    cp rpnObjectTypeDayOfWeek
    ret

; Description: Check if OP3 is an RpnDayOfWeek.
; Output: ZF=1 if RpnDayOfWeek
checkOp3DayOfWeekPageTwo:
    call getOp3RpnObjectTypePageTwo
    cp rpnObjectTypeDayOfWeek
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnDuration.
; Output: ZF=1 if RpnDuration
checkOp1DurationPageTwo:
    call getOp1RpnObjectTypePageTwo
    cp rpnObjectTypeDuration
    ret

; Description: Check if OP3 is an RpnDuration.
; Output: ZF=1 if RpnDuration
checkOp3DurationPageTwo:
    call getOp3RpnObjectTypePageTwo
    cp rpnObjectTypeDuration
    ret
