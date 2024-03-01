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
inputBufFlagsClosedEmpty equ 0 ; inputBuf empty when closeInput() called
inputBufFlagsArgAllowModifier equ 1 ; allow */-+ modifier in CommandArg mode
inputBufFlagsArgAllowLetter equ 2 ; allow A-Z,Theta in CommandArg mode
inputBufFlagsArgExit equ 3 ; set to exit CommandArg mode
inputBufFlagsArgCancel equ 4 ; set if exit was caused by CLEAR or ON/EXIT

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
rpn83pSchemaVersion equ 14

; Define true and false. Something else in spasm-ng defines the 'true' and
; 'false' symbols but I cannot find the definitions for them in the
; "ti83plus.inc" file. So maybe they are defined by the assembler itself?
; Regardless, I don't know what their values are, so I will explicitly define
; my own boolean values.
rpnfalse equ 0
rpntrue equ 1

;-----------------------------------------------------------------------------

; RpnObect type enums. TIOS defines object types from $00 (RealObj) to
; $17 (GroupObj). We'll continue from $18.

; Real number object. Use the same constant as TIOS.
rpnObjectTypeReal equ 0 ; same as TI-OS

; Complex number object. Use the same constant as TIOS.
rpnObjectTypeComplex equ $0C ; same as TI-OS

; Date and RpnDate objects:
; - struct Date{year:u16, mon:u8, day:u8}, 4 bytes
; - struct RpnDate{type:u8, date:Date}, 5 bytes
rpnObjectTypeDate equ $18
rpnObjectTypeDateSizeOf equ 5

; Time and RpnTime objects:
; - struct Time{hour:u8, minute:u8, second:u8}, 3 bytes
; - struct RpnTime{type:u8, date:Time}, 4 bytes
rpnObjectTypeTime equ $19
rpnObjectTypeTimeSizeOf equ 4

; DateTime and RpnDateTime objects:
; - struct DateTime{date:Date, hour:u8, min:u8, sec:u8}, 7 bytes
; - struct RpnDateTime{type:u8, dateTime:DateTime}, 8 bytes
rpnObjectTypeDateTime equ $1A
rpnObjectTypeDateTimeSizeOf equ 8

; Offset and RpnOffset object:
; - struct Offset{hour:i8, min:i8}, 2 bytes
; - struct RpnOffset{type:u8, offset:Offset}, 3 bytes
rpnObjectTypeOffset equ $1B
rpnObjectTypeOffsetSizeOf equ 3

; OffsetDateTime and RpnOffsetDateTime objects:
; - struct OffsetDateTime{datetime:DateTime, offset:Offset}, 9 bytes
; - struct RpnOffsetDateTime{type:u8, offsetDateTime:OffsetDateTime}, 10 bytes
; The sizeof(RpnOffsetDateTime) is 10, which is greater than the 9 bytes of a
; TI-OS floating point number. But OPx registers are 11 bytes long. We have
; to careful and use expandOp1ToOp2() and shrinkOp2ToOp1() when parsing or
; manipulating this object.
rpnObjectTypeOffsetDateTime equ $1C
rpnObjectTypeOffsetDateTimeSizeOf equ 10

; DayOfWeek and RpnDayOfWeek object:
; - struct DayOfWeek{dow:u8}, 1 bytes
; - struct RpnDayOfWeek{type:u8, DowOfWeek:dow}, 2 bytes
rpnObjectTypeDayOfWeek equ $1D
rpnObjectTypeDayOfWeekSizeOf equ 3

; Duration and RpnDuration object:
; - struct Duration{days:i16, hours:i8, minutes:i8, seconds:i8}, 5 bytes
; - struct RpnDuration{type:u8, duration:Duration}, 6 bytes
rpnObjectTypeDuration equ $1E
rpnObjectTypeDurationSizeOf equ 6

; An RpnObject is union of all possible Real, Complex, and RpnObjects. See the
; struct definitions in vars.asm. If the rpnObjectSizeOf is changed, the
; rpnObjectIndexToOffset() function must be updated.
rpnRealSizeOf equ 9 ; sizeof(float)
rpnComplexSizeOf equ 18 ; sizeof(complex)
rpnObjectSizeOf equ rpnComplexSizeOf + 1 ; type + sizeof(complex)

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

; Copy of the trigFlags, fmtFlags, and fmtDigits as used by this app. When the
; app starts, these values will be used to configure the corresponding OS
; settings. When the app quits, the OS settings are copied here.
appStateTrigFlags equ appStateInputBufFlags + 1 ; u8
appStateFmtFlags equ appStateTrigFlags + 1 ; u8
appStateFmtDigits equ appStateFmtFlags + 1 ; u8

; The result code after the execution of each handler. Success is code 0. If a
; TI-OS exception is thrown (through a `bcall(ErrXxx)`), the exception handler
; places a system error code into here. Before calling a handler, set this to 0
; because vast majority of handlers will not explicitly set handlerCode to 0
; upon success. (This makes coding easier because a successful handler can
; simply do a `ret` or a conditional `ret`.) A few handlers will set a custom,
; non-zero code to indicate an error.
handlerCode equ appStateFmtDigits + 1 ; u8

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

; The TI-OS floating point number supports 14 significant digits, but we need 6
; more characters to hold the optional mantissa minus sign, the optional
; decimal point, the optional 'E' symbol for the exponent, the 2-digit
; exponent, and the optional minus sign on the exponent. That's a total of 20
; characters. We need one more, to allow a complex delimiter to be entered.
inputBufFloatMaxLen equ 20+1

; A complex number requires 2 floating point numbers, plus the
; LimagI/Langle/Ldegree delimiter.
inputBufComplexMaxLen equ 20+20+1

; The longest record is currently OffsetDateTime{} which may be entered as
; "{yyyy,MM,dd,hh,mm,ss,ohh,omm}", so 29 characters max.
inputBufRecordMaxLen equ 29

; Max number of digits allowed for exponent.
inputBufEEMaxLen equ 2

