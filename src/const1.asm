;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Constants, usually floating point, duplicated from const.asm for Flash Page 1.
;-----------------------------------------------------------------------------

; Description: Set OP1 to 100. The TI-OS Provides OP2Set60() but not
; OP2Set100().
; Destroys: all, HL
op1Set100PageOne:
    ld hl, const100PageOne
    jp move9ToOp1PageOne

;PageOne Description: Set OP2 to 100. The TI-OS Provides OP2Set60() but not
; OP2Set100().
; Destroys: all, HL
op2Set100PageOne:
    ld hl, const100PageOne
    jp move9ToOp2PageOne

;-----------------------------------------------------------------------------

; Description: Set OP2 to 1e-8.
; Destroys: all, HL
op2Set1EM8PageOne:
    ld hl, const1EM8PageOne
    jp move9ToOp2PageOne

;-----------------------------------------------------------------------------

const100PageOne: ; 100
    .db $00, $82, $10, $00, $00, $00, $00, $00, $00

const1EM8PageOne: ; 10^-8
    .db $00, $78, $10, $00, $00, $00, $00, $00, $00
