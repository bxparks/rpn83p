;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Routines related to the TI-OS Floating Point Stack.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; RpnObject (OP1/OP2, OP3/OP4, OP5,OP6) to FPS.
;-----------------------------------------------------------------------------

; Description: Push OP1/OP2 to FPS.
; Output: HL=pointer to RpnObject on FPS.
; Destroys: A, HL
; Preserves: BC, DE
PushRpnObject1:
    ld hl, OP1
    jr pushRpnObject

; Description: Pop RpnObject from FPS to OP1/OP2.
; Output: DE=OP1
; Destroys: A, DE
; Preserves: BC, HL
PopRpnObject1:
    ld de, OP1
    jr popRpnObject

; Description: Push OP3/OP4 to FPS.
; Output: HL=pointer to RpnObject on FPS.
; Destroys: A, HL
; Preserves: BC, DE
PushRpnObject3:
    ld hl, OP3
    jr pushRpnObject

; Description: Pop RpnObject from FPS to OP3/OP4.
; Output: DE=OP3
; Destroys: A, DE
; Preserves: BC, HL
PopRpnObject3:
    ld de, OP3
    jr popRpnObject

; Description: Push OP5/OP6 to FPS.
; Output: HL=pointer to RpnObject on FPS.
; Destroys: A, HL
; Preserves: BC, DE
PushRpnObject5:
    ld hl, OP5
    jr pushRpnObject

; Description: Pop RpnObject from FPS to OP5/OP6.
; Output: DE=OP5
; Destroys: A, DE
; Preserves: BC, HL
PopRpnObject5:
    ld de, OP5
    jr popRpnObject

;-----------------------------------------------------------------------------

; Description: Push the RpnObject in OP1/OP2 into the FPS, no matter the
; RpnObject type (e.g. real, complex, date, etc).
; Input:
;   - HL:pointer to an OP register
;   - (FPS): pointer to end of FPS stack
; Output:
;   - HL=pointer to RpnObject on FPS
;   - (FPS) increased by 18 bytes
; Destroys: A, HL
; Preserves: DE, BC,
pushRpnObject:
    push bc ; stack=[BC]
    push de ; stack=[BC,DE]
    push hl ; stack=[BC,DE,OPx]
    ;
    ld hl, (FPS) ; HL=FPS-18
    push hl ; stack=[BC,DE,OPx,FPS-18]
    ; allocate space on stack
    ld hl, 18
    bcall(_AllocFPS1)
    ; copy OP1 into RpnObject on FPS
    pop de ; stack=[BC,DE,OPx]; DE=FPS-18
    pop hl ; stack=[BC,DE]; HL=OPx
    push de ; stack=[BC,DE,FPS-18]
    ld bc, 9
    ldir
    inc hl ; skip 2 extra bytes in OP1
    inc hl
    ; copy OP2 into RpnObject on FPS
    ld bc, 9
    ldir
    ;
    pop hl ; stack=[BC,DE]; HL=FPS-18
    pop de ; stack=[BC]; DE=restored
    pop bc ; stack=[]; BC=restored
    ret

; Description: Reserver an RpnObject on the FPS.
; Input: none
; Output: HL=pointer to RpnObject on FPS
; Preserves: BC, DE
reserveRpnObject:
    push bc
    push de
    ld hl, (FPS)
    push hl
    ld hl, 18
    bcall(_AllocFPS1) ; destroys all
    pop hl ; HL=FPS-18
    pop de
    pop bc
    ret

; Description: Pop the RpnObject from FPS to DE no matter the RpnObject type.
; Input:
;   - DE: pointer to an OPx register
;   - (FPS): pointer to end of stack
; Output:
;   - (OPx) register filled
;   - (FPS) decreased by 18 bytes
; Destroys: A
; Preserves: BC, DE, HL
popRpnObject:
    push bc ; stack=[BC]
    push de ; stack=[BC,DE]
    push hl ; stack=[BC,DE,HL]
    ; copy RpnObject on FPS to OPx pointed by DE
    ld hl, (FPS)
    ld bc, 18
    or a ; CF=0
    sbc hl, bc ; HL=pointer to RpnObject on FPS
    ld bc, 9
    ldir
    ; copy RpnObject on FPS to OP{x+1}
    inc de ; skip 2 extra bytes in OPx
    inc de
    ld bc, 9
    ldir
    ; deallocate
    ld de, 18
    bcall(_DeallocFPS1)
    ;
    pop hl ; stack=[BC,DE]; HL=restored
    pop de ; stack=[BC] ; DE=restored
    pop bc ; stack=[]; BC=restored
    ret

