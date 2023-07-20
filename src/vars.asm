;-----------------------------------------------------------------------------
; RPN stack and other variables. Existing TI system variables are used to
; implement the RPN stack:
;
;   RPN     TI      OS Routines
;   ---     --      -----------
;   T       T       StoT, TName + RclVarSym
;   Z       Z       none
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
    set rpnFlagsStackDirty, (iy + rpnFlags) ; force initial display
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

initX:
    bcall(_XName)
    bcall(_FindSym)
    ret nc
    bcall(_OP1Set0)
    call stoX
    ret

initY:
    bcall(_YName)
    bcall(_FindSym)
    ret nc
    bcall(_OP1Set0)
    call stoY
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
    call stoT
    ret

initR:
    bcall(_RName)
    bcall(_FindSym)
    ret nc
    bcall(_OP1Set0)
    bcall(_StoR)
    ret

;-----------------------------------------------------------------------------
; Stack registers to OPx functions. Functions outside of this file should
; go through these functions, instead of calling _StoX, _RclX directly.
;-----------------------------------------------------------------------------

; Function: Copy stX to OP1.
rclX:
    bcall(_RclX)
    ret

; Function: Store OP1 to stX, setting dirty flag.
stoX:
    bcall(_StoX)
    set rpnFlagsStackDirty, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------

; Function: Copy stY to OP1.
rclY:
    bcall(_RclY)
    ret

; Function: Store OP1 to stY, setting dirty flag.
stoY:
    bcall(_StoY)
    set rpnFlagsStackDirty, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------

; Function: Recall stZ to OP1.
; Output; Z = 1 if Z is real.
; Destroys: all, OP1
rclZ:
    ld hl, zname
    bcall(_Mov9ToOP1)
    bcall(_RclVarSym)
    ret

; Function: Store OP1 to stZ variable.
; Output; CF = 1 if failed to store
; Destroys: all, OP1, OP6
stoZ:
    set rpnFlagsStackDirty, (iy + rpnFlags)
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

; Name of the "Z" variable.
zName:
    .db 0, tZ, 0, 0 ; the trailing 5 bytes can be anything

;-----------------------------------------------------------------------------

; Function: Copy stT to OP1.
; Destroys: all, OP4
rclT:
    bcall(_TName)
    bcall(_RclVarSym)
    ret

; Function: Store OP1 to stT, setting dirty flag.
; Destroys: all, OP4
stoT:
    bcall(_StoT)
    set rpnFlagsStackDirty, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------

; Function: Lift the RPN stack, if inputBuf was not empty when closed.
; Input: none
; Output: T=Z; Z=Y; Y=X; X=X; OP1 preserved
; Destroys: all, OP1, OP2, OP4
liftStackNonEmpty:
    bit inputBufFlagsClosedEmpty, (iy + inputBufFlags)
    ret nz ; return doing nothing if closed empty
    ; [[fallthrough]]

; Function: Lift the RPN stack, copying X to Y.
; Input: none
; Output: T=Z; Z=Y; Y=X; X=X; OP1 preserved
; Destroys: all, OP2, OP4
liftStack:
    bcall(_PushRealO1)
    ; T = Z
    call rclZ
    call stoT
    ; Z = Y
    call rclY
    call stoZ
    ; Y = X
    call rclX
    call stoY
    ; X = X
    bcall(_PopRealO1)
    ret

;-----------------------------------------------------------------------------

; Function: Drop the RPN stack, copying T to Z.
; Input: none
; Output: X=Y; Y=Z; Z=T; T=T; OP1 preserved
; Destroys: all, OP2, OP4
dropStack:
    bcall(_PushRealO1)
    ; X = Y
    call rclY
    call stoX
    ; Y = Z
    call rclZ
    call stoY
    ; Z = T
    call rclT
    call stoZ
    ; T = T
    bcall(_PopRealO1)
    ret

;-----------------------------------------------------------------------------

; Function: Rotate the RPN stack *down*.
; Input: none
; Output: X=Y; Y=Z; Z=T; T=X
; Destroys: all, OP1, OP2, OP4
rotDownStack:
    ; save X in FPS
    call rclX
    bcall(_PushRealO1)
    ; X = Y
    call rclY
    call stoX
    ; Y = Z
    call rclZ
    call stoY
    ; Z = T
    call rclT
    call stoZ
    ; T = X
    bcall(_PopRealO1)
    call stoT
    ret

;-----------------------------------------------------------------------------

; Function: Rotate the RPN stack *up*.
; Input: none
; Output: T=Z; Z=Y; Y=X; X=T
; Destroys: all, OP1, OP2, OP4
rotUpStack:
    ; save T in FPS
    call rclT
    bcall(_PushRealO1)
    ; T = Z
    call rclZ
    call stoT
    ; Z = Y
    call rclY
    call stoZ
    ; Y = X
    call rclX
    call stoY
    ; X = T
    bcall(_PopRealO1)
    call stoX
    ret

;-----------------------------------------------------------------------------

; Function: Exchange X<->Y.
; Input: none
; Output: X=Y; Y=X
; Destroys: all, OP1, OP2, OP4
exchangeXYStack:
    call rclX
    bcall(_OP1ToOP2)
    call rclY
    call stoX
    bcall(_OP2ToOP1)
    call stoY
    ret
