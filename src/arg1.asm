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

;------------------------------------------------------------------------------

; Description: Parse the contents of the Pascal string argBuf (potentially an
; empty string, 1-N digits, or a letter) into (argType) and (argValue).
; Input:
;   - argBuf
; Output:
;   - (argType) updated
;   - (argValue) updated
; Destroys: A, B, C, DE, HL
ParseArgBuf:
    ; set argType and argValue initially to empty string
    ld a, argTypeEmpty
    ld (argType), a ; argType=argTypeEmpty
    xor a
    ld (argValue), a ; argValue=0
    ; prepare argBuf for parsing
    ld hl, argBuf
    call preparePascalStringForParsing ; preserves HL
    inc hl ; skip len byte
    ; peek at the first character
    ld a, (hl) ; A=firstChar, will be NUL if empty
    or a
    ret z ; return if NUL
    ; parse the different argument type (numerical, varLetter)
    call isVariableLetter ; CF=1 if varLetter
    jr c, parseArgBufLetter
    call isValidUnsignedDigit ; CF=1 if 0-9
    jr c, parseArgBufDigits
parseArgBufInvalid:
    ld a, argTypeInvalid
    ld (argType), a
    ret

; Description: Parse the single letter in argBuf into argType and argValue.
; Input:
;   - HL:(char*)=pointer into argBuf
; Output:
;   - (argType)=argTypeLetter or argTypeInvalid
;   - (argValue)=char(argBuf[0])
;   - HL=points to NUL at end of argBuf
parseArgBufLetter:
    ld a, (hl)
    inc hl
    ld (argValue), a ; argValue=char
    ld a, argTypeLetter
    ld (argType), a ; argType=argTypeLetter
    ; make sure there is only a single letter
    ld a, (hl)
    or a
    jr nz, parseArgBufInvalid
    ret

; Description: Parse the numerals in argBuf into argScanner.argType and
; argValue.
; Input:
;   - HL:(char*)=pointer into argBuf
; Output:
;   - (argType)=argTypeNumber or argTypeInvalid
;   - (argValue)=u8(argBuf)
;   - HL=points to NUL at end of argBuf
parseArgBufDigits:
    ld c, 0 ; sum=0
parseArgBufDigitsLoop:
    ld a, (hl)
    or a
    jr z, parseArgBufDigitsEnd ; if NUL: end loop
    inc hl
    call isValidUnsignedDigit ; CF=1 if 0-9
    jr nc, parseArgBufInvalid
    ld b, a ; B=digit
    ; sum=sum*10
    ld a, c
    add a, a
    add a, a
    add a, c ; A=5*C
    add a, a ; A=10*C
    ld c, a
    ; add digit
    ld a, b ; A=digit
    sub '0'
    add a, c
    ld c, a ; sum+=u8(digit)
    jr parseArgBufDigitsLoop
parseArgBufDigitsEnd:
    ; update argValue, argType
    ld a, c
    ld (argValue), a ; argValue=sum
    ld a, argTypeNumber
    ld (argType), a ; argType=argTypeNumber
    ret
