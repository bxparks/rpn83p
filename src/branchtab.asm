;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2025 Brian T. Park
;
; Branch table entries are placed on Flash Page 0. They can be called from any
; other flash page using the bcall() macro. It is possible to put routines on
; Flash Page 0 in the branch table as well, and make them available to other
; flash pages. However, we don't do that in this project. The dependencies are
; maintained so that Flash Page 0 contains the main event handler loop and the
; various handlers. Those handlers depend on other flash pages, but code on
; other flash pages does not depend on code on Flash Page 0.
;
; The spasm-ng documentation in Appendix A mentioned above recommends that each
; bcall() entry is defined by the expression `(44+n)*3` where `n` starts at 0
; and increments by one for each entry. The problem with that method is that it
; becomes a chore to maintain the correct `n` index when entries are added or
; removed.
;
; Instead, let's define the bcall() labels as offsets from start of flash page,
; $4000. When entries are added or removed, all the labels are automatically
; updated. Warning: spasm-ng cannot handle forward references in `equ`
; statements, so we have to define the bcall() label *after* the XxxLabel
; label.
;-----------------------------------------------------------------------------

branchTableBase equ $4000

;-----------------------------------------------------------------------------
; Branch table entries for routines on Flash Page 1.
;-----------------------------------------------------------------------------

; varsstack1.asm
_InitStackLabel:
_InitStack equ _InitStackLabel-branchTableBase
    .dw InitStack
    .db 1
_InitLastXLabel:
_InitLastX equ _InitLastXLabel-branchTableBase
    .dw InitLastX
    .db 1
_ClearStackLabel:
_ClearStack equ _ClearStackLabel-branchTableBase
    .dw ClearStack
    .db 1
_CloseStackLabel:
_CloseStack equ _CloseStackLabel-branchTableBase
    .dw CloseStack
    .db 1
_LenStackLabel:
_LenStack equ _LenStackLabel-branchTableBase
    .dw LenStack
    .db 1
_ResizeStackLabel:
_ResizeStack equ _ResizeStackLabel-branchTableBase
    .dw ResizeStack
    .db 1
;
_StoStackXLabel:
_StoStackX equ _StoStackXLabel-branchTableBase
    .dw StoStackX
    .db 1
_RclStackXLabel:
_RclStackX equ _RclStackXLabel-branchTableBase
    .dw RclStackX
    .db 1
_StoStackYLabel:
_StoStackY equ _StoStackYLabel-branchTableBase
    .dw StoStackY
    .db 1
_RclStackYLabel:
_RclStackY equ _RclStackYLabel-branchTableBase
    .dw RclStackY
    .db 1
_StoStackZLabel:
_StoStackZ equ _StoStackZLabel-branchTableBase
    .dw StoStackZ
    .db 1
_RclStackZLabel:
_RclStackZ equ _RclStackZLabel-branchTableBase
    .dw RclStackZ
    .db 1
_StoStackTLabel:
_StoStackT equ _StoStackTLabel-branchTableBase
    .dw StoStackT
    .db 1
_RclStackTLabel:
_RclStackT equ _RclStackTLabel-branchTableBase
    .dw RclStackT
    .db 1
_StoStackLLabel:
_StoStackL equ _StoStackLLabel-branchTableBase
    .dw StoStackL
    .db 1
_RclStackLLabel:
_RclStackL equ _RclStackLLabel-branchTableBase
    .dw RclStackL
    .db 1
;
_RclStackXYLabel:
_RclStackXY equ _RclStackXYLabel-branchTableBase
    .dw RclStackXY
    .db 1
;
_ReplaceStackXLabel:
_ReplaceStackX equ _ReplaceStackXLabel-branchTableBase
    .dw ReplaceStackX
    .db 1
_ReplaceStackXYLabel:
_ReplaceStackXY equ _ReplaceStackXYLabel-branchTableBase
    .dw ReplaceStackXY
    .db 1
_ReplaceStackXYWithOP1OP2Label:
_ReplaceStackXYWithOP1OP2 equ _ReplaceStackXYWithOP1OP2Label-branchTableBase
    .dw ReplaceStackXYWithOP1OP2
    .db 1
_ReplaceStackXWithOP1OP2Label:
_ReplaceStackXWithOP1OP2 equ _ReplaceStackXWithOP1OP2Label-branchTableBase
    .dw ReplaceStackXWithOP1OP2
    .db 1
_ReplaceStackXWithCP1CP3Label:
_ReplaceStackXWithCP1CP3 equ _ReplaceStackXWithCP1CP3Label-branchTableBase
    .dw ReplaceStackXWithCP1CP3
    .db 1
;
_PushToStackXLabel:
_PushToStackX equ _PushToStackXLabel-branchTableBase
    .dw PushToStackX
    .db 1
_PushOp1Op2ToStackXYLabel:
_PushOp1Op2ToStackXY equ _PushOp1Op2ToStackXYLabel-branchTableBase
    .dw PushOp1Op2ToStackXY
    .db 1
;
_LiftStackIfEnabledLabel:
_LiftStackIfEnabled equ _LiftStackIfEnabledLabel-branchTableBase
    .dw LiftStackIfEnabled
    .db 1
_LiftStackLabel:
_LiftStack equ _LiftStackLabel-branchTableBase
    .dw LiftStack
    .db 1
_RollUpStackLabel:
_RollUpStack equ _RollUpStackLabel-branchTableBase
    .dw RollUpStack
    .db 1
_DropStackLabel:
_DropStack equ _DropStackLabel-branchTableBase
    .dw DropStack
    .db 1
_RollDownStackLabel:
_RollDownStack equ _RollDownStackLabel-branchTableBase
    .dw RollDownStack
    .db 1
_ExchangeStackXYLabel:
_ExchangeStackXY equ _ExchangeStackXYLabel-branchTableBase
    .dw ExchangeStackXY
    .db 1

; varsregs1.asm
_InitRegsLabel:
_InitRegs equ _InitRegsLabel-branchTableBase
    .dw InitRegs
    .db 1
_ClearRegsLabel:
_ClearRegs equ _ClearRegsLabel-branchTableBase
    .dw ClearRegs
    .db 1
_CloseRegsLabel:
_CloseRegs equ _CloseRegsLabel-branchTableBase
    .dw CloseRegs
    .db 1
_LenRegsLabel:
_LenRegs equ _LenRegsLabel-branchTableBase
    .dw LenRegs
    .db 1
_ResizeRegsLabel:
_ResizeRegs equ _ResizeRegsLabel-branchTableBase
    .dw ResizeRegs
    .db 1
_RclGenericLabel:
_RclGeneric equ _RclGenericLabel-branchTableBase
    .dw RclGeneric
    .db 1
_StoOpGenericLabel:
_StoOpGeneric equ _StoOpGenericLabel-branchTableBase
    .dw StoOpGeneric
    .db 1
_RclOpGenericLabel:
_RclOpGeneric equ _RclOpGenericLabel-branchTableBase
    .dw RclOpGeneric
    .db 1

; varsstat1.asm
_InitStatRegsLabel:
_InitStatRegs equ _InitStatRegsLabel-branchTableBase
    .dw InitStatRegs
    .db 1
_ClearStatRegsLabel:
_ClearStatRegs equ _ClearStatRegsLabel-branchTableBase
    .dw ClearStatRegs
    .db 1
_CloseStatRegsLabel:
_CloseStatRegs equ _CloseStatRegsLabel-branchTableBase
    .dw CloseStatRegs
    .db 1
_StoStatRegNNLabel:
_StoStatRegNN equ _StoStatRegNNLabel-branchTableBase
    .dw StoStatRegNN
    .db 1
_RclStatRegNNLabel:
_RclStatRegNN equ _RclStatRegNNLabel-branchTableBase
    .dw RclStatRegNN
    .db 1
_RclStatRegNNToOP2Label:
_RclStatRegNNToOP2 equ _RclStatRegNNToOP2Label-branchTableBase
    .dw RclStatRegNNToOP2
    .db 1
_StoAddStatRegNNLabel:
_StoAddStatRegNN equ _StoAddStatRegNNLabel-branchTableBase
    .dw StoAddStatRegNN
    .db 1
_StoSubStatRegNNLabel:
_StoSubStatRegNN equ _StoSubStatRegNNLabel-branchTableBase
    .dw StoSubStatRegNN
    .db 1

; appstate1.asm
_StoreAppStateLabel:
_StoreAppState equ _StoreAppStateLabel-branchTableBase
    .dw StoreAppState
    .db 1
_RestoreAppStateLabel:
_RestoreAppState equ _RestoreAppStateLabel-branchTableBase
    .dw RestoreAppState
    .db 1

; osstate1.asm
_SaveOSStateLabel:
_SaveOSState equ _SaveOSStateLabel-branchTableBase
    .dw SaveOSState
    .db 1
_RestoreOSStateLabel:
_RestoreOSState equ _RestoreOSStateLabel-branchTableBase
    .dw RestoreOSState
    .db 1

; modes2.asm
_ColdInitModesLabel:
_ColdInitModes equ _ColdInitModesLabel-branchTableBase
    .dw ColdInitModes
    .db 1

; helpscanner1.asm
_ProcessHelpCommandsLabel:
_ProcessHelpCommands equ _ProcessHelpCommandsLabel-branchTableBase
    .dw ProcessHelpCommands
    .db 1

