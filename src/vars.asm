;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; RPN stack registers and storage registers are implemented using TI-OS list
; variables. Stack variables are stored in a list named 'STK' and storage
; registers are stored in a list named 'REGS' (which is similar to the 'REGS'
; variable used on the HP-42S calculator).
;
; There have been at least 3 implementations of the storage registers and stack
; variables:
;
; 1) Single Letter Variables
;
; Early versions of RPN83P mapped each stack register to a single-letter real
; variables in the TI-OS, in other words, X, Y, Z, T, R. They were convenient
; because the TI-OS seemed to provide a number of subroutines (e.g. StoX, RclX,
; etc), which makde it relatively easy access those single-letter variables.
;
; 2) ListObj Variables
;
; Later, I wanted to rename those single-letter variables to STX, STY, STZ,
; STT, and STL, to avoid any conflicts with other apps that may use those
; variables. But I discovered that the TI-OS allows only a single-letter
; variable name for RealObj variables. Multi-letter variables are supported
; only for ListObj, CListObj, ProgObj, ProtProgObj, and AppVarObj. Since I had
; already learned how to use the TI-OS routines related to list variables, it
; made sense to move the RPN stack variables to a ListObj variable. It is named
; 'STK' because I wanted it to be relatively short (for efficiency), but also
; long enough to be self-descriptive and avoid name conflicts with any other
; apps. (The other option was 'ST' which didn't seem self-descriptive enough.)
;
; The following are the TI-OS routines relavant to ListObj variables:
;
;   - GetLToOP1(): Get list element to OP1
;       - Input:
;           - HL = element index
;           - DE = pointer to list, output of FindSym()
;   - PutToL(): Store OP1 in list
;       - Input:
;           - HL = element index
;           - DE = pointer to list, output of FindSym()
;   - CreateRList(): Creat a real list variable in RAM
;       - Input:
;           - HL = number of elements in the list
;           - OP1 = name of list to create
;       - Output:
;           - HL = pointer to symbol table entry
;           - DE = pointer to RAM
;   - FindSym(): Search symbol table for variable in OP1
;       - Input:
;           - OP1: variable name
;       - Output:
;           - HL = pointer to start of symbol table entry
;           - DE = pointer to start of variable data in RAM. For List variables,
;             points to the a u16 size of list.
;           - B = 0 (variable located in RAM)
;   - MemChk(): Determine if there is enough memory before creating a variable
;   - DelVar(), DelVarArc(), DelVarNoArc(): delete variables
;
; Getting the size (dimension) of existing list. From the SDK docs: "After
; creating a list with 23 elements, the first two bytes of the data structure
; are set to the number of elements, 17h 00h, the number of elements in hex,
; with the LSB followed by the MSB."
;
;       LD HL,L1Name
;       B_CALL Mov9ToOP1; OP1 = list L1 name
;       B_CALL FindSym ; look up list variable in OP1
;       JR C, NotFound ; jump if it is not created
;       EX DE,HL ; HL = pointer to data structure
;       LD E,(HL) ; get the LSB of the number elements
;       INC HL ; move to MSB
;       LD D,(HL) ; DE = number elements in L1
;   L1Name:
;       DBListObj, tVarLst, tL1, 0
;
;
; 3) AppVar Variables
;
; Here are some notes for my future self:
;
;   - ChkFindSym() instead of FindSym() must be used for appVars.
;   - ChkFindSym() returns a data pointer. The first 2 bytes is the appVarSize
;   field.
;   - The appVarSize does *not* include the 2 bytes consumed by the appVarSize
;   field itself, see rpnObjectIndexToOffset().
;   - CreateAppVar() does *not* check for duplicate variable names.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; General RpnObject routines.
;
; Each RpnObject is large enough to hold a Real or Complex number. If the size
; of RpnObject changes, then rpnObjectIndexToOffset() must be updated.
;
; struct RpnFloat { // sizeof(RpnFloat)==9
;   uint8_t float_type;
;   uint8_t data[8];
; };
;
; struct RpnObject { // sizeof(RpnObject)==19
;   uint8_t object_type;
;   union {
;       RpnFloat floats[2];
;       uint8_t data[18];
;   };
; };
;
; An array of RpnObjects is stored in appVars (e.g. RPN83STK, RPN83REG,
; RPN83STA). The data section of the appVar can be described by the following C
; structure:
;
; struct RpnObjectList {
;   uint16_t size ; // maintained by the TIOS (*not* including 'size' field)
;   uint16_t crc16; // CRC16 checksum of all following bytes
;   uint16_t schemaVersion; // schema version in v0.11 (appId in < v0.11)
;   uint16_t appId; // appId
;   RpnObject objects[size/sizeof(RpnObject)];
; };
;
; The `schemaVersion` field was inadvertantly left out prior to v0.11. For
; v0.11, it is deliberately placed into the same slot as the `appId` field in
; the previous version, to allow the app to detect a schema change in both
; directions, during an upgrade from (v0.1-v0.10) to v0.11, or during a
; downgrade from v0.11 to (v0.1-v0.10):
;
; 1) (v0.1-v0.10) to v0.11: The `schemaVersion` field will change from
; `rpn83pAppId` to `rpnObjectListSchemaVersion`.
; 2) v0.11 to (v0.1-v0.10): The `appId` field will change from
; `rpnObjectListSchemaVersion` to `rpn83pAppId`.
;
; The only time this will fail is if the user upgrades/downgrades between a
; schema version of 1 (rpnObjectListSchemaVersion) and $1E69 (rpn83pAppId),
; which is likely to never happen.
;-----------------------------------------------------------------------------

