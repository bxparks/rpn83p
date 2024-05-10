;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; RpnOffsetDateTime functions.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Convert the RpnOffsetDateTime{} record in OP1 to relative
; epochSeconds.
; Input: OP1/OP2:RpnOffsetDateTime=input
; Output: OP1:real
; Destroys: all, OP1-OP6
RpnOffsetDateTimeToEpochSeconds:
    ; push OP1/OP2 onto the FPS, which has the side-effect of removing the
    ; 2-byte gap between OP1 and OP2
    call PushRpnObject1 ; FPS=[rpnOffsetDateTime]; HL=rpnOffsetDateTime
    ex de, hl ; DE=rpnOffsetDateTime
    call reserveRaw9 ; FPS=[rpnOffsetDateTime,reserved]; HL=reserved
    ; convert DateTime to dateTimeSeconds
    inc de ; DE=offsetDateTime, skip type byte
    call offsetDateTimeToEpochSeconds ; HL:(i40*)=reserved=epochSeconds
    ; copy back to OP1
    call popRaw9Op1 ; FPS=[rpnOffsetDateTime]; HL=OP1=epochSeconds
    call dropRpnObject ; FPS=[]
    jp convertI40ToOP1 ; OP1=float(OP1)

; Description: Convert OffsetDateTime{} to relative epochSeconds.
; Input:
;   - DE:(const OffsetDateTime*)=dateTime, must not be OPx
;   - HL:(i40*)=resultSeconds, must not be OPx
; Output:
;   - DE=DE+sizeof(OffsetDateTime)
;   - (*HL):i40=resultSeconds
; Destroys: OP4-OP6
; Preserves: HL
offsetDateTimeToEpochSeconds:
    ; convert DateTime to relative epochSeconds
    call dateTimeToEpochSeconds ; HL=dateTimeSeconds; DE+=sizeof(DateTime)
    ; convert localEpochSeconds to utcEpochSeconds
    call localEpochSecondsToUtcEpochSeconds ; HL=utcEpochSeconds; DE+=2
    ret

;-----------------------------------------------------------------------------

; Description: Convert the relative epochSeconds to an RpnOffsetDateTime
; record using the targetTimeZone.
; Input:
;   - BC:(Offset*)=targetTimeZone
;   - OP1:Real=epochSeconds
; Output:
;   - OP1:RpnOffsetDateTime
; Destroys: all, OP1-OP6
EpochSecondsToRpnOffsetDateTime:
    ; get relative epochSeconds
    push bc
    call convertOP1ToI40 ; OP1=i40(epochSeconds)
    pop bc
epochSecondsToRpnOffsetDateTimeAlt:
    push bc ; stack=[targetTimeZone]
    ; reserve RpnObject on FPS
    call reserveRpnObject ; FPS=[rpnOffsetDateTime]; HL=rpnOffsetDateTime
    ex de, hl ; DE=rpnOffsetDateTime
    call pushRaw9Op1 ; FPS=[rpnOffsetDateTime,epochSeconds]; HL=epochSeconds
    ; convert to RpnOffsetDateTime
    ex de, hl ; DE=epochSeconds; HL=rpnOffsetDateTime
    ld a, rpnObjectTypeOffsetDateTime
    call setHLRpnObjectTypePageTwo ; HL+=rpnObjectTypeSizeOf
    ; select the currently selected TZ offset
    pop bc ; stack=[]; bc=targetTimeZone
    call epochSecondsToOffsetDateTime ; HL=HL+sizeof(OffsetDateTime)
    ; clean up FPS
    call dropRaw9
    jp PopRpnObject1 ; OP1=RpnOffsetDateTime

