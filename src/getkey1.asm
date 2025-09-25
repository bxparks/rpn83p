;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2025 Brian T. Park
;
; A light wrapper around the bcall(_GetKey) function of the OS. This version
; allows one keycode to be "pushed back" into a buffer, so that the next
; getRpnKey() call returns the keycode that was pushed back. This is useful
; when one command processor (e.g. processShowCommands()) wants to read a
; keycode, then do nothing with it, then hand it off to another command
; processor (e.g. processMainCommands().
;------------------------------------------------------------------------------

; Description: Light wrapper around the `bcall(_GetKey)` function.
; Input:
;   - (rpnKeyCodeBuf)=push back buffer
; Output:
;   - A:u8=current key code
;   - (rpnKeyCodeBuf) updated
; Destroys: BC, DE, HL
GetRpnKeyCode:
    ld bc, (rpnKeyCodeBuf)
    bit 7, b
    jr nz, getRpnKeyCodeNew ; rpnKeyCodeBuf < 0, so get new code
    ; return the code in the push-back buffer
    ld a, c
    jr ClearRpnKeyCode ; preserves A
getRpnKeyCodeNew:
    ; The SDK docs say that GetKey() destroys only A, DE, HL. But it looks like
    ; BC also gets destroyed if 2ND QUIT is pressed.
    bcall(_GetKey)
    ; Reset the ON flag right after. See TI-83 Plus SDK guide, p. 69. If this
    ; flag is not reset, then the next bcall(_DispHL) causes subsequent
    ; bcall(_GetKey) to always return 0. Interestingly, if the flag is not
    ; reset, but the next call is another bcall(_GetKey), then it sort of seems
    ; to work. Except that upon exiting, the TI-OS displays an Quit/Goto error
    ; message.
    res onInterrupt, (iy + onFlags)
    ret

; Description: Push the keycode in A into the (rpnKeyCodeBuf).
; Input: A:u8=keyCode
; Output; (rpnKeyCodeBuf):i16=A
; Destroys: BC
PushRpnKeyCode:
    ld c, a
    ld b, $00
    ld (rpnKeyCodeBuf), bc
    ret

; Description: Clear the pending keycode in the (rpnKeyCodeBuf) by setting the
; code to -1.
; Input: none
; Output: (rpnKeyCodeBuf) cleared
; Destroys: BC
; Preserves: A
ClearRpnKeyCode:
    ld bc, $ffff ; i.e. -1
    ld (rpnKeyCodeBuf), bc
    ret
