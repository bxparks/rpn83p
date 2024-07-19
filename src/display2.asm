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

; Description: Initialize display variables upon cold start.
ColdInitDisplay:
    ld hl, 00*256 + renderWindowSize ; H=start=0; L=end=renderWindowSize
    ld (renderWindowEnd), hl
    ret

; Description: Configure flags and variables related to rendering to a sane
; state.
InitDisplay:
    ; always set drawMode to drawModeNormal
    xor a
    ld (drawMode), a
    ; clear the displayFontMasks
    ld (displayStackFontFlags), a
    ; always disable SHOW mode
    res rpnFlagsShowModeEnabled, (iy + rpnFlags)
    ; set all dirty flags so that everything on the display is re-rendered
    ld a, $ff
    ld (iy + dirtyFlags), a
    ret

;-----------------------------------------------------------------------------
; Soft menu labels.
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
    ; Set (penCol,penRow), preserving HL
    ld a, c ; A=penCol
    ld (penCol), a
    ld a, menuPenRow
    ld (penRow), a
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

;-----------------------------------------------------------------------------
; Print the inputBuf[] along with the TIOS blinking cursor.
; TODO: PrintInputBuf() needs polishing for drawModeInputBuf.
;-----------------------------------------------------------------------------

; Description: Print the input buffer.
; Input:
;   - inputBuf
;   - (curRow) cursor row
;   - (curCol) cursor column
; Output:
;   - (curCol) updated
;   - (renderWindowStart) updated
;   - (renderWindowEnd) updated
;   - (cursorRenderPos) updated
; Destroys: A, BC, DE, HL, IX
PrintInputBuf:
    call renderInputBuf
    call updateRenderWindow
    call printRenderWindow
    call clearEndOfRenderLine
    call setInputCursor
    ret

; Description: Convert inputBuf[] into renderBuf[] suitable for rendering on
; the screen. An Ldegree character for complex polar degree mode is two
; characters (Langle, Ltemp).
;
; This is a translation of the render_input() function in
; ../misc/cursornav/cursornav.c.
;
; Input:
;   - inputBuf:(const char*)
; Output:
;   - renderBuf updated
;   - indexes updated
;   - HL=renderBuf
; Destroys: A, BC, DE, HL, IX
renderInputBuf: ; TODO: Move to display2.asm
    ld ix, renderIndexes
    ld de, renderBuf
    inc de ; skip past len byte
    ld hl, inputBuf
    ld c, 0 ; renderIndex=0
    ld b, (hl) ; B=len(inputBuf)
    inc hl ; skip past len byte
    ; check for len(inputBuf) == 0
    ld a, b
    or a
    jr z, renderInputBufExit
renderInputBufLoop:
    ld a, (hl)
    inc hl
    ld (ix), c ; add entry to renderIndexes[]
    inc ix ; renderIndexes
    cp Ldegree
    jr nz, renderInputBufCopy
    ; Expand Ldegree into (Langle, Ltemp).
    ld a, Langle
    ld (de), a
    inc de ; renderBuf
    inc c ; renderIndex+=1
    ld a, Ltemp
renderInputBufCopy:
    ld (de), a
    inc de ; renderBuf
    inc c ; renderIndex+=1
    djnz renderInputBufLoop
renderInputBufExit:
    ; extra trailing space for trailing cursor
    ld a, Lspace
    ld (de), a
    ld hl, renderBuf
    ld (hl), c ; len(renderBuf)=renderLen
    ld (ix), c ; indexes[inputLen]=renderLen
    ret

; Description: Update the renderWindow{Start,End} variables given the
; renderBuf[] and the cursorInputPos.
;
; This is a translation of the update_window() function in
; ../misc/cursornav/cursornav.c.
;
; Input:
;   - renderBuf:(const char*)
;   - cursorInputPos
;   - renderIndexes:(const u8*)
; Output:
;   - cursorRenderPos updated
;   - renderWindowStart updated
;   - renderWindowEnd updated
; Destroys: A, BC, HL
updateRenderWindow:
    call updateCursorRenderPos ; A=cursorRenderPos
    ld bc, (renderWindowEnd) ; B=start; C=end
    ; if cursorRenderPos>=renderBufLen: cursor is at end of renderBuf
    ld hl, renderBufLen
    cp (hl) ; CF=0 if cursorRenderPos>=renderBufLen
    jr nc, updateRenderWindowAppending
    ; else if cursorRenderPos<=start: cursor is on left side of renderBuf
    ; (same as `if cursorRenderPos<start+1`)
    inc b
    cp b ; CF=1 if above true
    dec b ; does not affect CF
    jr c, updateRenderWindowShiftLeft
    ; else if end-1<=cursorRenderPos: cursor is on right side of renderBuf
    ; (same as `if cursorRenderPos>=end-1`)
    dec c ; end-1
    cp c ; CF=0 if above true
    inc c
    jr nc, updateRenderWindowShiftRight
    ret ; do nothing by default
updateRenderWindowAppending:
    ld a, (hl) ; A=renderBufLen
    cp renderWindowSize ; CF=1 if renderBufLen < renderWindowSize
    jr nc, updateRenderWindowAppendingPegRight
    ; peg left
    ld b, 0
    ld c, renderWindowSize
    jr updateRenderWindowUpdate
updateRenderWindowAppendingPegRight:
    inc a
    ld c, a ; C=renderWindowEnd=renderBufLen+1
    sub renderWindowSize
    ld b, a ; B=renderWindowBegin=renderWindowEnd-renderWindowSize
    jr updateRenderWindowUpdate
updateRenderWindowShiftRight:
    cp (hl) ; ZF=1 if cursorRenderPos == renderBufLen
    jr z, updateRenderWindowShiftRightContinue
    inc a ; A++
