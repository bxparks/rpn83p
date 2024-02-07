;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

InitDate:
    call SelectUnixEpochDate
    ; Set the default custom epochDate to 2000-01-01
    ld hl, y2kDate
    jp setEpochDateCustom

;-----------------------------------------------------------------------------
; RpnObjecType checkers.
;-----------------------------------------------------------------------------

; Description: Check if OP1 is a RpnDate.
; Output: ZF=1 if RpnDate
checkOp1DatePageOne:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeDate
    ret

; Description: Check if OP3 is a RpnDate.
; Output: ZF=1 if RpnDate
checkOp3DatePageOne:
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeDate
    ret

; Description: Check if OP1 is a RpnDateTime.
; Output: ZF=1 if RpnDateTime
checkOp1DateTimePageOne:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeDateTime
    ret

; Description: Check if OP3 is a RpnDateTime.
; Output: ZF=1 if RpnDateTime
checkOp3DateTimePageOne:
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeDateTime
    ret

;-----------------------------------------------------------------------------
; Validate various date-related records.
;-----------------------------------------------------------------------------

; Description: Validate that the given Date{} is a valid Gregorian calendar
; date between year 0000 and 9999, inclusive.
;
; TODO: Add the code to check for 0000 and 9999. Also, I think 0001 may make
; more sense, to avoid negative Gregorian era number in
; dateToInternalEpochDays().
;
; Input: HL:(*Date) pointer
; Output:
;   - HL=HL+4
; Destroys: A, BC, DE
; Throws: ErrInvalid on failure
validateDate:
    ld c, (hl)
    inc hl
    ld b, (hl)
    inc hl ; BC=year
    ld e, (hl) ; E=month
    inc hl
    dec e ; E=month-1
    ld d, (hl) ; D=day
    inc hl
    dec d ; D=day-1
    ; check month
    ld a, e ; A=month-1
    cp 12 ; CF=0 if month-1>=12
    jr nc, validateDateErr
    ; get maxDay
    ld a, d ; A=day-1
    push de
    push hl
    ld d, 0 ; DE=month-1
    ld hl, maxDaysPerMonth
    add hl, de
    cp (hl) ; CF=0 if day-1>=maxDaysPerMonth
    pop hl
    pop de
    jr nc, validateDateErr
    ; check special case for Feb
    ld a, e ; A=month-1
    cp 1 ; ZF=1 if month==Feb
    ret nz
    ; if Feb and leap year: no additional testing needed
    call isLeapYear ; CF=1 if leap; preserves BC, DE, HL
    ret c
    ; if not leap year: check that Feb has max of 28 days
    ld a, d ; A=day-1
    cp 28 ; if day-1>=28: CF=0
    ret c
validateDateErr:
    bcall(_ErrInvalid)

; Description: The maximum value of 'day' for each month.
maxDaysPerMonth:
    .db 31 ; Jan
    .db 29 ; Feb
    .db 31 ; Mar
    .db 30 ; Apr
    .db 31 ; May
    .db 30 ; Jun
    .db 31 ; Jul
    .db 31 ; Aug
    .db 30 ; Sep
    .db 31 ; Oct
    .db 30 ; Nov
    .db 31 ; Dec

;-----------------------------------------------------------------------------

; Description: Validate the Time components (h,m,s) of the Time{} record in HL.
; Input: HL:(*Time) pointer (h,m,s)
; Output: HL=HL+3
; Destroys: A, HL
; Preserves: BC, DE
; Throws: Err:Invalid on failure
validateTime:
    ld a, (hl) ; A=hour
    inc hl
    cp 24
    jr nc, validateTimeErr ; if hour>=24: err
    ld a, (hl) ; A=minute
    inc hl
    cp 60
    jr nc, validateTimeErr ; if minute>=60: err
    ld a, (hl) ; A=second
    inc hl
    cp 60
    ret c ; if second>=60: err
