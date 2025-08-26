;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Various classifiers of a particular character for use in parsing.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;------------------------------------------------------------------------------


; Description: Check if the character in A is a valid floating point digit
; which may be in scientific notation ('0' to '9', '-', '.', and 'E').
; Input: A: character
; Output: CF=1 if valid, 0 if not
; Destroys: none
isValidScientificDigit:
    cp Lexponent
    jr z, isValidDigitTrue
    ; [[fallthrough]]

; Description: Check if the character in A is a valid floating point digit ('0'
; to '9', '-', '.').
; Input: A: character
; Output: CF=1 if valid, 0 if not
; Destroys: none
isValidFloatDigit:
    cp '.'
    jr z, isValidDigitTrue

; Description: Check if the character in A is a valid signed integer ('0' to
; '9', '-').
; Input: A: character
; Output: CF=1 if valid, 0 if not
; Destroys: none
isValidSignedDigit:
    cp signChar ; '-'
    jr z, isValidDigitTrue
    ; [[fallthrough]]

; Description: Check if the character in A is a valid unsigned integer ('0' to
; '9').
; Input: A: character
; Output: CF=1 if valid, 0 if not
; Destroys: none
isValidUnsignedDigit:
    cp '0' ; if A<'0': CF=1
    jr c, isValidDigitFalse
    cp ':' ; if A<='9': CF=1
    ret c
    ; [[fallthrough]]

isValidDigitFalse:
    or a ; CF=0
    ret
isValidDigitTrue:
    scf ; CF=1
    ret

;-----------------------------------------------------------------------------

; Description: Check if the character in A is a TI-OS variable ('A'-'Z',
; 'tTheta').
; Input: A: char
; Output: CF=1 if valid
; Preserves: all
isVariableLetter:
    cp tA ; if A<'A': CF=1
    jr c, isVariableLetterFalse
    cp tTheta+1 ; if A<='Theta': CF=1
    ret
isVariableLetterFalse:
    or a ; CF=0
    ret

;-----------------------------------------------------------------------------

; Description: Check if the character in A is a Duration object short-hand
; character, i.e. 'D', 'H', 'M', 'S'.
; Input: A: char
; Output: CF=1 if valid
; Preserves: all
isDurationLetter:
    cp 'D'
    jr z, isValidDigitTrue
    cp 'H'
    jr z, isValidDigitTrue
    cp 'M'
    jr z, isValidDigitTrue
    cp 'S'
    jr z, isValidDigitTrue
    or a ; CF=0
    ret
