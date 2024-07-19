;-----------------------------------------------------------------------------
; Print routines.
;-----------------------------------------------------------------------------

; Description: Print the 4 bytes pointed by HL in little-endian format at the
; current curCol/CurRow.
; Input: HL: pointer to 4 bytes
; Destroys: None
PrintU32AsHex:
    push af
    push bc
    push de
    push hl
    ; Prep loop
    ld b, 4
printU32AsHexLoop:
    ld a, (hl)
    call printUnsignedAAsHex
    inc hl
    ld a, ' '
    bcall(_PutC) ; preserves B
    djnz printU32AsHexLoop
    pop hl
    pop de
    pop bc
    pop af
    ret

; Description: Print HL as a 4-digit hex, little-endian format.
; Destroys: A
; Preserves: BC, DE, HL
PrintUnsignedHLAsHex:
    ld a, l
    call printUnsignedAAsHex
    ld a, ' '
    bcall(_PutC) ; preserves B
    ld a, h
    call printUnsignedAAsHex
    ret

;-----------------------------------------------------------------------------

; Description: Print A has a 2-digit hex.
; Destroys: A
; Preserves: BC, DE, HL
printUnsignedAAsHex:
    push af
    srl a
    srl a
    srl a
    srl a
    call convertAToChar
    bcall(_PutC)
    ;
    pop af
    and $0F
    call convertAToChar
    bcall(_PutC)
    ret

; Description: Convert A into an Ascii Char ('0'-'9','A'-'F').
; Destroys: A
; Preserves: BC, DE, HL
convertAToChar:
    cp 10
    jr c, convertAToCharDecimal
    sub 10
    add a, 'A'
    ret
convertAToCharDecimal:
    add a, '0'
    ret
