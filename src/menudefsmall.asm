;-----------------------------------------------------------------------------
; Menu hierarchy definitions, hand-generated from menudefsmall.txt.
;-----------------------------------------------------------------------------

; Table of Nodes
mNodesTable:
mNull:
    mNullId equ 0
mRoot:
    mRootId equ 1
    .db $00+$80 ; mRoot.id=0, mRoot.type=1
    .db 0 ; mRoot.parentId=0
    .db 1 ; mRoot.nameId=1
    .db 1 ; mRoot.numStrips=1
    .db 0 ; mRoot.firstStripId=1
mHelp:
    mHelpId equ 1
    .db $01 ; mRoot.id=1, mRoot.type=0
    .db mRootId ; mRoot.parentId
    .db 2 ; mRoot.nameId=2
    .db 0 ; mRoot.numStrips=0
    .db 0 ; mRoot.firstStripId=0
mNum:
    mNumId equ 2
    .db $02+$80 ; mNum.id=2, mNum.type=1
    .db mRootId ; mNum.parentId=0
    .db 3 ; mNum.nameId=3
    .db 3 ; mNum.numStrips=3
    .db 0 ; mNum.firstStripId=0
mCube:
    mCubeId equ 3
    .db $03 ; mCube.id=3, mCube.type=0
    .db 


; Table of Strips
mStripsTable:
sRootStrip0:
    .db mHelpId
    .db mNumId
    .db mNullId
    .db mProbId
    .db mConvId


; Table of 2-byte Offsets into Pool of Names
mNamesTable:
    .dw mRootName
    .dw mHelpName
    .db mCubeName
    


; Pool of Names, NUL terminated C strings.
mRootName:
    .db "root", 0
mHelpName:
    .db "HELP", 0
mCubeName:
    .db "^3", 0
mCubeRootName:
    .db "CBRT", 0
mAtan2Name:
    .db "ATN2", 0
mPercentName:
    .db "%", 0
mDeltaPercentName:
    .db "D%", 0
    
