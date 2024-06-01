;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; TVM low-level functions. The handlers in tvmhandlers.asm will call these.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Store and recall the TVM variables. Most of the time, they are needed in this
; module, in Flash Page 1. But they are also needed in tvmhandlers.asm in Flash
; Page 0, so they are exported through the bcall(). Fortunately, all of the
; calls from tvmhandlers.asm are *not* performance critical, so they can pay
; for the overhead of the bcall() without problems.
;-----------------------------------------------------------------------------

; Description: Recall fin_N to OP1.
RclTvmN:
    ld hl, fin_N
    jp move9ToOp1PageOne

; Description: Store OP1 to fin_N.
StoTvmN:
    ld de, fin_N
    jp move9FromOp1PageOne

; Description: Recall fin_I to OP1.
RclTvmIYR:
    ld hl, fin_I
    jp move9ToOp1PageOne

; Description: Store OP1 to fin_I.
StoTvmIYR:
    ld de, fin_I
    jp move9FromOp1PageOne

; Description: Recall fin_PV to OP1.
RclTvmPV:
    ld hl, fin_PV
    jp move9ToOp1PageOne

; Description: Store OP1 to fin_PV.
StoTvmPV:
    ld de, fin_PV
    jp move9FromOp1PageOne

; Description: Recall fin_PMT to OP1.
RclTvmPMT:
    ld hl, fin_PMT
    jp move9ToOp1PageOne

; Description: Store OP1 to fin_PMT.
StoTvmPMT:
    ld de, fin_PMT
    jp move9FromOp1PageOne

; Description: Recall fin_N to OP1.
RclTvmFV:
    ld hl, fin_FV
    jp move9ToOp1PageOne

; Description: Store OP1 to fin_FV.
StoTvmFV:
    ld de, fin_FV
    jp move9FromOp1PageOne

; Description: Recall fin_PY to OP1.
RclTvmPYR:
    ld hl, fin_PY
    jp move9ToOp1PageOne

; Description: Store OP1 to fin_PY. Store the same value in fin_CY so that if
; we go back to the TI-OS and use the built-in "Financial" app, the same
; compounding frequency will appear there under "C/Y".
StoTvmPYR:
    ld de, fin_PY
    call move9FromOp1PageOne
    ld de, fin_CY
    call move9FromOp1PageOne
    ret

;-----------------------------------------------------------------------------
; Workspace variables used by the TVM Solver.
;-----------------------------------------------------------------------------

; Description: Recall tvmIYR0 to OP1.
RclTvmIYR0:
    ld hl, tvmIYR0
    jp move9ToOp1PageOne

; Description: Store OP1 to tvmIYR0 variable.
StoTvmIYR0:
    ld de, tvmIYR0
    jp move9FromOp1PageOne

; Description: Recall tvmIYR1 to OP1.
RclTvmIYR1:
    ld hl, tvmIYR1
    jp move9ToOp1PageOne

; Description: Store OP1 to tvmIYR1 variable.
StoTvmIYR1:
    ld de, tvmIYR1
    jp move9FromOp1PageOne

; Description: Recall tvmIterMax to OP1.
RclTvmIterMax:
    ld a, (tvmIterMax)
    call ConvertAToOP1
    ret

; Description: Store OP1 to tvmIterMax variable.
StoTvmIterMax:
    bcall(_ConvOP1) ; DE=hex; A=LSB
    ld a, d
    or a
    jr nz, stoTvmIterMaxErr ; DE>255
    ld a, e
stoTvmIterMaxA: ; alt version that stores A
    or a
    jr z, stoTvmIterMaxErr ; IterMax cannot be 0
    ld (tvmIterMax), a
    ret
stoTvmIterMaxErr:
    bcall(_ErrDomain)

;-----------------------------------------------------------------------------

; Description: Recall tvmI0 to OP1.
RclTvmI0:
    ld hl, tvmI0
    jp move9ToOp1PageOne

; Description: Store OP1 to tvmI0 variable.
StoTvmI0:
    ld de, tvmI0
    jp move9FromOp1PageOne

; Description: Recall tvmI1 to OP1.
RclTvmI1:
    ld hl, tvmI1
    jp move9ToOp1PageOne

