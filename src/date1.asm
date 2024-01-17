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
    call yearPrime ; HL=yearPrime
    ld (dateToEpochYear), hl ; dateToEpochYear=yearPrime
    ; era=yearPrime/400; yearOfEra=yearPrime%400
    ld bc, 400
    call divHLByBC ; HL=era=yearPrime/400=[0,24]; DE=yearOfEra
    ld (dateToEpochEra), hl ; (dateToEpochEra)=era
    ld (dateToEpochYearOfEra), de ; (dateToEpochYearOfEra)=yearOfEra
    ; monthPrime=(month<=2) ? month+9 : month-3; [0,11]
    ld a, (dateToEpochMonth)
    call monthPrime
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
    ; offset=-(kInternalEpochYear/400)*146097 + 60
    ;       =-(2000/400)*146097 + 60
    ;       =-730425
    ;       =-11*65536-9529
    ex de, hl ; DE=dayOfEpochPrime
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
; Input:
;   - HL=year
;   - A=month
; Output:
;   - HL=yearPrime
; Destroys: A, BC
; Preserves: DE
yearPrime:
    ; isLowMonth=(month <= 2) ? 1 : 0)
    cp 3
    jr nc, yearPrimeLargeMonth
    ld a, 1
    jr yearPrimeContinue
yearPrimeLargeMonth:
    xor a
yearPrimeContinue:
    ld c, a
    ld b, 0 ; BC=isLowMonth
    or a ; CF=0
    sbc hl, bc ; HL=yearPrime=year-isLowMonth
    ret

; Description: Calculate monthPrime=(month<3) ? month+9 : month-3
; Input: A=month
; Output: A=monthPrime
; Destroys: A
; Preserves: BC, DE, HL
monthPrime:
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
