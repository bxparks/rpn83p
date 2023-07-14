;-----------------------------------------------------------------------------
; RPN stack and other variables. Existing TI system variables are used to
; implement the RPN stack:
;
;   RPN     TI      OS Routines
;   ---     --      -----------
;   T       T       StoT, TName + RclVarSym
;   Z       Z       none (use stoZ)
;   Y       Y       StoY, RclY, YName
;   X       X       StoX, RclX, XName
;   LastX   R       StoR, RName + RclVarSym
;   ??      Ans     StoAns, RclAns
;-----------------------------------------------------------------------------

; Function: Initialize the RPN stack variables.
; Destroys: all?
initStack:
    bcall(_OP1Set0)
    bcall(_StoT)
    call stoZ
    bcall(_StoY)
    bcall(_StoX)
    bcall(_StoR)

    res rpnFlagsEditing, (iy + rpnFlags)
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------

; Function: Lift the RPN stack, copying X to Y.
; Input: none
; Output: T=Z; Z=Y; Y=X; X=X
; Destroys: all, OP1, OP2, OP4
liftStack:
    ; T = Z
    call rclZ
    bcall(_StoT)
    ; Z = Y
    bcall(_RclY)
    call stoZ
    ; Y = X
    bcall(_RclX)
    bcall(_StoY)
    ; X = X

    set displayFlagsStackDirty, (iy + displayFlags)
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
    call rclZ
    bcall(_StoY)
    ; Z = T
    bcall(_TName)
    bcall(_RclVarSym)
    call stoZ
    ; T = T

    set displayFlagsStackDirty, (iy + displayFlags)
    ret

;-----------------------------------------------------------------------------

; Function: Store OP1 to Z variable.
; Output; CF = 1 if failed to store
; Destroys: all, OP5
stoZ:
    bcall(_OP1ToOP5) ; OP5=OP1 save
    bcall(_PushRealO1) ; push data to FPS
    ld hl, zName
    bcall(_Mov9ToOP1) ; OP1 = name of var, i.e. "Z"

    ; AppOnErr macro does not seem to work on spasm-ng. So do it manually.
    ld hl, stoZFail
    call APP_PUSH_ERRORH
    bcall(_StoOther)
    call APP_POP_ERRORH
    bcall(_OP5ToOP1)
    or a ; CF=0
    ret
stoZFail:
    bcall(_OP5ToOP1)
    scf ; CF=1
    ret

; Function: Recal Z variable to OP1.
; Output; Z = 1 if Z is real.
rclZ:
    ld hl, zname
    bcall(_Mov9ToOP1)
    bcall(_RclVarSym)
    ret

; Name of the "Z" variable.
zName:
    .db 0, tZ, 0, 0 ; the trailing 5 bytes can be anything
