;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Functions to convert between TI-OS floating point and integer types, mostly
; to u40/i40 integers.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;------------------------------------------------------------------------------

; Description: Convert the i40 (signed integer) referenced by HL to a floating
; point number in OP1.
; Input: HL: pointer to i40 (must not be OP2)
; Output: OP1: floating point equivalent of u40(HL)
; Destroys: A, B, C, DE
; Preserves: HL, OP2
ConvertI40ToOP1:
    call isPosU40 ; ZF=1 if positive or zero
    jr z, ConvertU40ToOP1
    call negU40 ; U40=-U40
    call ConvertU40ToOP1
    bcall(_InvOP1S) ; invert the sign
    ret

; Description: Convert the u40 referenced by HL to a floating point number in
; OP1.
; Input: HL: pointer to u40 (must not be OP2)
; Output: OP1: floating point equivalent of u40(HL)
; Destroys: A, B, C, DE
; Preserves: HL, OP2
ConvertU40ToOP1:
    push hl
    bcall(_PushRealO2) ; FPS=[OP2 saved]
    bcall(_OP1Set0)
    pop hl
    push hl
    ld de, 4
    add hl, de ; HL points to most significant byte
    ld b, 5
convertU40ToOP1Loop:
    ld a, (hl)
    dec hl
    push bc
    call AddAToOP1
    pop bc
    djnz convertU40ToOP1Loop
    bcall(_PopRealO2) ; FPS=[]; OP2=OP2 saved
    pop hl
    ret
