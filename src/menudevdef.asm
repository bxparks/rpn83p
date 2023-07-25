;-----------------------------------------------------------------------------
; Menu hierarchy definitions, generated from menudevdef.txt.
; See menu.asm for the equivalent C struct declaration.
;
; The following symbols are reserved and pre-generated by the compilemenu.py
; script:
;   - mNull
;   - mNullId
;   - mNullName
;   - mNullNameId
;   - mNullHandler
;   - mGroupHandler
;
; The following symbols are not reserved, but they recommended to be used
; for the root menu:
;   - mRoot
;   - mRootId
;   - mRootNameId
;
; DO NOT EDIT: This file was autogenerated.
;-----------------------------------------------------------------------------

mMenuTable:
mNull:
mNullId equ 0
    .db mNullId ; id
    .db mNullId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler
mRoot:
mRootId equ 1
    .db mRootId ; id
    .db mNullId ; parentId
    .db mRootNameId ; nameId
    .db 2 ; numStrips
    .db mNumId ; stripBeginId
    .dw mGroupHandler ; handler (predefined)
; MenuGroup root: children
; MenuGroup root: children: strip 0
mNum:
mNumId equ 2
    .db mNumId ; id
    .db mRootId ; parentId
    .db mNumNameId ; nameId
    .db 3 ; numStrips
    .db mCubeId ; stripBeginId
    .dw mGroupHandler ; handler (predefined)
mProb:
mProbId equ 3
    .db mProbId ; id
    .db mRootId ; parentId
    .db mProbNameId ; nameId
    .db 1 ; numStrips
    .db mCombId ; stripBeginId
    .dw mGroupHandler ; handler (predefined)
mUnit:
mUnitId equ 4
    .db mUnitId ; id
    .db mRootId ; parentId
    .db mUnitNameId ; nameId
    .db 1 ; numStrips
    .db mFToCId ; stripBeginId
    .dw mGroupHandler ; handler (predefined)
mConv:
mConvId equ 5
    .db mConvId ; id
    .db mRootId ; parentId
    .db mConvNameId ; nameId
    .db 1 ; numStrips
    .db mRToDId ; stripBeginId
    .dw mGroupHandler ; handler (predefined)
mHelp:
mHelpId equ 6
    .db mHelpId ; id
    .db mRootId ; parentId
    .db mHelpNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mHelpHandler ; handler (to be implemented)
; MenuGroup root: children: strip 1
mMode:
mModeId equ 7
    .db mModeId ; id
    .db mRootId ; parentId
    .db mModeNameId ; nameId
    .db 1 ; numStrips
    .db mRadId ; stripBeginId
    .dw mGroupHandler ; handler (predefined)
mDisp:
mDispId equ 8
    .db mDispId ; id
    .db mRootId ; parentId
    .db mDispNameId ; nameId
    .db 1 ; numStrips
    .db mFixId ; stripBeginId
    .dw mGroupHandler ; handler (predefined)
mHyperbolic:
mHyperbolicId equ 9
    .db mHyperbolicId ; id
    .db mRootId ; parentId
    .db mHyperbolicNameId ; nameId
    .db 2 ; numStrips
    .db mBlank052Id ; stripBeginId
    .dw mGroupHandler ; handler (predefined)
mBlank010:
mBlank010Id equ 10
    .db mBlank010Id ; id
    .db mRootId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler ; handler (predefined)
mBlank011:
mBlank011Id equ 11
    .db mBlank011Id ; id
    .db mRootId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler ; handler (predefined)
; MenuGroup NUM: children
; MenuGroup NUM: children: strip 0
mCube:
mCubeId equ 12
    .db mCubeId ; id
    .db mNumId ; parentId
    .db mCubeNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mCubeHandler ; handler (to be implemented)
mCubeRoot:
mCubeRootId equ 13
    .db mCubeRootId ; id
    .db mNumId ; parentId
    .db mCubeRootNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mCubeRootHandler ; handler (to be implemented)
mPercent:
mPercentId equ 14
    .db mPercentId ; id
    .db mNumId ; parentId
    .db mPercentNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mPercentHandler ; handler (to be implemented)
mAtan2:
mAtan2Id equ 15
    .db mAtan2Id ; id
    .db mNumId ; parentId
    .db mAtan2NameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mAtan2Handler ; handler (to be implemented)
mBlank016:
mBlank016Id equ 16
    .db mBlank016Id ; id
    .db mNumId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler ; handler (predefined)