; crc1.asm
_Crc16ccittLabel:
_Crc16ccitt equ _Crc16ccittLabel-branchTableBase
    .dw Crc16ccitt
    .db 1

; errorcode1.asm
_ColdInitErrorCodeLabel:
_ColdInitErrorCode equ _ColdInitErrorCodeLabel-branchTableBase
    .dw ColdInitErrorCode
    .db 1
_PrintErrorStringLabel:
_PrintErrorString equ _PrintErrorStringLabel-branchTableBase
    .dw PrintErrorString
    .db 1
_SetErrorCodeLabel:
_SetErrorCode equ _SetErrorCodeLabel-branchTableBase
    .dw SetErrorCode
    .db 1
_SetHandlerCodeFromSystemCodeLabel:
_SetHandlerCodeFromSystemCode equ _SetHandlerCodeFromSystemCodeLabel-branchTableBase
    .dw SetHandlerCodeFromSystemCode
    .db 1

; input1.asm
_ColdInitInputBufLabel:
_ColdInitInputBuf equ _ColdInitInputBufLabel-branchTableBase
    .dw ColdInitInputBuf
    .db 1
_ClearInputBufLabel:
_ClearInputBuf equ _ClearInputBufLabel-branchTableBase
    .dw ClearInputBuf
    .db 1
_InsertCharInputBufLabel:
_InsertCharInputBuf equ _InsertCharInputBufLabel-branchTableBase
    .dw InsertCharInputBuf
    .db 1
_DeleteCharInputBufLabel:
_DeleteCharInputBuf equ _DeleteCharInputBufLabel-branchTableBase
    .dw DeleteCharInputBuf
    .db 1
_DeleteCharAtInputBufLabel:
_DeleteCharAtInputBuf equ _DeleteCharAtInputBufLabel-branchTableBase
    .dw DeleteCharAtInputBuf
    .db 1
_ChangeSignInputBufLabel:
_ChangeSignInputBuf equ _ChangeSignInputBufLabel-branchTableBase
    .dw ChangeSignInputBuf
    .db 1
_CheckInputBufEELabel:
_CheckInputBufEE equ _CheckInputBufEELabel-branchTableBase
    .dw CheckInputBufEE
    .db 1
_CheckInputBufDecimalPointLabel:
_CheckInputBufDecimalPoint equ _CheckInputBufDecimalPointLabel-branchTableBase
    .dw CheckInputBufDecimalPoint
    .db 1
_CheckInputBufRecordLabel:
_CheckInputBufRecord equ _CheckInputBufRecordLabel-branchTableBase
    .dw CheckInputBufRecord
    .db 1
_CheckInputBufCommaLabel:
_CheckInputBufComma equ _CheckInputBufCommaLabel-branchTableBase
    .dw CheckInputBufComma
    .db 1
_SetComplexDelimiterLabel:
_SetComplexDelimiter equ _SetComplexDelimiterLabel-branchTableBase
    .dw SetComplexDelimiter
    .db 1

; parse1.asm
_ParseAndClearInputBufLabel:
_ParseAndClearInputBuf equ _ParseAndClearInputBufLabel-branchTableBase
    .dw ParseAndClearInputBuf
    .db 1

; arg1.asm
_ClearArgBufLabel:
_ClearArgBuf equ _ClearArgBufLabel-branchTableBase
    .dw ClearArgBuf
    .db 1
_InitArgBufLabel:
_InitArgBuf equ _InitArgBufLabel-branchTableBase
    .dw InitArgBuf
    .db 1
_AppendArgBufLabel:
_AppendArgBuf equ _AppendArgBufLabel-branchTableBase
    .dw AppendArgBuf
    .db 1
_ParseArgBufLabel:
_ParseArgBuf equ _ParseArgBufLabel-branchTableBase
    .dw ParseArgBuf
    .db 1

; pstring1.asm. Commented out because they are currently always called from
; Flash Page 1, never from another Flash Page.
; _AppendStringLabel:
; _AppendString equ _AppendStringLabel-branchTableBase
;     .dw AppendString
;     .db 1
; _InsertAtPosLabel:
; _InsertAtPos equ _InsertAtPosLabel-branchTableBase
;     .dw InsertAtPos
;     .db 1
; _DeleteAtPosLabel:
; _DeleteAtPos equ _DeleteAtPosLabel-branchTableBase
;     .dw DeleteAtPos
;     .db 1

; integerconv1.asm
_ConvertAToOP1Label:
_ConvertAToOP1 equ _ConvertAToOP1Label-branchTableBase
    .dw ConvertAToOP1
    .db 1
_AddAToOP1Label:
_AddAToOP1 equ _AddAToOP1Label-branchTableBase
    .dw AddAToOP1
    .db 1

; num1.asm
_SignFunctionLabel:
_SignFunction equ _SignFunctionLabel-branchTableBase
    .dw SignFunction
    .db 1
_ModFunctionLabel:
_ModFunction equ _ModFunctionLabel-branchTableBase
    .dw ModFunction
    .db 1
_GcdFunctionLabel:
_GcdFunction equ _GcdFunctionLabel-branchTableBase
    .dw GcdFunction
    .db 1
_LcdFunctionLabel:
_LcdFunction equ _LcdFunctionLabel-branchTableBase
    .dw LcdFunction
    .db 1
_PercentFunctionLabel:
_PercentFunction equ _PercentFunctionLabel-branchTableBase
    .dw PercentFunction
    .db 1
_PercentChangeFunctionLabel:
_PercentChangeFunction equ _PercentChangeFunctionLabel-branchTableBase
    .dw PercentChangeFunction
    .db 1
_CeilFunctionLabel:
_CeilFunction equ _CeilFunctionLabel-branchTableBase
    .dw CeilFunction
    .db 1

; hms1.asm
_HmsToHrLabel:
_HmsToHr equ _HmsToHrLabel-branchTableBase
    .dw HmsToHr
    .db 1
_HmsFromHrLabel:
_HmsFromHr equ _HmsFromHrLabel-branchTableBase
    .dw HmsFromHr
    .db 1
_HmsPlusLabel:
_HmsPlus equ _HmsPlusLabel-branchTableBase
    .dw HmsPlus
    .db 1
_HmsMinusLabel:
_HmsMinus equ _HmsMinusLabel-branchTableBase
    .dw HmsMinus
    .db 1

; prob1.asm
_ProbPermLabel:
_ProbPerm equ _ProbPermLabel-branchTableBase
    .dw ProbPerm
    .db 1
_ProbCombLabel:
_ProbComb equ _ProbCombLabel-branchTableBase
    .dw ProbComb
    .db 1

; complex1.asm
_ColdInitComplexLabel:
_ColdInitComplex equ _ColdInitComplexLabel-branchTableBase
    .dw ColdInitComplex
    .db 1
_UpdateNumResultModeLabel:
_UpdateNumResultMode equ _UpdateNumResultModeLabel-branchTableBase
    .dw UpdateNumResultMode
    .db 1
_UpdateComplexModeLabel:
_UpdateComplexMode equ _UpdateComplexModeLabel-branchTableBase
    .dw UpdateComplexMode
    .db 1
_RectToComplexLabel:
_RectToComplex equ _RectToComplexLabel-branchTableBase
    .dw RectToComplex
    .db 1
_Rect3ToComplex3Label:
_Rect3ToComplex3 equ _Rect3ToComplex3Label-branchTableBase
    .dw Rect3ToComplex3
    .db 1
_PolarRadToComplexLabel:
_PolarRadToComplex equ _PolarRadToComplexLabel-branchTableBase
    .dw PolarRadToComplex
    .db 1
_PolarDegToComplexLabel:
_PolarDegToComplex equ _PolarDegToComplexLabel-branchTableBase
    .dw PolarDegToComplex
    .db 1
_ComplexToRectLabel:
_ComplexToRect equ _ComplexToRectLabel-branchTableBase
    .dw ComplexToRect
    .db 1
_Complex3ToRect3Label:
_Complex3ToRect3 equ _Complex3ToRect3Label-branchTableBase
    .dw Complex3ToRect3
    .db 1
_ComplexToPolarRadLabel:
_ComplexToPolarRad equ _ComplexToPolarRadLabel-branchTableBase
    .dw ComplexToPolarRad
    .db 1
_ComplexToPolarDegLabel:
_ComplexToPolarDeg equ _ComplexToPolarDegLabel-branchTableBase
    .dw ComplexToPolarDeg
    .db 1
;
_ComplexToRealsLabel:
_ComplexToReals equ _ComplexToRealsLabel-branchTableBase
    .dw ComplexToReals
    .db 1
_RealsToComplexLabel:
_RealsToComplex equ _RealsToComplexLabel-branchTableBase
    .dw RealsToComplex
    .db 1
_ComplexRealLabel:
_ComplexReal equ _ComplexRealLabel-branchTableBase
    .dw ComplexReal
    .db 1
_ComplexImagLabel:
_ComplexImag equ _ComplexImagLabel-branchTableBase
    .dw ComplexImag
    .db 1
_ComplexConjLabel:
_ComplexConj equ _ComplexConjLabel-branchTableBase
    .dw ComplexConj
    .db 1
