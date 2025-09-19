;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2025 Brian T. Park
;
; NUM routines for Real type.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Return the sign(x) function: -1 if x<0, 0 if x==0, 1 if x>0.
; Input: OP1:Real=x
; Output: OP1:Real=sign(x)
SignFunction:
    bcall(_CkOP1FP0) ; check OP1 is float 0
    jr z, signFunctionSetZero
    bcall(_CkOP1Pos) ; check OP1 > 0
    jr z, signFunctionSetOne
    ;
    bcall(_OP1Set1)
    bcall(_InvOP1S)
    ret
signFunctionSetOne:
    bcall(_OP1Set1)
    ret
signFunctionSetZero:
    bcall(_OP1Set0)
    ret
