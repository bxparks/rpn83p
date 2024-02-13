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
    ; select Unix epoch by default.
    call SelectUnixEpochDate
    ; Set the default custom epochDate to 2000-01-01
    ld hl, y2kEpochDate
    call setEpochDateCustom
    ; set current TimeZone to UTC initially
    ld hl, 0
    ld (timeZone), hl
    ret

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

; Description: Check if OP1 is a RpnOffsetDateTime.
; Output: ZF=1 if RpnOffsetDateTime
checkOp1OffsetDateTimePageOne:
    ld a, (OP1)
    and $1f
    cp rpnObjectTypeOffsetDateTime
    ret

; Description: Check if OP3 is a RpnOffsetDateTime.
; Output: ZF=1 if RpnOffsetDateTime
checkOp3OffsetDateTimePageOne:
    ld a, (OP3)
    and $1f
    cp rpnObjectTypeOffsetDateTime
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
; Throws: Err:DateType if input is the wrong type
convertToOffsetDateTime:
    ; check if already RpnOffsetDateTime
    ld a, (hl) ; A=rpnType
    and $1f
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

; Description: Convert RpnDateTime, RpnOffsetDateTime to RpnDate.
; Input: HL:(RpnDateTime*) or (RpnOffsetDateTime*)
; Output: HL:(RpnDate*)=rpnDate
; Destroys: A
; Preserves: BC, DE, HL
; Throws: Err:DateType if input is the wrong type
convertToDate:
    ld a, (hl) ; A=rpnType
    and $1f
    cp rpnObjectTypeTime
    ret z
    cp rpnObjectTypeDateTime
    jr z, convertToDateConvert
    cp rpnObjectTypeOffsetDateTime
    jr z, convertToDateConvert
    bcall(_ErrDataType)
convertToDateConvert:
    ld a, rpnObjectTypeDate
    ld (hl), a
    ret

; Description: Convert RpnDateTime, RpnOffsetDateTime to RpnTime.
; Input: HL:(RpnDateTime*) or (RpnOffsetDateTime*)
; Output: HL:(RpnTime*)=rpnTime
; Destroys: A
; Preserves: BC, DE, HL
; Throws: Err:DateType if input is the wrong type
convertToTime:
    ld a, (hl) ; A=rpnType
    and $1f
    cp rpnObjectTypeTime
    ret z
    cp rpnObjectTypeDateTime
    jr z, convertToTimeConvert
    cp rpnObjectTypeOffsetDateTime
    jr z, convertToTimeConvert
    bcall(_ErrDataType)
convertToTimeConvert:
    push bc ; stack=[BC]
    push de ; stack=[BC,DE]
    push hl ; stack=[BC,DE,rpnTime]
    ld a, rpnObjectTypeTime
    ld (hl), a
    ; move pointers to last Time field
    ld de, rpnObjectTypeDateTimeSizeOf-1
    add hl, de ; HL=last byte of old Time object
    ld e, l
    ld d, h
    dec de
    dec de
    dec de
    dec de ; DE=last byte of new Time object
    ld bc, 3
    lddr ; shift Time fields by 4 bytes to the left
    ; clean up stack
    pop hl ; stack=[BC,DE]; HL=rpnTime
    pop de ; stack=[BC]; DE=restored
    pop bc ; stack=[]; BC=restored
    ret

;-----------------------------------------------------------------------------
; Simple date functions.
;-----------------------------------------------------------------------------