; Description: Initialize the AppVar to contain an array of RpnObjects.
; Input:
;   - HL:(char*)=appVarName
;   - C:u8=defaultLen if appVar needs to be created, [0,99]
; Destroys: A, BC, DE, HL, OP1
initRpnObjectList:
    push bc ; stack=[len]
    call move9ToOp1 ; OP1=varName
    bcall(_ChkFindSym) ; DE=dataPointer; CF=1 if not found
    ld a, b ; A=romPage (0 if RAM)
    pop bc ; stack=[]; C=len
    jr c, initRpnObjectListCreate
    ; If archived, deleted it. TODO: Maybe try to unachive it?
    or a ; if romPage==0: ZF=1
    jr nz, initRpnObjectListDelete
    ; Exists in RAM, so validate.
    call validateRpnObjectList ; if valid: ZF=1 ; preserves BC
    ret z
initRpnObjectListDelete:
    ; Delete the existing (non-validating) appVar. We call ChkFindSym again to
    ; re-populate the various registers needed by DelVarArc, but but this code
    ; path should rarely happen, so I think it's ok to call it twice.
    push bc ; stack=[len]
    bcall(_ChkFindSym) ; DE=dataPointer; CF=1 if not found
    bcall(_DelVarArc)
    pop bc ; stack=[]; C=len
initRpnObjectListCreate:
    ; We are here if the appVar does not exist. So create.
    ; OP1=appVarName; C=len
    push bc ; stack=[len]
    call rpnObjectIndexToOffset ; HL=expectedSize
    bcall(_CreateAppVar) ; DE=dataPointer
    pop bc ; stack=[]; C=len
initRpnObjectListHeader:
    push bc ; stack=[len]
    push de ; stack=[len,dataPointer]
    inc de
    inc de ; skip past the appVarSize field
    inc de
    inc de ; skip past the CRC field
    ex de, hl ; HL=dataPointer+4
    ; insert schemaVersion
    ld bc, rpnObjectListSchemaVersion
    ld (hl), c
    inc hl
    ld (hl), b
    inc hl ; HL=dataPointer+6
    ; insert appId
    ld bc, rpn83pAppId
    ld (hl), c
    inc hl
    ld (hl), b
    inc hl ; HL=dataPointer+8
    ; clear all the elements from [begin,len)
    pop de ; stack=[len]; DE=dataPointer
    pop bc ; stack=[]; C=len
    ld b, 0 ; B=begin=0
    call clearRpnObjectList
    ret

; Description: Clear the rpnObjectList elements over the interval
; [begin,begin+len). No array boundary checks are performed.
;
; Input:
;   - B:u8=begin
;   - C:u8=len
;   - DE:(u8*)=dataPointer
; Destroys: A, DE, HL, OP1
clearRpnObjectList:
    push de ; stack=[dataPointer]
    push bc ; stack=[dataPointer,begin/len]
    call op1Set0 ; OP1=0.0
    ; calc the begin offset into appVar
    pop bc ; stack=[dataPointer]; B=begin; C=len
    ld a, c ; A=len
    ld c, b ; C=begin
    call rpnObjectIndexToOffset ; HL=offset; preserves A,BC,DE
    ld c, a ; C=len
    pop de ; stack=[]; DE=dataPointer
    inc de
    inc de ; DE=dataPointer+2; skip past appVarSize
    add hl, de ; HL=beginAddress=dataPointer+offset+2
    ex de, hl ; DE=beginAddress; HL=dataPointer
