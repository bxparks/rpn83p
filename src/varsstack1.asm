;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; RPN Stack implemented using an appVar named RPN83STK.
;
; Capitalized labels are intended to be exported to the branch table on flash
; page 0. Lowercased labels are intended to be local to the current flash page.
;-----------------------------------------------------------------------------

; RPN stack using an RpnElementList (see vars1.asm) inside a TI-OS AppVar.
; An RpnElementList is composed of objectType byte, and 18 bytes. When an
; RpnElement is copied to the OPx floating point registers, it occupies 2
; slots. They are named CP1 (OP1/OP2), CP3 (OP3/OP4), and CP5 (OP5/OP6).
;
; The RPN stack can be as large as 9 elements (RSIZ + 1). Each stack register
; is indexed by an integer, with the common RPN stack registers (LastX, X, Y,
; Z, T) assigned as follows:
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
InitStack:
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ld hl, stackVarName
    ld c, stackSizeDefault+1 ; add 1 for LastX register
    call initRpnElementList
    ; cache the stack size
    call LenStack ; A=stackLen
    dec a ; ignore LastX register in element 0
    ld (stackSize), a
    ret

; Description: Initialize LastX with the contents of 'ANS' variable from TI-OS
; if ANS is real or complex. Otherwise, do nothing.
; Input: ANS
; Output: LastX=ANS
InitLastX:
    bcall(_RclAns)
    bcall(_CkOP1Real) ; if OP1 real: ZF=1
    jp z, StoStackL
    bcall(_CkOP1Cplx) ; if OP complex: ZF=1
    jp z, StoStackL
    ret

; Description: Clear the RPN stack.
; Input: none
; Output: stack registers all set to 0.0
; Destroys: all, OP1
ClearStack:
    set dirtyFlagsStack, (iy + dirtyFlags) ; force redraw
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ;
    call LenStack ; A=len; DE=dataPointer
    ld c, a ; C=len
    ld b, 0 ; B=begin=0
    jp clearRpnElementList

; Description: Should be called just before existing the app.
CloseStack:
    ld hl, stackVarName
    jp closeRpnElementList

; Description: Return the length of the RPN stack variable.
; Output:
;   - A=length of RPN stack variable
;   - DE:(u8*)=dataPointer
; Destroys: BC, HL
LenStack:
    ld hl, stackVarName
    jp lenRpnElementList

; Description: Resize the stack to the new length in A.
; Input: A:u8=newLen
; Output:
;   - ZF=1 if newLen==oldLen
;   - CF=0 if newLen>oldLen
;   - CF=1 if newLen<oldLen
ResizeStack:
    ld hl, stackVarName
    call resizeRpnElementList
    push af
    call LenStack
    dec a ; ignore LastX register
    ld (stackSize), a
    pop af
    ret

;-----------------------------------------------------------------------------
; Stack registers to and from CP1 and CP3.
;-----------------------------------------------------------------------------

; Description: Store CP1 to STK[nn], setting dirty flag.
; Input:
;   - C:u8=stack register index, 0-based
;   - CP1: float value
; Output:
;   - STK[nn] = CP1
; Destroys: all
; Preserves: OP1, OP2
stoStackNN:
    set dirtyFlagsStack, (iy + dirtyFlags)
    ld hl, stackVarName
    jp stoRpnObject

; Description: Copy STK[nn] to CP1.
; Input:
;   - C: stack register index, 0-based
;   - 'STK' app variable
; Output:
;   - CP1: float value
;   - A: rpnObjectType
; Destroys: all
rclStackNN:
    ld hl, stackVarName
    jp rclRpnObject ; CP1=STK[A]

;-----------------------------------------------------------------------------

; Description: Store CP1 to X.
; Destroys: all
StoStackX:
    ld c, stackXIndex
    jr stoStackNN

; Description: Recall X to CP1.
; Output: A=objectType
; Destroys: all
RclStackX:
    ld c, stackXIndex
    jr rclStackNN

