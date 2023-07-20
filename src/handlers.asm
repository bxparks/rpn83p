;-----------------------------------------------------------------------------
; Key code dispatcher and handlers.
;-----------------------------------------------------------------------------

; Function: Handle the keyCode given by A. Append digits. Handle
; DEL, and CLEAR keys.
; Input: A: keyCode from GetKey()
; Output: none
; Destroys: A, B, DE, HL
lookupKey:
    ld hl, keyCodeHandlerTable
    ld b, keyCodeHandlerTableSize
lookupKeyLoop:
    cp a, (hl)
    inc hl
    jr z, lookupKeyMatched
    inc hl
    inc hl
    djnz lookupKeyLoop
    ret
lookupKeyMatched:
    ; jump to the corresponding jump table entry
    ld e, (hl)
    inc hl
    ld d, (hl)
    ex de, hl
    jp (hl) ; the handler excutes a 'ret' statement

;-----------------------------------------------------------------------------

; Function: Append a number character to inputBuf, updating various flags.
; Input:
;   A: character to be appended
; Output:
;   - Carry flag set when append fails.
;   - rpnFlagsEditing set.
;   - inputBufFlagsInputDirty set.
; Destroys: all
handleKeyNumber:
    ; If not in edit mode: lift stack and go into edit mode
    bit rpnFlagsEditing, (iy + rpnFlags)
    jr nz, handleKeyNumberEELen
handleKeyNumberFirstDigit:
    ; Lift the stack, unless disabled.
    push af
    bit rpnFlagsLiftEnabled, (iy + rpnFlags)
    call nz, liftStack
    pop af
    ; Go into editing mode
    call clearInputBuf
    set rpnFlagsEditing, (iy + rpnFlags)
    res rpnFlagsLiftEnabled, (iy + rpnFlags)
handleKeyNumberEELen:
    ; Limit number of exponent digits to 2.
    bit inputBufFlagsEE, (iy + inputBufFlags)
    jr z, handleKeyNumberAppend
    ; Check inputBufEELen, preserve the character in A.
    ld b, a
    ld a, (inputBufEELen)
    cp inputBufEELenMax
    ld a, b
    ret nc ; prevent more than 2 exponent digits
    ; Try to append. Check for buffer full before incrementing counter.
    call appendInputBuf
    ret c ; return if buffer full
    ld hl, inputBufEELen
    inc (hl)
    ret
handleKeyNumberAppend:
    ; Unconditionally append character in A.
    jp appendInputBuf

; Function: Append '0' to inputBuf.
; See handleKeyNumber()
handleKey0:
    ld a, '0'
    jr handleKeyNumber

; Function: Append '1' to inputBuf.
; See handleKeyNumber()
handleKey1:
    ld a, '1'
    jr handleKeyNumber

; Function: Append '2' to inputBuf.
; See handleKeyNumber()
handleKey2:
    ld a, '2'
    jr handleKeyNumber

; Function: Append '3' to inputBuf.
; See handleKeyNumber()
handleKey3:
    ld a, '3'
    jr handleKeyNumber

; Function: Append '4' to inputBuf.
; See handleKeyNumber()
handleKey4:
    ld a, '4'
    jr handleKeyNumber

; Function: Append '5' to inputBuf.
; See handleKeyNumber()
handleKey5:
    ld a, '5'
    jr handleKeyNumber

; Function: Append '6' to inputBuf.
; See handleKeyNumber()
handleKey6:
    ld a, '6'
    jr handleKeyNumber

; Function: Append '7' to inputBuf.
; See handleKeyNumber()
handleKey7:
    ld a, '7'
    jr handleKeyNumber

; Function: Append '8' to inputBuf.
; See handleKeyNumber()
handleKey8:
    ld a, '8'
    jr handleKeyNumber

; Function: Append '9' to inputBuf.
; See handleKeyNumber()
handleKey9:
    ld a, '9'
    jr handleKeyNumber

; Function: Append a '.' if not already entered.
; Input: none
; Output: (iy+inputBufFlags) DecPnt set
; Destroys: A, DE, HL
handleKeyDecPnt:
    ; Do nothing if a decimal point already exists.
    bit inputBufFlagsDecPnt, (iy + inputBufFlags)
    ret nz
    ; Also do nothing if 'E' exists. Exponents cannot have a decimal point.
    bit inputBufFlagsEE, (iy + inputBufFlags)
    ret nz
    ; try insert '.'
    ld a, '.'
    call handleKeyNumber
    ret c ; If Carry: append failed so return without setting the DecPnt flag
    set inputBufFlagsDecPnt, (iy + inputBufFlags)
    ret

