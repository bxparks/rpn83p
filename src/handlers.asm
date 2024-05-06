;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Main input key code handlers.
;-----------------------------------------------------------------------------

; Description: Append a number character to inputBuf or argBuf, updating
; various flags. If the inputBuf is already complex, this routine must not be
; called with Langle, LimagI or Ltheta.
; Input:
;   - A:char=character to be appended
;   - rpnFlagsEditing=whether we are already in Edit mode
; Output:
;   - CF=0 if successful
;   - rpnFlagsEditing set
;   - dirtyFlagsInput set
;   - (cursorInputPos) updated if successful
; Destroys: all
handleKeyNumber:
    ; Any digit entry should cause TVM menus to go into input mode.
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ; If not in input editing mode: lift stack and go into edit mode
    bit rpnFlagsEditing, (iy + rpnFlags)
    jr nz, handleKeyNumberCheckAppend
handleKeyNumberFirstDigit:
    ; Lift the stack, unless disabled.
    push af ; preserve A=char to append
    call liftStackIfEnabled
    pop af
    ; Go into editing mode.
    bcall(_ClearInputBuf) ; preserves A
    set rpnFlagsEditing, (iy + rpnFlags)
handleKeyNumberCheckAppend:
    call isComplexDelimiter ; ZF=1 if complex delimiter
    jr z, handleKeyNumberAppend
    ; Check if EE exists and check num digits in EE.
    ld d, a ; D=saved A
    bcall(_CheckInputBufEE) ; CF=1 if E exists; A=eeLen
    jr nc, handleKeyNumberRestoreAppend
    ; Check if eeLen<2.
    cp inputBufEEMaxLen
    ret nc ; prevent more than 2 exponent digits
handleKeyNumberRestoreAppend:
    ld a, d ; A=restored
handleKeyNumberAppend:
    bcall(_InsertCharInputBuf) ; CF=0 if successful
    ret

; Description: Return ZF=1 if A is a complex number delimiter (LimagI, Langle,
; Ldegree). Same as isComplexDelimiterPageOne().
; Input: A: char
; Output: ZF=1 if delimiter
; Destroys: none
isComplexDelimiter:
    cp LimagI
    ret z
    cp Langle
    ret z
    cp Ldegree
    ret

;-----------------------------------------------------------------------------

; Description: Append '0' to inputBuf.
handleKey0:
    ld a, '0'
    jr handleKeyNumber

; Description: Append '1' to inputBuf.
handleKey1:
    ld a, '1'
    jr handleKeyNumber

; Description: Append '2' to inputBuf.
handleKey2:
    call checkAllowOct ; ZF=1 if oct digits 0-7 allowed
    ret nz
    ld a, '2'
    jr handleKeyNumber

; Description: Append '3' to inputBuf.
handleKey3:
    call checkAllowOct ; ZF=1 if oct digits 0-7 allowed
    ret nz
    ld a, '3'
    jr handleKeyNumber

; Description: Append '4' to inputBuf.
handleKey4:
    call checkAllowOct ; ZF=1 if oct digits 0-7 allowed
    ret nz
    ld a, '4'
    jr handleKeyNumber

; Description: Append '5' to inputBuf.
handleKey5:
    call checkAllowOct ; ZF=1 if oct digits 0-7 allowed
    ret nz
    ld a, '5'
    jr handleKeyNumber

; Description: Append '6' to inputBuf.
handleKey6:
    call checkAllowOct ; ZF=1 if oct digits 0-7 allowed
    ret nz
    ld a, '6'
    jr handleKeyNumber

; Description: Append '7' to inputBuf.
handleKey7:
    call checkAllowOct ; ZF=1 if oct digits 0-7 allowed
    ret nz
    ld a, '7'
    jr handleKeyNumber

; Description: Append '8' to inputBuf.
handleKey8:
    call checkAllowDec ; ZF=1 if decimal digits 0-9 allowed.
    ret nz
    ld a, '8'
    jr handleKeyNumber

; Description: Append '9' to inputBuf.
handleKey9:
    call checkAllowDec ; ZF=1 if decimal digits 0-9 allowed.
    ret nz
    ld a, '9'
    jp handleKeyNumber

; Description: Append 'A' to inputBuf.
handleKeyA:
    call checkAllowHex ; ZF=1 if hex digits A-F allowed
    ret nz
    ld a, 'A'
    jp handleKeyNumber

; Description: Append 'B' to inputBuf.
handleKeyB:
    call checkAllowHex ; ZF=1 if hex digits A-F allowed
    ret nz
    ld a, 'B'
    jp handleKeyNumber

; Description: Append 'C' to inputBuf.
handleKeyC:
    call checkAllowHex ; ZF=1 if hex digits A-F allowed
    ret nz
    ld a, 'C'
    jp handleKeyNumber

