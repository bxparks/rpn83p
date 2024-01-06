;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; RPN stack registers and storage registers are implemented using TI-OS list
; variables. Stack variables are stored in a list named 'STK' and storage
; registers are stored in a list named 'REGS' (which is similar to the 'REGS'
; variable used on the HP-42S calculator).
;
; Early versions of RPN83P mapped each stack register to a single-letter real
; variables in the TI-OS, in other words, X, Y, Z, T, R. They were convenient
; because the TI-OS seemed to provide a number of subroutines (e.g. StoX, RclX,
; etc), which makde it relatively easy access those single-letter variables.
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
;    LD HL,L1Name
;    B_CALL Mov9ToOP1; OP1 = list L1 name
;    B_CALL FindSym ; look up list variable in OP1
;    JR C, NotFound ; jump if it is not created
;    EX DE,HL ; HL = pointer to data structure
;    LD E,(HL) ; get the LSB of the number elements
;    INC HL ; move to MSB
;    LD D,(HL) ; DE = number elements in L1
;L1Name:
;    DBListObj, tVarLst, tL1, 0
;
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Each RpnObject is large enough to hold a Real or Complex number. If the size
; of RpnObject changes, then rpnObjectIndexToSize() must be updated.
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
; // This is the data that is serialized into the AppVar. The first 2 bytes of
; the AppVar data section is reserved and filled in by the OS.
; struct RpnObjectList {
;   uint16_t crc16; // CRC16 checksum
;   uint16_t appId; // appId
;   RpnObject objects[size/sizeof(RpnObject)];
; };
;-----------------------------------------------------------------------------

; Description: Initialize the AppVar to contain an array of RpnObjects.
; Input:
;   - HL: name of list to create
;   - B: len of list, [0,99]
; Destroys: A, BC, DE, HL, OP1
initRpnObjectList:
    push bc ; stack=[len]
    call move9ToOp1 ; OP1=varName
    bcall(_ChkFindSym) ; DE=dataPointer; CF=1 if not found
    ld a, b ; A=romPage (0 if RAM)
    pop bc ; stack=[]; B=len
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
    pop bc ; stack=[]; B=len
initRpnObjectListCreate:
    ; We are here if the appVar does not exist. So create.
    ; OP1=appVarName; B=len
    push bc ; stack=[len]
    call rpnObjectIndexToSize ; HL=expectedSize
    bcall(_CreateAppVar) ; DE=dataPointer
    pop bc ; stack=[]; B=len
    ; [[fallthrough]]

; Description: Clear the given data segment in the appVar.
; Input:
;   - B: len
;   - DE: data pointer
; Destroys;: all, OP1
initRpnObjectListClear:
    push bc ; stack=[len]
    push de ; stack=[len, dataPointer]
    call op1Set0 ; OP1=0.0
    pop de ; stack=[len]; DE=dataPointer
    inc de
    inc de ; skip past the dataSize field
    inc de
    inc de ; skip past the CRC field
    ; insert appId
    ld bc, rpn83pAppId
    ex de, hl
    ld (hl), c
    inc hl
    ld (hl), b
    inc hl
    ex de, hl ; DE=dataPointer
    ;
    pop bc ; stack=[]; B=len
initRpnObjectListLoop:
    ; Copy OP1 into AppVar.
    ld a, rpnObjectTypeReal
    ld (de), a ; rpnObjectType
    inc de
    push bc ; stack=[len]
    call move9FromOP1
    ; Set the trailing bytes of the slot to binary 0.
    xor a
    ld b, rpnObjectSizeOf-rpnRealSizeOf-1 ; 9 bytes
initRpnObjectListLoopTrailing:
    ld (de), a
    inc de
    djnz initRpnObjectListLoopTrailing
    pop bc ; stack=[]; B=len
    djnz initRpnObjectListLoop
    ret

