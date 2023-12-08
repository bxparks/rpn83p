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

;------------------------------------------------------------------------------

; Description: Return the number of digits which are accepted or displayed for
; the given (baseWordSize) and (baseNumber).
;   - no BASE: inputBufMax
;   - BASE 2: numDigits = min(baseWordSize, inputBufMax)
;       - 8 -> 8
;       - 16 -> 16
;       - 24 -> 24
;       - 32 -> 32
;   - BASE 8: numDigits = ceil(baseWordSize / 3)
;       - 8 -> 3 (0o377)
;       - 16 -> 6 (0o177 777)
;       - 24 -> 8 (0o77 777 777)
;       - 32 -> 11 (0o37 777 777 777)
;   - BASE 10:
;       - 8 -> 3 (255)
;       - 16 -> 5 (65 535)
;       - 24 -> 8 (16 777 215)
;       - 32 -> 10 (4 294 967 295)
;   - BASE 16: numDigits = baseWordSize / 4
;       - 8 -> 2 (0xff)
;       - 16 -> 4 (0xff ff)
;       - 24 -> 6 (0xff ff ff)
;       - 32 -> 8 (0xff ff ff ff)
;
; This version uses a lookup table to make the above transformations. Another
; way is to use a series of nested if-then-else statements (i.e. a series of
; 'cp' and 'jr nz' statements in assembly language). The nested if-then-else
; actually turned out to be about 80 bytes *smaller*. However, the if-then-else
; version is so convoluted that it is basically unreadable and unmaintainable.
; Use the lookup table implementation instead even though it takes up slightly
; more space.
;
; Input: rpnFlagsBaseModeEnabled, (baseWordSize), (baseNumber).
; Output: A: numDigits
; Destroys: A
; Preserves: BC, DE, HL
GetWordSizeDigits:
    ; If floating point mode (not BASE) mode, return the normal maximum.
    bit rpnFlagsBaseModeEnabled, (iy + rpnFlags)
    jr nz, getWordSizeDigitsBaseMode
    ld a, inputBufNormalMaxLen
    ret
getWordSizeDigitsBaseMode:
    ; If BASE mode, the maximum number of digits depends on baseNumber and
    ; baseWordSize.
    push de
    push hl
    call getBaseNumberIndex ; A=baseNumberIndex
    sla a
    sla a ; A=baseNumberIndex * 4
    ld e, a
    call getWordSizeIndexPageOne ; A=wordSizeIndex
    add a, e ; A=4*baseNumberIndex+wordSizeIndex
    ld e, a
    ld d, 0
    ld hl, wordSizeDigitsArray
    add hl, de
    ld a, (hl)
    pop hl
    pop de
    ret

; List of the inputDigit limit of the inputBuf for each (baseNumber) and
; (baseWordSize). Each group of 4 represents the inputDigits for wordSizes (8,
; 16, 24, 32) respectively.
wordSizeDigitsArray:
    .db 8, 16, 24, 32 ; base 2
    .db 3, 6, 8, 11 ; base 8
    .db 3, 5, 8, 10 ; base 10
    .db 2, 4, 6, 8 ; base 16

;------------------------------------------------------------------------------

; Description: Convert the u8 in A to floating pointer number in OP1.
; Input:
;   - A: u8 integer
; Output:
;   - OP1: floating point value of A
; Destroys: A, B, DE, OP2
; Preserves: C, HL
convertU8ToOP1PageOne:
    push af
    bcall(_OP1Set0)
    pop af
    ; [[fallthrough]]

; Description: Convert the u8 in A to floating point number, and add it to OP1.
; Input:
;   - A: u8 integer
;   - OP1: current floating point value, set to 0.0 to start fresh
; Destroys: A, B, DE, OP2
; Preserves: C, HL
addU8ToOP1PageOne:
    push hl
    ld b, 8 ; loop for 8 bits in u8
addU8ToOP1PageOneLoop:
    push bc
    push af
    bcall(_Times2) ; OP1 *= 2
    pop af
    sla a
    jr nc, addU8ToOP1PageOneCheck
    push af
    bcall(_Plus1) ; OP1 += 1
    pop af
addU8ToOP1PageOneCheck:
    pop bc
    djnz addU8ToOP1PageOneLoop
    pop hl
    ret
