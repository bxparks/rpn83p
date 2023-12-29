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
signChar equ Lneg ; different from Ldash ('-'), or Lhyphen

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
dirtyFlagsStatus equ 3 ; set if anything on the status line is dirty
dirtyFlagsErrorCode equ 4 ; set if the error code is dirty
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
; the redraw algorithm so that the Lspace character is printed to overwrite the
; label *only* when transitioning from the command arg mode to normal mode.
; That would cause a redraw of the entire X line, so the slight flicker of the
; "X:" label should be completely imperceptible.
dirtyFlagsXLabel equ 5

; Flags for RPN stack modes. Offset from IY register.
rpnFlags equ asm_Flag2
rpnFlagsEditing equ 0 ; set if in edit mode
rpnFlagsArgMode equ 1 ; set if in command argument mode
rpnFlagsLiftEnabled equ 2 ; set if stack lift is enabled (ENTER disables it)
rpnFlagsShowModeEnabled equ 3 ; set if SHOW mode enabled
rpnFlagsBaseModeEnabled equ 4 ; set if inside BASE menu hierarchy
; rpnFlagsSecondKey: Set if the 2ND was pressed before a menu button. Most
; handlers can ignore this, but some handlers may choose to check this flag to
; implement additional functionality.
rpnFlagsSecondKey equ 5
rpnFlagsTvmCalculate equ 6 ; set if the next TVM function should calculate

; Flags for the inputBuf. Offset from IY register.
inputBufFlags equ asm_Flag3
inputBufFlagsDecPnt equ 0 ; set if decimal point exists
inputBufFlagsEE equ 1 ; set if EE symbol exists
inputBufFlagsClosedEmpty equ 2 ; inputBuf empty when closeInput() called
inputBufFlagsExpSign equ 3 ; exponent sign bit detected during parsing
inputBufFlagsArgExit equ 4 ; set to exit CommandArg mode
inputBufFlagsArgAllowModifier equ 5 ; allow */-+ modifier in CommandArg mode

;-----------------------------------------------------------------------------
; RPN83P application variables and buffers.
;-----------------------------------------------------------------------------

; A random 16-bit integer that identifies the RPN83P app.
rpn83pAppId equ $1E69

; Increment the schema version if the previously saved app variable 'RPN83SAV'
; should be marked as stale during validation. This will cause the app to
; initialize to the factory defaults. When an variable is added or deleted, the
; version does not absolutely need to be incremented, because the value of
; appStateSize will be checked, and since it will be different, the previous
; state is considered stale automatically. However, if the *semantics* of any
; variable is changed (e.g. if the meaning of a flag is changed), then we
; *must* increment the version number to mark the previous state as stale.
rpn83pSchemaVersion equ 9

; Define true and false. Something else in spasm-ng defines the 'true' and
; 'false' symbols but I cannot find the definitions for them in the
; "ti83plus.inc" file. So maybe they are defined by the assembler itself?
; Regardless, I don't know what their values are, so I will explicitly define
; my own boolean values.
rpnfalse equ 0
rpntrue equ 1

; Stack and register type enums.
rpnObjectTypeReal equ 0
rpnObjectTypeComplex equ $C ; same as TI-OS
rpnObjectTypeComplexDeg equ $2C ; uses bit 5 and 6
rpnObjectTypeComplexRad equ $4C ; uses bit 5 and 6
rpnObjectTypeMask equ $1F ; TI-OS type uses only bits 0-4
rpnObjectSizeOf equ 32
rpnRealSizeOf equ 9 ; sizeof(float)
rpnComplexSizeOf equ 18 ; sizeof(complex)

;-----------------------------------------------------------------------------

; Begin application variables at tempSwapArea. According to the TI-83 Plus SDK
; docs: "tempSwapArea (82A5h) This is the start of 323 bytes used only during
; Flash ROM loading. If this area is used, avoid archiving variables."
appStateBegin equ tempSwapArea