; Description: Validate the size and CRC16 checksum of the rpnObjectList data
; array.
; Input:
;   - B=expectedLen
;   - DE=dataPointer to appVar contents
;   - (appVar): 2 bytes (len), 2 bytes (crc16), 2 bytes (appId), data[]
; Output:
;   - ZF=1 if valid, 0 if not valid
; Destroys: DE, HL
; Preserves: BC (expectedLen), OP1
validateRpnObjectList:
    push bc ; stack=[expectedLen]
    ; Validate expected size of data segment
    call rpnObjectIndexToSize ; HL=expectedSize
    ex de, hl ; HL=dataPointer; DE=expectedSize
    ld c, (hl)
    inc hl
    ld b, (hl) ; BC=size(appVar)
    inc hl
    ; Compare expected size
    push hl ; stack=[expectedLen, dataPointer]
    ld l, c
    ld h, b
    or a ; CF=0
    sbc hl, de ; if size(appVar)==expectedSize: ZF=1
    pop hl ; stack=[expectedLen]; HL=dataPointer
    jr nz, validateRpnObjectListEnd
    ; Extract CRC
    ld e, (hl)
    inc hl
    ld d, (hl) ; DE=CRC16
    inc hl
    dec bc
    dec bc ; BC=size(appVar)-2; skip the CRC field itself
    ; Compare CRC
    push hl ; stack=[expectedLen, dataPointer]
    push de ; stack=[expectedLen, dataPointer, expectedCRC]
    bcall(_Crc16ccitt) ; DE=CRC16(HL)
    pop hl ; stack=[expectedLen, dataPointer]; HL=expectecCRC
    or a ; CF=0
    sbc hl, de ; if CRC matches: ZF=1
    pop hl ; stack=[expectedLen]; HL=dataPointer
    jr nz, validateRpnObjectListEnd
    ; Verify appId.
    ld e, (hl)
    inc hl
    ld d, (hl)
    inc hl ; DE=appId
    ld hl, rpn83pAppId
    or a ; CF=0
    sbc hl, de ; if appId matches: ZF=1
validateRpnObjectListEnd:
    pop bc ; stack=[] BC=expectedLen
    ret

; Description: Close the rpnObjectList by updating the CRC16 checksum. This is
; intended to be called just before the application exits.
; Input:
;   - HL: name of rpnObjectList to close
; Destroys: A, BC, DE, HL
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

;-----------------------------------------------------------------------------

; Description: Convert rpnObject index to the object pointer, including 2 bytes
; for the CRC16 checksum, and the 2-byte size field.
; Input:
;   - B=index
;   - DE=dataPointer to the begining of the appVar which is the 2-byte size
;   field provided by the OS
; Output: HL=objectPointer
; Preserves: A, BC, DE
rpnObjectIndexToPointer:
    call rpnObjectIndexToSize ; HL=dataSize
    add hl, de ; HL=dataSize+dataPointer
    inc hl
    inc hl ; skip past the size field
    ret

; Description: Convert rpnObject len or index to the data size of the appVas.
; This is the value stored by the TI-OS. Size = len*rpnObjectSizeOf + 2 (crc16)
; + 2 (appId).
; Input: B: len or index
; Output: HL: byteSize
; Preserves: A, BC, DE
rpnObjectIndexToSize:
    push de
    ld l, b
    ld h, 0
    ld e, l
    ld d, h ; DE=len
    add hl, hl ; HL=sum=2*len
    ex de, hl ; DE=2*len; HL=sum=len
    add hl, de ; DE=2*len; HL=sum=3*len
    ex de, hl ; DE=sum=3*len; HL=2*len
    add hl, hl
    add hl, hl
    add hl, hl ; De=sum=3*len; HL=16*len
    add hl, de ; HL=sum=19*len
    ld de, 4
    add hl, de ; HL=sum=19*len+4
    pop de
    ret

;-----------------------------------------------------------------------------

