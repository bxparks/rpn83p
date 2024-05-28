;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; List of GetKey() codes and their jump table.
;
; TODO: As this table gets longer, consider sorting this table so that a binary
; search can be used instead of a linear search.
;-----------------------------------------------------------------------------

kOnExit equ 0 ; ON key generates 00 as the key code

keyCodeHandlerTable:
;-----------------------------------------------------------------------------

    ; digits
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

    ; letters, HEX numbers and Record tags, e.g. D{2000,1,1,}
    .db kCapA
    .dw handleKeyA
    .db kCapB
    .dw handleKeyB
    .db kCapC
    .dw handleKeyC
    .db kCapD
    .dw handleKeyD
    .db kCapE
    .dw handleKeyE
    .db kCapF
    .dw handleKeyF
    .db kCapG
    .dw handleKeyG
    .db kCapH
    .dw handleKeyH
    .db kCapI
    .dw handleKeyI
    .db kCapJ
    .dw handleKeyJ
    .db kCapK
    .dw handleKeyK
    .db kCapL
    .dw handleKeyL
    .db kCapM
    .dw handleKeyM
    .db kCapN
    .dw handleKeyN
    .db kCapO
    .dw handleKeyO
    .db kCapP
    .dw handleKeyP
    .db kCapQ
    .dw handleKeyQ
    .db kCapR
    .dw handleKeyR
    .db kCapS
    .dw handleKeyS
    .db kCapT
    .dw handleKeyT
    .db kCapU
    .dw handleKeyU
    .db kCapV
    .dw handleKeyV
    .db kCapW
    .dw handleKeyW
    .db kCapX
    .dw handleKeyX
    .db kCapY
    .dw handleKeyY
    .db kCapZ
    .dw handleKeyZ

    ; number modifiers
    .db kDecPnt
    .dw handleKeyDecPnt
    .db kEE
    .dw handleKeyEE
    .db kColon
    .dw handleKeyColon

    ; Complex numbers
    .db kI
    .dw handleKeyImagI
    .db kAngle
    .dw handleKeyAngle

    ; Data records usng '{', '}', ','
    .db kLBrace
    .dw handleKeyLBrace
    .db kRBrace
    .dw handleKeyRBrace
    .db kComma
    .dw handleKeyComma

    ; editing
    .db kDel
    .dw handleKeyDel
    .db kClear
    .dw handleKeyClear
    .db kChs
    .dw handleKeyChs
    .db kEnter
    .dw handleKeyEnter

;-----------------------------------------------------------------------------

    ; cursor navigation
    .db kLeft
    .dw handleKeyLeft
    .db kRight
    .dw handleKeyRight
    .db kBOL ; 2ND Left
    .dw handleKeyBOL
    .db kEOL ; 2ND Right
    .dw handleKeyEOL

