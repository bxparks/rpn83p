;-----------------------------------------------------------------------------
; Functions and strings related to error codes.
;-----------------------------------------------------------------------------

errorCodeOk equ 0
; error codes added by RPN83P
errorCodeNotYet equ 64 ; NOT YET
errorCodeUnexpected equ 65 ; UNEXPECTED; any code >= errorCodeCount
; total number of error codes
errorCodeCount equ 66 ; total number of error codes

; Function: Initialize both errorCode and errorCodeDisplayed to 0.
initErrorCode:
    ld hl, errorCode
    ld (hl), errorCodeOk
    inc hl
    ld (hl), errorCodeCount ; guaranteed to trigger rendering
    ret

; Description: Mark the error code as dirty to force rerendering.
; Destroys: A
dirtyErrorCode:
    ld a, errorCodeCount ; guaranteed to trigger rendering
    ld (errorCodeDisplayed), a
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
    res 7, a ; reset the GOTO flag
    cp errorCodeCount
    jr c, setErrorCodeContinue
    ld a, errorCodeCount - 1 ; Unexpected
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

; An array of pointers to C strings. The TI-OS error handler defines the error
; code in the lower 7 bits, for a total of 128 possible values. But the SDK
; documentation defines `bjump()` calls for only 28 or so. Unfortunately, the
; numerical error code values passed through the `A` register are not
; documented.
;
; The following numerical error codes below were reverse engineered by calling
; the `bjump(_ErrXXX)` one at a time, trapping the exception, then printing out
; the code written into the `A` register. They match the codes given in this
; wiki page, https://learn.cemetech.net/index.php?title=Z80:Error_Codes, which
; seems to contain additional error codes which are not documented in the SDK
; docs. We will ignore those extra error codes in this application.
;
; This table defines additional custom error codes used internally by this
; application:
; - errorStrOk (0): OK or success status code
; - errorStrNotYet (64): not yet implemented
; - errorStrUnknown: This string is bound to any error code whose error string
; has not been reverse engineered, so it is unknown to this application. If the
; user sends a reproducible bug report, maybe we can reverse engineer the
; condition that triggers that particular error code.
; - errorStrUnexpected (65): unexpected error code. This error message means
; that the error code received from the exception handler was above the highest
; error code supported by this application. Even though there are 128 possible
; error codes, we expect that the TI-OS will use only the bottom 32 or 64
; codes.
errorStrings:
    .dw errorStrOk              ; 0, hopefully TI-OS uses 0 as "success"
    .dw errorStrOverflow        ; 1
    .dw errorStrDivBy0          ; 2
    .dw errorStrSingularMat     ; 3
    .dw errorStrDomain          ; 4
    .dw errorStrIncrement       ; 5
    .dw errorStrBreak           ; 6
    .dw errorStrNon_Real        ; 7
    .dw errorStrSyntax          ; 8, also triggered by ErrNonReal??
    .dw errorStrDataType        ; 9, also triggered by ErrNonReal??
    .dw errorStrArgument        ; 10
    .dw errorStrDimMismatch     ; 11
    .dw errorStrDimension       ; 12
    .dw errorStrUndefined       ; 13
    .dw errorStrMemory          ; 14
    .dw errorStrInvalid         ; 15
    .dw errorStrUnknown         ; 16
    .dw errorStrUnknown         ; 17
    .dw errorStrUnknown         ; 18
    .dw errorStrUnknown         ; 19
    .dw errorStrUnknown         ; 20
    .dw errorStrStat            ; 21
    .dw errorStrUnknown         ; 22
    .dw errorStrUnknown         ; 23
    .dw errorStrSignChange      ; 24
    .dw errorStrIterations      ; 25
    .dw errorStrBadGuess        ; 26
    .dw errorStrStatPlot        ; 27
    .dw errorStrTolTooSmall     ; 28
    .dw errorStrUnknown         ; 29
    .dw errorStrUnknown         ; 30
    .dw errorStrLinkXmit        ; 31
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
    .dw errorStrNotYet          ; 64, not yet implemented
    .dw errorStrUnexpected      ; 65, unexpected error code

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
errorStrUnknown:
    .db "Err: UNKNOWN", 0 ; not defined in this module
errorStrNotYet:
    .db "Err: NOT YET", 0 ; not implemented yet
errorStrUnexpected:
    .db "Err: UNEXPECTED", 0 ; code above $40
