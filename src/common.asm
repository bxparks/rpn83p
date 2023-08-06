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
; Destroys: A, HL
vPutPS:
    push bc
    ld a, (hl) ; A = length of Pascal string
    or a
    ret z
    ld b, a ; B = num chars
    inc hl ; HL = pointer to start of chars
vPutPN:
    ; implement inlined version of VPutSN() which works with flash string
    ld a, (hl)
    inc hl
    bcall(_VPutMap)
    jr c, vPutPNEnd
    djnz vPutPN
vPutPNEnd:
    pop bc
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

;-----------------------------------------------------------------------------

; Description: Inlined version of bcall(_VPutS) with 2 additional features:
;
; - Works for strings in flash (VPutS only works with strings in RAM).
; - Interprets the `Senter` and `Lenter` characters to move the pen to the
; beginning of the next line.
; - Interprets inline 2 escape characters (escapeLargeFont, escapeSmallFont) to
; change the font used by subsequent characters.
; - Automatically adjusts the line height to be 7px for small fonts and 8px for
; large fonts.
;
; See TI-83 Plus System Routine SDK docs for VPutS() for a reference
; implementation of this function.
;
; Input: HL: pointer to string using small font
; Ouptut:
;    - unlike VPutS(), the CF does *not* show if all of string was rendered
; Destroys: HL
; Preserves: AF, DE, IX (TODO: I think IX preservation can be removed)
smallFontHeight equ 7
largeFontHeight equ 8
escapeLargeFont equ $FE ; pseudo-char to switch to large font
escapeSmallFont equ $FF ; pseudo-char to switch to small font
vPutS:
    push af
    push de
    push ix
    ; assume using small font
    ld c, smallFontHeight ; C = current font height
    res fracDrawLFont, (IY + fontFlags) ; start with small font
vPutSLoop:
    ld a, (hl) ; A = current char
    inc hl
vPutSCheckSpecialChars:
    or a ; Check for NUL
    jr z, vPutSEnd
    cp a, Senter ; Check for Senter (same as Lenter)
    jr z, vPutSEnter
    cp a, escapeLargeFont ; check for large font
    jr z, vPutSLargeFont
    cp a, escapeSmallFont ; check for small font
    jr z, vPutSSmallFont
vPutSNormal:
    bcall(_VPutMap) ; preserves BC, HL
    jr vPutSLoop
vPutSLargeFont:
    ld c, largeFontHeight
    set fracDrawLFont, (IY + fontFlags) ; use large font
    jr vPutSLoop
vPutSSmallFont:
    ld c, smallFontHeight
    res fracDrawLFont, (IY + fontFlags) ; use small font
    jr vPutSLoop
vPutSEnter:
    ; move to the next line
    push af
    push hl
    ld hl, PenCol
    xor a
    ld (hl), a ; PenCol = 0
    inc hl ; PenRow
    ld a, (hl) ; A = PenRow
    add a, c ; A += C (font height)
    ld (hl), a ; PenRow += 7
    pop hl
    pop af
    jr vPutSLoop
vPutSEnd:
    pop ix
    pop de
    pop af
    ret

;-----------------------------------------------------------------------------

; Description: Inlined version of bcall(_PutS) which works for flash
; applications. See TI-83 Plus System Routine SDK docs for PutS() for a
; reference implementation. (I *think* that the _PutC() OS function interprets
; the `Lenter` character as a "newline" and moves the cursor to the next line.
; Need to verify.)
;
; Input: HL: pointer to C-string
; Output:
;   - CF=1 if the entire string was displayed, CF=0 if not
;   - curRow and curCol updated to the position after the last character
; Destroys: HL
putS:
    push bc
    push af
    ld a, (winBtm)
    ld b, a ; B = bottom line of window
putSLoop:
    ld a, (hl)
    inc hl
    or a ; test for end of string
    scf ; CF=1 if entire string displayed
    jr z, putSEnd
    bcall(_PutC)
    ld a, (curRow)
    cp b ; if A >= bottom line: CF=1
    jr c, putSLoop ; repeat if not at bottom
putSEnd:
    pop bc ; restore A (but not F)
    ld a, b
    pop bc
    ret

;-----------------------------------------------------------------------------

; Description: Inlined version of bcall(_PutPS) which works for Pascal strings
; in flash memory.
;
; Input: HL: pointer to Pascal string
; Destroys: A, B, C, HL
; Preserves: DE
putPS:
    ld a, (hl) ; A = length of Pascal string
    inc hl
    or a
    ret z
    ld b, a ; B = length of Pascal string (missing from SDK reference impl)
    ld a, (winBtm)
    ld c, a ; C = bottomRow (usually 8)
putPSLoop:
    ld a, (hl)
    inc hl
    bcall(_PutC)
    ; Check if next character is off-screen
    ld a, (curRow)
    cp c ; if currow == buttomRow: ZF=1
    ret z
    djnz putPSLoop
    ret
