;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

ColdInitDate:
    ; select Unix epoch by default.
    call SelectUnixEpochDate
    ; Set the default customEpochDate to 2050-01-01
    ld hl, defaultCustomEpochDate
    call setCustomEpochDateVar
    ; set the appTimeZone to UTC initially
    ld hl, 0
    ld (appTimeZone), hl
    ret

;-----------------------------------------------------------------------------
; Simple date functions.
;-----------------------------------------------------------------------------

; Description: Determine if OP1 is leap year.
; Input: OP1:Real=year
; Output: OP1:Real=1 or 0
; Destroys: all
IsLeap:
    call convertOP1ToYear ; BC=year, [1,9999]
    call isLeapYear ; CF=1 if leap
    jr c, isLeapTrue
    bcall(_OP1Set0)
    ret
isLeapTrue:
    bcall(_OP1Set1)
    ret

; Description: Convert real number in OP1 to a u16 year in BC. Throws
; Err:Domain if year is outside the range of[1,9999].
; Input: OP1:Real=year
; Output: BC:u16=year in the range of [1,9999]
; Destroys: A, BC, DE, HL
convertOP1ToYear:
    call convertOP1ToU40 ; OP1=u40(OP1) else Err:Domain
    ld hl, OP1
    call testU40 ; ZF=1 if zero
    jr z, convertOP1ToYearErr
    ex de, hl ; DE=year
    call reserveRaw9 ; FPS=[operand]; HL=operand
    ld bc, 10000
    call setU40ToBC ; operand=10000
    ex de, hl ; HL=year; DE=10000
    call cmpU40U40 ; CF=0 if year>=10000
    jr nc, convertOP1ToYearErr
    ld c, (hl)
    inc hl
    ld b, (hl) ; BC=year
    call dropRaw9 ; FPS=[]
    ret
convertOP1ToYearErr:
    bcall(_ErrDomain)

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
; RpnDate functions.
;-----------------------------------------------------------------------------

; Description: Convert RpnDate{} to epochDays relative to the currentEpochDate.
; Input:
;   - OP1:(RpnDate*)=rpnDate
;   - (currentEpochDate):Date{}=reference epoch date
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
    call convertI40ToOP1 ; OP1=float(epochDays)
    ret

; Description: Convert RpnDate{} to epochSeconds relative to the
; currentEpochDate.
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
    call convertI40ToOP1 ; OP1=float(epochSeconds)
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
    ld de, currentEpochDate
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
    call convertOP1ToI40 ; OP1:i40=epochDays
epochDaysToRpnDateAlt:
    ; reserve 2 slots on the FPS
    call pushRaw9Op1 ; FPS=[epochDays]; HL=epochDays
    ex de, hl ; DE=epochDays
    call reserveRaw9 ; FPS=[epochDays,rpnDate]; HL=rpnDate
    ; convert to RpnDate
    ld a, rpnObjectTypeDate
    call setHLRpnObjectTypePageTwo ; HL+=sizeof(type)
    call epochDaysToDate ; (HL)=date
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
    ld de, currentEpochDate
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
    call convertOP1ToI40 ; HL=OP1=i40(epochSeconds)
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
    jr z, addRpnDateByDaysAdd
    call cp1ExCp3PageTwo ; CP1=rpnDate; CP3=days
addRpnDateByDaysAdd:
    ; if here: CP1=rpnDate, CP3=days
    ; Push CP1:Rpndate to FPS
    call PushRpnObject1 ; FPS=[rpnDate]; HL=rpnDate
    push hl ; stack=[rpnDate]
    ; convert real(seconds) to i40(seconds)
    call op3ToOp1PageTwo ; OP1:real=seconds
    call convertOP1ToI40 ; OP1:i40=seconds
    ; add date+days
    pop hl ; stack=[]; HL=rpnDate
    inc hl ; HL=date
    ld de, OP1 ; DE:i40=days
    call addDateByDays ; HL=newDate
    ; clean up
    call PopRpnObject1 ; FPS=[]; OP1=newRpnDate
    ret

