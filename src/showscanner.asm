;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; The interactive key/button scanner for the SHOW mode. Currently, almost all
; keys go back to the normal mode. The exceptions are: QUIT and OFF. This file
; needs to be in Flash Page 0.
;------------------------------------------------------------------------------

; Description: Read loop for the SHOW mode.
processShowCommands:
    call clearShowArea
    set rpnFlagsShowModeEnabled, (iy + rpnFlags)
    set dirtyFlagsStack, (iy + dirtyFlags)
    ; Show the new display.
    call displayAll
    ; Pause and wait for use rinput
    bcall(_GetKey)
    res onInterrupt, (iy + onFlags)
    ; Quit the app on QUIT.
    cp a, kQuit
    jp z, mainExit
    ; Anything else exits the SHOW mode.
    call clearShowArea
    res rpnFlagsShowModeEnabled, (iy + rpnFlags)
    set dirtyFlagsStack, (iy + dirtyFlags)
    set dirtyFlagsErrorCode, (iy + dirtyFlags) ; errorCode displays "SHOW"
    ret
