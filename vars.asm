;-----------------------------------------------------------------------------
; RPN stack and other variables
;-----------------------------------------------------------------------------

; Function: Initialize the RPN stack variables.
; Destroys: all?
initStack:
    bcall(_OP1Set0)
    bcall(_StoT)
    bcall(_StoTheta)
    bcall(_StoY)
    bcall(_StoX)
    bcall(_StoR)

    ld hl, rpnFlags
    res rpnFlagsEditing, (hl)
    res rpnFlagsLiftDisabled, (hl)
    ret

; Function: Move the OP1 register to X, and lift the RPN stack.
; Input: OP1
; Output: T=Z; Z=Y; Y=X; X=OP1
; Destroys: HL, all
liftStack:
    ; save OP1 in lastX
    bcall(_StoR)

    ; T = Z
    bcall(_ThetaName)
    bcall(_RclVarSym)
    bcall(_StoT)

    ; Z = Y
    bcall(_RclY)
    bcall(_StoTheta)

    ; Y = X
    bcall(_RclX)
    bcall(_StoY)

    ; X = lastX
    bcall(_RName)
    bcall(_RclVarSym)
    bcall(_StoX)

    ld hl, displayFlags
    set displayFlagsStackDirty, (hl)
    ret
