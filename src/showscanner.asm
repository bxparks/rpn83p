;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; The interactive key/button scanner for the SHOW mode. Currently, almost all
; keys go back to the normal mode. The exceptions are: QUIT and OFF. This file
; needs to be in Flash Page 0 due to mainExit().
;------------------------------------------------------------------------------

; Description: Read loop for the SHOW mode. Any keyCode will exit the SHOW
; mode. There are a few subtle difference in the subsequent behavior of key
; codes as follows:
;
;   1) Most keyCodes will be passed on back to the main command processor
;   (processMainCommands()) for normal processing. For example, if one of the
;   digits (0-9) is pressed in SHOW mode, the digit will be pushed on to the
;   stack and the calculator will enter "input" mode.

;   2) Four keys cause the SHOW mode to exit, but they are *not* reprocessed by
;   the main command processor: DEL, CLEAR, ENTER, ON/EXIT. The only purpose of
;   these keys is to exit the SHOW mode.

;   3) 2ND QUIT causes the RPN83P application to exit. The application does not
;   save the SHOW mode state to avoid confusion upon restart. It will always
;   start in normal mode.
processShowCommands:
    bcall(_ClearShowArea)
    set rpnFlagsShowModeEnabled, (iy + rpnFlags)
    set dirtyFlagsStack, (iy + dirtyFlags)
    ; Show the new display.
    call displayAll
    ; Pause and wait for user input
    bcall(_GetRpnKeyCode)
    ; Quit the app on QUIT.
    cp kQuit
    jp z, mainExit
    ; Consume DEL, CLEAR, ENTER, ON/EXIT in this handler and exit SHOW.
    cp kDel
    jr z, clearShow
    cp kClear
    jr z, clearShow
    cp kEnter
    jr z, clearShow
    cp kOnExit
    jr z, clearShow
    ; Push back all other keyCodes into the buffer for reprocessing by
    ; processMainCommands().
    bcall(_PushRpnKeyCode)
    ; [[fallthrough]]
clearShow:
    ; Exit the SHOW mode, then return.
    bcall(_ClearShowArea)
    res rpnFlagsShowModeEnabled, (iy + rpnFlags)
    set dirtyFlagsStack, (iy + dirtyFlags)
    set dirtyFlagsErrorCode, (iy + dirtyFlags) ; errorCode displays "SHOW"
    ret