; CRC16CCITT of the appState data block, not including the CRC itself. 2 bytes.
; This is used only in StoreAppState() and RestoreAppState(), so in theory, we
; could remove it from here and save it only in the RPN83SAV AppVar. The
; advantage of duplicating the CRC here is that the content of the AppVar
; becomes *exactly* the same as this appState data block, so the serialization
; and deserialization code becomes almost trivial. Two bytes is not a large
; amount of memory, so let's keep things simple and duplicate the CRC field
; here.
appStateCrc16 equ appStateBegin ; u16

; A somewhat unique id to distinguish this app from other apps. 2 bytes.
; Similar to the 'appStateCrc16' field, this does not need to be in the
; appState data block. But this simplifies the serialization code.
appStateAppId equ appStateCrc16 + 2 ; u16

; Schema version. 2 bytes. If we overflow the 16-bits, it's probably ok because
; schema version 0 was probably created so far in the past the likelihood of a
; conflict is minimal. However, if the overflow does cause a problem, there is
; an escape hatch: we can create a new appStateAppId upon overflow. Similar to
; AppStateAppId and appStateCrc16, this field does not need to be here, but
; having it here simplifies the serialization code.
appStateSchemaVersion equ appStateAppId + 2 ; u16

; Copy of the 3 asm_FlagN flags. These will be serialized into RPN83SAV by
; StoreAppState(), and deserialized into asm_FlagN by RestoreAppState().
appStateDirtyFlags equ appStateSchemaVersion + 2 ; u8
appStateRpnFlags equ appStateDirtyFlags + 1 ; u8
appStateInputBufFlags equ appStateRpnFlags + 1 ; u8

; The result code after the execution of each handler. Success is code 0. If a
; TI-OS exception is thrown (through a `bcall(ErrXxx)`), the exception handler
; places a system error code into here. Before calling a handler, set this to 0
; because vast majority of handlers will not explicitly set handlerCode to 0
; upon success. (This makes coding easier because a successful handler can
; simply do a `ret` or a conditional `ret`.) A few handlers will set a custom,
; non-zero code to indicate an error.
handlerCode equ appStateInputBufFlags + 1 ; u8

; The errorCode is displayed on the LCD screen if non-zero. This is set to the
; value of handlerCode after every execution of a handler. Inside a handler,
; the errorCode will be the handlerCode of the previous handler. This is useful
; for the CLEAR handler which will simply clear the displayed errorCode if
; non-zero.
errorCode equ handlerCode + 1 ; u8

; Current base mode number. Allowed values are: 2, 8, 10, 16. Anything else is
; interpreted as 10.
baseNumber equ errorCode + 1 ; u8

; Base mode carry flag. Bit 0.
baseCarryFlag equ baseNumber + 1 ; boolean

; Base mode word size: 8, 16, 24, 32 (maybe 40 in the future).
baseWordSize equ baseCarryFlag + 1 ; u8

; String buffer for keyboard entry. In normal floating point entry mode, we
; need 20 characters (see inputBufNormalMaxLen below). But to support 32-bit
; base-2 numbers, we need 32 characters. Let's set this to 32.
;
; This is a Pascal-style with a single size byte at the start. It does not
; include the cursor displayed at the end of the string. The equilvalent C
; struct is:
;
;   struct InputBuf {
;       uint8_t len;
;       char buf[inputBufCapacity];
;   };
inputBuf equ baseWordSize + 1 ; struct InputBuf
inputBufLen equ inputBuf ; len byte of the pascal string
inputBufBuf equ inputBuf + 1
inputBufCapacity equ 32 ; excludes trailing cursor
inputBufSizeOf equ inputBufCapacity + 1 + 1 ; extra space for NUL terminator

; The TI-OS floating point number supports 14 significant digits, but we need 6
; more characters to hold the optional mantissa minus sign, the optional
; decimal point, the optional 'E' symbol for the exponent, the 2-digit
; exponent, and the optional minus sign on the exponent. That's a total of 20
; characters.
inputBufNormalMaxLen equ 20