; Description: Store OP1 to tvmI1 variable.
StoTvmI1:
    ld de, tvmI1
    jp move9FromOp1PageOne

; Description: Recall tvmNPMT0 to OP1.
RclTvmNPMT0:
    ld hl, tvmNPMT0
    jp move9ToOp1PageOne

; Description: Store OP1 to tvmNPMT0 variable.
StoTvmNPMT0:
    ld de, tvmNPMT0
    jp move9FromOp1PageOne

; Description: Recall tvmNPMT1 to OP1.
RclTvmNPMT1:
    ld hl, tvmNPMT1
    jp move9ToOp1PageOne

; Description: Store OP1 to tvmNPMT1 variable.
StoTvmNPMT1:
    ld de, tvmNPMT1
    jp move9FromOp1PageOne

; Description: Recall the TVM solver iteration counter as a float in OP1.
RclTvmSolverCount:
    ld a, (tvmSolverCount)
    call ConvertAToOP1 ; OP1=float(A)
    ret

;-----------------------------------------------------------------------------
; Lower-level routines that calculate various terms and coefficients of the
; various TVM equations.
;-----------------------------------------------------------------------------

; Description: Return the fractional interest rate per period (IPP) from the
; current IYR and PYR.
; Input:
;   - RclTvmIYR
;   - RclTvmPYR
; Output:
;   - OP1 = i = IYR / PYR / 100.
getTvmIPP:
    call RclTvmIYR
    ; [[fallthrough]]

; Description: Compute the interest rate per period (IPP) for the given
; interest percent yearly rate (IYR) in OP1.
; Input: OP1=IYR=interest percent yearly rate
; Output: OP1=IYR/PYR/100
; Preserves: OP2
TvmCalcIPPFromIYR:
    bcall(_PushRealO2) ; FPS=[OP2]
    call op1ToOp2PageOne
    call RclTvmPYR
    call op1ExOp2PageOne
    bcall(_FPDiv) ; OP1=I/PYR
    call op2Set100PageOne
    bcall(_FPDiv) ; OP1=I/PYR/100
    bcall(_PopRealO2) ; FPS=[]
    ret

; Description: Compute the I%/YR from the fractional interest per period.
; Input: OP1=i=fractional interest per period
; Output: OP1=IYR=percent per year=i*PYR*100
; Preserves: OP2
calcTvmIYRFromIPP:
    bcall(_PushRealO2) ; FPS=[OP2]
    call op1ToOp2PageOne
    call RclTvmPYR
    bcall(_FPMult)
    call op2Set100PageOne
    bcall(_FPMult)
    bcall(_PopRealO2) ; FPS=[]
    ret

;-----------------------------------------------------------------------------

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
;   - RclTvmIYR
;   - RclTvmPYR
;   - RclTvmN
; Output:
;   - OP1=CF1(i)=(1+i)^N=exp(N*log1p(i))
;   - OP2=CF3(i)=(1+ip)[(i+i)^N-1]/i=(1+ip)(expm1(N*log1p(i))/i)
; Destroys: OP1-OP5
compoundingFactors:
#ifdef TVM_NAIVE
    ; Use the TVM formulas directly, which can suffer from cancellation errors
    ; for small i.
    call getTvmIPP ; OP1=i
    bcall(_PushRealO1) ; FPS=[i]
    bcall(_PushRealO1) ; FPS=[i,i]
    call RclTvmN ; OP1=N
    call exchangeFPSOP1PageOne ; FPS=[i,N]; OP1=i
    bcall(_PushRealO1) ; FPS=[i,N,i]
    call beginEndFactor ; OP1=(1+ip)
    call exchangeFPSOP1PageOne ; FPS=[i,N,1+ip]; OP1=i
    bcall(_Plus1) ; OP1=1+i (destroys OP2)
    call exchangeFPSFPSPageOne ; FPS=[i,1+ip,N]
    bcall(_PopRealO2) ; FPS=[i,1+ip] OP2=N
    bcall(_YToX) ; OP1=(1+i)^N
    bcall(_OP1ToOP4) ; OP4=(1+i)^N (save)
    bcall(_Minus1) ; OP1=(1+i)^N-1
    call exchangeFPSFPSPageOne ; FPS=[1+ip,i]
    bcall(_PopRealO2) ; FPS=[1+ip]; OP2=i
    bcall(_FPDiv) ; OP1=[(1+i)^N-1]/i (destroys OP3)
    bcall(_PopRealO2) ; FPS=[]; OP2=1+ip
    bcall(_FPMult) ; OP1=(1+ip)[(1+i)^N-1]/i
    call op1ToOp2PageOne ; OP2=(1+ip)[(1+i)^N-1]/i
    bcall(_OP4ToOP1) ; OP1=(1+i)^N
    ret
