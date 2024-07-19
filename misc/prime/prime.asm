;-----------------------------------------------------------------------------
; Test the performance of the modDEIXByBC() routine selected by the `-D` flag
; in the Makefile by searching for the prime factor of a large number
; (input=65521*65521).
;
; On a TI-83+/84+, this program runs at 6 MHz by default. The main loop
; iterates through every odd number between 3 and 65521 in steps of 2 (i.e.
; 32759 iterations). According to the benchmarks listed in modu32u16.asm, the
; reference implementation (MOD_HLIX_BY_BC_RESTORING_MONOLITH) takes 20.5
; seconds. The fastest (MOD_DEIX_BY_BC_NONRESTORING_CHUNK8_REGA_UNROLLED) takes
; 11.8 seconds.
;-----------------------------------------------------------------------------

.nolist
#include "ti83plus.inc"
.list
.org userMem - 2
.db t2ByteTok, tasmCmp

input equ (65521*65521)
inputHigh16 equ ((input & $ffff0000) >> 16)
inputLow16 equ (input & $ffff)

main:
    bcall(_homeup)
    bcall(_ClrLCDFull)
    ld bc, 3 ; check all odd numbers from 3 to 65521
primeLoop:
    ld de, inputHigh16
    ld ix, inputLow16
    call modDEIXByBC ; HL=remainder
    inc bc
    inc bc
    ld a, h
    or l
    jp nz, primeLoop
    ret

#include "modu32u16.asm"

.end
