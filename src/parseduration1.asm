;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2025 Brian T. Park
;
; Functions related to parsing a compact Duration object of the form
; '[-][{i16}D][{i8}H][{i8}M][{i8}S]'.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;------------------------------------------------------------------------------

; Description: Check if the given inputBuf is a Duration object in compact form.
; Input:
;   - HL:(PascalString*)=inputBuf
; Output:
;   - CF=1 if a compact Duration object
; Destroys: A, B
; Preserves: C, DE, HL
checkCompactDuration:
    ; check for empty string
    ld a, (hl) ; A=stringSize
    or a
    ld b, a ; B=stringSize
    ret z ; return on empty string with CF=0
    push hl
checkCompactDurationLoop:
    inc hl
    ld a, (hl)
    call isDurationLetter ; CF=1 if one of [D,H,M,S]
    jr c, checkCompactDurationFound
    djnz checkCompactDurationLoop
checkCompactDurationFound:
    pop hl
    ret

;------------------------------------------------------------------------------

; Description: Parse a compact Duration object of the form "1D2H3M4S" with
; each component being unique but optional. (Duplicate component not allowed).
; Input:
;   - HL:(char*)=string
;   - DE:Duration=duration
; Output:
;   - (*DE):Duration filled
; Throws: Err:Syntax if there are trailing characters
; Destroys: all
parseCompactDuration:
    call clearCompactDurationBuf
    call parseCompactDurationSign ; updates parseDurationBufSign, HL
    ld b, 4
parseCompactDurationLoop:
    ; Check for end of string
    ld a, (hl)
    or a
    jr z, parseCompactDurationLoopBreak
    ; Check for up to 4 unique components of the form "{u16}{letter}"
    push de
    ld de, parseDurationBufCurrent
    call parseU16D4 ; (DE)=u16; HL=next char; preserves BC
    pop de
    ; Look for modifier
    call parseCompactDurationDelimiter ; A=modifier
    ; Update parseDurationBufXxx
    call updateCompactDurationComponent
    djnz parseCompactDurationLoop
parseCompactDurationLoopBreak:
    ; Copy parseDurationBuf into DE=Duration
    call copyCompactDurationBufIntoDuration
    ; Check for negative sign '-'
    ld a, (parseDurationBufFlags)
    bit parseDurationBufFlagSign, a
    ret z
    ; Invert the Duration object
    ex de, hl ; HL=Duration
    call chsDurationPageOne
    ret

; Description: Copy the fields in parseDurationBuf into the Duration
; pointed by DE.
; Input:
;   - DE:Duration
;   - (parseDurationBuf): contains parsed Duration fields
; Output:
;   - DE:Duration filled in from parseDurationBuf
; Destroys: A
; Preserves: DE, BC, HL
copyCompactDurationBufIntoDuration:
    push de
    push hl
    ld hl, parseDurationBufDays
    ; daysLow
    ld a, (hl)
    ld (de), a
    inc hl
    inc de
    ; daysHigh
    ld a, (hl)
    ld (de), a
    inc hl
    inc de
    ; hours
    ld a, (hl)
    ld (de), a
    inc hl
    inc hl
    inc de
    ; minutes
    ld a, (hl)
    ld (de), a
    inc hl
    inc hl
    inc de
    ; seconds
    ld a, (hl)
    ld (de), a
    inc hl
    inc hl
    inc de
    ;
    pop hl
    pop de
    ret

; Description: Update the u16 in (parseDurationBufCurrent) to the appropriate
; 'parseDurationBuf' field, depending on the modifier value in register A.
; Input:
;   - A:char=modifier
;   - (parseDurationBufCurrent):u16=value
; Output:
;   - (parseDurationBufXXX) updated
; Preserves:
;   - all
updateCompactDurationComponent:
    push hl ; stack=[HL]
    ld hl, parseDurationBufFlags
    cp 'D'
    jr z, updateCompactDurationComponentD
    cp 'H'
    jr z, updateCompactDurationComponentH
    cp 'M'
    jr z, updateCompactDurationComponentM
    cp 'S'
    jr z, updateCompactDurationComponentS
    jr parseCompactDurationSyntaxErr ; should never happen unless buggy
