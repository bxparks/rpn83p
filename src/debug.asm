;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;-----------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Routines for debugging, displaying contents of buffers or registers. These
; are not compiled into the app unless the -DDEBUG flag is given to the
; spasm-ng assembler.
;------------------------------------------------------------------------------

; Function: Print out the inputBuf on the debug line.
; Input: parseBuf
; Output:
; Destroys: none
debugInputBuf:
    push af
    push bc
    push de
    push hl
    ld hl, (CurRow)
    push hl

    ld hl, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    ld hl, inputBuf
    call putPS
    ld a, cursorCharAlt
    bcall(_PutC)
    bcall(_EraseEOL)

    pop hl
    ld (CurRow), hl
    pop hl
    pop de
    pop bc
    pop af
    ret

; Function: Print out the parseBuf on the debug line.
; Input: parseBuf
; Output:
; Destroys: none
debugParseBuf:
    push af
    push bc
    push de
    push hl
    ld hl, (CurRow)
    push hl

    ld hl, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    ld hl, parseBuf
    call putPS
    ld a, cursorCharAlt
    bcall(_PutC)
    bcall(_EraseEOL)

    pop hl
    ld (CurRow), hl
    pop hl
    pop de
    pop bc
    pop af
    ret

; Description: Print the C string at HL.
; Input: HL
; Output:
; Destroys: none
debugString:
    push af
    push bc
    push de
    push hl
    ld de, (CurRow)
    push de

    ld de, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (CurRow), de
    call putS
    bcall(_EraseEOL)

    pop de
    ld (CurRow), de
    pop hl
    pop de
    pop bc
    pop af
    ret

; Description: Print the Pascal string at HL.
; Input: HL
; Output:
; Destroys: none
debugPString:
    push af
    push bc
    push de
    push hl
    ld de, (CurRow)
    push de

    ld de, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (CurRow), de
    call putPS
    bcall(_EraseEOL)

    pop de
    ld (CurRow), de
    pop hl
    pop de
    pop bc
    pop af
    ret

;------------------------------------------------------------------------------

; Description: Clear the debug line.
; Destroys: none
debugClear:
    push hl
    ld hl, (CurRow)
    push hl

    ld hl, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    bcall(_EraseEOL)

    pop hl
    ld (CurRow), hl
    pop hl
    ret

;------------------------------------------------------------------------------

; Function: Print out OP1 at debug line.
; Input: OP1
; Output:
; Destroys: OP3
debugOP1:
    push af
    push bc
    push de
    push hl
    ld hl, (CurRow)
    push hl

    ld hl, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    ld a, 15 ; width of output
    bcall(_FormReal)
    ld hl, OP3
    call putS
    bcall(_EraseEOL)

    pop hl
    ld (CurRow), hl
    pop hl
    pop de
    pop bc
    pop af
    ret

;------------------------------------------------------------------------------

; Description: Print the value of the inputBufEEPos variable.
; Input: none
; Output: A printed on debug line
; Destroys: none
debugEEPos:
    push af
    ld a, (inputBufEEPos)
    call debugUnsignedA
    pop af
    ret

;------------------------------------------------------------------------------

; Function: Print the unsigned A on the debug line.
; Input: A
; Output: A printed on debug line
; Destroys: none
debugUnsignedA:
    push af
    push bc
    push de
    push hl
    ld hl, (CurRow)
    push hl

    ld hl, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    ld l, a
    ld h, 0
    bcall(_DispHL)

    pop hl
    ld (CurRow), hl
    pop hl
    pop de
    pop bc
    pop af
    ret

;------------------------------------------------------------------------------

; Function: Print the signed A on the debug line.
; Input: A
; Output: A printed on debug line
; Destroys: none
debugSignedA:
    push af
    push bc
    push de
    push hl
    ld hl, (CurRow)
    push hl

    ld hl, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    ld b, a ; save
    bit 7, a
    jr z, debugSignedAPositive
debugSignedANegative:
    ld a, signChar
    bcall(_PutC)
    ld a, b
    neg
    jr debugSignedAPrint
debugSignedAPositive:
    ld a, ' '
    bcall(_PutC)
    ld a, b
debugSignedAPrint:
    ld l, a
    ld h, 0
    bcall(_DispHL)

    pop hl
    ld (CurRow), hl
    pop hl
    pop de
    pop bc
    pop af
    ret

;------------------------------------------------------------------------------

