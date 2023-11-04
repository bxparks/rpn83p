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
    ret

; Description: Recall fin_N to OP1.
rclTvmN:
    ld hl, fin_N
    bcall(_Mov9ToOP1)
    ret

; Description: Store OP1 to fin_N.
stoTvmN:
    ld de, fin_N
    bcall(_MovFrOP1)
    ret

; Description: Recall fin_I to OP1.
rclTvmIYR:
    ld hl, fin_I
    bcall(_Mov9ToOP1)
    ret

; Description: Store OP1 to fin_I.
stoTvmIYR:
    ld de, fin_I
    bcall(_MovFrOP1)
    ret

; Description: Recall fin_PV to OP1.
rclTvmPV:
    ld hl, fin_PV
    bcall(_Mov9ToOP1)
    ret

; Description: Store OP1 to fin_PV.
stoTvmPV:
    ld de, fin_PV
    bcall(_MovFrOP1)
    ret

; Description: Recall fin_PMT to OP1.
rclTvmPMT:
    ld hl, fin_PMT
    bcall(_Mov9ToOP1)
    ret

; Description: Store OP1 to fin_PMT.
stoTvmPMT:
    ld de, fin_PMT
    bcall(_MovFrOP1)
    ret

; Description: Recall fin_N to OP1.
rclTvmFV:
    ld hl, fin_FV
    bcall(_Mov9ToOP1)
    ret

; Description: Store OP1 to fin_FV.
stoTvmFV:
    ld de, fin_FV
    bcall(_MovFrOP1)
    ret

; Description: Recall fin_PY to OP1.
rclTvmPYR:
    ld hl, fin_PY
    bcall(_Mov9ToOP1)
    ret

; Description: Store OP1 to fin_PY.
stoTvmPYR:
    ld de, fin_PY
    bcall(_MovFrOP1)
    ret

;-----------------------------------------------------------------------------

; Description: Return the interest rate per period: OP1 = i = IYR / PYR / 100.
; Destroys: OP2
getTvmIntPerPeriod:
    call rclTvmPYR
    bcall(_OP1ToOP2)
    call rclTvmIYR
    bcall(_FPDiv)
    call op2Set100
    bcall(_FPDiv)
    ret

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
; Destroys: OP1, OP2
beginEndFactor:
    bit rpnFlagsTvmPmtBegin, (iy + rpnFlags)
    jr nz, beginFactor
endFactor:
    bcall(_OP1Set1) ; OP1=1.0
    ret
beginFactor:
    bcall(_Plus1) ; OP1=1+i
    ret

; Description: Calculate the compounding factor defined by: [(1+i)^N-1]/i.
; Input:
;   - rclTvmIYR
;   - rclTvmPYR
;   - rclTvmN
; Output:
;   - OP1=CF1(i)=(1+i)^N
;   - OP2=CF3(i)=(1+ip)[(i+i)^N-1]/i
; Destroys: OP1-OP6
compoundingFactors:
    call getTvmIntPerPeriod ; OP1=i
    bcall(_PushRealO1) ; FPS=i
    bcall(_PushRealO1) ; FPS1=i; FPS=i
    call rclTvmN ; OP1=N
    call exchangeFPSOP1 ; FPS1=i; FPS=N; OP1=i
    bcall(_PushRealO1) ; FPS2=i; FPS1=N; FPS=i
    call beginEndFactor ; OP1=(1+ip)
    call exchangeFPSOP1 ; FPS2=i; FPS1=N; FPS=1+ip; OP1=i
    bcall(_Plus1) ; OP1=1+i (destroys OP2)
    call exchangeFPSFPS ; FPS2=i; FPS1=1+ip; FPS=N
    bcall(_PopRealO2) ; FPS1=i; FPS=1+ip; OP2=N
    bcall(_YToX) ; OP1=(1+i)^N
    bcall(_OP1ToOP4) ; OP4=(1+i)^N (save)
    bcall(_Minus1) ; OP1=(1+i)^N-1
    call exchangeFPSFPS ; FPS1=1+ip; FPS=i
    bcall(_PopRealO2) ; OP2=i
    bcall(_FPDiv) ; OP1=[(1+i)^N-1]/i (destroys OP3)
    bcall(_PopRealO2) ; OP2=1+ip
    bcall(_FPMult) ; OP1=(1+ip)[(1+i)^N-1]/i
    bcall(_OP1ToOP2) ; OP2=(1+ip)[(1+i)^N-1]/i
    bcall(_OP4ToOP1) ; OP1=(1+i)^N
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
    ; N = ln R / ln(1+i), where
    ; R = [PMT*(1+ip)-i*FV]/[PMT*(1+ip)+i*PV]jjj
    call getTvmIntPerPeriod ; OP1=i
    bcall(_PushRealO1) ; FPS=i
    call beginEndFactor ; OP1=1+ip
    bcall(_OP1ToOP2) ; OP2=1+ip
    call rclTvmPMT ; OP1=PMT
    bcall(_FPMult) ; OP1=PMT*(1+ip)
    bcall(_OP1ToOP4) ; OP4=PMT*(1+ip) (save)
    bcall(_PopRealO2) ; OP2=i
    bcall(_PushRealO2) ; FPS=i
    bcall(_PushRealO2) ; FPS1=i, FPS=i
    call rclTvmFV ; OP1=FV
    bcall(_FPMult) ; OP1=FV*i
    bcall(_OP4ToOP2) ; OP2=PMT*(1+ip)
    bcall(_InvSub) ; OP1=PMT*(1+ip)-FV*i
    call exchangeFPSOP1 ; FPS1=i; FPS=PMT*(1+ip)-FV; OP1=i
    bcall(_OP1ToOP2) ; OP2=i
    call rclTvmPV ; OP1=PV
    bcall(_FPMult) ; OP1=PV*i
    bcall(_OP4ToOP2) ; OP2=PMT*(1+ip)
    bcall(_FPAdd) ; OP1=PMT*(1+ip)+PV*i
    bcall(_PopRealO2) ; FPS=i; OP2=PMT*(1+ip)-FV*i
    bcall(_OP1ExOP2)
    bcall(_FPDiv) ; OP1=R=[PMT*(1+ip)-FV*i] / [PMT*(1+ip)+PV*i]
    call exchangeFPSOP1 ; OP1=i; FPS=R
    bcall(_Plus1) ; OP1=i+1
    bcall(_LnX) ; OP1=ln(i+1)
    call exchangeFPSOP1 ; FPS=ln(i+1); OP1=R
    bcall(_LnX) ; OP1=ln(R)
    bcall(_PopRealO2) ; OP2=ln(i+1)
    bcall(_FPDiv) ; OP1=ln(R)/ln(i+1)
    call stoTvmN
    call pushX
    ld a, errorCodeTvmCalculated
    jp setHandlerCode

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
    ; TODO: Calculate IYR
    ;bcall(_OP1Set1)
    ;call stoTvmIYR
    ;call pushX
    ;ld a, errorCodeTvmCalculated
    ;jp setHandlerCode
    jp mNotYetHandler

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
    call compoundingFactors ; OP1=CF1; OP2=CF3
    bcall(_PushRealO1) ; FPS=CF1
    call rclTvmPMT ; OP1=PMT
    bcall(_FPMult) ; OP1=PMT*CF3
    bcall(_OP1ToOP2) ; OP2=PMT*CF3
    call rclTvmFV ; OP1=FV
    bcall(_FPAdd) ; OP1=FV+PMT*CF3
    bcall(_InvOP1S) ; OP1=-OP1
    bcall(_PopRealO2); OP2=CF1
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
    ; PMT = [-PV * (1+i)N - FV] / [((1+i)N - 1) * (1 + i p) / i]
    ;     = (-PV * CF1(i) - FV) / CF3(i)
    call compoundingFactors ; OP1=CF1; OP2=CF3
    bcall(_PushRealO2) ; FPS=CF3
    bcall(_OP1ToOP2) ; OP2=CF1
    call rclTvmPV ; OP1=PV
    bcall(_FPMult) ; OP1=PV*CF1
    bcall(_OP1ToOP2) ; OP2=PV*CF1
    call rclTvmFV ; OP1=FV
    bcall(_FPAdd) ; OP1=FV+PV*CF1
    bcall(_InvOP1S) ; OP1=-OP1
    bcall(_PopRealO2) ; OP2=CF3
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
    ;    = -PMT*CF3-PV*CF1
    call compoundingFactors ; OP1=CF1; OP2=CF3
    bcall(_PushRealO1) ; FPS=CF1
    call rclTvmPMT ; OP1=PMT
    bcall(_FPMult) ; OP1=PMT*CF3
    call exchangeFPSOP1 ; FPS=PMT*CF3; OP1=CF1
    bcall(_OP1ToOP2) ; OP2=CF1
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
    bcall(_MovFrOP1)
    ld de, fin_CY
    bcall(_MovFrOP1)
    ret

tvmClear:
    bcall(_OP1Set0)
    ld de, fin_N
    bcall(_MovFrOP1)
    ld de, fin_I
    bcall(_MovFrOP1)
    ld de, fin_PV
    bcall(_MovFrOP1)
    ld de, fin_PMT
    bcall(_MovFrOP1)
    ld de, fin_FV
    bcall(_MovFrOP1)
    ret