; When the inputBuf is used as a command argBuf, the maximum number of
; characters in the buffer is 2.
argBuf equ inputBuf ; struct InputBuf
argBufLen equ inputBufLen
argBufCapacity equ inputBufCapacity
argBufSizeMax equ 2 ; max number of digits accepted on input

; Location (offset index) of the one past the 'E' symbol if it exists. Zero
; indicates that 'E' does NOT exist.
inputBufEEPos equ inputBuf + inputBufSizeOf ; u8
; Length of EE digits. Maximum of 2.
inputBufEELen equ inputBufEEPos + 1 ; u8
; Max number of digits allowed for exponent.
inputBufEELenMax equ 2

; Temporary buffer for parsing keyboard input into a floating point number.
; When the app is in BASE mode, the inputBuf is parsed directly, and this
; buffer is not used. In normal floating point mode, each mantissa digit is
; converted into this data structure, one byte per digit, before being
; converted into the packed floating point number format used by TI-OS.
;
; The decimal point will not appear explicitly here because it is implicitly
; present just before the first digit. The inputBuf can hold more than 14
; digits, but those extra digits will be ignored when parsed into this data
; structure.
;
; This is a Pascal string whose equivalent C struct is:
;
;   struct ParseBuf {
;       uint8_t len; // number of digits in mantissa, 0 for 0.0
;       char man[14];  // mantissa, implicit starting decimal point
;   }
parseBuf equ inputBufEELen + 1 ; struct ParseBuf
parseBufLen equ parseBuf ; len byte of the pascal string
parseBufMan equ parseBufLen + 1
parseBufCapacity equ 14
parseBufSizeOf equ parseBufCapacity + 1

; Menu variables. Two variables determine the current state of the menu, the
; groupId and the rowIndex in the group. The C equivalent is:
;
;   struct Menu {
;     uint8_t groupId; // id of the current menu group
;     uint8_t rowIndex; // menu row, groups of 5
;   }
menuGroupId equ parseBuf + parseBufSizeOf ; u8
menuRowIndex equ menuGroupId + 1 ; u8

; These variables remember the previous menuGroup/row pair when a shortcut was
; pressed to another menuGroup. On the ON/EXIT button is pressed, we can then
; go back to the previous menu, instead of going up to the parent of the menu
; invoked by the shortcut button. Not all shortcuts will choose to use this
; feature. Currently (v0.7.0), only the MODE button seems to be a good
; candidate. If jumpBackMenuGroupId is 0, then the memory feature is not
; active. If it is not 0, then the ON/EXIT button should go back to the menu
; defined by this pair.
jumpBackMenuGroupId equ menuRowIndex + 1 ; u8
jumpBackMenuRowIndex equ jumpBackMenuGroupId + 1 ; u8

; Menu name, copied here as a Pascal string.
;
;   struct MenuName {
;       uint8_t len;
;       char buf[5];
;   }
menuName equ jumpBackMenuRowIndex + 1 ; struct menuName
menuNameSize equ menuName
menuNameBuf equ menuName + 1
menuNameBufMax equ 5
menuNameSizeOf equ 6

; Data structure revelant to the command argument parser which handles
; something like "STO _ _". The C equivalent is:
;
;   struct ArgParser {
;       char *argPrompt; // e.g. "STO"
;       char argModifier; // see argModifierXxx
;       uint8_t argValue;
;   }
; The argModifierXxx (0-4) MUST match the corresponding operation in the
; 'floatOps' array in vars.asm.
argPrompt equ menuName + menuNameSizeOf ; (char*)
argModifier equ argPrompt + 2 ; char
argValue equ argModifier + 1 ; u8
argModifierNone equ 0
argModifierAdd equ 1 ; '+' pressed
argModifierSub equ 2 ; '-' pressed
argModifierMul equ 3 ; '*' pressed
argModifierDiv equ 4 ; '/' pressed
argModifierIndirect equ 5 ; '.' pressed (not yet supported)
argModifierCanceled equ 6 ; CLEAR or EXIT pressed

