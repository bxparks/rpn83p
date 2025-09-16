;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Memory routines for floating point (real and complex) numbers.
;-----------------------------------------------------------------------------

; Description: Implement bcall(_Exch9) without the overhead of a bcall().
; Input: DE, HL: pointers to floating point values
; Output: 9-byte contents of DE, HL exchanged
; Destroys: all registers
exchange9:
    ld b, 9
    ; [[fallthrough]]

; Description: Exchange the B number of bytes at DE and HL.
; Input: DE, HL: pointers; B=numBytes
; Output: contents of DE, HL exchanged
; Destroys: all registers
exchangeLoop:
    ld a, (de)
    ld c, (hl)
    ld (hl), a
    ld a, c
    ld (de), a
    inc de
    inc hl
    djnz exchangeLoop
    ret

;-----------------------------------------------------------------------------
; Floating point registers OP1-OP6.
;-----------------------------------------------------------------------------

; Description: Move 9 bytes (size of TI-OS floating point number) from HL to
; OP1. Implements bcall(_Mov9ToOP1) without the overhead of a bcall().
; Input: HL=pointer to float
; Output: (OP1)=contains float
; Destroys: BC, DE, HL
; Preserves: A
move9ToOp1:
    ld de, OP1
    ld bc, 9
    ldir
    ret

; Description: Move 9 bytes (size of TI-OS floating point number) from HL to
; OP2. Implements bcall(_Mov9ToOP2) without the overhead of a bcall().
; Input: HL=pointer to float
; Output: (OP2)=contains float
; Destroys: BC, DE, HL
; Preserves: A
move9ToOp2:
    ld de, OP2
    ld bc, 9
    ldir
    ret

; Description: Move 9 bytes (size of TI-OS floating point number) from HL to
; OP3. Implements bcall(_Mov9ToOP4) without the overhead of a bcall().
; Input: HL=pointer to float
; Output: (OP3)=contains float
; Destroys: BC, DE, HL
; Preserves: A
move9ToOp3:
    ld de, OP3
    ld bc, 9
    ldir
    ret

; Description: Move 9 bytes (size of TI-OS floating point number) from HL to
; OP4. Implements bcall(_Mov9ToOP4) without the overhead of a bcall().
; Input: HL=pointer to float
; Output: (OP4)=contains float
; Destroys: BC, DE, HL
; Preserves: A
move9ToOp4:
    ld de, OP4
    ld bc, 9
    ldir
    ret

; Description: Move 9 bytes (size of TI-OS floating point number) from HL to
; OP4. Implements bcall(_Mov9ToOP5) without the overhead of a bcall().
; Input: HL=pointer to float
; Output: (OP4)=contains float
; Destroys: BC, DE, HL
; Preserves: A
move9ToOp5:
    ld de, OP5
    ld bc, 9
    ldir
    ret

;-----------------------------------------------------------------------------

; Preserves: A
op1ToOp2:
    ld hl, OP1
    jr move9ToOp2

; Preserves: A
op1ToOp3:
    ld hl, OP1
    jr move9ToOp3

; Preserves: A
op1ToOp4:
    ld hl, OP1
    jr move9ToOp4

; Preserves: A
op1ToOp5:
    ld hl, OP1
    jr move9ToOp5

;-----------------------------------------------------------------------------

; Preserves: A
op2ToOp1:
    ld hl, OP2
    jr move9ToOp1

; Preserves: A
op2ToOp3:
    ld hl, OP2
    jr move9ToOp3

; Preserves: A
op2ToOp4:
    ld hl, OP2
    jr move9ToOp4

; Preserves: A
op2ToOp5:
    ld hl, OP2
    jr move9ToOp5

;-----------------------------------------------------------------------------

; Preserves: A
op3ToOp1:
    ld hl, OP3
    jr move9ToOp1

; Preserves: A
op3ToOp2:
    ld hl, OP3
    jr move9ToOp2

