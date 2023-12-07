;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Functions related to parsing the inputBuf into a floating point number.
;------------------------------------------------------------------------------

; Description: Close the inputBuf and transfer its contents to the X register
; if it had been opened in edit mode. Otherwise, do nothing.
; Input:
;   - rpnFlagsEditing: indicates if inputBuf is valid
;   - inputBuf: input buffer
; Output:
;   - rpnFlagsLiftEnabled: always set
;   - inputBufFlagsClosedEmpty: set if inputBuf was in edit mode AND was an
;   empty string when closed
;   - rpnFlagsEditing: always cleared
;   - inputBuf cleared to empty string
;   - X register: set to inputBuf if edited, otherwise unchanged
; Destroys: all, OP1, OP2, OP4
closeInput:
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    bit rpnFlagsEditing, (iy + rpnFlags)
    jr nz, closeInputEditing
    ; Not editing, so must clear inputBufFlagsClosedEmpty.
    res inputBufFlagsClosedEmpty, (iy + inputBufFlags)
    ret
closeInputEditing:
    bcall(_CloseInputBuf)
    call stoX
    res rpnFlagsEditing, (iy + rpnFlags)
    ret

;-----------------------------------------------------------------------------

; Close the input buffer, and recall X into OP1 respectively.
; Output:
;   - rpnFlagsTvmCalculate: cleared
closeInputAndRecallX:
    call closeInput
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    jp rclX

; Close the input buffer, and recall Y and X into OP1 and OP2 respectively.
; Output:
;   - rpnFlagsTvmCalculate: cleared
closeInputAndRecallXY:
    call closeInput
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call rclX
    bcall(_OP1ToOP2)
    jp rclY
