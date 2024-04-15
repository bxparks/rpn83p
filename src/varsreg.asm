;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Storage registers implemented using an appVar named RPN83REG.
;-----------------------------------------------------------------------------

regsSizeMin equ 25
regsSizeMax equ 100
regsSizeDefault equ 25

regsName:
    .db AppVarObj, "RPN83REG" ; max 8 char, NUL terminated if < 8

;-----------------------------------------------------------------------------

; Description: Initialize the REGS list variable which is used for user
; registers 00 to 24.
; Input: none
; Output:
;   - REGS created if it doesn't exist
; Destroys: all
initRegs:
    ld hl, regsName
    ld c, regsSizeDefault
    jp initRpnObjectList

; Description: Clear all REGS elements.
; Input: none
; Output: REGS elements set to 0.0
; Destroys: all, OP1
clearRegs:
    call lenRegs ; A=len; DE=dataPointer
    ld c, a ; C=len
    ld b, 0 ; B=begin=0
    jp clearRpnObjectList

; Description: Should be called just before existing the app.
closeRegs:
    ld hl, regsName
    jp closeRpnObjectList

; Description: Return the length of the REGS variable.
; Output:
;   - A=length of REGS variable
;   - DE:(u8*)=dataPointer
; Destroys: BC, HL
lenRegs:
    ld hl, regsName
    jp lenRpnObjectList

; Description: Resize the storage registers to the new length in A.
; Input: A:u8=newLen
; Output:
;   - ZF=1 if newLen==oldLen
;   - CF=0 if newLen>oldLen
;   - CF=1 if newLen<oldLen
resizeRegs:
    ld hl, regsName
    jp resizeRpnObjectList

;-----------------------------------------------------------------------------

; Description: Store OP1/OP2 into REGS[NN].
; Input:
;   - C:u8=register index, 0-based
;   - OP1/OP2:RpnObject
; Output:
;   - REGS[NN] = OP1
; Destroys: all
; Preserves: OP1/OP2
stoRegNN:
    ld hl, regsName
    jp stoRpnObject

; Description: Recall REGS[NN] into OP1/OP2.
; Input:
;   - C:u8=register index, 0-based
;   - 'REGS' list variable
; Output:
;   - OP1/OP2:RpnObject=output
;   - A:u8=objectType
; Destroys: all
rclRegNN:
    ld hl, regsName
    jp rclRpnObject ; OP1/OP2=STK[C]

; Description: Recall REGS[NN] to OP2. WARNING: Assumes real not complex.
; Input:
;   - C:u8=register index, 0-based
;   - 'REGS' list variable
; Output:
;   - OP2:(real|complex)=float value
; Destroys: all
; Preserves: OP1
rclRegNNToOP2:
    push bc ; stack=[NN]
    bcall(_PushRealO1) ; FPS=[OP1]
    pop bc ; C=NN
    call rclRegNN
    call op1ToOp2
    bcall(_PopRealO1) ; FPS=[]; OP1=OP1
    ret

;-----------------------------------------------------------------------------

; Description: Implement STO{op} NN, with {op} defined by B and NN given by C.
; Input:
;   - OP1/OP2:RpnObject
;   - B:u8=operation index [0,4] into floatOps, MUST be same as argModifierXxx
;   - C:u8=register index NN, 0-based
; Output:
;   - REGS[NN]=(REGS[NN] {op} OP1/OP2), where {op} is defined by B, and can be
;   a simple assignment operator
; Destroys: all, OP3, OP4
; Preserves: OP1, OP2
stoOpRegNN:
    push bc ; stack=[op,NN]
    bcall(_PushRpnObject1) ; FPS=[OP1/OP2]
    call cp1ToCp3 ; OP3/OP4=OP1/OP2
    ; Recall REGS[NN]
    pop bc ; stack=[]; B=op; C=NN
    push bc ; stack=[op,NN]
    call rclRegNN ; OP1/OP2=REGS[NN]
    ; Invoke op B
    pop bc ; stack=[]; B=op; C=NN
    push bc ; stack=[op,NN]
    ld a, b ; A=op
    ld hl, floatOps
    call jumpAOfHL
    ; Save REGS[C]
    pop bc ; stack=[]; B=op; C=NN
    call stoRegNN
    ; restore OP1, OP2
    bcall(_PopRpnObject1) ; FPS=[]; OP1/OP2=OP1/OP2
    ret