; Description: Store the OP1/OP2/OP3 rpnObject to the given AppVar.
; Input:
;   - C: objectType
;   - OP1, OP2: real or complex
;   - B: index
;   - HL: name of appVar
; Output:
;   - none
; Destroys: all
stoRpnObject:
    push bc ; stack=[index, objectType]
    push hl ; stack=[index, objectType, varName]
    bcall(_PushOP1) ; FPS=[OP1/OP2]
    pop hl ; stack=[index, objectType]; HL=varName
    call move9ToOp1 ; OP1=varName
    bcall(_ChkFindSym) ; DE=dataPointer; CF=1 if not found
    jr nc, stoRpnObjectContinue
    ; Not found, this should never happen.
    bcall(_PopOP1) ; FPS=[]; OP1/OP2
    pop bc ; stack=[]; C=objectType; B=index
    ret
stoRpnObjectContinue:
    push de ; stack=[index, objectType, dataPointer]
    bcall(_PopOP1) ; FPS=[]; OP1/OP2
    pop de ; stack=[index, objectType]; DE=dataPointer
    pop bc ; stack=[]; C=objectType; B=index
    ;
    call rpnObjectIndexToPointer ; HL=objectPointer
    ld (hl), c ; (hl)=objectType
    inc hl
    ld a, c
    ex de, hl ; DE=objectPointer+1
    cp rpnObjectTypeComplex
    jr z, stoRpnObjectCopyComplex
    ; copy real
    ld hl, OP1
    ld bc, rpnRealSizeOf
    ldir
    ret
stoRpnObjectCopyComplex:
    ; copy complex
    ld hl, OP1
    ld bc, rpnRealSizeOf
    ldir
    inc hl
    inc hl ; OPx registers are 11 bytes, not 9 bytes
    ld bc, rpnRealSizeOf
    ldir
    ret

; Description: Return the RPN object in OP1,OP2
; Input:
;   - B: index
;   - HL: name of appVar e.g. "RPN83STK", "RPN83REG"
; Output:
;   - A: rpnObjectType
;   - OP1/OP2: float or complex number
; Destroys: all
rclRpnObject:
    push bc
    call move9ToOp1 ; OP1=varName
    bcall(_ChkFindSym) ; DE=dataPointer; CF=1 if not found
    pop bc
    ret c ; TODO: throw an exception?
    call rpnObjectIndexToPointer ; HL=objectPointer
    ; figure out how much to copy
    ld de, OP1
    ld a, (hl) ; A=objectType
    inc hl
    cp rpnObjectTypeComplex
    jr z, rclRpnObjectCopyComplex
    ; copy real
    ld bc, rpnRealSizeOf
    ldir
    ret
rclRpnObjectCopyComplex:
    ; copy complex
    ld bc, rpnRealSizeOf
    ldir
    inc de
    inc de ; OPx registers are 11 bytes, not 9 bytes
    ld bc, rpnRealSizeOf
    ldir
    ret

;-----------------------------------------------------------------------------
; RPN Stack
;-----------------------------------------------------------------------------

; RPN stack using an ObjectList which has the following structure:
; X, Y, Z, T, LastX.
stackSize equ 5
stackXIndex equ 0 ; X
stackYIndex equ 1 ; Y
stackZIndex equ 2 ; Z
stackTIndex equ 3 ; T
stackLIndex equ 4 ; LastX

stackName:
    .db AppVarObj, "RPN83STK" ; max 8 char, NUL terminated if < 8

;-----------------------------------------------------------------------------

; Description: Initialize the RPN stack using the appVar 'RPN83STK'.
; Output:
;   - STK created and cleared if it doesn't exist
;   - stack lift enabled
; Destroys: all
initStack:
    set rpnFlagsLiftEnabled, (iy + rpnFlags)
    ld hl, stackName
    ld b, stackSize
    jp initRpnObjectList

; Description: Initialize LastX with the contents of 'ANS' variable from TI-OS
; if ANS is real or complex. Otherwise, do nothing.
; Input: ANS
; Output: LastX=ANS
initLastX:
    bcall(_RclAns)
    bcall(_CkOP1Real) ; if OP1 real: ZF=1
    jp z, stoL
    bcall(_CkOP1Cplx) ; if OP complex: ZF=1
    jp z, stoL
    ret

