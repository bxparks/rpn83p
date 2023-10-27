;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; RPN calculator for the TI-83 Plus and TI-84 Plus calculators. Inspired
; by the HP-42S calculator.
;
; See Appendix A ("Creating Flash Applications with SPASM") of the book ("TI-83
; ASM For the Absolute Beginner") at
; (https://www.ticalc.org/archives/files/fileinfo/437/43784.html) regarding the
; "app.inc" include, the defpage() macro, and the validate() macro.
;
; This needs to be compiled using spasm-ng into a *.8xk file.
;-----------------------------------------------------------------------------

.nolist
#include "ti83plus.inc"
#include "app.inc"
; Define single page flash app
defpage(0, "RPN83P")
.list

;-----------------------------------------------------------------------------

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

; Flags that indicate the need to re-draw the display. These are intended to
; be optimization purposes. In theory, we could eliminate these dirty flags
; without affecting the correctness of the rest of the RPN83P app.
dirtyFlags equ asm_Flag1
dirtyFlagsInput equ 0 ; set if the input buffer is dirty
dirtyFlagsStack equ 1 ; set if the stack is dirty
dirtyFlagsMenu equ 2 ; set if the menu selection is dirty
dirtyFlagsTrigMode equ 3 ; set if the trig status is dirty
dirtyFlagsFloatMode equ 4 ; set if the floating mode is dirty
dirtyFlagsBaseMode equ 5 ; set if any base mode flags or vars is dirty
dirtyFlagsErrorCode equ 6 ; set if the error code is dirty ; The dirtyFlagsXLabel flag is set if the 'X:' label is dirty due to the
; command arg mode. The 6x8 cell occupied by the 'X:' label is rendered in
; small-font, which means that it actually uses only 7 rows of pixels from the
; top. During the command arg mode, the cell is replaced by the first letter of
; the label (i.e. "FIX", "SCI", or "ENG"), which is rendered using large font,
; so that first letter consumes 8 rows of pixels. When the command arg mode
; exits, the bottom row of pixels contains artifacts of the command arg mode
; label. The easy solution is to write a large-font space (Lspace) into that
; first cell, then write the "X:" label in small font. But doing this for every
; refresh of that line (e.g. when entering the digits of a number) would cause
; flickering of the "X:" label on every redraw. This flag allows us to optimize
; the redraw algorithm so that the Lspace character *only* when transitioning
; from the command arg mode to normal mode. That would cause a redraw of the
; entire X line, so the slight flicker of the "X:" label should be completely
; imperceptible.
dirtyFlagsXLabel equ 7

; Flags for RPN stack modes. Offset from IY register.
rpnFlags equ asm_Flag2
rpnFlagsEditing equ 0 ; set if in edit mode
rpnFlagsArgMode equ 1 ; set if in command argument mode
rpnFlagsLiftEnabled equ 2 ; set if stack lift is enabled (ENTER disables it)
rpnFlagsAllStatEnabled equ 3 ; set if Sigma+ updates logarithm registers
rpnFlagsBaseModeEnabled equ 4 ; set if inside BASE menu hierarchy

; Flags for the inputBuf. Offset from IY register.
inputBufFlags equ asm_Flag3
inputBufFlagsDecPnt equ 1 ; set if decimal point exists
inputBufFlagsEE equ 2 ; set if EE symbol exists
inputBufFlagsClosedEmpty equ 3 ; inputBuf empty when closeInputBuf() called
inputBufFlagsExpSign equ 4 ; exponent sign bit detected during parsing
inputBufFlagsArgExit equ 5 ; set to exit CommandArg mode
inputBufFlagsArgAllowModifier equ 6 ; allow */-+ modifier in CommandArg mode

;-----------------------------------------------------------------------------
; Application variables and buffers.
;-----------------------------------------------------------------------------

; A random 16-bit integer that identifies the RPN83P app.
rpn83pAppId equ $1E69

; Increment the schema version when any variables are added or removed from the
; appState data block. The schema version will be validated upon restoring the
; application state from the AppVar.
rpn83pSchemaVersion equ 4

; Begin application variables at tempSwapArea. According to the TI-83 Plus SDK
; docs: "tempSwapArea (82A5h) This is the start of 323 bytes used only during
; Flash ROM loading. If this area is used, avoid archiving variables."
appStateBegin equ tempSwapArea

; CRC16CCITT of the appState data block, not including the CRC itself. 2 bytes.
; This is used only in storeAppState() and restoreAppState(), so in theory, we
; could remove it from here and save it only in the RPN83SAV AppVar. The
; advantage of duplicating the CRC here is that the content of the AppVar
; becomes *exactly* the same as this appState data block, so the serialization
; and deserialization code becomes almost trivial. Two bytes is not a large
; amount of memory, so let's keep things simple and duplicate the CRC field
; here.
appStateCrc16 equ appStateBegin

; A somewhat unique id to distinguish this app from other apps. 2 bytes.
; Similar to the 'appStateCrc16' field, this does not need to be in the
; appState data block. But this simplifies the serialization code.
appStateAppId equ appStateCrc16 + 2

; Schema version. 2 bytes. If we overflow the 16-bits, it's probably ok because
; schema version 0 was probably created so far in the past the likelihood of a
; conflict is minimal. However, if the overflow does cause a problem, there is
; an escape hatch: we can create a new appStateAppId upon overflow. Similar to
; AppStateAppId and appStateCrc16, this field does not need to be here, but
; having it here simplifies the serialization code.
appStateSchemaVersion equ appStateAppId + 2

; Copy of the 3 asm_FlagN flags. These will be serialized into RPN83SAV by
; storeAppState(), and deserialized into asm_FlagN by restoreAppState().
appStateDirtyFlags equ appStateSchemaVersion + 2
appStateRpnFlags equ appStateDirtyFlags + 1
appStateInputBufFlags equ appStateRpnFlags + 1

; The result code after the execution of each handler. Success is code 0. If a
; TI-OS exception is thrown (through a `bcall(ErrXxx)`), the exception handler
; places a system error code into here. Before calling a handler, set this to 0
; because vast majority of handlers will not explicitly set handlerCode to 0
; upon success. (This makes coding easier because a successful handler can
; simply do a `ret` or a conditional `ret`.) A few handlers will set a custom,
; non-zero code to indicate an error.
handlerCode equ appStateInputBufFlags + 1

; The errorCode is displayed on the LCD screen if non-zero. This is set to the
; value of handlerCode after every execution of a handler. Inside a handler,
; the errorCode will be the handlerCode of the previous handler. This is useful
; for the CLEAR handler which will simply clear the displayed errorCode if
; non-zero.
errorCode equ handlerCode + 1

; Current base mode number. Allowed values are: 2, 8, 10, 16. Anything else is
; interpreted as 10.
baseNumber equ errorCode + 1

; Base mode carry flag. Bit 0.
baseCarryFlag equ baseNumber + 1

; Base mode word size: 8, 16, 24, 32 (maybe 40 in the future).
baseWordSize equ baseCarryFlag + 1

; String buffer for keyboard entry. This is a Pascal-style with a single size
; byte at the start. It does not include the cursor displayed at the end of the
; string. The equilvalent C struct is:
;
;   struct inputBuf {
;       uint8_t size;
;       char buf[14];
;   };
inputBuf equ baseWordSize + 1
inputBufSize equ inputBuf ; size byte of the pascal string
inputBufBuf equ inputBuf + 1
inputBufMax equ 14 ; maximum size of buffer, not including appended cursor
inputBufSizeOf equ inputBufMax + 1

; When the inputBuf is used as a command argBuf, the maximum number of
; characters in the buffer is 2.
argBuf equ inputBuf
argBufSize equ inputBufSize
argBufMax equ inputBufMax
argBufSizeMax equ 2

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
;       char man[14];  // mantissa, implicit starting decimal point
;   }
;
; A TI-OS floating number can have a mantissa of a maximum 14 digits.
parseBuf equ inputBufEELen + 1
parseBufSize equ parseBuf ; size byte of the pascal string
parseBufMan equ parseBufSize + 1
parseBufMax equ 14
parseBufSizeOf equ parseBufMax + 1

; Menu variables. The C equivalent is:
;
;   struct menu {
;     uint8_t groupId; // id of the current menu group
;     uint8_t rowIndex; // menu row, groups of 5
;   }
menuGroupId equ parseBuf + parseBufSizeOf
menuRowIndex equ menuGroupId + 1

; Menu name, copied here as a Pascal string.
;
;   struct menuName {
;       uint8_t size;
;       char buf[5];
;   }
menuName equ menuRowIndex + 1
menuNameSize equ menuName
menuNameBuf equ menuName + 1
menuNameBufMax equ 5
menuNameSizeOf equ 6

; Data structure revelant to the command argument parser which handles
; something like "STO _ _". The C equivalent is:
;
;   struct argParser {
;       char *argPrompt; // e.g. "STO"
;       // modifier/status:
;       // - 0: no modifier
;       // - 1: indirect
;       // - 2: '+'
;       // - 3: '-'
;       // - 4: '*'
;       // - 5: '/'
;       // - 6+: canceled
;       char argModifier;
;       uint8_t argValue;
;   }
argPrompt equ menuName + menuNameSizeOf
argModifier equ argPrompt + 2
argValue equ argModifier + 1
argModifierNone equ 0
argModifierIndirect equ 1
argModifierAdd equ 2
argModifierSub equ 3
argModifierMul equ 4
argModifierDiv equ 5
argModifierCanceled equ 6

; Least square curve fit model.
curveFitModel equ argValue + 1

; End application variables.
appStateEnd equ curveFitModel + 1

; Total size of vars
appStateSize equ (appStateEnd - appStateBegin)

; Floating point number buffer, used only within parseNumBase10(). It is used
; only locally so it can probaly be anywhere. Let's just use OP3 instead of
; dedicating space within the appState area, because it does not need to be
; backed up. I think any OPx register except OP1 will work.
;
;   struct floatBuf {
;       uint8_t type;
;       uint8_t exp;
;       uint8_t man[7];
;   }
floatBuf equ OP3
floatBufType equ floatBuf ; type
floatBufExp equ floatBufType + 1 ; exponent, shifted by $80
floatBufMan equ floatBufExp + 1 ; mantissa, 2 digits per byte
floatBufSizeOf equ 9

;-----------------------------------------------------------------------------

; Commented out, not needed for flash app.
; .org userMem - 2
; .db t2ByteTok, tAsmCmp

main:
    bcall(_RunIndicOff)
    res appAutoScroll, (iy + appFlags) ; disable auto scroll
    res appTextSave, (iy + appFlags) ; disable shawdow text
    res lwrCaseActive, (iy + appLwrCaseFlag) ; disable ALPHA-ALPHA lowercase
    bcall(_ClrLCDFull)

    call restoreAppState
    jr nc, initAlways
    ; Initialize everything if restoreAppState() fails.
    call initErrorCode
    call initInputBuf
    call initStack
    call initRegs
    call initMenu
    call initBase
    call initStat
    call initCfit
initAlways:
    ; Initialize the following onlky if restoreAppState() suceeds.
    call initArgBuf ; Start with Command Arg parser off.
    call initLastX ; Always copy TI-OS 'ANS' to 'X'
    call initDisplay ; Always initialize the display.

    ; Initialize the App monitor so that we can intercept the Put Away (2ND
    ; OFF) signal.
    ld hl, appVectors
    bcall(_AppInit)
    ; [[fall through]]

; The main event/read loop. Read button and dispatch to the appropriate
; handler. Some of the functionalities are:
;
;   - 2ND-QUIT: quit app
;   - 0-9: add to input buffer
;   - . and (-): add to input buffer
;   - , or 2nd-EE: add scientific notation 'E'
;   - DEL: removes the last character in the input buffer
;   - CLEAR: remove RPN stack X register, or clear the input buffer
;
; See 83pa28d/week2/day12.
readLoop:
    ; call debugFlags
    call displayAll

    ; Set the handler code initially to 0.
    xor a
    ld (handlerCode), a

    ; Get the key code, and reset the ON flag right after. See TI-83 Plus SDK
    ; guide, p. 69. If this flag is not reset, then the next bcall(_DispHL)
    ; causes subsequent bcall(_GetKey) to always return 0. Interestingly, if
    ; the flag is not reset, but the next call is another bcall(_GetKey), then
    ; it sort of seems to work. Except that upon exiting, the TI-OS displays an
    ; Quit/Goto error message.
    bcall(_GetKey)
    res onInterrupt, (iy + onFlags)

    ; Check for 2nd-Quit to Quit. ON (0) triggers the handleKeyExit() to
    ; emulate the ON/EXIT key on the HP 42S which exits nested menus on that
    ; calculator.
    cp kQuit
    jr z, mainExit

    ; Install error handler
    ld hl, readLoopException
    call APP_PUSH_ERRORH
    ; Handle the normal buttons or the menu F1-F5 buttons.
    call lookupKey
    ; Uninstall error handler
    call APP_POP_ERRORH

    ; Transfer the handler code to errorCode.
    ld a, (handlerCode)
readLoopSetErrorCode:
    call setErrorCode
    jr readLoop

readLoopException:
    ; Handle system exception. Register A contains the system error code.
    call setHandlerCodeToSystemCode
    jr readLoopSetErrorCode

; Clean up and exit app.
;   - Called explicitly upon 2ND QUIT.
;   - Called by TI-OS application monitor upon 2ND OFF.
mainExit:
    call rclX
    bcall(_StoAns) ; transfer RPN83P 'X' to TI-OS 'ANS'
    call storeAppState
    set appAutoScroll, (iy + appFlags)
    ld (iy + textFlags), 0 ; reset text flags
    bcall(_ClrLCDFull)
    bcall(_HomeUp)

    bcall(_ReloadAppEntryVecs) ; App Loader in control of monitor
    bit monAbandon, (iy + monFlags) ; if turning off: ZF=1
    jr nz, appTurningOff
    ; If not turning off, then force control back to the home screen.
    ; Note: this will terminate the link activity that caused the application
    ; to be terminated.
    ld a, iAll ; all interrupts on
    out (intrptEnPort), a
    bcall(_LCD_DRIVERON) ; turn on the LCD
    set onRunning, (iy + onFlags) ; on interrupt running
    ei ; enable interrupts
    bjump(_JForceCmdNoChar) ; force to home screen
appTurningOff:
    bjump(_PutAway) ; force App locader to do its put away

; Set up the AppVectors so that we can intercept the Put Away Notification upon
; '2ND QUIT' or '2ND OFF'. See TI-83 Plus SDK documentation.
appVectors:
    .dw dummyVector
    .dw dummyVector
    .dw mainExit
    .dw dummyVector
    .dw dummyVector
    .dw dummyVector
    .db appTextSaveF

dummyVector:
    ret

;-----------------------------------------------------------------------------

#include "vars.asm"
#include "handlers.asm"
#include "argparser.asm"
#include "arghandlers.asm"
#include "pstring.asm"
#include "input.asm"
#include "display.asm"
#include "errorcode.asm"
#include "base.asm"
#include "basehandlers.asm"
#include "integer.asm"
#include "menu.asm"
#include "menuhandlers.asm"
#include "stathandlers.asm"
#include "cfithandlers.asm"
#include "prime.asm"
#include "common.asm"
#include "print.asm"
#include "crc.asm"
#include "const.asm"
#include "handlertab.asm"
#include "arghandlertab.asm"
#include "menudef.asm"
#ifdef DEBUG
#include "debug.asm"
#endif

.end

;-----------------------------------------------------------------------------

; Not sure if this needs to go before or after the `.end`.
validate()
