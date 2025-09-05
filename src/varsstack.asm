;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; RPN Stack implemented using an appVar named RPN83STK.
;-----------------------------------------------------------------------------

; RPN stack using an RpnElementList which has the following structure:
; LastX, X, Y, Z, T.
stackLIndex equ 0 ; LastX
stackXIndex equ 1 ; X
stackYIndex equ 2 ; Y
stackZIndex equ 3 ; Z
stackTIndex equ 4 ; T
stackAIndex equ 5 ; A
stackBIndex equ 6 ; B
stackCIndex equ 7 ; C
stackDIndex equ 8 ; D

stackVarName:
    .db AppVarObj, "RPN83STK" ; max 8 char, NUL terminated if < 8

;-----------------------------------------------------------------------------

; Description: Initialize the RPN stack using the appVar 'RPN83STK'.
; Output:
;   - STK created and cleared if it doesn't exist
;   - stack lift enabled
;   - (stackSize)=len(RPN83PSTK)-1
; Destroys: all
initStack:
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ld hl, stackVarName
    ld c, stackSizeDefault+1 ; add 1 for LastX register
    call initRpnElementList
    ; cache the stack size
    call lenStack ; A=stackLen
    dec a ; ignore LastX register in element 0
    ld (stackSize), a
    ret

; Description: Initialize LastX with the contents of 'ANS' variable from TI-OS
; if ANS is real or complex. Otherwise, do nothing.
; Input: ANS
; Output: LastX=ANS
initLastX:
    bcall(_RclAns)
    bcall(_CkOP1Real) ; if OP1 real: ZF=1
    jp z, stoL
    bcall(_CkOP1Cplx) ; if OP complex: ZF=1
    jp z, stoL
    ret

; Description: Clear the RPN stack.
; Input: none
; Output: stack registers all set to 0.0
; Destroys: all, OP1
clearStack:
    set dirtyFlagsStack, (iy + dirtyFlags) ; force redraw
    set rpnFlagsLiftEnabled, (iy + rpnFlags) ; TODO: I think this can be removed
    call lenStack ; A=len; DE=dataPointer
    ld c, a ; C=len
    ld b, 0 ; B=begin=0
    jp clearRpnElementList

; Description: Should be called just before existing the app.
closeStack:
    ld hl, stackVarName
    jp closeRpnElementList

; Description: Return the length of the RPN stack variable.
; Output:
;   - A=length of RPN stack variable
;   - DE:(u8*)=dataPointer
; Destroys: BC, HL
lenStack:
    ld hl, stackVarName
    jp lenRpnElementList

; Description: Resize the stack to the new length in A.
; Input: A:u8=newLen
; Output:
;   - ZF=1 if newLen==oldLen
;   - CF=0 if newLen>oldLen
;   - CF=1 if newLen<oldLen
resizeStack:
    ld hl, stackVarName
    call resizeRpnElementList
    push af
    call lenStack
    dec a ; ignore LastX register
    ld (stackSize), a
    pop af
    ret

;-----------------------------------------------------------------------------
; Stack registers to and from OP1/OP2
;-----------------------------------------------------------------------------

; Description: Store OP1/OP2 to STK[nn], setting dirty flag.
; Input:
;   - C:u8=stack register index, 0-based
;   - OP1/OP2: float value
; Output:
;   - STK[nn] = OP1/OP2
; Destroys: all
; Preserves: OP1, OP2
stoStackNN:
    set dirtyFlagsStack, (iy + dirtyFlags)
    ld hl, stackVarName
    jp stoRpnObject

; Description: Copy STK[nn] to OP1/OP2.
; Input:
;   - C: stack register index, 0-based
;   - 'STK' app variable
; Output:
;   - OP1/OP2: float value
;   - A: rpnObjectType
; Destroys: all
rclStackNN:
    ld hl, stackVarName
    jp rclRpnObject ; OP1/OP2=STK[A]

;-----------------------------------------------------------------------------

; Description: Store OP1/OP2 to X.
; Destroys: all
stoX:
    ld c, stackXIndex
    jr stoStackNN

; Description: Recall X to OP1/OP2.
; Output: A=objectType
; Destroys: all
rclX:
    ld c, stackXIndex
    jr rclStackNN

;-----------------------------------------------------------------------------

; Description: Store OP1/OP2 to Y.
; Destroys: all
stoY:
    ld c, stackYIndex
    jr stoStackNN

; Description: Recall Y to OP1/OP2.
; Output: A=objectType
; Destroys: all
rclY:
    ld c, stackYIndex
    jr rclStackNN

;-----------------------------------------------------------------------------

; Description: Store OP1/OP2 to Z.
; Destroys: all
stoZ:
    ld c, stackZIndex
    jr stoStackNN

; Description: Recall Z to OP1/OP2.
; Output: A=objectType
; Destroys: all
rclZ:
    ld c, stackZIndex
    jr rclStackNN

;-----------------------------------------------------------------------------

; Description: Store OP1/OP2 to T.
; Destroys: all
stoT:
    ld c, stackTIndex
    jr stoStackNN

; Description: Recall T to OP1/OP2.
; Output: A=objectType
; Destroys: all
rclT:
    ld c, stackTIndex
    jr rclStackNN

;-----------------------------------------------------------------------------

; Description: Store OP1/OP2 to L.
; Destroys: all
stoL:
    ld c, stackLIndex
    jr stoStackNN

; Description: Recall L to OP1/OP2.
; Output: A=objectType
; Destroys: all
rclL:
    ld c, stackLIndex
    jr rclStackNN

; Description: Save X to L, directly, without mutating OP1/OP2.
; Preserves: OP1/OP2
saveLastX:
    bcall(_PushRpnObject1) ; FPS=[OP1/OP2]
    call rclX
    call stoL
    bcall(_PopRpnObject1) ; FPS=[]; OP1/OP2=OP1/OP2
    ret

;-----------------------------------------------------------------------------
; Most routines should use these functions to set the results from OP1 and/or
; OP2 to the RPN stack.
;-----------------------------------------------------------------------------

; Description: Replace X with RpnObject in OP1/OP2, saving previous X to LastX,
; and setting dirty flag. Works for all RpnObject types.
; Input: CP1=OP1/OP2:RpnObject
; Preserves: OP1, OP2
replaceX:
    call checkValidRpnObjectCP1
    call saveLastX
    call stoX
    ret

; Description: Replace X and Y with RpnObject in OP1/OP2, saving previous X to
; LastX, and setting dirty flag. Works for all RpnObject types.
; Input: CP1=OP1/OP2:RpnObject
; Preserves: OP1, OP2
replaceXY:
    call checkValidRpnObjectCP1
    call saveLastX
    call dropStack
    call stoX
    ret

; Description: Replace X and Y with Real numbers OP1 and OP2, in that order.
; This causes X=OP2 and Y=OP1, saving the previous X to LastX, and setting
; dirty flag.
; Input:
;   - OP1:Real=Y
;   - OP2:Real=X
; Output:
;   - Y=OP1
;   - X=OP2
;   - LastX=X
; Preserves: OP1, OP2
replaceXYWithOP1OP2:
    ; validate OP1 and OP2 before modifying X and Y
    call checkValidRealOP1
    call op1ExOp2
    call checkValidRealOP1
    call op1ExOp2
    ;
    call saveLastX
    call stoY ; Y = OP1
    call op1ExOp2
    call stoX ; X = OP2
    call op1ExOp2
    ret

; Description: Replace X with Real numbers OP1 and OP2 in that order.
; Input: OP1:Real, OP2:Real
; Output:
;   - Y=OP1
;   - X=OP2
;   - LastX=X
; Preserves: OP1, OP2
replaceXWithOP1OP2:
    ; validate OP1 and OP2 before modifying X and Y
    call checkValidRealOP1
    call op1ExOp2
    call checkValidRealOP1
    call op1ExOp2
    ;
    call saveLastX
    call stoX
    call liftStack
    call op1ExOp2
    call stoX
    call op1ExOp2
    ret

; Description: Replace X with objects in CP1 and CP3 in that order.
; Input:
;   - CP1:RpnObject=newY
;   - CP3:RpnObject=newX
; Output:
;   - Y=CP1
;   - X=CP3
;   - LastX=X
; Preserves: CP1, CP3
replaceXWithCP1CP3:
    ; validate CP1 and CP2 before modifying X and Y
    call checkValidRpnObjectCP1
    call cp1ExCp3
    call checkValidRpnObjectCP1
    call cp1ExCp3
    ;
    call saveLastX
    call stoX
    call liftStack
    call cp1ExCp3
    call stoX
    call cp1ExCp3
    ret

;-----------------------------------------------------------------------------

; Description: Push RpnOjbect in OP1/OP2 to the X register. LastX is not
; updated because the previous X is not consumed, and is availabe as the Y
; register. Works for all RpnObject types.
; Input: CP1=OP1/OP2:RpnObject
; Output:
;   - Stack lifted (if the inputBuf was not an empty string)
;   - X=OP1/OP2
; Destroys: all
; Preserves: OP1, OP2, LastX
pushToX:
    call checkValidRpnObjectCP1
    call liftStackIfNonEmpty
    call stoX
    ret

; Description: Push Real numbers OP1 then OP2 onto the stack. LastX is not
; updated because the previous X is not consumed, and is available as the Z
; register.
; Input: OP1:Real, OP2:Real
; Output:
;   - Stack lifted (if the inputBuf was not an empty string)
;   - Y=OP1
;   - X=OP2
; Destroys: all
; Preserves: OP1, OP2, LastX
pushToXY:
    call checkValidRealOP1
    call op1ExOp2
    call checkValidRealOP1
    call op1ExOp2
    ;
    call liftStackIfNonEmpty
    call stoX
    call liftStack
    call op1ExOp2
    call stoX
    call op1ExOp2
    ret

;-----------------------------------------------------------------------------

; Description: Check that OP1/OP2 is a valid RpnObject type (e.g. Real,
; Complex, Date-related objects). If real or complex, verify validity of number
; using CkValidNum().
; Input: OP1/OP2:RpnObject
; Destroys: A, HL
checkValidRpnObjectCP1:
    call getOp1RpnObjectType ; A=type; HL=OP1
    cp rpnObjectTypeReal
    jr z, checkValidNumber
    cp rpnObjectTypeComplex
    jr z, checkValidNumber
    cp rpnObjectTypeDate
    ret z
    cp rpnObjectTypeTime
    ret z
    cp rpnObjectTypeDateTime
    ret z
    cp rpnObjectTypeOffset
    ret z
    cp rpnObjectTypeOffsetDateTime
    ret z
    cp rpnObjectTypeDayOfWeek
    ret z
    cp rpnObjectTypeDuration
    ret z
    cp rpnObjectTypeDenominate
    ret z
    bcall(_ErrDataType)
checkValidNumber:
    bcall(_CkValidNum) ; destroys AF, HL
    ret

; Description: Check that OP1 is real. Throws Err:NonReal if not real.
; Input: OP1/OP2:RpnObject
; Destroys: A, HL
checkValidRealOP1:
    call getOp1RpnObjectType ; A=type; HL=OP1
    cp rpnObjectTypeReal
    jr nz, checkValidRealErr
    bcall(_CkValidNum) ; dstroys AF, HL
    ret
checkValidRealErr:
    bcall(_ErrNonReal)

;-----------------------------------------------------------------------------

; Description: Lift the RPN stack, if inputBuf was not empty when closed.
; Input: none
; Output: T=Z; Z=Y; Y=X; X=X; OP1 preserved
; Destroys: all
; Preserves: OP1, OP2
liftStackIfNonEmpty:
    bit inputBufFlagsClosedEmpty, (iy + inputBufFlags)
    ret nz ; return doing nothing if closed empty
    ; [[fallthrough]]

; Description: Lift the RPN stack, if rpnFlagsLiftEnabled is set.
; Input: rpnFlagsLiftEnabled
; Output: T=Z; Z=Y; Y=X; X=X; OP1 preserved
; Destroys: all
; Preserves: OP1, OP2
liftStackIfEnabled:
    bit rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret z
    ; [[fallthrough]]

; Description: Lift the RPN stack unconditionally, copying X to Y.
; Input: none
; Output: stack lifted
; Destroys: all
; Preserves: OP1, OP2
liftStack:
    bcall(_PushRpnObject1) ; FPS=[OP1/OP2]
    call liftStackIntoOp1 ; OP1=lastElement, thrown away
    bcall(_PopRpnObject1) ; FPS=[]; OP1/OP2=OP1/OP2
    ret

