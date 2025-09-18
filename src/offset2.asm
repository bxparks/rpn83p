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
    skipRpnObjectTypeHL ; HL=offset
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
    call setHLRpnObjectTypePageTwo ; HL+=sizeof(type)
    call offsetHourToOffset ; (HL)=Offset(OP1)
    call popRaw9Op1 ; FPS=[]; OP1=rpnOffset
    ret

; Description: Set OP1 to UTC timezone offset.
; Input: none
; Output: OP1:RpnOffset=utcOffset
; Destroys: A, HL
RpnOffsetUtc:
    ld hl, OP1
    ld a, rpnObjectTypeOffset
    call setHLRpnObjectTypePageTwo
    xor a
    ld (hl), a
    inc hl
    ld (hl), a
    ret

;-----------------------------------------------------------------------------
; Arithmetic
;-----------------------------------------------------------------------------

; Description: Add RpnOffset by real(hours).
; Input:
;   - OP1:Union[RpnOffset,RpnReal]=rpnOffset or hours
;   - OP3:Union[RpnOffset,RpnReal]=rpnOffset or hours
; Output:
;   - OP1:RpnOffset=RpnOffset+hours
; Destroys: all, OP1-OP4
; Throws: Err:Domain if hours is invalid (|hours|>24h or not multiple of 15 min)
AddRpnOffsetByHours:
    call checkOp1OffsetPageTwo ; ZF=1 if CP1 is an RpnOffset
    jr z, addRpnOffsetByHoursAdd
    call cp1ExCp3PageTwo ; CP1=rpnOffset; CP3=hours
addRpnOffsetByHoursAdd:
    ; if here: CP1=rpnOffset, CP3=hours
    ; Push CP1:RpnOffset to FPS
    call PushRpnObject1 ; FPS=[rpnOffset]; HL=rpnOffset
    push hl ; stack=[rpnOffset]
    ; convert real(hours) to offset
    call op3ToOp1PageTwo ; OP1:real=hours
    ld hl, OP3
    call offsetHourToOffset ; OP3:Offset=offsethours
    ; add offset+offsethours
    ex de, hl ; DE=OP3=offsethours
    pop hl ; stack=[]; HL=rpnOffset
    skipRpnObjectTypeHL ; HL=offset
    call addOffsetByOffset ; HL=newOffset
    ; clean up
    call PopRpnObject1 ; FPS=[]; OP1=newRpnOffset
    ret

; Description: Add Offset + Offset.
; Input:
;   - HL:Offset=offset1
;   - DE:Offset=offset2
; Output:
;   - (*HL)=(*HL)+(*DE)
; Destroys: A
; Preserves: DE, HL
addOffsetByOffset:
    push de
    push hl ; stack=[offset2, offset1]
    ;
    push de ; stack=[offset2, offset1, offset2]
    call offsetToOffsetQuarter ; BC=offsetQuarter1
    ld l, c
    ld h, b
    ex (sp), hl ; stack=[offset2, offset1, offsetQuarter1]; HL=offset2
    call offsetToOffsetQuarter ; BC=offsetQuarter2
    ;
    pop hl ; stack=[offset2, offset1]; HL=offsetQuarter1
    add hl, bc ; HL=offsetQuarter1+offsetQuarter2
    ld c, l
    ld b, h ; BC=resultQuarter
    ;
    pop hl ; stack=[offset2]; HL=offset1
    call offsetQuarterToOffset ; HL=updated
    ; restore stack
    pop de ; stack=[]; DE=offset2
    ret

;-----------------------------------------------------------------------------

; Description: Add (RpnOffset plus duration) or (duration plus RpnOffset).
; Input:
;   - OP1:Union[RpnOffset,RpnDuration]=rpnOffset or rpnDuration
;   - OP3:Union[RpnOffset,RpnDuration]=rpnOffset or rpnDuration
; Output:
;   - OP1:RpnOffset=rpnOffset+rpnDuration
; Destroys: all, OP1-OP4
AddRpnOffsetByDuration:
    call checkOp1OffsetPageTwo ; ZF=1 if CP1 is an RpnDate
    jr z, addRpnOffsetByDurationAdd
    call cp1ExCp3PageTwo ; CP1=rpnDate; CP3=rpnDuration
