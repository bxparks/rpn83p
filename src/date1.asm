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

; Description: Validate that the given Date{} is a valid Gregorian calendar
; date between year 0000 and 9999, inclusive.
;
; TODO: Add the code to check for 0000 and 9999. Also, I think 0001 may make
; more sense, to avoid negative Gregorian era number in
; dateToInternalEpochDays().
;
; Input: HL:(*Date) pointer
; Output:
;   - CF=0 if not valid, 1 if valid
;   - HL=HL+4
; Destroys: A, BC, DE
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
    ret nc
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
    ret nc
    ; check special case for Feb
    ld a, e ; A=month-1
    cp 1 ; ZF=1 if month==Feb
    jr nz, validateDateOk
    ; if Feb and leap year: no additional testing needed
    call isLeapYear ; CF=1 if leap; preserves BC, DE, HL
    ret c
    ; if not leap year: check that Feb has max of 28 days
    ld a, d ; A=day-1
    cp 28 ; if day-1>=28: CF=0
    ret nc
validateDateOk:
    scf
    ret

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
; Output:
;   - CF=0 if not valid, 1 if valid
;   - HL=HL+3
; Destroys: A, HL
; Preserves: BC, DE
validateTime:
    ld a, (hl) ; A=hour
    inc hl
    cp 24
    ret nc ; if hour>=24: CF=0
    ld a, (hl) ; A=minute
    inc hl
    cp 60 ; if minute>=60: CF=0
    ret nc
    ld a, (hl) ; A=second
    inc hl
    cp 60
    ret

;-----------------------------------------------------------------------------

; Description: Convert RpnDate to RpnDateTime if necessary.
; Input: HL:RpnDate
; Output; HL:RpnDateTime
; Destroys: A
; Preserves: HL
ConvertToDateTime:
    ld a, (hl) ; A=rpnType
    cp rpnObjectTypeDateTime
    ret z
    ; convert RpnDate to RpnDateTime
    push hl
    ld a, rpnObjectTypeDateTime
    ld (hl), a
    inc hl ; year
    inc hl ; year+1
    inc hl ; month
    inc hl ; day
    inc hl ; hour
    ; set the Time{} part to 00:00:00
    xor a
    ld (hl), a ; hour=0
    inc hl
    ld (hl), a ; min=0
    inc hl
    ld (hl), a ; sec=0
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

; Description: Convert RpnDate{} object to epochDays relative to the current
; epochDate.
; Input:
;   - OP1:RpnDate
;   - (epochDate):Date{}=current epoch date
; Output:
;   - OP1:epochDays(RpnDate)
; Destroys: A, DE, BC, HL, OP1-OP3, OP4-OP6
RpnDateToEpochDays:
    ; convert input to epochDays
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
    ;
    call ConvertI40ToOP1 ; OP1=float(OP3)
    ret