; String buffer for keyboard entry. Different types of objects can be entered
; with different maxlen limits:
;
; 1) floating point real numbers: 20 characters (inputBufFloatMaxLen)
; 2) complex numbers: 20 * 2 = 40 characters (inputBufComplexMaxLen)
; 3) base-2 numbers: max of 32 digits (various, see getInputMaxLenBaseMode())
; 4) data records: max of 29 characters (various, see getInputMaxLenBaseMode())
;
; The inputBuf must be the maximum of all of the above.
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
inputBufCapacity equ inputBufComplexMaxLen ; excludes trailing cursor
inputBufSizeOf equ inputBufCapacity + 1 + 1 ; +1(len), +1(NUL)

; argBuf can reuse inputBuf because argBuf is activated only after inputBuf is
; closed.  The maximum number of characters in the buffer is 2.
argBuf equ inputBuf ; struct InputBuf
argBufLen equ inputBufLen
argBufCapacity equ inputBufCapacity
argBufSizeMax equ 2 ; max number of digits accepted on input

; Menu variables. Two variables determine the current state of the menu, the
; groupId and the rowIndex in the group. The C equivalent is:
;
;   struct Menu {
;     uint16_t groupId; // id of the current menu group
;     uint8_t rowIndex; // menu row, groups of 5
;   }
currentMenuGroupId equ inputBuf + inputBufSizeOf ; u16
currentMenuRowIndex equ currentMenuGroupId + 2 ; u8

; These variables remember the previous menuGroup/row pair when a shortcut was
; pressed to another menuGroup. On the ON/EXIT button is pressed, we can then
; go back to the previous menu, instead of going up to the parent of the menu
; invoked by the shortcut button. Not all shortcuts will choose to use this
; feature. Currently (v0.7.0), only the MODE button seems to be a good
; candidate. If jumpBackMenuGroupId is 0, then the memory feature is not
; active. If it is not 0, then the ON/EXIT button should go back to the menu
; defined by this pair.
jumpBackMenuGroupId equ currentMenuRowIndex + 1 ; u16
jumpBackMenuRowIndex equ jumpBackMenuGroupId + 2 ; u8

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

; Data structure revelant to the command argument scanner which handles
; something like "STO _ _". The C equivalent is:
;
;   struct ArgScanner {
;       char *argPrompt; // e.g. "STO"
;       char argModifier; // see argModifierXxx
;       char argType; // argTypeXxx
;       uint8_t argValue;
;   }
; The argModifierXxx (0-4) MUST match the corresponding operation in the
; 'floatOps' array in vars.asm.
argPrompt equ menuName + menuNameSizeOf ; (char*)
argModifier equ argPrompt + 2 ; char
argType equ argModifier + 1 ; u8
argValue equ argType + 1 ; u8
; argModifier enums
argModifierNone equ 0
argModifierAdd equ 1 ; '+' pressed
argModifierSub equ 2 ; '-' pressed
argModifierMul equ 3 ; '*' pressed
argModifierDiv equ 4 ; '/' pressed
argModifierIndirect equ 5 ; '.' pressed (not yet supported)
; argType enums
argTypeEmpty equ 0 ; empty string
argTypeNumber equ 1 ; 1 or 2 digit arguments
argTypeLetter equ 2 ; a TI-OS variable letter, 'A'-'Z', 'Theta'

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

; CommaEE button mode. In "Normal" mode, the CommaEE buton behaves according to
; the factory label. In "Swapped" mode, the CommaEE button does exactly the
; opposite.
commaEEMode equ complexMode+1 ; u8
commaEEModeNormal equ 0
commaEEModeSwapped equ 1

; FormatRecord button mode. In "Raw" mode, Record objects are formatted using
; {} notation. In "String" mode, Record objects are formatted using their
; human-readable string format.
formatRecordMode equ commaEEMode+1 ; u8
formatRecordModeRaw equ 0
formatRecordModeString equ 1

; Epoch type.
epochTypeCustom equ 0
epochTypeUnix equ 1
epochTypeNtp equ 2
epochTypeGps equ 3
epochTypeTios equ 4
epochTypeY2k equ 5

; Store the reference Epoch.
epochType equ formatRecordMode + 1 ; u8

; Current value of the Epoch Date as selected by epochType.
currentEpochDate equ epochType + 1 ; Date{y,m,d}, 4 bytes

; Custom value of the Epoch Date if epochTypeCustom selected.
customEpochDate equ currentEpochDate + 4 ; Date{y,m,d}, 4 bytes

; Set default time zone
timeZone equ customEpochDate + 4 ; Offset{hh,mm}, 2 bytes

; Set clock time zone
rtcTimeZone equ timeZone + 2 ; Offset{hh,mm}, 2 bytes

; End application variables.
appStateEnd equ rtcTimeZone + 2

; Total size of appState vars.
appStateSize equ (appStateEnd - appStateBegin)

;-----------------------------------------------------------------------------
; Temporary buffers which do NOT need to be saved to an app var.
;-----------------------------------------------------------------------------

appBufferStart equ appStateEnd

; Set to 1 if this calculator is an TI-83 Plus. Otherwise 0. Certain features
; (e.g. fast CPU, and Real Time Clock) are not available on the TI-83 Plus.
isTi83Plus equ appBufferStart ; u8

; Temporary buffer for parsing keyboard input into a floating point number.
; When the app is in BASE mode, the inputBuf is parsed directly, and this
; buffer is not used. In normal floating point mode, each mantissa digit is
; converted into this data structure, one byte per digit, before being
; converted into the packed floating point number format used by TI-OS. This
; essentially has the same role as the "Abstract Syntax Tree" of more
; complicated parsers.
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
parseBuf equ isTi83Plus + 1 ; struct ParseBuf
parseBufLen equ parseBuf ; len byte of the pascal string
parseBufMan equ parseBufLen + 1 ; actual string
parseBufCapacity equ 14
parseBufSizeOf equ parseBufCapacity + 1

; Internal flags updated during parsing of number string.
parseBufFlags equ parseBuf + parseBufSizeOf ; u8
parseBufFlagMantissaNeg equ 0 ; set if mantissa has a negative sign

; Floating point number exponent value (signed integer) extracted from the
; mantissa and the exponent digits. This value does not include the $80 offset.
parseBufExponent equ parseBufFlags + 1 ; i8

; Various OS flags and parameters are copied to these variables upon start of
; the app, then restored when the app quits.
savedTrigFlags equ parseBufExponent + 1 ; u8
savedFmtFlags equ savedTrigFlags + 1 ; u8
savedFmtDigits equ savedFmtFlags + 1 ; u8

