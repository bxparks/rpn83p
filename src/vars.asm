;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; RPN stack registers and storage registers are implemented using TI-OS list
; variables. Stack variables are stored in a list named 'STK' and storage
; registers are stored in a list named 'REGS' (which is similar to the 'REGS'
; variable used on the HP-42S calculator).
;
; Early versions of RPN83P mapped each stack register to a single-letter real
; variables in the TI-OS, in other words, X, Y, Z, T, R. They were convenient
; because the TI-OS seemed to provide a number of subroutines (e.g. StoX, RclX,
; etc), which makde it relatively easy access those single-letter variables.
;
; Later, I wanted to rename those single-letter variables to STX, STY, STZ,
; STT, and STL, to avoid any conflicts with other apps that may use those
; variables. But I discovered that the TI-OS allows only a single-letter
; variable name for RealObj variables. Multi-letter variables are supported
; only for ListObj, CListObj, ProgObj, ProtProgObj, and AppVarObj. Since I had
; already learned how to use the TI-OS routines related to list variables, it
; made sense to move the RPN stack variables to a ListObj variable. It is named
; 'STK' because I wanted it to be relatively short (for efficiency), but also
; long enough to be self-descriptive and avoid name conflicts with any other
; apps. (The other option was 'ST' which didn't seem self-descriptive enough.)
;
; The following are the TI-OS routines relavant to ListObj variables:
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

stackSize equ 5 ; X, Y, Z, T, LastX
stackXIndex equ 0
stackYIndex equ 1
stackZIndex equ 2
stackTIndex equ 3
stackLIndex equ 4 ; LastX

stackName:
    .db ListObj, tVarLst, "STK", 0

setStackName:
    ld hl, stackName
    bcall(_Mov9ToOP1)
    ret

; Description: Initialize the RPN stack using the TI-OS list variable named
; 'STK'.
; Output:
;   - STK deleted if not a real list
;   - STK deleted if dim(STK) != 5
;   - STK created if it doesn't exist
;   - stack lift enabled
; Destroys: all
initStack:
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    call setStackName
    bcall(_FindSym)
    jr c, initStackCreate ; if CF=1: not found
initStackCheckType:
    and $1F
    cp ListObj
    jr nz, initStackDelete
initStackCheckArchive:
    ; if B!=0: var is archived
    ld a, b
    or a
    jr nz, initStackDelete
initStackCheckSize:
    ex de, hl ; HL = pointer to data structure
    ld e, (hl) ; get the LSB of the number elements
    inc hl ; move to MSB
    ld d, (hl) ; DE = number elements in STK
    ex de, hl
    ld de, stackSize
    bcall(_CpHLDE) ; if dim(STK) == 5: ZF=1
    ret z ; STK is Real, size==5, all ok
initStackWrongSize:
    ; wrong size, so delete and recreate
    call setStackName ; OP1="STK"
    bcall(_FindSym)
initStackDelete:
    bcall(_DelVarArc)
    ; [[fallthrough]]
initStackCreate:
    call setStackName
    ld hl, stackSize
    bcall(_CreateRList)
    jr clearStackAltEntry

; Description: Initialize LastX with the contents of 'ANS' variable from TI-OS.
; If the ANS is not Real, do nothing.
; Input: ANS
; Output: LastX=ANS
initLastX:
    bcall(_RclAns)
    bcall(_CkOP1Real) ; if OP1 real: ZF=1
    ret nz
    jp stoL

; Description: Clear the RPN stack.
; Input: none
; Output: stack registers all set to 0.0
; Destroys: all
clearStack:
    call setStackName
    bcall(_FindSym)
clearStackAltEntry: ; alternate entry if DE is already correctly set
    inc de
    inc de ; skip u16 holding the list size
    ld hl, stackSize
    ld b, stackSize
    bcall(_OP1Set0)
clearStackLoop:
    ld hl, OP1
    push bc
    ld bc, 9
    ldir
    pop bc
    djnz clearStackLoop
clearStackEnd:
    set dirtyFlagsStack, (iy + dirtyFlags) ; force redraw
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------
; Stack registers to and from OP1.
;-----------------------------------------------------------------------------

; Description: Store OP1 to STK[nn], setting dirty flag.
; Input:
;   - A: register index, 0-based
;   - OP1: float value
; Output:
;   - STK[nn] = OP1
; Destroys: all
; Preserves: OP1, OP2
; TODO: I think we can combine stoNN() and stoStackNN().
stoStackNN:
    inc a ; change from 0-based to 1-based
    push af
    bcall(_PushRealO1) ; FPS=[OP1]
    call setStackName
    bcall(_FindSym) ; DE = pointer data area
    push de
    bcall(_PopRealO1) ; FPS=[]; OP1=OP1; destroys DE
    pop de
    pop af
    ld l, a
    ld h, 0
    bcall(_PutToL)
    set dirtyFlagsStack, (iy + dirtyFlags)
    ret

; Function: Copy STK[nn] to OP1.
; Input:
;   - A: register index, 0-based
;   - 'STK' list variable
; Output:
;   - OP1: float value
; Destroys: all
; Preserves: OP2
; TODO: I think we can combine rclNN() and rclStackNN().
rclStackNN:
    inc a ; change from 0-based to 1-based
    push af
    call setStackName
    bcall(_FindSym) ; DE = pointer data area
    pop af
    ld l, a
    ld h, 0
    bcall(_GetLToOP1)
    ret

;-----------------------------------------------------------------------------

; Description: Set OP1 to X.
; Destroys: all
rclX:
    ld a, stackXIndex
    jr rclStackNN

; Description: Set X to OP1. Also update `ANS` with the same value. Upon
; exiting the RPN83P app, the TI-OS can access the most current X value using
; `ANS`.
; Destroys: all
stoX:
    ld a, stackXIndex
    jr stoStackNN

;-----------------------------------------------------------------------------

; Description: Set OP1 to Y.
; Destroys: all
rclY:
    ld a, stackYIndex
    jr rclStackNN

; Description: Set Y to OP1.
; Destroys: all
stoY:
    ld a, stackYIndex
    jr stoStackNN

;-----------------------------------------------------------------------------

; Description: Set OP1 to stZ.
; Destroys: all
rclZ:
    ld a, stackZIndex
    jr rclStackNN

; Description: Set stZ to OP1.
; Destroys: all
stoZ:
    ld a, stackZIndex
    jr stoStackNN

;-----------------------------------------------------------------------------

; Description: Set OP1 to stT.
; Destroys: all
rclT:
    ld a, stackTIndex
    jr rclStackNN

; Description: Set stT to OP1.
; Destroys: all
stoT:
    ld a, stackTIndex
    jr stoStackNN

;-----------------------------------------------------------------------------

; Description: Set OP1 to stL.
; Destroys: all
rclL:
    ld a, stackLIndex
    jr rclStackNN

; Description: Set stL to OP1.
; Destroys: all
stoL:
    ld a, stackLIndex
    jr stoStackNN

;-----------------------------------------------------------------------------
; Most routines should use these functions to set the results from OP1 and/or
; OP2 to the RPN stack.
;-----------------------------------------------------------------------------

; Description: Replace X with OP1, saving previous X to LastX, and
; setting dirty flag.
; Preserves: OP1, OP2
replaceX:
    bcall(_CkValidNum)
    bcall(_PushRealO1) ; FPS=[OP1]
    call rclX
    call stoL
    bcall(_PopRealO1) ; FPS=[]; OP1=OP1
    call stoX
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

; Description: Replace (X, Y) pair with OP1, saving previous X to LastX,
; and setting dirty flag.
; Preserves: OP1, OP2
replaceXY:
    bcall(_CkValidNum)
    bcall(_PushRealO1) ; FPS=[OP1]
    call rclX
    call stoL
    call dropStack
    bcall(_PopRealO1) ; FPS=[]; OP1=OP1
    call stoX
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

; Description: Replace X and Y with push of OP1 and OP2 on the stack in that
; order. This causes X=OP2 and Y=OP1, saving the previous X to LastX, and
; setting dirty flag.
; Input: X, Y, OP1, OP2
; Output:
;   - Y=OP1
;   - X=OP2
;   - LastX=X
; Preserves: OP1, OP2
replaceXYWithOP1OP2:
    ; validate OP1 and OP2 before modifying X and Y
    bcall(_CkValidNum)
    bcall(_OP1ExOP2)
    bcall(_CkValidNum)
    bcall(_OP1ExOP2)

    call stoY ; Y = OP1
    bcall(_PushRealO1) ; FPS=[OP1]
    call rclX
    call stoL; LastX = X

    bcall(_OP2ToOP1)
    call stoX ; X = OP2
    bcall(_PopRealO1) ; FPS=[]; OP1=OP1
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

; Description: Replace X with OP1, and OP2 pushed onto the stack in that order.
; Input: X, OP1, OP2
; Output:
;   - Y=OP1
;   - X=OP2
;   - LastX=X
; Preserves: OP1, OP2
replaceXWithOP1OP2:
    ; validate OP1 and OP2 before modifying X and Y
    bcall(_CkValidNum)
    bcall(_OP1ExOP2)
    bcall(_CkValidNum)
    bcall(_OP1ExOP2)

    bcall(_PushRealO1) ; FPS=[OP1]
    call rclX
    call stoL
    bcall(_PopRealO1) ; FPS=[]; OP1=OP1
    call stoX
    call liftStack
    bcall(_OP2ToOP1)
    call stoX
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

; Description: Push OP1 to the X register. LastX is not updated because the
; previous X is not consumed, and is availabe as the Y register.
; Input: X, OP1
; Output:
;   - Stack lifted (if the inputBuf was not an empty string)
;   - X=OP1
; Destroys: all
; Preserves: OP1, OP2, LastX
pushX:
    bcall(_CkValidNum)
    call liftStackIfNonEmpty
    call stoX
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

; Description: Push OP1 then OP2 onto the stack. LastX is not updated because
; the previous X is not consumed, and is available as the Z register.
; Input: X, Y, OP1, OP2
; Output:
;   - Stack lifted (if the inputBuf was not an empty string)
;   - Y=OP1
;   - X=OP2
; Destroys: all
; Preserves: OP1, OP2, LastX
pushXY:
    bcall(_CkValidNum)
    bcall(_OP1ExOP2)
    bcall(_CkValidNum)
    bcall(_OP1ExOP2)
    call liftStackIfNonEmpty
    call stoX
    call liftStack
    bcall(_OP1ExOP2)
    call stoX
    bcall(_OP1ExOP2)
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------

; Function: Lift the RPN stack, if inputBuf was not empty when closed.
; Input: none
; Output: T=Z; Z=Y; Y=X; X=X; OP1 preserved
; Destroys: all
; Preserves: OP1, OP2
liftStackIfNonEmpty:
    bit inputBufFlagsClosedEmpty, (iy + inputBufFlags)
    ret nz ; return doing nothing if closed empty
    ; [[fallthrough]]

; Function: Lift the RPN stack, if rpnFlagsLiftEnabled is set.
; Input: rpnFlagsLiftEnabled
; Output: T=Z; Z=Y; Y=X; X=X; OP1 preserved
; Destroys: all
; Preserves: OP1, OP2
liftStackIfEnabled:
    bit rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret z
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ; [[fallthrough]]

; Function: Lift the RPN stack unconditionally, copying X to Y.
; Input: none
; Output: T=Z; Z=Y; Y=X; X=X; OP1 preserved
; Destroys: all
; Preserves: OP1, OP2
; TODO: Make this more efficient by taking advantage of the fact that stack
; registers are actually in a list variable named STK.
liftStack:
    bcall(_PushRealO1) ; FPS=[OP1]
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
    bcall(_PopRealO1) ; FPS=[]; OP1=OP1
    ret

;-----------------------------------------------------------------------------

; Function: Drop the RPN stack, copying T to Z.
; Input: none
; Output: X=Y; Y=Z; Z=T; T=T; OP1 preserved
; Destroys: all
; Preserves: OP1, OP2
; TODO: Make this more efficient by taking advantage of the fact that stack
; registers are actually in a list variable named STK.
dropStack:
    bcall(_PushRealO1) ; FPS=[OP1]
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
    bcall(_PopRealO1) ; FPS=[]; OP1=OP1
    ret

;-----------------------------------------------------------------------------

; Function: Rotate the RPN stack *down*.
; Input: none
; Output: X=Y; Y=Z; Z=T; T=X
; Destroys: all, OP1, OP2
; Preserves: none
; TODO: Make this more efficient by taking advantage of the fact that stack
; registers are actually in a list variable named STK.
rotDownStack:
    ; save X in FPS
    call rclX
    bcall(_PushRealO1) ; FPS=[OP1]
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
    bcall(_PopRealO1) ; FPS=[]; OP1=OP1
    call stoT
    ret

;-----------------------------------------------------------------------------

; Function: Rotate the RPN stack *up*.
; Input: none
; Output: T=Z; Z=Y; Y=X; X=T
; Destroys: all, OP1, OP2
; Preserves: none
; TODO: Make this more efficient by taking advantage of the fact that stack
; registers are actually in a list variable named STK.
rotUpStack:
    ; save T in FPS
    call rclT
    bcall(_PushRealO1) ; FPS=[OP1]
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
    bcall(_PopRealO1) ; FPS=[]; OP1=OP1
    call stoX
    ret

;-----------------------------------------------------------------------------

; Function: Exchange X<->Y.
; Input: none
; Output: X=Y; Y=X
; Destroys: all, OP1, OP2
exchangeXYStack:
    call rclX
    bcall(_OP1ToOP2)
    call rclY
    call stoX
    bcall(_OP2ToOP1)
    call stoY
    ret

;-----------------------------------------------------------------------------
; User registers in REGS list.
;-----------------------------------------------------------------------------

regsSize equ 25

setRegsName:
    ld hl, regsName ; HL = "REGS"
    bcall(_Mov9ToOP1)
    ret

regsName:
    .db ListObj, tVarLst, "REGS", 0

; Description: Initialize the REGS list variable which is used for user
; registers 00 to 24.
; Input: none
; Output:
;   - REGS deleted if not a real list
;   - REGS deleted if dim(REGS) != 25
;   - REGS created if it doesn't exist
; Destroys: all
initRegs:
    call setRegsName
    bcall(_FindSym)
    jr c, initRegsCreate ; if CF=1: not found
initRegsCheckType:
    and $1F
    cp ListObj
    jr nz, initRegsDelete
initRegsCheckArchive:
    ; if B!=0: var is archived
    ld a, b
    or a
    jr nz, initRegsDelete
initRegsCheckSize:
    ex de, hl ; HL = pointer to data structure
    ld e, (hl) ; get the LSB of the number elements
    inc hl ; move to MSB
    ld d, (hl) ; DE = number elements in REGS
    ex de, hl
    ld de, regsSize
    bcall(_CpHLDE) ; if dim(REGS) < 25: CF=1
    ret z ; REGS is Real, and sizeof 25, all ok
initRegsWrongSize:
    ; wrong size, so delete and recreate
    call setRegsName ; OP1="REGS"
    bcall(_FindSym)
initRegsDelete:
    bcall(_DelVarArc)
    ; [[fallthrough]
initRegsCreate:
    call setRegsName ; OP1="REGS"
    ld hl, regsSize
    bcall(_CreateRList) ; DE points to data area
    jr clearRegsAltEntry

; Description: Clear all REGS elements.
; Input: none
; Output: REGS elements set to 0.0
; Destroys: all
clearRegs:
    call setRegsName ; OP1="REGS"
    bcall(_FindSym)
clearRegsAltEntry: ; alternate entry if DE is already correctly set
    inc de
    inc de ; skip u16 holding the list size
    ld hl, regsSize
    ld b, regsSize
    bcall(_OP1Set0)
clearRegsLoop:
    ld hl, OP1
    push bc
    ld bc, 9
    ldir
    pop bc
    djnz clearRegsLoop
    ret

;-----------------------------------------------------------------------------

; Description: Store OP1 into REGS[NN].
; Input:
;   - A: register index, 0-based
;   - OP1: float value
; Output:
;   - REGS[NN] = OP1
; Destroys: all
; Preserves: OP1
stoNN:
    inc a ; change from 0-based to 1-based
    push af
    bcall(_PushRealO1) ; FPS=[OP1]
    call setRegsName
    bcall(_FindSym) ; DE=pointer to var data area
    push de
    bcall(_PopRealO1) ; FPS=[]; OP1=OP1
    pop de
    pop af
    ld l, a
    ld h, 0
    bcall(_PutToL)
    ret

; Description: Recall REGS[NN] into OP1.
; Input:
;   - A: register index, 0-based
;   - 'REGS' list variable
; Output:
;   - OP1: float value
; Destroys: all
; Preserves: OP2
rclNN:
    inc a ; change from 0-based to 1-based
    push af
    call setRegsName
    bcall(_FindSym)
    pop af
    ld l, a
    ld h, 0
    bcall(_GetLToOP1)
    ret

; Description: Recall REGS[NN] to OP2.
; Input:
;   - A: register index, 0-based
;   - 'REGS' list variable
; Output:
;   - OP2: float value
rclNNToOP2:
    bcall(_PushRealO1) ; FPS=[OP1]
    call rclNN
    bcall(_OP1ToOP2)
    bcall(_PopRealO1) ; FPS=[]; OP1=OP1
    ret

;-----------------------------------------------------------------------------

; Description: Add OP1 to storage register NN. Used by STAT functions.
; Input:
;   OP1: float value
;   A: register index NN, 0-based
; Output:
;   REGS[NN] += OP1
; Destroys: all
; Preserves: OP1, OP2
stoAddNN:
    push af ; A=NN
    bcall(_PushRealO1) ; FPS=[OP1]
    bcall(_PushRealO2) ; FPS=[OP1,OP2]
    bcall(_OP1ToOP2)
    call rclNN ; I guess A is preserved by the previous bcalls
    bcall(_FPAdd) ; OP1 += OP2
    pop af ; A=NN
    call stoNN
    bcall(_PopRealO2) ; FPS=[OP1]
    bcall(_PopRealO1) ; FPS=[]; OP1=OP1
    ret

; Description: Subtract OP1 from storage register NN. Used by STAT functions.
; Input:
;   OP1: float value
;   A: register index NN, 0-based
; Output:
;   REGS[NN] -= OP1
; Destroys: all
; Preserves: OP1, OP2
stoSubNN:
    push af ; A=NN
    bcall(_PushRealO1) ; FPS=[OP1]
    bcall(_PushRealO2) ; FPS=[OP1,OP2]
    bcall(_OP1ToOP2)
    call rclNN ; I guess A is preserved by the previous bcalls
    bcall(_FPSub) ; OP1 -= OP2
    pop af ; A=NN
    call stoNN
    bcall(_PopRealO2) ; FPS=[OP1]
    bcall(_PopRealO1) ; FPS=[]; OP1=OP1
    ret

;-----------------------------------------------------------------------------

; Description: Implement STO{op} NN, with {op} defined by B and NN given by C.
; Input:
;   - OP1
;   - B: operation index [0,4] into floatOps, MUST be same as argModifierXxx
;   - C: register index NN, 0-based
; Output:
;   - REGS[C] {op}= OP1, where {op} is defined by B
; Destroys: all
; Preserves: OP1, OP2
stoOpNN:
    push bc
    bcall(_PushRealO1) ; FPS=[OP1]
    bcall(_PushRealO2) ; FPS=[OP1,OP2]
    bcall(_OP1ToOP2)
    ; Recall REGS[C]
    pop bc
    push bc
    ld a, c ; A=C=register index
    call rclNN
    ; Invoke op B
    pop bc
    push bc
    ld a, b ; A=op-index
    ld hl, floatOps
    call jumpAOfHL
    ; Save REGS[C]
    pop bc
    ld a, c ; A=C=register index
    call stoNN
    ; restore OP1, OP2
    bcall(_PopRealO2) ; FPS=[OP1]
    bcall(_PopRealO1) ; FPS=[]; OP1=OP1
    ret

; Description: Implement RCL{op} NN, with {op} defined by B and NN given by C.
; Input:
;   - OP1
;   - B: operation index [0,4] into floatOps, MUST be same as argModifierXxx
;   - C: register index NN, 0-based
; Output:
;   - OP1 {op}= REGS[C], where {op} is defined by B
; Destroys: all
; Preserves: OP2
rclOpNN:
    push bc
    bcall(_PushRealO2) ; FPS=[OP2]
    ; Recall REGS[C]
    pop bc
    push bc
    ld a, c ; A=C=register index
    call rclNNToOP2
    ; Invoke op B
    pop bc
    ld a, b ; A=op-index
    ld hl, floatOps
    call jumpAOfHL
    bcall(_PopRealO2) ; FPS=[]; OP2=OP2
    ret

; List of floating point operations, indexed from 0 to 4. Implements `OP1 {op}=
; OP2`. These MUST be identical to the argModifierXxx constants.
floatOpsCount equ 5
floatOps:
    .dw floatOpAssign ; 0, argModifierNone
    .dw floatOpAdd ; 1, argModifierAdd
    .dw floatOpSub ; 2, argModifierSub
    .dw floatOpMul ; 3, argModifierMul
    .dw floatOpDiv ; 4, argModifierDiv

floatOpAssign:
    bcall(_OP2ToOP1)
    ret
floatOpAdd:
    bcall(_FPAdd)
    ret
floatOpSub:
    bcall(_FPSub)
    ret
floatOpMul:
    bcall(_FPMult)
    ret
floatOpDiv:
    bcall(_FPDiv)
    ret

;-----------------------------------------------------------------------------

; Description: Clear the storage registers used by the STAT functions. In
; Linear mode [R11, R16], in All mode [R11, R23], inclusive.
; Input: none
; Output:
;   - B: 0
;   - C: 24
;   - OP1: 0
; Destroys: all, OP1
; TODO: This could be implemented more efficiently by using the fact that the
; storage registers are located in contiguous memory. On the other hand, this
; function is not expected to be called often, so the efficiency probably
; doesn't matter.
clearStatRegs:
    bcall(_OP1Set0)
    ld c, 11 ; begin clearing register 11
    ; Check AllMode or LinearMode.
    ld a, (statAllEnabled)
    or a
    jr nz, clearStatRegsAll
    ld b, 6 ; clear first 6 registers in Linear mode
    jr clearStatRegsEntry
clearStatRegsAll:
    ld b, 13 ; clear all 13 registesr in All mode
    jr clearStatRegsEntry
clearStatRegsLoop:
    inc c
clearStatRegsEntry:
    ld a, c
    push bc
    call stoNN
    pop bc
    djnz clearStatRegsLoop
    ret

;-----------------------------------------------------------------------------
; Manage app state using an AppVar named 'RPN83SAV'.
;-----------------------------------------------------------------------------

appVarName:
    .db AppVarObj, "RPN83SAV" ; max 8 characters, NUL terminated if < 8

setAppVarName:
    ld hl, appVarName
    bcall(_Mov9ToOP1)
    ret

; Description: Store the RPN83P state to an AppVar named 'RPN83SAV'.
storeAppState:
    call setAppVarName
    bcall(_ChkFindSym)
    jr c, storeAppStateCreate ; if CF=1: not found
storeAppStateDelete:
    ; alway delete the app var if found
    bcall(_DelVarArc)
storeAppStateCreate:
    ; Fill in the appId and schemaVersion fields.
    ld hl, rpn83pAppId
    ld (appStateAppId), hl
    ld hl, rpn83pSchemaVersion
    ld (appStateSchemaVersion), hl
    ; Copy the app flags into the appState fields.
    ld a, (iy + dirtyFlags)
    ld (appStateDirtyFlags), a
    ld a, (iy + rpnFlags)
    ld (appStateRpnFlags), a
    ld a, (iy + inputBufFlags)
    ld (appStateInputBufFlags), a
    ; Calculate the CRC16 on the data block.
    ld hl, appStateBegin + 2 ; don't include the CRC16 field itself
    ld bc, appStateSize - 2 ; don't include the CRC16 field itself
    call crc16ccitt
    ld (appStateCrc16), hl
    ; Transfer the appState data block.
    call setAppVarName
    ld hl, appStateSize
    bcall(_CreateAppVar) ; DE=pointer to appvar data
    inc de
    inc de ; skip past the 2-byte size field
    ld hl, appStateBegin
    ld bc, appStateSize
    ldir ; transfer bytes
    ret

; Description: Restore the RPN83P application state from an AppVar named
; 'RPN83SAV'.
; Output:
;   CF=0: if restored correctly from the AppVar
;   CF=1: if the AppVar does not exist, or was invalid for any reason. The
;       application should initialize its state from scratch.
restoreAppState:
    call setAppVarName
    bcall(_ChkFindSym) ; DE=pointer to data
    ret c ; CF=1 if not found
    ex de, hl; HL=pointer to data
    ld e, (hl)
    inc hl
    ld d, (hl) ; DE=size of appVar
    inc hl
    ; Validate the AppVar size
    push hl ; save data + 2
    ld hl, appStateSize
    or a ; CF=0
    sbc hl, de ; if HL==DE: ZF=0
    pop hl ; HL=data + 2
    jr nz, restoreAppStateFailed
restoreAppStateRead:
    ; Read the AppVar data into appStateBegin
    ld de, appStateBegin
    ld bc, appStateSize
    ldir
restoreAppStateValidate:
    ; Validate the appStateAppId
    ld hl, (appStateAppId)
    ld de, rpn83pAppId
    or a ; CF=0
    sbc hl, de
    jr nz, restoreAppStateFailed
    ; Validate the appStateSchemaVersion
    ld hl, (appStateSchemaVersion)
    ld de, rpn83pSchemaVersion
    or a ; CF=0
    sbc hl, de
    jr nz, restoreAppStateFailed
    ; Validate the CRC16
    ld hl, appStateBegin + 2 ; don't include the CRC16 field itself
    ld bc, appStateSize - 2 ; don't include the CRC16 field itself
    call crc16ccitt
    ld de, (appStateCrc16)
    or a ; CF=0
    sbc hl, de
    jr nz, restoreAppStateFailed
    ; Restore the app flags
    ld a, (appStateDirtyFlags)
    ld (iy + dirtyFlags), a
    ld a, (appStateRpnFlags)
    ld (iy + rpnFlags), a
    ld a, (appStateInputBufFlags)
    ld (iy + inputBufFlags), a
    ; Validation passed
    or a ; CF=0
    ret
restoreAppStateFailed:
    scf
    ret