; Preserves: A
op3ToOp4:
    ld hl, OP3
    jr move9ToOp4

; Preserves: A
op3ToOp5:
    ld hl, OP3
    jr move9ToOp5

;-----------------------------------------------------------------------------

; Preserves: A
op4ToOp1:
    ld hl, OP4
    jr move9ToOp1

; Preserves: A
op4ToOp2:
    ld hl, OP4
    jr move9ToOp2

; Preserves: A
op4ToOp3:
    ld hl, OP4
    jr move9ToOp3

; Preserves: A
op4ToOp5:
    ld hl, OP4
    jr move9ToOp5

;-----------------------------------------------------------------------------

; Preserves: A
op5ToOp1:
    ld hl, OP5
    jp move9ToOp1

; Preserves: A
op5ToOp2:
    ld hl, OP5
    jp move9ToOp2

; Preserves: A
op5ToOp3:
    ld hl, OP5
    jp move9ToOp3

; Preserves: A
op5ToOp4:
    ld hl, OP5
    jp move9ToOp4

;-----------------------------------------------------------------------------

; Description: Exchange OP1 with OP2. Inlined version of bcall(_OP1ExOP2) to
; avoid the overhead of bcall().
; Output: OP1, OP2 exchanged
; Destroys: A, BC, DE, HL
op1ExOp2:
    ld hl, OP1
    ld de, OP2
    jp exchange9

;-----------------------------------------------------------------------------

; Input: DE: destination
; Preserves: A
move9FromOp1:
    ld hl, OP1
    ld bc, 9
    ldir
    ret

; Input: DE: destination
; Preserves: A
move9FromOp2:
    ld hl, OP2
    ld bc, 9
    ldir
    ret

;-----------------------------------------------------------------------------
; Complex numbers in OPx registers. Complex numbers are stored in consecutive
; registers (e.g. OP1/OP2), but each OPx register is 11 bytes wide not 9 bytes,
; which explains the 22 bytes that we move below.
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

; Input: HL=pointer to 2 floats in OPx registers.
; Destroys: BC, DE, HL
; Preserves: A
move22ToOp5:
    ld de, OP5
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

; Input: DE=pointer to 2 floats in OPx registers.
; Destroys: BC, DE, HL
; Preserves: A
move22FromOp5:
    ld hl, OP5
    ld bc, 22
    ldir
    ret

;-----------------------------------------------------------------------------

; Description: Move complex number in OP1/OP2 to OP3/OP4.
; Preserves: A
cp1ToCp3:
    ld hl, OP1
    jr move22ToOp3

; Description: Move complex number in OP1/OP2 to OP5/OP6.
; Preserves: A
cp1ToCp5:
    ld hl, OP1
    jr move22ToOp5

; Description: Move complex number in OP3/OP4 to OP1/OP2.
; Preserves: A
cp3ToCp1:
    ld hl, OP3
    jr move22ToOp1

; Description: Move complex number in OP5/OP6 to OP1/OP2.
; Preserves: A
cp5ToCp1:
    ld hl, OP5
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
    jp exchangeLoop

;-----------------------------------------------------------------------------

; Description: Shift the 9 bytes starting at OP1+9, down 2 bytes into OP2. This
; is required because the OP1 is 11 bytes bytes and anything that is parsed
; into the last 2 bytes must be shifted into OP2 before those bytes can be
; saved properly into the RPN registers or the storage
; registers.
; Destroys: none
expandOp1ToOp2:
    push bc
    push de
    push hl
    ld de, OP2+9-1
    ld hl, OP2+7-1
    ld bc, 9
    lddr
    pop hl
    pop de
    pop bc
    ret

; Description: The reverse of expandOp1ToOp2().
; Destroys: none
shrinkOp2ToOp1:
    push bc
    push de
    push hl
    ld de, OP1+9
    ld hl, OP2
    ld bc, 9
    ldir
    pop hl
    pop de
    pop bc
    ret