; Description: Clear the RPN stack.
; Input: none
; Output: stack registers all set to 0.0
; Destroys: all
clearStack:
    set dirtyFlagsStack, (iy + dirtyFlags) ; force redraw
    set rpnFlagsLiftEnabled, (iy + rpnFlags) ; TODO: I think this can be removed
    ld hl, stackName
    call move9ToOp1
    bcall(_ChkFindSym) ; DE=dataPointer; CF=1 if not found
    ret c
    ld b, stackSize
    jp initRpnObjectListClear

; Description: Should be called just before existing the app.
closeStack:
    ld hl, stackName
    jp closeRpnObjectList

;-----------------------------------------------------------------------------
; Stack registers to and from OP1/OP2
;-----------------------------------------------------------------------------

; Description: Store OP1/OP2 to STK[nn], setting dirty flag.
; Input:
;   - A: stack register index, 0-based
;   - OP1/OP2: float value
; Output:
;   - STK[nn] = OP1/OP2
; Destroys: all
; Preserves: OP1, OP2
stoStackNN:
    set dirtyFlagsStack, (iy + dirtyFlags)
    ld hl, stackName
    ld b, a ; B=index
    call getOp1RpnObjectType ; C=rpnObjectType
    jp stoRpnObject

; Description: Copy STK[nn] to OP1/OP2.
; Input:
;   - A: stack register index, 0-based
;   - 'STK' app variable
; Output:
;   - OP1/OP2: float value
;   - A: rpnObjectType
; Destroys: all
rclStackNN:
    ld hl, stackName
    ld b, a ; B=index
    jp rclRpnObject ; OP1/OP2=STK[A]

;-----------------------------------------------------------------------------

; Description: Store OP1/OP2 to X.
; Destroys: all
stoX:
    ld a, stackXIndex
    jr stoStackNN

; Description: Recall X to OP1/OP2.
; Output: A=objectType
; Destroys: all
rclX:
    ld a, stackXIndex
    jr rclStackNN

;-----------------------------------------------------------------------------

; Description: Store OP1/OP2 to Y.
; Destroys: all
stoY:
    ld a, stackYIndex
    jr stoStackNN

; Description: Recall Y to OP1/OP2.
; Output: A=objectType
; Destroys: all
rclY:
    ld a, stackYIndex
    jr rclStackNN

;-----------------------------------------------------------------------------

; Description: Store OP1/OP2 to Z.
; Destroys: all
stoZ:
    ld a, stackZIndex
    jr stoStackNN

; Description: Recall Z to OP1/OP2.
; Output: A=objectType
; Destroys: all
rclZ:
    ld a, stackZIndex
    jr rclStackNN

;-----------------------------------------------------------------------------

; Description: Store OP1/OP2 to T.
; Destroys: all
stoT:
    ld a, stackTIndex
    jr stoStackNN

; Description: Recall T to OP1/OP2.
; Output: A=objectType
; Destroys: all
rclT:
    ld a, stackTIndex
    jr rclStackNN

;-----------------------------------------------------------------------------

; Description: Store OP1/OP2 to L.
; Destroys: all
stoL:
    ld a, stackLIndex
    jr stoStackNN

; Description: Recall L to OP1/OP2.
; Output: A=objectType
; Destroys: all
rclL:
    ld a, stackLIndex
    jr rclStackNN

;-----------------------------------------------------------------------------
; Most routines should use these functions to set the results from OP1 and/or
; OP2 to the RPN stack.
;-----------------------------------------------------------------------------

; Description: Replace X with OP1/OP2, saving previous X to LastX, and
; setting dirty flag. Works for complex numbers.
; Preserves: OP1, OP2
replaceX:
    bcall(_CkValidNum)
    bcall(_PushOP1) ; FPS=[OP1/OP1]
    call rclX
    call stoL
    bcall(_PopOP1) ; FPS=[]; OP1/OP2=OP1/OP2
    call stoX
    ret

; Description: Replace X and Y pair with OP1/OP2, saving previous X to LastX,
; and setting dirty flag. Works for complex numbers.
; Preserves: OP1, OP2
replaceXY:
    bcall(_CkValidNum)
    bcall(_PushOP1) ; FPS=[OP1/OP1]
    call rclX
    call stoL
    call dropStack
    bcall(_PopOP1) ; FPS=[]; OP1/OP1=OP1/OP2
    call stoX
    ret

