;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; RpnDateTime functions.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Convert the RpnDateTime{} record in OP1 to relative
; epochSeconds, assuming UTC timezone.
; Input: OP1:RpnDateTime=input
; Output: OP1:real
; Destroys: all, OP1-OP6
RpnDateTimeToEpochSeconds:
    ; reserve 2 slots on FPS
    call pushRaw9Op1 ; FPS=[rpnDateTime]; HL=rpnDateTime
    ex de, hl ; DE=rpnDateTime
    call reserveRaw9 ; FPS=[rpnDateTime,epochSeconds]; HL=epochSeconds
    ; convert to epochSeconds
    skipRpnObjectTypeDE ; DE=dateTime, skip type byte
    call dateTimeToEpochSeconds ; HL=epochSeconds
    ; copy back to OP1
    call popRaw9Op1 ; FPS=[rpnDateTime]; OP1=epochSeconds
    call dropRaw9 ; FPS=[]
    jp convertI40ToOP1 ; OP1=float(epochSeconds)

; Description: Convert DateTime{} to relative epochSeconds.
; Input:
;   - DE:(const DateTime*)=dateTime, must not be OPx
;   - HL:(i40*)=resultSeconds, must not be OPx
; Output:
;   - DE=DE+sizeof(DateTime)
;   - (*HL):i40=resultSeconds
; Destroys: OP4-OP6
; Preserves: HL
dateTimeToEpochSeconds:
    ; convert Date to relative epochSeconds
    call dateToEpochDays ; HL=resultDays; DE=DE+sizeof(Date)=(Time*)
    call convertU40DaysToU40Seconds ; HL=resultSeconds
    ; convert Time to seconds
    push hl ; stack=[resultSeconds]
    call reserveRaw9 ; FPS=[timeSeconds]; HL=timeSeconds
    call timeToSeconds ; FPS.timeSeconds updated; DE=DE+sizeof(Time)
    ; add timeSeconds to resultSeconds
    ex de, hl ; HL=dateTime+7; DE=timeSeconds
    ex (sp), hl ; stack=[dateTime+7]; HL=resultSeconds
    call addU40U40 ; HL=resultSeconds+=timeSeconds
    ; clean up stack and FPS
    pop de ; stack=[]; DE=dateTime+7
    jp dropRaw9 ; FPS=[]

;-----------------------------------------------------------------------------

; Description: Convert the relative epochSeconds to an RpnDateTime{} record
; that assumes a UTC timezone.
; Input: OP1:Real=epochSeconds
; Output: OP1:RpnDateTime
; Destroys: all, OP1-OP6
EpochSecondsToRpnDateTime:
    ; get relative epochSeconds
    call convertOP1ToI40 ; OP1=i40(epochSeconds)
epochSecondsToRpnDateTimeAlt:
    ; reserve 2 slots on the FPS
    call reserveRaw9 ; FPS=[rpnDateTime]; HL=rpnDateTime
    ex de, hl ; DE=rpnDateTime
    call pushRaw9Op1 ; FPS=[rpnDateTime,epochSeconds]; HL=epochSeconds
    ; convert to RpnDateTime
    ex de, hl ; DE=epochSeconds; HL=rpnDateTime
    ld a, rpnObjectTypeDateTime
    call setHLRpnObjectTypePageTwo ; HL+=rpnObjectTypeSizeOf
    call epochSecondsToDateTime ; HL=HL+sizeof(DateTime)
    ; clean up FPS
    call dropRaw9
    jp popRaw9Op1

