;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Display the calculator modes, status, and RPN stack variables using 8 lines
; of the 96(w)x64(h) LCD display, using a mixture of small and large fonts.
; The format looks roughly like this:
;
; 0: Status: (left,up,down) (Fix|Sci|Eng) (Deg|Rad) ...
; 1: Debug: Debugging output, not used in app
; 2: Error or warning message
; 3: T: tttt
; 4: Z: zzzz
; 5: Y: yyyy
; 6: X: xxxx
; 7: Menu: [menu1][menu2][menu3][menu4][menu5]
;-----------------------------------------------------------------------------

; Display coordinates of the top status line. Use a 2px space between each
; annunciator. The last 6px should not be used because the TIOS uses that space
; for the 2ND and ALPHA modifier keys when the cursor is not shown. In other
; words, statusEndPenCol should not be greater than 90 (96-6).
statusCurRow equ 0
statusCurCol equ 0
statusPenRow equ statusCurRow*8
statusMenuPenCol equ 0 ; "left, up, down" + space = 3*4+2 = 14px
statusFloatModePenCol equ 14 ; "(FIX|SCI|ENG{n}" + space = 4*4+2 = 18px
statusTrigPenCol equ 32 ; "(DEG|RAD)" + space = 3*4+2 = 14px
statusBasePenCol equ 46 ; (C|-) + space = 6px
statusComplexModePenCol equ 52 ; "(aib|rLt|rLo)" + space = 3x4+2= 14px
statusStackModePenCol equ 66 ; "{n}STK" + space = 4x4+2 = 18px
statusEndPenCol equ 84

; Display coordinates of the debug line
debugCurRow equ 1
debugCurCol equ 0
debugPenRow equ debugCurRow*8

; Display coordinates of the error line
errorCurRow equ 2
errorCurCol equ 0
errorPenRow equ errorCurRow*8

; Display coordinates of the SHOW line, overlaps with T
showCurRow equ 3
showCurCol equ 0
showPenRow equ showCurRow*8

; Display coordinates of the stack T register.
stTCurRow equ 3
stTCurCol equ 1
stTPenRow equ stTCurRow*8

; Display coordinates of the stack Z register.
stZCurRow equ 4
stZCurCol equ 1
stZPenRow equ stZCurRow*8

; Display coordinates of the stack Y register.
stYCurRow equ 5
stYCurCol equ 1
stYPenRow equ stYCurRow*8

; Display coordinates of the stack X register.
stXCurRow equ 6
stXCurCol equ 1
stXPenRow equ stXCurRow*8

; Display coordinates of the TVM N counter
tvmNCurRow equ 3
tvmNCurCol equ 1
tvmNPenRow equ tvmNCurRow*8

; Display coordinates of the TVM i0 counter
tvmI0CurRow equ 4
tvmI0CurCol equ 1
tvmI0PenRow equ tvmI0CurRow*8

; Display coordinates of the TVM i1 counter
tvmI1CurRow equ 5
tvmI1CurCol equ 1
tvmI1PenRow equ tvmI1CurRow*8

; Display coordinates of the TVM extra line
tvmExtraCurRow equ 6
tvmExtraCurCol equ 0
tvmExtraPenRow equ tvmExtraCurRow*8

; Display coordinates of the input buffer.
inputCurRow equ stXCurRow
inputCurCol equ stXCurCol
inputPenRow equ inputCurRow*8

; Display coordinates of the arg buffer.
argCurRow equ 6
argCurCol equ 0
argPenRow equ argCurRow*8

; Menu box Pen Coordinates: (0,0) is top-left.
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
menuPenWidth    equ 18 ; excludes 1 px space between menu items
menuPenColStart equ 0 ; left edge of menu line
menuPenCol0     equ 1 ; left edge of menu0
menuPenCol1     equ 20 ; left edge of menu1
menuPenCol2     equ 39 ; left edge of menu2
menuPenCol3     equ 58 ; left edge of menu3
menuPenCol4     equ 77 ; left edge of menu4
menuPenColEnd   equ 96

; A menu folder icon is created using a small (5 pixel) line above the menu box.
; The bcall(_ILine) function uses Pixel Coordinates: (0,0) is the bottom-left,
; and (95,63) is the top-right.
menuFolderIconLineRow equ 7 ; pixel row of the menu folder icon line

;-----------------------------------------------------------------------------

; Description: Update the display, including the title, RPN stack variables,
; and the menu.
;
; We must turn off the cursor at the very beginning of the drawing code, then
; reenable it at the end (if needed). Otherwise, there seems to be a
; race-condition in the blinking code of TIOS where the cursor is shown
; (probably through an interrupt handler), then the cursor position is changed
; by our code, but the blinking code does not remember the prior location where
; the cursor was enabled, so does not unblink the cursor properly, leaving an
; artifact of the cursor in the wrong location.
;
; Input: none
; Output:
; Destroys: all
displayAll:
    ; Disable blinking cursor
    res curAble, (iy + curFlags)
    res curOn, (iy + curFlags)
    ;
    call displayStatus
    call displayErrorCode
    call displayMain
    call displayMenu
    call setCursorState
    ; Reset all dirty flags
    xor a
    ld (iy + dirtyFlags), a
    ret

; Description: Set the cursor properties. Enable cursor only in edit mode.
;
; NOTE: There are 2 variables that control the cursor (curOn and curAble), so
; it seemed possible to adjust the cursor so that it is non-blinking when
; placed at the end of the inputBuf, and blinking in the interior of the
; inputBuf. However setting `curOn=true` and `curAble=false` seems to just
; disable the cursor instead of showing a non-blinking cursor.
setCursorState:
    bit rpnFlagsEditing, (iy + rpnFlags)
    ret z
    ; enable a blinking cursor
    set curOn, (iy + curFlags)
    set curAble, (iy + curFlags)
    ret

;-----------------------------------------------------------------------------
; Routines for displaying the status bar at the top.
;-----------------------------------------------------------------------------