;-----------------------------------------------------------------------------

; Description: Store CP1 to Y.
; Destroys: all
StoStackY:
    ld c, stackYIndex
    jr stoStackNN

; Description: Recall Y to CP1.
; Output: A=objectType
; Destroys: all
RclStackY:
    ld c, stackYIndex
    jr rclStackNN

;-----------------------------------------------------------------------------

; Description: Store CP1 to Z.
; Destroys: all
StoStackZ:
    ld c, stackZIndex
    jr stoStackNN

; Description: Recall Z to CP1.
; Output: A=objectType
; Destroys: all
RclStackZ:
    ld c, stackZIndex
    jr rclStackNN

;-----------------------------------------------------------------------------

; Description: Store CP1 to T.
; Destroys: all
StoStackT:
    ld c, stackTIndex
    jr stoStackNN

; Description: Recall T to CP1.
; Output: A=objectType
; Destroys: all
RclStackT:
    ld c, stackTIndex
    jr rclStackNN

;-----------------------------------------------------------------------------

; Description: Store CP1 to L.
; Destroys: all
StoStackL:
    ld c, stackLIndex
    jr stoStackNN

; Description: Recall L to CP1.
; Output: A=objectType
; Destroys: all
RclStackL:
    ld c, stackLIndex
    jr rclStackNN

;-----------------------------------------------------------------------------

; Description: Save Y to CP1, X to CP3.
; Destroys: all
RclStackXY:
    call RclStackX
    call cp1ToCp3PageOne
    call RclStackY
    ret

;-----------------------------------------------------------------------------

; Description: Save X to L, directly, without mutating CP1.
; Preserves: CP1
SaveLastX:
    bcall(_PushRpnObject1) ; FPS=[CP1]
    call RclStackX
    call StoStackL
    bcall(_PopRpnObject1) ; FPS=[]; CP1=CP1
    ret

;-----------------------------------------------------------------------------
; Most routines should use these functions to set the results from OP1 and/or
; OP2 to the RPN stack.
;-----------------------------------------------------------------------------

; Description: Replace X with RpnObject in CP1, saving previous X to LastX,
; and setting dirty flag. Works for all RpnObject types.
; Input: CP1:RpnObject
; Preserves: OP1, OP2
ReplaceStackX:
    call validateValidRpnObjectCP1
    call SaveLastX
    call StoStackX
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

; Description: Replace X and Y with RpnObject in CP1, saving previous X to
; LastX, and setting dirty flag. Works for all RpnObject types.
; Input: CP1:RpnObject
; Preserves: OP1, OP2
ReplaceStackXY:
    call validateValidRpnObjectCP1
    call SaveLastX
    call DropStack
    call StoStackX
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
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
ReplaceStackXYWithOP1OP2:
    ; validate OP1 and OP2 before modifying X and Y
    call validateValidRealOP1
    call op1ExOp2PageOne
    call validateValidRealOP1
    call op1ExOp2PageOne
    ;
    call SaveLastX
    call StoStackY ; Y = OP1
    call op1ExOp2PageOne
    call StoStackX ; X = OP2
    call op1ExOp2PageOne
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

; Description: Replace X with Real numbers OP1 and OP2 in that order.
; Input: OP1:Real, OP2:Real
; Output:
;   - Y=OP1
;   - X=OP2
;   - LastX=X
; Preserves: OP1, OP2
ReplaceStackXWithOP1OP2:
    ; validate OP1 and OP2 before modifying X and Y
    call validateValidRealOP1
    call op1ExOp2PageOne
    call validateValidRealOP1
    call op1ExOp2PageOne
    ;
    call SaveLastX
    call LiftStackIfEnabled
    call StoStackX
    call op1ExOp2PageOne
    ;
    call LiftStack
    call StoStackX
    call op1ExOp2PageOne
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
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
ReplaceStackXWithCP1CP3:
    ; validate CP1 and CP2 before modifying X and Y
    call validateValidRpnObjectCP1
    call cp1ExCp3PageOne
    call validateValidRpnObjectCP1
    call cp1ExCp3PageOne
    ;
    call SaveLastX
    call StoStackX
    call cp1ExCp3PageOne
    ;
    call LiftStack
    call StoStackX
    call cp1ExCp3PageOne
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------

