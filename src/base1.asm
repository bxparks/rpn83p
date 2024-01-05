;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Functions related to base.asm in Flash Page 1.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;------------------------------------------------------------------------------

; Description: Return the index corresponding to each of the potential values
; of (baseWordSize). For the values of (8, 16, 24, 32) this returns (0, 1, 2,
; 3). This is the same as getWordSizeIndex() but located in Flash Page 1.
;
; Input: (baseWordSize)
; Output: A=(baseWordSize)/8-1
; Throws: Err:Domain if not 8, 16, 24, 32.
; Destroys: A
; Preserves: BC, DE, HL
getWordSizeIndexPageOne:
    push bc
    ld a, (baseWordSize)
    ld b, a
    and $07 ; 0b0000_0111
    jr nz, getWordSizeIndexPageOneErr
    ld a, b
    rrca
    rrca
    rrca
    dec a
    ld b, a
    and $FC ; 0b1111_1100
    ld a, b
    pop bc
    ret z
getWordSizeIndexPageOneErr:
    bcall(_ErrDomain)

;------------------------------------------------------------------------------

; Description: Return the index corresponding to the potential values of
; (baseNumber). For the values (2, 8, 10, 16) this returns (0, 1, 2, 3).
; Input: (baseWordSize)
; Output: A=one of (0, 1, 2, 3)
; Throws: Err:Domain if not 8, 16, 24, 32.
; Destroys: A
; Preserves: BC, DE, HL
getBaseNumberIndex:
    ; Note: The order of the conditionals below is 16, 10, 8, 2, which is
    ; roughly in descending order of expected usage. In other words, we expect
    ; BASE 16 to be most frequently used.
    ld a, (baseNumber)
    cp 16
    jr nz, getBaseNumberIndexNot16
    ld a, 3
    ret
getBaseNumberIndexNot16:
    cp 10
    jr nz, getBaseNumberIndexNot10
    ld a, 2
    ret
getBaseNumberIndexNot10:
    cp 8
    jr nz, getBaseNumberIndexNot8
    ld a, 1
    ret
getBaseNumberIndexNot8:
    cp 2
    jr nz, getBaseNumberIndexErr
    xor a
    ret
getBaseNumberIndexErr:
    bcall(_ErrDomain)
