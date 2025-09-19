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

;-----------------------------------------------------------------------------
; Apply a Denominate Unit, converting a Real to an RpnDenominate to changing
; the unit of an existing Denominate.
;-----------------------------------------------------------------------------

; Description: Apply the unit "function" to the given Real or an RpnDenominate.
; 1) If the input is a Real, then convert the displayValue into an
; RpnDenominate with the given displayUnitId.
; 2) If the input is an RpnDenominate, then change its unit to the
; displayUnitId.
; Input:
;   - OP1/OP2:Real|RpnDenominate
;   - A:u8=rpnObjectType
;   - C:u8=displayUnitId
; Output:
;   - OP1/OP2:RpnDenominate
; Destroys: all, OP1-OP3
ApplyRpnDenominateUnit:
    cp rpnObjectTypeReal
    jr z, convertDisplayValueToRpnDenominate
    cp rpnObjectTypeDenominate
    jr z, changeRpnDenominateUnit
    bcall(_ErrDataType)

;-----------------------------------------------------------------------------

; Description: Convert the given displayValue to an RpnDenominate object which
; holds its equilvalent baseValue in the baseUnit of the displayUnit.
; Input:
;   - OP1:Real=displayValue
;   - C:u8=displayUnitId
; Output:
;   - OP1/OP2:RpnDenominate
; Destroys: all
convertDisplayValueToRpnDenominate:
    call reserveRpnObject; FPS=[rpnDenominate]; (HL)=rpnDenominate; BC=BC
    ld a, c ; A=displayUnitId
    call setHLRpnDenominatePageTwo; (HL):Denominate=den; A=A; BC=BC
    call denominateSetDisplayValue ; den.baseValue=baseValue(OP1)
    call PopRpnObject1 ; FPS=[]; OP1=rpnDenominate
    ret

; Description: Set the baseValue of the given Denominate by converting the
; displayValue given in OP1 to the baseValue in the baseUnit of
; Denominate.displayUnit. This is the inverse of denominateGetDisplayValue().
; Input:
;   - (HL):Denominate=den
;   - OP1:Real=displayValue
; Output:
;   - (HL):Denominate=denominate with new baseValue
; Destroys: all
denominateSetDisplayValue:
    ; convert displayValue to the baseValue in the baseUnit
    ld a, (hl) ; A=displayUnit
    inc hl ; (HL):Real=baseValue
    push hl ; stack=[&den.baseValue]
    call convertDisplayValueToBaseValue ; OP1=baseValue
    pop de ; stack=[]; DE=&den.baseValue
    ; move the result into the 'value' of the rpnDenominate
    call move9FromOp1PageTwo ; (DE)=den.basValue=OP1=baseValue
    ret

; Description: Convert the given displayValue given in displayUnit in OP1 to
; the baseValue in the baseUnit of the displayUnit.
; Input:
;   - OP1:Real=displayValue
;   - A:u8=displayUnitId
; Output:
;   -OP1:Real=baseValue
; Destroys: all, OP1, OP2, OP3
convertDisplayValueToBaseValue:
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

; Description: Set the unit of an RpnDenominate to the given target displayUnit.
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
    ; Validate that the unit conversion is allowed
    ld b, a ; B=oldDisplayUnitId
    call validateCompatibleUnitClass ; throws Err:Invalid if different unitClass
    ; Clobber the oldDisplayUnitId with new targetUnitId
    ld a, c ; A=targetUnitId
    ld (OP1 + rpnDenominateFieldDisplayUnit), a ; displayUnitId=targetUnitId
    ret

;-----------------------------------------------------------------------------
; Validation functions, often looking at the unitClass.
;-----------------------------------------------------------------------------

; Description: Return CF=1 if Denominate is valid (unitId is within range).
; Input:
;   - HL:Denominate=denominate
; Output:
;   - A=unitId
;   - CF=1 if valid; CF=0 if invalid
; Preserves: BC, DE, HL
checkValidDenominate:
    ld a, (hl) ; A=unitId
    cp unitsCount ; if unitId >= unitsCount: CF=0 else: CF=1
    ret

;-----------------------------------------------------------------------------

