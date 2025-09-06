;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; CPLX (complex) menu handlers.
;
; Every handler is given the following input parameters:
;   - HL:u16=menuId
;   - CF:bool
;       - 0 indicates 'onEnter' event into group
;       - 1 indicates 'onExit' event from group
;-----------------------------------------------------------------------------

mComplexRealHandler:
    call closeInputAndRecallUniversalX
    bcall(_ComplexReal)
    jp replaceX ; X=Re(X)

mComplexImagHandler:
    call closeInputAndRecallUniversalX
    bcall(_ComplexImag)
    jp replaceX ; X=Im(X)

mComplexConjHandler:
    call closeInputAndRecallUniversalX ; OP1/OP2=X
    bcall(_ComplexConj)
    jp replaceX

mComplexAbsHandler:
    call closeInputAndRecallUniversalX
    bcall(_ComplexAbs)
    jp replaceX ; X=cabs(X) or abs(X)

mComplexAngleHandler:
    call closeInputAndRecallUniversalX
    bcall(_ComplexAngle)
    jp replaceX ; X=Cangle(X)

;-----------------------------------------------------------------------------

mNumResultModeRealHandler:
    call closeInputAndRecallNone
    ld a, numResultModeReal
    ld (numResultMode), a
    call updateNumResultMode
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mNumResultModeRealNameSelector:
    ld a, (numResultMode)
    cp numResultModeReal
    jr z, mNumResultModeRealNameSelectorAlt
    or a ; CF=0
    ret
mNumResultModeRealNameSelectorAlt:
    scf
    ret

mNumResultModeComplexHandler:
    call closeInputAndRecallNone
    ld a, numResultModeComplex
    ld (numResultMode), a
    call updateNumResultMode
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mNumResultModeComplexNameSelector:
    ld a, (numResultMode)
    cp numResultModeComplex
    jr z, mNumResultModeComplexNameSelectorAlt
    or a ; CF=0
    ret
mNumResultModeComplexNameSelectorAlt:
    scf
    ret

;-----------------------------------------------------------------------------

mComplexModeRectHandler:
    call closeInputAndRecallNone
    ld a, complexModeRect
    ld (complexMode), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    set dirtyFlagsStack, (iy + dirtyFlags)
    set dirtyFlagsStatus, (iy + dirtyFlags)
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mComplexModeRectNameSelector:
    ld a, (complexMode)
    cp complexModeRect
    jr z, mComplexModeRectNameSelectorAlt
    or a ; CF=0
    ret
mComplexModeRectNameSelectorAlt:
    scf
    ret

mComplexModeRadHandler:
    call closeInputAndRecallNone
    ld a, complexModeRad
    ld (complexMode), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    set dirtyFlagsStack, (iy + dirtyFlags)
    set dirtyFlagsStatus, (iy + dirtyFlags)
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mComplexModeRadNameSelector:
    ld a, (complexMode)
    cp complexModeRad
    jr z, mComplexModeRadNameSelectorAlt
    or a ; CF=0
    ret
mComplexModeRadNameSelectorAlt:
    scf
    ret

mComplexModeDegHandler:
    call closeInputAndRecallNone
    ld a, complexModeDeg
    ld (complexMode), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    set dirtyFlagsStack, (iy + dirtyFlags)
    set dirtyFlagsStatus, (iy + dirtyFlags)
    ret

; Description: Select menu name.
; Output: CF=0 for normal, CF=1 or alternate
mComplexModeDegNameSelector:
    ld a, (complexMode)
    cp complexModeDeg
    jr z, mComplexModeDegNameSelectorAlt
    or a ; CF=0
    ret
mComplexModeDegNameSelectorAlt:
    scf
    ret
