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

; Description: Return CF=1 if Denominate is valid (unitId is within range).
; Input:
;   - HL:Denominate=denominate
; Output:
;   - A=unitId
;   - CF=1 if valid; CF=0 if invalid
; Preserves: BC, DE, HL
validateDenominate:
    ld a, (hl) ; A=unitId
    cp unitsCount ; if unitId >= unitsCount: CF=0 else: CF=1
    ret

;-----------------------------------------------------------------------------
; Apply a Denominate Unit, converting a Real to an RpnDenominate to changing
; the unit of an existing Denominate.
;-----------------------------------------------------------------------------

; Description: Apply the unit "function" to the given Real or an RpnDenominate.
; 1) If the input is a Real, then convert it into an RpnDenominate with the
; given targetUnitId.
; 2) If the input is an RpnDenominate, then change its unit to the targetUnitId.
; Input:
;   - OP1/OP2:Real|RpnDenominate
;   - A:u8=rpnObjectType
;   - C:u8=targetUnitId
; Output:
;   - OP1/OP2:RpnDenominate
; Destroys: all, OP1-OP3
ApplyUnit: ; TODO: Rename to ApplyRpnDenominateUnit
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
    ; Special cases for temperature units.
    cp unitKelvinId
    ret z
    cp unitCelsiusId
    jp z, temperatureCToK
    cp unitFahrenheitId
    jp z, temperatureFToK
    cp unitRankineId
    jp z, temperatureRToK
    ; Special cases for fuel consumption units.
    cp unitLitersPerHundredKiloMetersId
    ret z
    cp unitMilesPerGallonId
    jp z, fuelMpgToLkm
    ; All other units can be normalized with a simple scaling factor.
    call op1ToOp2PageTwo ; OP2=value; A=A
    bcall(_GetUnitScale) ; OP1=scale
    bcall(_FPMult) ; OP1=baseValue=scale*value
    ret

;-----------------------------------------------------------------------------

; Description: Set the unit of an RpnDenominate to the given target unit.
; Input:
;   - OP1/OP2:RpnDenominate
;   - A:u8=rpnObjectType
;   - C:u8=targetUnitId
; Output:
;   - OP1/OP2:RpnDenominate=converted
; Destroys: A, OP1
; Preserves: BC, DE, HL
changeRpnDenominateUnit:
    ld a, (OP1 + rpnDenominateFieldDisplayUnit) ; A=oldDisplayUnitId
    cp c
    ret z ; source and target are same unit, do nothing
    ; Check that the unit conversion is allowed
    ld b, a ; B=oldDisplayUnitId
    call checkCompatibleUnitClass ; throws Err:Invalid if different unitClass
    ; Clobber the oldDisplayUnitId with new targetUnitId
    ld a, c ; A=targetUnitId
    ld (OP1 + rpnDenominateFieldDisplayUnit), a ; displayUnitId=targetUnitId
    ret

;-----------------------------------------------------------------------------

; Description: Check that CP1=rpnDen1 and CP3=rpnDen3 have compatible unit
; classes.
; Input: CP1, CP3
; Destroys: A, IX
; Preserves, BC, DE, HL
; Throws: Err:Invalid if unit classes don't match
checkCompatibleUnitClassOp1Op3:
    ld a, (OP1 + rpnDenominateFieldDisplayUnit) ; A=op1dDisplayUnitId
    ld b, a ; unit1
    ld a, (OP3 + rpnDenominateFieldDisplayUnit) ; A=op3dDisplayUnitId
    ld c, a ; unit3
    ; [[fallthrough]]

; Description: Check that the unitClasses of units in registers B and C are
; identical.
; Input:
;   - B=srcUnitId
;   - C=targetUnitId
; Destroys: A, IX
; Preserves, BC, DE, HL
; Throws: Err:Invalid if unit classes don't match
checkCompatibleUnitClass:
    ld a, b
    bcall(_GetUnitClass) ; A=unitClass; preserves BC, DE, HL
    ld b, a
    ;
    ld a, c
    bcall(_GetUnitClass) ; A=unitClass; preserves BC, DE, HL
    ;
    cp b
    ret z
    bcall(_ErrInvalid)

;-----------------------------------------------------------------------------

; Description: Throw Err:Invalid if OP1 is TEMP or FUEL units.
; Input:
;   - OP1/OP2:RpnDenominate=den1
; Throws: Err:Invalid
; Destroys: A, HL
checkArithmeticUnitClassOp1:
    ld hl, OP1
    jp checkArithmeticUnitClass

