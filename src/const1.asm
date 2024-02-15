;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Constants, usually floating point, duplicated from const.asm for Flash Page 1.
;-----------------------------------------------------------------------------

; Description: Set OP1 to 0.0. Faster version of bcall(_OP1Set0).
; Destroys: all, HL
op1Set0PageOne:
    ld hl, const0PageOne
    jp move9ToOp1PageOne

;-----------------------------------------------------------------------------

; Description: Set OP2 to 24. The TI-OS Provides OP2Set60() but not
; OP2Set24().
; Destroys: all, HL
op2Set24PageOne:
    ld hl, const24PageOne
    jp move9ToOp2PageOne

;-----------------------------------------------------------------------------

; Description: Set OP1 to 100. The TI-OS Provides OP2Set60() but not
; OP2Set100().
; Destroys: all, HL
op1Set100PageOne:
    ld hl, const100PageOne
    jp move9ToOp1PageOne

; Description: Set OP2 to 100. The TI-OS Provides OP2Set60() but not
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

; Description: Set OP2 to 10000.
; Destroys: all, HL
op2Set10000PageOne:
    ld hl, const10000PageOne
    jp move9ToOp2PageOne

;-----------------------------------------------------------------------------

; Description: Set OP2 to 2^16.
; Destroys: all, HL
op2Set2Pow16PageOne:
    ld hl, const2Pow16PageOne
    jp move9ToOp2PageOne

;-----------------------------------------------------------------------------

; Description: Set OP2 to 2^39.
; Destroys: all, HL
op2Set2Pow39PageOne:
    ld hl, const2Pow39PageOne
    jp move9ToOp2PageOne

;-----------------------------------------------------------------------------

; Description: Set OP2 to 2^40.
; Destroys: all, HL
op2Set2Pow40PageOne:
    ld hl, const2Pow40PageOne
    jp move9ToOp2PageOne

;-----------------------------------------------------------------------------

const0PageOne: ; 0.0
    .db $00, $80, $00, $00, $00, $00, $00, $00, $00

const24PageOne: ; 24
    .db $00, $81, $24, $00, $00, $00, $00, $00, $00

const100PageOne: ; 100
    .db $00, $82, $10, $00, $00, $00, $00, $00, $00

const1EM8PageOne: ; 10^-8
    .db $00, $78, $10, $00, $00, $00, $00, $00, $00

const10000PageOne: ; 10000
    .db $00, $84, $10, $00, $00, $00, $00, $00, $00

const2Pow16PageOne: ; 2^16 = 65 536
    .db $00, $84, $65, $53, $60, $00, $00, $00, $00

const2Pow39PageOne: ; 2^39 = 549 755 813 888
    .db $00, $8B, $54, $97, $55, $81, $38, $88, $00

const2Pow40PageOne: ; 2^40 = 1 099 511 627 776
    .db $00, $8C, $10, $99, $51, $16, $27, $76, $00
