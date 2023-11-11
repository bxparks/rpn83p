;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Display the calculator modes, status, and RPN stack variables using 8 lines
; of the 96(w)x64(h) LCD display, using a mixture of small and large fonts.
; The format looks roughly like this:
;
; 0: Status: (left,up,down) (Deg|Rad) (Fix|Sci|Eng) (Dec|Hex|Oct|Bin)
; 1: Debug: Debugging output, not used in app
; 2: Error code
; 3: T: tttt
; 4: Z: zzzz
; 5: Y: yyyy
; 6: X: xxxx
; 7: Menu: [menu1][menu2][menu3][menu4][menu5]
;-----------------------------------------------------------------------------

; Display coordinates of the top status line
statusCurRow equ 0
statusCurCol equ 0
statusPenRow equ statusCurRow*8
statusMenuPenCol equ 0 ; left, up, down, 2px = 3*4 + 2 = 14px
statusFloatModePenCol equ 14 ; (FIX|SCI|ENG), (, N, ), 4px = 5*4+2*3 = 26px
statusTrigPenCol equ 40 ; (DEG|RAD), 4px = 4*4 = 16px
statusBasePenCol equ 56 ; (C|-), 4px

; Display coordinates of the debug line
debugCurRow equ 1
debugCurCol equ 0
debugPenRow equ debugCurRow*8

; Display coordinates of the error line
errorCurRow equ 2
errorCurCol equ 0
errorPenRow equ errorCurRow*8

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

; Display coordinates of the input buffer.
inputCurRow equ stXCurRow
inputCurCol equ stXCurCol
inputPenRow equ inputCurRow*8

; Display coordinates of the arg buffer.
argCurRow equ 6
argCurCol equ 0
argPenRow equ argCurRow*8

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
menuPenWidth    equ 18 ; excludes 1 px space between menu items
menuPenColStart equ 0 ; left edge of menu line
menuPenCol0     equ 1 ; left edge of menu0
menuPenCol1     equ 20 ; left edge of menu1
menuPenCol2     equ 39 ; left edge of menu2
menuPenCol3     equ 58 ; left edge of menu3
menuPenCol4     equ 77 ; left edge of menu4
menuPenColEnd   equ 96

;-----------------------------------------------------------------------------

; Function: Set all dirty flags to dirty initially so that they are rendered.
initDisplay:
    ld a, $FF
    ld (iy + dirtyFlags), a ; set all dirty flags
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

    ; Reset all dirty flags
    xor a
    ld (iy + dirtyFlags), a
    ret

;-----------------------------------------------------------------------------
; Routines for displaying the status bar at the top.
;-----------------------------------------------------------------------------

; Function: Display the status bar, showing menu up/down arrows.
; Input: none
; Output: status line displayed
; Destroys: A, B, C, HL
displayStatus:
    call displayStatusArrow
    call displayStatusFloatMode
    call displayStatusTrig
    call displayStatusBase
    ret

; Description: Display the up and down arrows that indicate whether there are
; additional menus above or below the current set of 5 menu buttons.
displayStatusArrow:
    bit dirtyFlagsMenu, (iy + dirtyFlags)
    ret z

    ; TODO: maybe cache the numRows of the current node to make this
    ; calculation a little shorter and easier.

    ; Determine if multiple menu rows exist.
    ld hl, menuGroupId
    ld a, (hl) ; A=menuGroupId
    inc hl
    ld b, (hl) ; B=menuRowIndex
    call getMenuNode ; HL = pointer to MenuNode
    inc hl
    ld d, (hl) ; D = parentId
    inc hl
    inc hl
    ld c, (hl) ; C=numRows

    ld hl, statusPenRow*$100 + statusMenuPenCol; $(penRow)(penCol)
    ld (PenCol), hl

    ; If numRows==0: don't do anything. This should never happen if there
    ; are no bugs in the program.
    ld a, c ; A = numRows
    or a
    jr z, displayStatusArrowClear

