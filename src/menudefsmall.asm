;-----------------------------------------------------------------------------
; Menu hierarchy definitions, hand-generated from menudefsmall.txt.
;
; The equivalent C struct declarations are the following:
;
; struct MenuNode {
; 	u8 id; // root begins with 1
; 	u8 parentId; // 0 indicates NONE
; 	u8 nameId; // index into NameTable
; 	u8 numStrips; // 0: Item; >=1: Group
; 	u8 stripBeginId; // nodeId of the first node of first strip
; };
;
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
; Root
mRoot:
mRootId equ 1
    .db mRootId ; id
    .db mNullId ; parentId
    .db mRootNameId ; nameId
    .db 1 ; numStrips
    .db 2 ; stripBeginId
; Root > Strip 0
mNum:
mNumId equ 2
    .db mNumId ; id
    .db mRootId ; parentId
    .db mNumNameId ; nameId
    .db 2 ; numStrips
    .db 7 ; stripBeginId
mProb:
mProbId equ 3
    .db mProbId ; id
    .db mRootId ; parentId
    .db mProbNameId ; nameId
    .db 1 ; numStrips
    .db 17 ; stripBeginId
mBlank01:
mBlank01Id equ 4
	.db mBlank00Id ; id
	.db mRootId ; parentId
	.db mNullNameId ; nameId
	.db 0 ; numStrips
	.db 0 ; stripBeginId
mBlank02:
mBlank02Id equ 5
	.db mBlank00Id ; id
	.db mRootId ; parentId
	.db mNullNameId ; nameId
	.db 0 ; numStrips
	.db 0 ; stripBeginId
mHelp:
mHelpId equ 6
    .db mHelpId ; id
    .db mRootId ; parentId
    .db mHelpNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
; Root > Num > Strip 0
mCube:
mCubeId equ 7
    .db mCubeId ; id
    .db mNumId ; parentId
    .db mCubeNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
mCubeRoot:
mCubeRootId equ 8
    .db mCubeRootId ; id
    .db mNumId ; parentId
    .db mCubeRootNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
mAtan2:
mAtan2Id equ 9
    .db mAtan2Id ; id
    .db mNumId ; parentId
    .db mAtan2NameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
mPercent:
mPercentId equ 10
    .db mPercentId ; id
    .db mNumId ; parentId
    .db mPercentNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
mBlank00:
mBlank00Id equ 11
	.db mBlank00Id ; id
	.db mNumId ; parentId
	.db mNullNameId ; nameId
	.db 0 ; numStrips
	.db 0 ; stripBeginId
; Root > Num > Strip 1
mAbs:
mAbsId equ 12
    .db mAbsId ; id
    .db mNumId ; parentId
    .db mAbsNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
mSign:
mSignId equ 13
    .db mSignId ; id
    .db mNumId ; parentId
    .db mSignNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
mMod:
mModId equ 14
    .db mModId ; id
    .db mNumId ; parentId
    .db mModNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
mLcm:
mLcmId equ 15
    .db mLcmId ; id
    .db mNumId ; parentId
    .db mLcmNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
mGcd:
mGcdId equ 16
	.db mGcdId ; id
	.db mNumId ; parentId
	.db mGcdNameId ; nameId
	.db 0 ; numStrips
	.db 0 ; stripBeginId
; Root > Prob > Strip 0
mPerm:
mPermId equ 17
    .db mPermId ; id
    .db mProbId ; parentId
    .db mPermNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
mComb:
mCombId equ 18
    .db mCombId ; id
    .db mProbId ; parentId
    .db mCombNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
mFactorial:
mFactorialId equ 19
    .db mFactorialId ; id
    .db mProbId ; parentId
    .db mFactorialNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
mRandom:
mRandomId equ 20
    .db mRandomId ; id
    .db mProbId ; parentId
    .db mRandomNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
mRandomSeed:
mRandomSeedId equ 21
    .db mRandomSeedId ; id
    .db mProbId ; parentId
    .db mRandomSeedNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId

; Table of 2-byte Offsets into Pool of Names
mNameTable:
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
; Root > Num > Strip 0
mCubeNameId equ 5
    .dw mCubeName
mCubeRootNameId equ 6
    .dw mCubeRootName
mAtan2NameId equ 7
    .dw mAtan2Name
mPercentNameId equ 8
    .dw mPercentName
; Root > Num > Strip 1
mAbsNameId equ 9
    .dw mAbsName
mSignNameId equ 10
    .dw mSignName
mModNameId equ 11
    .dw mModName
mLcmNameId equ 12
    .dw mLcmName
mGcdNameId equ 13
    .dw mGcdName
; Root > Prob > Strip 0
mPermNameId equ 14
    .dw mPermName
mCombNameId equ 15
    .dw mCombName
mFactorialNameId equ 16
    .dw mFactorialName
mRandomNameId equ 17
    .dw mRandomName
mRandomSeedNameId equ 18
    .dw mRandomSeedName

; Table of Names as NUL terminated C strings.
mNameBase:
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