; Description: Display the status bar, showing menu up/down arrows. Most of
; these indicators check the dirtyFlagsStatus flag, but the menu arrows depend
; on dirtyFlagsMenu.
; Input: dirtyFlagsMenu, dirtyFlagsStatus
; Output: status line displayed
; Destroys: A, B, C, HL
displayStatus:
    res fracDrawLFont, (iy + fontFlags) ; use small font
    call displayStatusArrow
    call displayStatusFloatMode
    call displayStatusTrig
    call displayStatusBase
    call displayStatusComplexMode
    call displayStatusStackMode
    ret

;-----------------------------------------------------------------------------

; Description: Display the up and down arrows that indicate whether there are
; additional menus above or below the current set of 5 menu buttons. Each of
; the Sleft, SdownArrow, and SupArrow characters nominally take 4 pixel
; columns. However, when the SdownArrow and SupArrow are printed next to each
; other, one pixel-column seems to be removed (some sort of kerning?). So we
; have to insert an extra one-pixel-column space between the two.
displayStatusArrow:
    bit dirtyFlagsMenu, (iy + dirtyFlags)
    ret z
    ld hl, statusPenRow*$100 + statusMenuPenCol; $(penRow)(penCol)
    ld (PenCol), hl
    ; check arrow status
    bcall(_GetCurrentMenuArrowStatus) ; B=menuArrowStatus
    call displayStatusArrowLeft
    call displayStatusArrowDown
    call displayStatusArrowUp
    ret

; Description: Show left arrow if a parent node exists.
; Input: B=menuArrowStatus
displayStatusArrowLeft:
    bit menuArrowFlagLeft, b
    jr z, displayStatusArrowLeftNone
    ; display left arrow
    ld a, Sleft
    jr displayStatusArrowLeftDisplay
displayStatusArrowLeftNone:
    ld a, SFourSpaces
displayStatusArrowLeftDisplay:
    bcall(_VPutMap) ; destroys IX
    ret

; Description: If show Down arrow if additional rows exist.
; Input: B=menuArrowStatus
displayStatusArrowDown:
    bit menuArrowFlagDown, b
    jr z, displayStatusArrowDownNone
    ; Print a Down arrow with an extra space because when an upArrow is
    ; displayed immediately after, the 1px of space on the right side of the
    ; downArrow character seems to ellided so the downArrow occupies only 3px.
    ld a, SdownArrow
    bcall(_VPutMap) ; destroys IX
    ld a, Sspace
    jr displayStatusArrowDownDisplay
displayStatusArrowDownNone:
    ld a, SFourSpaces
displayStatusArrowDownDisplay:
    bcall(_VPutMap) ; destroys IX
    ret

; Description: If show Up arrow if previous rows exist.
; Input: B=menuArrowStatus
displayStatusArrowUp:
    bit menuArrowFlagUp, b
    jr z, displayStatusArrowUpNone
    ld a, SupArrow
    jr displayStatusArrowUpDisplay
displayStatusArrowUpNone:
    ld a, SFourSpaces
displayStatusArrowUpDisplay:
    bcall(_VPutMap)
    ret

;-----------------------------------------------------------------------------

; Description: Display the floating point format: FIX, SCI, ENG
; Destroys: A, HL
displayStatusFloatMode:
    bit dirtyFlagsStatus, (iy + dirtyFlags)
    ret z
    ld hl, statusPenRow*$100 + statusFloatModePenCol; $(penRow)(penCol)
    ld (PenCol), hl
    ; check float mode
    bit fmtExponent, (iy + fmtFlags)
    jr nz, displayStatusFloatModeSciOrEng
displayStatusFloatModeFix:
    ld hl, msgFixLabel
    jr displayStatusFloatModeBracketDigit
displayStatusFloatModeSciOrEng:
    bit fmtEng, (iy + fmtFlags)
    jr nz, displayStatusFloatModeEng
displayStatusFloatModeSci:
    ld hl, msgSciLabel
    jr displayStatusFloatModeBracketDigit
displayStatusFloatModeEng:
    ld hl, msgEngLabel
    ; [[fallthrough]]
displayStatusFloatModeBracketDigit:
    ; Print the number of digit
    call vPutS
    ld a, (fmtDigits)
    cp 10
    jr nc, displayStatusFloatModeFloating
    add a, '0'
    jr displayStatusFloatModeDigit
displayStatusFloatModeFloating:
    ld a, '-'
displayStatusFloatModeDigit:
    bcall(_VPutMap)
    ret

;-----------------------------------------------------------------------------

; Description: Display the Degree or Radian trig mode.
displayStatusTrig:
    bit dirtyFlagsStatus, (iy + dirtyFlags)
    ret z
    ld hl, statusPenRow*$100 + statusTrigPenCol; $(penRow)(penCol)
    ld (PenCol), hl
    bit trigDeg, (iy + trigFlags)
    jr z, displayStatusTrigRad
displayStatusTrigDeg:
    ld hl, msgDegLabel
    jr displayStatusTrigPutS
displayStatusTrigRad:
    ld hl, msgRadLabel
displayStatusTrigPutS:
    call vPutS
    ret

;-----------------------------------------------------------------------------

; Description: Display the Carry Flag used in BASE mode.
displayStatusBase:
    bit dirtyFlagsStatus, (iy + dirtyFlags)
    ret z
    ld hl, statusPenRow*$100 + statusBasePenCol; $(penRow)(penCol)
    ld (PenCol), hl
    ; Determine state of Carry Flag.
    ld a, (baseCarryFlag)
    or a
    jr z, displayStatusBaseCarryFlagOff
displayStatusBaseCarryFlagOn:
    ld a, 'C'
    jr displayStatusBasePutS
displayStatusBaseCarryFlagOff:
    ld a, '-'
displayStatusBasePutS:
    bcall(_VPutMap)
    ret

;-----------------------------------------------------------------------------