; Description: Determine if OP1 is leap year.
; Input: OP1:Real=year
; Output: OP1:Real=1 or 0
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
; Destroys: OP3-OP5
DayOfWeekIso:
    ex de, hl ; DE=inputDate
    ld hl, OP3
    call dateToInternalEpochDays ; HL=OP3=epochDays
    ex de, hl ; DE=OP3=epochDays
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
;   - OP1:(RpnDate*)=rpnDate
;   - (epochDate):Date{}=reference epoch date
; Output:
;   - OP1:(i40*)=epochDays
; Destroys: A, DE, BC, HL, OP4-OP6
RpnDateToEpochDays:
    ; reserve 2 slots on FPS
    call pushRaw9Op2 ; FPS=[epochDays]; HL=epochDays
    ex de, hl ; DE=epochDays
    call pushRaw9Op1 ; FPS=[epochDays,rpnDate]; HL=i40*=rpnDate
    inc hl ; HL=Date
    ; do conversion
    ex de, hl ; DE=rpnDate; HL=epochDays
    call dateToEpochDays ; HL=epochDays
    ; copy back to OP1
    call dropRaw9 ; FPS=[epochDays]
    call popRaw9Op1 ; FPS=[]; OP1=epochDays
    call ConvertI40ToOP1 ; OP1=float(epochDays)
    ret

; Description: Convert RpnDate{} to epochSeconds relative to the current
; epochDate.
; Input:
;   - OP1:(RpnDate*)=rpnDate
;   - (epochDate):Date{}=reference epoch date
; Output:
;   - OP1:(i40*)=epochSeconds
; Destroys: A, DE, BC, HL, OP1-OP3, OP4-OP6
RpnDateToEpochSeconds:
    ; reserve 2 slots on FPS
    call pushRaw9Op2 ; FPS=[epochDays]; HL=epochDays
    ex de, hl ; DE=epochDays
    call pushRaw9Op1 ; FPS=[epochDays,RpnDate]; HL=rpnDate
    inc hl ; HL=Date
    ; convert to days
    ex de, hl ; DE=rpnDate; HL=epochDays
    call dateToEpochDays ; HL=(i40*)=epochDays
    ; convert to seconds
    call convertU40DaysToU40Seconds ; HL=epochSeconds
    ; copy back to OP1
    call dropRaw9 ; FPS=[epochSeconds]
    call popRaw9Op1 ; FPS=[]; OP1=epochSeconds
    call ConvertI40ToOP1 ; OP1=float(epochSeconds)
    ret

; Description: Convert Date{} to relative epochSeconds.
; Input:
;   - DE:(Date*)=inputDate, must not be OPx
;   - HL:(i40*)=resultDays, must not be OPx
; Output:
;   - DE=DE+sizeof(Date)
;   - (*HL)=i40=resultDays
; Preserves: DE
dateToEpochDays:
    ; convert given date to internal epochDays
    call dateToInternalEpochDays ; HL=epochDays
    push de ; stack=[date+4]
    push hl ; stack=[date+4,resultDays]
    ; convert reference epochDate to refEpochDays
    ; TODO: precompute the refEpochDays
    call reserveRaw9 ; FPS=[refEpochDays]; HL=refEpochDays
    ld de, epochDate
    call dateToInternalEpochDays ; HL=refEpochDays
    ; convert to relative epochDays
    ex de, hl ; DE=refEpochDays
    pop hl ; stack=[date+4]; HL=resultDays
    call subU40U40 ; HL=resultDays=epochDays-refEpochDays
    ; clean up FPS
    call dropRaw9
    pop de ; stack=[]; DE=date+4
    ret

;-----------------------------------------------------------------------------

; Description: Convert the relative epochDays to an RpnDate{} record.
; Input: OP1:Real=epochDays
; Output: OP1:RpnDate
; Destroys: all, OP1-OP6
EpochDaysToRpnDate:
    call ConvertOP1ToI40 ; OP1:i40=epochDays
epochDaysToRpnDateAlt:
    ; reserve 2 slots on the FPS
    call pushRaw9Op1 ; FPS=[epochDays]; HL=epochDays
    ex de, hl ; DE=epochDays
    call reserveRaw9 ; FPS=[epochDays,rpnDate]; HL=rpnDate
    ; convert to RpnDate
    ld a, rpnObjectTypeDate
    ld (hl), a
    inc hl ; HL=RpnDate+1=Date
    call epochDaysToDate
    ; clean up FPS
    call popRaw9Op1
    jp dropRaw9

