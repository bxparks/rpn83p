;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; RPN object types. Basically the same as rpnobject.asm but in Flash Page 1.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Real numbers.
;-----------------------------------------------------------------------------

; Description: Check that OP1 is a Real number.
; Input: OP1
; Output: ZF=1 if real
; Destroys: A
checkOp1RealPageOne:
    call getOp1RpnObjectType
    cp rpnObjectTypeReal
    ret

; Description: Check that OP3 is a Real number.
; Input: OP3
; Output: ZF=1 if real
; Destroys: A
checkOp3RealPageOne:
    call getOp3RpnObjectType
    cp rpnObjectTypeReal
    ret

;-----------------------------------------------------------------------------
; Complex numbers.
;-----------------------------------------------------------------------------

; Description: Same as CkOP1Cplx() OS routine without the bcall() overhead.
; Input: OP1
; Output: ZF=1 if complex
; Destroys: A
checkOp1ComplexPageOne:
    call getOp1RpnObjectType
    cp rpnObjectTypeComplex
    ret

;-----------------------------------------------------------------------------
; Get rpnObjectType.
;-----------------------------------------------------------------------------

; Description: Return the rpnObjectType of OP1/OP2.
; Input: OP1
; Output: A=rpnObjectType; HL=OP1
; Destroys: A, HL
getOp1RpnObjectTypePageOne:
    ld hl, OP1
    jr getHLRpnObjectTypePageOne

; Description: Return the rpnObjectType of OP1/OP2.
; Input: OP1
; Output: A=rpnObjectType; HL=OP3
; Destroys: A, HL
getOp3RpnObjectTypePageOne:
    ld hl, OP3
    ; [[fallthrough]]

; Description: Return the rpnObjectType of HL.
; Input: HL:(RpnObject*)
; Output: A=rpnObjectType
; Destroys: A
; Preserves: HL
getHLRpnObjectTypePageOne:
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
setOp1RpnObjectTypePageOne:
    ld hl, OP1
    jr setHLRpnObjectTypePageOne

; Description: Return the rpnObjectType of OP3/OP4.
; Input: A=rpnObjectType
; Output: HL=OP3+rpnObjectTypeSizeOf
; Destroys: HL
; Preserves: A, BC, DE
setOp3RpnObjectTypePageOne:
    ld hl, OP3
    ; [[fallthrough]]

; Description: Set the rpnObjectType of HL to A.
; Input: A=rpnObjectType
; Output: HL+=rpnObjectTypeSizeOf
; Destroys: HL
; Preserves: A, BC, DE
setHLRpnObjectTypePageOne:
    push af
    ld a, rpnObjectTypePrefix
    ld (hl), a
    inc hl
    pop af
    ld (hl), a
    inc hl
    ret
