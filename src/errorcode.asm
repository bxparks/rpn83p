;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Functions and strings related to error codes.
;-----------------------------------------------------------------------------

; Function: Initialize errorCode and handlerCode to 0.
initErrorCode:
    xor a
    ld (errorCode), a
    ld (handlerCode), a
    ret

; Description: Set the handlerCode to the normalized system error code in
; Register A. The system error code uses the lower 7 bits, so in theory there
; are as many as 128. However, the SDK docs define only about 32, so those are
; reduced down to a range of `[0, errorCodeCount-1]`.
; Input: A: system error code
; Output: A: handlerCode
setHandlerCodeToSystemCode:
    res 7, a ; reset the GOTO flag
    ; [[fallthrough]]

; Description: Set `handlerCode` to register A, which will hold one of the
; `errorCodeXxx` values.
; Output: A: handlerCode
setHandlerCode:
    ld (handlerCode), a
    ret

; Description: Set the `errorCode` to the value given in register A.
; Input: A: error code
setErrorCode:
    ld hl, errorCode
    cp (hl) ; previous errorCode
    ret z ; same, no change
    ld (hl), a ; errorCode = new error code
    set dirtyFlagsErrorCode, (iy + dirtyFlags)
    ret

; Function: getErrorString(A) -> HL
; Description: Get the string for given error code.
; Input: A: error code
; Output: HL: pointer to a C string
; Destroys: DE, HL
; Preserves: A
getErrorString:
    cp errorCodeCount
    jr c, getErrorStringContinue
    ; Set to "Unknown" if code is beyond the error string table
    ld hl, errorStrUnknown
    ret
getErrorStringContinue:
    ld hl, errorStrings
    jp getString

;-----------------------------------------------------------------------------

; An array of pointers to C strings. The TI-OS error handler defines the error
; code in the lower 7 bits, for a total of 128 possible values. The SDK
; documentation defines `bjump/bcall()` calls for about 28 of these values, but
; the corresponding the numerical error codes passed through the `A` register
; are not documented.
;
; The following numerical error codes below were reverse engineered by calling
; the `bcall(_ErrXXX)` one at a time, trapping the exception, then printing out
; the code written into the `A` register. They match the codes given in this
; wiki page, https://learn.cemetech.net/index.php?title=Z80:Error_Codes, which
; seems to contain additional error codes which are not documented in the SDK
; docs. We will ignore those extra error codes in this application.
;
; This table defines additional custom error codes used internally by this
; application. The `errorStrUnknown` message is displayed for any error code
; whose error string is not known. If the user sends a reproducible bug report,
; maybe we can reverse engineer the condition that triggers that particular
; error code and create a human-readable string for it.

errorCodeCount equ 73           ; total number of error codes
errorStrings:
errorCodeOk equ                 0 ; hopefully TI-OS uses 0 as "success"
    .dw errorStrOk
errorCodeOverflow equ           1
    .dw errorStrOverflow
errorCodeDivBy0 equ             2
    .dw errorStrDivBy0
errorCodeSingularMat equ        3
    .dw errorStrSingularMat
errorCodeDomain equ             4
    .dw errorStrDomain
errorCodeIncrement equ          5
    .dw errorStrIncrement
errorCodeBreak equ              6
    .dw errorStrBreak
errorCodeNon_Real equ           7
    .dw errorStrNon_Real
errorCodeSyntax equ             8 ; also triggered by ErrNonReal??
    .dw errorStrSyntax
errorCodeDataType equ           9 ; also triggered by ErrNonReal??
    .dw errorStrDataType
errorCodeArgument equ           10
    .dw errorStrArgument
errorCodeDimMismatch equ        11
    .dw errorStrDimMismatch
errorCodeDimension equ          12
    .dw errorStrDimension
errorCodeUndefined equ          13
    .dw errorStrUndefined
errorCodeMemory equ             14
    .dw errorStrMemory
errorCodeInvalid equ            15
    .dw errorStrInvalid
errorCode16 equ                 16
    .dw errorStrUnknown
errorCode17 equ                 17
    .dw errorStrUnknown
errorCode18 equ                 18
    .dw errorStrUnknown
errorCode19 equ                 19
    .dw errorStrUnknown
errorCode20 equ                 20
    .dw errorStrUnknown
errorCodeStat equ               21
    .dw errorStrStat
errorCode22 equ                 22
    .dw errorStrUnknown
errorCode23 equ                 23
    .dw errorStrUnknown
errorCodeSignChange equ         24
    .dw errorStrSignChange
errorCodeIterations equ         25
    .dw errorStrIterations
errorCodeBadGuess equ           26
    .dw errorStrBadGuess
errorCodeStatPlot equ           27
    .dw errorStrStatPlot
errorCodeTolTooSmall equ        28
    .dw errorStrTolTooSmall
errorCode29 equ                 29
    .dw errorStrUnknown
errorCode30 equ                 30
    .dw errorStrUnknown
