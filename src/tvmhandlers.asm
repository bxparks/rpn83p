;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; TVM menu handlers. The equations and algorithms to calculate N, i, PV, PMT,
; and FV as a function of the other 4 variables are described in detail in the
; TVM.md document.
;
; The handling of rpnFlagsTvmCalculate is a bit tricky so let's write it down
; for posterity:
;
; - If any TVM variable or parameter is Stored, then set the
; rpnFlagsTvmCalculate flag, causing the next TVM button to Calculate. This
; includes the BEG and END which set or clear the tvmIsBegin flag.
;
; - If a `2ND` menu button is invoked, causing a recall of the specified TVM
; variable, then clear the rpnFlagsTvmCalculate flag, causing the next TVM
; button to Store. This makes sense because a value was just recalled into the
; X register.
;
; - If a TVM menu button performed a Calculate, then keep the
; rpnFlagsTvmCalculate flag set, so that another TVM menu button performs
; another Calculate.
;-----------------------------------------------------------------------------

; Description: Reset all of the TVM variables. This is performed only when
; restoreAppState() fails.
initTvm:
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call tvmClear
    ; [[fallthrough]]

; Description: Reset the TVM Solver status. This is always done at App start.
initTvmSolver:
    xor a
    ld (tvmSolverIsRunning), a
    ret

;-----------------------------------------------------------------------------
; Store and recall the TVM variables.
;-----------------------------------------------------------------------------

; Description: Recall fin_N to OP1.
rclTvmN:
    ld hl, fin_N
    jp move9ToOp1

; Description: Store OP1 to fin_N.
stoTvmN:
    ld de, fin_N
    jp move9FromOp1

; Description: Recall fin_I to OP1.
rclTvmIYR:
    ld hl, fin_I
    jp move9ToOp1

; Description: Store OP1 to fin_I.
stoTvmIYR:
    ld de, fin_I
    jp move9FromOp1

; Description: Recall fin_PV to OP1.
rclTvmPV:
    ld hl, fin_PV
    jp move9ToOp1

; Description: Store OP1 to fin_PV.
stoTvmPV:
    ld de, fin_PV
    jp move9FromOp1

; Description: Recall fin_PMT to OP1.
rclTvmPMT:
    ld hl, fin_PMT
    jp move9ToOp1

; Description: Store OP1 to fin_PMT.
stoTvmPMT:
    ld de, fin_PMT
    jp move9FromOp1

; Description: Recall fin_N to OP1.
rclTvmFV:
    ld hl, fin_FV
    jp move9ToOp1

; Description: Store OP1 to fin_FV.
stoTvmFV:
    ld de, fin_FV
    jp move9FromOp1

; Description: Recall fin_PY to OP1.
rclTvmPYR:
    ld hl, fin_PY
    jp move9ToOp1

; Description: Store OP1 to fin_PY. Store the same value in fin_CY so that if
; we go back to the TI-OS and use the built-in "Financial" app, the same
; compounding frequency will appear there under "C/Y".
stoTvmPYR:
    ld de, fin_PY
    call move9FromOp1
    ld de, fin_CY
    call move9FromOp1
    ret

;-----------------------------------------------------------------------------
; Workspace variables used by the TVM Solver.
;-----------------------------------------------------------------------------

; Description: Recall tvmIYR0 to OP1.
rclTvmIYR0:
    ld hl, tvmIYR0
    jp move9ToOp1

; Description: Store OP1 to tvmIYR0 variable.
stoTvmIYR0:
    ld de, tvmIYR0
    jp move9FromOp1

; Description: Recall tvmIYR1 to OP1.
rclTvmIYR1:
    ld hl, tvmIYR1
    jp move9ToOp1

; Description: Store OP1 to tvmIYR1 variable.
stoTvmIYR1:
    ld de, tvmIYR1
    jp move9FromOp1

; Description: Recall tvmIterMax to OP1.
rclTvmIterMax:
    ld a, (tvmIterMax)
    call convertU8ToOP1
    ret

; Description: Store OP1 to tvmIterMax variable.
stoTvmIterMax:
    ld hl, OP3
    call convertOP1ToU8 ; hl=OP3=U8; throws Err:Domain if larger than u8
    ld a, (hl)
stoTvmIterMaxA: ; alt version that stores A
    or a
    jr z, stoTvmIterMaxErr ; IterMax cannot be 0
    ld (tvmIterMax), a
    ret
stoTvmIterMaxErr:
    bcall(_ErrDomain)

;-----------------------------------------------------------------------------

; Description: Recall tvmI0 to OP1.
rclTvmI0:
    ld hl, tvmI0
    jp move9ToOp1

; Description: Store OP1 to tvmI0 variable.
stoTvmI0:
    ld de, tvmI0
    jp move9FromOp1

; Description: Recall tvmI1 to OP1.
rclTvmI1:
    ld hl, tvmI1
    jp move9ToOp1

; Description: Store OP1 to tvmI1 variable.
stoTvmI1:
    ld de, tvmI1
    jp move9FromOp1

; Description: Recall tvmNPMT0 to OP1.
rclTvmNPMT0:
    ld hl, tvmNPMT0
    jp move9ToOp1

; Description: Store OP1 to tvmNPMT0 variable.
stoTvmNPMT0:
    ld de, tvmNPMT0
    jp move9FromOp1

; Description: Recall tvmNPMT1 to OP1.
rclTvmNPMT1:
    ld hl, tvmNPMT1
    jp move9ToOp1

; Description: Store OP1 to tvmNPMT1 variable.
stoTvmNPMT1:
    ld de, tvmNPMT1
    jp move9FromOp1

; Description: Recall the TVM solver iteration counter as a float in OP1.
rclTvmSolverCount:
    ld a, (tvmSolverCount)
    call convertU8ToOP1 ; OP1=float(A)
    ret

;-----------------------------------------------------------------------------
; Lower-level routines that calculate various terms and coefficients of the
; various TVM equations.
;-----------------------------------------------------------------------------

; Description: Return the fractional interest rate per period.
; Input:
;   - rclTvmIYR
;   - rclTvmPYR
; Output:
;   - OP1 = i = IYR / PYR / 100.
getTvmIntPerPeriod:
    call rclTvmIYR
    ; [[fallthrough]]

; Description: Compute the interest rate per period for given annual interest
; rate in OP1.
; Input: OP1=IYR=annual interest percent
; Output: OP1=IYR/PYR/100
; Preserves: OP2
calcTvmIntPerPeriod:
    bcall(_PushRealO2) ; FPS=[OP2]
    call op1ToOP2
    call rclTvmPYR
    call op1ExOp2
    bcall(_FPDiv) ; OP1=I/PYR
    call op2Set100
    bcall(_FPDiv) ; OP1=I/PYR/100
    bcall(_PopRealO2) ; FPS=[]
    ret

