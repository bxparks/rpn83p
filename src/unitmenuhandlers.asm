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
; UNIT > LEN > Row 1
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
; UNIT > LEN > Row 2
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
; UNIT > LEN > Row 3
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

mUnitKiloLiterHandler:
    ld a, unitKiloLiterId
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

mUnitOilBarrelHandler:
    ld a, unitOilBarrelId
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
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
; UNIT > Row 1
;-----------------------------------------------------------------------------

mFToCHandler:
    call closeInputAndRecallX
    ld a, 32
    bcall(_SetXXOP2) ; OP2 = 32
    bcall(_FPSub) ; OP1 = X - 32
    ld a, $18
    bcall(_OP2SetA) ; OP2 = 1.8
    bcall(_FPDiv) ; OP1 = (X - 32) / 1.8
    jp replaceX

mCToFHandler:
    call closeInputAndRecallX
    ld a, $18
    bcall(_OP2SetA) ; OP2 = 1.8
    bcall(_FPMult) ; OP1 = X * 1.8
    ld a, 32
    bcall(_SetXXOP2) ; OP2 = 32
    bcall(_FPAdd) ; OP1 = 1.8*X + 32
    jp replaceX

mInhgToHpaHandler:
    call closeInputAndRecallX
    call op2SetHpaPerInhg
    bcall(_FPMult)
    jp replaceX

mHpaToInhgHandler:
    call closeInputAndRecallX
    call op2SetHpaPerInhg
    bcall(_FPDiv)
    jp replaceX

;-----------------------------------------------------------------------------
; UNIT > Row 4
;-----------------------------------------------------------------------------

mLbsToKgHandler:
    call closeInputAndRecallX
    call op2SetKgPerLbs
    bcall(_FPMult)
    jp replaceX

mKgToLbsHandler:
    call closeInputAndRecallX
    call op2SetKgPerLbs
    bcall(_FPDiv)
    jp replaceX

mOzToGHandler:
    call closeInputAndRecallX
    call op2SetGPerOz
    bcall(_FPMult)
    jp replaceX

mGToOzHandler:
    call closeInputAndRecallX
    call op2SetGPerOz
    bcall(_FPDiv)
    jp replaceX

;-----------------------------------------------------------------------------
; UNIT > Row 6
;-----------------------------------------------------------------------------

mCalToKjHandler:
    call closeInputAndRecallX
    call op2SetKjPerKcal
    bcall(_FPMult)
    jp replaceX

mKjToCalHandler:
    call closeInputAndRecallX
    call op2SetKjPerKcal
    bcall(_FPDiv)
    jp replaceX

mHpToKwHandler:
    call closeInputAndRecallX
    call op2SetKwPerHp
    bcall(_FPMult)
    jp replaceX

mKwToHpHandler:
    call closeInputAndRecallX
    call op2SetKwPerHp
    bcall(_FPDiv)
    jp replaceX

;-----------------------------------------------------------------------------
; UNIT > Row 7
;-----------------------------------------------------------------------------

; Description: Convert mpg (miles per US gallon) to lkm (Liters per 100 km):
; lkm = 100/[mpg * (km/mile) / (litre/gal)]
mMpgToLkmHandler:
    call closeInputAndRecallX
    call op2SetKmPerMi
    bcall(_FPMult)
    call op2SetLPerGal
    bcall(_FPDiv)
    call op1ToOp2
    call op1Set100
    bcall(_FPDiv)
    jp replaceX

; Description: Convert lkm to mpg: mpg = 100/lkm * (litre/gal) / (km/mile).
mLkmToMpgHandler:
    call closeInputAndRecallX
    call op1ToOp2
    call op1Set100
    bcall(_FPDiv)
    call op2SetLPerGal
    bcall(_FPMult)
    call op2SetKmPerMi
    bcall(_FPDiv)
    jp replaceX

; Description: Convert PSI (pounds per square inch) to kiloPascal.
; P(Pa) = P(psi) * 0.45359237 kg/lbf * (9.80665 m/s^2) / (0.0254 m/in)^2
; P(Pa) = P(psi) * 0.45359237 kg/lbf * (9.80665 m/s^2) / (2.54 cm/in)^2 * 10000
; P(kPa) = P(psi) * 0.45359237 kg/lbf * (9.80665 m/s^2) / (2.54 cm/in)^2 * 10
; See https://en.wikipedia.org/wiki/Pound_per_square_inch.
mPsiToKpaHandler:
    call closeInputAndRecallX
    call op2SetKgPerLbs
    bcall(_FPMult)
    call op2SetStandardGravity
    bcall(_FPMult)
    call op2SetCmPerIn
    bcall(_FPDiv)
    call op2SetCmPerIn
    bcall(_FPDiv)
    call op2Set10
    bcall(_FPMult)
    jp replaceX

; Description: Convert PSI (pounds per square inch) to kiloPascal.
; P(psi) = P(kPa) / 10 * (2.54m/in)^2 / (0.45359237 kg/lbf) / (9.80665 m/s^2)
; See https://en.wikipedia.org/wiki/Pound_per_square_inch.
mKpaToPsiHandler:
    call closeInputAndRecallX
    call op2Set10
    bcall(_FPDiv)
    call op2SetCmPerIn
    bcall(_FPMult)
    call op2SetCmPerIn
    bcall(_FPMult)
    call op2SetStandardGravity
    bcall(_FPDiv)
    call op2SetKgPerLbs
    bcall(_FPDiv)
    jp replaceX
