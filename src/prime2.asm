;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Various implementations of the primeFactor() function which calculates
; the smallest prime factor, or returns 1 if the number is a prime.
;
; There are at least 4 versions. Each can be selected passing the appropriate
; `-D` flag to `spasm` in the Makefile:
;
; - USE_PRIME_FACTOR_FLOAT
;   - uses TI-OS _FPDiv() and _Frac() routines to determine if `candidate` is a
;   factor of `input`
;   - Benchmarks (15 MHz, TilEm):
;       - 19997*19997: 28.6 seconds
;       - 65521*65521: 94.5 seconds
;       - About 693 effective-candidates / second.
; - USE_PRIME_FACTOR_INT
;   - uses divU32U32() to determine if `candidate` is a factor of `input`
;   - Benchmarks (15 MHz, TilEm, divU32U32):
;       - 19997*19997: 10.7 seconds
;       - 65521*65521: 34.4 seconds
;       - About 1905 effective-candidates / second
; - USE_PRIME_FACTOR_MOD_U32_BY_BC
;   - uses modU32ByBC() to determine if `candidate` is a factor of `input`
;   - Benchmarks (15 MHz, TilEm, modU32ByBC):
;       - 19997*19997: 4.2 seconds
;       - 65521*65521: 12.9 seconds
;       - About 5079 effective-candidates / second.
; - USE_PRIME_FACTOR_MOD_HLSP_BY_BC
;   - uses modHLSPByBC() to determine if `candidate` is a factor of `input`
;   - Benchmarks (15 MHz, TilEm, modHLSPByBC using (SP)):
;       - 19997*19997: 2.9 seconds
;       - 65521*65521: 9.0 seconds
;       - About 7280 effective-candidates / second.
; - USE_PRIME_FACTOR_MOD_HLIX_BY_BC (default)
;   - uses modHLIXByBC() to determine if `candidate` is a factor of `input`
;   - Benchmarks (15 MHz, TilEm, modHLIXByBC):
;       - 65521*65521: 7.0 seconds
;       - About 9360 effective-candidates / second.
;   - Benchmarks (15 MHz, TilEm, modHLIXByBC, rearrange code assuming rare
;   overflow):
;       - 65521*65521: 6.7 seconds
;       - About 9880 effective-candidates / second.
;   - Benchmarks (15 MHz, modHLIXByBC, use JR instead of JP on rare branch):
;       - 65521*65521: 6.6 seconds
;       - About 9927 effective-candidates / second
;   - Benchmarks (15 MHz, modHLIXByBC, remove unnecessary 'or a')
;       - 65521*65521: 6.3 seconds
;       - About 10400 effective-candidates / second
;
; The modHLIXByBC() version is now 15X faster than the floating point version.
;
; All of these take advantage of the fact that every prime above 3 is of the
; form (6n-1) or (6n+1), where n=1,2,3,... It checks candidate divisors from 5
; to sqrt(X), in steps of 6, checking whether (6n-1) or (6n+1) divides into X.
; If the candidate divides into X, X is *not* a prime. If the loop reaches the
; end of the iteration, then no prime factor was found, so X is a prime.
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

primeFactorBreak:
    bcall(_RunIndicOff) ; disable run indicator
    res onInterrupt, (iy + onFlags)
    bcall(_ErrBreak) ; throw exception

;-----------------------------------------------------------------------------

#ifdef USE_PRIME_FACTOR_FLOAT

; Description determine if OP1 is a prime using floating point routines
; provided by the TI-OS. This is the slowest.
;
; Input: OP1:real=input, an integer in the range of [2, 2^32-1].
; Output: OP1:real=1 if prime, or the smallest prime factor if not
; Destroys: all registers, OP2, OP4, OP5, OP6
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

#ifdef USE_PRIME_FACTOR_INT

; Description determine if OP1 is a prime using divU32U32() routine. This is
; almost 3X fastger than primeFactorFloat() but I think we can better.
;
; Input: OP1:real=an integer in the range of [2, 2^32-1].
; Output: OP1:real=1 if prime, or the smallest prime factor if not
; Destroys: all registers, OP1, OP2, OP3, OP4, OP5, OP6
; Throws: if OP1 not an integer
primeFactorInt:
    bcall(_OP1ToOP4) ; OP4=X
    call convertOP1ToU32 ; OP1=int(X); throws if not integer
    ; Calc limit=sqrt(X). The sqrt() function could be done using integer
    ; operations, but it's done only once in the routine, so we don't gain much
    ; speed improvement.
    bcall(_OP1ExOP4) ; OP1=X; OP4=int(X)
    bcall(_SqRoot) ; OP1=sqrt(X), uses OP1-OP3
    bcall(_RndGuard)
    bcall(_Trunc) ; OP1=trunc(sqrt(X)), uses OP1,OP2
    call convertOP1ToU32 ; OP1=limit=int(trunc(sqrt(X)))
    bcall(_OP1ToOP5) ; OP5=limit
    ; Check 2
    ld a, 2
    ld hl, OP6
    call setU32ToA ; OP6=candidate=2
    ld de, OP4 ; OP4=int(X)
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
    bcall(_OP6ToOP1) ; OP1=candidate
    call convertU32ToOP1 ; OP1=float(candidate)
    ret
primeFactorIntYes:
    bcall(_OP1Set1)
    ret

; Description: Check if `candidate` (OP6) is an integer factor of `input` (OP4).
; Input:
;   - OP4:u32=input
;   - OP6:u32=candidate
; Output:
;   - OP1:u32=quotient
;   - OP2:u32=remainder
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
; Input: OP1:real=an integer in the range of [2, 2^32-1].
; Output: OP1:real=1 if prime, or the smallest prime factor if not
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
    jp nz, primeFactorBreak
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

