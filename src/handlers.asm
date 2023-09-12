;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;-----------------------------------------------------------------------------

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
    jp jumpDE

;-----------------------------------------------------------------------------

; Description: Handle digit input in arg editing mode.
; Input:
;   A: character to be appended
handleKeyNumberArg:
    call appendArgBuf
    ld a, (argBuf) ; A = length of argBuf string
    cp a, argBufSizeMax
    ret nz ; if only 1 digit entered, just return

    ; On the 2nd digit, invoke auto ENTER to execute the pending command. But
    ; before we do that, we refresh display to allow the user to see the 2nd
    ; digit briefly. On a real HP-42S, the calculator seems to update the
    ; display on the *press* of the digit, then trigger the command on the
    ; *release* of the button, which allows the calculator to show the 2nd
    ; digit to the user. The TI-OS GetKey() function used by this app does not
    ; give us that level of control over the press and release events of a
    ; button. Hence the need for this hack.
    set dirtyFlagsInput, (iy + dirtyFlags)
    call displayStack
    jp handleKeyEnterArg

; Function: Append a number character to inputBuf or argBuf, updating various
; flags.
; Input:
;   A: character to be appended
;   rpnFlagsArgMode: whether we are in Command Arg mode
;   rpnFlagsEditing: whether we are already in Edit mode
; Output:
;   - CF set when append fails
;   - rpnFlagsEditing set
;   - rpnFlagsLiftEnabled set
;   - dirtyFlagsInput set
; Destroys: all
handleKeyNumber:
    ; Check if in arg editing mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    jr nz, handleKeyNumberArg
    ; If not in input editing mode: lift stack and go into edit mode
    bit rpnFlagsEditing, (iy + rpnFlags)
    jr nz, handleKeyNumberCheckAppend
handleKeyNumberFirstDigit:
    ; Lift the stack, unless disabled.
    push af ; preserve A=char to append
    call liftStackIfEnabled
    pop af
    ; Go into editing mode. Re-enable stack lift so that if the next keystroke
    ; is a PI, Euler, or some other function that takes no arguments and
    ; produces a number, the stack is lifted again.
    call clearInputBuf
    set rpnFlagsEditing, (iy + rpnFlags)
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
handleKeyNumberCheckAppend:
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

;-----------------------------------------------------------------------------

; Function: Append '0' to inputBuf.
handleKey0:
    ld a, '0'
    jr handleKeyNumber

; Function: Append '1' to inputBuf.
handleKey1:
    ld a, '1'
    jr handleKeyNumber

; Function: Append '2' to inputBuf.
handleKey2:
    call checkBase8Or10Or16
    ret nz
    ld a, '2'
    jr handleKeyNumber

; Function: Append '3' to inputBuf.
handleKey3:
    call checkBase8Or10Or16
    ret nz
    ld a, '3'
    jr handleKeyNumber

; Function: Append '4' to inputBuf.
handleKey4:
    call checkBase8Or10Or16
    ret nz
    ld a, '4'
    jr handleKeyNumber

; Function: Append '5' to inputBuf.
handleKey5:
    call checkBase8Or10Or16
    ret nz
    ld a, '5'
    jr handleKeyNumber

; Function: Append '6' to inputBuf.
handleKey6:
    call checkBase8Or10Or16
    ret nz
    ld a, '6'
    jr handleKeyNumber

; Function: Append '7' to inputBuf.
handleKey7:
    call checkBase8Or10Or16
    ret nz
    ld a, '7'
    jr handleKeyNumber

; Function: Append '8' to inputBuf.
handleKey8:
    call checkBase10Or16
    ret nz
    ld a, '8'
    jr handleKeyNumber

; Function: Append '9' to inputBuf.
handleKey9:
    call checkBase10Or16
    ret nz
    ld a, '9'
    jp handleKeyNumber

; Function: Append 'A' to inputBuf.
handleKeyA:
    call checkBase16
    ret nz
    ld a, 'A'
    jp handleKeyNumber

; Function: Append 'B' to inputBuf.
handleKeyB:
    call checkBase16
    ret nz
    ld a, 'B'
    jp handleKeyNumber

; Function: Append 'C' to inputBuf.
handleKeyC:
    call checkBase16
    ret nz
    ld a, 'C'
    jp handleKeyNumber