updateRenderWindowShiftRightContinue:
    inc a ; A++
    ld c, a ; C=end
    sub renderWindowSize ; A=start
    ld b, a
    jr updateRenderWindowUpdate
    ;
updateRenderWindowShiftLeft:
    ld b, a ; renderWindowStart=cursorRenderPos
    or a
    jr z, updateRenderWindowShiftLeftContinue
    dec b ; renderWindowStart=cursorRenderPos-1
    ld a, b
updateRenderWindowShiftLeftContinue:
    add a, renderWindowSize
    ld c, a ; renderWindowEnd=renderWindowStart+renderWindowSize
    ;
updateRenderWindowUpdate:
    ld (renderWindowEnd), bc
    ret

; Description: Calculator the cursorRenderPos from cursorInputPos. This is one
; line of code in C: `uint8_t cursor_render_pos = index_map[cursor_input_pos]`.
; But in Z80 assembly, it's annoying enough that it's easier to create a
; subroutine for it.
; Input:
;   - cursorInputPos
; Output:
;   - cursorRenderPos updated
;   - A=cursorRenderPos
; Destroys: A, DE, HL
updateCursorRenderPos:
    ld hl, renderIndexes
    ld a, (cursorInputPos)
    ld e, a
    ld d, 0
    add hl, de ; HL=renderIndexes+cursorInputPos
    ld a, (hl) ; A=renderIndexes[cursorInputPos]
    ld (cursorRenderPos), a ; A=cursorRenderPos
    ret

#ifdef DEBUG
; Description: Print the entire renderBuf[] without the renderWindow mask. For
; debugging.
printRenderBuf:
    ld hl, renderBuf
    ld b, (hl)
    inc hl
    ld a, b
    or a
    ret z
printRenderBufLoop:
    ld a, (hl)
    inc hl
    bcall(_PutC)
    djnz printRenderBufLoop
    ret
#endif

; Description: Print the renderBuf within the renderWindowStart and
; renderWindowEnd. If the left part or right parts are truncated, print an
; ellipsis character to indicate truncation.
;
; This is a translation of the print_render_window() function in
; ../misc/cursornav/cursornav.c.
;
; Input: renderBuf
; Output: renderBuf truncated if necessary
; Destroys: all registers
printRenderWindow:
    ; numPrintableChar=min(renderBufLen-renderWindowStart, renderWindowSize)
    ld a, (renderWindowStart)
    ld b, a ; B=renderWindowStart
    ld hl, renderBuf
    ld a, (hl) ; A=renderBufLen
    inc hl ; skip past len byte
    sub b ; A=renderBufLen-renderWindowStart
    cp renderWindowSize ; CF=1 if renderBufLen<renderWindowSize
    jr c, printRenderWindowSetupLoop
    ld a, renderWindowSize
printRenderWindowSetupLoop:
    ; check for 0 len
    or a
    ret z
    ld b, a ; B=numPrintableChar
    ; setup pointer to renderBufBuf[renderWindowStart]
    ld a, (renderWindowStart)
    ld d, a ; D=windowIndex=start
    add a, l
    ld l, a
    ld a, h
    adc a, 0
    ld h, a ; HL=renderBuf+start
    ; loop from windowStart until windowEnd
    ld e, 0 ; E=screenPos=0
printRenderWindowLoop:
    ; check if screenPos==0 && windowIndex!=0
    ld a, d ; A=windowIndex
    or a
    jr z, printRenderWindowCheckRightEllipsis
    ld a, e ; A=E=screenPos
    or a
    jr z, printRenderWindowEllipsis
printRenderWindowCheckRightEllipsis:
    ; check if windowIndex!=renderBufLen-1 && screenPos==windowSize-1
    ld a, d ; A=windowIndex
    inc a
    cp c ; CF=0 if windowIndex+1>=renderBufLen
    jr c, printRenderWindowNormal
    ld a, e ; A=screenPos
    cp renderWindowSize-1
    jr nz, printRenderWindowNormal
printRenderWindowEllipsis:
    ld a, Lellipsis
    jr printRenderWindowPutC
printRenderWindowNormal:
    ld a, (hl)
printRenderWindowPutC:
    inc hl ; renderBuf++
    bcall(_PutC)
    inc e ; screenPos++
    inc d ; windowIndex++
    djnz printRenderWindowLoop
    ret

; Description: Clear to the end of line of the inputBuf render line.
; Skip EraseEOL() if the PutC() above wrapped to next line.
; Destroys: A
clearEndOfRenderLine:
    ld a, (curCol)
    or a
    ret z
    bcall(_EraseEOL)
    ret

; Description: Set the native TIOS cursor position to cursorScreenPos+1. The
; addition of `+1` is because the 'X:' label occupies one slot.
; Input:
;   - cursorRenderPos
; Output:
;   - cursorScreenPos updated
;   - curCol updated
;   - curRow updated
setInputCursor:
    ; update cursor screen logical position
    ld a, (renderWindowStart)
    ld b, a
    ld a, (cursorRenderPos)
    ld c, a ; C=cursorRenderPos
    sub b ; A=cursorScreenPos=cursorRenderPos-renderWindowStart
    ld (cursorScreenPos), a
    ; Update cursor physical column, skipping past any labels or prompts at the
    ; beginning of th line. Also update physical row, because the TI-OS cursor
    ; could have wrapped to the next row
    add a, inputCurCol
    ld (curCol), a
    ld a, inputCurRow
    ld (curRow), a
    ; update cursor-under character
    ld hl, renderBuf
    inc hl
    ld b, 0 ; BC=cursorRenderPos
    add hl, bc
    ld a, (hl) ; A=cursorUnder character
    ld (curUnder), a
    ret
