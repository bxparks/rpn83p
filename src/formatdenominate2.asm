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
    push af ; stack=[unit]
    skipDenominateUnitHL ; HL=value
    push hl ; stack=[unit, value]
    bcall(_GetUnitName) ; HL=name
    call copyCStringPageTwo ; copy HL to DE
    ; Print '='
    ld a, '='
    ld (de), a
    inc de
    ; Extract value into OP1 and format the value.
    ex de, hl ; HL=dest
    ex (sp), hl ; stack=[unit, dest]; HL=value
    call move9ToOp1PageTwo ; OP1=value, works even if HL was in OP1
    ; Convert the normalize value to the target unit.
    pop de ; stack=[unit] ; DE=dest
    pop af ; stack=[]; A=unit
    push de ; stack=[dest]
    call getDenominateDisplayValue ; OP1=displayValue
    ;
    ld a, 10 ; maximum width of output
    bcall(_FormReal) ; OP3=formatted string
    pop de ; stack=[]; DE=dest
    ; Print value.
    ld hl, OP3
    call copyCStringPageTwo ; copy HL to DE
    ret

; Description: Convert the normalizedValue of the RpnDenominate object in terms
; of its unit to get the displayValue shown to the user.
; Input:
;   - OP1:Real=normalizedValue
;   - A:u8=targetUnit
; Output:
;   - OP1:Real=displayValue
; Destroys: all
getDenominateDisplayValue:
    call op1ToOp3PageTwo ; OP3=normalizedValue; preserves A
    call GetUnitScale ; OP1=scale
    call op1ToOp2PageTwo ; OP2=scale
    call op3ToOp1PageTwo ; OP1=normalizedValue
    bcall(_FPDiv) ; OP1=displayvalue=normalizedValue/scale
    ret
