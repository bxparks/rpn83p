;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Save the TI-OS state upon app start, and restore the OS state upon exit.
;
; Capitalized labels are intended to be exported to the branch table on flash
; page 0. Lowercased labels are intended to be local to the current flash page.
;-----------------------------------------------------------------------------

; Description: Save the TI-OS state.
; Destroys: A
SaveOSState:
    ld a, (iy + trigFlags)
    ld (savedTrigFlags), a
    ld a, (iy + fmtFlags)
    ld (savedFmtFlags), a
    ld a, (fmtDigits)
    ld (savedFmtDigits), a
    ret

RestoreOSState:
    ld a, (savedTrigFlags)
    ld (iy + trigFlags), a
    ld a, (savedFmtFlags)
    ld (iy + fmtFlags), a
    ld a, (savedFmtDigits)
    ld (fmtDigits), a
    ret
