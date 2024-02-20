;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Routines to access the menudef.asm data structure in flash page 1.
;
; Capitalized labels are intended to be exported to the branch table on flash
; page 0. Lowercased labels are intended to be local to the current flash page.
;-----------------------------------------------------------------------------

; Description: Set initial values for various menu node variables.
; Input: none
; Output:
;   - (currentMenuGroupId) = mRootId
;   - (currentMenuRowIndex) = 0
;   - (jumpBackMenuGroupId) = 0
;   - (jumpBackMenuRowIndex) = 0
; Destroys: A, HL
InitMenu:
    ld hl, mRootId
    ld (currentMenuGroupId), hl
    xor a
    ld (currentMenuRowIndex), a
    call ClearJumpBack
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Sanitize the current menuGroup upon application start. This is
; needed when the version of the app that saved its menu state (in RPN83SAV)
; has a different menu hierarchy than the current version of the app. It is
; then possible for the (currentMenuGroupId) to point to a completely different
; or non-existent menuGroup, which causes the menu bar to be rendered
; incorrectly. In the worse case, it may cause the system to hang. This
; function checks if the (currentMenuGroupId) is actually a valid MenuGroup. If
; not, we reset the menu to the ROOT.
;
; The problem would not exist if we incremented the appStateSchemaVersion when
; the menu hierarchy is changed using menudef.txt. But this is easy to forget,
; because changing the menu hierarchy does not change the *layout* of the app
; variables. It only changes the *semantic* meaning of the value stored in the
; (currentMenuGroupId) variable.
;
; Input:
;   - (currentMenuGroupId)
;   - (currentMenuRowIndex)
; Destroys: A, HL, IX
SanitizeMenu:
    ; Check valid menuId.
    ld hl, (currentMenuGroupId)
    ld de, mMenuTableSize
    call cpHLDEPageOne ; CF=0 if currentMenuGroupId>=mMenuTableSize
    jr nc, sanitizeMenuReset
    ; Check for MenuGroup.
    call findMenuNodeIX ; IX=menuNode
    ld a, (ix + menuNodeFieldNumRows); A=numRows
    or a
    jr z, sanitizeMenuReset ; reset if current node is a MenuItem
    ; Check currentMenuRowIndex
    ld a, (currentMenuRowIndex)
    cp (ix + menuNodeFieldNumRows)
    ret c
    ; [[fallthrough]] if currentMenuRowIndex >= numRows
sanitizeMenuReset:
    ld hl, mRootId
    ld (currentMenuGroupId), hl
    xor a
    ld (currentMenuRowIndex), a
    ret

;-----------------------------------------------------------------------------
; Routines which operate on the currentMenuGroupId or currentMenuRowIndex.
;-----------------------------------------------------------------------------

; Description: Clear the jumpBack variables.
; Input: (jumpBackMenuGroupId), (jumpBackMenuRowIndex)
; Output: (jumpBackMenuGroupId), (jumpBackMenuRowIndex) both set to 0
; Destroys: none
ClearJumpBack:
    push hl
    push af
    ld hl, 0
    ld (jumpBackMenuGroupId), hl ; set to 0
    ld a, l
    ld (jumpBackMenuRowIndex), a ; set to 0
    pop af
    pop hl
    ret

; Description: Save the current (currentMenuGroupId) and (currentMenuRowIndex)
; to the jumpBack variables.
; Input: (currentMenuGroupId), (currentMenuRowIndex)
; Output: (jumpBackMenuGroupId), (jumpBackMenuRowIndex) set
; Destroys: none
SaveJumpBack:
    push hl
    push af
    ld hl, (currentMenuGroupId)
    ld (jumpBackMenuGroupId), hl
    ld a, (currentMenuRowIndex)
    ld (jumpBackMenuRowIndex), a
    pop af
    pop hl
    ret

;-----------------------------------------------------------------------------

; Bit flags that indicate if the corresponding menu arrow should be shown.
menuArrowFlagLeft equ 0
menuArrowFlagDown equ 1
menuArrowFlagUp equ 2

; Description: Return the status of menu arrow indicators.
; Input:
;   - (currentMenuGroupId)
;   - (currentMenuRowIndex)
; Output:
;   - B:menuArrowFlag
; Destroys: A, B, C, HL
GetCurrentMenuArrowStatus:
    ld b, 0 ; B=menuArrowFlag
    ; Defensive check for MenuItem instead of MenuGroup.
    ld hl, (currentMenuGroupId)
    call findMenuNodeIX ; IX=menuNode
    ld a, (ix + menuNodeFieldNumRows) ; A=numRows
    or a
    ld c, a ; C=numRows
    ret z ; if numRows==0: display no arrows
    ; Check if left arrow should be shown.
    ld a, (ix + menuNodeFieldParentId)
    or (ix + menuNodeFieldParentId + 1) ; if parentId==0: ZF=1
    jr z, getCurrentMenuArrowStatusCheckDown
    set menuArrowFlagLeft, b
