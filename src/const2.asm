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

const24PageTwo: ; 24
    .db $00, $81, $24, $00, $00, $00, $00, $00, $00

const2Pow39PageTwo: ; 2^39 = 549 755 813 888
    .db $00, $8B, $54, $97, $55, $81, $38, $88, $00

const2Pow40PageTwo: ; 2^40 = 1 099 511 627 776
    .db $00, $8C, $10, $99, $51, $16, $27, $76, $00
