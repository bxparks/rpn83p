;-----------------------------------------------------------------------------
; Display the RPN stack variables.
;
;   0: Status line: (up|down) (bin|dec|hex) (deg|rad|grad) (small font)
;   1: Debug line
;   2: Error code line:
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
    set rpnFlagsStatusDirty, (iy + rpnFlags)
    set rpnFlagsMenuDirty, (iy + rpnFlags)
    set inputBufFlagsInputDirty, (iy + inputBufFlags)
    ret

; Function: Update the display, including the title, RPN stack variables,
; and the menu.
; Input: none
; Output:
; Destroys: all
displayAll:
    call displayStatus
    call displayErrorCode
    call displayStack
    call displayMenu

    ; Reset dirty flags
    res rpnFlagsStatusDirty, (iy + rpnFlags)
    res rpnFlagsStackDirty, (iy + rpnFlags)
    res rpnFlagsMenuDirty, (iy + rpnFlags)
    ret

; Function: Display the status bar, showing menu up/down arrows.
; Input: none
; Output: status line displayed
; Destroys: A, BC, HL
displayStatus:
    bit rpnFlagsMenuDirty, (iy + rpnFlags)
    ret z

    ; TODO: maybe cache the numStrips of the current node to make this
    ; calculation a little shorter and easier.

    ; Determine if multiple menu strips exists.
    ld hl, menuCurrentId
    ld a, (hl) ; currentId
    inc hl
    ld b, (hl) ; B=stripIndex
    call getMenuNode
    inc hl
    inc hl
    inc hl
    ld c, (hl) ; C=numStrips

    ld hl, statusPenRow*$100 ; $(penRow)(penCol)
    ld (PenCol), hl

    ; If numStrips==0: don't do anything. This should never happen if there
    ; are no bugs in the program.
    or a
    jr z, displayStatusMenuClear

displayStatusMenuDownArrow:
    ; If stripIndex < (numStrips - 1): show Down arrow
    ld a, b
    dec c
    cp c
    jr nc, displayStatusMenuDownArrowNone
    ld a, SdownArrow
    jr displayStatusMenuDownArrowDisplay
displayStatusMenuDownArrowNone:
    ld a, SFourSpaces
displayStatusMenuDownArrowDisplay:
    bcall(_VPutMap)

displayStatusMenuUpArrow:
    ; If stripIndex > 0: show Up arrow
    ld a, b
    or a
    jr z, displayStatusMenuUpArrowNone
    ld a, SupArrow
    jr displayStatusMenuUpArrowDisplay
displayStatusMenuUpArrowNone:
    ld a, SFourSpaces
displayStatusMenuUpArrowDisplay:
    bcall(_VPutMap)

    jr displayStatusEraseOfLine

    ; clear 8 px
displayStatusMenuClear:
    ld hl, msgStatusMenuBlank
    bcall(_VPutS)

displayStatusEraseOfLine:
    call vEraseEOL
    ret

; Function: Display the string corresponding to the current error code.
; Input: errorCode, errorCodeDisplayed
; Output:
;   - string corresponding to errorCode displayed
;   - errorCodeDisplayed updated
; Destroys: A, DE, HL
displayErrorCode:
    call checkErrorCodeDisplayed
    ret z

    ; Print error code string and its numerical code.
    ld hl, errorPenRow*$100 ; $(penRow)(penCol)
    ld (PenCol), hl
    call getErrorString
    bcall(_VPutS)
    ld a, Sspace
    bcall(_VPutMap)
    ;
    ld a, ' '
    bcall(_VPutMap)
    ld a, '('
    bcall(_VPutMap)
    ;
    ld a, (errorCode)
    ld hl, OP1
    call convertAToDec
    bcall(_VPutS)
    ;
    ld a, ')'
    bcall(_VPutMap)
    call vEraseEOL

    call saveErrorCodeDisplayed
    ret

; Function: Display the RPN stack variables
; Input: none
; Output: (rpnFlagsMenuDirty) reset
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
    ld hl, stTCurCol*$100 + stTCurRow ; $(curCol)(curRow)
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
    ld hl, stZCurCol*$100 + stZCurRow ; $(curCol)(curRow)
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
    ld hl, stYCurCol*$100 + stYCurRow ; $(curCol)(curRow)
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

    ret