; TVM Solver needs a bunch of workspace variables: interest rate, i0 and i1,
; plus the next interest rate i2, and the value of the NPMT() function at each
; of those points. Transient, so no need to persist them.
tvmI0 equ savedFmtDigits + 1 ; float
tvmI1 equ tvmI0 + 9 ; float
tvmNPMT0 equ tvmI1 + 9 ; float
tvmNPMT1 equ tvmNPMT0 + 9 ; float
; TVM Solver status and result code. Transient, no need to persist them.
tvmSolverIsRunning equ tvmNPMT1 + 9 ; boolean; true if active
tvmSolverCount equ tvmSolverIsRunning + 1 ; u8; iteration count

; A Pascal-string that contains the rendered version of inputBuf, truncated and
; formatted as needed, which can be printed on the screen. It is slightly
; longer than inputBuf because sometimes a single character in inputBuf gets
; expanded to multiple characters in inputDisplay (e.g. 'Ldegree' delimiter for
; complex numbers gets expanded to 'Langle,Ltemp' pair).
;
; The C structure is:
;
; struct InputDisplay {
;   uint8_t len;
;   char buf[inputDisplayCapacity];
; };
inputDisplay equ tvmSolverCount + 1 ; struct InputDisplay; Pascal-string
inputDisplayLen equ inputDisplay ; len byte of the string
inputDisplayBuf equ inputDisplay + 1 ; start of actual buffer
inputDisplayCapacity equ inputBufCapacity + 1 ; Ldegree -> Langle Ltemp
inputDisplaySizeOf equ inputDisplayCapacity + 1 ; total size of data structure

; Maximum number of characters that can be displayed during input/editing mode.
; The LCD line can display 16 characters using the large font. We need 1 char
; for the "X:" label, and 1 char for the trailing prompt "_", which leaves us
; with 14 characters.
inputDisplayMaxLen equ 14

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

appBufferEnd equ displayStackFontFlags + 1

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
floatBufType equ floatBuf ; type byte, also contains sign bit
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
; appstate1.asm
_StoreAppStateLabel:
_StoreAppState equ _StoreAppStateLabel-branchTableBase
    .dw StoreAppState
    .db 1
_RestoreAppStateLabel:
_RestoreAppState equ _RestoreAppStateLabel-branchTableBase
    .dw RestoreAppState
    .db 1

; osstate1.asm
_SaveOSStateLabel:
_SaveOSState equ _SaveOSStateLabel-branchTableBase
    .dw SaveOSState
    .db 1
_RestoreOSStateLabel:
_RestoreOSState equ _RestoreOSStateLabel-branchTableBase
    .dw RestoreOSState
    .db 1

; helpscanner1.asm
_ProcessHelpCommandsLabel:
_ProcessHelpCommands equ _ProcessHelpCommandsLabel-branchTableBase
    .dw ProcessHelpCommands
    .db 1

; menu1.asm
_InitMenuLabel:
_InitMenu equ _InitMenuLabel-branchTableBase
    .dw InitMenu
    .db 1
_SanitizeMenuLabel:
_SanitizeMenu equ _SanitizeMenuLabel-branchTableBase
    .dw SanitizeMenu
    .db 1
_ClearJumpBackLabel:
_ClearJumpBack equ _ClearJumpBackLabel-branchTableBase
    .dw ClearJumpBack
    .db 1
_SaveJumpBackLabel:
_SaveJumpBack equ _SaveJumpBackLabel-branchTableBase
    .dw SaveJumpBack
    .db 1
_GetCurrentMenuArrowStatusLabel:
_GetCurrentMenuArrowStatus equ _GetCurrentMenuArrowStatusLabel-branchTableBase
    .dw GetCurrentMenuArrowStatus
    .db 1
_GetMenuIdOfButtonLabel:
_GetMenuIdOfButton equ _GetMenuIdOfButtonLabel-branchTableBase
    .dw GetMenuIdOfButton
    .db 1
_GetCurrentMenuRowBeginIdLabel:
_GetCurrentMenuRowBeginId equ _GetCurrentMenuRowBeginIdLabel-branchTableBase
    .dw GetCurrentMenuRowBeginId
    .db 1
_GetCurrentMenuGroupNumRowsLabel:
_GetCurrentMenuGroupNumRows equ _GetCurrentMenuGroupNumRowsLabel-branchTableBase
    .dw GetCurrentMenuGroupNumRows
    .db 1
;
_ExtractMenuNamesLabel:
_ExtractMenuNames equ _ExtractMenuNamesLabel-branchTableBase
    .dw ExtractMenuNames
    .db 1
_GetMenuNodeHandlerLabel:
_GetMenuNodeHandler equ _GetMenuNodeHandlerLabel-branchTableBase
    .dw GetMenuNodeHandler
    .db 1
_GetMenuNodeParentLabel:
_GetMenuNodeParent equ _GetMenuNodeParentLabel-branchTableBase
    .dw GetMenuNodeParent
    .db 1
_GetMenuNodeRowBeginIdLabel:
_GetMenuNodeRowBeginId equ _GetMenuNodeRowBeginIdLabel-branchTableBase
    .dw GetMenuNodeRowBeginId
    .db 1

; crc1.asm
_Crc16ccittLabel:
_Crc16ccitt equ _Crc16ccittLabel-branchTableBase
    .dw Crc16ccitt
    .db 1

; errorcode1.asm
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
_AppendInputBufLabel:
_AppendInputBuf equ _AppendInputBufLabel-branchTableBase
    .dw AppendInputBuf
    .db 1
_CheckInputBufEELabel:
_CheckInputBufEE equ _CheckInputBufEELabel-branchTableBase
    .dw CheckInputBufEE
    .db 1
_CheckInputBufChsLabel:
_CheckInputBufChs equ _CheckInputBufChsLabel-branchTableBase
    .dw CheckInputBufChs
    .db 1
_CheckInputBufDecimalPointLabel:
_CheckInputBufDecimalPoint equ _CheckInputBufDecimalPointLabel-branchTableBase
    .dw CheckInputBufDecimalPoint
    .db 1
_CheckInputBufRecordLabel:
_CheckInputBufRecord equ _CheckInputBufRecordLabel-branchTableBase
    .dw CheckInputBufRecord
    .db 1
