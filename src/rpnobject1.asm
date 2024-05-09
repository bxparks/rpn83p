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

; Description: Return the rpnObjectType of OP1/OP2.
; Input: OP1
; Output: A=rpnObjectType
; Destroys: A
getOp1RpnObjectTypePageOne:
    ld a, (OP1)
    and rpnObjectTypeMask
    ret