; Description: Append 'D' to inputBuf.
handleKeyD:
    call checkAllowHex ; ZF=1 if hex digits A-F allowed
    ret nz
    ld a, 'D'
    jp handleKeyNumber

; Description: Append 'E' to inputBuf.
handleKeyE:
    call checkAllowHex ; ZF=1 if hex digits A-F allowed
    ret nz
    ld a, 'E'
    jp handleKeyNumber

; Description: Append 'F' to inputBuf.
handleKeyF:
    call checkAllowHex ; ZF=1 if hex digits A-F allowed
    ret nz
    ld a, 'F'
    jp handleKeyNumber

; Description: Append 'G' to inputBuf.
handleKeyG:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ld a, 'G'
    jp handleKeyNumber

; Description: Append 'H' to inputBuf.
handleKeyH:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ld a, 'H'
    jp handleKeyNumber

; Description: Append 'I' to inputBuf.
handleKeyI:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ld a, 'I'
    jp handleKeyNumber

; Description: Append 'J' to inputBuf.
handleKeyJ:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ld a, 'J'
    jp handleKeyNumber

; Description: Append 'K' to inputBuf.
handleKeyK:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ld a, 'K'
    jp handleKeyNumber

; Description: Append 'L' to inputBuf.
handleKeyL:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ld a, 'L'
    jp handleKeyNumber

; Description: Append 'M' to inputBuf.
handleKeyM:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ld a, 'M'
    jp handleKeyNumber

; Description: Append 'N' to inputBuf.
handleKeyN:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ld a, 'N'
    jp handleKeyNumber

; Description: Append 'O' to inputBuf.
handleKeyO:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ld a, 'O'
    jp handleKeyNumber

; Description: Append 'P' to inputBuf.
handleKeyP:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ld a, 'P'
    jp handleKeyNumber

; Description: Append 'Q' to inputBuf.
handleKeyQ:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ld a, 'Q'
    jp handleKeyNumber

; Description: Append 'R' to inputBuf.
handleKeyR:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ld a, 'R'
    jp handleKeyNumber

; Description: Append 'S' to inputBuf.
handleKeyS:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ld a, 'S'
    jp handleKeyNumber

; Description: Append 'T' to inputBuf.
handleKeyT:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ld a, 'T'
    jp handleKeyNumber

; Description: Append 'U' to inputBuf.
handleKeyU:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ld a, 'U'
    jp handleKeyNumber

; Description: Append 'V' to inputBuf.
handleKeyV:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ld a, 'V'
    jp handleKeyNumber

; Description: Append 'W' to inputBuf.
handleKeyW:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ld a, 'W'
    jp handleKeyNumber

; Description: Append 'X' to inputBuf.
handleKeyX:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ld a, 'X'
    jp handleKeyNumber

; Description: Append 'Y' to inputBuf.
handleKeyY:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ld a, 'Y'
    jp handleKeyNumber

; Description: Append 'Z' to inputBuf.
handleKeyZ:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ld a, 'Z'
    jp handleKeyNumber

; Description: Return ZF=1 if octal digits (0-7) are allowed.
checkAllowOct:
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret z ; ZF=1 if non-BASE
    ld a, (baseNumber)
    cp 8
    ret z
    cp 10
    ret z
    cp 16
    ret

; Description: Return ZF=1 if decimal digits (0-9) are allowed.
checkAllowDec:
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret z ; ZF=1 if non-BASE mode
    ld a, (baseNumber)
    cp 10
    ret z
    cp 16
    ret

; Description: Return ZF=1 if hexadecimal (A-F) are allowed.
checkAllowHex:
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret z ; return ZF=1 if non-BASE, to allow alpha A-F characters
    ld a, (baseNumber)
    cp 16 ; ZF=1 if baseNumber==16
    ret

;-----------------------------------------------------------------------------

; Description: Append a '.' if not already entered.
; Input: inputBuf
; Output: (inputBuf) updated
; Destroys: A, BC, DE, HL
handleKeyDecPnt:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ; Do nothing if decimal point already exists in the last number.
    bcall(_CheckInputBufDecimalPoint) ; CF=1 if decimal exists
    ret c
    ; Do nothing if 'E' exists. Exponents cannot have a decimal point.
    bcall(_CheckInputBufEE) ; CF=1 if E exists; A=eeLen
    ret c
    ; try insert '.'
    ld a, '.'
    call handleKeyNumber
    ret

; Description: Handle the EE for scientific notation. The 'EE' is mapped to
; 2ND-COMMA by default on the calculator. For faster entry, we map the COMMA
; key (withouth 2ND) to be EE as well.
; Input: none
; Output: (inputBuf) updated
; Destroys: A, BC, DE, HL
handleKeyEE:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ; Check if Comma and EE are swapped.
    ld a, (commaEEMode)
    cp commaEEModeSwapped
    jr z, handleKeyCommaAlt
