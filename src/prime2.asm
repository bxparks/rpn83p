;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Various implementations of the primeFactor() function which calculates
; the smallest prime factor, or 1 if the number is a prime.
;
; All of these take advantage of the fact that every prime above 3 is of the
; form (6n-1) or (6n+1), where n=1,2,3,... It checks candidate divisors from 5
; to sqrt(X), in steps of 6, checking whether (6n-1) or (6n+1) divides into X.
; If the candidate divides into X, X is *not* a prime. If the loop reaches the
; end of the iteration, then no prime factor was found, so X is a prime.
;-----------------------------------------------------------------------------

#ifdef USE_PRIME_FACTOR_FLOAT

; Description determine if OP1 is a prime using floating point routines
; provided by the TI-OS. This is the slowest.
;
; Input: OP1: an integer in the range of [2, 2^32-1].
; Output: OP1: 1 if prime, smallest prime factor if not
; Destroys: all registers, OP2, OP4, OP5, OP6
;
; Benchmarks (6 MHz):
;   - 4001*4001: 15 seconds
;   - 10007*10007: 36 seconds
;   - 19997*19997: 72 seconds
;   - About 280 effective-candidates / second.
primeFactorFloat:
    ; Check 2
    bcall(_OP2Set2) ; OP2 = 2
    bcall(_CpOP1OP2) ; if OP1==2: ZF=1
    jr z, primeFactorFloatYes
    ; Check div by 2
    call primeFactorFloatCheckDiv
    jr z, primeFactorFloatNo
    ; Check 3
    bcall(_OP4ToOP1) ; OP1 = X
    bcall(_OP2Set3) ; OP2 = 3
    bcall(_CpOP1OP2) ; if OP1==3: ZF=1
    jr z, primeFactorFloatYes
    ; Check div by 3
    call primeFactorFloatCheckDiv
    jr z, primeFactorFloatNo
primeFactorFloatLoopSetup:
    ; start with candidate=5, first of the form (6k +/- 1)
    ; OP4=original X
    ; OP5=limit
    ; OP6=candidate
    bcall(_OP4ToOP1)
    bcall(_SqRoot) ; OP1 = sqrt(X)
    bcall(_RndGuard)
    bcall(_Trunc) ; OP1 = trunc(sqrt(X))
    bcall(_OP1ToOP5) ; OP5=limit
    bcall(_OP2Set5)
    bcall(_OP2ToOP6) ; OP6=candidate=5
    bcall(_RunIndicOn) ; enable run indicator
primeFactorFloatLoop:
    ; Check if loop limit reached
    bcall(_OP6ToOP2) ; OP2=candidate
    bcall(_OP5ToOP1) ; OP1=limit
    bcall(_CpOP1OP2) ; if limit < candidate: CF=1
    jr c, primeFactorFloatYes
    ; Check for ON/Break
    bit onInterrupt, (iy + onFlags)
    jr nz, primeFactorBreak
    ; Check (6n-1)
    bcall(_OP4ToOP1) ; OP1 = X
    bcall(_OP6ToOP2) ; OP2 = candidate
    call primeFactorFloatCheckDiv
    jr z, primeFactorFloatNo
    ; Check (6n+1)
    bcall(_OP6ToOP1) ; OP1 = candidate
    bcall(_OP2Set2)
    bcall(_FPAdd) ; OP1+=2
    bcall(_OP1ToOP6) ; candidate+=2
    bcall(_OP1ToOP2) ; OP2=candidate
    bcall(_OP4ToOP1) ; OP1=X
    call primeFactorFloatCheckDiv
    jr z, primeFactorFloatNo
    ; OP6 += 4
    bcall(_OP6ToOP1) ; OP1 = candidate
    bcall(_OP2Set4) ; OP2=4
    bcall(_FPAdd) ; OP1+=4
    bcall(_OP1ToOP6) ; candidate+=4
    jr primeFactorFloatLoop
primeFactorFloatNo:
    bcall(_OP2ToOP1)
    ret
primeFactorFloatYes:
    bcall(_OP1Set1)
    ret