updateCompactDurationComponentD:
    ; Check for duplicate 'D'
    bit parseDurationBufFlagDays, (hl)
    jr nz, parseCompactDurationSyntaxErr
    set parseDurationBufFlagDays, (hl)
    ; Move the u16 into appropriate field
    ld hl, (parseDurationBufCurrent)
    ld (parseDurationBufDays), hl
    pop hl ; stack=[]
    ret
updateCompactDurationComponentH:
    ; Check for duplicate 'H'
    bit parseDurationBufFlagHours, (hl)
    jr nz, parseCompactDurationSyntaxErr
    set parseDurationBufFlagHours, (hl)
    ; Move the u8 into appropriate field
    ld hl, (parseDurationBufCurrent)
    call checkHLIsU8
    ld (parseDurationBufHours), hl
    pop hl ; stack=[]
    ret
updateCompactDurationComponentM:
    ; Check for duplicate 'M'
    bit parseDurationBufFlagMinutes, (hl)
    jr nz, parseCompactDurationSyntaxErr
    set parseDurationBufFlagMinutes, (hl)
    ; Move the u8 into appropriate field
    ld hl, (parseDurationBufCurrent)
    call checkHLIsU8
    ld (parseDurationBufMinutes), hl
    pop hl ; stack=[]
    ret
updateCompactDurationComponentS:
    ; Check for duplicate 'S'
    bit parseDurationBufFlagSeconds, (hl)
    jr nz, parseCompactDurationSyntaxErr
    set parseDurationBufFlagSeconds, (hl)
    ; Move the u8 into appropriate field
    ld hl, (parseDurationBufCurrent)
    call checkHLIsU8
    ld (parseDurationBufSeconds), hl
    pop hl ; stack=[]
    ret

; Description: Check that (HL) is a u8 number, not a u16 number.
; Input: HL:u16 or u8
; Destroys: none
; Throws: Err:Syntax if u16
checkHLIsU8:
    push af
    ld a, h
    or a
    jr nz, parseCompactDurationInvalidErr
    pop af
    ret

parseCompactDurationInvalidErr:
    bcall(_ErrInvalid)

; Description: Read the modifier suffix in the string, which must be 'D', 'H',
; 'M', or 'S'.
; Input:
;   - HL:(char*)=string
; Output:
;   - HL=HL+1
;   - A=char
; Destroys: A
; Throws:
;   - Err:Syntax if next letter not in DHMS
parseCompactDurationDelimiter:
    ld a, (hl)
    inc hl
    or a
    jr z, parseCompactDurationSyntaxErr
    call isDurationLetter
    ret c
    ; [[fallthrough]]

parseCompactDurationSyntaxErr:
    bcall(_ErrSyntax)

;------------------------------------------------------------------------------

; Description: Parse the optional negative sign at the start of the Duration.
; Input:
;   - HL:(const char*)=inputBuf
; Output:
;   - HL=point to char after optional sign
;   - (parseDurationBufFlagSign) = 1 if '-' exists, otherwise 0
; Destroys: A, HL
; Preserves: BC, DE
parseCompactDurationSign:
    ld a, (hl)
    or a ; check for empty string
    ret z
    cp signChar
    ret nz ; No '-' sign.
    ; Contains '-' so set the sign bit.
    inc hl
    ld a, (parseDurationBufFlags)
    set parseDurationBufFlagSign, a
    ld (parseDurationBufFlags), a
    ret

; Description: Clear the parseDurationBuf structure.
; Input: none
; Output:
;   - parseDurationBuf cleared
; Destroys: A, B
clearCompactDurationBuf:
    push hl
    ld b, parseDurationBufSizeOf
    xor a
    ld hl, parseDurationBufFlags
clearCompactDurationBufLoop:
    ld (hl), a
    inc hl
    djnz clearCompactDurationBufLoop
    pop hl
    ret
