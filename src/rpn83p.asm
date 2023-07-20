; RPN mode for the TI-83 Plus and TI-84 Plus calculators.
;
; Reads the following keycodes:
;   - 0-9 (TODO expand to Alpha-A to Alpha-F for hexadecimal)
;   - . and (-)
;   - , or 2nd-EE for EE
;   - DEL, backspace, removes the last character
;   - CLEAR, removes the entire line
;   - anything else sets the Carry bit and returns
; See 83pa28d/week2/day12.

.nolist
#include "ti83plus.inc"
.list

; Display coordinates of the status line
statusCurRow equ 0
statusCurCol equ 0
statusPenRow equ statusCurRow*8

; Display coordinates of the debug line
debugCurRow equ 1
debugCurCol equ 0
debugPenRow equ debugCurRow*8

; Display coordinates of the error line
errorCurRow equ 2
errorCurCol equ 0
errorPenRow equ errorCurRow*8

; Display coordinates of the stack T register.
stTCurRow equ 3
stTCurCol equ 1
stTPenRow equ stTCurRow*8

; Display coordinates of the stack Z register.
stZCurRow equ 4
stZCurCol equ 1
stZPenRow equ stZCurRow*8

; Display coordinates of the stack Y register.
stYCurRow equ 5
stYCurCol equ 1
stYPenRow equ stYCurRow*8

; Display coordinates of the stack X register.
stXCurRow equ 6
stXCurCol equ 1
stXPenRow equ stXCurRow*8

; Define the Cursor character
cursorChar equ LcurI
cursorCharAlt equ LcurO
signChar equ Lneg ; different from '-' which is LDash

; Menu keys, left to right.
keyMenu1 equ kYequ
keyMenu2 equ kWindow
keyMenu3 equ kZoom
keyMenu4 equ kTrace
keyMenu5 equ kGraph

; Flags for RPN stack modes. Offset from IY register.
rpnFlags equ asm_Flag2
rpnFlagsEditing equ 0 ; set if in edit mode
rpnFlagsLiftEnabled equ 1 ; set if stack lift is enabled (ENTER disables)
rpnFlagsStackDirty equ 2 ; set if the stack is dirty
rpnFlagsMenuDirty equ 3 ; set if the menu selection is dirty
rpnFlagsErrorDirty equ 4 ; set if the error code is dirty
rpnFlagsStatusDirty equ 5 ; set if the status is dirty (TODO: not used)

; Flags for the inputBuf. Offset from IY register.
inputBufFlags equ asm_Flag3
inputBufFlagsInputDirty equ 0 ; set if the input buffer is dirty
inputBufFlagsDecPnt equ 1 ; set if decimal point exists
inputBufFlagsEE equ 2 ; set if EE symbol exists
inputBufFlagsClosedEmpty equ 3 ; inputBuf empty when closeInputBuf() called
inputBufFlagsExpSign equ 4 ; exponent sign bit detected during parsing

; Error code and handling.
errorCode equ tempSwapArea ; current error code
errorCodeDisplayed equ errorCode + 1 ; displayed error code

; String buffer for keyboard entry. This is a Pascal-style with a single size
; byte at the start. It does not include the cursor displayed at the end of the
; string. The equilvalent C struct is:
;
;   struct inputBuf {
;       uint8_t size;
;       char buf[inputBufMax];
;   };
inputBuf equ errorCodeDisplayed + 1
inputBufSize equ inputBuf ; size byte of the pascal string
inputBufBuf equ inputBuf + 1
inputBufMax equ 14 ; maximum size of buffer, not including appended cursor
inputBufSizeOf equ inputBufMax + 1

; Location (offset index) of the one past the 'E' symbol if it exists. Zero
; indicates that 'E' does NOT exist.
inputBufEEPos equ inputBuf + inputBufSizeOf
; Length of EE digits. Maximum of 2.
inputBufEELen equ inputBufEEPos + 1
; Max number of digits allowed for exponent.
inputBufEELenMax equ 2

; Temporary buffer for parsing keyboard input into a floating point number. This
; is a pascal string that contains the normalized floating point number, one
; character per digit. It's a stepping stone before converting this into the
; packed floating point number format used by TI-OS. The equivalent C struct
; is:
;
;   struct parseBuf {
;       uint_t size; // number of digits in mantissa, 0 for 0.0
;       char man[parseBufMax];  // mantissa, implicit starting decimal point
;   }
;
; A TI-OS floating number can have a mantissa of a maximum 14 digits.
parseBuf equ inputBufEELen + 1
parseBufSize equ parseBuf ; size byte of the pascal string
parseBufMan equ parseBufSize + 1
parseBufMax equ 14
parseBufSizeOf equ parseBufMax + 1

; Floating point number buffer, 9 bytes for TI-OS:
;
;   struct floatBuf {
;       uint_t type;
;       uint_t exp;
;       uint_t man[7];
;   }
floatBuf equ parseBuf + parseBufSizeOf
floatBufType equ floatBuf ; type
floatBufExp equ floatBufType + 1 ; exponent, shifted by $80
floatBufMan equ floatBufExp + 1 ; mantissa, 2 digits per byte
floatBufSizeOf equ 9

; Menu variables. The C equivalent is:
;
;   struct menu {
;     uint8_t currentId;
;     uint8_t stripIndex; // menu strip, groups of 5
;   }
menuCurrentId equ floatBuf + floatBufSizeOf
menuStripIndex equ menuCurrentId + 1

;-----------------------------------------------------------------------------

.org userMem - 2
.db t2ByteTok, tAsmCmp

main:
    bcall(_RunIndicOff)
    bcall(_ClrLCDFull)
    res appAutoScroll, (iy + appFlags)
    call initErrorCode
    call initInputBuf
    call initStack
    call initMenu
    call initDisplay
    ; [[fall through]]

; The main event/read loop. Read each button until 2ND-QUIT is entered.
readLoop:
    ; call debugFlags
    call displayAll

    ; Get the key code, and reset the ON flag right after. See TI-83 Plus SDK
    ; guide, p. 69. If this flag is not reset, then the next bcall(_DispHL)
    ; causes subsequent bcall(_GetKey) to always return 0. Interestingly, if
    ; the flag is not reset, but the next call is another bcall(_GetKey), then
    ; it sort of seems to work. Except that upon exiting, the TI-OS displays an
    ; Quit/Goto error message.
    bcall(_GetKey)
    res onInterrupt, (IY+onFlags)

    ; Check for 2nd-Quit to Quit. ON (0) will act like the ON/EXIT key on the
    ; HP 42S.
    cp kQuit
    jr z, mainExit

    ; Install error handler
    ld hl, mainError
    call APP_PUSH_ERRORH
    ; Handle key
    call lookupKey
    ; Uninstall error handler
    call APP_POP_ERRORH

    call clearErrorCode
    jr readLoop

; Handle system error
mainError:
    call setErrorCode
    jr readLoop

; Clean up and exit app.
mainExit:
    set appAutoScroll, (iy + appFlags)
    bcall(_ClrLCDFull)
    bcall(_HomeUp)
    ret

;-----------------------------------------------------------------------------

#include "vars.asm"
#include "handlers.asm"
#include "common.asm"
#include "pstring.asm"
#include "parsenum.asm"
#include "display.asm"
#include "errorcode.asm"
#include "debug.asm"
#include "handlertab.asm"
#include "menu.asm"
#include "menudevdef.asm"

;-----------------------------------------------------------------------------

msgPrompt:
    .db "Press key", 0

msgExit:
    .db "Quit pressed", 0

.end
