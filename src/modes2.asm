;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Functions related to the MODE button.
;------------------------------------------------------------------------------

; Description: Initialize miscellaneous settings under the MODES menu.
InitModes:
    ld a, commaEEModeNormal ; factory default setting is "Normal"
    ld (commaEEMode), a
    ;
    ld a, formatRecordModeRaw
    ld (formatRecordMode), a
    ret