#else
    ; Use log1p() and expm1() functions to avoid cancellation errors.
    ;   - OP1=CF1(i)=(1+i)^N=exp(N*log1p(i))
    ;   - OP2=CF3(i)=(1+ip)[(i+i)^N-1]/i=(1+ip)(expm1(N*log1p(i))/i)
    call getTvmIPP ; OP1=i
    bcall(_CkOP1FP0) ; check if i==0.0
    ; CF3(i) has a removable singularity at i=0, so we use a different formula.
    jr z, compoundingFactorsZero
    bcall(_PushRealO1) ; FPS=[i]
    call LnOnePlus ; OP1=ln(1+i)
    call op1ToOp2PageOne
    call RclTvmN ; OP1=N
    bcall(_FPMult) ; OP1=N*ln(1+i)
    bcall(_PushRealO1) ; FPS=[i,N*ln(1+i)]
    call exchangeFPSFPSPageOne ; FPS=[N*ln(1+i),i]
    call ExpMinusOne ; OP1=exp(N*ln(1+i))-1
    call exchangeFPSOP1PageOne ; FPS=[N*ln(1+i),exp(N*ln(1+i))-1]; OP1=i
    bcall(_PushRealO1) ; FPS=[N*ln(1+i),exp(N*ln(1+i))-1,i]; OP1=i
    call beginEndFactor ; OP1=(1+ip)
    bcall(_OP1ToOP4) ; OP4=(1+ip) (save)
    bcall(_PopRealO2) ; FPS=[N*ln(1+i),exp(N*ln(1+i))-1]; OP2=i
    bcall(_PopRealO1) ; FPS=[N*ln(1+i)]; OP1=exp(N*ln(1+i))-1
    bcall(_FPDiv) ; OP1=[exp(N*ln(1+i))-1]/i
    bcall(_OP4ToOP2) ; OP2=(1+ip)
    bcall(_FPMult) ; OP1=CF3=(1+ip)[exp(N*ln(1+i))-1]/i
    call exchangeFPSOP1PageOne ; FPS=[CF3]; OP1=N*ln(1+i)
    bcall(_EToX) ; OP1=exp(N*ln(1+i))
    bcall(_PopRealO2) ; FPS=[]; OP2=CF3
    ret
compoundingFactorsZero:
    ; If i==0, then CF1=1 and CF3=N
    call RclTvmN
    call op1ToOp2PageOne ; OP2=CF3=N
    bcall(_OP1Set1) ; OP1=CF1=1
    ret
#endif

;-----------------------------------------------------------------------------
; TVM Solver routines to calculate IYR using TvmSolve().
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
    call signOfOp1PageOne ; A=signbit(OP1)
    add a, c
    ld c, a ; sumSign+=signbit(OP1)
    ret

; Description: Return (PV+PMT*p), where p=0 (end) or 1 (begin).
; Preserves: BC
tvmCheckPVPMT:
    push bc
    call RclTvmPV
    ld a, (tvmIsBegin)
    or a
    jr z, tvmCheckPVPMTRet ; return if p=begin=0
    call op1ToOp2PageOne
    call RclTvmPMT
    bcall(_FPAdd)
tvmCheckPVPMTRet:
    pop bc
    ret

; Description: Return (PMT*(1-p)+FV), where p=0 or 1.
; Preserves: BC
tvmCheckPMTFV:
    push bc
    call RclTvmFV
    ld a, (tvmIsBegin)
    or a
    jr nz, tvmCheckPMTFVRet ; return if p=begin=1
    call op1ToOp2PageOne
    call RclTvmPMT
    bcall(_FPAdd)
