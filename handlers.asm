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

; Function: Append character to inputBuf.
; Input:
;   A: character to be appended
; Output: Carry flag set when append fails
; Destroys: all
appendInputBuf:
    ld hl, inputBuf
    ld b, inputBufMax
    jp appendString

; Function: Append a number character to inputBuf, updating various flags.
; Input:
;   A: character to be appended
; Output:
;   Carry flag set when append fails.
;   (rpnFlagsEditing) set.
;   (displayFlagsInputDirty) set.
; Destroys: all
handleKeyNumber:
    ; If not in edit mode: lift stack and go into edit mode
    ld hl, rpnFlags
    bit rpnFlagsEditing, (hl)
    jr nz, handleKeyNumberContinue
    ; Go into editing mode upon first number key.
    call handleKeyClear
    ; Lift the stack, unless disabled.
    push af
    bit rpnFlagsLiftEnabled, (hl)
    call nz, liftStack
    pop af
handleKeyNumberContinue:
    ; mark input line as dirty
    ld hl, displayFlags
    set displayFlagsInputDirty, (hl)
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
; Output: (inputBufFlags) DecPnt set
; Destroys: A, DE, HL
handleKeyDecPnt:
    ; do nothing if a decimal point already exists
    ld hl, inputBufFlags
    bit inputBufFlagsDecPnt, (hl)
    ret nz
    ; try insert '.'
    ld a, '.'
    call handleKeyNumber
    ret c ; If Carry: append failed so return without setting flag
    ld hl, inputBufFlags
    set inputBufFlagsDecPnt, (hl)
    ret

;-----------------------------------------------------------------------------

; Function: Delete the last character of inputBuf.
;   - If the deleted char was a '.', reset the decimal point flag.
;   - If the deleted char was a '-', reset the negative flag.
; Input: none
; Output: inputBufFlags updated
; Destroys: A, DE, HL
handleKeyDel:
    ld hl, rpnFlags
    set rpnFlagsEditing, (hl)

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
    ld de, inputBufFlags
    ld a, (hl)
handleKeyDelCheckDecPnt:
    ; reset decimal point flag if the deleted character was a '.'
    cp a, '.'
    jr nz, handleKeyDelCheckMinus
    ex de, hl
    res inputBufFlagsDecPnt, (hl)
    ret
handleKeyDelCheckMinus:
    ; reset negative flag if the deleted character was a '-'
    cp a, '-'
    ret nz
    ex de, hl
    res inputBufFlagsManSign, (hl)
    ret

;-----------------------------------------------------------------------------

; Function: Clear the input buffer.
; Input: none
; Output: A=0; inputBuf cleared, inputBufFlags cleared.
; Destroys: A
handleKeyClear:
    call clearInputBuf
    ld hl, rpnFlags
    set rpnFlagsEditing, (hl)
    res rpnFlagsLiftEnabled, (hl)
    ld hl, displayFlags
    set displayFlagsInputDirty, (hl)
    ret

;-----------------------------------------------------------------------------

; Function: Handle (-) change sign.
; Input: none
; Output: none
; Destroys: all
handleKeyChs:
    ld hl, inputBufFlags
    bit inputBufFlagsManSign, (hl)
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
    ld hl, inputBufFlags
    set inputBufFlagsManSign, (hl)
    ret

;-----------------------------------------------------------------------------

; Function: Handle the ENTER key.
; Input: none
; Output:
; Destroys: all, OP1, OP2, OP4
handleKeyEnter:
    call parseNum
    bcall(_StoX) ; X=OP1
    call liftStack
    call clearInputBuf

    ld hl, rpnFlags
    res rpnFlagsLiftEnabled, (hl) ; Disable stack lift.
    res rpnFlagsEditing, (hl) ; Exit edit mode
    ret

;-----------------------------------------------------------------------------

; Function: If currently in edit mode, close the input buffer by parsing the
; input, enable stack lift, then copying the float value into X.
; Input: none
; Output:
; Destroys: all, OP1, OP2, OP4
closeInputBuf:
    ld hl, rpnFlags
    bit rpnFlagsEditing, (hl)
    ret z
    call parseNum
    bcall(_StoX) ; X=OP1
    ld hl, rpnFlags
    res rpnFlagsEditing, (hl)
    set rpnFlagsLiftEnabled, (hl) ; Enable stack lift.
    ret

; Function: Handle the + key.
; Input: none
; Output:
; Destroys: all, OP1, OP2, OP4, OP5
handleKeyAdd:
    call closeInputBuf
    bcall(_RclX)
    bcall(_OP1ToOP5) ; OP5=X
    call dropStack
    bcall(_RclX) ; OP1=Y
    bcall(_OP5ToOP2) ; OP2=X
    bcall(_FPAdd)
    bcall(_StoX)
    ret