; Description: Replace X and Y with push of OP1 and OP2 on the stack in that
; order. This causes X=OP2 and Y=OP1, saving the previous X to LastX, and
; setting dirty flag.
; WARNING: Assumes that OP1 and OP2 are real not complex.
; Input: X, Y, OP1, OP2
; Output:
;   - Y=OP1
;   - X=OP2
;   - LastX=X
; Preserves: OP1, OP2
replaceXYWithOP1OP2:
    ; validate OP1 and OP2 before modifying X and Y
    bcall(_CkValidNum)
    bcall(_OP1ExOP2)
    bcall(_CkValidNum)
    bcall(_OP1ExOP2)

    call stoY ; Y = OP1
    bcall(_PushRealO1) ; FPS=[OP1]
    call rclX
    call stoL; LastX = X

    bcall(_OP2ToOP1)
    call stoX ; X = OP2
    bcall(_PopRealO1) ; FPS=[]; OP1=OP1
    ret

; Description: Replace X with OP1, and OP2 pushed onto the stack in that order.
; WARNING: Assumes that OP1 and OP2 are real not complex.
; Input: X, OP1 (Re), OP2 (Im)
; Output:
;   - Y=OP1
;   - X=OP2
;   - LastX=X
; Preserves: OP1, OP2
replaceXWithOP1OP2:
    ; validate OP1 and OP2 before modifying X and Y
    bcall(_CkValidNum)
    bcall(_PushRealO1) ; FPS=[OP1]
    call op2ToOp1
    bcall(_CkValidNum)
    bcall(_PushRealO1) ; FPS=[OP1,OP2]
    call exchangeFPSFPS ; FPS=[OP2,OP1]

    call rclX
    call stoL
    bcall(_PopRealO1) ; FPS=[OP2]; OP1=OP1
    call stoX
    call liftStack
    bcall(_PopRealO1) ; FPS=[]; OP1=OP2
    call stoX
    ret

; Description: Push OP1 to the X register. LastX is not updated because the
; previous X is not consumed, and is availabe as the Y register. Works for
; complex numbers.
; Input: X, OP1/OP2
; Output:
;   - Stack lifted (if the inputBuf was not an empty string)
;   - X=OP1
; Destroys: all
; Preserves: OP1, OP2, LastX
pushX:
    bcall(_CkValidNum)
    call liftStackIfNonEmpty
    call stoX
    ret

; Description: Push OP1 then OP2 onto the stack. LastX is not updated because
; the previous X is not consumed, and is available as the Z register.
; WARNING: Assumes OP1 and OP2 are real not complex.
; Input: X, Y, OP1, OP2
; Output:
;   - Stack lifted (if the inputBuf was not an empty string)
;   - Y=OP1
;   - X=OP2
; Destroys: all
; Preserves: OP1, OP2, LastX
pushXY:
    bcall(_CkValidNum)
    bcall(_OP1ExOP2)
    bcall(_CkValidNum)
    bcall(_OP1ExOP2)
    call liftStackIfNonEmpty
    call stoX
    call liftStack
    bcall(_OP1ExOP2)
    call stoX
    bcall(_OP1ExOP2)
    ret

;-----------------------------------------------------------------------------

; Description: Lift the RPN stack, if inputBuf was not empty when closed.
; Input: none
; Output: T=Z; Z=Y; Y=X; X=X; OP1 preserved
; Destroys: all
; Preserves: OP1, OP2
liftStackIfNonEmpty:
    bit inputBufFlagsClosedEmpty, (iy + inputBufFlags)
    ret nz ; return doing nothing if closed empty
    ; [[fallthrough]]

; Description: Lift the RPN stack, if rpnFlagsLiftEnabled is set.
; Input: rpnFlagsLiftEnabled
; Output: T=Z; Z=Y; Y=X; X=X; OP1 preserved
; Destroys: all
; Preserves: OP1, OP2
liftStackIfEnabled:
    bit rpnFlagsLiftEnabled, (iy + rpnFlags)
    ret z
    ; [[fallthrough]]

