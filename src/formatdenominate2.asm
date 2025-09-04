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
    skipRpnObjectTypeHL
    skipDenominateUnitHL ; HL=value
    push de ; stack=[dest]
    call move9ToOp1PageTwo ; OP1=value, works even if HL was in OP1
    bcall(_FormReal) ; OP3=formatted string
    pop de ; stack=[]; DE=dest
    ; Create display string for a denominate number.
    ; TODO: print real unit here
    ld hl, unitPrefix
    call copyCStringPageTwo ; copy HL to DE
    ld hl, OP3
    call copyCStringPageTwo ; copy HL to DE
    ret

unitPrefix:
    .db "unit=", 0
