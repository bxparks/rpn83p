;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Handlers for UNIT menu items.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; UNIT > Row 1
;-----------------------------------------------------------------------------

mUnitMeterHandler:
    call closeInputAndRecallDenominateX ; A=rpnObjectType; B=objectUnit
    ld c, unitMeterId
    bcall(_ConvertUnit)
    jp replaceX

mUnitFeetHandler:
    call closeInputAndRecallDenominateX ; A=rpnObjectType; B=objectUnit
    ld c, unitFeetId
    bcall(_ConvertUnit)
    jp replaceX

mUnitSqMeterHandler:
    call closeInputAndRecallDenominateX ; A=rpnObjectType; B=objectUnit
    ld c, unitSqMeterId
    bcall(_ConvertUnit)
    jp replaceX

mUnitSqFeetHandler:
    call closeInputAndRecallDenominateX ; A=rpnObjectType; B=objectUnit
    ld c, unitSqFeetId
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
