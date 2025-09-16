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

; The TVM BEGIN/END flag of the "Finance" app appears to be stored at bit 3
; (i.e. $08) of memory location $8a08. If BEGIN is selected, bit 3 is on. If
; END is selected, bit 3 is off. This is not documented anywhere. I discovered
; it by creating a monitor app and manually searching for a bit flip when the
; BEGIN and END states were changed in the "Finance" app. This information
; seems be valid for all calculators that I was able to test (TI-83+, TI-83+SE,
; TI-84+, TI-84+SE, and TI-Nspire+84Keypad)
tvmFlags equ $8a08
tvmFlagsBegin equ 3

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
; RPN83P application constants and parameters.
;-----------------------------------------------------------------------------

; A random 16-bit integer that identifies the RPN83P app.
rpn83pAppId equ $1E69

; List of appVar types used by RPN83P. The header fields of all RPN83P appVars
; will be the same, described by th following C struct:
;
; struct RpnVar {
;   uint16_t size; // maintained by the TIOS (*not* including 'size' field)
;   struct RpnVarHeader {
;     uint16_t crc16; // CRC16 checksum of all following bytes
;     uint16_t appId; // appId
;     uint16_t varType; // varType
;     uint16_t schemaVersion; // schema version of the payload
;   } header;
;   uint8_t payload[] // data payload
;  }
;
; Validating the CRC16 is a relatively expensive process. For UI efficiency, it
; is allowed that the (appId, varType, schemaVersion) fields may be read and
; processed for UI purposes (e.g. to display a menu of matching appVars to the
; user). But the CRC must be validated before actually using the information
; containined in the payload.
rpnVarTypeAppState equ 0 ; app state, excluding RpnElements
rpnVarTypeElementList equ 1 ; RpnElements, stack or storage registers
rpnVarTypeFullState equ 2 ; all state including RpnElements (not implemented)

; Size of the common appVar header: crc16 + appId + varType + schemaVersion = 8
rpnVarHeaderSize equ 8

; Increment the schema version if the previously saved app variable 'RPN83SAV'
; should be marked as stale during validation. This will cause the app to
; initialize to the factory defaults. When an variable is added or deleted, the
; version does not absolutely need to be incremented, because the value of
; appStateSize will be checked, and since it will be different, the previous
; state is considered stale automatically. However, if the *semantics* of any
; variable is changed (e.g. if the meaning of a flag is changed), then we
; *must* increment the version number to mark the previous state as stale.
rpn83pSchemaVersion equ 15

; Similar to rpn83pSchemaVersion, this version number determines the schema of
; the appVars (e.g. RPN83STK, RPN83REG, RPN83STA) that hold the list of
; RpnObjects.
;
; Version 1 uses a single byte to encode the RpnObjectType, using the extended
; range of $18 to $1e inclusive. The problem is that if additional RpnObjects
; are added, the type would be forced to use $20, which is not allowed
; according to the 83 Plus SDK documents since only the bottom 5-bits are
; supposed to be used in the first type byte.
;
; Version 2 uses 2 bytes to encode the RpnObjectType. If the first byte is
; rpnObjectTypePrefix ($18), then the second byte is the actual type of the
; RpnObject. This extends the range of the RpnObjectType to $ff, which should
; be more than enough for the foreseeable future.
;
; In the unlikely chance that the type range to $ff is insufficient, there are
; 2 ways to extend the encoding further:
;   1) Other prefix values are available. The values from $19 to $1f are
;   currently unused.
;   2) A second prefix value can be defined in the 2nd byte, encoding new types
;   using 3 bytes instead of just 2.
;
; Beware that extending the type range beyond $ff will require other additional
; work. There a number of places in the code which assumes that the RpnObject
; type can be held in a single 8-bit register.
rpnElementListSchemaVersion equ 2

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

; The bit mask needed to extract the TIOS object type. Only the bottom 5 bits
; of the type byte are used.
rpnObjectTypeMask equ $1f

; Number of bytes used by the 'type' field in the RpnObject. Currently, the
; type field is a `u8[2]`, so takes 2 bytes.
rpnObjectTypeSizeOf equ 2

; Macros to skip the type header bytes of an RpnObject.
#define skipRpnObjectTypeHL inc hl \ inc hl
#define skipRpnObjectTypeDE inc de \ inc de

