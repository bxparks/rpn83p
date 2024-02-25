;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; RpnTime functions.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Convert the RpnTime{} record in OP1 to number of seconds.
; Input: OP1:RpnTime=input
; Output: OP1:Real=seconds
; Destroys: all, OP1-OP2
RpnTimeToSeconds:
    ; reserve 2 slots on FPS
    call pushRaw9Op1 ; FPS=[rpnTime]; HL=rpnTime
    ex de, hl ; DE=rpnTime
    call reserveRaw9 ; FPS=[rpnTime,seconds]; HL=seconds
    ; convert to seconds
    inc de ; DE=time, skip type byte
    call timeToSeconds ; HL=seconds
    ; copy back to OP1
    call popRaw9Op1 ; FPS=[rpnTime]; OP1=seconds
    call dropRaw9 ; FPS=[]
    jp ConvertI40ToOP1 ; OP1=float(seconds)

; Description: Convert the seconds to an RpnTime{} object.
; Input: OP1:Real=seconds
; Output: OP1:RpnTime
; Destroys: all, OP1-OP2
; Throws: ErrDomain if seconds>=86400 (i.e. 24:00:00)
SecondsToRpnTime:
    ; get relative seconds
    call ConvertOP1ToU40 ; HL=OP1=u40(seconds)
    ex de, hl ; DE=seconds
    ; check OP1<86400
    ld hl, OP2
    ld a, 1
    ld bc, 20864 ; ABC=86400 seconds per day
    call setU40ToABC ; HL=OP2=86400
    ex de, hl ; HL=seconds; DE=86400
    call cmpU40U40 ; CF=0 if seconds>=86400
    jr nc, secondsToRpnTimeErr
    ; reserve 2 slots on the FPS
    call reserveRaw9 ; FPS=[rpnTime]; HL=rpnTime
    ex de, hl ; DE=rpnTime
    call pushRaw9Op1 ; FPS=[rpnTime,seconds]; HL=seconds
    ; convert to RpnTime
    ex de, hl ; DE=seconds; HL=rpnTime
    ld a, rpnObjectTypeTime
    ld (hl), a
    inc hl ; HL=rpnTime+1=dateTime
    call secondsToTime ; HL=HL+sizeof(Time)
    ; clean up FPS
    call dropRaw9
    jp popRaw9Op1
secondsToRpnTimeErr:
    bcall(_ErrDomain)

;-----------------------------------------------------------------------------

; Description: Convert Time{hh,mm,ss} to seconds.
; Input:
;   - DE:(Time*)=time
;   - HL:(u40*)=resultSeconds
; Output:
;   - (HL): updated
;   - DE=DE+3
; Destroys: A, DE
; Preserves: BC, HL
timeToSeconds:
    push hl ; stack=[resultSeconds]
    ; read hour
    ld a, (de)
    inc de
    call setU40ToA ; HL=A
    ; multiply by 60
    ld a, 60
    call multU40ByA ; HL=resultSeconds=HL*60
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
    pop hl ; HL=resultSeconds
    ret

;-----------------------------------------------------------------------------

; Description: Convert seconds in a day to Time{hh,mm,ss}.
; Input:
;   - DE:(u40*)=seconds
;   - HL:(Time*)=time
; Output:
;   - HL=HL+sizeof(Time)=HL+3
;   - (HL):filled
; Destroys: A, (seconds)
; Preserves: BC, DE
secondsToTime:
    push bc ; stack=[BC]
    push de ; stack=[BC,seconds]
    ld c, l
    ld b, h ; BC:Time*=time
    ex de, hl ; HL=seconds
    ; move to 'second' field
    inc bc
    inc bc
    ; fill second
    ld d, 60
    call divU40ByD ; E=remainder; HL=quotient
    ld a, e
    ld (bc), a
    dec bc
    ; fill minute
    call divU40ByD ; E=remainder, HL=quotient
    ld a, e
    ld (bc), a
    dec bc
    ; fill hour
    ld a, (hl)
    ld (bc), a
    ; move pointer past the Time{} record.
    inc bc
    inc bc
    inc bc
    ld l, c
    ld h, b ; HL=time+3
    pop de ; stack=[BC]; DE=seconds
    pop bc ; stack=[]; BC=restored
    ret

