;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
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
; Preserves: BC
isLeapYear:
    ld a, c
    and $03
    ret nz ; not leap, and CF=0 already
    ; check if divisible by 100
    push bc ; save
    ld l, c
    ld h, b ; HL=year
    ld c, 100
    call divHLByC ; HL=quotient; A=remainder
    or a ; if remainder==0: ZF=1
    pop bc
    jr nz, isLeapYearTrue
    ; check if divisible by 400
    push bc ; save
    ld l, c
    ld h, b ; HL=year
    ld bc, 400
    call divHLByBC ; HL=quotient; DE=remainder
    ld a, e
    or d ; if remainder==0: ZF=1
    pop bc
    ret nz ; if not multiple of 400: not leap
isLeapYearTrue:
    scf
    ret

;-----------------------------------------------------------------------------

; Description: Convert DateRecord to epochDays.
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
;   - HL: dateRecord, most likely OP1
;   - DE: u40Pointer, most likely OP3
; Output:
;   - u40(DE) updated
; Destroys: all, OP4-OP6
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
DateToEpochDays:
    push de ; save output U40
    inc hl ; skip type byte
    ld de, dateToEpochRecord
    ld bc, 4
    ldir
    ; isLowMonth=(month <= 2) ? 1 : 0)
    ld a, (dateToEpochMonth) ; A=month
    ld hl, (dateToEpochYear) ; HL=year
    call yearToYearPrime ; HL=yearPrime
    ld (dateToEpochYear), hl ; dateToEpochYear=yearPrime
    ; era=yearPrime/400; yearOfEra=yearPrime%400
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
    pop de ; DE=destination U40
    ld bc, 5
    ldir ; DE=u40 result
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

; Description: Convert epochDays to (year,month,day) record.
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
;   - HL:u40=pointerToEpochDays
;   - DE:DateRecord=pointerToDateRecord
; Output: (DE) updated
; Destroys: all, OP3-OP6
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
EpochDaysToDate:
    push de ; stack=[pointerToDateRecord]
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
    ; P5=P5/146096=dayOfEra/146096
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
    call divU40U40 ; HL=P4=yearOfEra/4
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
    call divU40U40 ; HL=P4=yearOfEra/100
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
    ; ==== update DateRecord
    ex de, hl ; DE=year
    pop hl ; stack=[]; HL=DateRecord
    ; DateRecord.type
    ld a, rpnObjectTypeDate
    ld (hl), a
    inc hl
    ; DateRecord.year
    ld (hl), e
    inc hl
    ld (hl), d ; yearPrime=year
    inc hl
    ; DateRecord.month
    ld a, (epochToDateMonthPrime)
    ld (hl), a
    inc hl
    ; DateRecord.day
    ld a, (epochToDateDay)
    ld (hl), a
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