;-----------------------------------------------------------------------------

    ; menu navigation
    .db kUp
    .dw handleKeyUp
    .db kDown
    .dw handleKeyDown

    ; Handle the "menu back" or "menu exit" functionality. The best button
    ; functionality for this would have been an ESC button, but the TI-83 and
    ; TI-84 calculators don't have that button, unlike the TI-92 series
    ; calculators.
    ;
    ; The next best button seems to be the ON button, because it is similar to
    ; the ON/EXIT button on the HP-42S calculator. There are 3 potential
    ; problems with the ON button:
    ;
    ; 1) On the TI-83/TI-84, the ON button is special because it generates an
    ; interrupt that sets a flag which can be polled by the assembly language
    ; program, even without calling the GetKey() function. The ON button is
    ; therefore often used as a BREAK button, which is close enough to the EXIT
    ; function of the HP-42S, so I think this mapping is reasonable.
    ;
    ; 2) The ON button is physically far away from the UP and DOWN arrow keys,
    ; unlike the HP-42S where the UP and DOWN buttons are on the lower-left
    ; side of the calculator, close to the ON/EXIT button. I suspect that this
    ; may cause some ergonomic issues with traversing the hierarchical menus,
    ; potentially requring 2 hands to navigate, instead of just one. (The two
    ; buttons directly to the left of the arrow keys would have been nice to
    ; use as the ESC key, but those are currently mapped to DEL and STAT. DEL
    ; is used as the Backspace functionality, and I want to reserve the STAT
    ; button for future additions.)
    ;
    ; 3) The Tilem emulator exposes the ON button as the F12 key on the PC
    ; keyboard, which is somewhat awkward to use. The ESC key on Tilem is
    ; mapped to the CLEAR button so we can't use that. The PageUp key seemed
    ; like a good alternative candidate since it is easy to reach on a USB
    ; keyboard and is mapped to ALPHA_UP on the calculator. However, there
    ; seems to be a bug where the ALPHA_UP, ALPHA_DOWN and ALPHA_ENTER keys
    ; don't work properly if the application is running as a flash app (instead
    ; of an assembly language program). Those buttons seem to trigger just the
    ; normal UP, DOWN, ENTER key codes, instead of the distinct ALPHA_UP,
    ; ALPHA_DOWN, and ALPHA_ENTER codes. So I gave up: On the Tilem, we have to
    ; use F12 or use the mouse to do a Menu Back.
    ;
    ; In early versions of this program, I tried using the LEFT arrow key as
    ; the Menu Back. It seemed reasonable because it is close to the UP and
    ; DOWN arrow keys. But I discovered that the LEFT arrow key is so tightly
    ; associated with the "Cursor Back" functionality, that it never felt
    ; natural to use it as Menu Back. I remove that mapping, which frees up the
    ; LEFT and RIGHT keys for future use. For example, it could be used for
    ; scrolling long numbers or strings that overflow the 14-16 character
    ; display limit on the X register line.
    .db kOnExit ; ON button on real calculator, F12 on Tilem USB keyboard
    .dw handleKeyExit

    ; The 5 function keys just below the LCD screen, mapped to menu items.
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
    ; The 2ND versions of the 5 menu keys.
    .db keyMenuSecond1
    .dw handleKeyMenuSecond1
    .db keyMenuSecond2
    .dw handleKeyMenuSecond2
    .db keyMenuSecond3
    .dw handleKeyMenuSecond3
    .db keyMenuSecond4
    .dw handleKeyMenuSecond4
    .db keyMenuSecond5
    .dw handleKeyMenuSecond5

;-----------------------------------------------------------------------------

    ; Stack operations. These key bindings were borrowed from the HP30b
    ; and other HP calculators which support both ALG and RPN modes. The
    ; convention seems to be:
    ;   - `(` (left parens): RollDown
    ;   - `)` (right parens): x<->y (swap)
    .db kLParen ; (
    .dw handleKeyRollDown
    .db kRParen ; )
    .dw handleKeyExchangeXY

    ; The RollUp command is available through the menu system using the
    ; ROOT>STK>Rup soft menu button. But it is more convenient to bind a key to
    ; this function. The `2ND {` button (above the left-parens `(`) would have
    ; been a good candidate, but it is used to input Record objects (e.g. Date
    ; such as `{2024,5,13}`). No other button above the `(` button seemed
    ; appropriate. The best alternative seemed to be the `2ND u` button.
    ; 1) It is to the left of the `(`, which is similar to the location of the
    ; `Rollup` soft menu key in the `STK` menufolder.
    ; 2) The `u` can be a mnemonic for the "Rollup" name of the command.
    .db kunA
    .dw handleKeyRollup

    ; bind ANS to lastX.
    .db kAns ; ANS
    .dw handleKeyAns

;-----------------------------------------------------------------------------

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

    ; STO and RCL registers
    .db kStore
    .dw handleKeySto
    .db kRecall
    .dw handleKeyRcl

;-----------------------------------------------------------------------------

    ; MATH button performs Menu HOME functionality.
    .db kMath
    .dw handleKeyMath

    ; MODE button bound to MODE menu.
    .db kMode
    .dw handleKeyMode

    ; STAT button bound to STAT menu.
    .db kStat
    .dw handleKeyStat

;-----------------------------------------------------------------------------

    ; 2ND QUIT
    .db kQuit
    .dw handleKeyQuit

    ; DRAW (i.e. Debug) mode
    .db kDraw
    .dw handleKeyDraw

    ; 2ND ENTRY = SHOW
    .db kLastEnt
    .dw handleKeyShow

;-----------------------------------------------------------------------------

    ; 2ND LINK. Merge (link) reals to complex, or split complex into reals. When
    ; date-like objects are given, perform Merge(RpnOffset,RpnDateTime) or
    ; Merge(RpnTime, RpnDate).
    .db kLinkIO
    .dw handleKeyLink

;-----------------------------------------------------------------------------

; Auto-calculate the number of entries in the table.
keyCodeHandlerTableEnd:
keyCodeHandlerTableSize equ (keyCodeHandlerTableEnd-keyCodeHandlerTable)/3
