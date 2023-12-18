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