; Description: Convert Date{} to internal epochDays.
;
; TODO: The internal epoch date is currently 2000-01-01 to make debugging
; easier (because the result is a small integer value for modern dates.) We can
; change it to anything we want, because this is used only internally.
; Algorithmically, it probably makes more sense to make the internal epoch date
; something like 0001-01-01 or 0000-01-01, because it would simplify some of
; the code below.
;
; NOTE: If we restrict the 'year' component to be less than 10,000, then the
; maximum number of days is 3,652,425, which would fit inside an i32 or u32. So
; all the u40 routines below could be replaced by U32 routines from baseops.asm
; routines if/when they are moved over to Flash Page 1. However, when the
; epochDays are converted to epochSeconds, then we will exceed the maximum
; value of i32 or u32 in 68 or 136 years, respectively. So the u40 routines
; would be required when working with seconds.
;
; Input:
;   - HL:Date{}, most likely OP1+1
;   - DE: resultPointer to u40, most likely OP3
; Output:
;   - u40(DE) updated
;   - HL=HL+4
; Destroys: A, BC, HL, OP4-OP6
; Preserves: DE
dateToEpochRecord equ OP4
dateToEpochYear equ OP4 ; year:u16
dateToEpochMonth equ OP4+2 ; month:u8
dateToEpochDay equ OP4+3 ; day:u8
dateToEpochEra equ OP4+4 ; era:u16
dateToEpochYearOfEra equ OP4+6 ; yearOfEra:u16
dateToEpochMonthPrime equ OP4+8 ; monthPrime:u8
dateToEpochDayOfEra equ OP5 ; dayOfEra:u40; also 'dayOfEpochPrime'
dateToEpochP1 equ OP5+5 ; param1:u40
dateToEpochP2 equ OP6 ; param2:u40
dateToEpochP3 equ OP6+5 ; param3:u40
dateToInternalEpochDays:
    push de ; stack=[resultPointer]
    ld de, dateToEpochRecord
    ld bc, 4
    ldir
    ex (sp), hl ; stack=[Date+4]; HL=resultPointer
    push hl ; stack=[Date+4, resultPointer]
    ; isLowMonth=(month <= 2) ? 1 : 0)
    ld a, (dateToEpochMonth) ; A=month
    ld hl, (dateToEpochYear) ; HL=year
    call yearToYearPrime ; HL=yearPrime
    ld (dateToEpochYear), hl ; dateToEpochYear=yearPrime
    ; era=yearPrime/400; yearOfEra=yearPrime%400
    ; TODO: This formulation does not work for dates before 0001-03-01.
    ld bc, 400
    call divHLByBC ; HL=era=yearPrime/400=[0,24]; DE=yearOfEra
    ld (dateToEpochEra), hl ; (dateToEpochEra)=era
    ld (dateToEpochYearOfEra), de ; (dateToEpochYearOfEra)=yearOfEra
    ; monthPrime=(month<=2) ? month+9 : month-3; [0,11]
    ld a, (dateToEpochMonth)
    call monthToMonthPrime
    ; daysUntilMonthPrime
    ld l, a
    ld h, 0 ; HL=monthPrime
    call daysUntilMonthPrime ; HL=daysUntilMonthPrime; destroys DE
    ; dayOfYearPrime=daysUntilMonthPrime+day-1
    ld a, (dateToEpochDay)
    call addHLByA ; HL=dayOfYearPrime+day
    dec hl ; HL=dayOfYearPrime=dayOfYearPrime+day-1
    ; Long section to calculate dayOfEra:
    ; dayOfEra=365*yearOfEra + (yearOfEra/4) - (yearOfEra/100) + dayOfYearPrime
    ld c, l
    ld b, h
    ld hl, dateToEpochDayOfEra
    call setU40ToBC ; dayOfEra=u40(dayOfYearPrime)
    ; yearOfEra/4
    ld bc, (dateToEpochYearOfEra)
    srl b
    rr c
    srl b
    rr c ; BC=yearOfEra/4
    ld hl, dateToEpochP1
    call setU40ToBC ; HL=P1=yearOfEra/4
    ; dayOfEra+=yearOfEra/4
    ex de, hl ; DE=P1=yearOfEra/4
    ld hl, dateToEpochDayOfEra
    call addU40U40 ; HL=dayOfEra+=yearOfEra/4
    ; yearOfEra/100
    ld bc, (dateToEpochYearOfEra)
    ld hl, dateToEpochP1
    call setU40ToBC ; P1=yearOfEra
    ld bc, 100
    ld hl, dateToEpochP2
    call setU40ToBC ; HL=P2=100
    ex de, hl ; DE=P2=100; HL=P1=yearOfEra
    ld bc, dateToEpochP3 ; BC=P3=remainder
    call divU40U40 ; HL=P1=yearOfEra/100; BC=P3=remainder
    ; dayOfEra-=yearOfEra/100
    ex de, hl ; DE=P1=yearOfEra/100
    ld hl, dateToEpochDayOfEra
    call subU40U40 ; HL=dayOEra-=yearOfEra/100
    ; yearOfEra*365
    ld bc, (dateToEpochYearOfEra)
    ld hl, dateToEpochP1
    call setU40ToBC ; HL=P1=yearOfEra
    ld bc, 365
    ex de, hl ; DE=P1=yearOfEra
    ld hl, dateToEpochP2
    call setU40ToBC ; HL=P2=365
    call multU40U40 ; HL=P2=365*yearOfEra
    ; dayOfEra+=yearOfEra*365
    ex de, hl ; DE=P2=365*yearOfEra
    ld hl, dateToEpochDayOfEra
    call addU40U40 ; HL=dayOfEra+=365*yearOfEra
    ; 146097*era
    ld bc, (dateToEpochEra) ; BC=era
    ld hl, dateToEpochP1
    call setU40ToBC ; HL=P1=era
    ex de, hl
    ld a, 2
    ld bc, 15025 ; ABC=146097
    ld hl, dateToEpochP2
    call setU40ToABC ; HL=P2=146097
    call multU40U40 ; HL=P2=146097*era
    ; dayOfEpochPrime=dayOfEra+14097*era
    ex de, hl ; DE=P2=146097*era
    ld hl, dateToEpochDayOfEra ; HL=dayOfEra
    call addU40U40 ; HL=dayOfEpochPrime=dayOfEra+146097*era
    ex de, hl ; DE=dayOfEpochPrime
    ; offset=-(kInternalEpochYear/400)*146097 + 60
    ;       =-(2000/400)*146097 + 60
    ;       =-730425
    ;       =-11*65536-9529
    ld a, 11
    ld bc, 9529
    ld hl, dateToEpochP1
    call setU40ToABC ; HL=P1=730425
    ; epochDays=dayOfEpochPrime-offset
    ex de, hl ; HL=dayOfEpochPrime; DE=offset
    call subU40U40 ; HL=epochDays=dayOfEpochPrime-offset
    ; copy to destination U40
    pop de ; stack=[Date+4]; DE=resultPointer
    push de ; stack=[Date+4, resultPointer]
    ld bc, 5
    ldir
    ;
    pop de ; stack=[Date+4]; DE=resultPointer
    pop hl ; stack=[]; HL=Date+4
    ret

