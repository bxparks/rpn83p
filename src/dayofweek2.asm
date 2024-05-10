;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; DayOfWeek functions.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Return the RpnDayOfWeek object of the given a date-like object
; (RpnDate, RpnDateTime, RpnOffsetDateTime).
; Input: OP1:RpnDate=date
; Output: OP1:RpnDayOfWeek=dow
; Destroys: all, OP3-OP5
RpnDateToDayOfWeek:
    ld hl, OP1+rpnObjectTypeSizeOf ; skip type byte
    call dateToDayOfWeekNumber ; A=[1,7]
    ld b, a ; B=dayOfWeek
    ; convert to RpnDayOfWeek
    ld a, rpnObjectTypeDayOfWeek
    call setOp1RpnObjectTypePageTwo ; HL=OP1+sizeof(type)
    ld (hl), b ; (HL)=dayOfWeek
    ret

; Description: Convert Date record to the ISO dayOfWeekNumber (1=Monday,
; 7=Sunday).
; Input: HL:DayOfWeek=dayOfWeek
; Output: A:u8=dayOfWeekNumber [1-7]
; Destroys: OP3-OP5
dateToDayOfWeekNumber:
    ex de, hl ; DE=inputDate
    ld hl, OP3
    call dateToInternalEpochDays ; HL=OP3=epochDays
    ex de, hl ; DE=OP3=epochDays
    ld a, 7
    ld hl, OP4
    call setU40ToA ; OP4=7
    ex de, hl ; HL=OP3=epochDays; DE=OP4=7
    ld bc, OP5 ; BC=OP5=remainder
    call divI40U40 ; HL=quotient; BC=remainder ; TODO: create modU40U40()
    ld a, (bc) ; A=remainder=0-6
    ; 2000-01-01 is epoch 0, so returns 0, but it was a Sat, so should be a 6.
    ; Readjust the result modulo 7 to conform to ISO weekday numbering.
    add a, 5
    cp 7
    jr c, dateToDayOfWeekNumberEnd
    sub 7
dateToDayOfWeekNumberEnd:
    inc a
    ret

;-----------------------------------------------------------------------------

; Description: Add (RpnDayOfWeek plus days) or (days plus RpnDayOfWeek).
; Input:
;   - OP1:Union[RpnDayOfWeek,RpnReal]=rpnDayOfWeek or days
;   - OP3:Union[RpnDayOfWeek,RpnReal]=rpnDayOfWeek or days
; Output:
;   - OP1:RpnDayOfWeek=RpnDayOfWeek+days
; Destroys: all, OP1-OP4
AddRpnDayOfWeekByDays:
    call checkOp1DayOfWeekPageTwo ; ZF=1 if CP1 is an RpnDayOfWeek
    jr nz, addRpnDayOfWeekByDaysAdd
    call cp1ExCp3PageTwo ; CP1=days; CP3=RpnDayOfWeek
addRpnDayOfWeekByDaysAdd:
    ; CP1=days, CP3=RpnDayOfWeek
    call convertOP1ToI40 ; HL=OP1=u40(days)
    ; convert CP3=RpnDayOfWeek to OP1=days
    ld a, (OP3+1) ; A=dayOfWeekNumber
    ld hl, OP2
    call setU40ToA ; HL=OP2=dayOfWeekNumber
    ; add days + dayOfWeekNumber
    ld de, OP1
    call addU40U40 ; HL=OP2=resultDayOfWeekNumber=dayOfWeek+days
    ; normalize the resultDayOfWeekNumber
    call decU40 ; HL=OP2=resultDayOfWeekNumber-=1; convert to 0-based
    ex de, hl ; DE=OP2=resultDayOfWeekNumber
    ld hl, OP3
    ld a, 7
    call setU40ToA ; HL=OP3=7
    ex de, hl ; HL=dividend=OP2=resultDayOfWeekNumber; DE=divisor=OP3=7
    ld bc, OP1+1 ; BC=OP1+1=remainder
    call divI40U40 ; BC=remainder, always positive
    ld l, c
    ld h, b ; HL=OP1+1=remainder
    call incU40 ; convert back to 1-based dayOfWeekNumber
    ; Convert DayOfWeek to RpnDayOfWeek
    dec hl ; HL=OP1=resultRpnDayOfWeek
    ld a, rpnObjectTypeDayOfWeek
    call setHLRpnObjectTypePageTwo ; HL+=sizeof(type)
    ret

;-----------------------------------------------------------------------------

; Description: Subtract RpnDayOfWeek minus RpnDayOfWeek or days.
; Input:
;   - OP1:RpnDayOfWeek=Y
;   - OP3:RpnDayOfWeek or days=X
; Output:
;   - OP1:RpnDayOfWeek(RpnDayOfWeek-days) or i40(RpnDayOfWeek-RpnDayOfWeek).
; Destroys: OP1, OP2, OP3-OP6
SubRpnDayOfWeekByRpnDayOfWeekOrDays:
    call checkOp3DayOfWeekPageTwo ; ZF=1 if type(OP3)==DayOfWeek
    jr z, subRpnDayOfWeekByRpnDayOfWeek
subRpnDayOfWeekByDays:
    ; exchage CP1/CP3, invert the sign, then call addRpnDayOfWeekByDaysAdd()
    call cp1ExCp3PageTwo
    bcall(_InvOP1S) ; OP1=-OP1
    jr addRpnDayOfWeekByDaysAdd
subRpnDayOfWeekByRpnDayOfWeek:
    ; convert both OP1 and OP3 to dayOfWeekNumber, then subtract
    ld a, (OP3+1)
    ld b, a ; B=OP3
    ld a, (OP1+1)
    sub a, b ; A=OP1-OP3=result
    ; convert to i40, then to float
    ld hl, OP1
    call setI40ToA ; HL=OP1=i40(result)
    jp convertI40ToOP1 ; OP1=float(i40)