; Real number object. Use the same constant as TIOS.
rpnObjectTypeReal equ 0 ; same as TI-OS
rpnRealSizeOf equ 9 ; sizeof(float)

; Complex number object. Use the same constant as TIOS.
rpnObjectTypeComplex equ $0C ; same as TI-OS
rpnComplexSizeOf equ 18 ; sizeof(complex)

; Type prefix for RPN83P objects. The next byte is the actual rpnObjectType.
rpnObjectTypePrefix equ $18

; Date and RpnDate objects:
; - struct Date{year:u16, mon:u8, day:u8}, 4 bytes
; - struct RpnDate{type:u8[2], date:Date}, 6 bytes
rpnObjectTypeDate equ $20 ; start at $20 to support additional prefixes
rpnObjectTypeDateSizeOf equ 6

; Time and RpnTime objects:
; - struct Time{hour:u8, minute:u8, second:u8}, 3 bytes
; - struct RpnTime{type:u8[2], date:Time}, 5 bytes
rpnObjectTypeTime equ $21
rpnObjectTypeTimeSizeOf equ 5

; DateTime and RpnDateTime objects:
; - struct DateTime{date:Date, hour:u8, min:u8, sec:u8}, 7 bytes
; - struct RpnDateTime{type:u8[2], dateTime:DateTime}, 9 bytes
rpnObjectTypeDateTime equ $22
rpnObjectTypeDateTimeSizeOf equ 9

; Offset and RpnOffset object:
; - struct Offset{hour:i8, min:i8}, 2 bytes
; - struct RpnOffset{type:u8[2], offset:Offset}, 4 bytes
rpnObjectTypeOffset equ $23
rpnObjectTypeOffsetSizeOf equ 4

; OffsetDateTime and RpnOffsetDateTime objects:
; - struct OffsetDateTime{datetime:DateTime, offset:Offset}, 9 bytes
; - struct RpnOffsetDateTime{type:u8[2], offsetDateTime:OffsetDateTime},
;   11 bytes
; The sizeof(RpnOffsetDateTime) is 11, which is greater than the 9 bytes of a
; TI-OS floating point number. But OPx registers are 11 bytes long. We have
; to careful and use expandOp1ToOp2() and shrinkOp2ToOp1() when parsing or
; manipulating this object.
rpnObjectTypeOffsetDateTime equ $24
rpnObjectTypeOffsetDateTimeSizeOf equ 11

; DayOfWeek and RpnDayOfWeek object:
; - struct DayOfWeek{dow:u8}, 1 bytes
; - struct RpnDayOfWeek{type:u8[2], DowOfWeek:dow}, 3 bytes
rpnObjectTypeDayOfWeek equ $25
rpnObjectTypeDayOfWeekSizeOf equ 3

; Duration and RpnDuration object:
; - struct Duration{days:i16, hours:i8, minutes:i8, seconds:i8}, 5 bytes
; - struct RpnDuration{type:u8[2], duration:Duration}, 7 bytes
rpnObjectTypeDuration equ $26
rpnObjectTypeDurationSizeOf equ 7

; Denominate number (i.e. a number with units). The 'value' is represented
; in terms of the 'baseUnit' of the 'displayUnit', which makes unit conversion
; easy because we just need to update the 'displayUnit' field without changing
; the 'value'. However, this means that the 'value' needs to be converted into
; the 'displayUnit' for display purposes.
; - struct Denominate{displayUnit:u8, value:float}, 10 bytes
; - struct RpnDenominate{type:u8[2], denominate:Denominate}, 12 bytes
rpnObjectTypeDenominate equ $27
rpnObjectTypeDenominateSizeOf equ 12
rpnDenominateFieldType equ 0
rpnDenominateFieldDisplayUnit equ 2
rpnDenominateFieldValue equ 3
#define skipDenominateUnitHL inc hl
#define skipDenominateUnitDE inc de

; An RpnObject is the union of all Rpn objects: RpnReal, RpnComplex, and so on.
; See the definition of 'struct RpnObject' in vars1.asm. Its size is the
; max(sizeof(RpnReal), sizeof(RpnComplex), sizeof(RpnDate), ...).
rpnObjectSizeOf equ rpnComplexSizeOf ; type + sizeof(complex)

