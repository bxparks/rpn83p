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
; register after calling findMenuNodeIX().
menuNodeFieldId equ 0
menuNodeFieldParentId equ 2
menuNodeFieldNameId equ 4
menuNodeFieldNumRows equ 6
menuNodeFieldRowBeginId equ 7
menuNodeFieldAltNameId equ 7
menuNodeFieldHandler equ 9
menuNodeFieldNameSelector equ 11

;-----------------------------------------------------------------------------
; These routines cannot be moved into menu1.asm because they invoke callback
; functions which are defined on Flash Page 0.
;-----------------------------------------------------------------------------

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
; Input:
;   - HL:u16=menuId
; Output:
;   - A:u8=numRows (>1 if menuFolder)
;   - HL:(const char*)=menuName
; Destroys: A, HL, OP3, OP4
; Preserves: BC, DE
getMenuName:
    push bc ; stack=[BC]
    push de ; stack=[BC,DE]
    ld bc, OP3
    ld de, OP4
    bcall(_ExtractMenuNames) ; A=numRows; BC=altName; DE=normalName; HL=selector
    push af ; stack=[BC,DE,numRows]
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
    pop af ; stack=[BC,DE]; A=numRows
    pop de ; stack=[BC]
    pop bc ; stack=[]
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
    bcall(_GetMenuNodeHandler) ; A=numRows; DE=handler; IX=menuNode; HL=HL
    ; Invoke a MenuItem.
    or a ; if numRows == 0: ZF=1 (i.e. a MenuItem)
    jp z, jumpDE ; Invoke menuHandler().
    ; Item was a menuGroup, so change into the target menu group. First clear
    ; the jumpBack registers. Then invoke changeMenuGroup().
    bcall(_ClearJumpBack)
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
    bcall(_GetMenuNodeHandler) ; A=numRows; DE=handler; IX=menuNode; HL=HL
    ; Invoke a MenuItem.
    or a ; if numRows == 0: ZF=1 (i.e. a MenuItem)
    jp z, jumpDE ; Invoke menuHandler().
    ; Item was a menuGroup, so change into the target menu group. First, update
    ; the jumpBack registers if target is different than current. Then invoke
    ; changeMenuGroup().
    ld de, (currentMenuGroupId)
    call cpHLDE ; ZF=1 if targetNodeId==currentMenuGroupId
    jr z, dispatchMenuNodeWithJumpBackChange
    bcall(_SaveJumpBack)
dispatchMenuNodeWithJumpBackChange:
    xor a ; A=rowIndex=0
    jr changeMenuGroup

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
    bcall(_ClearJumpBack)
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
    bcall(_GetMenuNodeParent) ; A=numRows; DE=parentId; IX=menuNode
    ex de, hl ; HL=parentId
    push hl ; stack=[childId,parentId]
    bcall(_GetMenuNodeRowBeginId) ; A=numRows; DE=rowBeginId; IX=parentMenuNode
    ; Deduce the parent's rowIndex which matches the childId.
    pop hl ; stack=[childId]; HL=parentId
    ex (sp), hl ; stack=[parentId]; HL=childId
    call deduceRowIndex ; A=rowIndex
    pop hl ; stack=[]; HL=parentId
    jr changeMenuGroup

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
;   - A=parentNumRows
;   - DE=parentRowBeginId
;   - HL=childId
; Output:
;    - A=rowIndex
; Destroys: A, BC, DE
; Preserves: HL
deduceRowIndex:
    ld b, a ; B=numRows
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
    push af ; stack=[targetRowIndex]
    push hl ; stack=[targetRowIndex,targetMenuGroupId]
    ; 1) Invoke the onExit() handler of the previous MenuGroup by setting CF=1.
    ld hl, (currentMenuGroupId)
    bcall(_GetMenuNodeHandler) ; A=numRows; DE=handler; IX=menuNode; HL=HL
    scf ; CF=1 means "onExit()" event
    call jumpDE
    ; 2) Invoke the onEnter() handler of the target MenuGroup by setting CF=0.
    pop hl ; stack=[targetRowIndex]; HL=targeMenuGroupId
    pop af ; stack=[]; A=targetRowIndex
    ld (currentMenuRowIndex), a
    ld (currentMenuGroupId), hl
    bcall(_GetMenuNodeHandler) ; A=numRows; DE=handler; IX=menuNode; HL=HL
    or a ; set CF=0
    set dirtyFlagsMenu, (iy + dirtyFlags)
    jp jumpDE
