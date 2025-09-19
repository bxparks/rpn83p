;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Key code dispatcher and handlers for the command ArgScanner.
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
    ld a, (argLenLimit)
    ld b, a ; B=argLenLimit
    ld a, (argBufLen) ; A=argBufLen
    sub b ; A=argBufLen-argLenLimit; CF=0 if argBufLen>=argLenLimit
    ; invoke auto ENTER if argBufLen>=argLenLimit
    jp nc, handleArgKeyEnterAlt
    ret; argBuf not filled, just return

;-----------------------------------------------------------------------------

handleArgKeyA:
    ld a, tA
    jr handleArgLetter

handleArgKeyB:
    ld a, tB
    jr handleArgLetter

handleArgKeyC:
    ld a, tC
    jr handleArgLetter

handleArgKeyD:
    ld a, tD
    jr handleArgLetter

handleArgKeyE:
    ld a, tE
    jr handleArgLetter

handleArgKeyF:
    ld a, tF
    jr handleArgLetter

handleArgKeyG:
    ld a, tG
    jr handleArgLetter

handleArgKeyH:
    ld a, tH
    jr handleArgLetter

handleArgKeyI:
    ld a, tI
    jr handleArgLetter

handleArgKeyJ:
    ld a, tJ
    jr handleArgLetter

handleArgKeyK:
    ld a, tK
    jr handleArgLetter

handleArgKeyL:
    ld a, tL
    jr handleArgLetter

handleArgKeyM:
    ld a, tM
    jr handleArgLetter

handleArgKeyN:
    ld a, tN
    jr handleArgLetter

handleArgKeyO:
    ld a, tO
    jr handleArgLetter

handleArgKeyP:
    ld a, tP
    jr handleArgLetter

handleArgKeyQ:
    ld a, tQ
    jr handleArgLetter

handleArgKeyR:
    ld a, tR
    jr handleArgLetter

handleArgKeyS:
    ld a, tS
    jr handleArgLetter

handleArgKeyT:
    ld a, tT
    jr handleArgLetter

handleArgKeyU:
    ld a, tU
    jr handleArgLetter

handleArgKeyV:
    ld a, tV
    jr handleArgLetter

handleArgKeyW:
    ld a, tW
    jr handleArgLetter

handleArgKeyX:
    ld a, tX
    jr handleArgLetter

handleArgKeyY:
    ld a, tY
    jr handleArgLetter

handleArgKeyZ:
    ld a, tZ
    jr handleArgLetter

handleArgKeyTheta:
    ld a, tTheta
    jr handleArgLetter

handleArgLetter:
    bit inputBufFlagsArgAllowLetter, (iy + inputBufFlags)
    ret z
    jp handleArgNumber

;-----------------------------------------------------------------------------

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