getCurrentMenuArrowStatusCheckDown:
    ; Check if Down arrow should be shown.
    ld a, (currentMenuRowIndex)
    inc a
    cp c ; if rowIndex+1<numRows: CF=1
    jr nc, getCurrentMenuArrowStatusCheckUp
    set menuArrowFlagDown, b
getCurrentMenuArrowStatusCheckUp:
    ; Check if Up arrow should be shown.
    dec a ; ZF=1 if numRows==0
    ret z
    set menuArrowFlagUp, b
    ret

;-----------------------------------------------------------------------------

; Description: Get the menuId corresponding to the soft menu button given by A.
; Input:
;   - A=buttonIndex (0-4)
;   - (currentMenuGroupId)
;   - (currentMenuRowIndex)
; Output:
;   - HL=u16=menuId
; Destroys: DE, HL
GetMenuIdOfButton:
    ld e, a
    ld d, 0
    push de ; stack=[buttonIndex]
    call GetCurrentMenuRowBeginId ; HL=rowMenuId
    pop de
    add hl, de ; HL=menuId
    ret

; Description: Return the node id of the first item in the menu row at
; `currentMenuRowIndex` of the `currentMenuGroupId`. The next 4 node
; ids in sequential order define the other 4 menu buttons.
; Input:
;   - (currentMenuGroupId)
;   - (currentMenuRowIndex)
; Output:
;   - DE=rowBeginId=menuId of first item of row 0
;   - HL=rowMenuId=menuId of the first item of row 'rowIndex'
; Destroys: A, DE, HL
; Preserves: BC
GetCurrentMenuRowBeginId:
    ld hl, (currentMenuGroupId)
    ld a, (currentMenuRowIndex)
    jr getMenuRowBeginId

;-----------------------------------------------------------------------------

; Description: Return the number of rows in the current menu group.
; Input: (currentMenuGroupId)
; Output: A=numRows
GetCurrentMenuGroupNumRows:
    ld hl, (currentMenuGroupId)
    call findMenuNodeIX ; IX:(MenuNode*)=menuNode
    ld a, (ix + menuNodeFieldNumRows)
    ret

;-----------------------------------------------------------------------------
; Low-level routines for traversing and searching the mMenuTable. These do
; *not* depend on (currentMenuGroupId) or (currentMenuRowIndex).
;-----------------------------------------------------------------------------

; Description: Return the first menuNodeId for menuGroupId (HL) at rowIndex (A).
; Input:
;   - A=rowIndex
;   - HL=menuGroupId
; Output:
;   - DE=rowBeginId=menuId of first item of row 0
;   - HL=rowMenuId=menuId of the first item of row 'rowIndex'
; Destroys: A, DE, HL
; Preserves: BC
getMenuRowBeginId:
    call findMenuNodeIX ; IX=menuNode
    ld e, (ix + menuNodeFieldRowBeginId)
    ld d, (ix + menuNodeFieldRowBeginId + 1) ; DE=menuNode.rowBeginId
    ; Calc the rowMenuId at given rowIndex: rowMenuId=rowBeginId+5*rowIndex
    ld l, a ; L=rowIndex
    add a, a
    add a, a
    add a, l ; A=5*rowIndex
    ld l, a
    ld h, 0 ; HL=5*rowIndex
    ; calc rowMenuId=rowBeginId+5*rowIndex
    add hl, de ; HL=rowMenuId=rowBeginId+5*rowIndex
    ret

;-----------------------------------------------------------------------------

; Description: Retrieve the mXxxHandler of the given MenuNode.
; Input:
;   - HL=menuNodeId
; Output:
;   - A=numRows (0 indicates MenuItem; >0 indicates MenuGroup)
;   - DE=handler
;   - IX=menuNode
; Destroys: A, BC, DE, HL, IX
GetMenuNodeHandler:
    call findMenuNodeIX ; IX:(MenuNode*)=menuNode
    ld a, (ix + menuNodeFieldNumRows) ; A=numRows
    ld e, (ix + menuNodeFieldHandler)
    ld d, (ix + menuNodeFieldHandler + 1) ; DE=handler
    ret

;-----------------------------------------------------------------------------

; Description: Retrieve the parentId of the given MenuNode.
; Input:
;   - HL=menuNodeId
; Output:
;   - A=numRows (0 indicates MenuItem; >0 indicates MenuGroup)
;   - DE=parentId
;   - IX=menuNode
; Destroys: A, BC, DE, HL, IX
GetMenuNodeParent:
    call findMenuNodeIX ; IX:(MenuNode*)=menuNode
    ld a, (ix + menuNodeFieldNumRows) ; A=numRows
    ld e, (ix + menuNodeFieldParentId)
    ld d, (ix + menuNodeFieldParentId + 1) ; DE=parentId
    ret

;-----------------------------------------------------------------------------

; Description: Return the pointer to menuNode of HL in IX.
; Input: HL=menuNodeId
; Output: HL,IX:(MenuNode*)=address of node
; Destroys: HL, IX
; Preserves: A, BC, DE
GetMenuNodeIX:
    push af
    push bc
    push de
    ;
    call findMenuNode
    ; Copy it to (menuNodeBuf).
    ld de, menuNodeBuf
    ld bc, menuNodeSizeOf
    ldir
    ld hl, menuNodeBuf
    push hl
    pop ix
    ;
    pop de
    pop bc
    pop af
    ret

; Description: Find the MenuNode identified by menuId and return the pointer to
; the MenuNode in HL. No bounds checking is performed.
; Input:
;   - HL=menuId
; Output:
;   - HL(MenuNode*)=menuNode
; Destroys: all
findMenuNode:
    call calcMenuNodeOffset ; HL=offset
    ld de, mMenuTable
    add hl, de ; HL=menuNode
    ret

; Description: Find the MenuNode identified by menuId, and copy it into
; (menuNodeBuf). No bounds checking is performed.
; Input:
;   - HL=menuId
; Output:
;   - IX:(MenuNode*)=menuNode
; Destroys: all
findMenuNodeIX:
    call calcMenuNodeOffset ; HL=offset
    ex de, hl ; DE=offset
    ld ix, mMenuTable
    add ix, de ; IX=menuNode
    ret

; Description: Return the byte offset of menuId into the the mMenuTable.
; The formula is: offset=menuId*sizeof(MenuNode)=menuId*13=menuId*(8+4+1)
; Input: HL=menuId
; Output: HL=offset
; Destroys: BC, DE
calcMenuNodeOffset:
    ld c, l
    ld b, h ; BC=menuId
    add hl, hl
    add hl, hl ; HL=4*menuId
    ld e, l
    ld d, h ; DE=4*menuId
    add hl, hl ; 8*menuId
    add hl, de ; 12*menuId
    add hl, bc ; 13*menuId
    ret

;-----------------------------------------------------------------------------

; Description: Extract the normal and alternate menu names of the menu node
; identified by HL. Also returns the pointer to the nameSelector() function
; which selects the name which should be used.
;
; The input to the nameSelector() function is:
;   - HL: pointer to MenuNode (in case it is needed)
; The output of the nameSelector() is:
;   - CF=0 to select the normal name, CF=1 to select the alt name
; The name is selected according to the relevant internal state (e.g. DEG or
; RAD). The nameSelector is allowed to modify BC, DE, since they are restored
; before returning from this function. It is also allowed to modify HL since it
; gets clobbered with string pointer before returning from this function.
;
; Input: HL:u16=menuId
;   - BC:(char*)=altName (e.g. OP4)
;   - DE:(char*)=normalName (e.g. OP3)
;   - HL:u16=menuId
; Output:
;   - (*BC) filled with altName
;   - (*DE) filled with normalName
;   - HL=nameSelector
; Destroys: A, HL
; Preserves: BC, DE
ExtractMenuNames:
    push de ; stack=[normalName]
    push bc ; stack=[normalName,altName]
    call findMenuNodeIX ; IX=(MenuNode*)
    ; extract alt name
    ld l, (ix + menuNodeFieldAltNameId)
    ld h, (ix + menuNodeFieldAltNameId + 1)
    pop de ; [normalName] ; DE=altName
    call extractMenuString ; (*DE)=altName
    ; select normal name
    ex de, hl ; HL=altName
    ex (sp), hl ; stack=[altName] ; HL=normalName
    ex de, hl ; DE=normalName
    ld l, (ix + menuNodeFieldNameId)
    ld h, (ix + menuNodeFieldNameId + 1)
    call extractMenuString ; (*DE)=normalName
    ; nameSelector
    ld l, (ix + menuNodeFieldNameSelector)
    ld h, (ix + menuNodeFieldNameSelector + 1) ; HL=nameSelector
    ;
    pop bc ; stack=[]; BC=altname
    ret

; Description: Copy the menu name identified by HL into the C-string buffer at
; DE.
; Input:
;   - HL=menuNameId
;   - DE:(char*)=dest
; Output:
;   - (*DE)=destString updated
; Destroys: A
; Preserves: BC, DE, HL
extractMenuString:
    push bc ; stack=[BC]
    push hl ; stack=[BC,menuNameId]
    push de ; stack=[BC,menuNameId,dest]
    ex de, hl ; DE=menuNameId
    ld hl, mMenuNameTable
    call getDEStringPageOne ; HL:(const char*)=name
    ; Copy the name to DE
    pop de ; stack=[BC,menuNameId]; DE=dest
    push de ; stack=[BC,menuNameId,dest]
    ld b, 6 ; at most 6 bytes, including NUL terminator
extractMenuStringLoop:
    ld a, (hl)
    ld (de), a
    inc hl
    inc de
    or a
    jr z, extractMenuStringEnd
    djnz extractMenuStringLoop
    ; Clobber the last byte with NUL to terminate the C-string
    dec de
    xor a
    ld (de), a
extractMenuStringEnd:
    pop de ; stack=]BC,menunameId]; DE=dest restored
    pop hl ; stack=[BC]; HL=menuNameId restored
    pop bc ; stack=[]; BC=restored
    ret
