;-----------------------------------------------------------------------------
; RPN stack and other variables. Existing TI system variables are used to
; implement the RPN stack:
;
;   RPN     TI      OS Routines
;   ---     --      -----------
;   T       T       StoT, TName + RclVarSym
;   Z       Z       StoOther, RclVarSym
;   Y       Y       StoY, RclY, YName
;   X       X       StoX, RclX, XName
;   LastX   R       StoR, RName + RclVarSym
;   ??      Ans     StoAns, RclAns
;-----------------------------------------------------------------------------

; Function: Initialize the RPN stack variables. If X, Y, Z, T, R already exist,
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

; Description: Replace stX with OP1, saving previous stX to lastX, and
; setting dirty flag.
; Preserves: OP1
replaceX:
    bcall(_CkValidNum)
    bcall(_OP1ToOP2)
    bcall(_RclX)
    call stoLastX
    bcall(_OP2ToOP1)
    jr stoX

; Description: Replace (stX, stY) pair with OP1, saving previous stX to lastX,
; and setting dirty flag.
; Preserves: OP1
replaceXY:
    bcall(_CkValidNum)
    bcall(_OP1ToOP2)
    bcall(_RclX)
    call stoLastX
    bcall(_OP2ToOP1)
    call dropStack
    jr stoX

; Description: Replace stX=OP2 and stY=OP1, saving previous stX to lastX, and
; setting dirty flag.
; Preserves: OP1, OP2
replaceXYWithOP2OP1:
    ; validate OP1 and OP2 before modifying stX and stY
    bcall(_CkValidNum)
    bcall(_OP1ExOP2)
    bcall(_CkValidNum)
    bcall(_OP1ExOP2)

    call stoY ; stY = OP1
    bcall(_PushRealO1) ; FPS = OP1
    bcall(_RclX)
    call stoLastX ; lastX = stX

    bcall(_OP2ToOP1)
    call stoX ; stX = OP2 
    bcall(_PopRealO1) ; OP1 unchanged
    ret

;-----------------------------------------------------------------------------

; Function: Copy stX to OP1.
; Preserves: OP2
rclX:
    bcall(_RclX)
    ret

; Function: Store OP1 to stX, setting dirty flag.
; Destroys: all, OP4
; Preserves: OP1, OP2
stoX:
    bcall(_StoX)
    set rpnFlagsStackDirty, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------

; Function: Copy stT to OP1.
; Destroys: all, OP1
rclLastX:
    bcall(_RName)
    bcall(_RclVarSym)
    ret

; Function: Store OP1 to lastX.
; Destroys: all, OP4
; Preserves: OP1, OP2
stoLastX:
    bcall(_StoR)
    ret

;-----------------------------------------------------------------------------

; Function: Copy stY to OP1.
; Preserves: OP2
rclY:
    bcall(_RclY)
    ret

; Function: Store OP1 to stY, setting dirty flag.
; Destroys: all, OP4
; Preserves: OP1, OP2
stoY:
    bcall(_StoY)
    set rpnFlagsStackDirty, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------

; Function: Recall stZ to OP1.
; Output; OP1: set to stZ
; Destroys: all, OP1
; Preserves: OP2
rclZ:
    ld hl, zname
    bcall(_Mov9ToOP1)
    bcall(_RclVarSym)
    ret

; Function: Store OP1 to stZ variable, setting dirty flag.
; Output; CF = 1 if failed to store
; Destroys: all, OP4, OP6
; Preserves: OP1, OP2
stoZ:
    set rpnFlagsStackDirty, (iy + rpnFlags)
    bcall(_OP1ToOP6) ; OP6=OP1 save

    bcall(_PushRealO1) ; _StoOther() wants the data in FPS(!)
    ld hl, zName
    bcall(_Mov9ToOP1) ; OP1 = name of var, i.e. "Z"

    ; AppOnErr macro does not seem to work on spasm-ng. So do it manually.
    ld hl, stoZFail
    call APP_PUSH_ERRORH
    bcall(_StoOther) ; _StoOther() implicitly pops the FPS(!)
    call APP_POP_ERRORH

    bcall(_OP6ToOP1) ; restore OP1
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
; Destroys: all, OP1
; Preserves: OP2
rclT:
    bcall(_TName)
    bcall(_RclVarSym)
    ret

; Function: Store OP1 to stT, setting dirty flag.
; Destroys: all, OP4
; Preserves: OP1, OP2
stoT:
    bcall(_StoT)
    set rpnFlagsStackDirty, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------

; Function: Lift the RPN stack, if inputBuf was not empty when closed.
; Input: none
; Output: T=Z; Z=Y; Y=X; X=X; OP1 preserved
; Destroys: all, OP4
; Preserves: OP1, OP2
liftStackNonEmpty:
    bit inputBufFlagsClosedEmpty, (iy + inputBufFlags)
    ret nz ; return doing nothing if closed empty
    ; [[fallthrough]]

; Function: Lift the RPN stack, copying X to Y.
; Input: none
; Output: T=Z; Z=Y; Y=X; X=X; OP1 preserved
; Destroys: all, OP4
; Preserves: OP1, OP2
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
; Destroys: all, OP4
; Preserves: OP1, OP2
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
; Preserves: none
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
; Preserves: none
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