; Description: Handle the EE for scientific notation. The 'EE' is mapped to
; 2ND-COMMA by default on the calculator. For faster entry, we map the COMMA
; key (withouth 2ND) to be EE as well.
; Input: none
; Output: (inputBufEEPos), (inputBufFlagsEE, iy+inputBufFlags)
; Destroys: A, HL
handleKeyEE:
    ; do nothing if EE already exists
    bit inputBufFlagsEE, (iy + inputBufFlags)
    ret nz
    ; try insert 'E'
    ld a, Lexponent
    call handleKeyNumber
    ret c ; If Carry: append failed so return without setting the EE flag
    ; save the EE+1 position
    ld a, (inputBuf) ; position after the 'E'
    ld (inputBufEEPos), a
    ; set the EE Len to 0
    xor a
    ld (inputBufEELen), a
    ; set flag to indicate presence of EE
    set inputBufFlagsEE, (iy + inputBufFlags)
    ret

;-----------------------------------------------------------------------------

; Function: Delete the last character of inputBuf.
;   - If the deleted char was a '.', reset the decimal point flag.
;   - If the deleted char was a '-', reset the negative flag.
; Input: none
; Output: (iy+inputBufFlags) updated
; Destroys: A, DE, HL
handleKeyDel:
    set rpnFlagsEditing, (iy + rpnFlags)
    set inputBufFlagsInputDirty, (iy + inputBufFlags)

    ld hl, inputBuf
    ld a, (hl) ; A = inputBufSize
    or a
    ret z ; do nothing if buffer empty

    ; shorten string by one
    ld e, a ; E = inputBufSize
    dec a
    ld (hl), a
    ; retrieve the character deleted
    ld d, 0
    add hl, de
    ld a, (hl)
handleKeyDelDecPnt:
    ; reset decimal point flag if the deleted character was a '.'
    cp a, '.'
    jr nz, handleKeyDelMinus
    res inputBufFlagsDecPnt, (iy + inputBufFlags)
    ret
handleKeyDelMinus:
    ; reset negative flag if the deleted character was a '-'
    cp a, signChar
    jr nz, handleKeyDelEE
    res inputBufFlagsManSign, (iy + inputBufFlags)
    ret
handleKeyDelEE:
    ; reset EE flag if the deleted character was an 'E'
    cp Lexponent
    jr nz, handleKeyDelEEDigits
    xor a
    ld (inputBufEEPos), a
    ld (inputBufEELen), a
    res inputBufFlagsEE, (iy + inputBufFlags)
    ret
handleKeyDelEEDigits:
    ; decrement exponent len counter
    bit inputBufFlagsEE, (iy + inputBufFlags)
    jr z, handleKeyDelExit
    cp signChar
    jr z, handleKeyDelExit ; no special handling of '-' in exponent
    ;
    ld hl, inputBufEELen
    ld a, (hl)
    or a
    jr z, handleKeyDelExit ; don't decrement len below 0
    ;
    dec a
    ld (hl), a
handleKeyDelExit:
    ret

;-----------------------------------------------------------------------------

; Function: Clear the input buffer. If the CLEAR key is hit when the input
; buffer is already empty (e.g. hit twice), then trigger a refresh of the
; entire display. This is useful for removing and recovering from rendering
; bugs.
; Input: none
; Output:
;   - A=0
;   - inputBuf cleared
;   - editing mode set
;   - stack lift disabled
;   - mark displayInput dirty
; Destroys: A, HL
handleKeyClear:
    ; Check for non-zero error code.
    ld a, (errorCode)
    or a
    jr z, handleKeyClearNormal
handleKeyClearErrorCode:
    ; Clear the error code if non-zero
    xor a
    jp setErrorCode
handleKeyClearNormal:
    ; Check if editing and inputBuf is empty.
    bit rpnFlagsEditing, (iy + rpnFlags)
    jr z, handleKeyClearHitOnce
    ld a, (inputBuf)
    or a
    jr nz, handleKeyClearHitOnce
handleKeyClearHitTwice:
    ; Trigger refresh of the entire display, to remove any artifacts from buggy
    ; display code.
    set rpnFlagsMenuDirty, (iy + rpnFlags)
    set rpnFlagsStackDirty, (iy + rpnFlags)
    set rpnFlagsErrorDirty, (iy + rpnFlags)
    set rpnFlagsStatusDirty, (iy + rpnFlags)