; Description: Calculate yearPrime=year-((month<=2)?1:0).
; Input: HL=year; A=month
; Output: HL=yearPrime
; Destroys: A, BC
; Preserves: DE
yearToYearPrime:
    cp 3
    ret nc
    dec hl
    ret

; Description: Calculate monthPrime=(month<3) ? month+9 : month-3
; Input: A=month
; Output: A=monthPrime
; Destroys: A
; Preserves: BC, DE, HL
monthToMonthPrime:
    sub 3 ; if month>=3: CF=0
    ret nc
    add a, 12
    ret

; Description: Return the number of days until given monthPrime.
; Input: HL=monthPrime
; Output: HL=daysUntilMonthPrime=(153*monthPrime+2)/5
; Destroys: DE
daysUntilMonthPrime:
    ld bc, 153
    call multHLByBC ; HL=monthPrime*153
    inc hl
    inc hl ; HL=monthPrime*153+2
    ld c, 5
    call divHLByC ; HL=(153*monthPrime+2)/5
    ret

;-----------------------------------------------------------------------------

; Description: Convert the current epochDays (relative to the current
; epochDate) to an RpnDate{} record.
; Input: OP1: float(epochDays)
; Output: OP1: RpnDate
; Destroys: all, OP1-OP6
EpochDaysToRpnDate:
    ; get relative epochDays
    ld hl, OP2
    bcall(_ConvertOP1ToI40) ; OP2=i40(epochDays)
    ; convert relative epochDays to internal epochDays
    ld hl, epochDate
    ld de, OP1
    call dateToInternalEpochDays ; DE=OP1=currentInternalEpochDays
    ld hl, OP1
    ld de, OP2
    call addU40U40 ; HL=OP1=internal epochDays
    ; convert internal epochDays to RpnDate
    ld a, rpnObjectTypeDate
    ld (de), a
    inc de
    call internalEpochDaysToDate ; DE=OP2=RpnDate{}
    ;
    call op2ToOp1PageOne
    ret