; This is the normal, non-debug version, which combines the inputBuf and the X
; register on a single line.
displayStackXNormal:
    ld hl, stXCurCol*$100 + stXCurRow ; $(curCol)(curRow)
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
; Output: (rpnFlagsMenuDirty) reset
; Destroys: A, HL
displayMenu:
    bit rpnFlagsMenuDirty, (iy + rpnFlags)
    ret z

    ; TODO: This causes UI flickering when the menu is updated. It is more
    ; noticeable in an emulator than on a real caculator. A better way to
    ; implement this is to overwrite the prev menu string with the next one,
    ; then call something equivalent to 'eraseEndOfMenu()` to overwrite any
    ; trailing pixels until the end of the current menu box. That would prevent
    ; the flashing.
    call clearMenus

    call getCurrentMenuStripBeginId
    ld b, a

    call getMenuName
    ld a, menuPenCol0
    call printMenuAtA
    inc b

    ld a, b
    call getMenuName
    ld a, menuPenCol1
    call printMenuAtA
    inc b

    ld a, b
    call getMenuName
    ld a, menuPenCol2
    call printMenuAtA
    inc b

    ld a, b
    call getMenuName
    ld a, menuPenCol3
    call printMenuAtA
    inc b

    ld a, b
    call getMenuName
    ld a, menuPenCol4
    call printMenuAtA

    ret

; Function: Print floating point number at OP1 at the current cursor.
; Input: OP1: floating point number
; Destroys: A, HL, OP3
printOP1: ; TODO: rename to printFloatOP1
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
    ; ld hl, menuCurRow ; $(curCol)(curRow)
    ; bcall(_EraseEOL)

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
; Destroys: A, HL; BC destroyed by PutPS()
printInputBuf:
    bit inputBufFlagsInputDirty, (iy + inputBufFlags)
    ret z

    ld hl, stXCurCol*$100+stXCurRow ; $(col)(row) cursor
    ld (CurRow), hl
    ld hl, inputBuf
    bcall(_PutPS)
    ld a, cursorChar
    bcall(_PutC)
    ; Skip EraseEOL() if the PutC() above wrapped to next line
    ld a, (CurCol)
    or a
    jr z, printInputBufContinue
    bcall(_EraseEOL)
printInputBufContinue:
    res inputBufFlagsInputDirty, (iy + inputBufFlags)
    ret

;-----------------------------------------------------------------------------

; Function: Convert A to 3-digit nul terminated C string at the buffer pointed
; by HL. This is intended for debugging, so it is not optimized.
; Input: HL: pointer to string buffer
; Output: HL unchanged, with 1-3 ASCII string, terminated by NUL
; Destroys: A, B, C
convertAToDec:
    push hl
convertAToDec100:
    ld b, 100
    call divideAByB
    or a
    jr z, convertAToDec10
    call convertAToChar
    ld (hl), a
    inc hl
convertAToDec10:
    ld a, b
    ld b, 10
    call divideAByB
    or a
    jr z, convertAToDec1
    call convertAToChar
    ld (hl), a
    inc hl
convertAToDec1:
    ld a, b
    call convertAToChar
    ld (hl), a
    inc hl
convertAToDec0:
    ld (hl), 0
    pop hl
    ret

; Function: Return A / C using repeated substraction.
; Input:
;   - A: numerator
;   - B: denominator
; Output: A = A/B (quotient); B=A%B (remainder)
; Destroys: C
divideAByB:
    ld c, 0
divideAByBLoop:
    sub b
    jr c, divideAByBLoopEnd
    inc c
    jr divideAByBLoop
divideAByBLoopEnd:
    add a, b ; undo the last subtraction
    ld b, a
    ld a, c
    ret

; Function: Convert A into an Ascii Char ('0'-'9','A'-'F').
; Destroys: A
convertAToChar:
    cp 10
    jr c, convertAToCharDec
    sub 10
    add a, 'A'
    ret
convertAToCharDec:
    add a, '0'
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

; Up and Down arrows to indicate that there are additional menu options.
msgStatusMenuUpDown:
    .db SupArrow, SdownArrow, 0

; 8 px of spaces.
msgStatusMenuBlank:
    .db SFourSpaces, SFourSpaces, 0

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