clearRpnObjectListLoop:
    ; Copy OP1 into AppVar.
    ld a, rpnObjectTypeReal
    ld (de), a ; rpnObjectType
    inc de
    push bc ; stack=[len]
    call move9FromOp1 ; updates DE to the next element
    ; Set the trailing bytes of the slot to binary 0.
    xor a
    ld b, rpnObjectSizeOf-rpnRealSizeOf-1 ; 9 bytes
clearRpnObjectListLoopTrailing:
    ld (de), a
    inc de
    djnz clearRpnObjectListLoopTrailing
    ;
    pop bc ; stack=[]; C=len
    dec c
    jr nz, clearRpnObjectListLoop
    ret

; Description: Validate the `crc16` checksum, the `schemaVersion`, and the
; `appId` fields of the rpnObjectList appVar. The `size` field is not validated
; because the appVar could have been changed to a different size.
;
; Input:
;   - DE:(u8*)=dataPointer to appVar contents
;   - (appVar):(struct RpnObjectList*)
; Output:
;   - ZF=1 if valid, 0 if not valid
; Destroys: DE, HL
; Preserves: BC, OP1
validateRpnObjectList:
    push bc ; stack=[BC]
    ex de, hl ; HL=dataPointer
    ; Extract appVarSize
    ld c, (hl)
    inc hl
    ld b, (hl)
    inc hl ; BC=appVarSize
    ; Extract CRC
    ld e, (hl)
    inc hl
    ld d, (hl) ; DE=CRC16
    inc hl
    dec bc
    dec bc ; BC=appVarSize-2; skip the CRC field itself
    ; Compare CRC
    push hl ; stack=[BC, dataPointer]
    push de ; stack=[BC, dataPointer, expectedCRC]
    bcall(_Crc16ccitt) ; DE=CRC16(HL)
    pop hl ; stack=[BC, dataPointer]; HL=expectecCRC
    or a ; CF=0
    sbc hl, de ; if CRC matches: ZF=1
    pop hl ; stack=[BC]; HL=dataPointer
    jr nz, validateRpnObjectListEnd
    ; Verify schemaVersion.
    ld e, (hl)
    inc hl
    ld d, (hl)
    inc hl ; DE=schemaVersion
    ex de, hl ; DE=dataPointer; HL=schemaVersion
    ld bc, rpnObjectListSchemaVersion
    or a ; CF=0
    sbc hl, bc ; if schemaVersion matches: ZF=1
    ex de, hl ; HL=dataPointer
    jr nz, validateRpnObjectListEnd
    ; Verify appId.
    ld e, (hl)
    inc hl
    ld d, (hl)
    inc hl ; DE=appId
    ex de, hl ; DE=dataPointer; HL=appId
    ld bc, rpn83pAppId
    or a ; CF=0
    sbc hl, bc ; if appId matches: ZF=1
    ex de, hl ; HL=dataPointer
validateRpnObjectListEnd:
    pop bc ; stack=[]; BC=restored
    ret

; Description: Close the rpnObjectList by updating the CRC16 checksum. This is
; intended to be called just before the application exits.
; Input:
;   - HL:(char*)=appVarName
; Destroys: A, BC, DE, HL, OP1
closeRpnObjectList:
    call move9ToOp1 ; OP1=varName
    bcall(_ChkFindSym) ; DE=dataPointer; CF=1 if not found
    ret c ; nothing we can do if the appVar isn't found
    ; Update the CRC checksum.
    ex de, hl ; HL=dataPointer
    ld c, (hl)
    inc hl
    ld b, (hl) ; BC=size(appVar)
    inc hl
    ;
    push hl ; stack=[crc16Pointer]
    inc hl
    inc hl ; HL=dataPointer+4
    dec bc
    dec bc ; BC=size(appVar)-2
    bcall(_Crc16ccitt) ; DE=CRC16(HL)
    ;
    pop hl ; stack=[]; HL=crc16Pointer
    ld (hl), e
    inc hl
    ld (hl), d
    ret

