;-----------------------------------------------------------------------------

; Function: Append character to pascal-string buffer.
; Input:
;   A: character to be appended
;   HL: pascal string pointer
;   B: maxSize
; Output: Carry flag set when append fails
; Destroys: all
appendString:
    ld c, a ; C = char
    ld a, (hl) ; A = bufSize
    cp b
    jr nz, appendString10
    ; buffer full, set Carry flag
    scf
    ret
appendString10:
    ; Go to end of string
    inc a
    ld (hl), a
    ld d, 0
    ld e, a
    add hl, de
    ld (hl), c
    or a ; clear Carry flag
    ret

;-----------------------------------------------------------------------------

; Function: Insert character at position 'A' from a pascal-string, shifting
; characters to the right.
; Input:
;   A: insertPos (often 0, due to minus sign)
;   HL: pascal string pointer
;   B: sizeMax of pascal string
; Output:
;   Carry: set if buffer string too long to insert
;   HL: pointer to position at A (if Carry false)
; Destroys: all
insertAtPos:
    ld d, a ; D = insertPos (save)
    ; If stringSize == sizeMax: set Carry flag; return
    ld a, (hl) ; A = stringSize
    cp b
    ld b, d ; B = insertPos (save)
    jr nz, insertAtPos10
    scf
    ret
insertAtPos10:
    ; If stringSize == 0: increment stringSize; return
    or a
    jr nz, insertAtPos20
    ; stringSize++
    inc a
    ld (hl), a
    ; HL = stringPointer+1, insertion address
    inc hl
    or a ; clear Carry
    ret
insertAtPos20:
    ; Loop to shift characters to the right.
    ; C = stringSize
    ld c, a
    ; stringSize++
    inc a
    ld (hl), a
    ; Setup LDDR parameters:
    ;   HL = stringPointer + stringSize (last character)
    ;   DE = HL+1
    ;   BC = stringSize - insertPos
    ; DE = stringSize
    ld e, c
    ld d, 0
    ; BC = stringSize - insertPos
    ld a, c
    sub b
    ld c, a
    ld b, 0
    ; HL = stringPointer + stringSize
    add hl, de
    ; DE = HL + 1
    ld d, h
    ld e, l
    inc de
    ; shift
    lddr
    ; HL = insertion address
    ld h, d
    ld l, e
    or a ; clear Carry
    ret

; Function: Delete character at position A from a pascal-string, shifting
; characters to the left.
; Input:
;   A: insertPos (often 0, due to minus sign)
;   HL: pascal string pointer
;   B: maxSize
; Output: none
; Destroys: all
deleteAtPos:
    ld d, a ; D = insertPos (save)
    ; If stringSize == 0: return
    ld a, (hl) ; A = stringSize
    or a
    ret z
    ; stringSize--
    dec a
    ld (hl), a
    ; If --stringSize == 0: return
    ret z
    ; Set up LDIR parameters:
    ;   DE = stringPointer + insertPos + 1
    ;   HL = DE+1
    ;   BC = stringSize - 1
    ; DE = insertPos
    ld e, d
    ld d, 0
    ; BC = stringSize - 1
    ld c, a
    ld b, d
    ; HL = stringPointer + insertPos
    add hl, de
    inc hl
    ; DE = stringPointer + insertPos + 1
    ld d, h
    ld e, l
    ; HL = DE + 1
    inc hl
    ; shift
    ldir
    ret

;-----------------------------------------------------------------------------

; Function: Find the given character in the given pascal string.
; Input:
;   A: character to find
;   HL: pointer to pascal string
; Output:
;   A: position of character A. Returns len(string) if not found. Returns
;   0 if string is empty.
; Destroys: A, BC, D, HL
findChar:
    ld c, a ; C = char (save)
    ld b, (hl) ; B = stringSize
    ; Return stringSize == 0
    ld a, b
    or a
    ret z
    ld d, a ; D = stringSize (save)
    inc hl
findCharLoop:
    ld a, (hl)
    cp c
    jr z, findCharLoopFound
    inc hl
    djnz findCharLoop
findCharLoopFound:
    ld a, d ; A = stringSize
    sub b ; A = stringSize - B
    ret
