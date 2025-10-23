;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Low-level routines for manipulating C strings (NUL terminated). Some of these
; are duplicates of cstring.asm so that they can be used in Flash Page 1.
;-----------------------------------------------------------------------------

; Description: Copy the C string in HL to DE.
; Input: HL, DE:(char*)
; Output: DE points to terminating NUL
; Destroys: A, DE, HL
; Preserves: BC
copyCStringPageFour:
    ld a, (hl)
    ld (de), a
    or a
    ret z
    inc hl
    inc de
    jr copyCStringPageFour