; Description: Return the length (number of elements) in the
; rpnObjectList identified by the appVarName in HL.
; Input:
;   - HL:(char*)=appVarName
; Output:
;   - A:u8=length of list
;   - DE:(u8*)=dataPointer
; Throws:
;   - Err:Invalid if length calculation has a remainder
;   - Err:Undefined if appVarName does not exist
; Destroys: A, BC, DE, HL, OP1
lenRpnObjectList:
    call move9ToOp1 ; OP1=varName
    bcall(_ChkFindSym) ; DE=dataPointer; CF=1 if not found
    jr c, lenRpnObjectNotFound
calcLenRpnObjectList:
    ex de, hl ; HL=dataPointer
    ld e, (hl)
    inc hl
    ld d, (hl) ; DE=appVarSize
    dec hl ; HL=dataPointer
    ; remove the crc16, schemaVersion, and appId fields from appVarSize
    ex de, hl ; HL=appVarSize; DE=dataPointer
    dec hl
    dec hl
    dec hl
    dec hl
    dec hl
    dec hl ; HL=appVarSize-6=rpnObjectListSize
    ; divide rpnObjectListSize/sizeof(RpnObject)
    ld c, rpnObjectSizeOf
    call divHLByC ; HL=quotient; A=remainder; preserves DE
    or a ; validate no remainder
    jr nz, lenRpnObjectListInvalid
    ld a, l
    ret
lenRpnObjectListInvalid:
    ; sizeof(var)/sizeof(RpnObject) has a non-zero remainder
    bcall(_ErrInvalid) ; should never happen
lenRpnObjectNotFound:
    ; nothing we can do if the appVar isn't found
    bcall(_ErrUndefined) ; should never happen

; Description: Resize the rpnObjectList identified by appVarName in HL.
; Input:
;   - HL:(char*)=appVarName
;   - A:u8=newLen, expected to be [0,99] but no validation performed
; Output:
;   - appVar resized
;   - ZF=1 if newLen==oldLen
;   - CF=0 if newLen>oldLen
;   - CF=1 if newLen<oldLen
; Destroys: A, BC, DE, HL, OP1
; Throws:
;   - Err:Memory if out of memory
;   - Err:Undefined if appVarName does not exist
resizeRpnObjectList:
    push af ; stack=[newLen]
    call move9ToOp1 ; OP1=varName; preserves A
    bcall(_ChkFindSym) ; DE=dataPointer; CF=1 if not found
    jr c, resizeRpnObjectListNotFound
    push de ; stack=[newLen,dataPointer]
    call calcLenRpnObjectList
    ld b, a ; B=oldLen
    pop de ; stack=[newLen]; DE=dataPointer
    pop af ; stack=[]; A=newLen
    sub b ; A=diff=newLen-oldLen
    ret z ; ZF=1 if newLen==oldLen
    jr c, shrinkRpnObjectList ; CF=1 if newLen<oldLen
expandRpnObjectList:
    ld c, a ; C=diffLen
    push bc ; stack=[begin/diffLen]
    ld l, a
    ld h, 0 ; HL=expandLen
    ; calculate expandSize
    push de ; stack=[begin/diffLen,dataPointer]
    call rpnObjectLenToSize ; HL=expandSize=19*expandLen
    push hl
    bcall(_EnoughMem) ; CF=1 if insufficient
    jr c, resizeRpnObjectListOutOfMem
    pop hl
    pop de ; stack=[begin/diffLen]; DE=dataPointer
    ; move pointer to the insertionAddress
    push de ; stack=[begin/diffLen,dataPointer]
    ex de, hl ; HL=dataPointer; DE=expandSize
    ld c, (hl)
    inc hl
    ld b, (hl) ; BC=appVarSize
    inc hl ; HL=dataPointer+2
    add hl, bc ; HL=insertionAddress=dataPointer+2+appVarSize
    ; perform insertion
    ex de, hl ; DE=insertionAddress; HL=expandSize
    push hl ; stack=[begin/diffLen,dataPointer,expandSize]
    bcall(_InsertMem) ; preserves DE
    pop de ; stack=[begin/diffLen,dataPointer]; DE=expandSize
    ; update appVarSize
    pop hl ; stack=[begin/diffLen]; HL=dataPointer
    ld c, (hl)
    inc hl
    ld b, (hl) ; BC=appVarSize
    dec hl ; HL=dataPointer
    ex de, hl ; DE=dataPointer; HL=expandSize
    add hl, bc ; HL=newAppVarSize=expandSize+appVarSize
    ex de, hl ; DE=newAppVarSize; HL=dataPointer
    ld (hl), e
    inc hl
    ld (hl), d ; appVarSize=newAppVarSize
    dec hl ; HL=dataPointer
    ; clear the expanded slots
    ex de, hl ; DE=dataPointer
    pop bc ; stack=[]; B=begin; C=diffLen
    call clearRpnObjectList
    or 1 ; ZF=0; CF=0
    ret