;-----------------------------------------------------------------------------
; RpnTime functions.
;-----------------------------------------------------------------------------

; Description: Add (RpnTime plus seconds) or (seconds plus RpnTime).
; Input:
;   - OP1:Union[RpnTime,RpnReal]=rpnTime or seconds
;   - OP3:Union[RpnTime,RpnReal]=rpnTime or seconds
; Output:
;   - OP1:RpnTime=RpnTime+seconds=always positive
; Destroys: all, OP1-OP4
AddRpnTimeBySeconds:
    call checkOp1TimePageTwo ; ZF=1 if CP1 is an RpnTime
    jr nz, addRpnTimeBySecondsAdd
    call cp1ExCp3PageTwo ; CP1=seconds; CP3=RpnTime
addRpnTimeBySecondsAdd:
    ; CP1=seconds, CP3=RpnTime
    call ConvertOP1ToI40 ; HL=OP1=u40(seconds)
    call pushRaw9Op1 ; FPS=[seconds]; HL=seconds
    ; convert CP3=RpnTime to OP1=seconds
    ld de, OP3+1 ; DE=Time
    ld hl, OP1
    call timeToSeconds ; HL=OP1=timeSeconds
    ; add seconds + timeSeconds
    call popRaw9Op2 ; FPS=[]; OP2=seconds
    ld de, OP2
    ld hl, OP1
    call addU40U40 ; HL=OP1=resultSeconds=dateSeconds+seconds
    ; Reduce the total seconds by (mod 86400).
    ex de, hl ; DE=OP1=resultSeconds
    ld hl, OP2
    ld a, 1
    ld bc, 20864 ; ABC=86400 seconds per day
    call setU40ToABC ; HL=OP2=divisor=86400
    ex de, hl ; DE=OP2=divisor; HL=OP1=resultSeconds
    ld bc, OP3
    call divI40U40 ; BC=OP3=remainder=always positive
    ; convert seconds to OP1=RpnTime
    ld de, OP3 ; DE=remainder
    ld hl, OP1
    ld a, rpnObjectTypeTime
    ld (hl), a
    inc hl ; HL:(Time*)=newTime
    jr secondsToTime ; HL=OP1+sizeof(Time)

;-----------------------------------------------------------------------------

; Description: Subtract RpnTime minus RpnTime or seconds.
; Input:
;   - OP1:RpnTime=Y
;   - OP3:RpnTime or seconds=X
; Output:
;   - OP1:RpnTime(RpnTime-seconds) or i40(RpnTime-RpnTime).
; Destroys: all, OP1-OP4
SubRpnTimeByRpnTimeOrSeconds:
    call checkOp3TimePageTwo ; ZF=1 if type(OP3)==Time
    jr z, subRpnTimeByRpnTime
subRpnTimeBySeconds:
    ; exchage CP1/CP3, invert the sign, then call addRpnTimeBySecondsAdd()
    call cp1ExCp3PageTwo
    bcall(_InvOP1S) ; OP1=-OP1
    jr addRpnTimeBySecondsAdd
subRpnTimeByRpnTime:
    ; convert OP3 to seconds, on FPS stack
    call reserveRaw9 ; make space on FPS=[X.seconds]; HL=X.seconds
    push hl ; stack=[X.seconds]
    ld de, OP3+1 ; DE=Time{}
    call timeToSeconds ; HL=FPS.X.seconds updated
    ; convert OP1 to seconds, on FPS stack
    call reserveRaw9 ; make space, FPS=[X.seconds,Y.seconds]; HL=Y.seconds
    push hl ; stack=[X.seconds,Y.seconds]
    ld de, OP1+1 ; DE=Time{}
    call timeToSeconds ; HL=FPS.Y.seconds updated
    ; subtract Y.seconds-X.seconds
    pop hl ; HL=Y.seconds
    pop de ; De=X.seconds
    call subU40U40 ; HL=Y.seconds-X.seconds
    ; pop result into OP1
    call popRaw9Op1 ; FPS=[X.seconds]; OP1=Y.seconds-X.seconds
    call ConvertI40ToOP1 ; OP1=float(i40)
    jp dropRaw9 ; FPS=[]
