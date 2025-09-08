;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; UNIT menu items.
;
; Every handler is given the following input parameters:
;   - HL:u16=menuId
;   - CF:bool
;       - 0 indicates 'onEnter' event into group
;       - 1 indicates 'onExit' event from group
;
; The following design invokes a separate unit handler for each UNIT menu, and
; the sole purpose of each unit handler is to assign the unitId into register
; A, then forward the call to a common handler. The uintId corresponds to the
; specific unit conversion requested by the menu function.
;
; An alternative design involves adding a generic 'param:u8' field inside the
; MenuNode struct, then defining the corresponding unitId in the menudef.txt
; file which compiles into the menudef.asm. Every menuHandler already gets
; passed the menuId which triggered the handler. Using this menuId, we could
; look up the 'param' parameter from MenuNode.
;
; Although this design seems more "data-driven" and more aesthetically pleasing
; in some sense (because all UNIT menu items could be sent to a single menu
; handler), it has a number of problems:
;
;   1) It requires the 'MenuItem' directive in menudef.asm to support an
;   optional 'param' parameter, which requires extensions to the `Lexer` in
;   `compilemenu.py` to support a one-token pushback.
;   2) It increases the size of MenuNode by 1 byte, which increases the total
;   size of menuTable by 300 bytes, where most of the additional space is
;   wasted because the 'param' field is used only by UNIT menu items. In the
;   above "brute-force" design, each unit handler consumes 4 bytes. So the
;   breakeven point is about 75 units, which is more than the number
;   of units under the UNIT menu that I expect to support.
;   3) It couples the menudef.txt/menudef.asm to the unitdef.txt/asm.
;   4) The important consequence of the coupling (3) is that a unit menu
;   handler cannot be invoked independently with no external state. In other
;   words, we must invoke it with the HL register filled with the menuId that
;   would have trigger the unit conversion. Being able to invoke the unit
;   conversion function without additional state make it easier to support
;   keystroke programming in the future.
;   5) Temperature conversions must be done in a special way. It's easier to
;   handle temperatures using explicit menu handlers, instead of driving it
;   through the 'param' field in a table.
;-----------------------------------------------------------------------------

; Description: Common handler for all UNIT menus.
;
; Input:
;   - A:u8=targetUnit
commonUnitHandler:
    ld e, a
    push de
    call closeInputAndRecallDenominateX ; A=rpnObjectType; B=objectUnit
    pop de
    ld c, e ; C=targetUnit
    bcall(_ConvertUnit)
    jp replaceX

;-----------------------------------------------------------------------------
; UNIT > LENG > Row 1
;-----------------------------------------------------------------------------

mUnitNanoMeterHandler:
    ld a, unitNanoMeterId
    jp commonUnitHandler

mUnitMicroMeterHandler:
    ld a, unitMicroMeterId
    jp commonUnitHandler

mUnitMilliMeterHandler:
    ld a, unitMilliMeterId
    jp commonUnitHandler

mUnitCentiMeterHandler:
    ld a, unitCentiMeterId
    jp commonUnitHandler

mUnitMeterHandler:
    ld a, unitMeterId
    jp commonUnitHandler

;-----------------------------------------------------------------------------
; UNIT > LENG > Row 2
;-----------------------------------------------------------------------------

mUnitMilHandler:
    ld a, unitMilId
    jp commonUnitHandler

mUnitInchHandler:
    ld a, unitInchId
    jp commonUnitHandler

mUnitFootHandler:
    ld a, unitFootId
    jp commonUnitHandler

mUnitYardHandler:
    ld a, unitYardId
    jp commonUnitHandler

mUnitFanthomHandler:
    ld a, unitFanthomId
    jp commonUnitHandler

;-----------------------------------------------------------------------------
; UNIT > LENG > Row 3
;-----------------------------------------------------------------------------

mUnitKiloMeterHandler:
    ld a, unitKiloMeterId
    jp commonUnitHandler

mUnitMileHandler:
    ld a, unitMileId
    jp commonUnitHandler

mUnitNauticalMileHandler:
    ld a, unitNauticalMileId
    jp commonUnitHandler

;-----------------------------------------------------------------------------
; UNIT > LENG > ASTR > Row 1
;-----------------------------------------------------------------------------

mUnitAstronomicalUnitHandler:
    ld a, unitAstronomicalUnitId
    jp commonUnitHandler

mUnitLightYearHandler:
    ld a, unitLightYearId
    jp commonUnitHandler

mUnitParsecHandler:
    ld a, unitParsecId
    jp commonUnitHandler

;-----------------------------------------------------------------------------
; UNIT > AREA > Row 1
;-----------------------------------------------------------------------------

mUnitSqMilliMeterHandler:
    ld a, unitSqMilliMeterId
    jp commonUnitHandler

mUnitSqCentiMeterHandler:
    ld a, unitSqCentiMeterId
    jp commonUnitHandler