; Description: Display the complexMode setting on the status line.
displayStatusComplexMode:
    bit dirtyFlagsStatus, (iy + dirtyFlags)
    ret z
    ld hl, statusPenRow*$100 + statusComplexModePenCol; $(penRow)(penCol)
    ld (PenCol), hl
    ; Determine state of complexMode
    ld a, (complexMode)
    ; Check complexModeRad
    cp complexModeRad
    jr nz, displayStatusComplexModeCheckDeg
    ; complexModeRad
    ld hl, msgComplexModeRadLabel
    jr displayStatusComplexModePutS
displayStatusComplexModeCheckDeg:
    cp complexModeDeg
    jr nz, displayStatusComplexModeCheckRect
    ; complexModeDeg
    ld hl, msgComplexModeDegLabel
    jr displayStatusComplexModePutS
displayStatusComplexModeCheckRect:
    cp complexModeRect
    jr z, displayStatusComplexModeRect
displayStatusComplexModeFix:
    ; Should never happen, but if it does, fix the darned complexMode.
    ld a, complexModeRect
    ld (complexMode), a
displayStatusComplexModeRect:
    ; complexModeRect
    ld hl, msgComplexModeRectLabel
displayStatusComplexModePutS:
    call vPutS
    ret

;-----------------------------------------------------------------------------

; Description: Display the RPN Stack mode.
displayStatusStackMode:
    bit dirtyFlagsStatus, (iy + dirtyFlags)
    ret z
    ld hl, statusPenRow*$100 + statusStackModePenCol; $(penRow)(penCol)
    ld (PenCol), hl
    ; print the stackSize variable first
    ld a, (stackSize)
    add a, '0'
    bcall(_VPutMap)
    ; then the label
    ld hl, msgStkLabel
    call vPutS
    ret

;-----------------------------------------------------------------------------
; Routines for displaying the error code and string.
;-----------------------------------------------------------------------------

; Description: Display the string corresponding to the current error code.
; Input: errorCode
; Output:
;   - string corresponding to errorCode displayed
; Destroys: A, DE, HL
displayErrorCode:
    ; Check if the error code changed
    bit dirtyFlagsErrorCode, (iy + dirtyFlags)
    ret z ; return if no change
    ; Display nothing if errorCode == OK (0)
    res fracDrawLFont, (iy + fontFlags) ; use small font
    ld hl, errorPenRow*$100 ; $(penRow)(penCol)
    ld (PenCol), hl
    ld a, (errorCode)
    or a
    jr z, displayErrorCodeEnd
    ; Print error string and its numerical code.
    bcall(_PrintErrorString)
displayErrorCodeEnd:
    call vEraseEOL
    res dirtyFlagsErrorCode, (iy + dirtyFlags)
    ret

;-----------------------------------------------------------------------------
; Display the main panel, depending on DRAW mode.
;-----------------------------------------------------------------------------

; Description: Display the main area, depending on the drawMode. It will
; usually the RPN stack, but can be something else for debugging.
; Destroys: A, OP3-OP6
displayMain:
    bit rpnFlagsShowModeEnabled, (iy + rpnFlags)
    jp nz, displayShow
    ld a, (drawMode)
    cp drawModeNormal
    jr z, displayStack
    cp drawModeTvmSolverI
    jr z, displayTvmMaybe
    cp drawModeTvmSolverF
    jr z, displayTvmMaybe
    cp drawModeInputBuf
    jr z, displayStack
    ; Everything else display the stack.
    jr displayStack
displayTvmMaybe:
    ld a, (tvmSolverIsRunning)
    or a
    jp nz, displayTvm
    ; [[fallthrough]]

;-----------------------------------------------------------------------------
; Routines for displaying the RPN stack variables.
;-----------------------------------------------------------------------------

; Description: Display the RPN stack variables
; Input: none
; Output: (dirtyFlagsMenu) reset
; Destroys: A, HL, OP1-OP6
displayStack:
    ; display YZT if stack is dirty
    bit dirtyFlagsStack, (iy + dirtyFlags)
    call nz, displayStackYZT
    ; display X if stack or inputBuf are dirty
    bit dirtyFlagsStack, (iy + dirtyFlags)
    jr nz, displayStackX
    bit dirtyFlagsInput, (iy + dirtyFlags)
    jr nz, displayStackX
    ret

;-----------------------------------------------------------------------------

; Destroys: A, HL, OP1-OP6
displayStackYZT:
    ; print T label
    ld hl, stTPenRow*$100 ; $(penRow)(penCol)
    ld (PenCol), hl
    ld hl, msgTLabel
    call vPutSmallS

    ; print T value
    ld hl, stTCurCol*$100 + stTCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    call rclT
    ld b, displayStackFontFlagsT
    call printOP1

    ; print Z label
    ld hl, stZPenRow*$100 ; $(penRow)(penCol)
    ld (PenCol), hl
    ld hl, msgZLabel
    call vPutSmallS

    ; print Z value
    ld hl, stZCurCol*$100 + stZCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    call rclZ
    ld b, displayStackFontFlagsZ
    call printOP1

    ; print Y label
    ld hl, stYPenRow*$100 ; $(penRow)(penCol)
    ld (PenCol), hl
    ld hl, msgYLabel
    call vPutSmallS

    ; print Y value
    ld hl, stYCurCol*$100 + stYCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    call rclY
    ld b, displayStackFontFlagsY
    call printOP1

    ret

;-----------------------------------------------------------------------------

; Description: Render the X register line. There are multiple modes:
; 1) If rpnFlagsArgMode, print the argBuf for the ArgScanner, else
; 2) If rpnFlagsEditing, print the current inputBuf, else
; 3) Print the X register.
;
; Well... unless drawMode==drawModeInputBuf, in which case the inputBuf is
; displayed separately on the debug line, and the X register is always printed
; on the X line.
; Destroys: OP1-OP6
displayStackX:
    bit rpnFlagsArgMode, (iy + rpnFlags)
    jr nz, displayStackXArg
    ; If drawMode==drawModeInputBuf, print the inputBuf and X register on 2
    ; separate lines, instead of overlaying the inputBuf on the X register
    ; line. This helps with debugging the inputBuf. The inputBuf is printed on
    ; the debug line, and the X register is printed on the X register line.
    ld a, (drawMode)
    cp drawModeInputBuf
    jr z, displayStackXBoth
    ; If drawMode!=drawModeInputBuf: draw X or inputBuf, depending on the
    ; rpnFlagsEditing.
    bit rpnFlagsEditing, (iy + rpnFlags)
    jr nz, displayStackXInput
    jr displayStackXNormal