; An RpnElement is a single element in the RpnElementList appVar that holds a
; single RpnObject. It has an extra type byte in front of the RpnObject, to
; allow us to extract its type without having to parse inside the RpnObject. If
; the rpnElementSizeOf is changed, the rpnElementIndexToOffset() function must
; be updated.
rpnElementSizeOf equ rpnObjectSizeOf+1

;-----------------------------------------------------------------------------
; RPN83P application variables and buffers.
;-----------------------------------------------------------------------------

; Begin application variables at tempSwapArea. According to the TI-83 Plus SDK
; docs: "tempSwapArea (82A5h) This is the start of 323 bytes used only during
; Flash ROM loading. If this area is used, avoid archiving variables."
appStateBegin equ tempSwapArea

; The following 4 variables must match the fields in the RpnVarHeader struct
; defined above.

; CRC16CCITT of the appState data block, not including the CRC itself.
; This is used only in StoreAppState() and RestoreAppState(), so in theory, we
; could remove it from here and save it only in the RPN83SAV AppVar. The
; advantage of duplicating the CRC here is that the content of the AppVar
; becomes *exactly* the same as this appState data block, so the serialization
; and deserialization code becomes almost trivial. Two bytes is not a large
; amount of memory, so let's keep things simple and duplicate the CRC field
; here.
appStateCrc16 equ appStateBegin ; u16

; A somewhat unique id to distinguish this app from other apps.
; Similar to the 'appStateCrc16' field, this does not need to be in the
; appState data block. But this simplifies the serialization code.
appStateAppId equ appStateCrc16 + 2 ; u16

; Type of RpnVar, one of the rpnVarTypeXxx enums.
appStateVarType equ appStateAppId + 2 ; u16

; Schema version. 2 bytes. If we overflow the 16-bits, it's probably ok because
; schema version 0 was probably created so far in the past the likelihood of a
; conflict is minimal. However, if the overflow does cause a problem, there is
; an escape hatch: we can create a new appStateAppId upon overflow. Similar to
; AppStateAppId and appStateCrc16, this field does not need to be here, but
; having it here simplifies the serialization code.
appStateSchemaVersion equ appStateVarType + 2 ; u16

; Copy of the 3 asm_FlagN flags. These will be serialized into RPN83SAV by
; StoreAppState(), and deserialized into asm_FlagN by RestoreAppState().
appStateDirtyFlags equ appStateSchemaVersion + 2 ; u8
appStateRpnFlags equ appStateDirtyFlags + 1 ; u8
appStateInputBufFlags equ appStateRpnFlags + 1 ; u8

; Copy of the trigFlags, fmtFlags, and fmtDigits as used by this app. When the
; app starts, these values will be used to configure the corresponding OS
; settings. When the app quits, the OS settings are copied here.
;
; The `numMode` flags (fmtReal, fmtRect, fmtPolar) are stored in the same
; location as the `fmtFlags`, so we don't have to save the `numMode flags
; separately.
appStateTrigFlags equ appStateInputBufFlags + 1 ; u8
appStateFmtFlags equ appStateTrigFlags + 1 ; u8
appStateFmtDigits equ appStateFmtFlags + 1 ; u8

; fmtDigits value that indicates "floating" number of digits
fmtDigitsFloating equ $ff

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

; Size of RPN stack. This is a cache of the stack size for display purposes.
; The source of truth is the size of the RPN83PSTK appVar. This stackSize
; variable will be updated whenever the appVar is resized.
stackSize equ errorCode + 1 ; u8, [4,8] allowed
stackSizeDefault equ 4 ; factory default stack size
stackSizeMin equ 4
stackSizeMax equ 8

; Current base mode number. Allowed values are: 2, 8, 10, 16. Anything else is
; interpreted as 10.
baseNumber equ stackSize + 1 ; u8

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
; 2) complex numbers: 20*2+1 = 41 characters (inputBufComplexMaxLen)
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
argBufSizeMax equ 4 ; max number of digits accepted on input

