;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; TVM menu handlers.
;-----------------------------------------------------------------------------

mTvmNHandler:
    call closeInputBuf
    bit rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr nz, mTvmNCalculate
    ; save the inputBuf value
    ld de, fin_N
    bcall(_MovFrOP1)
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmNSet
    jp setHandlerCode
mTvmNCalculate:
    ; TODO: Calculate N
    bcall(_OP1Set0)
    ;ld hl, fin_N
    ;bcall(_Mov9ToOP1)
    call pushX
    ld a, errorCodeTvmNCalc
    jp setHandlerCode

mTvmIYRHandler:
    call closeInputBuf
    bit rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr nz, mTvmIYRCalculate
    ; save the inputBuf value
    ld de, fin_I
    bcall(_MovFrOP1)
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmIYRSet
    jp setHandlerCode
mTvmIYRCalculate:
    ; TODO: Calculate IYR
    bcall(_OP1Set1)
    ;ld hl, fin_I
    ;bcall(_Mov9ToOP1)
    call pushX
    ld a, errorCodeTvmIYRCalc
    jp setHandlerCode

mTvmPVHandler:
    call closeInputBuf
    bit rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr nz, mTvmPVCalculate
    ; save the inputBuf value
    ld de, fin_PV
    bcall(_MovFrOP1)
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmPVSet
    jp setHandlerCode
mTvmPVCalculate:
    ; TODO: Calculate IYR
    bcall(_OP1Set2)
    ;ld hl, fin_PV
    ;bcall(_Mov9ToOP1)
    call pushX
    ld a, errorCodeTvmPVCalc
    jp setHandlerCode

mTvmPMTHandler:
    call closeInputBuf
    bit rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr nz, mTvmPMTCalculate
    ; save the inputBuf value
    ld de, fin_PMT
    bcall(_MovFrOP1)
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmPMTSet
    jp setHandlerCode
mTvmPMTCalculate:
    ; TODO: Calculate PMT
    bcall(_OP1Set3)
    ;ld hl, fin_PMT
    ;bcall(_Mov9ToOP1)
    call pushX
    ld a, errorCodeTvmPMTCalc
    jp setHandlerCode

mTvmFVHandler:
    call closeInputBuf
    bit rpnFlagsTvmCalculate, (iy + rpnFlags)
    jr nz, mTvmFVCalculate
    ; save the inputBuf value
    ld de, fin_FV
    bcall(_MovFrOP1)
    set rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld a, errorCodeTvmFVSet
    jp setHandlerCode
mTvmFVCalculate:
    ; TODO: Calculate FV
    bcall(_OP1Set4)
    ;ld hl, fin_FV
    ;bcall(_Mov9ToOP1)
    call pushX
    ld a, errorCodeTvmFVCalc
    jp setHandlerCode

; Description: Set P/YR to X.
mTvmSetPYRHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    call rclX
    ld de, fin_PY ; payments / year
    bcall(_MovFrOP1)
    ret

; Description: Get P/YR to X.
mTvmGetPYRHandler:
    call closeInputBuf
    res rpnFlagsTvmCalculate, (iy + rpnFlags)
    ld hl, fin_PY ; payments / year
    bcall(_Mov9ToOP1)
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
    ; Set payment period to END
    call mTvmEndHandler
    ; Set payments per year to 12
    ld a, 12
    bcall(_SetXXOP1)
    ld de, fin_PY
    bcall(_MovFrOP1)
    ld de, fin_CY
    bcall(_MovFrOP1)
    ld a, errorCodeTvmReset
    jp setHandlerCode

mTvmClearHandler:
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
    ld a, errorCodeTvmCleared
    jp setHandlerCode
