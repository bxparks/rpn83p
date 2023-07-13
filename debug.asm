;------------------------------------------------------------------------------
; Routines for debugging, displaying contents of buffers or registers.
;------------------------------------------------------------------------------

; Function: Print out the inputBuf on the status line.
; Input: parseBuf
; Output:
; Destroys: A, HL
debugInputBuf:
    ld hl, statusCurCol*$100+statusCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    ld hl, inputBuf
    bcall(_PutPS)
    ld a, cursorCharAlt
    bcall(_PutC)
    bcall(_EraseEOL)
    ret

; Function: Print out the parseBuf on the status line.
; Input: parseBuf
; Output:
; Destroys: A, HL
debugParseBuf:
    ld hl, statusCurCol*$100+statusCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    ld hl, parseBuf
    bcall(_PutPS)
    ld a, cursorCharAlt
    bcall(_PutC)
    bcall(_EraseEOL)
    ret

;------------------------------------------------------------------------------

; Function: Print out OP1 at status line.
; Input: OP1
; Output:
; Destroys: all registers, OP3
debugOP1:
    ld hl, statusCurCol*$100+statusCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    ld a, 15 ; width of output
    bcall(_FormReal)
    ld hl, OP3
    bcall(_PutS)
    bcall(_EraseEOL)
    ret

;------------------------------------------------------------------------------

; Function: Print the unsigned A on the status line.
; Input: A
; Output: A printed on status line
; Destroys: none
debugUnsignedA:
    push af
    push de
    push hl
    ld hl, statusCurCol*$100+statusCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    ld l, a
    ld h, 0
    bcall(_DispHL)
    pop hl
    pop de
    pop af
    ret

;------------------------------------------------------------------------------

; Function: Print the signed A on the status line.
; Input: A
; Output: A printed on status line
; Destroys: none
debugSignedA:
    push af
    push bc
    push de
    push hl
    ld hl, statusCurCol*$100+statusCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    ld b, a ; save
    bit 7, a
    jr z, debugSignedAPositive
debugSignedANegative:
    ld a, '-'
    bcall(_PutC)
    ld a, b
    neg
    jr debugSignedAPrint
debugSignedAPositive:
    ld a, ' '
    bcall(_PutC)
    ld a, b
debugSignedAPrint:
    ld l, a
    ld h, 0
    bcall(_DispHL)
    pop hl
    pop de
    pop bc
    pop af
    ret

;------------------------------------------------------------------------------

; Function: Print some of the display and RPN flags.
; Input: (displayFlags), (rpnFlags)
; Output: Flags printed on status line.
; Destroys: none
debugFlags:
    push af
    push hl
    ld hl, statusCurCol*$100+statusCurRow ; $(curCol)(curRow)
    ld (CurRow), hl

    ; Print Editing flag
    ld hl, rpnFlags
    bit rpnFlagsEditing, (hl)
    ld a, 'E'
    call printFlag

    ld a, ' '
    bcall(_PutC)

    ; Print Lift flag
    ld hl, rpnFlags
    bit rpnFlagsLiftDisabled, (hl)
    ld a, 'L'
    call printFlag

    ld a, ' '
    bcall(_PutC)

    ; Print Input dirty flag
    ld hl, displayFlags
    bit displayFlagsInputDirty, (hl)
    ld a, 'I'
    call printFlag

    ld a, ' '
    bcall(_PutC)

    ; Print Stack dirty flag
    ld hl, displayFlags
    bit displayFlagsStackDirty, (hl)
    ld a, 'S'
    call printFlag

    bcall(_EraseEOL)

    pop hl
    pop af
    ret

; Function: Print the character in reg A, and a +/- depending on Z flag.
; Input:
;   A: flag char (e.g. 'I', 'E')
;   CF: 1 or 0
; Output:
;   Flag character with '+' or '-', e.g. "I+", "E+"
; Destroys: A
printFlag:
    jr z, printFlagMinus
printFlagPlus:
    bcall(_PutC)
    ld a, '+'
    bcall(_PutC)
    ret
printFlagMinus:
    bcall(_PutC)
    ld a, '-'
    bcall(_PutC)
    ret
