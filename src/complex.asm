;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Memory routines for complex numbers.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Memory routines to support complex numbers. Each OPx register is 11 bytes,
; not 9 bytes.
;-----------------------------------------------------------------------------

; Input: HL=pointer to 2 floats in OPx registers.
; Destroys: BC, DE, HL
; Preserves: A
move22ToOp1:
    ld de, OP1
    ld bc, 22
    ldir
    ret

; Input: HL=pointer to 2 floats in OPx registers.
; Destroys: BC, DE, HL
; Preserves: A
move22ToOp3:
    ld de, OP3
    ld bc, 22
    ldir
    ret

; Input: DE=pointer to 2 floats in OPx registers.
; Destroys: BC, DE, HL
; Preserves: A
move22FromOp1:
    ld hl, OP1
    ld bc, 22
    ldir
    ret

; Input: DE=pointer to 2 floats in OPx registers.
; Destroys: BC, DE, HL
; Preserves: A
move22FromOp3:
    ld hl, OP3
    ld bc, 22
    ldir
    ret

;-----------------------------------------------------------------------------

; Description: Move complex number in OP1/OP2 to OP3/OP4.
; Preserves: A
cp1ToCp3:
    ld hl, OP1
    jr move22ToOp3

; Description: Move complex number in OP3/OP4 to OP1/OP2.
; Preserves: A
cp3ToCp1:
    ld hl, OP3
    jr move22ToOp1

; Description: Exchange OP1/OP2 with OP3/OP4.
; Destroys: all
cp1ExCp3:
    ld de, OP1
    ld hl, OP3
    ; [[fallthrough]]

; Description: Exchange 2 complex numbers.
; Input: DE, HL: pointers to complex values
; Output: 22-byte contents of DE, HL exchanged
; Destroys: all registers
exchangeComplex:
    ld b, 22
    jp exchangeFloatLoop
