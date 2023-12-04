;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; The main interactive keyboard reader and parser.
;------------------------------------------------------------------------------

; The main interactive keyboard read loop. Read button and dispatch to the
; appropriate handler. See 83pa28d/week2/day12 for the basics.
processMainCommands:
    ; call debugFlags
    call displayAll

    ; Set the handler code initially to 0.
    xor a
    ld (handlerCode), a

    ; Get the key code, and reset the ON flag right after. See TI-83 Plus SDK
    ; guide, p. 69. If this flag is not reset, then the next bcall(_DispHL)
    ; causes subsequent bcall(_GetKey) to always return 0. Interestingly, if
    ; the flag is not reset, but the next call is another bcall(_GetKey), then
    ; it sort of seems to work. Except that upon exiting, the TI-OS displays an
    ; Quit/Goto error message.
    bcall(_GetKey)
    res onInterrupt, (iy + onFlags)

    ; Install error handler
    ld hl, cleanupHandlerException
    call APP_PUSH_ERRORH
    ; Dispatch to the handler for the given button, either the normal buttons
    ; or the menu F1-F5 buttons.
    ld hl, keyCodeHandlerTable
    ld b, keyCodeHandlerTableSize
    call dispatchHandler
    ; Uninstall error handler
    call APP_POP_ERRORH

    ; Transfer the handler code to errorCode.
    ld a, (handlerCode)
    ; Check for errorCodeQuitApp
    cp errorCodeQuitApp
    jr z, cleanupHandlerQuitApp
    ; Check for errorCodeClearScreen
    cp errorCodeClearScreen
    jr z, cleanupHandlerClearScreen
    ; [[fallthrough]]

cleanupHandlerSetErrorCode:
    ; transfer the handlerCode in A to displayable errorCode.
    bcall(_SetErrorCode)
    jr processMainCommands

; Handle system exception. A contains the system error code.
cleanupHandlerException:
    ; The exception may have been thrown inside a routine that enabled the run
    ; indicator (e.g. TVM Solver when calculating I%YR). Disable the indicator
    ; just in case.
    push af
    bcall(_RunIndicOff) ; destroys A (contrary to SDK docs)
    pop af
    ; Convert system code to handler code
    bcall(_SetHandlerCodeToSystemCode)
    jr cleanupHandlerSetErrorCode

cleanupHandlerClearScreen:
    ; force rerendering of normal calculator display
    bcall(_ClrLCDFull)
    ld a, $FF
    ld (iy + dirtyFlags), a ; set all dirty flags
    ld a, errorCodeOk
    jr cleanupHandlerSetErrorCode

cleanupHandlerQuitApp:
    ld a, errorCodeOk
    bcall(_SetErrorCode)
    jp mainExit

;-----------------------------------------------------------------------------

; Description: Handle the keyCode given by A. If keyCode is not in the handler
; table, do nothing.
; Input:
;   - A: keyCode from GetKey()
;   - HL: pointer to handler table
;   - B: number of entries in the handler table
; Output: none
; Destroys: A, B, DE, HL (and any other registers destroyed by the handler)
dispatchHandler:
    cp a, (hl)
    inc hl
    jr z, dispatchHandlerMatched
    inc hl
    inc hl
    djnz dispatchHandler
    ret
dispatchHandlerMatched:
    ; jump to the corresponding jump table entry
    ld e, (hl)
    inc hl
    ld d, (hl)
    jp jumpDE
