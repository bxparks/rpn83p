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
.list

;-----------------------------------------------------------------------------
; TI-OS related constants.
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
; Menu keys after 2ND key.
keyMenuSecond1 equ kSPlot
keyMenuSecond2 equ kTblSet
keyMenuSecond3 equ kFormat
keyMenuSecond4 equ kCalc
keyMenuSecond5 equ kTable

; Define font sizes
smallFontHeight equ 7
largeFontHeight equ 8

;-----------------------------------------------------------------------------
; RPN83P flags, using asm_Flag1, asm_Flag2, and asm_Flag3
;-----------------------------------------------------------------------------

; Flags that indicate the need to re-draw the display. These are intended to
; be optimization purposes. In theory, we could eliminate these dirty flags
; without affecting the correctness of the rest of the RPN83P app.
dirtyFlags equ asm_Flag1
dirtyFlagsInput equ 0 ; set if the inputBuf or argBuf is dirty
dirtyFlagsStack equ 1 ; set if the RPN stack is dirty
dirtyFlagsMenu equ 2 ; set if the menu selection is dirty
; TODO: Combine Trig, Float, and Base into a single 'dirtyFlagsStatus' bit.
dirtyFlagsTrigMode equ 3 ; set if the trig status is dirty
dirtyFlagsFloatMode equ 4 ; set if the floating mode is dirty
dirtyFlagsBaseMode equ 5 ; set if any base mode flags or vars is dirty
dirtyFlagsErrorCode equ 6 ; set if the error code is dirty
; The dirtyFlagsXLabel flag is set if the 'X:' label is dirty due to the
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
; rpnFlagsSecondKey: Set if the 2ND was pressed before a menu button. Most
; handlers can ignore this, but some handlers may choose to check this flag to
; implement additional functionality.
rpnFlagsSecondKey equ 5
rpnFlagsTvmCalculate equ 6 ; set if the next TVM function should calculate

; Flags for the inputBuf. Offset from IY register.
inputBufFlags equ asm_Flag3
inputBufFlagsDecPnt equ 1 ; set if decimal point exists
inputBufFlagsEE equ 2 ; set if EE symbol exists
inputBufFlagsClosedEmpty equ 3 ; inputBuf empty when closeInputBuf() called
inputBufFlagsExpSign equ 4 ; exponent sign bit detected during parsing
inputBufFlagsArgExit equ 5 ; set to exit CommandArg mode
inputBufFlagsArgAllowModifier equ 6 ; allow */-+ modifier in CommandArg mode

;-----------------------------------------------------------------------------
; RPN83P application variables and buffers.
;-----------------------------------------------------------------------------

; A random 16-bit integer that identifies the RPN83P app.
rpn83pAppId equ $1E69

; Increment the schema version when any variables are added or removed from the
; appState data block. The schema version will be validated upon restoring the
; application state from the AppVar.
rpn83pSchemaVersion equ 9

; Define true and false. Something else in spasm-ng defines the 'true' and
; 'false' symbols but I cannot find the definitions for them in the
; "ti83plus.inc" file. So maybe they are defined by the assembler itself?
; Regardless, I don't know what their values are, so I will explicitly define
; my own boolean values.
rpnfalse equ 0
rpntrue equ 1

;-----------------------------------------------------------------------------

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
;       char argModifier; // see argModifierXxx
;       uint8_t argValue;
;   }
; The argModifierXxx (0-4) MUST match the corresponding operation in the
; 'floatOps' array in vars.asm.
argPrompt equ menuName + menuNameSizeOf
argModifier equ argPrompt + 2
argValue equ argModifier + 1
argModifierNone equ 0
argModifierAdd equ 1 ; '+' pressed
argModifierSub equ 2 ; '-' pressed
argModifierMul equ 3 ; '*' pressed
argModifierDiv equ 4 ; '/' pressed
argModifierIndirect equ 5 ; '.' pressed (not yet supported)
argModifierCanceled equ 6 ; CLEAR or EXIT pressed

; Least square curve fit model.
curveFitModel equ argValue + 1

; Constants used by the TVM Solver.
tvmSolverDefaultIterMax equ 15
; tvmSolverResult enums indicate success or failure of the TVM Solver.
tvmSolverResultFound equ 0
tvmSolverResultNotFound equ 1
tvmSolverResultIterMaxed equ 2
tvmSolverResultBreak equ 3
; Bit position in tvmSolverOverrideFlags that determine if a specific parameter
; has been overridden.
tvmSolverOverrideFlagIYR0 equ 0
tvmSolverOverrideFlagIYR1 equ 1
tvmSolverOverrideFlagIterMax equ 2

