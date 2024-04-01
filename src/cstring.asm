;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Low-level routines for manipulating C strings (NUL terminated).
;-----------------------------------------------------------------------------

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

;-----------------------------------------------------------------------------

; Description: Get the string pointer at index A given an array of pointers at
; base pointer HL. Out-of-bounds is NOT checked.
; Input:
;   - A=index
;   - HL:(const char* const*)=pointer to an array of string pointers
; Output:
;   - HL:(const char*)=string
; Destroys: DE, HL
; Preserves: A
getString:
    ld e, a
    ld d, 0
    ; [[fallthrough]]

; Description: Get the string pointer at index DE given an array of pointers at
; base pointer HL. Out-of-bounds is NOT checked.
;
; Input:
;   - DE=index
;   - HL:(const char* const*)=pointer to array of string pointers
; Output:
;   - HL:(const char*)=string
; Destroys: DE, HL
; Preserves: A, BC
getDEString:
    add hl, de ; HL+=A*2
    add hl, de
    ld e, (hl)
    inc hl
    ld d, (hl)
    ex de, hl
    ret
