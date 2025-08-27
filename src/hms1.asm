;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Routines for converting between "hh.mmss" and "hh.rrrr" formats.
;
; Labels with Capital letters are intended to be exported to other flash pages
; and should be placed in the branch table on Flash Page 0. Labels with
; lowercase letters are intended to be private so do not need a branch table
; entry.
;-----------------------------------------------------------------------------

; Description: Convert "hh.mmss" to "hh.rrrr". The formula is:
;   hh.rrrr = int(hh.mmss) + int(mm.ss)/60 + int(ss.nnnn)/3600.
; Input: OP1: hh.mmss
; Output: OP1: hh.rrrr
; Destroys: OP1, OP2, OP3, OP4 (temp)
HmsToHr:
    ; Sometimes, the internal floating point value is slightly different than
    ; the displayed value due to rounding errors. For example, a value
    ; displayed as `10` (e.g. `e^(ln(10))`) could actually be `9.9999999999xxx`
    ; internally due to rounding errors. This routine parses out the digits
    ; after the decimal point and interprets them as minutes (mm) and seconds
    ; (ss) components. Any rounding errors will cause incorrect results. To
    ; mitigate this, we round the X value to 10 digits to make sure that the
    ; internal value matches the displayed value.
    bcall(_RndGuard)

    ; Extract the whole 'hh' and push it into the FPS.
    bcall(_OP1ToOP4) ; OP4 = hh.mmss (save in temp)
    bcall(_Trunc) ; OP1 = int(hh.mmss)
    bcall(_PushRealO1) ; FPS=[hh]

    ; Extract the 'mm' and push it into the FPS.
    bcall(_OP4ToOP1) ; OP1 = hh.mmss
    bcall(_Frac) ; OP1 = .mmss
    call op2Set100PageOne
    bcall(_FPMult) ; OP1 = mm.ss
    bcall(_OP1ToOP4) ; OP4 = mm.ss
    bcall(_Trunc) ; OP1 = mm
    bcall(_PushRealO1) ; FPS=[hh, mm]

    ; Extract the 'ss.nnn' part
    bcall(_OP4ToOP1) ; OP1 = mm.ssnnn
    bcall(_Frac) ; OP1 = .ssnnn
    call op2Set100PageOne
    bcall(_FPMult) ; OP1 = ss.nnn

    ; Reassemble in the form of `hh.nnn`.
    ; Extract ss.nnn/60
    bcall(_OP2Set60) ; OP2 = 60
    bcall(_FPDiv) ; OP1 = ss.nnn/60
    ; Extract mm/60
    bcall(_PopRealO2) ; FPS=[hh]; OP1 = mm
    bcall(_FPAdd) ; OP1 = mm + ss.nnn/60
    bcall(_OP2Set60) ; OP2 = 60
    bcall(_FPDiv) ; OP1 = (mm + ss.nnn/60) / 60
    ; Extract the hh.
    bcall(_PopRealO2) ; FPS=[]; OP1 = hh
    bcall(_FPAdd) ; OP1 = hh + (mm + ss.nnn/60) / 60
    ret