; Function: Append 'D' to inputBuf.
handleKeyD:
    call checkBase16
    ret nz
    ld a, 'D'
    jp handleKeyNumber

; Function: Append 'E' to inputBuf.
handleKeyE:
    call checkBase16
    ret nz
    ld a, 'E'
    jp handleKeyNumber

; Function: Append 'F' to inputBuf.
handleKeyF:
    call checkBase16
    ret nz
    ld a, 'F'
    jp handleKeyNumber

; Description: Return ZF=1 if BaseMode is 8, 10, or 16.
checkBase8Or10Or16:
    ld a, (baseMode)
    cp 8
    ret z
    cp 10
    ret z
    cp 16
    ret

; Description: Return ZF=1 if BaseMode is 10, or 16.
checkBase10Or16:
    ld a, (baseMode)
    cp 10
    ret z
    cp 16
    ret

; Description: Return ZF=1 if BaseMode is 16.
checkBase16:
    ld a, (baseMode)
    cp 16
    ret

; Description: Return ZF=1 if BaseMode is 10.
checkBase10:
    ld a, (baseMode)
    cp 10
    ret

; Function: Append a '.' if not already entered.
; Input: none
; Output: (iy+inputBufFlags) DecPnt set
; Destroys: A, DE, HL
handleKeyDecPnt:
    ; DecPnt is supported only in Base 10.
    call checkBase10
    ret nz
    ; Do nothing if in arg editing mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    ; Do nothing if a decimal point already exists.
    bit inputBufFlagsDecPnt, (iy + inputBufFlags)
    ret nz
    ; Also do nothing if 'E' exists. Exponents cannot have a decimal point.
    bit inputBufFlagsEE, (iy + inputBufFlags)
    ret nz
    ; try insert '.'
    ld a, '.'
    call handleKeyNumber
    ret c ; If CF: append failed so return without setting the DecPnt flag
    set inputBufFlagsDecPnt, (iy + inputBufFlags)
    ret

; Description: Handle the EE for scientific notation. The 'EE' is mapped to
; 2ND-COMMA by default on the calculator. For faster entry, we map the COMMA
; key (withouth 2ND) to be EE as well.
; Input: none
; Output: (inputBufEEPos), (inputBufFlagsEE, iy+inputBufFlags)
; Destroys: A, HL
handleKeyEE:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    ; EE is supported only in Base 10.
    call checkBase10
    ret nz
    ; do nothing if EE already exists
    bit inputBufFlagsEE, (iy + inputBufFlags)
    ret nz
    ; try insert 'E'
    ld a, Lexponent
    call handleKeyNumber
    ret c ; If CF: append failed so return without setting the EE flag
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
    ; Check if in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    jr nz, handleKeyDelArg
    ; Check if non-zero error code is currently displayed. The handlerCode was
    ; already set to 0 before this was called, so simply returning will clear
    ; the previous errorCode.
    ld a, (errorCode)
    or a
    ret nz
handleKeyDelNormal:
    set rpnFlagsEditing, (iy + rpnFlags)
    set dirtyFlagsInput, (iy + dirtyFlags)

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
    jr nz, handleKeyDelEE
    res inputBufFlagsDecPnt, (iy + inputBufFlags)
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

; Description: Handle the DEL key when in command arg mode by removing the last
; character in the argBuf.
handleKeyDelArg:
    set dirtyFlagsInput, (iy + dirtyFlags)
    ld hl, argBuf
    ld a, (hl) ; A = inputBufSize
    or a
    ret z ; do nothing if buffer empty
    dec (hl)
    ret

;-----------------------------------------------------------------------------

; Description: Handle CLEAR key in arg editing mode.
handleKeyClearArg:
    call clearArgBuf
    res rpnFlagsEditing, (iy + rpnFlags)
    set dirtyFlagsStack, (iy + dirtyFlags)
    ret

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
    ; Check if in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    jr nz, handleKeyClearArg
    ; Check if non-zero error code is currently displayed. The handlerCode was
    ; already set to 0 before this was called, so simply returning will clear
    ; the previous errorCode.
    ld a, (errorCode)
    or a
    ret nz