handleKeyClearHitOnce:
    call clearInputBuf
    set rpnFlagsEditing, (iy + rpnFlags)
    res rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------

; Function: Handle (-) change sign. If in edit mode, change the sign in the
; inputBuf. Otherwise, change the sign of the X register. If the EE symbol
; exists, change the sign of the exponent instead of the mantissa.
; Input: none
; Output: (inputBuf), X
; Destroys: all, OP1
handleKeyChs:
    bit rpnFlagsEditing, (iy + rpnFlags)
    jr nz, handleKeyChsInputBuf
handleKeyChsX:
    ; CHS of X register
    call rclX
    bcall(_InvOP1S)
    call stoX
    ret
handleKeyChsInputBuf:
    set inputBufFlagsInputDirty, (iy + inputBufFlags)
    ; Check if EE symbol exists
    ld hl, inputBuf
    ld b, inputBufMax
    ld a, (inputBufEEPos)
    or a
    jr z, handleKeyChsMan
handleKeyChsExp:
    call flipInputBufSign
    jr c, handleKeyChsExpResetSign
    set inputBufFlagsExpSign, (iy + inputBufFlags)
    ret
handleKeyChsExpResetSign:
    res inputBufFlagsExpSign, (iy + inputBufFlags)
    ret
handleKeyChsMan:
    call flipInputBufSign
    jr c, handleKeyChsManResetSign
    set inputBufFlagsManSign, (iy + inputBufFlags)
    ret
handleKeyChsManResetSign:
    res inputBufFlagsManSign, (iy + inputBufFlags)
    ret

; Description: Add or remove the '-' char at position A of the Pascal string at
; HL, with maximum length B.
; Input:
;   A: inputBuf offset where the sign ought to be
;   HL: pointer to Pascal string
;   B: max size of Pasal string
; Output:
;   (HL): updated with '-' removed or added
;   Carry:
;       - Set if positive (including if '-' could not be added due to size)
;       - Clear if negative
; Destroys:
;   A, BC, DE, HL
flipInputBufSign:
    ld c, (hl) ; size of string
    cp c
    jr c, flipInputBufSignInside ; If A < inputBufSize: interior position
    ld a, c ; set A = inputBufSize, just in case
    jr flipInputBufSignAdd
flipInputBufSignInside:
    ; Check for the '-' and flip it.
    push hl
    inc hl ; skip size byte
    ld e, a
    ld d, 0
    add hl, de
    ld a, (hl)
    cp signChar
    pop hl
    ld a, e ; A=sign position
    jr nz, flipInputBufSignAdd
flipInputBufSignRemove:
    ; Remove existing '-' sign
    call deleteAtPos
    scf ; set Carry to indicate positive
    ret
flipInputBufSignAdd:
    ; Add '-' sign.
    call insertAtPos
    ret c ; Return if Carry is set, indicating insert '-' failed
    ; Set newly created empty slot to '-'
    ld a, signChar
    ld (hl), a
    or a ; clear Carry to indicate negative
    ret

;-----------------------------------------------------------------------------

; Function: Handle the ENTER key.
; Input: none
; Output:
; Destroys: all, OP1, OP2, OP4
handleKeyEnter:
    call closeInputBuf
    call liftStack
    res rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

; closeInputBuf() -> None
; Description: If currently in edit mode, close the input buffer by parsing the
; input, enable stack lift, then copying the float value into X. If not in edit
; mode, no need to parse the inputBuf, but we still have to enable stack lift
; because the previous keyCode could have been ENTER which disabled it.
; Input: none
; Output:
; Destroys: all, OP1, OP2, OP4
closeInputBuf:
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    bit rpnFlagsEditing, (iy + rpnFlags)
    ret z
    call parseNum
    call stoX
    call clearInputBuf
    res rpnFlagsEditing, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------
; Menu key handlers.
;-----------------------------------------------------------------------------

; Function: Go to the previous menu strip, with stripIndex decreasing upwards.
; Input: none
; Output: (menuStripIndex) decremented, or wrapped around
; Destroys: all
handleKeyUp:
    ld hl, menuCurrentId
    ld a, (hl)
    inc hl
    ld b, (hl) ; menuStripIndex
    call getMenuNode
    inc hl
    inc hl
    inc hl
    ld c, (hl) ; numStrips

    ; Check for 1. TODO: Check for 0, but that should never happen.
    ld a, c
    cp 1
    ret z

    ; --(menuStripIndex) mod numStrips
    ld a, (menuStripIndex)
    or a
    jr nz, handleKeyUpContinue
    ld a, c
