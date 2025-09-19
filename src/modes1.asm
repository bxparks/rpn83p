;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Functions related to the MODE button.
;------------------------------------------------------------------------------

; Description: Initialize miscellaneous settings under the MODES menu.
ColdInitModes:
    ; set ',EE' button to act as labeled on keypad
    ld a, commaEEModeNormal
    ld (commaEEMode), a
    ; set to {..} mode instead of ".." mode
    ld a, formatRecordModeRaw
    ld (formatRecordMode), a
    ; [[fallthrough]]

; Description: Set the Trig, Display, and Display Digit modes which are shared
; with TI-OS to a known state.
;
; The complex result modes (RRES, CRES) are also shared with the TI-OS through
; the `numMode` variable (which is the same byte as the `fmtFlags`), but those
; are cold initialized by ColdInitComplex(), so we don't need to initialize
; them here.
;
; Destroys: A
coldInitOSModes:
    ; set to RAD (instead of DEG)
    res trigDeg, (iy + trigFlags)
    ; set to FIX (instead of SCI or ENG)
    res fmtExponent, (iy + fmtFlags)
    ; set number of digits to "floating"
    ld a, fmtDigitsFloating
    ld (fmtDigits), a
    ret
