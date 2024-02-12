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
    ; negate (hh,mm)
    ld a, b
    neg
    ld b, a
    ld a, c
    neg
    ld c, a
    ;
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
; record {hh,mm}. The floatHours is restricted in the following way:
;   - must be a multiple of 15 minutes. (If the floating hours is multiplied by
;   4, the result should be an integer.)
;   - must be within the interval [-23:45,+23:45]
;Input:
;   - OP1:Real=floatHours
;   - HL:(Offset*)=offset
; Output:
;   - HL:(Offset*)=offset filled
; Destroys: A, BC, DE
; Preserves: HL
; Throws: Err:Domain if greater than or equal to +/-24:00, or not a multiple of
; 15 minutes.
floatHoursToOffset:
    ld a, (OP1) ; bit7=sign bit
    rla ; CF=1 if negative
    jr nc, floatHoursToOffsetPos
floatHoursToOffsetNeg:
    ; If negative, invert the sign of input, convert to Offset, then invert the
    ; sign of the ouput.
    bcall(_InvOP1S) ; OP1=-OP1
    call floatHoursToOffsetPos ; Preserves HL=offset
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

; Input:
;   -OP1:floatHours
;   - HL=offset
; Output:
;   - HL=offset
; Preserves: HL
floatHoursToOffsetPos:
    ; reserve space for Offset object
    push hl ; stack=[offset]
    ; extract whole hh
    bcall(_RndGuard) ; eliminating invisible rounding errors
    ; check within +/-24:00
    call op2Set24PageOne ; OP2=24
    bcall(_CpOP1OP2) ; CF=1 if OP1<OP2
    jr nc, floatHoursToOffsetErr
    ; check multiple of 15 minutes
    bcall(_Times2) ; OP1*=2
    bcall(_Times2) ; OP1=floatQuarters=floatHours*4
    bcall(_CkPosInt) ; ZF=1 if OP1 is an integer >= 0
    jr nz, floatHoursToOffsetErr ; err if not a multiple of 15
    ; Convert floatQuarters into (hour,minute)
    call ConvertOP1ToI40 ; OP1=quarters=u40(floatQuarters)
    ld bc, (OP1) ; BC=floatQuarters
    call quartersToHourMinute ; DE=(hour,minute)
    ; Fill offset
    pop hl ; stack=[]; HL=offset
    ld (hl), d ; offset.hh=hour
    inc hl
    ld (hl), e ; offset.mm=minute
    dec hl ; HL=offset
    ret
floatHoursToOffsetErr:
    bcall(_ErrDomain)

; Description: Convert quarters (multiple of 15 minutes) into (hour,minute).
; Input:
;   - BC:u16=quarters
; Output:
;   - D:u8=hour
;   - E:u8=minute
; Destroys: A, BC
quartersToHourMinute:
    ld a, c
    and $03 ; A=remainderQuarter=quarters%4
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
    ld d, c ; D=hour=quarters/4
    ret

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
    push hl ; stack=[dateTimeSeconds]
    ; convert Offset to seconds in OP1
    call reserveRaw9 ; FPS=[offsetSeconds]; HL=offsetSeconds
    call offsetToSeconds ; HL=offsetSeconds; DE+=sizeof(Offset)
    ; add offsetSeconds to dateTimeSeconds
    ex de, hl ; DE=offsetSeconds; HL=offsetDateTime+9
    ex (sp), hl ; stack=[offsetDateTime+7]; HL=datetimeSeconds
    call subU40U40 ; HL=resultSeconds=dateTimeSeconds-offsetSeconds
    ; clean up stack and FPS
    pop de ; stack=[]; DE=offsetDateTime+7
    jp dropRaw9

;-----------------------------------------------------------------------------

; Description: Convert the relative epochSeconds to an RpnOffsetDateTime{}
; record.
; Input: OP1:Real=epochSeconds
; Output: OP1:RpnDateTime
; Destroys: all, OP1-OP6
EpochSecondsToRpnOffsetDateTime:
    ; get relative epochSeconds
    call ConvertOP1ToI40 ; OP1=i40(epochSeconds)
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
;   - (*HL)=offsetDateTime updated
;   - HL=HL+sizeof(OffsetDateTime)
; Destroys: all, OP1-OP6
epochSecondsToOffsetDateTime:
    push bc ; stack=[offset]
    push hl ; stack=[offset,offsetDateTime]
    push de ; stack=[offset,offsetDateTime,epochSeconds]
    ; convert offset (BC) to seconds
    call reserveRaw9 ; FPS=[offsetSeconds]; HL=offsetSeconds
    ld e, c
    ld d, b
    call offsetToSeconds ; HL=offsetSeconds updated
    ; shift the epochSeconds to the given Offset
    pop de ; stack=[offset,offsetDateTime]; DE=epochSeconds
    call addU40U40 ; HL=effEpochSeconds=offsetSeconds+epochSeconds
    ; convert effEpochSeconds to DateTime
    ex de, hl ; DE=effEpochSeconds
    pop hl ; stack=[offset]; HL=offsetDateTime
    call epochSecondsToDateTime ; HL=offsetDateTime+sizeof(DateTime)
    ; copy the given offset into OffsetDateTime.offset
    pop bc ; stack=[]; BC=offset
    ld a, (bc)
    inc bc
    ld (hl), a
    inc hl
    ;
    ld a, (bc)
    inc bc
    ld (hl), a
    inc hl
    ; cleanup FPS
    jp dropRaw9 ; FPS=[]

;-----------------------------------------------------------------------------