displayStatusArrowLeft:
    ld a, d
    or a ; if parentId==0: ZF=1
    jr z, displayStatusArrowLeftNone
    ; display left arrow
    ld a, Sleft
    jr displayStatusArrowLeftDisplay
displayStatusArrowLeftNone:
    ld a, SFourSpaces
displayStatusArrowLeftDisplay:
    bcall(_VPutMap)

displayStatusArrowDown:
    ; If rowIndex < (numRows - 1): show Down arrow
    ld a, b ; A = rowIndex
    dec c ; C = numRows - 1
    cp c
    jr nc, displayStatusArrowDownNone
    ld a, SdownArrow
    bcall(_VPutMap)
    ; Add an extra space after the downArrow because when an upArrow is
    ; displayed immediately after, the 1px of space on the right side of the
    ; downArrow character seems to ellided so the downArrow occupies only 3px.
    ld a, Sspace
    jr displayStatusArrowDownDisplay
displayStatusArrowDownNone:
    ld a, SFourSpaces
displayStatusArrowDownDisplay:
    bcall(_VPutMap)

displayStatusArrowUp:
    ; If rowIndex > 0: show Up arrow
    ld a, b
    or a
    jr z, displayStatusArrowUpNone
    ld a, SupArrow
    jr displayStatusArrowUpDisplay
displayStatusArrowUpNone:
    ld a, SFourSpaces
displayStatusArrowUpDisplay:
    bcall(_VPutMap)
    ret

    ; clear 8 px
displayStatusArrowClear:
    call displayStatusArrowUpNone
    jr displayStatusArrowUpNone

;-----------------------------------------------------------------------------

; Description: Display the Degree or Radian trig mode.
displayStatusTrig:
    bit dirtyFlagsTrigMode, (iy + dirtyFlags)
    ret z
displayStatusTrigUpdate:
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
    bit dirtyFlagsBaseMode, (iy + dirtyFlags)
    ret z
displayStatusBaseUpdate:
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

; Description: Display the floating point format: FIX, SCI, ENG
; Destroys: A, HL
displayStatusFloatMode:
    bit dirtyFlagsFloatMode, (iy + dirtyFlags)
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
; Input: errorCode
; Output:
;   - string corresponding to errorCode displayed
; Destroys: A, DE, HL
displayErrorCode:
    ; Check if the error code changed
    bit dirtyFlagsErrorCode, (iy + dirtyFlags)
    ret z ; return if no change

    ; Display nothing if errorCode == OK (0)
    ld hl, errorPenRow*$100 ; $(penRow)(penCol)
    ld (PenCol), hl
    ld a, (errorCode)
    or a
    jr z, displayErrorCodeEnd

    ; Print error string and its numerical code.
    call getErrorString
    push hl ; save HL = C-string
    call vPutS
    pop hl

    ; Append the numerical code only if the error message was errorStrUnknown.
    ; This helps debugging if an unknown error code is detected.
    ld de, errorStrUnknown
    bcall(_CpHLDE)
    jr nz, displayErrorCodeEnd

displayErrorCodeNumerical:
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
    call vPutS
    ;
    ld a, ')'
    bcall(_VPutMap)

displayErrorCodeEnd:
    call vEraseEOL
    res dirtyFlagsErrorCode, (iy + dirtyFlags)
    ret

;-----------------------------------------------------------------------------
; Routines for displaying the RPN stack variables.
;-----------------------------------------------------------------------------

; Function: Display the RPN stack variables
; Input: none
; Output: (dirtyFlagsMenu) reset
; Destroys: A, HL
displayStack:
    ; display YZT if stack is dirty
    bit dirtyFlagsStack, (iy + dirtyFlags)
    call nz, displayStackYZT

    ; display X if stack or inputBuf are dirty
    bit dirtyFlagsStack, (iy + dirtyFlags)
    jr nz, displayStackContinue
    bit dirtyFlagsInput, (iy + dirtyFlags)
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
    call vPutS

    ; print T value
    ld hl, stTCurCol*$100 + stTCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    call rclT
    call printOP1

    ; print Z label
    ld hl, stZPenRow*$100 ; $(penRow)(penCol)
    ld (PenCol), hl
    ld hl, msgZLabel
    call vPutS

    ; print Z value
    ld hl, stZCurCol*$100 + stZCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    call rclZ
    call printOP1

    ; print Y label
    ld hl, stYPenRow*$100 ; $(penRow)(penCol)
    ld (PenCol), hl
    ld hl, msgYLabel
    call vPutS

    ; print Y value
    ld hl, stYCurCol*$100 + stYCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    call rclY
    call printOP1

    ret

