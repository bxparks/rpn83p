;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Key/button scanner for HELP commands.
;
; Capitalized labels are intended to be exported to the branch table on flash
; page 0. Lowercased labels are intended to be local to the current flash page.
;-----------------------------------------------------------------------------

; Description: A key/button scanner loop to process Help commands.
ProcessHelpCommands:
    ld b, 0 ; B = current pageNumber
processHelpCommandsLoop:
    ld a, b ; A = pageNumber
    call displayHelpPage
processHelpCommandsGetKey:
    ; The SDK docs say that GetKey() destroys only A, DE, HL. But it looks like
    ; BC also gets destroyed if 2ND QUIT is pressed.
    push bc
    bcall(_GetKey) ; pause for key
    pop bc
    res onInterrupt, (iy + onFlags) ; reset flag set by ON button

    ; Handle HELP keys
    or a ; A == ON
    jr z, processHelpCommandsExit
    cp kClear ; A == CLEAR
    jr z, processHelpCommandsExit
    cp kDel ; A == CLEAR
    jr z, processHelpCommandsExit
    cp kMath ; A == MATH
    jr z, processHelpCommandsExit
    cp kLeft ; A == LEFT
    jr z, processHelpCommandsPrevPageWithWrap
    cp kUp ; A == UP
    jr z, processHelpCommandsPrevPageWithWrap
    cp kRight ; A == RIGHT
    jr z, processHelpCommandsNextPageWithWrap
    cp kDown ; A == DOWN
    jr z, processHelpCommandsNextPageWithWrap
    cp kQuit ; 2ND QUIT
    jr z, processHelpCommandsQuitApp
    jr processHelpCommandsNextPage ; everything else to the next page

processHelpCommandsPrevPageWithWrap:
    ; go to prev page with wrap around
    ld a, b
    sub 1
    ld b, a
    jr nc, processHelpCommandsLoop
    ; wrap around to the last page
    ld b, helpPageCount-1
    jr processHelpCommandsLoop

processHelpCommandsNextPageWithWrap:
    ; go to the next page with wrap around
    inc b
    ld a, b
    cp helpPageCount
    jr nz, processHelpCommandsLoop
    ld b, 0 ; wrap to the beginning
    jr processHelpCommandsLoop

processHelpCommandsNextPage:
    ; Any other key goes to the next the page, with no wrapping.
    inc b
    ld a, b
    cp helpPageCount
    jr nz, processHelpCommandsLoop

processHelpCommandsExit:
    ld a, errorCodeClearScreen
    ld (handlerCode), a
    ret

processHelpCommandsQuitApp:
    ld a, errorCodeQuitApp
    ld (handlerCode), a
    ret

;-----------------------------------------------------------------------------

; Description: Display the help page given by pageNumber in A.
; Input: A: pageNumber
; Destroys: none
displayHelpPage:
    ; Disable blinking cursor
    res curAble, (iy + curFlags)
    res curOn, (iy + curFlags)

    push af
    push bc
    push de
    push hl

    bcall(_ClrLCDFull)
    ld hl, 0
    ld (penCol), hl

    ; Get the string for page A, and display it.
    ld hl, helpPages ; HL = (char**)
    call getStringPageOne
    call eVPutS

    pop hl
    pop de
    pop bc
    pop af
    ret
