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

; Description: Format the denominate object in HL to DE.
; Input:
;   - HL:(const RpnDenominate*)=rpnDenominate
;   - DE:(char*)=dest
; Output:
;   - HL: incremented past end of denominate object
;   - DE: points to NUL char at end of string
; Destroys: all, OP1-OP6
FormatDenominate:
    ; Print the target unit name.
    skipRpnObjectTypeHL
    ld a, (hl) ; A=unit
    skipDenominateUnitHL ; HL=value
    push hl ; stack=[value]
    bcall(_GetUnitName) ; HL=name
    call copyCStringPageTwo ; copy HL to DE
    ; Print '='
    ld a, '='
    ld (de), a
    inc de
    ; Extract value into OP1 and format the value.
    ex de, hl ; HL=dest
    ex (sp), hl ; stack=[dest]; HL=value
    call move9ToOp1PageTwo ; OP1=value, works even if HL was in OP1
    bcall(_FormReal) ; OP3=formatted string
    pop de ; stack=[]; DE=dest
    ; Print value.
    ld hl, OP3
    call copyCStringPageTwo ; copy HL to DE
    ret
