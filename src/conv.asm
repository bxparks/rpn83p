;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Conversion routines, mostly about angles.
;-----------------------------------------------------------------------------

; Description: Implement custom implementation of RToP() using CAbs() and
; Angle(). The TI-OS RToP() suffers from overflow and underflow bugs when
; 'r=cabs(a,b)' overflows 1e100. This routine uses the same algorithm used by
; complexRToPCommon() routine in complex.asm, minus the various exception
; handling which isn't needed here because this does not clobber the
; 'trigFlags' global parameter.
;
; It looks like Cabs() does *not* throw an Err:Overflow exception when the
; exponent becomes >=100. But when the OP1 is saved into the Stack X register
; through replaceXY(), the bcall(_CkValidNum) will be called, and it will
; detect an overflow and throw an Err:Overflow exception.
;
; Input:
;   - OP1,OP2=(x,y) same order as RToP()
;   - (trigFlags)=angle mode
; Output:
;   - OP1,OP2: (r, theta)
rectToPolar:
    call mergeOp1Op2ToCp1 ; CP1=Z=complex(OP1,OP2)
    bcall(_PushOP1) ; FPS=[Z]
    bcall(_Angle) ; OP1=Angle(Z)
    call op1ToOp5 ; OP5=Angle(Z)
    bcall(_PopOP1) ; FPS=[]; CP1=Z
    bcall(_CAbs) ; OP1=Cabs(Z); destroys OP1-OP4
    call op5ToOp2 ; OP2=Angle(Z)
    ret
