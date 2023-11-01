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

; Description: Return OP1=(1/i+p).
; Input: OP1=i
; Output: OP1=1/i + p
; Destroys: OP2
calcTvmOneOverIPlusP:
    bcall(_OP1ToOP2) ; OP2=i
    bcall(_OP1Set1) ; OP1=1.0
    bcall(_FPDiv) ; OP1=1/i
    bcall(_OP1ToOP2) ; OP2=1/i
    call getTvmEndBegin ; OP1=p
    bcall(_FPAdd) ; OP1=1/i + p
    ret

;-----------------------------------------------------------------------------

mTvmNHandler:
    call closeInputBuf
    bit rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr nz, mTvmNCalculate
    ; save the inputBuf value
    call stoTvmN
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmNSet
    jp setHandlerCode
mTvmNCalculate:
    call getTvmIntPerPeriod ; OP1=i
    bcall(_PushRealO1) ; FPS=i
    call calcTvmOneOverIPlusP ; OP1=1/i+p
    bcall(_OP1ToOP2) ; OP2=1/i+p
    call rclTvmPMT ; OP1=PMT
    bcall(_FPMult) ; OP1=PMT*(1/i + p)
    bcall(_PushRealO1) ; FPS=PMT*(1/i + p)
    bcall(_OP1ToOP2) ; OP2=PMT*(1/i + p)
    call rclTvmFV ; OP1=FV
    bcall(_InvSub) ; OP1=PMT*(1/i+p)-FV
    call exchangeFPSOP1 ; OP1=PMT*(1/i+p); FPS=PMT*(1/i+p)-FV
    bcall(_OP1ToOP2) ; OP2=PMT*(1/i+p)
    call rclTvmPV ; OP1=PV
    bcall(_FPAdd) ; OP1=PMT*(1/i+p)+PV
    bcall(_PopRealO2) ; OP2=PMT*(1/i+p)-FV
    bcall(_OP1ExOP2)
    bcall(_FPDiv) ; OP1=R=[PMT*(1/i+p)-FV] / [PMT*(1/i+p)+PV]
    call exchangeFPSOP1 ; OP1=i; FPS=R
    bcall(_Plus1) ; OP1=i+1
    bcall(_LnX) ; OP1=ln(i+1)
    bcall(_OP1ToOP2) ; OP2=ln(i+1)
    bcall(_PopRealO1) ; OP1=R
    bcall(_LnX) ; OP1=ln(R)
    bcall(_FPDiv) ; OP1=ln(R)/ln(i+1)
    call stoTvmN
    call pushX
    ld a, errorCodeTvmNCalc
    jp setHandlerCode

mTvmIYRHandler:
    call closeInputBuf
    bit rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr nz, mTvmIYRCalculate
    ; save the inputBuf value
    call stoTvmIYR
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmIYRSet
    jp setHandlerCode
mTvmIYRCalculate:
    ; TODO: Calculate IYR
    ;bcall(_OP1Set1)
    ;call stoTvmIYR
    ;call pushX
    ;ld a, errorCodeTvmIYRCalc
    ;jp setHandlerCode
    jp mNotYetHandler

mTvmPVHandler:
    call closeInputBuf
    bit rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr nz, mTvmPVCalculate
    ; save the inputBuf value
    call stoTvmPV
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmPVSet
    jp setHandlerCode
mTvmPVCalculate:
    call getTvmIntPerPeriod ; OP1=i
    bcall(_PushRealO1) ; FPS=i
    bcall(_Plus1) ; OP1=i+1
    bcall(_OP1ToOP2) ; OP2=i+1
    call rclTvmN ; OP1=N
    bcall(_OP1ExOP2) ; OP1=i+1; OP2=N
    bcall(_YToX) ; OP1=(i+1)^N
    bcall(_OP1ToOP2) ; OP2=(i+1)^N
    call exchangeFPSOP1 ; FPS=(i+1)^N; OP1=i
    bcall(_PushRealO1) ; FPS1=(i+1)^N; FPS=i
    bcall(_OP2ToOP1) ; OP1=(i+1)^N
    bcall(_Minus1) ; OP1=(i+1)^N-1
    bcall(_OP1ToOP2) ; OP1=(i+1)^N-1
    call rclTvmPMT ; OP1=PMT
    bcall(_FPMult) ; OP1=PMT*[(i+1)^N-1]
    call exchangeFPSOP1 ; FPS1=(i+1)^N; FPS=PMT*[(i+1)^N-1]; OP1=i
    call calcTvmOneOverIPlusP ; OP1=1/i+p
    bcall(_OP1ToOP2) ; OP2=1/i+p
    bcall(_PopRealO1) ; FPS=(i+1)^N; OP1=PMT*[(i+1)^N-1]
    bcall(_FPMult) ; OP1=PMT*[(i+1)^N-1] * (1/i+p)
    bcall(_OP1ToOP2) ; OP2=PMT*[(i+1)^N-1] * (1/i+p)
    call rclTvmFV ; OP1=FV
    bcall(_FPAdd) ; OP1=FV+PMT*[(i+1)^N-1] * (1/i+p)
    bcall(_InvOP1S) ; OP1=-OP1
    bcall(_PopRealO2); OP2=(i+1)^N
    bcall(_FPDiv) ; OP1=[-FV-PMT*[(i+1)^N-1] * (1/i+p)]/(i+1)^N
    call stoTvmPV
    call pushX
    ld a, errorCodeTvmPVCalc
    jp setHandlerCode