validateTimeErr:
    bcall(_ErrInvalid)

;-----------------------------------------------------------------------------

; Description: Validate the DateTime object in HL.
; Input: HL:(*DateTime) pointer to {y,M,d,h,m,s}
; Output:
;   - HL=HL+7
; Destroys: A, HL
; Preserves: BC, DE
; Throws: Err:Invalid on failure
validateDateTime:
    call validateDate
    call validateTime
    ret

;-----------------------------------------------------------------------------

; Description: Validate the Offset object in HL. Restrict the range of the
; offset to "-24:00" to "+24:00" exclusive. Also verify that the sign of the
; hour and minute match. In other words, {0,0}, {0,30}, {1,0}, {8,30} {-1,0},
; {-8,-30}, are allowed, but {8,-30}, {-1,30}, {1,-30} are invalid.
;
; Input: HL:(*Offset) pointer to {h,m}
; Output:
;   - HL=HL+2
; Destroys: A, HL
; Preserves: BC, DE
; Throws: Err:Invalid on failure
validateOffset:
    ; read hour, minute
    push bc
    ld b, (hl) ; B=hour
    inc hl
    ld c, (hl) ; C=minute
    inc hl
    ;
    call validateOffsetMagnitudes
    call validateOffsetSigns
    pop bc
    ret

validateOffsetMagnitudes:
    ; validate hour
    ld a, b
    bit 7, a
    jr z, validateOffsetPosHour
    neg
validateOffsetPosHour:
    cp 24
    jr nc, validateOffsetErr ; if hour>=24: err
    ; validate minute
    ld a, c
    bit 7, a
    jr z, validateOffsetPosMinute
    neg
validateOffsetPosMinute:
    cp 60
    jr nc, validateOffsetErr ; if minute>=60: err
    ret

validateOffsetErr:
    bcall(_ErrInvalid)

validateOffsetSigns:
    ; if either hour or minute is 0, then the other can be any sign
    ld a, b
    or a
    ret z
    ld a, c
    or a
    ret z
    ; compare the sign bits of hour and minute
    ld a, b
    xor c
    bit 7, a
    jr nz, validateOffsetErr ; if sign(hour) != sign(minute): err
    ret

;-----------------------------------------------------------------------------

; Description: Validate the OffsetDateTime object in HL.
; Input: HL:(*OffsetDateTime) pointer to {y,M,d,h,m,s,oh,os}
; Output:
;   - HL=HL+9
; Destroys: A, HL
; Preserves: BC, DE
; Throws: Err:Invalid on failure
validateOffsetDateTime:
    call validateDate
    call validateTime
    call validateOffset
    ret

;-----------------------------------------------------------------------------
; Converters.
;-----------------------------------------------------------------------------

; Description: Convert RpnDate or RpnDateTime to RpnOffsetDateTime. The
; conversion is done in situ.
; Input: HL:RpnDate or RpnDateTime
; Output; HL:RpnOffsetDateTime
; Destroys: A
; Preserves: BC, DE, HL
convertToOffsetDateTime:
    ; check if already RpnOffsetDateTime
    ld a, (hl) ; A=rpnType
    cp rpnObjectTypeOffsetDateTime
    ret z
    ;
    push hl
    push de
    push bc
    ; check if RpnDateTime
    cp rpnObjectTypeDateTime
    jr z, convertToOffsetDateTimeFromDateTime
    ; check if RpnDate
    cp rpnObjectTypeDate
    jr z, convertToOffsetDateTimeFromDate
    bcall(_ErrDataType)
convertToOffsetDateTimeFromDateTime:
    ld bc, rpnObjectTypeDateTimeSizeOf
    jr convertToOffsetDateTimeClear
convertToOffsetDateTimeFromDate:
    ld bc, rpnObjectTypeDateSizeOf