shrinkRpnObjectList:
    neg
    ld l, a
    ld h, 0 ; HL=shrinkLen
    ; calculate shrinkSize
    push de ; stack=[dataPointer]
    call rpnObjectLenToSize ; HL=shrinkSize=19*shrinkLen
    pop de ; stack=[]; DE=dataPointer
    push de ; stack=[dataPointer]
    ; move pointer to the deletionAddress
    ex de, hl ; HL=dataPointer; DE=shrinkSize
    ld c, (hl)
    inc hl
    ld b, (hl) ; BC=appVarSize
    inc hl ; HL=dataPointer+2
    add hl, bc ; HL=dataPointer+2+appVarSize
    or a ; CF=0
    sbc hl, de ; HL=deletionAddress=dataPointer+2+appVarSize-shrinkSize
    ; perform deletion
    push de ; stack=[dataPointer,shrinkSize]
    bcall(_DelMem)
    pop de ; stack=[dataPointer]; DE=shrinkSize
    ; update appVarSize
    pop hl ; stack=[]; HL=dataPointer
    ld c, (hl)
    inc hl
    ld b, (hl) ; BC=appVarSize
    dec hl ; HL=dataPointer
    push hl ; stack=[dataPointer]
    ld l, c
    ld h, b ; HL=appVarSize
    or a ; CF=0
    sbc hl, de ; HL=newAppVarSize=appVarSize-shrinkSize
    ld c, l
    ld b, h ; BC=newAppVarSize
    pop hl ; stack=[]; HL=dataPointer
    ld (hl), c
    inc hl
    ld (hl), b
    or a ; ZF=0
    scf ; CF=1
    ret
resizeRpnObjectListNotFound:
    ; nothing we can do if the appVar isn't found
    bcall(_ErrUndefined) ; should never happen
resizeRpnObjectListOutOfMem:
    bcall(_ErrMemory) ; could happen

;-----------------------------------------------------------------------------

; Description: Convert rpnObject index to the array element pointer, including
; 2 bytes for the appVarSize (managed by the OS), 2 bytes for the CRC16
; checksum, and 2 bytes for the appId.
; Input:
;   - C:u8=index
;   - DE:(u8*)=appDataPointer to the begining of the appVar which is the 2-byte
;   appVarSize field provided by the OS
; Output:
;   - HL:(u8*)=elementPointer
;   - CF=1 if within bounds, otherwise 0
; Preserves: A, BC, DE
rpnObjectIndexToElementPointer:
    call rpnObjectIndexToOffset ; HL=dataOffset
    push bc ; stack=[BC]
    push de ; stack=[BC,DE]
    ; check pointer out of bounds
    ex de, hl ; HL=appDataPointer; DE=dataOffset
    ld c, (hl)
    inc hl
    ld b, (hl) ; BC=appVarSize
    inc hl
    ; calculate pointer to item at index
    add hl, de ; HL=elementPointer=dataOffset+appDataPointer+2
    ex de, hl ; HL=dataOffset; DE=elementPointer
    ; check array bounds
    or a ; CF=0
    sbc hl, bc ; if dataOffset < appVarSize; CF=1
    ; restore registers
    ex de, hl ; HL=elementPointer
    pop de ; stack=[BC]
    pop bc ; stack=[]
    ret

; Description: Convert rpnObject index to the offset into the appVar data
; segment. If 'index' is the 'len', then this is the value stored by the TI-OS
; in the appVarSize field at the beginning of the data segment:
;
;   appVarSize = len*rpnObjectSizeOf
;                + 2 (crc16) + 2 (schemaVersion) + 2 (appId)
;              = len*rpnObjectSizeOf + 6
;
; To get to the end of the appVar data segment, add this offset to the
; dataPointer. But don't forget to add another 2 byte to skip past the 2-byte
; appVarSize field at the location pointed by dataPointer.
;
; Input: C:u8=index or len
; Output: HL:u16=offset or size
; Preserves: A, BC, DE
rpnObjectIndexToOffset:
    push de
    ld l, c
    ld h, 0 ; HL=len
    call rpnObjectLenToSize ; HL=19*HL
    ld de, 6
    add hl, de ; HL=sum=19*len+6
    pop de
    ret

