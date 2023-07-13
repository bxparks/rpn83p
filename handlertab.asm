; List of GetKey() codes and their jump table.
keyCodeHandlerTableSize equ 15
keyCodeHandlerTable:
    .db k0
    .dw handleKey0
    .db k1
    .dw handleKey1
    .db k2
    .dw handleKey2
    .db k3
    .dw handleKey3
    .db k4
    .dw handleKey4
    .db k5
    .dw handleKey5
    .db k6
    .dw handleKey6
    .db k7
    .dw handleKey7
    .db k8
    .dw handleKey8
    .db k9
    .dw handleKey9
    .db kDecPnt
    .dw handleKeyDecPnt
    .db kDel
    .dw handleKeyDel
    .db kClear
    .dw handleKeyClear
    .db kChs
    .dw handleKeyChs
    .db kEnter
    .dw handleKeyEnter