; Description: Determine if OP2 is an integer factor of OP1.
; Output: ZF=1 if OP2 is a factor, 0 if not
; Destroys: OP1
primeFactorFloatCheckDiv:
    bcall(_FPDiv) ; OP1 = OP1/OP2
    bcall(_Frac) ; convert to frac part, preserving sign
    bcall(_CkOP1FP0) ; if OP1 == 0: ZF=1
    ret

#endif

;-----------------------------------------------------------------------------

primeFactorBreak:
    bcall(_RunIndicOff) ; disable run indicator
    res onInterrupt, (iy + onFlags)
    bcall(_ErrBreak) ; throw exception

;-----------------------------------------------------------------------------

#ifdef USE_PRIME_FACTOR_INT

; Description determine if OP1 is a prime using divU32U32() routine. This is
; almost 3X fastger than primeFactorFloat() but I think we can better.
;
; Input: OP1: an integer in the range of [2, 2^32-1].
; Output: OP1: 1 if prime, smallest prime factor if not
; Destroys: all registers, OP1, OP2, OP3, OP4, OP5, OP6
;
; Benchmarks (6 MHz):
;
; Using divU32U32():
;   - 4001*4001: 5 seconds
;   - 10007*10007: 14 seconds
;   - 19997*19997: 27 seconds
;   - About 750-800 effective-candidates / second.
primeFactorInt:
    ld hl, OP4
    call convertOP1ToU32 ; OP4=X
    ; Calc root(X) to OP5, to get it out of the way. The sqrt() function could
    ; be done using integer operations, but it's done only once in the routine,
    ; so we don't gain much speed improvement.
    bcall(_SqRoot) ; OP1 = sqrt(OP1), uses OP1-OP3
    bcall(_RndGuard)
    bcall(_Trunc) ; OP1 = trunc(sqrt(X)), uses OP1,OP2
    ld hl, OP5
    call convertOP1ToU32 ; OP5=limit=sqrt(X)
    ; Check 2
    ld a, 2
    ld hl, OP6
    call setU32ToA ; OP6=candidate=2
    ld de, OP4
    call cmpU32U32 ; if X==2: ZF=1
    jr z, primeFactorIntYes
    ; Check divisible by 2
    call primeFactorIntCheckDiv
    jr z, primeFactorIntNo
    ; Check 3
    ld a, 3
    ld hl, OP6
    call setU32ToA ; OP6=candidate=3
    ld de, OP4
    call cmpU32U32 ; if X==3: ZF=1
    jr z, primeFactorIntYes
    ; Check divisible by 3
    call primeFactorIntCheckDiv
    jr z, primeFactorIntNo
primeFactorIntSetup:
    ld a, 5
    ld hl, OP6
    call setU32ToA
    bcall(_RunIndicOn) ; enable run indicator
    ; OP4=X
    ; OP5=limit
    ; OP6=candidate
primeFactorIntLoop:
    ld de, OP6 ; DE=OP6=candidate
    ld hl, OP5 ; HL=OP5=limit
    call cmpU32U32 ; if limit < candidate: CF=1
    jr c, primeFactorIntYes
    ; Check for ON/Break
    bit onInterrupt, (iy + onFlags)
    jr nz, primeFactorBreak
    ; Check (6n-1)
    call primeFactorIntCheckDiv
    jr z, primeFactorIntNo
    ; OP6+=2
    ld a, 2
    ld hl, OP6
    call addU32ByA
    ; Check (6n+1)
    call primeFactorIntCheckDiv
    jr z, primeFactorIntNo
    ; OP6+=4
    ld a, 4
    ld hl, OP6
    call addU32ByA
    jr primeFactorIntLoop
primeFactorIntNo:
    ld hl, OP6
    call convertU32ToOP1
    ret
primeFactorIntYes:
    bcall(_OP1Set1)
    ret

; Input:
;   - OP4=X
;   - OP6=candidate
; Output:
;   - OP1=quotient
;   - OP2=remainder
;   - ZF=1 if remainder==0
; Destroys: A, BC, DE, HL
primeFactorIntCheckDiv:
    ld hl, OP4
    ld de, OP1
    call copyU32HLToDE ; OP1=X
    ex de, hl ; HL=OP1=X
    ld de, OP6 ; DE=OP6=candidate
    ld bc, OP2 ; BC=OP2=remainder
    call divU32U32 ; HL=OP1=quotient, BC=OP2=remainder
    call testU32BC ; ZF=1 if remainder 0
    ret

