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

PushRpnObject1:
    ld hl, OP1
    jr pushRpnObject

PopRpnObject1:
    ld de, OP1
    jr popRpnObject

PushRpnObject3:
    ld hl, OP3
    jr pushRpnObject

PopRpnObject3:
    ld de, OP3
    jr popRpnObject

PushRpnObject5:
    ld hl, OP5
    jr pushRpnObject

PopRpnObject5:
    ld de, OP5
    jr popRpnObject

;-----------------------------------------------------------------------------

; Description: Push the RpnObject in OP1/OP2 into the FPS, no matter the
; RpnObject type (e.g. real, complex, date, etc).
; Input:
;   - HL:pointer to an OP register
; Output:
;   - FPS increased by 18 bytes
; Destroys: all
pushRpnObject:
    push hl ; stack=[OPx]
    ld hl, 18
    bcall(_AllocFPS1)
    ld hl, (FPS)
    ld de, 18
    or a ; CF=0
    sbc hl, de ; HL=pointer to RpnObject on FPS
    ex de, hl ; DE=pointer to RpnObject on FPS
    pop hl ; stack=[]; HL=OPx
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
; Input:
;   - DE: pointer to an OP register
;   - FPS
; Output:
;   - OPx register updated
;   - FPS decreased by 18 bytes
; Destroys: all
popRpnObject:
    ld hl, (FPS)
    ld bc, 18
    or a ; CF=0
    sbc hl, bc ; HL=pointer to RpnObject on FPS
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

;-----------------------------------------------------------------------------