; Description: Convert the relative epochSeconds to an OffsetDateTime{} with
; the given Offset{}.
; Input:
;   - BC:(const Offset*)=offset
;   - DE:(const i40*)=epochSeconds, must not be an OPx
;   - HL:(OffsetDateTime*)=offsetDateTime, must not be an OPx
; Output:
;   - (*HL)=offsetDateTime updated
;   - HL=HL+sizeof(OffsetDateTime)
; Destroys: all, OP1-OP6
; Preserves: DE, BC
epochSecondsToOffsetDateTime:
    push de ; stack=[epochSeconds]
    push bc ; stack=[epochSeconds,offset]
    push hl ; stack=[epochSeconds,offset,offsetDateTime]
    ; convert utcEpochSeconds to localEpochSeconds
    ex de, hl ; HL=utcEpochSeconds
    ld e, c
    ld d, b ; DE=offset
    call utcEpochSecondsToLocalEpochSeconds ; HL=localEpochSeconds; DE+=2
    ; convert localEpochSeconds to DateTime
    ex de, hl ; DE=localEpochSeconds
    pop hl ; stack=[epochSeconds,offset]; HL=offsetDateTime
    call epochSecondsToDateTime ; HL=offsetDateTime+sizeof(DateTime)
    ; copy the given offset into OffsetDateTime.offset
    pop bc ; stack=[epochSeconds]; BC=offset
    ld a, (bc)
    inc bc
    ld (hl), a
    inc hl
    ld a, (bc)
    dec bc
    ld (hl), a
    inc hl ; HL=HL+sizeof(OffsetDateTime)
    pop de ; stack=[]; DE=epochSeconds
    ret

; Description: Convert the relative epochSeconds to an RpnOffsetDateTime
; using the UTC timezone.
; Input:
;   - OP1:Real=epochSeconds
; Output:
;   - OP1:RpnOffsetDateTime
; Destroys: all, OP1-OP6
EpochSecondsToRpnOffsetDateTimeUTC:
    call EpochSecondsToRpnDateTime ; OP1=RpnDateTime
    ; Transform RpnDateTime to RpnOffsetDateTime w/ UTC timezone
    ld hl, OP1
    call transformToOffsetDateTime ; HL=(RpnOffsetDateTime*)=utcDateTime
    call expandOp1ToOp2PageTwo ; handle 2-byte gap between OP1 and OP2
    ret

;-----------------------------------------------------------------------------

; Description: Add (RpnOffsetDateTime plus seconds) or (seconds plus
; RpnDateTime).
; Input:
;   - OP1:Union[RpnOffsetDateTime,RpnReal]=rpnOffsetDateTime or seconds
;   - OP3:Union[RpnOffsetDateTime,RpnReal]=rpnOffsetDateTime or seconds
; Output:
;   - OP1:RpnOffsetDateTime=RpnOffsetDateTime+seconds
; Destroys: all, OP1, OP2, OP3-OP6
AddRpnOffsetDateTimeBySeconds:
    call checkOp1OffsetDateTimePageTwo ; ZF=1 if CP1 is an RpnOffsetDateTime
    jr z, addRpnOffsetDateTimeBySecondsAdd
    call cp1ExCp3PageTwo ; CP1=rpnOffsetDateTime; CP3=seconds
addRpnOffsetDateTimeBySecondsAdd:
    ; if here: CP1=rpnOffsetDateTime, CP3=seconds.
    ; Save the rpnOffsetDateTime to FPS, to save the offset, and to remove
    ; 2-byte gap.
    call PushRpnObject1 ; FPS=[rpnOdt]; HL=rpnOdt
    push hl ; stack=[rpnOdt]
    ; Convert real(seconds) to i40(seconds) in OP1.
    call op3ToOp1PageTwo
    call convertOP1ToI40 ; OP1:(i40*)=seconds
    ; add odtSeconds + seconds
    pop hl ; stack=[]; HL=rpnOdt
    inc hl ; HL=odt
    ld de, OP1
    call addOffsetDateTimeBySeconds ; HL=newOdt
    ; clean up
    call PopRpnObject1 ; FPS=[]; OP1=newRpnOdt
    ret

