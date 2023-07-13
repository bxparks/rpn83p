;------------------------------------------------------------------------------
; Routines for debugging, displaying contents of buffers or registers.
;------------------------------------------------------------------------------

; Function: Print out the parseBuf at status line.
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

; Function: Print out OP1 at stack Z register row 'stZCurRow'.
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
    pop af
    ret
