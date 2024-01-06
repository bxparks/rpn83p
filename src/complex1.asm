;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Functions related to complex.asm in Flash Page 1.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;------------------------------------------------------------------------------

; Description: Convert OP1/OP2 (re,im) into complex number in CP1.
; Input: OP1/OP2=(re,im)
rectToComplex:
    ld a, (OP1)
    or rpnObjectTypeComplex
    ld (OP1), a
    ld a, (OP2)
    or rpnObjectTypeComplex
    ld (OP2), a
    ret

; Description: Convert OP1/OP2 (r,rad) in polar radians to CP1.
; Input: OP1/OP2=(r,radian)
pradToComplex:
    bcall(_PushRealO1) ; FPS=[r]
    call op2ToOp1PageOne ; OP1=rad
    bcall(_SinCosRad) ; OP1=sin(rad); OP2=cos(rad)
    bcall(_PopRealO3) ; FPS=[]; OP3=r
    bcall(_CMltByReal) ; OP1=r*sin(rad); OP2=r*cos(rad)
    call op1ExOp2PageOne ; OP1=r*cos(rad); OP2=r*sin(rad)
    jr rectToComplex

; Description: Convert OP1/OP2 (r,deg) in polar degrees to CP1.
; Input: OP1/OP2=(r,degree)
pdegToComplex:
    bcall(_PushRealO1) ; FPS=[r]
    call op2ToOp1PageOne ; OP1=deg
    bcall(_DToR) ; OP1=rad
    bcall(_SinCosRad) ; OP1=sin(rad); OP2=cos(rad)
    call op1ExOp2PageOne ; OP1=cos(rad); OP2=sin(rad)
    call rectToComplex
    bcall(_PopRealO3) ; FPS=[]; OP3=r
    bcall(_CMltByReal) ; OP1=r*sin(rad); OP2=r*cos(rad)
    ret
