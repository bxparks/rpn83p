;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Functions related to parsing the argBuf into an integer argument. Currently,
; argBuf is set to be identical to inputBuf, to save RAM, but it can be
; separated out if needed.
;
; This is now on Flash Page 1. Labels with Capital letters are intended to be
; exported to other flash pages and should be placed in the branch table on
; Flash Page 0. Labels with lowercase letters are intended to be private so do
; not need a branch table entry.
;------------------------------------------------------------------------------

ClearArgBuf:
    xor a
    ld (argBuf), a
    ; [[fallthrough]]
InitArgBuf:
    res rpnFlagsArgMode, (iy + rpnFlags)
    ret

; Description: Append character in A to the argBuf.
; Input:
;   - A: character to append
; Output:
;   - dirtyFlagsInput set
; Destroys: all
AppendArgBuf:
    set dirtyFlagsInput, (iy + dirtyFlags)
    ld hl, argBuf
    ld b, a
    ld a, (hl)
    cp argBufSizeMax
    ret nc ; limit total number of characters
    ld a, b
    ld b, argBufCapacity
    jp AppendString

; Description: Convert (0 to 2 digit) argBuf into an integer.
; Input: argBuf
; Output: A: value of argBuf
; Destroys: A, B, C, HL
ParseArgBuf:
    ld hl, argBuf
    ld b, (hl) ; B = argBufLen
    inc hl
    ; check for 0 digit
    ld a, b
    or a
    ret z
    ; A = current sum
    xor a
    ; check for 1 digit
    dec b
    jr z, parseArgBufOneDigit
parseArgBufTwoDigits:
    call parseArgBufOneDigit
    ; C = C * 10 = C * (2 * 5)
    ld c, a
    add a, a
    add a, a
    add a, c ; A = 5 * C
    add a, a
parseArgBufOneDigit:
    ld c, a
    ld a, (hl)
    inc hl
    sub '0'
    add a, c
    ret ; A = current sum
