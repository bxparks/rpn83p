;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Floating point common routines, some duplicated into float1.asm.
;-----------------------------------------------------------------------------

#ifdef USE_RTOP_WITH_SCALING

; Description: Clear the sign of OP3. Same behavior as ClrOP1S() and ClrOP2S()
; from TI-OS.
; Destroys: A
clearOp3Sign:
    ld a, (OP3)
    res 7, a
    ld (OP3), a
    ret

; Description: Check if OP3 is floating 0.0. Same as CkOP1FP0() and CkOP2FP0()
; from TI-OS.
; Destroys: A
checkOp3FP0:
    ld a, (OP3+2) ; mantissa first digit
    and $F0 ; if first digit is zero: ZF=1
    ret

#endif
