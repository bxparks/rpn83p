;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; RpnDuration functions.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Convert RpnDuration to relative seconds.
; Input: OP1:RpnDuration
; Output: OP1:real
; Destroys: all, OP1-OP2
RpnDurationToSeconds:
    call pushRaw9Op1 ; FPS=[rpnDuration]; HL=rpnDuration
    inc hl ; skip type byte
    ex de, hl ; DE=duration
    ld hl, OP1
    call durationToSeconds ; DE=duration+5; HL=OP1=seconds
    call dropRaw9 ; FPS=[]
    jp ConvertI40ToOP1 ; OP1=float(OP1)

; Description: Convert Duration to relative seconds.
; Input:
;   - DE:(Duration*)=duration
;   - HL:(i40*)=resultSeconds
; Output:
;   - DE=DE+sizeof(Duration)
;   - (*HL):i40=resultSeconds filled
; Destroys: A
; Preserves, BC, HL
durationToSeconds:
    ex de, hl ; HL=duration
    call isDurationNegative ; CF=1 if negative
    ex de, hl ; DE=duration
    jr nc, durationToSecondsPos
    ;
    ex de, hl ; HL=duration
    call chsDuration ; (*HL)=-(*HL)
    ex de, hl ; DE=duration
    call durationToSecondsPos
    ex de, hl ; HL=duration
    call chsDuration ; (*HL)=-(*HL)
    ex de, hl ; DE=duration
    call negU40
    ret

; Description: Convert postive duration to seconds.
; Input:
;   - DE:(Duration*)=duration
;   - HL:(i40*)=resultSeconds
; Output:
;   - DE=DE+sizeof(Duration)
;   - (*HL):i40=resultSeconds filled
; Destroys: A
; Preserves, BC, HL
durationToSecondsPos:
    push bc
    call clearU40 ; resultSeconds=0
    ; read days
    ex de, hl
    ld c, (hl)
    inc hl
    ld b, (hl) ; BC=days
    inc hl
    ex de, hl
    call setU40ToBC ; HL=resultSeconds=days
    ld c, e
    ld b, d ; BC=duration, DE and HL will be used to multiply/add U40 numbers
    ; create buffer for the multiplier
    ex de, hl ; DE=resultSeconds
    call reserveRaw9 ; FPS=[operand]; HL=operand
    ex de, hl ; DE=operaand; HL=resultSeconds
    ; multiply then add hours
    ld a, 24
    ex de, hl ; DE=resultSeconds; HL=operand
    call setU40ToA ; HL=operand=24
    ex de, hl ; DE=operand=24; HL=resultSeconds
    call multU40U40 ; HL=resultSeconds=days*24
    ;
    ld a, (bc) ; A=hours
    inc bc
    ex de, hl ; DE=resultSeconds; HL=operand
    call setU40ToA ; HL=operand=hours
    ex de, hl ; DE=operand; HL=resultSeconds
    call addU40U40 ; HL=resultSeconds*24+hours
    ; multiply then add minutes
    ld a, 60
    ex de, hl
    call setU40ToA
    ex de, hl
    call multU40U40 ; HL=resultSeconds=((days*24)+hours)*60
    ;
    ld a, (bc); A=minutes
    inc bc
    ex de, hl
    call setU40ToA
    ex de, hl
    call addU40U40 ; HL=resultSeconds=((days*24)+hours)*60+minutes
    ; multiply then add seconds
    ld a, 60
    ex de, hl
    call setU40ToA
    ex de, hl
    call multU40U40 ; HL=resultSeconds=(((days*24)+hours)*60+minutes)*60
    ;
    ld a, (bc); A=seconds
    inc bc
    ex de, hl
    call setU40ToA
    ex de, hl
    call addU40U40 ; HL=resultSeconds=(((days*24)+hours)*60+minutes)*60)+seconds
    ; clean up
    call dropRaw9 ; FPS=[]
    pop bc
    ret

;-----------------------------------------------------------------------------

