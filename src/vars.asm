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

; Function: Initialize the RPN stack variables. If X, Y, Z, T already exist,
; the existing values will be used. Otherwise, set to zero.
; TODO: Check if the variables are complex. If so, reinitialize them to be real.
; Destroys: all?
initStack:
    call initT
    call initY
    call initX
    call initZ
    call initR
    res rpnFlagsEditing, (iy + rpnFlags)
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

initX:
    bcall(_XName)
    bcall(_FindSym)
    ret nc
    bcall(_OP1Set0)
    bcall(_StoX)
    ret

initY:
    bcall(_YName)
    bcall(_FindSym)
    ret nc
    bcall(_OP1Set0)
    bcall(_StoY)
    ret

initZ:
    ld hl, zname
    bcall(_Mov9ToOP1)
    bcall(_FindSym)
    ret nc
    bcall(_OP1Set0)
    call stoZ
    ret

initT:
    bcall(_TName)
    bcall(_FindSym)
    ret nc
    bcall(_OP1Set0)
    bcall(_StoT)
    ret

initR:
    bcall(_RName)
    bcall(_FindSym)
    ret nc
    bcall(_OP1Set0)
    bcall(_StoR)
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

; Function: Rotate the RPN stack *down*.
; Input: none
; Output: X=Y; Y=Z; Z=T; T=X
; Destroys: all, OP1, OP2, OP4
rotDownStack:
    ; save X in FPS
    bcall(_RclX)
    bcall(_PushRealO1)
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
    ; T = X
    bcall(_PopRealO1)
    bcall(_StoT)

    set displayFlagsStackDirty, (iy + displayFlags)
    ret

;-----------------------------------------------------------------------------

; Function: Rotate the RPN stack *up*.
; Input: none
; Output: T=Z; Z=Y; Y=X; X=T
; Destroys: all, OP1, OP2, OP4
rotUpStack:
    ; save T in FPS
    bcall(_TName)
    bcall(_RclVarSym)
    bcall(_PushRealO1)
    ; T = Z
    call rclZ
    bcall(_StoT)
    ; Z = Y
    bcall(_RclY)
    call stoZ
    ; Y = X
    bcall(_RclX)
    bcall(_StoY)
    ; X = T
    bcall(_PopRealO1)
    bcall(_StoX)

    set displayFlagsStackDirty, (iy + displayFlags)
    ret

;-----------------------------------------------------------------------------

; Function: Exchange X<->Y.
; Input: none
; Output: T=Z; Z=Y; Y=X; X=T
; Destroys: all, OP1, OP2, OP4
exchangeXYStack:
    bcall(_RclX)
    bcall(_PushRealO1)
    bcall(_RclY)
    bcall(_StoX)
    bcall(_PopRealO1)
    bcall(_StoY)
    set displayFlagsStackDirty, (iy + displayFlags)
    ret

;-----------------------------------------------------------------------------

; Function: Store OP1 to Z variable.
; Output; CF = 1 if failed to store
; Destroys: all, OP6
stoZ:
    bcall(_OP1ToOP6) ; OP6=OP1 save
    bcall(_PushRealO1) ; push data to FPS
    ld hl, zName
    bcall(_Mov9ToOP1) ; OP1 = name of var, i.e. "Z"

    ; AppOnErr macro does not seem to work on spasm-ng. So do it manually.
    ld hl, stoZFail
    call APP_PUSH_ERRORH
    bcall(_StoOther)
    call APP_POP_ERRORH
    bcall(_OP6ToOP1)
    or a ; CF=0
    ret
stoZFail:
    bcall(_OP6ToOP1)
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