addRpnOffsetByDurationAdd:
    ; if here: CP1=rpnOffset, CP3=rpnDuration
    ld hl, OP3+rpnObjectTypeSizeOf ; HE=duration
    call validateDurationToOffset ; throws Err:Domain if Duration is invalid
    ex de, hl ; DE=duration
    inc de
    inc de ; DE=offset=duration+2 (skip over the 'days' field)
    ld hl, OP1+rpnObjectTypeSizeOf ; HL=resultOffset
    call addOffsetByOffset ; (*HL)+=(*DE)
    ret

; Description: Check if a Duration can be converted to an Offset object.
; Input:
;   - HL:(Duration*)=duration
; Output:
;   - none
; Preserves: HL
; Throws: Err:Domain if Duration has a non-zero 'day' or 'seconds' component.
validateDurationToOffset:
    push hl
    ld a, (hl)
    inc hl
    or a, (hl) ; ZF=1 if days==0
    jr nz, durationToOffsetErr
    inc hl
    inc hl
    inc hl
    ld a, (hl) ; A=seconds
    or a
    jr nz, durationToOffsetErr
    pop hl
    ret
durationToOffsetErr:
    bcall(_ErrDomain)

;-----------------------------------------------------------------------------

SubRpnOffsetByObject:
    call getOp3RpnObjectTypePageTwo ; A=type; HL=OP3
    cp rpnObjectTypeReal ; ZF=1 if Real
    jr z, subRpnOffsetByHours
    cp rpnObjectTypeOffset ; ZF=1 if Offset
    jr z, subRpnOffsetByRpnOffset
    cp rpnObjectTypeDuration ; ZF=1 if Duration
    jr z, subRpnOffsetByRpnDuration
    bcall(_ErrInvalid) ; should never happen
subRpnOffsetByHours:
    ; invert the sign of OP3=hours, then call addRpnOffsetByHoursAdd()
    call cp1ExCp3PageTwo
    bcall(_InvOP1S) ; OP1=-OP1
    call cp1ExCp3PageTwo
    jr addRpnOffsetByHoursAdd
subRpnOffsetByRpnOffset:
    ; convert OP3 to seconds, on FPS stack
    ; TODO: This would be more efficient using offsetToOffsetQuarter() to
    ; convert to u16(quarters) instead of u40(seconds). But the shape of this
    ; code was already available in SubRpnDateByObject(), and it was easier to
    ; just copy and modify it.
    call reserveRaw9 ; make space on FPS=[X.seconds]; HL=X.seconds
    push hl ; stack=[X.seconds]
    ld de, OP3+rpnObjectTypeSizeOf ; DE=Offset{}
    call offsetToSeconds ; HL=FPS.X.seconds updated
    ; convert OP1 to seconds, on FPS stack
    call reserveRaw9 ; make space, FPS=[X.seconds,Y.seconds]; HL=Y.seconds
    push hl ; stack=[X.seconds,Y.seconds]
    ld de, OP1+rpnObjectTypeSizeOf ; DE=Offset{}
    call offsetToSeconds ; HL=FPS.Y.seconds updated
    ; subtract Y.seconds-X.seconds
    pop hl ; stack=[X.seconds]; HL=Y.seconds
    pop de ; stack=[]; DE=X.seconds
    call subU40U40 ; HL=Y.seconds-X.seconds
    ; pop result into OP1
    call popRaw9Op1 ; FPS=[X.seconds]; OP1=Y.seconds-X.seconds
    call convertI40ToOP1 ; OP1=float(i40)
    ; convert seconds to hours
    call op2Set3600PageTwo
    bcall(_FPDiv) ; OP1=OP1/3600
    jp dropRaw9 ; FPS=[]
subRpnOffsetByRpnDuration:
    ; invert the sign of duration in OP3
    ld hl, OP3+rpnObjectTypeSizeOf
    call chsDuration
    jr addRpnOffsetByDurationAdd

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
isHourMinuteBCPos:
    ld a, b
    or c
    bit 7, a
    ret