convertToOffsetDateTimeClear:
    add hl, bc ; HL=pointerToClearArea
    ex de, hl ; DE=pointerToClearArea
    ld hl, rpnObjectTypeOffsetDateTimeSizeOf
    scf; CF=1
    sbc hl, bc ; HL=numBytesToClear=rpnObjectTypeOffsetDateTimeSizeOf-sizeOf-1
    ;
    ld c, l
    ld b, h ; BC=numBytesToClear
    ld l, e
    ld h, d ; HL=pointerToClearArea
    inc de ; DE=HL+1
    ld (hl), 0 ; clear the first byte
    ldir ; clear the rest
    ;
    pop bc
    pop de
    pop hl
    ret

;-----------------------------------------------------------------------------

; Description: Multiply the u40 days pointed by HL by 86400 seconds/day to get
; seconds.
; Input: HL:(*u40)=days
; Output: HL:(*u40)=seconds
; Destroys: A
; Preserves: BC, DE, HL
convertU40DaysToU40Seconds:
    push de ; stack=[DE]
    ex de, hl ; DE=days
    ; Push 86400 onto stack
    ld hl, 0
    push hl
    ld hl, 1
    push hl
    ld hl, 20864
    push hl
    ld hl, 0
    add hl, sp ; HL=SP=u40=86400
    ; Multiply days by 86400
    ex de, hl ; DE=86400, HL=days
    call multU40U40 ; HL=days*86400
    ; Remove 86400 from stack
    pop de
    pop de
    pop de
    ; Restore
    pop de ; stack=[]; DE=DE
    ret

;-----------------------------------------------------------------------------
; Simple date functions.
;-----------------------------------------------------------------------------

; Description: Determine if OP1 is leap year.
; Input: OP1
; Output: 1 or 0
; Destroys: all
IsLeap:
    call convertOP1ToHLPageOne ; HL=u16(OP1) else Err:Domain
    ld c, l
    ld b, h
    call isLeapYear ; CF=1 if leap
    jr c, isLeapTrue
    bcall(_OP1Set0)
    ret
isLeapTrue:
    bcall(_OP1Set1)
    ret

; Description: Check if given year (BC) is a leap year. A year is leap if:
; ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0)
; Input: BC: year
; Output: CF=1 if leap
; Destroys: A
; Preserves: BC, DE, HL
isLeapYear:
    push hl ; stack=[HL]
    push de ; stack=[HL,DE]
    ld a, c
    and $03 ; A=year%4
    jr nz, isLeapYearFalse ; if not multiple of 4: not leap
    ; check if divisible by 100
    push bc ; stack=[HL,DE,year]
    ld l, c
    ld h, b ; HL=year
    ld c, 100
    call divHLByC ; HL=quotient; A=remainder
    or a ; if remainder==0: ZF=1
    pop bc ; stack=[HL,DE]; BC=year
    jr nz, isLeapYearTrue
    ; check if divisible by 400
    push bc ; stack=[HL,DE,year]
    ld l, c
    ld h, b ; HL=year
    ld bc, 400
    call divHLByBC ; HL=quotient; DE=remainder
    ld a, e
    or d ; if remainder==0: ZF=1
    pop bc ; stack=[HL,DE]; BC=year
    jr z, isLeapYearTrue ; if multiple of 400: leap
isLeapYearFalse:
    pop de ; stack=[HL]; DE=DE
    pop hl ; stack=[]; HL=HL
    or a
    ret
isLeapYearTrue:
    pop de ; stack=[HL]; DE=DE
    pop hl ; stack=[]; HL=HL
    scf
    ret

;-----------------------------------------------------------------------------

