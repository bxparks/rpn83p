;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; STAT register functions.
; TODO: Move stat registers to a separate "RPN83STA" appVar so that we don't
; overlap with [R11,R23].
;-----------------------------------------------------------------------------

; Description: Add OP1 to storage register NN. Used by STAT functions.
; WARNING: Works only for real not complex.
; Input:
;   - OP1:real=float value
;   - C:u8=register index NN, 0-based
; Output:
;   - REGS[NN] += OP1
; Destroys: all
; Preserves: OP1, OP2
stoAddRegNN:
    push bc ; stack=[NN]
    bcall(_PushRealO1) ; FPS=[OP1]
    bcall(_PushRealO2) ; FPS=[OP1,OP2]
    call op1ToOp2
    pop bc ; C=NN
    push bc ; stack=[NN]
    call rclRegNN
    bcall(_FPAdd) ; OP1 += OP2
    pop bc ; C=NN
    call stoRegNN
    bcall(_PopRealO2) ; FPS=[OP1]
    bcall(_PopRealO1) ; FPS=[]; OP1=OP1
    ret

; Description: Subtract OP1 from storage register NN. Used by STAT functions.
; WARNING: Works only for real not complex.
; Input:
;   - OP1:real=float value
;   - C:u8=register index NN, 0-based
; Output:
;   - REGS[NN] -= OP1
; Destroys: all
; Preserves: OP1, OP2
stoSubRegNN:
    push bc ; stack=[NN]
    bcall(_PushRealO1) ; FPS=[OP1]
    bcall(_PushRealO2) ; FPS=[OP1,OP2]
    call op1ToOp2
    pop bc ; C=NN
    push bc
    call rclRegNN
    bcall(_FPSub) ; OP1 -= OP2
    pop bc ; C=NN
    call stoRegNN
    bcall(_PopRealO2) ; FPS=[OP1]
    bcall(_PopRealO1) ; FPS=[]; OP1=OP1
    ret

; Description: Clear the storage registers used by the STAT functions. In
; Linear mode [R11, R16], in All mode [R11, R23], inclusive.
; Input: none
; Output:
;   - B: 0
;   - C: 24
;   - OP1: 0
; Destroys: all, OP1
clearStatRegs:
    call op1Set0
    ld c, 11 ; begin clearing register 11
    ; Check AllMode or LinearMode.
    ld a, (statAllEnabled)
    or a
    jr nz, clearStatRegsAll
    ld b, 6 ; clear first 6 registers in Linear mode
    jr clearStatRegsEntry
clearStatRegsAll:
    ld b, 13 ; clear all 13 registesr in All mode
    jr clearStatRegsEntry
clearStatRegsLoop:
    inc c
clearStatRegsEntry:
    ld a, c
    push bc
    call stoRegNN
    pop bc
    djnz clearStatRegsLoop
    ret
