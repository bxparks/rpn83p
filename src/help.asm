;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Help strings and handlers.
;-----------------------------------------------------------------------------

; Description: A read loop dedicated to the help screens.
processHelp:
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
    jp z, mainExit
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
    ; force rerendering of normal calculator display
    bcall(_ClrLCDFull)
    ld a, $FF
    ld (iy + dirtyFlags), a ; set all dirty flags
    call initDisplay
    call initMenu
    ret

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
    call getString
    call vPutS

    pop hl
    pop de
    pop bc
    pop af
    ret

; Array of (char*) pointers to C-strings.
helpPageCount equ 7
helpPages:
    .dw msgHelpPage1
    .dw msgHelpPage2
    .dw msgHelpPage3
    .dw msgHelpPage4
    .dw msgHelpPage5
    .dw msgHelpPage6
    .dw msgHelpPage7

msgHelpPage1:
    .db escapeLargeFont, "RPN83P", Lenter
    .db escapeSmallFont, "v0.7.0-dev (2023", Shyphen, "10", Shyphen, "29)", Senter
    .db "(c) 2023  Brian T. Park", Senter
    .db Senter
    .db "An RPN calculator for the", Senter
    .db "TI", Shyphen, "83 Plus and TI", Shyphen, "84 Plus", Senter
    .db "inspired by the HP", Shyphen, "42S.", Senter
    .db Senter
    .db SlBrack, "1/7", SrBrack, " Any key to continue...", Senter
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
    .db SlBrack, "2/7", SrBrack, " Any key to continue...", Senter
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
    .db SlBrack, "3/7", SrBrack, " Any key to continue...", Senter
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
    .db SlBrack, "4/7", SrBrack, " Any key to continue...", Senter
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
    .db SlBrack, "5/7", SrBrack, " Any key to continue...", Senter
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
    .db SlBrack, "6/7", SrBrack, " Any key to continue...", Senter
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
    .db SlBrack, "7/7", SrBrack, " Any key to return.", Senter
    .db 0