; Description: Push RpnOjbect in CP1 to the X register. LastX is not
; updated because the previous X is not consumed, and is available as the Y
; register. Works for all RpnObject types.
; Input:
;   - CP1:RpnObject
; Output:
;   - Stack lifted (if the stackLift is enabled)
;   - X=CP1
; Destroys: all
; Preserves: OP1, OP2, LastX
PushToStackX:
    call validateValidRpnObjectCP1
    call LiftStackIfEnabled
    call StoStackX
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

; Description: Push Real numbers OP1 then OP2 onto the stack. LastX is not
; updated because the previous X is not consumed, and is available as the Z
; register.
; Input:
;   - OP1:Real
;   - OP2:Real
; Output:
;   - Stack lifted (if the inputBuf was not an empty string)
;   - Y=OP1
;   - X=OP2
; Destroys: all
; Preserves: OP1, OP2, LastX
PushOp1Op2ToStackXY:
    call validateValidRealOP1
    call op1ExOp2PageOne
    call validateValidRealOP1
    call op1ExOp2PageOne
    ;
    call LiftStackIfEnabled
    call StoStackX
    call op1ExOp2PageOne
    ;
    call LiftStack
    call StoStackX
    call op1ExOp2PageOne
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------

; Description: Recall StackX register to CP1. StackX is consumed, so always
; set rpnFlagsLiftEnabled to enable stack lift. Also save X to LastX.
; Output:
;   - rpnFlagsLiftEnabled=1
;   - CP1=StackX
;   - LastX=StackX
;
; Although this function is conceptually the core mechanism to get the X value
; form the stack into OP1, it is not actually used because the various
; ReplaceXxx() and PushXxx() optimize this away to minimize stack movement.
;
; There are 2 important side effects of this function which must be implemented
; by the various ReplaceXxx() and PushXxx() precisely to emulate the Classi RPN
; system of HP calculators:
;
;   1) the consumption of X causes "stack lift" to be enabled again for
;   subsequent push into X, and
;   2) the consumption of X saves the value into LastX.
;
; PopStackX:
;     call SaveLastX
;     call DropStack
;     set rpnFlagsLiftEnabled, (iy + rpnFlags)
;     ret

;-----------------------------------------------------------------------------

; Description: Check that CP1 is a valid RpnObject type (e.g. Real,
; Complex, Date-related objects). If real or complex, verify validity of number
; using CkValidNum().
; Input: CP1:RpnObject
; Destroys: A, HL
; Throws:
;   - Err:Overflow if exponent overflows
;   - Err:DateType if not an RpnObject
validateValidRpnObjectCP1:
    call getOp1RpnObjectTypePageOne ; A=type; HL=OP1
    cp rpnObjectTypeReal
    jr z, validateValidNumber
    cp rpnObjectTypeComplex
    jr z, validateValidNumber
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
validateValidNumber:
    bcall(_CkValidNum) ; destroys AF, HL
    ret

; Description: Check that OP1 is real.
; Input: CP1:RpnObject
; Destroys: A, HL
; Throws:
;   - Err:NonReal if not real.
;   - Err:Overflow if out of range
validateValidRealOP1:
    call getOp1RpnObjectTypePageOne ; A=type; HL=OP1
    cp rpnObjectTypeReal
    jr nz, validateValidRealErr
    bcall(_CkValidNum) ; dstroys AF, HL
    ret
validateValidRealErr:
    bcall(_ErrNonReal)

