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
    ; Extract 'value'
    call extractDenominateValue ; OP1='value'
    ; Format 'value'
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
    call checkValidDenominate ; CF=0 if invalid; A=unitId
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

; Description: Extract the displayable value of the denominate object in HL to
; OP1. In most cases, we want the displayUnit. If the denominate is invalid
; (i.e. its unitId is invalid), the best we can do is print its baseValue.
; Input:
;   - HL:Denominate=denominate
; Output:
;   - OP1:Real=value
; Preserves: DE
extractDenominateValue:
    ld a, (hl) ; A=unitId
    call checkValidDenominate ; CF=0 if invalid; A=unitId
    jp nc, denominateBaseValueToOp1 ; OP1=baseValue
    jp denominateGetDisplayValue ; OP1=displayValue

; Description: Format the value of the denominate object in OP1 to DE.
; Input:
;   - OP1:Real=value
;   - DE:(char*)=stringBuf
; Output:
;   - DE=points to next character
; Destroys: A, BC, HL
formatDenominateValue:
    ; Format OP1
    push de ; stack=[denominate,stringBuf]
    ld a, 10 ; maximum width of output
    bcall(_FormReal) ; OP3=formatted string
    pop de ; stack=[denominate]; DE=stringBuf
    ; Copy the formatted string to dest
    ld hl, OP3
    call copyCStringPageTwo ; copy HL to DE
    ret
