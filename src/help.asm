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
    ld b, 0 ; B = current pageNumber
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
    cp kDel ; A == CLEAR
    jr z, processHelpExit
    cp kMath ; A == MATH
    jr z, processHelpExit
    cp kLeft ; A == LEFT
    jr z, processHelpPrevPageWithWrap
    cp kUp ; A == UP
    jr z, processHelpPrevPageWithWrap
    cp kRight ; A == RIGHT
    jr z, processHelpNextPageWithWrap
    cp kDown ; A == DOWN
    jr z, processHelpNextPageWithWrap
    cp kQuit ; 2ND QUIT
    jr z, processHelpQuitApp
    jr processHelpNextPage ; everything else to the next page

processHelpPrevPageWithWrap:
    ; go to prev page with wrap around
    ld a, b
    sub 1
    ld b, a
    jr nc, processHelpLoop
    ; wrap around to the last page
    ld b, helpPageCount-1
    jr processHelpLoop

processHelpNextPageWithWrap:
    ; go to the next page with wrap around
    inc b
    ld a, b
    cp helpPageCount
    jr nz, processHelpLoop
    ld b, 0 ; wrap to the beginning
    jr processHelpLoop

processHelpNextPage:
    ; Any other key goes to the next the page, with no wrapping.
    inc b
    ld a, b
    cp helpPageCount
    jr nz, processHelpLoop

processHelpExit:
    ld a, errorCodeClearScreen
    ld (handlerCode), a
    ret

processHelpQuitApp:
    ld a, errorCodeQuitApp
    ld (handlerCode), a
    ret

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
    call getStringFP1
    call eVPutS

    pop hl
    pop de
    pop bc
    pop af
    ret

;-----------------------------------------------------------------------------

; Array of (char*) pointers to C-strings.
helpPageCount equ 13
helpPages:
    .dw msgHelpPage1
    .dw msgHelpPage2
    .dw msgHelpPage3
    .dw msgHelpPage4
    .dw msgHelpPage5
    .dw msgHelpPage6
    .dw msgHelpPage7
    .dw msgHelpPage8
    .dw msgHelpPage9
    .dw msgHelpPage10
    .dw msgHelpPage11
    .dw msgHelpPage12
    .dw msgHelpPage13

