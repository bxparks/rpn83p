;-----------------------------------------------------------------------------
; Display the RPN stack variables.
;
;   0: Status line: (up|down) (deg|rad) (fix|sci|eng) # small font
;   1: Debug line
;   2: Error code line:
;   3: T: tttt
;   4: Z: zzzz
;   5: Y: yyyy
;   6: X: xxxx
;   7: [menu1][menu2][menu3][menu4][menu5] (small font)
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
    set rpnFlagsTrigModeDirty, (iy + rpnFlags)
    set rpnFlagsFloatModeDirty, (iy + rpnFlags)
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
    res rpnFlagsStackDirty, (iy + rpnFlags)
    res rpnFlagsMenuDirty, (iy + rpnFlags)
    res rpnFlagsTrigModeDirty, (iy + rpnFlags)
    res rpnFlagsFloatModeDirty, (iy + rpnFlags)
    res inputBufFlagsInputDirty, (iy + inputBufFlags)
    ret

;-----------------------------------------------------------------------------
; Routines for displaying the status bar at the top.
;-----------------------------------------------------------------------------

; Function: Display the status bar, showing menu up/down arrows.
; Input: none
; Output: status line displayed
; Destroys: A, B, C, HL
displayStatus:
    call displayStatusMenu
    call displayStatusTrig
    call displayStatusFloatMode
    ret

displayStatusMenu:
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

    ld hl, statusPenRow*$100 + statusMenuPenCol; $(penRow)(penCol)
    ld (PenCol), hl

    ; If numStrips==0: don't do anything. This should never happen if there
    ; are no bugs in the program.
    ld a, c ; A = numStrips
    or a
    jr z, displayStatusMenuClear

displayStatusMenuDownArrow:
    ; If stripIndex < (numStrips - 1): show Down arrow
    ld a, b ; A = stripIndex
    dec c ; C = numStrips - 1
    cp c
    jr nc, displayStatusMenuDownArrowNone
    ld a, SdownArrow
    bcall(_VPutMap)
    ; Add an extra space after the downArrow because when an upArrow is
    ; displayed immediately after, the 1px of space on the right side of the
    ; downArrow character seems to ellided so the downArrow occupies only 3px.
    ld a, Sspace
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
    ret

    ; clear 8 px
displayStatusMenuClear:
    call displayStatusMenuUpArrowNone
    jr displayStatusMenuUpArrowNone

;-----------------------------------------------------------------------------

; Description: Display the Degree or Radian trig mode.
displayStatusTrig:
    bit rpnFlagsTrigModeDirty, (iy + rpnFlags)
    ret z
displayStatusTrigUpdate:
    ld hl, statusPenRow*$100 + statusTrigPenCol; $(penRow)(penCol)
    ld (PenCol), hl
    bit trigDeg, (iy + trigFlags)
    jr z, displayStatusTrigRad
displayStatusTrigDeg:
    ld hl, msgStatusTrigDeg
    jr displayStatusTrigPutS
displayStatusTrigRad:
    ld hl, msgStatusTrigRad
displayStatusTrigPutS:
    bcall(_VPutS)
    ret

;-----------------------------------------------------------------------------

; Description: Display the floating point format: FIX, SCI, ENG
; Destroys: A, HL
displayStatusFloatMode:
    bit rpnFlagsFloatModeDirty, (iy + rpnFlags)
    ret z
    ld hl, statusPenRow*$100 + statusFloatModePenCol; $(penRow)(penCol)
    ld (PenCol), hl
    ; check float mode
    bit fmtExponent, (iy + fmtFlags)
    jr nz, displayStatusFloatModeSciOrEng
displayStatusFloatModeFix:
    ld hl, mFixName
    jr displayStatusFloatModeBracketDigit
displayStatusFloatModeSciOrEng:
    bit fmtEng, (iy + fmtFlags)
    jr nz, displayStatusFloatModeEng