; Description: Drop the RpnObject (18 byte) from FPS.
; Input: none
; Output: (FPS) decreased by 18 bytes
; Preserves: all
dropRpnObject:
    push hl
    push de
    ld de, 18
    bcall(_DeallocFPS1)
    pop de
    pop hl
    ret

;-----------------------------------------------------------------------------
; Raw 9 bytes from OPx to FPS.
;-----------------------------------------------------------------------------

; Description: Push 9 raw bytes from OP1 into FPS.
; Output: HL=pointer to raw 9 bytes on FPS.
; Destroys: A, HL
; Preserves: BC, DE
pushRaw9Op1:
    ld hl, OP1
    jr pushRaw9

; Description: Pop 9 raw bytes from FPS to OP1.
; Output: DE=OP1
; Destroys: DE
; Preserves: BC, HL
popRaw9Op1:
    ld de, OP1
    jr popRaw9

; Description: Push 9 raw bytes from OP2 into FPS.
; Output: HL=pointer to raw 9 bytes on FPS.
; Destroys: A, HL
; Preserves: BC, DE
pushRaw9Op2:
    ld hl, OP2
    jr pushRaw9

; Description: Pop 9 raw bytes from FPS to OP2.
; Output: DE=OP2
; Destroys: DE
; Preserves: BC, HL
popRaw9Op2:
    ld de, OP2
    jr popRaw9

; Description: Push 9 raw bytes from OP3 into FPS.
; Output: HL=pointer to raw 9 bytes on FPS.
; Destroys: A, HL
; Preserves: BC, DE
pushRaw9Op3:
    ld hl, OP3
    jr pushRaw9

; Description: Pop 9 raw bytes from FPS to OP3.
; Output: DE=OP3
; Destroys: DE
; Preserves: BC, HL
popRaw9Op3:
    ld de, OP3
    jr popRaw9

;-----------------------------------------------------------------------------

; Description: Push 9 raw bytes from OPx to FPS.
; Input:
;   - HL:pointer to an OP register
; Output:
;   - (FPS) increased by 9 bytes
;   - HL=pointer to Raw9 on FPS
; Destroys: A, HL
; Preserves: BC, DE
pushRaw9:
    push bc ; stack=[BC]
    push de ; stack=[BC,DE]
    push hl ; stack=[BC,DE,OPx]
    ld hl, (FPS) ; HL=FPS-9
    push hl ; stack=[BC,DE,OPx,FPS-9]
    ; allocate space on stack
    ld hl, 9
    bcall(_AllocFPS1)
    ; copy 9 raw bytes in OP1 to FPS
    pop de ; stack=[BC,DE,OPx]; DE=FPS-9
    pop hl ; stack=[BC,DE]; HL=OPx
    push de ; stack=[BC,DE,FPS-9]
    ld bc, 9
    ldir
    pop hl ; stack=[BC,DE]; HL=FPS-9
    pop de ; stack=[BC]; DE=restored
    pop bc ; stack=[]; BC=restored
    ret

; Description: Reserve 9 raw bytes on FPS.
; Input: none
; Output: HL=pointer to raw 9 bytes on FPS.
; Preserved: BC, DE
reserveRaw9:
    push bc
    push de
    ld hl, (FPS)
    push hl ; stack=[FPS-9]
    ld hl, 9
    bcall(_AllocFPS1)
    pop hl ; HL=FPS-18
    pop de
    pop bc
    ret

; Description: Pop the Raw 9 bytes from FPS to DE.
; Input:
;   - DE: pointer to an OPx register
;   - (FPS): pointer to end of FPS stack
; Output:
;   - (OPx) register filled
;   - (FPS) decreased by 9 bytes
; Destroys: A
; Preserves: BC, DE, HL
popRaw9:
    push hl
    push de
    push bc
    ;
    ; copy raw 9 bytes on FPS to DE
    ld hl, (FPS)
    ld bc, 9
    or a ; CF=0
    sbc hl, bc ; HL=pointer to raw 9 bytes on FPS
    ldir
    ;
    ld de, 9
    bcall(_DeallocFPS1)
    ;
    pop bc
    pop de
    pop hl
    ret

; Description: Drop the raw 9 bytes from FPS.
; Input: none
; Output: (FPS) decreased by 9 bytes
; Preserves: all
dropRaw9:
    push hl
    push de
    ld de, 9
    bcall(_DeallocFPS1)
    pop de
    pop hl
    ret