; Description: Validate that CP1=rpnDen1 and CP3=rpnDen3 have compatible unit
; classes.
; Input: CP1, CP3
; Destroys: A, BC, IX
; Preserves, DE, HL
; Throws: Err:Invalid if unit classes don't match
validateCompatibleUnitClassOp1Op3:
    ld a, (OP1 + rpnDenominateFieldDisplayUnit) ; A=op1dDisplayUnitId
    ld b, a ; unit1
    ld a, (OP3 + rpnDenominateFieldDisplayUnit) ; A=op3dDisplayUnitId
    ld c, a ; unit3
    ; [[fallthrough]]

; Description: Validate that the unitClasses of units in registers B and C are
; identical.
; Input:
;   - B=srcUnitId
;   - C=targetUnitId
; Destroys: A, BC, IX
; Preserves, DE, HL
; Throws: Err:Invalid if unit classes don't match
validateCompatibleUnitClass:
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
validateArithmeticUnitClassOp1:
    ld hl, OP1
    jp validateArithmeticUnitClass

; Description: Throw Err:Invalid if OP3 is TEMP or FUEL units.
validateArithmeticUnitClassOp3:
    ld hl, OP3
    jp validateArithmeticUnitClass

; Description: Throw Err:Invalid if HL is TEMP or FUEL units.
; Input:
;   - HL:RpnDenominate=den
; Throws: Err:Invalid
; Destroys: A, HL
validateArithmeticUnitClass:
    call getHLRpnObjectTypePageTwo ; A=rpnObjectType; preserves HL
    cp rpnObjectTypeDenominate
    ret nz
    ;
    skipRpnObjectTypeHL
    ld a, (HL) ; A=displayUnitId
    ;
    bcall(_GetUnitClass) ; A=unitClass
    cp unitClassTemperature
    jr z, validateUnitClassForAddInvalid
    cp unitClassFuel
    jr z, validateUnitClassForAddInvalid
    ret
validateUnitClassForAddInvalid:
    bcall(_ErrInvalid)

;-----------------------------------------------------------------------------
; Convert RpnDenominate to its base unit.
;-----------------------------------------------------------------------------

; Description: Convert the RpnDenominate object to its 'baseUnit'.
; Input:
;   - A:u8=rpnObjectType
;   - OP1/OP2:RpnDenominate=rpnDenominate
; Output:
;   - OP1/OP2:RpnDenominate=rpnDenominate
; Destroys: all, OP1-OP3
ConvertRpnDenominateToBaseUnit:
    cp rpnObjectTypeDenominate
    jr nz, convertRpnDenominateToBaseUnitErr
    ;
    call PushRpnObject1 ; FPS=[rpnDenominate]; HL=rpnDenominate
    skipRpnObjectTypeHL ; HL=denominate
    ld a, (hl); A=unitId
    bcall(_GetUnitBase) ; A=baseUnitId
    ld (hl), a ; denominate.displayUnit=baseUnit
    call PopRpnObject1 ; FPS=[]; OP1=rpnDenominate
    ret
convertRpnDenominateToBaseUnitErr:
    bcall(_ErrDataType)

;-----------------------------------------------------------------------------
; Extracting the Denominate value in different ways.
;-----------------------------------------------------------------------------

; Description: Extract the display value of RpnDenominate as a Real number,
; removing the unit from the RpnObject.
; Input:
;   - OP1/OP2:RpnDenominate=rpnDenominate
; Output:
;   - OP1:Real=displayValue
; Destroys: all, OP1-OP3
GetRpnDenominateDisplayValue:
    cp rpnObjectTypeDenominate
    jr nz, getRpnDenominateDisplayValueErr
    ;
    call PushRpnObject1 ; FPS=[rpnDenominate]; HL=rpnDenominate
    skipRpnObjectTypeHL ; HL=denominate
    call denominateGetDisplayValue ; OP1=displayValue
    call dropRpnObject ; FPS=[];
    ret
getRpnDenominateDisplayValueErr:
    bcall(_ErrDataType)

; Description: Get the displayValue of the denominate pointed by HL by
; converting its internval baseValue to the unit of its 'displayUnitId'. This
; is the inverse of denominateSetDisplayValue().
; Input: HL:Denominate=denominate
; Output: OP1:Real=displayValue
; Preserves: BC, DE, HL
; Destroys: A, OP1-OP4
denominateGetDisplayValue:
    push bc
    push de
    push hl
    call denominateGetDisplayValueInternal
    pop hl
    pop de
    pop bc
    ret

; Description: Version of denominateGetDisplayValue() that does not care about
; destroying all the registers. This version is much simpler when we don't have
; to worry about cleaning up the stack, because we can return early.
denominateGetDisplayValueInternal:
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