; Description: Convert relative epochSeconds to DateTime.
; Input:
;   - DE:(const i40*)=epochSeconds, must not be an OPx
;   - HL:(DateTime*)=dateTime, must not be an OPx
; Output:
;   - (*HL)=dateTime updated
;   - HL=HL+sizeof(DateTime)
; Destroys: all, OP1-OP6
epochSecondsToDateTime:
    push hl ; stack=[dateTime]
    push de ; stack=[dateTime,epochSeconds]
    ; TODO: Precompute the refEpochSeconds.
    ld de, currentEpochDate
    ld hl, OP2
    call dateToInternalEpochDays ; HL=OP2=refEpochDays
    call convertU40DaysToU40Seconds ; HL=OP2=refEpochSeconds
    ; calculate internal epochSeconds
    ex de, hl ; DE=OP2=refEpochSeconds
    pop hl ; stack=[dateTime]; HL=epochSeconds
    call addU40U40 ; HL=internal epochSeconds
    ; convert internal epochSeconds to RpnDateTime
    ex de, hl ; DE=epochSeconds
    pop hl ; stack=[]; HL=dateTime
    jp internalEpochSecondsToDateTime ; HL=HL+sizeof(DateTime)

;-----------------------------------------------------------------------------

; Description: Add (RpnDateTime plus seconds) or (seconds plus RpnDateTime).
; Input:
;   - OP1:(RpnDateTime|RpnReal)=rpnDateTime or seconds
;   - OP3:(RpnDateTime|RpnReal)=rpnDateTime or seconds
; Output:
;   - OP1:RpnDateTime=RpnDateTime+seconds
; Destroys: all, OP1, OP2, OP3-OP6
AddRpnDateTimeBySeconds:
    call checkOp1DateTimePageTwo ; ZF=1 if CP1 is an RpnDateTime
    jr z, addRpnDateTimeBySecondsAdd
    call cp1ExCp3PageTwo ; CP1=rpnDateTime, CP3=seconds
addRpnDateTimeBySecondsAdd:
    ; if here: CP1=rpnDateTime, CP3=seconds
    ; Push CP1:RpnDateTime to FPS
    call PushRpnObject1 ; FPS=[dateTime]; HL=dateTime
    push hl ; stack=[dateTime]
    ; convert real(seconds) to i40(seconds)
    call op3ToOp1PageTwo ; OP1:real=seconds
    call convertOP1ToI40 ; OP1:u40=seconds
    ; add dateTime+seconds
    pop hl ; stack=[]; HL=rpnDateTime
    skipRpnObjectTypeHL ; HL=dateTime
    ld de, OP1
    call addDateTimeBySeconds ; HL=newDateTime
    ; clean up
    call PopRpnObject1 ; FPS=[]; OP1=newRpnDateTime
    ret

; Description: Add (RpnDateTime plus duration) or (duration plus RpnDateTime).
; Input:
;   - OP1:(RpnDateTime|RpnDuration)=rpnDateTime or duration
;   - OP3:(RpnDateTime|RpnDuration)=rpnDateTime or duration
; Output:
;   - OP1:RpnDateTime=RpnDateTime+duration
; Destroys: all, OP1, OP2, OP3-OP6
AddRpnDateTimeByRpnDuration:
    call checkOp1DateTimePageTwo ; ZF=1 if CP1 is an RpnDateTime
    jr z, addRpnDateTimeByRpnDurationAdd
    call cp1ExCp3PageTwo ; CP1=rpnDateTime, CP3=duration
addRpnDateTimeByRpnDurationAdd:
    ; if here: CP1=rpnDateTime, CP3=duration
    ; Push CP1:RpnDateTime to FPS
    call PushRpnObject1 ; FPS=[dateTime]; HL=dateTime
    push hl ; stack=[dateTime]
    ; Convert OP3:RpnDuration to OP1 days
    ld de, OP3+rpnObjectTypeSizeOf ; DE:(Duration*)=duration
    ld hl, OP1 ; HL:(i40*)=durationSeconds
    call durationToSeconds ; HL=durationSeconds
    ; add dateTime+seconds
    pop hl ; stack=[]; HL=rpnDateTime
    skipRpnObjectTypeHL ; HL=dateTime
    ld de, OP1
    call addDateTimeBySeconds ; HL=newDateTime
    ; OP1=newDateTime
    call PopRpnObject1 ; FPS=[]; OP1=newDateTime
    ret

