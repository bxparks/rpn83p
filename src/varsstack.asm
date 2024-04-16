;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; RPN Stack implemented using an appVar named RPN83STK.
;-----------------------------------------------------------------------------

; RPN stack using an ObjectList which has the following structure:
; X, Y, Z, T, LastX.
stackSize equ 5
stackXIndex equ 0 ; X
stackYIndex equ 1 ; Y
stackZIndex equ 2 ; Z
stackTIndex equ 3 ; T
stackLIndex equ 4 ; LastX

stackVarName:
    .db AppVarObj, "RPN83STK" ; max 8 char, NUL terminated if < 8

;-----------------------------------------------------------------------------

; Description: Initialize the RPN stack using the appVar 'RPN83STK'.
; Output:
;   - STK created and cleared if it doesn't exist
;   - stack lift enabled
; Destroys: all
initStack:
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ld hl, stackVarName
    ld c, stackSize
    jp initRpnObjectList

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
    jp clearRpnObjectList

; Description: Should be called just before existing the app.
closeStack:
    ld hl, stackVarName
    jp closeRpnObjectList

; Description: Return the length of the RPN stack variable.
; Output:
;   - A=length of RPN stack variable
;   - DE:(u8*)=dataPointer
; Destroys: BC, HL
lenStack:
    ld hl, stackVarName
    jp lenRpnObjectList

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
    call checkValid
    call saveLastX
    call stoX
    ret

; Description: Replace X and Y with RpnObject in OP1/OP2, saving previous X to
; LastX, and setting dirty flag. Works for all RpnObject types.
; Input: CP1=OP1/OP2:RpnObject
; Preserves: OP1, OP2
replaceXY:
    call checkValid
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
    call checkValidReal
    call op1ExOp2
    call checkValidReal
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
    call checkValidReal
    call op1ExOp2
    call checkValidReal
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
    call checkValid
    call cp1ExCp3
    call checkValid
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
    call checkValid
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
    call checkValidReal
    call op1ExOp2
    call checkValidReal
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

; Description: Check that OP1/OP2 is a valid RpnObject type (real, complex,
; RpnDate or RpnDateTime). If real or complex, verify validity of number using
; CkValidNum().
; Input: OP1/OP2:RpnObject
; Destroys: A, HL
checkValid: ; TODO: Rename this checkValidObjectCP1()
    ld a, (OP1)
    and $1f
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
    cp rpnObjectTypeOffsetDateTime
    ret z
    cp rpnObjectTypeOffset
    ret z
checkValidNumber:
    bcall(_CkValidNum) ; destroys AF, HL
    ret

; Description: Check that OP1 is real. Throws Err:NonReal if not real.
; Input: OP1/OP2:RpnObject
; Destroys: A, HL
checkValidReal: ; TODO: Rename this checkValidRealOP1()
    ld a, (OP1)
    and $1f
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
; Output: T=Z; Z=Y; Y=X; X=X; OP1 preserved
; Destroys: all
; Preserves: OP1, OP2
; TODO: Make this more efficient by taking advantage of the fact that stack
; registers are contiguous.
liftStack:
    bcall(_PushRpnObject1) ; FPS=[OP1/OP2]
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
    bcall(_PopRpnObject1) ; FPS=[]; OP1/OP2=OP1/OP2
    ret

;-----------------------------------------------------------------------------

; Description: Drop the RPN stack, copying T to Z.
; Input: none
; Output: X=Y; Y=Z; Z=T; T=T; OP1 preserved
; Destroys: all
; Preserves: OP1, OP2
; TODO: Make this more efficient by taking advantage of the fact that stack
; registers are contiguous.
dropStack:
    bcall(_PushRpnObject1) ; FPS=[OP1/OP2]
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
    bcall(_PopRpnObject1) ; FPS=[]; OP1/OP2=OP1/OP2
    ret

;-----------------------------------------------------------------------------

; Description: Roll the RPN stack *down*.
; Input: none
; Output: X=Y; Y=Z; Z=T; T=X
; Destroys: all, OP1, OP2
; Preserves: none
; TODO: Make this more efficient by taking advantage of the fact that stack
; registers are contiguous.
rollDownStack:
    ; save X in FPS
    call rclX
    bcall(_PushRpnObject1) ; FPS=[OP1/OP2]
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
    bcall(_PopRpnObject1) ; FPS=[]; OP1/OP2=OP1/OP2
    call stoT
    ret

;-----------------------------------------------------------------------------

; Description: Roll the RPN stack *up*.
; Input: none
; Output: T=Z; Z=Y; Y=X; X=T
; Destroys: all, OP1, OP2
; Preserves: none
; TODO: Make this more efficient by taking advantage of the fact that stack
; registers are contiguous.
rollUpStack:
    ; save T in FPS
    call rclT
    bcall(_PushRpnObject1) ; FPS=[OP1/OP2]
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
    bcall(_PopRpnObject1) ; FPS=[]; OP1/OP2=OP1/OP2
    call stoX
    ret

;-----------------------------------------------------------------------------

; Description: Exchange X<->Y.
; Input: none
; Output: X=Y; Y=X
; Destroys: all, OP1, OP2
exchangeXYStack:
    ; TODO: Make this a lot faster by directly swapping the memory allocated to
    ; X and Y within the appVar.
    call rclX
    bcall(_PushRpnObject1) ; FPS=[OP1/OP2]
    call rclY
    call stoX
    bcall(_PopRpnObject1) ; FPS=[]; OP1/OP2=OP1/OP2
    call stoY
    ret