;-----------------------------------------------------------------------------
; Stack movement functions.
;-----------------------------------------------------------------------------

; Description: Lift the RPN stack, if rpnFlagsLiftEnabled is set.
; Input: rpnFlagsLiftEnabled
; Output: T=Z; Z=Y; Y=X; X=X; OP1 preserved
; Destroys: all
; Preserves: OP1, OP2
LiftStackIfEnabled:
    bit rpnFlagsLiftEnabled, (iy + rpnFlags)
    jr z, LiftStackEnd
    ; [[fallthrough]]

; Description: Lift the RPN stack unconditionally, copying X to Y.
; Input: none
; Output: stack lifted
; Destroys: all
; Preserves: OP1, OP2
LiftStack:
    bcall(_PushRpnObject1) ; FPS=[CP1]
    call liftStackIntoOp1 ; OP1=lastElement, thrown away
    bcall(_PopRpnObject1) ; FPS=[]; CP1=CP1
LiftStackEnd:
    ; The "disable stack lift" lasts for one attempt. Subsequent stack lifts
    ; should go ahead.
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

; Description: Lift the RPN stack with last element pushed into OP1.
; Input: none
; Output:
;   - stack lifted
;   - last element shifted into OP1
;   - DE=pointer to first element (to which OP1 can be copied to)
;   - stack lift enabled
; Destroys: all, OP1
liftStackIntoOp1:
    ; Calculate moveSize=(numElements-2)*rpnElementSizeOf
    call LenStack ; A=stackLen
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
    ; Mark stack as dirty
    set dirtyFlagsStack, (iy + dirtyFlags)
    ; RPN stack movement cancels existing 'disable stack lift' request.
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------

; Description: Roll the RPN stack up, rotating last element into X.
; Input: none
; Output:
;   - stack rolled up
;   - stack lift enabled
; Destroys: all, OP1, OP2
; Preserves: none
RollUpStack:
    call liftStackIntoOp1 ; OP1=lastElement; DE=pointer to first element
    call moveRpnElementFromOp1 ; X=lastElement
    ret

;-----------------------------------------------------------------------------

; Description: Drop the RPN stack, duplicating the top-most element.
; Input: none
; Output:
;   - stack dropped
;   - OP1 preserved
;   - stack lift enabled
; Destroys: all
; Preserves: OP1, OP2
DropStack:
    bcall(_PushRpnObject1) ; FPS=[CP1]
    call dropStackIntoOp1 ; OP1=X, thrown away
    bcall(_PopRpnObject1) ; FPS=[]; CP1=CP1
    ret

; Description: Drop the RPN stack, shifting the X register into OP1.
; Output:
;   - stack dropped (shifted left)
;   - OP1=X
;   - DE=pointer to last element (to which OP1 can be copied to)
;   - stack lift enabled
dropStackIntoOp1:
    ; Calculate moveSize=(numElements-2)*rpnElementSizeOf
    call LenStack ; A=stackLen
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
    ; Mark stack as dirty
    set dirtyFlagsStack, (iy + dirtyFlags)
    ; RPN stack movement cancels existing 'disable stack lift' request.
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------

; Description: Roll the RPN stack *down*, rotating X into T.
; Input: none
; Output:
;   - stack rolled down
;   - stack lift enabled
; Destroys: all, OP1, OP2
; Preserves: none
RollDownStack:
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
; Output:
;   - X=Y; Y=X
;   - stack lift enabled
; Destroys: all, OP1, OP2
ExchangeStackXY:
    ld b, stackXIndex
    ld c, stackYIndex
    ld hl, stackVarName
    call rpnObjectIndexesToPointers ; DE=pointerX; HL=pointerY; destroys OP1
    ld b, rpnElementSizeOf
    call exchangeLoopPageOne
    ; Movement of RPN stack cancels existing 'disable stack lift' request.
    set dirtyFlagsStack, (iy + dirtyFlags)
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret
