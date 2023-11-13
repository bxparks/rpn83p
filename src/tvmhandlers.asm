;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; TVM menu handlers.
;-----------------------------------------------------------------------------

initTvm:
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call tvmReset
    call tvmClear
    ; [[fallthrough]]

initTvmSolver:
    xor a
    ld (tvmSolverStatus), a
    ret

;-----------------------------------------------------------------------------
; Store and recall the TVM variables. The recall functions use the cal_xx
; variables so moveTvmToCalc() must be called at the start of a sequence of
; calculation. The store functions stores OP1 to the fin_xx variables.
;
; The cal_xx variables are used for computation so that if an exception is
; thrown the middle of a long calculation that modifies the cal_xx variables,
; the original fin_xx variables are unaffected. Essentially, the cal_xx
; variables are used for passing the TVM parameters to the various functions.
;-----------------------------------------------------------------------------

; Description: Recall cal_N to OP1.
rclTvmN:
    ld hl, cal_N
    jp move9ToOp1

; Description: Store OP1 to fin_N.
stoTvmN:
    ld de, fin_N
    jp move9FromOp1

; Description: Recall cal_I to OP1.
rclTvmIYR:
    ld hl, cal_I
    jp move9ToOp1

; Description: Store OP1 to fin_I.
stoTvmIYR:
    ld de, fin_I
    jp move9FromOp1

; Description: Recall cal_PV to OP1.
rclTvmPV:
    ld hl, cal_PV
    jp move9ToOp1

; Description: Store OP1 to fin_PV.
stoTvmPV:
    ld de, fin_PV
    jp move9FromOp1

; Description: Recall cal_PMT to OP1.
rclTvmPMT:
    ld hl, cal_PMT
    jp move9ToOp1

; Description: Store OP1 to fin_PMT.
stoTvmPMT:
    ld de, fin_PMT
    jp move9FromOp1

; Description: Recall cal_N to OP1.
rclTvmFV:
    ld hl, cal_FV
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

; Description: Copy the 5 fin_xxx variables to the cal_xxx working variables,
; so that intermediate calculations can modify the cal_xxx variables without
; affecting the fin_xxx variables until the very end. These variables are
; defined sequentially, so we can use the LDIR instruction.
; Destroys: BC, DE, HL
moveTvmToCalc:
    ld de, cal_N
    ld hl, fin_N
    ld bc, 5*9 ; 5 variables x 9 bytes
    ldir
    ret

; Description: Copy the 6 working cal_xxx variables to the fin_xxx.
; Destroys: BC, DE, HL
;moveCalcToTvm:
;    ld de, fin_N
;    ld hl, cal_N
;    ld bc, 5*9 ; 6 variables x 9 bytes
;    ldir
;    ret

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
    bcall(_SetXXOP1) ; OP1=float(A)
    ret

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
; Destroys: OP1
getTvmEndBegin:
    bit rpnFlagsTvmPmtBegin, (iy + rpnFlags)
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
; Destroys: OP1
; Preserves: OP2
beginEndFactor:
    bit rpnFlagsTvmPmtBegin, (iy + rpnFlags)
    jr nz, beginFactor
endFactor:
    bcall(_OP1Set1) ; OP1=1.0
    ret
beginFactor:
    bcall(_PushRealO2)
    bcall(_Plus1) ; OP1=1+i
    bcall(_PopRealO2)
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
    bcall(_PopRealO2) ; OP2=i
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
    bcall(_FPMult) ; OP1=(1+ip)[exp(N*ln(1+i))-1]/i
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
; If PV, PMT, and PMT+FV all have the same sign, then there are no solutions.
;
; Input: tvmPV, tvmFV, tvmN, tvmPMT
; Output:
;   - ZF=0 if solution *may* exist
;   - ZF=1 if no solution exists
; Destroys: OP1, OP2
tvmSolverCheckNoSolution:
    call rclTvmPMT
    call op1ToOp2
    call rclTvmFV
    bcall(_FPAdd) ; OP1=PMT+FV
    ld a, (OP1) ; A=sign(PMT+FV)
    call rclTvmPV ; OP1=PV; preserves A
    ld b, a ; B=sign(PMT+FV)
    ld a, (OP1)
    xor b ; A=sign(PMT+FV) XOR sign(PV), bit7=1 if different
    and $80 ; ZF=1 if same, 0 if different
    ret nz ; ret ZF=0 if different, solution may exist
    ld a, b ; save B=sign(PMT+FV)
    call rclTvmFV ; preserves A
    ld b, a
    ld a, (OP1) ; OP1=sign(FV)
    xor b ; A=sign(PMT+FV) XOR sign(FV), bit7=1 if different
    and $80 ; ZF=1 if same, 0 if different
    ret ; ZF=0 if different, solution may exist; ZF=1 no solution

