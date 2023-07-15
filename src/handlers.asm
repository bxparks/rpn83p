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

; Function: Clear the inputBuf.
; Input: inputBuf
; Output:
;   - inputBuf cleared
;   - inputBufFlagsInputDirty set
; Destroys: none
clearInputBuf:
    push af
    xor a
    ld (inputBuf), a
    ld (iy+inputBufFlags), a
    set inputBufFlagsInputDirty, (iy + inputBufFlags)
    pop af
    ret

; Function: Append character to inputBuf.
; Input:
;   A: character to be appended
; Output:
;   - Carry flag set when append fails
;   - inputBufFlagsInputDirty set
; Destroys: all
appendInputBuf:
    ld hl, inputBuf
    ld b, inputBufMax
    set inputBufFlagsInputDirty, (iy + inputBufFlags)
    jp appendString

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
    jr nz, handleKeyNumberContinue
handleKeyNumberFirstDigit:
    ; Lift the stack, unless disabled.
    push af
    bit rpnFlagsLiftEnabled, (iy + rpnFlags)
    call nz, liftStack
    pop af
    ; Go into editing mode
    call handleKeyClear
handleKeyNumberContinue:
    jr appendInputBuf

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
    ; do nothing if a decimal point already exists
    bit inputBufFlagsDecPnt, (iy + inputBufFlags)
    ret nz
    ; try insert '.'
    ld a, '.'
    call handleKeyNumber
    ret c ; If Carry: append failed so return without setting the DecPnt flag
    set inputBufFlagsDecPnt, (iy + inputBufFlags)
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

    ; remove last character
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
    cp a, '-'
    ret nz
    res inputBufFlagsManSign, (iy + inputBufFlags)
    ret

;-----------------------------------------------------------------------------

; Function: Clear the input buffer.
; Input: none
; Output:
;   - A=0; inputBuf cleared
;   - editing mode set
;   - stack lift disabled
;   - mark displayInput dirty
; Destroys: A
handleKeyClear:
    call clearInputBuf
    set rpnFlagsEditing, (iy + rpnFlags)
    res rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------

; Function: Handle (-) change sign. If in edit mode, change the sign in the
; inputBuf. Otherwise, change the sign of the X register.
; Input: none
; Output: (inputBuf), X
; Destroys: all, OP1
handleKeyChs:
    bit rpnFlagsEditing, (iy + rpnFlags)
    jr nz, handleKeyChsInputBuf
handleKeyChsX:
    call rclX
    bcall(_InvOP1S)
    call stoX
    ret
handleKeyChsInputBuf:
    set inputBufFlagsInputDirty, (iy + inputBufFlags)
    bit inputBufFlagsManSign, (iy + inputBufFlags)
    jr z, handleKeyChsSetNegative
handleKeyChsSetPositive:
    ; Currently negative, so set positive
    res inputBufFlagsManSign, (hl)
    ld a, 0 ; string position 0
    ld hl, inputBuf
    ld b, inputBufMax
    jp deleteAtPos
handleKeyChsSetNegative:
    ; Currently positive, so set negative
    ld a, 0 ; string position 0
    ld hl, inputBuf
    ld b, inputBufMax
    call insertAtPos
    ret c ; Return if Carry set indicating string too long
    ; Insert '-' at beginning of string
    ld a, '-'
    ld (hl), a
    set inputBufFlagsManSign, (iy + inputBufFlags)
    ret

;-----------------------------------------------------------------------------

; Function: Handle the ENTER key.
; Input: none
; Output:
; Destroys: all, OP1, OP2, OP4
handleKeyEnter:
    call parseNum
    call stoX
    call liftStack
    call clearInputBuf

    res rpnFlagsLiftEnabled, (iy + rpnFlags)
    res rpnFlagsEditing, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------
; Arithmetic functions.
;-----------------------------------------------------------------------------

; Function: If currently in edit mode, close the input buffer by parsing the
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