handleKeyUpContinue:
    dec a
    ld (menuStripIndex), a

    set rpnFlagsMenuDirty, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------

; Function: Go to the next menu strip, with stripIndex increasing downwards.
; Input: none
; Output: (menuStripIndex) incremented mod numStrips
; Destroys: all
handleKeyDown:
    ld hl, menuCurrentId
    ld a, (hl)
    inc hl
    ld b, (hl) ; menuStripIndex
    call getMenuNode
    inc hl
    inc hl
    inc hl
    ld c, (hl) ; numStrips

    ; Check for 1. TODO: Check for 0, but that should never happen.
    ld a, c
    cp 1
    ret z

    ; ++(menuStripIndex) mod numStrips
    ld a, (menuStripIndex)
    inc a
    cp c
    jr c, handleKeyDownContinue
    xor a
handleKeyDownContinue:
    ld (menuStripIndex), a

    set rpnFlagsMenuDirty, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------

; Description: Go back up the menu hierarchy to the parent menu group. If
; already at the rootMenu, and the stripIndex is not 0, then reset the
; stripIndex to 0 so that we return to the default, top-level view of the menu
; hierarchy.
; Input: (menuCurrentId)
; Output: (menuCurrentId) at parentId, (menuStripIndex) at strip of the current
; menu group
; Destroys: all
handleKeyMenuBack:
    ld hl, menuCurrentId
    ld a, (hl)
    ; Check if already at rootGroup
    cp mRootId
    jr nz, handleKeyMenuBackToParent

    ; If already at rootId, go to menuStrip0 if not already there.
    inc hl
    ld a, (hl) ; menuStripIndex
    or a
    ret z
    xor a ; set stripIndex to 0
    jr handleKeyMenuBackStripSave

handleKeyMenuBackToParent:
    ; Set menuCurrentId = child.parentId
    ld c, a ; C=childId (saved)
    call getMenuNode
    inc hl
    ld a, (hl) ; A=parentId
    ld (menuCurrentId), a

    ; Get the numStrips and stripBeginId of the parent.
    inc hl
    inc hl
    ld d, (hl) ; numStrips
    inc hl
    ld a, (hl) ; stripBeginId

    ; Deduce the stripIndex from the childId above. The `stripIndex =
    ; int((childId - stripBeginId)/5)` but the Z80 does not have a divison
    ; instruction so we use a loop that increments an `index` in increments of
    ; 5 to determine the corresponding stripIndex.
    ;
    ; The complication is that we want to evaluate `(childId < nodeId)` but the
    ; Z80 instruction can only increment the A register, so we have to store
    ; the `nodeId` in A and the `childId` in C. Which forces us to reverse the
    ; comparison. But checking for NC (no carry) is equivalent to a '>='
    ; instead of a '<', so we are forced to start at `5-1` instead of `5`. I
    ; hope my future self will understand this explanation.
    add a, 4 ; nodeId = stripBeginId + 4
    ld b, d ; B (DJNZ counter) = numStrips
handleKeyMenuBackLoop:
    cp c ; nodeId - childId
    jr nc, handleKeyMenuBackStripFound ; nodeId >= childId
    add a, 5 ; nodeId += 5
    djnz handleKeyMenuBackLoop
    ; We should never fall off the end of the loop, but if we do, set the
    ; stripIndex to 0.
    xor a
    jr handleKeyMenuBackStripSave
handleKeyMenuBackStripFound:
    ld a, d ; numStrips
    sub b ; stripIndex = numStrips - B
handleKeyMenuBackStripSave:
    ld (menuStripIndex), a
    set rpnFlagsMenuDirty, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------

; handleKeyMenu0() -> None
; Description: Handle menu key 0 (left most).
; Input: none
; Destroys: all
handleKeyMenu0:
    ld a, 0
    jr handleKeyMenuA

; handleKeyMenu1() -> None
; Description: Handle menu key 1 (2nd from left).
; Input: none
; Destroys: all
handleKeyMenu1:
    ld a, 1
    jr handleKeyMenua

; handleKeyMenu2() -> None
; Description: Handle menu key 0 (middle).
; Input: none
; Destroys: all
handleKeyMenu2:
    ld a, 2
    jr handleKeyMenuA

