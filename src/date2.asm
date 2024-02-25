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
    call ConvertOP1ToU40 ; HL=u40(OP1) else Err:Domain
    ; TODO: Add domain check for 1<=year<=9999.
    ld c, (hl)
    inc hl
    ld b, (hl)
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
    call divHLByCPageTwo ; HL=quotient; A=remainder
    or a ; if remainder==0: ZF=1
    pop bc ; stack=[HL,DE]; BC=year
    jr nz, isLeapYearTrue
    ; check if divisible by 400
    push bc ; stack=[HL,DE,year]
    ld l, c
    ld h, b ; HL=year
    ld bc, 400
    call divHLByBCPageTwo ; HL=quotient; DE=remainder
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
    call checkOp1DatePageTwo ; ZF=1 if CP1 is an RpnDate
    jr nz, addRpnDateByDaysAdd
    call cp1ExCp3PageTwo ; CP1=days; CP3=RpnDate
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
    call op1ToOp2PageTwo ; OP2=resultDays
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
    call checkOp3DatePageTwo ; ZF=1 if type(OP3)==Date
    jr z, subRpnDateByRpnDate
subRpnDateByDays:
    ; exchage CP1/CP3, invert the sign, then call addRpnDateByDaysAdd()
    call cp1ExCp3PageTwo
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