; Description: Implement RCL{op} NN, with {op} defined by B and NN given by C.
; Input:
;   - OP1/OP2:RpnObject
;   - B:u8=operation index [0,4] into floatOps, MUST be same as argModifierXxx
;   - C:u8=register index NN, 0-based
; Output:
;   - OP1/OP2=(OP1/OP2 {op} REGS[NN]), where {op} is defined by B, and can be a
;   simple assignment operator
; Destroys: all, OP3, OP4
rclOpRegNN:
    push bc ; stack=[op,NN]
    bcall(_PushRpnObject1) ; FPS=[OP1/OP2]
    ; Recall REGS[NN]
    pop bc ; stack=[]; B=op; C=NN
    push bc ; stack=[op,NN]
    call rclRegNN ; OP1/OP2=REGS[NN]
    call cp1ToCp3 ; OP3/OP4=OP1/OP2
    bcall(_PopRpnObject1) ; FPS=[]; OP1/OP2=OP1/OP2
    ; Invoke op B
    pop bc ; stack=[]; B=op; C=NN
    ld a, b ; A=op
    ld hl, floatOps
    jp jumpAOfHL ; OP1/OP2=OP1/OP2{op}OP3/OP4

;-----------------------------------------------------------------------------

; List of floating point operations, indexed from 0 to 4. Implements `OP1/OP2
; {op}= OP3/OP4`. These MUST be identical to the argModifierXxx constants.
floatOpsCount equ 5
floatOps:
    .dw floatOpAssign ; 0, argModifierNone
    .dw floatOpAdd ; 1, argModifierAdd
    .dw floatOpSub ; 2, argModifierSub
    .dw floatOpMul ; 3, argModifierMul
    .dw floatOpDiv ; 4, argModifierDiv

; We could place these jump routines directly into the floatOps table. However,
; at some point the various complex functions will probably move to different
; flash page, which will requires a bcall(), so having this layer of
; indirection will make that refactoring easier. Also, this provides slightly
; better self-documentation.
floatOpAssign:
    jp cp3ToCp1
floatOpAdd:
    jp universalAdd
floatOpSub:
    jp universalSub
floatOpMul:
    jp universalMult
floatOpDiv:
    jp universalDiv

;-----------------------------------------------------------------------------
; Predefined single-letter Real or Complex variables.
;-----------------------------------------------------------------------------

; Description: Store OP1/OP2 into the TI-OS variable named in C.
; Input:
;   - C:u8=varName
;   - OP1/OP2:(real|complex)=number, only real or complex supported
; Output:
;   - OP1/OP2: value stored
; Destroys: all
; Preserves: OP1/OP2
; Throws: Err:DataType if not Real or Complex
stoVar:
    ; StoOther() wants its argument in the FPS. If the argument is real, then
    ; only a single float should be pushed. If the argument is complex, 2
    ; floating number need to be pushed. The PushOP1() function automatically
    ; handles both real and complex. In contrast, the PushRpnObject1() function
    ; always pushes 2 floating numbers into the FPS, so we cannot use that
    ; here. After the operation is performed, StoOther() cleans up the FPS
    ; automatically.
    push bc
    bcall(_PushOP1) ; FPS=[OP1/OP2]
    pop bc
    ;
    call checkOp1Complex ; ZF=1 if complex
    jr z, stoVarComplex
    call checkOp1Real ; ZF=1 if real
    jr z, stoVarReal
    bcall(_ErrDataType)
stoVarReal:
    ld b, RealObj
    jr stoVarSave
stoVarComplex:
    ld b, CplxObj
stoVarSave:
    call createVarName ; OP1=varName
    bcall(_StoOther) ; FPS=[]; (varName)=OP1/OP2; var created if necessary
    ret

; Description: Recall OP1 from the TI-OS variable named in C.
; Input: C:u8=varName
; Output: OP1/OP2:(real|complex), only real or complex supported
; Throws:
;   - ErrUndefined if the varName does not exist.
; Destroys: all
rclVar:
    ld b, RealObj ; B=varType, probably ignored by RclVarSym()
    call createVarName ; OP1=varName
    bcall(_RclVarSym) ; OP1/OP2=value
    ret

; Description: Create a real variable name in OP1.
; Input: B:u8=varType; C:u8=varName
; Output: OP1=varName
; Destroys: A, HL
; Preserves: BC, DE
createVarName:
    ld hl, OP1
    ld (hl), b ; (OP1)=varType
    inc hl
    ld (hl), c ; (OP1+1)=varName
    inc hl
    xor a
    ld (hl), a
    inc hl
    ld (hl), a ; terminated by 2 NUL
    inc hl
    ; next 5 bytes in OP1 can be anything so no need to set them
    ret

