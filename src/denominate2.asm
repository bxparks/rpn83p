;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Routines for RpnDenominate objects.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Convert a Real or an RpnDenominate to the target unit.
; Input:
;   - OP1/OP2:Real|RpnDenominate
;   - A:u8=rpnObjectType
;   - B:u8=srcUnitId
;   - C:u8=targetUnitId
; Output:
;   - OP1/OP2:RpnDenominate
; Destroys: all, OP1-OP3
ConvertUnit:
    cp rpnObjectTypeReal
    jr z, convertRealToRpnDenominate
    cp rpnObjectTypeDenominate
    jr z, changeRpnDenominateUnit
    bcall(_ErrDataType)

; Description: Convert a Real to an RpnDenominate object, converting the value
; into its base unit, then attaching the target unit.
; Input:
;   - OP1:Real=value
;   - A:u8=rpnObjectType
;   - C:u8=targetUnitId
; Output:
;   - OP1/OP2:RpnDenominate
; Destroys: all
convertRealToRpnDenominate:
    call reserveRpnObject; FPS=[rpnDenominate]; HL=rpnDenominate
    ld a, c ; A=targetUnitId
    call setHLRpnDenominatePageTwo; HL:(*Real)=value; preserves A
    call normalizeRealToBaseUnit ; OP1=baseValue; preserves HL
    ; move the result into the 'value' of the rpnDenominate
    ex de, hl ; DE=value
    call move9FromOp1PageTwo ; (DE)=value
    call PopRpnObject1 ; FPS=[]; OP1=rpnDenominate
    ret

; Description: Normalize the value in OP1 to the baseUnit of the unit in
; register A.
; Input:
;   - OP1:Real=value
;   - A:u8=targetUnitId
; Output:
;   -OP1:Real=baseValue
; Preserves: HL
; Destroys: A, BC, DE, OP1, OP2, OP3
normalizeRealToBaseUnit:
    push hl ; stack=[HL]
    push af ; stack=[HL, targetUnitId]
    call pushRaw9Op1 ; FPS=[value]
    pop af ; stack=[HL]; A=targetUnitId
    call GetUnitScale ; OP1=scale
    call popRaw9Op2 ; FPS=[]; OP2=value
    bcall(_FPMult) ; OP1=baseValue=scale*value
    pop hl ; stack=[]; HL=HL
    ret

; Description: Set the unit of an RpnDenominate to the given target unit.
; Input:
;   - OP1/OP2:RpnDenominate
;   - A:u8=rpnObjectType
;   - B:u8=srcUnitId
;   - C:u8=targetUnitId
; Output:
;   - OP1/OP2:RpnDenominate=converted
; Destroys: A, OP1
; Preserves: BC, DE, HL
changeRpnDenominateUnit:
    ld a, b
    cp c
    ret z ; source and target are same unit, do nothing
    ; Check that the unit conversion is allowed
    call checkCompatibleUnitClass
    ; Clobber the new targetUnit
    ld a, c ; A=targetUnitId
    ld (OP1 + rpnDenominateFieldTargetUnit), a ; unit=targetUnitId
    ret

; Description: Check that the unitClasses of units in registers B and C are
; identical.
; Input:
;   - B=srcUnitId
;   - C=targetUnitId
; Destroys: A, IX
; Preserves, BC, DE, HL
; Throws:
;   - Err:Invalid if unit classes don't match
checkCompatibleUnitClass:
    ld a, b
    call GetUnitClass ; A=unitClass; preserves BC, DE, HL
    ld b, a
    ;
    ld a, c
    call GetUnitClass ; A=unitClass; preserves BC, DE, HL
    ;
    cp b
    ret z
    bcall(_ErrInvalid)

;-----------------------------------------------------------------------------

; Description: Convert the Denominate object pointed by HL to a Real at DE
; which is represented in terms of its 'targetUnit' instead of the normalized
; 'baseUnit'.
; Input: HL:Denominate=denominate
; Output: OP1:Real=displayValue
; Destroys: all, OP1-OP4
denominateToDisplayValue:
    ld a, (hl) ; A=targetUnitId
    inc hl ; HL=value
    call move9ToOp2PageTwo ; OP2=value; preserves A
    call GetUnitScale ; OP1=scale
    call op1ExOp2PageTwo ; OP1=value; OP2=scale
    bcall(_FPDiv) ; OP1=displayValue=normalizedValue/scale
    ret
