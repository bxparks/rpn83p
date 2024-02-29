;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Return the rpnObjectType of OP1/OP2.
; Input: OP1
; Output: A=rpnObjectType
; Destroys: A
getOp1RpnObjectTypePageTwo:
    ld a, (OP1)
    and $1f
    ret

;-----------------------------------------------------------------------------

; Description: Same as CkOP1Cplx() OS routine without the bcall() overhead.
; Input: OP1
; Output: ZF=1 if complex
; Destroys: A
checkOp1ComplexPageTwo:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeComplex
    ret

;-----------------------------------------------------------------------------
; Date related objects.
;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnTime.
; Output: ZF=1 if RpnTime
checkOp1TimePageTwo:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeTime
    ret

; Description: Check if OP3 is an RpnTime.
; Output: ZF=1 if RpnTime
checkOp3TimePageTwo:
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeTime
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is a RpnDate.
; Output: ZF=1 if RpnDate
checkOp1DatePageTwo:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeDate
    ret

; Description: Check if OP3 is a RpnDate.
; Output: ZF=1 if RpnDate
checkOp3DatePageTwo:
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeDate
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is a RpnDateTime.
; Output: ZF=1 if RpnDateTime
checkOp1DateTimePageTwo:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeDateTime
    ret

; Description: Check if OP3 is a RpnDateTime.
; Output: ZF=1 if RpnDateTime
checkOp3DateTimePageTwo:
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeDateTime
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is a RpnOffset.
; Output: ZF=1 if RpnOffset
checkOp1OffsetPageTwo:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeOffset
    ret

; Description: Check if OP3 is a RpnOffset.
; Output: ZF=1 if RpnOffset
checkOp3OffsetPageTwo:
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeOffset
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is a RpnOffsetDateTime.
; Output: ZF=1 if RpnOffsetDateTime
checkOp1OffsetDateTimePageTwo:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeOffsetDateTime
    ret

; Description: Check if OP3 is a RpnOffsetDateTime.
; Output: ZF=1 if RpnOffsetDateTime
checkOp3OffsetDateTimePageTwo:
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeOffsetDateTime
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnDayOfWeek.
; Output: ZF=1 if RpnDayOfWeek
checkOp1DayOfWeekPageTwo:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeDayOfWeek
    ret

; Description: Check if OP3 is an RpnDayOfWeek.
; Output: ZF=1 if RpnDayOfWeek
checkOp3DayOfWeekPageTwo:
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeDayOfWeek
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnDuration.
; Output: ZF=1 if RpnDuration
checkOp1DurationPageTwo:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeDuration
    ret

; Description: Check if OP3 is an RpnDuration.
; Output: ZF=1 if RpnDuration
checkOp3DurationPageTwo:
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeDuration
    ret