; Description: Extract the baseValue of the denominate given by HL to OP1.
; Input: HL:Denominate=denominate
; Output: OP1:Real=baseValue
; Preserves: all
denominateBaseValueToOp1:
    push hl
    push de
    push bc
    inc hl ; HL=value
    call move9ToOp1PageTwo ; preserves A
    pop bc
    pop de
    pop hl
    ret

; Description: Set the baseValue of the denominate in HL to OP1.
; Input:
;   - OP1:Real=baseValue
;   - HL:Denominate=denominate
; Output:
;   - (HL).baseValue=baseValue
; Preserves: all
op1ToDenominateBaseValue:
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
    call validateArithmeticUnitClassOp1 ; throws Err:Invalid
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
    call denominateBaseValueToOp1 ; OP1=value
    push hl
    bcall(_InvOP1S)
    pop hl
    call op1ToDenominateBaseValue ; (*HL)=-value
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
    call validateArithmeticUnitClassOp1 ; throws Err:Invalid
    call validateArithmeticUnitClassOp3 ; throws Err:Invalid
    call validateCompatibleUnitClassOp1Op3 ; throws Err:Invalid
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
    call denominateBaseValueToOp1 ; OP1=valueHL
    ;
    push de ; stack=[denHL,denDE]
    call op1ToOp2PageTwo ; OP2=valueHL
    pop hl ; stack=[denHL]; HL=denDE
    call denominateBaseValueToOp1 ; OP1=valueDE
    bcall(_FPAdd)
    ;
    pop hl ; stack=[]; HL=denHL
    call op1ToDenominateBaseValue ; value(HL)+=value(DE)
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
    call validateArithmeticUnitClassOp1 ; throws Err:Invalid
    call validateArithmeticUnitClassOp3 ; throws Err:Invalid
    call validateCompatibleUnitClassOp1Op3 ; throws Err:Invalid
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
    call validateArithmeticUnitClassOp1 ; throws Err:Invalid
    call validateArithmeticUnitClassOp3 ; throws Err:Invalid
    ;
    call getOp1RpnObjectTypePageTwo ; A=type; HL=OP1
    cp rpnObjectTypeReal
    call z, cp1ExCp3PageTwo ; CP1=rpnDenominate; CP3=real
    ;
    call PushRpnObject1 ; FPS=[rpnDenominate]; HL=FPS(rpnDenominate)
    skipRpnObjectTypeHL ; HL=denominate
    push hl ; stack=[denominate]
    call denominateBaseValueToOp1 ; OP1=value
    call op3ToOp2PageTwo ; OP2=real
    bcall(_FPMult) ; OP1=real*value
    ;
    pop hl ; stack=[]; HL=denominate
    call op1ToDenominateBaseValue ; value(denominate)*=real*value
    ;
    call PopRpnObject1 ; FPS=[]; OP1=result
    ret

;-----------------------------------------------------------------------------

; Description: Divide Denominte/Denominate to get a Real number.
; Input:
;   - OP1/OP2:RpnDenominate=dividend
;   - OP3/OP4:RpnDenominate=divisor
; Output:
;   - OP1/OP2:Real=dividend/divisor
DivRpnDenominateByDenominate:
    call validateArithmeticUnitClassOp1 ; throws Err:Invalid
    call validateArithmeticUnitClassOp3 ; throws Err:Invalid
    call validateCompatibleUnitClassOp1Op3 ; throws Err:Invalid
    ;
    call PushRpnObject1 ; FPS=[divisor,dividend]; HL=FPS(dividend)
    skipRpnObjectTypeHL ; HL=dividend
    push hl ; stack=[dividend]
    ;
    call PushRpnObject3 ; FPS=[divisor]; HL=FPS(divisor)
    skipRpnObjectTypeHL ; HL=divisor
    ;
    call denominateBaseValueToOp1 ; OP1=divisor
    call op1ToOp2PageTwo ; OP2=divisor
    ;
    pop hl ; stack=[]; HL=dividend
    call denominateBaseValueToOp1 ; OP1=dividend
    ;
    bcall(_FPDiv) ; OP1=dividend/divisor
    ;
    call dropRpnObject
    call dropRpnObject ; FPS=[]
    ret

;-----------------------------------------------------------------------------

