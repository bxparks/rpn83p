;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Same as print.asm but in Flash Page 2.
;-----------------------------------------------------------------------------

; Description: Print char A the multiple times.
; Input:
;   - A: char to print
;   - B: number of times
; Destroys: A, BC, DE, HL
printARepeatBPageTwo:
    ld c, a ; C = char to print (saved)
    ; Check for B == 0
    ld a, b
    or a
    ret z
printARepeatBPageTwoLoop:
    ld a, c
    bcall(_VPutMap) ; destroys A, DE, HL, but not BC
    djnz printARepeatBPageTwoLoop
    ret

;-----------------------------------------------------------------------------

; Description: Convenience wrapper around SStringLength() that works for
; zero-length strings.
; Input: HL:(PascalString*)=pstring in RAM
; Output: A=B=number of pixels
; Destroys: all but HL
smallStringWidthPageTwo:
    ld a, (hl)
    or a
    ld b, a
    ret z
    bcall(_SStringLength) ; A, B = stringWidth; HL preserved
    ret

;-----------------------------------------------------------------------------

; Description: Call vPutPS() using small font.
vPutSmallPSPageTwo:
    res fracDrawLFont, (iy + fontFlags) ; use small font
    ; [[fallthrough]]

; Description: Convenience wrapper around VPutSN() that works for zero-length
; strings. Also provides an API similar to PutPS() which takes a pointer to a
; Pascal string directly, instead of providing the length and (char*)
; separately.
; Input: HL: Pascal-string
; Output; CF=1 if characters overflowed screen
; Destroys: A, HL
vPutPSPageTwo:
    push bc
    ld a, (hl) ; A = length of Pascal string
    or a
    ret z
    ld b, a ; B = num chars
    inc hl ; HL = pointer to start of chars
vPutPNPageTwo:
    ; implement inlined version of VPutSN() which works with flash string
    ld a, (hl)
    inc hl
    bcall(_VPutMap)
    jr c, vPutPNPageTwoEnd
    djnz vPutPNPageTwo
vPutPNPageTwoEnd:
    pop bc
    ret
