;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Low-level routines for manipulating C strings (NUL terminated).
;-----------------------------------------------------------------------------

; Description: Copy the C string in HL to DE.
; Input: HL, DE: C string
; Output: DE: points to terminating NUL
; Destroys: A
copyCString:
    ld a, (hl)
    ld (de), a
    or a
    ret z
    inc hl
    inc de
    jr copyCString

; Description: Set the character A at the C string in DE.
; Input:
;   - HL: pointer to C string
;   - A: char
; Output: HL=HL+1, points to NUL
; Destroys: none
setCStringToA:
    ld (hl), a
    inc hl
    ld (hl), 0
    ret
