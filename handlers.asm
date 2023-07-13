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

; Function: Append '0' to inputBuf.
; See appendInputBuf()
handleKey0:
    ld a, '0'
    jr appendInputBuf

; Function: Append '1' to inputBuf.
; See appendInputBuf()
handleKey1:
    ld a, '1'
    jr appendInputBuf

; Function: Append '2' to inputBuf.
; See appendInputBuf()
handleKey2:
    ld a, '2'
    jr appendInputBuf

; Function: Append '3' to inputBuf.
; See appendInputBuf()
handleKey3:
    ld a, '3'
    jr appendInputBuf

; Function: Append '4' to inputBuf.
; See appendInputBuf()
handleKey4:
    ld a, '4'
    jr appendInputBuf

; Function: Append '5' to inputBuf.
; See appendInputBuf()
handleKey5:
    ld a, '5'
    jr appendInputBuf

; Function: Append '6' to inputBuf.
; See appendInputBuf()
handleKey6:
    ld a, '6'
    jr appendInputBuf

; Function: Append '7' to inputBuf.
; See appendInputBuf()
handleKey7:
    ld a, '7'
    jr appendInputBuf

; Function: Append '8' to inputBuf.
; See appendInputBuf()
handleKey8:
    ld a, '8'
    jr appendInputBuf

; Function: Append '9' to inputBuf.
; See appendInputBuf()
handleKey9:
    ld a, '9'
    jr appendInputBuf

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
    call appendInputBuf
    ret c ; If Carry: append failed so return without setting flag
    ld hl, inputBufFlags
    set inputBufFlagsDecPnt, (hl)
    ret

; Function: Delete the last character of inputBuf.
;   - If the deleted char was a '.', reset the decimal point flag.
;   - If the deleted char was a '-', reset the negative flag.
; Input: none
; Output: inputBufFlags updated
; Destroys: A, DE, HL
handleKeyDel:
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

; Function: Clear the input buffer.
; Input: none
; Output: A=0; inputBuf cleared, inputBufFlags cleared.
; Destroys: A
handleKeyClear:
    call readNumInit
    call parseNumInit
    ret

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
; Destroys: all
handleKeyEnter:
    call parseNum
    call debugOP1
    ; call liftStack

    ld hl, displayFlags
    set displayFlagsDirty, (hl)
    ret
