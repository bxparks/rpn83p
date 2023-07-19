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

; Function: Prepare to insert a character at position 'A' from a pascal-string,
; shifting characters to the right.
; Input:
;   A: insertPos, range of [0, stringSize]
;   HL: pascal string pointer
;   B: sizeMax of pascal string
; Output:
;   Carry: set if buffer string too long to insert
;   HL: pointer to position at A (if Carry false)
; Destroys: all
insertAtPos:
    ld e, a ; E = insertPos (save)
    ; If stringSize == sizeMax: set Carry flag; return
    ld a, (hl) ; A = stringSize
    cp b ; stringSize == sizeMax
    jr nz, insertAtPosAppendOrShiftRight
    scf
    ret
insertAtPosAppendOrShiftRight:
    cp e ; If stringSize == insertPos
    jr nz, insertAtPosShiftRight
    ; Just append, no need to shift.
    ; stringSize++
    inc (hl)
    ; HL = stringPointer+1+insertPos
    ld d, 0 ; No need to set E, it's already E = insertPos
    add hl, de
    inc hl
    or a ; clear Carry
    ret
insertAtPosShiftRight:
    ; Loop to shift characters to the right, by setting up LDDR parameters:
    ;   HL = stringPointer + stringSize (last character)
    ;   DE = HL+1
    ;   BC = stringSize - insertPos
    ;
    inc (hl) ; stringSize++
    ; BC = A = stringSize - insertPos
    ld d, a ; save stringSize
    sub e ; A = stringSize - insertPos
    ld c, a
    ld b, 0
    ; DE = stringSize
    ld e, d
    ld d, 0
    ; HL = stringPointer + stringSize = last character
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
;   A: deletePos, range of [0, stringSize-1]
;   HL: pascal string pointer
;   B: maxSize
; Output: none
; Destroys: all
deleteAtPos:
    ld e, a ; E = deletePos (save)
    ; If stringSize == 0: return
    ld a, (hl) ; A = stringSize
    or a
    ret z ; do nothing if string is empty
deleteAtPosTruncateOrShiftLeft:
    dec a
    ld (hl), a
    ld d, a ; E = stringSize-1
    ; If deletePos >= stringSize-1: truncate
    ; If !(deletePos < stringSize-1): truncate
    ; If stringSize-1 <= deletePos: truncate
    ; If !(stringSize-1 > deletePos): truncate
    ld a, e ; A = deletePos
    cp d ; If deletePos < stringSize-1: set Carry
    ret nc
    ; A = deletePos
    ; E = deletePos
    ; D = stringSize-1
deleteAtPosShiftLeft:
    ; Set up LDIR parameters:
    ;   DE = stringPointer + deletePos + 1
    ;   HL = DE+1
    ;   BC = stringSize - 1 - deletePos
    ;
    ; BC = stringSize - 1 - deletePos
    ld a, d ; A = stringSize-1
    sub e ; A = stringSize-1 - deletePos
    ld c, a
    ld b, 0
    ; DE = deletePos
    ld d, b ; D=0
    ; HL = stringPointer + deletePos + 1
    add hl, de
    inc hl
    ; DE = HL
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
