;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Process the SHOW mode. Currently, almost all keys go back to the normal mode.
; The exceptions are: QUIT and OFF. This file needs to be in Flash Page 0.
;------------------------------------------------------------------------------

; Description: Read loop for the SHOW mode.
processCommandShow:
    call clearShowArea
    ld a, (drawMode)
    push af ; stack=[drawMode]
    ld a, drawModeShow
    ld (drawMode), a
    set dirtyFlagsStack, (iy + dirtyFlags)
    ; Show the new display.
    call displayAll
    ; Pause and wait for use rinput
    bcall(_GetKey)
    res onInterrupt, (iy + onFlags)
    ; Quit the app on QUIT.
    cp a, KQuit
    jp z, mainExit
    ; Anything exits the SHOW mode.
    call clearShowArea
    pop af ; stack=[]; A=drawMode
    ld (drawMode), a
    set dirtyFlagsStack, (iy + dirtyFlags)
    set dirtyFlagsErrorCode, (iy + dirtyFlags) ; errorCode displays "SHOW"
    ret