; handleKeyMenu3() -> None
; Description: Handle menu key 0 (2nd from right).
; Input: none
; Destroys: all
handleKeyMenu3:
    ld a, 3
    jr handleKeyMenuA

; handleKeyMenu4() -> None
; Description: Handle menu key 0 (right most).
; Input: none
; Destroys: all
handleKeyMenu4:
    ld a, 4
    ; [[fallthrough]]

; handleKeyMenuA(A) -> None
;
; Description: Dispatch to the handler specified by the menu node at the menu
; button indexed by A (0: left most, 4: right most).
; Destroys: all
handleKeyMenuA:
    ld c, a
    call getCurrentMenuStripBeginId
    add a, c ; menu node ids are sequential starting with beginId
    ; get menu node corresponding to pressed menu key
    call getMenuNode
    push hl ; save pointer to MenuNode
    ; load and jump to the mXxxHandler
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    ld e, (hl)
    inc hl
    ld d, (hl) ; DE=mXxxHandler of the current node
    ex de, hl ; HL=mXxxHandler
    ex (sp), hl
    ret ; jump to mXxxHandler(HL=MenuNode)

;-----------------------------------------------------------------------------
; Arithmetic functions.
;-----------------------------------------------------------------------------

; Function: Handle the Add key.
; Input: inputBuf
; Output:
; Destroys: all, OP1, OP2, OP4
handleKeyAdd:
    call closeInputBuf
    call rclX
    bcall(_OP1ToOP2)
    call rclY
    bcall(_FPAdd) ; Y + X
    call dropStack ; drop stack only if no exception
    call stoX
    ret

; Function: Handle the Sub key.
; Input: inputBuf
; Output:
; Destroys: all, OP1, OP2, OP4
handleKeySub:
    call closeInputBuf
    call rclX
    bcall(_OP1ToOP2)
    call rclY
    bcall(_FPSub) ; Y - X
    call dropStack ; drop stack only if no exception
    call stoX
    ret

; Function: Handle the Mul key.
; Input: inputBuf
; Output:
; Destroys: all, OP1, OP2, OP4, OP5
handleKeyMul:
    call closeInputBuf
    call rclX
    bcall(_OP1ToOP2)
    call rclY
    bcall(_FPMult) ; Y * X
    call dropStack ; drop stack only if no exception
    call stoX
    ret

; Function: Handle the Div key.
; Input: inputBuf
; Output:
; Destroys: all, OP1, OP2, OP4
handleKeyDiv:
    call closeInputBuf
    call rclX
    bcall(_OP1ToOP2)
    call rclY
    bcall(_FPDiv) ; Y / X
    call dropStack ; drop stack only if no exception
    call stoX
    ret

;-----------------------------------------------------------------------------
; Constants: pi and e. There does not seem to be an existing bcall() that loads
; these constants. It's almost unbelievable, because these constants are shown
; on the calculator keyboard, and there are dozens of bcall() functions to load
; other values such as 0, 1, 2, 3 but I cannot find the bcall() to load these
; constants.
;-----------------------------------------------------------------------------

handleKeyPi:
    call closeInputBuf
    ld hl, constPi
    bcall(_Mov9ToOP1)
    call liftStack
    call stoX
    ret

handleKeyEuler:
    call closeInputBuf
    ld hl, constEuler
    bcall(_Mov9ToOP1)
    call liftStack
    call stoX
    ret

constPi:
    .db $00, $80, $31, $41, $59, $26, $53, $58, $98 ; 3.1415926535897(9323)

constEuler:
    .db $00, $80, $27, $18, $28, $18, $28, $45, $94 ; 2.7182818284594(0452)

constTen:
    .db $00, $81, $10, $00, $00, $00, $00, $00, $00 ; 10

constHundred:
    .db $00, $82, $10, $00, $00, $00, $00, $00, $00 ; 100

constThousand:
    .db $00, $83, $10, $00, $00, $00, $00, $00, $00 ; 1000

;-----------------------------------------------------------------------------
; Alegbraic functions.
;-----------------------------------------------------------------------------

; Function: y^x
handleKeyExpon:
    call closeInputBuf
    call rclX
    bcall(_OP1ToOP2)
    call rclY
    bcall(_YToX)
    call dropStack ; drop stack only if no exception
    call stoX
    ret

; Function: 1/x
handleKeyInv:
    call closeInputBuf
    call rclX
    bcall(_FPRecip)
    call stoX
    ret

; Function: x^2
handleKeySquare:
    call closeInputBuf
    call rclX
    bcall(_FPSquare)
    call stoX
    ret