; Description: Convert internal epochDays to Date{} record.
;
; TODO: The internal epoch date is currently 2000-01-01 to make debugging
; easier (because the result is a small integer value for modern dates.) We can
; change it to anything we want, because this is used only internally.
; Algorithmically, it probably makes more sense to make the internal epoch date
; something like 0001-01-01 or 0000-01-01, because it would simplify some of
; the code below.
;
; NOTE: If we restrict the 'year' component to be less than 10,000, then the
; maximum number of days is 3,652,425, which would fit inside an i32 or u32. So
; all the u40 routines below could be replaced by U32 routines from baseops.asm
; routines if/when they are moved over to Flash Page 1. However, when the
; epochDays are converted to epochSeconds, then we will exceed the maximum
; value of i32 or u32 in 68 or 136 years, respectively. So the u40 routines
; would be required when working with seconds.
;
; Input:
;   - HL:u40=epochDays
;   - DE:Date{}, probably OP2+1
; Output: (DE) updated, cannot be OP3-OP6
; Destroys: A, BC, OP3-OP6
; Preserves: DE, HL
epochToDateYearPrime equ OP3 ; u16
epochToDateMonthPrime equ OP3+2 ; u8; also holds monthPrime->month
epochToDateDay equ OP3+3 ; u8
epochToDateDayOfYearPrime equ OP3+4 ; u16
epochToDateEra equ OP3+6 ; u16
epochToDateYearOfEra equ OP3+8 ; u16
epochToDateP1 equ OP4 ; u40; epochDays; dayOfEpochPrime; era
epochToDateP2 equ OP4+5 ; u40; various consts
epochToDateP3 equ OP5 ; u40; dayOfEra
epochToDateP4 equ OP5+5 ; u40; sum, yearOfYear
epochToDateP5 equ OP6 ; u40; dividend (e.g. dayOfEra)
epochToDateP6 equ OP6+5 ; u40; remainder
internalEpochDaysToDate:
    push hl ; stack=[epochDays]
    push de ; stack=[epochDays, Date{}]
    ; ==== Calculate dayOfEpochPrime
    ; copy epochDays to P1
    ld de, epochToDateP1
    call copyU40 ; DE=P1=epochDays
    ; offset= 730425
    ld a, 11
    ld bc, 9529
    ld hl, epochToDateP2
    call setU40ToABC ; HL=P2=730425
    ; dayOfEpochPrime = epochDays+offset
    ex de, hl ; HL=P1=epochDays; DE=P2=730425
    call addU40U40 ; HL=P1=dayOfEpochPrime=epochDays+730425
    ; ==== Calculate era, dayOfEra
    ; P1=era=dayOfEpochPrime/146097;
    ; P3=dayOfEra=dayOfEpochPrime%146097;
    ; P2=146097
    ex de, hl ; DE=P1=dayOfEpochPrime
    ld a, 2
    ld bc, 15025 ; ABC=146097
    ld hl, epochToDateP2
    call setU40ToABC ; HL=P2=146097
    ex de, hl ; DE=P2=146097; HL=P1=dayOfEpochPrime
    ld bc, epochToDateP3
    call divU40U40 ; HL=P1=era; BC=P3=dayOfEra
    ; era=P1
    ld hl, (epochToDateP1)
    ld (epochToDateEra), hl
    ; ==== Calculate yearOfEra
    ; P3=dayOfEra
    ; P4=sum
    ld hl, epochToDateP3 ; HL=P3=dayOfEra
    ld de, epochToDateP4 ; DE=P4=sum
    call copyU40 ; DE=P4=sum=dayOfEra
    ; P5=P3=dayOfEra
    ld de, epochToDateP5
    call copyU40 ; DE=P5=dayOfEra
    ; P5=P5/146096=dayOfEra/146096.
    ; TODO: Replace divU40U40() with a cmpU40U40() to evaluate
    ; (dayOfEra==146096?1:0).
    ld a, 2
    ld bc, 15024 ; ABC=146096
    ld hl, epochToDateP2 ; HL=P2
    call setU40ToABC ; HL=P2=146096
    ex de, hl ; HL=P5=dayOfEra; DE=P2=146096
    ld bc, epochToDateP6 ; BC=P6=remainder
    call divU40U40 ; HL=P5=dayOfEra/146096; BC=P6=remainder
    ; P4=sum-=dayOfEra/146096
    ex de, hl ; DE=P5=dayOfEra/146096
    ld hl, epochToDateP4
    call subU40U40 ; HL=P4=sum
    ; P5=dayOfEra/36524
    ld bc, 36524
    ld hl, epochToDateP2
    call setU40ToBC ; HL=P2=36524
    ld de, epochToDateP5
    ld hl, epochToDateP3 ; HL=P3=dayOfEra
    call copyU40 ; DE=P5=dayOfEra
    ex de, hl ; HL=P5=dayOfEra
    ld de, epochToDateP2 ; DE=P2=36524
    ld bc, epochToDateP6 ; BC=P6=remainder
    call divU40U40 ; HL=P5=dayOfEra/36524
    ; P4=sum+=dayOfEra/36524
    ex de, hl ; DE=P5=dayOfEra/36524
    ld hl, epochToDateP4 ; HL=P4=sum
    call addU40U40 ; HL=P4=sum+=dayOfEra/36524
    ; P5=dayOfEra/1460
    ld bc, 1460
    ld hl, epochToDateP2
    call setU40ToBC ; HL=P2=1460
    ld de, epochToDateP5
    ld hl, epochToDateP3 ; HL=P3=dayOfEra
    call copyU40 ; DE=P5=dayToEra
    ex de, hl ; HL=P4=dayToEra
    ld de, epochToDateP2 ; DE=P2=1460
    ld bc, epochToDateP6 ; BC=P6=remainder
    call divU40U40 ; HL=P5=dayOfEra/1460
    ; P4=sum+=dayOfEra/1460
    ex de, hl ; DE=P5=dayOfEra/1460
    ld hl, epochToDateP4 ; HL=P4=sum
    call subU40U40 ; HL=P4=sum-=dayOfEra/1460
    ; P4=yearOfEra=sum/365
    ld bc, 365
    ld hl, epochToDateP2
    call setU40ToBC ; HL=P2=365
    ex de, hl ; DE=P2=365
    ld hl, epochToDateP4 ; HL=P4=sum
    ld bc, epochToDateP6 ; BC=P6=remainder
    call divU40U40 ; HL=P4=yearOfEra=sum/365
    ; yearOfEra=P4
    ld hl, (epochToDateP4)
    ld (epochToDateYearOfEra), hl
    ; ==== Calculate yearPrime
    ld bc, 400
    ld hl, (epochToDateEra)
    call multHLByBC ; HL=era*400
    ld bc, (epochToDateYearOfEra)
    add hl, bc; HL=yearPrime=era*400+yearOfEra
    ld (epochToDateYearPrime), hl ; yearPrime=HL
    ; ==== Calculate dayOfYearPrime
    ld hl, epochToDateP3 ; HL=P3=dayOfEra
    ld de, epochToDateP1 ; DE=P1=dayOfYearPrime
    call copyU40 ; DE=P1=dayOfYearPrime
    ; ---- Calculate yearOfEra*365
    ld bc, (epochToDateYearOfEra) ; BC=yearOfEra
    ld hl, epochToDateP4 ; HL=P4
    call setU40ToBC ; HL=P4=yearOfEra
    ex de, hl ; DE=P4=yearOfEra
    ld bc, 365
    ld hl, epochToDateP2 ; HL=P2
    call setU40ToBC ; HL=P2=365
    ex de, hl ; HL=P4=yearOfEra; DE=P2=365
    call multU40U40 ; HL=P4=yearOfEra*365
    ;
    ex de, hl ; DE=P4=yearOfEra*365
    ld hl, epochToDateP1 ; HL=P1=dayOfYearPrime
    call subU40U40 ; HL=P1=dayOfYearPrime-=yearOfEra*365
    ; ---- Calculate yearOfEra/4
    ld bc, (epochToDateYearOfEra) ; BC=yearOfEra
    ld hl, epochToDateP4 ; HL=P4
    call setU40ToBC ; HL=P4=yearOfEra
    ex de, hl ; DE=P4=yearOfEra
    ld bc, 4
    ld hl, epochToDateP2 ; HL=P2
    call setU40ToBC ; HL=P2=365
    ex de, hl ; HL=P4=yearOfEra; DE=P2=4
    ld bc, epochToDateP6 ; BC=P6=remainder
    call divU40U40 ; HL=P4=yearOfEra/4; TODO: replace with divU40ByD()
    ;
    ex de, hl ; DE=P4=yearOfEra/4
    ld hl, epochToDateP1 ; HL=P1=dayOfYearPrime
    call subU40U40 ; HL=P1=dayOfYearPrime-=yearOfEra/4
    ; ---- Calculate yearOfEra/100
    ld bc, (epochToDateYearOfEra) ; BC=yearOfEra
    ld hl, epochToDateP4 ; HL=P4
    call setU40ToBC ; HL=P4=yearOfEra
    ex de, hl ; DE=P4=yearOfEra
    ld bc, 100
    ld hl, epochToDateP2 ; HL=P2
    call setU40ToBC ; HL=P2=100
    ex de, hl ; HL=P4=yearOfEra; DE=P2=100
    ld bc, epochToDateP6 ; BC=P6=remainder
    call divU40U40 ; HL=P4=yearOfEra/100; TODO: replace with divU40ByD()
    ;
    ex de, hl ; DE=P4=yearOfEra/100
    ld hl, epochToDateP1
    call addU40U40 ; HL=P1=dayOfYearPrime+=yearOfEra/100
    ; ---- Save dayOfYearPrime
    ld hl, (epochToDateP1)
    ld (epochToDateDayOfYearPrime), hl
    ; ==== Calculate monthPrime=(5*dayOfYearPrime+2)/153
    ld c, l
    ld b, h
    add hl, hl
    add hl, hl
    add hl, bc ; HL=5*dayOfYearPrime
    inc hl
    inc hl ; HL=5*dayOfYearPrime+2
    ld c, 153
    call divHLByC ; HL=monthPrime=(5*dayOfYearPrime+2)/153
    ld a, l
    ld (epochToDateMonthPrime), a ; monthPrime=L
    ; ==== Calculate daysUntilMonthPrime
    call daysUntilMonthPrime ; HL=daysUntilMonthPrime
    ; ==== Calculate day, month, year
    ; day
    ex de, hl ; DE=daysUntilMonthPrime
    ld hl, (epochToDateDayOfYearPrime) ; HL=dayOfYearPrime
    or a ; CF=0
    sbc hl, de ; HL=dayOfYearPrime-daysUntilMonthPrime
    inc hl ; HL=day=dayOfYearPrime-daysUntilMonthPrime+1
    ld a, l
    ld (epochToDateDay), a ; epochToDateDay=day
    ; month
    ld a, (epochToDateMonthPrime) ; A=monthPrime
    call monthPrimeToMonth ; A=month
    ld (epochToDateMonthPrime), a
    ; year
    ld hl, (epochToDateYearPrime) ; HL=yearPrime
    call yearPrimeToYear ; HL=year
    ; ==== update Date{}
    ex de, hl ; DE=year
    pop hl ; stack=[epochDays]; HL=Date{}
    push hl ; stack=[epochDays, Date{}]
    ; Date{}.year
    ld (hl), e
    inc hl
    ld (hl), d ; yearPrime=year
    inc hl
    ; Date{}.month
    ld a, (epochToDateMonthPrime)
    ld (hl), a
    inc hl
    ; Date{}.day
    ld a, (epochToDateDay)
    ld (hl), a
    pop de ; stack=[epochDays]; DE=Date{}
    pop hl ; stack=[]; HL=epochDays
    ret

