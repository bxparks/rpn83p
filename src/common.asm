;-----------------------------------------------------------------------------
; Common utilties that are useful in multiple modules.
;-----------------------------------------------------------------------------

; Function: getString(A, HL) -> HL
; Description: Get the string pointer at index A starting with base pointer HL.
; Input:
;   A: index
;   HL: base pointer
; Output: HL: pointer to a string
; Destroys: DE, HL
getString:
    ld e, a
    ld d, 0
    add hl, de ; hl += a * 2
    add hl, de
    ld e, (hl)
    inc hl
    ld d, (hl)
    ex de, hl
    ret

