;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Routines for navigating the singly-rooted tree of MenuNodes. A MenuNode can
; be either a MenuItem or MenuGroup. A MenuGroup is a list of one or more
; MenuRow. A MenuRow is a list of exactly 5 MenuNodes, corresponding to the
; 5 menu buttons located just below the LCD screen of the calculator.
;
; The root of the menu tree is usually called the RootMenu and has an id of 1.
; The calculator menu hierarchy is described using a DSL (domain specific
; language) that I loosely call the "Menu Definition Language". The menu nodes
; are defined in the `menudef.txt` file. It is compiled through a Python script
; located at `tools/compilemenu.py`, which generates the `menudef.asm` file,
; which contains a list of MenuNodes and the C-strings that define the names of
; the menu items.
;
; Each MenuNode has the following structure, described using the C language
; syntax:
;
; struct MenuNode {
;   uint16_t id; // root begins with 1
;   uint16_t parentId; // 0 indicates NONE
;   uint16_t nameId; // index into NameTable
;   uint8_t numRows; // 0 if MenuItem; >=1 if MenuGroup
;   union {
;       uint16_t rowBeginId; // nodeId of the first node of first menu row
;       uint16_t altNameId; // alternate name string (if nameSelector!=NULL)
;   }
;   void *handler; // pointer to the handler function
;   void *nameSelector; // function that selects between 2 menu names
; };
;
; sizeof(MenuNode) == 13
;
;-----------------------------------------------------------------------------

; Offsets into the MenuNode struct. Intended to be used as offset to the IX
; register after calling getMenuNodeIX().
menuNodeFieldId equ 0
menuNodeFieldParentId equ 2
menuNodeFieldNameId equ 4
menuNodeFieldNumRows equ 6
menuNodeFieldRowBeginId equ 7
menuNodeFieldAltNameId equ 7
menuNodeFieldHandler equ 9
menuNodeFieldNameSelector equ 11

; Description: Set initial values for various menu node variables.
; Input: none
; Output:
;   - (currentMenuGroupId) = mRootId
;   - (currentMenuRowIndex) = 0
;   - (jumpBackMenuGroupId) = 0
;   - (jumpBackMenuRowIndex) = 0
; Destroys: A, HL
initMenu:
    ld hl, mRootId
    ld (currentMenuGroupId), hl
    xor a
    ld (currentMenuRowIndex), a
    call clearJumpBack
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
; Destroys: A, HL, IX
sanitizeMenu:
    ; Check valid menuId.
    ld hl, (currentMenuGroupId)
    ld de, mMenuTableSize
    call cpHLDE ; CF=0 if currentMenuGroupId>=mMenuTableSize
    jr nc, sanitizeMenuReset
    ; Check for MenuGroup.
    call getMenuNodeIX ; IX=menuNode
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

; Description: Get the menuId corresponding to the soft menu button given by A.
; Input:
;   - A=buttonIndex (0-4)
;   - (currentMenuGroupId)
;   - (currentMenuRowIndex)
; Output:
;   - HL=u16=menuId
; Destroys: DE, HL
getMenuIdOfButton:
    ld e, a
    ld d, 0
    push de ; stack=[buttonIndex]
    call getCurrentMenuRowBeginId ; HL=rowMenuId
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
getCurrentMenuRowBeginId:
    ld hl, (currentMenuGroupId)
    ld a, (currentMenuRowIndex)
    jr getMenuRowBeginId

; Description: Return the number of rows in the current menu group.
; Input: (currentMenuGroupId)
getCurrentMenuGroupNumRows:
    ld hl, (currentMenuGroupId)
    call getMenuNodeIX ; IX:(MenuNode*)=menuNode
    ld a, (ix + menuNodeFieldNumRows)
    ret

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
getCurrentMenuArrowStatus:
    ld b, 0 ; B=menuArrowFlag
    ; Defensive check for MenuItem instead of MenuGroup.
    ld hl, (currentMenuGroupId)
    call getMenuNodeIX ; IX=menuNode
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
    call getMenuNodeIX ; IX=menuNode
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

; Description: Return the pointer to menu node identified by menuNodeId.
; TODO: Move to menulookup1.asm.
; Input: HL=menuNodeId
; Output: HL:(MenuNode*)=address of node
; Destroys: DE, HL
; Preserves: A, BC
getMenuNode:
    push af
    push bc
    bcall(_FindMenuNode)
    pop bc
    pop af
    ret