; Description: Return ZF=1 if (hh,mm) in DE is zero or positive.
; Input: DE=(hh,mm)
; Output: ZF=1 if zero or positive
; Destroys: A
isHourMinuteDEPos:
    ld a, d
    or e
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
chsHourMinuteBC:
    ld a, b
    neg
    ld b, a
    ld a, c
    neg
    ld c, a
    ret

; Description: Negate the (hh,mm) Offset components in DE.
; Input: D, E
; Output: D=-D, E=-E
; Destroys: A
chsHourMinuteDE:
    ld a, d
    neg
    ld d, a
    ld a, e
    neg
    ld e, a
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
    call isHourMinuteBCPos ; ZF=1 if zero or positive
    jr z, offsetToSecondsPos
offsetToSecondsNeg:
    call chsHourMinuteBC
    call hourMinuteToSeconds ; (*HL) updated
    call negU40
    pop bc ; stack=[]; BC=restored
    ret
offsetToSecondsPos:
    call hourMinuteToSeconds ; (*HL) updated
    pop bc ; stack=[]; BC=restored
    ret

; Description: Convert positive (hh,mm) in BC to seconds.
; Input: BC=(hh,mm)
; Output: HL:(u40*)=offsetSeconds
; Preserves: DE, HL
hourMinuteToSeconds:
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
    call offsetHourToOffsetPos ; (*HL)=offset
    call chsOffset ; invert the signs of offset{hh,mm}
    ret

; Description: Convert offsetHour (offset represented as a real number, in
; multiples of 0.25, and assumed to be positive) to Offset{} object.
; Input:
;   - OP1:real=offsetHour
;   - HL:(Offset*)=offset
; Output:
;   - HL=offset updated
; Destroys: A, BC, DE
; Preserves: HL
; Throws: Err:Domain if offsetHour is outside of [-23.75,23.75] or if
; offsetHour is not a multiple of 0.25 (i.e. 15 minutes)
offsetHourToOffsetPos:
    ; reserve space for Offset object
    push hl ; stack=[offset]
    call offsetHourToOffsetQuarterPos ; BC=offsetHour
    call offsetQuarterToHourMinutePos ; DE=(hour,minute)
    ; Fill offset
    pop hl ; stack=[]; HL=offset
    ld (hl), d ; offset.hh=hour
    inc hl
    ld (hl), e ; offset.mm=minute
    dec hl ; HL=offset
    ret

; Description: Convert positive offsetHours to positive offsetQuarters
; (multiples of 15 minutes). The offsetHours must be within the range of
; [-23:45,+23:45] which means that the offsetQuarters will be within [-95,+95].
; Input:
;   - OP1:real=offsetHour
; Output:
;   - BC:u16=offsetQuarter
; Destroys: all
; Throws: Err:Domain if offsetHour is outside of [-23.75,23.75] or if
; offsetHour is not a multiple of 0.25 (i.e. 15 minutes)
offsetHourToOffsetQuarterPos:
    ; extract whole hh
    bcall(_RndGuard) ; eliminating invisible rounding errors
    ; check < 24:00
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
    call convertOP1ToU40 ; OP1:u40=offsetQuarter
    ld bc, (OP1) ; BC=offsetQuarter
    ret
offsetHourToOffsetQuarterErr:
    bcall(_ErrDomain)

;-----------------------------------------------------------------------------

; Description: Convert Offset object to offsetQuarter:i16.
; Input:
;   - HL:(Offset*)=offset
; Output:
;   - BC:i16=offsetQuarter
; Destroys: A, DE
; Preserves: HL
offsetToOffsetQuarter:
    ld d, (hl)
    inc hl
    ld e, (hl)
    dec hl
    call isHourMinuteDEPos ; ZF=1 if zero or positive
    jr z, hourMinuteToOffsetQuarterPos
    ; negative
    call chsHourMinuteDE
    call hourMinuteToOffsetQuarterPos
    call negBCPageTwo
    ret

