;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Routines to access the menudef.asm data structure in flash page 1.
;
; Capitalized labels are intended to be exported to the branch table on flash
; page 0. Lowercased labels are intended to be local to the current flash page.
;-----------------------------------------------------------------------------

; Description: Copy the MenuNode matching the menuId in A into (menuNodeBuf).
; No bounds checking is performed.
; Input: A: menuId
; Output:
;   - HL=menuNodeBuf
;   - (menuNodeBuf) contains copy of the matching MenuNode
; Destroys: all
FindMenuNode:
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
    ; Copy it to (menuNodeBuf)
    ld de, menuNodeBuf
    ld bc, menuNodeSizeOf
    ldir
    ld hl, menuNodeBuf
    ret

; Description: Copy the menu name identified by the id in 'A' into
; (menuStringBuf). (The (menuNameBuf) is a Pascal-string used to determine the
; pixel width of the menu.)
; Input: A: menuNameId
; Output:
;   - HL=menuStringBuf
;   - (menuStringBuf) contains a copy of the matching string.
; Destroys: all
FindMenuString:
    ld hl, mMenuNameTable
    call getStringOnPage1 ; HL=name string
copyToMenuStringBuf:
    ; Copy the name to (menuStringBuf)
    ld de, menuStringBuf
    ld b, 6 ; at most 6 bytes, including NUL terminator
findMenuStringLoop:
    ld a, (hl)
    ld (de), a
    inc hl
    inc de
    or a
    jr z, findMenuStringEnd
    djnz findMenuStringLoop
    ; Clobber the last byte with NUL to terminate the C-string
    dec de
    xor a
    ld (de), a
findMenuStringEnd:
    ld hl, menuStringBuf
    ret
