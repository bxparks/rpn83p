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
DayOfWeek:
    ld hl, OP1+1 ; skip type byte
    call dayOfWeekIso ; A=[1,7]
    ; convert to RpnDayOfWeek
    ld hl, OP1+1
    ld (hl), a
    dec hl
    ld a, rpnObjectTypeDayOfWeek
    ld (hl), a ; OP1:RpnDayOfWeek
    ret

; Description: Return the ISO day of week (1=Monday, 7=Sunday) of the given
; Date record.
; Input: HL:Date=date
; Output: A:u8=dow [1-7]
; Destroys: OP3-OP5
dayOfWeekIso:
    ex de, hl ; DE=inputDate
    ld hl, OP3
    call dateToInternalEpochDays ; HL=OP3=epochDays
    ex de, hl ; DE=OP3=epochDays
    ld a, 7
    ld hl, OP4
    call setU40ToA ; OP4=7
    ex de, hl ; HL=OP3=epochDays; DE=OP4=7
    ld bc, OP5 ; BC=OP5=remainder
    call divU40U40 ; HL=quotient; BC=remainder ; TODO: create modU40U40()
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