displayStackXBoth:
    ; If drawMode==drawModeInputBuf: draw both X and inputBuf on separate lines.
    call displayStackXInputAtDebug
    ; [[fallthrough]]

displayStackXNormal:
    call displayStackXLabel
    ; print the X register
    ld hl, stXCurCol*$100 + stXCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    call rclX
    ld b, displayStackFontFlagsX
    jp printOP1

displayStackXInput:
    call displayStackXLabel
    ; print the inputBuf
    ld hl, inputCurCol*$100 + inputCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    ld b, displayStackFontFlagsX
    call displayStackSetLargeFont
    bcall(_PrintInputBuf)
    ret

; Display the inputBuf in the debug line. Used for DRAW mode 3.
displayStackXInputAtDebug:
    ld hl, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    bcall(_PrintInputBuf)
    ret

displayStackXLabel:
    ; If the "X:" label was corrupted by the command arg mode label, then
    ; clear the cell with an Lspace.
    bit dirtyFlagsXLabel, (iy + dirtyFlags)
    jr nz, displayStackXLabelContinue
    ld hl, 0*$100 + stXCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    ld a, Lspace
    bcall(_PutC)
    res dirtyFlagsXLabel, (iy + dirtyFlags)
displayStackXLabelContinue:
    ; print X label
    ld hl, inputPenRow*$100 ; $(penRow)(penCol)
    ld (PenCol), hl
    ld hl, msgXLabel
    call vPutSmallS
    ret

;-----------------------------------------------------------------------------

; Display the argBuf in the X register line.
; Input: (argBuf)
; Output: (CurCol) updated
displayStackXArg:
    ; Set commandArg cursor position.
    ld hl, argCurCol*$100 + argCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    ld b, displayStackFontFlagsX
    ; [[fallthrough]]

; Description: Print the arg buffer at the (CurRow) and (CurCol).
; Input:
;   - B=displayFontMask
;   - argBuf (same as inputBuf)
;   - argPrompt
;   - argModifier
;   - (CurCol) cursor position
; Output:
;   - (CurCol) is updated
;   - (displayStackFontFlagsX) cleared to indicate large font
; Destroys: A, HL; BC destroyed by PutPS()
printArgBuf:
    call displayStackSetLargeFont
    ; Print prompt and contents of argBuf
    ld hl, (argPrompt)
    call putS
    ; Print the argModifier
    ld a, (argModifier)
    ld hl, argModifierStrings
    call getString
    call putS
    ; Print the command argument.
    ld hl, argBuf
    call putPS
    ; Print any trailing cursors.
    call printArgTrailing
    bcall(_EraseEOL)
    ret

; Description: Print 1 or more trailing cursor characters, i.e. "_ _ _" up to a
; maximum of (argLenLimit).
; Destroys: A, B
printArgTrailing:
    ; cursorLen=(argLenLimit)-(argBufLen)
    ld a, (argBufLen)
    ld b, a ; B=argBufLen
    ld a, (argLenLimit)
    sub b ; A=cursorLen=argLenLimit-argBufLen
    ret z
    ret c ; do nothing if argBufLen>argLenLimit; should never happen
    ld b, a
printArgTrailingLoop:
    ld a, cursorChar
    bcall(_PutC) ; preserves B
    djnz printArgTrailingLoop
    ret

; Human-readable labels for each of the argModifierXxx enum.
argModifierStrings:
    .dw msgArgModifierNone
    .dw msgArgModifierAdd
    .dw msgArgModifierSub
    .dw msgArgModifierMul
    .dw msgArgModifierDiv
    .dw msgArgModifierIndirect

msgArgModifierNone:
    .db " ", 0
msgArgModifierAdd:
    .db "+ ", 0
msgArgModifierSub:
    .db "- ", 0
msgArgModifierMul:
    .db "* ", 0
msgArgModifierDiv:
    .db "/ ", 0
msgArgModifierIndirect:
    .db " IND ", 0

;-----------------------------------------------------------------------------
; Routines to display the progress of the TVM solver (for debugging).
;-----------------------------------------------------------------------------

; Description: Display the intermediate state of the TVM Solver. This routine
; will be invoked only if drawMode==1 or 2.
; Destroys: OP3-OP6
displayTvm:
    ; print TVM n label
    ld hl, tvmNPenRow*$100 ; $(penRow)(penCol)
    ld (PenCol), hl
    ld hl, msgTvmNLabel
    call vPutSmallS

    ; print TVM n value
    ld hl, tvmNCurCol*$100 + tvmNCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    bcall(_RclTvmSolverCount)
    ld b, displayStackFontFlagsT
    call printOP1

    ; print TVM i0 or npmt0 label
    ld hl, tvmI0PenRow*$100 ; $(penRow)(penCol)
    ld (PenCol), hl
    ld hl, msgTvmI0Label
    call vPutSmallS

    ; print TVM i0 or npmt0 value
    ld hl, tvmI0CurCol*$100 + tvmI0CurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    ld a, (drawMode)
    cp a, drawModeTvmSolverI ; if drawMode==1: ZF=1
    jr z, displayTvmI0
    bcall(_RclTvmNPMT0)
    jr displayTvm0
displayTvmI0:
    bcall(_RclTvmI0)
displayTvm0:
    ld b, displayStackFontFlagsZ
    call printOP1

    ; print TVM i1 or npmt1 label
    ld hl, tvmI1PenRow*$100 ; $(penRow)(penCol)
    ld (PenCol), hl
    ld hl, msgTvmI1Label
    call vPutSmallS

    ; print TVM i1 or npmt1 value
    ld hl, tvmI1CurCol*$100 + tvmI1CurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    ld a, (drawMode)
    cp a, drawModeTvmSolverI ; if drawMode==1: ZF=1
    jr z, displayTvmI1
    bcall(_RclTvmNPMT1)
    jr displayTvm1
