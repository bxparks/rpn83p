;-----------------------------------------------------------------------------
; Functions and strings related to error codes.
;-----------------------------------------------------------------------------

errorCodeOk equ 0
errorCodeDivByZero equ 1
errorCodeCount equ 65 ; number of error codes

; Function: Initialize both errorCode and errorCodeDisplayed to 0.
initErrorCode:
    ld hl, errorCode
    ld (hl), errorCodeOk
    inc hl
    ld (hl), errorCodeCount ; guaranteed to trigger rendering
    ret

; Function: Set error code to errorCodeOk.
; Output: (errorCode) set
; Destroys: A, HL
clearErrorCode:
    xor a
    ; [[fallthrough]]

; Function: Set error code. The system error code uses the lower 7 bits, so in
; theory there are as many as 128. However, the SDK docs define only about 32.
; So let's hope that only the lower 6 bites (64=$40) are used.
; Input: A: error code
; Output: (errorCode) set
; Destroys: HL
setErrorCode:
    res 7, a
    cp $40
    jr c, setErrorCodeContinue ; if a < $40
    ld a, $40
setErrorCodeContinue:
    ld (errorCode), a
    ret

; Function: getErrorString(A) -> HL
; Description: Get the string for given error code.
; Input: A: error code
; Output: HL: pointer to a C string
; Destroys: DE, HL
getErrorString:
    ld hl, errorStrings
    jp getString

; Function: Save the current errorCode to errorCodeDisplayed.
; Destroys: A, HL
saveErrorCodeDisplayed:
    ld hl, errorCode
    ld a, (hl)
    inc hl
    ld (hl), a
    ret

; Function: Check if errorCode is the same as errorCodeDisplayed
; Output: Z if same, NZ if different
; Destroys: A, HL
checkErrorCodeDisplayed:
    ld hl, errorCode
    ld a, (hl)
    inc hl
    cp (hl)
    ret

;-----------------------------------------------------------------------------

; An array of pointers to C strings. The TI-OS error handle defines the error
; code in the lower 7 bits, for a total of 128 possible values. But the SDK
; documentation defines only 28 or so, but their numerical values are not
; documents. We will use this array of 64 slots to error messages to reverse
; engineer the mapping from errorCode to their meaning.
errorStrings:
    .dw errorStrOk              ; 0, hopefully TI-OS uses 0 as "success"
    .dw errorStrOverflow        ; 1
    .dw errorStrDivBy0          ; 2
    .dw errorStrUnknown         ; 3
    .dw errorStrDomain          ; 4
    .dw errorStrUnknown         ; 5
    .dw errorStrUnknown         ; 6
    .dw errorStrUnknown         ; 7
    .dw errorStrUnknown         ; 8
    .dw errorStrUnknown         ; 9
    .dw errorStrUnknown         ; 10
    .dw errorStrUnknown         ; 11
    .dw errorStrUnknown         ; 12
    .dw errorStrUnknown         ; 13
    .dw errorStrUnknown         ; 14
    .dw errorStrUnknown         ; 15
    .dw errorStrUnknown         ; 16
    .dw errorStrUnknown         ; 17
    .dw errorStrUnknown         ; 18
    .dw errorStrUnknown         ; 19
    .dw errorStrUnknown         ; 20
    .dw errorStrUnknown         ; 21
    .dw errorStrUnknown         ; 22
    .dw errorStrUnknown         ; 23
    .dw errorStrUnknown         ; 24
    .dw errorStrUnknown         ; 25
    .dw errorStrUnknown         ; 26
    .dw errorStrUnknown         ; 27
    .dw errorStrUnknown         ; 28
    .dw errorStrUnknown         ; 29
    .dw errorStrUnknown         ; 30
    .dw errorStrUnknown         ; 31
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
    .dw errorStrUnknown         ; 63
    .dw errorStrUnsupported     ; 64, code unsupported

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
errorStrDimention:
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
errorStrNonReal:
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
    .db "Err: Tool Not Met", 0
errorStrUndefined:
    .db "Err: Undefined", 0 ; indicates a system error "Undefined"
errorStrUnknown:
    .db "Err: UNKNOWN", 0 ; not defined in this module
errorStrUnsupported:
    .db "Err: UNSUPPORTED", 0 ; code above $40
