;-----------------------------------------------------------------------------
; Common utilties that are useful in multiple modules.
;-----------------------------------------------------------------------------

; Description: Get the string pointer at index A given an array of pointers at
; base pointer HL.
; Input:
;   A: index
;   HL: pointer to an array of pointers
; Output: HL: pointer to a string
; Destroys: DE, HL
; Preserves: A
getString:
    ld e, a
    ld d, 0
    add hl, de ; HL += A * 2
    add hl, de
    ld e, (hl)
    inc hl
    ld d, (hl)
    ex de, hl
    ret

;-----------------------------------------------------------------------------

; Description: Copy the C string in HL to the Pascal string in DE. The C string
; is longer than the destination Pascal string buffer, it is truncated to the
; max length given by C.
; Input:
;   HL: source C string
;   DE: destination Pascal string buffer (with leading size byte)
;   C: max size of Pascal string buffer (assumed to be > 0)
; Output:
;   - buffer at DE updated
;   - A: actual size of Pascal string
; Destroys: A, B, HL
; Preserves: C, DE
copyCToPascal:
    push de ; save pointer to the Pascal string
    ld b, c ; B = max size
    inc de
copyCToPascalLoop:
    ld a, (hl)
    or a ; check for terminating NUL character in C string
    jr z, copyCToPascalLoopEnd
    ld (de), a
    inc hl
    inc de
    djnz copyCToPascalLoop
copyCToPascalLoopEnd:
    ld a, c ; A = max size
    sub a, b ; A = actual size of Pascal string
    pop de ; DE = pointer to Pascal string size byte
    ld (de), a ; save actual Pascal string size
    ret

;-----------------------------------------------------------------------------

; Description: Append character A to the C-string at HL. Assumes that HL points
; to a buffer big enough to hold one more character.
; Input:
;   - HL: pointer to C-string
;   - A: character to add
; Destroys: none
appendCString:
    push hl
    push af
    jr appendCStringLoopEntry
appendCStringLoop:
    inc hl
appendCStringLoopEntry:
    ld a, (hl)
    or a
    jr nz, appendCStringLoop
appendCStringAtEnd:
    pop af
    ld (hl), a
    inc hl
    ld (hl), 0
    pop hl
    ret

;-----------------------------------------------------------------------------

; Description: Print char A the multiple times.
; Input:
;   - A: char to print
;   - B: number of times
; Destroys: A, BC, DE, HL
printARepeatB:
    ld c, a ; C = char to print (saved)
    ; Check for B == 0
    ld a, b
    or a
    ret z
printARepeatBLoop:
    ld a, c
    bcall(_VPutMap) ; destroys A, DE, HL, but not BC
    djnz printARepeatBLoop
    ret

;-----------------------------------------------------------------------------

; Description: Convenience wrapper around VPutSN() that works for zero-length
; strings. Also provides an API similar to PutPS() which takes a pointer to a
; Pascal string directly, instead of providing the length and (char*)
; separately.
; Input: HL: Pascal-string
; Output; CF=1 if characters overflowed screen
; Destroys: A, B, HL
vPutPS:
    ld a, (hl)
    or a
    ret z
    ld b, a ; B = num chars
    inc hl ; HL = pointer to start of chars
    bcall(_VPutSN)
    ret

;-----------------------------------------------------------------------------

; Description: Convenience rapper around SStringLength() that works for
; zero-length strings.
; Input: HL: Pascal string, in RAM
; Output: A = B = number of pixels
; Destroys: all but HL
sStringWidth:
    ld a, (hl)
    or a
    ld b, a
    ret z
    bcall(_SStringLength) ; A, B = stringWidth; HL preserved
    ret

;-----------------------------------------------------------------------------

; Function: Erase to end of line using small font. Same as bcall(_EraseEOL).
; Prints a quad space (4 pixels side), 24 times, for 96 pixels.
; Destroys: B
vEraseEOL:
    ld b, 24
vEraseEOLLoop:
    ld a, SFourSpaces
    bcall(_VPutMap)
    djnz vEraseEOLLoop
    ret

; Description: Inlined version of bcall(_VPutS) which has 2 advantages:
; 1) It works for strings which are in flash (VPutS only works with strings in
; RAM).
; 2) It interprets the `Senter` character to move the pen to the beginning of
; the next line. A line using small font is 7 px high.
;
; See TI-83 Plus System Routine SDK docs for VPutS() for a reference
; implementation of this function.
;
; Input: HL: pointer to string using small font
; Destroys: HL
smallFontHeight equ 7
vPutS:
    push af
    push de
    push ix
vPutSLoop:
    ld a, (hl)
    inc hl
    or a
    jr z, vPutSEnd
    cp a, Senter
    jr nz, vPutSNormal
vPutSenter:
    ; move to the next line
    push af
    push hl
    ld hl, PenCol
    xor a
    ld (hl), a ; PenCol = 0
    inc hl ; PenRow
    ld a, (hl) ; A = PenRow
    add a, smallFontHeight
    ld (hl), a ; PenRow += 7
    pop hl
    pop af
vPutSNormal:
    bcall(_VPutMap)
    jr nc, vPutSLoop
vPutSEnd:
    pop ix
    pop de
    pop af
    ret
