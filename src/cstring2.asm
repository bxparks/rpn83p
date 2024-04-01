;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Low-level routines for manipulating C strings (NUL terminated).
;-----------------------------------------------------------------------------

; Description: Copy the C string in HL to DE.
; Input: HL, DE: C string
; Output: DE: points to terminating NUL
; Destroys: A
copyCStringPageTwo:
    ld a, (hl)
    ld (de), a
    or a
    ret z
    inc hl
    inc de
    jr copyCStringPageTwo

;-----------------------------------------------------------------------------

; Description: Get the string pointer at index A given an array of pointers at
; base pointer HL. Out-of-bounds is NOT checked. Duplicate of getString() but
; located in Flash Page 1.
;
; Input:
;   - A=index
;   - HL:(const char* const*) pointer to an array of pointers
; Output:
;   - HL:(const char*)=string
; Destroys: DE, HL
; Preserves: A
getStringPageTwo:
    ld e, a
    ld d, 0
    ; [[fallthrough]]

; Description: Get the string pointer at index DE given an array of pointers at
; base pointer HL. Out-of-bounds is NOT checked. Duplicate of getDEString() but
; located in Flash Page 1.
;
; Input:
;   - DE=index
;   - HL:(const char* const*)=pointer to array of string pointers
; Output:
;   - HL:(const char*)=string
; Destroys: DE, HL
; Preserves: A, BC
getDEStringPageTwo:
    add hl, de ; HL+=DE*2
    add hl, de
    ld e, (hl)
    inc hl
    ld d, (hl)
    ex de, hl ; HL=stringPointer
    ret