; Description: Convert the epochDays to Date.
; Input:
;   - DE:(u40*)=epochDays, must not be an OPx
;   - HL:(Date*)=resultDate, must not be an OPx
; Output:
;   - (HL): filled
;   - HL=HL+sizeof(Date)=HL+4
; Destroys: all, OP2, OP3-6
epochDaysToDate:
    push hl ; stack=[resultDate]
    push de ; stack=[resultDate,epochDays]
    ; TODO: precompute the refEpochDays
    ld de, epochDate
    ld hl, OP2
    call dateToInternalEpochDays ; HL=OP2=refEpochDays
    ; convert relative epochDays to internal epochDays
    ex de, hl ; DE=refEpochDays
    pop hl ; stack=[resultDate]; HL=epochDays
    call addU40U40 ; HL=internal epochDays
    ; convert internal epochDays to RpnDate
    ex de, hl ; DE=internalEpochDays
    pop hl ; stack=[]; HL=resultDate
    jp internalEpochDaysToDate ; HL=HL+sizeof(Date); (HL)=resultDate

;-----------------------------------------------------------------------------

; Description: Convert the relative epochSeconds to an RpnDate{} object.
; Input: OP1:Real=epochSeconds
; Output: OP1:RpnDate
; Destroys: all, OP1-OP6
EpochSecondsToRpnDate:
    ; get relative epochSeconds
    call ConvertOP1ToI40 ; HL=OP1=i40(epochSeconds)
    ; divisor=86400
    ld hl, OP2
    ld a, 1
    ld bc, 20864 ; ABC=86400 seconds per day
    call setU40ToABC ; HL=OP2=86400
    ; divide epochSeconds by 86400 to get epochDays, truncate towards -infinity
    ex de, hl ; DE=OP2=86400
    ld hl, OP1 ; HL=OP1=epochSeconds
    ld bc, OP3
    call divI40U40 ; BC=OP3=remainder; HL=OP1=epochDays
    ; convert to Date
    jr epochDaysToRpnDateAlt

;-----------------------------------------------------------------------------

; Description: Add (RpnDate plus days) or (days plus RpnDate).
; Input:
;   - OP1:Union[RpnDate,RpnReal]=rpnDate or days
;   - OP3:Union[RpnDate,RpnReal]=rpnDate or days
; Output:
;   - OP1:RpnDate=RpnDate+days
; Destroys: all, OP1, OP2, OP3-OP6
AddRpnDateByDays:
    call checkOp1DatePageOne ; ZF=1 if CP1 is an RpnDate
    jr nz, addRpnDateByDaysAdd
    call cp1ExCp3PageOne ; CP1=days; CP3=RpnDate
addRpnDateByDaysAdd:
    ; CP1=days, CP3=RpnDate
    call ConvertOP1ToI40 ; HL=OP1=u40(days)
    call pushRaw9Op1 ; FPS=[days]; HL=days
    ; convert CP3=RpnDate to OP1=days
    ld de, OP3+1 ; DE=Date
    ld hl, OP1
    call dateToInternalEpochDays ; HL=OP1=dateDays
    ; add days, dateDays
    call popRaw9Op2 ; FPS=[]; OP2=days
    ld de, OP2
    ld hl, OP1
    call addU40U40 ; HL=resultDays=dateDays+days
    ; convert days to OP1=RpnDate
    call op1ToOp2PageOne ; OP2=resultDays
    ld de, OP2
    ld hl, OP1
    ld a, rpnObjectTypeDate
    ld (hl), a
    inc hl ; HL:(Date*)=newDate
    jp internalEpochDaysToDate ; HL=OP1+sizeof(Date)

;-----------------------------------------------------------------------------

; Description: Subtract RpnDate minus RpnDate or days.
; Input:
;   - OP1:RpnDate=Y
;   - OP3:RpnDate or days=X
; Output:
;   - OP1:RpnDate(RpnDate-days) or i40(RpnDate-RpnDate).
; Destroys: OP1, OP2, OP3-OP6
SubRpnDateByRpnDateOrDays:
    call checkOp3DatePageOne ; ZF=1 if type(OP3)==Date
    jr z, subRpnDateByRpnDate
