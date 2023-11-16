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
;   uint8_t id; // root begins with 1
;   uint8_t parentId; // 0 indicates NONE
;   uint8_t nameId; // index into NameTable
;   uint8_t numRows; // 0 if MenuItem; >=1 if MenuGroup
;   union {
;       uint8_t rowBeginId; // nodeId of the first node of first menu row
;       uint8_t altNameId; // alternate name string (if nameSelector!=NULL)
;   }
;   void *handler; // pointer to the handler function
;   void *nameSelector; // function that selects between 2 menu names
; };
;
; sizeof(MenuNode) == 9
;
;-----------------------------------------------------------------------------

; Offsets into the MenuNode struct
menuNodeId equ 0
menuNodeParentId equ 1
menuNodeNameId equ 2
menuNodeNumRows equ 3
menuNodeRowBeginId equ 4
menuNodeAltNameId equ 4
menuNodeHandler equ 5
menuNodeNameSelector equ 7

; sizeof(MenuNode) == 9
menuNodeSizeOf equ 9

; Description: Set initial values for (menuGroupId) and (menuRowIndex).
; Input: none
; Output:
;   (menuGroupId) = mRootId
;   (menuRowIndex) = 0
; Destroys: A, HL
initMenu:
    ld hl, menuGroupId
    ld a, mRootId
    ld (hl), a
    inc hl
    xor a
    ld (hl), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Sanitize the current menuGroup upon application start. This is
; needed when the version of the app that saved its menu state (in RPN83SAV)
; has a different menu hierarchy than the current version of the app. It is
; then possible for the (menuGroupId) to point to a completely different or
; non-existent menuGroup, which causes the menu bar to be rendered incorrectly.
; In the worse case, it may cause the system to hang. This function checks if
; the (menuGroupId) is actually a valid MenuGroup. If not, we reset the menu to
; the ROOT.
;
; The problem would not exist if we incremented the appStateSchemaVersion when
; the menu hierarchy is changed using menudef.txt. But this is easy to forget,
; because changing the menu hierarchy does not change the *layout* of the app
; variables. It only changes the *semantic* meaning of the value stored in the
; (menuGroupId) variable.
;
; Destroys: A, HL, IX
sanitizeMenu:
    ld a, (menuGroupId)
    ; Check valid menuId.
    cp mMenuTableSize
    jr nc, sanitizeMenuReset
    ; Check for MenuGroup.
    call getMenuNodeIX ; IX=menuNode
    ld a, (ix + menuNodeNumRows)
    or a
    jr z, sanitizeMenuReset ; jump if node was a MenuItem
    ; Check menuRowIndex
    ld a, (menuRowIndex)
    cp (ix + menuNodeNumRows)
    ret c
    ; [[fallthrough]] if menuRowIndex >= menuNodeNumRows
sanitizeMenuReset:
    ld a, mRootId
    ld (menuGroupId), a
    xor a
    ld (menuRowIndex), a
    ret

; Description: Return the node id of the first item in the menu row at
; `menuRowIndex` of the current menu node `menuGroupId`. The next 4 node
; ids in sequential order define the other 4 menu buttons.
; Input:
;   - (menuGroupId)
;   - (menuRowIndex)
; Output: A: row begin id
; Destroys: A, B, DE, HL
getCurrentMenuRowBeginId:
    ld hl, menuGroupId
    ld a, (hl) ; menuGroupId
    inc hl
    ld b, (hl) ; menuRowIndex
    ; [[fallthrough]]

; Description: Return the first menu id for menuGroupId A at row index B.
; Input:
;   A: menu id
;   B: row index
; Output: A: row begin id
; Destroys: A, DE, HL
getMenuRowBeginId:
    call getMenuNode ; HL = menuNode
    ; A = menNode.rowBeginId
    inc hl
    inc hl
    inc hl
    inc hl
    ld a, (hl)
    ; A = A + 5*B
    ld e, a
    ld a, b
    add a, a
    add a, a
    add a, b ; 5*B
    add a, e
    ret

