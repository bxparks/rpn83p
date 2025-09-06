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
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; UNIT > Row 1
;-----------------------------------------------------------------------------

mUnitMeterHandler:
    ld a, unitMeterId
    jr commonUnitHandler

mUnitFeetHandler:
    ld a, unitFeetId
    jr commonUnitHandler

mUnitSqMeterHandler:
    ld a, unitSqMeterId
    jr commonUnitHandler

mUnitSqFeetHandler:
    ld a, unitSqFeetId
    jr commonUnitHandler

; Description: Common handler for all UNIT menus.
;
; Input:
;   - A:u8=targetUnitId
commonUnitHandler:
    ld e, a
    push de
    call closeInputAndRecallDenominateX ; A=rpnObjectType; B=objectUnit
    pop de
    ld c, e ; C=targetUnitId
    bcall(_ConvertUnit)
    jp replaceX

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
; UNIT > Row 2
;-----------------------------------------------------------------------------

mMiToKmHandler:
    call closeInputAndRecallX
    call op2SetKmPerMi
    bcall(_FPMult)
    jp replaceX

mKmToMiHandler:
    call closeInputAndRecallX
    call op2SetKmPerMi
    bcall(_FPDiv)
    jp replaceX

mFtToMHandler:
    call closeInputAndRecallX
    call op2SetMPerFt
    bcall(_FPMult)
    jp replaceX

mMToFtHandler:
    call closeInputAndRecallX
    call op2SetMPerFt
    bcall(_FPDiv)
    jp replaceX

;-----------------------------------------------------------------------------
; UNIT > Row 3
;-----------------------------------------------------------------------------

mInToCmHandler:
    call closeInputAndRecallX
    call op2SetCmPerIn
    bcall(_FPMult)
    jp replaceX

mCmToInHandler:
    call closeInputAndRecallX
    call op2SetCmPerIn
    bcall(_FPDiv)
    jp replaceX

mMilToMicronHandler:
    call closeInputAndRecallX
    call op2SetCmPerIn
    bcall(_FPMult)
    call op2Set10
    bcall(_FPMult)
    jp replaceX

mMicronToMilHandler:
    call closeInputAndRecallX
    call op2SetCmPerIn
    bcall(_FPDiv)
    call op2Set10
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
; UNIT > Row 5
;-----------------------------------------------------------------------------

mGalToLHandler:
    call closeInputAndRecallX
    call op2SetLPerGal
    bcall(_FPMult)
    jp replaceX

mLToGalHandler:
    call closeInputAndRecallX
    call op2SetLPerGal
    bcall(_FPDiv)
    jp replaceX

mFlozToMlHandler:
    call closeInputAndRecallX
    call op2SetMlPerFloz
    bcall(_FPMult)
    jp replaceX

mMlToFlozHandler:
    call closeInputAndRecallX
    call op2SetMlPerFloz
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

;-----------------------------------------------------------------------------
; UNIT > Row 8
;-----------------------------------------------------------------------------

; Description: Convert US acre (66 ft x 660 ft) to hectare (100 m)^2. See
; https://en.wikipedia.org/wiki/Acre, and
; https://en.wikipedia.org/wiki/Hectare.
; Area(ha) = Area(acre) * 43560 * (0.3048 m/ft)^2 / (100 m)^2
mAcreToHectareHandler:
    call closeInputAndRecallX
    call op2SetSqFtPerAcre
    bcall(_FPMult)
    call op2SetMPerFt
    bcall(_FPMult)
    call op2SetMPerFt
    bcall(_FPMult)
    call op2Set100
    bcall(_FPDiv)
    call op2Set100
    bcall(_FPDiv)
    jp replaceX

; Description: Convert hectare to US acre.
; Area(acre) = Area(ha) * (100 m)^2 / 43560 / (0.3048 m/ft)^2
mHectareToAcreHandler:
    call closeInputAndRecallX
    call op2Set100
    bcall(_FPMult)
    call op2Set100
    bcall(_FPMult)
    call op2SetMPerFt
    bcall(_FPDiv)
    call op2SetMPerFt
    bcall(_FPDiv)
    call op2SetSqFtPerAcre
    bcall(_FPDiv)
    jp replaceX
