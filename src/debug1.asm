;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Routines for debugging, displaying contents of buffers or registers. These
; are not compiled into the app unless the -DDEBUG flag is given to the
; spasm-ng assembler.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;------------------------------------------------------------------------------

; Description: Print out the inputBuf on the debug line.
; Input: parseBuf
; Output:
; Destroys: none
DebugInputBuf:
    push af
    push bc
    push de
    push hl
    ld hl, (curRow)
    push hl

    ld hl, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (curRow), hl
    ld hl, inputBuf
    call putPSPageOne
    ld a, cursorCharAlt
    bcall(_PutC)
    bcall(_EraseEOL)

    pop hl
    ld (curRow), hl
    pop hl
    pop de
    pop bc
    pop af
    ret

;------------------------------------------------------------------------------

; Description: Print out the parseBuf on the debug line.
; Input: parseBuf
; Output:
; Destroys: none
DebugParseBuf:
    push af
    push bc
    push de
    push hl
    ld hl, (curRow)
    push hl

    ld hl, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (curRow), hl
    ld hl, parseBuf
    call putPSPageOne
    ld a, cursorCharAlt
    bcall(_PutC)
    bcall(_EraseEOL)

    pop hl
    ld (curRow), hl
    pop hl
    pop de
    pop bc
    pop af
    ret

;------------------------------------------------------------------------------

; Description: Print the C string at HL.
; Input: HL
; Output:
; Destroys: none
DebugString:
    push af
    push bc
    push de
    push hl
    ld de, (curRow)
    push de

    ld de, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (curRow), de
    call putSPageOne
    bcall(_EraseEOL)

    pop de
    ld (curRow), de
    pop hl
    pop de
    pop bc
    pop af
    ret

; Description: Print the Pascal string at HL.
; Input: HL
; Output:
; Destroys: none
DebugPString:
    push af
    push bc
    push de
    push hl
    ld de, (curRow)
    push de

    ld de, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (curRow), de
    call putPSPageOne
    bcall(_EraseEOL)

    pop de
    ld (curRow), de
    pop hl
    pop de
    pop bc
    pop af
    ret

;------------------------------------------------------------------------------

; Description: Clear the debug line.
; Destroys: none
DebugClear:
    push hl
    ld hl, (curRow)
    push hl

    ld hl, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (curRow), hl
    bcall(_EraseEOL)

    pop hl
    ld (curRow), hl
    pop hl
    ret

;------------------------------------------------------------------------------

; Description: Print out OP1 at debug line.
; Input: OP1
; Output:
; Destroys: OP3
DebugOP1:
    push af
    push bc
    push de
    push hl
    ld hl, (curRow)
    push hl

    ld hl, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (curRow), hl
    ld a, 15 ; width of output
    bcall(_FormReal)
    ld hl, OP3
    call putSPageOne
    bcall(_EraseEOL)

    pop hl
    ld (curRow), hl
    pop hl
    pop de
    pop bc
    pop af
    ret

;------------------------------------------------------------------------------

; Description: Print the unsigned A on the debug line.
; Input: A
; Output: A printed on debug line
; Destroys: none
; Note: Cannot use bcall(_dispHL) because it destroys OP1.
DebugUnsignedA:
    ; Save all registers
    push af
    push bc
    push de
    push hl
    push ix
    ; Save curRow/CurCol
    ld hl, (curRow)
    push hl
    ld hl, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (curRow), hl
    ; Create 4-byte buffer on the stack
    push hl
    push hl
    ld hl, 0
    add hl, sp ; HL:(char*)=buffer

    ; Convert A into string
    push hl
    bcall(_FormatAToString)
    ld (hl), 0
    pop hl
    call putSPageOne
    bcall(_EraseEOL)

    ; Clean up stack buffer
    pop hl
    pop hl
    ; Restore curRow/CurCol
    pop hl
    ld (curRow), hl
    ; Restore all registers.
    pop ix
    pop hl
    pop de
    pop bc
    pop af
    ret

