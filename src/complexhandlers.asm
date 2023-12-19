;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Handlers for the CPLX (complex) menu items.
;-----------------------------------------------------------------------------

mComplexConjHandler:
    call closeInputAndRecallUniversalX ; OP1/OP2=X
    call complexConj
    jp replaceX

mComplexRealHandler:
    call closeInputAndRecallUniversalX
    call complexReal
    jp replaceX ; X=Re(X)

mComplexImagHandler:
    call closeInputAndRecallUniversalX
    call complexImag
    jp replaceX ; X=Im(X)

mComplexAbsHandler:
    call closeInputAndRecallUniversalX
    call complexAbs
    jp replaceX ; X=cabs(X) or abs(X)

mComplexAngleHandler:
    call closeInputAndRecallUniversalX
    call complexAngle
    jp replaceX ; X=Cangle(X)

;-----------------------------------------------------------------------------

mNumResultModeRealHandler:
    call closeInputAndRecallNone
    ld a, numResultModeReal
    ld (numResultMode), a
    call updateNumResultMode
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Input: A=B=menuLabel; C=altLabel
; Output: A=selectedLabel
mNumResultModeRealNameSelector:
    ld a, (numResultMode)
    cp numResultModeReal
    ld a, b
    ret nz
    ld a, c
    ret

mNumResultModeComplexHandler:
    call closeInputAndRecallNone
    ld a, numResultModeComplex
    ld (numResultMode), a
    call updateNumResultMode
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Input: A=B=menuLabel; C=altLabel
; Output: A=selectedLabel
mNumResultModeComplexNameSelector:
    ld a, (numResultMode)
    cp numResultModeComplex
    ld a, b
    ret nz
    ld a, c
    ret
