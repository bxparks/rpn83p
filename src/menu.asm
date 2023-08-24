;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
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
;       uint8_t altNameId; // alternate name string
;   }
;   void *handler; // pointer to the handler function
;   void *nameSelector; // function that selects between 2 menu names
; };
;
; sizeof(MenuNode) == 9
;
;-----------------------------------------------------------------------------

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
    ld a, (hl)
    inc hl
    ld b, (hl)
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
getMenuNode:
    ; HL = A * sizeof(MenuNode) = 9*A
    ld l, a
    ld h, 0
    ld e, l
    ld d, h
    add hl, hl
    add hl, hl
    add hl, hl ; 8*A
    add hl, de ; 9*A
    ; HL = mMenuTable + 9*A
    ex de, hl
    ld hl, mMenuTable
    add hl, de
    ret

; Description: Return the pointer to the name string of the menu node at id A.
; If MenuNode.get_name is 0, then the display name is simply the nameId. But
; if the MenuNode.get_name is not 0, then it is a pointer to a function that
; returns the display name.
; Input: A: menu node id
; Output: HL: address of the C-string
; Destroys: A, HL
; Preserves: BC, DE
getMenuName:
    push bc
    push de
    push hl
    call getMenuNode ; HL=(MenuNode)
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
    ld a, e
    or d
    ld a, b ; A=nameId
    pop hl
    jr z, getMenuNameDefault ; if nameSelector==0: goto default
getMenuNameCustom:
    ; The following ugly hack is required because the Z80 does not have a `call
    ; (hl)` instruction, analogous to `jp (hl)`. The nameSelector(BC, HL) -> A
    ; selects one of the 2 strings (B or C), and returns the selection in A.
    push hl ; MenuNode
    ld hl, getMenuNameDefault ; the return address
    ex (sp), hl ; (SP)=return address, HL=MenuNode
    push de ; nameSelector
    ret ; jp (de)
getMenuNameDefault:
    ; A contains the menu string ID
    ld hl, mMenuNameTable
    call getString ; HL=name string
    pop de
    pop bc
    ret