msgHelpPage1:
    .db escapeLargeFont, "RPN83P", Lenter
    .db escapeSmallFont, "v0.9.0-dev (2023", Shyphen, "12", Shyphen, "06)", Senter
    .db "(c) 2023  Brian T. Park", Senter
    .db Senter
    .db "An RPN calculator for the", Senter
    .db "TI", Shyphen, "83 Plus and TI", Shyphen, "84 Plus", Senter
    .db "inspired by the HP", Shyphen, "42S.", Senter
    .db Senter
    .db SlBrack, "1/13", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage2:
    .db escapeLargeFont, "Menu Navigation", Lenter
    .db escapeSmallFont, "Home:  MATH", Senter
    .db "Prev Row:  UP", Senter
    .db "Next Row:  DOWN", Senter
    .db "Back:  ON", Senter
    .db Senter
    .db "Quit:  2ND QUIT", Senter
    .db "Off:  2ND OFF", Senter
    .db SlBrack, "2/13", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage3:
    .db escapeLargeFont, "Input Editing", Lenter
    .db escapeSmallFont, "+/-:  (-)", Senter
    .db "EE:  2ND EE or ,", Senter
    .db "<-:  DEL", Senter
    .db "CLX:  CLEAR", Senter
    .db "CLST:  CLEAR CLEAR CLEAR", Senter
    .db Senter
    .db Senter
    .db SlBrack, "3/13", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage4:
    .db escapeLargeFont, "Stack Ops", Lenter
    .db escapeSmallFont, "R", SdownArrow, " :  (", Senter
    .db "X", Sleft, Sconvert, "Y", ":  )", Senter
    .db "LastX", ":  2ND  ANS", Senter
    .db "R", SupArrow, " :  STK  R", SupArrow, Senter
    .db Senter
    .db Senter
    .db Senter
    .db SlBrack, "4/13", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage5:
    .db escapeLargeFont, "Display Modes", Lenter
    .db escapeSmallFont, "FIX nn: Fixed", Senter
    .db "SCI nn: Scientific", Senter
    .db "ENG nn: Engineering", Senter
    .db SFourSpaces, "nn: 0..9: Num digits", Senter
    .db SFourSpaces, "nn: 11..99: Reset to floating", Senter
    .db "SHOW: 2ND ENTRY", Senter
    .db Senter
    .db SlBrack, "5/13", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage6:
    .db escapeLargeFont, "Register Ops", Lenter
    .db escapeSmallFont, "STO nn", Senter
    .db "STO+ STO- STO* STO/ nn", Senter
    .db "RCL nn", Senter
    .db "RCL+ RCL- RCL* RCL/ nn", Senter
    .db "nn: 0..24", Senter
    .db Senter
    .db Senter
    .db SlBrack, "6/13", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage7:
    .db escapeLargeFont, "NUM Functions", Lenter
    .db escapeSmallFont, "%: Y=Y; X=Y*X/100", Senter
    .db "%CH: Y=Y; X=100*(X-Y)/Y", Senter
    .db "PRIM: Prime factor of < 2^32", Senter
    .db Senter
    .db Senter
    .db Senter
    .db Senter
    .db SlBrack, "7/13", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage8:
    .db escapeLargeFont, "CONV Arguments", Lenter
    .db escapeSmallFont, Sconvert, "POL ", Sconvert, "REC:", Senter
    .db SFourSpaces, "Y: y or ", Stheta, Senter
    .db SFourSpaces, "X: x or r", Senter
    .db Sconvert, "HMS: hh.mmss", Senter
    .db "ATN2: same as ", Sconvert, "POL", Senter
    .db Senter
    .db Senter
    .db SlBrack, "8/13", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage9:
    .db escapeLargeFont, "STAT Functions", Lenter
    .db escapeSmallFont, "WMN: Weighted Mean", Senter
    .db SFourSpaces, "Y: ", ScapSigma, "XY/", ScapSigma, "X", Senter
    .db SFourSpaces, "X: ", ScapSigma, "XY/", ScapSigma, "Y", Senter
    .db "SDEV: Sample Std Deviation", Senter
    .db "SCOV: Sample Covariance", Senter
    .db "PDEV: Pop Std Deviation", Senter
    .db "PCOV: Pop Covariance", Senter
    .db SlBrack, "9/13", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage10:
    .db escapeLargeFont, "CFIT Models", Lenter
    .db escapeSmallFont, "LINF: y = B + M x", Senter
    .db "LOGF: y = B + M lnx", Senter
    .db "EXPF: y = B e^(M x)", Senter
    .db "PWRF: y = B x^M", Senter
    .db "BEST: Select best model", Senter
    .db Senter
    .db Senter
    .db SlBrack, "10/13", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage11:
    .db escapeLargeFont, "BASE Ops", Lenter
    .db escapeSmallFont, "SL,SR: Shift Logical", Senter
    .db "ASR: Arithmetic Shift Right", Senter
    .db "RL,RR: Rotate Circular",  Senter
    .db "RLC,RRC: Rotate thru Carry",  Senter
    .db "REVB: Reverse Bits", Senter
    .db "CNTB: Count Bits", Senter
    .db "WSIZ: 8, 16, 24, 32", Senter
    .db SlBrack, "11/13", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage12:
    .db escapeLargeFont, "TVM", Lenter
    .db escapeSmallFont, "Outflow: -", Senter
    .db "Inflow: +", Senter
    .db "P/YR: Payments per year", Senter
    .db "BEG: Payments at begin", Senter
    .db "END: Payments at end", Senter
    .db "CLTV: Clear TVM",  Senter
    .db Senter
    .db SlBrack, "12/13", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage13:
    .db escapeLargeFont, "TVM Solver", Lenter
    .db escapeSmallFont, "IYR1: I%YR guess 1",  Senter
    .db "IYR2: I%YR guess 2",  Senter
    .db "TMAX: Iteration max",  Senter
    .db "RSTV: Reset TVM Solver",  Senter
    .db Senter
    .db Senter
    .db Senter
    .db SlBrack, "13/13", SrBrack, " Any key to return.", Senter
    .db 0