; Description: Return the ISO day of week (1=Monday, 7=Sunday) of the given
; Date{} record.
; Input: HL: Date{} record
; Output: A: 1-7
DayOfWeekIso:
    ld de, OP3
    call dateToInternalEpochDays ; DE=OP3=epochDays
    ld a, 7
    ld hl, OP4
    call setU40ToA ; OP4=7
    ex de, hl ; HL=OP3=epochDays; DE=OP4=7
    ld bc, OP5 ; BC=OP5=remainder
    call divU40U40 ; HL=quotient
    ld a, (bc) ; A=remainder=0-6
    ; 2000-01-01 is epoch 0, so returns 0, but it was a Sat, so should be a 6.
    ; Readjust the result modulo 7 to conform to ISO weekday numbering.
    add a, 5
    cp 7
    jr c, dayOfWeekIsoEnd
    sub 7
dayOfWeekIsoEnd:
    inc a
    ret

;-----------------------------------------------------------------------------
; RpnDate functions.
;-----------------------------------------------------------------------------

; Description: Convert RpnDate{} to epochDays relative to the current
; epochDate.
; Input:
;   - OP1:RpnDate
;   - (epochDate):Date{}=current epoch date
; Output:
;   - OP1:epochDays
; Destroys: A, DE, BC, HL, OP1-OP3, OP4-OP6
RpnDateToEpochDays:
    call dateToEpochDays ; HL=OP3=epochDays
    call ConvertI40ToOP1 ; OP1=float(OP3)
    ret

; Description: Convert RpnDate{} to epochSeconds relative to the current
; epochDate.
; Input:
;   - OP1:RpnDate
;   - (epochDate):Date{}=current epoch date
; Output:
;   - OP1:epochSeconds
; Destroys: A, DE, BC, HL, OP1-OP3, OP4-OP6
RpnDateToEpochSeconds:
    call dateToEpochDays ; HL=OP3=(i40*)=relative epochDays
    call convertU40DaysToU40Seconds
    call ConvertI40ToOP1
    ret

; Description: Convert Date{} to relative epochSeconds.
; Input:
;   - OP1:Date
; Output:
;   - HL=OP3
;   - OP3:i40=days
dateToEpochDays:
    ld hl, OP1+1
    ld de, OP3
    call dateToInternalEpochDays ; OP3=epochDays(input)
    call op3ToOp2PageOne ; OP2=internalEpochDays(input)
    ; convert current epochDate to current epochDays
    ld hl, epochDate
    ld de, OP1
    call dateToInternalEpochDays ; OP1=epochDays(currentEpochDate)
    ; convert epochDays relatives to current epochDays
    ld hl, OP3
    ld de, OP1
    call subU40U40 ; OP3=epochDays(input)-epochDays(currentEpochDate)
    ret

;-----------------------------------------------------------------------------

; Description: Convert the current epochDays (relative to the current
; epochDate) to an RpnDate{} record.
; Input: OP1: float(epochDays)
; Output: OP1: RpnDate
; Destroys: all, OP1-OP6
EpochDaysToRpnDate:
    ; get relative epochDays
    ld hl, OP2 ; TODO: I think this needs to be OP3
    call ConvertOP1ToI40 ; OP2=i40(epochDays)
epochDaysU40ToRpnDate:
    ; convert relative epochDays to internal epochDays
    ld hl, epochDate
    ld de, OP1
    call dateToInternalEpochDays ; DE=OP1=currentInternalEpochDays
    ld hl, OP1
    ld de, OP2
    call addU40U40 ; HL=OP1=internal epochDays
    call op1ToOp2PageOne ; OP2=internal epochDays
    ; convert internal epochDays to RpnDate
    ld hl, OP2
    ld de, OP1
    ld a, rpnObjectTypeDate
    ld (de), a
    inc de
    jp internalEpochDaysToDate ; DE=OP1+sizeof(RpnDate)

;-----------------------------------------------------------------------------