tvmCheckPMTFVRet:
    pop bc
    ret

; Description: Return PMT.
; Preserves: BC
tvmCheckPMT:
    push bc
    call RclTvmPMT
    pop bc
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
    call exchangeFPSOP1PageOne ; FPS=[N,N*i]; OP1=i
    call LnOnePlus ; OP1=ln(1+i)
    call exchangeFPSFPSPageOne ; FPS=[N*i,N]
    bcall(_PopRealO2) ; FPS=[Ni]; OP2=N
    bcall(_FPMult) ; OP1=N*ln(1+i)
    call ExpMinusOne ; OP1=exp(N*ln(1+i))-1
    call op1ToOp2PageOne ; OP2=exp(N*ln(1+i))-1
    bcall(_PopRealO1) ; FPS=[]; OP1=Ni
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
    call op1ToOp2PageOne ; OP2=i
    call RclTvmN ; OP1=N
    call inverseCompoundingFactor ; OP1=ICFN(N,i)
    call op1ToOp2PageOne ; OP2=ICFN(N,i)
    call RclTvmFV ; OP1=FV
    bcall(_FPMult) ; OP1=FV*ICFN(N,i)
    call exchangeFPSOP1PageOne ; FPS=[FV*ICFN()]; OP1=i
    ; Calcuate PV*ICFN(-N,i)
    bcall(_PushRealO1) ; FPS=[FV*ICFN(),i]; OP1=i
    call op1ToOp2PageOne ; OP2=i
    call RclTvmN ; OP1=N
    bcall(_InvOP1S) ; OP1=-N
    call inverseCompoundingFactor ; OP1=ICFN(-N,i)
    call op1ToOp2PageOne ; OP2=ICFN(-N,i)
    call RclTvmPV ; OP1=PV
    bcall(_FPMult) ; OP1=PV*ICFN(-N,i)
    call exchangeFPSOP1PageOne ; FPS=[FV*ICFN(N,i),PV*ICFN(-N,i)]; OP1=i
    ; Calculate (1+ip)PMT*N
    call beginEndFactor ; OP1=(1+ip)
    call op1ToOp2PageOne ; OP2=(1+ip)
    call RclTvmPMT ; OP1=PMT
    bcall(_FPMult) ; OP1=(1+ip)*PMT
    call op1ToOp2PageOne ; OP2=(1+ip)
    call RclTvmN ; OP1=N
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
    call RclTvmI0
    call op1ToOp2PageOne
    call RclTvmNPMT1
    bcall(_PushRealO1) ; FPS=[npmt1]
    bcall(_FPMult) ; OP1=i0*npmt1
    bcall(_PushRealO1) ; FPS=[npmt1,i0*npmt1]
    call RclTvmI1
    call op1ToOp2PageOne
    call RclTvmNPMT0
    bcall(_PushRealO1) ; FPS=[npmt1,i0*npmt1,npmt0]
    bcall(_FPMult) ; OP1=i1*npmt0
    call exchangeFPSFPSPageOne ; FPS=[npmt1,npmt0,i0*npmt1]
    bcall(_PopRealO2) ; FPS=[npmt1,npmt0]; OP2=i0*npmt1
    bcall(_InvSub) ; OP1=i0*npmt1-i1*npmt0
    call exchangeFPSOP1PageOne ; FPS=[npmt1,i0*npmt1-i1*npmt0]; OP1=npmt0
    call op1ToOp2PageOne ; OP2=npmt0
    call exchangeFPSFPSPageOne ; FPS=[i0*npmt1-i1*npmt0,npmt1]; OP2=npmt0
    bcall(_PopRealO1) ; FPS=[i0*npmt1-i1*npmt0]; OP1=npmt1; OP2=npmt0
    bcall(_FPSub)  ; OP1=npmt1-npmt0
    call op1ToOp2PageOne ; OP2=npmt1-npmt0
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
    call RclTvmI1 ; OP1=i1
    call StoTvmI0 ; i1=i0
    call RclTvmNPMT1 ; OP1=npmt1
    call StoTvmNPMT0 ; npmt0=npmt1
    ;
    bcall(_PopRealO1) ; FPS=[i2]; OP1=npmt2
    call StoTvmNPMT1 ; npmt1=npmt2
    bcall(_PopRealO1) ; FPS=[]; OP1=i2
    call StoTvmI1 ; i1=i2
    ret