; Description: Convert "hh.rrrr" to "hh.mmss". The formula is:
;   hh.mmss = int(hh + (mm + ss.nnn/100)/100
; where
;   mm = int(.nnn* 60), and
;   ss.nnn = frac(.nnn*60)*60
; Input: OP1: hh.rrrr
; Output: OP1: hh.mmss
; Destroys: OP1, OP2, OP3, OP4, OP5, OP6
HmsFromHr:
    ; Extract the whole hh.
    bcall(_OP1ToOP4) ; OP4 = hh.nnn (save in temp)
    bcall(_Trunc) ; OP1 = int(hh.nnn)
    bcall(_PushRealO1) ; FPS=[hh]

    ; Extract the 'mm' and push it into the FPS
    bcall(_OP4ToOP1) ; OP1 = hh.nnn
    bcall(_Frac) ; OP1 = .nnn
    bcall(_OP2Set60) ; OP2 = 60
    bcall(_FPMult) ; OP1 = mm.nnn
    bcall(_OP1ToOP4) ; OP4 = mm.nnn
    bcall(_Trunc) ; OP1 = mm
    bcall(_PushRealO1) ; FPS=[hh,mm]

    ; Extract the 'ss.nnn' part
    bcall(_OP4ToOP1) ; OP1 = mm.nnn
    bcall(_Frac) ; OP1 = .nnn
    bcall(_OP2Set60) ; OP2 = 60
    bcall(_FPMult) ; OP1 = ss.nnn

    ; Normalize ss, mm, and hh. Required because the TIOS sometimes tries to be
    ; helpful and rounds non-integral results to exact integers when it should
    ; not. This can result in the 'ss' field to be exactly 60, which must be
    ; normalized, and overflowed to the 'mm' field. The 'mm' must in turn must
    ; be normalized, and overflowed to the 'hh' field. For example, without
    ; this normalization, "[1.32] [ENTER] [HMS+]" returns "3.0360" instead of
    ; "3.0400".
    bcall(_OP1ToOP4) ; OP4=ss.nnn
    bcall(_PopRealO5) ; FPS=[hh]; OP5=mm
    bcall(_PopRealO6) ; FPS=[]; OP6=hh
    ; Check for ss overflow
    bcall(_RndGuard) ; OP1=rounded(ss.nnn) without guard digits
    bcall(_OP2Set60) ; OP2 = 60
    bcall(_CpOP1OP2) ; if ss.nnn >= 60: CF=0
    jr c, HmsFromHrFinishOverflow
    ; Overflow ss to mm
    bcall(_FPSub) ; OP1=ss.nnn-60
    bcall(_OP1ToOP4) ; OP4=normalized(ss.nnn)
    bcall(_OP5ToOP1) ; OP1=mm
    bcall(_Plus1) ; OP1=mm+1
    bcall(_OP1ToOP5) ; OP5=mm+1
    ; Check for mm overflow
    bcall(_OP2Set60) ; OP2 = 60
    bcall(_CpOP1OP2) ; if mm >= 60: CF=0
    jr c, HmsFromHrFinishOverflow
    ; Overflow mm to hh
    bcall(_FPSub) ; OP1=mm-60
    bcall(_OP1ToOP5) ; OP5=normalized(mm)
    bcall(_OP6ToOP1) ; OP1=hh
    bcall(_Plus1) ; OP1=hh+1
    bcall(_OP1ToOP6) ; OP6=hh+1

HmsFromHrFinishOverflow:
    ; Reassemble OP4=ss.nnn, OP5=mm, OP6=hh in the form of `hh.mmssnnn`.
    ; Extract ss.nnn/100
    bcall(_OP4ToOP1) ; OP1=ss.nnn
    call op2Set100PageOne
    bcall(_FPDiv) ; OP1 = ss.nnn/100
    ; Extract mm/100
    bcall(_OP5ToOP2) ; FPS=[hh]; OP1 = mm
    bcall(_FPAdd) ; OP1 = mm + ss.nnn/100
    call op2Set100PageOne
    bcall(_FPDiv) ; OP1 = (mm + ss.nnn/100) / 100
    ; Extract the hh.
    bcall(_OP6ToOP2) ; FPS=[]; OP1 = hh
    bcall(_FPAdd) ; OP1 = hh + (mm + ss.nnn/100) / 100
    ret

; Description: Add OP2(hh.mmss) to OP1(hh.mmss).
; Input: OP1:hh.mmssY; OP2:hh.mmssX
; Output: OP1 = hh.mmssY + hh.mmssX
; Destroys: OP1, OP2, OP3, OP4, OP5, OP6
HmsPlus:
    bcall(_PushRealO1) ; FPS=[hh.mmssY]
    call op2ToOp1PageOne ; OP1=hh.mmssX
    call HmsToHr ; OP1=hh.ddX
    call exchangeFPSOP1PageOne ; FPS=[hh.ddX]; OP1=hh.mmssY
    call HmsToHr ; OP1=hh.ddY
    bcall(_PopRealO2) ; FPS=[]; OP2=hh.ddX
    bcall(_FPAdd) ; OP1=hh.ddX+h.ddY
    call HmsFromHr ; OP1=hh.mmss(X+Y)
    ret

; Description: Substract OP2(hh.mmss) from OP1(hh.mmss).
; Input: OP1:hh.mmssY; OP2:hh.mmssX
; Output: OP1 = hh.mmssY - hh.mmssX
; Destroys: OP1, OP2, OP3, OP4, OP5, OP6
HmsMinus:
    bcall(_PushRealO1) ; FPS=[hh.mmssY]
    call op2ToOp1PageOne ; OP1=hh.mmssX
    call HmsToHr ; OP1=hh.ddX
    call exchangeFPSOP1PageOne ; FPS=[hh.ddX]; OP1=hh.mmssY
    call HmsToHr ; OP1=hh.ddY
    bcall(_PopRealO2) ; FPS=[]; OP2=hh.ddX
    bcall(_FPSub) ; OP1=hh.ddY-hh.ddX
    call HmsFromHr ; OP1=hh.mmss(Y-X)
    ret
