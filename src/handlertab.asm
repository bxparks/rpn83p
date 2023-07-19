; List of GetKey() codes and their jump table.
keyCodeHandlerTableSize equ 42
kOnExit equ 0 ; ON key generates 00 as the key code
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
    ; For convenience, both EE (2ND-COMMA) and COMMA are mapped to handleKeyEE.
    .db kEE
    .dw handleKeyEE
    .db kComma
    .dw handleKeyEE

    ; editing
    .db kDel
    .dw handleKeyDel
    .db kClear
    .dw handleKeyClear
    .db kChs
    .dw handleKeyChs
    .db kEnter
    .dw handleKeyEnter

    ; menu navigation
    .db kUp
    .dw handleKeyUp
    .db kDown
    .dw handleKeyDown

    ; At first, the kLeft arrow button seems to be a good candiate to bind
    ; the MenuBack function. But in the Tilem emulator, the keyboard Backspace
    ; is mapped to send kLeft + kDel, so a Backspace will perform a MenuBack
    ; functionality, as well as deleting the last character in the inputBuf.
    ;
    ; The HP42S uses the ON/EXIT button to exit out of nested menus. The Tilem
    ; emulator exposes that button by mapping F12 to the ON button. But F12 is
    ; an awkward key to use for menu navigation. Therefore, let's use
    ; kAlphaUp which is bound to the PageUp key in Tilem.
    .db kOnExit ; ON button on real calculator, F12 on Tilem
    .dw handleKeyMenuBack
    .db kAlphaUp ; PageUp on Tilem
    .dw handleKeyMenuBack

    .db keyMenu0
    .dw handleKeyMenu0
    .db keyMenu1
    .dw handleKeyMenu1
    .db keyMenu2
    .dw handleKeyMenu2
    .db keyMenu3
    .dw handleKeyMenu3
    .db keyMenu4
    .dw handleKeyMenu4

    ; arithmetic
    .db kAdd
    .dw handleKeyAdd
    .db kSub
    .dw handleKeySub
    .db kMul
    .dw handleKeyMul
    .db kDiv
    .dw handleKeyDiv

    ; constants
    .db kPi ; pi
    .dw handleKeyPi
    .db kCONSTeA ; e
    .dw handleKeyEuler

    ; algebraic
    .db kExpon
    .dw handleKeyExpon
    .db kInv
    .dw handleKeyInv
    .db kSquare
    .dw handleKeySquare
    .db kSqrt
    .dw handleKeySqrt

    ; stack operations. These key bindings were borrowed from the HP30b
    ; calculator which supports both ALG and RPN modes, and places the R-down
    ; on the (, and x<->y on the ).
    .db kLParen ; (
    .dw handleKeyRotDown
    .db kLBrace ; INV (
    .dw handleKeyRotUp
    .db kRParen ; )
    .dw handleKeyExchangeXY

    ; transcendentals
    .db kLog ; LOG
    .dw handleKeyLog
    .db kALog ; 10^x
    .dw handleKeyALog
    .db kLn ; LN
    .dw handleKeyLn
    .db kExp ; e^x
    .dw handleKeyExp