;-----------------------------------------------------------------------------

; Description: Render the X register line. There are 3 modes:
; 1) If rpnFlagsArgMode, print the argBuf for the ArgParser, else
; 2) If rpnFlagsEditing, print the current inputBuf, else
; 3) Print the X register.
displayStackX:
    bit rpnFlagsArgMode, (iy + rpnFlags)
    jr nz, displayStackXArg
    bit rpnFlagsEditing, (iy + rpnFlags)
    jr nz, displayStackXInput
    ; [[fallthrough]]

displayStackXNormal:
    call displayStackXLabel
    ; print the X register
    ld hl, stXCurCol*$100 + stXCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    call rclX
    jp printOP1

displayStackXInput:
    call displayStackXLabel
    ; print the inputBuf
    ld hl, inputCurCol*$100 + inputCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    jp printInputBuf

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
    call vPutS
    ret

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
; Input: (argBuf)
; Output: (CurCol) updated
displayStackXArg:
    ld hl, argCurCol*$100 + argCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    ; [[fallthrough]]

;-----------------------------------------------------------------------------

; Function: Print the arg buffer.
; Input:
;   - argBuf (same as inputBuf)
;   - argPrompt
;   - argModifier
;   - (CurCol) cursor position
; Output:
;   - (CurCol) is updated
; Destroys: A, HL; BC destroyed by PutPS()
printArgBuf:
    ; Print prompt and contents of argBuf
    ld hl, (argPrompt)
    call putS

    ; Print the argModifier if needed.
    ld a, (argModifier)
    cp argModifierCanceled
    jr nc, printArgBufNumber
    ld hl, argModifierStrings
    call getString
    call putS

printArgBufNumber:
    ; Print the command argument.
    ld hl, argBuf
    call putPS

    ; Append trailing cursor to fill 2 digits
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

; Function: Print the input buffer.
; Input:
;   - inputBuf
;   - (CurCol) cursor position
; Output:
;   - (CurCol) is updated
; Destroys: A, HL; BC destroyed by PutPS()
printInputBuf:
    ld hl, inputBuf
    call putPS
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
; Output: (dirtyFlagsMenu) reset
; Destroys: A, HL
displayMenu:
    bit dirtyFlagsMenu, (iy + dirtyFlags)
    ret z

    ; get starting menuId
    call getCurrentMenuRowBeginId ; A=rowBeginId
    ; set up loop over 5 consecutive menu buttons
    ld d, a ; D = menuId
    ld e, 0 ; E = menuIndex [0,4]
    ld c, menuPenCol0 ; C = penCol
    ld b, 5 ; B = loop 5 times
displayMenuLoop:
    ld a, d ; A = menuId
    call getMenuName ; HL = menu name of menuId in A

    ld a, c ; A = penCol
    call printMenuAtA

    inc d ; D = menuId + 1
    inc e ; E =  menuIndex + 1

    ld a, c ; A = penCol
    add a, menuPenWidth + 1 ; A += menuWidth + 1 (1px spacing)
    ld c, a ; C += menuPenWidth + 1

    djnz displayMenuLoop
    ret

;-----------------------------------------------------------------------------

