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
;   - A=index
;   - HL:(const void* const*)=pointer to a list of pointers to subroutines
; Output: depends on the routine called
; Destroys: DE, HL, and others depending on the routine called
jumpAOfHL:
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