displayTvmI1:
    bcall(_RclTvmI1)
displayTvm1:
    ld b, displayStackFontFlagsY
    call printOP1

    ; print the TVM empty line
    ld hl, tvmExtraCurCol*$100 + tvmExtraCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    bcall(_EraseEOL)
    ret

;-----------------------------------------------------------------------------
; Routines for displaying the menu bar.
;-----------------------------------------------------------------------------

; Description: Display the bottom menus.
; Input: none
; Output: (dirtyFlagsMenu) reset
; Destroys: A, HL
displayMenu:
    bit dirtyFlagsMenu, (iy + dirtyFlags)
    ret z
    ; get starting menuId
    res fracDrawLFont, (iy + fontFlags) ; use small font
    bcall(_GetCurrentMenuRowBeginId) ; HL=rowMenuId
    ; set up loop over 5 consecutive menu buttons
    ld e, 0 ; E = menuIndex [0,4]
    ld c, menuPenCol0 ; C = penCol
    ld b, 5 ; B = loop 5 times
displayMenuLoop:
    push hl ; stack=[menuId]
    call getMenuName ; HL:(const char*)=menuName; A=numRows
    bcall(_PrintMenuNameAtC) ; preserves A, BC, DE
    bcall(_DisplayMenuFolder) ; preserves A, BC, DE
    pop hl ; stack=[]; HL=menuId
    ; increment to next menu
    inc hl ; HL=menuId+1
    inc e ; E=menuIndex+1
    ld a, c ; A = penCol
    add a, menuPenWidth + 1 ; A += menuWidth + 1 (1px spacing)
    ld c, a ; C += menuPenWidth + 1
    djnz displayMenuLoop
    ret

;-----------------------------------------------------------------------------
; SHOW mode
;-----------------------------------------------------------------------------

msgShowLabel:
    .db "SHOW", 0

; Description: Display the X register in SHOW mode, showing all 14 significant
; digits.
; Destroys; A, HL, OP1, OP3-OP6
displayShow:
    ; Print 'SHOW' label on Error Code line
    ld hl, errorPenRow*$100 ; $(penRow)(penCol)
    ld (PenCol), hl
    ld hl, msgShowLabel
    call vPutSmallS
    call vEraseEOL
    ; Call special FormShowable() function to show all digits of OP1.
    ld hl, showCurCol*$100 + showCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    call rclX
    ; fmtString is a buffer of 65 bytes used by FormDCplx(). There should be no
    ; problems using it as our string buffer.
    ld de, fmtString
    bcall(_FormShowable)
    ld hl, fmtString
    call putS
    ret

; Clear the display area used by the SHOW feature (errorCode, T, Z, Y, X).
; Input: none
; Destroys: A, B, HL
clearShowArea:
    ld hl, errorCurCol*$100 + errorCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    ld b, 5
clearShowAreaLoop:
    bcall(_EraseEOL) ; saves all registers
    ld hl, (CurRow)
    inc l
    ld (CurRow), hl
    djnz clearShowAreaLoop
    ret

;-----------------------------------------------------------------------------
; Low-level helper routines.
;-----------------------------------------------------------------------------

; Description: Print data in OP1 at the current cursor. The data could be a
; real number, a complex number, or RpnObject. Erase to the end of line (but
; only if the floating point did not spill over to the next line).
;
; Input:
;   - A:u8=objectType
;   - B=displayFontMask
;   - OP1:(Real|Complex|RpnObject)=value
; Destroys: A, HL, OP3-OP6
printOP1:
    call getOp1RpnObjectType ; A=type; HL=OP1
    ; The rpnObjecTypes are tested in order of decreasing frequency.
    cp rpnObjectTypeReal
    jr z, printOP1Real
    ;
    cp rpnObjectTypeComplex
    jr z, printOP1Complex
    ;
    cp rpnObjectTypeDate
    jp z, printOP1DateRecord
    ;
    cp rpnObjectTypeTime
    jp z, printOP1TimeRecord
    ;
    cp rpnObjectTypeDateTime
    jp z, printOP1DateTimeRecord
    ;
    cp rpnObjectTypeOffset
    jp z, printOP1OffsetRecord
    ;
    cp rpnObjectTypeOffsetDateTime
    jp z, printOP1OffsetDateTimeRecord
    ;
    cp rpnObjectTypeDayOfWeek
    jp z, printOP1DayOfWeekRecord
    ;
    cp rpnObjectTypeDuration
    jp z, printOP1DurationRecord
    ;
    ld hl, msgRpnObjectTypeUnknown
    jp printHLString

;-----------------------------------------------------------------------------

; Description: Print the real number in OP1, taking into account the BASE mode.
; This routine always uses large font, so it never needs to clear the line with
; EraseEOL(), so the displayFontMask does not need to be used.
; Input:
;   - OP1: real number
;   - B=displayFontMask
; Destroys: OP3-OP6
printOP1Real:
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    jp z, printOP1AsFloat
    ld a, (baseNumber)
    cp 16
    jp z, printOP1Base16
    cp 8
    jp z, printOP1Base8
    cp 2
    jp z, printOP1Base2
    jp printOP1Base10

;-----------------------------------------------------------------------------

