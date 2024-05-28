; Investigate the values and purpose of various undocumented cursor variables.
;
; Result:
;   - curUnder: the character under the blinking cursor
;   - curType: unknown, seems to have no effect
;   - curTime: seems to be an internal timer variable, probably controlling the
;   blinking
;   - curOffset: unknown, always 0
;   - curY: unknown, always 0x20
;   - curXRow: unknown, always 0xA0
;
; This can be created as an assembly language PRGM or a flash APP, depending on
; the `FLASHAPP` macro defined in the Makefile.
;
; See Appendix A ("Creating Flash Applications with SPASM") of the book ("TI-83
; ASM For the Absolute Beginner") at
; (https://www.ticalc.org/archives/files/fileinfo/437/43784.html) regarding the
; "app.inc" include, the defpage() macro, and the validate() macro.

.nolist
#include "ti83plus.inc"
#ifdef FLASHAPP
#include "app.inc"
#endif
.list

#ifdef FLASHAPP
defpage(0, "cursor")
#else
.org userMem - 2
.db t2ByteTok, tAsmCmp
#endif

;-----------------------------------------------------------------------------

; Location of the cursor
CursorRow equ 0
CursorCol equ 4

; App state
appStateBegin equ tempSwapArea
cursorType equ appStateBegin ; u8
; End application variables.
appStateEnd equ appCurTyp + 1
appStateSize equ (appStateEnd - appStateBegin)

main:
    ; Set up OS configs.
    bcall(_RunIndicOff)
    bcall(_ClrLCDFull)
    set lwrCaseActive, (iy + appLwrCaseFlag) ; allow lowercase letters

    ; Set up app state.
    xor a
    ld (cursorType), a

loop:
    ; Disable the blinking cursor just before printing various prompts
    res curAble, (iy + curFlags)
    res curOn, (iy + curFlags)

    ; Print current cursor info
    call printCursorInfo

    ; Set the cursor and enable the blinking cursor
    ld a, (cursorType)
    ld (curType), a
    ld hl, CursorCol*256+CursorRow
    ld (curRow), hl
    ld a, 'y' ; char under (CursorRow,CursorCol) is 'o'
    ld (curUnder), a
    set curAble, (iy + curFlags)
    set curOn, (iy + curFlags)

    ; Must reset the ON interrupt flag to detect it.
    res onInterrupt, (iy + onFlags)

    ; Get the key code, and reset the ON flag right after. See TI-83 Plus SDK
    ; guide, p. 69. If this flag is not reset, then the next bcall(_DispHL)
    ; causes subsequent bcall(_GetKey) to always return 0. Interestingly, if
    ; the flag is not reset, but the next call is another bcall(_GetKey), then
    ; it sort of seems to work. Except that upon exiting, the TI-OS displays an
    ; Quit/Goto error message.
    bcall(_GetKey)
    res onInterrupt, (iy + onFlags)

    ; Check for 2nd-Quit, or ON.
    cp kQuit
    jr z, exit
    or a
    jr z, exit

    ; Handle Up and Down arrow keys to change the cursor variables.
    cp kUp
    jr z, handleUp
    cp kDown
    jr z, handleDown
    cp kLeft
    jr z, handleLeft
    cp kRight
    jr z, handleRight
    jr loop

handleUp:
    ld hl, cursorType
    inc (hl)
    jr loop
handleDown:
    ld hl, cursorType
    dec (hl)
    jr loop
handleLeft:
    ld hl, cursorType
    sla (hl)
    jr loop
handleRight:
    ld hl, cursorType
    srl (hl)
    jr loop

exit:
    res lwrCaseActive, (iy + appLwrCaseFlag)
    bcall(_ClrLCDFull)
    bcall(_HomeUp)
    bcall(_NewLine)
    ld hl, msg_exit
    call putS
    bcall(_EraseEOL)

#ifdef FLASHAPP
    ; In a real flash app, the exit handler will be a LOT more complicated than
    ; this. For example, it needs to install a handler for the 2ND OFF signal
    ; to clean up before the calculator turns off. See the rpn83p app for
    ; details. This app is so simple, we can just call the '_JForceCmdNoChar'
    ; entry point, and things are just fine. Flash apps seem to clean up well
    ; enough that 2ND OFF does *not* leak memory. No idea why that is.
    bcall(_JForceCmdNoChar)
#else
    ; If an assembly program (i.e. non-flash program) is terminated using 2ND
    ; OFF, it will leak memory. This app is so small, and it intended to be
    ; only a debugging app, I can live with that memory leak.
    ret
#endif

;-----------------------------------------------------------------------------

; Description: Print value of A.
; Input: A:u8=cursorType
printCursorInfo:
    ld hl, 0
    ld (curRow), hl
    ; curType
    ld hl, msg_curtype
    call putS
    ld a, (curType)
    call printUnsignedA
    bcall(_EraseEOL)
    bcall(_NewLine)
    ; curTime
    ld hl, msg_curtime
    call putS
    ld a, (curTime)
    call printUnsignedA
    bcall(_EraseEOL)
    bcall(_NewLine)
    ; curOffset
    ld hl, msg_curoffset
    call putS
    ld a, (curOffset)
    call printUnsignedA
    bcall(_EraseEOL)
    bcall(_NewLine)
    ; curY
    ld hl, msg_cury
    call putS
    ld a, (curY)
    call printUnsignedA
    bcall(_EraseEOL)
    bcall(_NewLine)
    ; curXRow
    ld hl, msg_curxrow
    call putS
    ld a, (curXRow)
    call printUnsignedA
    bcall(_EraseEOL)
    bcall(_NewLine)
    ret

;-----------------------------------------------------------------------------

; Description: Print key code or codes. The SDK says that GetKey() can return a
; 2-byte code using kExtendEcho and kExtendEcho2. Two-byte codes are returned
; for lowercased alpha letters (ALPHA ALPHA A to ALPHA ALPHA Z). They begin
; with 0xFC (i.e. kExtendEcho2), and the actual letter code is given by
; (keyExtend):
;
;   - 'a': 0xE2 (226), kLa
;   - 'z': 0xFB (251), kLz

; I have not figured out how to activate all the other 2-byte key codes defined
; in ti83plus.inc.
;
; Input: A=keyCode
printUnsignedA:
    ;push af
    call printHex
    ;ld a, '-'
    ;bcall(_PutC)
    ;pop af
    ;call printDecimal
    ret

;-----------------------------------------------------------------------------

; Description: Print register A as hexadecimal.
; Destroys: B
; Preserves: A
printHex:
    ld b, a ; preserve
    and $F0
    srl a
    srl a
    srl a
    srl a
    call printHexSingle
    ld a, b
    and $0F
    call printHexSingle
    ld a, b ; restore
    ret
printHexSingle:
    cp 10
    jr c, printHex0To9
    sub a, 10
    add a, 'A'
    jr printHexAToF
printHex0To9:
    add a, '0'
printHexAToF:
    bcall(_PutC)
    ret

; Description: Print register A as unsigned decimal.
; Destroys: BC, DE, HL, OP3
; Preserves: A
printDecimal:
    push af
    ld hl, OP3
    call FormatAToString ; HL=formattedString
    ld (hl), 0 ; NUL
    ld hl, OP3
    call putS
    pop af
    ret

;-----------------------------------------------------------------------------

; Description: Inlined version of bcall(_PutS) which works for flash
; applications. See TI-83 Plus System Routine SDK docs for PutS() for a
; reference implementation. The _PutC() OS function interprets the `Lenter`
; character as a "newline" and moves the cursor to the next line. But it also
; adds a ':' character at the beginning of the next line (to signify
; continuation?). To handle `Lenter` better, see the putS() version in the
; rpn83p project.
;
; Input: HL: pointer to C-string
; Output:
;   - CF=1 if the entire string was displayed, CF=0 if not
;   - curRow and curCol updated to the position after the last character
; Destroys: A, HL
putS:
    push bc
    push af
    ld a, (winBtm)
    ld b, a ; B = bottom line of window
putSLoop:
    ld a, (hl)
    inc hl
    or a ; test for end of string
    scf ; CF=1 if entire string displayed
    jr z, putSEnd
    bcall(_PutC)
    ld a, (curRow)
    cp b ; if A >= bottom line: CF=1
    jr c, putSLoop ; repeat if not at bottom
putSEnd:
    pop bc ; restore A (but not F)
    ld a, b
    pop bc
    ret

msg_curtype:
    .db "curType: ", 0

msg_curtime:
    .db "curTime: ", 0

msg_curoffset:
    .db "curOffset: ", 0

msg_cury:
    .db "curY: ", 0

msg_curxrow:
    .db "curXRow: ", 0

msg_exit:
    .db "Quit pressed", 0

.end

;-----------------------------------------------------------------------------

; Description: Format integer A to a string of 1 to 3 digits, with the leading
; '0' suppressed, and append at the string buffer pointed by HL. Borrowed from
; the RPN83P project.
; Input:
;   - A:u8=input
;   - HL:(char*)
; Output:
;   - HL=points to char after string, no NUL termination
; Destroys: A, B, C, HL
; Preserves: DE
suppressLeadingZero equ 0 ; bit 0 of D
FormatAToString:
    push de
    set suppressLeadingZero, d
    ; Divide by 100
    ld b, 100
    call divideAByB
    or a
    jr z, formatAToStringTen ; skip hundred's leading zero
    ; print non-zero hundred's digit
    call convertAToChar
    ld (hl), a
    inc hl
    res suppressLeadingZero, d
formatAToStringTen:
    ; Divide by 10
    ld a, b
    ld b, 10
    call divideAByB
    or a
    jr nz, formatAToStringTenPrint
    ; Check if ten's zero should be suppressed before printing.
    bit suppressLeadingZero, d ; if suppressLeadingZero: ZF=0
    jr nz, formatAToStringOne
formatAToStringTenPrint:
    call convertAToChar
    ld (hl), a
    inc hl
formatAToStringOne:
    ; Extract the 1
    ld a, b
    call convertAToChar
    ; always print the last digit regardless of suppressLeadingZero
    ld (hl), a
    inc hl
    pop de
    ret

; Description: Return A / B using repeated substraction.
; Input:
;   - A=numerator
;   - B=denominator
; Output:
;   - A=A/B (quotient)
;   - B=A%B (remainder)
; Destroys: C
divideAByB:
    ld c, 0
divideAByBLoop:
    sub b
    jr c, divideAByBLoopEnd
    inc c
    jr divideAByBLoop
divideAByBLoopEnd:
    add a, b ; undo the last subtraction
    ld b, a
    ld a, c
    ret

; Description: Convert A into an Ascii Char ('0'-'9','A'-'F').
; Destroys: A
convertAToChar:
    cp 10
    jr c, convertAToCharDecimal
    sub 10
    add a, 'A'
    ret
convertAToCharDecimal:
    add a, '0'
    ret

;-----------------------------------------------------------------------------

#ifdef FLASHAPP
validate()
#endif