; Description: Determine if TVM Solver debugging is enabled, which is activated
; when drawMode for TVM Solver is enabled and the TVM Solver is in effect. In
; other words, (drawMode==drawModeTvmSolverI || drawMode==drawModeTvmSolverF)
; && tvmSolverIsRunning.
; Output:
;   - CF: 1 if TVM solver debug enabled; 0 if disabled
; Destroys: A
TvmSolveCheckDebugEnabled:
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
    bit onInterrupt, (iy + onFlags)
    jr nz, tvmSolveCheckTerminationInterrupted
    ;
    ; Check if i0 and i1 are within tolerance, where the relative error =
    ; |i0-i1| < (|i0|+|i1|) * tol. This expression handles the case where the
    ; solution is very close to 0 causing i0 and i1 to straddle zero.
    call RclTvmI0
    call op1ToOp2PageOne ; OP2=i0
    call RclTvmI1 ; OP1=i1
    bcall(_AbsO1PAbsO2) ; OP1=|i0|+|i1|
    call op2Set1EM10PageOne ; OP2=tol
    bcall(_FPMult) ; OP1=tol*(|i0|+|i1|)
    call op1ToOp3PageOne ; OP3=tol*(|i0|+|i1|)
    call RclTvmI0
    call op1ToOp2PageOne ; OP2=i0
    call RclTvmI1 ; OP1=i1
    bcall(_FPSub) ; OP1=(i1-i0)
    call op3ToOp2PageOne ; OP2=tol*(|i0|+|i1|)
    bcall(_AbsO1O2Cp) ; if |OP1| <= |OP2|: CF=1 or ZF=1
    jr c, tvmSolveCheckTerminationFound
    jr z, tvmSolveCheckTerminationFound
    ;
    ; Check iteration counter against tvmIterMax
    ld hl, tvmSolverCount
    ld a, (hl)
    inc a
    ld (hl), a
    ld b, a
    ld a, (tvmIterMax)
    cp b
    jr z, tvmSolveCheckTerminationIterMaxed
    ;
    ; Check if single-step debug mode enabled. This *must* be the last
    ; condition to check, so that when tvmSolve() is called again, it does not
    ; terminate immediately if single-step debugging is enabled.
    call TvmSolveCheckDebugEnabled ; CF=1 if enabled
    jr c, tvmSolveCheckTerminationSingleStep
    ;
    ; Return normal result to indicate the loop should continue.
    ld a, tvmSolverResultContinue
    ret
tvmSolveCheckTerminationInterrupted:
    res onInterrupt, (iy + onFlags)
    ld a, tvmSolverResultBreak
    ret
tvmSolveCheckTerminationFound:
    ld a, tvmSolverResultFound ; Found!
    ret
tvmSolveCheckTerminationIterMaxed:
    ld a, tvmSolverResultIterMaxed
    ret
tvmSolveCheckTerminationSingleStep:
    ld a, tvmSolverResultSingleStep
    ret

; Description: Initialize i0 and i1 from IYR0 and IYR1 respectively.
tvmSolveInitGuesses:
    call RclTvmIYR0
    call TvmCalcIPPFromIYR
    call StoTvmI0
    ;
    call RclTvmIYR1
    call TvmCalcIPPFromIYR
    call StoTvmI1
    ret