; Description: Print the menu C-string in HL to the menuPenCol in A, using the
; small and inverted font, centering the menu name in the middle of the 18 px
; width of a menu box.
; Inputs:
;   A: penCol
;   B: loop counter (must be preserved)
;   C: penCol (must be preserved)
;   D: menuId (ignored but must be preserved, useful for debugging)
;   E: menuIndex [0-4] (ignored but must be preserved, useful for debugging)
;   HL: C string
; Destroys: A, HL
; Preserves: BC, DE
printMenuAtA:
    push bc ; B = loop counter
    push de ; D = menuId; E = menuIndex

    ; Set (PenCol,PenRow), preserving HL
    ld (PenCol), a
    ld a, menuPenRow
    ld (PenRow), a

    ; Predict the width of menu name.
    ld de, menuName
    ld c, menuNameBufMax
    call copyCToPascal ; C, DE are preserved
    ex de, hl ; HL = menuName
    call smallStringWidth ; A = B = string width

printMenuAtANoAdjust:
    ; Calculate the starting pixel to center the string
    ld a, menuPenWidth
    sub b ; A = menuPenWidth - stringWidth
    jr nc, printMenuAtAFitsInside
printMenuAtATooWide:
    xor a ; if string too wide (shouldn't happen), set to 0
printMenuAtAFitsInside:
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

    ld c, a ; C = A = leftPadWidth
    push bc ; B = stringWidth; C = leftPadWidth
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
printMenuAtALeftPad:
    ld b, a ; B = leftPadWidth
    ld a, Sspace
    call printARepeatB
printMenuAtAPrintName:
    ; Print the menu name
    ld hl, menuName
    call vPutPS
printMenuAtARightPad:
    pop bc ; B = stringWidth; C = leftPadWidth
    ld a, menuPenWidth
    sub c ; A = menuPenWidth - leftPadWidth
    sub b ; A = rightPadWidth = menuPenWidth - leftPadWidth - stringWidth
    jr z, printMenuAtAExit ; no space left
    jr c, printMenuAtAExit ; overflowed, shouldn't happen but be safe
    ; actually print the right pad
    ld b, a ; B = rightPadWidth
    ld a, Sspace
    call printARepeatB

printMenuAtAExit:
    res textInverse, (iy + textFlags)
    res textEraseBelow, (iy + textFlags)
    pop de ; D = menuId; E = menuIndex
    pop bc ; B = loop counter
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
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    jr z, printOP1AsFloat
    ld a, (baseNumber)
    cp 16
    jp z, printOP1Base16
    cp 8
    jp z, printOP1Base8
    cp 2
    jp z, printOP1Base2
    jp printOP1Base10

;-----------------------------------------------------------------------------

; Function: Print floating point number at OP1 using base 10.
; Input: OP1: floating point number
; Destroys: A, HL, OP3
printOP1AsFloat:
    ld a, 15 ; width of output
    bcall(_FormReal)
    ld hl, OP3
    ; [[fallthrough]]

; Description: Print the C-string referenced by HL, and erase to the end of
; line, taking care that the cursor did not move to the next line
; automatically.
; Input: HL: pointer to C-string
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

; Function: Print integer at OP1 at the current cursor in base 10. Erase to
; the end of line (but only if the digits did not spill over to the next line).
; Input: OP1
; Destroys: all, OP1, OP2, OP3, OP4
printOP1Base10:
    ld hl, OP3
    call convertOP1ToW32
    call checkW32FitsWsize
    ld a, (hl)
    bit w32StatusCodeTooBig, a
    jr nz, printOP1BaseInvalid
    bit w32StatusCodeNegative, a
    jr nz, printOP1BaseNegative
    ; Convert u32 into a base-10 string.
    inc hl ; W32+1
    ld de, OP4
    call convertU32ToDecString
printOP1BaseXX:
    ; Add '.' if OP1 has fractional component.
    dec hl
    call appendHasFrac
    jr printHLString

; Description: Append a '.' at the end of the string if W32.hasFrac is set.
; Input:
;   - HL: pointer to W32 struct
;   - DE: pointer to ascii string
; Output:
;   - HL: pointer to ascii string with '.' appended if w32.hasFrac is enabled
;   - DE: pointer to W32 struct
; Destroys: A
appendHasFrac:
    bit w32StatusCodeHasFrac, (hl)
    ex de, hl
    ret z
    ld a, '.'
    jp appendCString

;-----------------------------------------------------------------------------

; Function: Print ingeger at OP1 at the current cursor in base 16. Erase to
; the end of line (but only if the digits did not spill over to the next line).
; TODO: I think printOP1Base16(), printOP1Base8(), and printOP1Base2() can be
; combined into a single subroutine, saving memory.
; Input: OP1
; Destroys: all, OP1, OP2, OP3, OP4
printOP1Base16:
    ld hl, OP3
    call convertOP1ToW32
    call checkW32FitsWsize
    ld a, (hl)
    bit w32StatusCodeTooBig, a
    jr nz, printOP1BaseInvalid
    bit w32StatusCodeNegative, a
    jr nz, printOP1BaseNegative
    ; Convert u32 into a base-16 string.
    inc hl ; W32+1
    ld de, OP4
    call convertU32ToHexString ; DE=rendered string
    ; Append frac indicator
    dec hl
    call appendHasFrac ; HL=rendered string
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

; Function: Print ingeger at OP1 at the current cursor in base 8. Erase to
; the end of line (but only if the digits did not spill over to the next line).
; Input: OP1
; Destroys: all, OP1, OP2, OP3, OP4, OP5
printOP1Base8:
    ld hl, OP3
    call convertOP1ToW32
    call checkW32FitsWsize
    ld a, (hl)
    bit w32StatusCodeTooBig, a
    jr nz, printOP1BaseInvalid
    bit w32StatusCodeNegative, a
    jr nz, printOP1BaseNegative
    ; Convert u32 into a base-8 string.
    inc hl ; W32+1
    ld de, OP4
    call convertU32ToOctString
    ; Append frac indicator
    dec hl
    call appendHasFrac ; HL=rendered string
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

; Description: Print ingeger at OP1 at the current cursor in base 2. Erase to
; the end of line (but only if the floating point did not spill over to the
; next line). A single line can display a maximum of 15 digits, but we need
; space for a trailing ".", so the maximum number of binary digits is 14, which
; means that we can display numbers which are < 2^14.
; Input: OP1: non-negative floating point number < 2^14
; Destroys: all, OP1, OP2, OP3, OP4, OP5
printOP1Base2:
    ld hl, OP3
    call convertOP1ToW32
    call checkW32FitsWsize
    ld a, (hl)
    bit w32StatusCodeTooBig, a
    jp nz, printOP1BaseInvalid
    bit w32StatusCodeNegative, a
    jp nz, printOP1BaseNegative
    ; Convert u32 into a base-2 string.
    inc hl ; W32+1
    ld de, OP4
    call convertU32ToBinString
    ; Append frac indicator
    dec hl
    call appendHasFrac ; HL=rendered string
    call truncateBinDigits
    jp printHLString

; Description: Truncate upper digits depending on baseWordSize. The number of
; digits to truncate is (32 - baseWordSize).
; Input: HL: pointer to rendered string
; Output:
;   HL: pointer to truncated string
; Destroys: A, BC
truncateBinDigits:
    ld a, (baseWordSize)
    cp 15 ; cap the number of display digits to <= 14
    jr c, truncateBinDigitsContinue
    ld a, 14
truncateBinDigitsContinue:
    sub 32
    neg ; A=24,16,8,0
    ; Check leading digits to determine if truncation causes overflow
    ld b, a
    ld c, 0
truncateBinDigitsCheckOverflow:
    ld a, (hl)
    sub '0'
    or c ; check for a '1' digit
    ld c, a
    inc hl
    djnz truncateBinDigitsCheckOverflow
    ; HL now points to the left most digit of the truncated string.
    ret z ; C=0, indicating no overflow
    ; Replace left most digit with ellipsis symbol to indicate overflow.
    ld a, Lellipsis
    ld (hl), a
truncateBinDigitsNoOverflow:
    ret

;-----------------------------------------------------------------------------

; Function: Convert A to a NUL-terminated C-string of 1 to 3 digits at the
; buffer pointed by HL. This is intended for debugging, so it is not optimized.
; TODO: This can probably be written to be faster and smaller.
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

; Function: Return A / B using repeated substraction.
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