; Description: Lift the RPN stack unconditionally, copying X to Y.
; Input: none
; Output: T=Z; Z=Y; Y=X; X=X; OP1 preserved
; Destroys: all
; Preserves: OP1, OP2
; TODO: Make this more efficient by taking advantage of the fact that stack
; registers are contiguous.
liftStack:
    bcall(_PushOP1) ; FPS=[OP1/OP2]
    ; T = Z
    call rclZ
    call stoT
    ; Z = Y
    call rclY
    call stoZ
    ; Y = X
    call rclX
    call stoY
    ; X = X
    bcall(_PopOP1) ; FPS=[]; OP1/OP2=OP1/OP2
    ret

;-----------------------------------------------------------------------------

; Description: Drop the RPN stack, copying T to Z.
; Input: none
; Output: X=Y; Y=Z; Z=T; T=T; OP1 preserved
; Destroys: all
; Preserves: OP1, OP2
; TODO: Make this more efficient by taking advantage of the fact that stack
; registers are contiguous.
dropStack:
    bcall(_PushOP1) ; FPS=[OP1/OP2]
    ; X = Y
    call rclY
    call stoX
    ; Y = Z
    call rclZ
    call stoY
    ; Z = T
    call rclT
    call stoZ
    ; T = T
    bcall(_PopOP1) ; FPS=[]; OP1/OP2=OP1/OP2
    ret

;-----------------------------------------------------------------------------

; Description: Roll the RPN stack *down*.
; Input: none
; Output: X=Y; Y=Z; Z=T; T=X
; Destroys: all, OP1, OP2
; Preserves: none
; TODO: Make this more efficient by taking advantage of the fact that stack
; registers are contiguous.
rollDownStack:
    ; save X in FPS
    call rclX
    bcall(_PushOP1) ; FPS=[OP1/OP2]
    ; X = Y
    call rclY
    call stoX
    ; Y = Z
    call rclZ
    call stoY
    ; Z = T
    call rclT
    call stoZ
    ; T = X
    bcall(_PopOP1) ; FPS=[]; OP1/OP2=OP1/OP2
    call stoT
    ret

;-----------------------------------------------------------------------------

; Description: Roll the RPN stack *up*.
; Input: none
; Output: T=Z; Z=Y; Y=X; X=T
; Destroys: all, OP1, OP2
; Preserves: none
; TODO: Make this more efficient by taking advantage of the fact that stack
; registers are contiguous.
rollUpStack:
    ; save T in FPS
    call rclT
    bcall(_PushOP1) ; FPS=[OP1/OP2]
    ; T = Z
    call rclZ
    call stoT
    ; Z = Y
    call rclY
    call stoZ
    ; Y = X
    call rclX
    call stoY
    ; X = T
    bcall(_PopOP1) ; FPS=[]; OP1/OP2=OP1/OP2
    call stoX
    ret

;-----------------------------------------------------------------------------

; Description: Exchange X<->Y.
; Input: none
; Output: X=Y; Y=X
; Destroys: all, OP1, OP2
exchangeXYStack:
    call rclX
    bcall(_PushOP1)
    call rclY
    call stoX
    bcall(_PopOP1)
    call stoY
    ret

;-----------------------------------------------------------------------------
; Storage registers.
;-----------------------------------------------------------------------------

regsSize equ 25

regsName:
    .db AppVarObj, "RPN83REG" ; max 8 char, NUL terminated if < 8

; Description: Initialize the REGS list variable which is used for user
; registers 00 to 24.
; Input: none
; Output:
;   - REGS created if it doesn't exist
; Destroys: all
initRegs:
    ld hl, regsName
    ld b, regsSize
    jp initRpnObjectList

; Description: Clear all REGS elements.
; Input: none
; Output: REGS elements set to 0.0
; Destroys: all
clearRegs:
    ld hl, regsName
    bcall(_FindSym)
    call move9ToOp1
    bcall(_ChkFindSym) ; DE=dataPointer; CF=1 if not found
    ret c
    ld b, regsSize
    jp initRpnObjectListClear

