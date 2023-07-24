; List of GetKey() codes and their jump table.
keyCodeHandlerTableSize equ 49
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

    ; The MenuBack function is bound to multiple buttons until I can decide
    ; on the one that seems most convenient. The best button would have been
    ; the ESC button, but the TI-83 and TI-84 calculators don't have that
    ; button (unlike the TI-92 series.)
    ;
    ; 1) The primary button is kLeft, because it has proximity to the kUp and
    ; kDown button used to scroll through different menu strips at the same
    ; level.
    ;
    ; 2) In the Tilem emulator, the keyboard Backspace is mapped to kLeft+kDel,
    ; so a Backspace interfere. The DEL key should probably be used in the
    ; emulator.
    ;
    ; 3) The HP42S uses the ON/EXIT button to exit out of nested menus. The
    ; Tilem emulator exposes that button by mapping F12 to the ON button, but
    ; F12 is an awkward key to use for menu navigation.
    .db kOnExit ; ON button on real calculator, F12 on Tilem
    .dw handleKeyMenuBack
    .db kLeft ; Left arrow
    .dw handleKeyMenuBack

    .db keyMenu1
    .dw handleKeyMenu1
    .db keyMenu2
    .dw handleKeyMenu2
    .db keyMenu3
    .dw handleKeyMenu3
    .db keyMenu4
    .dw handleKeyMenu4
    .db keyMenu5
    .dw handleKeyMenu5

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
    .db kExpon ; y^x
    .dw handleKeyExpon
    .db kInv ; 1/x
    .dw handleKeyInv
    .db kSquare ; x^2
    .dw handleKeySquare
    .db kSqrt
    .dw handleKeySqrt

    ; stack operations. These key bindings were borrowed from the HP30b
    ; calculator which supports both ALG and RPN modes, and places the R-down
    ; on the (, and x<->y on the ).
    .db kLParen ; (
    .dw handleKeyRotDown
    .db kLBrace ; { = 2ND (
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

    ; trignometric
    .db kSin ; SIN
    .dw handleKeySin
    .db kCos ; COS
    .dw handleKeyCos
    .db kTan ; TAN
    .dw handleKeyTan
    .db kASin ; SIN^{-1}
    .dw handleKeyASin
    .db kACos ; COS^{-1}
    .dw handleKeyACos
    .db kATan ; TAN^{-1}
    .dw handleKeyATan
