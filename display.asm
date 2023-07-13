; Display the RPN stack variables.
;
; Reuse existing system variables to implement the RPN stack:
;   RPN     TI      OS Routines
;   ---     --      -----------
;   T       T       StoT
;   Z       Z       StoTheta  (TODO: Replace with 'Z')
;   Y       Y       StoY, RclY
;   X       X       StoX, RclX
;   LastX   R       StoR
;   ??      Ans     StoAns, RclAns
;
; Display format:
;   0: RPN83P (help msg)
;   1: Status line: (up|down) (bin|dec|hex) (deg|rad|grad) (small font)
;   2: Error msg: (overflow|invalid)
;   3: T: tttt
;   4: Z: zzzz
;   5: Y: yyyy
;   6: X: xxxx
;   7: [menu0][menu1][menu2][menu3][menu4] (small font)

; Menu pixel columns:
;   - 96 px wide, 5 menus
;   - 18 px/menu = 90 px, 6 leftover
;   - 1 px between 5 menus, plus 1 px on far left and right = 6 px
;   - each menu spaced 19 px apart
;   - menuPenColStart - 0
;   - menuPenCol0 - 1
;   - menuPenCol1 - 20
;   - menuPenCol2 - 39
;   - menuPenCol3 - 58
;   - menuPenCol4 - 77
;   - menuPenColEnd - 96
menuCurRow      equ 7 ; row 7
menuPenRow      equ menuCurRow*8+1 ; row 7, in px, +1 for small font
menuPenWidth    equ 18
menuPenColStart equ 0
menuPenCol0     equ 1
menuPenCol1     equ 20
menuPenCol2     equ 39
menuPenCol3     equ 58
menuPenCol4     equ 77
menuPenColEnd   equ 96

;-----------------------------------------------------------------------------

; Function: Set the display flags to dirty initially so that they are rendered.
initDisplay:
    ld hl, displayFlags
    set displayFlagsTitleDirty, (hl)
    set displayFlagsStackDirty, (hl)
    set displayFlagsMenuDirty, (hl)
    set displayFlagsInputDirty, (hl)
    ret

; Function: Update the display, including the title, RPN stack variables,
; and the menu.
; Input: none
; Output:
; Destroys: all
displayAll:
    call displayTitle
    call displayStack
    call displayMenu
    ret

; Function: Display the title bar.
; Input: none
; Output: (displayFlagsTitleDirty) reset
; Destroys: A, HL
displayTitle:
    ld hl, displayFlags
    bit displayFlagsTitleDirty, (hl)
    ret z

    ld hl, 0 ; $(col)(row) cursor
    ld (CurRow), hl
    ld hl, msgTitle
    bcall(_PutS)
    bcall(_EraseEOL)

    ; Reset dirty flag
    ld hl, displayFlags
    res displayFlagsTitleDirty, (hl)
    ret

; Function: Display the RPN stack variables
; Input: none
; Output: (displayFlagsMenuDirty) reset
; Destroys: A, HL
displayStack:
    ; Return if stack and input are clean.
    ld hl, displayFlags
    bit displayFlagsStackDirty, (hl)
    jr nz, displayStackContinue
    bit displayFlagsInputDirty, (hl)
    ret z

displayStackContinue:
    ; print T label
    ld hl, stTPenRow*$100 ; $(penRow)(penCol)
    ld (PenCol), hl
    ld hl, msgTLabel
    bcall(_VPutS)

    ; print T value
    ld hl, $0100 + stTCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    bcall(_TName)
    bcall(_RclVarSym)
    call printOP1
    bcall(_EraseEOL)
    bcall(_NewLine)

    ; print Z label
    ld hl, stZPenRow*$100 ; $(penRow)(penCol)
    ld (PenCol), hl
    ld hl, msgZLabel
    bcall(_VPutS)

    ; print Z value
    ld hl, $0100 + stZCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    bcall(_ThetaName)
    bcall(_RclVarSym)
    call printOP1
    bcall(_EraseEOL)
    bcall(_NewLine)

    ; print Y label
    ld hl, stYPenRow*$100 ; $(penRow)(penCol)
    ld (PenCol), hl
    ld hl, msgYLabel
    bcall(_VPutS)

    ; print Y value
    ld hl, $0100 + stYCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    bcall(_YName)
    bcall(_RclVarSym)
    call printOP1
    bcall(_EraseEOL)
    bcall(_NewLine)

    ; print X label
    ld hl, stXPenRow*$100 ; $(penRow)(penCol)
    ld (PenCol), hl
    ld hl, msgXLabel
    bcall(_VPutS)

    ; print X value
    ld hl, $0100 + stXCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