handleKeyClearNormal:
    ; Check if editing and inputBuf is empty.
    bit rpnFlagsEditing, (iy + rpnFlags)
    jr z, handleKeyClearSimple
    ld a, (inputBuf)
    or a
    jr nz, handleKeyClearSimple
handleKeyClearWhileClear:
    ; If CLEAR is hit while the inputBuffer is already clear, then force a
    ; complete refresh of the entire display. Useful for removing any artifacts
    ; from buggy display code.
    call initDisplay
handleKeyClearSimple:
    ; Clear the input buffer, and set various flags.
    call clearInputBuf
    set rpnFlagsEditing, (iy + rpnFlags)
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------

; Function: Handle (-) change sign. If in edit mode, change the sign in the
; inputBuf. Otherwise, change the sign of the X register. If the EE symbol
; exists, change the sign of the exponent instead of the mantissa.
; Input: none
; Output: (inputBuf), X
; Destroys: all, OP1
handleKeyChs:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    call checkBase10
    ret nz ; use NEG function for bases other than 10
    bit rpnFlagsEditing, (iy + rpnFlags)
    jr nz, handleKeyChsInputBuf
handleKeyChsX:
    ; CHS of X register
    call rclX
    bcall(_InvOP1S)
    call stoX
    ret
handleKeyChsInputBuf:
    set dirtyFlagsInput, (iy + dirtyFlags)
    ; Change sign of Mantissa or Exponent.
    ld hl, inputBuf
    ld b, inputBufMax
    ld a, (inputBufEEPos) ; offset to EE digit, or 0 if 'E' does not exist
    ; [[fallthrough]]

; Description: Add or remove the '-' char at position A of the Pascal string at
; HL, with maximum length B.
; Input:
;   A: inputBuf offset where the sign ought to be
;   HL: pointer to Pascal string
;   B: max size of Pasal string
; Output:
;   (HL): updated with '-' removed or added
;   CF:
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
    scf ; set CF to indicate positive
    ret
flipInputBufSignAdd:
    ; Add '-' sign.
    call insertAtPos
    ret c ; Return if CF is set, indicating insert '-' failed
    ; Set newly created empty slot to '-'
    ld a, signChar
    ld (hl), a
    or a ; clear CF to indicate negative
    ret

;-----------------------------------------------------------------------------

; Function: Handle the ENTER key.
; Input: none
; Output:
; Destroys: all, OP1, OP2, OP4
handleKeyEnter:
    bit rpnFlagsArgMode, (iy + rpnFlags)
    jr nz, handleKeyEnterArg
    call closeInputBuf
    call liftStack ; always lift the stack
    res rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

; Description: Handle the ENTER key for arg input.
; Input: argBuf
; Output: argValue
; Destroys: A, B, C, HL
handleKeyEnterArg:
    set dirtyFlagsInput, (iy + dirtyFlags)
    res rpnFlagsArgMode, (iy + rpnFlags)
    call parseArgBuf
    ld (argValue), a
    ld hl, (argHandler)
    jp (hl)

;-----------------------------------------------------------------------------
; Menu key handlers.
;-----------------------------------------------------------------------------

; Function: Go to the previous menu row, with rowIndex decreasing upwards.
; Input: none
; Output: (menuRowIndex) decremented, or wrapped around
; Destroys: all
handleKeyUp:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz

    ld hl, menuGroupId
    ld a, (hl) ; A = menuGroupId
    inc hl
    ld b, (hl) ; B = menuRowIndex
    call getMenuNode ; HL = pointer to MenuNode
    inc hl
    inc hl
    inc hl
    ld c, (hl) ; C = numRows

    ; Check for 1. TODO: Check for 0, but that should never happen.
    ld a, c
    cp 1
    ret z

    ; (menuRowIndex-1) mod numRows
    ld a, (menuRowIndex)
    or a
    jr nz, handleKeyUpContinue
    ld a, c ; A = numRows
handleKeyUpContinue:
    dec a
    ld (menuRowIndex), a

    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

;-----------------------------------------------------------------------------