_SetComplexDelimiterLabel:
_SetComplexDelimiter equ _SetComplexDelimiterLabel-branchTableBase
    .dw SetComplexDelimiter
    .db 1

; parse1.asm
_ParseAndClearInputBufLabel:
_ParseAndClearInputBuf equ _ParseAndClearInputBufLabel-branchTableBase
    .dw ParseAndClearInputBuf
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
_GetLastCharLabel:
_GetLastChar equ _GetLastCharLabel-branchTableBase
    .dw GetLastChar
    .db 1

; integerconv1.asm
_ConvertAToOP1Label:
_ConvertAToOP1 equ _ConvertAToOP1Label-branchTableBase
    .dw ConvertAToOP1
    .db 1
_AddAToOP1Label:
_AddAToOP1 equ _AddAToOP1Label-branchTableBase
    .dw AddAToOP1
    .db 1

; tvm1.asm
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

; hms1.asm
_HmsToHrLabel:
_HmsToHr equ _HmsToHrLabel-branchTableBase
    .dw HmsToHr
    .db 1
_HmsFromHrLabel:
_HmsFromHr equ _HmsFromHrLabel-branchTableBase
    .dw HmsFromHr
    .db 1

; prob1.asm
_ProbPermLabel:
_ProbPerm equ _ProbPermLabel-branchTableBase
    .dw ProbPerm
    .db 1
_ProbCombLabel:
_ProbComb equ _ProbCombLabel-branchTableBase
    .dw ProbComb
    .db 1

; complex1.asm
_RectToComplexLabel:
_RectToComplex equ _RectToComplexLabel-branchTableBase
    .dw RectToComplex
    .db 1
_Rect3ToComplex3Label:
_Rect3ToComplex3 equ _Rect3ToComplex3Label-branchTableBase
    .dw Rect3ToComplex3
    .db 1
_PolarRadToComplexLabel:
_PolarRadToComplex equ _PolarRadToComplexLabel-branchTableBase
    .dw PolarRadToComplex
    .db 1
_PolarDegToComplexLabel:
_PolarDegToComplex equ _PolarDegToComplexLabel-branchTableBase
    .dw PolarDegToComplex
    .db 1
_ComplexToRectLabel:
_ComplexToRect equ _ComplexToRectLabel-branchTableBase
    .dw ComplexToRect
    .db 1
_Complex3ToRect3Label:
_Complex3ToRect3 equ _Complex3ToRect3Label-branchTableBase
    .dw Complex3ToRect3
    .db 1
_ComplexToPolarRadLabel:
_ComplexToPolarRad equ _ComplexToPolarRadLabel-branchTableBase
    .dw ComplexToPolarRad
    .db 1
_ComplexToPolarDegLabel:
_ComplexToPolarDeg equ _ComplexToPolarDegLabel-branchTableBase
    .dw ComplexToPolarDeg
    .db 1

; formatcomplex1.asm
_FormatComplexRectLabel:
_FormatComplexRect equ _FormatComplexRectLabel-branchTableBase
    .dw FormatComplexRect
    .db 1
_FormatComplexPolarRadLabel:
_FormatComplexPolarRad equ _FormatComplexPolarRadLabel-branchTableBase
    .dw FormatComplexPolarRad
    .db 1
_FormatComplexPolarDegLabel:
_FormatComplexPolarDeg equ _FormatComplexPolarDegLabel-branchTableBase
    .dw FormatComplexPolarDeg
    .db 1

;-----------------------------------------------------------------------------

; modes2.asm
_InitModesLabel:
_InitModes equ _InitModesLabel-branchTableBase
    .dw InitModes
    .db 2

; selectepoch2.asm
_SelectUnixEpochDateLabel:
_SelectUnixEpochDate equ _SelectUnixEpochDateLabel-branchTableBase
    .dw SelectUnixEpochDate
    .db 2
_SelectNtpEpochDateLabel:
_SelectNtpEpochDate equ _SelectNtpEpochDateLabel-branchTableBase
    .dw SelectNtpEpochDate
    .db 2
_SelectGpsEpochDateLabel:
_SelectGpsEpochDate equ _SelectGpsEpochDateLabel-branchTableBase
    .dw SelectGpsEpochDate
    .db 2
_SelectTiosEpochDateLabel:
_SelectTiosEpochDate equ _SelectTiosEpochDateLabel-branchTableBase
    .dw SelectTiosEpochDate
    .db 2
_SelectY2kEpochDateLabel:
_SelectY2kEpochDate equ _SelectY2kEpochDateLabel-branchTableBase
    .dw SelectY2kEpochDate
    .db 2
_SelectCustomEpochDateLabel:
_SelectCustomEpochDate equ _SelectCustomEpochDateLabel-branchTableBase
    .dw SelectCustomEpochDate
    .db 2
; Set and get custom epoch date.
_SetCustomEpochDateLabel:
_SetCustomEpochDate equ _SetCustomEpochDateLabel-branchTableBase
    .dw SetCustomEpochDate
    .db 2
_GetCustomEpochDateLabel:
_GetCustomEpochDate equ _GetCustomEpochDateLabel-branchTableBase
    .dw GetCustomEpochDate
    .db 2

; fps2.asm
_PushRpnObject1Label:
_PushRpnObject1 equ _PushRpnObject1Label-branchTableBase
    .dw PushRpnObject1
    .db 2
_PopRpnObject1Label:
_PopRpnObject1 equ _PopRpnObject1Label-branchTableBase
    .dw PopRpnObject1
    .db 2
_PushRpnObject3Label:
_PushRpnObject3 equ _PushRpnObject3Label-branchTableBase
    .dw PushRpnObject3
    .db 2
_PopRpnObject3Label:
_PopRpnObject3 equ _PopRpnObject3Label-branchTableBase
    .dw PopRpnObject3
    .db 2
_PushRpnObject5Label:
_PushRpnObject5 equ _PushRpnObject5Label-branchTableBase
    .dw PushRpnObject5
    .db 2
_PopRpnObject5Label:
_PopRpnObject5 equ _PopRpnObject5Label-branchTableBase
    .dw PopRpnObject5
    .db 2

