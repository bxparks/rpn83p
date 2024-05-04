;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Low-level routines for manipulating Pascal strings, similar to pstring.asm
; but located in Flash Page 1.
;
; This is now on Flash Page 1. Labels with Capital letters are intended to be
; exported to other flash pages and should be placed in the branch table on
; Flash Page 0. Labels with lowercase letters are intended to be private so do
; not need a branch table entry.
;-----------------------------------------------------------------------------

; Description: Append character to pascal-string buffer.
; Input:
;   A: character to be appended
;   HL: pascal string pointer
;   B: maxSize
; Output: CF set when append fails
; Destroys: all
AppendString:
    ld c, a ; C = char
    ld a, (hl) ; A = bufSize
    cp b
    jr nz, appendStringNotFull
    ; buffer full, set CF
    scf
    ret
appendStringNotFull:
    ; Go to end of string
    inc a
    ld (hl), a
    ld d, 0
    ld e, a
    add hl, de
    ld (hl), c
    or a ; clear CF
    ret

;-----------------------------------------------------------------------------

; Description: Prepare to insert a character at position 'A' from a
; pascal-string, shifting characters to the right.
; Input:
;   - A:u8=insertPos, range of [0, stringSize]
;   - B:u8=pascalStringSizeMax
;   - HL:(PascalString*)
; Output:
;   - CF=1 if insert failed due to string too long
;   - HL:(const char*)=pointer to position at A (if CF==0)
; Destroys: all
InsertAtPos:
    ld e, a ; E = insertPos (save)
    ; If stringSize == sizeMax: set CF; return
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
    or a ; clear CF
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
    or a ; clear CF
    ret

; Description: Delete character at position A from a pascal-string, shifting
; characters to the left.
; Input:
;   A: deletePos, range of [0, stringSize-1]
;   HL: pascal string pointer
;   B: maxSize
; Output: none
; Destroys: all
DeleteAtPos:
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
    cp d ; If deletePos < stringSize-1: set CF
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

#if 0
; Description: Return the first character in the Pascal string, or 0 if the
; string is empty.
; Input:
;   - HL:(PascalStrign*)=pascalString
; Output:
;   - A:char=firstChar (0 if empty)
; Destroys: A
; Preserves: BC, DE, HL
GetFirstChar:
    ld a, (hl)
    or a
    ret z
    inc hl ; skip past the len byte
    ld a, (hl)
    dec hl
    ret
#endif

; Description: Return the last character in the Pascal string, or 0 if the
; string is empty.
; Input: HL: Pascal string pointer
; Output: A: lastChar (0 if empty)
; Destroys: A, BC, HL
; Preserves: DE
GetLastChar:
    ld a, (hl)
    or a
    ret z
    ; No need to 'inc hl' to skip past the size byte, since we'd have to do a
    ; 'dec hl' anyway.
    ld c, a
    ld b, 0
    add hl, bc
    ld a, (hl)
    ret

;-----------------------------------------------------------------------------

; Description: Find the given character in the given pascal string.
; Input:
;   - A:char=searchChar
;   - HL:(PascalString*)=pascalString
; Output:
;   - CF=1 if found, 0 if not found
;   - HL:(char*)=posOfChar (if found)
; Destroys: BC, HL
; Preserves: A, DE, HL
findChar:
    push hl
    ld c, a ; C=searchChar
    ld a, (hl) ; B=stringSize
    ; check for empty string
    or a
    ld b, a ; B=stringSize
    ld a, c ; A=searchChar
    ret z
findCharLoop:
    inc hl
    cp (hl)
    jr z, findCharLoopFound
    djnz findCharLoop
    ; not found
    or a ; CF=0
    pop hl
    ret
findCharLoopFound:
    scf
    pop hl
    ret

;-----------------------------------------------------------------------------

; Description: Prepare the given pascal string in HL by appending a NUL
; character at the end. This assumes that the capacity of the pascal string
; buffer is one more than the length limit of the pascal string.
; Input:
;   - HL:(PascalString*)=string
; Output:
;   - NUL appended to the end
; Destroys: A
; Preserves: BC, DE, HL
preparePascalStringForParsing:
    push hl
    push de
    ld e, (hl)
    xor a
    ld d, a
    inc hl ; skip len byte
    add hl, de ; HL=pointerToNUL
    ld (hl), a
    pop de
    pop hl
    ret