; Description: Compute the I%/YR from the fractional interest per period.
; Input: OP1=i=fractional interest per period
; Output: OP1=IYR=percent per year=i*PYR*100
; Preserves: OP2
calcTvmIYR:
    bcall(_PushRealO2) ; FPS=[OP2]
    call op1ToOP2
    call rclTvmPYR
    bcall(_FPMult)
    call op2Set100
    bcall(_FPMult)
    bcall(_PopRealO2) ; FPS=[]
    ret

;-----------------------------------------------------------------------------

; Description: Return OP1 = p = {0.0 if END, 1.0 if BEGIN}.
; Destroys: A, HL, OP1
getTvmEndBegin:
    ld a, (tvmIsBegin)
    or a
    jr nz, getTvmBegin
getTvmEnd:
    bcall(_OP1Set0)
    ret
getTvmBegin:
    bcall(_OP1Set1)
    ret

; Description: Return OP1=(1+ip) which distinguishes between payment at BEGIN
; (p=1) versus payment at END (p=0).
; Input: OP1=i
; Output: OP1=1+ip
; Destroys: all, OP1
; Preserves: OP2
beginEndFactor:
    ld a, (tvmIsBegin)
    or a
    jr nz, beginFactor
endFactor:
    bcall(_OP1Set1) ; OP1=1.0
    ret
beginFactor:
    bcall(_PushRealO2) ; FPS=[OP2 saved]
    bcall(_Plus1) ; OP1=1+i
    bcall(_PopRealO2) ; FPS=[]; OP2=OP2 saved
    ret

; Description: Calculate the compounding factor defined by: [(1+i)^N-1]/i.
; Input:
;   - rclTvmIYR
;   - rclTvmPYR
;   - rclTvmN
; Output:
;   - OP1=CF1(i)=(1+i)^N=exp(N*log1p(i))
;   - OP2=CF3(i)=(1+ip)[(i+i)^N-1]/i=(1+ip)(expm1(N*log1p(i))/i)
; Destroys: OP1-OP5
compoundingFactors:
#ifdef TVM_NAIVE
    ; Use the TVM formulas directly, which can suffer from cancellation errors
    ; for small i.
    call getTvmIntPerPeriod ; OP1=i
    bcall(_PushRealO1) ; FPS=[i]
    bcall(_PushRealO1) ; FPS=[i,i]
    call rclTvmN ; OP1=N
    call exchangeFPSOP1 ; FPS=[i,N]; OP1=i
    bcall(_PushRealO1) ; FPS=[i,N,i]
    call beginEndFactor ; OP1=(1+ip)
    call exchangeFPSOP1 ; FPS=[i,N,1+ip]; OP1=i
    bcall(_Plus1) ; OP1=1+i (destroys OP2)
    call exchangeFPSFPS ; FPS=[i,1+ip,N]
    bcall(_PopRealO2) ; FPS=[i,1+ip] OP2=N
    bcall(_YToX) ; OP1=(1+i)^N
    bcall(_OP1ToOP4) ; OP4=(1+i)^N (save)
    bcall(_Minus1) ; OP1=(1+i)^N-1
    call exchangeFPSFPS ; FPS=[1+ip,i]
    bcall(_PopRealO2) ; FPS=[1+ip]; OP2=i
    bcall(_FPDiv) ; OP1=[(1+i)^N-1]/i (destroys OP3)
    bcall(_PopRealO2) ; FPS=[]; OP2=1+ip
    bcall(_FPMult) ; OP1=(1+ip)[(1+i)^N-1]/i
    call op1ToOP2 ; OP2=(1+ip)[(1+i)^N-1]/i
    bcall(_OP4ToOP1) ; OP1=(1+i)^N
    ret
#else
    ; Use log1p() and expm1() functions to avoid cancellation errors.
    ;   - OP1=CF1(i)=(1+i)^N=exp(N*log1p(i))
    ;   - OP2=CF3(i)=(1+ip)[(i+i)^N-1]/i=(1+ip)(expm1(N*log1p(i))/i)
    call getTvmIntPerPeriod ; OP1=i
    bcall(_CkOP1FP0) ; check if i==0.0
    ; CF3(i) has a removable singularity at i=0, so we use a different formula.
    jr z, compoundingFactorsZero
    bcall(_PushRealO1) ; FPS=[i]
    call lnOnePlus ; OP1=ln(1+i)
    call op1ToOP2
    call rclTvmN ; OP1=N
    bcall(_FPMult) ; OP1=N*ln(1+i)
    bcall(_PushRealO1) ; FPS=[i,N*ln(1+i)]
    call exchangeFPSFPS ; FPS=[N*ln(1+i),i]
    call expMinusOne ; OP1=exp(N*ln(1+i))-1
    call exchangeFPSOP1 ; FPS=[N*ln(1+i),exp(N*ln(1+i))-1]; OP1=i
    bcall(_PushRealO1) ; FPS=[N*ln(1+i),exp(N*ln(1+i))-1,i]; OP1=i
    call beginEndFactor ; OP1=(1+ip)
    bcall(_OP1ToOP4) ; OP4=(1+ip) (save)
    bcall(_PopRealO2) ; FPS=[N*ln(1+i),exp(N*ln(1+i))-1]; OP2=i
    bcall(_PopRealO1) ; FPS=[N*ln(1+i)]; OP1=exp(N*ln(1+i))-1
    bcall(_FPDiv) ; OP1=[exp(N*ln(1+i))-1]/i
    bcall(_OP4ToOP2) ; OP2=(1+ip)
    bcall(_FPMult) ; OP1=CF3=(1+ip)[exp(N*ln(1+i))-1]/i
    call exchangeFPSOP1 ; FPS=[CF3]; OP1=N*ln(1+i)
    bcall(_EToX) ; OP1=exp(N*ln(1+i))
    bcall(_PopRealO2) ; FPS=[]; OP2=CF3
    ret
compoundingFactorsZero:
    ; If i==0, then CF1=1 and CF3=N
    call rclTvmN
    call op1ToOP2 ; OP2=CF3=N
    bcall(_OP1Set1) ; OP1=CF1=1
    ret
#endif

;-----------------------------------------------------------------------------