; Description: Return the address of the menu node at id A.
; Input: A: menu node id
; Output: HL: address of node
; Destroys: DE, HL
; Preserves: A, BC
getMenuNode:
    push af
    push bc
    bcall(_findMenuNode) ; use bcall() to invoke routine on Flash Page 1
    pop bc
    pop af
    ret

; Description: Return the pointer to the menu node at id A in register IX.
; Input: A: menu node id
; Output: HL, IX: address of node
; Destroys: DE, HL
; Preserves: A, BC
getMenuNodeIX:
    call getMenuNode
    push hl
    pop ix
    ret

; Description: Return the pointer to the name string of the menu node at id A.
; If MenuNode.nameSelector is 0, then the display name is simply the nameId.
; But if the MenuNode.nameSelector is not 0, then it is a pointer to a function
; that returns the display name.
;
; The input to the nameSelector function is:
;   - A,B: normal name
;   - C: alternate name
;   - HL: pointer to MenuNode (in case it is needed)
; The output of the nameSelector is:
;   - A: the selected name
; The name is selected according to the relevant internal state (e.g. DEG or
; RAD). The nameSelector is allowed to modify BC, DE, since they are restored
; before returning from this function. It is also allowed to modify HL since it
; gets clobbered with string pointer before returning from this function.
;
; Input: A: menu node id
; Output: HL: address of the C-string
; Destroys: A, HL
; Preserves: BC, DE
getMenuName:
    push bc
    push de
    call getMenuNode ; HL=(MenuNode)
    push hl ; save the MenuNode pointer
    inc hl
    inc hl
    ld b, (hl) ; B=nameId
    inc hl
    inc hl 
    ld c, (hl) ; C=altNameId
    inc hl
    inc hl
    inc hl
    ld e, (hl)
    inc hl
    ld d, (hl) ; DE=nameSelector
    pop hl ; HL=MenuNode pointer
    ld a, e
    or d ; if DE==0: ZF=1
    ld a, b ; A=nameId
    call nz, jumpDE ; if nameSelector!=NULL: call (DE)
    ; A contains the menu string ID
    bcall(_findMenuString)
    pop de
    pop bc
    ret

;-----------------------------------------------------------------------------

; Description: Dispatch to the handler for the menu node in register A. There
; are 2 cases:
; 1) If the target node is a MenuItem, then the 'onEnter' event is sent to the
; item by invoking its handler.
; 2) If the target node is a MenuGroup, a 'chdir' operation is implemented in 3
; steps:
;   a) The handler of the previous MenuGroup is sent an 'onExit' event,
;   signaled by calling its handlers with the carry flag CF=1.
;   b) The (menuGroupId) and (menuRowIndex) are updated with the target menu
;   group.
;   c) The handler of the traget MenuGroup is sent an 'onEnter' event, signaled
;   by calling its handlers with the carry flag CF=0.
;
; Input: A=target nodeId
; Output:
;   - (menuGroupId) is updated if the target is a MenuGroup
;   - (menuRowIndex) is set to 0 if the target is a MenuGroup
; Destroys: A, B, C, DE, HL, IX
dispatchMenuNode:
    ; get menu node corresponding to pressed menu key
    call getMenuNode
    ld b, a ; save B=target nodeId
    push hl ; save pointer to MenuNode
    ; load mXxxHandler
    inc hl
    inc hl
    inc hl
    ld a, (hl) ; A=numRows
    inc hl
    inc hl
    ld e, (hl)
    inc hl
    ld d, (hl) ; DE=mXxxHandler of the target node
    pop hl ; HL=pointer to target MenuNode
    or a ; if targetNode.numRows == 0: ZF=1
    ld a, b ; A=target nodeId
    jp z, jumpDE

    ; Change into the target menu group.
    ; B=target groupId
    ld c, 0 ; C=rowIndex=0
    jr changeMenuGroup

;-----------------------------------------------------------------------------

