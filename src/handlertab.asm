; List of GetKey() codes and their jump table.
keyCodeHandlerTableSize equ 26
keyCodeHandlerTable:
    ; number entry
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

    ; editing
    .db kDel
    .dw handleKeyDel
    .db kClear
    .dw handleKeyClear
    .db kChs
    .dw handleKeyChs
    .db kEnter
    .dw handleKeyEnter

    ; arithmetic
    .db kAdd
    .dw handleKeyAdd
    .db kSub
    .dw handleKeySub
    .db kMul
    .dw handleKeyMul
    .db kDiv
    .dw handleKeyDiv

    ; algebraic
    .db kExpon
    .dw handleKeyExpon
    .db kInv
    .dw handleKeyInv
    .db kSquare
    .dw handleKeySquare
    .db kSqrt
    .dw handleKeySqrt

    ; stack operations
    .db kLParen ; (
    .dw handleKeyRotDown
    .db kLBrace ; INV (
    .dw handleKeyRotUp
    .db kRParen ; )
    .dw handleKeyExchangeXY