; Description: Divide Denominte/Real.
; Input:
;   - OP1/OP2:RpnDenominate=den
;   - OP3/OP4:Real=divisor
; Output:
;   - OP1/OP2:Denominate=den/divisor
DivRpnDenominateByReal:
    call validateArithmeticUnitClassOp1 ; throws Err:Invalid
    ;
    call PushRpnObject1 ; FPS=[rpnDenominate]; HL=FPS(rpnDenominate)
    skipRpnObjectTypeHL ; HL=denominate
    push hl ; stack=[denominate]
    call denominateBaseValueToOp1 ; OP1=value
    call op3ToOp2PageTwo ; OP2=real
    bcall(_FPDiv) ; OP1=real/value
    ;
    pop hl ; stack=[]; HL=denominate
    call op1ToDenominateBaseValue ; value(denominate)*=real*value
    ;
    call PopRpnObject1 ; FPS=[]; OP1=result
    ret

;-----------------------------------------------------------------------------
; Numerical operations: %, %CH, IP, FP, FLR, CEIL, NEAR, ABS, SIGN, MIN, MAX,
; RND, RNDN, RNDG
;-----------------------------------------------------------------------------

; Description: Return the X% of Y.
; Input:
;   - CP1:RpnDenominate=Y
;   - CP3:Real=X (percent)
; Output:
;    - CP1:RpnDenominate=Y*X/100
RpnDenominatePercent:
    call validateArithmeticUnitClassOp1 ; throws Err:Invalid
    ;
    call PushRpnObject1 ; FPS=[rpnDen]; HL=rpnDen
    skipRpnObjectTypeHL ; HL=den
    call denominateBaseValueToOp1 ; OP1:Real=baseValue
    push hl
    call op3ToOp2PageTwo
    bcall(_PercentFunction) ; OP1=Y*X/100
    pop hl
    call op1ToDenominateBaseValue ; rpnDen=abs(baseValue)
    call PopRpnObject1 ; CP1:RpnDenominate
    ret

; Description: Return the percentage change from Y to X.
; Input:
;   - CP1:RpnDenominate=Y
;   - CP3:RpnDenominate=X
; Output:
;    - CP1:Real=100*(X-Y)/Y
RpnDenominatePercentChange:
    call validateArithmeticUnitClassOp1 ; throws Err:Invalid
    call validateArithmeticUnitClassOp3 ; throws Err:Invalid
    call validateCompatibleUnitClassOp1Op3 ; throws Err:Invalid
    ;
    call PushRpnObject1 ; FPS=[rpnDenY]; HL=rpnDenY
    push hl ; stack=[rpnDenY]
    call PushRpnObject3 ; FPS=[valueY,rpnDenX]; HL=rpnDenX
    ;
    skipRpnObjectTypeHL ; HL=denX
    call denominateBaseValueToOp1 ; OP1:Real=valueX
    call op1ToOp2PageTwo ; OP2=valueX
    ;
    pop hl ; stack=[]; HL=rpnDenY
    skipRpnObjectTypeHL ; HL=denY
    call denominateBaseValueToOp1 ; OP1:Real=valueY

    call dropRpnObject ; FPS=[valueY]
    call dropRpnObject ; FPS=[]
    ;
    bcall(_PercentChangeFunction) ; OP1=100*(X-Y)/Y
    ret

; Description: Return the abs(x).
; Input: CP1:RpnDenominate=rpnDen
; Output: CP1:RpnDenominate=abs(rpnDen)
RpnDenominateAbs:
    call validateArithmeticUnitClassOp1 ; throws Err:Invalid
    ;
    call PushRpnObject1 ; FPS=[rpnDen]; HL=rpnDen
    skipRpnObjectTypeHL ; HL=den
    call denominateBaseValueToOp1 ; OP1:Real=baseValue
    push hl
    bcall(_ClrOP1S) ; clear sign bit of OP1
    pop hl
    call op1ToDenominateBaseValue ; rpnDen=abs(baseValue)
    call PopRpnObject1
    ret

; Description: Return the sign(x).
; Input: CP1:RpnDenominate=rpnDen
; Output: OP1:Real=sign(x)
RpnDenominateSign:
    call validateArithmeticUnitClassOp1 ; throws Err:Invalid
    ;
    call PushRpnObject1 ; FPS=[rpnDen]; HL=rpnDen
    skipRpnObjectTypeHL ; HL=den
    call denominateBaseValueToOp1 ; OP1:Real=baseValue
    bcall(_SignFunction) ; sign(baseValue)
    call dropRpnObject ; FPS=[]
    ret