; TVM variables for root-solving the NPMT(i)=0 equation.
tvmIsBegin equ curveFitModel + 1 ; boolean; true if payment is at BEGIN
; The tvmSolverOverrideFlags is a collection of bit flags. Each flag determines
; whether a particular parameter that controls the TVM Solver execution has its
; default value overridden by a manual value from the user.
tvmSolverOverrideFlags equ tvmIsBegin + 1 ; u8 flag
; TVM Solver configuration parameters. These are normally defined automatically
; but can be overridden using the 'IYR0', 'IYR1', and 'TMAX' menu buttons.
tvmIYR0 equ tvmSolverOverrideFlags + 1 ; float
tvmIYR1 equ tvmIYR0 + 9 ; float
tvmIterMax equ tvmIYR1 + 9 ; u8 integer

; Draw/Debug mode constants
drawModeNormal equ 0
drawModeTvmSolverI equ 1 ; show i0, i1
drawModeTvmSolverF equ 2 ; show npmt0, npmt1

; Draw/Debug mode, u8 integer. Activated by secret '2ND DRAW' button.
; - 0: normal
; - 1: TVM Solver i0, i1 values
; - 2: TVM Solver f0, f1 values
drawMode equ tvmIterMax + 1

; End application variables.
appStateEnd equ drawMode + 1

; Total size of vars
appStateSize equ (appStateEnd - appStateBegin)

;-----------------------------------------------------------------------------
; Temporary buffers which do NOT need to be saved to an app var.
;-----------------------------------------------------------------------------

appBufferStart equ appStateEnd

; FindMenuNode() copies the matching menuNode from menudef.asm (in flash page 1)
; to here so that routines in flash page 0 can access the information.
menuNodeBuf equ appBufferStart ; 9 bytes, defined by menuNodeSizeOf

; FindMenuString() copies the name of the menu from flash page 1 to here so that
; routines in flash page 0 can access it. This is named 'menuStringBuf' to
; avoid conflicting with the existing 'menuNameBuf' which is a Pascal-string
; version of 'menuStringBuf'.
menuStringBuf equ menuNodeBuf + 9 ; 6 bytes
menuStringBufSizeOf equ 6

; TVM Solver needs a bunch of workspace variables: interest rate, i0 and i1,
; plus the next interest rate i2, and the value of the NPMT() function at each
; of those points. Transient, so no need to persist them.
tvmI0 equ menuStringBuf + menuStringBufSizeOf ; float
tvmI1 equ tvmI0 + 9 ; float
tvmNPMT0 equ tvmI1 + 9 ; float
tvmNPMT1 equ tvmNPMT0 + 9 ; float
; TVM Solver status and result code. Transient, no need to persist them.
tvmSolverIsRunning equ tvmNPMT1 + 9 ; boolean; true if active
tvmSolverCount equ tvmSolverIsRunning + 1 ; u8; iteration count
tvmSolverResult equ tvmSolverCount + 1 ; u8 enum; tvmSolverResultXxx

appBufferEnd equ tvmSolverResult + 1

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
; Flash Page 0
;
; See "Appendix A: Creating Flash Applications with SPASM" of "Hot Dog's TI-83
; z80 ASM For The Absolute Beginner" to information on creating flash
; applications using multiple pages.
;-----------------------------------------------------------------------------

defpage(0, "RPN83P")

; Start of program.
    jp main ; must be a 'jp' to get correct alignment of the branch table
    .db 0 ; pad one byte so that Branch Table starts at address multiple of 3

; Branch table here.
_processHelp equ (44+0)*3
    .dw ProcessHelp
    .db 1
_findMenuNode equ (44+1)*3
    .dw FindMenuNode
    .db 1
_findMenuString equ (44+2)*3
    .dw FindMenuString
    .db 1

#include "main.asm"
#include "mainparser.asm"
#include "handlers.asm"
#include "argparser.asm"
#include "arghandlers.asm"
#include "vars.asm"
#include "pstring.asm"
#include "input.asm"
#include "display.asm"
#include "errorcode.asm"
#include "base.asm"
#include "basehandlers.asm"
#include "menu.asm"
#include "menuhandlers.asm"
#include "stathandlers.asm"
#include "cfithandlers.asm"
#include "tvmhandlers.asm"
#include "prime.asm"
#include "common.asm"
#include "integer.asm"
#include "float.asm"
#include "print.asm"
#include "crc.asm"
#include "const.asm"
#include "handlertab.asm"
#include "arghandlertab.asm"
#ifdef DEBUG
#include "debug.asm"
#endif

;-----------------------------------------------------------------------------
; Flash Page 1
;-----------------------------------------------------------------------------

defpage(1)

#include "help.asm"
#include "menulookup.asm"
#include "menudef.asm"

.end

;-----------------------------------------------------------------------------

; Not sure if this needs to go before or after the `.end`.
validate()
