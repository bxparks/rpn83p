;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Lower level routines for PROB menu functions (PERM, COMB) on Flash Page 1.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Calculate the Permutation function: P(OP1,OP2) = P(n,r) = n!/(n-r)! =
; n(n-1)...(n-r+1). n and r are limited to integers less than 65536 (2^16).
;
; Input: OP1=n; OP2=r
; Output: OP1=P(n,r)
ProbPerm:
    call validatePermComb ; HL=n; DE=r
    ; Do the calculation. Set initial Result to 1 since P(N, 0) = 1.
    push hl
    bcall(_OP1Set1)
    pop hl
    ; Loop r times, multiply by each factor of (n-i)
probPermLoop:
    ld a, e
    or d
    ret z ; return if DE==0
    push de ; stack=[r]
    push hl ; stack=[r,n]
    bcall(_SetXXXXOP2) ; OP2=n
    bcall(_FPMult) ; OP1=n(n-1)...
    pop hl ; stack=[r]; HL=n
    pop de ; stack=[]; DE=r
    dec hl ; n--
    dec de ; r--
    jr probPermLoop

; Description: Calculate the Combination function C(OP1,OP2) = C(n,r) =
; n!/(n-r)!/r! = n(n-1)...(n-r+1)/(r)(r-1)...(1).
;
; Several tricks are used in the code below:
;
; 1) C(n,r) is symmetric with C(n, n-r). So we can make the code faster for
; large r by exchanging r with n-r if r is > (n-r).
;
; 2) If the divisor in the formula below starts with r and counts down to 1,
; then it is possible for intermediate results to be non-integers. The final
; answer is guaranteed to be an integer, but rounding errors in the
; intermediate result may produce a non-integer answer. The solution is to
; start the divisor from 1 and increment *up* to r. See
; https://www.hpmuseum.org/forum/thread-3962.html (2015) for more details.
;
; Input: OP1=n, OP2=r
; Output: OP1=C(n,r)
ProbComb:
#if 0
    bcall(_DebugClear)
#endif
    call validatePermComb ; HL=n; DE=r
    ; Select the smaller of r and (n-r).
    push hl ; stack=[n]
    or a ; CF=0
    sbc hl, de ; HL=n-r
    bcall(_CpHLDE) ; if (n-r)>=r: CF=0
    jr nc, ProbCombNormalized
#if 0
    bcall(_DebugHL) ; Print (n-r) if it's smaller than r.
#endif
    ex de, hl ; DE=n-r
ProbCombNormalized:
    ; Do the calculation. Set initial Result to 1 since C(n,0) = 1.
    bcall(_OP1Set1)
    ; Loop r times, multiply by each factor (n-i), divide by divisor.
    pop hl ; stack=[]; HL=n
    ld b, d
    ld c, e ; BC=r
    ld de, 1 ; DE=1=divisor
probCombLoop:
    ld a, c
    or b
    ret z ; return if BC==0
    push bc ; stack=[r]
    push hl ; stack=[r,n]
    push de ; stack=[r,n,divisor]
    bcall(_SetXXXXOP2) ; OP2=n
    bcall(_FPMult) ; OP1=n(n-1)...
    pop hl ; stack=[r,n]; HL=divisor
    push hl ; stack=[r,n,divisor]
    bcall(_SetXXXXOP2) ; OP2=divisor
    bcall(_FPDiv) ; OP1=n(n-1).../[(1)(2)...(r)]
    pop de ; stack=[r,n]; DE=divisor
    pop hl ; stack=[r]; HL=n
    pop bc ; stack=[]; BC=r
    inc de ; divisor++
    dec hl ; n--
    dec bc ; r--
    jr probCombLoop

;-----------------------------------------------------------------------------

; Validate the n and r parameters of P(n,r) and C(n,r):
;   - n, r are integers in the range of [0,65535]
;   - n >= r
; Input: OP1=Y=n; OP2=X=r
; Output: HL=u16(n); DE=u16(r)
; Destroys: A, BC, DE, HL, OP1, OP2
validatePermComb:
    ; Validate OP1=n
    bcall(_PushRealO2) ; FPS=[r]
    call convertOP1ToHLPageOne ; HL=u16(n)
    push hl ; stack=[u16(n)]
    ; Validate OP2=r
    bcall(_PopRealO1) ; FPS=[]; OP1=r
    call convertOP1ToHLPageOne ; HL=u16(r)
    ex de, hl ; DE=u16(r)
    pop hl ; stack=[]; HL=u16(n)
    ; Check that n >= r
    bcall(_CpHLDE) ; if HL(n)<DE(r): CF=1
    ret nc
    bcall(_ErrDomain) ; throw exception
