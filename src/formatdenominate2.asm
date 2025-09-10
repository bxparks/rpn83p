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
;   - DE:(char*)=stringBuf
; Output:
;   - HL: incremented past end of denominate object
;   - DE: points to NUL char at end of string
; Destroys: all, OP1-OP3
FormatDenominate:
    skipRpnObjectTypeHL ; HL=denominate
    ; Print 'name'
    call formatDenominateName
    ; Print '='
    ld a, '='
    ld (de), a
    inc de
    ; Print 'value'
    call formatDenominateValue
    ret

; Description: Format the name of denominate object in HL to DE.
; Input:
;   - HL:(const Denominate*)=denominate
;   - DE:(char*)=stringBuf
; Output:
;   - DE=points to next character
; Preserves: BC, HL
; Destroys: A
formatDenominateName:
    ld a, (hl) ; A=unitId
    call validateDenominate ; CF=0 if invalid; A=unitId
    jr nc, formatDenominateNameForInvalid
    ; extract real name
    ex de, hl ; HL=stringBuf; DE=denominate
    bcall(_ExtractUnitName) ; HL=name
    ex de, hl ; DE=stringBuf; HL=denominate
    ret
formatDenominateNameForInvalid:
    ; extract "INVALID"
    push hl ; stack=[denominate]
    ld hl, unitInvalidName
    call copyCStringPageTwo
    pop hl ; stack=[]; HL=denominate
    ret

unitInvalidName:
    .db "INVALID", 0

; Description: Format the value of the denominate object in HL to DE. Convert
; the 'value' into its 'displayUnit', except if the denominate is invalid, in
; which case just print the raw 'value'.
; Input:
;   - HL:(const Denominate*)=denominate
;   - DE:(char*)=stringBuf
; Output:
;   - DE=points to next character
; Preserves: HL
; Destroys: BC, A
formatDenominateValue:
    ld a, (hl) ; A=unitId
    call validateDenominate ; CF=0 if invalid; A=unitId
    jr nc, formatDenominateValueForInvalid
    call denominateToDisplayValue ; OP1=displayValue
    jr formatDenominateValueOP1
formatDenominateValueForInvalid:
    call denominateValueToOp1
    ; [[fallthrough]]
formatDenominateValueOP1:
    push hl ; stack=[denominate]
    ; Format OP1
    push de ; stack=[denominate,stringBuf]
    ld a, 10 ; maximum width of output
    bcall(_FormReal) ; OP3=formatted string
    pop de ; stack=[denominate]; DE=stringBuf
    ; Copy the formatted string to dest
    ld hl, OP3
    call copyCStringPageTwo ; copy HL to DE
    ; Restore stack
    pop hl ; stack=[]; HL=denominate
    ret
