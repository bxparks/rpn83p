;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Floating point common routines.
;-----------------------------------------------------------------------------

; Description: Exchange OP2 and FPS.
; Destroys: all registers
exchangeFPSOP2:
    ld hl, OP2
    jr exchangeFPSHL

; Description: Exchange OP1 and FPS.
; Destroys: all registers
exchangeFPSOP1:
    ld hl, OP1
    ; [[fallthrough]]

; Description: Exchange the floating point at HL with the top of the FPS.
; This is useful when both OP1 and OP2 contain values that need further
; numerical computation, but those floating point ops will destory OP2 (and
; often OP3). With this helper routine, we can push OP2 to the stack, operate
; on OP1, then exchange OP1 and FPS, operate on OP2, then pop the FPS back to
; OP1.
; Input: HL=floating point value
; Destroys: all registers
; Preserves: all OPx registers
exchangeFPSHL:
    ld c, l
    ld b, h ; BC=HL
    ld hl, (FPS)
    ld de, 9
    or a ; clear CF
    sbc hl, de ; HL=(FPS) - 9
    ld e, c
    ld d, b ; DE=original HL
    ; [[fallthrough]]

; Description: Implement bcall(_Exch9) without the overhead of a bcall().
; Input: DE, HL: pointers to floating point values
; Output: 9-byte contents of DE, HL exchanged
; Destroys: all registers
exchangeFloat:
    ld b, 9
exchangeFloatLoop:
    ld a, (de)
    ld c, (hl)
    ld (hl), a
    ld a, c
    ld (de), a
    inc de
    inc hl
    djnz exchangeFloatLoop
    ret

; Description: Exchange the top 2 floating point numbers on the FPS.
; Destroys: all
; Preserves: OP1, OP2
exchangeFPSFPS:
    ld hl, (FPS)
    ld de, 9
    or a ; clear CF
    sbc hl, de ; HL=(FPS) - 9
    ld c, l
    ld b, h
    sbc hl, de ; HL=(FPS) - 18
    ld e, c
    ld d, b
    jr exchangeFloat

;-----------------------------------------------------------------------------

; Description: Move 9 bytes (size of TI-OS floating point number) from HL to
; OP1. Implements bcall(_Mov9ToOP1) without the overhead of a bcall().
; Input: HL=pointer to float
; Output: (OP1)=contains float
; Destroys: BC, DE, HL
; Preserves: A
move9ToOp1:
    ld de, OP1
    ld bc, 9
    ldir
    ret

; Description: Move 9 bytes (size of TI-OS floating point number) from HL to
; OP2. Implements bcall(_Mov9ToOP2) without the overhead of a bcall().
; Input: HL=pointer to float
; Output: (OP2)=contains float
; Destroys: BC, DE, HL
; Preserves: A
move9ToOp2:
    ld de, OP2
    ld bc, 9
    ldir
    ret

; Description: Move OP1 to OP2. This is used so frequently that it's worth
; inlining it to avoid the overhead of calling bcall(_OP1ToOP2).
; Destroys: BC, DE, HL
; Preserves: A
op1ToOp2:
    ld de, OP2
    ; [[fallthrough]]

; Description: Move 9 bytes (size of TI-OS floating point number) from OP1 to
; DE. Implements bcall(_MovFrOP1) without the overhead of a bcall().
; Input:
;   - DE=destination pointer to float
;   - OP1=float
; Output: (DE)=contains OP1
; Destroys: BC, DE, HL
; Preserves: A
move9FromOp1:
    ld hl, OP1
    ld bc, 9
    ldir
    ret

; Description: Move 9 bytes from OP2 to OP1.
; Destroys: BC, DE, HL
; Preserves: A
op2ToOp1:
    ld de, OP1
    ld hl, OP2
    ld bc, 9
    ldir
    ret

; Description: Exchange OP1 with OP2. Inlined version of bcall(_OP1ExOP2) to
; avoid the overhead of bcall().
; Output: OP1, OP2 exchanged
; Destroys: A, BC, DE, HL
op1ExOp2:
    ld hl, OP1
    ld de, OP2
    jr exchangeFloat

;-----------------------------------------------------------------------------