;-----------------------------------------------------------------------------

; Description: Implement STO{op} LETTER. Very similar to stoOpRegNN().
; Input:
;   - OP1/OP2:(real|complex), only real or complex supported
;   - B:u8=operation index [0,4] into floatOps, MUST be same as argModifierXxx
;   - C:u8=LETTER, name of variable
; Output:
;   - VARS[LETTER]=(VARS[LETTER] {op} OP1/OP2), where {op} is defined by B, and
;   can be a simple assignment operator (argModifierNone)
; Destroys: all, OP3, OP4
; Preserves: OP1/OP2
stoOpVar:
    ; Use stoVar() to avoid error in rclVar() if the {op} is argModifierNone.
    ld a, b ; A=op
    or a ; ZF=1 if op==argModifierNone
    jr z, stoVar
    ;
    push bc ; stack=[op,LETTER]
    bcall(_PushRpnObject1) ; FPS=[OP1/OP2]
    call cp1ToCp3 ; OP3/OP4=OP1/OP2
    ; Recall VARS[LETTER]
    pop bc ; stack=[]; B=op; C=LETTER
    push bc ; stack=[op,LETTER]
    call rclVar ; OP1/OP2=VARS[LETTER]
    ; Invoke op B
    pop bc ; stack=[]; B=op; C=LETTER
    push bc ; stack=[op,LETTER]
    ld a, b ; A=op
    ld hl, floatOps
    call jumpAOfHL
    ; Save VARS[LETTER]
    pop bc ; stack=[]; B=op; C=LETTER
    call stoVar
    ; restore OP1, OP2
    bcall(_PopRpnObject1) ; FPS=[]; OP1/OP2=OP1/OP2
    ret

; Description: Implement RCL{op} LETTER, with {op} defined by B and LETTER
; given by C. Very similar to rclOpRegNN().
; Input:
;   - OP1/OP2:(real|complex), only real or complex support
;   - B:u8=operation index [0,4] into floatOps, MUST be same as argModifierXxx
;   - C:u8=LETTER, name of variable
; Output:
;   - OP1/OP2=(OP1/OP2 {op} REGS[LETTER]), where {op} is defined by B, and can
;   be a simple assignment operator
; Destroys: all, OP3, OP4
rclOpVar:
    push bc ; stack=[op/LETTER]
    bcall(_PushRpnObject1) ; FPS=[OP1/OP2]
    ; Recall VARS[LETTER]
    pop bc ; stack=[]; B=op; C=LETTER
    push bc ; stack=[op,LETTER]
    call rclVar ; OP1/OP2=VARS[LETTER]
    call cp1ToCp3 ; OP3/OP4=OP1/OP2
    bcall(_PopRpnObject1) ; FPS=[]; OP1/OP2=OP1/OP2
    ; Invoke op B
    pop bc ; stack=[]; B=op; C=LETTER
    ld a, b ; A=op
    ld hl, floatOps
    jp jumpAOfHL ; OP1/OP2=OP1/OP2{op}OP3/OP4

;-----------------------------------------------------------------------------
; Universal Sto, Rcl, Sto{op}, Rcl{op} which work for both numeric storage
; registers and single-letter variables.
;-----------------------------------------------------------------------------

; Description: Implement stoVar() or stoRegNN() depending on the argType in A.
; Input: A=varType; C=indexOrLetter
; Output: none
stoGeneric:
    cp a, argTypeLetter
    jp z, stoVar
    jp stoRegNN

; Description: Implement rclVar() or rclRegNN() depending on the argType in A.
; Input: A=varType; C=indexOrLetter
; Output: none
rclGeneric:
    cp a, argTypeLetter
    jp z, rclVar
    jp rclRegNN

; Description: Implement stoOpVar() or stoOpRegNN() depending on the argType in
; A.
; Input: A=varType; B=op; C=indexOrLetter
; Output: OP1/OP2: updated
stoOpGeneric:
    cp a, argTypeLetter
    jp z, stoOpVar
    jp stoOpRegNN

; Description: Implement rclVar() or rclRegNN() depending on the argType in A.
; Input: A=varType; B=op; C=indexOrLetter
; Output: OP1/OP2: updated
rclOpGeneric:
    cp a, argTypeLetter
    jp z, rclOpVar
    jp rclOpRegNN

