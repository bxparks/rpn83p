;-----------------------------------------------------------------------------
; Validate a particular mod(u32,u16) routine against the reference
; implementation (modHLIXByBCRef()). Examine a bunch of prime numbers < 2^32
; and verify that the modDEIXByBC() routine gives the same answer as the
; reference.
;
; The Makefile rule for 'validate.8xp' should contain the `-D` define that
; identifies the specific mod(u32,u16) routine that is being tested.
;-----------------------------------------------------------------------------

.nolist
#include "ti83plus.inc"
.list
.org userMem - 2
.db t2ByteTok, tasmCmp

;input equ (4001*4001)
;input equ (10007*10007)
;input equ (19997*19997)
;input equ (40013*40013)
input equ (65521*65521)
inputHigh16 equ ((input & $ffff0000) >> 16)
inputLow16 equ (input & $ffff)

main:
    ; Initialize OS.
    call setFastSpeed
    bcall(_homeup)
    bcall(_ClrLCDFull)

    ; Initialize app.
    ld hl, inputLow16
    ld (OP1), hl
    ld hl, inputHigh16
    ld (OP1+2), hl
    ; [[fallthrough]]

; Description: Validate modDEIXByC() using the u32 at OP1, starting with 3
; until a prime factor is found.
; Input:
;   - OP1:u32=dividend
validate:
    ld bc, 3 ; check all odd numbers from 3 to a prime factor of OP1
validateLoop:
    ; Check for ON/Break
    bit onInterrupt, (iy + onFlags)
    jr nz, validateBreak
    ;
    ld hl, (OP1+2) ; inputHigh16
    ld ix, (OP1) ; inputLow16
    call modHLIXByBCRef ; DE=remainder
    push de ; stack=[expected]
    ;
    ld de, inputHigh16
    ld ix, inputLow16
    call modDEIXByBC ; HL=remainder
    pop de ; stack=[]; DE=expected
    ; compare the result
    or a
    push hl
    sbc hl, de
    pop hl
    jr nz, validateFailed
    ;
    inc bc
    inc bc
    ld a, h
    or l
    jp nz, validateLoop
    ; [[fallthrough]]

validateOk:
    ld hl, msgOk
    bcall(_PutS)
    bcall(_NewLine)
    ret

validateBreak:
    ld hl, msgBreak
    bcall(_PutS)
    bcall(_NewLine)
    ret

; Description: Print failure message.
; Input:
;   - OP1:u32=dividend
;   - BC:u16=divisor
;   - DE:u16=expected
;   - HL:u16=observed
validateFailed:
    push hl ; stack=[observed]
    ;
    ld hl, msgFailed
    bcall(_PutS)
    bcall(_NewLine)
    ;
    ld hl, msgDividend
    bcall(_PutS)
    ld hl, OP1
    call PrintU32AsHex
    bcall(_NewLine)
    ;
    ld hl, msgDivisor
    bcall(_PutS)
    ld h, b
    ld l, c
    call PrintUnsignedHLAsHex
    bcall(_NewLine)
    ;
    ld hl, msgExpected
    bcall(_PutS)
    ld h, d
    ld l, e
    call PrintUnsignedHLAsHex
    bcall(_NewLine)
    ;
    ld hl, msgObserved
    bcall(_PutS)
    pop hl ; stack=[]; HL=observed
    call PrintUnsignedHLAsHex
    bcall(_NewLine)
    ret

msgOk:
    .db "Ok", 0

msgFailed:
    .db "Failed!", 0

msgBreak:
    .db "Break", 0

msgDividend:
    .db "D:", 0

msgDivisor:
    .db "V:", 0

msgExpected:
    .db "Exp:", 0

msgObserved:
    .db "Obs:", 0

;-----------------------------------------------------------------------------

; Decription: Calculate mod(u32,u16), i.e. the remainder when a u32 dividend is
; divided by a u16 divisor. This is the reference implementation, which uses
; the same algorithm as MOD_HLIX_BY_BC_RESTORING_MONOLITH.
; Input:
;   - HL:u16=high 16 bits of u32 dividend
;   - IX:u16=low 16 bits of u32 dividend
;   - BC:u16=divisor
; Output:
;   - DE:u16=remainder
; Destroys: A, HL, IX
modHLIXByBCRef:
    ld de, 0 ; DE=remainder
    ld a, 32
modHLIXByBCRefLoop:
    add ix, ix
    adc hl, hl
    ex de, hl ; HL=remainder; DE=dividend
    adc hl, hl
    jr c, modHLIXByBCRefOverflow ; remainder overflowed, so substract
    sbc hl, bc ; remainder -= divisor
    jp nc, modHLIXByBCRefNextBit
    add hl, bc ; revert the subtraction
modHLIXByBCRefNextBit:
    ex de, hl ; DE=remainder; HL=dividend
    dec a
    jp nz, modHLIXByBCRefLoop
    ret
modHLIXByBCRefOverflow:
    or a ; reset CF
    sbc hl, bc ; remainder -= divisor
    jp modHLIXByBCRefNextBit

;-----------------------------------------------------------------------------

; Description: Set CPU speed to 15 MHz on supported hardware (83+SE, 84+,
; 84+SE) on OS 1.13 or higher. See TI-83 Plus SDK reference for SetExSpeed().
setFastSpeed:
    call checkOS113 ; CF=0 if OS>=1.13
    ret c
    ld a, $ff
    bcall(_SetExSpeed)
    ret

; Description: Check if OS is >= 1.13.
; Output: CF=0 if OS >= 1.13; 1 otherwise
checkOS113:
    bcall(_GetBaseVer) ; OS version in A (major), B (minor)
    cp 1 ; CF=1 if major < 1; CF=0 and ZF=0 if major > 1
    ret nz ; returns if major >= 2 or < 1
    ld a, b
    cp 13 ; CF=0 if minor version > 13, otherwise CF=1
    ret

;-----------------------------------------------------------------------------

#include "modu32u16.asm"
#include "print.asm"

.end
