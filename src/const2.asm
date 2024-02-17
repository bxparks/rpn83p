;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Floating point constants for routines in Flash Page 2.
;-----------------------------------------------------------------------------

; Description: Set OP2 to 24. The TI-OS Provides OP2Set60() but not
; OP2Set24().
; Destroys: all, HL
op2Set24PageTwo:
    ld hl, const24PageTwo
    jp move9ToOp2PageTwo

;-----------------------------------------------------------------------------

; Description: Set OP2 to 2^32.
; Destroys: all, HL
op2Set2Pow32PageTwo:
    ld hl, const2Pow32PageTwo
    jp move9ToOp2PageTwo

;-----------------------------------------------------------------------------

; Description: Set OP2 to 2^39.
; Destroys: all, HL
op2Set2Pow39PageTwo:
    ld hl, const2Pow39PageTwo
    jp move9ToOp2PageTwo

;-----------------------------------------------------------------------------

; Description: Set OP2 to 2^40.
; Destroys: all, HL
op2Set2Pow40PageTwo:
    ld hl, const2Pow40PageTwo
    jp move9ToOp2PageTwo

;-----------------------------------------------------------------------------

; Description: Set OP2 to 1E14.
op2Set1E14PageTwo:
    ld hl, const1E14PageTwo
    jp move9ToOp2PageTwo

;-----------------------------------------------------------------------------

const24PageTwo: ; 24
    .db $00, $81, $24, $00, $00, $00, $00, $00, $00

const2Pow32PageTwo: ; 2^32 = 4 294 967 296
    .db $00, $89, $42, $94, $96, $72, $96, $00, $00

const2Pow39PageTwo: ; 2^39 = 549 755 813 888
    .db $00, $8B, $54, $97, $55, $81, $38, $88, $00

const2Pow40PageTwo: ; 2^40 = 1 099 511 627 776
    .db $00, $8C, $10, $99, $51, $16, $27, $76, $00

const1E14PageTwo: ; 10^14, EXP=$80+14=$8E
    .db $00, $8E, $10, $00, $00, $00, $00, $00, $00