handleKeyEEAlt:
    ; Check prior characters in the inputBuf.
    bcall(_CheckInputBufEE) ; CF=1 if E exists; A=eeLen
    ret c
    ; Append 'E'
    ld a, Lexponent
    jp handleKeyNumber

; Description: Handle the (ALPHA :) button which defines a number with a
; modifier, for example "2:D" (2 days), "2:H" (2 hours), "2:M" (2 minutes),
; "2:S" (2 seconds).
handleKeyColon:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ; Append ':'
    ld a, ':'
    jp handleKeyNumber

; Description: Add imaginary-i into the input buffer.
handleKeyImagI:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ; Try setting an existing complex delimiter.
    set dirtyFlagsInput, (iy + dirtyFlags)
    ld a, LimagI
    bcall(_SetComplexDelimiter) ; CF=1 if complex number
    ret c
    ; Try inserting imaginary-i
    ld a, LimagI
    call handleKeyNumber
    ret

; Description: Add Angle symbol into the input buffer for angle in degrees.
handleKeyAngle:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ; Try setting or toggling an existing complex delimiter.
    set dirtyFlagsInput, (iy + dirtyFlags)
    ld a, Ldegree
    bcall(_SetComplexDelimiter) ; CF=1 if complex delimiter exists
    ret c
    ; Insert Ldegree delimiter for initial default.
    ld a, Ldegree
    call handleKeyNumber
    ret

;-----------------------------------------------------------------------------

handleKeyLBrace:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    bcall(_CheckInputBufRecord) ; CF=1 if inputBuf is a data record
    ret c ; return if already in data structure mode.
    ld a, LlBrace
    jp handleKeyNumber

handleKeyRBrace:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ; Check if in data record mode.
    bcall(_CheckInputBufRecord) ; CF=1 if inputBuf is a data record
    ret nc ; return if *not* in data structure mode.
    ; Check braceLevel
    or a
    ret z ; return if braceLevel<=0
    ; RBrace allowed.
    ld a, LrBrace
    jp handleKeyNumber

; Description: Handle the Comma button.
; Input: (commaEEMode)
; Output: (inputBuf) updated
; Destroys: all
handleKeyComma:
    ; Do nothing in BASE mode.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ; Check if Comma and EE are swapped.
    ld a, (commaEEMode)
    cp commaEEModeSwapped
    jr z, handleKeyEEAlt
handleKeyCommaAlt:
    ; Check if in data record mode.
    bcall(_CheckInputBufRecord) ; CF=1 if inputBuf is a data record
    ret nc ; return if not in data structure mode
    or a
    ret z ; return if braceLevel==0
    ; Prevent double-comma or comma after opening left brace.
    ld hl, inputBuf
    bcall(_GetLastChar) ; A=lastChar
    or a
    ret z ; return if empty
    cp ','
    ret z ; return if comma
    cp LlBrace
    ret z ; return if '{'
    ; Append the comma
    ld a, ','
    jp handleKeyNumber

;-----------------------------------------------------------------------------

; Description: Implement the DEL functionality, which does slightly different
; things depending on the context:
;   - If not in edit mode, clear the inputBuf and go into edit mode.
;   - If the deleted char was a '.', reset the decimal point flag.
;   - If the deleted char was a '-', reset the negative flag.
; Input: none
; Output: (iy+inputBufFlags) updated
; Destroys: A, DE, HL
handleKeyDel:
    ; Clear TVM Calculate mode.
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ; Check if non-zero error code is currently displayed. The handlerCode was
    ; already set to 0 before this was called, so simply returning will clear
    ; the previous errorCode.
    ld a, (errorCode)
    or a
    ret nz
    ; If not in edit mode, go into edit mode, clear the inputBuf, and just
    ; return because there is nothing to do with an empty inputBuf.
    bit rpnFlagsEditing, (iy + rpnFlags)
    jr nz, handleKeyDelInEditMode
    set rpnFlagsEditing, (iy + rpnFlags)
    bcall(_ClearInputBuf)
    ret
handleKeyDelInEditMode:
    ; DEL pressed in edit mode.
    bcall(_DeleteCharInputBuf)
    ret

;-----------------------------------------------------------------------------

