;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2025 Brian T. Park
;
; Routines for extracting information about a given unit from the 'unitTable'.
;
; The C struct equivalent is:
;
; struct UnitInfo {
;    const char* name; // pointer to name, 2 bytes
;    uint8_t unitClass; // Length, Area, Volume, Mass, etc
;    uint8_t baseUnitId; // base unit for this unitClass
;    float scale; // thisUnit = scale * baseUnit
; }
;
; sizeof(UnitInfo) = 13
;-----------------------------------------------------------------------------

unitInfoFieldName equ 0
unitInfoFieldUnitClass equ 2
unitInfoFieldBaseUnitId equ 3
unitInfoFieldScale equ 4

; Description: Return the name of the unit given in register A.
; Input: A:u8=unitId
; Output:
;   - HL:(const char*)=name
;   - IX:(UnitInfo*)=unitInfo
; Destroys: IX
; Preserves: A, BC, DE
GetUnitName:
    call findUnitInfoIX ; IX=unitInfo
    ld l, (ix + unitInfoFieldName)
    ld h, (ix + unitInfoFieldName + 1)
    ret

; Description: Return the unitClass of the unit given in register A.
; Input: A:u8=unitId
; Output:
;   - A:u8=unitClass
;   - IX:(UnitInfo*)=unitInfo
; Preserves: BC, DE, HL
GetUnitClass:
    call findUnitInfoIX ; IX=unitInfo
    ld a, (ix + unitInfoFieldUnitClass)
    ret

; Description: Return the baseUnit of the unit given in register A.
; Input: A:u8=unitId
; Output:
;   - A:u8=baseUnitId
;   - IX:(UnitInfo*)=unitInfo
; Preserves: BC, DE, HL
GetUnitBase:
    call findUnitInfoIX ; IX=unitInfo
    ld a, (ix + unitInfoFieldBaseUnitId)
    ret

; Description: Return the scale of the unit given in register A.
; Input: A:u8=unitId
; Output:
;   - OP1:Real=scale
;   - IX:(UnitInfo*)=unitInfo
; Destroys: all
GetUnitScale:
    call findUnitInfoIX ; IX=unitInfo
    push ix
    pop hl
    ld de, unitInfoFieldScale
    add hl, de
    ld de, OP1
    ld bc, 9
    ldir
    ret

;-----------------------------------------------------------------------------

; Description: Return the pointer to the UnitInfo for given unit.
; Input:
;   - A:u8=unitId
; Output:
;   - IX:*UnitInfo=unitInfo
; Preserves: A, BC, DE, HL
findUnitInfoIX:
    push hl
    call calcUnitInfoOffset ; HL=offset
    ld ix, unitInfoTable
    ex de, hl ; DE=offset
    add ix, de ; IX=unitInfo
    ex de, hl ; HL=offset
    pop hl
    ret

; Description: Return the byte offset into the unitTable for the given id.
; The formula is: offset=unitId*sizeof(Unitinfo)=unitId*13.
; Input: A=unitId
; Output: HL=offset
; Destroys: HL
; Preserves: A, BC, DE, IX
calcUnitInfoOffset:
    push bc
    push de
    ld l, a
    ld h, 0
    ld c, l
    ld b, h
    add hl, hl
    add hl, hl ; HL=4*unitId
    ld e, l
    ld d, h ; DE=4*unitId
    add hl, hl ; 8*unitId
    add hl, de ; 12*unitId
    add hl, bc ; 13*unitId
    pop de
    pop bc
    ret