mTvmPMTHandler:
    call closeInputBuf
    bit rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr nz, mTvmPMTCalculate
    ; save the inputBuf value
    call stoTvmPMT
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmPMTSet
    jp setHandlerCode
mTvmPMTCalculate:
    call getTvmIntPerPeriod ; OP1=i
    bcall(_PushRealO1) ; FPS=i
    call calcTvmOneOverIPlusP ; OP1=(1/i+p)
    call exchangeFPSOP1 ; FPS=(1/i+p); OP1=i
    bcall(_Plus1) ; OP1=i+1
    bcall(_OP1ToOP2) ; OP2=i+1
    call rclTvmN ; OP1=N
    bcall(_OP1ExOP2) ; OP1=i+1; OP2=N
    bcall(_YToX) ; OP1=(i+1)^N
    bcall(_PushRealO1) ; FPS1=1/i+p; FPS=(i+1)^N
    bcall(_Minus1) ; OP1=(i+1)^N-1
    call exchangeFPSOP1 ; FPS1=1/i+p; FPS=(i+1)^N-1; OP1=(i+1)^N
    bcall(_OP1ToOP2)
    call rclTvmPV ; OP1=PV
    bcall(_FPMult) ; OP1=PV*(i+1)^N
    bcall(_OP1ToOP2) ; OP2=PV*(i+1)^N
    call rclTvmFV ; OP1=FV
    bcall(_FPAdd) ; OP1=FV+PV*(i+1)^N
    bcall(_InvOP1S) ; OP1=-OP1
    bcall(_PopRealO2) ; OP2=(i+1)^N-1
    bcall(_FPDiv) ; OP1=-[FV+PV*(i+1)^N]/[(i+1)^N-1]
    bcall(_PopRealO2) ; OP2=1/i+p
    bcall(_FPDiv) ; OP1=-[FV+PV*(i+1)^N]/[(i+1)^N-1]/(1/i+p)
    call stoTvmPMT
    call pushX
    ld a, errorCodeTvmPMTCalc
    jp setHandlerCode

mTvmFVHandler:
    call closeInputBuf
    bit rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr nz, mTvmFVCalculate
    ; save the inputBuf value
    call stoTvmFV
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmFVSet
    jp setHandlerCode
mTvmFVCalculate:
    call getTvmIntPerPeriod ; OP1=i
    bcall(_PushRealO1) ; FPS=i
    call calcTvmOneOverIPlusP ; OP1=(1/i+p)
    call exchangeFPSOP1 ; FPS=(1/i+p); OP1=i
    bcall(_Plus1) ; OP1=i+1
    bcall(_OP1ToOP2) ; OP2=i+1
    call rclTvmN ; OP1=N
    bcall(_OP1ExOP2) ; OP1=i+1; OP2=N
    bcall(_YToX) ; OP1=(i+1)^N
    bcall(_PushRealO1) ; FPS1=1/i+p; FPS=(i+1)^N
    call exchangeFPSFPS ; FPS1=(i+1)^N; FPS=1/i+p
    bcall(_Minus1) ; OP1=(i+1)^N-1
    bcall(_OP1ToOP2)
    call rclTvmPMT ; OP1=PMT
    bcall(_FPMult) ; OP1=PMT*[(i+1)^N-1]
    bcall(_PopRealO2) ; OP2=1/i+p
    bcall(_FPMult) ; OP1=PMT*[(i+1)^N-1]*(1/i+p)
    call exchangeFPSOP1 ; FPS=PMT*[(i+1)^N-1]*(1/i+p); OP1=(i+1)^N
    bcall(_OP1ToOP2)
    call rclTvmPV ; OP1=PV
    bcall(_FPMult) ; OP1=PV*(i+1)^N
    bcall(_PopRealO2) ; OP2=PMT*[(i+1)^N-1]*(1/i+p)
    bcall(_FPAdd) ; OP1=PMT*[(i+1)^N-1]*(1/i+p)+ PV*(i+1)^N
    bcall(_InvOP1S) ; OP1=-OP1
    call stoTvmFV
    call pushX
    ld a, errorCodeTvmFVCalc
    jp setHandlerCode

;-----------------------------------------------------------------------------

; Description: Set P/YR to X.
mTvmSetPYRHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call rclX
    jp stoTvmPYR

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
