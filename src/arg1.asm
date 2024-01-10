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

; Description: Parse the contents of the Pascal string argBuf (potentially an
; empty string, 1-2 digits, or a letter) into (argType) and (argValue).
; Input: argBuf
; Output:
;   - (argType) updated
;   - (argValue) updated
; Destroys: A, B, C, DE, HL
ParseArgBuf:
    ; set argType and argValue initially to empty string
    ld de, argType
    xor a
    ld (de), a ; argType=argTypeEmpty
    inc de
    ld (de), a ; argValue=0; DE=pointer to argValue
    ; check for empty string
    ld hl, argBuf
    ld a, (hl) ; A=argBufLen
    inc hl
    or a
    ret z
    ld b, a ; B=argBufLen
    ; check for A-Z,Theta
    ld a, (hl)
    call isVariableLetter ; CF=1 if varLetter
    jr nc, parseArgBufDigits
    ; here if A is letter
    ld (de), a ; argValue=char
    dec de
    ld a, argTypeLetter
    ld (de), a ; argType=argTypeLetter
    ret
parseArgBufDigits:
    ld c, 0 ; sum=0
    dec b ; B=argBufLen-1
    jr z, parseArgBufOneDigit
parseArgBufTwoDigits:
    call parseArgBufAddDigit ; C=sum=sum+u8(HL++)
    ; C=C*10=(C*5)*2
    ld a, c
    add a, a
    add a, a
    add a, c ; A = 5 * C
    add a, a
    ld c, a
parseArgBufOneDigit:
    call parseArgBufAddDigit ; C=sum=sum+u8(HL++)
    ld a, c
    ld (de), a ; argValue=sum
    dec de
    ld a, argTypeNumber
    ld (de), a ; argType=argTypeNumber
    ret

; Description: Add numerical value of char in (hl) to sum 'C'.
; Input: HL: pointer to char; C: sum
; Output: C=C+u8(HL); HL=HL+1
; Destroys; A
parseArgBufAddDigit:
    ld a, (hl)
    inc hl
    sub '0'
    add a, c
    ld c, a ; sum+=u8(HL)
    ret

; Description: Check if the character in 'A' is a TI-OS variable (A-Z, Theta).
; Input: A: char
; Output: CF=1 if valid
; Preserves: all
isVariableLetter:
    cp tA ; if A<'A': CF=1
    jr c, isVariableLetterFalse
    cp tTheta ; if A<='Theta': CF=1
    ret c
isVariableLetterFalse:
    or a ; CF=0
    ret