; Maximum number of characters that can be displayed during input/editing mode.
; The LCD line can display 16 characters using the large font. We need 1 char
; for the "X:" label which makes the window size of the inputBuf 15 characters.
; An extra space for the cursor is needed only when it is at the end of the
; inputBuf, and the rendering algorithm incorporates that extra space in this
; window size.
renderWindowSize equ 15

; Define the [start,end) of the renderWindow over the renderBuf[].
; These *must* be defined contiguously because we will read both variables at
; the same time using a `ld rr, (nn)` instruction. That's more convenient than
; the `ld a, (nn)` instruction which only supports the A register. We use
; little-endian order (end defined first) so that the high registers (B, D, H)
; are `start`, and the low registers (C, E, L) are `end`.
renderWindowEnd equ inputBuf + inputBufSizeOf ; u8
renderWindowStart equ renderWindowEnd + 1; u8

; Cursor position inside inputBuf[]. Valid values are from [0, inputBufLen]
; inclusive, which allows the cursor to be just to the right of the last
; character in inputBuf[].
cursorInputPos equ renderWindowStart + 1 ; u8

; Menu variables. Two variables determine the location in the menu hierarchy,
; the groupId and the rowIndex in the group. The C equivalent is:
;
;   struct MenuLocation {
;     uint16_t groupId; // id of the current menu group
;     uint8_t rowIndex; // menu row, groups of 5
;   }
currentMenuGroupId equ cursorInputPos + 1 ; u16
currentMenuRowIndex equ currentMenuGroupId + 2 ; u8

; The MenuLocation of the previous menuGroup/row pair when a shortcut was
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
;       uint8_t argLenLimit; // max num char allowed for the current prompt
;       char argModifier; // see argModifierXxx
;       uint8_t argType; // argTypeXxx
;       uint8_t argValue;
;   }
; The argModifierXxx (0-4) MUST match the corresponding operation in the
; 'floatOps' array in vars1.asm.
argPrompt equ menuName + menuNameSizeOf ; (char*)
argLenLimit equ argPrompt + 2 ; u8
argModifier equ argLenLimit + 1 ; char
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
argTypeInvalid equ 0 ; invalid argument
argTypeEmpty equ 1 ; empty string
argTypeNumber equ 2 ; numerical argument
argTypeLetter equ 3 ; a TI-OS variable letter, 'A'-'Z', 'Theta'
; argLenLimit defaults
argLenDefault equ 2 ; default argLenLimit if not explicitly overridden

; STAT variables
statAllEnabled equ argValue + 1 ; boolean, 1 if "ALLSigma" enabled
; Least square CFIT model.
curveFitModel equ statAllEnabled + 1 ; u8

; Constants used by the TVM Solver.
tvmSolverDefaultIterMax equ 15
; TVM Solver enums indicate if the solver should stop or continue the
; iterations
tvmSolverResultContinue equ 0 ; loop should continue
tvmSolverResultFound equ 1
tvmSolverResultNoSolution equ 2
tvmSolverResultNotFound equ 3
tvmSolverResultIterMaxed equ 4
tvmSolverResultBreak equ 5
tvmSolverResultSingleStep equ 6 ; return after each iteration

; TVM Solver configuration parameters. These are normally defined automatically
; but can be overridden using the 'IYR0', 'IYR1', and 'TMAX' menu buttons.
tvmIYR0 equ curveFitModel + 1 ; float
tvmIYR1 equ tvmIYR0 + 9 ; float
tvmIterMax equ tvmIYR1 + 9 ; u8

; Draw mode constants
drawModeNormal equ 0
drawModeInputBuf equ 1 ; show inputBuf in debug line
drawModeTvmSolver equ 2 ; show TVM n, i0, i1, npmt0, npmt1

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

; Set default time zone.
appTimeZone equ customEpochDate + 4 ; Offset{hh,mm}, 2 bytes

; Set clock time zone
rtcTimeZone equ appTimeZone + 2 ; Offset{hh,mm}, 2 bytes

; End application variables.
appStateEnd equ rtcTimeZone + 2

; Total size of appState vars.
appStateSize equ (appStateEnd - appStateBegin)

;-----------------------------------------------------------------------------
; Temporary buffers which do NOT need to be saved to an app var.
;-----------------------------------------------------------------------------

appBufferStart equ appStateEnd

