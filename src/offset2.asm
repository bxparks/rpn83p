;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; RpnOffset functions.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Convert the RpnOffset{} record in OP1 to relative seconds.
; Input: OP1:RpnOffset=rpnOffset
; Output: OP1:real=seconds
; Destroys: all, OP1-OP4
RpnOffsetToSeconds:
    call pushRaw9Op1 ; FPS=[rpnOffset]; HL=rpnOffset
    inc hl ; HL=offset
    ex de, hl ; DE=offset
    ld hl, OP1
    call offsetToSeconds ; DE=offset+2; HL=OP1=seconds
    call dropRaw9 ; FPS=[]
    jp convertI40ToOP1 ; OP1=float(OP1)

; Description: Convert the RpnOffset{} record in OP1 to relative hours.
; Input: OP1:RpnOffset=rpnOffset
; Output: OP1:real=hours
; Destroys: all, OP1-OP4
RpnOffsetToHours:
    call RpnOffsetToSeconds
    call op2Set3600PageTwo ; OP2=3600
    bcall(_FPDiv) ; OP1=OP1/OP2
    ret

; Description: Convert the hours (in multiples of 0.25) in OP1 to RpnOffset.
; Input: OP1:real=hours
; Output: OP1:RpnOffset=rpnOffset
; Destroys: all, OP1-OP4
HoursToRpnOffset:
    call reserveRaw9 ; FPS=[rpnOffset]; HL=rpnOffset
    ld a, rpnObjectTypeOffset
    ld (hl), a
    inc hl
    call offsetHourToOffset ; HL=RpnOffset(OP1)
    call popRaw9Op1 ; FPS=[]; OP1=rpnOffset
    ret

;-----------------------------------------------------------------------------
; Lower-level routines.
;-----------------------------------------------------------------------------

; Description: Return ZF=1 if Offset{} is zero or positive.
; Input: HL:(Offset*)=pointerToOffset
; Output: ZF=1 if zero or positive
; Destroys: A
; Preserves: HL
isOffsetPos:
    ld a, (hl)
    inc hl
    or (hl)
    dec hl
    bit 7, a ; ZF=1 if both sign bits are 0
    ret

; Descripton: Return ZF=1 if offset is exactly 00:00.
; Input: HL:(Offset*)=offset
; Output: ZF=1 if offset==00:00
; Destroys: A
; Preserves: HL
isOffsetZero:
    ld a, (hl)
    inc hl
    or (hl)
    dec hl
    ret

; Description: Return ZF=1 if (hh,mm) in BC is zero or positive.
; Input: BC=(hh,mm)
; Output: ZF=1 if zero or positive
; Destroys: A
isHmComponentsPos:
    ld a, b
    or c
    bit 7, a
    ret

;-----------------------------------------------------------------------------

; Description: Change sign of Offset{ohh,omm}.
; Input: HL:(Offset*)=pointerToOffset
; Output: (*HL):Offset=Offset{-ohh,-omm}.
; Destroys: A
; Preserves: HL
chsOffset:
    ld a, (hl)
    neg
    ld (hl), a
    inc hl
    ld a, (hl)
    neg
    ld (hl), a
    dec hl
    ret

; Description: Negate the (hh,mm) Offset components in BC.
; Input: B, C
; Output: B=-B, C=-C
; Destroys: A
chsHmComponents:
    ld a, b
    neg
    ld b, a
    ld a, c
    neg
    ld c, a
    ret

;-----------------------------------------------------------------------------

; Description: Convert (hh,mm) to i40 seconds.
; Input:
;   - DE:(Offset*)=offset
;   - HL:(i40*)=seconds
; Output:
;   - DE=DE+2
;   - (*HL):i40 updated
; Destroys: A
; Preserves: BC, HL
offsetToSeconds:
    push bc ; stack=[BC]
    ex de, hl ; DE=seconds; HL=offset
    ld b, (hl)
    inc hl
    ld c, (hl)
    inc hl
    ex de, hl ; DE=offset; HL=seconds
    call isHmComponentsPos ; ZF=1 if zero or positive
    jr z, offsetToSecondsPos
offsetToSecondsNeg:
    call chsHmComponents
    call hmComponentsToSeconds
    call negU40
    pop bc ; stack=[]; BC=restored
    ret
offsetToSecondsPos:
    call hmComponentsToSeconds
    pop bc ; stack=[]; BC=restored
    ret

; Description: Convert positive (hh,mm) in BC to seconds.
; Input: BC=(hh,mm)
; Output: HL:(u40*)=offsetSeconds
; Preserves: DE, HL
hmComponentsToSeconds:
    ; set hour
    ld a, b
    call setU40ToA ; u40(*HL)=A
    ; multiply by 60
    ld a, 60
    call multU40ByA ; HL=result=HL*60
    ; add minute
    ld a, c
    call addU40ByA ; HL=HL+A
    ; multiply by 60
    ld a, 60
    jp multU40ByA ; HL=HL*60