; formatdate2.asm
_FormatDateLabel:
_FormatDate equ _FormatDateLabel-branchTableBase
    .dw FormatDate
    .db 2
_FormatTimeLabel:
_FormatTime equ _FormatTimeLabel-branchTableBase
    .dw FormatTime
    .db 2
_FormatDateTimeLabel:
_FormatDateTime equ _FormatDateTimeLabel-branchTableBase
    .dw FormatDateTime
    .db 2
_FormatOffsetLabel:
_FormatOffset equ _FormatOffsetLabel-branchTableBase
    .dw FormatOffset
    .db 2
_FormatOffsetDateTimeLabel:
_FormatOffsetDateTime equ _FormatOffsetDateTimeLabel-branchTableBase
    .dw FormatOffsetDateTime
    .db 2
_FormatDayOfWeekLabel:
_FormatDayOfWeek equ _FormatDayOfWeekLabel-branchTableBase
    .dw FormatDayOfWeek
    .db 2
_FormatDurationLabel:
_FormatDuration equ _FormatDurationLabel-branchTableBase
    .dw FormatDuration
    .db 2

; datevalidation2.asm
_ValidateDateLabel:
_ValidateDate equ _ValidateDateLabel-branchTableBase
    .dw ValidateDate
    .db 2
_ValidateTimeLabel:
_ValidateTime equ _ValidateTimeLabel-branchTableBase
    .dw ValidateTime
    .db 2
_ValidateDateTimeLabel:
_ValidateDateTime equ _ValidateDateTimeLabel-branchTableBase
    .dw ValidateDateTime
    .db 2
_ValidateOffsetLabel:
_ValidateOffset equ _ValidateOffsetLabel-branchTableBase
    .dw ValidateOffset
    .db 2
_ValidateOffsetDateTimeLabel:
_ValidateOffsetDateTime equ _ValidateOffsetDateTimeLabel-branchTableBase
    .dw ValidateOffsetDateTime
    .db 2
_ValidateDayOfWeekLabel:
_ValidateDayOfWeek equ _ValidateDayOfWeekLabel-branchTableBase
    .dw ValidateDayOfWeek
    .db 2
_ValidateDurationLabel:
_ValidateDuration equ _ValidateDurationLabel-branchTableBase
    .dw ValidateDuration
    .db 2

; date2.asm
_InitDateLabel:
_InitDate equ _InitDateLabel-branchTableBase
    .dw InitDate
    .db 2
; Year functions
_IsLeapLabel:
_IsLeap equ _IsLeapLabel-branchTableBase
    .dw IsLeap
    .db 2
; RpnDate and days functions
_RpnDateToEpochDaysLabel:
_RpnDateToEpochDays equ _RpnDateToEpochDaysLabel-branchTableBase
    .dw RpnDateToEpochDays
    .db 2
_RpnDateToEpochSecondsLabel:
_RpnDateToEpochSeconds equ _RpnDateToEpochSecondsLabel-branchTableBase
    .dw RpnDateToEpochSeconds
    .db 2
_EpochDaysToRpnDateLabel:
_EpochDaysToRpnDate equ _EpochDaysToRpnDateLabel-branchTableBase
    .dw EpochDaysToRpnDate
    .db 2
_EpochSecondsToRpnDateLabel:
_EpochSecondsToRpnDate equ _EpochSecondsToRpnDateLabel-branchTableBase
    .dw EpochSecondsToRpnDate
    .db 2
_AddRpnDateByDaysLabel:
_AddRpnDateByDays equ _AddRpnDateByDaysLabel-branchTableBase
    .dw AddRpnDateByDays
    .db 2
_SubRpnDateByRpnDateOrDaysLabel:
_SubRpnDateByRpnDateOrDays equ _SubRpnDateByRpnDateOrDaysLabel-branchTableBase
    .dw SubRpnDateByRpnDateOrDays
    .db 2

; time2.asm
_RpnTimeToSecondsLabel:
_RpnTimeToSeconds equ _RpnTimeToSecondsLabel-branchTableBase
    .dw RpnTimeToSeconds
    .db 2
_SecondsToRpnTimeLabel:
_SecondsToRpnTime equ _SecondsToRpnTimeLabel-branchTableBase
    .dw SecondsToRpnTime
    .db 2
_AddRpnTimeBySecondsLabel:
_AddRpnTimeBySeconds equ _AddRpnTimeBySecondsLabel-branchTableBase
    .dw AddRpnTimeBySeconds
    .db 2
_SubRpnTimeByRpnTimeOrSecondsLabel:
_SubRpnTimeByRpnTimeOrSeconds equ _SubRpnTimeByRpnTimeOrSecondsLabel-branchTableBase
    .dw SubRpnTimeByRpnTimeOrSeconds
    .db 2

; dayofweek2.asm
_DayOfWeekLabel:
_DayOfWeek equ _DayOfWeekLabel-branchTableBase
    .dw DayOfWeek
    .db 2
_AddRpnDayOfWeekByDaysLabel:
_AddRpnDayOfWeekByDays equ _AddRpnDayOfWeekByDaysLabel-branchTableBase
    .dw AddRpnDayOfWeekByDays
    .db 2
_SubRpnDayOfWeekByRpnDayOfWeekOrDaysLabel:
_SubRpnDayOfWeekByRpnDayOfWeekOrDays equ _SubRpnDayOfWeekByRpnDayOfWeekOrDaysLabel-branchTableBase
    .dw SubRpnDayOfWeekByRpnDayOfWeekOrDays
    .db 2

; datetime2.asm
_RpnDateTimeToEpochSecondsLabel:
_RpnDateTimeToEpochSeconds equ _RpnDateTimeToEpochSecondsLabel-branchTableBase
    .dw RpnDateTimeToEpochSeconds
    .db 2
_EpochSecondsToRpnDateTimeLabel:
_EpochSecondsToRpnDateTime equ _EpochSecondsToRpnDateTimeLabel-branchTableBase
    .dw EpochSecondsToRpnDateTime
    .db 2
_AddRpnDateTimeBySecondsLabel:
_AddRpnDateTimeBySeconds equ _AddRpnDateTimeBySecondsLabel-branchTableBase
    .dw AddRpnDateTimeBySeconds
    .db 2
