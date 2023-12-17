;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Memory routines for floating point (real) numbers.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Floating point stack (FPS).
;-----------------------------------------------------------------------------

; Description: Exchange OP2 and FPS.
; Destroys: all registers
exchangeFPSOP2:
    ld hl, OP2
    jr exchangeFPSHL

; Description: Exchange OP1 and FPS.
; Destroys: all registers
exchangeFPSOP1:
    ld hl, OP1
    ; [[fallthrough]]

; Description: Exchange the floating point at HL with the top of the FPS.
; This is useful when both OP1 and OP2 contain values that need further
; numerical computation, but those floating point ops will destory OP2 (and
; often OP3). With this helper routine, we can push OP2 to the stack, operate
; on OP1, then exchange OP1 and FPS, operate on OP2, then pop the FPS back to
; OP1.
; Input: HL=floating point value
; Destroys: all registers
; Preserves: all OPx registers
exchangeFPSHL:
    ld c, l
    ld b, h ; BC=HL
    ld hl, (FPS)
    ld de, 9
    or a ; clear CF
    sbc hl, de ; HL=(FPS) - 9
    ld e, c
    ld d, b ; DE=original HL
    ; [[fallthrough]]

; Description: Implement bcall(_Exch9) without the overhead of a bcall().
; Input: DE, HL: pointers to floating point values
; Output: 9-byte contents of DE, HL exchanged
; Destroys: all registers
exchangeFloat:
    ld b, 9
exchangeFloatLoop:
    ld a, (de)
    ld c, (hl)
    ld (hl), a
    ld a, c
    ld (de), a
    inc de
    inc hl
    djnz exchangeFloatLoop
    ret

; Description: Exchange the top 2 floating point numbers on the FPS.
; Destroys: all
; Preserves: OP1, OP2
exchangeFPSFPS:
    ld hl, (FPS)
    ld de, 9
    or a ; clear CF
    sbc hl, de ; HL=(FPS) - 9
    ld c, l
    ld b, h
    sbc hl, de ; HL=(FPS) - 18
    ld e, c
    ld d, b
    jr exchangeFloat

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

;-----------------------------------------------------------------------------

; Description: Exchange OP1 with OP2. Inlined version of bcall(_OP1ExOP2) to
; avoid the overhead of bcall().
; Output: OP1, OP2 exchanged
; Destroys: A, BC, DE, HL
op1ExOp2:
    ld hl, OP1
    ld de, OP2
    jp exchangeFloat

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