; Description: Convert the current epochSeconds (relative to the current
; epochDate) to an RpnDate{} object.
; Input: OP1: float(epochSeconds)
; Output: OP1: RpnDate
; Destroys: all, OP1-OP6
EpochSecondsToRpnDate:
    ; get relative epochSeconds
    ld hl, OP3 ; cannot be OP2
    call ConvertOP1ToI40 ; HL=OP3=i40(epochSeconds)
    call op3ToOp2PageOne ; OP2=epochSeconds
    ; divisor=86400
    ld hl, OP4
    ld a, 1
    ld bc, 20864 ; ABC=86400 seconds per day
    call setU40ToABC ; HL=OP4=86400
    ; divide epochSeconds by 86400 to get epochDays, truncate towards -infinity
    ex de, hl ; DE=OP4=86400
    ld hl, OP2 ; HL=OP2=epochSeconds
    ld bc, OP3
    call divI40U40 ; BC=OP3=remainder; HL=OP2=epochDays
    ;
    jr epochDaysU40ToRpnDate

;-----------------------------------------------------------------------------

; Description: Add (RpnDate plus days) or (days plus RpnDate).
; Input:
;   - OP1:Union[RpnDate,RpnReal]=rpnDate or days
;   - OP3:Union[RpnDate,RpnReal]=rpnDate or days
; Output:
;   - OP1:RpnDate=RpnDate+days
; Destroys: OP1, OP2, OP3-OP6
AddRpnDateByDays:
    call checkOp1DatePageOne ; ZF=1 if CP1 is an RpnDate
    jr nz, addRpnDateByDaysAdd
    call cp1ExCp3PageOne ; CP1=days; CP3=RpnDate
addRpnDateByDaysAdd:
    ; CP1=days, CP3=RpnDate
    call PushRpnObject3 ; FPS=[RpnDate]
    ld hl, OP3
    call ConvertOP1ToI40 ; HL=OP3=u40(days)
    ;
    call PopRpnObject1 ; FPS=[]; CP1=RpnDate
    call PushRpnObject3 ; FPS=[u40(days)]
    ;
    ld hl, OP1+1 ; HL=OP1+1=Date
    ld de, OP3
    call dateToInternalEpochDays ; OP3=u40(epochDays)
    call PopRpnObject1 ; FPS=[]; OP1=u40(days)
    ;
    ld hl, OP1
    ld de, OP3
    call addU40U40 ; HL=OP1=u40(epochDays+days)
    ;
    call op1ToOp2PageOne ; OP2=u40(epochDays+days)
    ld hl, OP2
    ld de, OP1
    ld a, rpnObjectTypeDate
    ld (de), a
    inc de
    jp internalEpochDaysToDate ; DE=OP1+sizeof(RpnDate)

;-----------------------------------------------------------------------------

; Description: Subtract RpnDate minus RpnDate or days.
; Input:
;   - OP1:RpnDate=Y
;   - OP3:RpnDate or days=X
; Output:
;   - OP1:(RpnDate-days) or (RpnDate-RpnDate).
; Destroys: OP1, OP2, OP3-OP6
SubRpnDateByRpnDateOrDays:
    call PushRpnObject3 ; FPS=[Date or days]
    ld de, OP3
    ld hl, OP1+1
    call dateToInternalEpochDays ; OP3=u40(Y.days)
    call exchangeFPSCP3PageOne ; FPS=[u40(Y.days)]; OP3=Date or days
    call checkOp3DatePageOne ; ZF=1 if type(OP3)==Date
    jr z, subRpnDateByRpnDate
    ; Subtract by OP3=days
    call op3ToOp1PageOne ; OP1=days
    ld hl, OP3
    call ConvertOP1ToI40 ; HL=OP3=u40(X.days)
    call PopRpnObject1 ; FPS=[]; OP1=u40(Y.days)
    ld hl, OP1
    ld de, OP3
    call subU40U40 ; HL=OP1=Y.days-X.days
    ; conver to RpnDate
    call op1ToOp2PageOne ; OP2=Y.days-X.days
    ld hl, OP2
    ld de, OP1
    ld a, rpnObjectTypeDate
    ld (de), a
    inc de
    jp internalEpochDaysToDate ; DE=OP1+sizeof(RpnDate)
