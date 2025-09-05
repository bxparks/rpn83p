;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Routines for RpnDenominate objects.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Convert a Real or an RpnDenominate to the target unit.
; Input:
;   - OP1/OP2:Real|RpnDenominate
;   - A:u8=rpnObjectType
;   - B:u8=srcUnitId
;   - C:u8=targetUnitId
; Destroys: all, OP1
ConvertUnit:
    cp rpnObjectTypeReal
    jr z, convertRealToUnit
    cp rpnObjectTypeDenominate
    jr z, convertUnitToUnit
    bcall(_ErrDataType)

; Description: Convert a Real to the target unit, converting the value into
; its base unit, then attaching the target unit.
; Input:
;   - OP1:Real=value
;   - A:u8=rpnObjectType
;   - C:u8=targetUnitId
; Output:
;   - OP1/OP2:RpnDenominate
; Destroys: all
convertRealToUnit:
    ld a, c ; A=targetUnitId
    call GetUnitBase ; A=baseUnitId; preserves BC
    call normalizeRealToBaseUnit ; OP1=baseValue; preserves BC
    call shiftOp1ToRpnDenominateValue ; HL=OP1; preserves BC
    ld a, c ; A=targetUnitId
    call setOp1RpnDenominatePageTwo
    call expandOp1ToOp2PageTwo
    ret

; Description: Normalize the given value in OP1 to the baseUnit in register A.
; Input:
;   - OP1:Real=value
;   - A:u8=baseUnitId
;   - C:u8=targetUnitId
; Output:
;   -OP1:Real=baseValue
; Preserves: BC
; Destroys: A, DE, HL, OP1, OP2, OP3
normalizeRealToBaseUnit:
    cp c ; if targetUnitId==baseUnitId: ZF=1
    ret z
    push bc
    call op1ToOp2PageTwo ; OP2=targetValue
    pop bc
    push bc
    ld a, c ; A=targetUnitId
    call GetUnitScale ; OP1=scale, thisUnit=scale*baseUnit
    bcall(_FPMult) ; OP1=baseValue=scale*value
    pop bc
    ret

; Description: Convert an RpnDenominate from its source unit to its target
; unit.
; Input:
;   - OP1/OP2:RpnDenominate
;   - A:u8=rpnObjectType
;   - B:u8=srcUnitId
;   - C:u8=targetUnitId
; Destroys: all, OP1
convertUnitToUnit:
    ld a, b
    cp c
    ret z ; source and target are same unit, do nothing
    call checkCompatibleUnitClass
    ; Clobber the new targetUnit
    ld hl, OP1 + rpnDenominatedFieldTargetUnit
    ld (hl), c ; rpnDenominate[unit]=targetUnitId
    ret

; Description: Check that the unitClass of units in registers B and C are
; identical.
; Input:
;   - B=srcUnitId
;   - C=targetUnitId
; Destroys: A, IX
; Throws:
;   - Err:Invalid if unit classes don't match
checkCompatibleUnitClass:
    ld a, b
    call GetUnitClass ; A=unitClass
    ld b, a
    ;
    ld a, c
    call GetUnitClass ; A=unitClass
    ;
    cp b
    ret z
    bcall(_ErrInvalid)

;-----------------------------------------------------------------------------

; Description: Shift real value of OP1 into the 'value' position of a
; RpnDenominate in-situ in OP1.
; Input:
;   - OP1/OP2:RpnDenominate
; Output:
;   - OP1:Real=value
;   - HL=OP1
; Destroys: DE, HL
; Preserves: A, BC
shiftOp1ToRpnDenominateValue:
    push bc
    ld hl, OP1+rpnRealSizeOf-1
    ld de, OP1+rpnRealSizeOf-1+rpnDenominatedFieldValue
    ld bc, rpnRealSizeOf
    lddr
    ex de, hl
    inc hl ; HL=OP1
    pop bc
    ret

; Description: Extract the value of RpnDenominate in OP1 to OP3.
; Input:
;   - OP1/OP2:RpnDenominate
; Output:
;   - OP3:Real=value
; Destroys: BC, DE, HL
; Preserves: A
extractRpnDenominateValueToOp3:
    ld hl, OP1 + rpnDenominatedFieldValue
    ld de, OP3
    ld bc, rpnRealSizeOf
    ldir
    ret
