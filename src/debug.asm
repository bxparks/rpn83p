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

; Function: Print out the inputBuf on the debug line.
; Input: parseBuf
; Output:
; Destroys: none
DebugInputBuf:
    push af
    push bc
    push de
    push hl
    ld hl, (CurRow)
    push hl

    ld hl, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    ld hl, inputBuf
    call debugPutPS
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

;------------------------------------------------------------------------------

; Function: Print out the parseBuf on the debug line.
; Input: parseBuf
; Output:
; Destroys: none
DebugParseBuf:
    push af
    push bc
    push de
    push hl
    ld hl, (CurRow)
    push hl

    ld hl, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (CurRow), hl
    ld hl, parseBuf
    call debugPutPS
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
    ld de, (CurRow)
    push de

    ld de, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (CurRow), de
    call debugPutS
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
DebugPString:
    push af
    push bc
    push de
    push hl
    ld de, (CurRow)
    push de

    ld de, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (CurRow), de
    call debugPutPS
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
DebugClear:
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
DebugOP1:
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
    call debugPutS
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
DebugEEPos:
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
DebugUnsignedA:
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
DebugSignedA:
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
DebugFlags:
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
    push de
    push hl

    ; Set cursor position, saving the previous on the stack.
    ld de, (CurRow)
    push de
    ld de, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (CurRow), de

debugU32AsHexAltEntry:
    ld a, (hl)
    call debugUnsignedAAsHex
    inc hl
    ld a, ' '
    bcall(_PutC)

    ld a, (hl)
    call debugUnsignedAAsHex
    inc hl
    ld a, ' '
    bcall(_PutC)

    ld a, (hl)
    call debugUnsignedAAsHex
    inc hl
    ld a, ' '
    bcall(_PutC)

    ld a, (hl)
    call debugUnsignedAAsHex

    pop de
    ld (CurRow), de
    pop hl
    pop de
    pop af
    ret

debugUnsignedAAsHex:
    push af
    srl a
    srl a
    srl a
    srl a
    call debugAToChar
    bcall(_PutC)

    pop af
    and $0F
    call debugAToChar
    bcall(_PutC)
    ret

;------------------------------------------------------------------------------

; Description: Print the 4 bytes pointed by DE into the error code line.
; Input: De: pointer to 4 bytes
; Destroys: None
DebugU32DEAsHex:
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
DebugHLAsHex:
    push af
    push bc
    push de
    push hl

    ld de, (CurRow)
    push de
    ld de, debugCurCol*$100+debugCurRow ; $(curCol)(curRow)
    ld (CurRow), de

    ld a, h
    call debugUnsignedAAsHex
    ld a, l
    call debugUnsignedAAsHex
    bcall(_EraseEOL)

    pop de
    ld (CurRow), de
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

;------------------------------------------------------------------------------
; Low level routines, duplicated from Flash Page 0 for Flash Page 1.
;------------------------------------------------------------------------------

; Description: Convert A into an Ascii Char ('0'-'9','A'-'F'). For Flash Page 1.
; Destroys: A
debugAToChar:
    cp 10
    jr c, debugAToCharDec
    sub 10
    add a, 'A'
    ret
debugAToCharDec:
    add a, '0'
    ret

; Description: Inlined version of bcall(_PutPS) which works for Pascal strings
; in flash memory. For Flash Page 1. Identical to putPS().
;
; Input: HL: pointer to Pascal string
; Destroys: A, B, C, HL
; Preserves: DE
debugPutPS:
    ld a, (hl) ; A = length of Pascal string
    inc hl
    or a
    ret z
    ld b, a ; B = length of Pascal string (missing from SDK reference impl)
    ld a, (winBtm)
    ld c, a ; C = bottomRow (usually 8)
debugPutPSLoop:
    ld a, (hl)
    inc hl
    bcall(_PutC)
    ; Check if next character is off-screen
    ld a, (curRow)
    cp c ; if currow == buttomRow: ZF=1
    ret z
    djnz debugPutPSLoop
    ret

; Description: Inlined version of bcall(_PutS) which works for flash
; applications in Flash Page 1. Identical to putS().
;
; Input: HL: pointer to C-string
; Output:
;   - CF=1 if the entire string was displayed, CF=0 if not
;   - curRow and curCol updated to the position after the last character
; Destroys: HL
debugPutS:
    push bc
    push af
    ld a, (winBtm)
    ld b, a ; B = bottom line of window
debugPutSLoop:
    ld a, (hl)
    inc hl
    or a ; test for end of string
    scf ; CF=1 if entire string displayed
    jr z, debugPutSEnd
    bcall(_PutC)
    ld a, (curRow)
    cp b ; if A >= bottom line: CF=1
    jr c, debugPutSLoop ; repeat if not at bottom
debugPutSEnd:
    pop bc ; restore A (but not F)
    ld a, b
    pop bc
    ret
