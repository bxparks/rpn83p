;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024 Brian T. Park
;
; Routines for manipulating the storage variables (A-Z,Theta).
;-----------------------------------------------------------------------------

; Description: Delete all single-letter variables (A-Z,Theta), unless they are
; archived. Certain variables are allowed to be archived by the OS: R, T, X, Y,
; and Theta. Interestingly, both N and Z can be archived even though there
; exist direct OS functions for _StoN() and _RclN().
;
; Commented out for now, because the CLV command on the HP-42S deletes only a
; single variable, not *all* variables. Upon reflection, a CLV command is
; needed on the HP-42S because variables can be user-defined up to 7 characters
; long, so there needs to be a way to delete them. But on the TI-83+/84+, there
; are only fixed number of single-letter variables, 27. So it is not critical
; to be able to delete a single variable, or even the whole group of them.
;
; ClearVars:
;     ; Set OP1 to the variable name 'A', 4 bytes: [RealObj, tA, 0, 0].
;     ld hl, RealObj + (tA * 256)
;     ld (OP1), hl
;     ld hl, 0
;     ld (OP1 + 2), hl
;     ; Setup loop for A-Z and Theta. TI-OS cleverly placed the tTheta token
;     ; ($5B) to be just after the tZ token ($5A), so we can just loop 27 times
;     ; starting with tA ($41).
;     ; variables.
;     ld hl, OP1
;     ld b, 27
; clearVarsLoop:
;     call clearVar
;     inc hl
;     inc (hl) ; increment the variable name tA to tTheta
;     dec hl
;     djnz clearVarsLoop
;     ld a, errorCodeVarsDeleted
;     ld (handlerCode), a
;     ret
;     ;
; clearVar:
;     push bc
;     push hl
;     bcall(_FindSym) ; CF=1 if not found; B!=0 if archived
;     jr c, clearVarEnd
;     ld a, b
;     or a
;     jr nz, clearVarEnd
;     bcall(_DelVarNoArc)
; clearVarEnd:
;     pop hl
;     pop bc
;     ret