_ComplexAbsLabel:
_ComplexAbs equ _ComplexAbsLabel-branchTableBase
    .dw ComplexAbs
    .db 1
_ComplexAngleLabel:
_ComplexAngle equ _ComplexAngleLabel-branchTableBase
    .dw ComplexAngle
    .db 1

; formatcomplex1.asm
_FormatComplexRectLabel:
_FormatComplexRect equ _FormatComplexRectLabel-branchTableBase
    .dw FormatComplexRect
    .db 1
_FormatComplexPolarRadLabel:
_FormatComplexPolarRad equ _FormatComplexPolarRadLabel-branchTableBase
    .dw FormatComplexPolarRad
    .db 1
_FormatComplexPolarDegLabel:
_FormatComplexPolarDeg equ _FormatComplexPolarDegLabel-branchTableBase
    .dw FormatComplexPolarDeg
    .db 1

; unit1.asm
_ExtractUnitNameLabel:
_ExtractUnitName equ _ExtractUnitNameLabel-branchTableBase
    .dw ExtractUnitName
    .db 1
_GetUnitClassLabel:
_GetUnitClass equ _GetUnitClassLabel-branchTableBase
    .dw GetUnitClass
    .db 1
_GetUnitBaseLabel:
_GetUnitBase equ _GetUnitBaseLabel-branchTableBase
    .dw GetUnitBase
    .db 1
_GetUnitScaleLabel:
_GetUnitScale equ _GetUnitScaleLabel-branchTableBase
    .dw GetUnitScale
    .db 1

; universal.asm
_UniversalAddLabel:
_UniversalAdd equ _UniversalAddLabel-branchTableBase
    .dw UniversalAdd
    .db 1
_UniversalSubLabel:
_UniversalSub equ _UniversalSubLabel-branchTableBase
    .dw UniversalSub
    .db 1
_UniversalMultLabel:
_UniversalMult equ _UniversalMultLabel-branchTableBase
    .dw UniversalMult
    .db 1
_UniversalDivLabel:
_UniversalDiv equ _UniversalDivLabel-branchTableBase
    .dw UniversalDiv
    .db 1
_UniversalChsLabel:
_UniversalChs equ _UniversalChsLabel-branchTableBase
    .dw UniversalChs
    .db 1
_UniversalRecipLabel:
_UniversalRecip equ _UniversalRecipLabel-branchTableBase
    .dw UniversalRecip
    .db 1
_UniversalSquareLabel:
_UniversalSquare equ _UniversalSquareLabel-branchTableBase
    .dw UniversalSquare
    .db 1
_UniversalSqRootLabel:
_UniversalSqRoot equ _UniversalSqRootLabel-branchTableBase
    .dw UniversalSqRoot
    .db 1
_UniversalCubeLabel:
_UniversalCube equ _UniversalCubeLabel-branchTableBase
    .dw UniversalCube
    .db 1
_UniversalCubeRootLabel:
_UniversalCubeRoot equ _UniversalCubeRootLabel-branchTableBase
    .dw UniversalCubeRoot
    .db 1
_UniversalPowLabel:
_UniversalPow equ _UniversalPowLabel-branchTableBase
    .dw UniversalPow
    .db 1
_UniversalXRootYLabel:
_UniversalXRootY equ _UniversalXRootYLabel-branchTableBase
    .dw UniversalXRootY
    .db 1
_UniversalLogLabel:
_UniversalLog equ _UniversalLogLabel-branchTableBase
    .dw UniversalLog
    .db 1
_UniversalTenPowLabel:
_UniversalTenPow equ _UniversalTenPowLabel-branchTableBase
    .dw UniversalTenPow
    .db 1
_UniversalLnLabel:
_UniversalLn equ _UniversalLnLabel-branchTableBase
    .dw UniversalLn
    .db 1
_UniversalExpLabel:
_UniversalExp equ _UniversalExpLabel-branchTableBase
    .dw UniversalExp
    .db 1
_UniversalTwoPowLabel:
_UniversalTwoPow equ _UniversalTwoPowLabel-branchTableBase
    .dw UniversalTwoPow
    .db 1
_UniversalLog2Label:
_UniversalLog2 equ _UniversalLog2Label-branchTableBase
    .dw UniversalLog2
    .db 1
_UniversalLogBaseLabel:
_UniversalLogBase equ _UniversalLogBaseLabel-branchTableBase
    .dw UniversalLogBase
    .db 1

;-----------------------------------------------------------------------------

#ifdef DEBUG
; debug1.asm
_DebugInputBufLabel:
_DebugInputBuf equ _DebugInputBufLabel-branchTableBase
    .dw DebugInputBuf
    .db 1
_DebugParseBufLabel:
_DebugParseBuf equ _DebugParseBufLabel-branchTableBase
    .dw DebugParseBuf
    .db 1
_DebugStringLabel:
_DebugString equ _DebugStringLabel-branchTableBase
    .dw DebugString
    .db 1
_DebugPStringLabel:
_DebugPString equ _DebugPStringLabel-branchTableBase
    .dw DebugPString
    .db 1
_DebugClearLabel:
_DebugClear equ _DebugClearLabel-branchTableBase
    .dw DebugClear
    .db 1
_DebugOP1Label:
_DebugOP1 equ _DebugOP1Label-branchTableBase
    .dw DebugOP1
    .db 1
_DebugUnsignedALabel:
_DebugUnsignedA equ _DebugUnsignedALabel-branchTableBase
    .dw DebugUnsignedA
    .db 1
_DebugSignedALabel:
_DebugSignedA equ _DebugSignedALabel-branchTableBase
    .dw DebugSignedA
    .db 1
_DebugFlagsLabel:
_DebugFlags equ _DebugFlagsLabel-branchTableBase
    .dw DebugFlags
    .db 1
_DebugU32AsHexLabel:
_DebugU32AsHex equ _DebugU32AsHexLabel-branchTableBase
    .dw DebugU32AsHex
    .db 1
_DebugU40AsHexLabel:
_DebugU40AsHex equ _DebugU40AsHexLabel-branchTableBase
    .dw DebugU40AsHex
    .db 1
_DebugHLLabel:
_DebugHL equ _DebugHLLabel-branchTableBase
    .dw DebugHL
    .db 1
_DebugHLAsHexLabel:
_DebugHLAsHex equ _DebugHLAsHexLabel-branchTableBase
    .dw DebugHLAsHex
    .db 1
_DebugPauseLabel:
_DebugPause equ _DebugPauseLabel-branchTableBase
    .dw DebugPause
    .db 1
_DebugU32DEAsHexLabel:
_DebugU32DEAsHex equ _DebugU32DEAsHexLabel-branchTableBase
    .dw DebugU32DEAsHex
    .db 1
#endif

;-----------------------------------------------------------------------------
; Branch table entries for routines on Flash Page 2.
;-----------------------------------------------------------------------------

; stats2.asm
_StatSigmaPlusLabel:
_StatSigmaPlus equ _StatSigmaPlusLabel-branchTableBase
    .dw StatSigmaPlus
    .db 2
_StatSigmaMinusLabel:
_StatSigmaMinus equ _StatSigmaMinusLabel-branchTableBase
    .dw StatSigmaMinus
    .db 2
_StatSumLabel:
_StatSum equ _StatSumLabel-branchTableBase
    .dw StatSum
    .db 2
_StatMeanLabel:
_StatMean equ _StatMeanLabel-branchTableBase
    .dw StatMean
    .db 2
_StatWeightedMeanLabel:
_StatWeightedMean equ _StatWeightedMeanLabel-branchTableBase
    .dw StatWeightedMean
    .db 2
_StatStdDevLabel:
_StatStdDev equ _StatStdDevLabel-branchTableBase
    .dw StatStdDev
    .db 2
_StatSampleStdDevLabel:
_StatSampleStdDev equ _StatSampleStdDevLabel-branchTableBase
    .dw StatSampleStdDev
    .db 2
_StatCovarianceLabel:
_StatCovariance equ _StatCovarianceLabel-branchTableBase
    .dw StatCovariance
    .db 2
_StatSampleCovarianceLabel:
_StatSampleCovariance equ _StatSampleCovarianceLabel-branchTableBase
    .dw StatSampleCovariance
    .db 2
_StatCorrelationLabel:
_StatCorrelation equ _StatCorrelationLabel-branchTableBase
    .dw StatCorrelation
    .db 2

; cfit2.asm
_CfitForecastYLabel:
_CfitForecastY equ _CfitForecastYLabel-branchTableBase
    .dw CfitForecastY
    .db 2
_CfitForecastXLabel:
_CfitForecastX equ _CfitForecastXLabel-branchTableBase
    .dw CfitForecastX
    .db 2
_CfitSlopeLabel:
_CfitSlope equ _CfitSlopeLabel-branchTableBase
    .dw CfitSlope
    .db 2
_CfitInterceptLabel:
_CfitIntercept equ _CfitInterceptLabel-branchTableBase
    .dw CfitIntercept
    .db 2
_CfitCorrelationLabel:
_CfitCorrelation equ _CfitCorrelationLabel-branchTableBase
    .dw CfitCorrelation
    .db 2
_CfitBestFitLabel:
_CfitBestFit equ _CfitBestFitLabel-branchTableBase
    .dw CfitBestFit
    .db 2