; Description: Should be called just before existing the app.
closeRegs:
    ld hl, regsName
    jp closeRpnObjectList

;-----------------------------------------------------------------------------

; Description: Store OP1/OP2 into REGS[NN]. Works for complex.
; Input:
;   - A: register index, 0-based
;   - OP1: float value
; Output:
;   - REGS[NN] = OP1
; Destroys: all
; Preserves: OP1
stoRegNN:
    ld hl, regsName
    ld b, a ; B=index
    call getOp1RpnObjectType ; C=rpnObjectType
    jp stoRpnObject

; Description: Recall REGS[NN] into OP1/OP2. Works for complex.
; Input:
;   - A: register index, 0-based
;   - 'REGS' list variable
; Output:
;   - OP1: float value
;   - A: objectType
; Destroys: all
; Preserves: OP2
rclRegNN:
    ld hl, regsName
    ld b, a ; B=index
    jp rclRpnObject ; OP1/OP2=STK[A]

; Description: Recall REGS[NN] to OP2. WARNING: Assumes real not complex.
; Input:
;   - A: register index, 0-based
;   - 'REGS' list variable
; Output:
;   - OP2: float value
; Preserves: OP1
rclRegNNToOP2:
    push af
    bcall(_PushRealO1) ; FPS=[OP1]
    pop af
    call rclRegNN
    bcall(_OP1ToOP2)
    bcall(_PopRealO1) ; FPS=[]; OP1=OP1
    ret

;-----------------------------------------------------------------------------

; Description: Implement STO{op} NN, with {op} defined by B and NN given by C.
; Input:
;   - OP1/OP2: real or complex number
;   - B: operation index [0,4] into floatOps, MUST be same as argModifierXxx
;   - C: register index NN, 0-based
; Output:
;   - REGS[NN]=(REGS[NN] {op} OP1/OP2), where {op} is defined by B, and can be
;   a simple assignment operator
; Destroys: all, OP3, OP4
; Preserves: OP1, OP2
stoOpRegNN:
    push bc ; stack=[op,NN]
    bcall(_PushOP1) ; FPS=[OP1/OP2]
    call cp1ToCp3 ; OP3/OP4=OP1/OP2
    ; Recall REGS[NN]
    pop bc ; stack=[]; B=op; C=NN
    push bc ; stack=[op,NN]
    ld a, c ; A=NN
    call rclRegNN ; OP1/OP2=REGS[NN]
    ; Invoke op B
    pop bc ; stack=[]; B=op; C=NN
    push bc ; stack=[op,NN]
    ld a, b ; A=op
    ld hl, floatOps
    call jumpAOfHL
    ; Save REGS[C]
    pop bc ; stack=[]; B=op; C=NN
    ld a, c ; A=NN
    call stoRegNN
    ; restore OP1, OP2
    bcall(_PopOP1) ; FPS=[]; OP1/OP2=OP1/OP2
    ret

; Description: Implement RCL{op} NN, with {op} defined by B and NN given by C.
; WARNING: Works only for real not complex.
; Input:
;   - OP1
;   - B: operation index [0,4] into floatOps, MUST be same as argModifierXxx
;   - C: register index NN, 0-based
; Output:
;   - OP1/OP2=(OP1/OP2 {op} REGS[NN]), where {op} is defined by B, and can be a
;   simple assignment operator
; Destroys: all, OP3, OP4
rclOpRegNN:
    push bc ; stack=[op,NN]
    bcall(_PushOP1) ; FPS=[OP1/OP2]
    ; Recall REGS[NN]
    pop bc ; stack=[]; B=op; C=NN
    push bc ; stack=[op,NN]
    ld a, c ; A=NN
    call rclRegNN ; OP1/OP2=REGS[NN]
    call cp1ToCp3 ; OP3/OP4=OP1/OP2
    bcall(_PopOP1) ; FPS=[]; OP1/OP2=OP1/OP2
    ; Invoke op B
    pop bc ; stack=[]; B=op; C=NN
    ld a, b ; A=op
    ld hl, floatOps
    jp jumpAOfHL ; OP1/OP2=OP1/OP2{op}OP3/OP4

