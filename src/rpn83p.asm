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
statusMenuPenCol equ 0 ; 3 * 4px, (up | down) + quadspace
statusFloatModePenCol equ 12 ; 7 * 4px (FIX|SCI|ENG) + (n) + quadspace
statusTrigPenCol equ 40 ; 4 * 4px, (DEG | RAD) + quadspace

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

; Display coordinates of the input buffer.
inputCurRow equ stXCurRow
inputCurCol equ stXCurCol
inputPenRow equ inputCurRow*8

; Display coordinates of the arg buffer.
argCurRow equ 6
argCurCol equ 0
argPenRow equ argCurRow*8

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
rpnFlagsArgMode equ 1 ; set if in command argument mode
rpnFlagsLiftEnabled equ 2 ; set if stack lift is enabled (ENTER disables it)
rpnFlagsStackDirty equ 3 ; set if the stack is dirty
rpnFlagsMenuDirty equ 4 ; set if the menu selection is dirty
rpnFlagsTrigDirty equ 5 ; set if the trig status is dirty
rpnFlagsFloatModeDirty equ 6 ; set if the floating mode is dirty

; Flags for the inputBuf. Offset from IY register.
inputBufFlags equ asm_Flag3
inputBufFlagsInputDirty equ 0 ; set if the input buffer is dirty
inputBufFlagsDecPnt equ 1 ; set if decimal point exists
inputBufFlagsEE equ 2 ; set if EE symbol exists
inputBufFlagsClosedEmpty equ 3 ; inputBuf empty when closeInputBuf() called
inputBufFlagsExpSign equ 4 ; exponent sign bit detected during parsing

;-----------------------------------------------------------------------------
; Application variables and buffers.
;-----------------------------------------------------------------------------

; Begin RPN83P variables.
rpnVarsBegin equ tempSwapArea

; Error code and handling.
errorCode equ rpnVarsBegin ; current error code
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
;       uint8_t size; // number of digits in mantissa, 0 for 0.0
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
;       uint8_t type;
;       uint8_t exp;
;       uint8_t man[7];
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

; When the inputBuf is used as a command argBuf, the maximum number of
; characters in the buffer is 2.
argBuf equ inputBuf
argBufSize equ inputBufSize
argBufMax equ inputBufMax
argBufSizeMax equ 2

; Pointer to a C string that prompts before the argBuf.
; void *argPrompt;
argPrompt equ menuStripIndex + 1
argPromptSizeOf equ 2

; Pointer to the command handler waiting for the arg.
argHandler equ argPrompt + argPromptSizeOf
argHandlerSizeOf equ 2

; Parsed value of argBuf.
argValue equ argHandler + argHandlerSizeOf
argValueSizeOf equ 1

; End RPN83P variables. Total size of vars = rpnVarsEnd - rpnVarsBegin.
rpnVarsEnd equ argValue + argValueSizeOf

;-----------------------------------------------------------------------------

.org userMem - 2
.db t2ByteTok, tAsmCmp

main:
    bcall(_RunIndicOff)
    res appAutoScroll, (iy + appFlags) ; disable auto scroll
    res appTextSave, (iy + appFlags) ; disable shawdow text
    bcall(_ClrLCDFull)

    call initErrorCode
    call initInputBuf
    call initArgBuf
    call initStack
    call initMenu
    call initDisplay
    ; [[fall through]]

; The main event/read loop. Read each button until 2ND-QUIT is entered.
readLoop:
    ; call debugFlags
    call displayAll

    ; Clear the error code before calling lookupKey() to detect any custom
    ; error code set directly by the handler. This makes the implementation of
    ; handleKeyClear() slightly more tricky because when a CLEAR is hit just
    ; after a non-zero error code is displayed, the CLEAR key should simply
    ; clear the error, instead of clearing the inputBuf. The solution is for
    ; the handleKeyClear() function to check for errorCodeDisplayed, which is
    ; the error code that was most recently rendered, which is not affected by
    ; this call.
    call clearErrorCode

    ; Get the key code, and reset the ON flag right after. See TI-83 Plus SDK
    ; guide, p. 69. If this flag is not reset, then the next bcall(_DispHL)
    ; causes subsequent bcall(_GetKey) to always return 0. Interestingly, if
    ; the flag is not reset, but the next call is another bcall(_GetKey), then
    ; it sort of seems to work. Except that upon exiting, the TI-OS displays an
    ; Quit/Goto error message.
    bcall(_GetKey)
    res onInterrupt, (IY+onFlags)

    ; Check for 2nd-Quit to Quit. ON (0) triggers the handleKeyMenuBack() to
    ; emulate the ON/EXIT key on the HP 42S which exits nested menus on that
    ; calculator.
    ; TODO: The LeftArrow is also bound to hanldeKeyMenuBack(), and that seems
    ; convenient because LeftArrow is in close proximity to UpArrow and
    ; DownArrow. Maybe on the TI-83/TI-84 calculators, the ON button should
    ; just do nothing.
    cp kQuit
    jr z, mainExit

    ; Install error handler
    ld hl, mainError
    call APP_PUSH_ERRORH
    ; Handle the normal buttons or the menu F1-F5 buttons.
    call lookupKey
    ; Uninstall error handler
    call APP_POP_ERRORH

    jr readLoop

; Handle system error. Register A contains the error code.
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
#include "menu.asm"
#include "menuhandlers.asm"
; Place data files at the end, because the TI-OS prevents execution of assembly
; code if it spills over to page $C000. The limitation does not apply to data.
#include "handlertab.asm"
#include "menudevdef.asm"

;-----------------------------------------------------------------------------

msgPrompt:
    .db "Press key", 0

msgExit:
    .db "Quit pressed", 0

.end