; Description: Convert seconds to RpnDuration.
; Input:
;   - OP1:(i40*)=seconds
; Output:
;   - OP1:(RpnDuration*)=resultDuration
; Destroys: all, OP1-OP4
SecondsToRpnDuration:
    call ConvertOP1ToI40 ; OP1:i40=seconds
    call pushRaw9Op1 ; FPS=[seconds]; HL=seconds
    ex de, hl ; DE=seconds
    ld hl, OP1
    ld a, rpnObjectTypeDuration
    ld (hl), a
    inc hl ; HL=(Duration*)=resultDuration
    call secondsToDuration
    call dropRaw9
    ret

; Description: Convert seconds to Duration.
; Input:
;   - DE:(i40*)=seconds
;   - HL:(Duration*)=resultDuration
; Output:
;   - (*DE) destroyed
;   - (*HL) filled
; Destroys: A, BC
; Preserves: DE, HL
secondsToDuration:
    ; TODO: Check for overflow of i40(seconds).
    ex de, hl
    call isPosU40 ; ZF=1 if u40 positive or zero
    ex de, hl
    jr z, secondsToDurationPos
    ex de, hl ; HL=seconds
    call negU40
    ex de, hl ; DE=seconds; HL=resultDuration
    call secondsToDurationPos
    call chsDuration ; HL=-HL
    ret

; Description: Convert positive seconds to Duration.
; Input:
;   - DE:(u40*)=seconds
;   - HL:(Duration*)=resultDuration
; Output:
;   - (*DE) destroyed
;   - (*HL) filled
; Destroys: A, BC, IX
; Preserves: DE, HL
secondsToDurationPos:
    push hl
    pop ix ; IX=HL=resultDuration
    ; reserve slots on FPS
    call reserveRaw9 ; FPS=[remainder] ; HL=remainder
    ld c, l
    ld b, h ; BC=remainder
    call reserveRaw9 ; FPS=[remainder,divisor] ; HL=divisor
    ; divide by 60 and collect remainder seconds
    ld a, 60
    call setU40ToA; HL=OP2=divsor=60
    ex de, hl ; DE=OP2=60=divisor; HL=seconds=dividend/quotient
    call divU40U40 ; DE=divisor=60; HL=minutes; BC=remainderSeconds
    ld a, (bc) ; A=remainderSeconds
    ld (ix + 4), a ; duration.seconds=remainderSeconds
    ; divide by 60 to collect remainder minutes
    call divU40U40 ; DE=divisor; HL=hours; BC=remainderMinutes
    ld a, (bc) ; A=remainderMinutes
    ld (ix + 3), a ; duration.minutes=remainderMinutes
    ; divide by 24 to get remainder hours
    ex de, hl ; DE=quotient; HL=divisor
    ld a, 24
    call setU40ToA ; HL=divisor=24
    ex de, hl
    call divU40U40 ; DE=divisor=24; HL=days; BC=remainderDays
    ld a, (bc) ; A=remainderHours
    ld (ix + 2), a ; duration.hours=remainderHours
    ; extract remaining days
    ld a, (hl)
    ld (ix + 0), a
    inc hl
    ld a, (hl)
    ld (ix + 1), a ; duration.days=days
    dec hl ; HL=quotient=original seconds
    ; clean up
    call dropRaw9 ; FPS=[remainder]
    call dropRaw9 ; FPS=[]
    ex de, hl ; DE=original seconds
    push ix
    pop hl ; HL=IX=resultDuration
    ret

;-----------------------------------------------------------------------------

; Description: Return CF=1 if Duration is negative. CF=0 if zero or positive.
; Input:
;   - HL:(Duration*)=duration
; Output:
;   - CF=1 if negative, 0 if positive or zero
; Destroys: A
; Preserves: BC, DE, HL
isDurationNegative:
    push hl
    inc hl
    ld a, (hl) ; days
    inc hl
    bit 7, a
    jr nz, isNegativeTrue
    ;
    ld a, (hl) ; hours
    inc hl
    bit 7, a
    jr nz, isNegativeTrue
    ;
    ld a, (hl) ; minutes
    inc hl
    bit 7, a
    jr nz, isNegativeTrue
    ;
    ld a, (hl) ; seconds
    inc hl
    bit 7, a
    jr nz, isNegativeTrue
isNegativeFalse:
    pop hl
    or a
    ret
