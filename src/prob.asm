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
; n(n-1)...(n-r+1)
;
; TODO: (n,r) are limited to [0.255]. It should be relatively easy to extended
; the range to [0,65535].
;
; Input: OP1=Y=n; OP2=X=r
; Output: OP1=P(n,r)
ProbPerm:
    call validatePermComb ; C=n; E=r
    ; Do the calculation. Set initial Result to 1 since P(N, 0) = 1.
    bcall(_OP1Set1)
    ld a, e ; A=r
    or a
    ret z
    ; Loop r times, multiple by (y-i)
    ld b, a ; B=r, C=n
probPermLoop:
    push bc
    ld l, c ; L=C=n
    ld h, 0 ; HL=n
    bcall(_SetXXXXOP2)
    bcall(_FPMult)
    pop bc
    dec c
    djnz probPermLoop
    ret

; Description: Calculate the Combination function C(OP1,OP2) = C(n,r) =
; n!/(n-r)!/r! = n(n-1)...(n-r+1)/(r)(r-1)...(1).
;
; TODO: (n,r) are limited to [0.255]. It should be relatively easy to extended
; the range to [0,65535].
;
; TODO: This algorithm below is a variation of the algorithm used for P(n,r)
; above, with a division operation inside the loop that corresponds to each
; term of the `r!` divisor. However, the division can cause intermediate result
; to be non-integral. Eventually the final answer will be an integer, but
; that's not guaranteed until the end of the loop. I think it should be
; possible to rearrange the order of these divisions so that the intermediate
; results are always integral.
;
; Input: OP1=Y=n, OP2=X=r
; Output: OP1=C(n,r)
ProbComb:
    call validatePermComb ; C=n; E=r
    ; Do the calculation. Set initial Result to 1 since C(n,0) = 1.
    bcall(_OP1Set1)
    ld a, e ; A=r
    or a
    ret z
    ; Loop r times, multiple by (n-i), divide by i.
    ld b, a ; B=r, C=n
probCombLoop:
    push bc
    ld l, c ; L=C=n
    ld h, 0 ; HL=n
    bcall(_SetXXXXOP2) ; OP2=n
    bcall(_FPMult)
    pop bc
    push bc
    ld l, b ; L=B=r
    ld h, 0 ; HL=r
    bcall(_SetXXXXOP2) ; OP2=r
    bcall(_FPDiv)
    pop bc
    dec c
    djnz probCombLoop
    ret

;-----------------------------------------------------------------------------

; Validate the n and r parameters of P(n,r) and C(n,r):
;   - n, r are integers in the range of [0,255]
;   - n >= r
; Input: OP1=Y=n; OP2=X=r
; Output: C=n=int(OP1); E=r=int(OP2)
; Destroys: A, BC, DE, HL, OP1, OP2
validatePermComb:
    ; Validate OP1=n
    bcall(_PushRealO2) ; FPS=[r]
    call validatePermCombParam
    bcall(_ConvOP1) ; DE=int(n)
    push de ; stack=[int(n)]
    ; Validate OP2=r
    bcall(_PopRealO1) ; FPS=[]; OP1=r
    call validatePermCombParam
    bcall(_ConvOP1) ; DE=int(r)
    pop bc ; BC=int(n)
    ; Check that n >= r
    ld a, c ; A=n
    cp e ; if n<r: CF=1
    ret nc
    bcall(_ErrDomain) ; throw exception

; Validate OP1 is an integer in the range of [0, 255].
; Input: OP1
; Output: throws ErrDomain if outside of range
; Destroys: all, OP2
validatePermCombParam:
    bcall(_CkPosInt) ; if OP1 >= 0: ZF=1
    jr nz, validatePermCombError
    ld hl, 256
    bcall(_SetXXXXOP2) ; OP2=256
    bcall(_CpOP1OP2) ; destroys all
    ret c ; ok if OP1 < 255
validatePermCombError:
    bcall(_ErrDomain) ; throw exception