subRpnDateByDays:
    ; exchage CP1/CP3, invert the sign, then call addRpnDateByDaysAdd()
    call cp1ExCp3PageOne
    bcall(_InvOP1S) ; OP1=-OP1
    jr addRpnDateByDaysAdd
subRpnDateByRpnDate:
    ; convert OP3 to days, on FPS stack
    call reserveRaw9 ; make space on FPS=[X.days]; HL=X.days
    push hl ; stack=[X.days]
    ld de, OP3+1 ; DE=Date{}
    call dateToInternalEpochDays ; HL=FPS.X.days updated
    ; convert OP1 to days, on FPS stack
    call reserveRaw9 ; make space, FPS=[X.days,Y.days]; HL=Y.days
    push hl ; stack=[X.days,Y.days]
    ld de, OP1+1 ; DE=Date{}
    call dateToInternalEpochDays ; HL=FPS.Y.days updated
    ; subtract Y.days-X.days
    pop hl ; HL=Y.days
    pop de ; De=X.days
    call subU40U40 ; HL=Y.days-X.days
    ; pop result into OP1
    call popRaw9Op1 ; FPS=[X.days]; OP1=Y.days-X.days
    call ConvertI40ToOP1 ; OP1=float(i40)
    jp dropRaw9 ; FPS=[]

;-----------------------------------------------------------------------------
; RpnDateTime functions.
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
    call hmsToSeconds ; FPS.timeSeconds updated; DE=DE+sizeof(Time)
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
    ld de, epochDate
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
;   - DE=OP1+sizeof(DateTime)
; Destroys: OP1, OP2, OP3-OP6
AddRpnDateTimeBySeconds:
    call checkOp1DateTimePageOne ; ZF=1 if CP1 is an RpnDateTime
    jr nz, addRpnDateTimeBySecondsAdd
    call cp1ExCp3PageOne ; CP1=seconds; CP3=RpnDateTime
addRpnDateTimeBySecondsAdd:
    ; CP1=seconds, CP3=RpnDateTime
    call ConvertOP1ToI40 ; HL=OP1=u40(seconds)
    call pushRaw9Op1 ; FPS=[seconds]
    ; convert CP3=RpnDateTime to OP1=seconds
    ld de, OP3+1 ; DE=DateTime
    ld hl, OP1
    call dateTimeToInternalEpochSeconds ; HL=OP1=dateTimeSeconds
    ; add seconds, dateSeconds
    call popRaw9Op2 ; FPS=[]; OP2=seconds
    ld de, OP2
    ld hl, OP1
    call addU40U40 ; HL=OP1=resultSeconds=dateTimeSeconds+seconds
    ; convert seconds to OP1=RpnDateTime
    call op1ToOp2PageOne ; OP2=resultSeconds
    ld de, OP2
    ld hl, OP1
    ld a, rpnObjectTypeDateTime
    ld (hl), a
    inc hl ; HL:(DateTime*)=newDateTime
    jp internalEpochSecondsToDateTime ; HL=OP1+sizeof(DateTime)

;-----------------------------------------------------------------------------

; Description: Subtract RpnDateTime minus RpnDateTime or seconds.
; Input:
;   - OP1:RpnDateTime=Y
;   - OP3:RpnDateTime or seconds=X
; Output:
;   - OP1:(RpnDateTime-seconds) or (RpnDateTime-RpnDateTime).
; Destroys: OP1, OP2, OP3-OP6
SubRpnDateTimeByRpnDateTimeOrSeconds:
    call checkOp3DateTimePageOne ; ZF=1 if type(OP3)==DateTime
    jr z, subRpnDateTimeByRpnDateTime
subRpnDateTimeBySeconds:
    ; exchage CP1/CP3, invert the sign, then call addRpnDateTimeBySecondsAdd()
    call cp1ExCp3PageOne
    bcall(_InvOP1S) ; OP1=-OP1
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