; tvm2.asm
_ColdInitTvmLabel:
_ColdInitTvm equ _ColdInitTvmLabel-branchTableBase
    .dw ColdInitTvm
    .db 2
_InitTvmSolverLabel:
_InitTvmSolver equ _InitTvmSolverLabel-branchTableBase
    .dw InitTvmSolver
    .db 2
_TvmCalculateNLabel:
_TvmCalculateN equ _TvmCalculateNLabel-branchTableBase
    .dw TvmCalculateN
    .db 2
_TvmSolveLabel:
_TvmSolve equ _TvmSolveLabel-branchTableBase
    .dw TvmSolve
    .db 2
_TvmSolveCheckDebugEnabledLabel:
_TvmSolveCheckDebugEnabled equ _TvmSolveCheckDebugEnabledLabel-branchTableBase
    .dw TvmSolveCheckDebugEnabled
    .db 2
_TvmCalculatePVLabel:
_TvmCalculatePV equ _TvmCalculatePVLabel-branchTableBase
    .dw TvmCalculatePV
    .db 2
_TvmCalculatePMTLabel:
_TvmCalculatePMT equ _TvmCalculatePMTLabel-branchTableBase
    .dw TvmCalculatePMT
    .db 2
_TvmCalculateFVLabel:
_TvmCalculateFV equ _TvmCalculateFVLabel-branchTableBase
    .dw TvmCalculateFV
    .db 2
_TvmCalcIPPFromIYRLabel:
_TvmCalcIPPFromIYR equ _TvmCalcIPPFromIYRLabel-branchTableBase
    .dw TvmCalcIPPFromIYR
    .db 2
_TvmClearLabel:
_TvmClear equ _TvmClearLabel-branchTableBase
    .dw TvmClear
    .db 2
_TvmSolverResetLabel:
_TvmSolverReset equ _TvmSolverResetLabel-branchTableBase
    .dw TvmSolverReset
    .db 2
_RclTvmNLabel:
_RclTvmN equ _RclTvmNLabel-branchTableBase
    .dw RclTvmN
    .db 2
_StoTvmNLabel:
_StoTvmN equ _StoTvmNLabel-branchTableBase
    .dw StoTvmN
    .db 2
_RclTvmIYRLabel:
_RclTvmIYR equ _RclTvmIYRLabel-branchTableBase
    .dw RclTvmIYR
    .db 2
_StoTvmIYRLabel:
_StoTvmIYR equ _StoTvmIYRLabel-branchTableBase
    .dw StoTvmIYR
    .db 2
_RclTvmPVLabel:
_RclTvmPV equ _RclTvmPVLabel-branchTableBase
    .dw RclTvmPV
    .db 2
_StoTvmPVLabel:
_StoTvmPV equ _StoTvmPVLabel-branchTableBase
    .dw StoTvmPV
    .db 2
_RclTvmPMTLabel:
_RclTvmPMT equ _RclTvmPMTLabel-branchTableBase
    .dw RclTvmPMT
    .db 2
_StoTvmPMTLabel:
_StoTvmPMT equ _StoTvmPMTLabel-branchTableBase
    .dw StoTvmPMT
    .db 2
_RclTvmFVLabel:
_RclTvmFV equ _RclTvmFVLabel-branchTableBase
    .dw RclTvmFV
    .db 2
_StoTvmFVLabel:
_StoTvmFV equ _StoTvmFVLabel-branchTableBase
    .dw StoTvmFV
    .db 2
_RclTvmPYRLabel:
_RclTvmPYR equ _RclTvmPYRLabel-branchTableBase
    .dw RclTvmPYR
    .db 2
_StoTvmPYRLabel:
_StoTvmPYR equ _StoTvmPYRLabel-branchTableBase
    .dw StoTvmPYR
    .db 2
_RclTvmCYRLabel:
_RclTvmCYR equ _RclTvmCYRLabel-branchTableBase
    .dw RclTvmCYR
    .db 2
_StoTvmCYRLabel:
_StoTvmCYR equ _StoTvmCYRLabel-branchTableBase
    .dw StoTvmCYR
    .db 2
;
_RclTvmIYR0Label:
_RclTvmIYR0 equ _RclTvmIYR0Label-branchTableBase
    .dw RclTvmIYR0
    .db 2
_StoTvmIYR0Label:
_StoTvmIYR0 equ _StoTvmIYR0Label-branchTableBase
    .dw StoTvmIYR0
    .db 2
_RclTvmIYR1Label:
_RclTvmIYR1 equ _RclTvmIYR1Label-branchTableBase
    .dw RclTvmIYR1
    .db 2
_StoTvmIYR1Label:
_StoTvmIYR1 equ _StoTvmIYR1Label-branchTableBase
    .dw StoTvmIYR1
    .db 2
_RclTvmIterMaxLabel:
_RclTvmIterMax equ _RclTvmIterMaxLabel-branchTableBase
    .dw RclTvmIterMax
    .db 2
_StoTvmIterMaxLabel:
_StoTvmIterMax equ _StoTvmIterMaxLabel-branchTableBase
    .dw StoTvmIterMax
    .db 2
_RclTvmI0Label:
_RclTvmI0 equ _RclTvmI0Label-branchTableBase
    .dw RclTvmI0
    .db 2
_StoTvmI0Label:
_StoTvmI0 equ _StoTvmI0Label-branchTableBase
    .dw StoTvmI0
    .db 2
_RclTvmI1Label:
_RclTvmI1 equ _RclTvmI1Label-branchTableBase
    .dw RclTvmI1
    .db 2
_StoTvmI1Label:
_StoTvmI1 equ _StoTvmI1Label-branchTableBase
    .dw StoTvmI1
    .db 2
_RclTvmNPMT0Label:
_RclTvmNPMT0 equ _RclTvmNPMT0Label-branchTableBase
    .dw RclTvmNPMT0
    .db 2
_StoTvmNPMT0Label:
_StoTvmNPMT0 equ _StoTvmNPMT0Label-branchTableBase
    .dw StoTvmNPMT0
    .db 2
_RclTvmNPMT1Label:
_RclTvmNPMT1 equ _RclTvmNPMT1Label-branchTableBase
    .dw RclTvmNPMT1
    .db 2
_StoTvmNPMT1Label:
_StoTvmNPMT1 equ _StoTvmNPMT1Label-branchTableBase
    .dw StoTvmNPMT1
    .db 2
_RclTvmSolverCountLabel:
_RclTvmSolverCount equ _RclTvmSolverCountLabel-branchTableBase
    .dw RclTvmSolverCount
    .db 2
;
_RclTvmIYR0DefaultLabel:
_RclTvmIYR0Default equ _RclTvmIYR0DefaultLabel-branchTableBase
    .dw RclTvmIYR0Default
    .db 2
_RclTvmIYR1DefaultLabel:
_RclTvmIYR1Default equ _RclTvmIYR1DefaultLabel-branchTableBase
    .dw RclTvmIYR1Default
    .db 2

; float2.asm
_LnOnePlusLabel:
_LnOnePlus equ _LnOnePlusLabel-branchTableBase
    .dw LnOnePlus
    .db 2
_ExpMinusOneLabel:
_ExpMinusOne equ _ExpMinusOneLabel-branchTableBase
    .dw ExpMinusOne
    .db 2

; selectepoch2.asm
_SelectUnixEpochDateLabel:
_SelectUnixEpochDate equ _SelectUnixEpochDateLabel-branchTableBase
    .dw SelectUnixEpochDate
    .db 2
_SelectNtpEpochDateLabel:
_SelectNtpEpochDate equ _SelectNtpEpochDateLabel-branchTableBase
    .dw SelectNtpEpochDate
    .db 2
_SelectGpsEpochDateLabel:
_SelectGpsEpochDate equ _SelectGpsEpochDateLabel-branchTableBase
    .dw SelectGpsEpochDate
    .db 2
_SelectTiosEpochDateLabel:
_SelectTiosEpochDate equ _SelectTiosEpochDateLabel-branchTableBase
    .dw SelectTiosEpochDate
    .db 2
_SelectY2kEpochDateLabel:
_SelectY2kEpochDate equ _SelectY2kEpochDateLabel-branchTableBase
    .dw SelectY2kEpochDate
    .db 2
_SelectCustomEpochDateLabel:
_SelectCustomEpochDate equ _SelectCustomEpochDateLabel-branchTableBase
    .dw SelectCustomEpochDate
    .db 2
; Set and get custom epoch date.
_SetCustomEpochDateLabel:
_SetCustomEpochDate equ _SetCustomEpochDateLabel-branchTableBase
    .dw SetCustomEpochDate
    .db 2
_GetCustomEpochDateLabel:
_GetCustomEpochDate equ _GetCustomEpochDateLabel-branchTableBase
    .dw GetCustomEpochDate
    .db 2

; fps2.asm
_PushRpnObject1Label:
_PushRpnObject1 equ _PushRpnObject1Label-branchTableBase
    .dw PushRpnObject1
    .db 2
_PopRpnObject1Label:
_PopRpnObject1 equ _PopRpnObject1Label-branchTableBase
    .dw PopRpnObject1
    .db 2
_PushRpnObject3Label:
_PushRpnObject3 equ _PushRpnObject3Label-branchTableBase
    .dw PushRpnObject3
    .db 2
