;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; RPN object types. Basically the same as rpnobject2.asm.
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
getOp1RpnObjectTypePageFour:
    ld hl, OP1
    jr getHLRpnObjectTypePageFour

; Description: Return the rpnObjectType of OP3/OP4.
; Input: OP3
; Output: A=rpnObjectType; HL=OP3
; Destroys: A, HL
getOp3RpnObjectTypePageFour:
    ld hl, OP3
    ; [[fallthrough]]

; Description: Return the rpnObjectType of HL.
; Input: HL:(RpnObject*)
; Output: A=rpnObjectType
; Destroys: A
; Preserves: HL
getHLRpnObjectTypePageFour:
    ld a, (hl)
    and rpnObjectTypeMask
    cp rpnObjectTypePrefix
    ret nz
    inc hl
    ld a, (hl)
    dec hl
    ret

;-----------------------------------------------------------------------------
; Set rpnObjectType.
;-----------------------------------------------------------------------------

; Description: Set the rpnObjectType of OP1/OP2 to A.
; Input: A=rpnObjectType
; Output: HL=OP1+rpnObjectTypeSizeOf
; Destroys: HL
; Preserves: A, BC, DE
setOp1RpnObjectTypePageFour:
    ld hl, OP1
    jr setHLRpnObjectTypePageFour

; Description: Return the rpnObjectType of OP3/OP4.
; Input: A=rpnObjectType
; Output: HL=OP3+rpnObjectTypeSizeOf
; Destroys: HL
; Preserves: A, BC, DE
setOp3RpnObjectTypePageFour:
    ld hl, OP3
    ; [[fallthrough]]

; Description: Set the rpnObjectType of HL to A.
; Input: A=rpnObjectType
; Output: HL+=rpnObjectTypeSizeOf
; Destroys: HL
; Preserves: A, BC, DE
setHLRpnObjectTypePageFour:
    push af
    ld a, rpnObjectTypePrefix
    ld (hl), a
    inc hl
    pop af
    ld (hl), a
    inc hl
    ret

;-----------------------------------------------------------------------------
; Real numbers.
;-----------------------------------------------------------------------------

; Description: Check that OP3 is a Real number.
; Input: OP3
; Output: ZF=1 if real
; Destroys: A
checkOp3RealPageFour:
    call getOp3RpnObjectTypePageFour
    cp rpnObjectTypeReal
    ret

;-----------------------------------------------------------------------------
; Complex numbers.
;-----------------------------------------------------------------------------

; Description: Same as CkOP1Cplx() OS routine without the bcall() overhead.
; Input: OP1
; Output: ZF=1 if complex
; Destroys: A
checkOp1ComplexPageFour:
    call getOp1RpnObjectTypePageFour
    cp rpnObjectTypeComplex
    ret

;-----------------------------------------------------------------------------
; Date related objects.
;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnTime.
; Output: ZF=1 if RpnTime
checkOp1TimePageFour:
    call getOp1RpnObjectTypePageFour
    cp rpnObjectTypeTime
    ret

; Description: Check if OP3 is an RpnTime.
; Output: ZF=1 if RpnTime
checkOp3TimePageFour:
    call getOp3RpnObjectTypePageFour
    cp rpnObjectTypeTime
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is a RpnDate.
; Output: ZF=1 if RpnDate
checkOp1DatePageFour:
    call getOp1RpnObjectTypePageFour
    cp rpnObjectTypeDate
    ret

; Description: Check if OP3 is a RpnDate.
; Output: ZF=1 if RpnDate
checkOp3DatePageFour:
    call getOp3RpnObjectTypePageFour
    cp rpnObjectTypeDate
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is a RpnDateTime.
; Output: ZF=1 if RpnDateTime
checkOp1DateTimePageFour:
    call getOp1RpnObjectTypePageFour
    cp rpnObjectTypeDateTime
    ret

; Description: Check if OP3 is a RpnDateTime.
; Output: ZF=1 if RpnDateTime
checkOp3DateTimePageFour:
    call getOp3RpnObjectTypePageFour
    cp rpnObjectTypeDateTime
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is a RpnOffset.
; Output: ZF=1 if RpnOffset
checkOp1OffsetPageFour:
    call getOp1RpnObjectTypePageFour
    cp rpnObjectTypeOffset
    ret

; Description: Check if OP3 is a RpnOffset.
; Output: ZF=1 if RpnOffset
checkOp3OffsetPageFour:
    call getOp3RpnObjectTypePageFour
    cp rpnObjectTypeOffset
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is a RpnOffsetDateTime.
; Output: ZF=1 if RpnOffsetDateTime
checkOp1OffsetDateTimePageFour:
    call getOp1RpnObjectTypePageFour
    cp rpnObjectTypeOffsetDateTime
    ret

; Description: Check if OP3 is a RpnOffsetDateTime.
; Output: ZF=1 if RpnOffsetDateTime
checkOp3OffsetDateTimePageFour:
    call getOp3RpnObjectTypePageFour
    cp rpnObjectTypeOffsetDateTime
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnDayOfWeek.
; Output: ZF=1 if RpnDayOfWeek
checkOp1DayOfWeekPageFour:
    call getOp1RpnObjectTypePageFour
    cp rpnObjectTypeDayOfWeek
    ret

; Description: Check if OP3 is an RpnDayOfWeek.
; Output: ZF=1 if RpnDayOfWeek
checkOp3DayOfWeekPageFour:
    call getOp3RpnObjectTypePageFour
    cp rpnObjectTypeDayOfWeek
    ret

;-----------------------------------------------------------------------------

; Description: Check if OP1 is an RpnDuration.
; Output: ZF=1 if RpnDuration
checkOp1DurationPageFour:
    call getOp1RpnObjectTypePageFour
    cp rpnObjectTypeDuration
    ret

; Description: Check if OP3 is an RpnDuration.
; Output: ZF=1 if RpnDuration
checkOp3DurationPageFour:
    call getOp3RpnObjectTypePageFour
    cp rpnObjectTypeDuration
    ret

;-----------------------------------------------------------------------------
; Denominate numbers
;-----------------------------------------------------------------------------

checkOp1DenominatePageFour:
    call getOp1RpnObjectTypePageFour
    cp rpnObjectTypeDenominate
    ret

checkOp3DenominatePageFour:
    call getOp3RpnObjectTypePageFour
    cp rpnObjectTypeDenominate
    ret

; Description: Set the memory in HL to be an RpnDenominate whose unit is given
; by register A.
; Input:
;   - A:u8=displayUnit
;   - (HL):RpnObject
; Output:
;   - (HL).objectType=rpnObjectTypeDenominate
;   - (HL).displayUnit:u8=A
;   - HL=HL+rpnObjectTypeSizeOf=denominate
; Preserves: A, BC, DE
setHLRpnDenominatePageFour:
    push af
    ld a, rpnObjectTypeDenominate
    call setHLRpnObjectTypePageFour
    pop af ; A=displayUnit
    ld (hl), a ; denominate.displayUnit=A
    inc hl
    ld (hl), 0 ; denominate.reserved=0
    dec hl ; HL=denominate
    ret