mUnitSqMeterHandler:
    ld a, unitSqMeterId
    jp commonUnitHandler

mUnitSqKiloMeterHandler:
    ld a, unitSqKiloMeterId
    jp commonUnitHandler

;-----------------------------------------------------------------------------
; UNIT > AREA > Row 2
;-----------------------------------------------------------------------------

mUnitSqInchHandler:
    ld a, unitSqInchId
    jp commonUnitHandler

mUnitSqFootHandler:
    ld a, unitSqFootId
    jp commonUnitHandler

mUnitSqYardHandler:
    ld a, unitSqYardId
    jp commonUnitHandler

mUnitSqMileHandler:
    ld a, unitSqMileId
    jp commonUnitHandler

mUnitSqNauticalMileHandler:
    ld a, unitSqNauticalMileId
    jp commonUnitHandler

;-----------------------------------------------------------------------------
; UNIT > AREA > Row 3
;-----------------------------------------------------------------------------

mUnitAcreHandler:
    ld a, unitAcreId
    jp commonUnitHandler

mUnitHectareHandler:
    ld a, unitHectareId
    jp commonUnitHandler

mUnitUSFootballHandler:
    ld a, unitUSFootballId
    jp commonUnitHandler

mUnitCAFootballHandler:
    ld a, unitCAFootballId
    jp commonUnitHandler

;-----------------------------------------------------------------------------
; UNIT > VOL > Row 1
;-----------------------------------------------------------------------------

mUnitCuMilliMeterHandler:
    ld a, unitCuMilliMeterId
    jp commonUnitHandler

mUnitCuCentiMeterHandler:
    ld a, unitCuCentiMeterId
    jp commonUnitHandler

mUnitCuMeterHandler:
    ld a, unitCuMeterId
    jp commonUnitHandler

mUnitCuKiloMeterHandler:
    ld a, unitCuKiloMeterId
    jp commonUnitHandler

;-----------------------------------------------------------------------------
; UNIT > VOL > Row 2
;-----------------------------------------------------------------------------

mUnitCuInchHandler:
    ld a, unitCuInchId
    jp commonUnitHandler

mUnitCuFootHandler:
    ld a, unitCuFootId
    jp commonUnitHandler

mUnitCuYardHandler:
    ld a, unitCuYardId
    jp commonUnitHandler

mUnitCuMileHandler:
    ld a, unitCuMileId
    jp commonUnitHandler

mUnitCuNauticalMileHandler:
    ld a, unitCuNauticalMileId
    jp commonUnitHandler

;-----------------------------------------------------------------------------
; UNIT > VOL > SI > Row 1
;-----------------------------------------------------------------------------

mUnitMicroLiterHandler:
    ld a, unitMicroLiterId
    jp commonUnitHandler

mUnitMilliLiterHandler:
    ld a, unitMilliLiterId
    jp commonUnitHandler

mUnitLiterHandler:
    ld a, unitLiterId
    jp commonUnitHandler

;-----------------------------------------------------------------------------
; UNIT > VOL > US > Row 1
;-----------------------------------------------------------------------------

mUnitTeaspoonHandler:
    ld a, unitTeaspoonId
    jp commonUnitHandler

mUnitTablespoonHandler:
    ld a, unitTablespoonId
    jp commonUnitHandler

mUnitFluidOunceHandler:
    ld a, unitFluidOunceId
    jp commonUnitHandler

mUnitGillHandler:
    ld a, unitGillId
    jp commonUnitHandler

mUnitCupHandler:
    ld a, unitCupId
    jp commonUnitHandler

;-----------------------------------------------------------------------------
; UNIT > VOL > US > Row 2
;-----------------------------------------------------------------------------

mUnitPintHandler:
    ld a, unitPintId
    jp commonUnitHandler

mUnitQuartHandler:
    ld a, unitQuartId
    jp commonUnitHandler

mUnitGallonHandler:
    ld a, unitGallonId
    jp commonUnitHandler

;-----------------------------------------------------------------------------
; UNIT > VOL > US > Row 3
;-----------------------------------------------------------------------------

mUnitOilBarrelHandler:
    ld a, unitOilBarrelId
    jp commonUnitHandler

mUnitAcreFootHandler:
    ld a, unitAcreFootId
    jp commonUnitHandler

mUnitOlympicPoolHandler:
    ld a, unitOlympicPoolId
    jp commonUnitHandler

;-----------------------------------------------------------------------------
; UNIT > VOL > Imp > Row 1
;-----------------------------------------------------------------------------

mUnitImpFluidOunceHandler:
    ld a, unitImpFluidOunceId
    jp commonUnitHandler

mUnitImpGillHandler:
    ld a, unitImpGillId
    jp commonUnitHandler

mUnitImpCupHandler:
    ld a, unitImpCupId
    jp commonUnitHandler

;-----------------------------------------------------------------------------
; UNIT > VOL > Imp > Row 2
;-----------------------------------------------------------------------------

