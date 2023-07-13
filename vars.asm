;-----------------------------------------------------------------------------
; RPN stack and other variables. Existing TI system variables are used to
; implement the RPN stack:
;
;   RPN     TI      OS Routines
;   ---     --      -----------
;   T       T       StoT
;   Z       Z       StoTheta  (TODO: Replace with 'Z')
;   Y       Y       StoY, RclY
;   X       X       StoX, RclX
;   LastX   R       StoR
;   ??      Ans     StoAns, RclAns
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

;-----------------------------------------------------------------------------

; Function: Lift the RPN stack, copying X to Y.
; Input: none
; Output: T=Z; Z=Y; Y=X; X=X
; Destroys: all, OP1, OP2, OP4
liftStack:
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
    ; X = X

    ld hl, displayFlags
    set displayFlagsStackDirty, (hl)
    ret

;-----------------------------------------------------------------------------

; Function: Drop the RPN stack, copying T to Z.
; Input: none
; Output: X=Y; Y=Z; Z=T; T=T
; Destroys: all, OP1, OP2, OP4
dropStack:
    ; X = Y
    bcall(_RclY)
    bcall(_StoX)
    ; Y = Z
    bcall(_ThetaName)
    bcall(_RclVarSym)
    bcall(_StoY)
    ; Z = T
    bcall(_TName)
    bcall(_RclVarSym)
    bcall(_StoTheta)
    ; T = T

    ld hl, displayFlags
    set displayFlagsStackDirty, (hl)
    ret