; MenuGroup NUM: children: strip 1
mAbs:
mAbsId equ 17
    .db mAbsId ; id
    .db mNumId ; parentId
    .db mAbsNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mAbsHandler ; handler (to be implemented)
mSign:
mSignId equ 18
    .db mSignId ; id
    .db mNumId ; parentId
    .db mSignNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mSignHandler ; handler (to be implemented)
mMod:
mModId equ 19
    .db mModId ; id
    .db mNumId ; parentId
    .db mModNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mModHandler ; handler (to be implemented)
mMin:
mMinId equ 20
    .db mMinId ; id
    .db mNumId ; parentId
    .db mMinNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mMinHandler ; handler (to be implemented)
mMax:
mMaxId equ 21
    .db mMaxId ; id
    .db mNumId ; parentId
    .db mMaxNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mMaxHandler ; handler (to be implemented)
; MenuGroup NUM: children: strip 2
mIntPart:
mIntPartId equ 22
    .db mIntPartId ; id
    .db mNumId ; parentId
    .db mIntPartNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mIntPartHandler ; handler (to be implemented)
mFracPart:
mFracPartId equ 23
    .db mFracPartId ; id
    .db mNumId ; parentId
    .db mFracPartNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mFracPartHandler ; handler (to be implemented)
mFloor:
mFloorId equ 24
    .db mFloorId ; id
    .db mNumId ; parentId
    .db mFloorNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mFloorHandler ; handler (to be implemented)
mCeil:
mCeilId equ 25
    .db mCeilId ; id
    .db mNumId ; parentId
    .db mCeilNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mCeilHandler ; handler (to be implemented)
mNear:
mNearId equ 26
    .db mNearId ; id
    .db mNumId ; parentId
    .db mNearNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNearHandler ; handler (to be implemented)
; MenuGroup PROB: children
; MenuGroup PROB: children: strip 0
mComb:
mCombId equ 27
    .db mCombId ; id
    .db mProbId ; parentId
    .db mCombNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mCombHandler ; handler (to be implemented)
mPerm:
mPermId equ 28
    .db mPermId ; id
    .db mProbId ; parentId
    .db mPermNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mPermHandler ; handler (to be implemented)
mFactorial:
mFactorialId equ 29
    .db mFactorialId ; id
    .db mProbId ; parentId
    .db mFactorialNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mFactorialHandler ; handler (to be implemented)
mRandom:
mRandomId equ 30
    .db mRandomId ; id
    .db mProbId ; parentId
    .db mRandomNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mRandomHandler ; handler (to be implemented)
mRandomSeed:
mRandomSeedId equ 31
    .db mRandomSeedId ; id
    .db mProbId ; parentId
    .db mRandomSeedNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mRandomSeedHandler ; handler (to be implemented)
; MenuGroup UNIT: children
; MenuGroup UNIT: children: strip 0
mFToC:
mFToCId equ 32
    .db mFToCId ; id
    .db mUnitId ; parentId
    .db mFToCNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mFToCHandler ; handler (to be implemented)
mCToF:
mCToFId equ 33
    .db mCToFId ; id
    .db mUnitId ; parentId
    .db mCToFNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mCToFHandler ; handler (to be implemented)
mBlank034:
mBlank034Id equ 34
    .db mBlank034Id ; id
    .db mUnitId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler ; handler (predefined)
mMiToKm:
mMiToKmId equ 35
    .db mMiToKmId ; id
    .db mUnitId ; parentId
    .db mMiToKmNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mMiToKmHandler ; handler (to be implemented)
mKmToMi:
mKmToMiId equ 36
    .db mKmToMiId ; id
    .db mUnitId ; parentId
    .db mKmToMiNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mKmToMiHandler ; handler (to be implemented)
; MenuGroup CONV: children
; MenuGroup CONV: children: strip 0
mRToD:
mRToDId equ 37
    .db mRToDId ; id
    .db mConvId ; parentId
    .db mRToDNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mRToDHandler ; handler (to be implemented)
mDToR:
mDToRId equ 38
    .db mDToRId ; id
    .db mConvId ; parentId
    .db mDToRNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mDToRHandler ; handler (to be implemented)
mBlank039:
mBlank039Id equ 39
    .db mBlank039Id ; id
    .db mConvId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler ; handler (predefined)
mHrToHms:
mHrToHmsId equ 40
    .db mHrToHmsId ; id
    .db mConvId ; parentId
    .db mHrToHmsNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mHrToHmsHandler ; handler (to be implemented)