; Description: Print a complex number. The LCD screen is 96 pixels wide. The
; stack label is 6 pixels, leaving 90 pixels. Each small font character is 4
; pixels wide for digits, exponent 'E', and minus sign. A decimal point is only
; 2 pixels wide, so we have extra space. So that's 22 small-font characters.
; The imaginary-i is 4 pixels. Add a space on either wide, for 2 more pixels.
; So this means that we can print the Re and Im parts using a width of 10 each,
; then add the imaginary-i character in between, and still fit inside the 96
; pixel limit.
;
; A complex number is always printed using small font. If the previous
; rendering was done using large font, then we must call EraseEOL() before
; printing the small font characters, to avoid artifacts on the bottom row. The
; displayFontMask in B will tell us the previous font.
;
; Input:
;   - CP1: complex number
;   - B=displayFontMask
; Destroys: OP3-OP6
printOP1Complex:
    call eraseEOLIfNeeded ; uses B
    call displayStackSetSmallFont
    ld a, (complexMode)
    cp a, complexModeRect
    jr z, printOP1ComplexRect
    cp a, complexModeRad
    jr z, printOP1ComplexRad
    cp a, complexModeDeg
    jp z, printOP1ComplexDeg
    ; [[falltrhough]]

; Description: Print the complex numberin CP1 in rectangular form.
; Input: CP1: complex number
; Destroys: OP3-OP6
printOP1ComplexRect:
    ld de, fmtString
    bcall(_FormatComplexRect)
    ld hl, fmtString
    call vPutSmallS
    jp vEraseEOL

; Description: Print the complex numberin CP1 in polar form using radians.
; Note: An r value >= 1e100 or <= 1e-100 can be returned by complexRToPRad()
; and will be displayed by this function. This is useful because that means we
; can display the entire domain of the rectangular complex numbers, even when
; the 'r' value goes beyond 1e100 or 1e-100.
; Input: CP1: complex number
; Destroys: OP3-OP6
printOP1ComplexRad:
    ld de, fmtString
    bcall(_FormatComplexPolarRad)
    ld hl, fmtString
    call vPutSmallS
    jp vEraseEOL

; Description: Print the complex numberin CP1 in polar form using degrees.
; Note: An r value >= 1e100 or <= 1e-100 can be returned by complexRToPRad()
; and will be displayed by this function. This is useful because that means we
; can display the entire domain of the rectangular complex numbers, even when
; the 'r' value goes beyond 1e100 or 1e-100.
; Input: CP1: complex number
; Destroys: A, HL, OP3-OP6
printOP1ComplexDeg:
    ld de, fmtString
    bcall(_FormatComplexPolarDeg)
    ld hl, fmtString
    call vPutSmallS
    jp vEraseEOL

;-----------------------------------------------------------------------------

; Erase the previous rendering on the line identified by the mask in B
; if the previous rendering was done in large font (fontMask==0).
; Input:
;   - (displayStackFontFlags)
;   - B=displayFontMask
; Destroys: A
eraseEOLIfNeeded:
    ld a, (displayStackFontFlags)
    and b ; if previous==smallFont: ZF=0
    ret nz ; if previous==smallFont: ret
    bcall(_EraseEOL) ; all registered saved
    ret

; Description: Mark the stack line identified by B as using small font.
; Input: B=displayFontMask
; Output: displayStackFontFlags |= B
; Destroys: A
displayStackSetSmallFont:
    ld a, (displayStackFontFlags)
    or b ; A=displayFontMask OR (displayStackFontFlags)
    ld (displayStackFontFlags), a
    ret

; Description: Mark the stack line identified by B as using large font.
; Input: B=displayFontMask
; Output: displayStackFontFlags &= (~B)
; Destroys: A
displayStackSetLargeFont:
    ld a, (displayStackFontFlags)
    cpl ; A=~displayFontMask
    or b ; A=(~displayFontMask|B)
    cpl ; A=(displayFontMask & ~B)
    ld (displayStackFontFlags), a
    ret

;-----------------------------------------------------------------------------

; Description: Print floating point number at OP1 using base 10.
; Input: OP1: floating point number
; Destroys: A, HL, OP3
printOP1AsFloat:
    call displayStackSetLargeFont
    ld a, 15 ; width of output
    bcall(_FormReal)
    ld hl, OP3
    ; [[fallthrough]]

; Description: Print the C-string referenced by HL, and erase to the end of
; line, taking care that the cursor did not move to the next line
; automatically.
; Input: HL:(const char*)
; Output:
; Destroys: A, HL
printHLString:
    call putS
    ld a, (CurCol)
    or a
    ret z ; if spilled to next line, don't call EraseEOL
    bcall(_EraseEOL)
    ret

; Description: Print an indicator ("...") that the OP1 number cannot be
; rendered in the current base mode (hex, oct, or bin).
printOP1BaseInvalid:
    ld hl, msgBaseInvalid
    jr printHLString

; Description: Print just a negative sign for OP1 number that is negative.
; Negative numbers cannot be displayed in base HEX, OCT or BIN modes.
printOP1BaseNegative:
    ld hl, msgBaseNegative
    jr printHLString

;-----------------------------------------------------------------------------

; Description: Print integer at OP1 at the current cursor in base 10. Erase to
; the end of line (but only if the digits did not spill over to the next line).
; Input:
;   - OP1
;   - B=displayFontMask
; Destroys: all, OP1-OP6
printOP1Base10:
    call displayStackSetLargeFont
    bcall(_ConvertOP1ToUxxNoFatal) ; HL=OP1=uxx(OP1); C=u32StatusCode
    bit u32StatusCodeTooBig, c
    jr nz, printOP1BaseInvalid
    bit u32StatusCodeNegative, c
    jr nz, printOP1BaseNegative
    ; Convert u32 into a base-10 string.
    ld de, OP4
    bcall(_FormatU32ToDecString) ; DE=formattedString
    ; Add '.' if OP1 has fractional component.
    call appendHasFrac ; DE=rendered string
    ex de, hl ; HL=rendered string
    jr printHLString

; Description: Append a '.' at the end of the string if u32StatusCode contains
; u32StatusCodeHasFrac.
; Input:
;   - C: u32StatusCode
;   - DE: pointer to ascii string
; Output:
;   - DE: pointer to ascii string with '.' appended if u32StatusCodehasFrac is
;   enabled
; Destroys: A
; Preserves, BC, DE, HL
appendHasFrac:
    bit u32StatusCodeHasFrac, c
    ret z
    ld a, '.'
    ex de, hl
    call appendCString
    ex de, hl
    ret

;-----------------------------------------------------------------------------