; Description: Add DateTime plus seconds.
; Input:
;   - DE:(i40*)=seconds
;   - HL:(DateTime*)=dateTime
; Output:
;   - HL:(DateTime*)=newDateTime
; Destroys: A, BC
; Preserves: DE, HL
addDateTimeBySeconds:
    push hl ; stack=[dateTime]
    push de ; stack=[dateTime,seconds]
    ; convert dateTime to dateTimeSeconds
    ex de, hl ; DE=dateTime
    call reserveRaw9 ; FPS=[dateTimeSeconds]; HL=dateTimeSeconds
    call dateTimeToInternalEpochSeconds ; HL=dateTimeSeconds
    ; add seconds
    pop de ; stack=[dateTime]; DE=seconds
    call addU40U40 ; HL=resultSeconds=dateTimeSeconds+seconds
    ; convert dateTimeSeconds to dateTime
    ex de, hl ; DE=resultSeconds; HL=seconds
    ex (sp), hl ; stack=[seconds]; HL=dateTime
    call internalEpochSecondsToDateTime ; HL=dateTime filled
    ; clean up
    pop de ; stack=[]; DE=seconds
    call dropRaw9 ; FPS=[]
    ret

;-----------------------------------------------------------------------------

; Description: Subtract RpnDateTime minus RpnDateTime or seconds.
; Input:
;   - OP1:RpnDateTime=Y
;   - OP3:RpnDateTime or seconds=X
; Output:
;   - OP1:(RpnDateTime-seconds) or i40(RpnDateTime-RpnDateTime).
; Destroys: OP1, OP2, OP3-OP6
SubRpnDateTimeByObject:
    call getOp3RpnObjectTypePageTwo ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, subRpnDateTimeBySeconds
    cp rpnObjectTypeDateTime
    jr z, subRpnDateTimeByRpnDateTime
    cp rpnObjectTypeDuration
    jr z, subRpnDateTimeByRpnDuration
    bcall(_ErrInvalid) ; should never happen
subRpnDateTimeBySeconds:
    ; invert the sign of OP3, then call addRpnDateTimeBySecondsAdd()
    call cp1ExCp3PageTwo
    bcall(_InvOP1S) ; OP1=-OP1
    call cp1ExCp3PageTwo
    jr addRpnDateTimeBySecondsAdd
subRpnDateTimeByRpnDateTime:
    ; convert OP3 to seconds on the FPS stack
    call reserveRaw9 ; FPS=[X.seconds]; HL=X.seconds
    push hl ; stack=[X.seconds]
    ld de, OP3+rpnObjectTypeSizeOf ; DE=(DateTime*)
    call dateTimeToInternalEpochSeconds ; FPS.X.seconds updated; HL=X.seconds
    ; convert OP1 to seconds on FPS stack
    call pushRaw9Op1 ; make space on FPS=[X.seconds,Y.seconds]; HL=Y.seconds
    push hl ; stack=[X.seconds,Y.seconds]
    ld de, OP1+rpnObjectTypeSizeOf ; DE=(DateTime*)
    call dateTimeToInternalEpochSeconds ; FPS.Y.seconds updated; HL=Y.seconds
    ; subtract Y.seconds-X.seconds
    pop hl ; HL=Y.seconds
    pop de ; DE=X.seconds
    call subU40U40 ; HL=Y.seconds-X.seconds
    ; pop result into OP1
    call popRaw9Op1 ; FPS=[X.seconds]; OP1=epochSeconds
    call convertI40ToOP1 ; OP1=float(epochSeconds)
    jp dropRaw9 ; FPS=[]
