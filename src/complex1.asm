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
RectToComplex:
    ld a, (OP1)
    or rpnObjectTypeComplex
    ld (OP1), a
    ld a, (OP2)
    or rpnObjectTypeComplex
    ld (OP2), a
    ret

; Description: Convert OP3/OP4 (re,im) into complex number in CP3.
; Input: OP3/OP4=(re,im)
Rect3ToComplex3:
    ld a, (OP3)
    or rpnObjectTypeComplex
    ld (OP3), a
    ld a, (OP4)
    or rpnObjectTypeComplex
    ld (OP4), a
    ret

; Description: Convert OP1/OP2 (r,rad) in polar radians to CP1. This implements
; its own rect to polar conversion instead of using the built-in RToP() and
; PToR() TI-OS functions:
;
; 1) The OS functions are buggy. For example, RToP() overflows internally when
; it calculators r^2 = a^2 + b^2. For example, it throws an exception when
; a=b=7.1e63 (1/sqrt(2)*10^64).
;
; 2) The output of the OS routines depend on the 'trigFlags' global parameter,
; but our routines must be deterministic, instead of changing its results
; depending on the DEG or RAD modes.
;
; Input: OP1/OP2=(r,radian)
PolarRadToComplex:
    bcall(_PushRealO1) ; FPS=[r]
    call op2ToOp1PageOne ; OP1=rad
    bcall(_SinCosRad) ; OP1=sin(rad); OP2=cos(rad)
    bcall(_PopRealO3) ; FPS=[]; OP3=r
    bcall(_CMltByReal) ; OP1=r*sin(rad); OP2=r*cos(rad)
    call op1ExOp2PageOne ; OP1=r*cos(rad); OP2=r*sin(rad)
    jr RectToComplex

; Description: Convert OP1/OP2 (r,deg) in polar degrees to CP1. This implements
; its own rect to polar conversion instead of using the built-in RToP() and
; PToR() TI-OS functions:
;
; 1) The OS functions are buggy. For example, RToP() overflows internally when
; it calculators r^2 = a^2 + b^2. For example, it throws an exception when
; a=b=7.1e63 (1/sqrt(2)*10^64).
;
; 2) The output of the OS routines depend on the 'trigFlags' global parameter,
; but our routines must be deterministic, instead of changing its results
; depending on the DEG or RAD modes.
;
; Input: OP1/OP2=(r,degree)
PolarDegToComplex:
    bcall(_PushRealO1) ; FPS=[r]
    call op2ToOp1PageOne ; OP1=deg
    bcall(_DToR) ; OP1=rad
    bcall(_SinCosRad) ; OP1=sin(rad); OP2=cos(rad)
    call op1ExOp2PageOne ; OP1=cos(rad); OP2=sin(rad)
    call RectToComplex
    bcall(_PopRealO3) ; FPS=[]; OP3=r
    bcall(_CMltByReal) ; OP1=r*sin(rad); OP2=r*cos(rad)
    ret

;-----------------------------------------------------------------------------

; Description: Convert the complex number in OP1 and OP2 into 2 real numbers.
; Destroys: A
ComplexToRect:
    ld a, (OP1)
    and ~rpnObjectTypeComplex
    ld (OP1), a
    ld a, (OP2)
    and ~rpnObjectTypeComplex
    ld (OP2), a
    ret

; Description: Convert the complex number in OP3 and OP4 into 2 real numbers.
; Destroys: A
Complex3ToRect3:
    ld a, (OP3)
    and ~rpnObjectTypeComplex
    ld (OP3), a
    ld a, (OP4)
    and ~rpnObjectTypeComplex
    ld (OP4), a
    ret

; Description: Convert complex number into polar-rad form.
; It looks like Cabs() does *not* throw an Err:Overflow exception when the
; exponent becomes >=100. An 'r' of >=1E100 can be returned and will be
; displayed on the screen in polar mode.
;
; Input: CP1: Z, complex number
; Output: OP1,OP2: (r, thetaRad)
; Destroys: all, OP1-OP5
ComplexToPolarRad:
    ; Cabs() does not seem to suffer the internal overflow and underflow
    ; problems of RToP(). This implementation also uses fewer of the expensive
    ; bcall() so I think this is the winner.
    bcall(_PushOP1) ; FPS=[Z]
    call op1ExOp2PageOne ; OP1=Im(Z)=y; OP2=Re(Z)=x
    ld d, 0 ; set undocumented parameter for ATan2Rad()
    bcall(_ATan2Rad) ; OP1=Angle(Z), destroys OP1-OP5
    call op1ToOp3PageOne ; OP3=Angle(Z)
    bcall(_PopOP1) ; FPS=[]; CP1=Z
    bcall(_PushRealO3) ; FPS=[Angle(Z)]
    bcall(_CAbs) ; OP1=Cabs(Z); destroys OP1-OP4
    bcall(_PopRealO2) ; FPS=[]; OP2=Angle(Z)
    ret

; Description: Convert complex number into polar-degree form.
; Input: CP1: Z, complex number
; Output: OP1,OP2: (r, thetaDeg)
; Destroys: all
ComplexToPolarDeg:
    call ComplexToPolarRad ; OP1=abs(Z); OP2=radian(Z)
    bcall(_PushRealO1) ; FPS=[abs(Z)]
    call op2ToOp1PageOne ; OP1=radian(Z)
    bcall(_RToD) ; OP1=degree(Z)
    call op1ToOp2PageOne ; OP2=degree(Z)
    bcall(_PopRealO1) ; FPS=[]; OP1=abs(Z)
    ret