#endif

;-----------------------------------------------------------------------------

; Description determine if OP1 is a prime using the modU32ByBC() routine. This
; is 7X faster than primeFactorFloat(), and 2.5X faster than primeFactorInt().
;
; Benchmarks (6 MHz, modU32ByBC):
;   - 4001*4001: 2.4 seconds
;   - 10007*10007: 5.5 seconds
;   - 19997*19997: 10.5 seconds
;   - 65521*65521: 33 seconds
;   - About 2000 effective-candidates / second.
;
; Benchmarks (15 MHz, modU32ByBC):
;   - 4001*4001: 1.0 seconds
;   - 10007*10007: 2.3 seconds
;   - 19997*19997: 4.2 seconds
;   - 65521*65521: 12.9 seconds
;   - About 5000 effective-candidates / second.
;
; Benchmarks (15 MHz, modOP1ByBC):
;   - 4001*4001: 0.85 seconds
;   - 10007*10007: 1.6 seconds
;   - 19997*19997: 2.9 seconds
;   - 65521*65521: 9.0 seconds
;   - About 7280 effective-candidates / second.
;
; Input: OP1: an integer in the range of [2, 2^32-1].
; Output: OP1: 1 if prime, smallest prime factor if not
; Destroys: all registers, OP1-OP3
primeFactorMod:
    call pushRaw9Op1 ; FPS=[X]; HL=X
    ; Calc root(X) to OP5, to get it out of the way. The sqrt() function could
    ; be done using integer operations, but it's done only once in the routine,
    ; so we don't gain much speed improvement.
    bcall(_SqRoot) ; OP1 = sqrt(OP1), uses OP1-OP3
    bcall(_RndGuard)
    bcall(_Trunc) ; OP1 = trunc(sqrt(X)), uses OP1,OP2
    call convertOP1ToU32 ; OP1:u32=limit=sqrt(X)
    call op1ToOp2PageTwo ; OP2:u32=limit
    call popRaw9Op1 ; FPS=[]; OP1=X
    call convertOP1ToU32 ; HL=OP1:u32=x
    ; Check equals 2
    ld bc, 2 ; BC=candidate=2
    ld a, c
    ld hl, OP1
    call cmpU32WithA ; if x==2: ZF=1
    jr z, primeFactorModYes
    ; Check divisible by 2
    call primeFactorModCheckDiv ; ZF=1 if remainder==0
    jr z, primeFactorModNo
    ; Check equals 3
    inc bc ; BC=candidate=3
    ld a, c
    ld hl, OP1
    call cmpU32WithA ; if x==3: ZF=1
    jr z, primeFactorModYes
    ; Check divisible by 3
    call primeFactorModCheckDiv ; ZF=1 if remainder==0
    jr z, primeFactorModNo
primeFactorModSetup:
    inc bc
    inc bc ; BC=candidate=5
    bcall(_RunIndicOn) ; enable run indicator
    ; OP1:u32=x
    ; OP2:u16=limit
    ; BC:u16=candidate
primeFactorModLoop:
    ld hl, (OP2) ; HL=limit
    or a ; clear CF
    sbc hl, bc ; CF=1 if candidate>limit
    jr c, primeFactorModYes
    ; Check for ON/Break
    bit onInterrupt, (iy + onFlags)
    jr nz, primeFactorBreak
    ; Check (6n-1)
    call primeFactorModCheckDiv ; ZF=1 if remainder==0
    jr z, primeFactorModNo
    ; candidate+=2
    inc bc
    inc bc
    ; Check (6n+1)
    call primeFactorModCheckDiv ; ZF=1 if remainder==0
    jr z, primeFactorModNo
    ; candidate+=4
    inc bc
    inc bc
    inc bc
    inc bc
    jr primeFactorModLoop
primeFactorModNo:
    ld (OP1), bc ; OP1=candidate
    ld hl, 0
    ld (OP1+2), hl
    call convertU32ToOP1 ; OP1=real(candidate)
    ret
primeFactorModYes:
    bcall(_OP1Set1)
    ret

