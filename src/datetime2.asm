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

; Description: Convert the RpnDateTime{} record in OP1 to relative epochSeconds.
; Input: OP1:RpnDateTime=input
; Output: OP1:real
; Destroys: all, OP1-OP6
RpnDateTimeToEpochSeconds:
    ; reserve 2 slots on FPS
    call pushRaw9Op1 ; FPS=[rpnDateTime]; HL=rpnDateTime
    ex de, hl ; DE=rpnDateTime
    call reserveRaw9 ; FPS=[rpnDateTime,epochSeconds]; HL=epochSeconds
    ; convert to epochSeconds
    inc de ; DE=dateTime, skip type byte
    call dateTimeToEpochSeconds ; HL=epochSeconds
    ; copy back to OP1
    call popRaw9Op1 ; FPS=[rpnDateTime]; OP1=epochSeconds
    call dropRaw9 ; FPS=[]
    jp ConvertI40ToOP1 ; OP1=float(epochSeconds)

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

; Description: Convert the relative epochSeconds to an RpnDateTime{} record.
; Input: OP1:Real=epochSeconds
; Output: OP1:RpnDateTime
; Destroys: all, OP1-OP6
EpochSecondsToRpnDateTime:
    ; get relative epochSeconds
    call ConvertOP1ToI40 ; OP1=i40(epochSeconds)
    ; reserve 2 slots on the FPS
    call reserveRaw9 ; FPS=[rpnDateTime]; HL=rpnDateTime
    ex de, hl ; DE=rpnDateTime
    call pushRaw9Op1 ; FPS=[rpnDateTime,epochSeconds]; HL=epochSeconds
    ; convert to RpnDateTime
    ex de, hl ; DE=epochSeconds; HL=rpnDateTime
    ld a, rpnObjectTypeDateTime
    ld (hl), a
    inc hl ; HL=rpnDateTime+1=dateTime
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
;   - OP1:Union[RpnDateTime,RpnReal]=rpnDateTime or seconds
;   - OP3:Union[RpnDateTime,RpnReal]=rpnDateTime or seconds
; Output:
;   - OP1:RpnDateTime=RpnDateTime+seconds
; Destroys: all, OP1, OP2, OP3-OP6
AddRpnDateTimeBySeconds:
    call checkOp1DateTimePageTwo ; ZF=1 if CP1 is an RpnDateTime
    jr z, addRpnDateTimeBySecondsAdd
    call cp1ExCp3PageTwo ; CP1=rpnDateTime, CP3=seconds
addRpnDateTimeBySecondsAdd:
    ; CP1=rpnDateTime, CP3=seconds
    ; Push rpnDateTime to FPS.
    call PushRpnObject1 ; FPS=[rpnDateTime]
    push hl ; stack=[rpnDateTime]
    ; convert OP3 to i40, then push to FPS
    call op3ToOp1PageTwo ; OP1:real=seconds
    call ConvertOP1ToI40 ; OP1:u40=seconds
    call pushRaw9Op1 ; FPS=[rpnDateTime,seconds]; HL=seconds
    ex (sp), hl ; stack=[seconds]; HL=rpnDateTime
    ; convert rpnDateTime to i40 seconds
    ex de, hl ; DE=rpnDateTime
    inc de ; skip type byte
    ld hl, OP1
    call dateTimeToInternalEpochSeconds ; HL=OP1=dateTimeSeconds
    ; add seconds + dateSeconds
    ex de, hl ; DE=dateTimeSeconds
    pop hl ; stack=[]; HL=FPS.seconds
    call addU40U40 ; HL=FPS.resultSeconds=dateTimeSeconds+seconds
    ; Convert resultSeconds to RpnDateTime. Technically, we don't have to
    ; reserve an RpnObject on the FPS, we could have created the result
    ; directly in OP1, because an RpnDateTime will fit inside an OP1. But using
    ; it makes this routine follow the same pattern as
    ; AddRpnOffsetDateTimeBySeconds(), which makes things easier to maintain.
    ex de, hl ; DE=resultSeconds
    call reserveRpnObject ; FPS=[rpnDateTime,seconds,rpnDateTime]
    ld a, rpnObjectTypeDateTime
    ld (hl), a
    inc hl ; HL:(DateTime*)=resultDateTime
    call internalEpochSecondsToDateTime ; HL=resultDateTime+sizeof(DateTime)
    ; clean up stack and FPS
    call PopRpnObject1 ; FPS=[rpnDateTime,seconds]; OP1=resultDateTime
    call dropRaw9 ; FPS=[rpnDateTime,seconds]
    jp dropRpnObject ; FPS=[]

;-----------------------------------------------------------------------------

; Description: Subtract RpnDateTime minus RpnDateTime or seconds.
; Input:
;   - OP1:RpnDateTime=Y
;   - OP3:RpnDateTime or seconds=X
; Output:
;   - OP1:(RpnDateTime-seconds) or (RpnDateTime-RpnDateTime).
; Destroys: OP1, OP2, OP3-OP6
SubRpnDateTimeByRpnDateTimeOrSeconds:
    call checkOp3DateTimePageTwo ; ZF=1 if type(OP3)==DateTime
    jr z, subRpnDateTimeByRpnDateTime
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
    ld de, OP3+1 ; HL=DateTime{}
    call dateTimeToInternalEpochSeconds ; FPS.X.seconds updated; HL=X.seconds
    ; convert OP1 to seconds on FPS stack
    call pushRaw9Op1 ; make space on FPS=[X.seconds,Y.seconds]; HL=Y.seconds
    push hl ; stack=[X.seconds,Y.seconds]
    ld de, OP1+1 ; HL=DateTime{}
    call dateTimeToInternalEpochSeconds ; FPS.Y.seconds updated; HL=Y.seconds
    ; subtract Y.seconds-X.seconds
    pop hl ; HL=Y.seconds
    pop de ; DE=X.seconds
    call subU40U40 ; HL=Y.seconds-X.seconds
    ; pop result into OP1
    call popRaw9Op1 ; FPS=[X.seconds]; OP1=epochSeconds
    call ConvertI40ToOP1 ; OP1=float(epochSeconds)
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
    ld de, OP3 ; DE:(Date*)
    ld a, rpnObjectTypeDate
    ld (de), a
    inc de
    ld hl, OP1+1 ; HL:(const Date*)
    ld bc, rpnObjectTypeDateSizeOf-1
    ldir
    ; Extract the Time part by shifting forward. This is allowed because
    ; sizeof(Date)>sizeof(Time), so there is no overlap.
    ld de, OP1
    ld a, rpnObjectTypeTime
    ld (de), a
    inc de
    ld hl, OP1+rpnObjectTypeDateSizeOf ; HL:(const Time*)
    ld bc, rpnObjectTypeTimeSizeOf-1
    ldir
    ret

;-----------------------------------------------------------------------------

; Description: Merge RpnDate with RpnTime.
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
    ld de, OP1
    ld a, rpnObjectTypeDateTime
    ld (de), a
    ld de, OP1+rpnObjectTypeDateSizeOf
    ld hl, OP3+1
    ld bc, rpnObjectTypeTimeSizeOf-1
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
    ld (OP1), a
    ; clear the Time fields
    ld hl, OP1+rpnObjectTypeDateSizeOf
    xor a
    ld (hl), a
    inc hl
    ld (hl), a
    inc hl
    ld (hl), a
    ret
