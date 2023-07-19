;-----------------------------------------------------------------------------
; Menu hierarchy definitions, hand-generated from menudevdef.txt.
; See menu.asm for the equivalent C struct declaration.
;-----------------------------------------------------------------------------

; Depth-first serialization of the menu hierarchy.
mMenuTable:
; Null Item
mNull:
mNullId equ 0
    .db mNullId ; id
    .db mNullId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler
; Root
mRoot:
mRootId equ 1
    .db mRootId ; id
    .db mNullId ; parentId
    .db mRootNameId ; nameId
    .db 2 ; numStrips
    .db mNumId ; stripBeginId
    .dw mGroupHandler
; Root > Strip 0
mNum:
mNumId equ 2
    .db mNumId ; id
    .db mRootId ; parentId
    .db mNumNameId ; nameId
    .db 2 ; numStrips
    .db mCubeId ; stripBeginId
    .dw mGroupHandler
mProb:
mProbId equ 3
    .db mProbId ; id
    .db mRootId ; parentId
    .db mProbNameId ; nameId
    .db 1 ; numStrips
    .db mPermId ; stripBeginId
    .dw mGroupHandler
mBlank01:
mBlank01Id equ 4
	.db mBlank00Id ; id
	.db mRootId ; parentId
	.db mNullNameId ; nameId
	.db 0 ; numStrips
	.db 0 ; stripBeginId
    .dw mNullHandler
mBlank02:
mBlank02Id equ 5
	.db mBlank00Id ; id
	.db mRootId ; parentId
	.db mNullNameId ; nameId
	.db 0 ; numStrips
	.db 0 ; stripBeginId
    .dw mNullHandler
mHelp:
mHelpId equ 6
    .db mHelpId ; id
    .db mRootId ; parentId
    .db mHelpNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler
; Root > Strip 1
mDisp:
mDispId equ 7
    .db mDispId ; id
    .db mRootId ; parentId
    .db mDispNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler
mMode:
mModeId equ 8
    .db mModeId ; id
    .db mRootId ; parentId
    .db mModeNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler
mHyperbolic:
mHyperbolicId equ 9
	.db mHyperbolicId ; id
	.db mRootId ; parentId
	.db mHyperbolicNameId ; nameId
	.db 0 ; numStrips
	.db 0 ; stripBeginId
    .dw mNullHandler
mUnit:
mUnitId equ 10
    .db mUnitId ; id
    .db mRootId ; parentId
    .db mUnitNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler
mBlank03:
mBlank03Id equ 11
	.db mBlank03Id ; id
	.db mRootId ; parentId
	.db mNullNameId ; nameId
	.db 0 ; numStrips
	.db 0 ; stripBeginId
    .dw mNullHandler
; Root > Num > Strip 0
mCube:
mCubeId equ 12
    .db mCubeId ; id
    .db mNumId ; parentId
    .db mCubeNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mCubeHandler
mCubeRoot:
mCubeRootId equ 13
    .db mCubeRootId ; id
    .db mNumId ; parentId
    .db mCubeRootNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mCubeRootHandler
mAtan2:
mAtan2Id equ 14
    .db mAtan2Id ; id
    .db mNumId ; parentId
    .db mAtan2NameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mAtan2Handler
mPercent:
mPercentId equ 15
    .db mPercentId ; id
    .db mNumId ; parentId
    .db mPercentNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mPercentHandler
mBlank00:
mBlank00Id equ 16
	.db mBlank00Id ; id
	.db mNumId ; parentId
	.db mNullNameId ; nameId
	.db 0 ; numStrips
	.db 0 ; stripBeginId
    .dw mNullHandler
; Root > Num > Strip 1
mAbs:
mAbsId equ 17
    .db mAbsId ; id
    .db mNumId ; parentId
    .db mAbsNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler
mSign:
mSignId equ 18
    .db mSignId ; id
    .db mNumId ; parentId
    .db mSignNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler
mMod:
mModId equ 19
    .db mModId ; id
    .db mNumId ; parentId
    .db mModNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler
mLcm:
mLcmId equ 20
    .db mLcmId ; id
    .db mNumId ; parentId
    .db mLcmNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler
mGcd:
mGcdId equ 21
	.db mGcdId ; id
	.db mNumId ; parentId
	.db mGcdNameId ; nameId
	.db 0 ; numStrips
	.db 0 ; stripBeginId
    .dw mNullHandler
; Root > Prob > Strip 0
mPerm:
mPermId equ 22
    .db mPermId ; id
    .db mProbId ; parentId
    .db mPermNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler
mComb:
mCombId equ 23
    .db mCombId ; id
    .db mProbId ; parentId
    .db mCombNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler
mFactorial:
mFactorialId equ 24
    .db mFactorialId ; id
    .db mProbId ; parentId
    .db mFactorialNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mFactorialHandler
mRandom:
mRandomId equ 25
    .db mRandomId ; id
    .db mProbId ; parentId
    .db mRandomNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mRandomHandler
mRandomSeed:
mRandomSeedId equ 26
    .db mRandomSeedId ; id
    .db mProbId ; parentId
    .db mRandomSeedNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler

; Table of 2-byte Offsets into Pool of Names
mMenuNameTable:
mNullNameId equ 0
    .dw mNullName
mRootNameId equ 1
    .dw mRootName
; Root > Strip 0
mNumNameId equ 2
    .dw mNumName
mProbNameId equ 3
    .dw mProbName
mHelpNameId equ 4
    .dw mHelpName
; Root > Strip 1
mDispNameId equ 5
    .dw mDispName
mModeNameId equ 6
    .dw mModeName
mHyperbolicNameId equ 7
    .dw mHyperbolicName
mUnitNameId equ 8
    .dw mUnitName
; Root > Num > Strip 0
mCubeNameId equ 9
    .dw mCubeName
mCubeRootNameId equ 10
    .dw mCubeRootName
mAtan2NameId equ 11
    .dw mAtan2Name
mPercentNameId equ 12
    .dw mPercentName
; Root > Num > Strip 1
mAbsNameId equ 13
    .dw mAbsName
mSignNameId equ 14
    .dw mSignName
mModNameId equ 15
    .dw mModName
mLcmNameId equ 16
    .dw mLcmName
mGcdNameId equ 17
    .dw mGcdName
; Root > Prob > Strip 0
mPermNameId equ 18
    .dw mPermName
mCombNameId equ 19
    .dw mCombName
mFactorialNameId equ 20
    .dw mFactorialName
mRandomNameId equ 21
    .dw mRandomName
mRandomSeedNameId equ 22
    .dw mRandomSeedName

; Table of Names as NUL terminated C strings.
mNullName:
    .db 0
mRootName:
    .db "root", 0
; Root > Strip 0
mNumName:
	.db "NUM", 0
mProbName:
	.db "PROB", 0
mHelpName:
    .db "HELP", 0
; Root > Strip 1
mDispName:
	.db "DISP", 0
mModeName:
	.db "Mode", 0
mHyperbolicName:
	.db "HYP", 0
mUnitName:
	.db "UNIT", 0
; Root > Num > Strip 0
mCubeName:
    .db "^3", 0
mCubeRootName:
    .db "CBRT", 0
mAtan2Name:
    .db "ATN2", 0
mPercentName:
    .db "%", 0
; Root > Num > Strip 1
mAbsName:
	.db "ABS", 0
mSignName:
	.db "SIGN", 0
mModName:
	.db "MOD", 0
mLcmName:
	.db "LCM", 0
mGcdName:
	.db "GCD", 0
; Root > Prob > Strip 0
mPermName:
	.db "PERM", 0
mCombName:
	.db "COMB", 0
mFactorialName:
	.db "N!", 0
mRandomName:
	.db "RND", 0
mRandomSeedName:
	.db "SEED", 0
