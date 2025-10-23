;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Memory routines related to floating point values and registers, basically
; duplicated from memory2.asm.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Exchange FPS operations.
;-----------------------------------------------------------------------------

; Description: Exchange OP2 and FPS.
; Destroys: all registers
exchangeFPSOP2PageFour:
    ld hl, OP2
    jr exchangeFPSHLPageFour

; Description: Exchange OP1 and FPS.
; Destroys: all registers
exchangeFPSOP1PageFour:
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
exchangeFPSHLPageFour:
    ex de, hl ; DE=saved
    ld hl, (FPS)
    ld bc, 9
    or a ; CF=0
    sbc hl, bc ; HL=(FPS)-9
    ; [[fallthrough]]

; Description: Implement bcall(_Exch9) without the overhead of a bcall().
; Input: DE, HL: pointers to floating point values
; Output: 9-byte contents of DE, HL exchanged
; Destroys: all registers
exchange9PageFour:
    ld b, 9
    ; [[fallthrough]]

; Description: Exchange 'B' bytes between DE and HL.
; Destroys: all registers
exchangeLoopPageFour:
    ld a, (de)
    ld c, (hl)
    ld (hl), a
    ld a, c
    ld (de), a
    inc de
    inc hl
    djnz exchangeLoopPageFour
    ret

; Description: Exchange 18 bytes between DE and HL pointers.
; Input: DE, HL: pointers to complex values
; Output: 18-byte contents of DE, HL exchanged
; Destroys: all registers
exchange18PageFour:
    ld b, 18
    jp exchangeLoopPageFour

; Description: Exchange the top 2 floating point numbers on the FPS.
; Destroys: all
; Preserves: OP1, OP2
exchangeFPSFPSPageFour:
    ld hl, (FPS)
    ld bc, 9
    or a ; clear CF
    sbc hl, bc ; HL=(FPS)-9
    ld e, l
    ld d, h
    sbc hl, bc ; HL=(FPS)-18
    jr exchange9PageFour

;-----------------------------------------------------------------------------
; Floating point registers OP1-OP6.
;-----------------------------------------------------------------------------

; Description: Move 9 bytes (size of TI-OS floating point number) from HL to
; OP1. Implements bcall(_Mov9ToOP1) without the overhead of a bcall().
; Input: HL=pointer to float
; Output: (OP1)=contains float
; Destroys: BC, DE, HL
; Preserves: A
move9ToOp1PageFour:
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
move9ToOp2PageFour:
    ld de, OP2
    ld bc, 9
    ldir
    ret

; Description: Move 9 bytes (size of TI-OS floating point number) from HL to
; OP3. Implements bcall(_Mov9ToOP3) without the overhead of a bcall().
; Input: HL=pointer to float
; Output: (OP2)=contains float
; Destroys: BC, DE, HL
; Preserves: A
move9ToOp3PageFour:
    ld de, OP3
    ld bc, 9
    ldir
    ret

; Description: Move 9 bytes (size of TI-OS floating point number) from OP1 to
; DE. Implements bcall(_MovFrOP1) without the overhead of a bcall().
; Input:
;   - DE=destination pointer to float
;   - OP1=float
; Output: (DE)=contains OP1
; Destroys: BC, DE, HL
; Preserves: A
move9FromOp1PageFour:
    ld hl, OP1
    ld bc, 9
    ldir
    ret

;-----------------------------------------------------------------------------

; Description: Move 9 bytes from OP1 to OP2, avoiding the overhead of
; bcall(_OP1ToOP2).
; Destroys: BC, DE, HL
; Preserves: A
op1ToOp2PageFour:
    ld hl, OP1
    jr move9ToOp2PageFour

; Description: Move 9 bytes from OP1 to OP3.
; Destroys: BC, DE, HL
; Preserves: A
op1ToOp3PageFour:
    ld hl, OP1
    jr move9ToOp3PageFour

; Description: Move 9 bytes from OP1 to OP4.
; Destroys: BC, DE, HL
; Preserves: A
op1ToOp4PageFour:
    ld de, OP4
    jr move9FromOp1PageFour

; Description: Move 9 bytes from OP2 to OP1.
; Destroys: BC, DE, HL
; Preserves: A
op2ToOp1PageFour:
    ld hl, OP2
    jr move9ToOp1PageFour

; Description: Move 9 bytes from OP3 to OP1.
; Destroys: BC, DE, HL
; Preserves: A
op3ToOp1PageFour:
    ld hl, OP3
    jr move9ToOp1PageFour

; Description: Move 9 bytes from OP3 to OP2.
; Destroys: BC, DE, HL
; Preserves: A
op3ToOp2PageFour:
    ld hl, OP3
    jr move9ToOp2PageFour

; Description: Move 9 bytes from OP4 to OP1.
; Destroys: BC, DE, HL
; Preserves: A
op4ToOp1PageFour:
    ld hl, OP4
    jr move9ToOp1PageFour

;-----------------------------------------------------------------------------

; Description: Exchange OP1 with OP2. Inlined version of bcall(_OP1ExOP2) to
; avoid the overhead of bcall().
; Output: OP1, OP2 exchanged
; Destroys: A, BC, DE, HL
op1ExOp2PageFour:
    ld hl, OP1
    ld de, OP2
    jp exchange9PageFour

; Description: Exchange CP1=OP1/OP2 with CP3=OP3/OP4.
; Output: CP1, CP3 exchanged
; Destroys: all
cp1ExCp3PageFour:
    ld de, OP1
    ld hl, OP3
    ld b, 22 ; each OP register is 11 bytes
    jp exchangeLoopPageFour
