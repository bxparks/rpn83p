;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; RpnTime functions.
;-----------------------------------------------------------------------------

; Description: Convert the RpnTime{} record in OP1 to number of seconds.
; Input: OP1:RpnTime=input
; Output: OP1:real
; Destroys: all, OP1-OP6
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