; Description: Convert monthPrime to normal month where `month = (monthPrime <
; 10) ? monthPrime+3 : monthPrime-9`. So that Mar(0)-> 3, Apr(1)->4, ..., Dec
; (9)->12, Jan(10)->1, Feb(11)->2.
; Input: A=monthPrime [0,11]
; Otuput: A=month [1,12]
monthPrimeToMonth:
    sub 10
    jr nc, monthPrimeToMonthInc
    add a, 12
monthPrimeToMonthInc:
    inc a
    ret

; Description: Convert yearPrime to normal year, where `year =
; yearPrime + ((month<=2)?1:0)`, so that the yearPrime for Jan and Feb is
; incremented by 1 to get the actual year.
; Input: HL=yearPrime; A=month
; Output; HL=year
; Destroys: HL
yearPrimeToYear:
    cp 3 ; CF=1 if month<=2
    ret nc
    inc hl
    ret

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
    ld de, OP1+1 ; DE=OP1+1=Date
    call internalEpochDaysToDate ; DE=OP1+1:Date=newDate
    ;
    ld a, rpnObjectTypeDate
    ld (OP1), a ; OP1:RpnDate=newRpnDate
    ret

;-----------------------------------------------------------------------------

; Description: Add (RpnDateTime plus seconds) or (seconds plus RpnDateTime).
; Input:
;   - OP1:Union[RpnDateTime,RpnReal]=rpnDateTime or seconds
;   - OP3:Union[RpnDateTime,RpnReal]=rpnDateTime or seconds
; Output:
;   - OP1:RpnDateTime=RpnDateTime+seconds
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
    ld de, OP1+1 ; DE=OP1+1=DateTime
    call internalEpochSecondsToDateTime ; DE=OP1+1:DateTime=newDateTime
    ;
    ld a, rpnObjectTypeDateTime
    ld (OP1), a ; OP1:RpnDateTime=newRpnDateTime
    ret