_AddRpnDateTimeByRpnDurationLabel:
_AddRpnDateTimeByRpnDuration equ _AddRpnDateTimeByRpnDurationLabel-branchTableBase
    .dw AddRpnDateTimeByRpnDuration
    .db 2
_SubRpnDateTimeByObjectLabel:
_SubRpnDateTimeByObject equ _SubRpnDateTimeByObjectLabel-branchTableBase
    .dw SubRpnDateTimeByObject
    .db 2
_SplitRpnDateTimeLabel:
_SplitRpnDateTime equ _SplitRpnDateTimeLabel-branchTableBase
    .dw SplitRpnDateTime
    .db 2
_MergeRpnDateWithRpnTimeLabel:
_MergeRpnDateWithRpnTime equ _MergeRpnDateWithRpnTimeLabel-branchTableBase
    .dw MergeRpnDateWithRpnTime
    .db 2
_ExtendRpnDateToDateTimeLabel:
_ExtendRpnDateToDateTime equ _ExtendRpnDateToDateTimeLabel-branchTableBase
    .dw ExtendRpnDateToDateTime
    .db 2
_TruncateRpnDateTimeLabel:
_TruncateRpnDateTime equ _TruncateRpnDateTimeLabel-branchTableBase
    .dw TruncateRpnDateTime
    .db 2

; offset2.asm
_RpnOffsetToSecondsLabel:
_RpnOffsetToSeconds equ _RpnOffsetToSecondsLabel-branchTableBase
    .dw RpnOffsetToSeconds
    .db 2

; offsetdatetime2.asm
_RpnOffsetDateTimeToEpochSecondsLabel:
_RpnOffsetDateTimeToEpochSeconds equ _RpnOffsetDateTimeToEpochSecondsLabel-branchTableBase
    .dw RpnOffsetDateTimeToEpochSeconds
    .db 2
_EpochSecondsToRpnOffsetDateTimeLabel:
_EpochSecondsToRpnOffsetDateTime equ _EpochSecondsToRpnOffsetDateTimeLabel-branchTableBase
    .dw EpochSecondsToRpnOffsetDateTime
    .db 2
_AddRpnOffsetDateTimeBySecondsLabel:
_AddRpnOffsetDateTimeBySeconds equ _AddRpnOffsetDateTimeBySecondsLabel-branchTableBase
    .dw AddRpnOffsetDateTimeBySeconds
    .db 2
_AddRpnOffsetDateTimeByDurationLabel:
_AddRpnOffsetDateTimeByDuration equ _AddRpnOffsetDateTimeByDurationLabel-branchTableBase
    .dw AddRpnOffsetDateTimeByDuration
    .db 2
_SubRpnOffsetDateTimeByObjectLabel:
_SubRpnOffsetDateTimeByObject equ _SubRpnOffsetDateTimeByObjectLabel-branchTableBase
    .dw SubRpnOffsetDateTimeByObject
    .db 2
_SplitRpnOffsetDateTimeLabel:
_SplitRpnOffsetDateTime equ _SplitRpnOffsetDateTimeLabel-branchTableBase
    .dw SplitRpnOffsetDateTime
    .db 2
_MergeRpnDateTimeWithRpnOffsetLabel:
_MergeRpnDateTimeWithRpnOffset equ _MergeRpnDateTimeWithRpnOffsetLabel-branchTableBase
    .dw MergeRpnDateTimeWithRpnOffset
    .db 2
_ExtendRpnDateTimeToOffsetDateTimeLabel:
_ExtendRpnDateTimeToOffsetDateTime equ _ExtendRpnDateTimeToOffsetDateTimeLabel-branchTableBase
    .dw ExtendRpnDateTimeToOffsetDateTime
    .db 2
_TruncateRpnOffsetDateTimeLabel:
_TruncateRpnOffsetDateTime equ _TruncateRpnOffsetDateTimeLabel-branchTableBase
    .dw TruncateRpnOffsetDateTime
    .db 2

; duration2.asm
_RpnDurationToSecondsLabel:
_RpnDurationToSeconds equ _RpnDurationToSecondsLabel-branchTableBase
    .dw RpnDurationToSeconds
    .db 2
_SecondsToRpnDurationLabel:
_SecondsToRpnDuration equ _SecondsToRpnDurationLabel-branchTableBase
    .dw SecondsToRpnDuration
    .db 2
_ChsRpnDurationLabel:
_ChsRpnDuration equ _ChsRpnDurationLabel-branchTableBase
    .dw ChsRpnDuration
    .db 2
_AddRpnDurationBySecondsLabel:
_AddRpnDurationBySeconds equ _AddRpnDurationBySecondsLabel-branchTableBase
    .dw AddRpnDurationBySeconds
    .db 2
_AddRpnDurationByRpnDurationLabel:
_AddRpnDurationByRpnDuration equ _AddRpnDurationByRpnDurationLabel-branchTableBase
    .dw AddRpnDurationByRpnDuration
    .db 2
_SubRpnDurationByRpnDurationOrSecondsLabel:
_SubRpnDurationByRpnDurationOrSeconds equ _SubRpnDurationByRpnDurationOrSecondsLabel-branchTableBase
    .dw SubRpnDurationByRpnDurationOrSeconds
    .db 2

; zoneconversion2.asm
_ConvertRpnDateTimeToTimeZoneAsOffsetLabel:
_ConvertRpnDateTimeToTimeZoneAsOffset equ _ConvertRpnDateTimeToTimeZoneAsOffsetLabel-branchTableBase
    .dw ConvertRpnDateTimeToTimeZoneAsOffset
    .db 2
_ConvertRpnDateTimeToTimeZoneAsRealLabel:
_ConvertRpnDateTimeToTimeZoneAsReal equ _ConvertRpnDateTimeToTimeZoneAsRealLabel-branchTableBase
    .dw ConvertRpnDateTimeToTimeZoneAsReal
    .db 2
_ConvertRpnOffsetDateTimeToOffsetLabel:
_ConvertRpnOffsetDateTimeToOffset equ _ConvertRpnOffsetDateTimeToOffsetLabel-branchTableBase
    .dw ConvertRpnOffsetDateTimeToOffset
    .db 2
