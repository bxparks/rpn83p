;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Floating point constants for routines in Flash Page 2.
;-----------------------------------------------------------------------------

; Description: Set OP1 to -50.
; Destroys: all, HL
op1SetM50PageTwo:
    ld hl, constM50PageTwo
    jp move9ToOp1PageTwo

;-----------------------------------------------------------------------------

; Description: Set OP1 to 0.0. Faster version of bcall(_OP1Set0).
; Destroys: all, HL
op1Set0PageTwo:
    ld hl, const0PageTwo
    jp move9ToOp1PageTwo

;-----------------------------------------------------------------------------

; Description: Set OP2 to 1e-10.
; Destroys: all, HL
op2Set1EM10PageTwo:
    ld hl, const1EM10PageTwo
    jp move9ToOp2PageTwo

;-----------------------------------------------------------------------------

; Description: Set OP2 to 6e-5
; Destroys: all, HL
op2Set6EM5PageTwo:
    ld hl, const6EM5PageTwo
    jp move9ToOp2PageTwo

;-----------------------------------------------------------------------------

; Description: Set OP2 to 1.
; Destroys: all, HL
op2Set1PageTwo:
    ld hl, const1PageTwo
    jp move9ToOp2PageTwo

;-----------------------------------------------------------------------------

; Description: Set OP1 to 7.
; Destroys: all, HL
op1Set7PageTwo:
    ld hl, const7PageTwo
    jp move9ToOp1PageTwo

; Description: Set OP1 to 7.
; Destroys: all, HL
op2Set7PageTwo:
    ld hl, const7PageTwo
    jp move9ToOp2PageTwo

;-----------------------------------------------------------------------------

; Description: Set OP2 to 12.
; Destroys: all, HL
op2Set12PageTwo:
    ld hl, const12PageTwo
    jp move9ToOp2PageTwo

;-----------------------------------------------------------------------------

; Description: Set OP2 to 24. The TI-OS Provides OP2Set60() but not
; OP2Set24().
; Destroys: all, HL
op2Set24PageTwo:
    ld hl, const24PageTwo
    jp move9ToOp2PageTwo

;-----------------------------------------------------------------------------

; Description: Set OP1 to 100. The TI-OS Provides OP2Set60() but not
; OP2Set100().
; Destroys: all, HL
op1Set100PageTwo:
    ld hl, const100PageTwo
    jp move9ToOp1PageTwo

; Description: Set OP2 to 100. The TI-OS Provides OP2Set60() but not
; OP2Set100().
; Destroys: all, HL
op2Set100PageTwo:
    ld hl, const100PageTwo
    jp move9ToOp2PageTwo

;-----------------------------------------------------------------------------

; Description: Set OP2 to 3600.
; Destroys: all, HL
op2Set3600PageTwo:
    ld hl, const3600PageTwo
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

; Description: Set OP1 to the maximum floating point number.
; Destroys: all, HL
op1SetMaxFloatPageTwo:
    ld hl, constMaxFloatPageTwo
    jp move9ToOp1PageTwo

;-----------------------------------------------------------------------------

constM50PageTwo: ; -50
    .db $80, $81, $50, $00, $00, $00, $00, $00, $00

const0PageTwo: ; 0.0
    .db $00, $80, $00, $00, $00, $00, $00, $00, $00

const1EM10PageTwo: ; 1E-10
    .db $00, $76, $10, $00, $00, $00, $00, $00, $00

const6EM5PageTwo: ; 6E-5
    .db $00, $7B, $60, $00, $00, $00, $00, $00, $00

const1PageTwo: ; 1
    .db $00, $80, $10, $00, $00, $00, $00, $00, $00

const7PageTwo: ; 7
    .db $00, $80, $70, $00, $00, $00, $00, $00, $00

const12PageTwo: ; 12
    .db $00, $81, $12, $00, $00, $00, $00, $00, $00

const24PageTwo: ; 24
    .db $00, $81, $24, $00, $00, $00, $00, $00, $00

const100PageTwo: ; 100
    .db $00, $82, $10, $00, $00, $00, $00, $00, $00

const3600PageTwo: ; 3600
    .db $00, $83, $36, $00, $00, $00, $00, $00, $00

const2Pow32PageTwo: ; 2^32 = 4 294 967 296
    .db $00, $89, $42, $94, $96, $72, $96, $00, $00

const2Pow39PageTwo: ; 2^39 = 549 755 813 888
    .db $00, $8B, $54, $97, $55, $81, $38, $88, $00

const2Pow40PageTwo: ; 2^40 = 1 099 511 627 776
    .db $00, $8C, $10, $99, $51, $16, $27, $76, $00

const1E14PageTwo: ; 10^14, EXP=$80+14=$8E
    .db $00, $8E, $10, $00, $00, $00, $00, $00, $00

; Useful to indicate an error condition in some parameters, while allowing
; other parameters to be calculated. If an exception is thrown instead (e.g.
; Err: Domain), then the entire calculation will be aborted, and none of the
; parameters can be calculated, which is not as useful in some cases.
constMaxFloatPageTwo: ; 9.9999999999999E99
    .db $00, $E3, $99, $99, $99, $99, $99, $99, $99