;-----------------------------------------------------------------------------

; Description: Subtract RpnDate minus Date or days.
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
    ;
    call op1ToOp2PageOne ; OP2=Y.days-X.days
    ld de, OP1+1
    ld hl, OP2
    call internalEpochDaysToDate ; OP1+1:Date
    ;
    ld a, rpnObjectTypeDate
    ld (OP1), a ; OP1:RpnDate
    ret
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

; Description: Subtract RpnDateTime minus DateTime or seconds.
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
    ld de, OP1+1
    ld hl, OP2
    call internalEpochSecondsToDateTime ; OP1+1:DateTime
    ;
    ld a, rpnObjectTypeDateTime
    ld (OP1), a ; OP1:RpnDateTime
    ret
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

; Description: Convert the RpnDate{} record in OP1 to epochSeconds relative to
; the current epochDate.
; Input: OP1:RpnDateTime=input
; Output: OP1:real
; Destroys: all, OP1-OP6
RpnDateTimeToEpochSeconds:
    ; convert input to relative epochSeconds
    ld hl, OP1+1
    ld de, OP3
    call dateTimeToInternalEpochSeconds ; OP3=epochSeconds(input)
    call op3ToOp2PageOne ; OP2=internalEpochSeconds(input)
    ; convert current epochDate to current epochSeconds
    ld hl, epochDate
    ld de, OP1
    call dateToInternalEpochDays ; DE=OP1=epochDays
    ex de, hl ; HL=OP1=epochDays
    call convertU40DaysToU40Seconds ; HL=OP1=epochSeconds
    ; convert relative epochSeconds to internal epochSeconds
    ld hl, OP3
    ld de, OP1
    call subU40U40 ; OP3=epochSeconds(input)-epochSeconds(currentEpochDate)
    ;
    call ConvertI40ToOP1 ; OP1=float(OP3)
    ret

