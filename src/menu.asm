;-----------------------------------------------------------------------------
; Routines to display menus and read the 5 top-row keys corresponding to the
; menus.
;-----------------------------------------------------------------------------

; getMenuNode(A) -> HL
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
; Description: Return the pointer to the name string of the menu node at id A.
; Input: A: menu node id
; Output: HL: address of the C-string
; Destroys: DE, HL
getMenuName:
    ld hl, mMenuNameTable
    jp getString
