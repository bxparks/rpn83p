;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Routines to access the menudef.asm data structure in flash page 1.
;
; Capitalized labels are intended to be exported to the branch table on flash
; page 0. Lowercased labels are intended to be local to the current flash page.
;-----------------------------------------------------------------------------

; Description: Find the MenuNode identified by menuId, and copy it into
; (menuNodeBuf). No bounds checking is performed.
; Input:
;   - HL=menuId
; Output:
;   - HL=menuNodeBuf
;   - (menuNodeBuf) contains copy of the matching MenuNode
; Destroys: all
FindMenuNode:
    ; HL=menuId*sizeof(MenuNode)=menuId*13=menuId*(8+4+1)
    ld c, l
    ld b, h ; BC=menuId
    add hl, hl
    add hl, hl ; HL=4*menuId
    ld e, l
    ld d, h ; DE=4*menuId
    add hl, hl ; 8*menuId
    add hl, de ; 12*menuId
    add hl, bc ; 13*menuId
    ; HL=mMenuTable+13*menuId
    ld de, mMenuTable
    add hl, de
    ; Copy it to (menuNodeBuf)
    ld de, menuNodeBuf
    ld bc, menuNodeSizeOf
    ldir
    ld hl, menuNodeBuf
    ret

; Description: Copy the menu name identified by the id in HL into
; (menuStringBuf). (The (menuNameBuf) is a Pascal-string used to determine the
; pixel width of the menu.)
; Input:
;   - HL: menuNameId
; Output:
;   - HL=menuStringBuf
;   - (menuStringBuf) contains a copy of the matching string.
; Destroys: all
FindMenuString:
    ex de, hl ; DE=menuNameId
    ld hl, mMenuNameTable
    call getDEStringPageOne ; HL:(const char*)=name
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
