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
statusCurRow equ 2
statusCurCol equ 0
statusPenRow equ stTCurRow*8

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

; Flags for the display.
displayFlags equ tempSwapArea
displayFlagsInputDirty equ 0 ; set if the input buffer is dirty
displayFlagsTitleDirty equ 1 ; set if the title bar is dirty
displayFlagsStackDirty equ 2 ; set if the stack is dirty
displayFlagsMenuDirty equ 3 ; set if the menu bar is dirty

; Flags for RPN stack modes
rpnFlags equ displayFlags + 1
rpnFlagsEditing equ 1 ; set if in edit mode
rpnFlagsLiftDisabled equ 1 ; set if stack lift is disabled (e.g. after ENTER)

; Flags for the inputBuf.
inputBufFlags equ rpnFlags + 1
inputBufFlagsDecPnt equ 0 ; set if decimal point exists
inputBufFlagsManSign equ 1 ; mantissa sign bit
inputBufFlagsExpSign equ 2 ; exponent sign bit

; String buffer for keyboard entry. This is a Pascal-style with a single size
; byte at the start. It not include the cursor displayed at the end of the
; string. The equilvalent C struct is:
;
;   struct inputBuf {
;       uint8_t size;
;       char buf[inputBufMax];
;   };
inputBuf equ inputBufFlags + 1
inputBufSize equ inputBuf ; size byte of the pascal string
inputBufBuf equ inputBuf + 1
inputBufMax equ 14 ; maximum size of buffer, not including terminating cursor
inputBufSizeOf equ inputBufMax + 1

; Temporary buffer for parsing keyboard input into a floating point number. This
; contains the normalized floating point number, one character per digit. It's
; a stepping stone before converting this into the packed floating point number
; format used by TI-OS. The equivalent C struct is:
;
;   struct parseBuf {
;       uint_t size; // number of digits in mantissa, 0 for 0.0
;       char man[parseBufMax];  // mantissa, implicit starting decimal point
;   }
;
; A TI-OS floating number can have a mantissa of a maximum 14 digits.
parseBuf equ inputBuf + inputBufSizeOf
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
;
floatBuf equ parseBuf + parseBufSizeOf
floatBufType equ floatBuf ; type
floatBufExp equ floatBufType + 1 ; exponent, shifted by $80
floatBufMan equ floatBufExp + 1 ; mantissa, 2 digits per byte
floatBufSizeOf equ 9

; Define the Cursor character
cursorChar equ LcurI
cursorCharAlt equ LcurO

;-----------------------------------------------------------------------------

.org userMem - 2
.db t2ByteTok, tAsmCmp

main:
    bcall(_RunIndicOff)
    bcall(_ClrLCDFull)
    res appAutoScroll, (iy + appFlags)
    call stackInit
    call displayInit
    call clearInputBuf

readLoop:
    call debugInputBuf
    ;call debugFlags

    call displayAll

    ; Get the key code, and reset the ON flag right after. See TI-83 Plus SDK
    ; guide, p. 69. If this flag is not reset, then the next bcall(_DispHL)
    ; causes subsequent bcall(_GetKey) to always return 0. Interestingly, if
    ; the flag is not reset, but the next call is another bcall(_GetKey), then
    ; it sort of seems to work. Except that upon exiting, the TI-OS displays an
    ; Quit/Goto error message.
    bcall(_GetKey)
    res onInterrupt, (IY+onFlags)

    ; Check for 2nd-Quit, or ON.
    cp kQuit
    jr z, mainExit
    or a
    jr z, mainExit

    ; Handle key
    call lookupKey
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
#include "pstring.asm"
#include "parsenum.asm"
#include "display.asm"
#include "debug.asm"
#include "handlertab.asm"

;-----------------------------------------------------------------------------

msgPrompt:
    .db "Press key", 0

msgExit:
    .db "Quit pressed", 0

.end
