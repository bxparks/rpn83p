;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Common utilties that are useful in multiple modules. None of these should
; depend on the TI-OS.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Indirect jumps and calls.
;-----------------------------------------------------------------------------

; Description: Invoke a function according to the index in A. You can invoke
; this using 'jp' or 'call'.
; Input:
;   - A: index
;   - HL: pointer to a list of pointers to subroutines
; Output: depends on the routine called
; Destroys: DE, HL, and others depending on the routine called
jumpAofHL:
    call getString
    ; [[fallthrough]]

; Description: This trampoline hack is needed because the Z80 does not have a
; `call (HL)` analogous to the `jp (HL)` instruction. With this, you can do a
; `call jumpHL` or `call cc, jumpHL`. See
; https://www.msx.org/forum/msx-talk/development/indirect-calls-with-the-z80
; for other hacks, although I figured out this one independently.
jumpHL:
    jp (HL)

; Description: Implement the equilvalent of `jp (de)`, similar to `jp (HL)`.
; Call this using `call jumpDE` or `call cc, jumpDE`.
jumpDE:
    push de
    ret

;-----------------------------------------------------------------------------
; String common routines. See also 'pstring.asm'.
; TODO: Maybe combine them into a 'string.asm'?
;-----------------------------------------------------------------------------

; Description: Get the string pointer at index A given an array of pointers at
; base pointer HL. Out-of-bounds is NOT checked.
; Input:
;   A: index
;   HL: pointer to an array of pointers
; Output: HL: pointer to a string
; Destroys: DE, HL
; Preserves: A
getString:
    ld e, a
    ld d, 0
    add hl, de ; HL += A * 2
    add hl, de
    ld e, (hl)
    inc hl
    ld d, (hl)
    ex de, hl
    ret

;-----------------------------------------------------------------------------

; Description: Copy the C string in HL to the Pascal string in DE. The C string
; is longer than the destination Pascal string buffer, it is truncated to the
; max length given by C.
; Input:
;   HL: source C string
;   DE: destination Pascal string buffer (with leading size byte)
;   C: max size of Pascal string buffer (assumed to be > 0)
; Output:
;   - buffer at DE updated
;   - A: actual size of Pascal string
; Destroys: A, B, HL
; Preserves: C, DE
copyCToPascal:
    push de ; save pointer to the Pascal string
    ld b, c ; B = max size
    inc de
copyCToPascalLoop:
    ld a, (hl)
    or a ; check for terminating NUL character in C string
    jr z, copyCToPascalLoopEnd
    ld (de), a
    inc hl
    inc de
    djnz copyCToPascalLoop
copyCToPascalLoopEnd:
    ld a, c ; A = max size
    sub a, b ; A = actual size of Pascal string
    pop de ; DE = pointer to Pascal string size byte
    ld (de), a ; save actual Pascal string size
    ret

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