; Function: Go to the next menu row, with rowIndex increasing downwards.
; Input: none
; Output: (menuRowIndex) incremented mod numRows
; Destroys: all
handleKeyDown:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz

    ld hl, menuGroupId
    ld a, (hl)
    inc hl
    ld b, (hl) ; menuRowIndex
    call getMenuNode
    inc hl
    inc hl
    inc hl
    ld c, (hl) ; numRows

    ; Check for 1. TODO: Check for 0, but that should never happen.
    ld a, c
    cp 1
    ret z

    ; (menuRowIndex+1) mod numRows
    ld a, (menuRowIndex)
    inc a
    cp c
    jr c, handleKeyDownContinue
    xor a
handleKeyDownContinue:
    ld (menuRowIndex), a

    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

;-----------------------------------------------------------------------------

; Description: Go back up the menu hierarchy to the parent menu group. If
; already at the rootMenu, and the rowIndex is not 0, then reset the
; rowIndex to 0 so that we return to the default, top-level view of the menu
; hierarchy.
; Input: (menuGroupId), the current (child) menu group
; Output:
;   - (menuGroupId) at parentId
;   - (menuRowIndex) of the input (child) menu group
; Destroys: all
handleKeyMenuBack:
    ; Clear the command arg mode if already in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    jp nz, handleKeyClearArg

    ld hl, menuGroupId
    ld a, (hl) ; A = menuGroupId
    ; Check if already at rootGroup
    cp mRootId
    jr nz, handleKeyMenuBackToParent

    ; If already at rootId, go to menuRow0 if not already there.
    inc hl
    ld a, (hl) ; menuRowIndex
    or a
    ret z
    xor a ; set rowIndex to 0, set dirty bit
    jr handleKeyMenuBackRowSave

handleKeyMenuBackToParent:
    ; Set menuGroupId = child.parentId
    ld c, a ; C=menuGroupId=childId (saved)
    call getMenuNode ; get current (child) node
    inc hl
    ld a, (hl) ; A=parentId
    ld (menuGroupId), a

    ; Get numRows and rowBeginId of the parent.
    call getMenuNode ; get parentNode
    inc hl
    inc hl
    inc hl
    ld d, (hl) ; D=parent.numRows
    inc hl
    ld a, (hl) ; A=parent.rowBeginId

    ; Deduce the parent's rowIndex which matches the childId.
    call deduceRowIndex

handleKeyMenuBackRowSave:
    ld (menuRowIndex), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Deduce the rowIndex from the childId above. The `rowIndex =
; int((childId - rowBeginId)/5)` but the Z80 does not have a divison
; instruction so we use a loop that increments an `index` in increments of 5 to
; determine the corresponding rowIndex.
;
; The complication is that we want to evaluate `(childId < nodeId)` but the
; Z80 instruction can only increment the A register, so we have to store
; the `nodeId` in A and the `childId` in C. Which forces us to reverse the
; comparison. But checking for NC (no carry) is equivalent to a '>='
; instead of a '<', so we are forced to start at `5-1` instead of `5`. I
; hope my future self will understand this explanation.
;
; Input:
;   A: rowBeginId
;   D: numRows
;   C: childId
; Output: A: rowIndex
; Destroys: B; preserves C, D
deduceRowIndex:
    add a, 4 ; nodeId = rowBeginId + 4
    ld b, d ; B (DJNZ counter) = numRows
deduceRowIndexLoop:
    cp c ; If nodeId < childId: set CF
    jr nc, deduceRowIndexFound ; nodeId >= childId
    add a, 5 ; nodeId += 5
    djnz deduceRowIndexLoop
    ; We should never fall off the end of the loop, but if we do, set the
    ; rowIndex to 0.
    xor a
    ret
deduceRowIndexFound:
    ld a, d ; numRows
    sub b ; rowIndex = numRows - B
    ret

;-----------------------------------------------------------------------------

; handleKeyMenu1() -> None
; Description: Handle menu key 1 (left most).
; Input: none
; Destroys: all
handleKeyMenu1:
    ld a, 0
    jr handleKeyMenuA

; handleKeyMenu2() -> None
; Description: Handle menu key 2 (2nd from left).
; Input: none
; Destroys: all
handleKeyMenu2:
    ld a, 1
    jr handleKeyMenuA

; handleKeyMenu3() -> None
; Description: Handle menu key 3 (middle).
; Input: none
; Destroys: all
handleKeyMenu3:
    ld a, 2
    jr handleKeyMenuA

; handleKeyMenu4() -> None
; Description: Handle menu key 4 (2nd from right).
; Input: none
; Destroys: all
handleKeyMenu4:
    ld a, 3
    jr handleKeyMenuA