; Description: Clear the X register and go into edit mode. If already in edit
; mode, clear the inputBuf. If the CLEAR is pressed when the input buffer is
; already empty, then go into ClearAgain mode. If CLEAR is pressed in
; ClearAgain mode, the RPN stack is cleared (like the CLST command).
; Input:
;   - errorCode
;   - inputBuf
;   - rpnFlagsEditing
; Output:
;   - inputBuf cleared
;   - editing mode set
;   - stack lift disabled
;   - handlerCode set to `errorCodeOk` or `errorCodeClearAgain`
; Destroys: A, HL
handleKeyClear:
    ; Clear TVM Calculate mode.
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ; Check if an error code is currently displayed.
    ld a, (errorCode)
    or a
    jr z, handleKeyClearNormal
    ; We are here if a non-zero errorCode from the previous handler is
    ; displayed. Previously, we simply returned if that was true, causing the
    ; CLEAR button to clear the previous error code. But we now support hitting
    ; CLEAR twice to invoke CLST, so we should return for all error codes
    ; except errorCodeClearAgain.
    cp errorCodeClearAgain
    ret nz
    ; We are here if the last errorCode was errorCodeClearAgain. CLEAR was
    ; pressed again, but before going ahead and clearing the RPN stack, let's
    ; check that the inputBuf is still empty. I am not actually sure if it is
    ; possible to have an errorCodeClearAgain and also have a non-empty
    ; inputBuf, but if that's the case, simply return without doing anything.
    ld a, (inputBuf)
    or a
    ret nz ; not sure if inputBuf can ever be non-empty, but just ret if so
    res rpnFlagsEditing, (iy + rpnFlags)
    jp clearStack
handleKeyClearNormal:
    ; We are here if CLEAR was pressed when there are no other error conditions
    ; previously. If we are already in edit mode, then we clear the inputBuf.
    ; If not in edit mode, then we "clear the X register" by going into edit
    ; mode with an empty inputBuf.
    bit rpnFlagsEditing, (iy + rpnFlags)
    jr z, handleKeyClearToEmptyInput
    ; We are here if clearing the inputBuf.
    ld a, (inputBuf)
    or a
    ; If the inputBuf has stuff, then clear the inputBuf.
    jr nz, handleKeyClearToEmptyInput
handleKeyClearWhileClear:
    ; We are here if CLEAR was pressed while the inputBuffer was already empty.
    ; Go into ClearAgain mode, where the next CLEAR invokes CLST.
    ld a, errorCodeClearAgain
    ld (handlerCode), a
    ret
handleKeyClearToEmptyInput:
    ; We are here if we were not in edit mode, so CLEAR should "clear the X
    ; register" by going into edit mode with an emtpy inputBuf.
    bcall(_ClearInputBuf)
    set rpnFlagsEditing, (iy + rpnFlags)
    ; We also disable stack lift. Testing seems to show that this is not seem
    ; strictly necessary because handleNumber() handles the edit mode properly
    ; even if the stack lift is enabled. But I think it is safer to disable it
    ; in case handleKeyNumber() is refactored in the future to use a different
    ; algorithm.
    res rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------

; Description: Handle (-) change sign key. There are 2 major types of behavior:
;
; 1) If in edit mode, change the sign of the right-most component in the
; inputBuf:
;   a) If the number is a simple real number, change the sign of the number.
;   b) If the number is a real number in scientific notation (containing the
;   `E` symbol), change the sign of the exponent instead of the mantissa.
;   c) If the number is a complex number, change the sign of the right most
;   component (either real or imaginary), subject to the rules (a) and (b)
;   above.
;   d) If the entry is a Record object (e.g. Date or Time), then change the
;   sign of the last component in the list of comma-separated numbers.
; 2) If not in edit mode, change the sign of the entire X register if it
; makes sense. An error code will be displayed if the CHS operation is not
; allowed.
;
; Input:
;   - X:(Real|Complex|RpnObject)
;   - (inputBuf)
; Output:
;   - X=-X, or
;   - (inputBuf) modified with '-' sign
; Destroys: all, OP1
handleKeyChs:
    ; Do nothing in BASE mode. Use NEG function instead.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    ret nz
    ; Clear TVM mode.
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ; Check if edit mode.
    bit rpnFlagsEditing, (iy + rpnFlags)
    jr nz, handleKeyChsInputBuf
handleKeyChsX:
    ; Not in edit mode, so change sign of X register
    call rclX
    call universalChs
    call stoX
    ret
handleKeyChsInputBuf:
    ; In edit mode, so change sign of Mantissa or Exponent.
    set dirtyFlagsInput, (iy + dirtyFlags)
    bcall(_CheckInputBufChs) ; A=chsPos
    ld hl, inputBuf
    ld b, inputBufCapacity
    ; [[fallthrough]]

; Description: Add or remove the '-' char at position A of the Pascal string at
; HL, with maximum length B.
; Input:
;   - A:u8=signPos, the offset where the sign ought to be
;   - B:u8=inputBufCapacity, max size of Pasal string
;   - HL:(PascalString*)
; Output:
;   - (HL): updated with '-' removed or added
; Destroys:
;   A, BC, DE, HL
flipInputBufSign:
    ld c, (hl) ; size of string
    cp c
    jr c, flipInputBufSignInside ; If A < inputBufLen: interior position
    ld a, c ; A=inputBufLen, location of insertion
    jr flipInputBufSignAdd
