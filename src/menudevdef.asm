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
    .db 4 ; numStrips
    .db mPercentId ; stripBeginId
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
mDisp:
mDispId equ 7
    .db mDispId ; id
    .db mRootId ; parentId
    .db mDispNameId ; nameId
    .db 1 ; numStrips
    .db mFixId ; stripBeginId
    .dw mGroupHandler ; handler (predefined)
mMode:
mModeId equ 8
    .db mModeId ; id
    .db mRootId ; parentId
    .db mModeNameId ; nameId
    .db 1 ; numStrips
    .db mRadId ; stripBeginId
    .dw mGroupHandler ; handler (predefined)
mHyperbolic:
mHyperbolicId equ 9
    .db mHyperbolicId ; id
    .db mRootId ; parentId
    .db mHyperbolicNameId ; nameId
    .db 2 ; numStrips
    .db mBlank057Id ; stripBeginId
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
mPercent:
mPercentId equ 12
    .db mPercentId ; id
    .db mNumId ; parentId
    .db mPercentNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mPercentHandler ; handler (to be implemented)
mDeltaPercent:
mDeltaPercentId equ 13
    .db mDeltaPercentId ; id
    .db mNumId ; parentId
    .db mDeltaPercentNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mDeltaPercentHandler ; handler (to be implemented)
mBlank014:
mBlank014Id equ 14
    .db mBlank014Id ; id
    .db mNumId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler ; handler (predefined)
mBlank015:
mBlank015Id equ 15
    .db mBlank015Id ; id
    .db mNumId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler ; handler (predefined)
mBlank016:
mBlank016Id equ 16
    .db mBlank016Id ; id
    .db mNumId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler ; handler (predefined)
; MenuGroup NUM: children: strip 1
mCube:
mCubeId equ 17
    .db mCubeId ; id
    .db mNumId ; parentId
    .db mCubeNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mCubeHandler ; handler (to be implemented)
mCubeRoot:
mCubeRootId equ 18
    .db mCubeRootId ; id
    .db mNumId ; parentId
    .db mCubeRootNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mCubeRootHandler ; handler (to be implemented)
mLog2:
mLog2Id equ 19
    .db mLog2Id ; id
    .db mNumId ; parentId
    .db mLog2NameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mLog2Handler ; handler (to be implemented)
mLogBase:
mLogBaseId equ 20
    .db mLogBaseId ; id
    .db mNumId ; parentId
    .db mLogBaseNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mLogBaseHandler ; handler (to be implemented)
mAtan2:
mAtan2Id equ 21
    .db mAtan2Id ; id
    .db mNumId ; parentId
    .db mAtan2NameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mAtan2Handler ; handler (to be implemented)
; MenuGroup NUM: children: strip 2
mAbs:
mAbsId equ 22
    .db mAbsId ; id
    .db mNumId ; parentId
    .db mAbsNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mAbsHandler ; handler (to be implemented)
mSign:
mSignId equ 23
    .db mSignId ; id
    .db mNumId ; parentId
    .db mSignNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mSignHandler ; handler (to be implemented)
mMod:
mModId equ 24
    .db mModId ; id
    .db mNumId ; parentId
    .db mModNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mModHandler ; handler (to be implemented)
mMin:
mMinId equ 25
    .db mMinId ; id
    .db mNumId ; parentId
    .db mMinNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mMinHandler ; handler (to be implemented)
mMax:
mMaxId equ 26
    .db mMaxId ; id
    .db mNumId ; parentId
    .db mMaxNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mMaxHandler ; handler (to be implemented)
; MenuGroup NUM: children: strip 3
mIntPart:
mIntPartId equ 27
    .db mIntPartId ; id
    .db mNumId ; parentId
    .db mIntPartNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mIntPartHandler ; handler (to be implemented)
mFracPart:
mFracPartId equ 28
    .db mFracPartId ; id
    .db mNumId ; parentId
    .db mFracPartNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mFracPartHandler ; handler (to be implemented)
mFloor:
mFloorId equ 29
    .db mFloorId ; id
    .db mNumId ; parentId
    .db mFloorNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mFloorHandler ; handler (to be implemented)
mCeil:
mCeilId equ 30
    .db mCeilId ; id
    .db mNumId ; parentId
    .db mCeilNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mCeilHandler ; handler (to be implemented)
mNear:
mNearId equ 31
    .db mNearId ; id
    .db mNumId ; parentId
    .db mNearNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNearHandler ; handler (to be implemented)