;------------------------------------------------------------------------------

; Description: Print the signed A on the debug line.
; Input: A
; Output: A printed on debug line
; Destroys: none
; Note: Cannot use bcall(_dispHL) because it destroys OP1.
DebugSignedA:
    ; Save all registers
    push af
    push bc
    push de
    push hl
    push ix
    ; Save curRow/CurCol
    ld hl, (curRow)
    push hl
    ld hl, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (curRow), hl
    ; Create 4-byte buffer on the stack
    push hl
    push hl
    ld hl, 0
    add hl, sp ; HL:(char*)=buffer

    ; Check for negative A
    ld b, a ; save
    bit 7, a
    jr z, debugSignedAPrint
    ; negative
    ld a, signChar
    bcall(_PutC)
    ld a, b
    neg
debugSignedAPrint:
    ; Convert A into string
    push hl
    bcall(_FormatAToString)
    ld (hl), 0
    pop hl
    call putSPageOne
    bcall(_EraseEOL)

    ; Clean up stack buffer
    pop hl
    pop hl
    ; Restore curRow/CurCol
    pop hl
    ld (curRow), hl
    ; Restore all registers.
    pop ix
    pop hl
    pop de
    pop bc
    pop af
    ret

;------------------------------------------------------------------------------

; Description: Print some of the display and RPN flags on the debug line.
;   - I: input dirty
;   - E: editing
;   - L: stack lift disabled
;   - S: stack dirty
; Input: (iy+rpnFlags), (iy+inputBufFlags)
; Output: Flags printed on debug line.
; Destroys: none
DebugFlags:
    push af
    push bc
    push de
    push hl
    ld hl, (curRow)
    push hl

    ld hl, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (curRow), hl

    ; Print Input dirty flag
    bit dirtyFlagsInput, (iy + dirtyFlags)
    ld a, 'I'
    call debugPrintFlag

    ; Print Editing flag
    bit rpnFlagsEditing, (iy + rpnFlags)
    ld a, 'E'
    call debugPrintFlag

    ; Print ClosedEmpty flag
    bit inputBufFlagsClosedEmpty, (iy + inputBufFlags)
    ld a, 'Z'
    call debugPrintFlag

    ld a, ' '
    bcall(_PutC)

    ; Print Stack dirty flag
    bit dirtyFlagsStack, (iy + dirtyFlags)
    ld a, 'S'
    call debugPrintFlag

    ; Print Lift flag
    bit rpnFlagsLiftEnabled, (iy + rpnFlags)
    ld a, 'L'
    call debugPrintFlag

    bcall(_EraseEOL)

    pop hl
    ld (curRow), hl
    pop hl
    pop de
    pop bc
    pop af
    ret

; Description: Print the character in reg A, and a +/- depending on Z flag.
; Input:
;   A: flag char (e.g. 'I', 'E')
;   CF: 1 or 0
; Output:
;   Flag character with '+' or '-', e.g. "I+", "E+"
; Destroys: A
debugPrintFlag:
    jr z, debugPrintFlagMinus
debugPrintFlagPlus:
    bcall(_PutC)
    ld a, '+'
    bcall(_PutC)
    ret
debugPrintFlagMinus:
    bcall(_PutC)
    ld a, '-'
    bcall(_PutC)
    ret

;------------------------------------------------------------------------------

; Description: Print the 4 bytes pointed by HL.
; Input: HL: pointer to 4 bytes
; Destroys: None
DebugU32AsHex:
    push af
    push bc
    push de
    push hl
    ; Set cursor position, saving the previous on the stack.
    ld de, (curRow)
    push de
    ld de, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (curRow), de
    ; Prep loop
    ld b, 4