; Description: Throw Err:Invalid if OP3 is TEMP or FUEL units.
checkArithmeticUnitClassOp3:
    ld hl, OP3
    jp checkArithmeticUnitClass

; Description: Throw Err:Invalid if HL is TEMP or FUEL units.
; Input:
;   - HL:RpnDenominate=den
; Throws: Err:Invalid
; Destroys: A, HL
checkArithmeticUnitClass:
    call getHLRpnObjectTypePageTwo ; A=rpnObjectType; preserves HL
    cp rpnObjectTypeDenominate
    ret nz
    ;
    skipRpnObjectTypeHL
    ld a, (HL) ; A=displayUnitId
    ;
    bcall(_GetUnitClass) ; A=unitClass
    cp unitClassTemperature
    jr z, checkUnitClassForAddInvalid
    cp unitClassFuel
    jr z, checkUnitClassForAddInvalid
    ret
checkUnitClassForAddInvalid:
    bcall(_ErrInvalid)

;-----------------------------------------------------------------------------
; Extracting the Denominate value in different ways.
;-----------------------------------------------------------------------------

; Description: Convert the normalized 'value' of the denominate pointed by HL
; to the display value in units of its 'displayUnitId'.
; Input: HL:Denominate=denominate
; Output: OP1:Real=displayValue
; Destroys: all, OP1-OP4
denominateToDisplayValue:
    ld a, (hl) ; A=displayUnitId
    inc hl ; HL=value
    call move9ToOp1PageTwo ; OP1=value; preserves A
    ; Special cases for temperature units.
    cp unitKelvinId
    ret z
    cp unitCelsiusId
    jp z, temperatureKToC
    cp unitFahrenheitId
    jp z, temperatureKToF
    cp unitRankineId
    jp z, temperatureKToR
    ; Special cases for fuel consumption units.
    cp unitLitersPerHundredKiloMetersId
    ret z
    cp unitMilesPerGallonId
    jp z, fuelLkmToMpg
    ; All other units can be converted with a simple scaling factor.
    call op1ToOp2PageTwo ; OP2=value; preserves A
    bcall(_GetUnitScale) ; OP1=scale
    call op1ExOp2PageTwo ; OP1=value; OP2=scale
    bcall(_FPDiv) ; OP1=displayValue=normalizedValue/scale
    ret

;-----------------------------------------------------------------------------

; Description: Extract the denominate 'value' of HL to OP1.
; Input: HL:Denominate=denominate
; Output: OP1:Real=rawValue
; Preserves: all
denominateValueToOp1:
    push hl
    push de
    push bc
    inc hl ; HL=value
    call move9ToOp1PageTwo ; preserves A
    pop bc
    pop de
    pop hl
    ret

; Description: Extract the denominate 'value' of HL to OP1.
; Input:
;   - OP1:Real=rawValue
;   - HL:Denominate=denominate
; Output:
;   - (HL)=denominateValue filled
; Preserves: all
op1ToDenominateValue:
    push hl
    push de
    push bc
    inc hl ; *HL=value
    ex de, hl ; *DE=value
    call move9FromOp1PageTwo ; preserves A
    pop bc
    pop de
    pop hl
    ret

;-----------------------------------------------------------------------------
; Arithmetic operations.
;-----------------------------------------------------------------------------

; Description: Implement CHS (+/-) function on an RpnDenominate.
; Input: OP1/OP2:RpnDenominate=den
; Output: OP1/OP2:RpnDenominate=-den
; Destroys: all
ChsRpnDenominate:
    call checkArithmeticUnitClassOp1 ; throws Err:Invalid
    call PushRpnObject1 ; FPS=[CP1]; HL=rpnDenominate(OP1)
    skipRpnObjectTypeHL ; HL=denominate
    call chsDenominate
    call PopRpnObject1
    ret

; Description: Implement CHS (+/-) function on a Denominate.
; Input: HL:Denominate=den
; Output: HL:Denominate=-den
; Preserves: all
chsDenominate:
    call denominateValueToOp1 ; OP1=value
    push hl
    bcall(_InvOP1S)
    pop hl
    call op1ToDenominateValue ; (*HL)=-value
    ret

;-----------------------------------------------------------------------------