mUnitImpPintHandler:
    ld a, unitImpPintId
    jp commonUnitHandler

mUnitImpQuartHandler:
    ld a, unitImpQuartId
    jp commonUnitHandler

mUnitImpGallonHandler:
    ld a, unitImpGallonId
    jp commonUnitHandler

;-----------------------------------------------------------------------------
; UNIT > MASS > Row 1
;-----------------------------------------------------------------------------

mUnitMicroGramHandler:
    ld a, unitMicroGramId
    jp commonUnitHandler

mUnitMilliGramHandler:
    ld a, unitMilliGramId
    jp commonUnitHandler

mUnitGramHandler:
    ld a, unitGramId
    jp commonUnitHandler

mUnitKiloGramHandler:
    ld a, unitKiloGramId
    jp commonUnitHandler

;-----------------------------------------------------------------------------
; UNIT > MASS > Row 2
;-----------------------------------------------------------------------------

mUnitOunceHandler:
    ld a, unitOunceId
    jp commonUnitHandler

mUnitPoundHandler:
    ld a, unitPoundId
    jp commonUnitHandler

mUnitTonHandler:
    ld a, unitTonId
    jp commonUnitHandler

;-----------------------------------------------------------------------------
; UNIT > TEMP > Row 1
;-----------------------------------------------------------------------------

mUnitCelsiusHandler:
    ld a, unitCelsiusId
    jp commonUnitHandler

mUnitFahrenheitHandler:
    ld a, unitFahrenheitId
    jp commonUnitHandler

mUnitRankineHandler:
    ld a, unitRankineId
    jp commonUnitHandler

mUnitKelvinHandler:
    ld a, unitKelvinId
    jp commonUnitHandler

;-----------------------------------------------------------------------------
; UNIT > PRES > Row 1
;-----------------------------------------------------------------------------

mUnitPascalHandler:
    ld a, unitPascalId
    jp commonUnitHandler

mUnitHectoPascalHandler:
    ld a, unitHectoPascalId
    jp commonUnitHandler

mUnitKiloPascalHandler:
    ld a, unitKiloPascalId
    jp commonUnitHandler

mUnitAtmosphereHandler:
    ld a, unitAtmosphereId
    jp commonUnitHandler

;-----------------------------------------------------------------------------
; UNIT > PRES > Row 2
;-----------------------------------------------------------------------------

mUnitMilliBarHandler:
    ld a, unitMilliBarId
    jp commonUnitHandler

mUnitDeciBarHandler:
    ld a, unitDeciBarId
    jp commonUnitHandler

mUnitBarHandler:
    ld a, unitBarId
    jp commonUnitHandler

mUnitPoundSquareInchHandler:
    ld a, unitPoundSquareInchId
    jp commonUnitHandler

;-----------------------------------------------------------------------------
; UNIT > PRES > Row 3
;-----------------------------------------------------------------------------

mUnitMilliMeterMercuryHandler:
    ld a, unitMilliMeterMercuryId
    jp commonUnitHandler

mUnitInchMercuryHandler:
    ld a, unitInchMercuryId
    jp commonUnitHandler

mUnitTorrHandler:
    ld a, unitTorrId
    jp commonUnitHandler

;-----------------------------------------------------------------------------
; UNIT > ENER > Row 1
;-----------------------------------------------------------------------------

mUnitJouleHandler:
    ld a, unitJouleId
    jp commonUnitHandler

mUnitWattHourHandler:
    ld a, unitWattHourId
    jp commonUnitHandler

mUnitKiloWattHourHandler:
    ld a, unitKiloWattHourId
    jp commonUnitHandler

mUnitCalorieHandler:
    ld a, unitCalorieId
    jp commonUnitHandler

mUnitKiloCalorieHandler:
    ld a, unitKiloCalorieId
    jp commonUnitHandler

;-----------------------------------------------------------------------------
; UNIT > ENER > Row 2
;-----------------------------------------------------------------------------

mUnitElectronVoltHandler:
    ld a, unitElectronVoltId
    jp commonUnitHandler

mUnitBritishThermalUnitHandler:
    ld a, unitBritishThermalUnitId
    jp commonUnitHandler

mUnitTonTNTHandler:
    ld a, unitTonTNTId
    jp commonUnitHandler

;-----------------------------------------------------------------------------
; UNIT > PWR > Row 1
;-----------------------------------------------------------------------------

mUnitWattHandler:
    ld a, unitWattId
    jp commonUnitHandler

mUnitHorsepowerHandler:
    ld a, unitHorsepowerId
    jp commonUnitHandler

;-----------------------------------------------------------------------------
; UNIT > FUEL > Row 1
;-----------------------------------------------------------------------------

mUnitMilesPerGallonHandler:
    ld a, unitMilesPerGallonId
    jp commonUnitHandler

mUnitLitersPerHundredKiloMetersHandler:
    ld a, unitLitersPerHundredKiloMetersId
    jp commonUnitHandler