;-----------------------------------------------------------------------------

; Description: Convert floating hours (e.g. 8.25, 8.5, 8.75) into an Offset
; record {hh,mm}. The offsetHour is restricted in the following way:
;   - must be a multiple of 15 minutes. (If the floating hours is multiplied by
;   4, the result should be an integer.)
;   - must be within the interval [-23:45,+23:45]
;Input:
;   - OP1:Real=offsetHour
;   - HL:(Offset*)=offset
; Output:
;   - HL:(Offset*)=offset filled
; Destroys: A, BC, DE
; Preserves: HL
; Throws: Err:Domain if greater than or equal to +/-24:00, or not a multiple of
; 15 minutes.
offsetHourToOffset:
    ld a, (OP1) ; bit7=sign bit
    rla ; CF=1 if negative
    jr nc, offsetHourToOffsetPos
offsetHourToOffsetNeg:
    ; If negative, invert the sign of input, convert to Offset, then invert the
    ; sign of the ouput.
    bcall(_InvOP1S) ; OP1=-OP1
    call offsetHourToOffsetPos ; Preserves HL=offset
    ; invert the signs of offset{hh,mm}
    ld a, (hl)
    neg
    ld (hl), a
    inc hl
    ld a, (hl)
    neg
    ld (hl), a
    dec hl ; preserve HL
    ret

; Description: Convert offsetHour (offset represented as a real number, in
; multiples of 0.25, and assumed to be positive) to Offset{} object.
; Input:
;   - OP1:real=offsetHour
;   - HL:(Offset*)=offset
; Output:
;   - HL=offset updated
; Preserves: HL
; Throws: Err:Domain if offsetHour is outside of [-23.75,23.75] or if
; offsetHour is not a multiple of 0.25 (i.e. 15 minutes)
offsetHourToOffsetPos:
    ; reserve space for Offset object
    push hl ; stack=[offset]
    call offsetHourToOffsetQuarter ; BC=offsetHour
    call offsetQuarterToHourMinute ; DE=(hour,minute)
    ; Fill offset
    pop hl ; stack=[]; HL=offset
    ld (hl), d ; offset.hh=hour
    inc hl
    ld (hl), e ; offset.mm=minute
    dec hl ; HL=offset
    ret

; Description: Convert offsetHours to offsetQuarters (multiples of 15 minutes).
; The offsetHours must be within the range of [-23:45,+23:45] which means
; that the offsetQuarters will be within [-95,+95].
; Input:
;   - OP1:real=offsetHour
; Output:
;   - BC:i16=offsetQuarter
; Destroys: all
; Throws: Err:Domain if offsetHour is outside of [-23.75,23.75] or if
; offsetHour is not a multiple of 0.25 (i.e. 15 minutes)
offsetHourToOffsetQuarter:
    ; extract whole hh
    bcall(_RndGuard) ; eliminating invisible rounding errors
    ; check within +/-24:00
    call op2Set24PageTwo ; OP2=24
    bcall(_CpOP1OP2) ; CF=1 if OP1<OP2
    jr nc, offsetHourToOffsetQuarterErr
    ; check offsetHour is a multiple of 15 minutes
    bcall(_Times2) ; OP1*=2
    bcall(_Times2) ; OP1=offsetQuarter=offsetHour*4
    bcall(_CkPosInt) ; ZF=1 if OP1 is an integer >= 0
    jr nz, offsetHourToOffsetQuarterErr ; err if not a multiple of 15
    ; Convert offsetQuarter into (hour,minute). offsetQuarter is < 96 (24*4),
    ; so only a single byte is needed.
    call convertOP1ToI40 ; OP1:u40=offsetQuarter
    ld bc, (OP1) ; BC=offsetQuarter
    ret
offsetHourToOffsetQuarterErr:
    bcall(_ErrDomain)

; Description: Convert offsetQuarter (multiple of 15 minutes) into
; (hour,minute).
; Input:
;   - BC:u16=offsetQuarter
; Output:
;   - D:u8=hour
;   - E:u8=minute
; Destroys: A, BC
; Preserves: HL
offsetQuarterToHourMinute:
    ld a, c
    and $03 ; A=remainderQuarter=offsetQuarter%4
    ld e, a ; E=remainderQuarter
    add a, a
    add a, a
    add a, a
    add a, a ; A=remainderQuarter*16
    sub e ; A=minutes=remainderQuarter*(16-1)
    ld e, a ; E=minutes
    ; divide BC by 4
    srl b
    rr c ; BC/=2
    srl b
    rr c ; BC/=2
    ld d, c ; D=hour=offsetQuarter/4
    ret