; Description: Add Denominte+Denominate, keeping the displayUnit of OP1 (the
; first) argument.
; Input:
;   - OP1/OP2:RpnDenominate=den1
;   - OP3/OP4:RpnDenominate=den3
; Output:
;   - OP1/OP2:RpnDenominate=den1+den3
; Destroys: all
AddRpnDenominateByDenominate:
    call checkArithmeticUnitClassOp1 ; throws Err:Invalid
    call checkArithmeticUnitClassOp3 ; throws Err:Invalid
    call checkCompatibleUnitClassOp1Op3 ; throws Err:Invalid
    ;
    call PushRpnObject1 ; FPS=[CP1]; HL=rpnDenominate(OP1)
    skipRpnObjectTypeHL
    ex de, hl ; DE=OP1
    call PushRpnObject3 ; FPS=[CP3]; HL=rpnDenominate(OP3)
    skipRpnObjectTypeHL
    ex de, hl ; HL=FPS(OP1); DE=FPS(OP3)
    call addDenominateByDenominate; value(HL)+=value(DE)
    call dropRpnObject ; FPS=[CP1]
    call PopRpnObject1 ; FPS=[]; OP1=RpnObject
    ret

; Description: Add Denominate(DE) to Denominate(HL).
; Input:
;   - HL:Denominate=denHL
;   - DE:Denominate=denDE
; Output:
;   - value(HL)+=value(DE)
addDenominateByDenominate:
    push hl ; stack=[denHL]
    call denominateValueToOp1 ; OP1=valueHL
    ;
    push de ; stack=[denHL,denDE]
    call op1ToOp2PageTwo ; OP2=valueHL
    pop hl ; stack=[denHL]; HL=denDE
    call denominateValueToOp1 ; OP1=valueDE
    bcall(_FPAdd)
    ;
    pop hl ; stack=[]; HL=denHL
    call op1ToDenominateValue ; value(HL)+=value(DE)
    ret

;-----------------------------------------------------------------------------

; Description: Subtract Denominate-Denominate, keeping the displayUnit of OP1
; (the first) argument.
;   - OP1/OP2:RpnDenominate=den1
;   - OP3/OP4:RpnDenominate=den3
; Output:
;   - OP1/OP2:RpnDenominate=den1-den3
; Destroys: all
SubRpnDenominateByDenominate:
    call checkArithmeticUnitClassOp1 ; throws Err:Invalid
    call checkArithmeticUnitClassOp3 ; throws Err:Invalid
    call checkCompatibleUnitClassOp1Op3 ; throws Err:Invalid
    ;
    call PushRpnObject1 ; FPS=[CP1]; HL=rpnDenominate(OP1)
    skipRpnObjectTypeHL
    ;
    ex de, hl ; DE=OP1
    call PushRpnObject3 ; FPS=[CP3]; HL=rpnDenominate(OP3)
    skipRpnObjectTypeHL
    ;
    call chsDenominate ; den3=-den3; preserves DE, HL
    ex de, hl ; HL=FPS(OP1); DE=FPS(OP3)
    ;
    call addDenominateByDenominate; value(HL)+=value(DE)
    call dropRpnObject ; FPS=[CP1]
    call PopRpnObject1 ; FPS=[]; OP1=RpnObject
    ret

;-----------------------------------------------------------------------------

; Description: Multiply Denominte*Real or Real*Denominate.
; Input:
;   - OP1/OP2:RpnDenominate|Real=obj1
;   - OP3/OP4:RpnDenominate|Real=obj3
; Output:
;   - OP1/OP2:Denominate=den*value
MultRpnDenominateByReal:
    call checkArithmeticUnitClassOp1 ; throws Err:Invalid
    call checkArithmeticUnitClassOp3 ; throws Err:Invalid
    ;
    call getOp1RpnObjectTypePageTwo ; A=type; HL=OP1
    cp rpnObjectTypeReal
    call z, cp1ExCp3PageTwo ; CP1=rpnDenominate; CP3=real
    ;
    call PushRpnObject1 ; FPS=[rpnDenominate]; HL=FPS(rpnDenominate)
    skipRpnObjectTypeHL ; HL=denominate
    push hl ; stack=[denominate]
    call denominateValueToOp1 ; OP1=value
    call op3ToOp2PageTwo ; OP2=real
    bcall(_FPMult) ; OP1=real*value
    ;
    pop hl ; stack=[]; HL=denominate
    call op1ToDenominateValue ; value(denominate)*=real*value
    ;
    call PopRpnObject1 ; FPS=[]; OP1=result
    ret

;-----------------------------------------------------------------------------