; Description: Determine if the TVM equation has NO solutions. This algorithm
; detects a *sufficient* condition for an equation to have no solutions. In
; other words, there may be TVM equations with zero solutions which are not
; detected by this function.
;
; From https://github.com/thomasokken/plus42desktop/issues/2, use Descartes
; Rules of Signs (https://en.wikipedia.org/wiki/Descartes%27_rule_of_signs).
;
; The non-zero coefficients of the NFV() polynomial are:
;
;   - PV+PMT*p
;   - PMT
;   - PMT*(1-p)+FV.
;
; where p=BEGIN is 0 for payment at END, and 1 for payment at BEG.
;
; If they all have the same sign, then there are no solutions. If there is only
; a single sign change, then one positive solution. If there are 2 sign
; changes, then there are 0 or 2 positive solutions.
;
; This routine figures out whether all the coefficients have the same sign. It
; is somewhat tricky because we have to ignore coefficients which are exactly
; zero, and we need to consider both negative and positive signs. There are
; probably multiple ways to solve this, but the solution that I created was to
; use 2 counters/accumulators:
;
; 1) numNonZero: the number of non-zero coefficients from the above 3, and
; 2) sumSign: the sum of the sign bit of each non-zero coefficient (where the
; sign bit of a floating point number is 1 if negative, 0 if positive).
;
; If numNonZero==0, then we have a degenerate situation where all the terms of
; the NPV() polynomial are 0, so any I%YR will actually fit the solution.
; Return NO SOLUTION.
;
; If sumSign==numNonZero OR sumSign==0, then we know that all non-zero
; coefficients have the same sign. Return NO SOLUTION.
;
; For all other situations, we have either 0, 1, or 2 solutions, so return that
; a solution *may* exist.
;
; Input: tvmPV, tvmFV, tvmPMT
; Output:
;   - CF=0 if no solution exists
;   - CF=1 if solution *may* exist
; Destroys: A, BC, DE, HL, OP1, OP2
tvmCheckNoSolution:
    ld bc, 0 ; B=numNonZero, C=sumSign
    ; Consider each polynomial coefficient and update the sums.
    call tvmCheckPVPMT
    call tvmCheckUpdateSums
    call tvmCheckPMT
    call tvmCheckUpdateSums
    call tvmCheckPMTFV
    call tvmCheckUpdateSums
    ; Check degenerate condition of numNonZero==0
    ld a, b ; A=numNonZero
    or a ; CF=0
    ret z ; all coefficients are zero
    ; Check if sumSign==0.
    ld a, c ; A=sumSign
    or a ; CF=0
    ret z ; all non-zero coef are positive
    ; Check if sumSign==numNonZero
    ld a, b ; A=numNonZero
    cp c ; will always set CF=0 because numNonZero>=sumSign
    ret z; all non-zero coef are negative
    scf ; sumSign!=numNonZero, so set CF
    ret

; Description: Update the numNonZero (B) and sumSign (C).
; Input: BC, OP1
; Output: BC
; Destroys: A
tvmCheckUpdateSums:
    bcall(_CkOP1FP0) ; preserves BC
    jr z, tvmCheckUpdateSumSign
    inc b ; numNonZero++
tvmCheckUpdateSumSign:
    call signOfOp1 ; A=signbit(OP1)
    add a, c
    ld c, a ; sumSign+=signbit(OP1)
    ret

; Description: Return (PV+PMT*p), where p=0 (end) or 1 (begin).
; Preserves: BC
tvmCheckPVPMT:
    push bc
    call rclTvmPV
    ld a, (tvmIsBegin)
    or a
    jr z, tvmCheckPVPMTRet ; return if p=begin=0
    call op1ToOp2
    call rclTvmPMT
    bcall(_FPAdd)
tvmCheckPVPMTRet:
    pop bc
    ret

; Description: Return (PMT*(1-p)+FV), where p=0 or 1.
; Preserves: BC
tvmCheckPMTFV:
    push bc
    call rclTvmFV
    ld a, (tvmIsBegin)
    or a
    jr nz, tvmCheckPMTFVRet ; return if p=begin=1
    call op1ToOp2
    call rclTvmPMT
    bcall(_FPAdd)
tvmCheckPMTFVRet:
    pop bc
    ret

; Description: Return PMT.
; Preserves: BC
tvmCheckPMT:
    push bc
    call rclTvmPMT
    pop bc
    ret

; Description: Return the sign bit of OP1 in A as a 1 (negative) or 0 (positive
; or zero).
; Input: OP1
; Output: A=0 or 1
; Preserves: BC
signOfOp1:
    ld a, (OP1); bit7=sign bit
    rlca
    and $01
    ret

;-----------------------------------------------------------------------------