; STAT variables
statAllEnabled equ argValue + 1 ; boolean, 1 if "ALLSigma" enabled
; Least square CFIT model.
curveFitModel equ statAllEnabled + 1 ; u8

; Constants used by the TVM Solver.
tvmSolverDefaultIterMax equ 15
; tvmSolverResult enums indicate if the solver should stop or continue the
; iterations
tvmSolverResultContinue equ 0 ; loop should continue
tvmSolverResultFound equ 1
tvmSolverResultNoSolution equ 2
tvmSolverResultNotFound equ 3
tvmSolverResultIterMaxed equ 4
tvmSolverResultBreak equ 5
tvmSolverResultSingleStep equ 6 ; return after each iteration
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
tvmIterMax equ tvmIYR1 + 9 ; u8

; Draw mode constants
drawModeNormal equ 0
drawModeTvmSolverI equ 1 ; show i0, i1
drawModeTvmSolverF equ 2 ; show npmt0, npmt1
drawModeInputBuf equ 3 ; show inputBuf in debug line

; Draw/Debug mode, u8 integer. Activated by secret '2ND DRAW' button.
drawMode equ tvmIterMax + 1 ; u8

; Function result modes determines whether certain functions return real
; results always, or will sometimes return a complex result.
numResultModeReal equ 0 ; return real results only
numResultModeComplex equ 1 ; return complex results
numResultMode equ drawMode + 1 ; u8

; Complex number display modes. The 2 complex polar mode (RAD and DEG) are
; explicitly separate from the DEG and RAD settings that affect trigonometric
; functions.
complexModeRect equ 0
complexModeRad equ 1
complexModeDeg equ 2
complexMode equ numResultMode + 1 ; u8

; End application variables.
appStateEnd equ complexMode + 1

; Total size of appState vars.
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
menuStringBuf equ menuNodeBuf + 9 ; char[6]
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

; A Pascal-string that contains the rendered version of inputBuf, truncated and
; formatted as needed, which can be printed on the screen.
;
; The C structure is:
;
; struct InputDisplay {
;   uint8_t len;
;   char buf[14];
; };
inputDisplay equ tvmSolverCount + 1 ; struct InputDisplay; Pascal-string
inputDisplayLen equ inputDisplay ; len byte of the string
inputDisplayBuf equ inputDisplay + 1 ; start of actual buffer
inputDisplayCapacity equ 14 ; 14-characters displayed, excluding trailing cursor
inputDisplaySizeOf equ inputDisplayCapacity + 1 ; total size of data structure

; Set of bit-flags that remember whether an RPN stack display line was rendered
; in large or small font. We can optimize the drawing algorithm by performing a
; pre-clear of the line only when the rendering transitions from a large font
; to a small font. This prevents unnecessary flickering of the RPN stack line.
; Normally large fonts are used so a cleared bit means large font. A set flag
; means small font.
displayStackFontFlagsX equ 1
displayStackFontFlagsY equ 2
displayStackFontFlagsZ equ 4
displayStackFontFlagsT equ 8
displayStackFontFlags equ inputDisplay + inputDisplaySizeOf ; u8

appBufferEnd equ rpnStackFontFlags + 1

; Total size of appBuffer.
appBufferSize equ appBufferEnd-appBufferStart