; Description: Check if `candidate` (BC) is an integer factor of `input` (OP1).
; Input:
;   - OP1:u32=x
;   - BC:u16=candidate
; Output:
;   - DE:u16=remainder
;   - ZF=1 if remainder==0
; Destroys: A, DE, HL, OP3
; Preserves: BC, OP1
primeFactorModCheckDiv:
#ifdef USE_PRIME_FACTOR_MOD_U32_BY_BC
    ld hl, OP1
    ld de, OP3
    call copyU32HLToDE ; OP3=x; preserves BC
    ex de, hl ; HL=OP3
    call modU32ByBC ; DE:u16=remainder; destroys (*HL); preserves BC=candidate
#else
    #ifdef USE_PRIME_FACTOR_MOD_HLSP_BY_BC
        call modHLSPByBC
    #else
        ld ix, (OP1) ; IX=low16
        ld hl, (OP1+2) ; HL=high16
        call modHLIXByBC
    #endif
#endif
    ld a, d
    or e ; if remainder==0: ZF=1
    ret

;-----------------------------------------------------------------------------

#ifdef USE_PRIME_FACTOR_MOD_HLSP_BY_BC

; Decription: A specialized version of modU32ByBC() which is faster by storing
; 16-bits of the u32 in HL and the other 16-bits on the stack (SP). I
; implemented this version because my Z80 cheatsheet said (incorrectly) that
; the `add ix, ix` instruction did not exist. Once I realized that `add ix, ix`
; is available, I implemented modHLIXByBC() below.
;
; The benchmark says that this is about 45% faster than modU32ByBC().
;
; Input:
;   - OP1:u32=dividend
;   - BC:u16=divisor
; Output:
;   - DE:u16=remainder
; Destroys: A, HL
modHLSPByBC:
    ; push the dividend (x) to a combination of HL and the stack
    ld hl, (OP1+2) ; HL=high16
    push hl ; stack=[high16]
    ld hl, (OP1) ; HL=low16
    ;
    ld de, 0 ; DE=remainder
    ld a, 32
modHLSPByBCLoop:
    ; shift x by one bit to the left
    add hl, hl
    ex (sp), hl ; stack=[low16]; HL=high16
    adc hl, hl
    ex (sp), hl ; stack=[high16]; HL=low16
    ; shift bit into remainder
    rl e
    rl d ; DE=remainder
    ex de, hl ; HL=remainder; DE=dividend
    jp c, modHLSPByBCOverflow ; remainder overflowed, so substract
    or a ; CF=0
    sbc hl, bc ; HL(remainder) -= divisor
    jp nc, modHLSPByBCNextBit
    add hl, bc ; revert the subtraction
    jp modHLSPByBCNextBit
modHLSPByBCOverflow:
    or a ; reset CF
    sbc hl, bc ; HL(remainder) -= divisor
modHLSPByBCNextBit:
    ex de, hl ; DE=remainder; HL=dividend
    dec a
    jp nz, modHLSPByBCLoop
    pop hl ; stack=[]; HL=high16
    ret

#endif

;-----------------------------------------------------------------------------

; Description: An improved version of modHLSPByBC() which uses IX instead of
; 2 bytes on the stack (SP). This means that the entire computation can be
; performed using just the Z80 registers, without touching RAM. This improves
; PRIM by another 25%. Another 3-4% comes from replacing the sequence of `rl e;
; rl d; ex de, hl` with `ex de, hl; adc hl, hl`. We get a few extra percent
; improvement from selecting a 'jr' or 'jp' instruction judiciously. And
; another 5 percent comes from from deleting an unnecessary 'or a' instruction
; in one of the branches. Overall, this version is a surprising 43% faster than
; modHLSPByBC(). See benchmarks above.
;
; Input:
;   - HL:u16=high 16 bits of u32 dividend
;   - IX:u16=low 16 bits of u32 dividend
;   - BC:u16=divisor
; Output:
;   - DE:u16=remainder
; Destroys: A, HL, IX
modHLIXByBC:
    ld de, 0 ; DE=remainder
    ld a, 32
modHLIXByBCLoop:
    ; shift dividend by one bit to the left
    add ix, ix
    adc hl, hl
    ; shift bit into remainder
    ex de, hl ; HL=remainder; DE=dividend
    adc hl, hl
    ; Use 'jr c' instead of 'jp c' because the common case is expected to be
    ; CF=0, so the branch is not taken, which means only 7 T cycles in the
    ; common case.
    jr c, modHLIXByBCOverflow ; remainder overflowed, so subtract
    sbc hl, bc ; HL(remainder) -= divisor
    ; I *think* CF=0 and CF=1 will occur in equal probability, so it makes
    ; almost no difference whether we use 'jr nc' or 'jp nc'. The 'jr nc'
    ; instruction takes 7 T cycles if the branch is not taken, and 12 cycles if
    ; the branch is taken, for an average of 9.5 cycles. The 'jp nc'
    ; instruction takes 10 cycles whether or not the branch is taken. The
    ; difference is so small, I prefer the predictability of 'jp nc' always
    ; taking 10 cycles.
    jp nc, modHLIXByBCNextBit
    add hl, bc ; revert the subtraction
modHLIXByBCNextBit:
    ex de, hl ; DE=remainder; HL=dividend
    dec a
    ; Use 'jp nz' instead of 'jr nz' because 'jp nz' is faster in the common
    ; case of ZF=0 when the branch is taken 32 times.
    jp nz, modHLIXByBCLoop
    ret
modHLIXByBCOverflow:
    ; This branch (CF=1) is more rare than (CF=0) because it will happen only
    ; after the 16th iteration.
    or a ; reset CF
    sbc hl, bc ; HL(remainder) -= divisor
    jp modHLIXByBCNextBit