displayStatusFloatModeSci:
    ld hl, mSciName
    jr displayStatusFloatModeBracketDigit
displayStatusFloatModeEng:
    ld hl, mEngName
    ; [[fallthrough]]
displayStatusFloatModeBracketDigit:
    ; Print the number of digit
    bcall(_VPutS)
    ld a, SlParen
    bcall(_VPutMap)
    ld a, (fmtDigits)
    cp 10
    jr nc, displayStatusFloatModeFloating
    add a, '0'
    jr displayStatusFloatModeDigit
displayStatusFloatModeFloating:
    ld a, '-'
displayStatusFloatModeDigit:
    bcall(_VPutMap)
    ld a, SrParen
    bcall(_VPutMap)
    ret

;-----------------------------------------------------------------------------
; Routines for displaying the error code and string.
;-----------------------------------------------------------------------------

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

;-----------------------------------------------------------------------------
; Routines for displaying the RPN stack variables.
;-----------------------------------------------------------------------------

; Function: Display the RPN stack variables
; Input: none
; Output: (rpnFlagsMenuDirty) reset
; Destroys: A, HL
displayStack:
    ; display YZT if stack is dirty
    bit rpnFlagsStackDirty, (iy + rpnFlags)
    call nz, displayStackYZT

    ; display X if stack or inputBuf are dirty
    bit rpnFlagsStackDirty, (iy + rpnFlags)
    jr nz, displayStackContinue
    bit inputBufFlagsInputDirty, (iy + inputBufFlags)
    jr nz, displayStackContinue
    ret
displayStackContinue:
    call displayStackX
    ret

;-----------------------------------------------------------------------------

displayStackYZT:
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

    ret

;-----------------------------------------------------------------------------

; Description: Render the X lines. There are 3 options:
; 1) if rpnFlagsArgMode, print the inputbuf as a command argument,
; 2) else if rpnFlagsEditing, print the inputBuf as a stack number,
; 3) else print the stX variable.
displayStackX:
    bit rpnFlagsArgMode, (iy + rpnFlags)
    jr nz, displayStackXArg
    bit rpnFlagsEditing, (iy + rpnFlags)
    jr nz, displayStackXInput
    ; [[fallthrough]]

displayStackXNormal:
    ; print X label
    ld hl, stXPenRow*$100 ; $(penRow)(penCol)
    ld (PenCol), hl
    ld hl, msgXLabel
    bcall(_VPutS)
    ; print the stX variable
    ld hl, stXCurCol*$100 + stXCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    call rclX
    jp printOP1

displayStackXInput:
    ; print X label
    ld hl, inputPenRow*$100 ; $(penRow)(penCol)
    ld (PenCol), hl
    ld hl, msgXLabel
    bcall(_VPutS)
    ; print the inputBuf
    ld hl, inputCurCol*$100 + inputCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    jr printInputBuf

#ifdef DEBUG
; This is the debug version which always shows the current X register, and
; prints the inputBuf on the debug line.
displayStackXDebug:
    ld hl, $0100 + stXCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    call rclX
    call printOP1
    ; print the inputBuf on the error line
    jp debugInputBuf
#endif

; Display the argBuf in the X register line.
displayStackXArg:
    ld hl, argCurCol*$100 + argCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    jr printArgBuf

;-----------------------------------------------------------------------------

; Function: Print the arg buffer.
; Input:
;   - argBuf (same as inputBuf)
;   - argBufPrompt
;   - (CurCol) cursor position
; Output:
;   - (CurCol) is updated
; Destroys: A, HL; BC destroyed by PutPS()
printArgBuf:
    ; Print prompt and contents of argBuf
    ld hl, (argPrompt)
    bcall(_PutS)
    ld a, ' '
    bcall(_PutC)
    ld hl, argBuf
    bcall(_PutPS)

    ; Append cursor if needed.
    ld a, (argBufSize)
    or a
    jr z, printArgBufTwoCursors
    cp 1
    jr z, printArgBufOneCursor
    jr printArgBufZeroCursor
