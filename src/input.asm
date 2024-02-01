;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Functions related to parsing the inputBuf into a floating point number.
;------------------------------------------------------------------------------

; Description: Initialize the commaEEMode.
initCommaEEMode:
    ld a, commaEEModeNormal ; factory default setting is "Normal"
    ld (commaEEMode), a
    ret

; Description: Close the inputBuf by parsing its content into OP1, then
; transfer OP1 into the X register. If the app is *not* in edit mode, do
; nothing (except to reset the 'inputBufFlagsClosedEmpty' flag which should
; only be set if it was in editMode and the inputBuf was empty).
;
; The 'rpnFlagsLiftEnabled' flag is always* set after this call. It is up to
; the calling handler to override this default and disable it if necessary
; (e.g. ENTER, or Sigma+). The rpnFlagsLiftEnabled is used by the next manual
; entry of a number (digits 0-9 usualy, sometimes A-F in hexadecimal mode).
; Usually, the next manual number entry lifts the stack, but this flag can be
; used to disable that. (e.g. ENTER will disable the lift of the next number).
;
; Most button and menu handlers should probably use closeInputAndRecallX() and
; closeInputAndRecallXY() instead, to transfer the X and Y parameters into the
; OP1 and OP2 variables. This decouples the implementations of those handlers
; from the RPN stack, and making them easier move to different Flash Pages if
; needed.
;
; Input:
;   - rpnFlagsEditing: indicates if inputBuf is valid
;   - inputBuf: input buffer
; Output:
;   - X register: set to inputBuf if edited, otherwise unchanged
;   - rpnFlagsLiftEnabled: always set
;   - inputBufFlagsClosedEmpty: set if inputBuf was in edit mode AND was an
;   empty string when closed
;   - rpnFlagsEditing: always cleared
;   - inputBuf cleared to empty string
; Destroys: all, OP1, OP2, OP3, OP4, OP5
closeInput:
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    bit rpnFlagsEditing, (iy + rpnFlags)
    jr nz, closeInputEditing
    ; Not editing, so must clear inputBufFlagsClosedEmpty.
    res inputBufFlagsClosedEmpty, (iy + inputBufFlags)
    ret
closeInputEditing:
    bcall(_CloseInputBuf) ; OP1/OP2=real or complex number
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

; Close the input buffer, and recall real X into OP1.
; Output:
;   - OP1=X
;   - rpnFlagsTvmCalculate: cleared
closeInputAndRecallX:
    call closeInput
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call rclX ; A=objectType
    cp rpnObjectTypeReal
    ret z
    bcall(_ErrDataType)

; Close the input buffer, and recall real values into OP1=Y and OP2=X.
; Output:
;   - OP1=Y
;   - OP2=X
;   - rpnFlagsTvmCalculate: cleared
closeInputAndRecallXY:
    call closeInput
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call rclX ; A=objectType
    cp rpnObjectTypeReal
    jr nz, closeInputAndRecallXYErr
    call op1ToOp2
    call rclY ; A=objectType
    cp rpnObjectTypeReal
    ret z
closeInputAndRecallXYErr:
    bcall(_ErrDataType)

; Close the input buffer, and recall the real or complex X to OP1/OP2.
; Output:
;   - OP1=X
;   - rpnFlagsTvmCalculate: cleared
closeInputAndRecallUniversalX:
    call closeInput
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    jp rclX

; Close the input buffer, and recall the real or complex values X, Y into
; OP1/OP2=Y and OP3/OP4=X.
; Output:
;   - OP1/OP2=Y
;   - OP3/OP4=X
;   - rpnFlagsTvmCalculate: cleared
closeInputAndRecallUniversalXY:
    call closeInput
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call rclX ; A=objectType
    call cp1ToCp3
    jp rclY

;-----------------------------------------------------------------------------

; Close the input buffer, parse RpnDate{} or RpnDateTime{} record, place it
; into OP1.
closeInputAndRecallRpnDateX:
    call closeInput
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call rclX ; A=objectType
    cp rpnObjectTypeDate
    ret z
    cp rpnObjectTypeDateTime
    ret z
    bcall(_ErrDataType)