; handleKeyMenu5() -> None
; Description: Handle menu key 5 (right most).
; Input: none
; Destroys: all
handleKeyMenu5:
    ld a, 4
    ; [[fallthrough]]

; handleKeyMenuA(A) -> None
;
; Description: Dispatch to the handler specified by the menu node at the menu
; button indexed by A (0: left most, 4: right most).
; Input: A: menu button index (0-4)
; Output: A: nodeId of the selected menu item
; Destroys: all
handleKeyMenuA:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz

    ld c, a ; save A (menu button index 0-4)
    call getCurrentMenuRowBeginId ; A=row begin id
    add a, c ; menu node ids are sequential starting with beginId
    ; [[fallthrough]]

; Description: Dispatch to the handler for the menu node in register A.
; Input: A=target nodeId
; Output: none
; Destroys: all?
dispatchMenuNode:
    ; get menu node corresponding to pressed menu key
    call getMenuNode
    push af
    push hl ; save pointer to MenuNode
    ; load mXxxHandler
    inc hl
    inc hl
    inc hl
    ld a, (hl) ; A=numRows
    inc hl
    inc hl
    ld e, (hl)
    inc hl
    ld d, (hl) ; DE=mXxxHandler of the target node
    push de
    ; If the target node is a MenuGroup, then we are essentially doing a
    ; 'chdir' operation, so we need to call the exit handler of the current
    ; node.
    or a ; if targetNode.numRows == 0: ZF=1
    jr z, dispatchMenuNodeEnterTargetGroup
dispatchMenuNodeExitCurrentGroup:
    ld a, (menuGroupId)
    call getMenuNodeIX
    ld l, (ix + menuNodeHandler)
    ld h, (ix + menuNodeHandler + 1)
    scf ; set CF=1 to invoke handler for exit
    call jumpHL
dispatchMenuNodeEnterTargetGroup:
    pop de ; DE=menu handler of target group
    pop hl ; HL=pointer to target menu group
    pop af ; A=menuId of target menu group
    or a ; set CF=0 to invoke handler for entry
    jp jumpDE

;-----------------------------------------------------------------------------
; Arithmetic functions.
;-----------------------------------------------------------------------------

; Function: Handle the Add key.
; Input: inputBuf
; Output:
; Destroys: all, OP1, OP2, OP4
handleKeyAdd:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    call checkBase10
    jp nz, mBitwiseAddHandler
    call closeInputAndRecallXY
    bcall(_FPAdd) ; Y + X
    jp replaceXY

; Function: Handle the Sub key.
; Input: inputBuf
; Output:
; Destroys: all, OP1, OP2, OP4
handleKeySub:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    call checkBase10
    jp nz, mBitwiseSubtHandler
    call closeInputAndRecallXY
    bcall(_FPSub) ; Y - X
    jp replaceXY

; Function: Handle the Mul key.
; Input: inputBuf
; Output:
; Destroys: all, OP1, OP2, OP4, OP5
handleKeyMul:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    call checkBase10
    jp nz, mBitwiseMultHandler
    call closeInputAndRecallXY
    bcall(_FPMult) ; Y * X
    jp replaceXY

; Function: Handle the Div key.
; Input: inputBuf
; Output:
; Destroys: all, OP1, OP2, OP4
handleKeyDiv:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    call checkBase10
    jp nz, mBitwiseDivHandler
    call closeInputAndRecallXY
    bcall(_FPDiv) ; Y / X
    jp replaceXY

;-----------------------------------------------------------------------------
; Constants: pi and e. There does not seem to be an existing bcall() that loads
; these constants. It's almost unbelievable, because these constants are shown
; on the calculator keyboard, and there are dozens of bcall() functions to load
; other values such as 0, 1, 2, 3 but I cannot find the bcall() to load these
; constants.
;-----------------------------------------------------------------------------

handleKeyPi:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    call closeInputBuf
    call op1SetPi
    jp pushX

handleKeyEuler:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    call closeInputBuf
    call op1SetEuler
    jp pushX

;-----------------------------------------------------------------------------
; Alegbraic functions.
;-----------------------------------------------------------------------------

