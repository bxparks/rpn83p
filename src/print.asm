;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Printing utilities, mostly wrappers or reimplementations of the underlying
; TI-OS bcall() routines. Some TI-OS routines work only from assembly language
; programs in RAM, and do not work from flash apps. They need to be
; reimplemented here so that they reside in the same flash page as the string
; that they will handle.
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

; Description: Call vPutPS() using small font.
vPutSmallPS:
    res fracDrawLFont, (iy + fontFlags) ; use small font
    ; [[fallthrough]]

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

; Description: Convenience wrapper around SStringLength() that works for
; zero-length strings.
; Input: HL: Pascal string, in RAM
; Output: A = B = number of pixels
; Destroys: all but HL
smallStringWidth:
    ld a, (hl)
    or a
    ld b, a
    ret z
    bcall(_SStringLength) ; A, B = stringWidth; HL preserved
    ret

;-----------------------------------------------------------------------------

; Description: Erase to end of line using small font. Same as bcall(_EraseEOL).
; Prints a quad space (4 pixels side) as many times as necessary to overwrite
; the remainder of the line.
; Destroys: A, B
vEraseEOL:
    ld a, (penCol)
    sub 96 ; if A>=96: CF=0
    ret nc
    neg ; A=96-penCol=numPixelsToEnd
    add a, 3 ; A=numPixelsToEnd+3
    srl a
    srl a ; A=numSpacesToPrint=(numPixelsToEnd+3)/4
    ld b, a
vEraseEOLLoop:
    ld a, SFourSpaces
    bcall(_VPutMap)
    djnz vEraseEOLLoop
    ret

;-----------------------------------------------------------------------------

; Description: Print the HL string using VPutMap(), using small font.
; Input: HL: pointer to C-string
; Output:
;    - unlike VPutS(), the CF does *not* show if all of string was rendered
; Destroys: all
vPutSmallS:
    res fracDrawLFont, (iy + fontFlags) ; use small font
    ; [[fallthrough]]

; Description: Inlined version of bcall(_VPutS) so that it works for strings in
; flash (VPutS only works with strings in RAM). See TI-83 Plus System Routine
; SDK docs for VPutS() for a reference implementation of this function. See
; also eVPutS() for an extended version of this that supported embedded font
; control characters.
;
; Input: HL: pointer to string
; Ouptut:
;    - unlike VPutS(), the CF does *not* show if all of string was rendered
; Destroys: all
vPutS:
vPutSLoop:
    ld a, (hl) ; A = current char
    inc hl
    or a ; Check for NUL
    ret z
    bcall(_VPutMap) ; preserves BC, HL
    jr vPutSLoop

;-----------------------------------------------------------------------------

; Description: Inlined version of bcall(_PutS) which works for flash
; applications. See TI-83 Plus System Routine SDK docs for PutS() for a
; reference implementation. The _PutC() OS function interprets the `Lenter`
; character as a "newline" and moves the cursor to the next line. BUT, it also
; seems to add a ':' on the next line (as a continuation marker?), which we do
; NOT want. So we handle the Lenter ourselves.
;
; Input: HL: pointer to C-string
; Output:
;   - CF=1 if the entire string was displayed, CF=0 if not
;   - curRow and curCol updated to the position after the last character
; Destroys: HL
; Preserves: A, BC
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
    cp Lenter ; check for newline
    jr z, putSEnter
    bcall(_PutC)
putSCheck:
    ld a, (curRow)
    cp b ; if A >= bottom line: CF=1
    jr c, putSLoop ; repeat if not at bottom
putSEnd:
    pop bc ; restore A (but not F)
    ld a, b
    pop bc
    ret
putSEnter:
    ; Handle newline
    push hl
    ld hl, (CurRow)
    inc l ; CurRow++
    ld h, 0 ; CurCol=0
    ld (CurRow), hl
    pop hl
    jr putSCheck

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

;-----------------------------------------------------------------------------

; Description: Convert A into an Ascii Char ('0'-'9','A'-'F').
; Destroys: A
convertAToChar:
    cp 10
    jr c, convertAToCharDecimal
    sub 10
    add a, 'A'
    ret
convertAToCharDecimal:
    add a, '0'
    ret