;-----------------------------------------------------------------------------

; List of floating point operations, indexed from 0 to 4. Implements `OP1/OP2
; {op}= OP3/OP4`. These MUST be identical to the argModifierXxx constants.
floatOpsCount equ 5
floatOps:
    .dw floatOpAssign ; 0, argModifierNone
    .dw floatOpAdd ; 1, argModifierAdd
    .dw floatOpSub ; 2, argModifierSub
    .dw floatOpMul ; 3, argModifierMul
    .dw floatOpDiv ; 4, argModifierDiv

; We could place these jump routines directly into the floatOps table. However,
; at some point the various complex functions will probably move to different
; flash page, which will requires a bcall(), so having this layer of
; indirection will make that refactoring easier. Also, this provides slightly
; better self-documentation.
floatOpAssign:
    jp cp3ToCp1
floatOpAdd:
    jp universalAdd
floatOpSub:
    jp universalSub
floatOpMul:
    jp universalMult
floatOpDiv:
    jp universalDiv

;-----------------------------------------------------------------------------
; STAT register functions.
; TODO: Move stat registers to a separate "RPN83STA" appVar so that we don't
; overlap with [R11,R23].
;-----------------------------------------------------------------------------

; Description: Add OP1 to storage register NN. Used by STAT functions.
; WARNING: Works only for real not complex.
; Input:
;   OP1: float value
;   A: register index NN, 0-based
; Output:
;   REGS[NN] += OP1
; Destroys: all
; Preserves: OP1, OP2
stoAddRegNN:
    push af ; A=NN
    bcall(_PushRealO1) ; FPS=[OP1]
    bcall(_PushRealO2) ; FPS=[OP1,OP2]
    bcall(_OP1ToOP2)
    call rclRegNN ; I guess A is preserved by the previous bcalls
    bcall(_FPAdd) ; OP1 += OP2
    pop af ; A=NN
    call stoRegNN
    bcall(_PopRealO2) ; FPS=[OP1]
    bcall(_PopRealO1) ; FPS=[]; OP1=OP1
    ret

; Description: Subtract OP1 from storage register NN. Used by STAT functions.
; WARNING: Works only for real not complex.
; Input:
;   OP1: float value
;   A: register index NN, 0-based
; Output:
;   REGS[NN] -= OP1
; Destroys: all
; Preserves: OP1, OP2
stoSubRegNN:
    push af ; A=NN
    bcall(_PushRealO1) ; FPS=[OP1]
    bcall(_PushRealO2) ; FPS=[OP1,OP2]
    bcall(_OP1ToOP2)
    call rclRegNN ; I guess A is preserved by the previous bcalls
    bcall(_FPSub) ; OP1 -= OP2
    pop af ; A=NN
    call stoRegNN
    bcall(_PopRealO2) ; FPS=[OP1]
    bcall(_PopRealO1) ; FPS=[]; OP1=OP1
    ret

; Description: Clear the storage registers used by the STAT functions. In
; Linear mode [R11, R16], in All mode [R11, R23], inclusive.
; Input: none
; Output:
;   - B: 0
;   - C: 24
;   - OP1: 0
; Destroys: all, OP1
clearStatRegs:
    bcall(_OP1Set0)
    ld c, 11 ; begin clearing register 11
    ; Check AllMode or LinearMode.
    ld a, (statAllEnabled)
    or a
    jr nz, clearStatRegsAll
    ld b, 6 ; clear first 6 registers in Linear mode
    jr clearStatRegsEntry
clearStatRegsAll:
    ld b, 13 ; clear all 13 registesr in All mode
    jr clearStatRegsEntry
clearStatRegsLoop:
    inc c
clearStatRegsEntry:
    ld a, c
    push bc
    call stoRegNN
    pop bc
    djnz clearStatRegsLoop
    ret
