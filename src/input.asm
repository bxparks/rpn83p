;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Functions related to parsing the inputBuf into a floating point number.
;------------------------------------------------------------------------------

; Description: Close the inputBuf and transfer its contents to the X register
; if it had been opened in edit mode. Otherwise, do nothing.
;
; Most button and menu handlers should probably use closeInputAndRecallX() and
; closeInputAndRecallXY() instead, to transfer the X and Y parameters into the
; OP1 and OP2 variables. This decouples the implementations of those handlers
; from the RPN stack, and making them easier move to different Flash Pages if
; needed.
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

; Close the input buffer, and don't set OP1 to anything.
; Output:
;   - rpnFlagsTvmCalculate: cleared
closeInputAndRecallNone:
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr closeInput

; Close the input buffer, and set OP1=X.
; Output:
;   - OP1=X
;   - rpnFlagsTvmCalculate: cleared
closeInputAndRecallX:
    call closeInput
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    jp rclX

; Close the input buffer, and recall real values into OP1=Y and OP2=X.
; Output:
;   - OP1=Y
;   - OP2=X
;   - rpnFlagsTvmCalculate: cleared
closeInputAndRecallXY:
    call closeInput
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call rclX
    call op1ToOp2
    jp rclY

; Close the input buffer, and recall the potentially complex values into
; OP1/OP2=Y and OP3/OP4=X.
; Output:
;   - OP1/OP2=Y
;   - OP3/OP4=X
;   - rpnFlagsTvmCalculate: cleared
closeInputAndRecallComplexXY:
    call closeInput
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call rclX
    call cp1ToCp3
    jp rclY
