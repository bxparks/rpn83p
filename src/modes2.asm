;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Functions related to the MODE button.
;------------------------------------------------------------------------------

; Description: Initialize miscellaneous settings under the MODES menu.
ColdInitModes:
    ld a, commaEEModeNormal ; set ',EE' button to act as labeled on keypad
    ld (commaEEMode), a
    ;
    ld a, formatRecordModeRaw
    ld (formatRecordMode), a
    ret
