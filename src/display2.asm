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
    ; - if A<0: MenuLink, jump to dotted
    ; - if A==0: MenuItem, set A=0 to draw light line
    ; - if A>0: MenuFolder, set A=1 to draw dark line
    bit 7, a
    jr nz, displayMenuFolderDotted
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
    pop de
    pop bc
    ret
displayMenuFolderDotted:
    ; draw dotted line 5 px wide
    ld b, c
    inc b ; B=start.x
    ld c, menuFolderIconLineRow ; C=start.y
    ;
    ld d, 1
    bcall(_IPoint)
    inc b
    ;
    ld d, 0
    bcall(_IPoint)
    inc b
    ;
    ld d, 1
    bcall(_IPoint)
    inc b
    ;
    ld d, 0
    bcall(_IPoint)
    inc b
    ;
    ld d, 1
    bcall(_IPoint)
    inc b
    ;
    pop de
    pop bc
    ret