; Function: Print some of the display and RPN flags on the debug line.
;   - I: input dirty
;   - E: editing
;   - L: stack lift disabled
;   - S: stack dirty
; Input: (iy+rpnFlags), (iy+inputBufFlags)
; Output: Flags printed on debug line.
; Destroys: none
debugFlags:
    push af
    push bc
    push de
    push hl
    ld hl, (CurRow)
    push hl

    ld hl, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (CurRow), hl

    ; Print Input dirty flag
    bit dirtyFlagsInput, (iy + dirtyFlags)
    ld a, 'I'
    call printFlag

    ; Print Editing flag
    bit rpnFlagsEditing, (iy + rpnFlags)
    ld a, 'E'
    call printFlag

    ; Print ClosedEmpty flag
    bit inputBufFlagsClosedEmpty, (iy + inputBufFlags)
    ld a, 'Z'
    call printFlag

    ld a, ' '
    bcall(_PutC)

    ; Print Stack dirty flag
    bit dirtyFlagsStack, (iy + dirtyFlags)
    ld a, 'S'
    call printFlag

    ; Print Lift flag
    bit rpnFlagsLiftEnabled, (iy + rpnFlags)
    ld a, 'L'
    call printFlag

    bcall(_EraseEOL)

    pop hl
    ld (CurRow), hl
    pop hl
    pop de
    pop bc
    pop af
    ret

; Function: Print the character in reg A, and a +/- depending on Z flag.
; Input:
;   A: flag char (e.g. 'I', 'E')
;   CF: 1 or 0
; Output:
;   Flag character with '+' or '-', e.g. "I+", "E+"
; Destroys: A
printFlag:
    jr z, printFlagMinus
printFlagPlus:
    bcall(_PutC)
    ld a, '+'
    bcall(_PutC)
    ret
printFlagMinus:
    bcall(_PutC)
    ld a, '-'
    bcall(_PutC)
    ret

;------------------------------------------------------------------------------

; Description: Print the 4 bytes pointed by HL.
; Input: HL: pointer to 4 bytes
; Destroys: None
debugU32AsHex:
    push af
    push de
    push hl

    ; Set cursor position, saving the previous on the stack.
    ld de, (CurRow)
    push de
    ld de, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (CurRow), de

debugU32AsHexAltEntry:
    ld a, (hl)
    call printUnsignedAAsHex
    inc hl
    ld a, ' '
    bcall(_PutC)

    ld a, (hl)
    call printUnsignedAAsHex
    inc hl
    ld a, ' '
    bcall(_PutC)

    ld a, (hl)
    call printUnsignedAAsHex
    inc hl
    ld a, ' '
    bcall(_PutC)

    ld a, (hl)
    call printUnsignedAAsHex

    pop de
    ld (CurRow), de
    pop hl
    pop de
    pop af
    ret

printUnsignedAAsHex:
    push af
    srl a
    srl a
    srl a
    srl a
    call convertAToChar
    bcall(_PutC)

    pop af
    and $0F
    call convertAToChar
    bcall(_PutC)
    ret

; Description: Print the 4 bytes pointed by DE into the error code line.
; Input: De: pointer to 4 bytes
; Destroys: None
debugU32DEAsHex:
    push af
    push de
    push hl
    ex de, hl

    ; Set cursor position, saving the previous on the stack.
    ld de, (CurRow)
    push de
    ld de, errorCurCol*$100+errorCurRow ; $(curCol)(curRow)
    ld (CurRow), de

    jp debugU32AsHexAltEntry

;------------------------------------------------------------------------------

; Description: print HL as hexadecimal
debugHLAsHex:
    push af
    push bc
    push de
    push hl

    ld de, (CurRow)
    push de
    ld de, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (CurRow), de

    ld a, h
    call printUnsignedAAsHex
    ld a, l
    call printUnsignedAAsHex
    bcall(_EraseEOL)

    pop de
    ld (CurRow), de
    pop hl
    pop de
    pop bc
    pop af
    ret

;------------------------------------------------------------------------------

debugPause:
    push af
    push bc
    push de
    push hl
    bcall(_GetKey)
    bit onInterrupt, (iy + onFlags)
    jr nz, debugPauseBreak
    res onInterrupt, (iy + onFlags) ; reset flag set by ON button
    pop hl
    pop de
    pop bc
    pop af
    ret
debugPauseBreak:
    res onInterrupt, (iy + onFlags)
    bcall(_ErrBreak) ; throw exception