; Description: Convert DateTime{} record to epochSeconds.
; Input:
;   - HL:(DateTime*): dateTime, most likely OP1+1
;   - DE:(u40*)=resultPointer, most likely OP3
; Output:
;   - (*DE)=result
; Destroys: A, BC, OP4-OP6
dateTimeToInternalEpochSeconds:
    call dateToInternalEpochDays ; DE=epochDays; HL=timePointer=dateTime+4
    push hl ; stack=[timePointer]
    ; convert days to seconds
    ld hl, OP4
    ld a, 1
    ld bc, 20864 ; ABC=86400 seconds per day
    call setU40ToABC ; HL=OP4=86400
    ex de, hl ; HL=result; DE=OP4=86400
    call multU40U40 ; HL=result=86400*epochDays
    ; convert time to seconds
    ex (sp), hl ; stack=[resultPointer]; HL=timePointer
    ex de, hl ; DE=timePointer
    ld hl, OP5
    call hmsToSeconds ; HL=OP5=timeSeconds
    ; add timeSeconds to epochDays*86400
    ex de, hl ; DE=OP5=timeSeconds
    pop hl ; stack=[]; HL=resultPointer
    call addU40U40 ; HL=result=epochDays*86400+timeSeconds
    ret

; Description: Convert (hh,mm,ss) to seconds.
; Input:
;   - DE: pointer to 3 bytes (hh,mm,ss).
;   - HL: pointer to u40 result
; Output:
;   - (HL): updated
;   - DE=DE+3
; Destroys: A, DE
; Preserves: BC, HL
hmsToSeconds:
    push hl ; stack=[result]
    ; read hour
    ld a, (de)
    inc de
    call setU40ToA ; HL=A
    ; multiply by 60
    ld a, 60
    call multU40ByA ; HL=result=HL*60
    ; add minute
    ld a, (de)
    inc de
    call addU40ByA ; HL=HL+A
    ; multiply by 60
    ld a, 60
    call multU40ByA ; HL=HL*60
    ; add second
    ld a, (de)
    inc de
    call addU40ByA ; HL=HL+A
    pop hl ; HL=result
    ret