isNegativeTrue:
    pop hl
    scf
    ret

;-----------------------------------------------------------------------------

; Description: Change the sign of the RpnDuration.
; Input:
;   - OP1:(RpnDuration*)=duration
; Output:
;   - (*OP1)=-(*OP1)
; Destroys: A
; Preserves: BC, DE, HL
ChsRpnDuration:
    ld hl, OP1
    inc hl
    ; [[fallthrough]]

; Description: Change the sign of the Duration.
; Input:
;   - HL:(Duration*)=duration
; Output:
;   - (*HL)=-(*HL)
; Destroys: A
; Preserves: BC, DE, HL
chsDuration:
    push hl
    ld a, (hl)
    neg
    ld (hl), a
    inc hl
    ;
    ld a, 0
    sbc a, (hl)
    ld (hl), a ; days=-days
    inc hl
    ;
    ld a, (hl)
    neg
    ld (hl), a ; hours=-hours
    inc hl
    ;
    ld a, (hl)
    neg
    ld (hl), a ; minutes=-minutes
    inc hl
    ;
    ld a, (hl)
    neg
    ld (hl), a ; seconds=-seconds
    ;
    pop hl
    ret

;-----------------------------------------------------------------------------

; Description: Add (RpnDuration plus seconds) or (seconds plus RpnDuration).
; Input:
;   - OP1:Union[RpnDuration,RpnReal]=rpnDuration or seconds
;   - OP3:Union[RpnDuration,RpnReal]=rpnDuration or seconds
; Output:
;   - OP1:RpnDuration=RpnDuration+seconds
; Destroys: all, OP1,OP2
AddRpnDurationBySeconds:
    call checkOp1DurationPageTwo ; ZF=1 if CP1 is an RpnDuration
    jr nz, addRpnDurationBySecondsAdd
    call cp1ExCp3PageTwo ; CP1=seconds; CP3=RpnDuration
addRpnDurationBySecondsAdd:
    ; CP1=seconds, CP3=RpnDuration
    call ConvertOP1ToI40 ; HL=OP1=i40(seconds)
    call pushRaw9Op1 ; FPS=[seconds]; HL=seconds
    ; convert CP3=RpnDuration to OP1=seconds
    ld de, OP3+1 ; DE=Duration
    ld hl, OP1
    call durationToSeconds ; HL=OP1=durationSeconds
    ; add seconds, durationSeconds
    call popRaw9Op2 ; FPS=[]; OP2=seconds
    ld de, OP2
    ld hl, OP1
    call addU40U40 ; HL=resultDays=durationSeconds+seconds
    ; convert seconds to OP1=RpnDuration
    call op1ToOp2PageTwo ; OP2=resultDays
    ld de, OP2
    ld hl, OP1
    ld a, rpnObjectTypeDuration
    ld (hl), a
    inc hl ; HL:(Duration*)=newDuration
    jp secondsToDuration ; HL=OP1+sizeof(Duration)

; Description: Add (RpnDuration plus RpnDuration).
; Input:
;   - OP1:Union[RpnDuration]=rpnDuration
;   - OP3:Union[RpnDuration]=rpnDuration
; Output:
;   - OP1:RpnDuration+=RpnDuration
; Destroys: all, OP1,OP2
AddRpnDurationByRpnDuration:
    call reserveRaw9 ; FPS=[seconds1]; HL=op1=seconds1
    ld de, OP1+1 ; DE:(Duration*)
    call durationToSeconds ; seconds1
    push hl ; stack=[seconds1]
    ;
    call reserveRaw9 ; FPS=[seconds3]; HL=op3=seconds3
    ld de, OP3+1
    call durationToSeconds ; seconds3
    ;
    pop de ; stack=[]; DE=seconds1
    call addU40U40 ; HL=resultSeconds=seconds3+seconds1
    ;
    ex de, hl ; DE=resultSeconds
    ld hl, OP1
    ld a, rpnObjectTypeDuration
    ld (hl), a
    inc hl ; HL:(Duration*)=newDuration
    call secondsToDuration ; HL=OP1=resultRpnDuration
    ; clean up
    call dropRaw9
    call dropRaw9
    ret
