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
copyCString:
    ld a, (hl)
    ld (de), a
    or a
    ret z
    inc hl
    inc de
    jr copyCString

; Description: Append character A to the C-string at HL. Assumes that HL points
; to a buffer big enough to hold one more character.
; Input:
;   - HL: pointer to C-string
;   - A: character to add
; Destroys: none
appendCString:
    push hl
    push af
    jr appendCStringLoopEntry
appendCStringLoop:
    inc hl
appendCStringLoopEntry:
    ld a, (hl)
    or a
    jr nz, appendCStringLoop
appendCStringAtEnd:
    pop af
    ld (hl), a
    inc hl
    ld (hl), 0
    pop hl
    ret
