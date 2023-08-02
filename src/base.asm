; Routines to handle calculations in different bases (2, 8, 10, 16).

initBase:
    ld a, 10
    ld (baseMode), a
    ret