; Description: Add (RpnOffsetDateTime plus duration) or (seconds plus
; RpnDateTime).
; Input:
;   - OP1:Union[RpnOffsetDateTime,RpnDuration]=rpnOffsetDateTime or duration
;   - OP3:Union[RpnOffsetDateTime,RpnDuration]=rpnOffsetDateTime or duration
; Output:
;   - OP1:RpnOffsetDateTime=RpnOffsetDateTime+duration
; Destroys: all, OP1, OP2, OP3-OP6
AddRpnOffsetDateTimeByDuration:
    call checkOp1OffsetDateTimePageTwo ; ZF=1 if CP1 is an RpnOffsetDateTime
    jr z, addRpnOffsetDateTimeByDurationAdd
    call cp1ExCp3PageTwo ; CP1=rpnOffsetDateTime; CP3=duration
addRpnOffsetDateTimeByDurationAdd:
    ; if here: CP1=rpnOffsetDateTime, CP3=duration.
    ; Save the rpnOffsetDateTime in the FPS, to save the offset, and to remove
    ; the 2-byte gap.
    call PushRpnObject1 ; FPS=[rpnOdt]; HL=rpnOdt
    push hl ; stack=[rpnOdt]
    ; Convert OP3:RpnDuration to OP1:i40.
    ld de, OP3+1 ; DE:(Duration*)=duration
    ld hl, OP1
    call durationToSeconds ; HL=OP1=durationSeconds
    ; add odtSeconds + duration
    pop hl ; stack=[]; HL=rpnOdt
    inc hl ; HL=odt
    ld de, OP1
    call addOffsetDateTimeBySeconds ; HL=newOdt
    ; clean up
    call PopRpnObject1 ; FPS=[]; OP1=newRpnOdt
    ret

; Description: Add OffsetDateTime plus seconds.
; Input:
;   - DE:(i40*)=seconds
;   - HL:(OffsetDateTime*)=offsetDateTime
; Output:
;   - HL:(OffsetDateTime*)=newOffsetDateTime
; Destroys: A, BC
; Preserves: DE, HL
addOffsetDateTimeBySeconds:
    push hl ; stack=[odt]
    push de ; stack=[odt,seconds]
    ; convert odt to odtSeconds
    ex de, hl ; DE=odt
    call reserveRaw9 ; FPS=[odtSeconds]; HL=odtSeconds
    call offsetDateTimeToEpochSeconds ; HL=odtSeconds
    ; add seconds
    pop de ; stack=[odt]; DE=seconds
    call addU40U40 ; HL=resultSeconds=odtSeconds+seconds
    ; convert back to odt, in-situ
    ex de, hl ; DE=resultSeconds
    pop hl ; stack=[]; HL=odt
    ; BC=offset, converted in-situ
    ld a, rpnObjectTypeDateTimeSizeOf-rpnObjectTypeSizeOf
    add a, l
    ld c, a
    ld a, 0
    adc a, h
    ld b, a ; BC=odt+sizeof(DateTime)=offset
    call epochSecondsToOffsetDateTime ; HL=resultOffsetDateTime+sizeof(ODT)
    ; clean up
    call dropRaw9 ; FPS=[]
    ret

;-----------------------------------------------------------------------------

; Description: Subtract RpnOffsetDateTime minus RpnOffsetDateTime or seconds.
; Input:
;   - OP1:RpnOffsetDateTime=Y
;   - OP3:RpnOffsetDateTime or seconds=X
; Output:
;   - OP1:(RpnOffsetDateTime-seconds) or (RpnOffsetDateTime-RpnOffsetDateTime).
; Destroys: OP1, OP2, OP3-OP6
SubRpnOffsetDateTimeByObject:
    call getOp3RpnObjectTypePageTwo ; A=type; HL=OP3
    cp rpnObjectTypeReal
    jr z, subRpnOffsetDateTimeBySeconds
    cp RpnObjectTypeOffsetDateTime ; ZF=1 if RpnOffsetDateTime
    jr z, subRpnOffsetDateTimeByRpnOffsetDateTime
    cp rpnObjectTypeDuration
    jr z, subRpnOffsetDateTimeByRpnDuration
    bcall(_ErrInvalid) ; should never happen
subRpnOffsetDateTimeBySeconds:
    ; invert the sign of OP3, then call addRpnOffsetDateTimeBySecondsAdd()
    call cp1ExCp3PageTwo
    bcall(_InvOP1S) ; OP1=-OP1
    call cp1ExCp3PageTwo
    jp addRpnOffsetDateTimeBySecondsAdd
