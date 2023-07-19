;------------------------------------------------------------------------------
; Routines for debugging, displaying contents of buffers or registers.
;------------------------------------------------------------------------------

; Function: Print out the inputBuf on the debug line.
; Input: parseBuf
; Output:
; Destroys: none
debugInputBuf:
    push af
    push bc
    push de
    push hl
    ld hl, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    ld hl, inputBuf
    bcall(_PutPS)
    ld a, cursorCharAlt
    bcall(_PutC)
    bcall(_EraseEOL)
    pop hl
    pop de
    pop bc
    pop af
    ret

; Function: Print out the parseBuf on the debug line.
; Input: parseBuf
; Output:
; Destroys: none
debugParseBuf:
    push af
    push bc
    push de
    push hl
    ld hl, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    ld hl, parseBuf
    bcall(_PutPS)
    ld a, cursorCharAlt
    bcall(_PutC)
    bcall(_EraseEOL)
    pop hl
    pop de
    pop bc
    pop af
    ret

; Description: Print the value of (inputBufEEPos).
; Input: inputBufEEPos
; Destroys: none
;

;------------------------------------------------------------------------------

; Description: Clear the debug line.
; Destroys: none
debugClear:
    push hl
    ld hl, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    bcall(_EraseEOL)
    pop hl
    ret

;------------------------------------------------------------------------------

; Function: Print out OP1 at debug line.
; Input: OP1
; Output:
; Destroys: OP3
debugOP1:
    push af
    push bc
    push de
    push hl
    ld hl, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    ld a, 15 ; width of output
    bcall(_FormReal)
    ld hl, OP3
    bcall(_PutS)
    bcall(_EraseEOL)
    pop hl
    pop de
    pop bc
    pop af
    ret

;------------------------------------------------------------------------------

; Description: Print the value of the inputBufEEPos variable.
; Input: none
; Output: A printed on debug line
; Destroys: none
debugEEPos:
    push af
    ld a, (inputBufEEPos)
    call debugUnsignedA
    pop af
    ret

;------------------------------------------------------------------------------

; Function: Print the unsigned A on the debug line.
; Input: A
; Output: A printed on debug line
; Destroys: none
debugUnsignedA:
    push af
    push bc
    push de
    push hl
    ld hl, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    ld l, a
    ld h, 0
    bcall(_DispHL)
    pop hl
    pop de
    pop bc
    pop af
    ret

;------------------------------------------------------------------------------

; Function: Print the signed A on the debug line.
; Input: A
; Output: A printed on debug line
; Destroys: none
debugSignedA:
    push af
    push bc
    push de
    push hl
    ld hl, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
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

; Function: Print some of the display and RPN flags on the debug line.
;   - I: input dirty
;   - E: editing
;   - L: stack lift disabled
;   - S: stack dirty
; Input: (iy+rpnFlags), (iy+inputBufFlags)
; Output: Flags printed on debug line.
; Destroys: none
debugFlags:
    push af
    push bc
    push de
    push hl

    ld hl, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (CurRow), hl

    ; Print Input dirty flag
    bit inputBufFlagsInputDirty, (iy + inputBufFlags)
    ld a, 'I'
    call printFlag

    ; Print Editing flag
    bit rpnFlagsEditing, (iy + rpnFlags)
    ld a, 'E'
    call printFlag

    ld a, ' '
    bcall(_PutC)

    ; Print Lift flag
    bit rpnFlagsLiftEnabled, (iy + rpnFlags)
    ld a, 'L'
    call printFlag

    ld a, ' '
    bcall(_PutC)

    ld a, ' '
    bcall(_PutC)

    ; Print Stack dirty flag
    bit rpnFlagsStackDirty, (iy + rpnFlags)
    ld a, 'S'
    call printFlag

    bcall(_EraseEOL)

    pop hl
    pop de
    pop bc
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
