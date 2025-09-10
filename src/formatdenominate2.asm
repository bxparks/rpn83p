;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2025 Brian T. Park
;
; Formatting routines for denominate numbers (numbers with units) of type
; RpnDenominate.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Format the RpnDenominate object in HL to DE in the form of
; "{unitName}={value}". If the RpnDenominate is invalid (invalid unit), then
; print "ERROR={value}" instead.
; Input:
;   - HL:(const RpnDenominate*)=rpnDenominate
;   - DE:(char*)=dest
; Output:
;   - HL: incremented past end of denominate object
;   - DE: points to NUL char at end of string
; Destroys: all, OP1-OP3
FormatDenominate:
    skipRpnObjectTypeHL ; HL=denominate
    ; Check for error state
    call validateDenominate ; CF=0 if invalid; A=unitId
    jr nc, formatErrorDenominate
    ; Print the target unit name.
    push hl ; stack=[denominate]
    ld hl, OP3 ; buffer for unitName
    bcall(_ExtractUnitName) ; HL=name
    call copyCStringPageTwo ; copy HL to DE
    ; Print '='
    ld a, '='
    ld (de), a
    inc de
    ; Convert denominate into its display value
    pop hl ; stack=[]; HL=denominate
    push de ; stack=[dest]
    call denominateToDisplayValue ; OP1=displayValue
    pop de ; stack=[]; DE=dest
    ; Format OP1
formatDenominateFormatOP1:
    push de ; stack=[dest]
    ld a, 10 ; maximum width of output
    bcall(_FormReal) ; OP3=formatted string
    ; Copy the formatted string to dest
    pop de ; stack=[]; DE=dest
    ld hl, OP3
    call copyCStringPageTwo ; copy HL to DE
    ret

; Description: Format the denominate object in HL to DE.
; Input:
;   - HL:(const Denominate*)=denominate
;   - DE:(char*)=dest
formatErrorDenominate:
    push hl ; stack=[denominate]
    ld hl, unitErrorName
    call copyCStringPageTwo
    pop hl ; stack=[]; HL=denominate
    ; Print '='
    ld a, '='
    ld (de), a
    inc de
    ; Extract the raw value without scaling.
    call denominateValueToOp1 ; OP1=rawValue
    jr formatDenominateFormatOP1

unitErrorName:
    .db "ERROR", 0
