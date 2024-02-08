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

; Description: Push OP1/OP2 to FPS.
; Output: HL=pointer to RpnObject on FPS.
PushRpnObject1:
    ld hl, OP1
    jr pushRpnObject

PopRpnObject1:
    ld de, OP1
    jr popRpnObject

; Description: Push OP3/OP4 to FPS.
; Output: HL=pointer to RpnObject on FPS.
PushRpnObject3:
    ld hl, OP3
    jr pushRpnObject

PopRpnObject3:
    ld de, OP3
    jr popRpnObject

; Description: Push OP5/OP6 to FPS.
; Output: HL=pointer to RpnObject on FPS.
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
;   - (FPS): pointer to end of FPS stack
; Output:
;   - HL=pointer to RpnObject on FPS
;   - (FPS) increased by 18 bytes
; Destroys: all
pushRpnObject:
    push hl ; stack=[OPx]
    ld hl, (FPS) ; HL=FPS1=futureFPS-18
    push hl ; stack=[OPx,FPS1]
    ; allocate space on stack
    ld hl, 18
    bcall(_AllocFPS1)
    ; copy OP1 into RpnObject on FPS
    pop de ; stack=[OPx]; DE=FPS1
    pop hl ; stack=[]; HL=OPx
    push de ; stack=[FPS1]
    ld bc, 9
    ldir
    inc hl ; skip 2 extra bytes in OP1
    inc hl
    ; copy OP2 into RpnObject on FPS
    ld bc, 9
    ldir
    pop hl ; stack=[]; HL=FPS1
    ret

; Description: Pop the RpnObject from FPS to DE no matter the RpnObject type.
; Input:
;   - DE: pointer to an OPx register
;   - (FPS): pointer to end of stack
; Output:
;   - (OPx) register filled
;   - (FPS) decreased by 18 bytes
; Destroys: all
popRpnObject:
    ld hl, (FPS)
    ; copy RpnObject on FPS to OPx pointed by DE
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
    ret

;-----------------------------------------------------------------------------

; Description: Push 9 raw bytes from OP1 into FPS.
; Output: HL=pointer to raw 9 bytes on FPS.
; Destroys: all
pushRaw9Op1:
    ld hl, OP1
    jr pushRaw9

popRaw9Op1:
    ld de, OP1
    jr popRaw9

; Description: Push 9 raw bytes from OP1 into FPS.
; Output: HL=pointer to raw 9 bytes on FPS.
; Destroys: all
pushRaw9Op2:
    ld hl, OP2
    jr pushRaw9

popRaw9Op2:
    ld de, OP2
    jr popRaw9

;-----------------------------------------------------------------------------

; Description: Push 9 raw bytes from OPx to FPS.
; Input:
;   - HL:pointer to an OP register
; Output:
;   - (FPS) increased by 9 bytes
;   - HL=pointer to Raw9 on FPS
; Destroys: all
pushRaw9:
    push hl ; stack=[OPx]
    ld hl, (FPS) ; HL=FPS0=futureFPS-9
    push hl ; stack=[OPx,FPST]
    ; allocate space on stack
    ld hl, 9
    bcall(_AllocFPS1)
    ; copy 9 raw bytes in OP1 to FPS
    pop de ; stack=[OPx]; DE=FPS0
    pop hl ; stack=[]; HL=OPx
    push de ; stack=[FPS0]
    ld bc, 9
    ldir
    pop hl ; stack=[]; HL=FPS0
    ret

; Description: Pop the Raw 9 bytes from FPS to DE.
; Input:
;   - DE: pointer to an OPx register
;   - (FPS): pointer to end of FPS stack
; Output:
;   - (OPx) register filled
;   - (FPS) decreased by 9 bytes
; Destroys: all
popRaw9:
    ld hl, (FPS)
    ; copy raw 9 bytes on FPS to DE
    ld bc, 9
    or a ; CF=0
    sbc hl, bc ; HL=pointer to raw 9 bytes on FPS
    ldir
    ; [[fallthrough]]

; Description: Drop the raw 9 bytes from FPS.
; Input: none
; Output: (FPS) decreased by 9 bytes
; Destroys: DE
dropRaw9:
    ld de, 9
    bcall(_DeallocFPS1)
    ret