; Function: y^x
handleKeyExpon:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    call closeInputAndRecallXY
    bcall(_YToX)
    jp replaceXY

; Function: 1/x
handleKeyInv:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    call closeInputAndRecallX
    bcall(_FPRecip)
    jp replaceX

; Function: x^2
handleKeySquare:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    call closeInputAndRecallX
    bcall(_FPSquare)
    jp replaceX

; Function: sqrt(x)
handleKeySqrt:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    call closeInputAndRecallX
    bcall(_SqRoot)
    jp replaceX

;-----------------------------------------------------------------------------
; Stack operations
;-----------------------------------------------------------------------------

handleKeyRotDown:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    call closeInputBuf
    jp rotDownStack

handleKeyExchangeXY:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    call closeInputBuf
    jp exchangeXYStack

handleKeyAns:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    call closeInputBuf
    call rclL
    jp pushX

;-----------------------------------------------------------------------------
; Transcendentals
;-----------------------------------------------------------------------------

handleKeyLog:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    call closeInputAndRecallX
    bcall(_LogX)
    jp replaceX

handleKeyALog:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    call closeInputAndRecallX
    bcall(_TenX)
    jp replaceX

handleKeyLn:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    call closeInputAndRecallX
    bcall(_LnX)
    jp replaceX

handleKeyExp:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    call closeInputAndRecallX
    bcall(_EToX)
    jp replaceX

;-----------------------------------------------------------------------------
; Trignometric
;-----------------------------------------------------------------------------

handleKeySin:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    call closeInputAndRecallX
    bcall(_Sin)
    jp replaceX

handleKeyCos:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    call closeInputAndRecallX
    bcall(_Cos)
    jp replaceX

handleKeyTan:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    call closeInputAndRecallX
    bcall(_Tan)
    jp replaceX

handleKeyASin:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    call closeInputAndRecallX
    bcall(_ASin)
    jp replaceX

handleKeyACos:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    call closeInputAndRecallX
    bcall(_ACos)
    jp replaceX

handleKeyATan:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    call closeInputAndRecallX
    bcall(_ATan)
    jp replaceX

;-----------------------------------------------------------------------------
; Buttons providing direct access to menu groups.
;-----------------------------------------------------------------------------

handleKeyMath:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    ld a, mRootId ; MATH becomes the menu HOME button
    jp dispatchMenuNode

handleKeyMode:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    ld a, mModeId ; MODE triggers the MODE menu.
    jp dispatchMenuNode

handleKeyStat:
    ; Do nothing in command arg mode.
    bit rpnFlagsArgMode, (iy + rpnFlags)
    ret nz
    ld a, mStatId ; MODE triggers the MODE menu.
    jp dispatchMenuNode

;-----------------------------------------------------------------------------
; User registers, accessed through RCL nn and STO nn.
;-----------------------------------------------------------------------------

handleKeySto:
    call closeInputBuf
    ld hl, handleKeyStoCallback
    ld (argHandler), hl
    ld hl, msgStoName
    jp enableArgMode
handleKeyStoCallback:
    call rclX
    ld a, (argValue)
    ; check if command argument too large
    cp regsSize
    jr c, handleKeyStoCallbackContinue
    ld a, errorCodeDimension
    jp setHandlerCode
handleKeyStoCallbackContinue:
    jp stoNN

handleKeyRcl:
    call closeInputBuf
    ld hl, handleKeyRclCallback
    ld (argHandler), hl
    ld hl, msgRclName
    jp enableArgMode
handleKeyRclCallback:
    ld a, (argValue)
    ; check if command argument too large
    cp regsSize
    jr c, handleKeyRclCallbackContinue
    ld a, errorCodeDimension
    jp setHandlerCode
handleKeyRclCallbackContinue:
    call rclNN
    jp pushX

msgStoName:
    .db "STO", 0
msgRclName:
    .db "RCL", 0

;-----------------------------------------------------------------------------
; Common code fragments, to save space.
;-----------------------------------------------------------------------------

; Close the input buffer, and recall Y and X into OP1 and OP2 respectively.
closeInputAndRecallXY:
    call closeInputBuf
    call rclX
    bcall(_OP1ToOP2)
    jp rclY

; Close the input buffer, and recall X into OP1 respectively.
closeInputAndRecallX:
    call closeInputBuf
    jp rclX
