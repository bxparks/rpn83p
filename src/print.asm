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
; Input: HL:(PascalString*)=pstring in RAM
; Output: A=B=number of pixels
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
;
; There are 2 loops below, one printing quad-column spaces, and one printing
; single-column spaces. There seems to be a bug with VPutMap() where the very
; last pixel column does not seem get erased properly with an SFourSpaces
; character. If the character on the last column is a '}' for example, a single
; dot from the point of the '}' remains on the screen. If we switch to printing
; single-column wide Sspace for the last 4 pixels, the problem seems to go
; away.
;
; Destroys: A, B
vEraseEOL:
    ld a, (penCol)
    sub 96 ; if A>=96: CF=0
    ret nc
    neg ; A=96-penCol=numPixelsToEnd
    add a, 3 ; A=numPixelsToEnd+3
    srl a
    srl a ; A=numSpacesToPrint=(numPixelsToEnd+3)/4
    dec a
    jr z, vEraseEOLSingles ; switch to print single-spaces for the last 4
vEraseEOLQuads:
    ld b, a
vEraseEOLLoop:
    ld a, SFourSpaces
    bcall(_VPutMap)
    djnz vEraseEOLLoop
vEraseEOLSingles:
    ld b, 4
vEraseEOLLoop2:
    ld a, Sspace
    bcall(_VPutMap)
    djnz vEraseEOLLoop2
    ret

;-----------------------------------------------------------------------------

; Description: Print the HL string using VPutMap(), using small font. If the
; string is too long to fit into the current line, we print 2 dots (4 pixels
; wide) are printed at the end to indicate truncation.
;
; I would have thought that checking for penCol>=92 would have been sufficient,
; since the display is 96 pixels wide, and a dot is only 2 pixels wide. But it
; turns out that VPutMap() function has some strange, undocumented behavior, so
; penCol>=89 seems to work a lot better.
;
; It has been hard to characterize the exact behavior of VPutMap() at the end
; of the line. Even if there are 4 pixels available at the end of the line, it
; does not want to write a 4-pixel wide character. Furthermore, if the
; character does not fit, it is simply ignored, penCol is not updated, and a
; subsequent call to VPutMap() with a narrow enough character will print that
; narrow character into that space. So sometimes, some random character at the
; end seems to have been lost.
;
; Input:
;   - HL:(char*)=cstring
; Output:
;    - unlike VPutS(), the CF does *not* show if all of string was rendered
; Destroys: all
vPutSmallS:
    res fracDrawLFont, (iy + fontFlags) ; use small font
vPutSmallSLoop:
    ld a, (hl) ; A = current char
    inc hl
    or a ; Check for NUL
    ret z
    ; Check if the string is too long. Check for overflow into the last 8
    ; pixels instead of the last 6 pixels because this is a variable-sized
    ; font, and the the previous character could have been a 4 pixel-wide
    ; character that could bled into the last 6 pixels. Also, there's some
    ; funny business with vPutMap() that I cannot quite characterize. With 8
    ; spaces, we get more flexibility.
    ld b, a ; B=saved A
    ld a, (penCol)
    cp 88
    jr nc, vPutSmallSMaybeTruncate
    ld a, b ; A=restored A
    bcall(_VPutMap) ; preserves BC, HL
    jr vPutSmallSLoop
vPutSmallSMaybeTruncate:
    ; Check if the current chara is actually the very last character. If so,
    ; there ought be enough space on the display for it, so just print that.
    ; Otgherwise, print 3 dots (ellipsis) to indicate truncation.
    ld a, (hl)
    or a
    jr z, vPutSmallSLastChar
    ld a, '.'
    bcall(_VPutMap)
    ld a, '.'
    bcall(_VPutMap)
    ld a, '.'
    bcall(_VPutMap)
    ret
vPutSmallSLastChar:
    ld a, b ; A=lastChar
    bcall(_VPutMap)
    ret

; Description: Inlined version of bcall(_VPutS) so that it works for strings in
; flash (VPutS only works with strings in RAM). See TI-83 Plus System Routine
; SDK docs for VPutS() for a reference implementation of this function. See
; also eVPutS() for an extended version of this that supported embedded font
; control characters.
;
; Input:
;   - HL:(char*)=cstring
; Ouptut:
;    - unlike VPutS(), CF does *not* show if all of string was rendered
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
; Input:
;   - HL:(char*)=cstring
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
    ld hl, (curRow)
    inc l ; curRow++
    ld h, 0 ; CurCol=0
    ld (curRow), hl
    pop hl
    jr putSCheck

;-----------------------------------------------------------------------------

; Description: Inlined version of bcall(_PutPS) which works for Pascal strings
; in flash memory.
;
; Input:
;   - HL:(PascalString*)=pstring
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
