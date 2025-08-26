;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2025 Brian T. Park
;
; Functions related to parsing a compact Duration object of the form
; '[-][{i16}D][{i16}H][{i16}M][{i16}S]'. All fields (days, hours, minutes,
; seconds) support values as large as 9999 (4 digits) when parsed. They are
; normalized when the Duration object is created:
;
;   days:[0,65535]
;   hours: [0,23]
;   minutes: [0,59]
;   seconds: [0,59]
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
    ; Update parseDurationBufXxx field
    call updateCompactDurationComponent
    djnz parseCompactDurationLoop
parseCompactDurationLoopBreak:
    ; Normalize parseDurationBuf
    call normalizeCompactDurationBuf
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

; Description: Normalize the days, hours, minutes, seconds fields which are u16
; in the parseDurationBuf structure into days:u16, hours:u8, minutes:u8,
; seconds:u8.
; Input:
;   - (parseDurationBuf): contains parsed Duration fields
; Output:
;   - (parseDurationBuf): normalized
; Destroys: A
; Preserves: DE, BC, HL
; Throws: Err:Invalid if any bits overflow
normalizeCompactDurationBuf:
    push hl
    push de
    push bc

    ; normalize 'seconds'
    ld hl, (parseDurationBufSeconds)
    ld c, 60
    call divHLByCPageOne ; HL=quotient; A=remainder
    ld (parseDurationBufSeconds), a
    xor a
    ld (parseDurationBufSeconds + 1), a
    ; overflow to 'minutes'
    ex de, hl ; DE=quotient
    ld hl, (parseDurationBufMinutes)
    add hl, de ; new minutes
    jr c, normalizeCompactDurationBufInvalid
    ; normalize 'minutes'
    ld c, 60
    call divHLByCPageOne ; HL=quotient; A=remainder
    ld (parseDurationBufMinutes), a
    xor a
    ld (parseDurationBufMinutes + 1), a
    ; overflow to 'hours'
    ex de, hl ; DE=quotient
    ld hl, (parseDurationBufHours)
    add hl, de ; new hours
    jr c, normalizeCompactDurationBufInvalid
    ; normalize 'hours'
    ld c, 24
    call divHLByCPageOne ; HL=quotient; A=remainder
    ld (parseDurationBufHours), a
    xor a
    ld (parseDurationBufHours + 1), a
    ; overflow to 'days'
    ex de, hl ; DE=quotient
    ld hl, (parseDurationBufDays)
    add hl, de
    jr c, normalizeCompactDurationBufInvalid
    ld (parseDurationBufDays), hl

    pop bc
    pop de
    pop hl
    ret

normalizeCompactDurationBufInvalid:
    bcall(_ErrInvalid)

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
    ld (parseDurationBufSeconds), hl
    pop hl ; stack=[]
    ret

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