subRpnDateByRpnDate:
    ; Subtract by OP3=Date
    ld de, OP1
    ld hl, OP3+1
    call dateToInternalEpochDays ; OP1=u40(days(X))
    call op1ToOp3PageOne ; OP3=u40(days(X))
    ;
    call PopRpnObject1 ; FPS=[]; OP1=u40(Y.days)
    ld hl, OP1
    ld de, OP3
    call subU40U40 ; HL=OP1=u40(Y.days)-u40(X.days)
    ;
    call op1ToOp3PageOne ; OP3=Y.days-X.days
    ld hl, OP3
    jp ConvertI40ToOP1 ; OP1=Y.date-X.date

;-----------------------------------------------------------------------------
; RpnDateTime functions.
;-----------------------------------------------------------------------------

; Description: Convert the RpnDateTime{} record in OP1 to epochSeconds relative
; to the current epochDate.
; Input: OP1:RpnDateTime=input
; Output: OP1:real
; Destroys: all, OP1-OP6
RpnDateTimeToEpochSeconds:
    ld hl, OP1
    call convertToOffsetDateTime ; preserves HL
    call rpnDateTimeToU40EpochSeconds
    jp ConvertI40ToOP1 ; OP1=float(OP3)

; Input: OP1:(DateTime*)=input
; Output: OP3:(u40*)=epochSeconds
rpnDateTimeToU40EpochSeconds:
    ; convert input to relative epochSeconds
    ld hl, OP1+1
    ld de, OP3
    call dateTimeToInternalEpochSeconds ; OP3=epochSeconds(input)
    call op3ToOp2PageOne ; OP2=internalEpochSeconds(input)
    ; convert current epochDate to current epochSeconds
    ; TODO: Replace this with pre-calculated currentEpochSeconds.
    ld hl, epochDate
    ld de, OP1
    call dateToInternalEpochDays ; DE=OP1=epochDays
    ex de, hl ; HL=OP1=epochDays
    call convertU40DaysToU40Seconds ; HL=OP1=epochSeconds
    ; convert relative epochSeconds to internal epochSeconds
    ld hl, OP3
    ld de, OP1
    call subU40U40 ; OP3=epochSeconds(input)-epochSeconds(currentEpochDate)
    ret

;-----------------------------------------------------------------------------

; Description: Convert the current epochSeconds (relative to the current
; epochDate) to an RpnDateTime{} record.
; Input: OP1: float(epochSeconds)
; Output: OP1: RpnDateTime
; Destroys: all, OP1-OP6
EpochSecondsToRpnDateTime:
    ; get relative epochSeconds
    ld hl, OP3 ; cannot be OP2
    call ConvertOP1ToI40 ; HL=OP3=i40(epochSeconds)
    call op3ToOp2PageOne ; OP2=relative epochSeconds
    ld hl, OP2
    ; set up OP1 as DateTime
    ld de, OP1
    ld a, rpnObjectTypeDateTime
    ld (de), a
    inc de
    ; [[fallthrough]]

; Description: Convert relative epochSeconds to DateTime.
; Input:
;   - HL=epochSeconds=usually OP2
;   - DE:(DateTime*)=result=usually OP1
; Output:
;   DE=DE+sizeof(DateTime)
;   (DE)=DateTime
; Destroys: all, OP1-OP6
epochSecondsToDateTime:
    push de ; stack=[result]
    push hl ; stack=[result,epochSeconds]
    ; get currentEpochSeconds
    ; TODO: Replace this with pre-calculated currentEpochSeconds.
    ld hl, epochDate
    ld de, OP3
    call dateToInternalEpochDays ; DE=OP3=currentEpochDays
    ex de, hl ; HL=OP3=epochDays
    call convertU40DaysToU40Seconds ; HL=OP3=currentEpochSeconds
    ;
    ex de, hl ; DE=OP3=currentEpochSeconds
    pop hl ; stack=[result]; HL=OP2=epochSeconds
    call addU40U40 ; HL=OP2=internal epochSeconds
    ; convert internal epochSeconds to RpnDateTime
    pop de ; stack=[]; DE=result
    jp internalEpochSecondsToDateTime ; DE=result=RpnDateTime{}

