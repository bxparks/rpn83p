;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; List of keyCodes from GetKey() and their handlers within the context of the
; argument dialog box (e.g. "FIX _ _").
;------------------------------------------------------------------------------

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
    .db kCapB
    .dw handleArgKeyB
    .db kCapC
    .dw handleArgKeyC
    .db kCapD
    .dw handleArgKeyD
    .db kCapE
    .dw handleArgKeyE
    .db kCapF
    .dw handleArgKeyF
    .db kCapG
    .dw handleArgKeyG
    .db kCapH
    .dw handleArgKeyH
    .db kCapI
    .dw handleArgKeyI
    .db kCapJ
    .dw handleArgKeyJ
    .db kCapK
    .dw handleArgKeyK
    .db kCapL
    .dw handleArgKeyL
    .db kCapM
    .dw handleArgKeyM
    .db kCapN
    .dw handleArgKeyN
    .db kCapO
    .dw handleArgKeyO
    .db kCapP
    .dw handleArgKeyP
    .db kCapQ
    .dw handleArgKeyQ
    .db kCapR
    .dw handleArgKeyR
    .db kCapS
    .dw handleArgKeyS
    .db kCapT
    .dw handleArgKeyT
    .db kCapU
    .dw handleArgKeyU
    .db kCapV
    .dw handleArgKeyV
    .db kCapW
    .dw handleArgKeyW
    .db kCapX
    .dw handleArgKeyX
    .db kCapY
    .dw handleArgKeyY
    .db kCapZ
    .dw handleArgKeyZ
    .db kTheta
    .dw handleArgKeyTheta

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

;-----------------------------------------------------------------------------

; Auto-calculate the number of entries in the table.
argKeyCodeHandlerTableEnd:
argKeyCodeTableSize equ (argKeyCodeHandlerTableEnd-argKeyCodeHandlerTable)/3

