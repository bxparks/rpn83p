;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Functions to convert between TI-OS floating point and integer types, mostly
; to u40/i40 integers. Functions related to u32 integers are on Flash Page 0 in
; base.asm.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;------------------------------------------------------------------------------

; Description: Convert the u8 in A to floating pointer number in OP1. This
; supports the full range of A from 0 to 255, compared to the SetXXOP1()
; function in the SDK which supports only integers between 0 and 99.
; Input:
;   - A: u8 integer
; Output:
;   - OP1: floating point value of A
; Destroys: A, B, DE, OP2
; Preserves: C, HL
ConvertAToOP1:
    push af
    bcall(_OP1Set0)
    pop af
    ; [[fallthrough]]

; Description: Convert the u8 in A to floating point number, and add it to OP1.
; Input:
;   - A: u8 integer
;   - OP1: current floating point value, set to 0.0 to start fresh
; Destroys: A, DE, OP2
; Preserves: BC, HL
AddAToOP1:
    push hl
    push bc
    ld b, 8 ; loop for 8 bits in u8
addAToOP1Loop:
    push bc
    push af
    bcall(_Times2) ; OP1 *= 2
    pop af
    sla a
    jr nc, addAToOP1Check
    push af
    bcall(_Plus1) ; OP1 += 1
    pop af
addAToOP1Check:
    pop bc
    djnz addAToOP1Loop
    ;
    pop bc
    pop hl
    ret

;------------------------------------------------------------------------------

; Description: Convert OP1 to u16(HL). Throw ErrDomain exception if:
;   - OP1 >= 2^16
;   - OP1 < 0
;   - OP1 is not an integer
; Input: OP1
; Output: HL=u16(OP1)
; Destroys: all, OP2
convertOP1ToHLPageOne:
    bcall(_CkPosInt) ; if OP1>=0 and OP1 is int: ZF=1
    jr nz, convertOP1ToHLErr
    call op2Set2Pow16PageOne
    bcall(_CpOP1OP2) ; if OP1 >= 2^16: CF=0
    jr nc, convertOP1ToHLErr
    jr convertOP1ToHLNoCheck
convertOP1ToHLErr:
    bcall(_ErrDomain)

; Description: Convert OP1 to u16(HL) without any boundary checks. Adapted from
; convertOP1ToU32NoCheck().
; Input: OP1
; Output: HL=u16(OP1)
; Destroys: all
convertOP1ToHLNoCheck:
    ; initialize the target u16 and check for 0.0
    ld hl, 0
    bcall(_CkOP1FP0) ; preserves HL
    ret z
    ; extract number of decimal digits
    ld de, OP1+1 ; exponent byte
    ld a, (de)
    sub $7F ; A = exponent + 1 = num digits in mantissa
    ld b, a ; B = num digits in mantissa
    jr convertOP1ToHLLoopEntry
convertOP1ToHLLoop:
    call multHLBy10
convertOP1ToHLLoopEntry:
    ; get next 2 digits of mantissa
    inc de ; DE = pointer to mantissa
    ld a, (de)
    ; Process first mantissa digit
    rrca
    rrca
    rrca
    rrca
    and $0F
    call addHLByA
    ; check number of mantissa digits
    dec b
    ret z
    ; Process second mantissa digit
    call multHLBy10
    ld a, (de)
    and $0F
    call addHLByA
    djnz convertOP1ToHLLoop
    ret