;-----------------------------------------------------------------------------

; Description: Add (RpnDateTime plus seconds) or (seconds plus RpnDateTime).
; Input:
;   - OP1:Union[RpnDateTime,RpnReal]=rpnDateTime or seconds
;   - OP3:Union[RpnDateTime,RpnReal]=rpnDateTime or seconds
; Output:
;   - OP1:RpnDateTime=RpnDateTime+seconds
;   - DE=OP1+sizeof(DateTime)
; Destroys: OP1, OP2, OP3-OP6
AddRpnDateTimeBySeconds:
    call checkOp1DateTimePageOne ; ZF=1 if CP1 is an RpnDateTime
    jr nz, addRpnDateTimeBySecondsAdd
    call cp1ExCp3PageOne ; CP1=seconds; CP3=RpnDateTime
addRpnDateTimeBySecondsAdd:
    ; CP1=seconds, CP3=RpnDateTime
    call PushRpnObject3 ; FPS=[RpnDateTime]
    ld hl, OP3
    call ConvertOP1ToI40 ; HL=OP3=u40(seconds)
    ;
    call PopRpnObject1 ; FPS=[]; CP1=RpnDateTime
    call PushRpnObject3 ; FPS=[u40(seconds)]
    ;
    ld hl, OP1+1 ; HL=OP1+1=DateTime
    ld de, OP3
    call dateTimeToInternalEpochSeconds ; OP3=u40(epochSeconds)
    call PopRpnObject1 ; FPS=[]; OP1=u40(seconds)
    ;
    ld hl, OP1
    ld de, OP3
    call addU40U40 ; HL=OP1=u40(epochSeconds+seconds)
    ;
    call op1ToOp2PageOne ; OP2=u40(epochSeconds+seconds)
    ld hl, OP2
    ld de, OP1 ; DE=OP1+1=DateTime
    ld a, rpnObjectTypeDateTime
    ld (de), a
    inc de
    jp internalEpochSecondsToDateTime ; DE=OP1+sizeof(DateTime)

;-----------------------------------------------------------------------------

; Description: Subtract RpnDateTime minus RpnDateTime or seconds.
; Input:
;   - OP1:RpnDateTime=Y
;   - OP3:RpnDateTime or seconds=X
; Output:
;   - OP1:(RpnDateTime-seconds) or (RpnDateTime-RpnDateTime).
; Destroys: OP1, OP2, OP3-OP6
SubRpnDateTimeByRpnDateTimeOrSeconds:
    call PushRpnObject3 ; FPS=[DateTime or seconds]
    ld de, OP3
    ld hl, OP1+1
    call dateTimeToInternalEpochSeconds ; OP3=u40(Y.seconds)
    call exchangeFPSCP3PageOne ; FPS=[u40(Y.seconds)]; OP3=DateTime or seconds
    call checkOp3DateTimePageOne ; ZF=1 if type(OP3)==DateTime
    jr z, subRpnDateTimeByRpnDateTime
    ; Subtract by OP3=seconds
    call op3ToOp1PageOne ; OP1=seconds
    ld hl, OP3
    call ConvertOP1ToI40 ; HL=OP3=u40(X.seconds)
    call PopRpnObject1 ; FPS=[]; OP1=u40(Y.seconds)
    ld hl, OP1
    ld de, OP3
    call subU40U40 ; HL=OP1=Y.seconds-X.seconds
    ;
    call op1ToOp2PageOne ; OP2=Y.seconds-X.seconds
    ld hl, OP2
    ld de, OP1
    ld a, rpnObjectTypeDateTime
    ld (de), a ; OP1:RpnDateTime
    inc de
    jp internalEpochSecondsToDateTime ; DE=OP1+sizeof(DateTime)
