;-----------------------------------------------------------------------------
; Routines to display menus and read the 5 top-row keys corresponding to the
; menus. The equilvanet C struct for each MenuNode is the following:
;
; struct MenuNode {
; 	u8 id; // root begins with 1
; 	u8 parentId; // 0 indicates NONE
; 	u8 nameId; // index into NameTable
; 	u8 numStrips; // 0: Item; >=1: Group
; 	u8 stripBeginId; // nodeId of the first node of first strip
; };
;
;-----------------------------------------------------------------------------

; initMenu() -> None
;
; Description: Set initial values for (menuCurrentId) and (menuStripIndex).
; Output:
;   (menuCurrentId) = mRootId
;   (menuStripIndex) = 0
; Destroys: A, HL
initMenu:
    ld hl, menuCurrentId
    ld a, mRootId
    ld (hl), a
    inc hl
    xor a
    ld (hl), a
    ret

; getCurrentMenuStripBeginId(menuCurrentId, menuStripIndex) -> None
;
; Description: Return the node id of the first item in the menu strip at
; `menuStripIndex` of the current menu node `menuCurrentId`. The next 4 node
; ids in sequential order define the other 4 menu buttons.
; Input: (menuCurrentId), (menuStripIndex)
; Output: A: strip begin id
; Destroys: A, DE, HL
getCurrentMenuStripBeginId:
    ld hl, menuCurrentId
    ld a, (hl)
    inc hl
    ld b, (hl)
    ; [[fallthrough]]

; getMenuBeginNode(A, B) -> A
;
; Description: Return the menu node id for menuCurrentId A, strip index B.
; Input:
;   A: menu id
;   B: strip index
; Output: A: strip begin id
; Destroys: A, DE, HL
getMenuStripBeginId:
    ; HL = menuNode
    call getMenuNode
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

; getMenuNode(A) -> HL
;
; Description: Return the address of the menu node at id A.
; Input: A: menu node id
; Output: HL: address of node
; Destroys: DE, HL
getMenuNode:
    ; HL = A * 5
    ld l, a
    ld h, 0
    ld e, l
    ld d, h
    add hl, hl
    add hl, hl
    add hl, de
    ; HL = mMenuTable + 5*A
    ex de, hl
    ld hl, mMenuTable
    add hl, de
    ret

; getMenuName(A) -> HL
;
; Description: Return the pointer to the name string of the menu node at id A.
; Input: A: menu node id
; Output: HL: address of the C-string
; Destroys: DE, HL
getMenuName:
    call getMenuNode
    inc hl
    inc hl
    ld a, (hl) ; nameId
    ld hl, mMenuNameTable
    jp getString