; Description: Return the pointer to the menu node at id A in register IX.
; TODO: Move to menulookup1.asm.
; Input: HL=menuNodeId
; Output: IX:(MenuNode*)=address of node
; Destroys: DE, HL
; Preserves: A, BC
getMenuNodeIX:
    call getMenuNode
    push hl
    pop ix
    ret

; Description: Return the pointer to the name string of the menu node at HL.
; If MenuNode.nameSelector is 0, then the display name is simply the nameId.
; But if the MenuNode.nameSelector is not 0, then it is a pointer to a function
; that returns the display name.
;
; The input to the nameSelector() function is:
;   - HL: pointer to MenuNode (in case it is needed)
; The output of the nameSelector() is:
;   - CF=0 to select the normal name, CF=1 to select the alt name
;
; The name is selected according to the relevant internal state (e.g. DEG or
; RAD). The nameSelector is allowed to modify BC, DE, since they are restored
; before returning from this function. It is also allowed to modify HL since it
; gets clobbered with string pointer before returning from this function.
;
; Input: HL:u16=menuId
; Output: HL:(const char*)=menuName
; Destroys: A, HL, OP3, OP4
; Preserves: BC, DE
getMenuName:
    push bc
    push de
    ld bc, OP3
    ld de, OP4
    call extractMenuNames ; BC=altName; DE=normalName; HL=selector
    ; if nameSelector!=NULL: call nameSelector()
    ld a, l
    or h ; if HL==0: ZF=1
    jr z, getMenuNameSelectNormal
    ; call nameSelector() to select the name string
    call jumpHL ; call nameSelector(); CF=1 if altName selected
    jr c, getMenuNameSelectAlt
getMenuNameSelectNormal:
    ex de, hl ; HL=normalName
    jr getMenuNameFind
getMenuNameSelectAlt:
    ld l, c
    ld h, b ; HL=altName
getMenuNameFind:
    pop de
    pop bc
    ret

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
extractMenuNames:
    push de ; stack=[normalName]
    push bc ; stack=[normalName,altName]
    call getMenuNodeIX ; IX=(MenuNode*)
    ; extract alt name
    ld l, (ix + menuNodeFieldAltNameId)
    ld h, (ix + menuNodeFieldAltNameId + 1)
    pop de ; [normalName] ; DE=altName
    bcall(_ExtractMenuString) ; (*DE)=altName
    ; select normal name
    ex de, hl ; HL=altName
    ex (sp), hl ; stack=[altName] ; HL=normalName
    ex de, hl ; DE=normalName
    ld l, (ix + menuNodeFieldNameId)
    ld h, (ix + menuNodeFieldNameId + 1)
    bcall(_ExtractMenuString) ; (*DE)=normalName
    ; nameSelector
    ld l, (ix + menuNodeFieldNameSelector)
    ld h, (ix + menuNodeFieldNameSelector + 1) ; HL=nameSelector
    ;
    pop bc ; stack=[]; BC=altname
    ret

;-----------------------------------------------------------------------------

; Description: Dispatch to the handler for the menu node in register A.
;
; There are 2 cases:
;
; 1) If the target node is a MenuItem, then the 'onEnter' event is sent to the
; item by invoking its handler.
; 2) If the target node is a MenuGroup, a 'chdir' operation is implemented in 3
; steps:
;   a) The handler of the previous MenuGroup is sent an 'onExit' event,
;   signaled by calling its handlers with the carry flag CF=1.
;   b) The (currentMenuGroupId) and (currentMenuRowIndex) are updated with the
;   target menu group.
;   c) The handler of the traget MenuGroup is sent an 'onEnter' event, signaled
;   by calling its handlers with the carry flag CF=0.
;
; Input:
;    - HL=targetNodeId
; Output:
;   - (currentMenuGroupId) is updated if the target is a MenuGroup
;   - (currentMenuRowIndex) is set to 0 if the target is a MenuGroup
;   - (jumpBackMenuGroupId) cleared
;   - (jumpBackMenuRowIndex) cleared
; Destroys: A, B, C, DE, HL, IX
dispatchMenuNode:
    push hl ; stack=[targetNodeId]
    call getMenuNode ; HL:(MenuNode*)=menuNode
    call getMenuNodeHandler ; A=numRows; DE=handler; HL=menuNode
    ; Invoke a MenuItem.
    or a ; if numRows == 0: ZF=1 (i.e. a MenuItem)
    pop hl ; stack=[]; HL=targetNodeId
    jp z, jumpDE ; Invoke menuHandler().
    ; Item was a menuGroup, so change into the target menu group. First clear
    ; the jumpBack registers. Then invoke changeMenuGroup().
    call clearJumpBack
    xor a ; A=targetRowIndex=0
    jr changeMenuGroup

; Description: Same as dispatchMenuNode, except save the
; currentMenuGroupId/currentMenuRowIndex in the jumpBack registers if the
; target is different than the current.
; Input:
;   - HL=targetNodeId
; Output
;   - (currentMenuGroupId) is updated if the target is a MenuGroup
;   - (currentMenuRowIndex) is set to 0 if the target is a MenuGroup
;   - (jumpBackMenuGroupId) set to currentMenuGroupId
;   - (jumpBackMenuRowIndex) set to currentMenuRowIndex
; Destroys: B
dispatchMenuNodeWithJumpBack:
    push hl ; stack=[targetNodeId]
    call getMenuNode ; HL:(MenuNode*)=menuNode
    call getMenuNodeHandler ; A=numRows; DE=handler; HL=menuNode
    ; Invoke a MenuItem.
    or a ; if numRows == 0: ZF=1 (i.e. a MenuItem)
    pop hl ; stack=[]; HL=targetNodeId
    jp z, jumpDE ; Invoke menuHandler().
    ; Item was a menuGroup, so change into the target menu group. First, update
    ; the jumpBack registers if target is different than current. Then invoke
    ; changeMenuGroup().
    ld de, (currentMenuGroupId)
    call cpHLDE ; ZF=1 if targetNodeId==currentMenuGroupId
    call nz, saveJumpBack
    xor a ; A=rowIndex=0
    jr changeMenuGroup

; Description: Retrieve the mXxxHandler of the given MenuNode.
; Input:
;   - HL:(MenuNode*)=menuNode
; Output:
;   - A=numRows (0 indicates MenuItem; >0 indicates MenuGroup)
;   - DE=handler
; Preserves: BC, HL
; Destroys: A, DE, IX
getMenuNodeHandler:
    push hl ; stack=[menuNode]
    pop ix ; stack=[]; IX=menuNode
    ld a, (ix + menuNodeFieldNumRows) ; C=numRows
    ld e, (ix + menuNodeFieldHandler)
    ld d, (ix + menuNodeFieldHandler + 1) ; DE=handler
    ret

;-----------------------------------------------------------------------------

; Description: Go back from the menu group specified by (currentMenuGroupId).
; Normally, the jumpBackMenuGroupId is 0, and this handler should go up to the
; parent MenuGroup of the current MenuGroup. However, if jumpBackMenuGroupId is
; non-zero, then the current MenuGroup was reached through a keyboard shortcut,
; and the exit handler should go back to the jumpBack MenuGroup.
; Input:
;   - (currentMenuGroupId)
;   - (jumpBackMenuGroupId)
;   - (jumpBackMenuRowIndex)
; Output:
;   - (currentMenuGroupId) updated
;   - (currentMenuRowIndex) updated
; Destroys: A, BC, DE, HL
exitMenuGroup:
    ; Check if the jumpBack target is defined.
    ld hl, (jumpBackMenuGroupId)
    ld a, h
    or l
    jr z, exitMenuGroupHierarchy
exitMenuGroupThroughJumpBack:
    ; Go to jumpBack MenuGroup.
    ld a, (jumpBackMenuRowIndex)
    ; But clear the jumpBack before going back.
    call clearJumpBack
    jr changeMenuGroup
exitMenuGroupHierarchy:
    ; Check if already at rootGroup
    ld hl, (currentMenuGroupId)
    ld de, mRootId
    call cpHLDE
    jr nz, exitMenuGroupToParent
    ; If already at rootId, go to menuRow0 if not already there.
    ld a, (currentMenuRowIndex)
    or a
    ret z ; already at rowIndex 0
    xor a ; set rowIndex to 0, set dirty bit
    ld (currentMenuRowIndex), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret
exitMenuGroupToParent:
    ; Get target groupId and rowIndex of the parent group.
    push hl ; stack=[childId]
    call getMenuNodeIX ; IX=menuNode
    ld l, (ix + menuNodeFieldParentId)
    ld h, (ix + menuNodeFieldParentId + 1) ; HL=parentId
    push hl ; stack=[childId,parentId]
    call getMenuNodeIX ; IX=parentMenuNode
    ld b, (ix + menuNodeFieldNumRows) ; B=parent.numRows
    ld e, (ix + menuNodeFieldRowBeginId)
    ld d, (ix + menuNodeFieldRowBeginId + 1) ; DE=parent.rowBeginId
    ; Deduce the parent's rowIndex which matches the childId.
    pop hl ; stack=[childId]; HL=parentId
    ex (sp), hl ; stack=[parentId]; HL=childId
    call deduceRowIndex ; A=rowIndex
    pop hl ; stack=[]; HL=parentId
    ; [[fallthrough]]

; Description: Change the current menu group to the target menuGroup and
; rowIndex. Sends an onExit() event to the previous menuGroupHandler by setting
; at CF=1. Then sends an onEnter() event to the new menuGroupHandler by setting
; CF=0.
; Input:
;   - A=targetRowIndex
;   - HL=targetMenuGroupId
; Output:
;   - (currentMenuGroupId)=target nodeId
;   - (currentMenuRowIndex)=target rowIndex
;   - dirtyFlagsMenu set
; Destroys: A, DE, HL, IX
changeMenuGroup:
    push hl ; stack=[targetMenuGroupId]
    push af ; stack=[targetMenuGroupId,targetRowIndex]
    ; 1) Invoke the onExit() handler of the previous MenuGroup by setting CF=1.
    ld hl, (currentMenuGroupId)
    call getMenuNodeIX ; IX:(MenuNode*)=menuNode
    ld e, (ix + menuNodeFieldHandler)
    ld d, (ix + menuNodeFieldHandler + 1)
    scf ; CF=1 means "onExit()" event
    call jumpDE
    ; 2) Invoke the onEnter() handler of the target MenuGroup by setting CF=0.
    pop af ; stack=[targetMenuGroupId]; A=targetRowIndex
    pop hl ; stack=[]; HL=targeMenuGroupId
    ld (currentMenuGroupId), hl
    ld (currentMenuRowIndex), a
    call getMenuNodeIX ; IX=menuNode
    ld e, (ix + menuNodeFieldHandler)
    ld d, (ix + menuNodeFieldHandler + 1)
    or a ; set CF=0
    set dirtyFlagsMenu, (iy + dirtyFlags)
    jp jumpDE

; Description: Deduce the rowIndex location of the childId (HL) within a parent
; menuGroup that contains parentNumRows (B) which begin with parentRowBeginId
; (DE). The formula is actually simple: `rowIndex = int((childId -
; parentRowBeginId)/5)` but the problem is that the Z80 does not have a
; hardware divison instruction. We could use one of the software divide
; routines (e.g. divHLByCPageTwo()), but for this simple calculation, it's
; easy enough to just loop through the 5 menu ids of each row until we find the
; row that contains the childId.
;
; Input:
;   - B=parentNumRows
;   - DE=parentRowBeginId
;   - HL=childId
; Output:
;    - A=rowIndex
; Destroys: A, BC, DE
; Preserves: HL
deduceRowIndex:
    ld c, 0 ; C=rowIndex
    ; begin with DE=rowId=parentRowBeginId
deduceRowIndexLoop:
    ; add 5 to DE=rowId to next rowBeginId
    ld a, e
    add a, 5
    ld e, a
    ld a, d
    adc a, 0
    ld d, a
    ; check if childId is contained within the previous row
    call cpHLDE ; if child<rowId: CF=1
    jr c, deduceRowIndexEnd ; found if childId<rowId
    inc c ; increment the candidate rowIndex
    djnz deduceRowIndexLoop
    ; We should never fall off the end of the loop, but if we do, set the
    ; rowIndex to 0.
    xor a
    ret
deduceRowIndexEnd:
    ld a, c
    ret

;-----------------------------------------------------------------------------

; Description: Clear the jumpBack variables.
; Input: (jumpBackMenuGroupId), (jumpBackMenuRowIndex)
; Output: (jumpBackMenuGroupId), (jumpBackMenuRowIndex) both set to 0
; Destroys: none
clearJumpBack:
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
saveJumpBack:
    push hl
    push af
    ld hl, (currentMenuGroupId)
    ld (jumpBackMenuGroupId), hl
    ld a, (currentMenuRowIndex)
    ld (jumpBackMenuRowIndex), a
    pop af
    pop hl
    ret