subRpnDateTimeByRpnDateTime:
    ; Subtract by OP3=DateTime
    ld de, OP1
    ld hl, OP3+1
    call dateTimeToInternalEpochSeconds ; OP1=u40(seconds(X))
    call op1ToOp3PageOne ; OP3=u40(seconds(X))
    ;
    call PopRpnObject1 ; FPS=[]; OP1=u40(Y.seconds)
    ld hl, OP1
    ld de, OP3
    call subU40U40 ; HL=OP1=u40(Y.seconds)-u40(X.seconds)
    ;
    call op1ToOp3PageOne ; OP3=Y.seconds-X.seconds
    ld hl, OP3
    jp ConvertI40ToOP1 ; OP1=Y.date-X.date

;-----------------------------------------------------------------------------
; Current EpochDate functions.
;-----------------------------------------------------------------------------

; Description: Set epochType and epochDate to UNIX (1970-01-01).
SelectUnixEpochDate:
    ld a, epochTypeUnix
    ld (epochType), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ld hl, unixDate
    jr setEpochDate

; Description: Set epochType and epochDate to NTP (1900-01-01).
SelectNtpEpochDate:
    ld a, epochTypeNtp
    ld (epochType), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ld hl, ntpDate
    jr setEpochDate

; Description: Set epochType and epochDate to GPS (1980-01-06).
SelectGpsEpochDate:
    ld a, epochTypeGps
    ld (epochType), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ld hl, gpsDate
    jr setEpochDate

; Description: Set epochType and epochDate to TIOS epoch (1997-01-01).
SelectTiosEpochDate:
    ld a, epochTypeTios
    ld (epochType), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ld hl, tiosDate
    jr setEpochDate

; Description: Set epochType and epochDate to the custom epochDate.
SelectCustomEpochDate:
    ld a, epochTypeCustom
    ld (epochType), a
    set dirtyFlagsMenu, (iy + dirtyFlags)
    ld hl, epochDateCustom
    jr setEpochDate

;-----------------------------------------------------------------------------

; Description: Set the current epoch to the date given in OP1.
; Input: OP1: RpnDate{}
; Output: (epochDate) updated
SetCustomEpochDate:
    call checkOp1DatePageOne ; ZF=1 if CP1 is an RpnDate
    jr nz, setCustomEpochDateErr
    ld hl, OP1+1
    call setEpochDateCustom
    jr SelectCustomEpochDate ; automatically select the Custom epoch date
setCustomEpochDateErr:
    bcall(_ErrDataType)

; Description: Get the current epoch date into OP1.
; Input: none
; Output: OP1=epochDate
GetCustomEpochDate:
    ld de, OP1
    ld a, rpnObjectTypeDate
    ld (de), a
    inc de
    ld hl, epochDateCustom
    ld bc, 4
    ldir
    ret

;-----------------------------------------------------------------------------

; Description: Copy the Date{} pointed by HL to (epochDateCustom).
; Input: HL:Date{}
; Output: (epochDate) updated
; Destroys: all
; Preserves: A
setEpochDateCustom:
    ld de, epochDateCustom
    ld bc, 4
    ldir
    ret

; Description: Copy the Date{} pointed by HL to (epochDate).
; Input: HL:Date{}
; Output: (epochDate) updated
; Destroys: all
; Preserves: A
setEpochDate:
    ld de, epochDate
    ld bc, 4
    ldir
    ret

;-----------------------------------------------------------------------------

unixDate:
    .dw 1970
    .db 1
    .db 1
ntpDate:
    .dw 1900
    .db 1
    .db 1
gpsDate:
    .dw 1980
    .db 1
    .db 6
tiosDate:
    .dw 1997
    .db 1
    .db 1
y2kDate:
    .dw 2000
    .db 1
    .db 1
