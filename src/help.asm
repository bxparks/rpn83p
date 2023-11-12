;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Help strings and handlers. These are placed in flash Page 1 because we
; overflowed Page 0. 
;
; Capitalized labels are intended to be exported to the branch table on flash
; page 0. Lowercased labels are intended to be local to the current flash page.
;-----------------------------------------------------------------------------

; Description: A read loop dedicated to the help screens.
ProcessHelp:
    ld b, 0 ; B = pageNumber
processHelpLoop:
    ld a, b ; A = pageNumber
    call displayHelpPage
processHelpGetKey:
    ; The SDK docs say that GetKey() destroys only A, DE, HL. But it looks like
    ; BC also gets destroyed if 2ND QUIT is pressed.
    push bc
    bcall(_GetKey) ; pause for key
    pop bc
    res onInterrupt, (IY+onFlags) ; reset flag set by ON button

    ; Handle HELP keys
    or a ; A == ON
    jr z, processHelpExit
    cp kClear ; A == CLEAR
    jr z, processHelpExit
    cp kMath ; A == MATH
    jr z, processHelpExit
    cp kLeft ; A == LEFT
    jr z, processHelpPrevPageMaybe
    cp kUp ; A == UP
    jr z, processHelpPrevPageMaybe
    cp kQuit ; 2ND QUIT
    jr z, processHelpQuitApp
    jr processHelpNextPage ; everything else to the next page

processHelpPrevPageMaybe:
    ; go to prev page if not already at page 0
    ld a, b
    or a
    jr z, processHelpGetKey
mHelpHandlerPrevPage:
    dec b
    jr processHelpLoop

processHelpNextPage:
    ; any other key goes to the next the page
    inc b
    ld a, b
    cp helpPageCount
    jr nz, processHelpLoop

processHelpExit:
    ld a, errorCodeClearScreen
    ld (handlerCode), a ; cannot call setHandlerCode() on Page 0
    ret

processHelpQuitApp:
    ld a, errorCodeQuitApp
    ld (handlerCode), a ; cannot call setHandlerCode() on Page 0
    ret

;-----------------------------------------------------------------------------

; Description: Get the string pointer at index A given an array of pointers at
; base pointer HL. Out-of-bounds is NOT checked. NOTE: This is a duplicate of
; getString(), copied here so that routines in flash Page 1 can call this.
;
; Input:
;   A: index
;   HL: pointer to an array of pointers
; Output: HL: pointer to a string
; Destroys: DE, HL
; Preserves: A
getStringOnPage1:
    ld e, a
    ld d, 0
    add hl, de ; HL += A * 2
    add hl, de
    ld e, (hl)
    inc hl
    ld d, (hl)
    ex de, hl
    ret

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
; Input: HL: pointer to string using small font
; Ouptut:
;    - unlike VPutS(), the CF does *not* show if all of string was rendered
; Destroys: all
escapeLargeFont equ $FE ; pseudo-char to switch to large font
escapeSmallFont equ $FF ; pseudo-char to switch to small font
eVPutS:
    ; assume using small font
    ld c, smallFontHeight ; C = current font height
    res fracDrawLFont, (IY + fontFlags) ; start with small font
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
    set fracDrawLFont, (IY + fontFlags) ; use large font
    jr eVPutSLoop
eVPutSSmallFont:
    ld c, smallFontHeight
    res fracDrawLFont, (IY + fontFlags) ; use small font
    jr eVPutSLoop
eVPutSEnter:
    ; move to the next line
    push af
    push hl
    ld hl, PenCol
    xor a
    ld (hl), a ; PenCol = 0
    inc hl ; PenRow
    ld a, (hl) ; A = PenRow
    add a, c ; A += C (font height)
    ld (hl), a ; PenRow += 7
    pop hl
    pop af
    jr eVPutSLoop

;-----------------------------------------------------------------------------

; Description: Display the help page given by pageNumber in A.
; Input: A: pageNumber
; Destroys: none
displayHelpPage:
    push af
    push bc
    push de
    push hl

    bcall(_ClrLCDFull)
    ld hl, 0
    ld (PenCol), hl

    ; Get the string for page A, and display it.
    ld hl, helpPages ; HL = (char**)
    call getStringOnPage1
    call eVPutS

    pop hl
    pop de
    pop bc
    pop af
    ret

