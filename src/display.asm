;-----------------------------------------------------------------------------
; Display the RPN stack variables.
;
;   0: RPN83P (help msg)
;   1: Status line: (up|down) (bin|dec|hex) (deg|rad|grad) (small font)
;   2: Error msg: (overflow|invalid)
;   3: T: tttt
;   4: Z: zzzz
;   5: Y: yyyy
;   6: X: xxxx
;   7: [menu0][menu1][menu2][menu3][menu4] (small font)
;-----------------------------------------------------------------------------

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
    set rpnFlagsTitleDirty, (iy + rpnFlags)
    set displayFlagsMenuDirty, (iy + displayFlags)
    set inputBufFlagsInputDirty, (iy + inputBufFlags)
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
; Output: rpnFlagsTitleDirty reset
; Destroys: A, HL
displayTitle:
    bit rpnFlagsTitleDirty, (iy + rpnFlags)
    ret z

    ld hl, 0 ; $(col)(row) cursor
    ld (CurRow), hl
    ld hl, msgTitle
    bcall(_PutS)
    bcall(_EraseEOL)

    ; Reset dirty flag
    res rpnFlagsTitleDirty, (iy + rpnFlags)
    ret

; Function: Display the RPN stack variables
; Input: none
; Output: (displayFlagsMenuDirty) reset
; Destroys: A, HL
displayStack:
    ; Return if both stackDirty and inputDirty are clean.
    bit rpnFlagsStackDirty, (iy + rpnFlags)
    jr nz, displayStackContinue
    bit inputBufFlagsInputDirty, (iy + inputBufFlags)
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
    call rclT
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
    call rclZ
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
    call rclY
    call printOP1
    bcall(_EraseEOL)
    bcall(_NewLine)

    ; print X label
    ld hl, stXPenRow*$100 ; $(penRow)(penCol)
    ld (PenCol), hl
    ld hl, msgXLabel
    bcall(_VPutS)

    ; print X value.
    ; NOTE: Use one (but not both) of the following.
    ; call displayStackXDebug
    call displayStackXNormal

    ; Reset dirty flag
    res rpnFlagsStackDirty, (iy + rpnFlags)

    ret

; This is the normal, non-debug version, which combines the inputBuf and the X
; register on a single line.
displayStackXNormal:
    ld hl, $0100 + stXCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    ; If in edit mode, display the inputBuf, otherwise display X.
    bit rpnFlagsEditing, (iy + rpnFlags)
    jr z, displayStackXReg
displayStackXInputBuf:
    jp printInputBuf
displayStackXReg:
    call rclX
    call printOP1
    bcall(_EraseEOL)
    bcall(_NewLine)
    ret

; This is the debug version which always shows the current X register, and
; prints the inputBuf on the error line.
displayStackXDebug:
    ld hl, $0100 + stXCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    call rclX
    call printOP1
    bcall(_EraseEOL)
    bcall(_NewLine)
    ; print the inputBuf on the error line
    jp debugInputBuf

; Function: Display the bottom menus.
; Input: none
; Output: (displayFlagsMenuDirty) reset
; Destroys: A, HL
displayMenu:
    bit displayFlagsMenuDirty, (iy + displayFlags)
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

    res displayFlagsMenuDirty, (iy + displayFlags)
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
;   inputBufFlagsInputDirty
; Output:
;   - (CurCol) is updated
;   - inputBufFlagsInputDirty reset
; Destroys: A, HL; other regs prob destroyed by OS calls
printInputBuf:
    bit inputBufFlagsInputDirty, (iy + inputBufFlags)
    ret z

    ld hl, stXCurCol*$100+stXCurRow ; $(col)(row) cursor
    ld (CurRow), hl
    ld hl, inputBuf
    bcall(_PutPS)
    ld a, cursorChar
    bcall(_PutC)
    bcall(_EraseEOL)

    res inputBufFlagsInputDirty, (iy + inputBufFlags)
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