_PopRpnObject3Label:
_PopRpnObject3 equ _PopRpnObject3Label-branchTableBase
    .dw PopRpnObject3
    .db 2
_PushRpnObject5Label:
_PushRpnObject5 equ _PushRpnObject5Label-branchTableBase
    .dw PushRpnObject5
    .db 2
_PopRpnObject5Label:
_PopRpnObject5 equ _PopRpnObject5Label-branchTableBase
    .dw PopRpnObject5
    .db 2

; formatdate2.asm
_FormatDateLabel:
_FormatDate equ _FormatDateLabel-branchTableBase
    .dw FormatDate
    .db 2
_FormatTimeLabel:
_FormatTime equ _FormatTimeLabel-branchTableBase
    .dw FormatTime
    .db 2
_FormatDateTimeLabel:
_FormatDateTime equ _FormatDateTimeLabel-branchTableBase
    .dw FormatDateTime
    .db 2
_FormatOffsetLabel:
_FormatOffset equ _FormatOffsetLabel-branchTableBase
    .dw FormatOffset
    .db 2
_FormatOffsetDateTimeLabel:
_FormatOffsetDateTime equ _FormatOffsetDateTimeLabel-branchTableBase
    .dw FormatOffsetDateTime
    .db 2
_FormatDayOfWeekLabel:
_FormatDayOfWeek equ _FormatDayOfWeekLabel-branchTableBase
    .dw FormatDayOfWeek
    .db 2
_FormatDurationLabel:
_FormatDuration equ _FormatDurationLabel-branchTableBase
    .dw FormatDuration
    .db 2

; datevalidation2.asm
_ValidateDateLabel:
_ValidateDate equ _ValidateDateLabel-branchTableBase
    .dw ValidateDate
    .db 2
_ValidateTimeLabel:
_ValidateTime equ _ValidateTimeLabel-branchTableBase
    .dw ValidateTime
    .db 2
_ValidateDateTimeLabel:
_ValidateDateTime equ _ValidateDateTimeLabel-branchTableBase
    .dw ValidateDateTime
    .db 2
_ValidateOffsetLabel:
_ValidateOffset equ _ValidateOffsetLabel-branchTableBase
    .dw ValidateOffset
    .db 2
_ValidateOffsetDateTimeLabel:
_ValidateOffsetDateTime equ _ValidateOffsetDateTimeLabel-branchTableBase
    .dw ValidateOffsetDateTime
    .db 2
_ValidateDayOfWeekLabel:
_ValidateDayOfWeek equ _ValidateDayOfWeekLabel-branchTableBase
    .dw ValidateDayOfWeek
    .db 2
_ValidateDurationLabel:
_ValidateDuration equ _ValidateDurationLabel-branchTableBase
    .dw ValidateDuration
    .db 2

; date2.asm
_ColdInitDateLabel:
_ColdInitDate equ _ColdInitDateLabel-branchTableBase
    .dw ColdInitDate
    .db 2
; Leap year functions
_IsYearLeapLabel:
_IsYearLeap equ _IsYearLeapLabel-branchTableBase
    .dw IsYearLeap
    .db 2
_IsDateLeapLabel:
_IsDateLeap equ _IsDateLeapLabel-branchTableBase
    .dw IsDateLeap
    .db 2
; RpnDate and days functions
_RpnDateToEpochDaysLabel:
_RpnDateToEpochDays equ _RpnDateToEpochDaysLabel-branchTableBase
    .dw RpnDateToEpochDays
    .db 2
_RpnDateToEpochSecondsLabel:
_RpnDateToEpochSeconds equ _RpnDateToEpochSecondsLabel-branchTableBase
    .dw RpnDateToEpochSeconds
    .db 2
_EpochDaysToRpnDateLabel:
_EpochDaysToRpnDate equ _EpochDaysToRpnDateLabel-branchTableBase
    .dw EpochDaysToRpnDate
    .db 2
_EpochSecondsToRpnDateLabel:
_EpochSecondsToRpnDate equ _EpochSecondsToRpnDateLabel-branchTableBase
    .dw EpochSecondsToRpnDate
    .db 2
; arithmetics
_AddRpnDateByDaysLabel:
_AddRpnDateByDays equ _AddRpnDateByDaysLabel-branchTableBase
    .dw AddRpnDateByDays
    .db 2
_AddRpnDateByDurationLabel:
_AddRpnDateByDuration equ _AddRpnDateByDurationLabel-branchTableBase
    .dw AddRpnDateByDuration
    .db 2
_SubRpnDateByObjectLabel:
_SubRpnDateByObject equ _SubRpnDateByObjectLabel-branchTableBase
    .dw SubRpnDateByObject
    .db 2
; extractors
_RpnDateExtractYearLabel:
_RpnDateExtractYear equ _RpnDateExtractYearLabel-branchTableBase
    .dw RpnDateExtractYear
    .db 2
_RpnDateExtractMonthLabel:
_RpnDateExtractMonth equ _RpnDateExtractMonthLabel-branchTableBase
    .dw RpnDateExtractMonth
    .db 2
_RpnDateExtractDayLabel:
_RpnDateExtractDay equ _RpnDateExtractDayLabel-branchTableBase
    .dw RpnDateExtractDay
    .db 2

; time2.asm
_RpnTimeToSecondsLabel:
_RpnTimeToSeconds equ _RpnTimeToSecondsLabel-branchTableBase
    .dw RpnTimeToSeconds
    .db 2
_SecondsToRpnTimeLabel:
_SecondsToRpnTime equ _SecondsToRpnTimeLabel-branchTableBase
    .dw SecondsToRpnTime
    .db 2
; arithmetics
_AddRpnTimeBySecondsLabel:
_AddRpnTimeBySeconds equ _AddRpnTimeBySecondsLabel-branchTableBase
    .dw AddRpnTimeBySeconds
    .db 2
_AddRpnTimeByDurationLabel:
_AddRpnTimeByDuration equ _AddRpnTimeByDurationLabel-branchTableBase
    .dw AddRpnTimeByDuration
    .db 2
_SubRpnTimeByObjectLabel:
_SubRpnTimeByObject equ _SubRpnTimeByObjectLabel-branchTableBase
    .dw SubRpnTimeByObject
    .db 2
; extractors
_RpnTimeExtractHourLabel:
_RpnTimeExtractHour equ _RpnTimeExtractHourLabel-branchTableBase
    .dw RpnTimeExtractHour
    .db 2
_RpnTimeExtractMinuteLabel:
_RpnTimeExtractMinute equ _RpnTimeExtractMinuteLabel-branchTableBase
    .dw RpnTimeExtractMinute
    .db 2
_RpnTimeExtractSecondLabel:
_RpnTimeExtractSecond equ _RpnTimeExtractSecondLabel-branchTableBase
    .dw RpnTimeExtractSecond
    .db 2

; dayofweek2.asm
_RpnDateToDayOfWeekLabel:
_RpnDateToDayOfWeek equ _RpnDateToDayOfWeekLabel-branchTableBase
    .dw RpnDateToDayOfWeek
    .db 2
_RpnDayOfWeekToIsoNumberLabel:
_RpnDayOfWeekToIsoNumber equ _RpnDayOfWeekToIsoNumberLabel-branchTableBase
    .dw RpnDayOfWeekToIsoNumber
    .db 2
_IsoNumberToRpnDayOfWeekLabel:
_IsoNumberToRpnDayOfWeek equ _IsoNumberToRpnDayOfWeekLabel-branchTableBase
    .dw IsoNumberToRpnDayOfWeek
    .db 2
; arithmetics
_AddRpnDayOfWeekByDaysLabel:
_AddRpnDayOfWeekByDays equ _AddRpnDayOfWeekByDaysLabel-branchTableBase
    .dw AddRpnDayOfWeekByDays
    .db 2
_SubRpnDayOfWeekByRpnDayOfWeekOrDaysLabel:
_SubRpnDayOfWeekByRpnDayOfWeekOrDays equ _SubRpnDayOfWeekByRpnDayOfWeekOrDaysLabel-branchTableBase
    .dw SubRpnDayOfWeekByRpnDayOfWeekOrDays
    .db 2

; datetime2.asm
_RpnDateTimeToEpochSecondsLabel:
_RpnDateTimeToEpochSeconds equ _RpnDateTimeToEpochSecondsLabel-branchTableBase
    .dw RpnDateTimeToEpochSeconds
    .db 2
_EpochSecondsToRpnDateTimeLabel:
_EpochSecondsToRpnDateTime equ _EpochSecondsToRpnDateTimeLabel-branchTableBase
    .dw EpochSecondsToRpnDateTime
    .db 2
_RpnDateTimeToEpochDaysLabel:
_RpnDateTimeToEpochDays equ _RpnDateTimeToEpochDaysLabel-branchTableBase
    .dw RpnDateTimeToEpochDays
    .db 2
_EpochDaysToRpnDateTimeLabel:
_EpochDaysToRpnDateTime equ _EpochDaysToRpnDateTimeLabel-branchTableBase
    .dw EpochDaysToRpnDateTime
    .db 2
; arithmetics
_AddRpnDateTimeBySecondsLabel:
_AddRpnDateTimeBySeconds equ _AddRpnDateTimeBySecondsLabel-branchTableBase
    .dw AddRpnDateTimeBySeconds
    .db 2