; Array of (char*) pointers to C-strings.
helpPageCount equ 8
helpPages:
    .dw msgHelpPage1
    .dw msgHelpPage2
    .dw msgHelpPage3
    .dw msgHelpPage4
    .dw msgHelpPage5
    .dw msgHelpPage6
    .dw msgHelpPage7
    .dw msgHelpPage8

msgHelpPage1:
    .db escapeLargeFont, "RPN83P", Lenter
    .db escapeSmallFont, "v0.7.0-dev (2023", Shyphen, "11", Shyphen, "12)", Senter
    .db "(c) 2023  Brian T. Park", Senter
    .db Senter
    .db "An RPN calculator for the", Senter
    .db "TI", Shyphen, "83 Plus and TI", Shyphen, "84 Plus", Senter
    .db "inspired by the HP", Shyphen, "42S.", Senter
    .db Senter
    .db SlBrack, "1/8", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage2:
    .db escapeLargeFont, "Stack Ops", Lenter
    .db escapeSmallFont, Senter
    .db "R", SdownArrow, " :  (", Senter
    .db "X", Sleft, Sconvert, "Y", ":  )", Senter
    .db "LastX", ":  2ND  ANS", Senter
    .db "R", SupArrow, " :  STK  R", SupArrow, Senter
    .db Senter
    .db Senter
    .db SlBrack, "2/8", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage3:
    .db escapeLargeFont, "Register Ops", Lenter
    .db escapeSmallFont, Senter
    .db "STO nn", Senter
    .db "STO+ STO- STO* STO/ nn", Senter
    .db "RCL nn", Senter
    .db "RCL+ RCL- RCL* RCL/ nn", Senter
    .db "nn: 0 to 24", Senter
    .db Senter
    .db SlBrack, "3/8", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage4:
    .db escapeLargeFont, "Input Editing", Lenter
    .db escapeSmallFont, Senter
    .db "EE:  2ND EE or ,", Senter
    .db "+/-:  (-)", Senter
    .db "<-:  DEL", Senter
    .db "ClrX:  CLEAR", Senter
    .db Senter
    .db Senter
    .db SlBrack, "4/8", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage5:
    .db escapeLargeFont, "Menu Navigation", Lenter
    .db escapeSmallFont, Senter
    .db "Home:  MATH", Senter
    .db "Prev Row:  UP", Senter
    .db "Next Row:  DOWN", Senter
    .db "Back:  ON", Senter
    .db "Quit App:  2ND QUIT", Senter
    .db Senter
    .db SlBrack, "5/8", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage6:
    .db escapeLargeFont, "CFIT Models", Lenter
    .db escapeSmallFont, Senter
    .db "LINF: y = B + M x", Senter
    .db "LOGF: y = B + M lnx", Senter
    .db "EXPF: y = B e^(M x)", Senter
    .db "PWRF: y = B x^M", Senter
    .db Senter
    .db Senter
    .db SlBrack, "6/8", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage7:
    .db escapeLargeFont, "BASE Ops", Lenter
    .db escapeSmallFont, Senter
    .db "SL SR: shift logical", Senter
    .db "ASR: arithmetic shift right", Senter
    .db "RL RR: rotate circular",  Senter
    .db "RLC RRC: rotate thru carry",  Senter
    .db "REVB: reverse bits", Senter
    .db "CNTB: count bits", Senter
    .db SlBrack, "7/8", SrBrack, " Any key to return.", Senter
    .db 0

msgHelpPage8:
    .db escapeLargeFont, "TVM", Lenter
    .db escapeSmallFont, Senter
    .db "outflow: - sign", Senter
    .db "inflow: + sign", Senter
    .db "RSTV: Reset P/YR BEG END",  Senter
    .db "CLTV: Clear N ... FV",  Senter
    .db "P/YR: Payments per year", Senter
    .db Senter
    .db SlBrack, "8/8", SrBrack, " Any key to return.", Senter
    .db 0
