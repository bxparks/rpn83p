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
    ret

;-----------------------------------------------------------------------------
; Set rpnObjectType.
;-----------------------------------------------------------------------------

; Description: Set the rpnObjectType of OP1/OP2 to A.
; Input: A=rpnObjectType
; Output: HL=OP1+1
; Destroys: HL
; Preserves: A, BC, DE
setOp1RpnObjectTypePageOne:
    ld hl, OP1
    jr setHLRpnObjectTypePageOne

; Description: Return the rpnObjectType of OP3/OP4.
; Input: A=rpnObjectType
; Output: HL=OP3+1
; Destroys: HL
; Preserves: A, BC, DE
setOp3RpnObjectTypePageOne:
    ld hl, OP3
    ; [[fallthrough]]

; Description: Set the rpnObjectType of HL to A.
; Input: A=rpnObjectType
; Output: HL+=1
; Destroys: HL
; Preserves: A, BC, DE
setHLRpnObjectTypePageOne:
    ld (hl), a
    inc hl
    ret