; Description: Convert offsetQuarter:i16 to result offset.
; Input:
;   - BC:i16=offsetQuarter
;   - HL:(Offset*)=result
; Output:
;   - (*HL) updated
; Destroys: A, BC, DE
; Preserves: HL
offsetQuarterToOffset:
    bit 7, b ; ZF=1 if zero or positive
    jr z, offsetQuarterToOffsetPos
    ; negative
    call negBCPageTwo
    call offsetQuarterToHourMinutePos ; DE=(hour,minute)
    call chsHourMinuteDE ; DE=-(hour,minute)
    jr offsetQuarterToOffsetSave
offsetQuarterToOffsetPos:
    call offsetQuarterToHourMinutePos
offsetQuarterToOffsetSave:
    ld (hl), d
    inc hl
    ld (hl), e
    dec hl
    ret

;-----------------------------------------------------------------------------

; Description: Convert positive offsetQuarter (multiple of 15 minutes) into
; positive (hour,minute).
; Input:
;   - BC:u16=offsetQuarter
; Output:
;   - D:u8=hour
;   - E:u8=minute
; Destroys: A, BC
; Preserves: HL
; Throws: Err:Domain if invalid
offsetQuarterToHourMinutePos:
    call validateOffsetQuarter
    ;
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

; Description: Check that the offsetQuarter in BC is within [-23:45,23:45], in
; othe words |BC| < 96.
; Input:
;   - BC:u16=offsetQuarter
; Output:
;   - none
; Destroys: A
; Preserves: BC, DE, HL
; Throws: Err:Domain if invalid
validateOffsetQuarter:
    ld a, b
    or a
    jr nz, validateOffsetQuarterErr
    ld a, c
    cp 96
    jr nc, validateOffsetQuarterErr
    ret
validateOffsetQuarterErr:
    bcall(_ErrDomain)

; Description: Convert positive (hour, minute) to positive offsetQuarter
; (integer in unit of 15 minutes).
; Input:
;   - D:u8=hour
;   - E:u8=minute
; Output:
;   - BC:u16=offsetQuarter=4*hour+minute/15
; Destroys: A, BC
; Preserves: HL, DE
; Throws: Err:Domain if invalid
hourMinuteToOffsetQuarterPos:
    call validateOffsetHourMinute
    ;
    ld b, 0
    ld c, d
    sla c
    sla c ; C=hour*4
    ;
    ld a, e
    sub 15
    ret c
    inc c
    sub 15
    ret c
    inc c
    sub 15
    ret c
    inc c
    ret

; Description: Check that the offset (hour, minute) in DE is within
; [-23:45,23:45].
; Input:
;   - D:u8=hour
;   - E:u8=minute
; Output:
;    - none
; Destroys: A
; Preserves: BC, DE, HL
; Throws: Err:Domain if invalid
validateOffsetHourMinute:
    ld a, d
    cp 24
    jr nc, validateOffsetHourMinuteErr
    ld a, e
    cp 0
    ret z
    cp 15
    ret z
    cp 30
    ret z
    cp 45
    ret z
    ; [[fallthrough]]
validateOffsetHourMinuteErr:
    bcall(_ErrDomain)

;-----------------------------------------------------------------------------
; Extractors
;-----------------------------------------------------------------------------

; Description: Extract the hour component.
; Input: OP1:RpnOffset=offset
; Output: OP1:Real=offset.hour()
RpnOffsetExtractHour:
    ld a, (OP1+rpnObjectTypeSizeOf+0) ; A=hour
    ld hl, OP1
    call setI40ToA ; OP1:I40=hour
    jp convertI40ToOP1 ; OP1:Real=hour

;-----------------------------------------------------------------------------

; Description: Extract the minute component.
; Input: OP1:RpnOffset=offset
; Output: OP1:Real=offset.minute()
RpnOffsetExtractMinute:
    ld a, (OP1+rpnObjectTypeSizeOf+1) ; A=minute
    ld hl, OP1
    call setI40ToA ; OP1:I40=minute
    jp convertI40ToOP1 ; OP1:Real=minute
