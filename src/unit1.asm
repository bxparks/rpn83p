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
;    uint8_t unitType; // Length, Area, Volume, Mass, etc
;    uint8_t baseUnitId; // base unit for this unitType
;    float scale; // thisUnit = scale * baseUnit
; }
;
; sizeof(UnitInfo) = 13
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

unitInfoFieldName equ 0
unitInfoFieldUnitType equ 2
unitInfoFieldBaseUnitId equ 3
unitInfoFieldScale equ 4

; Description: Extract the name of the unit given in register A, and copy it
; into the buffer given by HL.
;
; The calling code is required to pass a string buffer large enough to hold the
; name of the unit (e.g. OP3 or OP4). We cannot simply return the pointer to
; the string to the caller because the caller may be on a different flash page
; than the unitInfoTable.
; Input:
;   - A:u8=unitId
;   - HL:(const char*)=namebuf
; Output:
;   - HL:(const char*)=next char in namebuf
; Destroys: A, IX
; Preserves: BC, DE, HL
ExtractUnitName:
    push de
    push bc
    call findUnitInfoIX ; IX=unitInfo
    ex de, hl ; DE=namebuf
    ld l, (ix + unitInfoFieldName)
    ld h, (ix + unitInfoFieldName + 1)
    call copyCStringPageOne ; DE+=sizeof(name)
    ex de, hl ; HL=nameBuf+sizeof(name)
    pop bc
    pop de
    ret

; Description: Return the unitType of the unit given in register A.
; Input:
;   - A:u8=unitId
; Output:
;   - A:u8=unitType
; Destroys: A, IX
; Preserves: BC, DE, HL
GetUnitType:
    call findUnitInfoIX ; IX=unitInfo
    ld a, (ix + unitInfoFieldUnitType)
    ret

; Description: Return the baseUnit of the unit given in register A.
; Input: A:u8=unitId
; Output:
;   - A:u8=baseUnitId
; Preserves: BC, DE, HL
GetUnitBase:
    call findUnitInfoIX ; IX=unitInfo
    ld a, (ix + unitInfoFieldBaseUnitId)
    ret

; Description: Return the scale of the unit given in register A.
; Input: A:u8=unitId
; Output:
;   - OP1:Real=scale
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