; Description: Convert len of RpnObject to the byte size of those RpnObjects.
; This *must* be updated if sizeof(RpnObject) changes.
;
; Input: HL:u16=len
; Output: HL:u16=size=len*sizeof(RpnObject)=len*19
; Destroys: DE
rpnObjectLenToSize:
    ld e, l
    ld d, h ; DE=len
    add hl, hl ; HL=sum=2*len
    ex de, hl ; DE=2*len; HL=sum=len
    add hl, de ; DE=2*len; HL=sum=3*len
    ex de, hl ; DE=sum=3*len; HL=2*len
    add hl, hl
    add hl, hl
    add hl, hl ; DE=sum=3*len; HL=16*len
    add hl, de ; HL=sum=19*len
    ret

;-----------------------------------------------------------------------------

; Description: Store the OP1/OP2 rpnObject to the given AppVar at index C.
; Input:
;   - OP1,OP2:RpnObject
;   - C:u8=index
;   - HL:(char*)=varName
; Output:
;   - none
; Throws:
;   - ErrDimension if index out of bounds
;   - ErrUndefined if appVar not found
; Destroys: all
stoRpnObject:
    call getOp1RpnObjectType ; A=rpnObjectType
    ld b, a ; B=rpnObjectType
    push bc ; stack=[index/objectType]
    ; save OP1/OP2 to FPS
    push hl ; stack=[index/objectType, varName]
    bcall(_PushRpnObject1) ; FPS=[OP1/OP2]
    pop hl ; stack=[index, objectType]; HL=varName
    ; find varName
    call move9ToOp1 ; OP1=varName
    bcall(_ChkFindSym) ; DE=dataPointer; CF=1 if not found
    jr c, rpnObjectUndefined ; Not found, this should never happen.
    ; find elementPointer of index
    pop bc ; stack=[]; B=objectType; C=index
    call rpnObjectIndexToElementPointer ; HL=elementPointer
    jr nc, rpnObjectOutOfBounds
    ; retrieve OP1/OP2 from FPS
    push hl ; stack=[elementPointer]
    push bc
    bcall(_PopRpnObject1) ; FPS=[]; OP1/OP2
    pop bc
    pop hl ; stack=[]; HL=elementPointer
    ; copy from OP1/OP2 into AppVar element
    ld (hl), b ; (hl)=objectType
    inc hl
    ld a, b
    ex de, hl ; DE=elementPointer+1
    ld hl, OP1
    ; copy first 9 bytes
    ld bc, rpnRealSizeOf
    ldir
    ; return early if Real
    cp rpnObjectTypeReal
    ret z
    ; copy next 9 bytes for everything else
    inc hl
    inc hl ; skip 2 bytes, OPx registers are 11 bytes, not 9 bytes
    ld bc, rpnRealSizeOf
    ldir
    ret

rpnObjectOutOfBounds:
    bcall(_ErrDimension)
rpnObjectUndefined:
    bcall(_ErrUndefined)

; Description: Return the RPN object in OP1,OP2
; Input:
;   - C:u8=index
;   - HL:(char*)=appVarName e.g. "RPN83STK", "RPN83REG"
; Output:
;   - A:u8=rpnObjectType
;   - OP1/OP2: float or complex number
; Throws:
;   - ErrDimension if index out of bounds
;   - ErrUndefined if appVar not found
; Destroys: all, OP1
rclRpnObject:
    ; find varName
    push bc ; stack=[index]
    call move9ToOp1 ; OP1=varName
    bcall(_ChkFindSym) ; DE=dataPointer; CF=1 if not found
    pop bc ; C=[index]
    jr c, rpnObjectUndefined
    ; find elementPointer of index
    call rpnObjectIndexToElementPointer ; HL=elementPointer
    jr nc, rpnObjectOutOfBounds
    ; copy from AppVar to OP1/OP2
    ld de, OP1
    ld a, (hl) ; A=objectType
    inc hl
    and $1f
    ; copy first 9 bytes
    ld bc, rpnRealSizeOf
    ldir
    ; return early if Real
    cp rpnObjectTypeReal
    ret z
    ; copy next 9 bytes for everything else
    inc de
    inc de ; OPx registers are 11 bytes, not 9 bytes
    ld bc, rpnRealSizeOf
    ldir
    ret
