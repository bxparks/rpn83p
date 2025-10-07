;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; CPLX (complex) menu handlers.
;
; Every handler is given the following input parameters:
;   - DE:(void*):address of handler
;   - HL:u16=newMenuId
; If the handler is a MenuGroup, then it also gets the following:
;   - BC:u16=oldMenuId
;   - CF:bool
;       - 0 indicates 'onEnter' event into group
;       - 1 indicates 'onExit' event from group
;-----------------------------------------------------------------------------

mComplexRealHandler:
    call closeInputAndRecallUniversalX
    bcall(_ComplexReal)
    bcall(_ReplaceStackX) ; X=Re(X)
    ret

mComplexImagHandler:
    call closeInputAndRecallUniversalX
    bcall(_ComplexImag)
    bcall(_ReplaceStackX) ; X=Im(X)
    ret

mComplexConjHandler:
    call closeInputAndRecallUniversalX ; OP1/OP2=X
    bcall(_ComplexConj)
    bcall(_ReplaceStackX)
    ret

mComplexAbsHandler:
    call closeInputAndRecallUniversalX
    bcall(_ComplexAbs)
    bcall(_ReplaceStackX) ; X=cabs(X) or abs(X)
    ret

mComplexAngleHandler:
    call closeInputAndRecallUniversalX
    bcall(_ComplexAngle)
    bcall(_ReplaceStackX) ; X=Cangle(X)
    ret

;-----------------------------------------------------------------------------

mNumResultModeRealHandler:
    ld a, numResultModeReal
    ld (numResultMode), a
    bcall(_UpdateNumResultMode)
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
    ld a, numResultModeComplex
    ld (numResultMode), a
    bcall(_UpdateNumResultMode)
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
