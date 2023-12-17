;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Universal Arithmetic operations, supporting both real and complex arguments.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; RPN object types.
;-----------------------------------------------------------------------------

; Description: Return the rpnObjectType of OP1/OP2.
; Input: OP1
; Output: A=C=rpnObjectType
; Destroys: A
getOp1RpnObjectType:
    ld a, (OP1)
    and $1f
    ld c, a
    ret

; Description: Same as CkOP1Cplx() OS routine without the bcall() overhead.
; Input: OP1
; Output: ZF=1 if complex
; Destroys: A
checkOp1Complex:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeComplex
    ret

; Description: Same as checkOp1Complex() for OP3.
; Input: OP1
; Output: ZF=1 if complex
; Destroys: A
checkOp3Complex:
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeComplex
    ret

; Description: Check if either OP1 or OP3 are complex.
; Input: OP1, OP3
; Output: ZF=1 if either parameters is complex
; Destroys: A
checkOp1OrOP3Complex:
    ld a, (OP1)
    ld b, a
    ld a, (OP3)
    or b
    and $1F
    cp rpnObjectTypeComplex
    ret

;-----------------------------------------------------------------------------

; Description: Convert a real number in OP1 to a complex number in OP1/OP2 by
; setting the OP2 to 0, and setting the objectType to complex. If already a
; complex number, do nothing.
; Input: OP1
; Output: OP1/OP2
; Destroys: A
convertOp1ToCp1:
    call checkOp1Complex
    ret z
    call op2Set0
    ; [[fallthrough]]

; Description: Convert real numbers in OP1 and OP2 into a complex number.
; Destroys: A
convertOp1Op2ToCp1:
    ld a, (OP1)
    or rpnObjectTypeComplex
    ld (OP1), a
    ld a, (OP2)
    or rpnObjectTypeComplex
    ld (OP2), a
    ret

; Description: Convert the complex number in OP1 and OP2 into 2 real numbers.
; Destroys: A
convertCp1ToOp1Op2:
    ld a, (OP1)
    and ~rpnObjectTypeComplex
    ld (OP1), a
    ld a, (OP2)
    and ~rpnObjectTypeComplex
    ld (OP2), a
    ret

;-----------------------------------------------------------------------------

; Description: Convert a real number in OP3 to a complex number in OP3/OP4 by
; setting the OP4 to 0, and setting the objectType to complex. If already a
; complex number, do nothing.
; Input: OP3
; Output: OP3/OP4
; Destroys: A
convertOp3ToCp3:
    call checkOp3Complex
    ret z
    call op4Set0
    ; [[fallthrough]]

; Description: Convert real numbers in OP3 and OP4 into a complex number in OP3.
; Destroys: A
convertOp3Op4ToCp3:
    ld a, (OP3)
    or rpnObjectTypeComplex
    ld (OP3), a
    ld a, (OP4)
    or rpnObjectTypeComplex
    ld (OP4), a
    ret

; Description: Convert the complex number in OP3 and OP4 into 2 real numbers.
; Destroys: A
convertCp3ToOp3Op4:
    ld a, (OP3)
    and ~rpnObjectTypeComplex
    ld (OP3), a
    ld a, (OP4)
    and ~rpnObjectTypeComplex
    ld (OP4), a
    ret

;-----------------------------------------------------------------------------
; Arithmetic operations.
;-----------------------------------------------------------------------------

; Input:
;   - OP1/OP2: Y
;   - OP3/OP4: X
; Output:
;   - OP1/OP2: Y+X
universalAdd:
    call checkOp1OrOP3Complex
    jr z, universalAddComplex
    ; Add 2 real numbers.
    call op3ToOp2
    bcall(_FPAdd) ; OP1=Y+X
    ret
universalAddComplex:
    call convertOp1ToCp1
    bcall(_PushOP1) ; FPS=[Y]
    call cp3ToCp1 ; OP1/OP2=OP3/OP4
    call convertOp1ToCp1
    bcall(_CAdd) ; OP1/OP2 += FPS[OP1/OP2]; FPS=[]
    ret

; Input:
;   - OP1/OP2: Y
;   - OP3/OP4: X
; Output:
;   - OP1/OP2: Y-X
universalSub:
    call checkOp1OrOP3Complex
    jr z, universalSubComplex
    ; Sub 2 real numbers.
    call op3ToOp2
    bcall(_FPSub) ; OP1=Y-X
    ret
universalSubComplex:
    call convertOp1ToCp1
    bcall(_PushOP1) ; FPS=[Y]
    call cp3ToCp1 ; OP1/OP2=OP3/OP4
    call convertOp1ToCp1
    bcall(_CSub) ; OP1/OP2 = FPS[OP1/OP2] - OP1/OP2; FPS=[]
    ret

; Input:
;   - OP1/OP2: Y
;   - OP3/OP4: X
; Output:
;   - OP1/OP2: Y*X
universalMult:
    call checkOp1OrOP3Complex
    jr z, universalMultComplex
    ; Sub 2 real numbers.
    call op3ToOp2
    bcall(_FPMult) ; OP1=Y*X
    ret
universalMultComplex:
    call convertOp1ToCp1
    bcall(_PushOP1) ; FPS=[Y]
    call cp3ToCp1 ; OP1/OP2=OP3/OP4
    call convertOp1ToCp1
    ; TODO: If one of the arguments is real, then we could use CMltByReal() for
    ; a little bit of efficiency, probably.
    bcall(_CMult) ; OP1/OP2 = FPS[OP1/OP2] * OP1/OP2; FPS=[]
    ret

; Input:
;   - OP1/OP2: Y
;   - OP3/OP4: X
; Output:
;   - OP1/OP2: Y/X
universalDiv:
    call checkOp1OrOP3Complex
    jr z, universalDivComplex
    ; Sub 2 real numbers.
    call op3ToOp2
    bcall(_FPDiv) ; OP1=Y/X
    ret
universalDivComplex:
    call convertOp1ToCp1
    bcall(_PushOP1) ; FPS=[Y]
    call cp3ToCp1 ; OP1/OP2=OP3/OP4
    call convertOp1ToCp1
    ; TODO: If the divisor is real, then we could use CDivByReal() for a little
    ; bit of efficiency, probably.
    bcall(_CDiv) ; OP1/OP2 = FPS[OP1/OP2] / OP1/OP2; FPS=[]
    ret