; MenuGroup PROB: children
; MenuGroup PROB: children: strip 0
mComb:
mCombId equ 32
    .db mCombId ; id
    .db mProbId ; parentId
    .db mCombNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mCombHandler ; handler (to be implemented)
mPerm:
mPermId equ 33
    .db mPermId ; id
    .db mProbId ; parentId
    .db mPermNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mPermHandler ; handler (to be implemented)
mFactorial:
mFactorialId equ 34
    .db mFactorialId ; id
    .db mProbId ; parentId
    .db mFactorialNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mFactorialHandler ; handler (to be implemented)
mRandom:
mRandomId equ 35
    .db mRandomId ; id
    .db mProbId ; parentId
    .db mRandomNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mRandomHandler ; handler (to be implemented)
mRandomSeed:
mRandomSeedId equ 36
    .db mRandomSeedId ; id
    .db mProbId ; parentId
    .db mRandomSeedNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mRandomSeedHandler ; handler (to be implemented)
; MenuGroup UNIT: children
; MenuGroup UNIT: children: strip 0
mFToC:
mFToCId equ 37
    .db mFToCId ; id
    .db mUnitId ; parentId
    .db mFToCNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mFToCHandler ; handler (to be implemented)
mCToF:
mCToFId equ 38
    .db mCToFId ; id
    .db mUnitId ; parentId
    .db mCToFNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mCToFHandler ; handler (to be implemented)
mBlank039:
mBlank039Id equ 39
    .db mBlank039Id ; id
    .db mUnitId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler ; handler (predefined)
mMiToKm:
mMiToKmId equ 40
    .db mMiToKmId ; id
    .db mUnitId ; parentId
    .db mMiToKmNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mMiToKmHandler ; handler (to be implemented)
mKmToMi:
mKmToMiId equ 41
    .db mKmToMiId ; id
    .db mUnitId ; parentId
    .db mKmToMiNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mKmToMiHandler ; handler (to be implemented)
; MenuGroup CONV: children
; MenuGroup CONV: children: strip 0
mRToD:
mRToDId equ 42
    .db mRToDId ; id
    .db mConvId ; parentId
    .db mRToDNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mRToDHandler ; handler (to be implemented)
mDToR:
mDToRId equ 43
    .db mDToRId ; id
    .db mConvId ; parentId
    .db mDToRNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mDToRHandler ; handler (to be implemented)
mBlank044:
mBlank044Id equ 44
    .db mBlank044Id ; id
    .db mConvId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler ; handler (predefined)
mHmsToHr:
mHmsToHrId equ 45
    .db mHmsToHrId ; id
    .db mConvId ; parentId
    .db mHmsToHrNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mHmsToHrHandler ; handler (to be implemented)
mHrToHms:
mHrToHmsId equ 46
    .db mHrToHmsId ; id
    .db mConvId ; parentId
    .db mHrToHmsNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mHrToHmsHandler ; handler (to be implemented)
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
; MenuGroup MODE: children
; MenuGroup MODE: children: strip 0
mRad:
mRadId equ 52
    .db mRadId ; id
    .db mModeId ; parentId
    .db mRadNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mRadHandler ; handler (to be implemented)
mDeg:
mDegId equ 53
    .db mDegId ; id
    .db mModeId ; parentId
    .db mDegNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mDegHandler ; handler (to be implemented)
mBlank054:
mBlank054Id equ 54
    .db mBlank054Id ; id
    .db mModeId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler ; handler (predefined)
mBlank055:
mBlank055Id equ 55
    .db mBlank055Id ; id
    .db mModeId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler ; handler (predefined)
mBlank056:
mBlank056Id equ 56
    .db mBlank056Id ; id
    .db mModeId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler ; handler (predefined)
; MenuGroup HYP: children
; MenuGroup HYP: children: strip 0
mBlank057:
mBlank057Id equ 57
    .db mBlank057Id ; id
    .db mHyperbolicId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler ; handler (predefined)
mSinh:
mSinhId equ 58
    .db mSinhId ; id
    .db mHyperbolicId ; parentId
    .db mSinhNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mSinhHandler ; handler (to be implemented)
mCosh:
mCoshId equ 59
    .db mCoshId ; id
    .db mHyperbolicId ; parentId
    .db mCoshNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mCoshHandler ; handler (to be implemented)
mTanh:
mTanhId equ 60
    .db mTanhId ; id
    .db mHyperbolicId ; parentId
    .db mTanhNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mTanhHandler ; handler (to be implemented)