flipInputBufSignInside:
    ; Check for the '-' and flip it.
    push hl
    inc hl ; skip size byte
    ld e, a
    ld d, 0 ; DE=signPos
    add hl, de
    ld a, (hl) ; A=char at signPos
    cp signChar
    pop hl
    ld a, e ; A=signPos
    jr nz, flipInputBufSignAdd
flipInputBufSignRemove:
    ; Remove existing '-' sign
    bcall(_DeleteAtPos)
    ret
flipInputBufSignAdd:
    ; Add '-' sign.
    bcall(_InsertAtPos) ; CF=1 if insertion failed
    ret c
    ; Set newly created empty slot to '-'
    ld a, signChar
    ld (hl), a
    ret

;-----------------------------------------------------------------------------

; Description: Handle the ENTER key.
; Input: none
; Output:
; Destroys: all, OP1, OP2, OP4
handleKeyEnter:
    call closeInputAndRecallNone
    call liftStack ; always lift the stack
    res rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------
; Cursor navigation
;-----------------------------------------------------------------------------

handleKeyLeft:
    ld a, (cursorInputPos)
    or a
    ret z
    dec a
    jr saveCursorInputPos

handleKeyRight:
    ld a, (inputBuf) ; A=inputBufLen
    ld b, a
    ld a, (cursorInputPos)
    cp b
    ret nc
    inc a
    jr saveCursorInputPos

handleKeyBOL:
    xor a
    jr saveCursorInputPos

handleKeyEOL:
    ld a, (inputBuf) ; A=inputBufLen
    ; [[fallthrough]]

saveCursorInputPos:
    ld (cursorInputPos), a
    set dirtyFlagsInput, (iy + dirtyFlags)
    ret

;-----------------------------------------------------------------------------
; Menu key handlers.
;-----------------------------------------------------------------------------

; Description: Go to the previous menu row, with rowIndex decreasing upwards.
; Input: none
; Output: (currentMenuRowIndex) decremented, or wrapped around
; Destroys: all
handleKeyUp:
    bcall(_GetCurrentMenuGroupNumRows) ; A=numRows
    ; if numRows==1: return
    cp 2 ; CF=1 if numRows<=1
    ret c
    ; currentMenuRowIndex=(currentMenuRowIndex-1) mod numRows
    ld c, a ; C=numRows
    ld a, (currentMenuRowIndex)
    or a
    jr nz, handleKeyUpContinue
    ld a, c ; A = numRows
handleKeyUpContinue:
    dec a
    ld (currentMenuRowIndex), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

;-----------------------------------------------------------------------------

; Description: Go to the next menu row, with rowIndex increasing downwards.
; Input: none
; Output: (currentMenuRowIndex) incremented mod numRows
; Destroys: all
handleKeyDown:
    bcall(_GetCurrentMenuGroupNumRows) ; A=numRows
    ; if numRows==1: return
    cp 2
    ret c
    ; currentMenuRowIndex=(currentMenuRowIndex+1) mod numRows
    ld c, a
    ld a, (currentMenuRowIndex)
    inc a
    cp c
    jr c, handleKeyDownContinue
    xor a
handleKeyDownContinue:
    ld (currentMenuRowIndex), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

;-----------------------------------------------------------------------------

; Description: Go back up the menu hierarchy to the parent menu group. If
; already at the rootMenu, and the rowIndex is not 0, then reset the
; rowIndex to 0 so that we return to the default, top-level view of the menu
; hierarchy.
; Input:
;   - (currentMenuGroupId), the current (child) menu group
; Output:
;   - (currentMenuGroupId) at parentId
;   - (currentMenuRowIndex) of the input (child) menu group
; Destroys: all
handleKeyExit:
    jp exitMenuGroup

;-----------------------------------------------------------------------------

; Description: Handle menu key 1 (left most).
; Input: none
; Destroys: all
handleKeyMenu1:
    ld a, 0
    jr handleKeyMenuA

; Description: Handle menu key 2 (2nd from left).
; Input: none
; Destroys: all
handleKeyMenu2:
    ld a, 1
    jr handleKeyMenuA

; Description: Handle menu key 3 (middle).
; Input: none
; Destroys: all
handleKeyMenu3:
    ld a, 2
    jr handleKeyMenuA

; Description: Handle menu key 4 (2nd from right).
; Input: none
; Destroys: all
handleKeyMenu4:
    ld a, 3
    jr handleKeyMenuA

