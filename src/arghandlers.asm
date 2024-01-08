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
    bcall(_AppendArgBuf) ; sets dirtyFlagsInput
    ld a, (argBufLen)
    cp a, argBufSizeMax
    ret nz ; if only 1 digit entered, just return
    ; On the 2nd digit, invoke auto ENTER to execute the pending command.
    jr handleArgKeyEnterAlt

handleArgKeyEnter:
    ; If no argument digits entered, then do nothing.
    ld a, (argBufLen)
    or a
    ret z
handleArgKeyEnterAlt:
    ; Parse the argument digits into (argValue).
    set inputBufFlagsArgExit, (iy + inputBufFlags)
    ret

handleArgKeyDel:
    set dirtyFlagsInput, (iy + dirtyFlags)
    ld hl, argBuf
    ld a, (hl) ; A=argBufLen
    or a
    ret z ; do nothing if buffer empty
    dec (hl)
    ret

handleArgKeyClear:
handleArgKeyExit:
    bcall(_ClearArgBuf)
    res rpnFlagsEditing, (iy + rpnFlags)
    set dirtyFlagsStack, (iy + dirtyFlags)
    set inputBufFlagsArgExit, (iy + inputBufFlags)
    set inputBufFlagsArgCancel, (iy + inputBufFlags)
    ret

handleArgKeyQuit:
    jp mainExit

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
