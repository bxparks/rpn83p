;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; STAT register functions.
;-----------------------------------------------------------------------------

; STAT registers using an RpnElementList separate from the storage registers.
statRegSize equ 13
statRegX equ 0
statRegX2 equ 1
statRegY equ 2
statRegY2 equ 3
statRegXY equ 4
statRegN equ 5
statRegLnX equ 6
statRegLnX2 equ 7
statRegLnY equ 8
statRegLnY2 equ 9
statRegLnXLnY equ 10
statRegXLnY equ 11
statRegYLnX equ 12

statVarName:
    .db AppVarObj, "RPN83STA" ; max 8 char, NUL terminated if < 8

;-----------------------------------------------------------------------------

; Description: Initialize the RPN83STA variable.
; Input: none
; Output: RPN83STA created if it doesn't exist
; Destroys: all
InitStatRegs:
    ld hl, statVarName
    ld c, statRegSize
    jp initRpnElementList

; Description: Clear all RPN83STA elements.
; Input: none
; Output: RPN83STA elements set to 0.0
; Destroys: all, OP1
ClearStatRegs:
    call lenStatRegs ; A=len; DE=dataPointer
    ld c, a ; C=len
    ld b, 0 ; B=begin=0
    jp clearRpnElementList

; Description: Should be called just before existing the app.
CloseStatRegs:
    ld hl, statVarName
    jp closeRpnElementList

; Description: Return the length of the RPN83STA variable.
; Output:
;   - A=length of RPN83STA variable
;   - DE:(u8*)=dataPointer
; Destroys: BC, HL
lenStatRegs:
    ld hl, statVarName
    jp lenRpnElementList

;-----------------------------------------------------------------------------

; Description: Store OP1/OP2 into RPN83STA[NN].
; Input:
;   - C:u8=registerIndex, 0-based
;   - OP1/OP2:RpnObject
; Output:
;   - RPN83STA[NN] = OP1
; Destroys: all
; Preserves: OP1/OP2
StoStatRegNN:
    ld hl, statVarName
    jp stoRpnObject

; Description: Recall RPN83STA[NN] into OP1/OP2.
; Input:
;   - C:u8=registerIndex, 0-based
;   - RPN83STA variable
; Output:
;   - OP1/OP2:RpnObject=output
;   - A:u8=objectType
; Destroys: all
RclStatRegNN:
    ld hl, statVarName
    jp rclRpnObject ; OP1/OP2=STK[C]

; Description: Recall RPN83STA[NN] to OP2. WARNING: Assumes real not complex.
; Input:
;   - C:u8=register index, 0-based
;   - 'REGS' list variable
; Output:
;   - OP2:(real|complex)=float value
; Destroys: all
; Preserves: OP1
RclStatRegNNToOP2:
    push bc ; stack=[NN]
    bcall(_PushRealO1) ; FPS=[OP1]
    pop bc ; C=NN
    call RclStatRegNN
    call op1ToOp2PageOne
    bcall(_PopRealO1) ; FPS=[]; OP1=OP1
    ret

;-----------------------------------------------------------------------------

; Description: Add OP1 to stat register NN. Used by STAT functions.
; WARNING: Works only for real not complex.
; Input:
;   - OP1:real=float value
;   - C:u8=registerIndex, 0-based
; Output:
;   - RPN83STA[NN] += OP1
; Destroys: all
; Preserves: OP1, OP2
StoAddStatRegNN:
    push bc ; stack=[NN]
    bcall(_PushRealO1) ; FPS=[OP1]
    bcall(_PushRealO2) ; FPS=[OP1,OP2]
    call op1ToOp2PageOne
    pop bc ; C=NN
    push bc ; stack=[NN]
    call RclStatRegNN
    bcall(_FPAdd) ; OP1 += OP2
    pop bc ; C=NN
    call StoStatRegNN
    bcall(_PopRealO2) ; FPS=[OP1]
    bcall(_PopRealO1) ; FPS=[]; OP1=OP1
    ret

; Description: Subtract OP1 from stat register NN. Used by STAT functions.
; WARNING: Works only for real not complex.
; Input:
;   - OP1:real=float value
;   - C:u8=registerIndex, 0-based
; Output:
;   - RPN83STA[NN] -= OP1
; Destroys: all
; Preserves: OP1, OP2
StoSubStatRegNN:
    push bc ; stack=[NN]
    bcall(_PushRealO1) ; FPS=[OP1]
    bcall(_PushRealO2) ; FPS=[OP1,OP2]
    call op1ToOp2PageOne
    pop bc ; C=NN
    push bc
    call RclStatRegNN
    bcall(_FPSub) ; OP1 -= OP2
    pop bc ; C=NN
    call StoStatRegNN
    bcall(_PopRealO2) ; FPS=[OP1]
    bcall(_PopRealO1) ; FPS=[]; OP1=OP1
    ret