; Description: Multiply Denominte*Real or Real*Denominate.
; Input:
;   - OP1/OP2:RpnDenominate|Real=denominate
;   - OP3/OP4:Real=real
; Output:
;   - OP1/OP2:Denominate=den/value
DivRpnDenominateByReal:
    call checkArithmeticUnitClassOp1 ; throws Err:Invalid
    call checkArithmeticUnitClassOp3 ; throws Err:Invalid
    ;
    call PushRpnObject1 ; FPS=[rpnDenominate]; HL=FPS(rpnDenominate)
    skipRpnObjectTypeHL ; HL=denominate
    push hl ; stack=[denominate]
    call denominateValueToOp1 ; OP1=value
    call op3ToOp2PageTwo ; OP2=real
    bcall(_FPDiv) ; OP1=real/value
    ;
    pop hl ; stack=[]; HL=denominate
    call op1ToDenominateValue ; value(denominate)*=real*value
    ;
    call PopRpnObject1 ; FPS=[]; OP1=result
    ret

;-----------------------------------------------------------------------------
; Converters for special units which cannot be converted by simple scaling. For
; example temperature units (C, F, R, K) and fuel consumption units (mpg,
; L/100km).
;-----------------------------------------------------------------------------

; Description: Convert OP1 from Celsius to Kelvin.
; K = C + 273.15
; Input: OP1:Real=celsius
temperatureCToK:
    ld hl, constCelsiusOffset
    call move9ToOp2PageTwo
    bcall(_FPAdd)
    ret

; Description: Convert OP1 from Kelvin to Celsius.
; C = K - 273.15
; Input: OP1:Real=kelvin
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
; Input: OP1:Real=fahrenheit
temperatureFToK:
    call temperatureFToC
    jr temperatureCToK

; Description: Convert OP1 from Kelvin to Fahrenheit.
; C = K - 273.15
; Input: OP1:Real=kelvin
temperatureKToF:
    call temperatureKToC
    jr temperatureCToF

;-----------------------------------------------------------------------------

; Description: Convert OP1 from Rankine to Kelvin.
; K = R * 5/9
; Input: OP1:Real=rankine
temperatureRToK:
    ld a, $18
    bcall(_OP2SetA) ; OP2 = 1.8
    bcall(_FPDiv)
    ret

; Description: Convert OP1 from Kelvin to Rankine.
; R = K * 9/5
; Input: OP1:Real=kelvin
temperatureKToR:
    ld a, $18
    bcall(_OP2SetA) ; OP2 = 1.8
    bcall(_FPMult)
    ret

;-----------------------------------------------------------------------------

; Description: Convert OP1 from Celsius to Fahrenheit.
; F = C*9/5 + 32
; Input: OP1:Real=celsius
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
; Input: OP1:Real=kelvin
temperatureFToC:
    ld a, 32
    bcall(_SetXXOP2) ; OP2 = 32
    bcall(_FPSub) ; OP1 = X - 32
    ld a, $18
    bcall(_OP2SetA) ; OP2 = 1.8
    bcall(_FPDiv) ; OP1 = (X - 32) / 1.8
    ret

;-----------------------------------------------------------------------------

; Description: Convert miles per gallon (US) to liters per 100km (everywhere
; else).
;   Lkm = 100/[mpg * (km/mile) / (litre/gal)]
; Input: OP1:Real=mpg
fuelMpgToLkm:
    call op2SetKmPerMi
    bcall(_FPMult)
    call op2SetLPerGal
    bcall(_FPDiv)
    call op1ToOp2PageTwo
    call op1Set100PageTwo
    bcall(_FPDiv)
    ret

; Description: Convert liters per 100km to mpg.
;   mpg = 100/lkm * (litre/gal) / (km/mile).
; Input: OP1:Real=Lkm
fuelLkmToMpg:
    call op1ToOp2PageTwo
    call op1Set100PageTwo
    bcall(_FPDiv)
    call op2SetLPerGal
    bcall(_FPMult)
    call op2SetKmPerMi
    bcall(_FPDiv)
    ret

op2SetKmPerMi:
    ld hl, constKmPerMi
    jp move9ToOp2PageTwo

op2SetLPerGal:
    ld hl, constLPerGal
    jp move9ToOp2PageTwo

constKmPerMi: ; 1.609344 km/mi, exact
    .db $00, $80, $16, $09, $34, $40, $00, $00, $00

constLPerGal: ; 3.785 411 784 L/gal, exact, gallon == 231 in^3
    .db $00, $80, $37, $85, $41, $17, $84, $00, $00