; Description: Check if the current tvmI0 and tvmI1 straddle a zero crossing.
; Input: tvmI0, tvmI1
; Output:
;   - ZF=1 if either i0 or i1 evals to 0
;   - A=0 or 1 to indicates which i0 or i1 is the zero (if ZF=1)
;   - CF=1 if there is a zero crossing
;   - CF=0 if no zero crossing
tvmSolveZeroCrossing:
    ; evaluate i0
    call RclTvmI0 ; i0=0.0
    call nominalPMT ; OP1=NPMT(i0)
    call StoTvmNPMT0 ; tvmNPMT0=NPMT(i0)
    bcall(_CkOP1FP0) ; if OP1==0: ZF=set
    jr z, tvmSolveZeroCrossingI0EvalsToZero
    ; Set up the i1 guess
    call RclTvmI1 ; i1=100%/PYR/100
    call nominalPMT ; OP1=NPMT(i1)
    call StoTvmNPMT1 ; tvmNPMT1=NPMT(N,i1)
    bcall(_CkOP1FP0) ; if OP1==0: ZF=set
    jr z, tvmSolveZeroCrossingI1EvalsToZero
    ; Check for different sign bit of NPMT(i)
    call RclTvmNPMT0
    call op1ToOp2PageOne
    call RclTvmNPMT1
    call compareSignOP1OP2PageOne
    jr nz, tvmSolveZeroCrossingTrue
tvmSolveZeroCrossingFalse:
    or 1 ; ZF=0, CF=0
    ret
tvmSolveZeroCrossingI0EvalsToZero:
    ld a, 0
    ret
tvmSolveZeroCrossingI1EvalsToZero:
    ld a, 1
    ret
tvmSolveZeroCrossingTrue:
    scf
    ret

; Description: Calculate the interest rate by solving the root of the NPMT
; equation using the Newton-Secant method. Uses 2 initial interest rate guesses
; in i0 and i1. Usually, they will be i0=0 i1=(100/(PYR)/100) (100%/year). These
; can be overridden using the IYR1 and IYR2 menu items.
;
; The tricky part of this subroutine is that it supports a "single-step"
; debugging mode where it returns to the after each iteration. Then the caller
; can call this routine again, to continue the next iteration. Therefore, this
; routine must preserve enough state information to be able to continue the
; iteration at the correct point.
;
; Input:
;   - A:u8=tvmSolverResultXxx. If tvmSolverResultSingleStep, the subroutine
;   - i0:float=initial guess 1, usually 0%
;   - i1:float=initial guess 0, usually (100%/PYR/100)
;   - both i0 and i1 can be overridden by using the IYR1 and IYR2 menu items
; Output:
;   - A:u8=tvmSolverResultXxx, will never be zero when it returns
;   - OP1:float=the calculated I%YR if A==tvmSolverResultFound
; Destroys:
;   - all registers, OP1-OP5
TvmSolve:
    cp tvmSolverResultSingleStep
    jr z, tvmSolveLoopSingleStepContinue
    ; We are here when starting from scratch. First check if we know
    ; definitively that there are no solutions.
    call tvmCheckNoSolution ; CF=0 if no solution
    jr c, tvmSolveMayExist
    ld a, tvmSolverResultNoSolution
    ret
tvmSolveMayExist:
    ; Set iteration counter to 0 initially. Counting down is more efficient,
    ; but counting up allows better debugging. The number of iterations is so
    ; low that this small bit of inefficiency doesn't matter.
    xor a
    ld (tvmSolverCount), a
    ; Initialize i0 and i1 from IYR0 and IYR1
    call tvmSolveInitGuesses
    call tvmSolveZeroCrossing ; ZF=1 if endpoints zero; CF=1 if zero crossing
    jr z, tvmSolveEndPointsEvalsToZero
    jr nc, tvmSolveNotFound
tvmSolveLoop:
    call tvmSolveCheckTermination ; A=tvmSolverResultXxx
    or a ; if A==0: keep looping
    jr nz, tvmSolveTerminate
tvmSolveLoopSingleStepContinue:
    ; Use Secant method to estimate the next interest rate
    call calculateNextSecantInterest ; OP1=i2
    ;call tvmSolveCheckBounds ; CF=1 if out of bounds
    ; Secant failed. Use bisection.
    ;call c, call calculateNextBisectInterest
    call tvmSolveUpdateGuesses ; update tvmI0,tmvI1
    jr tvmSolveLoop
tvmSolveTerminate:
    cp tvmSolverResultFound
    ret nz ; not found
    ; Found, set OP1 to the result.
