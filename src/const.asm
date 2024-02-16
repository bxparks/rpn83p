;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Floating point constants for routines in Flash Page 0.
;-----------------------------------------------------------------------------

; Description: Set OP1 to -1.0, avoiding the overhead of bcall.
; Destroys: all, HL
op1SetM1:
    ld hl, constM1
    jp move9ToOp1

;-----------------------------------------------------------------------------

; Description: Set OP1 to 0.0. Faster version of bcall(_OP1Set0).
; Destroys: all, HL
op1Set0:
    ld hl, const0
    jp move9ToOp1

; Description: Set OP1 to 0.0. Faster version of bcall(_OP1Set0).
; Destroys: all, HL
op2Set0:
    ld hl, const0
    jp move9ToOp2

; Description: Set OP1 to 0.0. Faster version of bcall(_OP1Set0).
; Destroys: all, HL
op3Set0:
    ld hl, const0
    jp move9ToOp3

; Description: Set OP1 to 0.0. Faster version of bcall(_OP1Set0).
; Destroys: all, HL
op4Set0:
    ld hl, const0
    jp move9ToOp4

;-----------------------------------------------------------------------------

; Description: Set OP2 to 10. The TI-OS Provides OP2Set60() but not
; OP2Set10().
; Destroys: all, HL
op2Set10:
    ld hl, const10
    jp move9ToOp2

;-----------------------------------------------------------------------------

; Description: Set OP1 to 100. The TI-OS Provides OP2Set60() but not
; OP2Set100().
; Destroys: all, HL
op1Set100:
    ld hl, const100
    jp move9ToOp1

; Description: Set OP2 to 100. The TI-OS Provides OP2Set60() but not
; OP2Set100().
; Destroys: all, HL
op2Set100:
    ld hl, const100
    jp move9ToOp2

;-----------------------------------------------------------------------------

; Description: Set OP2 to 1e-8.
; Destroys: all, HL
op2Set1EM8:
    ld hl, const1EM8
    jp move9ToOp2

;-----------------------------------------------------------------------------

; Description: Set OP2 to 1E14.
op2Set1E14:
    ld hl, const1E14
    jp move9ToOp2

;-----------------------------------------------------------------------------

; Description: Set OP1 to PI.
; Destroys: all, HL
op1SetPi:
    ld hl, constPi
    jp move9ToOp1

; Description: Set OP2 to PI.
; Destroys: all, HL
op2SetPi:
    ld hl, constPi
    jp move9ToOp2

;-----------------------------------------------------------------------------

; Description: Set OP1 to Euler constant.
; Destroys: all, HL
op1SetEuler:
    ld hl, constEuler
    jp move9ToOp1

; Description: Set OP2 to Euler constant.
; Destroys: all, HL
op2SetEuler:
    ld hl, constEuler
    jp move9ToOp2

;-----------------------------------------------------------------------------

; Description: Set OP1 to the maximum floating point number.
; Destroys: all, HL
op1SetMaxFloat:
    ld hl, constMaxFloat
    jp move9ToOp1

;-----------------------------------------------------------------------------

; Description: Set OP1 to StandardGravity.
; Destroys: all, HL
; op1SetStandardGravity:
;     ld hl, constStandardGravity
;     jp move9ToOp1

; Description: Set OP2 to StandardGravity.
; Destroys: all, HL
; op2SetStandardGravity:
;     ld hl, constStandardGravity
;     jp move9ToOp2

;-----------------------------------------------------------------------------

; Description: Set OP2 to KmPerMi.
; Destroys: all, HL
op2SetKmPerMi:
    ld hl, constKmPerMi
    jp move9ToOp2

;-----------------------------------------------------------------------------

; Description: Set OP2 to MPerFt
; Destroys: all, HL
op2SetMPerFt:
    ld hl, constMPerFt
    jp move9ToOp2

;-----------------------------------------------------------------------------

; Description: Set OP2 to CmPerIn
; Destroys: all, HL
op2SetCmPerIn:
    ld hl, constCmPerIn
    jp move9ToOp2

;-----------------------------------------------------------------------------

; Description: Set OP2 to KgPerLbs
; Destroys: all, HL
op2SetKgPerLbs:
    ld hl, constKgPerLbs
    jp move9ToOp2

;-----------------------------------------------------------------------------

; Description: Set OP2 to GPerOz.
; Destroys: all, HL
op2SetGPerOz:
    ld hl, constGPerOz
    jp move9ToOp2

;-----------------------------------------------------------------------------