; Description: Add (RpnDate plus duration) or (duration plus RpnDate).
; Input:
;   - OP1:Union[RpnDate,RpnDuration]=rpnDate or duration
;   - OP3:Union[RpnDate,RpnDuration]=rpnDate or duration
; Output:
;   - OP1:RpnDate=rpnDate+duration
; Destroys: all, OP1, OP2, OP3-OP6
AddRpnDateByDuration:
    call checkOp1DatePageTwo ; ZF=1 if CP1 is an RpnDate
    jr z, addRpnDateByDurationAdd
    call cp1ExCp3PageTwo ; CP1=rpnDate; CP3=duration
addRpnDateByDurationAdd:
    ; if here: CP1=rpnDate, CP3=duration
    ; Push CP1:rpnDate to FPS
    call PushRpnObject1 ; FPS=[rpnDate]; HL=rpnDate
    push hl ; stack=[rpnDate]
    ; Convert OP3:RpnDuration to days
    ld hl, OP3+1 ; DE:(Duration*)=duration
    ld c, (hl)
    inc hl
    ld b, (hl) ; BC=duration.days
    ld hl, OP1 ; HL:(i40*)=durationDays
    call setI40ToBC
    ; add date+durationDays
    pop hl ; stack=[]; HL=rpnDate
    inc hl ; HL=date
    ld de, OP1 ; DE:i40=duration
    call addDateByDays ; HL=newDate
    ; clean up
    call PopRpnObject1 ; FPS=[]; OP1=newRpnDate
    ret

; Description: Add Date plus days.
; Input:
;   - DE:(i40*)=days
;   - HL:(Date*)=date
; Output:
;   - HL:(Date*)=newDate
; Destroys: A, BC
; Preserves: DE, HL
addDateByDays:
    push hl ; stack=[date]
    push de ; stack=[date,days]
    ; convert date to dateDays
    ex de, hl ; DE=date
    call reserveRaw9 ; FPS=[dateDays]; HL=dateDays
    call dateToInternalEpochDays ; HL=dateDays
    ; add days
    pop de ; stack=[date]; DE=days
    call addU40U40 ; HL=resultDays=dateDays+days
    ; convert dateDays to date
    ex de, hl ; DE=resultDays; HL=days
    ex (sp), hl ; stack=[days]; HL=date
    call internalEpochDaysToDate ; HL=date filled
    ; clean up
    pop de ; stack=[]; DE=days
    call dropRaw9 ; FPS=[]
    ret

;-----------------------------------------------------------------------------

; Description: Subtract RpnDate minus RpnDate or days.
; Input:
;   - OP1:RpnDate=Y
;   - OP3:RpnDate or days=X
; Output:
;   - OP1:RpnDate(RpnDate-days) or i40(RpnDate-RpnDate).
; Destroys: OP1, OP2, OP3-OP6
SubRpnDateByObject:
    call getOp3RpnObjectTypePageTwo ; A=type; HL=OP3
    cp rpnObjectTypeReal ; ZF=1 if Real
    jr z, subRpnDateByDays
    cp rpnObjectTypeDate ; ZF=1 if Date
    jr z, subRpnDateByRpnDate
    cp rpnObjectTypeDuration ; ZF=1 if Duration
    jr z, subRpnDateByRpnDuration
    bcall(_ErrInvalid) ; should never happen
subRpnDateByDays:
    ; invert the sign of OP3=days, then call addRpnDateByDaysAdd()
    call cp1ExCp3PageTwo
    bcall(_InvOP1S) ; OP1=-OP1
    call cp1ExCp3PageTwo
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
    pop hl ; stack=[X.days]; HL=Y.days
    pop de ; stack=[]; DE=X.days
    call subU40U40 ; HL=Y.days-X.days
    ; pop result into OP1
    call popRaw9Op1 ; FPS=[X.days]; OP1=Y.days-X.days
    call convertI40ToOP1 ; OP1=float(i40)
    jp dropRaw9 ; FPS=[]
subRpnDateByRpnDuration:
    ; invert the sign of duration in OP3
    ld hl, OP3+1
    call chsDuration
    jr addRpnDateByDurationAdd