; Floating point number buffer, used only within parseNumBase10(). It is used
; only locally so it can probaly be anywhere. Let's just use OP3 instead of
; dedicating space within the appState area, because it does not need to be
; backed up. I think any OPx register except OP1 will work.
;
;   struct FloatBuf {
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
; Validate that app memory buffers do not overflow the assigned RAM area.
; According to the TI-83 Plus SDK docs: "tempSwapArea (82A5h) This is the start
; of 323 bytes used only during Flash ROM loading. If this area is used, avoid
; archiving variables."
;-----------------------------------------------------------------------------

; Print out the sizes of various sections.
appMemSize equ appStateSize+appBufferSize
appMemMax equ 323
.echo "App State Size: ", appStateSize
.echo "App Buffer Size: ", appBufferSize
.echo "App Mem Size: ", appMemSize, " (max ", appMemMax, ")"

; Make sure that appStateSize+appBufferSize <= appMemMax
#if appMemSize > appMemMax
  .error "App Mem Size ", appMemSize, " > ", appMemMax, " bytes"
#endif

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

; Branch table here. The spasm-ng documentation in Appendix A mentioned above
; recommends that each bcall() entry is defined by the expression `(44+n)*3`
; where `n` starts at 0 and increments by one for each entry. The problem with
; that method is that it becomes a chore to maintain the correct `n` index when
; entries are added or removed.
;
; Instead, let's define the bcall() labels as offsets from start of flash page,
; $4000. When entries are added or removed, all the labels are automatically
; updated. Warning: spasm-ng cannot handle forward references in `equ`
; statements, so we have to define the bcall() label *after* the XxxLabel
; label.
branchTableBase equ $4000
; appstate.asm
_StoreAppStateLabel:
_StoreAppState equ _StoreAppStateLabel-branchTableBase
    .dw StoreAppState
    .db 1
_RestoreAppStateLabel:
_RestoreAppState equ _RestoreAppStateLabel-branchTableBase
    .dw RestoreAppState
    .db 1
; help.asm
_ProcessHelpLabel:
_ProcessHelp equ _ProcessHelpLabel-branchTableBase
    .dw ProcessHelp
    .db 1
; menulookup.asm
_FindMenuNodeLabel:
_FindMenuNode equ _FindMenuNodeLabel-branchTableBase
    .dw FindMenuNode
    .db 1
_FindMenuStringLabel:
_FindMenuString equ _FindMenuStringLabel-branchTableBase
    .dw FindMenuString
    .db 1
; crc.asm
_Crc16ccittLabel:
_Crc16ccitt equ _Crc16ccittLabel-branchTableBase
    .dw Crc16ccitt
    .db 1
; errorcode.asm
_InitErrorCodeLabel:
_InitErrorCode equ _InitErrorCodeLabel-branchTableBase
    .dw InitErrorCode
    .db 1
_PrintErrorStringLabel:
_PrintErrorString equ _PrintErrorStringLabel-branchTableBase
    .dw PrintErrorString
    .db 1
_SetErrorCodeLabel:
_SetErrorCode equ _SetErrorCodeLabel-branchTableBase
    .dw SetErrorCode
    .db 1
_SetHandlerCodeFromSystemCodeLabel:
_SetHandlerCodeFromSystemCode equ _SetHandlerCodeFromSystemCodeLabel-branchTableBase
    .dw SetHandlerCodeFromSystemCode
    .db 1
; input1.asm
_InitInputBufLabel:
_InitInputBuf equ _InitInputBufLabel-branchTableBase
    .dw InitInputBuf
    .db 1
_ClearInputBufLabel:
_ClearInputBuf equ _ClearInputBufLabel-branchTableBase
    .dw ClearInputBuf
    .db 1
_CloseInputBufLabel:
_CloseInputBuf equ _CloseInputBufLabel-branchTableBase
    .dw CloseInputBuf
    .db 1
_AppendInputBufLabel:
_AppendInputBuf equ _AppendInputBufLabel-branchTableBase
    .dw AppendInputBuf
    .db 1
; arg1.asm
_ClearArgBufLabel:
_ClearArgBuf equ _ClearArgBufLabel-branchTableBase
    .dw ClearArgBuf
    .db 1
_InitArgBufLabel:
_InitArgBuf equ _InitArgBufLabel-branchTableBase
    .dw InitArgBuf
    .db 1
_AppendArgBufLabel:
_AppendArgBuf equ _AppendArgBufLabel-branchTableBase
    .dw AppendArgBuf
    .db 1
_ParseArgBufLabel:
_ParseArgBuf equ _ParseArgBufLabel-branchTableBase
    .dw ParseArgBuf
    .db 1
; pstring1.asm
_AppendStringLabel:
_AppendString equ _AppendStringLabel-branchTableBase
    .dw AppendString
    .db 1
_InsertAtPosLabel:
_InsertAtPos equ _InsertAtPosLabel-branchTableBase
    .dw InsertAtPos
    .db 1
_DeleteAtPosLabel:
_DeleteAtPos equ _DeleteAtPosLabel-branchTableBase
    .dw DeleteAtPos
    .db 1
; integer1.asm
_ConvertAToOP1PageOneLabel:
_ConvertAToOP1PageOne equ _ConvertAToOP1PageOneLabel-branchTableBase
    .dw ConvertAToOP1PageOne
    .db 1
; tvm.asm
_TvmCalculateNLabel:
_TvmCalculateN equ _TvmCalculateNLabel-branchTableBase
    .dw TvmCalculateN
    .db 1
_TvmSolveLabel:
_TvmSolve equ _TvmSolveLabel-branchTableBase
    .dw TvmSolve
    .db 1
_TvmCalculatePVLabel:
_TvmCalculatePV equ _TvmCalculatePVLabel-branchTableBase
    .dw TvmCalculatePV
    .db 1
_TvmCalculatePMTLabel:
_TvmCalculatePMT equ _TvmCalculatePMTLabel-branchTableBase
    .dw TvmCalculatePMT
    .db 1
_TvmCalculateFVLabel:
_TvmCalculateFV equ _TvmCalculateFVLabel-branchTableBase
    .dw TvmCalculateFV
    .db 1
_TvmCalcIPPFromIYRLabel:
_TvmCalcIPPFromIYR equ _TvmCalcIPPFromIYRLabel-branchTableBase
    .dw TvmCalcIPPFromIYR
    .db 1
_TvmClearLabel:
_TvmClear equ _TvmClearLabel-branchTableBase
    .dw TvmClear
    .db 1
_TvmSolverResetLabel:
_TvmSolverReset equ _TvmSolverResetLabel-branchTableBase
    .dw TvmSolverReset
    .db 1
_RclTvmNLabel:
_RclTvmN equ _RclTvmNLabel-branchTableBase
    .dw RclTvmN
    .db 1
_StoTvmNLabel:
_StoTvmN equ _StoTvmNLabel-branchTableBase
    .dw StoTvmN
    .db 1
_RclTvmIYRLabel:
_RclTvmIYR equ _RclTvmIYRLabel-branchTableBase
    .dw RclTvmIYR
    .db 1
_StoTvmIYRLabel:
_StoTvmIYR equ _StoTvmIYRLabel-branchTableBase
    .dw StoTvmIYR
    .db 1
_RclTvmPVLabel:
_RclTvmPV equ _RclTvmPVLabel-branchTableBase
    .dw RclTvmPV
    .db 1
_StoTvmPVLabel:
_StoTvmPV equ _StoTvmPVLabel-branchTableBase
    .dw StoTvmPV
    .db 1
_RclTvmPMTLabel:
_RclTvmPMT equ _RclTvmPMTLabel-branchTableBase
    .dw RclTvmPMT
    .db 1
_StoTvmPMTLabel:
_StoTvmPMT equ _StoTvmPMTLabel-branchTableBase
    .dw StoTvmPMT
    .db 1
_RclTvmFVLabel:
_RclTvmFV equ _RclTvmFVLabel-branchTableBase
    .dw RclTvmFV
    .db 1
_StoTvmFVLabel:
_StoTvmFV equ _StoTvmFVLabel-branchTableBase
    .dw StoTvmFV
    .db 1
_RclTvmPYRLabel:
_RclTvmPYR equ _RclTvmPYRLabel-branchTableBase
    .dw RclTvmPYR
    .db 1
_StoTvmPYRLabel:
_StoTvmPYR equ _StoTvmPYRLabel-branchTableBase
    .dw StoTvmPYR
    .db 1
_RclTvmIYR0Label:
_RclTvmIYR0 equ _RclTvmIYR0Label-branchTableBase
    .dw RclTvmIYR0
    .db 1
_StoTvmIYR0Label:
_StoTvmIYR0 equ _StoTvmIYR0Label-branchTableBase
    .dw StoTvmIYR0
    .db 1
_RclTvmIYR1Label:
_RclTvmIYR1 equ _RclTvmIYR1Label-branchTableBase
    .dw RclTvmIYR1
    .db 1
_StoTvmIYR1Label:
_StoTvmIYR1 equ _StoTvmIYR1Label-branchTableBase
    .dw StoTvmIYR1
    .db 1
_RclTvmIterMaxLabel:
_RclTvmIterMax equ _RclTvmIterMaxLabel-branchTableBase
    .dw RclTvmIterMax
    .db 1
_StoTvmIterMaxLabel:
_StoTvmIterMax equ _StoTvmIterMaxLabel-branchTableBase
    .dw StoTvmIterMax
    .db 1
_RclTvmI0Label:
_RclTvmI0 equ _RclTvmI0Label-branchTableBase
    .dw RclTvmI0
    .db 1
_StoTvmI0Label:
_StoTvmI0 equ _StoTvmI0Label-branchTableBase
    .dw StoTvmI0
    .db 1
_RclTvmI1Label:
_RclTvmI1 equ _RclTvmI1Label-branchTableBase
    .dw RclTvmI1
    .db 1
_StoTvmI1Label:
_StoTvmI1 equ _StoTvmI1Label-branchTableBase
    .dw StoTvmI1
    .db 1
_RclTvmNPMT0Label:
_RclTvmNPMT0 equ _RclTvmNPMT0Label-branchTableBase
    .dw RclTvmNPMT0
    .db 1
_StoTvmNPMT0Label:
_StoTvmNPMT0 equ _StoTvmNPMT0Label-branchTableBase
    .dw StoTvmNPMT0
    .db 1
_RclTvmNPMT1Label:
_RclTvmNPMT1 equ _RclTvmNPMT1Label-branchTableBase
    .dw RclTvmNPMT1
    .db 1
_StoTvmNPMT1Label:
_StoTvmNPMT1 equ _StoTvmNPMT1Label-branchTableBase
    .dw StoTvmNPMT1
    .db 1
_RclTvmSolverCountLabel:
_RclTvmSolverCount equ _RclTvmSolverCountLabel-branchTableBase
    .dw RclTvmSolverCount
    .db 1
; float1.asm
_LnOnePlusLabel:
_LnOnePlus equ _LnOnePlusLabel-branchTableBase
    .dw LnOnePlus
    .db 1
_ExpMinusOneLabel:
_ExpMinusOne equ _ExpMinusOneLabel-branchTableBase
    .dw ExpMinusOne
    .db 1
; hms.asm
_HmsToHrLabel:
_HmsToHr equ _HmsToHrLabel-branchTableBase
    .dw HmsToHr
    .db 1
_HmsFromHrLabel:
_HmsFromHr equ _HmsFromHrLabel-branchTableBase
    .dw HmsFromHr
    .db 1
; prob.asm
_ProbPermLabel:
_ProbPerm equ _ProbPermLabel-branchTableBase
    .dw ProbPerm
    .db 1
_ProbCombLabel:
_ProbComb equ _ProbCombLabel-branchTableBase
    .dw ProbComb
    .db 1

#ifdef DEBUG
; debug.asm
_DebugInputBufLabel:
_DebugInputBuf equ _DebugInputBufLabel-branchTableBase
    .dw DebugInputBuf
    .db 1
_DebugParseBufLabel:
_DebugParseBuf equ _DebugParseBufLabel-branchTableBase
    .dw DebugParseBuf
    .db 1
_DebugStringLabel:
_DebugString equ _DebugStringLabel-branchTableBase
    .dw DebugString
    .db 1
_DebugPStringLabel:
_DebugPString equ _DebugPStringLabel-branchTableBase
    .dw DebugPString
    .db 1
_DebugClearLabel:
_DebugClear equ _DebugClearLabel-branchTableBase
    .dw DebugClear
    .db 1
_DebugOP1Label:
_DebugOP1 equ _DebugOP1Label-branchTableBase
    .dw DebugOP1
    .db 1
_DebugEEPosLabel:
_DebugEEPos equ _DebugEEPosLabel-branchTableBase
    .dw DebugEEPos
    .db 1
_DebugUnsignedALabel:
_DebugUnsignedA equ _DebugUnsignedALabel-branchTableBase
    .dw DebugUnsignedA
    .db 1
_DebugSignedALabel:
_DebugSignedA equ _DebugSignedALabel-branchTableBase
    .dw DebugSignedA
    .db 1
_DebugFlagsLabel:
_DebugFlags equ _DebugFlagsLabel-branchTableBase
    .dw DebugFlags
    .db 1
_DebugU32AsHexLabel:
_DebugU32AsHex equ _DebugU32AsHexLabel-branchTableBase
    .dw DebugU32AsHex
    .db 1
_DebugHLLabel:
_DebugHL equ _DebugHLLabel-branchTableBase
    .dw DebugHL
    .db 1
_DebugHLAsHexLabel:
_DebugHLAsHex equ _DebugHLAsHexLabel-branchTableBase
    .dw DebugHLAsHex
    .db 1
_DebugPauseLabel:
_DebugPause equ _DebugPauseLabel-branchTableBase
    .dw DebugPause
    .db 1
_DebugU32DEAsHexLabel:
_DebugU32DEAsHex equ _DebugU32DEAsHexLabel-branchTableBase
    .dw DebugU32DEAsHex
    .db 1
#endif

#include "main.asm"
#include "mainparser.asm"
#include "handlers.asm"
#include "argparser.asm"
#include "arghandlers.asm"
#include "showparser.asm"
#include "vars.asm"
#include "input.asm"
#include "display.asm"
#include "show.asm"
#include "base.asm"
#include "basehandlers.asm"
#include "baseops.asm"
#include "menu.asm"
#include "menuhandlers.asm"
#include "stathandlers.asm"
#include "cfithandlers.asm"
#include "tvmhandlers.asm"
#include "complexhandlers.asm"
#include "prime.asm"
#include "common.asm"
#include "memory.asm"
#include "float.asm"
#include "complex.asm"
#include "conv.asm"
#include "print.asm"
#include "const.asm"
#include "handlertab.asm"
#include "arghandlertab.asm"

;-----------------------------------------------------------------------------
; Flash Page 1
;-----------------------------------------------------------------------------

defpage(1)

#include "appstate.asm"
#include "help.asm"
#include "menulookup.asm"
#include "menudef.asm"
#include "crc.asm"
#include "errorcode.asm"
#include "print1.asm"
#include "input1.asm"
#include "arg1.asm"
#include "base1.asm"
#include "pstring1.asm"
#include "memory1.asm"
#include "float1.asm"
#include "integer1.asm"
#include "const1.asm"
#include "tvm.asm"
#include "hms.asm"
#include "prob.asm"
#ifdef DEBUG
#include "debug.asm"
#endif

.end

;-----------------------------------------------------------------------------

; Not sure if this needs to go before or after the `.end`.
validate()
