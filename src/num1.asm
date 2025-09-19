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

; Description: Calculate the X percent of Y.
;   - PercentFunction(Y, X) -> Y*(X/100)
; Input:
;   - OP1:Real=Y
;   - OP2:Real=X
; Output:
;   - OP1:Real=Y*(X/100)
PercentFunction:
    bcall(_FPMult) ; OP1=OP1*OP2=X*Y
    call op2Set100PageOne
    bcall(_FPDiv) ; OP1=X*Y/100
    ret

;-----------------------------------------------------------------------------

; Description: Calculate the change from Y to X as a percentage of Y.
;   - PercentChangeFunction(Y, X) -> 100*(X-Y)/Y
; Input:
;   - OP1:Real=Y
;   - OP2:Real=X
; Output:
;   - OP1:Real=100*(X-Y)/Y
PercentChangeFunction:
    bcall(_PushRealO1) ; FPS=[Y]
    bcall(_InvSub) ; OP1=X-Y
    bcall(_PopRealO2) ; FPS=[]; OP2=Y
    bcall(_FPDiv) ; OP1=(X-Y)/Y
    call op2Set100PageOne
    bcall(_FPMult) ; OP1=100*(X-Y)/Y
    ret

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

;-----------------------------------------------------------------------------

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

;-----------------------------------------------------------------------------

; Description: Implement the Euclidean algorithm for the Greatest Common
; Divisor (GCD) as described in
; https://en.wikipedia.org/wiki/Euclidean_algorithm:
;
; function gcd(a, b)
;    while b != 0
;        t := b
;        b := a mod b
;        a := t
;    return a
;
; TODO: To reduce code size and programming time, this uses the TI-OS floating
; point operations to calculate (a mod b). It would probably be a LOT faster to
; use native Z-80 assembly to implement the (a mod b). At the time that I wrote
; this, the integer32.asm or the integer40.asm routines had not been written
; yet. I could probably use those integer routines to make this a LOT faster.
; However, the GCD algorithm is very efficient and does not take too many
; iterations. So I'm not sure it's worth changing this over to the integer
; routines.
;
; Input: OP1, OP2
; Output: OP1 = GCD(OP1, OP2)
; Destroys: OP1, OP2, OP3
GcdFunction:
    bcall(_CkOP2FP0) ; while b != 0
    ret z
    bcall(_PushRealO2) ; FPS=[b]; (t = b)
    call ModFunction ; (a mod b)
    bcall(_OP1ToOP2) ; b = (a mod b)
    bcall(_PopRealO1) ; FPS=[]; (a = t)
    jr GcdFunction

;-----------------------------------------------------------------------------

; Description: Calculate the Lowest Common Multiple using the following:
; LCM(Y, X) = Y * X / GCD(Y, X)
;           = Y * (X / GCD(Y,X))
LcdFunction:
    bcall(_PushRealO1) ; FPS=[Y]
    bcall(_PushRealO2) ; FPS=[Y,X]
    call GcdFunction ; OP1 = gcd()
    bcall(_OP1ToOP2) ; OP2 = gcd()
    bcall(_PopRealO1) ; FPS=[Y]; OP1 = X
    bcall(_FPDiv) ; OP1 = X / gcd
    bcall(_PopRealO2) ; FPS=[]; OP2 = Y
    bcall(_FPMult) ; OP1 = Y * (X / gcd)
    ret
