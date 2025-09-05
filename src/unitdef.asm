;-----------------------------------------------------------------------------
; Table of units and their conversion information.
;-----------------------------------------------------------------------------

unitClassLength equ 0
unitClassArea equ 1
unitClassVolume equ 2

unitInfoTableSize equ 2

unitInfoTable:

unitMeterInfo:
unitMeterId equ 0
    .dw unitMeterName ; name
    .db unitClassLength ; unitClass
    .db unitMeterId ; baseUnitId
    .db $00, $80, $10, $00, $00, $00, $00, $00, $00 ; scale=1
unitFeetInfo:
unitFeetId equ 1
    .dw unitFeetName ; name
    .db unitClassLength ; unitClass
    .db unitMeterId ; baseUnitId
    .db $00, $7f, $30, $48, $00, $00, $00, $00, $00 ; scale=0.3048
unitSqMeterInfo:
unitSqMeterId equ 2
    .dw unitSqMeterName ; name
    .db unitClassArea ; unitClass
    .db unitSqMeterId ; baseUnitId
    .db $00, $80, $10, $00, $00, $00, $00, $00, $00 ; scale=1
unitSqFeetInfo:
unitSqFeetId equ 3
    .dw unitSqFeetName ; name
    .db unitClassArea ; unitClass
    .db unitSqFeetId ; baseUnitId
    .db $00, $7f, $30, $48, $00, $00, $00, $00, $00 ; scale=0.3048

; Table of names as NUL terminated C strings.
unitMeterName:
    .db "meter", 0
unitFeetName:
    .db "feet", 0
unitSqMeterName:
    .db "sq meter", 0
unitSqFeetName:
    .db "sq feet", 0