; Description: Return the min(X, Y).
; Input:
;   - CP1:RpnDenominate=rpnDenY
;   - CP3:RpnDenominate=rpnDenX
; Output:
;   - CP1:RpnDenominateSign=min(X,Y) using unit of the winning denominate
;   - if equal, prefer Y unit over X unit
RpnDenominateMin:
    call validateArithmeticUnitClassOp1 ; throws Err:Invalid
    call validateArithmeticUnitClassOp3 ; throws Err:Invalid
    call validateCompatibleUnitClassOp1Op3 ; throws Err:Invalid
    ;
    call PushRpnObject1 ; FPS=[rpnDenY]; HL=rpnDenY
    push hl ; stack=[rpnDenY]
    call PushRpnObject3 ; FPS=[rpnDenY,rpnDenX]; HL=rpnDenX
    ;
    skipRpnObjectTypeHL ; HL=denX
    call denominateBaseValueToOp1 ; OP1:Real=baseValueX
    call op1ToOp2PageTwo ; OP2=baseValueX
    ;
    pop hl ; stack=[]; HL=rpnDenY
    skipRpnObjectTypeHL ; HL=denY
    call denominateBaseValueToOp1 ; OP1=baseValueY
    ;
    bcall(_CpOP1OP2) ; OP1-OP2 => ZF, CF flags
    jr c, rpnDenominateMinSelectY
    jr z, rpnDenominateMinSelectY
rpnDenominateMinSelectX:
    call PopRpnObject1 ; FPS=[rpnDenY]; OP1=rpnDenX
    call dropRpnObject ; FPS=[]
    ret
rpnDenominateMinSelectY:
    call dropRpnObject ; FPS=[rpnDenY]
    call PopRpnObject1 ; FPS=[]; OP1=rpnDenY
    ret

; Description: Return the max(X, Y).
; Input:
;   - CP1:RpnDenominate=rpnDenY
;   - CP3:RpnDenominate=rpnDenX
; Output:
;   - CP1:RpnDenominateSign=max(X,Y) using unit of the winning denominate
;   - if equal, prefer Y unit over X unit
RpnDenominateMax:
    call validateArithmeticUnitClassOp1 ; throws Err:Invalid
    call validateArithmeticUnitClassOp3 ; throws Err:Invalid
    call validateCompatibleUnitClassOp1Op3 ; throws Err:Invalid
    ;
    call PushRpnObject1 ; FPS=[rpnDenY]; HL=rpnDenY
    push hl ; stack=[rpnDenY]
    call PushRpnObject3 ; FPS=[rpnDenY,rpnDenX]; HL=rpnDenX
    ;
    skipRpnObjectTypeHL ; HL=denX
    call denominateBaseValueToOp1 ; OP1:Real=baseValueX
    call op1ToOp2PageTwo ; OP2=baseValueX
    ;
    pop hl ; stack=[]; HL=rpnDenY
    skipRpnObjectTypeHL ; HL=denY
    call denominateBaseValueToOp1 ; OP1=baseValueY
    ;
    bcall(_CpOP1OP2) ; OP1-OP2 => ZF, CF flags
    jr nc, rpnDenominateMaxSelectY
rpnDenominateMaxSelectX:
    call PopRpnObject1 ; FPS=[rpnDenY]; OP1=rpnDenX
    call dropRpnObject ; FPS=[]
    ret
rpnDenominateMaxSelectY:
    call dropRpnObject ; FPS=[rpnDenY]
    call PopRpnObject1 ; FPS=[]; OP1=rpnDenY
    ret

;-----------------------------------------------------------------------------

; Description: Return the IntPart(x).
; Input: CP1:RpnDenominate=rpnDen
; Output: CP1:RpnDenominate=IntPart(rpnDen)
RpnDenominateIntPart:
    call PushRpnObject1 ; FPS=[rpnDen]; HL=rpnDen
    skipRpnObjectTypeHL ; HL=den
    call denominateGetDisplayValue ; OP1:Real=displayValue
    push hl ; stack=[den]
    bcall(_Trunc) ; integer part, truncating towards 0.0, preserving sign
    pop hl ; stack=[]; HL=den
    call denominateSetDisplayValue ; den.baseValue=displayValue(result)
    call PopRpnObject1 ; FPS=[]; OP1=rpnDen
    ret

