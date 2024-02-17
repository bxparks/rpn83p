;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Low-level routines for manipulating C strings (NUL terminated).
;-----------------------------------------------------------------------------

; Description: Copy the C string in HL to DE.
; Input: HL, DE: C string
; Output: DE: points to terminating NUL
; Destroys: A
copyCStringPageTwo:
    ld a, (hl)
    ld (de), a
    or a
    ret z
    inc hl
    inc de
    jr copyCStringPageTwo