_AddRpnDateTimeByRpnDurationLabel:
_AddRpnDateTimeByRpnDuration equ _AddRpnDateTimeByRpnDurationLabel-branchTableBase
    .dw AddRpnDateTimeByRpnDuration
    .db 2
_SubRpnDateTimeByObjectLabel:
_SubRpnDateTimeByObject equ _SubRpnDateTimeByObjectLabel-branchTableBase
    .dw SubRpnDateTimeByObject
    .db 2
; extractors
_RpnDateTimeExtractDateLabel:
_RpnDateTimeExtractDate equ _RpnDateTimeExtractDateLabel-branchTableBase
    .dw RpnDateTimeExtractDate
    .db 2
_RpnDateTimeExtractTimeLabel:
_RpnDateTimeExtractTime equ _RpnDateTimeExtractTimeLabel-branchTableBase
    .dw RpnDateTimeExtractTime
    .db 2

; offset2.asm
_RpnOffsetToSecondsLabel:
_RpnOffsetToSeconds equ _RpnOffsetToSecondsLabel-branchTableBase
    .dw RpnOffsetToSeconds
    .db 2
_RpnOffsetToHoursLabel:
_RpnOffsetToHours equ _RpnOffsetToHoursLabel-branchTableBase
    .dw RpnOffsetToHours
    .db 2
_HoursToRpnOffsetLabel:
_HoursToRpnOffset equ _HoursToRpnOffsetLabel-branchTableBase
    .dw HoursToRpnOffset
    .db 2
_AddRpnOffsetByHoursLabel:
_AddRpnOffsetByHours equ _AddRpnOffsetByHoursLabel-branchTableBase
    .dw AddRpnOffsetByHours
    .db 2
_AddRpnOffsetByDurationLabel:
_AddRpnOffsetByDuration equ _AddRpnOffsetByDurationLabel-branchTableBase
    .dw AddRpnOffsetByDuration
    .db 2
_SubRpnOffsetByObjectLabel:
_SubRpnOffsetByObject equ _SubRpnOffsetByObjectLabel-branchTableBase
    .dw SubRpnOffsetByObject
    .db 2
; extractors
_RpnOffsetExtractHourLabel:
_RpnOffsetExtractHour equ _RpnOffsetExtractHourLabel-branchTableBase
    .dw RpnOffsetExtractHour
    .db 2
_RpnOffsetExtractMinuteLabel:
_RpnOffsetExtractMinute equ _RpnOffsetExtractMinuteLabel-branchTableBase
    .dw RpnOffsetExtractMinute
    .db 2

; offsetdatetime2.asm
_RpnOffsetDateTimeToEpochSecondsLabel:
_RpnOffsetDateTimeToEpochSeconds equ _RpnOffsetDateTimeToEpochSecondsLabel-branchTableBase
    .dw RpnOffsetDateTimeToEpochSeconds
    .db 2
_EpochSecondsToRpnOffsetDateTimeLabel:
_EpochSecondsToRpnOffsetDateTime equ _EpochSecondsToRpnOffsetDateTimeLabel-branchTableBase
    .dw EpochSecondsToRpnOffsetDateTime
    .db 2
_EpochSecondsToRpnOffsetDateTimeUTCLabel:
_EpochSecondsToRpnOffsetDateTimeUTC equ _EpochSecondsToRpnOffsetDateTimeUTCLabel-branchTableBase
    .dw EpochSecondsToRpnOffsetDateTimeUTC
    .db 2
_AddRpnOffsetDateTimeBySecondsLabel:
_AddRpnOffsetDateTimeBySeconds equ _AddRpnOffsetDateTimeBySecondsLabel-branchTableBase
    .dw AddRpnOffsetDateTimeBySeconds
    .db 2
_AddRpnOffsetDateTimeByDurationLabel:
_AddRpnOffsetDateTimeByDuration equ _AddRpnOffsetDateTimeByDurationLabel-branchTableBase
    .dw AddRpnOffsetDateTimeByDuration
    .db 2
_SubRpnOffsetDateTimeByObjectLabel:
_SubRpnOffsetDateTimeByObject equ _SubRpnOffsetDateTimeByObjectLabel-branchTableBase
    .dw SubRpnOffsetDateTimeByObject
    .db 2
; extractors
_RpnOffsetDateTimeExtractDateLabel:
_RpnOffsetDateTimeExtractDate equ _RpnOffsetDateTimeExtractDateLabel-branchTableBase
    .dw RpnOffsetDateTimeExtractDate
    .db 2
_RpnOffsetDateTimeExtractDateTimeLabel:
_RpnOffsetDateTimeExtractDateTime equ _RpnOffsetDateTimeExtractDateTimeLabel-branchTableBase
    .dw RpnOffsetDateTimeExtractDateTime
    .db 2
_RpnOffsetDateTimeExtractTimeLabel:
_RpnOffsetDateTimeExtractTime equ _RpnOffsetDateTimeExtractTimeLabel-branchTableBase
    .dw RpnOffsetDateTimeExtractTime
    .db 2
_RpnOffsetDateTimeExtractOffsetLabel:
_RpnOffsetDateTimeExtractOffset equ _RpnOffsetDateTimeExtractOffsetLabel-branchTableBase
    .dw RpnOffsetDateTimeExtractOffset
    .db 2

; duration2.asm
_RpnDurationToSecondsLabel:
_RpnDurationToSeconds equ _RpnDurationToSecondsLabel-branchTableBase
    .dw RpnDurationToSeconds
    .db 2
_SecondsToRpnDurationLabel:
_SecondsToRpnDuration equ _SecondsToRpnDurationLabel-branchTableBase
    .dw SecondsToRpnDuration
    .db 2
_ChsRpnDurationLabel:
_ChsRpnDuration equ _ChsRpnDurationLabel-branchTableBase
    .dw ChsRpnDuration
    .db 2
_AddRpnDurationBySecondsLabel:
_AddRpnDurationBySeconds equ _AddRpnDurationBySecondsLabel-branchTableBase
    .dw AddRpnDurationBySeconds
    .db 2
_AddRpnDurationByRpnDurationLabel:
_AddRpnDurationByRpnDuration equ _AddRpnDurationByRpnDurationLabel-branchTableBase
    .dw AddRpnDurationByRpnDuration
    .db 2
_SubRpnDurationByRpnDurationOrSecondsLabel:
_SubRpnDurationByRpnDurationOrSeconds equ _SubRpnDurationByRpnDurationOrSecondsLabel-branchTableBase
    .dw SubRpnDurationByRpnDurationOrSeconds
    .db 2
_SubSecondsByRpnDurationLabel:
_SubSecondsByRpnDuration equ _SubSecondsByRpnDurationLabel-branchTableBase
    .dw SubSecondsByRpnDuration
    .db 2
_MultRpnDurationByRealLabel:
_MultRpnDurationByReal equ _MultRpnDurationByRealLabel-branchTableBase
    .dw MultRpnDurationByReal
    .db 2
_DivRpnDurationByRealLabel:
_DivRpnDurationByReal equ _DivRpnDurationByRealLabel-branchTableBase
    .dw DivRpnDurationByReal
    .db 2
; extracors
_RpnDurationExtractDayLabel:
_RpnDurationExtractDay equ _RpnDurationExtractDayLabel-branchTableBase
    .dw RpnDurationExtractDay
    .db 2
_RpnDurationExtractHourLabel:
_RpnDurationExtractHour equ _RpnDurationExtractHourLabel-branchTableBase
    .dw RpnDurationExtractHour
    .db 2
_RpnDurationExtractMinuteLabel:
_RpnDurationExtractMinute equ _RpnDurationExtractMinuteLabel-branchTableBase
    .dw RpnDurationExtractMinute
    .db 2
_RpnDurationExtractSecondLabel:
_RpnDurationExtractSecond equ _RpnDurationExtractSecondLabel-branchTableBase
    .dw RpnDurationExtractSecond
    .db 2

; zoneconversion2.asm
_ConvertRpnDateLikeToTimeZoneLabel:
_ConvertRpnDateLikeToTimeZone equ _ConvertRpnDateLikeToTimeZoneLabel-branchTableBase
    .dw ConvertRpnDateLikeToTimeZone
    .db 2
_ConvertRpnOffsetDateTimeToUtcLabel:
_ConvertRpnOffsetDateTimeToUtc equ _ConvertRpnOffsetDateTimeToUtcLabel-branchTableBase
    .dw ConvertRpnOffsetDateTimeToUtc
    .db 2

; zone2.asm
_SetAppTimeZoneLabel:
_SetAppTimeZone equ _SetAppTimeZoneLabel-branchTableBase
    .dw SetAppTimeZone
    .db 2
_GetAppTimeZoneLabel:
_GetAppTimeZone equ _GetAppTimeZoneLabel-branchTableBase
    .dw GetAppTimeZone
    .db 2

; genericdate2.asm
_GenericDateIsLeapLabel:
_GenericDateIsLeap equ _GenericDateIsLeapLabel-branchTableBase
    .dw GenericDateIsLeap
    .db 2
_GenericDateShrinkLabel:
_GenericDateShrink equ _GenericDateShrinkLabel-branchTableBase
    .dw GenericDateShrink
    .db 2
