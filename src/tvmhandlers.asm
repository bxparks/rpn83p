;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; TVM menu handlers.
;-----------------------------------------------------------------------------

mTvmNHandler:
    call closeInputBuf
    ld hl, fin_N
    bcall(_Mov9ToOP1)
    jp pushX

mTvmIYRHandler:
    call closeInputBuf
    ld hl, fin_I
    bcall(_Mov9ToOP1)
    jp pushX

mTvmPVHandler:
    call closeInputBuf
    ld hl, fin_PV
    bcall(_Mov9ToOP1)
    jp pushX

mTvmPMTHandler:
    call closeInputBuf
    ld hl, fin_PMT
    bcall(_Mov9ToOP1)
    jp pushX

mTvmFVHandler:
    call closeInputBuf
    ld hl, fin_FV
    bcall(_Mov9ToOP1)
    jp pushX

mTvmPYRHandler:
    call closeInputBuf
    ld hl, fin_PY ; payments / year
    bcall(_Mov9ToOP1)
    jp pushX

mTvmBeginHandler:
    call closeInputBuf
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
    ret

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
    ret
