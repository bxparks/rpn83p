;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;-----------------------------------------------------------------------------

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

;-----------------------------------------------------------------------------
; User registers. Accessed through `STO nn` and `RCL nn`. Let's store them as a
; list variable named `REGS`, similar to HP-42S. The TI-OS routines related to
; list variables are:
;
;   - GetLToOP1(): Get list element to OP1
;       - Input:
;           - HL = element index
;           - DE = pointer to list, output of FindSym()
;   - PutToL(): Store OP1 in list
;       - Input:
;           - HL = element index
;           - DE = pointer to list, output of FindSym()
;   - CreateRList(): Creat a real list variable in RAM
;       - Input:
;           - HL = number of elements in the list
;           - OP1 = name of list to create
;       - Output:
;           - HL = pointer to symbol table entry
;           - DE = pointer to RAM
;   - FindSym(): Search symbol table for variable in OP1
;       - Input:
;           - OP1: variable name
;       - Output:
;           - HL = pointer to start of symbol table entry
;           - DE = pointer to start of variable data in RAM. For List variables,
;             points to the a u16 size of list.
;           - B = 0 (variable located in RAM)
;   - MemChk(): Determine if there is enough memory before creating a variable
;   - DelVar(), DelVarArc(), DelVarNoArc(): delete variables
;
; Getting the size (dimension) of existing list. From the SDK docs: "After
; creating a list with 23 elements, the first two bytes of the data structure
; are set to the number of elements, 17h 00h, the number of elements in hex,
; with the LSB followed by the MSB."
;
;    LD HL,L1Name
;    B_CALL Mov9ToOP1; OP1 = list L1 name
;    B_CALL FindSym ; look up list variable in OP1
;    JR C, NotFound ; jump if it is not created
;    EX DE,HL ; HL = pointer to data structure
;    LD E,(HL) ; get the LSB of the number elements
;    INC HL ; move to MSB
;    LD D,(HL) ; DE = number elements in L1
;L1Name:
;    DBListObj, tVarLst, tL1, 0
;
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
    set dirtyFlagsStack, (iy + dirtyFlags) ; force initial display
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
    set dirtyFlagsStack, (iy + dirtyFlags)
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
    set dirtyFlagsStack, (iy + dirtyFlags)
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
    set dirtyFlagsStack, (iy + dirtyFlags)
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
    set dirtyFlagsStack, (iy + dirtyFlags)
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
