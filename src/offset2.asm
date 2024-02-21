;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; RpnOffset functions.
;-----------------------------------------------------------------------------

; Description: Convert the RpnOffset{} record in OP1 to relative seconds.
; Input: OP1:RpnOffet
; Output: OP1:real
; Destroys: all, OP1-OP4
RpnOffsetToSeconds:
    call pushRaw9Op1 ; FPS=[rpnOffset]; HL=rpnOffset
    inc hl ; HL=offset
    ex de, hl ; DE=offset
    ld hl, OP1
    call offsetToSeconds ; DE=offset+2; HL=OP1=seconds
    call dropRaw9 ; FPS=[]
    jp ConvertI40ToOP1 ; OP1=float(OP1)

;-----------------------------------------------------------------------------

; Description: Return ZF=1 if Offset{} is zero or positive.
; Input: HL=(Offset*)=pointerToOffset
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

; Convert offsetHour (offset represented as a real number, in multiples of
; 0.25) to Offset{} object.
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
    ; extract whole hh
    bcall(_RndGuard) ; eliminating invisible rounding errors
    ; check within +/-24:00
    call op2Set24PageTwo ; OP2=24
    bcall(_CpOP1OP2) ; CF=1 if OP1<OP2
    jr nc, offsetHourToOffsetErr
    ; check offsetHour is a multiple of 15 minutes
    bcall(_Times2) ; OP1*=2
    bcall(_Times2) ; OP1=offsetQuarter=offsetHour*4
    bcall(_CkPosInt) ; ZF=1 if OP1 is an integer >= 0
    jr nz, offsetHourToOffsetErr ; err if not a multiple of 15
    ; Convert offsetQuarter into (hour,minute). offsetQuarter is < 96 (24*4),
    ; so only a single byte is needed.
    call ConvertOP1ToI40 ; OP1:u40=offsetQuarter, [
    ld bc, (OP1) ; BC=offsetQuarter
    call offsetQuarterToHourMinute ; DE=(hour,minute)
    ; Fill offset
    pop hl ; stack=[]; HL=offset
    ld (hl), d ; offset.hh=hour
    inc hl
    ld (hl), e ; offset.mm=minute
    dec hl ; HL=offset
    ret
offsetHourToOffsetErr:
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

;-----------------------------------------------------------------------------

; Description: Convert the utcEpochSeconds to an epochSeconds relative to the
; given Offset, so that when that is converted to Date or DateTime, the result
; is accurate for the given Offset.
; Input:
;   - DE:(Offset*)=offset
;   - HL:(i40*)=utcEpochSeconds
; Output:
;   - DE=offset+2
;   - HL=localEpochSeconds
; Preserves: BC, DE
utcEpochSecondsToLocalEpochSeconds:
    push hl ; stack=[utcEpochSeconds]
    call reserveRaw9 ; FPS=[offset, offsetSeconds]; HL=offsetSeconds
    call offsetToSeconds ; HL=offsetSeconds updated
    ex de, hl ; DE=offsetSeconds; HL=offset+2
    ex (sp), hl ; stack=[offset+2]; HL=utcEpochSeconds
    call addU40U40 ; HL=localEpochSeconds=utcEpochSeconds+offseSeconds
    pop de ; stack=[]; DE=offset+2
    jp dropRaw9

; Description: Convert the localEpochSeconds relative to the given Offset to
; the utcEpochSeconds.
; Input:
;   - DE:(Offset*)=offset
;   - HL:(i40*)=localEpochSeconds
; Output:
;   - DE=offset+2
;   - HL=utcEpochSeconds
; Preserves: BC, DE
localEpochSecondsToUtcEpochSeconds:
    push hl ; stack=[localEpochSeconds]
    call reserveRaw9 ; FPS=[offsetSeconds]; HL=offsetSeconds
    call offsetToSeconds ; HL=offsetSeconds updated
    ex de, hl ; DE=offsetSeconds; HL=offset+2
    ex (sp), hl ; stack=[offset+2]; HL=localEpochSeconds
    call subU40U40 ; HL=utcEpochSeconds=localEpochSeconds-offsetSeconds
    pop de ; stack=[]; DE=offset+2
    jp dropRaw9

;-----------------------------------------------------------------------------
; RpnOffsetDateTime functions.
;-----------------------------------------------------------------------------

; Description: Convert the RpnOffsetDateTime{} record in OP1 to relative
; epochSeconds.
; Input: OP1/OP2:RpnOffsetDateTime=input
; Output: OP1:real
; Destroys: all, OP1-OP6
RpnOffsetDateTimeToEpochSeconds:
    ; push OP1/OP2 onto the FPS, which has the side-effect of removing the
    ; 2-byte gap between OP1 and OP2
    call PushRpnObject1 ; FPS=[rpnOffsetDateTime]; HL=rpnOffsetDateTime
    ex de, hl ; DE=rpnOffsetDateTime
    call reserveRaw9 ; FPS=[rpnOffsetDateTime,reserved]
    ; convert DateTime to dateTimeSeconds
    inc de ; DE=offsetDateTime, skip type byte
    call offsetDateTimeToEpochSeconds ; HL=epochSeconds
    ; copy back to OP1
    call popRaw9Op1 ; FPS=[rpnOffsetDateTime]; HL=OP1=epochSeconds
    call dropRpnObject ; FPS=[]
    jp ConvertI40ToOP1 ; OP1=float(OP1)

; Description: Convert OffsetDateTime{} to relative epochSeconds.
; Input:
;   - DE:(const OffsetDateTime*)=dateTime, must not be OPx
;   - HL:(i40*)=resultSeconds, must not be OPx
; Output:
;   - DE=DE+sizeof(OffsetDateTime)
;   - (*HL):i40=resultSeconds
; Destroys: OP4-OP6
; Preserves: HL
offsetDateTimeToEpochSeconds:
    ; convert DateTime to relative epochSeconds
    call dateTimeToEpochSeconds ; HL=dateTimeSeconds; DE+=sizeof(DateTime)
    ; convert localEpochSeconds to utcEpochSeconds
    call localEpochSecondsToUtcEpochSeconds ; HL=utcEpochSeconds; DE+=2
    ret

;-----------------------------------------------------------------------------

; Description: Convert the relative epochSeconds to an RpnOffsetDateTime{}
; record.
; Input: OP1:Real=epochSeconds
; Output: OP1:RpnOffsetDateTime
; Destroys: all, OP1-OP6
EpochSecondsToRpnOffsetDateTime:
    ; get relative epochSeconds
    call ConvertOP1ToI40 ; OP1=i40(epochSeconds)
epochSecondsToRpnOffsetDateTimeAlt:
    ; reserve RpnObject on FPS
    call reserveRpnObject ; FPS=[rpnOffsetDateTime]; HL=rpnOffsetDateTime
    ex de, hl ; DE=rpnOffsetDateTime
    call pushRaw9Op1 ; FPS=[rpnOffsetDateTime,epochSeconds]; HL=epochSeconds
    ; convert to RpnOffsetDateTime
    ex de, hl ; DE=epochSeconds; HL=rpnOffsetDateTime
    ld a, rpnObjectTypeOffsetDateTime
    ld (hl), a
    inc hl ; HL=rpnOffsetDateTime+1=offsetDateTime
    ; select the currently selected TZ offset
    ld bc, timeZone
    call epochSecondsToOffsetDateTime ; HL=HL+sizeof(OffsetDateTime)
    ; clean up FPS
    call dropRaw9
    jp PopRpnObject1 ; OP1=RpnOffsetDateTime

; Description: Convert the relative epochSeconds to an OffsetDateTime{} with
; the given Offset{}.
; Input:
;   - BC:(const Offset*)=offset
;   - DE:(const i40*)=epochSeconds, must not be an OPx
;   - HL:(OffsetDateTime*)=offsetDateTime, must not be an OPx
; Output:
;   - BC=offset+2
;   - (*HL)=offsetDateTime updated
;   - HL=HL+sizeof(OffsetDateTime)
; Destroys: all, OP1-OP6
; Preserves: DE
epochSecondsToOffsetDateTime:
    push de ; stack=[epochSeconds]
    push bc ; stack=[epochSeconds,offset]
    push hl ; stack=[epochSeconds,offset,offsetDateTime]
    ; convert utcEpochSeconds to localEpochSeconds
    ex de, hl ; HL=utcEpochSeconds
    ld e, c
    ld d, b ; DE=offset
    call utcEpochSecondsToLocalEpochSeconds ; HL=localEpochSeconds; DE+=2
    ; convert localEpochSeconds to DateTime
    ex de, hl ; DE=localEpochSeconds
    pop hl ; stack=[epochSeconds,offset]; HL=offsetDateTime
    call epochSecondsToDateTime ; HL=offsetDateTime+sizeof(DateTime)
    ; copy the given offset into OffsetDateTime.offset
    pop bc ; stack=[epochSeconds]; BC=offset
    ld a, (bc)
    inc bc
    ld (hl), a
    inc hl
    ld a, (bc)
    inc bc
    ld (hl), a
    inc hl ; HL=HL+sizeof(OffsetDateTime)
    pop de ; stack=[]; DE=epochSeconds
    ret

;-----------------------------------------------------------------------------

; Description: Add (RpnOffsetDateTime plus seconds) or (seconds plus
; RpnDateTime).
; Input:
;   - OP1:Union[RpnOffsetDateTime,RpnReal]=rpnOffsetDateTime or seconds
;   - OP3:Union[RpnOffsetDateTime,RpnReal]=rpnOffsetDateTime or seconds
; Output:
;   - OP1:RpnOffsetDateTime=RpnOffsetDateTime+seconds
; Destroys: all, OP1, OP2, OP3-OP6
AddRpnOffsetDateTimeBySeconds:
    call checkOp1OffsetDateTimePageTwo ; ZF=1 if CP1 is an RpnOffsetDateTime
    jr z, addRpnOffsetDateTimeBySecondsAdd
    call cp1ExCp3PageTwo ; CP1=rpnOffsetDateTime; CP3=seconds
addRpnOffsetDateTimeBySecondsAdd:
    ; CP1=rpnOffsetDateTime, CP3=seconds
    ; Push rpnOffsetDateTime to FPS, which also removes the 2-byte gap between
    ; OP1/OP2.
    call PushRpnObject1 ; FPS=[rpnOffsetDateTime]
    push hl ; stack=[rpnOffsetDateTime]
    ; convert OP3 to i40, then push to FPS
    call op3ToOp1PageTwo ; OP1:real=seconds
    call ConvertOP1ToI40 ; OP1:(i40*)=seconds
    call pushRaw9Op1 ; FPS=[rpnOffsetDateTime,seconds]; HL=seconds
    ex (sp), hl ; stack=[seconds]; HL=rpnOffsetDateTime
    ; convert rpnOffsetDateTime to i40 seconds
    ex de, hl ; DE=rpnOffsetDateTime
    inc de ; skip type byte
    ld hl, OP1
    call offsetDateTimeToEpochSeconds ; HL=OP1:(i40*)=offsetDateTimeSeconds
    ; save (Offset*) pointer to original offset
    ld c, e
    ld b, d ; BC=offsetDateTime+sizeof(OffsetDateTime)
    dec bc
    dec bc ; BC:(Offset*)=offset
    ; add seconds + dateSeconds
    ex de, hl ; DE=offsetDateTimeSeconds
    pop hl ; stack=[]; HL=FPS.seconds
    call addU40U40 ; HL=FPS.resultSeconds=offsetDateTimeSeconds+seconds
    ; convert resultSeconds to RpnOffsetDateTime (use FPS to avoid the 2-byte
    ; gap)
    ex de, hl ; DE=resultSeconds
    ; after the call below:
    ;   - FPS=[rpnOffsetDateTime,resultSeconds,resultOffsetDateTime]
    ;   - HL=resultOffsetDatetime
    call reserveRpnObject
    ld a, rpnObjectTypeOffsetDateTime
    ld (hl), a
    inc hl ; HL:(OffsetDateTime*)=newOffsetDateTime
    call epochSecondsToOffsetDateTime ; HL=resultOffsetDateTime+sizeof(ODT)
    ; clean up stack and FPS
    call PopRpnObject1 ; FPS=[rpnOffsetDateTime,resultSeconds]; OP1=result
    call dropRaw9 ; FPS=[rpnOffsetDateTime]
    jp dropRpnObject ; FPS=[]

;-----------------------------------------------------------------------------

; Description: Subtract RpnOffsetDateTime minus RpnOffsetDateTime or seconds.
; Input:
;   - OP1:RpnOffsetDateTime=Y
;   - OP3:RpnOffsetDateTime or seconds=X
; Output:
;   - OP1:(RpnOffsetDateTime-seconds) or (RpnOffsetDateTime-RpnOffsetDateTime).
; Destroys: OP1, OP2, OP3-OP6
SubRpnOffsetDateTimeByRpnOffsetDateTimeOrSeconds:
    call checkOp3OffsetDateTimePageTwo ; ZF=1 if type(OP3)==OffsetDateTime
    jr z, subRpnOffsetDateTimeByRpnOffsetDateTime
subRpnOffsetDateTimeBySeconds:
    ; invert the sign of OP3, then call addRpnOffsetDateTimeBySecondsAdd()
    call cp1ExCp3PageTwo
    bcall(_InvOP1S) ; OP1=-OP1
    call cp1ExCp3PageTwo
    jr addRpnOffsetDateTimeBySecondsAdd
subRpnOffsetDateTimeByRpnOffsetDateTime:
    ; save copies of X, Y OffsetDateTime to FPS
    call PushRpnObject1 ; FPS=[Yodt]; HL=Yodt
    push hl ; stack=[Yodt]
    call PushRpnObject3 ; FPS=[Yodt,Xodt]; HL=Xodt
    ; calculate X epochSeconds
    ex de, hl ; DE=Xodt
    inc de ; skip type byte
    call reserveRaw9 ; FPS=[Yodt,Xodt,Xeps]; HL=Xeps
    call offsetDateTimeToEpochSeconds ; HL=Xeps filled
    ; calculate Y epochSeconds
    ex (sp), hl ; stack=[Xeps]; HL=Yodt
    ex de, hl ; DE=Yodt
    inc de ; skip type byte
    call reserveRaw9 ; FPS=[Yodt,Xodt,Xeps,Yeps]; HL=Yeps
    call offsetDateTimeToEpochSeconds ; HL=Yeps filled
    ; subtract Yeps-Xeps
    pop de ; stack=[]; DE=Xeps
    call subU40U40 ; HL=Yeps=Y-X
    ; copy result to OP1
    call popRaw9Op1 ; OP1=Yeps-Xeps
    call ConvertI40ToOP1 ; OP1=float(Y-X)
    ; clean up FPS
    call dropRaw9
    call dropRpnObject
    jp dropRpnObject

;-----------------------------------------------------------------------------
; Convert OffsetDateTime or DateTime to target Offset timeZone.
;-----------------------------------------------------------------------------

; Description: Convert the RpnDateTime (OP1) to the timeZone specified by
; RpnOffset (OP3).
; Input:
;   - OP1:RpnDateTime or RpnOffset
;   - OP3:RpnOffset or RpnDateTime
; Output:
;   - OP1; RpnOffsetDatetime
; Destroys: all, OP3-OP6
ConvertRpnDateTimeToOffset:
    call checkOp1DateTimePageTwo ; ZF=1 if CP1 is an RpnDateTime
    jr z, convertRpnDateTimeToOffsetConvert
    call cp1ExCp3PageTwo ; CP1=rpnDateTime; CP3=rpnOffset
convertRpnDateTimeToOffsetConvert:
    ; CP1=rpnDateTime; CP3=rpnOffset
    call PushRpnObject1 ; FPS=[rpnDateTime]; HL=rpnDateTime
    inc hl ; HL=dateTime
    ex de, hl ; DE=dateTime
    ;
    call pushRaw9Op3 ; FPS=[rpnDateTime,rpnOffset]; HL=rpnOffset
    inc hl ; HL=offset
    push hl ; stack=[offset]
    ; convert DateTime to epochSeconds
    call reserveRaw9 ; FPS=[rpnDateTime,rpnOffset,epochSeconds]
    call dateTimeToEpochSeconds ; HL=epochSeconds
    ; convert to OffsetDateTime
    ex de, hl ; DE=epochSeconds
    pop bc ; stack=[]; BC=offset
    ld hl, OP1
    ld a, rpnObjectTypeOffsetDateTime
    ld (hl), a
    inc hl
    call epochSecondsToOffsetDateTime ; HL=OP1=offsetDateTime
    call expandOp1ToOp2PageTwo
    ; clean up FPS
    call dropRaw9 ; FPS=[rpnDateTime,rpnOffset]
    call dropRaw9 ; FPS=[rpnDateTime]
    jp dropRpnObject ; FPS=[]

; Description: Convert the RpnDateTime to the timeZone specified as offsetHour
; (e.g. 8.5 for Offset{8,30}).
; Input:
;   - OP1:RpnDateTime or Real
;   - OP3:Real or RpnDateTime
; Output:
;   - OP1; RpnOffsetDatetime
; Destroys: all, OP3-OP6
ConvertRpnDateTimeToReal:
    call checkOp1DateTimePageTwo ; ZF=1 if CP1 is an RpnDateTime
    jr z, convertRpnDateTimeToRealConvert
    call cp1ExCp3PageTwo ; CP1=rpnDateTime; CP3=offsetHour
convertRpnDateTimeToRealConvert:
    call PushRpnObject1 ; FPS=[rpnDateTime]; HL=rpnDateTime
    call op3ToOp1PageTwo ; OP1=offsetHour
    ; convert offsetHour to RpnOffset
    ld hl, OP3
    ld a, rpnObjectTypeOffset
    ld (hl), a
    inc hl
    call offsetHourToOffset ; HL=OP3+1=offset
    ; clean up FPS
    call PopRpnObject1 ; FPS=[]; OP1=rpnDateTime
    jr convertRpnDateTimeToOffsetConvert

;-----------------------------------------------------------------------------

; Description: Convert the RpnOffsetDateTime (OP1) to the timeZone specified by
; RpnOffset (OP3).
; Input:
;   - OP1:RpnOffsetDateTime
;   - OP3:RpnOffset
; Output:
;   - OP1; RpnOffsetDatetime
; Destroys: all, OP3-OP6
ConvertRpnOffsetDateTimeToOffset:
    call checkOp1OffsetDateTimePageTwo ; ZF=1 if CP1 is an RpnOffsetDateTime
    jr z, convertRpnOffsetDateTimeToOffsetConvert
    call cp1ExCp3PageTwo ; CP1=rpnOffsetDateTime; CP3=rpnOffset
convertRpnOffsetDateTimeToOffsetConvert:
    ; CP1=rpnOffsetDateTime; CP3=rpnOffset
    call PushRpnObject1 ; FPS=[rpnOffsetDateTime]; HL=rpnOffsetDateTime
    inc hl ; HL=offsetDateTime
    ex de, hl ; DE=offsetDateTime
    ;
    call pushRaw9Op3 ; FPS=[rpnOffsetDateTime,rpnOffset]; HL=rpnOffset
    inc hl ; HL=offset
    push hl ; stack=[offset]
    ; convert OffsetDateTime to epochSeconds
    call reserveRaw9 ; FPS=[rpnOffsetDateTime,rpnOffset,epochSeconds]
    call offsetDateTimeToEpochSeconds ; HL=epochSeconds
    ; convert to OffsetDateTime
    ex de, hl ; DE=epochSeconds
    pop bc ; stack=[]; BC=offset
    ld hl, OP1
    ld a, rpnObjectTypeOffsetDateTime
    ld (hl), a
    inc hl
    call epochSecondsToOffsetDateTime ; HL=OP1=offsetDateTime
    call expandOp1ToOp2PageTwo
    ; clean up FPS
    call dropRaw9 ; FPS=[rpnOffsetDateTime,rpnOffset]
    call dropRaw9 ; FPS=[rpnOffsetDateTime]
    jp dropRpnObject ; FPS=[]

; Description: Convert the RpnOffsetDateTime (OP1) to the timeZone specified by
; (hour,minute) as a floating point number (OP3) (e.g. 8.5 for Offset{8,30}).
; Input:
;   - OP1:RpnOffsetDateTime
;   - OP3:Real
; Output:
;   - OP1; RpnOffsetDatetime
; Destroys: all, OP3-OP6
ConvertRpnOffsetDateTimeToReal:
    call checkOp1OffsetDateTimePageTwo ; ZF=1 if CP1 is an RpnOffsetDateTime
    jr z, convertRpnOffsetDateTimeToRealConvert
    call cp1ExCp3PageTwo ; CP1=rpnOffsetDateTime; CP3=offsetHour
convertRpnOffsetDateTimeToRealConvert:
    call PushRpnObject1 ; FPS=[rpnOffsetDateTime]; HL=rpnOffsetDateTime
    call op3ToOp1PageTwo ; OP1=offsetHour
    ; convert offsetHour to RpnOffset
    ld hl, OP3
    ld a, rpnObjectTypeOffset
    ld (hl), a
    inc hl
    call offsetHourToOffset ; HL=OP3+1=offset
    ; clean up FPS
    call PopRpnObject1 ; FPS=[]; OP1=rpnOffsetDateTime
    jr convertRpnOffsetDateTimeToOffsetConvert
