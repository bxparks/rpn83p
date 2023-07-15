;-----------------------------------------------------------------------------
; Functions and strings related to error codes.
;-----------------------------------------------------------------------------

errorCodeOk equ 0
errorCodeDivByZero equ 1
errorCodeCount equ 2 ; number of error codes

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

; Function: Set error code
; Input: A: error code
; Output: (errorCode) set
; Destroys: HL
setErrorCode:
    ld (errorCode), a
    ret

; Function: Get the string for given error code.
; Input: A: error code
; Output: HL: pointer to a C string
; Destroys: DE, HL
getErrorString:
    ld l, a
    ld h, 0
    add hl, hl
    ld de, errorStrings
    add hl, de
    ld e, (hl)
    inc hl
    ld d, (hl)
    ex de, hl
    ret

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

; An array of pointers to C strings.
errorStrings:
    .dw errorStrOk
    .dw errorStrDivByZero

; The C strings for each error code.
errorStrOk:
    .db "OK", 0 ; this won't be displayed, but define the string just in case
errorStrDivByZero:
    .db "Err: Div By Zero", 0
