;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Routines for navigating the singly-rooted tree of MenuNodes. A MenuNode can
; be either a MenuItem or MenuGroup. A MenuGroup is a list of one or more
; MenuStrip. A MenuStrip is a list of exactly 5 MenuNodes, corresponding to the
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
;   uint8_t numStrips; // 0 if MenuItem; >=1 if MenuGroup
;   uint8_t stripBeginId; // nodeId of the first node of first strip
;   void *handler; // pointer to the handler function
; };
;
; sizeof(MenuNode) == 7
;
;-----------------------------------------------------------------------------

; Description: Set initial values for (menuGroupId) and (menuStripIndex).
; Input: none
; Output:
;   (menuGroupId) = mRootId
;   (menuStripIndex) = 0
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

; Description: Return the node id of the first item in the menu strip at
; `menuStripIndex` of the current menu node `menuGroupId`. The next 4 node
; ids in sequential order define the other 4 menu buttons.
; Input:
;   - (menuGroupId)
;   - (menuStripIndex)
; Output: A: strip begin id
; Destroys: A, B, DE, HL
getCurrentMenuStripBeginId:
    ld hl, menuGroupId
    ld a, (hl)
    inc hl
    ld b, (hl)
    ; [[fallthrough]]

; Description: Return the first menu id for menuGroupId A at strip index B.
; Input:
;   A: menu id
;   B: strip index
; Output: A: strip begin id
; Destroys: A, DE, HL
getMenuStripBeginId:
    call getMenuNode ; HL = menuNode

    ; A = menNode.stripBeginId
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
    ; HL = A * sizeof(MenuNode) = 7*A
    ld l, a
    ld h, 0
    ld e, l
    ld d, h
    add hl, hl
    add hl, hl
    add hl, hl ; 8*A
    or a ; clear CF
    sbc hl, de ; 7*A
    ; HL = mMenuTable + 7*A
    ex de, hl
    ld hl, mMenuTable
    add hl, de
    ret

; Description: Return the pointer to the name string of the menu node at id A.
; Input: A: menu node id
; Output: HL: address of the C-string
; Destroys: A, HL
; Preserves: DE
getMenuName:
    push de
    call getMenuNode
    inc hl
    inc hl
    ld a, (hl) ; nameId
    ld hl, mMenuNameTable
    call getString
    pop de
    ret