tvmSolveSelectI1:
    call RclTvmI1
tvmSolveSelectOP1:
    call calcTvmIYRFromIPP ; convert i (per period) to IYR
    ld a, tvmSolverResultFound
    ret
tvmSolveEndPointsEvalsToZero:
    or a ; ZF=1 if A==0
    jr nz, tvmSolveSelectI1
    call RclTvmI0
    jr tvmSolveSelectOP1
tvmSolveNotFound:
    ld a, tvmSolverResultNotFound
    ret

;-----------------------------------------------------------------------------
; TVM functions for the other 4 variables (N, PV, PMT, FV). See TvmSolve() for
; IYR.
;-----------------------------------------------------------------------------

; Description: Calculate the TVM N variable.
; if i!=0:
;   N = ln(1+N0)/ln(1+i), where
;   N0 = -i(FV+PV)/[PMT*(1+ip)+i*PV]
;   if N0<=-1: no solution
; else:
;   N -> N0/i = -(FV+PV)/PMT
;   if N<=0: no solution
TvmCalculateN:
    call getTvmIPP ; OP1=i
    bcall(_CkOP1FP0) ; check for i==0
    jr z, tvmCalculateNZero
    bcall(_PushRealO1) ; FPS=[i]
    call beginEndFactor ; OP1=1+ip
    call op1ToOp2PageOne ; OP2=1+ip
    call RclTvmPMT ; OP1=PMT
    bcall(_FPMult) ; OP1=PMT*(1+ip)
    bcall(_OP1ToOP4) ; OP4=PMT*(1+ip) (save)
    bcall(_PopRealO2) ; FPS=[]; OP2=i
    bcall(_PushRealO2) ; FPS=[i]
    bcall(_PushRealO2) ; FPS=[i,i]
    call RclTvmPV ; OP1=PV
    bcall(_FPMult) ; OP1=PV*i
    bcall(_OP4ToOP2) ; OP2=PMT*(1+ip)
    bcall(_FPAdd) ; OP1=PMT*(1+ip)+i*PV
    bcall(_PushRealO1) ; FPS[i,i,PMT*(1+ip)+i*PV]
    call RclTvmPV ; OP1=PV
    call op1ToOp2PageOne ; OP2=PV
    call RclTvmFV ; OP1=FV
    bcall(_FPAdd) ; OP1=PV+FV
    bcall(_PopRealO2) ; FPS=[i,i]; OP2=PMT*(1+ip)+i*PV
    bcall(_FPDiv) ; OP1=(FV+PV)/(PMT*(1+ip)+i*PV)
    bcall(_PopRealO2) ; FPS=[i]; OP2=i
    bcall(_FPMult) ; OP1=N0=i*(FV+PV)/(PMT*(1+ip)+i*PV)
    bcall(_InvOP1S) ; OP1=N0=-i*(FV+PV)/(PMT*(1+ip)+i*PV)
    call LnOnePlus ; OP1=ln(1+N0); throws exception if 1+N0<=0
    call exchangeFPSOP1PageOne ; FPS=[ln(1+N0)]; OP1=i
    call LnOnePlus ; OP1=ln(1+i); throws exception if 1+i<=0
    call op1ToOp2PageOne ; OP2=ln(1+i)
    bcall(_PopRealO1) ; FPS=[]; OP1=ln(1+N0)
    bcall(_FPDiv) ; OP1=ln(1+N0)/ln(1+i)
    ret
tvmCalculateNZero:
    ; if i==0: N = (-FV-PV)/PMT
    call RclTvmFV
    call op1ToOp2PageOne
    call RclTvmPV
    bcall(_FPAdd)
    bcall(_InvOP1S)
    call op1ToOp2PageOne
    call RclTvmPMT
    call op1ExOp2PageOne
    bcall(_FPDiv)
    ret

;-----------------------------------------------------------------------------