printArgBufTwoCursors:
    ld a, cursorChar
    bcall(_PutC)
printArgBufOneCursor:
    ld a, cursorChar
    bcall(_PutC)
printArgBufZeroCursor:
    bcall(_EraseEOL)
    ret

;-----------------------------------------------------------------------------

; Function: Print the input buffer.
; Input:
;   - inputBuf
;   - (CurCol) cursor position
; Output:
;   - (CurCol) is updated
; Destroys: A, HL; BC destroyed by PutPS()
printInputBuf:
    ld hl, inputBuf
    bcall(_PutPS)
    ld a, cursorChar
    bcall(_PutC)
    ; Skip EraseEOL() if the PutC() above wrapped to next line
    ld a, (CurCol)
    or a
    ret z
    bcall(_EraseEOL)
    ret

;-----------------------------------------------------------------------------
; Routines for displaying the menu bar.
;-----------------------------------------------------------------------------

; Function: Display the bottom menus.
; Input: none
; Output: (rpnFlagsMenuDirty) reset
; Destroys: A, HL
displayMenu:
    bit rpnFlagsMenuDirty, (iy + rpnFlags)
    ret z

    call getCurrentMenuStripBeginId ; A=stripBeginId

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

;-----------------------------------------------------------------------------

; Function: Print the menu C string in HL to the menuPenCol in A, using small
; and inverted font. Actually prints at (A+1) to show a 1px left border.
; Inputs:
;   A: penCol
;   HL: C string
; Destroys: DE, HL
; Preserves: BC
printMenuAtA:
    push bc
    ld c, a ; C=A=menuPenCol (saved)

    ; Set (PenCol,PenRow), preserving HL
    ld (PenCol), a
    ld a, menuPenRow
    ld (PenRow), a

    ; Print the menu string, inverted.
    set textInverse, (iy + textFlags)
    ld a, Sspace
    bcall(_VPutMap)
    bcall(_VPutS)

    ; Calculate remaining space on the right
    ld a, (PenCol)
    sub c ; C=PenCol-startPenCol
    ld c, a
    ld a, menuPenWidth
    sub c ; C = pixelsRemaining = menuPenWidth - pixelsWritten
    jr z, printMenuAtAExit ; no space left
    jr c, printMenuAtAExit ; wrote past the box; shouldn't happen but be safe

    ; Overwrite trailing space.
    ld b, a
printMenuAtAOverwriteLoop:
    ld a, Sspace
    bcall(_VPutMap)
    djnz printMenuAtAOverwriteLoop

printMenuAtAExit:
    res textInverse, (iy + textFlags)
    pop bc
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
; Low-level helper routines.
;-----------------------------------------------------------------------------

; Function: Print floating point number at OP1 at the current cursor. Erase to
; the end of line (but only if the floating point did not spill over to the
; next line).
; Input: OP1: floating point number
; Destroys: A, HL, OP3
printOP1:
    ld a, 15 ; width of output
    bcall(_FormReal)
    ld hl, OP3
    bcall(_PutS)
    ld a, (CurCol)
    or a
    ret z ; if spilled to next line, don't call EraseEOL
    bcall(_EraseEOL)
    ret

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

; Description: Inlined version of bcall(_VPutS) which has 2 advantages:
; 1) It works for strings which are in flash (VPutS only works with strings in
; RAm).
; 2) It interprets the `Senter` character to move the pen to the beginning of
; the next line. A line using small font is 7 px high.
;
; See TI-83 Plus System Routine SDK docs for VPutS() for a reference
; implementation of this function.
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
    add a, 7 ; height of small font characters
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

;-----------------------------------------------------------------------------

; "DEG" and "RAD" trig indicators
msgStatusTrigDeg:
    .db "DEG", 0
msgStatusTrigRad:
    .db "RAD", 0

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