_GenericDateExtendLabel:
_GenericDateExtend equ _GenericDateExtendLabel-branchTableBase
    .dw GenericDateExtend
    .db 2
_GenericDateCutLabel:
_GenericDateCut equ _GenericDateCutLabel-branchTableBase
    .dw GenericDateCut
    .db 2
_GenericDateLinkLabel:
_GenericDateLink equ _GenericDateLinkLabel-branchTableBase
    .dw GenericDateLink
    .db 2

; rtc2.asm
_ColdInitRtcLabel:
_ColdInitRtc equ _ColdInitRtcLabel-branchTableBase
    .dw ColdInitRtc
    .db 2
_RtcGetNowLabel:
_RtcGetNow equ _RtcGetNowLabel-branchTableBase
    .dw RtcGetNow
    .db 2
_RtcGetDateLabel:
_RtcGetDate equ _RtcGetDateLabel-branchTableBase
    .dw RtcGetDate
    .db 2
_RtcGetTimeLabel:
_RtcGetTime equ _RtcGetTimeLabel-branchTableBase
    .dw RtcGetTime
    .db 2
_RtcGetOffsetDateTimeLabel:
_RtcGetOffsetDateTime equ _RtcGetOffsetDateTimeLabel-branchTableBase
    .dw RtcGetOffsetDateTime
    .db 2
_RtcGetOffsetDateTimeForUtcLabel:
_RtcGetOffsetDateTimeForUtc equ _RtcGetOffsetDateTimeForUtcLabel-branchTableBase
    .dw RtcGetOffsetDateTimeForUtc
    .db 2
;
_RtcSetClockLabel:
_RtcSetClock equ _RtcSetClockLabel-branchTableBase
    .dw RtcSetClock
    .db 2
_RtcSetTimeZoneLabel:
_RtcSetTimeZone equ _RtcSetTimeZoneLabel-branchTableBase
    .dw RtcSetTimeZone
    .db 2
_RtcGetTimeZoneLabel:
_RtcGetTimeZone equ _RtcGetTimeZoneLabel-branchTableBase
    .dw RtcGetTimeZone
    .db 2

; denominate2.asm
_ApplyRpnDenominateUnitLabel:
_ApplyRpnDenominateUnit equ _ApplyRpnDenominateUnitLabel-branchTableBase
    .dw ApplyRpnDenominateUnit
    .db 2
_GetRpnDenominateDisplayValueLabel:
_GetRpnDenominateDisplayValue equ _GetRpnDenominateDisplayValueLabel-branchTableBase
    .dw GetRpnDenominateDisplayValue
    .db 2
_ConvertRpnDenominateToBaseUnitLabel:
_ConvertRpnDenominateToBaseUnit equ _ConvertRpnDenominateToBaseUnitLabel-branchTableBase
    .dw ConvertRpnDenominateToBaseUnit
    .db 2
_ChsRpnDenominateLabel:
_ChsRpnDenominate equ _ChsRpnDenominateLabel-branchTableBase
    .dw ChsRpnDenominate
    .db 2
_AddRpnDenominateByDenominateLabel:
_AddRpnDenominateByDenominate equ _AddRpnDenominateByDenominateLabel-branchTableBase
    .dw AddRpnDenominateByDenominate
    .db 2
_SubRpnDenominateByDenominateLabel:
_SubRpnDenominateByDenominate equ _SubRpnDenominateByDenominateLabel-branchTableBase
    .dw SubRpnDenominateByDenominate
    .db 2
_MultRpnDenominateByRealLabel:
_MultRpnDenominateByReal equ _MultRpnDenominateByRealLabel-branchTableBase
    .dw MultRpnDenominateByReal
    .db 2
_DivRpnDenominateByRealLabel:
_DivRpnDenominateByReal equ _DivRpnDenominateByRealLabel-branchTableBase
    .dw DivRpnDenominateByReal
    .db 2
_DivRpnDenominateByDenominateLabel:
_DivRpnDenominateByDenominate equ _DivRpnDenominateByDenominateLabel-branchTableBase
    .dw DivRpnDenominateByDenominate
    .db 2
;
_RpnDenominatePercentLabel:
_RpnDenominatePercent equ _RpnDenominatePercentLabel-branchTableBase
    .dw RpnDenominatePercent
    .db 2
_RpnDenominatePercentChangeLabel:
_RpnDenominatePercentChange equ _RpnDenominatePercentChangeLabel-branchTableBase
    .dw RpnDenominatePercentChange
    .db 2
_RpnDenominateAbsLabel:
_RpnDenominateAbs equ _RpnDenominateAbsLabel-branchTableBase
    .dw RpnDenominateAbs
    .db 2
_RpnDenominateSignLabel:
_RpnDenominateSign equ _RpnDenominateSignLabel-branchTableBase
    .dw RpnDenominateSign
    .db 2
_RpnDenominateModLabel:
_RpnDenominateMod equ _RpnDenominateModLabel-branchTableBase
    .dw RpnDenominateMod
    .db 2
_RpnDenominateMinLabel:
_RpnDenominateMin equ _RpnDenominateMinLabel-branchTableBase
    .dw RpnDenominateMin
    .db 2
_RpnDenominateMaxLabel:
_RpnDenominateMax equ _RpnDenominateMaxLabel-branchTableBase
    .dw RpnDenominateMax
    .db 2
;
_RpnDenominateIntPartLabel:
_RpnDenominateIntPart equ _RpnDenominateIntPartLabel-branchTableBase
    .dw RpnDenominateIntPart
    .db 2
_RpnDenominateFracPartLabel:
_RpnDenominateFracPart equ _RpnDenominateFracPartLabel-branchTableBase
    .dw RpnDenominateFracPart
    .db 2
_RpnDenominateFloorLabel:
_RpnDenominateFloor equ _RpnDenominateFloorLabel-branchTableBase
    .dw RpnDenominateFloor
    .db 2
_RpnDenominateCeilLabel:
_RpnDenominateCeil equ _RpnDenominateCeilLabel-branchTableBase
    .dw RpnDenominateCeil
    .db 2
_RpnDenominateNearLabel:
_RpnDenominateNear equ _RpnDenominateNearLabel-branchTableBase
    .dw RpnDenominateNear
    .db 2
;
_RpnDenominateRoundToFixLabel:
_RpnDenominateRoundToFix equ _RpnDenominateRoundToFixLabel-branchTableBase
    .dw RpnDenominateRoundToFix
    .db 2
_RpnDenominateRoundToGuardLabel:
_RpnDenominateRoundToGuard equ _RpnDenominateRoundToGuardLabel-branchTableBase
    .dw RpnDenominateRoundToGuard
    .db 2
_RpnDenominateRoundToNLabel:
_RpnDenominateRoundToN equ _RpnDenominateRoundToNLabel-branchTableBase
    .dw RpnDenominateRoundToN
    .db 2

; formatdenominate2.asm
_FormatDenominateLabel:
_FormatDenominate equ _FormatDenominateLabel-branchTableBase
    .dw FormatDenominate
    .db 2

; base2.asm
_ColdInitBaseLabel:
_ColdInitBase equ _ColdInitBaseLabel-branchTableBase
    .dw ColdInitBase
    .db 2
_BitwiseAndLabel:
_BitwiseAnd equ _BitwiseAndLabel-branchTableBase
    .dw BitwiseAnd
    .db 2
_BitwiseOrLabel:
_BitwiseOr equ _BitwiseOrLabel-branchTableBase
    .dw BitwiseOr
    .db 2
_BitwiseXorLabel:
_BitwiseXor equ _BitwiseXorLabel-branchTableBase
    .dw BitwiseXor
    .db 2
_BitwiseNotLabel:
_BitwiseNot equ _BitwiseNotLabel-branchTableBase
    .dw BitwiseNot
    .db 2
_BitwiseNegLabel:
_BitwiseNeg equ _BitwiseNegLabel-branchTableBase
    .dw BitwiseNeg
    .db 2
;
_BaseShiftLeftLogicalLabel:
_BaseShiftLeftLogical equ _BaseShiftLeftLogicalLabel-branchTableBase
    .dw BaseShiftLeftLogical
    .db 2
_BaseShiftRightLogicalLabel:
_BaseShiftRightLogical equ _BaseShiftRightLogicalLabel-branchTableBase
    .dw BaseShiftRightLogical
    .db 2
_BaseShiftRightArithmeticLabel:
_BaseShiftRightArithmetic equ _BaseShiftRightArithmeticLabel-branchTableBase
    .dw BaseShiftRightArithmetic
    .db 2
_BaseShiftLeftLogicalNLabel:
_BaseShiftLeftLogicalN equ _BaseShiftLeftLogicalNLabel-branchTableBase
    .dw BaseShiftLeftLogicalN
    .db 2
_BaseShiftRightLogicalNLabel:
_BaseShiftRightLogicalN equ _BaseShiftRightLogicalNLabel-branchTableBase
    .dw BaseShiftRightLogicalN
    .db 2
;
_BaseRotateLeftCircularLabel:
_BaseRotateLeftCircular equ _BaseRotateLeftCircularLabel-branchTableBase
    .dw BaseRotateLeftCircular
    .db 2
_BaseRotateRightCircularLabel:
_BaseRotateRightCircular equ _BaseRotateRightCircularLabel-branchTableBase
    .dw BaseRotateRightCircular
    .db 2
