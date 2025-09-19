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

; Description: Calculate OP1 = (OP1 mod OP2) = OP1 - OP2 * floor(OP1/OP2). Used
; by mModHandler and mGcdHandler. There does not seem to be a built-in function
; to calculate this.
; Destroys: OP1, OP2, OP3
ModFunction:
    bcall(_PushRealO1) ; FPS=[OP1]
    bcall(_PushRealO2) ; FPS=[OP1,OP2]
    bcall(_FPDiv) ; OP1 = OP1/OP2
    bcall(_Intgr) ; OP1 = floor(OP1/OP2)
    bcall(_PopRealO2) ; FPS=[OP1]; OP2 = OP2
    bcall(_FPMult) ; OP1 = floor(OP1/OP2) * OP2
    bcall(_OP1ToOP2) ; OP2 = floor(OP1/OP2) * OP2
    bcall(_PopRealO1) ; FPS=[]; OP1 = OP1
    bcall(_FPSub) ; OP1 = OP1 - floor(OP1/OP2) * OP2
    bcall(_RndGuard) ; force integer results if OP1 and OP2 were integers
    ret