; Description: Handle menu key 5 (right most).
; Input: none
; Destroys: all
handleKeyMenu5:
    ld a, 4
    jr handleKeyMenuA

; Description: Handle menu key 2ND 1 (left most).
; Input: none
; Destroys: all
handleKeyMenuSecond1:
    ld a, 0
    jr handleKeyMenuSecondA

; Description: Handle menu key 2ND 2 (2nd from left).
; Input: none
; Destroys: all
handleKeyMenuSecond2:
    ld a, 1
    jr handleKeyMenuSecondA

; Description: Handle menu key 2ND 3 (middle).
; Input: none
; Destroys: all
handleKeyMenuSecond3:
    ld a, 2
    jr handleKeyMenuSecondA

; Description: Handle menu key 2ND 4 (2nd from right).
; Input: none
; Destroys: all
handleKeyMenuSecond4:
    ld a, 3
    jr handleKeyMenuSecondA

; Description: Handle menu key 2ND 5 (right most).
; Input: none
; Destroys: all
handleKeyMenuSecond5:
    ld a, 4
    jr handleKeyMenuSecondA

; Description: Dispatch to the handler specified by the menu node at the menu
; button indexed by A (0: left most, 4: right most).
; Input: A: menu button index (0-4)
; Output: A: nodeId of the selected menu item
; Destroys: all
handleKeyMenuA:
    res rpnFlagsSecondKey, (iy + rpnFlags)
handleKeyMenuAltEntry:
    bcall(_GetMenuIdOfButton) ; HL=menuId of button
    jp dispatchMenuNode

; Description: Same as handleKeyMenuA() except that the menu key was invoked
; using the 2ND key, which sets the rpnFlagsSecondKey flag.
; Input: A: menu button index (0-4)
; Output: A: nodeId of the selected menu item
; Destroys: all
handleKeyMenuSecondA:
    set rpnFlagsSecondKey, (iy + rpnFlags)
    jr handleKeyMenuAltEntry

;-----------------------------------------------------------------------------
; Arithmetic functions.
;-----------------------------------------------------------------------------

; Description: Handle the Add key.
; Input: inputBuf
; Output:
; Destroys: all, OP1, OP2, OP3, OP4
handleKeyAdd:
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    jp nz, mBaseAddHandler
    call closeInputAndRecallUniversalXY ; CP1=Y; CP3=X
    call universalAdd
    jp replaceXY

; Description: Handle the Sub key.
; Input: inputBuf
; Output:
; Destroys: all, OP1, OP2, OP3, OP4
handleKeySub:
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    jp nz, mBaseSubtHandler
    call closeInputAndRecallUniversalXY ; CP1=X; CP3=Y
    call universalSub
    jp replaceXY

; Description: Handle the Mul key.
; Input: inputBuf
; Output:
; Destroys: all, OP1, OP2, OP3, OP4, OP5
handleKeyMul:
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    jp nz, mBaseMultHandler
    call closeInputAndRecallUniversalXY ; CP1=Y; CP3=X
    call universalMult
    jp replaceXY

; Description: Handle the Div key.
; Input: inputBuf
; Output:
; Destroys: all, OP1, OP2, OP3, OP4
handleKeyDiv:
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    jp nz, mBaseDivHandler
    call closeInputAndRecallUniversalXY ; CP1=Y; CP3=X
    call universalDiv
    jp replaceXY

;-----------------------------------------------------------------------------
; Constants: pi and e. There does not seem to be an existing bcall() that loads
; these constants. It's almost unbelievable, because these constants are shown
; on the calculator keyboard, and there are dozens of bcall() functions to load
; other values such as 0, 1, 2, 3 but I cannot find the bcall() to load these
; constants.
;-----------------------------------------------------------------------------

handleKeyPi:
    call closeInputAndRecallNone
    call op1SetPi
    jp pushToX

handleKeyEuler:
    call closeInputAndRecallNone
    call op1SetEuler
    jp pushToX

;-----------------------------------------------------------------------------
; Alegbraic functions.
;-----------------------------------------------------------------------------

; Description: y^x
handleKeyExpon:
    call closeInputAndRecallUniversalXY ; CP1=Y; CP3=X
    call universalPow
    jp replaceXY

; Description: Handle the 1/x button. For Real and Complex, this is the
; reciprocal function. But for RpnDateTime and RpnOffsetDateTime, this button
; is bound to the DCUT (aka DateCut) function using the mDateCutHandlerAlt()
; routine.
handleKeyInv:
    call closeInputAndRecallUniversalX ; A=rpnObjectType
    cp rpnObjectTypeDateTime
    jp z, mDateCutHandlerAlt
    cp rpnObjectTypeOffsetDateTime
    jp z, mDateCutHandlerAlt
    call universalRecip
    jp replaceX

