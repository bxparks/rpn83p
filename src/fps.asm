;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Routines related to the TI-OS Floating Point Stack.
;-----------------------------------------------------------------------------

; Description: Push the RpnObject in OP1/OP2 into the FPS, no matter the
; RpnObject type (e.g. real, complex, date, etc).
; Input: OP1/OP2
; Output:
;   - FPS increased by 18 bytes
pushRpnObject1:
    ld hl, 18
    bcall(_AllocFPS1)
    ld hl, (FPS)
    ld de, 18
    or a ; CF=0
    sbc hl, de ; HL=pointer to RpnObject on FPS
    ex de, hl ; DE=pointer to RpnObject on FPS
    ld hl, OP1
    ; copy OP1 into RpnObject on FPS
    ld bc, 9
    ldir
    inc hl ; skip 2 extra bytes in OP1
    inc hl
    ; copy OP2 into RpnObject on FPS
    ld bc, 9
    ldir
    ret

; Description: Pop the RpnObject from FPS to OP1/OP2 no matter the RpnObject
; type.
; Input: FPS
; Output:
;   - OP1/OP2 updated
;   - FPS decreased by 18 bytes
popRpnObject1:
    ld hl, (FPS)
    ld de, 18
    or a ; CF=0
    sbc hl, de ; HL=pointer to RpnObject on FPS
    ld de, OP1
    ; copy RpnObject on FPS to OP1
    ld bc, 9
    ldir
    inc de ; skip 2 extra bytes in OP1
    inc de
    ; copy RpnObject on FPS to OP2
    ld bc, 9
    ldir
    ; deallocate
    ld de, 18
    bcall(_DeallocFPS1)
    ret