subRpnOffsetDateTimeByRpnOffsetDateTime:
    ; save copies of X, Y OffsetDateTime to FPS
    call PushRpnObject1 ; FPS=[Yodt]; HL=Yodt
    push hl ; stack=[Yodt]
    call PushRpnObject3 ; FPS=[Yodt,Xodt]; HL=Xodt
    ; calculate X epochSeconds
    ex de, hl ; DE=Xodt
    inc de ; skip type byte
    call reserveRaw9 ; FPS=[Yodt,Xodt,Xeps]; HL=Xeps
    call offsetDateTimeToEpochSeconds ; HL=Xeps filled
    ; calculate Y epochSeconds
    ex (sp), hl ; stack=[Xeps]; HL=Yodt
    ex de, hl ; DE=Yodt
    inc de ; skip type byte
    call reserveRaw9 ; FPS=[Yodt,Xodt,Xeps,Yeps]; HL=Yeps
    call offsetDateTimeToEpochSeconds ; HL=Yeps filled
    ; subtract Yeps-Xeps
    pop de ; stack=[]; DE=Xeps
    call subU40U40 ; HL=Yeps=Y-X
    ; copy result to OP1
    call popRaw9Op1 ; OP1=Yeps-Xeps
    call convertI40ToOP1 ; OP1=float(Y-X)
    ; clean up FPS
    call dropRaw9
    call dropRpnObject
    jp dropRpnObject
subRpnOffsetDateTimeByRpnDuration:
    call shrinkOp2ToOp1PageTwo ; remove 2-byte gap
    ; convert OP3 to seconds on the FPS stack
    call reserveRaw9 ; FPS=[durationSeconds]; HL=durationSeconds
    ld de, OP3+1 ; DE:(DateTime*)
    call durationToSeconds ; HL=durationSeconds
    ; calculate odt-duration
    call negU40 ; HL=-durationSeconds
    ex de, hl ; DE=-durationSeconds
    ld hl, OP1+1 ; HL=dateTime
    call addOffsetDateTimeBySeconds ; HL=odt-durationSeconds
    ; clean up
    call expandOp1ToOp2PageTwo ; add back 2-byte gap
    jp dropRaw9 ; FPS=[]

;-----------------------------------------------------------------------------

; Description: Convert the utcEpochSeconds to an epochSeconds relative to the
; given Offset, so that when that is converted to Date or DateTime, the result
; is accurate for the given Offset.
; Input:
;   - DE:(Offset*)=offset
;   - HL:(i40*)=utcEpochSeconds
; Output:
;   - DE=offset+2
;   - HL=localEpochSeconds
; Preserves: BC, DE
utcEpochSecondsToLocalEpochSeconds:
    push hl ; stack=[utcEpochSeconds]
    call reserveRaw9 ; FPS=[offset, offsetSeconds]; HL=offsetSeconds
    call offsetToSeconds ; HL=offsetSeconds updated
    ex de, hl ; DE=offsetSeconds; HL=offset+2
    ex (sp), hl ; stack=[offset+2]; HL=utcEpochSeconds
    call addU40U40 ; HL=localEpochSeconds=utcEpochSeconds+offseSeconds
    pop de ; stack=[]; DE=offset+2
    jp dropRaw9

; Description: Convert the localEpochSeconds relative to the given Offset to
; the utcEpochSeconds.
; Input:
;   - DE:(Offset*)=offset
;   - HL:(i40*)=localEpochSeconds
; Output:
;   - DE=offset+2
;   - HL=utcEpochSeconds
; Preserves: BC, DE
localEpochSecondsToUtcEpochSeconds:
    push hl ; stack=[localEpochSeconds]
    call reserveRaw9 ; FPS=[offsetSeconds]; HL=offsetSeconds
    call offsetToSeconds ; HL=offsetSeconds updated
    ex de, hl ; DE=offsetSeconds; HL=offset+2
    ex (sp), hl ; stack=[offset+2]; HL=localEpochSeconds
    call subU40U40 ; HL=utcEpochSeconds=localEpochSeconds-offsetSeconds
    pop de ; stack=[]; DE=offset+2
    jp dropRaw9