; Description: Calculate the TVM PV variable.
; PV = [-FV - PMT * [(1+i)N - 1] * (1 + i p) / i] / (1+i)N
;    = [-FV - PMT * CF3(i)] / CF1(i)
; Output: OP1: PV
TvmCalculatePV:
    call compoundingFactors ; OP1=CF1; OP2=CF3
    bcall(_PushRealO1) ; FPS=[CF1]
    call RclTvmPMT ; OP1=PMT
    bcall(_FPMult) ; OP1=PMT*CF3
    call op1ToOp2PageOne ; OP2=PMT*CF3
    call RclTvmFV ; OP1=FV
    bcall(_FPAdd) ; OP1=FV+PMT*CF3
    bcall(_InvOP1S) ; OP1=-OP1
    bcall(_PopRealO2) ; FPS=[]; OP2=CF1
    bcall(_FPDiv) ; OP1=(-FV-PMT*CF3)/CF1
    ret

;-----------------------------------------------------------------------------

; Description: Calculate the TVM PMT variable.
; PMT = [-PV * (1+i)^N - FV] / [((1+i)^N - 1) * (1+ip)/i]
;     = (-PV * CF1(i) - FV) / CF3(i)
; Output: OP1: PMT
TvmCalculatePMT:
    call compoundingFactors ; OP1=CF1; OP2=CF3
    bcall(_PushRealO2) ; FPS=[CF3]
    call op1ToOp2PageOne ; OP2=CF1
    call RclTvmPV ; OP1=PV
    bcall(_FPMult) ; OP1=PV*CF1
    call op1ToOp2PageOne ; OP2=PV*CF1
    call RclTvmFV ; OP1=FV
    bcall(_FPAdd) ; OP1=FV+PV*CF1
    bcall(_InvOP1S) ; OP1=-OP1
    bcall(_PopRealO2) ; FPS=[]; OP2=CF3
    bcall(_FPDiv) ; OP1=(-PV*CF1-FV)/CF3
    ret

;-----------------------------------------------------------------------------

; Description: Calculate the TVM FV variable.
; FV = -PMT * [(1+i)N - 1] * (1 + i p) / i - PV * (1+i)N
;    = -PMT*CF3(i)-PV*CF1(i)
; Output: OP1: FV
TvmCalculateFV:
    call compoundingFactors ; OP1=CF1; OP2=CF3
    bcall(_PushRealO1) ; FPS=[CF1]
    call RclTvmPMT ; OP1=PMT
    bcall(_FPMult) ; OP1=PMT*CF3
    call exchangeFPSOP1PageOne ; FPS=[PMT*CF3]; OP1=CF1
    call op1ToOp2PageOne ; OP2=CF1
    call RclTvmPV ; OP1=PV
    bcall(_FPMult) ; OP1=PV*CF1
    bcall(_PopRealO2) ; FPS=[]; OP2=PMT*CF3
    bcall(_FPAdd) ; OP1=PMT*CF3+PV*CF1
    bcall(_InvOP1S) ; OP1=-OP1
    ret

;-----------------------------------------------------------------------------
; TVM maintenance routines.
;-----------------------------------------------------------------------------

; Description: Clear the 5 NPV or NFV variables.
TvmClear:
    ; Reset the PYR, BEGIN parameters to their defaults.
    xor a
    ld (tvmIsBegin), a
    ld a, 12
    bcall(_SetXXOP1)
    ld de, fin_PY
    call move9FromOp1PageOne
    ld de, fin_CY
    call move9FromOp1PageOne
    ; Clear the 5 TVM equation variables to 0.
    bcall(_OP1Set0)
    ld de, fin_N
    call move9FromOp1PageOne
    ld de, fin_I
    call move9FromOp1PageOne
    ld de, fin_PV
    call move9FromOp1PageOne
    ld de, fin_PMT
    call move9FromOp1PageOne
    ld de, fin_FV
    call move9FromOp1PageOne
    ; [[fallthrough]]

; Description: Reset the TVM Solver parameters to their factory defaults and
; clear the override flags to remove the menu dots.
TvmSolverReset:
    ; Set factory defaults
    bcall(_OP1Set0) ; 0%/year
    call StoTvmIYR0
    call op1Set100PageOne ; 100%/year
    call StoTvmIYR1
    ld a, tvmSolverDefaultIterMax
    call stoTvmIterMaxA
    ; Clear flags
    xor a
    ld (tvmSolverOverrideFlags), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret
