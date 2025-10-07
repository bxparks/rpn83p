;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Same as common.asm.
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
jumpAOfHLPageOne:
    call getStringPageOne
    ; [[fallthrough]]

; Description: This trampoline hack is needed because the Z80 does not have a
; `call (HL)` analogous to the `jp (HL)` instruction. With this, you can do a
; `call jumpHL` or `call cc, jumpHL`. See
; https://www.msx.org/forum/msx-talk/development/indirect-calls-with-the-z80
; for other hacks, although I figured out this one independently.
jumpHLPageOne:
    jp (HL)

; Description: Implement the equilvalent of `jp (de)`, similar to `jp (HL)`.
; Call this using `call jumpDE` or `call cc, jumpDE`.
jumpDEPageOne:
    push de
    ret