; Description: Return the function C(N,i) = N*i/((1+i)^N-1)) =
; N*i/((expm1(N*log1p(i)) which is the reciprocal of the compounding factor,
; with a special case of C(N,0)=1 to remove a singularity at i=0.
; Input:
;   - fin_PV, fin_PMT, fin_FV, fin_PY
;   - OP1: N
;   - OP2: i (fractional interest per period)
; Output: OP1: C(N,i)
; Destroys: OP1-OP5
inverseCompoundingFactor:
    bcall(_CkOP2FP0) ; check if i==0.0
    ; C(N,i) has a removable singularity at i=0
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
;   NPMT(i,N) = PV*C(-N,i) + (1+ip)PMT*N + FV*C(N,i) = 0
; where
;   C(N,i) = inverseCompoundingFactor(N,i) defined above.
;
; It is roughly the total nominal amount of money that was paid out
; (positive sign), if the discount-equivalent of PV and FV had been
; spread out across N payments at the given interest rate i.
;
; Input:
;   - moveTvmToCalc() must be called to populate the cal_xx variables
;   - OP1: i (interest per period)
; Output: OP1=NPMT(i)
; Destroys: OP1-OP5
nominalPMT:
    bcall(_PushRealO1) ; FPS=[i]
    ; Calculate FV*C(N,i)
    call op1ToOP2 ; OP2=i
    call rclTvmN ; OP1=N
    call inverseCompoundingFactor ; OP1=C(N,i)
    call op1ToOP2 ; OP2=C(N,i)
    call rclTvmFV ; OP1=FV
    bcall(_FPMult) ; OP1=FV*C(N,i)
    call exchangeFPSOP1 ; FPS=[FV*C()]; OP1=i
    ; Calcuate PV*C(-N,i)
    bcall(_PushRealO1) ; FPS=[FV*C(),i]; OP1=i
    call op1ToOP2 ; OP2=i
    call rclTvmN ; OP1=N
    bcall(_InvOP1S) ; OP1=-N
    call inverseCompoundingFactor ; OP1=C(-N,i)
    call op1ToOP2 ; OP2=C(-N,i)
    call rclTvmPV ; OP1=PV
    bcall(_FPMult) ; OP1=PV*C(-N,i)
    call exchangeFPSOP1 ; FPS=[FV*C(N,i),PV*C(-N,i)]; OP1=i
    ; Calculate (1+ip)PMT*N
    call beginEndFactor ; OP1=(1+ip)
    call op1ToOP2 ; OP2=(1+ip)
    call rclTvmPMT ; OP1=PMT
    bcall(_FPMult) ; OP1=(1+ip)*PMT
    call op1ToOP2 ; OP2=(1+ip)
    call rclTvmN ; OP1=N
    bcall(_FPMult) ; OP1=(1+ip)*PMT*N
    ; Sum up the 3 terms
    bcall(_PopRealO2) ; FPS=[FV*C(N,i)]; OP2=PV*C(-N,i)
    bcall(_FPAdd) ; OP1=PV*C(-N,i)+(1+ip)*PMT*N
    bcall(_PopRealO2) ; FPS=[]; OP2=FV*C(N,i)
    bcall(_FPAdd) ; OP1=PV*C(-N,i)+(1+ip)*PMT*N+FV*C(N,i)
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
updateInterestGuesses:
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
; && tvmSolverStatus!=0.
; Output:
;   - CF: 1 if TVM solver debug enabled; 0 if disabled
; Destroys: A
tvmSolverCheckDebugEnabled:
    ld a, (tvmSolverStatus)
    or a
    ret z ; CF==0 if TVM Solver not running
    ; check for drawMode 1 or 2
    ld a, (drawMode)
    dec a
    jr z, tvmSolverDebugEnabled
    dec a
    jr z, tvmSolverDebugEnabled
    or a ; CF=0
    ret
tvmSolverDebugEnabled:
    scf ; CF=1
    ret

; Description: Check if the root finding iteration should stop.
; Input: i0, i1
; Output:
;   - (tvmSolverResult) set to status
;   - CF=1 if should terminate
; Destroys: A
checkInterestTermination:
    ; Display debugging progress if enabled
    call tvmSolverCheckDebugEnabled ; CF=1 if enabled
    jr nc, checkInterestNoDebug
    call displayAll
    bcall(_GetKey) ; pause
    bit dirtyFlagsStack, (iy + dirtyFlags)
checkInterestNoDebug:
    ; Check for ON/Break
    bit onInterrupt, (IY+onFlags)
    jp nz, checkInterestBreak
    ; Check if i0 and i1 are within tolerance. If i1!=0.0, then use relative
    ; error |i0-i1|/|i1| < tol. Otherwise use absolute error |i0-i1| < tol.
    call rclTvmI0
    call op1ToOP2
    call rclTvmI1
    bcall(_PushRealO1) ; FPS=[i1]
    bcall(_FPSub) ; OP1=(i1-i0)
    bcall(_PopRealO2) ; FPS=[]; OP2=i1
    bcall(_CkOP2FP0) ; if OP2==0: ZF=1
    jr z, checkInterestNoRelativeError
    bcall(_FPDiv) ; OP1=(i1-i0)/i1
checkInterestNoRelativeError:
    call op2Set1EM8 ; OP2=1e-8
    bcall(_AbsO1O2Cp) ; if |OP1| < |OP2|: CF=1
    jr c, checkInterestFound
    ; Check iteration counter
    ld hl, tvmSolverCount
    ld a, (hl)
    inc a
    ld (hl), a
    cp a, tvmSolverIterMax
    jr z, checkInterestIterMaxed
    or a ; CF=0 to continue
    ret
checkInterestFound:
    ld a, tvmSolverResultFound
    jr checkInterestTerminate
checkInterestBreak:
    res onInterrupt, (iy + onFlags)
    ld a, tvmSolverResultBreak
    jr checkInterestTerminate
checkInterestIterMaxed:
    ld a, tvmSolverResultIterMaxed
checkInterestTerminate:
    ld (tvmSolverResult), a
    scf ; CF=1 to terminate
    ret

; Description: Calculate the interest rate by solving the root of the NPMT
; equation using the Newton-Secant method. Uses 2 initial interest rate
; guesses:
;   - i0=0
;   - i1=100 (100%/year)
; Input:
;   - moveTvmToCalc() must be called to populate the cal_xx variables
; Output:
;   - OP1: the calculated I%YR if tvmSolverResult==Found
;   - (tvmSolverResult) set
; Destroys:
;   - OP1-OP5
calculateInterest:
    ld a, 1
    ld (tvmSolverStatus), a
    ; Set iteration counter to 0 initially. Counting down is more efficient,
    ; but counting up allows better debugging. The number of iterations is so
    ; low that the small bit of inefficiency here doesn't matter.
    xor a
    ld (tvmSolverCount), a
    ; Set up i0 using 0.0%
    bcall(_OP1Set0) ; OP1=0.0
    call stoTvmI0 ; i0=0.0
    call nominalPMT ; OP1=NPMT(i0)
    call stoTvmNPMT0 ; tvmNPMT0=NPMT(i0)
    bcall(_CkOP1FP0) ; if OP1==0: ZF=set
    jr z, calculateInterestI0Zero
    ; Set up i1 using 100.0%
    call op1Set100 ; OP1=100.0%
    call calcTvmIntPerPeriod
    call stoTvmI1 ; i1=100%/PYR/100
    call nominalPMT ; OP1=NPMT(i1)
    call stoTvmNPMT1 ; tvmNPMT1=NPMT(N,i1)
    bcall(_CkOP1FP0) ; if OP1==0: ZF=set
    jr z, calculateInterestI1Zero
    ; Check for different sign bit of NPMT(i)
    call rclTvmNPMT0
    call op1ToOP2
    call rclTvmNPMT1
    call compareSignOP1OP2
    jr z, calculateInterestNotFound
calculateInterestLoop:
    call checkInterestTermination
    jr c, calculateInterestTerminate
    ; Use Secant method to estimate the next interest rate
    call calculateNextSecantInterest ; OP1=i2
    ;call checkInterestBounds ; CF=1 if out of bounds
    ; Secant failed. Use bisection.
    ;call c, call calculateNextBisectInterest
    call updateInterestGuesses ; update tvmI0,tmvI1
    jr calculateInterestLoop
calculateInterestTerminate:
    ld a, (tvmSolverResult)
    or a
    jr nz, calculateInterestEnd ; if status!=tvmSolverResultFound: return
    ; Found!
    call rclTvmI1
    call calcTvmIYR
    jr calculateInterestFound
calculateInterestNotFound:
    ld a, tvmSolverResultNotFound
    ld (tvmSolverResult), a
    jr calculateInterestEnd
calculateInterestI0Zero:
    bcall(_OP1Set0) ; OP1=0.0
    jr calculateInterestFound
calculateInterestI1Zero:
    call op1Set100 ; OP1=100.0%
calculateInterestFound:
    xor a
    ld (tvmSolverResult), a
calculateInterestEnd:
    call tvmSolverCheckDebugEnabled ; CF=1 if enabled
    jr nc, calculateInterestEndNoDirty
    set dirtyFlagsStack, (iy + dirtyFlags)
calculateInterestEndNoDirty:
    xor a
    ld (tvmSolverStatus), a
    ret

;-----------------------------------------------------------------------------

mTvmNHandler:
    call closeInputBuf
    bit rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr nz, mTvmNCalculate
    ; save the inputBuf value
    call stoTvmN
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmSet
    jp setHandlerCode
mTvmNCalculate:
    ; if i>0: N = ln(R) / ln(1+i)
    ; where: R = [PMT*(1+ip)-i*FV]/[PMT*(1+ip)+i*PV]
    ;
    ; TODO: Maybe use R = [1 - i*FV/(PMT*(1+ip))]/[1 + i*PV/(PMT*(1+ip))], then
    ; use log1p() for the denominator and numerator separately. This will be
    ; more robust if i becomes very small. On the other hand, if PMT==0, then
    ; this version will fail. So maybe we need to have 2 different formulas,
    ; depending on the relative size of PMT(1+ip) compared to i*FV and i*PV.
    call moveTvmToCalc
    call getTvmIntPerPeriod ; OP1=i
    bcall(_CkOP1FP0) ; check for i==0
    jr z, mTvmNCalculateZero
    bcall(_PushRealO1) ; FPS=[i]
    call beginEndFactor ; OP1=1+ip
    call op1ToOP2 ; OP2=1+ip
    call rclTvmPMT ; OP1=PMT
    bcall(_FPMult) ; OP1=PMT*(1+ip)
    bcall(_OP1ToOP4) ; OP4=PMT*(1+ip) (save)
    bcall(_PopRealO2) ; FPS=[]; OP2=i
    bcall(_PushRealO2) ; FPS=[i]
    bcall(_PushRealO2) ; FPS=[i,i]
    call rclTvmFV ; OP1=FV
    bcall(_FPMult) ; OP1=FV*i
    bcall(_OP4ToOP2) ; OP2=PMT*(1+ip)
    bcall(_InvSub) ; OP1=PMT*(1+ip)-FV*i
    call exchangeFPSOP1 ; FPS=[i,PMT*(1+ip)-FV]; OP1=i
    call op1ToOP2 ; OP2=i
    call rclTvmPV ; OP1=PV
    bcall(_FPMult) ; OP1=PV*i
    bcall(_OP4ToOP2) ; OP2=PMT*(1+ip)
    bcall(_FPAdd) ; OP1=PMT*(1+ip)+PV*i
    bcall(_PopRealO2) ; FPS=[i]; OP2=PMT*(1+ip)-FV*i
    call op1ExOp2
    bcall(_FPDiv) ; OP1=R=[PMT*(1+ip)-FV*i] / [PMT*(1+ip)+PV*i]
    bcall(_LnX) ; OP1=ln(R)
    call exchangeFPSOP1 ; FPS=[ln(R)]; OP1=i
    call lnOnePlus ; OP1=ln(i+1)
    call op1ToOP2 ; OP2=ln(i+1)
    bcall(_PopRealO1) ; FPS=[]; OP1=ln(R)
    bcall(_FPDiv) ; OP1=ln(R)/ln(i+1)
mTvmNCalculateSto:
    call stoTvmN
    call pushX
    ld a, errorCodeTvmCalculated
    jp setHandlerCode
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

mTvmIYRHandler:
    call closeInputBuf
    bit rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr nz, mTvmIYRCalculate
    ; save the inputBuf value
    call stoTvmIYR
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmSet
    jp setHandlerCode
mTvmIYRCalculate:
    ; Interest rate does not have a closed-form solution, so requires solving
    ; the root of an equation. First, determine if equation has no roots
    ; definitively.
    call moveTvmToCalc
    call tvmSolverCheckNoSolution ; ZF=0 if no solution
    jr nz, mTvmIYRCalculateMayExists
    ; Cannot have a solution
    ld a, errorCodeTvmNoSolution
    jp setHandlerCode
mTvmIYRCalculateMayExists:
    bcall(_RunIndicOn)
    call calculateInterest
    ld a, (tvmSolverResult)
    or a
    jr nz, mTvmIYRCalculateNotFound
    ; Found!
    call stoTvmIYR
    call pushX
    ld a, errorCodeTvmCalculated
    jr mTvmIYRCalculateEnd
mTvmIYRCalculateNotFound:
    dec a
    jr nz, mTvmIYRCalculateCheckIterMax
    ; root not found because sign +/- was not detected in initial guess
    ld a, errorCodeTvmNotFound
    jr mTvmIYRCalculateEnd
mTvmIYRCalculateCheckIterMax:
    dec a
    jr nz, mTvmIYRCalculateBreak
    ; root not found after max iterations
    ld a, errorCodeTvmIterations
    jr mTvmIYRCalculateEnd
mTvmIYRCalculateBreak:
    ; user hit ON/EXIT
    ld a, errorCodeBreak
mTvmIYRCalculateEnd:
    push af
    bcall(_RunIndicOff)
    pop af
    jp setHandlerCode

mTvmPVHandler:
    call closeInputBuf
    bit rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr nz, mTvmPVCalculate
    ; save the inputBuf value
    call stoTvmPV
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmSet
    jp setHandlerCode
mTvmPVCalculate:
    ; PV = [-FV - PMT * [(1+i)N - 1] * (1 + i p) / i] / (1+i)N
    ;    = [-FV - PMT * CF3(i)] / CF1(i)
    call moveTvmToCalc
    call compoundingFactors ; OP1=CF1; OP2=CF3
    bcall(_PushRealO1) ; FPS=[CF1]
    call rclTvmPMT ; OP1=PMT
    bcall(_FPMult) ; OP1=PMT*CF3
    call op1ToOP2 ; OP2=PMT*CF3
    call rclTvmFV ; OP1=FV
    bcall(_FPAdd) ; OP1=FV+PMT*CF3
    bcall(_InvOP1S) ; OP1=-OP1
    bcall(_PopRealO2); FPS=[]; OP2=CF1
    bcall(_FPDiv) ; OP1=(-FV-PMT*CF3)/CF1
    call stoTvmPV
    call pushX
    ld a, errorCodeTvmCalculated
    jp setHandlerCode

mTvmPMTHandler:
    call closeInputBuf
    bit rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr nz, mTvmPMTCalculate
    ; save the inputBuf value
    call stoTvmPMT
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmSet
    jp setHandlerCode
mTvmPMTCalculate:
    ; PMT = [-PV * (1+i)^N - FV] / [((1+i)^N - 1) * (1+ip)/i]
    ;     = (-PV * CF1(i) - FV) / CF3(i)
    call moveTvmToCalc
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
    jp setHandlerCode

mTvmFVHandler:
    call closeInputBuf
    bit rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr nz, mTvmFVCalculate
    ; save the inputBuf value
    call stoTvmFV
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmSet
    jp setHandlerCode
mTvmFVCalculate:
    ; FV = -PMT * [(1+i)N - 1] * (1 + i p) / i - PV * (1+i)N
    ;    = -PMT*CF3(i)-PV*CF1(i)
    call moveTvmToCalc
    call compoundingFactors ; OP1=CF1; OP2=CF3
    bcall(_PushRealO1) ; FPS=CF1
    call rclTvmPMT ; OP1=PMT
    bcall(_FPMult) ; OP1=PMT*CF3
    call exchangeFPSOP1 ; FPS=PMT*CF3; OP1=CF1
    call op1ToOP2 ; OP2=CF1
    call rclTvmPV ; OP1=PV
    bcall(_FPMult) ; OP1=PV*CF1
    bcall(_PopRealO2) ; OP2=PMT*CF3
    bcall(_FPAdd) ; OP1=PMT*CF3+PV*CF1
    bcall(_InvOP1S) ; OP1=-OP1
    call stoTvmFV
    call pushX
    ld a, errorCodeTvmCalculated
    jp setHandlerCode

;-----------------------------------------------------------------------------

; Description: Set P/YR to X.
mTvmSetPYRHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call rclX
    call stoTvmPYR
    ld a, errorCodeTvmSet
    jp setHandlerCode

; Description: Get P/YR to X.
mTvmGetPYRHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call rclTvmPYR
    jp pushX

mTvmBeginHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    set rpnFlagsTvmPmtBegin, (iy + rpnFlags)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Return A if rpnFlagsTvmPmtBegin is zero, C otherwise.
mTvmBeginNameSelector:
    bit rpnFlagsTvmPmtBegin, (iy + rpnFlags)
    ret z
    ld a, c
    ret

mTvmEndHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    res rpnFlagsTvmPmtBegin, (iy + rpnFlags)
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ret

; Return C if rpnFlagsTvmPmtBegin is zero, A otherwise.
mTvmEndNameSelector:
    bit rpnFlagsTvmPmtBegin, (iy + rpnFlags)
    ret nz
    ld a, c
    ret

mTvmResetHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call tvmReset
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ld a, errorCodeTvmReset
    jp setHandlerCode

mTvmClearHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call tvmClear
    ld a, errorCodeTvmCleared
    jp setHandlerCode

;-----------------------------------------------------------------------------

tvmReset:
    res rpnFlagsTvmPmtBegin, (iy + rpnFlags)
    ld a, 12
    bcall(_SetXXOP1)
    ld de, fin_PY
    call move9FromOp1
    ld de, fin_CY
    jp move9FromOp1

tvmClear:
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
    jp move9FromOp1