mHmsToHr:
mHmsToHrId equ 41
    .db mHmsToHrId ; id
    .db mConvId ; parentId
    .db mHmsToHrNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mHmsToHrHandler ; handler (to be implemented)
; MenuGroup MODE: children
; MenuGroup MODE: children: strip 0
mRad:
mRadId equ 42
    .db mRadId ; id
    .db mModeId ; parentId
    .db mRadNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mRadHandler ; handler (to be implemented)
mDeg:
mDegId equ 43
    .db mDegId ; id
    .db mModeId ; parentId
    .db mDegNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mDegHandler ; handler (to be implemented)
mBlank044:
mBlank044Id equ 44
    .db mBlank044Id ; id
    .db mModeId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler ; handler (predefined)
mBlank045:
mBlank045Id equ 45
    .db mBlank045Id ; id
    .db mModeId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler ; handler (predefined)
mBlank046:
mBlank046Id equ 46
    .db mBlank046Id ; id
    .db mModeId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler ; handler (predefined)
; MenuGroup DISP: children
; MenuGroup DISP: children: strip 0
mFix:
mFixId equ 47
    .db mFixId ; id
    .db mDispId ; parentId
    .db mFixNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mFixHandler ; handler (to be implemented)
mSci:
mSciId equ 48
    .db mSciId ; id
    .db mDispId ; parentId
    .db mSciNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mSciHandler ; handler (to be implemented)
mEng:
mEngId equ 49
    .db mEngId ; id
    .db mDispId ; parentId
    .db mEngNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mEngHandler ; handler (to be implemented)
mBlank050:
mBlank050Id equ 50
    .db mBlank050Id ; id
    .db mDispId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler ; handler (predefined)
mBlank051:
mBlank051Id equ 51
    .db mBlank051Id ; id
    .db mDispId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler ; handler (predefined)
; MenuGroup HYP: children
; MenuGroup HYP: children: strip 0
mBlank052:
mBlank052Id equ 52
    .db mBlank052Id ; id
    .db mHyperbolicId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler ; handler (predefined)
mSinh:
mSinhId equ 53
    .db mSinhId ; id
    .db mHyperbolicId ; parentId
    .db mSinhNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mSinhHandler ; handler (to be implemented)
mCosh:
mCoshId equ 54
    .db mCoshId ; id
    .db mHyperbolicId ; parentId
    .db mCoshNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mCoshHandler ; handler (to be implemented)
mTanh:
mTanhId equ 55
    .db mTanhId ; id
    .db mHyperbolicId ; parentId
    .db mTanhNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mTanhHandler ; handler (to be implemented)
mBlank056:
mBlank056Id equ 56
    .db mBlank056Id ; id
    .db mHyperbolicId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler ; handler (predefined)
; MenuGroup HYP: children: strip 1
mBlank057:
mBlank057Id equ 57
    .db mBlank057Id ; id
    .db mHyperbolicId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler ; handler (predefined)
mAsinh:
mAsinhId equ 58
    .db mAsinhId ; id
    .db mHyperbolicId ; parentId
    .db mAsinhNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mAsinhHandler ; handler (to be implemented)
mAcosh:
mAcoshId equ 59
    .db mAcoshId ; id
    .db mHyperbolicId ; parentId
    .db mAcoshNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mAcoshHandler ; handler (to be implemented)
mAtanh:
mAtanhId equ 60
    .db mAtanhId ; id
    .db mHyperbolicId ; parentId
    .db mAtanhNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mAtanhHandler ; handler (to be implemented)
mBlank061:
mBlank061Id equ 61
    .db mBlank061Id ; id
    .db mHyperbolicId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler ; handler (predefined)

; Table of 2-byte pointers to names in the pool of strings below.
mMenuNameTable:
mNullNameId equ 0
    .dw mNullName
mRootNameId equ 1
    .dw mRootName
mNumNameId equ 2
    .dw mNumName
mProbNameId equ 3
    .dw mProbName
mUnitNameId equ 4
    .dw mUnitName
mConvNameId equ 5
    .dw mConvName
mHelpNameId equ 6
    .dw mHelpName
mModeNameId equ 7
    .dw mModeName
mDispNameId equ 8
    .dw mDispName
mHyperbolicNameId equ 9
    .dw mHyperbolicName
mCubeNameId equ 10
    .dw mCubeName
mCubeRootNameId equ 11
    .dw mCubeRootName
mPercentNameId equ 12
    .dw mPercentName