; Description: Go up to the parent of the menu group specified by register A.
; Input: A=current groupId
; Output:
;   - (menuGroupId) updated
;   - (menuRowIndex) updated
; Destroys: A, BC, DE, HL
exitMenuGroup:
    ; Check if already at rootGroup
    ld hl, menuGroupId
    ld a, (hl) ; A = menuGroupId
    cp mRootId
    jr nz, exitMenuGroupToParent
    ; If already at rootId, go to menuRow0 if not already there.
    inc hl
    ld a, (hl) ; A = menuRowIndex
    or a
    ret z ; already at rowIndex 0
    xor a ; set rowIndex to 0, set dirty bit
    ld (hl), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret
exitMenuGroupToParent:
    ; Get target groupId and rowIndex of the parent group.
    ld c, a ; save C=menuGroupId=childId
    call getMenuNode ; HL=pointer to current MenuNode
    inc hl
    ld a, (hl) ; A=parentId
    call getMenuNode ; HL=pointer to parent node
    inc hl
    inc hl
    inc hl
    ld d, (hl) ; D=parent.numRows
    inc hl
    ld e, a ; save E=parentId
    ld a, (hl) ; A=parent.rowBeginId
    ; Deduce the parent's rowIndex which matches the childId.
    call deduceRowIndex ; A=rowIndex
    ld c, a ; C=rowIndex
    ld b, e ; B=parentId
    ; [[fallthrough]]

; Description: Change the current menu group to the target menuGroup and
; rowIndex.
; Input:
;   - B=target nodeGroupId
;   - C=target rowIndex
; Output:
;   - (menuGroupId)=target nodeId
;   - (menuRowIndex)=target rowIndex
;   - dirtyFlagsMenu set
; Destroys: A, DE, HL, IX
changeMenuGroup:
    ; Call the onExit handler of the current node.
    ld a, (menuGroupId)
    call getMenuNodeIX
    ld e, (ix + menuNodeHandler)
    ld d, (ix + menuNodeHandler + 1)
    scf ; set CF=1 to invoke onExit handler
    push bc
    call jumpDE
    pop bc
    ; Call the onEnter handler of the target node.
    ld a, c ; A=target rowIndex
    ld (menuRowIndex), a
    ld a, b ; A=target nodeId
    ld (menuGroupId), a
    call getMenuNodeIX
    ld e, (ix + menuNodeHandler)
    ld d, (ix + menuNodeHandler + 1)
    or a ; set CF=0 to invoke onEnter handler
    set dirtyFlagsMenu, (iy + dirtyFlags)
    jp jumpDE

; Description: Deduce the rowIndex location of the childId from the given
; rowBeginId. The `rowIndex = int((childId - rowBeginId)/5)` but the Z80 does
; not have a divison instruction so we use a loop that increments an `index` in
; increments of 5 to determine the corresponding rowIndex.
;
; The complication is that we want to evaluate `(childId < nodeId)` but the
; Z80 instruction can only add to the A register, so we have to store
; the `nodeId` in A and the `childId` in C. Which forces us to reverse the
; comparison. But checking for NC (no carry) is equivalent to a '>='
; instead of a '<', so we are forced to start at `5-1` instead of `5`. I
; hope my future self will understand this explanation.
;
; Input:
;   A: rowBeginId
;   D: numRows
;   C: childId
; Output: A: rowIndex
; Destroys: B; preserves C, DE, HL
deduceRowIndex:
    add a, 4 ; nodeId = rowBeginId + 4
    ld b, d ; B (DJNZ counter) = numRows
deduceRowIndexLoop:
    cp c ; If nodeId < childId: set CF
    jr nc, deduceRowIndexFound ; nodeId >= childId
    add a, 5 ; nodeId += 5
    djnz deduceRowIndexLoop
    ; We should never fall off the end of the loop, but if we do, set the
    ; rowIndex to 0.
    xor a
    ret
deduceRowIndexFound:
    ld a, d ; numRows
    sub b ; rowIndex = numRows - B
    ret
