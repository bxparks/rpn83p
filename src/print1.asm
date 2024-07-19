;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Print routines similar to print.asm but located in Flash Page 1.
;
; Capitalized labels are intended to be exported to the branch table on flash
; page 0. Lowercased labels are intended to be local to the current flash page.
;-----------------------------------------------------------------------------

; Description: Inlined and extended version of bcall(_VPutS) with additional
; features. Place on flash Page 1 so that routines on that page can access
; this.
;
;   - Works for strings in flash (VPutS only works with strings in RAM).
;   - Interprets the `Senter` and `Lenter` characters to move the pen to the
;   beginning of the next line.
;   - Supports inlined escape characters (escapeLargeFont, escapeSmallFont) to
;   change the font dynamically.
;   - Automatically adjusts the line height to be 7px for small font and 8px
;   for large font.
;
; See TI-83 Plus System Routine SDK docs for VPutS() for a reference
; implementation of this function.
;
; Input:
;   - HL:(char*)=cstring
; Ouptut:
;    - unlike VPutS(), the CF does *not* show if all of string was rendered
; Destroys: all
escapeLargeFont equ $FE ; pseudo-char to switch to large font
escapeSmallFont equ $FF ; pseudo-char to switch to small font
eVPutS:
    ; assume using small font
    ld c, smallFontHeight ; C = current font height
    res fracDrawLFont, (iy + fontFlags) ; start with small font
eVPutSLoop:
    ld a, (hl) ; A = current char
    inc hl
eVPutSCheckSpecialChars:
    or a ; Check for NUL
    ret z
    cp a, Senter ; Check for Senter (same as Lenter)
    jr z, eVPutSEnter
    cp a, escapeLargeFont ; check for large font
    jr z, eVPutSLargeFont
    cp a, escapeSmallFont ; check for small font
    jr z, eVPutSSmallFont
eVPutSNormal:
    bcall(_VPutMap) ; preserves BC, HL
    jr eVPutSLoop
eVPutSLargeFont:
    ld c, largeFontHeight
    set fracDrawLFont, (iy + fontFlags) ; use large font
    jr eVPutSLoop
eVPutSSmallFont:
    ld c, smallFontHeight
    res fracDrawLFont, (iy + fontFlags) ; use small font
    jr eVPutSLoop
eVPutSEnter:
    ; move to the next line
    push af
    push hl
    ld hl, penCol
    xor a
    ld (hl), a ; penCol = 0
    inc hl ; PenRow
    ld a, (hl) ; A = PenRow
    add a, c ; A += C (font height)
    ld (hl), a ; PenRow += 7
    pop hl
    pop af
    jr eVPutSLoop

;------------------------------------------------------------------------------

; Description: Inlined version of bcall(_PutPS) which works for Pascal strings
; in flash memory. For Flash Page 1. Identical to putPS() but located in Flash
; Page 1.
;
; Input: HL:(PascalString*)=pstring
; Destroys: A, B, C, HL
; Preserves: DE
putPSPageOne:
    ld a, (hl) ; A = length of Pascal string
    inc hl
    or a
    ret z
    ld b, a ; B = length of Pascal string (missing from SDK reference impl)
    ld a, (winBtm)
    ld c, a ; C = bottomRow (usually 8)
putPSPageOneLoop:
    ld a, (hl)
    inc hl
    bcall(_PutC)
    ; Check if next character is off-screen
    ld a, (curRow)
    cp c ; if currow == buttomRow: ZF=1
    ret z
    djnz putPSPageOneLoop
    ret

;------------------------------------------------------------------------------

; Description: Inlined version of bcall(_PutS), identical to putS().
;
; Input:
;   HL:(char*)=cstring
; Output:
;   - CF=1 if the entire string was displayed, CF=0 if not
;   - curRow and curCol updated to the position after the last character
; Destroys: HL
putSPageOne:
    push bc
    push af
    ld a, (winBtm)
    ld b, a ; B = bottom line of window
putSPageOneLoop:
    ld a, (hl)
    inc hl
    or a ; test for end of string
    scf ; CF=1 if entire string displayed
    jr z, putSPageOneEnd
    cp Lenter ; check for newline
    jr z, putSPageOneEnter
    bcall(_PutC)
putSPageOneCheck:
    ld a, (curRow)
    cp b ; if A >= bottom line: CF=1
    jr c, putSPageOneLoop ; repeat if not at bottom
putSPageOneEnd:
    pop bc ; restore A (but not F)
    ld a, b
    pop bc
    ret
putSPageOneEnter:
    ; Handle newline
    push hl
    ld hl, (curRow)
    inc l ; curRow++
    ld h, 0 ; CurCol=0
    ld (curRow), hl
    pop hl
    jr putSPageOneCheck

;------------------------------------------------------------------------------

; Description: Version of bcall(_VPutS) and vPutS() that works for Flash Page 1.
; See also eVPutS() for an extended version of this that supported embedded
; font control characters.
;
; Input:
;   - HL:(char*)=cstring
; Ouptut:
;   - unlike VPutS(), CF does *not* show if all of string was rendered
; Destroys: all
vPutSPageOne:
    ; assume using small font
    ld c, smallFontHeight ; C = current font height
    res fracDrawLFont, (iy + fontFlags) ; start with small font
vPutSPageOneLoop:
    ld a, (hl) ; A = current char
    inc hl
vPutSPageOneCheckSpecialChars:
    or a ; Check for NUL
    ret z
    bcall(_VPutMap) ; preserves BC, HL
    jr vPutSPageOneLoop