errorCodeLinkXmit equ           31
    .dw errorStrLinkXmit
    .dw errorStrUnknown         ; 32
    .dw errorStrUnknown         ; 33
    .dw errorStrUnknown         ; 34
    .dw errorStrUnknown         ; 35
    .dw errorStrUnknown         ; 36
    .dw errorStrUnknown         ; 37
    .dw errorStrUnknown         ; 38
    .dw errorStrUnknown         ; 39
    .dw errorStrUnknown         ; 40
    .dw errorStrUnknown         ; 41
    .dw errorStrUnknown         ; 42
    .dw errorStrUnknown         ; 43
    .dw errorStrUnknown         ; 44
    .dw errorStrUnknown         ; 45
    .dw errorStrUnknown         ; 46
    .dw errorStrUnknown         ; 47
    .dw errorStrUnknown         ; 48
    .dw errorStrUnknown         ; 49
    .dw errorStrUnknown         ; 50
    .dw errorStrUnknown         ; 51
    .dw errorStrUnknown         ; 52
    .dw errorStrUnknown         ; 53
    .dw errorStrUnknown         ; 54
    .dw errorStrUnknown         ; 55
    .dw errorStrUnknown         ; 56
    .dw errorStrUnknown         ; 57
    .dw errorStrUnknown         ; 58
    .dw errorStrUnknown         ; 59
    .dw errorStrUnknown         ; 60
    .dw errorStrUnknown         ; 61
    .dw errorStrUnknown         ; 62
    .dw errorStrUnknown         ; 63, hopefully the last TI-OS error code
; Start of extended error codes used by RPN83P.
errorCodeQuitApp equ            64 ; Handler wants to Quit the App
    .dw errorStrQuitApp
errorCodeClearScreen equ        65 ; Handler wants to clear screen
    .dw errorStrClearScreen
errorCodeNotYet equ             66 ; Handler not yet implemented
    .dw errorStrNotYet
errorCodeRegsCleared equ        67 ; REGS cleared
    .dw errorStrRegsCleared
errorCodeStatCleared equ        68 ; STAT registers cleared
    .dw errorStrStatCleared
errorCodeTvmSet equ             69
    .dw errorStrTvmSet
errorCodeTvmCalculated equ      70
    .dw errorStrTvmCalculated
errorCodeTvmReset equ           71
    .dw errorStrTvmReset
errorCodeTvmCleared equ         72
    .dw errorStrTvmCleared

; The C strings for each error code. In alphabetical order, as listed in the TI
; 83 Plus SDK docs.
errorStrOk:
    .db "OK", 0 ; this won't be displayed, but define the string just in case
errorStrArgument:
    .db "Err: Argument", 0
errorStrBadGuess:
    .db "Err: Bad Guess", 0
errorStrBreak:
    .db "Err: Break", 0
errorStrDomain:
    .db "Err: Domain", 0
errorStrDataType:
    .db "Err: Data Type", 0
errorStrDimension:
    .db "Err: Invalid Dim", 0
errorStrDimMismatch:
    .db "Err: Dim Mismatch", 0
errorStrDivBy0:
    .db "Err: Divide By 0", 0
errorStrIncrement:
    .db "Err: Increment", 0
errorStrInvalid:
    .db "Err: Invalid", 0
errorStrIterations:
    .db "Err: Iterations", 0
errorStrLinkXmit:
    .db "Err: In Xmit", 0
errorStrMemory:
    .db "Err: Memory", 0
errorStrNon_Real:
    .db "Err: Non Real", 0
errorStrOverflow:
    .db "Err: Overflow", 0
errorStrSignChange:
    .db "Err: No Sign Change", 0
errorStrSingularMat:
    .db "Err: Singularity", 0
errorStrStat:
    .db "Err: Stat", 0
errorStrStatPlot:
    .db "Err: StatPlot", 0
errorStrSyntax:
    .db "Err: Syntax", 0
errorStrTolTooSmall:
    .db "Err: Tol Not Met", 0
errorStrUndefined:
    .db "Err: Undefined", 0 ; indicates the system error "Undefined"
; Start of RPN83P custom error messages
errorStrQuitApp:
    .db "QUIT", 0 ; handler wants to QUIT the app
errorStrClearScreen:
    .db "Clear Screen", 0 ; handler wants to clear the screen
errorStrUnknown:
    .db "Err: UNKNOWN", 0 ; error string of error code not known
errorStrNotYet:
    .db "Err: NOT YET", 0 ; handler not implemented yet
errorStrRegsCleared:
    .db "REGS Cleared", 0 ; storage registers cleared
errorStrStatCleared:
    .db "STAT Cleared", 0 ; STAT registers cleared
errorStrTvmSet:
    .db "TVM Set", 0
errorStrTvmCalculated:
    .db "TVM Calculated", 0
errorStrTvmReset:
    .db "TVM Reset", 0
errorStrTvmCleared:
    .db "TVM Cleared", 0
