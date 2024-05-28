;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Store and restore the app state using an AppVar named 'RPN83SAV'.
;
; Capitalized labels are intended to be exported to the branch table on flash
; page 0. Lowercased labels are intended to be local to the current flash page.
;-----------------------------------------------------------------------------

appVarName:
    .db AppVarObj, "RPN83SAV" ; max 8 characters, NUL terminated if < 8

setAppVarName:
    ld hl, appVarName
    bcall(_Mov9ToOP1)
    ret

; Description: Store the RPN83P state to an AppVar named 'RPN83SAV'.
StoreAppState:
    call setAppVarName
    bcall(_ChkFindSym)
    jr c, storeAppStateCreate ; if CF=1: not found
storeAppStateDelete:
    ; alway delete the app var if found
    bcall(_DelVarArc)
storeAppStateCreate:
    ; Fill in the appVar header fields (appId, varType, schemaVersion).
    ld hl, rpn83pAppId
    ld (appStateAppId), hl
    ld hl, rpnVarTypeAppState
    ld (appStateVarType), hl
    ld hl, rpn83pSchemaVersion
    ld (appStateSchemaVersion), hl
    ; Copy various OS parameters into the appState fields.
    call setAppStateFromOS
    ; Calculate the CRC16 on the data block.
    ld hl, appStateBegin + 2 ; don't include the CRC16 field itself
    ld bc, appStateSize - 2 ; don't include the CRC16 field itself
    bcall(_Crc16ccitt)
    ld (appStateCrc16), hl
    ; Transfer the appState data block.
    call setAppVarName
    ld hl, appStateSize
    bcall(_CreateAppVar) ; DE=pointer to appvar data
    inc de
    inc de ; skip past the 2-byte size field
    ld hl, appStateBegin
    ld bc, appStateSize
    ldir ; transfer bytes
    ret

; Description: Copy various OS parameters into the appState.
setAppStateFromOS:
    ld a, (iy + dirtyFlags)
    ld (appStateDirtyFlags), a
    ld a, (iy + rpnFlags)
    ld (appStateRpnFlags), a
    ld a, (iy + inputBufFlags)
    ld (appStateInputBufFlags), a
    ;
    ld a, (iy + trigFlags)
    ld (appStateTrigFlags), a
    ld a, (iy + fmtFlags)
    ld (appStateFmtFlags), a
    ld a, (fmtDigits)
    ld (appStateFmtDigits), a
    ret

;-----------------------------------------------------------------------------

; Description: Restore the RPN83P application state from an AppVar named
; 'RPN83SAV'.
; Output:
;   CF=0: if restored correctly from the AppVar
;   CF=1: if the AppVar does not exist, or was invalid for any reason. The
;       application should initialize its state from scratch.
RestoreAppState:
    call setAppVarName
    bcall(_ChkFindSym) ; DE=pointer to data
    ret c ; CF=1 if not found
    ex de, hl; HL=pointer to data
    ld e, (hl)
    inc hl
    ld d, (hl) ; DE=size of appVar
    inc hl
    ; Validate the AppVar size
    push hl ; save data + 2
    ld hl, appStateSize
    or a ; CF=0
    sbc hl, de ; if HL==DE: ZF=0
    pop hl ; HL=data + 2
    jr nz, restoreAppStateFailed
restoreAppStateRead:
    ; Read the AppVar data into appStateBegin
    ld de, appStateBegin
    ld bc, appStateSize
    ldir
restoreAppStateValidate:
    ; Validate the appStateAppId
    ld hl, (appStateAppId)
    ld de, rpn83pAppId
    or a ; CF=0
    sbc hl, de
    jr nz, restoreAppStateFailed
    ; Validate the appStateVarType
    ld hl, (appStateVarType)
    ld de, rpnVarTypeAppState
    or a ; CF=0
    sbc hl, de
    jr nz, restoreAppStateFailed
    ; Validate the appStateSchemaVersion
    ld hl, (appStateSchemaVersion)
    ld de, rpn83pSchemaVersion
    or a ; CF=0
    sbc hl, de
    jr nz, restoreAppStateFailed
    ; Validate the CRC16
    ld hl, appStateBegin + 2 ; don't include the CRC16 field itself
    ld bc, appStateSize - 2 ; don't include the CRC16 field itself
    bcall(_Crc16ccitt)
    ld de, (appStateCrc16)
    or a ; CF=0
    sbc hl, de
    jr nz, restoreAppStateFailed
    ; Restore OS parameters from appState.
    call setOSFromAppState
    ; Validation passed
    or a ; CF=0
    ret
restoreAppStateFailed:
    scf
    ret

; Set the various OS parameters from the AppState.
setOSFromAppState:
    ld a, (appStateDirtyFlags)
    ld (iy + dirtyFlags), a
    ld a, (appStateRpnFlags)
    ld (iy + rpnFlags), a
    ld a, (appStateInputBufFlags)
    ld (iy + inputBufFlags), a
    ;
    ld a, (appStateTrigFlags)
    ld (iy + trigFlags), a
    ld a, (appStateFmtFlags)
    ld (iy + fmtFlags), a
    ld a, (appStateFmtDigits)
    ld (fmtDigits), a
    ret