;-----------------------------------------------------------------------------

; Description: Split an RpnOffsetDateTime into RpnDateTime and RpnOffset.
; Input:
;   - CP1:RpnOffsetDateTime=X
; Output:
;   - CP1:RpnOffset=Y
;   - CP3:RpnDateTime=X
; Destroys: all
SplitRpnOffsetDateTime:
    call shrinkOp2ToOp1PageTwo ; remove 2-byte gap between OP1 and OP2
    ; extract the DateTime part
    ld a, rpnObjectTypeDateTime
    call setOp3RpnObjectTypePageTwo ; HL=OP3+rpnObjectTypeSizeOf
    ex de, hl ; DE=(DateTime*)
    ld hl, OP1+rpnObjectTypeSizeOf ; HL:(const DateTime*)
    ld bc, rpnObjectTypeDateTimeSizeOf-rpnObjectTypeSizeOf
    ldir
    ; Extract the Offset part by shifting forward. This is allowed because
    ; sizeof(DateTime)>sizeof(Offset), so there is no overlap.
    ld a, rpnObjectTypeOffset
    call setOp1RpnObjectTypePageTwo ; HL=OP1+rpnObjectTypeSizeOf
    ex de, hl ; DE=(Offset*)
    ld hl, OP1+rpnObjectTypeDateTimeSizeOf ; HL:(const Offset*)
    ld bc, rpnObjectTypeOffsetSizeOf-rpnObjectTypeSizeOf
    ldir
    ret

;-----------------------------------------------------------------------------

; Description: Merge RpnDateTime with RpnOffset into an RpnOffsetDateTime.
; Input:
;   - OP1:RpnDateTime|RpnOffset
;   - OP3:RpnDateTime|RpnOffset
; Output:
;   - OP1:RpnOffsetDateTime(OP1,OP3)
; Destroys: all, OP1-OP4
MergeRpnDateTimeWithRpnOffset:
    call checkOp1OffsetPageTwo ; ZF=1 if OP1=RpnOffset
    call z, cp1ExCp3PageTwo
    ; if reached here: CP1:RpnDateTime; CP3:RpnOffset
    ld a, rpnObjectTypeOffsetDateTime
    call setOp1RpnObjectTypePageTwo ; HL=OP1+rpnObjectTypeSizeOf
    ld de, OP1+rpnObjectTypeDateTimeSizeOf
    ld hl, OP3+rpnObjectTypeSizeOf
    ld bc, rpnObjectTypeOffsetSizeOf-rpnObjectTypeSizeOf
    ldir
    call expandOp1ToOp2PageTwo
    ret

;-----------------------------------------------------------------------------

; Description: Convert RpnDateTime into RpnOffsetDateTime by appending an
; TimeZone offset of "+00:00", i.e. TZ{0,0}.
; Input:
;   - OP1:RpnDateTime
; Output:
;   - OP1:RpnOffsetDateTime
; Destroys: A, DE, HL, OP1
ExtendRpnDateTimeToOffsetDateTime:
    ld a, rpnObjectTypeOffsetDateTime
    call setOp1RpnObjectTypePageTwo ; HL=OP1+rpnObjectTypeSizeOf
    ; clear the Offset fields
    ld de, rpnObjectTypeDateTimeSizeOf-rpnObjectTypeSizeOf
    add hl, de ; HL=offsetPointer
    xor a
    ld (hl), a
    inc hl
    ld (hl), a
    call expandOp1ToOp2PageTwo
    ret

;-----------------------------------------------------------------------------

; Description: Convert RpnOffsetDateTime into RpnDateTime by truncating the
; TimeZone offset.
; Input:
;   - OP1:RpnOffsetDateTime
; Output:
;   - OP1:RpnDateTime
; Destroys: OP1
TruncateRpnOffsetDateTime:
    ld a, rpnObjectTypeDateTime
    call setOp1RpnObjectTypePageTwo
    ret
