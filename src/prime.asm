;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Various implementations of the isprime() function.
;-----------------------------------------------------------------------------

#ifdef DEBUG

; Description determine if OP1 is a prime using floating point routines
; provided by the TI-OS.
; Input: OP1: an integer in the range of [2, 2^32-1].
; Output: OP1: 1 if prime, smallest prime factor if not
; Destroys: all registers, OP2, OP4, OP5, OP6
;
; Benchmarks:
;   - 4001*4001: 15 seconds
;   - 10007*10009: 36 seconds
;   - 19997*19997: 72 seconds
; About 280 effective-candidates / second.
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
    bit onInterrupt, (IY+onFlags)
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
    res onInterrupt, (IY+onFlags)
    bjump(_ErrBreak) ; throw exception

;-----------------------------------------------------------------------------

; Description determine if OP1 is a prime using U32 integer routines in
; integer.asm.
; Input: OP1: an integer in the range of [2, 2^32-1].
; Output: OP1: 1 if prime, smallest prime factor if not
; Destroys: all registers, OP1, OP2, OP3, OP4, OP5, OP6
;
; Benchmarks:
;   - 4001*4001: 5 seconds
;   - 10007*10009: 14 seconds
;   - 19997*19997: 27 seconds
; About 750-800 effective-candidates / second.
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
    call cpU32U32 ; if X==2: ZF=1
    jr z, primeFactorIntYes
    ; Check divisible by 2
    call primeFactorIntCheckDiv
    jr z, primeFactorIntNo
    ; Check 3
    ld a, 3
    ld hl, OP6
    call setU32ToA ; OP6=candidate=3
    ld de, OP4
    call cpU32U32 ; if X==3: ZF=1
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
    call cpU32U32 ; if limit < candidate: CF=1
    jr c, primeFactorIntYes
    ; Check for ON/Break
    bit onInterrupt, (IY+onFlags)
    jr nz, primeFactorBreak
    ; Check (6n-1)
    call primeFactorIntCheckDiv
    jr z, primeFactorIntNo
    ; OP6+=2
    ld a, 2
    ld hl, OP6
    call addU32U8
    ; Check (6n+1)
    call primeFactorIntCheckDiv
    jr z, primeFactorIntNo
    ; OP6+=4
    ld a, 4
    ld hl, OP6
    call addU32U8
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