; Description: Calculate ln(1+x) such that it is less susceptible from
; cancellation errors when x is close to 0.
; Input: OP1
; Output: OP1: ln(1+OP1)
; Destroys: OP1-OP5
lnOnePlus:
#ifdef LOG1P_USING_LOG
    ; This uses ln(1+x) = x * log(1+x) / ((1+x)-1). I think this algorithm is
    ; faster than above, but apparently it doesn't work on certain computers
    ; (though I don't know why).
    ; See https://math.stackexchange.com/questions/175891
    bcall(_PushRealO1) ; FPS=[x]
    bcall(_Plus1) ; OP1=y=1+x
    bcall(_PushRealO1) ; FPS=[x,1+x]
    bcall(_Minus1) ; OP1=z=1+x-1
    bcall(_CkOP1FP0) ; if OP1==0: ZF=1
    jr nz, lnOnePlusNotZero
    bcall(_PopRealO1) ; FPS=[x]; OP1=1+x
    bcall(_PopRealO1) ; FPS=[]; OP1=x
    ret
lnOnePlusNotZero:
    bcall(_OP1ToOP2) ; OP2=z=1+x-1
    call exchangeFPSOP1 ; FPS=[x,1+x-1]; OP1=1+x
    bcall(_LnX) ; OP1=ln(1+x)
    bcall(_PopRealO2) ; FPS=[x]; OP2=1+x-1
    bcall(_FPDiv) ; OP1=ln(1+x)/(1+x-1)
    bcall(_PopRealO2) ; FPS=[]; OP1=x
    bcall(_FPMult) ; OP1=x*ln(1+x)/(1+x-1)
    ret
#else
    ; This uses ln(1+x) = asinh(x^2+2x)/(2x+2)). I think it is better than
    ; above for calculators with the asinh() function. For better numerical
    ; stability, use asinh((x/2)(1+1/(1+x))). Must check for (1+x)>0, because
    ; asinh() will actually return a value, but ln(1+x) will throw an
    ; exception.
    ; See https://www.hpmuseum.org/forum/thread-1012-post-8714.html#pid8714
    bcall(_PushRealO1) ; FPS=x
    bcall(_Plus1) ; OP1=1+x
    bcall(_CkOP1FP0) ; if OP1==0: ZF=1
    jr z, lnOnePlusError
    bcall(_CkOP1Pos) ; if OP1>=0: ZF=1 (SDK doc "OP1>0" is incorrect)
    jr z, lnOnePlusContinue
lnOnePlusError:
    bcall(_ErrDomain)
lnOnePlusContinue:
    bcall(_FPRecip) ; OP1=1/(1+x)
    bcall(_Plus1) ; OP1=1+1/(1+x)
    call op1ToOp2 ; OP2=1+1/(1+x)
    bcall(_PopRealO1) ; OP1=x
    bcall(_FPMult) ; OP1=x*(1+1/(1+x))
    bcall(_TimesPt5) ; OP1=(x/2)(1+1/(1+x))
    bcall(_ASinH) ; OP1=asinh((x/2)(1+1/(1+x)))
    ret
#endif

; Description: Calculate exp(x)-1 such that it is immune from cancellation
; errors when x is close to 0. Uses the identity: exp(x) - 1 = 2 sinh(x/2)
; exp(x/2).
; Input: OP1
; Output: OP1=exp(OP1) - 1
; Destroys: OP1-OP5
expMinusOne:
    bcall(_TimesPt5) ; OP1=x/2
    bcall(_PushRealO1) ; FPS=x/2
    bcall(_SinH) ; OP1=sinh(x/2)
    call exchangeFPSOP1 ; FPS=sinh(x/2); OP1=x/2
    bcall(_EToX) ; OP1=exp(x/2)
    bcall(_PopRealO2) ; OP2=sinh(x/2)
    bcall(_FPMult) ; OP1=sinh(x/2) exp(x/2)
    bcall(_Times2) ; OP1=2 sinh(x/2) exp(x/2)
    ret

;-----------------------------------------------------------------------------

; Description: Check if the sign bit of OP1 and OP2 are equal (ZF=1) or
; different (ZF=0).
; Input: OP1, OP2
; Output: ZF=0 if different, ZF=1 if same
; Destroys: all registers
; Preserves: OP1, OP2
compareSignOP1OP2:
    ld a, (OP1) ; A=sign bit of OP1
    ld b, a
    ld a, (OP2) ; A=sign bit of OP2
    xor b ; bit7=1 if different, 0 if same
    and $80 ; ZF=1 if same, 0 if different
    ret
