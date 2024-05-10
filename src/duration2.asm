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
    jp convertI40ToOP1 ; OP1=float(OP1)

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
    call convertOP1ToI40 ; OP1:i40=seconds
    call pushRaw9Op1 ; FPS=[seconds]; HL=seconds
    ex de, hl ; DE=seconds
    ld a, rpnObjectTypeDuration
    call setOp1RpnObjectTypePageTwo ; HL=OP1+sizeof(type)
    call secondsToDuration ; HL=resultDuration
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
    ; check for overflow, days must be < 2^15=32768
    ex de, hl ; DE=quotient=days; HL=divisor
    ld bc, 32768
    call setU40ToBC ; HL=32768
    ex de, hl ; HL=days; DE=32768
    call cmpU40U40
    jr nc, secondsToDurationPosOverflow
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
secondsToDurationPosOverflow:
    bcall(_ErrDomain)

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
    jr z, addRpnDurationBySecondsAdd
    call cp1ExCp3PageTwo ; CP1=rpnDuration; CP3=seconds
addRpnDurationBySecondsAdd:
    ; if here: CP1=rpnDuration, CP3=seconds
    call PushRpnObject1 ; FPS=[rpnDuration]; HL=rpnDuration
    push hl ; stack=[rpnDuration]
    ; convert real(seconds) to i40(seconds)
    call op3ToOp1PageTwo ; OP1:real=seconds
    call convertOP1ToI40 ; OP1:u40=seconds
    ; add duration+seconds
    pop hl ; stack=[]; HL=rpnDuration
    inc hl ; HL=duration
    ld de, OP1
    call addDurationBySeconds ; HL=newDuration
    ; clean up
    call PopRpnObject1 ; FPS=[]; OP1=newRpnDuration
    ret

; Description: Add Duration plus seconds.
; Input:
;   - DE:(i40*)=seconds
;   - HL:(Duration*)=duration
; Output:
;   - HL:(Duration*)=newDuration
; Destroys: A, BC
; Preserves: DE, HL
addDurationBySeconds:
    push hl ; stack=[duration]
    push de ; stack=[duration,seconds]
    ; convert duration to durationSeconds
    ex de, hl ; DE=duration
    call reserveRaw9 ; FPS=[durationSeconds]; HL=durationSeconds
    call durationToSeconds ; HL=durationSeconds
    ; add seconds
    pop de ; stack=[duration]; DE=seconds
    call addU40U40 ; HL=resultSeconds=durationSeconds+seconds
    ; convert durationSeconds to duration
    ex de, hl ; DE=resultSeconds; HL=seconds
    ex (sp), hl ; stack=[seconds]; HL=duration
    call secondsToDuration ; HL=duration filled
    ; clean up
    pop de ; stack=[]; DE=seconds
    call dropRaw9 ; FPS=[]
    ret

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
    ld a, rpnObjectTypeDuration
    call setOp1RpnObjectTypePageTwo ; HL=OP1+sizeof(type)
    call secondsToDuration ; (HL)=resultRpnDuration
    ; clean up
    call dropRaw9
    call dropRaw9
    ret

;-----------------------------------------------------------------------------

; Description: Subtract RpnDuration minus RpnDuration or seconds.
; Input:
;   - OP1:RpnDuration=Y
;   - OP3:RpnDuration or seconds=X
; Output:
;   - OP1:RpnDuration(RpnDuration-seconds) or
;   RpnDuration(RpnDuration-RpnDuration).
; Destroys: OP1, OP2
SubRpnDurationByRpnDurationOrSeconds:
    call getOp3RpnObjectTypePageTwo ; A=type; HL=OP3
    cp rpnObjectTypeReal ; ZF=1 if Real
    jr z, subRpnDurationBySeconds
    cp rpnObjectTypeDuration ; ZF=1 if Duration
    jr z, subRpnDurationByRpnDuration
    bcall(_ErrInvalid) ; should never happen
subRpnDurationBySeconds:
    ; exchage CP1/CP3, invert the sign, then call addRpnDurationBySecondsAdd()
    call cp1ExCp3PageTwo
    bcall(_InvOP1S) ; OP1=-OP1
    call cp1ExCp3PageTwo
    jr addRpnDurationBySecondsAdd
subRpnDurationByRpnDuration:
    ; convert OP3 to seconds
    call reserveRaw9 ; FPS=[seconds3]; HL=seconds3
    ld de, OP3+1 ; DE:(Duration*)
    call durationToSeconds ; HL=seconds3
    call negU40 ; HL=-seconds3
    ;
    ex de, hl ; DE=-seconds3
    ld hl, OP1+1
    call addDurationBySeconds ; OP1=duration1-duration3=>RpnDuration
    jp dropRaw9 ; FPS=[]

SubSecondsByRpnDuration:
    call cp1ExCp3PageTwo
    call SubRpnDurationByRpnDurationOrSeconds
    call ChsRpnDuration
    ret