; Set to 1 if this calculator has an RTC chip, otherwise 0. Filled in
; setIsRtcAvaiable().
isRtcAvailable equ appBufferStart ; u8

; Temporary buffer for parsing keyboard input into a floating point number.
; (TODO: Rename this to parseFloatBuf, for consistency with parseDurationBuf).
;
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
parseBuf equ isRtcAvailable + 1 ; struct ParseBuf
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

; Temporary variables used for parsing Compact Duration objects. Overlaps 11
; bytes with the 'parseBuf' used by floating point parsing.
;   struct ParseDurationBuf {
;     uint8_t flags;
;     uint16_t days;
;     uint16_t hours;
;     uint16_t minutes;
;     uint16_t seconds;
;     uint16_t current;
;   }
parseDurationBuf equ parseBuf
parseDurationBufFlags equ parseDurationBuf
parseDurationBufFlagSign equ 0
parseDurationBufFlagDays equ 1 ; 'D' modifier detected
parseDurationBufFlagHours equ 2 ; 'H' modifier detected
parseDurationBufFlagMinutes equ 3 ; 'M' modifier detected
parseDurationBufFlagSeconds equ 4 ; 'S' modifier detected
parseDurationBufDays equ parseDurationBufFlags + 1
parseDurationBufHours equ parseDurationBufDays + 2
parseDurationBufMinutes equ parseDurationBufHours + 2
parseDurationBufSeconds equ parseDurationBufMinutes + 2
parseDurationBufCurrent equ parseDurationBufSeconds + 2
parseDurationBufSizeOf equ 11

; Various OS flags and parameters are copied to these variables upon start of
; the app, then restored when the app quits.
savedTrigFlags equ parseBufExponent + 1 ; u8
savedFmtFlags equ savedTrigFlags + 1 ; u8
savedFmtDigits equ savedFmtFlags + 1 ; u8

; TVM Solver needs a bunch of workspace variables: interest rate, i0 and i1,
; plus the next interest rate i2, and the value of the NPMT() function at each
; of those points. Transient, so no need to persist them.
tvmI0 equ savedFmtDigits + 1 ; float
tvmNPMT0 equ tvmI0 + 9 ; float
tvmI1 equ tvmNPMT0 + 9 ; float
tvmNPMT1 equ tvmI1 + 9 ; float
tvmI2 equ tvmNPMT1 + 9 ; float
tvmNPMT2 equ tvmI2 + 9 ; float
; TVM Solver status and result code. Transient, no need to persist them.
tvmSolverIsRunning equ tvmNPMT2 + 9 ; boolean; true if active
tvmSolverCount equ tvmSolverIsRunning + 1 ; u8, iteration count
tvmSolverSolutions equ tvmSolverCount + 1 ; u8, numPotentialSolutions [0,1,2]

; A Pascal-string that contains the rendered version of inputBuf[] which can be
; printed on the screen. It is slightly longer than inputBuf for 2 reasons:
;
;   1) The 'Ldegree' delimiter for complex numbers is expanded to 2 characters
;   ('Langle' and 'Ltemp').
;
;   2) A sentinel 'space' character is added at the very end representing the
;   character that is behind the cursor when it is placed just after the end of
;   the string in inputBuf[]. It is convenient to define this sentinel in
;   renderBuf[] instead of adding special logic during the printing routine.
;
; The C structure is:
;
; struct RenderBuf {
;   uint8_t len;
;   char buf[renderBufCapacity];
; };
renderBuf equ tvmSolverSolutions + 1 ; struct RenderBuf; Pascal-string
renderBufLen equ renderBuf ; len byte of the string
renderBufBuf equ renderBuf + 1 ; start of actual buffer
renderBufCapacity equ inputBufCapacity + 2
renderBufSizeOf equ renderBufCapacity + 1 ; total size of data structure

; Lookup table that converts inputBuf[] coordinates to renderBuf[] coordinates.
; The C date type is:
;
;   uint8_t renderIndexes[inputBufCapacity + 1];
;
; The size of this array is inputBufCapacity+1 because the cursor can be placed
; one position past the last character in inputBuf[].
renderIndexes equ renderBuf + renderBufSizeOf ; u8*renderIndexesSize
renderIndexesSize equ inputBufCapacity + 1