;-----------------------------------------------------------------------------

EpochSecondsToRpnDateTime:
    ; get relative epochSeconds
    ld hl, OP2
    bcall(_ConvertOP1ToI40) ; OP2=i40(epochSeconds)
    ; convert relative epochSeconds to internal epochSeconds
    ld hl, epochDate
    ld de, OP1
    call dateToInternalEpochDays ; DE=OP1=epochDays
    ex de, hl ; HL=OP1=epochDays
    call convertU40DaysToU40Seconds ; HL=OP1=epochSeconds
    ld de, OP2
    call addU40U40 ; HL=OP1=internal epochSeconds
    ; convert internal epochSeconds to RpnDateTime
    ld a, rpnObjectTypeDateTime
    ld (de), a
    inc de
    call internalEpochSecondsToDateTime ; DE=OP2=RpnDateTime{}
    ;
    call op2ToOp1PageOne
    ret

; Description: Convert internal epochSeconds to DateTime{} structure.
; Input:
;   - HL:(i40*)=epochSeconds, probably OP1
;   - DE:(DateTime*)=dateTime, probably OP2+1
; Output:
;   - *DE=dateTime result
; Destroys: A, BC, OP3-OP6
internalEpochSecondsToDateTime:
    push de ; stack=[dateTime]
    push hl ; stack=[dateTime,epochSeconds]
    ; (epochDays,seconds)=div2(epochSeconds,86400)
    ld a, 1
    ld bc, 20864 ; ABC=86400 seconds per day
    ld hl, OP3
    call setU40ToABC ; HL=OP4=86400
    ;
    ex de, hl ; DE=OP4=divisor=86400
    pop hl ; stack=[dateTime]; HL=epochSeconds
    ld bc, OP4 ; remainder
    call divI40U40 ; HL=epochDays; BC=OP4=seconds
    ;
    ex (sp), hl ; stack=[epochDays]; HL=dateTime
    push hl ; stack=[epochDays,dateTime]
    inc hl
    inc hl
    inc hl
    inc hl ; HL=dateTime+4
    ; ex bc, hl
    push hl
    push bc
    pop hl ; HL=OP4=remainder
    pop bc ; BC=dateTime+4
    call secondsToHms ; BC=dateTime+4 updated
    ;
    pop de ; stack=[epochDays]; DE=dateTime
    pop hl ; stack=[]; HL=epochDays
    jp internalEpochDaysToDate ; DE=date

; Description: Convert seconds in a day to (hh,mm,ss).
; Input:
;   - HL:(u40*)=secondsPointer
;   - BC:(Time*)=hmsPointer
; Output:
;   - HL: destroyed
;   - BC: updated
; Destroys: A, (HL)
; Preserves: BC, DE, HL
secondsToHms:
    push de
    inc bc
    inc bc
    ld d, 60
    ;
    call divU40ByD ; E=remainder; HL=quotient
    ld a, e
    ld (bc), a
    dec bc
    ;
    call divU40ByD ; E=remainder, HL=quotient
    ld a, e
    ld (bc), a
    dec bc
    ;
    ld a, (hl)
    ld (bc), a
    ;
    pop de
    ret

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
