;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2025 Brian T. Park
;
; Routines for extracting information about a given unit from the 'unitTable'.
;
; The C struct equivalent is:
;
; struct UnitTypeInfo {
;    const char* name; // pointer to name, 2 bytes
;    uint8_t baseUnitId; // base unit for this unitType
; }
; sizeof(UnitTypeInfo) = 3
;
; struct UnitInfo {
;    const char* name; // pointer to name, 2 bytes
;    uint8_t unitTypeId; // Length, Area, Volume, Mass, etc
;    float scale; // thisUnit = scale * baseUnit
; }
; sizeof(UnitInfo) = 12
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Offsets to the fields of UnitTypeInfo
unitTypeInfoFieldName equ 0
unitTypeInfoFieldBaseUnitId equ 2

; Offsets into the fields of UnitInfo
unitInfoFieldName equ 0
unitInfoFieldUnitTypeId equ 2
unitInfoFieldScale equ 3

;-----------------------------------------------------------------------------
; UnitTypes
;-----------------------------------------------------------------------------

; Description: Extract the name of the UnitType given in register A, and copy
; it into the buffer given by HL.
;
; The calling code is required to pass a string buffer large enough to hold the
; name of the UnitType (e.g. OP3 or OP4). We cannot simply return the pointer
; to the string to the caller because the caller may be on a different flash
; page than the unitTypeInfoTable.
; Input:
;   - A:u8=unitTypeId
;   - HL:(const char*)=namebuf
; Output:
;   - HL:(const char*)=next char in namebuf
; Destroys: A, IX
; Preserves: BC, DE, HL
;
; **Commented out because it is not used by anything right now.**
;
;ExtractUnitTypeName:
;    push de
;    push bc
;    call findUnitTypeInfoIX ; IX=unitTypeInfo
;    ex de, hl ; DE=namebuf
;    ld l, (ix + unitTypeInfoFieldName)
;    ld h, (ix + unitTypeInfoFieldName + 1)
;    call copyCStringPageOne ; DE+=sizeof(name)
;    ex de, hl ; HL=nameBuf+sizeof(name)
;    pop bc
;    pop de
;    ret

;-----------------------------------------------------------------------------

; Description: Return the pointer to the UnitTypeInfo for given unitTypeId.
; Input:
;   - A:u8=unitTypeId
; Output:
;   - IX:*UnitTypeInfo=unitTypeInfo
; Preserves: A, BC, DE, HL
findUnitTypeInfoIX:
    push hl
    call calcUnitTypeInfoOffset ; HL=offset
    ld ix, unitTypeTable
    ex de, hl ; DE=offset
    add ix, de ; IX=unitTypeInfo
    ex de, hl ; HL=offset
    pop hl
    ret

; Description: Return the byte offset into the unitTypeTable for the given id.
; The formula is:
;   offset = unitTypeId*sizeof(UnitTypeinfo)
;          = unitTypeId*3
;          = unitTypeId*(0b11).
; Input: A=unitTypeId
; Output: HL=offset
; Destroys: HL
; Preserves: A, BC, DE, IX
calcUnitTypeInfoOffset:
    push de
    ld l, a
    ld h, 0 ; HL*0b0001
    ld e, l
    ld d, h
    add hl, hl ; HL*0b0010
    add hl, de ; HL*0b0011
    pop de
    ret

;-----------------------------------------------------------------------------
; Units
;-----------------------------------------------------------------------------

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

; Description: Return the unitTypeId of the unit given in register A.
; Input:
;   - A:u8=unitId
; Output:
;   - A:u8=unitTypeId
; Destroys: A, IX
; Preserves: BC, DE, HL
GetUnitTypeId:
    call findUnitInfoIX ; IX=unitInfo
    ld a, (ix + unitInfoFieldUnitTypeId)
    ret

; Description: Return the baseUnit of the unit given in register A.
; Input:
;   - A:u8=unitId
; Output:
;   - A:u8=baseUnitId
; Preserves: BC, DE, HL
GetUnitBaseId:
    call findUnitInfoIX ; IX=unitInfo
    ld a, (ix + unitInfoFieldUnitTypeId)
    call findUnitTypeInfoIX ; IX=unitTypeInfo
    ld a, (ix + unitTypeInfoFieldBaseUnitId)
    ret

; Description: Return the scale of the unit given in register A.
; Input:
;   - A:u8=unitId
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

; Description: Return the pointer to the UnitInfo for given unitId.
; Input:
;   - A:u8=unitId
; Output:
;   - IX:*UnitInfo=unitInfo
; Preserves: A, BC, DE, HL
findUnitInfoIX:
    push hl
    call calcUnitInfoOffset ; HL=offset
    ld ix, unitTable
    ex de, hl ; DE=offset
    add ix, de ; IX=unitInfo
    ex de, hl ; HL=offset
    pop hl
    ret

; Description: Return the byte offset into the unitTable for the given id.
; The formula is:
;   offset = unitId*sizeof(Unitinfo)
;          = unitId*12
;          = unitId*(0b1100).
; Input: A=unitId
; Output: HL=offset
; Destroys: HL
; Preserves: A, BC, DE, IX
calcUnitInfoOffset:
    push de
    ld l, a
    ld h, 0 ; HL*0b0001
    ld e, l
    ld d, h
    add hl, hl ; HL*0b0010
    add hl, de ; HL*0b0011
    add hl, hl ; HL*0b0110
    add hl, hl ; HL*0b1100
    pop de
    ret