; Function: sqrt(x)
handleKeySqrt:
    call closeInputBuf
    call rclX
    bcall(_SqRoot)
    call stoX
    ret

;-----------------------------------------------------------------------------
; Stack operations
;-----------------------------------------------------------------------------

handleKeyRotDown:
    call closeInputBuf
    call rotDownStack
    ret

handleKeyRotUp:
    call closeInputBuf
    call rotUpStack
    ret

handleKeyExchangeXY:
    call closeInputBuf
    call exchangeXYStack
    ret

;-----------------------------------------------------------------------------
; Transcendentals
;-----------------------------------------------------------------------------

handleKeyLog:
    call closeInputBuf
    call rclX
    bcall(_LogX)
    call stoX
    ret

handleKeyALog:
    call closeInputBuf
    call rclX
    bcall(_TenX)
    call stoX
    ret

handleKeyLn:
    call closeInputBuf
    call rclX
    bcall(_LnX)
    call stoX
    ret

handleKeyExp:
    call closeInputBuf
    call rclX
    bcall(_EToX)
    call stoX
    ret

;-----------------------------------------------------------------------------
; Menu handlers.
; Input:
;   HL: pointer to MenuNode that was activated
;   A: menu button index (0 - 4)
;-----------------------------------------------------------------------------

mNullHandler: ; do nothing
    ret

; Description: General handler for menu nodes of type "MenuGroup". Selecting
; this should cause the menuCurrentId to be set to this item, and the
; menuStripIndex to be set to 0
; Input:
;   HL: pointer to the selected MenuNode
;   A: the selected menuId
; Output: (menuCurrentId) and (menuStripIndex) updated
; Destroys: A
mGroupHandler:
    ld (menuCurrentId), a
    xor a
    ld (menuStripIndex), a
    set rpnFlagsMenuDirty, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------

; mCubeHandler(X) -> X^3
; Description: Calculate X^3.
mCubeHandler:
    call closeInputBuf
    call rclX
    bcall(_Cube)
    call stoX
    ret

; mCubeRootHandler(X) -> X^(1/3)
; Description: Calculate the cubic root of X. The SDK documentation has the OP1
; and OP2 flipped.
mCubeRootHandler:
    call closeInputBuf
    call rclX
    bcall(_OP1ToOP2)
    bcall(_OP1Set3)
    bcall(_XRootY)
    call stoX
    ret

; mAtan2Handler(Y, X) -> atan2(Y + Xi)
;
; Description: Calculate the angle of the (Y, X) number in complex plane.
; Use bcall(_RToP) instead of bcall(_ATan2) because ATan2 does not seem produce
; the correct results. There must be something wrong with the documentation, or
; it is buggy and no one has bothered to fix it because I don't think this
; function is exposed to the user through the normal TI-OS.
;
; The real part (i.e. x-axis) is assumed to be entered first, then the
; imaginary part (i.e. y-axis). They becomes stored in the RPN stack variables
; with X and Y flipped, which is bit confusing.
mAtan2Handler:
    call closeInputBuf
    call rclX ; imaginary
    bcall(_OP1ToOP2)
    call rclY ; OP1=Y (real), OP2=X (imaginary)
    bcall(_RToP) ; complex to polar
    call dropStack
    bcall(_OP2ToOP1) ; OP2 contains the angle with range of (-pi, pi]
    call stoX
    ret

; mPercentHandler(Y, X) -> (Y, Y*(X/100))
; Description: Calculate the X percent of Y.
mPercentHandler:
    call closeInputBuf
    call rclX
    ld hl, constHundred
    bcall(_Mov9ToOP2)
    bcall(_FPDiv)
    bcall(_OP1ToOP2)
    call rclY
    bcall(_FPMult)
    call stoX
    ret

;-----------------------------------------------------------------------------

; mFactorialHandler(X) -> X!
; Description: Calculate the factorial of X.
mFactorialHandler:
    call closeInputBuf
    call rclX
    bcall(_Factorial)
    bcall(_CkValidNum)
    call stoX
    ret

; mRandomHandler() -> rand()
; Description: Calculate the factorial of X.
mRandomHandler:
    call closeInputBuf
    bcall(_Random)
    call liftStack
    call stoX
    ret

; mRandomSeedHandler(X) -> None
; Description: Set X as the Random() seed.
mRandomSeedHandler:
    call closeInputBuf
    call rclX
    bcall(_StoRand)
    ret