; Description: Print ingeger at OP1 at the current cursor in base 16. Erase to
; the end of line (but only if the digits did not spill over to the next line).
; TODO: I think printOP1Base16(), printOP1Base8(), and printOP1Base2() can be
; combined into a single subroutine, saving memory.
; Input:
;   - OP1
;   - B=displayFontMask
; Destroys: all, OP1-OP5
printOP1Base16:
    call displayStackSetLargeFont
    bcall(_ConvertOP1ToUxxNoFatal) ; OP1=U32; C=u32StatusCode
    bit u32StatusCodeTooBig, c
    jr nz, printOP1BaseInvalid
    bit u32StatusCodeNegative, c
    jr nz, printOP1BaseNegative
    ; Convert u32 into a base-16 string.
    ld de, OP4
    bcall(_FormatU32ToHexString) ; DE=formattedString
    ; Append frac indicator
    call appendHasFrac ; DE=rendered string
    ex de, hl ; HL=rendered string
    call truncateHexDigits
    jr printHLString

; Description: Truncate upper digits depending on baseWordSize.
; Input: HL: pointer to rendered string
; Output: HL: pointer to truncated string
; Destroys: A, DE
truncateHexDigits:
    ld a, (baseWordSize)
    srl a
    srl a ; A=2,4,6,8
    sub 8
    neg ; A=6,4,2,0
    ld e, a
    ld d, 0
    add hl, de
    ret

;-----------------------------------------------------------------------------

; Description: Print ingeger at OP1 at the current cursor in base 8. Erase to
; the end of line (but only if the digits did not spill over to the next line).
; Input:
;   - OP1
;   - B=displayFontMask
; Destroys: all, OP1-OP5
printOP1Base8:
    call displayStackSetLargeFont
    bcall(_ConvertOP1ToUxxNoFatal) ; OP1=U32; C=u32StatusCode
    bit u32StatusCodeTooBig, c
    jr nz, printOP1BaseInvalid
    bit u32StatusCodeNegative, c
    jr nz, printOP1BaseNegative
    ; Convert u32 into a base-8 string.
    ld de, OP4
    bcall(_FormatU32ToOctString) ; DE=formattedString
    ; Append frac indicator
    call appendHasFrac ; DE=rendered string
    ex de, hl ; HL=rendered string
    call truncateOctDigits
    jp printHLString

; Truncate upper digits depending on baseWordSize. For base-8, the u32 integer
; was converted to 11 digits (33 bits). The number of digits to retain for each
; baseWordSize is: {8: 3, 16: 6, 24: 8, 32: 11}, so the number of digits to
; truncate is: {8: 8, 16: 5, 24: 3, 32: 0}.
; Input: HL: pointer to rendered string
; Output: HL: pointer to truncated string
; Destroys: A, DE
truncateOctDigits:
    ld a, (baseWordSize)
    cp 8
    jr nz, truncateOctDigits16
    ld e, a
    jr truncateOctString
truncateOctDigits16:
    cp 16
    jr nz, truncateOctDigits24
    ld e, 5
    jr truncateOctString
truncateOctDigits24:
    cp 24
    jr nz, truncateOctDigits32
    ld e, 3
    jr truncateOctString
truncateOctDigits32:
    ld e, 0
truncateOctString:
    ld d, 0
    add hl, de
    ret

;-----------------------------------------------------------------------------

; Description: Print integer at OP1 at the current cursor in base 2. Erase to
; the end of line (but only if the floating point did not spill over to the
; next line).
;
; The display can handle a maximum of 15 digits (1 character for
; the "X:" label). We need one space for a trailing "." so that's 14 digits. We
; also want to display the binary digits in group of 4, separated by a space
; between groups, for readability, With 3 groups of 4 digits plus 2 spaces in
; between, that's exactly 14 characters.
;
; If there are non-zero digits after the left most digit (digit 13 from the
; right, zero-based), then digit 13 should be replaced with a one-character
; ellipsis character to indicate hidden digits. The SHOW command can be used to
; display the additional digits.
;
; Input:
;   - OP1
;   - B=displayFontMask
; Destroys: all, OP1-OP5
printOP1Base2:
    ; Convert OP1 into Uxx first, so that we can determine whether to display
    ; the results using small font or large font.
    push bc ; stack=[displayFontMask]
    bcall(_ConvertOP1ToUxxNoFatal) ; HL=OP1=uxx(OP1); C=u32StatusCode
    pop de ; D=displayFontMask
    ld b, d ; B=displayFontMask
    ; Check for errors
    bit u32StatusCodeTooBig, c
    jr nz, printOP1Base2TooBig
    bit u32StatusCodeNegative, c
    jr nz, printOP1Base2Negative
    push bc ; stack=[u32StatusCode]
    ; Convert HL=u32 into a base-2 string.
    ld de, fmtString
    bcall(_FormatU32ToBinString) ; DE=fmtString=formattedString
    ; Truncate leading digits to fit display (12 or 8 digits)
    ex de, hl ; HL=formattedString
    bcall(_TruncateBinDigits) ; HL=truncatedString; A=strLen
    ; Group digits in groups of 4.
    ld de, OP3
    bcall(_FormatBinDigits) ; DE=formattedString=OP3
    ; Append frac indicator
    pop bc ; stack=[]; C=u32StatusCode
    call appendHasFrac ; DE=formattedString
    ;
    ex de, hl ; HL=formattedString
    jr printBase2StringSmallOrLarge
    ;
printOP1Base2TooBig:
    call displayStackSetLargeFont
    jp printOP1BaseInvalid
printOP1Base2Negative:
    call displayStackSetLargeFont
    jp printOP1BaseNegative

; Description: Print the string in HL in large font size for WSIZ=8, and small
; font for WSIZ=16,24,32.
; Destroys: A, HL
printBase2StringSmallOrLarge:
    ld a, (baseWordSize)
    cp 16 ; CF=0 if baseWordSize >= 16
    jr nc, printBase2StringSmall
    call displayStackSetLargeFont
    jp printHLString