; Description: Return the FracPart(x).
; Input: CP1:RpnDenominate=rpnDen
; Output: CP1:RpnDenominate=FracPart(rpnDen)
RpnDenominateFracPart:
    call PushRpnObject1 ; FPS=[rpnDen]; HL=rpnDen
    skipRpnObjectTypeHL ; HL=den
    call denominateGetDisplayValue ; OP1:Real=displayValue
    push hl ; stack=[den]
    bcall(_Frac) ; fractional part, preserving sign
    pop hl ; stack=[]; HL=den
    call denominateSetDisplayValue ; den.baseValue=displayValue(result)
    call PopRpnObject1 ; FPS=[]; OP1=rpnDen
    ret

; Description: Return the Floor(x).
; Input: CP1:RpnDenominate=rpnDen
; Output: CP1:RpnDenominate=Floor(rpnDen)
RpnDenominateFloor:
    call PushRpnObject1 ; FPS=[rpnDen]; HL=rpnDen
    skipRpnObjectTypeHL ; HL=den
    call denominateGetDisplayValue ; OP1:Real=displayValue
    push hl ; stack=[den]
    bcall(_Intgr) ; convert to integer towards -Infinity
    pop hl ; stack=[]; HL=den
    call denominateSetDisplayValue ; den.baseValue=displayValue(result)
    call PopRpnObject1 ; FPS=[]; OP1=rpnDen
    ret

; Description: Return the Ceil(x).
; Input: CP1:RpnDenominate=rpnDen
; Output: CP1:RpnDenominate=Ceil(rpnDen)
RpnDenominateCeil:
    call PushRpnObject1 ; FPS=[rpnDen]; HL=rpnDen
    skipRpnObjectTypeHL ; HL=den
    call denominateGetDisplayValue ; OP1:Real=displayValue
    push hl ; stack=[den]
    bcall(_CeilFunction)
    pop hl ; stack=[]; HL=den
    call denominateSetDisplayValue ; den.baseValue=displayValue(result)
    call PopRpnObject1 ; FPS=[]; OP1=rpnDen
    ret

; Description: Return the Near(x).
; Input: CP1:RpnDenominate=rpnDen
; Output: CP1:RpnDenominate=Near(rpnDen)
RpnDenominateNear:
    call PushRpnObject1 ; FPS=[rpnDen]; HL=rpnDen
    skipRpnObjectTypeHL ; HL=den
    call denominateGetDisplayValue ; OP1:Real=displayValue
    push hl ; stack=[den]
    bcall(_Int) ; round to the nearest integer
    pop hl ; stack=[]; HL=den
    call denominateSetDisplayValue ; den.baseValue=displayValue(result)
    call PopRpnObject1 ; FPS=[]; OP1=rpnDen
    ret

;-----------------------------------------------------------------------------

; Description: Return the RoundToFix(x).
; Input: CP1:RpnDenominate=rpnDen
; Output: CP1:RpnDenominate=RoundToFix(rpnDen)
RpnDenominateRoundToFix:
    call PushRpnObject1 ; FPS=[rpnDen]; HL=rpnDen
    skipRpnObjectTypeHL ; HL=den
    call denominateGetDisplayValue ; OP1:Real=displayValue
    push hl ; stack=[den]
    bcall(_RnFx) ; round to FIX/SCI/ENG digits, do nothing if digits==floating
    pop hl ; stack=[]; HL=den
    call denominateSetDisplayValue ; den.baseValue=displayValue(result)
    call PopRpnObject1 ; FPS=[]; OP1=rpnDen
    ret

;-----------------------------------------------------------------------------

; Description: Return the RoundToGuard(x).
; Input: CP1:RpnDenominate=rpnDen
; Output: CP1:RpnDenominate=RoundToGuard(rpnDen)
RpnDenominateRoundToGuard:
    call PushRpnObject1 ; FPS=[rpnDen]; HL=rpnDen
    skipRpnObjectTypeHL ; HL=den
    call denominateGetDisplayValue ; OP1:Real=displayValue
    push hl ; stack=[den]
    bcall(_RndGuard) ; round to 10 digits, removing guard digits
    pop hl ; stack=[]; HL=den
    call denominateSetDisplayValue ; den.baseValue=displayValue(result)
    call PopRpnObject1 ; FPS=[]; OP1=rpnDen
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