_ConvertRpnOffsetDateTimeToTimeZoneAsRealLabel:
_ConvertRpnOffsetDateTimeToTimeZoneAsReal equ _ConvertRpnOffsetDateTimeToTimeZoneAsRealLabel-branchTableBase
    .dw ConvertRpnOffsetDateTimeToTimeZoneAsReal
    .db 2

; zone2.asm
_SetTimeZoneLabel:
_SetTimeZone equ _SetTimeZoneLabel-branchTableBase
    .dw SetTimeZone
    .db 2
_GetTimeZoneLabel:
_GetTimeZone equ _GetTimeZoneLabel-branchTableBase
    .dw GetTimeZone
    .db 2

; rtc2.asm
_RtcInitLabel:
_RtcInit equ _RtcInitLabel-branchTableBase
    .dw RtcInit
    .db 2
_RtcGetNowLabel:
_RtcGetNow equ _RtcGetNowLabel-branchTableBase
    .dw RtcGetNow
    .db 2
_RtcGetOffsetDateTimeLabel:
_RtcGetOffsetDateTime equ _RtcGetOffsetDateTimeLabel-branchTableBase
    .dw RtcGetOffsetDateTime
    .db 2
;
_RtcSetClockLabel:
_RtcSetClock equ _RtcSetClockLabel-branchTableBase
    .dw RtcSetClock
    .db 2
_RtcSetTimeZoneLabel:
_RtcSetTimeZone equ _RtcSetTimeZoneLabel-branchTableBase
    .dw RtcSetTimeZone
    .db 2
_RtcGetTimeZoneLabel:
_RtcGetTimeZone equ _RtcGetTimeZoneLabel-branchTableBase
    .dw RtcGetTimeZone
    .db 2

; base2.asm
_InitBaseLabel:
_InitBase equ _InitBaseLabel-branchTableBase
    .dw InitBase
    .db 2
_BitwiseAndLabel:
_BitwiseAnd equ _BitwiseAndLabel-branchTableBase
    .dw BitwiseAnd
    .db 2
_BitwiseOrLabel:
_BitwiseOr equ _BitwiseOrLabel-branchTableBase
    .dw BitwiseOr
    .db 2
_BitwiseXorLabel:
_BitwiseXor equ _BitwiseXorLabel-branchTableBase
    .dw BitwiseXor
    .db 2
_BitwiseNotLabel:
_BitwiseNot equ _BitwiseNotLabel-branchTableBase
    .dw BitwiseNot
    .db 2
_BitwiseNegLabel:
_BitwiseNeg equ _BitwiseNegLabel-branchTableBase
    .dw BitwiseNeg
    .db 2
;
_BaseShiftLeftLogicalLabel:
_BaseShiftLeftLogical equ _BaseShiftLeftLogicalLabel-branchTableBase
    .dw BaseShiftLeftLogical
    .db 2
_BaseShiftRightLogicalLabel:
_BaseShiftRightLogical equ _BaseShiftRightLogicalLabel-branchTableBase
    .dw BaseShiftRightLogical
    .db 2
_BaseShiftRightArithmeticLabel:
_BaseShiftRightArithmetic equ _BaseShiftRightArithmeticLabel-branchTableBase
    .dw BaseShiftRightArithmetic
    .db 2
_BaseShiftLeftLogicalNLabel:
_BaseShiftLeftLogicalN equ _BaseShiftLeftLogicalNLabel-branchTableBase
    .dw BaseShiftLeftLogicalN
    .db 2
_BaseShiftRightLogicalNLabel:
_BaseShiftRightLogicalN equ _BaseShiftRightLogicalNLabel-branchTableBase
    .dw BaseShiftRightLogicalN
    .db 2
;
_BaseRotateLeftCircularLabel:
_BaseRotateLeftCircular equ _BaseRotateLeftCircularLabel-branchTableBase
    .dw BaseRotateLeftCircular
    .db 2
_BaseRotateRightCircularLabel:
_BaseRotateRightCircular equ _BaseRotateRightCircularLabel-branchTableBase
    .dw BaseRotateRightCircular
    .db 2
_BaseRotateLeftCarryLabel:
_BaseRotateLeftCarry equ _BaseRotateLeftCarryLabel-branchTableBase
    .dw BaseRotateLeftCarry
    .db 2
_BaseRotateRightCarryLabel:
_BaseRotateRightCarry equ _BaseRotateRightCarryLabel-branchTableBase
    .dw BaseRotateRightCarry
    .db 2
;
_BaseRotateLeftCircularNLabel:
_BaseRotateLeftCircularN equ _BaseRotateLeftCircularNLabel-branchTableBase
    .dw BaseRotateLeftCircularN
    .db 2
_BaseRotateRightCircularNLabel:
_BaseRotateRightCircularN equ _BaseRotateRightCircularNLabel-branchTableBase
    .dw BaseRotateRightCircularN
    .db 2
_BaseRotateLeftCarryNLabel:
_BaseRotateLeftCarryN equ _BaseRotateLeftCarryNLabel-branchTableBase
    .dw BaseRotateLeftCarryN
    .db 2
_BaseRotateRightCarryNLabel:
_BaseRotateRightCarryN equ _BaseRotateRightCarryNLabel-branchTableBase
    .dw BaseRotateRightCarryN
    .db 2
;
_BaseAddLabel:
_BaseAdd equ _BaseAddLabel-branchTableBase
    .dw BaseAdd
    .db 2
_BaseSubLabel:
_BaseSub equ _BaseSubLabel-branchTableBase
    .dw BaseSub
    .db 2
_BaseMultLabel:
_BaseMult equ _BaseMultLabel-branchTableBase
    .dw BaseMult
    .db 2
_BaseDivLabel:
_BaseDiv equ _BaseDivLabel-branchTableBase
    .dw BaseDiv
    .db 2
_BaseDiv2Label:
_BaseDiv2 equ _BaseDiv2Label-branchTableBase
    .dw BaseDiv2
    .db 2
;
_BaseReverseBitsLabel:
_BaseReverseBits equ _BaseReverseBitsLabel-branchTableBase
    .dw BaseReverseBits
    .db 2
_BaseCountBitsLabel:
_BaseCountBits equ _BaseCountBitsLabel-branchTableBase
    .dw BaseCountBits
    .db 2
_BaseSetBitLabel:
_BaseSetBit equ _BaseSetBitLabel-branchTableBase
    .dw BaseSetBit
    .db 2