; Description: Lift the RPN stack with last element pushed into OP1.
; Input: none
; Output:
;   - stack lifted
;   - last element shifted into OP1
;   - DE=pointer to first element (to which OP1 can be copied to)
; Destroys: all, OP1
liftStackIntoOp1:
    ; Calculate moveSize=(numElements-2)*rpnElementSizeOf
    call lenStack ; A=stackLen
    ld l, a
    dec l
    dec l
    ld h, 0 ; HL=numElements-2
    call rpnElementLenToSize ; HL=moveSize; preserves A
    push hl ; stack=[moveSize]
    ; calculate source and dest indexes
    dec a ; index to last element
    ld b, a
    dec a
    ld c, a ; index to 2nd last element
    ld hl, stackVarName
    call rpnObjectIndexesToPointers ; DE=end-1; HL=end-2; destroys OP1
    ; copy the last element to OP1
    push hl
    push de
    ex de, hl ; HL=end-1
    call moveRpnElementToOp1
    pop de
    pop hl
    ; shift pointers to the end of the element, in prep for LDDR
    ld bc, rpnElementSizeOf-1
    add hl, bc
    ex de, hl
    add hl, bc
    ex de, hl ; DE, HL=pointer to last byte of RpnElement
    ;
    pop bc ; stack=[]; BC=moveSize
    lddr ; HL=pointer to one byte before the X element
    ;
    ex de, hl
    inc de ; pointer to first element
    set dirtyFlagsStack, (iy + dirtyFlags)
    ret

;-----------------------------------------------------------------------------

; Description: Roll the RPN stack up, rotating last element into X.
; Input: none
; Output: stack rolled up
; Destroys: all, OP1, OP2
; Preserves: none
rollUpStack:
    call liftStackIntoOp1 ; OP1=lastElement; DE=pointer to first element
    call moveRpnElementFromOp1 ; X=lastElement
    ret

;-----------------------------------------------------------------------------

; Description: Drop the RPN stack, duplicating the top-most element.
; Input: none
; Output: stack dropped; OP1 preserved
; Destroys: all
; Preserves: OP1, OP2
dropStack:
    bcall(_PushRpnObject1) ; FPS=[OP1/OP2]
    call dropStackIntoOp1 ; OP1=X, thrown away
    bcall(_PopRpnObject1) ; FPS=[]; OP1/OP2=OP1/OP2
    ret

; Description: Drop the RPN stack, shifting the X register into OP1.
; Output:
;   - stack dropped (shifted left)
;   - OP1=X
;   - DE=pointer to last element (to which OP1 can be copied to)
dropStackIntoOp1:
    ; Calculate moveSize=(numElements-2)*rpnElementSizeOf
    call lenStack ; A=stackLen
    ld l, a
    dec l
    dec l
    ld h, 0
    call rpnElementLenToSize ; HL=moveSize; preserves A
    push hl ; stack=[moveSize]
    ; calculate source and dest indexes
    ld b, stackXIndex
    ld c, stackYIndex
    ld hl, stackVarName
    call rpnObjectIndexesToPointers ; DE=pointerX; HL=pointerY; destroys OP1
    ; copy the first element to OP1
    push hl
    push de
    ex de, hl ; HL=X element
    call moveRpnElementToOp1
    pop de
    pop hl
    ;
    pop bc ; stack=[]; BC=moveSize
    ldir ; DE=pointer to last element
    set dirtyFlagsStack, (iy + dirtyFlags)
    ret

;-----------------------------------------------------------------------------

; Description: Roll the RPN stack *down*, rotating X into T.
; Input: none
; Output: X=Y; Y=Z; Z=T; T=X
; Destroys: all, OP1, OP2
; Preserves: none
rollDownStack:
    call dropStackIntoOp1 ; DE=pointer to last element; OP1=X
    call moveRpnElementFromOp1 ; lastElement=X
    ret

;-----------------------------------------------------------------------------

; Description: Move RpnElement from HL to OP1. Assumes rpnElementSizeOf<=22.
; Destroys: BC, DE, HL
; Preserves: A
moveRpnElementToOp1:
    ld de, OP1
    ld bc, rpnElementSizeOf
    ldir
    ret

; Description: Move RpnElement from OP1 to DE. Assumes rpnElementSizeOf<=22.
; Destroys: BC, DE, HL
; Preserves: A
moveRpnElementFromOp1:
    ld hl, OP1
    ld bc, rpnElementSizeOf
    ldir
    ret

;-----------------------------------------------------------------------------

; Description: Exchange X<->Y.
; Input: none
; Output: X=Y; Y=X
; Destroys: all, OP1, OP2
exchangeXYStack:
    ld b, stackXIndex
    ld c, stackYIndex
    ld hl, stackVarName
    call rpnObjectIndexesToPointers ; DE=pointerX; HL=pointerY; destroys OP1
    ld b, rpnElementSizeOf
    call exchangeLoop
    set dirtyFlagsStack, (iy + dirtyFlags)
    ret