;    ; If in edit mode, display the inputBuf, otherwise display X.
;    ld hl, rpnFlags
;    bit rpnFlagsEditing, (hl)
;    jr z, displayStackPrintX
;displayStackPrintInputBuf:
;    call printInputBuf
;    jr displayStackPrintXContinue
;displayStackPrintX:
    bcall(_XName)
    bcall(_RclVarSym)
    call printOP1
    bcall(_EraseEOL)
    bcall(_NewLine)

displayStackPrintXContinue:
    ; Reset dirty flag
    ld hl, displayFlags
    res displayFlagsStackDirty, (hl)

    ret

; Function: Display the bottom menus.
; Input: none
; Output: (displayFlagsMenuDirty) reset
; Destroys: A, HL
displayMenu:
    ld hl, displayFlags
    bit displayFlagsMenuDirty, (hl)
    ret z

    call clearMenus

    ld a, menuPenCol0
    ld hl, msgMenuBase
    call printMenuAtA

    ld a, menuPenCol1
    ld hl, msgMenuProb
    call printMenuAtA

    ld a, menuPenCol2
    ld hl, msgMenuHyp
    call printMenuAtA

    ld a, menuPenCol3
    ld hl, msgMenuUnit
    call printMenuAtA

    ld a, menuPenCol4
    ld hl, msgMenuHelp
    call printMenuAtA

    ld hl, displayFlags
    res displayFlagsMenuDirty, (hl)
    ret

; Function: Print OP1 floating point number at the current cursor.
; Input: OP1: floating point number
; Destroys: A, HL, OP3
printOP1:
    ld a, 15 ; width of output
    bcall(_FormReal)
    ld hl, OP3
    bcall(_PutS)
    ret

;-----------------------------------------------------------------------------

; Function: Print the menu C string in HL to the menuPenCol in A, using small
; and inverted font. Actually prints at (A+1) to show a 1px left border.
; Inputs:
;   A: penCol
;   HL: C string
; Destroys: DE, HL
printMenuAtA:
    ex de, hl
    ld h, menuPenRow
    ld l, a
    inc l
    ld (PenCol), hl
    ex de, hl
    set textInverse, (iy + textFlags)
    bcall(_VPutS)
    res textInverse, (iy + textFlags)
    ret

; Function: Print blank (all black) at menuPenCol in A.
; Input: A: penCol
; Destroys: HL
printMenuBlank:
    ld h, menuPenRow
    ld l, a
    ld (PenCol), hl
    ld hl, msgMenuBlank
    set textInverse, (iy + textFlags)
    bcall(_VPutS)
    res textInverse, (iy + textFlags)
    ret

; Function: Initialize the menu items with blanks, using inverted spaces.
; Destroys: A, HL
clearMenus:
    ld hl, menuCurRow ; $(curCol)(curRow)
    bcall(_EraseEOL)

    ld a, menuPenCol0
    call printMenuBlank

    ld a, menuPenCol1
    call printMenuBlank

    ld a, menuPenCol2
    call printMenuBlank

    ld a, menuPenCol3
    call printMenuBlank

    ld a, menuPenCol4
    call printMenuBlank

    ret

;-----------------------------------------------------------------------------

; Function: Print the input buffer.
; Input:
;   (displayFlagsInputDirty)
; Output:
;   - (CurCol) is updated
;   - (displayFlagsInputDirty) reset
; Destroys: A, HL; other regs prob destroyed by OS calls
printInputBuf:
    ld hl, displayFlags
    bit displayFlagsInputDirty, (hl)
    ret z

    ld hl, stXCurCol*$100+stXCurRow ; $(col)(row) cursor
    ld (CurRow), hl
    ld hl, inputBuf
    bcall(_PutPS)
    ld a, cursorChar
    bcall(_PutC)
    bcall(_EraseEOL)

    ld hl, displayFlags
    res displayFlagsInputDirty, (hl)
    ret

;-----------------------------------------------------------------------------

msgTitle:
    .db "RPN83P", 0
msgTLabel:
    .db "T:", 0
msgZLabel:
    .db "Z:", 0
msgYLabel:
    .db "Y:", 0
msgXLabel:
    .db "X:", 0

msgMenuBlank: ; 18px wide
    .db SFourSpaces, SFourSpaces, SFourSpaces, SFourSpaces, Sspace, Sspace, 0

msgMenuBase:
    .db "BASE", 0
msgMenuProb:
    .db "PROB", 0
msgMenuHyp:
    .db "HYP", 0
msgMenuUnit:
    .db "UNIT", 0
msgMenuHelp:
    .db "HELP", 0

euler:
    .db $00, $80, $27, $18, $28, $18, $28, $45, $94 ; 2.7182818284594

ten:
    .db $00, $81, $10, $00, $00, $00, $00, $00, $00 ; 10

thousand:
    .db $00, $83, $10, $00, $00, $00, $00, $00, $00 ; 1000
