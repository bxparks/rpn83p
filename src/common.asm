;-----------------------------------------------------------------------------
; Common utilties that are useful in multiple modules.
;-----------------------------------------------------------------------------

; Function: getString(A, HL) -> HL
; Description: Get the string pointer at index A starting with base pointer HL.
; Input:
;   A: index
;   HL: base pointer
; Output: HL: pointer to a string
; Destroys: DE, HL
getString:
    ld e, a
    ld d, 0
    add hl, de ; hl += a * 2
    add hl, de
    ld e, (hl)
    inc hl
    ld d, (hl)
    ex de, hl
    ret

;-----------------------------------------------------------------------------

; Description: Set OP1 to 10. The TI-OS provides OP2Set60() but not
; OP1Set10().
; Destroys: all, HL
op1Set10:
    ld hl, const10
    bcall(_Mov9ToOP1)
    ret

; Description: Set OP2 to 10. The TI-OS Provides OP2Set60() but not
; OP2Set10().
; Destroys: all, HL
op2Set10:
    ld hl, const10
    bcall(_Mov9ToOP2)
    ret

;-----------------------------------------------------------------------------

; Description: Set OP1 to 100. The TI-OS provides OP2Set60() but not
; OP1Set100().
; Destroys: all, HL
op1Set100:
    ld hl, const100
    bcall(_Mov9ToOP1)
    ret

; Description: Set OP2 to 100. The TI-OS Provides OP2Set60() but not
; OP2Set100().
; Destroys: all, HL
op2Set100:
    ld hl, const100
    bcall(_Mov9ToOP2)
    ret

;-----------------------------------------------------------------------------

; Description: Set OP1 to PI.
; Destroys: all, HL
op1SetPi:
    ld hl, constPi
    bcall(_Mov9ToOP1)
    ret

; Description: Set OP2 to PI.
; Destroys: all, HL
op2SetPi:
    ld hl, constPi
    bcall(_Mov9ToOP2)
    ret

;-----------------------------------------------------------------------------

; Description: Set OP1 to Euler constant.
; Destroys: all, HL
op1SetEuler:
    ld hl, constEuler
    bcall(_Mov9ToOP1)
    ret

; Description: Set OP2 to Euler constant.
; Destroys: all, HL
op2SetEuler:
    ld hl, constEuler
    bcall(_Mov9ToOP2)
    ret

;-----------------------------------------------------------------------------

; Description: Set OP1 to KmPerMi.
; Destroys: all, HL
op1SetKmPerMi:
    ld hl, constKmPerMi
    bcall(_Mov9ToOP1)
    ret

; Description: Set OP2 to KmPerMi.
; Destroys: all, HL
op2SetKmPerMi:
    ld hl, constKmPerMi
    bcall(_Mov9ToOP2)
    ret

;-----------------------------------------------------------------------------

; Description: Set OP1 to MPerFt.
; Destroys: all, HL
op1SetMPerFt:
    ld hl, constMPerFt
    bcall(_Mov9ToOP1)
    ret

; Description: Set OP2 to MPerFt
; Destroys: all, HL
op2SetMPerFt:
    ld hl, constMPerFt
    bcall(_Mov9ToOP2)
    ret

;-----------------------------------------------------------------------------

; Description: Set OP1 to CmPerIn.
; Destroys: all, HL
op1SetCmPerIn:
    ld hl, constCmPerIn
    bcall(_Mov9ToOP1)
    ret

; Description: Set OP2 to CmPerIn
; Destroys: all, HL
op2SetCmPerIn:
    ld hl, constCmPerIn
    bcall(_Mov9ToOP2)
    ret

;-----------------------------------------------------------------------------

; Description: Set OP1 to KgPerLbs
; Destroys: all, HL
op1SetKgPerLbs:
    ld hl, constKgPerLbs
    bcall(_Mov9ToOP1)
    ret

; Description: Set OP2 to KgPerLbs
; Destroys: all, HL
op2SetKgPerLbs:
    ld hl, constKgPerLbs
    bcall(_Mov9ToOP2)
    ret

;-----------------------------------------------------------------------------

; Description: Set OP1 to GPerOz.
; Destroys: all, HL
op1SetGPerOz:
    ld hl, constGPerOz
    bcall(_Mov9ToOP1)
    ret

; Description: Set OP2 to GPerOz.
; Destroys: all, HL
op2SetGPerOz:
    ld hl, constGPerOz
    bcall(_Mov9ToOP2)
    ret

;-----------------------------------------------------------------------------

; Description: Set OP1 to LPerGal.
; Destroys: all, HL
op1SetLPerGal:
    ld hl, constLPerGal
    bcall(_Mov9ToOP1)
    ret

; Description: Set OP2 to LPerGal.
; Destroys: all, HL
op2SetLPerGal:
    ld hl, constLPerGal
    bcall(_Mov9ToOP2)
    ret

;-----------------------------------------------------------------------------

; Description: Set OP1 to MlPerFloz.
; Destroys: all, HL
op1SetMlPerFloz:
    ld hl, constMlPerFloz
    bcall(_Mov9ToOP1)
    ret

; Description: Set OP2 to MlPerFloz.
; Destroys: all, HL
op2SetMlPerFloz:
    ld hl, constMlPerFloz
    bcall(_Mov9ToOP2)
    ret

;-----------------------------------------------------------------------------

; Description: Set OP1 to KjPerKcal.
; Destroys: all, HL
op1SetKjPerKcal
    ld hl, constKjPerKcal
    bcall(_Mov9ToOP1)
    ret

; Description: Set OP2 to KjPerKcal.
; Destroys: all, HL
op2SetKjPerKcal
    ld hl, constKjPerKcal
    bcall(_Mov9ToOP2)
    ret

;-----------------------------------------------------------------------------

; Description: Set OP1 to KwPerHp
; Destroys: all, HL
op1SetKwPerHp
    ld hl, constKwPerHp
    bcall(_Mov9ToOP1)
    ret

; Description: Set OP2 to KwPerHp
; Destroys: all, HL
op2SetKwPerHp
    ld hl, constKwPerHp
    bcall(_Mov9ToOP2)
    ret

;-----------------------------------------------------------------------------

; Description: Set OP1 to StandardGravity.
; Destroys: all, HL
op1SetStandardGravity
    ld hl, constStandardGravity
    bcall(_Mov9ToOP1)
    ret

; Description: Set OP2 to StandardGravity.
; Destroys: all, HL
op2SetStandardGravity
    ld hl, constStandardGravity
    bcall(_Mov9ToOP2)
    ret

;-----------------------------------------------------------------------------

const10: ; 10
    .db $00, $81, $10, $00, $00, $00, $00, $00, $00

const100: ; 100
    .db $00, $82, $10, $00, $00, $00, $00, $00, $00

constPi: ; 3.1415926535897(9323)
    .db $00, $80, $31, $41, $59, $26, $53, $58, $98

constEuler: ; 2.7182818284594(0452)
    .db $00, $80, $27, $18, $28, $18, $28, $45, $94

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

constStandardGravity: ; g_0 = 9.806 65 m/s^2, exact
    .db $00, $80, $98, $06, $65, $00, $00, $00, $00
