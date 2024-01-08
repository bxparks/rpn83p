;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Process and parse the command arguments that follows certain commands: STO,
; RCL, FIX, SCI, ENG.
;------------------------------------------------------------------------------

; Description: Configure the command arg parser and display before each
; invocation. Use InitArgBuf() to initialize at the start of application.
; Input:
;   - HL: pointer to command argument label
; Destroys: A
startArgParser:
    ld (argPrompt), hl
    xor a
    ld (argModifier), a
    ld (argBufLen), a
    res inputBufFlagsArgAllowModifier, (iy + inputBufFlags)
    res inputBufFlagsArgExit, (iy + inputBufFlags)
    res inputBufFlagsArgCancel, (iy + inputBufFlags)
    set rpnFlagsArgMode, (iy + rpnFlags)
    set dirtyFlagsInput, (iy + dirtyFlags)
    set dirtyFlagsXLabel, (iy + dirtyFlags)
    ret

; Description: Read loop which reads a 2-digit command argument, needed by
; commands such as 'FIX', 'SCI', 'ENG', 'STO', and 'RCL'. Only a subset of
; buttons are allowed:
; - digits: 0 to 9
; - CLEAR: exit from Command Arg mode and do nothing
; - ON (EXIT): same as CLEAR currently
; - DEL (Backspace): remove previous digit in the command argument
; - ENTER: parse the argument and return
; - *, /, -, +: Converts STO and RCL to STO+, RCL+, etc.
; - 2ND QUIT
; - 2ND OFF
;
; The calling routine should take the following steps:
;   1) call startArgParser()
;   2) any custom configurations (inputBufFlagsArgAllowModifier)
;   3) call processArgCommands()
;   4) check if ZF=0 (was canceled)
;   5) process the argument value in argValue
;
; Input:
;   - inputBufFlagsArgAllowModifier: set if +,-,*,/,. are allowed
; Output:
;   - (argBuf): contains characters typed in by user
;   - (argModifier): modifier enum if a modifier key (+ - * / .) was selected
;   - (argValue): parsed integer value of argBuf
;   - A=argModifier
;   - ZF=0: if arg input was canceled (ON/EXIT or CLEAR)
processArgCommands:
    call displayAll

    ; Get key code, and reset the ON flag.
    bcall(_GetKey)
    res onInterrupt, (iy + onFlags)

    ; Handle the button press.
    ld hl, argKeyCodeHandlerTable
    ld b, argKeyCodeTableSize
    call dispatchHandler

    ; Check for terminate flag.
    bit inputBufFlagsArgExit, (iy + inputBufFlags)
    jr z, processArgCommands

    ; Refresh display a final time to allow the user to see the 2nd digit
    ; briefly. On a real HP-42S, the calculator seems to update the display on
    ; the *press* of the digit, then trigger the command on the *release* of
    ; the button, which allows the calculator to show the 2nd digit to the
    ; user. The TI-OS GetKey() function used by this app does not give us that
    ; level of control over the press and release events of a button. So we
    ; need to hack this in.
    set dirtyFlagsInput, (iy + dirtyFlags)
    call displayStack

    ; Parse the string into an integer.
    bcall(_ParseArgBuf)
    ld (argValue), a

    ; Terminate argParser.
    res rpnFlagsArgMode, (iy + rpnFlags)
    set dirtyFlagsInput, (iy + dirtyFlags)

    ; Set A=argModifier, for convenience of caller.
    ld a, (argModifier)

    ; Set ZF=0 if ArgParser was canceled.
    bit inputBufFlagsArgCancel, (iy + inputBufFlags)
    ret