; Description: Handle the x^2 button. For Real and Complex, this performs the
; X^2 function. But for RpnDate, RpnDateTime, this invokes the DEXT
; (DateExtend) function using the mDateExtendHandlerAlt() routine.
handleKeySquare:
    call closeInputAndRecallUniversalX ; A=rpnObjectType
    cp rpnObjectTypeDate
    jp z, mDateExtendHandlerAlt
    cp rpnObjectTypeDateTime
    jp z, mDateExtendHandlerAlt
    call universalSquare
    jp replaceX

; Description: Handle the sqrt(x) button. For Real and Complex, this performs
; the sqrt(x) function. But for RpnDateTime and RpnOffsetDateTime, this invokes
; the DSHK (DateShrink) function using the mDateShrinkHandlerAlt() routine.
handleKeySqrt:
    call closeInputAndRecallUniversalX ; A=rpnObjectType
    cp rpnObjectTypeDateTime
    jp z, mDateShrinkHandlerAlt
    cp rpnObjectTypeOffsetDateTime
    jp z, mDateShrinkHandlerAlt
    call universalSqRoot
    jp replaceX

;-----------------------------------------------------------------------------
; Stack operations
;-----------------------------------------------------------------------------

handleKeyRollDown:
    call closeInputAndRecallNone
    jp rollDownStack

handleKeyExchangeXY:
    call closeInputAndRecallNone
    jp exchangeXYStack

handleKeyAns:
    call closeInputAndRecallNone
    call rclL
    jp pushToX

;-----------------------------------------------------------------------------
; Transcendentals
;-----------------------------------------------------------------------------

handleKeyLog:
    call closeInputAndRecallUniversalX
    call universalLog ; A=numReturnValues
    jp replaceX

handleKeyALog:
    call closeInputAndRecallUniversalX
    call universalTenPow
    jp replaceX

handleKeyLn:
    call closeInputAndRecallUniversalX
    call universalLn
    jp replaceX

handleKeyExp:
    call closeInputAndRecallUniversalX
    call universalExp
    jp replaceX

;-----------------------------------------------------------------------------
; Trignometric
;-----------------------------------------------------------------------------

handleKeySin:
    call closeInputAndRecallX
    bcall(_Sin)
    jp replaceX

handleKeyCos:
    call closeInputAndRecallX
    bcall(_Cos)
    jp replaceX

handleKeyTan:
    call closeInputAndRecallX
    bcall(_Tan)
    jp replaceX

handleKeyASin:
    call closeInputAndRecallX
    bcall(_ASin)
    jp replaceX

handleKeyACos:
    call closeInputAndRecallX
    bcall(_ACos)
    jp replaceX

handleKeyATan:
    call closeInputAndRecallX
    bcall(_ATan)
    jp replaceX

;-----------------------------------------------------------------------------
; User registers, accessed through RCL nn and STO nn.
;-----------------------------------------------------------------------------

handleKeySto:
    call closeInputAndRecallNone
    ld hl, msgStoPrompt
    call startArgScanner
    set inputBufFlagsArgAllowModifier, (iy + inputBufFlags)
    set inputBufFlagsArgAllowLetter, (iy + inputBufFlags)
    call processArgCommands ; ZF=0 if cancelled
    ret nz ; do nothing if cancelled
    cp argModifierIndirect
    ret nc ; TODO: implement this
    call rclX ; OP1/OP2=X
    ; Set up Sto parameters
    ld a, (argValue) ; A=indexOrLetter
    ld c, a ; C=index or letter
    ld a, (argModifier)
    ld b, a ; B=op
    ld a, (argType) ; A=argType
    jp stoOpGeneric
handleKeyStoInvalid:
    bcall(_ErrInvalid)

; Description: Handle the RCL button. There are 2 cases:
; 1) If {op} is empty, it's a simple assignment, so we call rclGeneric() and
; push the value on to the RPN stack.
; 2) If the {op} is not empty, it is an arithmetic operator, we call
; rclOpGeneric() and *replace* the current X with the new X.
handleKeyRcl:
    call closeInputAndRecallNone
    ld hl, msgRclPrompt
    call startArgScanner
    set inputBufFlagsArgAllowModifier, (iy + inputBufFlags)
    set inputBufFlagsArgAllowLetter, (iy + inputBufFlags)
    call processArgCommands ; ZF=0 if cancelled
    ret nz ; do nothing if cancelled
    cp argModifierIndirect
    ret nc ; TODO: implement this
    ld a, (argValue) ; A=varLetter
    ld c, a ; C=indexOrLetter
    ld a, (argModifier)
    ld b, a ; B=modifier
    or a
    jr nz, handleKeyRclOp
    ; No modifier, so call rclGeneric() and *push* value onto the RPN stack.
    ld a, (argType) ; A=argType
    call rclGeneric
    jp pushToX