_BaseRotateLeftCarryLabel:
_BaseRotateLeftCarry equ _BaseRotateLeftCarryLabel-branchTableBase
    .dw BaseRotateLeftCarry
    .db 2
_BaseRotateRightCarryLabel:
_BaseRotateRightCarry equ _BaseRotateRightCarryLabel-branchTableBase
    .dw BaseRotateRightCarry
    .db 2
;
_BaseRotateLeftCircularNLabel:
_BaseRotateLeftCircularN equ _BaseRotateLeftCircularNLabel-branchTableBase
    .dw BaseRotateLeftCircularN
    .db 2
_BaseRotateRightCircularNLabel:
_BaseRotateRightCircularN equ _BaseRotateRightCircularNLabel-branchTableBase
    .dw BaseRotateRightCircularN
    .db 2
_BaseRotateLeftCarryNLabel:
_BaseRotateLeftCarryN equ _BaseRotateLeftCarryNLabel-branchTableBase
    .dw BaseRotateLeftCarryN
    .db 2
_BaseRotateRightCarryNLabel:
_BaseRotateRightCarryN equ _BaseRotateRightCarryNLabel-branchTableBase
    .dw BaseRotateRightCarryN
    .db 2
;
_BaseAddLabel:
_BaseAdd equ _BaseAddLabel-branchTableBase
    .dw BaseAdd
    .db 2
_BaseSubLabel:
_BaseSub equ _BaseSubLabel-branchTableBase
    .dw BaseSub
    .db 2
_BaseMultLabel:
_BaseMult equ _BaseMultLabel-branchTableBase
    .dw BaseMult
    .db 2
_BaseDivLabel:
_BaseDiv equ _BaseDivLabel-branchTableBase
    .dw BaseDiv
    .db 2
_BaseDiv2Label:
_BaseDiv2 equ _BaseDiv2Label-branchTableBase
    .dw BaseDiv2
    .db 2
;
_BaseReverseBitsLabel:
_BaseReverseBits equ _BaseReverseBitsLabel-branchTableBase
    .dw BaseReverseBits
    .db 2
_BaseCountBitsLabel:
_BaseCountBits equ _BaseCountBitsLabel-branchTableBase
    .dw BaseCountBits
    .db 2
_BaseSetBitLabel:
_BaseSetBit equ _BaseSetBitLabel-branchTableBase
    .dw BaseSetBit
    .db 2
_BaseClearBitLabel:
_BaseClearBit equ _BaseClearBitLabel-branchTableBase
    .dw BaseClearBit
    .db 2
_BaseGetBitLabel:
_BaseGetBit equ _BaseGetBitLabel-branchTableBase
    .dw BaseGetBit
    .db 2
;
_BaseStoreCarryFlagLabel:
_BaseStoreCarryFlag equ _BaseStoreCarryFlagLabel-branchTableBase
    .dw BaseStoreCarryFlag
    .db 2
_BaseGetCarryFlagLabel:
_BaseGetCarryFlag equ _BaseGetCarryFlagLabel-branchTableBase
    .dw BaseGetCarryFlag
    .db 2
;
_BaseSetWordSizeLabel:
_BaseSetWordSize equ _BaseSetWordSizeLabel-branchTableBase
    .dw BaseSetWordSize
    .db 2
_BaseGetWordSizeLabel:
_BaseGetWordSize equ _BaseGetWordSizeLabel-branchTableBase
    .dw BaseGetWordSize
    .db 2

; prime2.asm
_PrimeFactorLabel:
_PrimeFactor equ _PrimeFactorLabel-branchTableBase
    .dw PrimeFactor
    .db 2

; integerconv32.asm
_ConvertOP1ToUxxNoFatalLabel:
_ConvertOP1ToUxxNoFatal equ _ConvertOP1ToUxxNoFatalLabel-branchTableBase
    .dw ConvertOP1ToUxxNoFatal
    .db 2

; formatinteger32.asm
_FormatCodedU32ToHexStringLabel:
_FormatCodedU32ToHexString equ _FormatCodedU32ToHexStringLabel-branchTableBase
    .dw FormatCodedU32ToHexString
    .db 2
_FormatCodedU32ToOctStringLabel:
_FormatCodedU32ToOctString equ _FormatCodedU32ToOctStringLabel-branchTableBase
    .dw FormatCodedU32ToOctString
    .db 2
_FormatCodedU32ToBinStringLabel:
_FormatCodedU32ToBinString equ _FormatCodedU32ToBinStringLabel-branchTableBase
    .dw FormatCodedU32ToBinString
    .db 2
_FormatCodedU32ToDecStringLabel:
_FormatCodedU32ToDecString equ _FormatCodedU32ToDecStringLabel-branchTableBase
    .dw FormatCodedU32ToDecString
    .db 2
_FormatU32ToHexStringLabel:
_FormatU32ToHexString equ _FormatU32ToHexStringLabel-branchTableBase
    .dw FormatU32ToHexString
    .db 2
_FormatU32ToOctStringLabel:
_FormatU32ToOctString equ _FormatU32ToOctStringLabel-branchTableBase
    .dw FormatU32ToOctString
    .db 2
_FormatU32ToBinStringLabel:
_FormatU32ToBinString equ _FormatU32ToBinStringLabel-branchTableBase
    .dw FormatU32ToBinString
    .db 2
_FormatU32ToDecStringLabel:
_FormatU32ToDecString equ _FormatU32ToDecStringLabel-branchTableBase
    .dw FormatU32ToDecString
    .db 2

; format2.asm
_FormatAToStringLabel:
_FormatAToString equ _FormatAToStringLabel-branchTableBase
    .dw FormatAToString
    .db 2

; show2.asm
_ClearShowAreaLabel:
_ClearShowArea equ _ClearShowAreaLabel-branchTableBase
    .dw ClearShowArea
    .db 2
_FormShowableLabel:
_FormShowable equ _FormShowableLabel-branchTableBase
    .dw FormShowable
    .db 2

; display2.asm
_ColdInitDisplayLabel:
_ColdInitDisplay equ _ColdInitDisplayLabel-branchTableBase
    .dw ColdInitDisplay
    .db 2
_InitDisplayLabel:
_InitDisplay equ _InitDisplayLabel-branchTableBase
    .dw InitDisplay
    .db 2
_PrintMenuNameAtCLabel:
_PrintMenuNameAtC equ _PrintMenuNameAtCLabel-branchTableBase
    .dw PrintMenuNameAtC
    .db 2
_DisplayMenuFolderLabel:
_DisplayMenuFolder equ _DisplayMenuFolderLabel-branchTableBase
    .dw DisplayMenuFolder
    .db 2
_PrintInputBufLabel:
_PrintInputBuf equ _PrintInputBufLabel-branchTableBase
    .dw PrintInputBuf
    .db 2

;-----------------------------------------------------------------------------
; Branch table entries for routines on Flash Page 3.
;-----------------------------------------------------------------------------

; menu3.asm
_ColdInitMenuLabel:
_ColdInitMenu equ _ColdInitMenuLabel-branchTableBase
    .dw ColdInitMenu
    .db 3
_SanitizeMenuLabel:
_SanitizeMenu equ _SanitizeMenuLabel-branchTableBase
    .dw SanitizeMenu
    .db 3
_ClearJumpBackLabel:
_ClearJumpBack equ _ClearJumpBackLabel-branchTableBase
    .dw ClearJumpBack
    .db 3
_SaveJumpBackLabel:
_SaveJumpBack equ _SaveJumpBackLabel-branchTableBase
    .dw SaveJumpBack
    .db 3
_GetCurrentMenuArrowStatusLabel:
_GetCurrentMenuArrowStatus equ _GetCurrentMenuArrowStatusLabel-branchTableBase
    .dw GetCurrentMenuArrowStatus
    .db 3
_GetMenuIdOfButtonLabel:
_GetMenuIdOfButton equ _GetMenuIdOfButtonLabel-branchTableBase
    .dw GetMenuIdOfButton
    .db 3
_GetCurrentMenuRowBeginIdLabel:
_GetCurrentMenuRowBeginId equ _GetCurrentMenuRowBeginIdLabel-branchTableBase
    .dw GetCurrentMenuRowBeginId
    .db 3
_GetCurrentMenuGroupNumRowsLabel:
_GetCurrentMenuGroupNumRows equ _GetCurrentMenuGroupNumRowsLabel-branchTableBase
    .dw GetCurrentMenuGroupNumRows
    .db 3
;
_ExtractMenuNamesLabel:
_ExtractMenuNames equ _ExtractMenuNamesLabel-branchTableBase
    .dw ExtractMenuNames
    .db 3
_GetMenuNodeHandlerLabel:
_GetMenuNodeHandler equ _GetMenuNodeHandlerLabel-branchTableBase
    .dw GetMenuNodeHandler
    .db 3
_GetMenuNodeParentLabel:
_GetMenuNodeParent equ _GetMenuNodeParentLabel-branchTableBase
    .dw GetMenuNodeParent
    .db 3
_GetMenuNodeRowBeginIdLabel:
_GetMenuNodeRowBeginId equ _GetMenuNodeRowBeginIdLabel-branchTableBase
    .dw GetMenuNodeRowBeginId
    .db 3
