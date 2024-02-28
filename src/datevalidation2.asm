;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Validation of various date-related records.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
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
ValidateDate:
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
ValidateTime:
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
; Input: HL:(DateTime*) pointer to {y,M,d,h,m,s}
; Output: HL=HL+7
; Destroys: A, HL
; Preserves: BC, DE
; Throws: Err:Invalid on failure
ValidateDateTime:
    call ValidateDate
    call ValidateTime
    ret

;-----------------------------------------------------------------------------

; Description: Validate the Offset object in HL. Restrict the range of the
; offset to "-24:00" to "+24:00" exclusive. Also verify that the sign of the
; hour and minute match. In other words, {0,0}, {0,30}, {1,0}, {8,30} {-1,0},
; {-8,-30}, are allowed, but {8,-30}, {-1,30}, {1,-30} are invalid.
;
; Input: HL:(Offset*) pointer to {h,m}
; Output: HL=HL+2
; Destroys: A, HL
; Preserves: BC, DE
; Throws: Err:Invalid on failure
ValidateOffset:
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

; Description: Validate the signs of 'hour' and 'minute' are compatible.
; Input:
;   - B:hour
;   - C:minute
; Output:
; Destroys: A
; Preserves: BC
; Throws: Err:Invalid if signs are not compatible
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
; Input: HL:(OffsetDateTime*) pointer to {y,M,d,h,m,s,oh,os}
; Output: HL=HL+9
; Destroys: A, HL
; Preserves: BC, DE
; Throws: Err:Invalid on failure
ValidateOffsetDateTime:
    call ValidateDate
    call ValidateTime
    call ValidateOffset
    ret

;-----------------------------------------------------------------------------

; Description: Validate the DayOfWeek object in HL. ISO dayOfWeek must be in
; the range of [1,7], starting on Monday.
; Input: HL:(DayOfWeek*) pointer to {dayOfWeek} record
; Output: HL=HL+1
; Destroys: A, HL
; Preserves: BC, DE
; Throws: Err:Invalid on failure
ValidateDayOfWeek:
    ld a, (hl) ; A=dayOfWeek
    inc hl
    or 0
    jr z, validateDayOfWeekErr ; if dayOfWeek==0: err
    cp dayOfWeekStringsLen ; if dayOfWeek>7: err
    jr nc, validateDayOfWeekErr
    ret
validateDayOfWeekErr:
    bcall(_ErrInvalid)

;-----------------------------------------------------------------------------

; Description: Validate the Duration object in HL. Restrict the range of the
; hours/minutes/seconds to "+/-24:59:59". Also verify that the signs of all the
; fields match.
;
; Input:
;   - HL:(Duration*) pointer to {days,hours,minutes,seconds}
; Output:
;   - HL=HL+sizeof(Duration)
; Destroys: A, HL
; Preserves: BC, DE
; Throws: Err:Invalid on failure
ValidateDuration:
    push hl
    call validateDurationSigns
    pop hl
    call validateDurationMagnitudes
    ret

; Description: Check that all the fields have the same sign. (There's got to be
; an easier way to do this, but the algorithm is complicated by the fact that a
; 0 is compatible with both positive and negative numbers. So the algorithm
; that came to my mind is that I check all four fields, and keep 2 counters:
;
;   1) the number of non-zero fields.
;   2) the number of sign bits of those non-zero fields.
;
; The final check for validity is that:
;
;   nonZeroCount==0 OR signBitCount==0 OR signBitCount==nonZeroCount
;
; Input:
;   - HL:(Duration*)=duration
; Output:
;   - HL=HL+sizeof(Duration)
;   - CF=1 if negative, 0 if positive or zero
; Throws: Err:Invalid if the signs of the fields are mixed
; Destroys: A, HL
; Preserves: BC, DE
validateDurationSigns:
    push bc
    ld bc, 0 ; B=signBitCount; C=nonZeroCount
    ; check days
    inc hl
    ld a, (hl)
    inc hl
    or (hl)
    jr z, validateDurationSignOfHours
    inc c
    bit 7, a
    jr z, validateDurationSignOfHours
    inc b
validateDurationSignOfHours:
    ld a, (hl)
    inc hl
    or a
    jr z, validateDurationSignOfMinutes
    inc c
    bit 7, a
    jr z, validateDurationSignOfMinutes
    inc b
validateDurationSignOfMinutes:
    ld a, (hl)
    inc hl
    or a
    jr z, validateDurationSignOfSeconds
    inc c
    bit 7, a
    jr z, validateDurationSignOfSeconds
    inc b
validateDurationSignOfSeconds:
    ld a, (hl)
    inc hl
    or a
    jr z, validateDurationSignsCheck
    inc c
    bit 7, a
    jr z, validateDurationSignsCheck
    inc b
validateDurationSignsCheck:
    ld a, c ; A=nonZeroCount
    or a
    jr z, validateDurationSignsEnd ; CF=0 if all zero
    ld a, b ; A=signBitCount
    or a
    jr z, validateDurationSignsEnd ; CF=0 if non-zeros are all positive
    cp c ; ZF=1 if nonZerCount==signBitCount
    scf ; CF=1 if negative
    jr z, validateDurationSignsEnd ; CF=1 if non-zeros are all negative
    jr validateDurationErr
validateDurationSignsEnd:
    pop bc
    ret

validateDurationErr:
    bcall(_ErrInvalid)

; Description: Validate the magnitudes of each field in the Duration object:
;   - days:i16, any value allowed
;   - hours:i8, abs(hours)<24
;   - minutes:i8, abs(minutes)<60
;   - seconds:i8, abs(seconds)<60
;
; Input:
;   - HL:(Duration*) pointer to {days,hours,minutes,seconds}
; Output:
;   - HL=HL+sizeof(Duration)
; Destroys: A, HL
; Preserves: BC, DE
; Throws: Err:Invalid on failure
validateDurationMagnitudes:
    inc hl
    inc hl ; any value allowed in 'days' field
    ;
    ld a, (hl) ; A=hours
    inc hl
    bit 7, a
    jr z, validateDurationMagnitudesPosHours
    neg
validateDurationMagnitudesPosHours:
    cp 24
    jr nc, validateDurationErr ; if hour>=24: err
    ;
    ld a, (hl) ; A=minutes
    inc hl
    bit 7, a
    jr z, validateDurationMagnitudesPosMinutes
    neg
validateDurationMagnitudesPosMinutes:
    cp 60
    jr nc, validateDurationErr
    ;
    ld a, (hl)
    inc hl
    bit 7, a
    jr z, validateDurationMagnitudesPosSeconds
    neg
validateDurationMagnitudesPosSeconds:
    cp 60
    jr nc, validateDurationErr
    ret