printBase2StringSmall:
    call eraseEOLIfNeeded ; uses B
    call displayStackSetSmallFont
    bcall(_ConvertBinDigitsToSmallFont)
    call vPutSmallS ; TODO: create a printHLStringSmall() routine.
    jp vEraseEOL

;-----------------------------------------------------------------------------
; RpnObject records.
;-----------------------------------------------------------------------------

; Description: Print the RpnDate Record in OP1 using small font.
; Input:
;   - OP1:RpnDate
;   - B=displayFontMask
; Destroys: OP3-OP6
printOP1DateRecord:
    call eraseEOLIfNeeded ; uses B
    call displayStackSetSmallFont
    ; format OP1
    ld hl, OP1
    ld de, OP3 ; destPointer
    push de
    bcall(_FormatDate)
    xor a
    ld (de), a ; add NUL terminator
    ; print string stored in OP3
    pop hl ; HL=OP3
    call vPutSmallS
    jp vEraseEOL

; Description: Print the RpnTime Record in OP1 using small font.
; Input:
;   - OP1:RpnTime
;   - B=displayFontMask
; Destroys: OP3-OP6
printOP1TimeRecord:
    call eraseEOLIfNeeded ; uses B
    call displayStackSetSmallFont
    ; format OP1
    ld hl, OP1
    ld de, OP3 ; destPointer
    push de
    bcall(_FormatTime)
    xor a
    ld (de), a ; add NUL terminator
    ; print string stored in OP3
    pop hl ; HL=OP3
    call vPutSmallS
    jp vEraseEOL

; Description: Print the RpnDateTime Record in OP1 using small font.
; Input:
;   - OP1:RpnDateTime Record
;   - B=displayFontMask
; Destroys: OP3-OP6
printOP1DateTimeRecord:
    call eraseEOLIfNeeded ; uses B
    call displayStackSetSmallFont
    ; format OP1
    ld hl, OP1
    ld de, OP3 ; destPointer
    push de
    bcall(_FormatDateTime)
    ; print string stored in OP3
    pop hl ; HL=OP3
    call vPutSmallS
    jp vEraseEOL

; Description: Print the RpnOffset Record in OP1 using small font.
; Input:
;   - OP1:RpnOffset Record
;   - B=displayFontMask
; Destroys: all, OP3-OP6
printOP1OffsetRecord:
    call eraseEOLIfNeeded ; uses B
    call displayStackSetSmallFont
    ld hl, OP1
    ld de, OP3 ; destPointer
    push de
    bcall(_FormatOffset)
    ; print string stored in OP3
    pop hl ; HL=OP3
    call vPutSmallS
    jp vEraseEOL

; Description: Print the RpnOffsetDateTime Record in OP1 using small font.
; Input:
;   - OP1:RpnOffsetDateTime Record
;   - B=displayFontMask
; Destroys: all, OP3-OP6
printOP1OffsetDateTimeRecord:
    call eraseEOLIfNeeded ; uses B
    call displayStackSetSmallFont
    ; format OP1
    call shrinkOp2ToOp1
    ld hl, OP1
    ld de, OP3 ; destPointer
    push de
    bcall(_FormatOffsetDateTime)
    call expandOp1ToOp2
    ; print string stored in OP3
    pop hl ; HL=OP3
    call vPutSmallS
    jp vEraseEOL

; Description: Print the RpnDayOfWeek record in OP1 using small font.
; Input:
;   - OP1:RpnDayOfWeek
;   - B=displayFontMask
printOP1DayOfWeekRecord:
    call eraseEOLIfNeeded ; uses B
    call displayStackSetSmallFont
    ; format OP1
    ld hl, OP1
    ld de, OP3 ; destPointer
    push de
    bcall(_FormatDayOfWeek)
    ; print string stored in OP3
    pop hl ; HL=OP3
    call vPutSmallS
    jp vEraseEOL

; Description: Print the RpnDuration record in OP1 using small font.
; Input:
;   - OP1:RpnDuration
;   - B=displayFontMask
printOP1DurationRecord:
    call eraseEOLIfNeeded ; uses B
    call displayStackSetSmallFont
    ; format OP1
    ld hl, OP1
    ld de, OP3 ; destPointer
    push de
    bcall(_FormatDuration)
    ; print string stored in OP3
    pop hl ; HL=OP3
    call vPutSmallS
    jp vEraseEOL

;-----------------------------------------------------------------------------
; String constants.
;-----------------------------------------------------------------------------

; Indicates number has overflowed the current Base mode.
msgBaseInvalid:
    .db "...", 0

; Indicates number is negative so cannot be rendered in Base mode.
msgBaseNegative:
    .db "-", 0

; RPN stack variable labels
msgTLabel:
    .db "T:", 0
msgZLabel:
    .db "Z:", 0
msgYLabel:
    .db "Y:", 0
msgXLabel:
    .db "X:", 0

; Floating point mode indicators. Previously reused the strings in menudef.asm,
; but it got moved into Flash Page 1, so we have to copy them here.
msgFixLabel:
    .db "FIX", 0
msgSciLabel:
    .db "SCI", 0
msgEngLabel:
    .db "ENG", 0

; DEG or RAD indicators. Previously reused the strings in menudef.asm, but it
; got moved into Flash Pae 1, so we have to copy them here.
msgDegLabel:
    .db "DEG", 0
msgRadLabel:
    .db "RAD", 0

; RPN stack mode indicators.
msgStkLabel:
    .db "STK", 0

; TVM debug labels
msgTvmNLabel:
    .db "n:", 0
msgTvmI0Label:
    .db "0:", 0
msgTvmI1Label:
    .db "1:", 0

; ComplexMode labels
msgComplexModeRectLabel:
    .db "a", SimagI, "b", 0
msgComplexModeRadLabel:
    .db "r", Sangle, Stheta, 0
msgComplexModeDegLabel:
    .db "r", Sangle, Stemp, 0

; Unknown RpnObjectType
msgRpnObjectTypeUnknown:
    .db "{Unknown}", 0
