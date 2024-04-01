;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Format complex numbers into a string.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;------------------------------------------------------------------------------

; Description: Format the complex number in OP1/OP2 in rectangular format into
; the C string pointed by DE.
; Input:
;   - OP1/OP2: complex number
;   - DE: pointer to C string
; Output:
;   - DE: pointer updated to the trailing NUL character
; Destroys: all, OP3-OP4
FormatComplexRect:
    call ComplexToRect ; convert CP1 to OP1/OP2
    ; format Re(Z)
    call formatComplexRectFormatOP1 ; assembly allows calling our own tail
    ; add the spacer
    ld hl, msgFormatComplexRectSpacer
    call copyCStringPageOne
    ; format Im(Z)
    push de
    call op2ToOp1PageOne
    pop de
formatComplexRectFormatOP1:
    ld a, 10
    push de
    bcall(_FormReal)
    pop de
    ld hl, OP3
    jp copyCStringPageOne

msgFormatComplexRectSpacer:
    .db "  ", SimagI, " ", 0

;-----------------------------------------------------------------------------

; Description: Format the complex number in OP1/OP2 in polar RAD format into
; the C string pointed by DE.
; Input:
;   - OP1/OP2: complex number
;   - DE: pointer to C string
; Output:
;   - DE: pointer updated to the trailing NUL character
; Destroys: all, OP3-OP4
FormatComplexPolarRad:
    push de
    call ComplexToPolarRad ; OP1=r; OP2=theta(rad)
    pop de
    ; format Abs(Z)
    call formatComplexPolarRadFormatOP1 ; assembly allows calling our own tail
    ; add the spacer
    ld hl, msgFormatComplexPolarRadSpacer
    call copyCStringPageOne
    ; format Ang(Z)
    push de
    call op2ToOp1PageOne
    pop de
formatComplexPolarRadFormatOP1:
    ld a, 10
    push de
    bcall(_FormReal)
    pop de
    ld hl, OP3
    jp copyCStringPageOne

msgFormatComplexPolarRadSpacer:
    .db "  ", Sangle, " ", 0

;-----------------------------------------------------------------------------

; Description: Format the complex number in OP1/OP2 in polar DEG format into
; the C string pointed by DE.
; Input:
;   - OP1/OP2: complex number
;   - DE: pointer to C string
; Output:
;   - DE: pointer updated to the trailing NUL character
; Destroys: all, OP3-OP4
FormatComplexPolarDeg:
    push de
    call ComplexToPolarDeg ; OP1=r; OP2=theta(deg)
    pop de
    ; format Abs(Z)
    call formatComplexPolarDegFormatOP1 ; assembly allows calling our own tail
    ; add the spacer
    ld hl, msgFormatComplexPolarDegSpacer
    call copyCStringPageOne
    ; format Ang(Z)
    push de
    call op2ToOp1PageOne
    pop de
formatComplexPolarDegFormatOP1:
    ld a, 10
    push de
    bcall(_FormReal)
    pop de
    ld hl, OP3
    jp copyCStringPageOne

msgFormatComplexPolarDegSpacer:
    .db "  ", Sangle, Stemp, " ", 0
