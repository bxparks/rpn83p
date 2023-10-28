;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Key code dispatcher and handlers for the command argument parser.
;-----------------------------------------------------------------------------

handleArgKey0:
    ld a, '0'
    jr handleArgNumber

handleArgKey1:
    ld a, '1'
    jr handleArgNumber

handleArgKey2:
    ld a, '2'
    jr handleArgNumber

handleArgKey3:
    ld a, '3'
    jr handleArgNumber

handleArgKey4:
    ld a, '4'
    jr handleArgNumber

handleArgKey5:
    ld a, '5'
    jr handleArgNumber

handleArgKey6:
    ld a, '6'
    jr handleArgNumber

handleArgKey7:
    ld a, '7'
    jr handleArgNumber

handleArgKey8:
    ld a, '8'
    jr handleArgNumber

handleArgKey9:
    ld a, '9'
    jr handleArgNumber

handleArgNumber:
    call appendArgBuf ; sets dirtyFlagsInput
    ld a, (argBuf) ; A = length of argBuf string
    cp a, argBufSizeMax
    ret nz ; if only 1 digit entered, just return
    ; On the 2nd digit, invoke auto ENTER to execute the pending command. But
    ; before we do that, we refresh display to allow the user to see the 2nd
    ; digit briefly. On a real HP-42S, the calculator seems to update the
    ; display on the *press* of the digit, then trigger the command on the
    ; *release* of the button, which allows the calculator to show the 2nd
    ; digit to the user. The TI-OS GetKey() function used by this app does not
    ; give us that level of control over the press and release events of a
    ; button. Hence the need for this hack.
    set dirtyFlagsInput, (iy + dirtyFlags)
    call displayStack
    ; [[fallthrough]]

handleArgKeyEnter:
    ; If no argument digits entered, then do nothing.
    ld a, (argBufSize)
    or a
    ret z
    ; Parse the argument digits into (argValue).
    call parseArgBuf
    ld (argValue), a
    set inputBufFlagsArgExit, (iy + inputBufFlags)
    ret

handleArgKeyDel:
    set dirtyFlagsInput, (iy + dirtyFlags)
    ld hl, argBuf
    ld a, (hl) ; A = inputBufSize
    or a
    ret z ; do nothing if buffer empty
    dec (hl)
    ret

handleArgKeyClear:
handleArgKeyExit:
    call clearArgBuf
    ld a, argModifierCanceled
    ld (argModifier), a
    res rpnFlagsEditing, (iy + rpnFlags)
    set dirtyFlagsStack, (iy + dirtyFlags)
    set inputBufFlagsArgExit, (iy + inputBufFlags)
    ret

handleArgKeyAdd:
    bit inputBufFlagsArgAllowModifier, (iy + inputBufFlags)
    ret z
    ld a, argModifierAdd
    ld (argModifier), a
    set dirtyFlagsInput, (iy + dirtyFlags)
    ret

handleArgKeySub:
    bit inputBufFlagsArgAllowModifier, (iy + inputBufFlags)
    ret z
    ld a, argModifierSub
    ld (argModifier), a
    set dirtyFlagsInput, (iy + dirtyFlags)
    ret

handleArgKeyMul:
    bit inputBufFlagsArgAllowModifier, (iy + inputBufFlags)
    ret z
    ld a, argModifierMul
    ld (argModifier), a
    set dirtyFlagsInput, (iy + dirtyFlags)
    ret

handleArgKeyDiv:
    bit inputBufFlagsArgAllowModifier, (iy + inputBufFlags)
    ret z
    ld a, argModifierDiv
    ld (argModifier), a
    set dirtyFlagsInput, (iy + dirtyFlags)
    ret