; Description: Add (RpnOffsetDateTime plus seconds) or (seconds plus
; RpnDateTime).
; Input:
;   - OP1:Union[RpnOffsetDateTime,RpnReal]=rpnOffsetDateTime or seconds
;   - OP3:Union[RpnOffsetDateTime,RpnReal]=rpnOffsetDateTime or seconds
; Output:
;   - OP1:RpnOffsetDateTime=RpnOffsetDateTime+seconds
;   - DE=OP1+sizeof(OffsetDateTime)
; Destroys: OP1, OP2, OP3-OP6
AddRpnOffsetDateTimeBySeconds:
    call checkOp1OffsetDateTimePageOne ; ZF=1 if CP1 is an RpnDateTime
    jr nz, addRpnOffsetDateTimeBySecondsAdd
    call cp1ExCp3PageOne ; CP1=seconds; CP3=RpnDateTime
addRpnOffsetDateTimeBySecondsAdd:
    ; CP1=seconds, CP3=RpnOffsetDateTime
    call ConvertOP1ToI40 ; HL=OP1=u40(seconds)
    call pushRaw9Op1 ; FPS=[seconds]
    push hl ; stack=[seconds]
    ; convert rpnOffsetDateTime to OP1=seconds
    call PushRpnObject3 ; FPS[seconds,rpnOffsetDateTime];
    ex de, hl ; DE=rpnOffsetDateTime
    inc de
    ld hl, OP1
    call offsetDateTimeToEpochSeconds ; HL=OP1=offsetDateTimeSeconds
    ld c, e
    ld b, d ; BC=offsetDateTime+sizeof(OffsetDateTime)
    dec bc
    dec bc ; BC:(Offset*)
    ; add seconds + dateSeconds
    ex de, hl ; DE=offsetDateTimeSeconds
    pop hl ; stack=[]; HL=FPS.seconds
    call addU40U40 ; HL=FPS.resultSeconds=offsetDateTimeSeconds+seconds
    ; convert seconds to RpnOffsetDateTime
    ex de, hl ; DE=resultSeconds
    ld hl, OP1
    ld a, rpnObjectTypeOffsetDateTime
    ld (hl), a
    inc hl ; HL:(OffsetDateTime*)=newOffsetDateTime
    call epochSecondsToOffsetDateTime ; HL=OP1+sizeof(OffsetDateTime)
    ; clean up stack and FPS
    call dropRpnObject
    jp dropRaw9

;-----------------------------------------------------------------------------

; Description: Subtract RpnOffsetDateTime minus RpnOffsetDateTime or seconds.
; Input:
;   - OP1:RpnOffsetDateTime=Y
;   - OP3:RpnOffsetDateTime or seconds=X
; Output:
;   - OP1:(RpnOffsetDateTime-seconds) or (RpnOffsetDateTime-RpnOffsetDateTime).
; Destroys: OP1, OP2, OP3-OP6
SubRpnOffsetDateTimeByRpnOffsetDateTimeOrSeconds:
    call checkOp3OffsetDateTimePageOne ; ZF=1 if type(OP3)==OffsetDateTime
    jr z, subRpnOffsetDateTimeByRpnOffsetDateTime
subRpnOffsetDateTimeBySeconds:
    ; exchage CP1/CP3, invert the sign, then call
    ; addRpnOffsetDateTimeBySecondsAdd()
    call cp1ExCp3PageOne
    bcall(_InvOP1S) ; OP1=-OP1
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
    call checkOp1DateTimePageOne ; ZF=1 if CP1 is an RpnDateTime
    jr z, convertRpnDateTimeToOffsetConvert
    call cp1ExCp3PageOne ; CP1=rpnDateTime; CP3=rpnOffset
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
    call expandOp1ToOp2PageOne
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
    call checkOp1DateTimePageOne ; ZF=1 if CP1 is an RpnDateTime
    jr z, convertRpnDateTimeToRealConvert
    call cp1ExCp3PageOne ; CP1=rpnDateTime; CP3=offsetHour
convertRpnDateTimeToRealConvert:
    call PushRpnObject1 ; FPS=[rpnDateTime]; HL=rpnDateTime
    call op3ToOp1PageOne ; OP1=offsetHour
    ; convert offsetHour to RpnOffset
    ld hl, OP3
    ld a, rpnObjectTypeOffset
    ld (hl), a
    inc hl
    call floatHoursToOffset ; HL=OP3+1=offset
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
    call checkOp1OffsetDateTimePageOne ; ZF=1 if CP1 is an RpnOffsetDateTime
    jr z, convertRpnOffsetDateTimeToOffsetConvert
    call cp1ExCp3PageOne ; CP1=rpnOffsetDateTime; CP3=rpnOffset
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
    call expandOp1ToOp2PageOne
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
    call checkOp1OffsetDateTimePageOne ; ZF=1 if CP1 is an RpnOffsetDateTime
    jr z, convertRpnOffsetDateTimeToRealConvert
    call cp1ExCp3PageOne ; CP1=rpnOffsetDateTime; CP3=offsetHour
convertRpnOffsetDateTimeToRealConvert:
    call PushRpnObject1 ; FPS=[rpnOffsetDateTime]; HL=rpnOffsetDateTime
    call op3ToOp1PageOne ; OP1=offsetHour
    ; convert offsetHour to RpnOffset
    ld hl, OP3
    ld a, rpnObjectTypeOffset
    ld (hl), a
    inc hl
    call floatHoursToOffset ; HL=OP3+1=offset
    ; clean up FPS
    call PopRpnObject1 ; FPS=[]; OP1=rpnOffsetDateTime
    jr convertRpnOffsetDateTimeToOffsetConvert