; Input:
;   - OP1:u32=x
;   - BC:u16=candidate
; Output:
;   - DE:u16=remainder
;   - ZF=1 if remainder==0
; Destroys: A, DE, HL, OP3
; Preserves: BC, OP1
primeFactorModCheckDiv:
#ifdef USE_PRIME_FACTOR_U32_BY_BC
    ld hl, OP1
    ld de, OP3
    call copyU32HLToDE ; OP3=x; preserves BC
    ex de, hl ; HL=OP3
    call modU32ByBC ; DE:u16=remainder; destroys (*HL); preserves BC=candidate
#else
    call modOP1ByBC
#endif
    ld a, d
    or e ; if remainder==0: ZF=1
    ret

; Decription: Highly specialized version of modU32ByBC() to get the highest
; performance. For example, uses 'jp' instead 'jr' because 'jp' is faster. I
; tried to use IX instead of the stack (SP), but the Z80 does not support 'add
; ix,ix' or 'adc ix,ix' which forced the use of the stack anyway. The benchmark
; says that this is about 45% faster than modU32ByBC().
;
; Input:
;   - OP1:u32=dividend
;   - BC:u16=divisor
; Output:
;   - DE:u16=remainder
; Destroys: A, HL
modOP1ByBC:
    ; push the dividend (x) to a combination of HL and the stack
    ld hl, (OP1+2) ; HL=high16
    push hl ; stack=[high16]
    ld hl, (OP1) ; HL=low16
    ;
    ld de, 0 ; DE=remainder
    ld a, 32
modOP1ByBCCheckDivLoop:
    ; shift x by one bit to the left
    add hl, hl
    ex (sp), hl ; stack=[low16]; HL=high16
    adc hl, hl
    ex (sp), hl ; stack=[high16]; HL=low16
    ; shift bit into remainder
    rl e
    rl d ; DE=remainder
    ex de, hl ; HL=remainder; DE=dividend
    jp c, modOP1ByBCCheckDivOverflow ; remainder overflowed, so substract
    or a ; CF=0
    sbc hl, bc ; HL(remainder) -= divisor
    jp nc, modOP1ByBCCheckDivNextBit
    add hl, bc ; revert the subtraction
    jp modOP1ByBCCheckDivNextBit
modOP1ByBCCheckDivOverflow:
    or a ; reset CF
    sbc hl, bc ; HL(remainder) -= divisor
modOP1ByBCCheckDivNextBit:
    ex de, hl ; DE=remainder; HL=dividend
    dec a
    jp nz, modOP1ByBCCheckDivLoop
    pop hl ; stack=[]; HL=high16
    ret

;-----------------------------------------------------------------------------

; Description: Choose one of the various primeFactorXXX() routines.
; Input:
;   - OP1:real=input
; Output:
;   - OP1=1 if prime, or its smallest prime factor (>1) otherwise
; Throws: Err:Domain if OP1 is not an integer in the interval [2,2^32-1].
PrimeFactor:
    ; TODO: Replace the following validation with convertOP1ToU32(). I think we
    ; just need to check for 0 and 1. Oh, and create a sqrtU32() replacement
    ; for the floating point function _SqRoot().
    ;
    ; Check 0
    bcall(_CkOP1FP0)
    jr z, primeFactorError
    ; Check 1
    bcall(_OP2Set1) ; OP2 = 1
    bcall(_CpOP1OP2) ; if OP1==1: ZF=1
    jr z, primeFactorError
    bcall(_OP1ToOP4) ; save OP4 = X
    ; Check integer >= 0
    bcall(_CkPosInt) ; if OP1 >= 0: ZF=1
    jr nz, primeFactorError
    ; Check unsigned 32-bit integer, i.e. < 2^32.
    call op2Set2Pow32PageTwo ; if OP1 >= 2^32: CF=0
    bcall(_CpOP1OP2)
    jr nc, primeFactorError

#ifdef USE_PRIME_FACTOR_FLOAT
    jp primeFactorFloat
#else
    #ifdef USE_PRIME_FACTOR_INT
        jp primeFactorInt
    #else
        jp primeFactorMod
    #endif
#endif

primeFactorError:
    bcall(_ErrDomain) ; throw exception
