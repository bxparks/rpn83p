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
; Destroys: all, OP1-OP3
FormatDenominate:
    ; Print the target unit name.
    skipRpnObjectTypeHL ; HL=denominate
    ld a, (hl) ; A=unit
    push hl ; stack=[denominate]
    call GetUnitName ; HL=name
    call copyCStringPageTwo ; copy HL to DE
    ; Print '='
    ld a, '='
    ld (de), a
    inc de
    ; Convert denominate into its display value
    pop hl ; stack=[]; HL=denominate
    push de ; stack=[dest]
    call shrinkOp2ToOp1PageTwo ; close the 2-byte gap between OP1 and OP2
    call denominateToDisplayValue ; OP1=displayValue
    ; Format OP1
    ld a, 10 ; maximum width of output
    bcall(_FormReal) ; OP3=formatted string
    ; Copy the formatted string to dest
    pop de ; stack=[]; DE=dest
    ld hl, OP3
    call copyCStringPageTwo ; copy HL to DE
    ret