; Cursor position inside renderBuf[]. Derived from the value of
; renderIndexes[cursorInputPos].
cursorRenderPos equ renderIndexes + renderIndexesSize ; u8

; Cursor position on the LCD screen in the range of [0,renderWindowSize). This
; is the *logical* screen position. The actual physical screen column index is
; `cursorScreenPos+1` because the `X:` label occupies one slot.
; TODO: Currently used only in setInputCursor(). Remove?
cursorScreenPos equ cursorRenderPos + 1 ; u8

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
displayStackFontFlagsA equ 16
displayStackFontFlags equ cursorScreenPos + 1 ; u8

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

;-----------------------------------------------------------------------------
; Branch table must be on Flash Page 0.
;-----------------------------------------------------------------------------

#include "branchtab.asm"

;-----------------------------------------------------------------------------
; Source code for Flash Page 0
;-----------------------------------------------------------------------------

#include "main.asm"
#include "mainscanner.asm"
#include "handlers.asm"
#include "argscanner.asm"
#include "arghandlers.asm"
#include "showscanner.asm"
#include "input.asm"
#include "display.asm"
#include "menu.asm"
#include "menuhandlers.asm"
#include "basemenuhandlers.asm"
#include "statmenuhandlers.asm"
#include "cfitmenuhandlers.asm"
#include "tvmmenuhandlers.asm"
#include "complexmenuhandlers.asm"
#include "datemenuhandlers.asm"
#include "unitmenuhandlers.asm"
#include "common.asm"
#include "memory.asm"
#include "cstring.asm"
#include "integer.asm"
#include "float.asm"
#include "complex.asm"
#include "rpnobject.asm"
#include "conv.asm"
#include "print.asm"
#include "const.asm"
#include "handlertab.asm"
#include "arghandlertab.asm"
#include "format.asm"

;-----------------------------------------------------------------------------
; Source code for Flash Page 1
;-----------------------------------------------------------------------------

defpage(1)

#include "vars1.asm"
#include "varsreg1.asm"
#include "varsstack1.asm"
#include "varsstat1.asm"
;
#include "appstate1.asm"
#include "osstate1.asm"
#include "help1.asm"
#include "helpscanner1.asm"
#include "crc1.asm"
#include "errorcode1.asm"
#include "print1.asm"
#include "input1.asm"
#include "parse1.asm"
#include "parsefloat1.asm"
#include "parsedate1.asm"
#include "parseduration1.asm"
#include "parseclassifiers1.asm"
#include "arg1.asm"
#include "base1.asm"
#include "cstring1.asm"
#include "pstring1.asm"
#include "memory1.asm"
#include "integer1.asm"
#include "rpnobject1.asm"
#include "integerconv1.asm"
#include "const1.asm"
#include "universal1.asm"
#include "complex1.asm"
#include "formatcomplex1.asm"
#include "hms1.asm"
#include "prob1.asm"
#include "format1.asm"
#include "duration1.asm"
;
#include "common1.asm"
;
#include "unitdef.asm"
#include "unit1.asm"
;
#ifdef DEBUG
#include "debug1.asm"
#endif

;-----------------------------------------------------------------------------
; Source Code for Flash Page 2
;-----------------------------------------------------------------------------

defpage(2)

#include "modes2.asm"
#include "tvm2.asm"
#include "float2.asm"
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
;
#include "denominate2.asm"
#include "formatdenominate2.asm"
;
#include "integer40.asm"
#include "integerconv40.asm"
#include "fps2.asm"
#include "format2.asm"
#include "show2.asm"
#include "display2.asm"
#include "print2.asm"
#include "memory2.asm"
#include "const2.asm"
#include "integer2.asm"
#include "rpnobject2.asm"
#include "cstring2.asm"
#include "common2.asm"
;
#include "prime2.asm"
#include "base2.asm"
#include "integerconv32.asm"
#include "formatinteger32.asm"
#include "integer32.asm"

;-----------------------------------------------------------------------------
; Source Code for Flash Page 3
;-----------------------------------------------------------------------------

defpage(3)

#include "menu3.asm"
#include "menudef.asm"
#include "integer3.asm"

;-----------------------------------------------------------------------------

.end

; Not sure if this needs to go before or after the `.end`.
validate()