mAtan2NameId equ 13
    .dw mAtan2Name
mAbsNameId equ 14
    .dw mAbsName
mSignNameId equ 15
    .dw mSignName
mModNameId equ 16
    .dw mModName
mMinNameId equ 17
    .dw mMinName
mMaxNameId equ 18
    .dw mMaxName
mIntPartNameId equ 19
    .dw mIntPartName
mFracPartNameId equ 20
    .dw mFracPartName
mFloorNameId equ 21
    .dw mFloorName
mCeilNameId equ 22
    .dw mCeilName
mNearNameId equ 23
    .dw mNearName
mCombNameId equ 24
    .dw mCombName
mPermNameId equ 25
    .dw mPermName
mFactorialNameId equ 26
    .dw mFactorialName
mRandomNameId equ 27
    .dw mRandomName
mRandomSeedNameId equ 28
    .dw mRandomSeedName
mFToCNameId equ 29
    .dw mFToCName
mCToFNameId equ 30
    .dw mCToFName
mMiToKmNameId equ 31
    .dw mMiToKmName
mKmToMiNameId equ 32
    .dw mKmToMiName
mRToDNameId equ 33
    .dw mRToDName
mDToRNameId equ 34
    .dw mDToRName
mHrToHmsNameId equ 35
    .dw mHrToHmsName
mHmsToHrNameId equ 36
    .dw mHmsToHrName
mRadNameId equ 37
    .dw mRadName
mDegNameId equ 38
    .dw mDegName
mFixNameId equ 39
    .dw mFixName
mSciNameId equ 40
    .dw mSciName
mEngNameId equ 41
    .dw mEngName
mSinhNameId equ 42
    .dw mSinhName
mCoshNameId equ 43
    .dw mCoshName
mTanhNameId equ 44
    .dw mTanhName
mAsinhNameId equ 45
    .dw mAsinhName
mAcoshNameId equ 46
    .dw mAcoshName
mAtanhNameId equ 47
    .dw mAtanhName

; Table of names as NUL terminated C strings.
mNullName:
    .db 0
mRootName:
    .db "root", 0
mNumName:
    .db "NUM", 0
mProbName:
    .db "PROB", 0
mUnitName:
    .db "UNIT", 0
mConvName:
    .db "CONV", 0
mHelpName:
    .db "HELP", 0
mModeName:
    .db "MODE", 0
mDispName:
    .db "DISP", 0
mHyperbolicName:
    .db "HYP", 0
mCubeName:
    .db 'X', Scaret, '3', 0
mCubeRootName:
    .db ScubeR, Sroot, 'X', 0
mPercentName:
    .db Spercent, 0
mAtan2Name:
    .db "ATN2", 0
mAbsName:
    .db "ABS", 0
mSignName:
    .db "SIGN", 0
mModName:
    .db "MOD", 0
mMinName:
    .db "MIN", 0
mMaxName:
    .db "MAX", 0
mIntPartName:
    .db "IP", 0
mFracPartName:
    .db "FP", 0
mFloorName:
    .db "FLR", 0
mCeilName:
    .db "CEIL", 0
mNearName:
    .db "NEAR", 0
mCombName:
    .db "COMB", 0
mPermName:
    .db "PERM", 0
mFactorialName:
    .db 'N', Sexclam, 0
mRandomName:
    .db "RAND", 0
mRandomSeedName:
    .db "SEED", 0
mFToCName:
    .db Sconvert, Stemp, 'C', 0
mCToFName:
    .db Sconvert, Stemp, 'F', 0
mMiToKmName:
    .db Sconvert, 'k', 'm', 0
mKmToMiName:
    .db Sconvert, 'm', 'i', 0
mRToDName:
    .db Sconvert, 'D', 'E', 'G', 0
mDToRName:
    .db Sconvert, 'R', 'A', 'D', 0
mHrToHmsName:
    .db Sconvert, 'H', 'M', 'S', 0
mHmsToHrName:
    .db Sconvert, 'H', 'R', 0
mRadName:
    .db "RAD", 0
mDegName:
    .db "DEG", 0
mFixName:
    .db "FIX", 0
mSciName:
    .db "SCI", 0
mEngName:
    .db "ENG", 0
mSinhName:
    .db "SINH", 0
mCoshName:
    .db "COSH", 0
mTanhName:
    .db "TANH", 0
mAsinhName:
    .db "ASNH", 0
mAcoshName:
    .db "ACSH", 0
mAtanhName:
    .db "ATNH", 0