subRpnDateTimeByRpnDuration:
    ; convert OP3 to seconds on the FPS stack
    call reserveRaw9 ; FPS=[durationSeconds]; HL=durationSeconds
    ld de, OP3+rpnObjectTypeSizeOf ; DE:(DateTime*)
    call durationToSeconds ; HL=durationSeconds
    ; negate the seconds
    call negU40 ; HL=-durationSeconds
    ex de, hl ; DE=-durationSeconds
    ld hl, OP1+rpnObjectTypeSizeOf ; HL=dateTime
    call addDateTimeBySeconds ; HL=dateTime-durationSeconds
    ; clean up
    jp dropRaw9 ; FPS=[]

;-----------------------------------------------------------------------------

; Description: Split an RpnDateTime into RpnDate and RpnTime.
; Input:
;   - CP1:RpnDateTime=X
; Output:
;   - CP1:RpnTime=Y
;   - CP3:RpnDate=X
; Destroys: all
SplitRpnDateTime:
    ; extract the Date part
    ld a, rpnObjectTypeDate
    call setOp3RpnObjectTypePageTwo ; HL=OP3+rpnObjectTypeSizeOf
    ex de, hl ; DE=(Date*)
    ld hl, OP1+rpnObjectTypeSizeOf ; HL:(const Date*)
    ld bc, rpnObjectTypeDateSizeOf-rpnObjectTypeSizeOf
    ldir
    ; Extract the Time part by shifting forward. This is allowed because
    ; sizeof(Date)>sizeof(Time), so there is no overlap.
    ld a, rpnObjectTypeTime
    call setOp1RpnObjectTypePageTwo ; HL=OP1+rpnObjectTypeSizeOf
    ex de, hl ; DE=(Time*)
    ld hl, OP1+rpnObjectTypeDateSizeOf ; HL:(const Time*)
    ld bc, rpnObjectTypeTimeSizeOf-rpnObjectTypeSizeOf
    ldir
    ret

;-----------------------------------------------------------------------------

; Description: Merge RpnDate with RpnTime into an RpnDateTime.
; Input:
;   - OP1:RpnDate|RpnTime
;   - OP3:RpnDate|RpnTime
; Output:
;   - OP1:RpnDateTime(OP1,OP3)
; Destroys: OP1-OP4
MergeRpnDateWithRpnTime:
    call checkOp1TimePageTwo ; ZF=1 if OP1=RpnTime
    call z, cp1ExCp3PageTwo
    ; if reached here: CP1:RpnDate; CP3:RpnTime
    ld a, rpnObjectTypeDateTime
    call setOp1RpnObjectTypePageTwo ; HL=OP1+rpnObjectTypeSizeOf
    ld de, OP1+rpnObjectTypeDateSizeOf
    ld hl, OP3+rpnObjectTypeSizeOf
    ld bc, rpnObjectTypeTimeSizeOf-rpnObjectTypeSizeOf
    ldir
    ret

;-----------------------------------------------------------------------------

; Description: Convert RpnDate into RpnDateTime by appending a Time field of
; "00:00:00", i.e. T{0,0,0}.
; Input:
;   - OP1:RpnDate
; Output:
;   - OP1:RpnDateTime
; Destroys: OP1
ExtendRpnDateToDateTime:
    ld a, rpnObjectTypeDateTime
    call setOp1RpnObjectTypePageTwo ; HL=OP1+rpnObjectTypeSizeOf
    ; clear the Time fields
    ld de, rpnObjectTypeDateSizeOf-rpnObjectTypeSizeOf
    add hl, de ; HL=timePointer
    xor a
    ld (hl), a
    inc hl
    ld (hl), a
    inc hl
    ld (hl), a
    ret

;-----------------------------------------------------------------------------

; Description: Convert RpnDateTime into RpnDate by truncating the Time field.
; Input:
;   - OP1:RpnDateTime
; Output:
;   - OP1:RpnDate
; Destroys: OP1
TruncateRpnDateTime:
    ld a, rpnObjectTypeDate
    call setOp1RpnObjectTypePageTwo
    ret
