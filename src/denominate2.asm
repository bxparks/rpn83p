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

;-----------------------------------------------------------------------------

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
    call reserveRpnObject; FPS=[rpnDenominate]; HL=rpnDenominate; BC=BC
    ld a, c ; A=targetUnitId
    call setHLRpnDenominatePageTwo; HL:(*Real)=value; A=A; BC=BC
    ; normalize to the base unit
    push hl
    call normalizeRealToBaseUnit ; OP1=baseValue
    pop de ; DE=value
    ; move the result into the 'value' of the rpnDenominate
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
; Destroys: all, OP1, OP2, OP3
normalizeRealToBaseUnit:
    ; Special cases for Temperature.
    cp unitKelvinId
    ret z
    cp unitCelsiusId
    jr z, temperatureCToK
    cp unitFahrenheitId
    jr z, temperatureFToK
    cp unitRankineId
    jr z, temperatureRToK
    ; All other units can be normalized with a simple scaling factor.
    call op1ToOp2PageTwo ; OP2=value; A=A
    call GetUnitScale ; OP1=scale
    bcall(_FPMult) ; OP1=baseValue=scale*value
    ret

;-----------------------------------------------------------------------------

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
    call move9ToOp1PageTwo ; OP1=value; preserves A
    ; Special cases for Temperature.
    cp unitKelvinId
    ret z
    cp unitCelsiusId
    jr z, temperatureKToC
    cp unitFahrenheitId
    jr z, temperatureKToF
    cp unitRankineId
    jr z, temperatureKToR
    ; All other units can be converted with a simple scaling factor.
    call op1ToOp2PageTwo ; OP2=value; preserves A
    call GetUnitScale ; OP1=scale
    call op1ExOp2PageTwo ; OP1=value; OP2=scale
    bcall(_FPDiv) ; OP1=displayValue=normalizedValue/scale
    ret

;-----------------------------------------------------------------------------

; Description: Convert OP1 from Celsius to Kelvin.
; K = C + 273.15
temperatureCToK:
    ld hl, constCelsiusOffset
    call move9ToOp2PageTwo
    bcall(_FPAdd)
    ret

; Description: Convert OP1 from Kelvin to Celsius.
; C = K - 273.15
temperatureKToC:
    ld hl, constCelsiusOffset
    call move9ToOp2PageTwo
    bcall(_FPSub)
    ret

constCelsiusOffset: ; 273.15 K = 0 C
    .db $00, $82, $27, $31, $50, $00, $00, $00, $00

;-----------------------------------------------------------------------------

; Description: Convert OP1 from Fahrenheit to Kelvin.
; K = C + 273.15
temperatureFToK:
    call temperatureFToC
    jr temperatureCToK

; Description: Convert OP1 from Kelvin to Fahrenheit.
; C = K - 273.15
temperatureKToF:
    call temperatureKToC
    jr temperatureCToF

;-----------------------------------------------------------------------------

; Description: Convert OP1 from Rankine to Kelvin.
; K = R * 5/9
temperatureRToK:
    ld a, $18
    bcall(_OP2SetA) ; OP2 = 1.8
    bcall(_FPDiv)
    ret

; Description: Convert OP1 from Kelvin to Rankine.
; R = K * 9/5
temperatureKToR:
    ld a, $18
    bcall(_OP2SetA) ; OP2 = 1.8
    bcall(_FPMult)
    ret

;-----------------------------------------------------------------------------

; Description: Convert OP1 from Celsius to Fahrenheit.
; F = C*9/5 + 32
temperatureCToF:
    ld a, $18
    bcall(_OP2SetA) ; OP2 = 1.8
    bcall(_FPMult) ; OP1 = X * 1.8
    ld a, 32
    bcall(_SetXXOP2) ; OP2 = 32
    bcall(_FPAdd) ; OP1 = 1.8*X + 32
    ret

; Description: Convert OP1 from Fahrenheit to Celsius.
; C = (F - 32) * 5/9
temperatureFToC:
    ld a, 32
    bcall(_SetXXOP2) ; OP2 = 32
    bcall(_FPSub) ; OP1 = X - 32
    ld a, $18
    bcall(_OP2SetA) ; OP2 = 1.8
    bcall(_FPDiv) ; OP1 = (X - 32) / 1.8
    ret