_BaseClearBitLabel:
_BaseClearBit equ _BaseClearBitLabel-branchTableBase
    .dw BaseClearBit
    .db 2
_BaseGetBitLabel:
_BaseGetBit equ _BaseGetBitLabel-branchTableBase
    .dw BaseGetBit
    .db 2
;
_BaseStoreCarryFlagLabel:
_BaseStoreCarryFlag equ _BaseStoreCarryFlagLabel-branchTableBase
    .dw BaseStoreCarryFlag
    .db 2
_BaseGetCarryFlagLabel:
_BaseGetCarryFlag equ _BaseGetCarryFlagLabel-branchTableBase
    .dw BaseGetCarryFlag
    .db 2
;
_BaseSetWordSizeLabel:
_BaseSetWordSize equ _BaseSetWordSizeLabel-branchTableBase
    .dw BaseSetWordSize
    .db 2
_BaseGetWordSizeLabel:
_BaseGetWordSize equ _BaseGetWordSizeLabel-branchTableBase
    .dw BaseGetWordSize
    .db 2

; prime2.asm
_PrimeFactorLabel:
_PrimeFactor equ _PrimeFactorLabel-branchTableBase
    .dw PrimeFactor
    .db 2

; integerconv32.asm
_ConvertOP1ToU32StatusCodeLabel:
_ConvertOP1ToU32StatusCode equ _ConvertOP1ToU32StatusCodeLabel-branchTableBase
    .dw ConvertOP1ToU32StatusCode
    .db 2
_CheckU32FitsWsizeLabel:
_CheckU32FitsWsize equ _CheckU32FitsWsizeLabel-branchTableBase
    .dw CheckU32FitsWsize
    .db 2

; formatinteger32.asm
_ReformatBaseTwoStringLabel:
_ReformatBaseTwoString equ _ReformatBaseTwoStringLabel-branchTableBase
    .dw ReformatBaseTwoString
    .db 2
_FormatU32ToHexStringLabel:
_FormatU32ToHexString equ _FormatU32ToHexStringLabel-branchTableBase
    .dw FormatU32ToHexString
    .db 2
_FormatU32ToOctStringLabel:
_FormatU32ToOctString equ _FormatU32ToOctStringLabel-branchTableBase
    .dw FormatU32ToOctString
    .db 2
_FormatU32ToBinStringLabel:
_FormatU32ToBinString equ _FormatU32ToBinStringLabel-branchTableBase
    .dw FormatU32ToBinString
    .db 2
_FormatU32ToDecStringLabel:
_FormatU32ToDecString equ _FormatU32ToDecStringLabel-branchTableBase
    .dw FormatU32ToDecString
    .db 2

; format2.asm
_FormatAToStringLabel:
_FormatAToString equ _FormatAToStringLabel-branchTableBase
    .dw FormatAToString
    .db 2

; show2.asm
_FormShowableLabel:
_FormShowable equ _FormShowableLabel-branchTableBase
    .dw FormShowable
    .db 2

;-----------------------------------------------------------------------------

#ifdef DEBUG
; debug1.asm
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
_DebugU40AsHexLabel:
_DebugU40AsHex equ _DebugU40AsHexLabel-branchTableBase
    .dw DebugU40AsHex
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

;-----------------------------------------------------------------------------

#include "main.asm"
#include "mainscanner.asm"
#include "handlers.asm"
#include "argscanner.asm"
#include "arghandlers.asm"
#include "showscanner.asm"
#include "vars.asm"
#include "input.asm"
#include "display.asm"
#include "basehandlers.asm"
#include "menu.asm"
#include "menuhandlers.asm"
#include "stathandlers.asm"
#include "cfithandlers.asm"
#include "tvmhandlers.asm"
#include "complexhandlers.asm"
#include "datehandlers.asm"
#include "common.asm"
#include "memory.asm"
#include "cstring.asm"
#include "integer.asm"
#include "float.asm"
#include "complex.asm"
#include "universal.asm"
#include "rpnobject.asm"
#include "conv.asm"
#include "print.asm"
#include "const.asm"
#include "handlertab.asm"
#include "arghandlertab.asm"
#include "format.asm"

;-----------------------------------------------------------------------------
; Flash Page 1
;-----------------------------------------------------------------------------

defpage(1)

#include "appstate1.asm"
#include "osstate1.asm"
#include "help1.asm"
#include "helpscanner1.asm"
#include "menu1.asm"
#include "menudef.asm"
#include "crc1.asm"
#include "errorcode1.asm"
#include "print1.asm"
#include "input1.asm"
#include "parse1.asm"
#include "parsefloat1.asm"
#include "parsedate1.asm"
#include "arg1.asm"
#include "base1.asm"
#include "cstring1.asm"
#include "pstring1.asm"
#include "memory1.asm"
#include "integer1.asm"
#include "float1.asm"
#include "integerconv1.asm"
#include "const1.asm"
#include "complex1.asm"
#include "formatcomplex1.asm"
#include "tvm1.asm"
#include "hms1.asm"
#include "prob1.asm"
#include "format1.asm"
#ifdef DEBUG
#include "debug1.asm"
#endif

;-----------------------------------------------------------------------------
; Flash Page 2
;-----------------------------------------------------------------------------

defpage(2)

#include "modes2.asm"
#include "selectepoch2.asm"
#include "epoch2.asm"
#include "datevalidation2.asm"
#include "date2.asm"
#include "time2.asm"
#include "dayofweek2.asm"
#include "datetime2.asm"
#include "offset2.asm"
#include "offsetdatetime2.asm"
#include "duration2.asm"
#include "zoneconversion2.asm"
#include "zone2.asm"
#include "rtc2.asm"
#include "formatdate2.asm"
#include "integer40.asm"
#include "integerconv40.asm"
#include "fps2.asm"
#include "format2.asm"
#include "show2.asm"
#include "memory2.asm"
#include "const2.asm"
#include "integer2.asm"
#include "rpnobject2.asm"
#include "cstring2.asm"
;
#include "prime2.asm"
#include "base2.asm"
#include "integerconv32.asm"
#include "formatinteger32.asm"
#include "integer32.asm"

.end

;-----------------------------------------------------------------------------

; Not sure if this needs to go before or after the `.end`.
validate()