handleKeyRclOp:
    ; Modifier provided, so call rclOpGeneric() and *replace* the X register
    ; with (OP1 {op} registerOrVariable).
    push bc ; stack=[BC saved]
    call rclX ; OP1=X
    pop bc ; BC=restored
    ld a, (argType) ; A=argType
    call rclOpGeneric
    jp replaceX ; updates LastX

msgStoPrompt:
    .db "STO", 0
msgRclPrompt:
    .db "RCL", 0

;-----------------------------------------------------------------------------
; Buttons providing direct access to menu groups.
;-----------------------------------------------------------------------------

; Description: Handle the MATH key as the "HOME" key, going up to the top of
; the menu hierarchy.
handleKeyMath:
    ld hl, mRootId
    jp dispatchMenuNode

; Description: Handle the MODE key as a shortcut to `ROOT > MODE`, except this
; saves the current MenuGroup as the jumpBack menu, and the ON/EXIT
handleKeyMode:
    ld hl, mModeId
    jp dispatchMenuNodeWithJumpBack

; Description: Handle the STAT key as a shortcut to `ROOT > STAT`, but unlike
; `MODE`, this does *not* save the current MenuGroup in the jumpBack variables.
handleKeyStat:
    ld hl, mStatId
    jp dispatchMenuNode

;-----------------------------------------------------------------------------
; QUIT. The mainExit routine will cleanup any application specific memory,
; including the call stack.
;-----------------------------------------------------------------------------

handleKeyQuit:
    jp mainExit

;-----------------------------------------------------------------------------
; Secret "DRAW" mode.
;-----------------------------------------------------------------------------

handleKeyDraw:
    call closeInput ; preserve rpnFlagsTvmCalculate
    ld hl, msgDrawPrompt
    call startArgScanner
    call processArgCommands ; ZF=0 if cancelled
    ret nz ; do nothing if cancelled
    ; save (argValue)
    ld a, (argValue)
    ld (drawMode), a
    ; notify the dispatcher to clear and redraw the screen
    ld a, errorCodeClearScreen
    ld (handlerCode), a
    ret

handleKeyShow:
    call closeInput ; preserve rpnFlagsTvmCalculate
    call processShowCommands
    ret

; DRAW mode prompt.
msgDrawPrompt:
    .db "DRAW", 0

;-----------------------------------------------------------------------------
; Keys related to linking and unlinking.
;-----------------------------------------------------------------------------

; Description: Convert between 2 reals and a complex number, depending on the
; complexMode setting (RECT, PRAD, PDEG). For RpnDate and RpnDateTime objects,
; this invokes the DLNK (DateLink) function using the mDateLinkHandlerAlt()
; routine.
; Input:
;   - X:(Real|Complex|RpnDate|RpnDateTime)
;   - Y:(Real|Complex|RpnDate|RpnDateTime)
; Output:
;   - X:(Real|Complex|RpnDateTime|RpnOffsetDateTime)
;   - Y:(Real|Complex|RpnDateTime|RpnOffsetDateTime)
handleKeyLink:
    call closeInputAndRecallNone
    call rclX ; CP1=X; A=objectType
    cp a, rpnObjectTypeReal
    jr z, handleKeyLinkRealsToComplex
    cp a, rpnObjectTypeComplex
    jr z, handleKeyLinkComplexToReals
    ;
    cp rpnObjectTypeTime ; ZF=1 if RpnTime
    jp z, mDateLinkHandlerAlt
    cp rpnObjectTypeDate ; ZF=1 if RpnDate
    jp z, mDateLinkHandlerAlt
    cp rpnObjectTypeOffset ; ZF=1 if RpnOffset
    jp z, mDateLinkHandlerAlt
    cp rpnObjectTypeDateTime ; ZF=1 if RpnDateTime
    jp z, mDateLinkHandlerAlt
handleKeyLinkErrDataType:
    bcall(_ErrDataType)
handleKeyLinkComplexToReals:
    ; Convert complex into 2 reals
    bcall(_ComplexToReals) ; OP1=Re(X), OP2=Im(X)
    jp replaceXWithOP1OP2 ; replace X with OP1,OP2
handleKeyLinkRealsToComplex:
    bcall(_PushRealO1) ; FPS=[Im]
    ; Verify that Y is also real.
    call rclY ; CP1=Y; A=objectType
    cp a, rpnObjectTypeReal
    jr nz, handleKeyLinkErrDataType
    ; Convert 2 reals to complex
    bcall(_PopRealO2) ; FPS=[]; OP2=X=Im; OP1=Y=Re
    bcall(_RealsToComplex) ; CP1=complex(OP1,OP2)
    jp replaceXY ; replace X, Y with CP1
