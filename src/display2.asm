;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Spillovers from display.asm into Flash Page 2.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Print the menu name in HL to the menu penCol in C, using the
; small and inverted font, centering the menu name in the middle of the 18 px
; width of a menu box.
; Inputs:
;   - A:u8=numRows (ignored but must be preserved)
;   - B:u8=loopCounter (must be preserved)
;   - C:u8=penCol (must be preserved)
;   - E:u8=menuIndex [0-4] (ignored but must be preserved, useful for debugging)
;   - HL:(const char*)=menuName
; Destroys: HL
; Preserves: AF, BC, DE
PrintMenuNameAtC:
    push af ; stack=[numRows]
    push bc ; stack=[numRows, loopCounter/penCol]
    push de ; stack=[numRows, loopCounter/penCol,menuIndex]
    ; Set (PenCol,PenRow), preserving HL
    ld a, c ; A=penCol
    ld (PenCol), a
    ld a, menuPenRow
    ld (PenRow), a
    ; Predict the width of menu name.
    ld de, menuName
    ld c, menuNameBufMax
    call copyCToPascalPageTwo ; C, DE are preserved
    ex de, hl ; HL = menuName
    call smallStringWidthPageTwo ; A = B = string width
printMenuNameAtCNoAdjust:
    ; Calculate the starting pixel to center the string
    ld a, menuPenWidth
    sub b ; A = menuPenWidth - stringWidth
    jr nc, printMenuNameAtCFitsInside
printMenuNameAtCTooWide:
    xor a ; if string too wide (shouldn't happen), set to 0
printMenuNameAtCFitsInside:
    ; Add 1px to the total padding so that when divided between left and right
    ; padding, the left padding gets 1px more if the total padding is an odd
    ; number. This allows a few names which are 17px wide to actually fit
    ; nicely within the 18px box (with 1px padding on each side), because each
    ; small font character actually has an embedded 1px padding on the right,
    ; so effectively it is only 16px wide. This tweak allows short names (whose
    ; widths are an odd number of px) to be centered perfectly with equal
    ; padding on both sides.
    inc a
    rra ; CF=0, divide by 2 for centering; A = padWidth
    ;
    ld c, a ; C = A = leftPadWidth
    push bc ; B=stringWidth; C=leftPadWidth
    set textInverse, (iy + textFlags)
    ; The code below sets the textEraseBelow flag to fix a font rendering
    ; problem on the very last row of pixels on the LCD display, where the menu
    ; names are printed.
    ;
    ; The menu names are printed using the small font, which are 4px (w) by 7px
    ; (h) for capital letters, including a one px padding on the right and
    ; bottom of each letter. Each menu name is drawn on the last 7 piexel rows
    ; of the LCD screen, in other words, at penRow of 7*8+1 = 57. When the
    ; characters are printed using `textInverse`, the last line of pixels just
    ; below each menu name should be black (inverted), and on the assembly
    ; version of this program, it is. But in the flash app version, the line of
    ; pixels directly under the letter is white. Setting this flag fixes that
    ; problem.
    set textEraseBelow, (iy + textFlags)
printMenuNameAtCLeftPad:
    ld b, a ; B = leftPadWidth
    ld a, Sspace
    call printARepeatBPageTwo
printMenuNameAtCPrintName:
    ; Print the menu name
    ld hl, menuName
    call vPutSmallPSPageTwo
printMenuNameAtCRightPad:
    pop bc ; B = stringWidth; C = leftPadWidth
    ld a, menuPenWidth
    sub c ; A = menuPenWidth - leftPadWidth
    sub b ; A = rightPadWidth = menuPenWidth - leftPadWidth - stringWidth
    jr z, printMenuNameAtCExit ; no space left
    jr c, printMenuNameAtCExit ; overflowed, shouldn't happen but be safe
    ; actually print the right pad
    ld b, a ; B = rightPadWidth
    ld a, Sspace
    call printARepeatBPageTwo
printMenuNameAtCExit:
    res textInverse, (iy + textFlags)
    res textEraseBelow, (iy + textFlags)
    pop de ; stack=[numRows,loopCounter/penCol]; E=menuIndex
    pop bc ; stack=[numRows]; BC=loopCounter/penCol
    pop af ; stack=[]; A=numRows
    ret

;-----------------------------------------------------------------------------

; Description: Print a small line above the menu box if the menu node is a
; MenuFolder.
; Input:
;   - A:u8=numRows (>0 if menuFolder)
;   - B=loopCounter (must be preserved)
;   - C=penCol (must be preserved)
;   - E=menuIndex [0-4] (ignored but must be preserved, useful for debugging)
; Preserves: A, BC, DE
; Destroys: HL
DisplayMenuFolder:
    push bc
    push de
    ; Determine the type of line, depending on type of menu node: MenuItem,
    ; MenuFolder, or MenuLink (not implemented yet).
    ; - if A==0: MenuItem, set A=0 to draw light line
    ; - if A>0: MenuFolder, set A=1 to draw dark line
    ; - if A<0: MenuLink, draw dotted line
    or a
    ld h, a ; H=typeOfLine
    jr z, displayMenuFolderLightOrDark
    ld h, 1 ; 0=light, 1=dark
displayMenuFolderLightOrDark:
    ; calculate the start coordinate of the folder icon line. bcall(_ILine)
    ; uses Pixel Coordinates, (0,0) is bottom left.
    ld b, c
    inc b ; B=start.x
    ld c, menuFolderIconLineRow ; C=start.y
    ; calculate the end coordinate of the folder icon line (inclusive)
    ld d, b
    inc d
    inc d
    inc d
    inc d ; D=end.x (5 pixels wide)
    ld e, c ; E=end.y
displayMenuFolderDraw:
    bcall(_ILine) ; preserves all registers according to the SDK docs
#ifdef ENABLE_MENU_LINK
    bit 7, a ; ZF=0 if menulink
    jr z, displayMenuFolderEnd
    ; convert solid line into dotted line by removing 2 interior pixels
    inc b ; B=start.x
    ld d, 0
    bcall(_IPoint)
    inc b
    inc b
    bcall(_IPoint)
displayMenuFolderEnd:
#endif
    pop de
    pop bc
    ret