; Description: Return the function ICFN(N,i) = N*i/((1+i)^N-1)) =
; N*i/((expm1(N*log1p(i)) which is the reciprocal of the compounding factor,
; with a special case of ICFN(N,0)=1 to remove a singularity at i=0.
; Input:
;   - fin_PV, fin_PMT, fin_FV, fin_PY
;   - OP1: N
;   - OP2: i (fractional interest per period)
; Output: OP1: ICFN(N,i)
; Destroys: OP1-OP5
inverseCompoundingFactor:
    bcall(_CkOP2FP0) ; check if i==0.0
    ; ICFN(N,i) has a removable singularity at i=0
    jr z, inverseCompoundingFactorZero
    bcall(_PushRealO1) ; FPS=[N]
    bcall(_PushRealO2) ; FPS=[N,i]
    bcall(_FPMult) ; OP1=N*i
    call exchangeFPSOP1 ; FPS=[N,N*i]; OP1=i
    call lnOnePlus ; OP1=ln(1+i)
    call exchangeFPSFPS ; FPS=[N*i,N]
    bcall(_PopRealO2) ; FPS=[Ni]; OP2=N
    bcall(_FPMult) ; OP1=N*ln(1+i)
    call expMinusOne ; OP1=exp(N*ln(1+i))-1
    call op1ToOP2 ; OP2=exp(N*ln(1+i))-1
    bcall(_PopRealO1) ; FPS=[]; OP2=Ni
    bcall(_FPDiv) ; OP1=Ni/[exp(N*ln(1+i)-1]
    ret
inverseCompoundingFactorZero:
    bcall(_OP1Set1) ; OP1=C=1
    ret

; Description: This is the function whose root we have to solve to find the
; interest rate corresponding to the N, PV, PMT, and FV. The function is:
;   NPMT(i,N) = PV*ICFN(-N,i) + (1+ip)PMT*N + FV*ICFN(N,i) = 0
; where
;   ICFN(N,i) = inverseCompoundingFactor(N,i) defined above.
;
; It is roughly the total nominal amount of money that was paid out (positive
; sign), if the discount-equivalent of PV and FV had been spread out across N
; payments at the given interest rate i. I guess we could also call this the
; "Net Payment", and I think I used that term in the TVM.md document.
;
; Input: OP1: i (interest per period)
; Output: OP1=NPMT(i)
; Destroys: OP1-OP5
nominalPMT:
    bcall(_PushRealO1) ; FPS=[i]
    ; Calculate FV*ICFN(N,i)
    call op1ToOP2 ; OP2=i
    call rclTvmN ; OP1=N
    call inverseCompoundingFactor ; OP1=ICFN(N,i)
    call op1ToOP2 ; OP2=ICFN(N,i)
    call rclTvmFV ; OP1=FV
    bcall(_FPMult) ; OP1=FV*ICFN(N,i)
    call exchangeFPSOP1 ; FPS=[FV*ICFN()]; OP1=i
    ; Calcuate PV*ICFN(-N,i)
    bcall(_PushRealO1) ; FPS=[FV*ICFN(),i]; OP1=i
    call op1ToOP2 ; OP2=i
    call rclTvmN ; OP1=N
    bcall(_InvOP1S) ; OP1=-N
    call inverseCompoundingFactor ; OP1=ICFN(-N,i)
    call op1ToOP2 ; OP2=ICFN(-N,i)
    call rclTvmPV ; OP1=PV
    bcall(_FPMult) ; OP1=PV*ICFN(-N,i)
    call exchangeFPSOP1 ; FPS=[FV*ICFN(N,i),PV*ICFN(-N,i)]; OP1=i
    ; Calculate (1+ip)PMT*N
    call beginEndFactor ; OP1=(1+ip)
    call op1ToOP2 ; OP2=(1+ip)
    call rclTvmPMT ; OP1=PMT
    bcall(_FPMult) ; OP1=(1+ip)*PMT
    call op1ToOP2 ; OP2=(1+ip)
    call rclTvmN ; OP1=N
    bcall(_FPMult) ; OP1=(1+ip)*PMT*N
    ; Sum up the 3 terms
    bcall(_PopRealO2) ; FPS=[FV*ICFN(N,i)]; OP2=PV*ICFN(-N,i)
    bcall(_FPAdd) ; OP1=PV*ICFN(-N,i)+(1+ip)*PMT*N
    bcall(_PopRealO2) ; FPS=[]; OP2=FV*ICFN(N,i)
    bcall(_FPAdd) ; OP1=PV*ICFN(-N,i)+(1+ip)*PMT*N+FV*ICFN(N,i)
    ret

; Description: Calculate the interest rate of the next interation using the
; Secant method.
;   x(n) = x(n-1) - f(n-1)[x(n-1)-x(n-2)]/[f(n-1)-f(n-2))
;        = [x(n-2)f(n-1) - x(n-1)f(n-2)] / [f(n-1)-f(n-2))
; Input: tvmI0, tvmI1, tvmNPMT0, tvmNPMT1
; Output: OP1: i2 the next estimate
calculateNextSecantInterest:
    call rclTvmI0
    call op1ToOP2
    call rclTvmNPMT1
    bcall(_PushRealO1) ; FPS=[npmt1]
    bcall(_FPMult) ; OP1=i0*npmt1
    bcall(_PushRealO1) ; FPS=[npmt1,i0*npmt1]
    call rclTvmI1
    call op1ToOP2
    call rclTvmNPMT0
    bcall(_PushRealO1) ; FPS=[npmt1,i0*npmt1,npmt0]
    bcall(_FPMult) ; OP1=i1*npmt0
    call exchangeFPSFPS ; FPS=[npmt1,npmt0,i0*npmt1]
    bcall(_PopRealO2) ; FPS=[npmt1,npmt0]; OP2=i0*npmt1
    bcall(_InvSub) ; OP1=i0*npmt1-i1*npmt0
    call exchangeFPSOP1 ; FPS=[npmt1,i0*npmt1-i1*npmt0]; OP1=npmt0
    call op1ToOP2 ; OP2=npmt0
    call exchangeFPSFPS ; FPS=[i0*npmt1-i1*npmt0,npmt1]; OP2=npmt0
    bcall(_PopRealO1) ; FPS=[i0*npmt1-i1*npmt0]; OP1=npmt1; OP2=npmt0
    bcall(_FPSub)  ; OP1=npmt1-npmt0
    call op1ToOP2 ; OP2=npmt1-npmt0
    bcall(_PopRealO1) ; FPS=[]; OP1=i0*npmt1-i1*npmt0
    bcall(_FPDiv) ; OP1=i0*npmt1-i1*npmt0)/(npmt1-npmt0)
    ret

; Description: Update i0 and i1 using the new i2 guess by moving i1 to i0, then
; i2 into i1. (An alternate algorithm is to clobber the i0 or i1 that preserves
; the sign change across the root. Unfortunately, that algorithm results in a
; much slower convergence rate beside it often converges only from one side.)
; Input:
;   - i0, i1, npmt0, npmt1
;   - OP1: i2, the next interest rate
; Output: i0, i1, npmt0, npmpt1 updated
tvmSolveUpdateGuesses:
    bcall(_PushRealO1) ; FPS=[i2]
    call nominalPMT ; OP1=npmt2
    bcall(_PushRealO1) ; FPS=[i2,npmt2]
    ;
    call rclTvmI1 ; OP1=i1
    call stoTvmI0 ; i1=i0
    call rclTvmNPMT1 ; OP1=npmt1
    call stoTvmNPMT0 ; npmt0=npmt1
    ;
    bcall(_PopRealO1) ; FPS=[i2]; OP1=npmt2
    call stoTvmNPMT1 ; npmt1=npmt2
    bcall(_PopRealO1) ; FPS=[]; OP1=i2
    call stoTvmI1 ; i1=i2
    ret

; Description: Determine if TVM Solver debugging is enabled, which is activated
; when drawMode for TVM Solver is enabled and the TVM Solver is in effect. In
; other words, (drawMode==drawModeTvmSolverI || drawMode==drawModeTvmSolverF)
; && tvmSolverIsRunning.
; Output:
;   - CF: 1 if TVM solver debug enabled; 0 if disabled
; Destroys: A
tvmSolveCheckDebugEnabled:
    ld a, (tvmSolverIsRunning)
    or a
    ret z ; CF==0 if TVM Solver not running
    ; check for drawMode 1 or 2
    ld a, (drawMode)
    dec a
    jr z, tvmSolveDebugEnabled
    dec a
    jr z, tvmSolveDebugEnabled
    or a ; CF=0
    ret
tvmSolveDebugEnabled:
    scf ; CF=1
    ret

; Description: Check if the root finding iteration should stop.
; Input: i0, i1
; Output:
;   - A=tvmSolverResultXxx, non-zero means terminate loop.
; Destroys: A, B, OP1, OP2
tvmSolveCheckTermination:
    ; Check for ON/Break
    bit onInterrupt, (IY+onFlags)
    jr z, tvmSolveCheckTolerance
    res onInterrupt, (iy + onFlags)
    ld a, tvmSolverResultBreak
    ret
tvmSolveCheckTolerance:
    ; Check if i0 and i1 are within tolerance. If i1!=0.0, then use relative
    ; error |i0-i1|/|i1| < tol. Otherwise use absolute error |i0-i1| < tol.
    call rclTvmI0
    call op1ToOP2
    call rclTvmI1
    bcall(_PushRealO1) ; FPS=[i1]
    bcall(_FPSub) ; OP1=(i1-i0)
    bcall(_PopRealO2) ; FPS=[]; OP2=i1
    bcall(_CkOP2FP0) ; if OP2==0: ZF=1
    jr z, tvmSolveCheckNoRelativeError
    bcall(_FPDiv) ; OP1=(i1-i0)/i1
tvmSolveCheckNoRelativeError:
    call op2Set1EM8 ; OP2=1e-8
    bcall(_AbsO1O2Cp) ; if |OP1| < |OP2|: CF=1
    jr nc, tvmSolveCheckCount
    ld a, tvmSolverResultFound ; Found!
    ret
tvmSolveCheckCount:
    ; Check iteration counter against tvmIterMax
    ld hl, tvmSolverCount
    ld a, (hl)
    inc a
    ld (hl), a
    ld b, a
    ld a, (tvmIterMax)
    cp b
    jr nz, tvmSolveCheckSingleStep
    ld a, tvmSolverResultIterMaxed
    ret
tvmSolveCheckSingleStep:
    ; Check if single-step debug mode enabled. This *must* be the last
    ; condition to check, so that when tvmSolve() is called again, it does not
    ; terminate immediately if single-step debugging is enabled.
    call tvmSolveCheckDebugEnabled ; CF=1 if enabled
    jr nc, tvmSolveCheckContinue
    ld a, tvmSolverResultSingleStep
    ret
tvmSolveCheckContinue:
    ld a, tvmSolverResultContinue
    ret

; Description: Initialize i0 and i1 from IYR0 and IYR1 respectively.
tvmSolveInitGuesses:
    call rclTvmIYR0
    call calcTvmIntPerPeriod
    call stoTvmI0
    ;
    call rclTvmIYR1
    call calcTvmIntPerPeriod
    call stoTvmI1
    ret

; Description: Calculate the interest rate by solving the root of the NPMT
; equation using the Newton-Secant method. Uses 2 initial interest rate guesses
; in i0 and i1. Usually, they will be i0=0 i1=100 (100%/year). But if multiple
; values are entered repeatedly using the I%YR menu key, the last 2 values will
; be used as the initial guess.
;
; The tricky part of this subroutine is that it supports a "single-step"
; debugging mode where it returns to the after each iteration. Then the caller
; can call this routine again, to continue the next iteration. Therefore, this
; routine must preserve enough state information to be able to continue the
; iteration at the correct point.
;
; Input:
;   - A: tvmSolverResultXxx. If tvmSolverResultSingleStep, the subroutine
;   - i0, i1: initial guesses, usually 0% and 100%, but can be overridden by
;   entering 2 values using '2ND I%YR' menu button twice
;   continues from previous iteration. Otherwise it initializes the various
;   parameters for a fresh calculation.
; Output:
;   - A: tvmSolverResultXxx
;   - OP1: the calculated I%YR if A==tvmSolverResultFound
; Destroys:
;   - all registers, OP1-OP5
tvmSolve:
    cp tvmSolverResultSingleStep
    jr z, tvmSolveLoop
    ; Set iteration counter to 0 initially. Counting down is more efficient,
    ; but counting up allows better debugging. The number of iterations is so
    ; low that this small bit of inefficiency doesn't matter.
    xor a
    ld (tvmSolverCount), a
    ; Initialize i0 and i1 from IYR0 and IYR1
    call tvmSolveInitGuesses
    ; Set up the i0 guess
    call rclTvmI0 ; i0=0.0
    call nominalPMT ; OP1=NPMT(i0)
    call stoTvmNPMT0 ; tvmNPMT0=NPMT(i0)
    bcall(_CkOP1FP0) ; if OP1==0: ZF=set
    jr z, tvmSolveI0Zero
    ; Set up the i1 guess
    call rclTvmI1 ; i1=100%/PYR/100
    call nominalPMT ; OP1=NPMT(i1)
    call stoTvmNPMT1 ; tvmNPMT1=NPMT(N,i1)
    bcall(_CkOP1FP0) ; if OP1==0: ZF=set
    jr z, tvmSolveI1Zero
    ; Check for different sign bit of NPMT(i)
    call rclTvmNPMT0
    call op1ToOP2
    call rclTvmNPMT1
    call compareSignOP1OP2
    jr nz, tvmSolveLoopEntry
    ld a, tvmSolverResultNotFound
    ret
tvmSolveLoop:
    ; Use Secant method to estimate the next interest rate
    call calculateNextSecantInterest ; OP1=i2
    ;call tvmSolveCheckBounds ; CF=1 if out of bounds
    ; Secant failed. Use bisection.
    ;call c, call calculateNextBisectInterest
    call tvmSolveUpdateGuesses ; update tvmI0,tmvI1
tvmSolveLoopEntry:
    call tvmSolveCheckTermination ; A=tvmSolverResultXxx
    or a ; if A==0: keep looping
    jr z, tvmSolveLoop
tvmSolveTerminate:
    cp tvmSolverResultFound
    ret nz ; not found
    ; Found, set OP1 to the result.
    call rclTvmI1
    jr tvmSolveFound
tvmSolveI0Zero:
    bcall(_OP1Set0) ; OP1=0.0
    jr tvmSolveFound
tvmSolveI1Zero:
    call op1Set100 ; OP1=100.0%
tvmSolveFound:
    call calcTvmIYR ; convert i (per period) to IYR
    ld a, tvmSolverResultFound
    ret

;-----------------------------------------------------------------------------
; TVM handlers are invoked by the menu buttons.
;-----------------------------------------------------------------------------

mTvmNHandler:
    call closeX
    ; Check if '2ND N' pressed.
    bit rpnFlagsSecondKey, (iy + rpnFlags)
    jr nz, mTvmNGet
    ; Check if N needs to be calculated.
    bit rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr nz, mTvmNCalculate
    ; save the inputBuf value
    call rclX
    call stoTvmN
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmNGet:
    call rclTvmN
    call pushX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret
mTvmNCalculate:
    ; if i!=0:
    ;   N = ln(1+N0)/ln(1+i), where
    ;   N0 = -i(FV+PV)/[PMT*(1+ip)+i*PV]
    ;   if N0<=-1: no solution
    ; else:
    ;   N -> N0/i = -(FV+PV)/PMT
    ;   if N<=0: no solution
    call getTvmIntPerPeriod ; OP1=i
    bcall(_CkOP1FP0) ; check for i==0
    jr z, mTvmNCalculateZero
    bcall(_PushRealO1) ; FPS=[i]
    call beginEndFactor ; OP1=1+ip
    call op1ToOp2 ; OP2=1+ip
    call rclTvmPMT ; OP1=PMT
    bcall(_FPMult) ; OP1=PMT*(1+ip)
    bcall(_OP1ToOP4) ; OP4=PMT*(1+ip) (save)
    bcall(_PopRealO2) ; FPS=[]; OP2=i
    bcall(_PushRealO2) ; FPS=[i]
    bcall(_PushRealO2) ; FPS=[i,i]
    call rclTvmPV ; OP1=PV
    bcall(_FPMult) ; OP1=PV*i
    bcall(_OP4ToOP2) ; OP2=PMT*(1+ip)
    bcall(_FPAdd) ; OP1=PMT*(1+ip)+i*PV
    bcall(_PushRealO1) ; FPS[i,i,PMT*(1+ip)+i*PV]
    call rclTvmPV ; OP1=PV
    call op1ToOp2 ; OP2=PV
    call rclTvmFV ; OP1=FV
    bcall(_FPAdd) ; OP1=PV+FV
    bcall(_PopRealO2) ; FPS=[i,i]; OP2=PMT*(1+ip)+i*PV
    bcall(_FPDiv) ; OP1=(FV+PV)/(PMT*(1+ip)+i*PV)
    bcall(_PopRealO2) ; FPS=[i]; OP2=i
    bcall(_FPMult) ; OP1=N0=i*(FV+PV)/(PMT*(1+ip)+i*PV)
    bcall(_InvOP1S) ; OP1=N0=-i*(FV+PV)/(PMT*(1+ip)+i*PV)
    call lnOnePlus ; OP1=ln(1+N0); throws exception if 1+N0<=0
    call exchangeFPSOP1 ; FPS=[ln(1+N0)]; OP1=i
    call lnOnePlus ; OP1=ln(1+i); throws exception if 1+i<=0
    call op1ToOP2 ; OP2=ln(1+i)
    bcall(_PopRealO1) ; FPS=[]; OP1=ln(1+N0)
    bcall(_FPDiv) ; OP1=ln(1+N0)/ln(1+i)
mTvmNCalculateSto:
    call stoTvmN
    call pushX
    ld a, errorCodeTvmCalculated
    ld (handlerCode), a
    ret
mTvmNCalculateZero:
    ; if i==0: N = (-FV-PV)/PMT
    call rclTvmFV
    call op1ToOP2
    call rclTvmPV
    bcall(_FPAdd)
    bcall(_InvOP1S)
    call op1ToOP2
    call rclTvmPMT
    call op1ExOp2
    bcall(_FPDiv)
    jr mTvmNCalculateSto

;-----------------------------------------------------------------------------

mTvmIYRHandler:
    call closeX
    ; Check if '2ND I%YR' pressed.
    bit rpnFlagsSecondKey, (iy + rpnFlags)
    jr nz, mTvmIYRGet
    ; Check if I%YR needs to be calculated.
    bit rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr nz, mTvmIYRCalculate
    ; save the inputBuf value
    call rclX
    call calcTvmIntPerPeriod
    call op1ToOp2 ; OP2=IYR/N=i
    call op1SetM1 ; OP1=-1
    bcall(_CpOP1OP2) ; if -1<i: CF=1 (valid)
    jr c, mTvmIYRSet
    bcall(_ErrDomain)
mTvmIYRSet:
    call rclX
    call stoTvmIYR
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmIYRGet:
    call rclTvmIYR
    call pushX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret
mTvmIYRCalculate:
    call tvmIYRCalculate ; OP1=answer; A=handlerCode
    ld (handlerCode), a
    cp errorCodeTvmCalculated
    ret nz
    call stoTvmIYR
    call pushX
    ret

; Description: Call the tvmSolver() as often as necessary (e.g. during
; debugging single step) to arrive a solution, or determine that there is no
; solution.
; Output:
;   - A: handlerCoder
;   - OP1: IYR solution if A==errorCodeCalculated
; Destroys: all
tvmIYRCalculate:
    ; Interest rate does not have a closed-form solution, so requires solving
    ; the root of an equation. First, determine if equation has no roots
    ; definitively.
    call tvmCheckNoSolution ; ZF=0 if no solution
    jr c, tvmIYRCalculateMayExists
    ; Cannot have a solution
    ld a, errorCodeTvmNoSolution
    ret
tvmIYRCalculateMayExists:
    ; TVM Solver is a bit slow, 2-3 seconds. During that time, the errorCode
    ; from the previous command will be displayed, which is a bit confusing.
    ; Let's remove the previous error code before running the long subroutine.
    ; NOTE: It might be reasonable to do this before all commands, but we have
    ; to be a little careful because the CLEAR command behaves slightly
    ; differently if there an errorcode is currently being displayed. The CLEAR
    ; command simply clears the current errorCode if it exists, without doing
    ; anything else, so the logic is a bit tricky.
    ld a, (errorCode)
    or a
    jr z, tvmIYRCalculateSolve
    ; Remove the displayed error code if it exists
    xor a
    bcall(_SetErrorCode)
    call displayAll
tvmIYRCalculateSolve:
    ld a, rpntrue
    ld (tvmSolverIsRunning), a ; set 'isRunning' flag
    bcall(_RunIndicOn)
    xor a ; A=0=tvmSolverResultContinue
tvmIYRCalculateSolveLoop:
    ; tvmSolve() can be called with 2 values of A:
    ; - A=tvmSolverResultSingleStep to restart from the last loop, or
    ; - A=anything else to start the root solver from the beginning,
    call tvmSolve ; A=tvmSolverResultXxx, guaranteed non-zero when it returns
    cp tvmSolverResultFound
    jr nz, tvmIYRCalculateCheckNotFound
    ld a, errorCodeTvmCalculated
    jr tvmIYRCalculateEnd
tvmIYRCalculateCheckNotFound:
    cp tvmSolverResultNotFound
    jr nz, tvmIYRCalculateCheckIterMax
    ; root not found
    ld a, errorCodeTvmNotFound
    jr tvmIYRCalculateEnd
tvmIYRCalculateCheckIterMax:
    cp tvmSolverResultIterMaxed
    jr nz, tvmIYRCalculateCheckBreak
    ; root not found after max iterations
    ld a, errorCodeTvmIterations
    jr tvmIYRCalculateEnd
tvmIYRCalculateCheckBreak:
    cp tvmSolverResultBreak
    jr nz, tvmIYRCalculateCheckSingleStep
    ; user hit ON/EXIT
    ld a, errorCodeBreak
    jr tvmIYRCalculateEnd
tvmIYRCalculateCheckSingleStep:
    cp tvmSolverResultSingleStep
    jr nz, tvmIYRCalculateStatusUnknown
    ; single-step debugging mode: render display and wait for key
    push af ; preserve A==tvmSolverResultSingleStep
    set dirtyFlagsStack, (iy + dirtyFlags)
    call displayAll
    ; Pause and wait for button press.
    ; If QUIT or OFF then TvmSolver will be reset upon app start.
    bcall(_GetKey)
    pop af
    jr tvmIYRCalculateSolveLoop
tvmIYRCalculateStatusUnknown:
    ld a, errorCodeTvmNotFound
tvmIYRCalculateEnd:
    push af
    xor a
    ld (tvmSolverIsRunning), a ; clear 'isRunning' flag
    bcall(_RunIndicOff)
    pop af
    ret

;-----------------------------------------------------------------------------

mTvmPVHandler:
    call closeX
    ; Check if '2ND PV' pressed.
    bit rpnFlagsSecondKey, (iy + rpnFlags)
    jr nz, mTvmPVGet
    ; Check if PV needs to be calculated.
    bit rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr nz, mTvmPVCalculate
    ; save the inputBuf value
    call rclX
    call stoTvmPV
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmPVGet:
    call rclTvmPV
    call pushX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret
mTvmPVCalculate:
    ; PV = [-FV - PMT * [(1+i)N - 1] * (1 + i p) / i] / (1+i)N
    ;    = [-FV - PMT * CF3(i)] / CF1(i)
    call compoundingFactors ; OP1=CF1; OP2=CF3
    bcall(_PushRealO1) ; FPS=[CF1]
    call rclTvmPMT ; OP1=PMT
    bcall(_FPMult) ; OP1=PMT*CF3
    call op1ToOP2 ; OP2=PMT*CF3
    call rclTvmFV ; OP1=FV
    bcall(_FPAdd) ; OP1=FV+PMT*CF3
    bcall(_InvOP1S) ; OP1=-OP1
    bcall(_PopRealO2) ; FPS=[]; OP2=CF1
    bcall(_FPDiv) ; OP1=(-FV-PMT*CF3)/CF1
    call stoTvmPV
    call pushX
    ld a, errorCodeTvmCalculated
    ld (handlerCode), a
    ret

;-----------------------------------------------------------------------------

mTvmPMTHandler:
    call closeX
    ; Check if '2ND PMT' pressed.
    bit rpnFlagsSecondKey, (iy + rpnFlags)
    jr nz, mTvmPMTGet
    ; Check if PMT needs to be calculated.
    bit rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr nz, mTvmPMTCalculate
    ; save the inputBuf value
    call rclX
    call stoTvmPMT
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmPMTGet:
    call rclTvmPMT
    call pushX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret
mTvmPMTCalculate:
    ; PMT = [-PV * (1+i)^N - FV] / [((1+i)^N - 1) * (1+ip)/i]
    ;     = (-PV * CF1(i) - FV) / CF3(i)
    call compoundingFactors ; OP1=CF1; OP2=CF3
    bcall(_PushRealO2) ; FPS=[CF3]
    call op1ToOP2 ; OP2=CF1
    call rclTvmPV ; OP1=PV
    bcall(_FPMult) ; OP1=PV*CF1
    call op1ToOP2 ; OP2=PV*CF1
    call rclTvmFV ; OP1=FV
    bcall(_FPAdd) ; OP1=FV+PV*CF1
    bcall(_InvOP1S) ; OP1=-OP1
    bcall(_PopRealO2) ; FPS=[]; OP2=CF3
    bcall(_FPDiv) ; OP1=(-PV*CF1-FV)/CF3
    call stoTvmPMT
    call pushX
    ld a, errorCodeTvmCalculated
    ld (handlerCode), a
    ret

;-----------------------------------------------------------------------------

mTvmFVHandler:
    call closeX
    ; Check if '2ND FV' pressed.
    bit rpnFlagsSecondKey, (iy + rpnFlags)
    jr nz, mTvmFVGet
    ; Check if FV needs to be calculated.
    bit rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr nz, mTvmFVCalculate
    ; save the inputBuf value
    call rclX
    call stoTvmFV
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmFVGet:
    call rclTvmFV
    call pushX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret
mTvmFVCalculate:
    ; FV = -PMT * [(1+i)N - 1] * (1 + i p) / i - PV * (1+i)N
    ;    = -PMT*CF3(i)-PV*CF1(i)
    call compoundingFactors ; OP1=CF1; OP2=CF3
    bcall(_PushRealO1) ; FPS=[CF1]
    call rclTvmPMT ; OP1=PMT
    bcall(_FPMult) ; OP1=PMT*CF3
    call exchangeFPSOP1 ; FPS=[PMT*CF3]; OP1=CF1
    call op1ToOP2 ; OP2=CF1
    call rclTvmPV ; OP1=PV
    bcall(_FPMult) ; OP1=PV*CF1
    bcall(_PopRealO2) ; FPS=[]; OP2=PMT*CF3
    bcall(_FPAdd) ; OP1=PMT*CF3+PV*CF1
    bcall(_InvOP1S) ; OP1=-OP1
    call stoTvmFV
    call pushX
    ld a, errorCodeTvmCalculated
    ld (handlerCode), a
    ret

;-----------------------------------------------------------------------------

; Description: Set or get P/YR to X.
mTvmPYRHandler:
    call closeX
    ; Check if '2ND PYR' pressed.
    bit rpnFlagsSecondKey, (iy + rpnFlags)
    jr nz, mTvmPYRGet
    ; save the inputBuf value in OP1
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call rclX
    bcall(_PosNo0Int) ; if posnonzeroint(x): ZF=1
    jr z, mTvmPYRHandlerSet
    bcall(_ErrDomain)
mTvmPYRHandlerSet:
    call stoTvmPYR
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmPYRGet:
    call rclTvmPYR
    call pushX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret

;-----------------------------------------------------------------------------

mTvmBeginHandler:
    call closeX
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, rpntrue
    ld (tvmIsBegin), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Return B if tvmIsBegin is false, C otherwise.
; Input: A, B: normal nameId; C: alt nameId
; Output: A
mTvmBeginNameSelector:
    ld a, (tvmIsBegin)
    or a
    jr nz, mTvmBeginNameSelectorC
    ld a, b
    ret
mTvmBeginNameSelectorC:
    ld a, c
    ret

;-----------------------------------------------------------------------------

mTvmEndHandler:
    call closeX
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    xor a
    ld (tvmIsBegin), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Return C if tvmIsBegin is false, B otherwise.
; Input:
;   - A, B: normal nameId
;   - C: alt nameId
; Output: A
mTvmEndNameSelector:
    ld a, (tvmIsBegin)
    or a
    jr z, mTvmEndNameSelectorC
    ld a, b
    ret
mTvmEndNameSelectorC:
    ld a, c
    ret

;-----------------------------------------------------------------------------

mTvmIYR0Handler:
    call closeX
    ; Check if '2ND IYR1' pressed.
    bit rpnFlagsSecondKey, (iy + rpnFlags)
    jr nz, mTvmIYR0Get
    ; save the inputBuf value in OP1
    call rclX
    call stoTvmIYR0
    call tvmSolverSetOverrideFlagIYR0
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmIYR0Get:
    call rclTvmIYR0
    call pushX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret

; Description: Return B if tvmIsBegin is false, C otherwise.
; Input: A, B: normal nameId; C: alt nameId
; Output: A
mTvmIYR0NameSelector:
    call tvmSolverBitOverrideFlagIYR0
    jr nz, mTvmIYR0NameSelectorC
    ld a, b
    ret
mTvmIYR0NameSelectorC:
    ld a, c
    ret

;-----------------------------------------------------------------------------

mTvmIYR1Handler:
    call closeX
    ; Check if '2ND IYR2' pressed.
    bit rpnFlagsSecondKey, (iy + rpnFlags)
    jr nz, mTvmIYR1Get
    ; save the inputBuf value in OP1
    call rclX
    call stoTvmIYR1
    call tvmSolverSetOverrideFlagIYR1
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmIYR1Get:
    call rclTvmIYR1
    call pushX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret

; Description: Return B if tvmIsBegin is false, C otherwise.
; Input: A, B: normal nameId; C: alt nameId
; Output: A
mTvmIYR1NameSelector:
    call tvmSolverBitOverrideFlagIYR1
    jr nz, mTvmIYR1NameSelectorC
    ld a, b
    ret
mTvmIYR1NameSelectorC:
    ld a, c
    ret

;-----------------------------------------------------------------------------

mTvmIterMaxHandler:
    call closeX
    ; Check if '2ND TMAX' pressed.
    bit rpnFlagsSecondKey, (iy + rpnFlags)
    jr nz, mTvmIterMaxGet
    ; save the inputBuf value in OP1
    call rclX
    call stoTvmIterMax
    call tvmSolverSetOverrideFlagIterMax
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmStored
    ld (handlerCode), a
    ret
mTvmIterMaxGet:
    call rclTvmIterMax
    call pushX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmRecalled
    ld (handlerCode), a
    ret

; Description: Return B if tvmIsBegin is false, C otherwise.
; Input: A, B: normal nameId; C: alt nameId
; Output: A
mTvmIterMaxNameSelector:
    call tvmSolverBitOverrideFlagIterMax
    jr nz, mTvmIterMaxNameSelectorC
    ld a, b
    ret
mTvmIterMaxNameSelectorC:
    ld a, c
    ret

;-----------------------------------------------------------------------------
; More low-level helper routines, placed at the bottom to avoid clutter in the
; main parts of the file.
;-----------------------------------------------------------------------------

mTvmClearHandler:
    call closeX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call tvmClear
    ld a, errorCodeTvmCleared
    ld (handlerCode), a
    ret

mTvmSolverResetHandler:
    call closeX
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call tvmSolverReset
    ld a, errorCodeTvmSolverReset
    ld (handlerCode), a
    ret

;-----------------------------------------------------------------------------

; Description: Clear the 5 NPV or NFV variables.
tvmClear:
    ; Reset the PYR, BEGIN parameters to their defaults.
    xor a
    ld (tvmIsBegin), a
    ld a, 12
    bcall(_SetXXOP1)
    ld de, fin_PY
    call move9FromOp1
    ld de, fin_CY
    call move9FromOp1
    ; Clear the 5 TVM equation variables to 0.
    bcall(_OP1Set0)
    ld de, fin_N
    call move9FromOp1
    ld de, fin_I
    call move9FromOp1
    ld de, fin_PV
    call move9FromOp1
    ld de, fin_PMT
    call move9FromOp1
    ld de, fin_FV
    call move9FromOp1
    ; [[fallthrough]]

; Description: Reset the TVM Solver parameters to their factory defaults and
; clear the override flags to remove the menu dots.
tvmSolverReset:
    ; Set factory defaults
    call op1Set0 ; 0%/year
    call stoTvmIYR0
    call op1Set100 ; 100%/year
    call stoTvmIYR1
    ld a, tvmSolverDefaultIterMax
    call stoTvmIterMaxA
    ; Clear flags
    xor a
    ld (tvmSolverOverrideFlags), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

;-----------------------------------------------------------------------------

; Description: Set tvmSolverOverrideFlagIYR0.
; Destroys: HL
tvmSolverSetOverrideFlagIYR0:
    ld hl, tvmSolverOverrideFlags
    set tvmSolverOverrideFlagIYR0, (hl)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Reset tvmSolverOverrideFlagIYR0.
; Destroys: HL
tvmSolverResOverrideFlagIYR0:
    ld hl, tvmSolverOverrideFlags
    res tvmSolverOverrideFlagIYR0, (hl)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Test bit tvmSolverOverrideFlagIYR0.
; Destroys: HL
tvmSolverBitOverrideFlagIYR0:
    ld hl, tvmSolverOverrideFlags
    bit tvmSolverOverrideFlagIYR0, (hl)
    ret

; Description: Set tvmSolverOverrideFlagIYR1.
; Destroys: HL
tvmSolverSetOverrideFlagIYR1:
    ld hl, tvmSolverOverrideFlags
    set tvmSolverOverrideFlagIYR1, (hl)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Reset tvmSolverOverrideFlagIYR1.
; Destroys: HL
tvmSolverResOverrideFlagIYR1:
    ld hl, tvmSolverOverrideFlags
    res tvmSolverOverrideFlagIYR1, (hl)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Test bit tvmSolverOverrideFlagIYR1.
; Destroys: HL
tvmSolverBitOverrideFlagIYR1:
    ld hl, tvmSolverOverrideFlags
    bit tvmSolverOverrideFlagIYR1, (hl)
    ret

; Description: Set tvmSolverOverrideFlagIterMax.
; Destroys: HL
tvmSolverSetOverrideFlagIterMax:
    ld hl, tvmSolverOverrideFlags
    set tvmSolverOverrideFlagIterMax, (hl)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Reset tvmSolverOverrideFlagIterMax.
; Destroys: HL
tvmSolverResOverrideFlagIterMax:
    ld hl, tvmSolverOverrideFlags
    res tvmSolverOverrideFlagIterMax, (hl)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Description: Test bit tvmSolverOverrideFlagIterMax.
; Destroys: HL
tvmSolverBitOverrideFlagIterMax:
    ld hl, tvmSolverOverrideFlags
    bit tvmSolverOverrideFlagIterMax, (hl)
    ret
