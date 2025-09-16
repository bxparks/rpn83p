;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2024-2025 Brian T. Park
;
; Generic DATE functions for shrinking, extending, cutting, and linking.
;
; Every handler is given the following input parameters:
;   - HL:u16=menuId
;   - CF:bool
;       - 0 indicates 'onEnter' event into group
;       - 1 indicates 'onExit' event from group
;-----------------------------------------------------------------------------

; Description: Determine if the year or Date-like object is a leap year.
; Input:
;   - CP1:Real|RpnDate|RpnDateTime|RpnOffsetDateTime
;   - A:u8=objectType
; Output:
;   - CP1:Real=1 if leap; 0 if not leap
GenericDateIsLeap:
    cp rpnObjectTypeReal
    jp z, IsYearLeap
    cp rpnObjectTypeDate
    jp z, IsDateLeap
    cp rpnObjectTypeDateTime
    jp z, IsDateLeap
    cp rpnObjectTypeOffsetDateTime
    jp z, IsDateLeap
    bcall(_ErrDataType)

;-----------------------------------------------------------------------------

; Description: Shrink RpnDateTime to RpnDate, or RpnOffsetDateTime to
; RpnDateTime. The reverse of Extend.
; Input:
;   - CP1:RpnDateTime|RpnOffsetDateTime
;   - A:u8=objectType
; Output:
;   - CP1:RpnDate|RpnDateTime
GenericDateShrink:
    cp rpnObjectTypeDateTime ; ZF=1 if RpnDateTime
    jr z, dateShrinkRpnDateTime
    cp rpnObjectTypeOffsetDateTime ; ZF=1 if RpnOffsetDateTime
    jr z, dateShrinkRpnOffsetDateTime
    bcall(_ErrDataType)
dateShrinkRpnDateTime:
    call TruncateRpnDateTime
    ret
dateShrinkRpnOffsetDateTime:
    call TruncateRpnOffsetDateTime
    ret

;-----------------------------------------------------------------------------

; Description: Extend RpnDate to RpnDateTime, or RpnDateTime to
; RpnOffsetDateTime. The reverse of Shrink.
; Input:
;   - CP1:RpnDateTime|RpnOffsetDateTime
;   - A:u8=objectType
; Output:
;   - CP1:RpnDate|RpnDateTime
GenericDateExtend:
    cp rpnObjectTypeDate ; ZF=1 if RpnDate
    jr z, dateExtendRpnDate
    cp rpnObjectTypeDateTime ; ZF=1 if RpnDateTime
    jr z, dateExtendRpnDateTime
    bcall(_ErrDataType)
dateExtendRpnDate:
    call ExtendRpnDateToDateTime ; CP1:RpnDateTime
    ret
dateExtendRpnDateTime:
    call ExtendRpnDateTimeToOffsetDateTime ; CP1:RpnOffsetDateTime
    ret

;-----------------------------------------------------------------------------

; Description: Cut RpnDateTime to (RpnDate, RpnTime) pair, or RpnOffsetDateTime
; to (RpnDateTime, RpnOffset) pair. The reverse of Link
; Input:
;   - CP1:RpnDateTime|RpnOffsetDateTime
;   - A:u8=objectType
; Output:
;   - CP1:RpnDate|RpnTime|RpnDateTime
;   - CP3:RpnDate|RpnTime|RpnDateTime
GenericDateCut:
    cp rpnObjectTypeDateTime ; ZF=1 if RpnDateTime
    jr z, dateCutRpnDateTime
    cp rpnObjectTypeOffsetDateTime ; ZF=1 if RpnOffsetDateTime
    jr z, dateCutRpnOffsetDateTime
    bcall(_ErrDataType)
dateCutRpnDateTime:
    call SplitRpnDateTime ; CP1=X=RpnTime; CP3=Y=RpnDate
    ret
dateCutRpnOffsetDateTime:
    call SplitRpnOffsetDateTime ; CP1=X=RpnOffset; CP3=Y=RpnDateTime
    ret

;-----------------------------------------------------------------------------

; Description: Link (RpnDate, RpnTime) pair to RpnDateTime, or (RpnDateTime,
; RpnOffset) pair to RpnOffsetDateTime. The reverse of Cut.
; Input:
;   - CP1:RpnDate|RpnDateTime|RpnOffsetDateTime=Y
;   - CP3:RpnDate|RpnDateTime|RpnOffsetDateTime=X
; Output:
;   - CP1:RpnDateTime|RpnOffsetDateTime
GenericDateLink:
    call getOp1RpnObjectTypePageTwo ; A=rpnObjectTypeY
    cp rpnObjectTypeTime ; ZF=1 if RpnTime
    jr z, dateLinkTime
    cp rpnObjectTypeDate ; ZF=1 if RpnDate
    jr z, dateLinkDate
    cp rpnObjectTypeOffset ; ZF=1 if RpnOffset
    jr z, dateLinkOffset
    cp rpnObjectTypeDateTime ; ZF=1 if RpnDateTime
    jr z, dateLinkDateTime
dateLinkErrDataType:
    bcall(_ErrDataType)
dateLinkTime:
    call checkOp3DatePageTwo
    jr nz, dateLinkErrDataType
    jp MergeRpnDateWithRpnTime ; CP1=rpnDateTime
dateLinkDate:
    call checkOp3TimePageTwo
    jr nz, dateLinkErrDataType
    jp MergeRpnDateWithRpnTime ; CP1=rpnDateTime
dateLinkOffset:
    call checkOp3DateTimePageTwo
    jr nz, dateLinkErrDataType
    jp MergeRpnDateTimeWithRpnOffset ; CP1=rpnOffsetDateOffset
dateLinkDateTime:
    call checkOp3OffsetPageTwo
    jr nz, dateLinkErrDataType
    jp MergeRpnDateTimeWithRpnOffset ; CP1=rpnOffsetDateTime
