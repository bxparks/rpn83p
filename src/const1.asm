;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Floating point constants for routines in Flash Page 1.
;-----------------------------------------------------------------------------

; Description: Set OP1 to 0.0. Faster version of bcall(_OP1Set0).
; Destroys: all, HL
op1Set0PageOne:
    ld hl, const0PageOne
    jp move9ToOp1PageOne

; Description: Set OP1 to 0.0. Faster version of bcall(_OP1Set0).
; Destroys: all, HL
op2Set0PageOne:
    ld hl, const0PageOne
    jp move9ToOp2PageOne

; Description: Set OP1 to 0.0. Faster version of bcall(_OP1Set0).
; Destroys: all, HL
op4Set0PageOne:
    ld hl, const0PageOne
    jp move9ToOp4PageOne

;-----------------------------------------------------------------------------

; Description: Set OP2 to 100. The TI-OS Provides OP2Set60() but not
; OP2Set100().
; Destroys: all, HL
op2Set100PageOne:
    ld hl, const100PageOne
    jp move9ToOp2PageOne

;-----------------------------------------------------------------------------

; Description: Set OP2 to 2^16.
; Destroys: all, HL
op2Set2Pow16PageOne:
    ld hl, const2Pow16PageOne
    jp move9ToOp2PageOne

;-----------------------------------------------------------------------------

const0PageOne: ; 0.0
    .db $00, $80, $00, $00, $00, $00, $00, $00, $00

const100PageOne: ; 100
    .db $00, $82, $10, $00, $00, $00, $00, $00, $00

const2Pow16PageOne: ; 2^16 = 65 536
    .db $00, $84, $65, $53, $60, $00, $00, $00, $00
