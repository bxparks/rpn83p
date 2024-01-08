;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; List of keyCodes from GetKey() and their handlers within the context of the
; argument dialog box (e.g. "FIX _ _").
;------------------------------------------------------------------------------

argKeyCodeTableSize equ 19

argKeyCodeHandlerTable:
    ; number entry
    .db k0
    .dw handleArgKey0
    .db k1
    .dw handleArgKey1
    .db k2
    .dw handleArgKey2
    .db k3
    .dw handleArgKey3
    .db k4
    .dw handleArgKey4
    .db k5
    .dw handleArgKey5
    .db k6
    .dw handleArgKey6
    .db k7
    .dw handleArgKey7
    .db k8
    .dw handleArgKey8
    .db k9
    .dw handleArgKey9

    ; letter entry (A-Z, Theta)
    .db kCapA
    .dw handleArgKeyA

    ; editing
    .db kDel
    .dw handleArgKeyDel
    .db kClear
    .dw handleArgKeyClear
    .db kEnter
    .dw handleArgKeyEnter

    ; on/exit
    .db kOnExit ; ON button on real calculator, F12 on Tilem USB keyboard
    .dw handleArgKeyExit
    .db kQuit ; 2ND QUIT
    .dw handleArgKeyQuit

    ; arithmetic
    .db kAdd
    .dw handleArgKeyAdd
    .db kSub
    .dw handleArgKeySub
    .db kMul
    .dw handleArgKeyMul
    .db kDiv
    .dw handleArgKeyDiv
