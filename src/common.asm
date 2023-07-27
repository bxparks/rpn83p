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

; Description: Set OP1 to 100. The TI-OS provides OP2Set60() but not
; OP1Set100().
; Destroys: all, HL
op1Set100:
    ld hl, const100
    bcall(_Mov9ToOP1)
    ret

; Description: Set OP2 to 100. The TI-OS Provides OP2Set60() but not
; OP2Set60().
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

; Description: Set OP2 to GPerOz
; Destroys: all, HL
op2SetGPerOz:
    ld hl, constGPerOz
    bcall(_Mov9ToOP2)
    ret

;-----------------------------------------------------------------------------

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