; Description: Set OP2 to LPerGal.
; Destroys: all, HL
op2SetLPerGal:
    ld hl, constLPerGal
    jp move9ToOp2

;-----------------------------------------------------------------------------

; Description: Set OP2 to MlPerFloz.
; Destroys: all, HL
op2SetMlPerFloz:
    ld hl, constMlPerFloz
    jp move9ToOp2

;-----------------------------------------------------------------------------

; Description: Set OP2 to KjPerKcal.
; Destroys: all, HL
op2SetKjPerKcal:
    ld hl, constKjPerKcal
    jp move9ToOp2

;-----------------------------------------------------------------------------

; Description: Set OP2 to KwPerHp
; Destroys: all, HL
op2SetKwPerHp:
    ld hl, constKwPerHp
    jp move9ToOp2

;-----------------------------------------------------------------------------

; Description: Set OP2 to KwPerHp
; Destroys: all, HL
op2SetHpaPerInhg:
    ld hl, constHpaPerInhg
    jp move9ToOp2

;-----------------------------------------------------------------------------

constM1: ; -1
    .db $80, $80, $10, $00, $00, $00, $00, $00, $00

const0: ; 0.0
    .db $00, $80, $00, $00, $00, $00, $00, $00, $00

const10: ; 10
    .db $00, $81, $10, $00, $00, $00, $00, $00, $00

const100: ; 100
    .db $00, $82, $10, $00, $00, $00, $00, $00, $00

const1E14: ; 10^14, EXP=$80+14=$8E
    .db $00, $8E, $10, $00, $00, $00, $00, $00, $00

const1EM8: ; 10^-8
    .db $00, $78, $10, $00, $00, $00, $00, $00, $00

constPi: ; 3.1415926535897(9323)
    .db $00, $80, $31, $41, $59, $26, $53, $58, $98

constEuler: ; 2.7182818284594(0452)
    .db $00, $80, $27, $18, $28, $18, $28, $45, $94

; Useful to indicate an error condition in some parameters, while allowing
; other parameters to be calculated. If an exception is thrown instead (e.g.
; Err: Domain), then the entire calculation will be aborted, and none of the
; parameters can be calculated, which is not as useful in some cases.
constMaxFloat: ; 9.9999999999999E99
    .db $00, $E3, $99, $99, $99, $99, $99, $99, $99

; constStandardGravity: ; g_0 = 9.806 65 m/s^2, exact
;     .db $00, $80, $98, $06, $65, $00, $00, $00, $00

constKmPerMi: ; 1.609344 km/mi, exact
    .db $00, $80, $16, $09, $34, $40, $00, $00, $00

constMPerFt: ; 0.3048 m/ft, exact
    .db $00, $7F, $30, $48, $00, $00, $00, $00, $00

constCmPerIn: ; 2.54 cm/in, exact
    .db $00, $80, $25, $40, $00, $00, $00, $00, $00

constKgPerLbs: ; 0.453 592 37 kg/lbs, exact
    .db $00, $7F, $45, $35, $92, $37, $00, $00, $00

constGPerOz: ; 28.349 523 125 g/oz, exact
    .db $00, $81, $28, $34, $95, $23, $12, $50, $00

constLPerGal: ; 3.785 411 784 L/gal, exact, gallon == 231 in^3
    .db $00, $80, $37, $85, $41, $17, $84, $00, $00

constMlPerFloz: ; 29.573 529 562 5 mL/floz, exact, gal = 128 floz
    .db $00, $81, $29, $57, $35, $29, $56, $25, $00

constKjPerKcal: ; 4.184 J/cal or kJ/kcal, exact
    .db $00, $80, $41, $84, $00, $00, $00, $00, $00

; According to https://en.wikipedia.org/wiki/Horsepower:
; 1 hp (mechanical)
;   = 33 000 ft*lbf/min
;   = 550 ft*lbf/s
;   = 550 ft*lbf/s * 0.3048 m/ft * 9.806 65 m/s^2 * 0.453 592 37 kg/lbs
;   ~ 0.745 699 871 582 270 22 kW
constKwPerHp: ; 0.745 699 871 582 270 22 kW/hp, approx
    .db $00, $7F, $74, $56, $99, $87, $15, $82, $27

; According to https://en.wikipedia.org/wiki/Millimetre_of_mercury:
; 1 mmHg = 133.322 387 415 pascals (exact)
; 1 inHg = 25.4 * (above) = 3386.388640341 Pa (exact)
;        = 33.863 886 403 41 hPa (exact)
constHpaPerInhg:
    .db $00, $81, $33, $86, $38, $86, $40, $34, $10