mBlank061:
mBlank061Id equ 61
    .db mBlank061Id ; id
    .db mHyperbolicId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler ; handler (predefined)
; MenuGroup HYP: children: strip 1
mBlank062:
mBlank062Id equ 62
    .db mBlank062Id ; id
    .db mHyperbolicId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler ; handler (predefined)
mAsinh:
mAsinhId equ 63
    .db mAsinhId ; id
    .db mHyperbolicId ; parentId
    .db mAsinhNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mAsinhHandler ; handler (to be implemented)
mAcosh:
mAcoshId equ 64
    .db mAcoshId ; id
    .db mHyperbolicId ; parentId
    .db mAcoshNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mAcoshHandler ; handler (to be implemented)
mAtanh:
mAtanhId equ 65
    .db mAtanhId ; id
    .db mHyperbolicId ; parentId
    .db mAtanhNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mAtanhHandler ; handler (to be implemented)
mBlank066:
mBlank066Id equ 66
    .db mBlank066Id ; id
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
mDispNameId equ 7
    .dw mDispName
mModeNameId equ 8
    .dw mModeName
mHyperbolicNameId equ 9
    .dw mHyperbolicName
mPercentNameId equ 10
    .dw mPercentName
mDeltaPercentNameId equ 11
    .dw mDeltaPercentName
mCubeNameId equ 12
    .dw mCubeName
mCubeRootNameId equ 13
    .dw mCubeRootName
mLog2NameId equ 14
    .dw mLog2Name
mLogBaseNameId equ 15
    .dw mLogBaseName
mAtan2NameId equ 16
    .dw mAtan2Name
mAbsNameId equ 17
    .dw mAbsName
mSignNameId equ 18
    .dw mSignName
mModNameId equ 19
    .dw mModName
mMinNameId equ 20
    .dw mMinName
mMaxNameId equ 21
    .dw mMaxName
mIntPartNameId equ 22
    .dw mIntPartName
mFracPartNameId equ 23
    .dw mFracPartName
mFloorNameId equ 24
    .dw mFloorName
mCeilNameId equ 25
    .dw mCeilName
mNearNameId equ 26
    .dw mNearName
mCombNameId equ 27
    .dw mCombName
mPermNameId equ 28
    .dw mPermName
mFactorialNameId equ 29
    .dw mFactorialName
mRandomNameId equ 30
    .dw mRandomName
mRandomSeedNameId equ 31
    .dw mRandomSeedName
mFToCNameId equ 32
    .dw mFToCName
mCToFNameId equ 33
    .dw mCToFName
mMiToKmNameId equ 34
    .dw mMiToKmName
mKmToMiNameId equ 35
    .dw mKmToMiName
mRToDNameId equ 36
    .dw mRToDName
mDToRNameId equ 37
    .dw mDToRName
mHmsToHrNameId equ 38
    .dw mHmsToHrName
mHrToHmsNameId equ 39
    .dw mHrToHmsName
mFixNameId equ 40
    .dw mFixName
mSciNameId equ 41
    .dw mSciName
mEngNameId equ 42
    .dw mEngName
mRadNameId equ 43
    .dw mRadName
mDegNameId equ 44
    .dw mDegName
mSinhNameId equ 45
    .dw mSinhName
mCoshNameId equ 46
    .dw mCoshName
mTanhNameId equ 47
    .dw mTanhName
mAsinhNameId equ 48
    .dw mAsinhName
mAcoshNameId equ 49
    .dw mAcoshName
mAtanhNameId equ 50
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
mDispName:
    .db "DISP", 0
mModeName:
    .db "MODE", 0
mHyperbolicName:
    .db "HYP", 0
mPercentName:
    .db Spercent, 0
mDeltaPercentName:
    .db ScapDelta, Spercent, 0
mCubeName:
    .db 'X', Scaret, '3', 0
mCubeRootName:
    .db ScubeR, Sroot, 'X', 0
mLog2Name:
    .db "LOG2", 0
mLogBaseName:
    .db "LOGB", 0
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
mHmsToHrName:
    .db Sconvert, 'H', 'R', 0
mHrToHmsName:
    .db Sconvert, 'H', 'M', 'S', 0
mFixName:
    .db "FIX", 0
mSciName:
    .db "SCI", 0
mEngName:
    .db "ENG", 0
mRadName:
    .db "RAD", 0
mDegName:
    .db "DEG", 0
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