debugU32AsHexLoop:
    ld a, (hl)
    call debugUnsignedAAsHex
    inc hl
    ld a, ' '
    bcall(_PutC) ; preserves B
    djnz debugU32AsHexLoop
    ;
    pop de
    ld (curRow), de
    pop hl
    pop de
    pop bc
    pop af
    ret

; Description: Print A has a 2-digit hex.
; Destroys: A
debugUnsignedAAsHex:
    push af
    srl a
    srl a
    srl a
    srl a
    call convertAToCharPageOne
    bcall(_PutC)
    ;
    pop af
    and $0F
    call convertAToCharPageOne
    bcall(_PutC)
    ret

; Description: Print the 4 bytes pointed by DE into the error code line.
; Input: DE: pointer to 4 bytes
; Destroys: None
DebugU32DEAsHex:
    ex de, hl
    call DebugU32AsHex
    ex de, hl
    ret

;------------------------------------------------------------------------------

; Description: Print the 5 bytes pointed by HL.
; Input: HL: pointer to 5 bytes
; Destroys: None
DebugU40AsHex:
    push af
    push bc
    push de
    push hl
    ; Set cursor position, saving the previous on the stack.
    ld de, (curRow)
    push de
    ld de, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (curRow), de
    ; Prep loop
    ld b, 5
debugU40AsHexLoop:
    ld a, (hl)
    call debugUnsignedAAsHex
    inc hl
    ld a, ' '
    bcall(_PutC) ; preserves B
    djnz debugU40AsHexLoop
    ;
    pop de
    ld (curRow), de
    pop hl
    pop de
    pop bc
    pop af
    ret

;------------------------------------------------------------------------------

; Description: Print HL as a decimal number.
; Destroys: none
DebugHL:
    push af
    push bc
    push de
    push hl
    bcall(_PushRealO1)
    bcall(_PushRealO2)
    bcall(_PushRealO3)
    bcall(_PushRealO4) ; up to 16 bytes starting at OP3, which spills into OP4
    pop hl
    push hl
    ld de, (curRow)
    push de
    ;
    ld de, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (curRow), de
    ; Converting to float is not efficient, but ok for debugging.
    bcall(_SetXXXXOP2) ; OP2=float(HL)
    bcall(_OP2ToOP1) ; OP1=float(HL)
    ld a, 15 ; width of output
    bcall(_FormReal)
    ld hl, OP3
    call putSPageOne
    bcall(_EraseEOL)
    ;
    pop de
    ld (curRow), de
    bcall(_PopRealO4)
    bcall(_PopRealO3)
    bcall(_PopRealO2)
    bcall(_PopRealO1)
    pop hl
    pop de
    pop bc
    pop af
    ret

;------------------------------------------------------------------------------

; Description: print HL as hexadecimal
DebugHLAsHex:
    push af
    push bc
    push de
    push hl
    ld de, (curRow)
    push de
    ;
    ld de, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (curRow), de
    ;
    ld a, h
    call debugUnsignedAAsHex
    ld a, l
    call debugUnsignedAAsHex
    bcall(_EraseEOL)
    ;
    pop de
    ld (curRow), de
    pop hl
    pop de
    pop bc
    pop af
    ret

;------------------------------------------------------------------------------

; Description: print DE and HL as hexadecimal
DebugDEHLAsHex:
    push af
    push bc
    push de
    push hl
    ld bc, (curRow)
    push bc
    ;
    ld bc, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (curRow), bc
    ;
    ld a, d
    call debugUnsignedAAsHex
    ld a, e
    call debugUnsignedAAsHex
    ld a, ' '
    bcall(_PutC)
    ld a, h
    call debugUnsignedAAsHex
    ld a, l
    call debugUnsignedAAsHex
    bcall(_EraseEOL)
    ;
    pop bc
    ld (curRow), bc
    pop hl
    pop de
    pop bc
    pop af
    ret

;------------------------------------------------------------------------------

; Description: Pause and wait for a keyboard input.
; Input: none
; Output: none
; Destroys: none
DebugPause:
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
