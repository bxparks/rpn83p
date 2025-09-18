;-----------------------------------------------------------------------------
; MIT License
; Copyright (c) 2023 Brian T. Park
;
; Online HELP strings.
;
; Capitalized labels are intended to be exported to the branch table on flash
; page 0. Lowercased labels are intended to be local to the current flash page.
;-----------------------------------------------------------------------------

; Array of (char*) pointers to C-strings.
helpPages:
    .dw msgHelpPage1
    .dw msgHelpPage2
    .dw msgHelpPage3
    .dw msgHelpPage4
    .dw msgHelpPage5
    .dw msgHelpPage6
    .dw msgHelpPage7
    .dw msgHelpPage8
    .dw msgHelpPage9
    .dw msgHelpPage10
    .dw msgHelpPage11
    .dw msgHelpPage12
    .dw msgHelpPage13
    .dw msgHelpPage14
    .dw msgHelpPage15
    .dw msgHelpPage16
    .dw msgHelpPage17
    .dw msgHelpPage18
    .dw msgHelpPage19
helpPagesEnd:
helpPageCount equ (helpPagesEnd-helpPages)/2

msgHelpPage1:
    .db escapeLargeFont, "RPN83P", Lenter
    .db escapeSmallFont, "v1.1.0", Shyphen, "dev (2025", Shyphen, "09", Shyphen, "18)", Senter
    ;.db escapeSmallFont, "v1.0.0 (2024", Shyphen, "07", Shyphen, "19)", Senter
    .db "(c) 2023", Shyphen, "2025 Brian T. Park", Senter
    .db Senter
    .db "An RPN calculator for the", Senter
    .db "TI", Shyphen, "83 Plus and TI", Shyphen, "84 Plus", Senter
    .db "inspired by the HP", Shyphen, "42S.", Senter
    .db Senter
    .db SlBrack, "1/19", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage2:
    .db escapeLargeFont, "Menu Navigation", Lenter
    .db escapeSmallFont, "MATH: Home", Senter
    .db "UP: Prev row", Senter
    .db "DOWN: Next row", Senter
    .db "ON: Back/Exit", Senter
    .db Senter
    .db "2ND QUIT: Quit", Senter
    .db "2ND OFF: Off", Senter
    .db SlBrack, "2/19", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage3:
    .db escapeLargeFont, "Input Editing", Lenter
    .db escapeSmallFont, "(-): +/-", Senter
    .db "2ND EE: EE", Senter
    .db "{ } ,: Record objects", Senter
    .db Senter
    .db "DEL: Delete left", Senter
    .db "CLEAR: CLX", Senter
    .db "CLEAR CLEAR CLEAR: CLST", Senter
    .db SlBrack, "3/19", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage4:
    .db escapeLargeFont, "Cursor Movement", Lenter
    .db escapeSmallFont, "LEFT: Cursor left", Senter
    .db "RIGHT: Cursor right", Senter
    .db Senter
    .db "2ND LEFT: Begin of line", Senter
    .db "2ND RIGHT: End of line", Senter
    .db Senter
    .db Senter
    .db SlBrack, "4/19", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage5:
    .db escapeLargeFont, "Stack Ops", Lenter
    .db escapeSmallFont, "(: R", SdownArrow, Senter
    .db "2ND u: R", SupArrow, Senter
    .db "): X", Sleft, Sconvert, "Y", Senter
    .db "2ND ANS: LastX", Senter
    .db "DUP: Duplicate X", Senter
    .db "DROP: Delete X", Senter
    .db "SSIZ: Stack size: 4..8", Senter
    .db SlBrack, "5/19", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage6:
    .db escapeLargeFont, "Display Modes", Lenter
    .db escapeSmallFont, "FIX nn: Fixed", Senter
    .db "SCI nn: Scientific", Senter
    .db "ENG nn: Engineering", Senter
    .db SFourSpaces, "nn: 0..9: Num digits", Senter
    .db SFourSpaces, "nn: 10..99: Reset to floating", Senter
    .db "2ND ENTRY: SHOW", Senter
    .db Senter
    .db SlBrack, "6/19", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage7:
    .db escapeLargeFont, "Complex Modes", Lenter
    .db escapeSmallFont, "RRES: Real results", Senter
    .db "CRES: Complex results", Senter
    .db Senter
    .db "RECT: Rectangular", Senter
    .db "PRAD: Polar radian", Senter
    .db "PDEG: Polar degree", Senter
    .db Senter
    .db SlBrack, "7/19", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage8:
    .db escapeLargeFont, "Complex Entry", Lenter
    .db escapeSmallFont, "2ND ", SimagI, ": a ", SimagI, " b", Senter
    .db "2ND ANGLE: r ", Sangle, Stemp, " ", Stheta, Senter
    .db "2ND ANGLE 2ND ANGLE: r ", Sangle, " ", Stheta, Senter
    .db Senter
    .db "2ND LINK: X,Y to complex", Senter
    .db Senter
    .db Senter
    .db SlBrack, "8/19", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage9:
    .db escapeLargeFont, "Register Ops", Lenter
    .db escapeSmallFont, "STO nn", Senter
    .db "STO+ STO- STO* STO/ nn", Senter
    .db "RCL nn", Senter
    .db "RCL+ RCL- RCL* RCL/ nn", Senter
    .db SFourSpaces, "nn: 0..(RSIZ-1), A-Z, ", Stheta, Senter
    .db "RSIZ: Register size: 25..100", Senter
    .db Senter
    .db SlBrack, "9/19", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage10:
    .db escapeLargeFont, "NUM Functions", Lenter
    .db escapeSmallFont, "%: Y=Y, X=Y*X/100", Senter
    .db "%CH: Y=Y, X=100*(X-Y)/Y", Senter
    .db "PRIM: Smallest prime factor", Senter
    .db Senter
    .db "RNDF: Round to FIX/SCI/ENG", Senter
    .db "RNDN: Round to N digits", Senter
    .db "RNDG: Round to guard digits", Senter
    .db SlBrack, "10/19", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage11:
    .db escapeLargeFont, "CONV Arguments", Lenter
    .db escapeSmallFont, Sconvert, "POL ", Sconvert, "REC:", Senter
    .db SFourSpaces, "Y: y or ", Stheta, Senter
    .db SFourSpaces, "X: x or r", Senter
    .db Sconvert, "HMS: hh.mmss", Senter
    .db "ATN2: Same as ", Sconvert, "POL", Senter
    .db Senter
    .db Senter
    .db SlBrack, "11/19", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage12:
    .db escapeLargeFont, "STAT Functions", Lenter
    .db escapeSmallFont, "WMN: Weighted Mean", Senter
    .db SFourSpaces, "Y: ", ScapSigma, "XY/", ScapSigma, "X", Senter
    .db SFourSpaces, "X: ", ScapSigma, "XY/", ScapSigma, "Y", Senter
    .db "SDEV: Sample Std Deviation", Senter
    .db "SCOV: Sample Covariance", Senter
    .db "PDEV: Pop Std Deviation", Senter
    .db "PCOV: Pop Covariance", Senter
    .db SlBrack, "12/19", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage13:
    .db escapeLargeFont, "CFIT Models", Lenter
    .db escapeSmallFont, "LINF: y = B + M x", Senter
    .db "LOGF: y = B + M lnx", Senter
    .db "EXPF: y = B e^(M x)", Senter
    .db "PWRF: y = B x^M", Senter
    .db "BEST: Select best model", Senter
    .db Senter
    .db Senter
    .db SlBrack, "13/19", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage14:
    .db escapeLargeFont, "BASE Ops", Lenter
    .db escapeSmallFont, "SL,SR: Shift Logical", Senter
    .db "ASR: Arithmetic Shift Right", Senter
    .db "RL,RR: Rotate Circular",  Senter
    .db "RLC,RRC: Rotate thru Carry",  Senter
    .db "REVB: Reverse Bits", Senter
    .db "CNTB: Count Bits", Senter
    .db "WSIZ: 8, 16, 24, 32", Senter
    .db SlBrack, "14/19", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage15:
    .db escapeLargeFont, "TVM", Lenter
    .db escapeSmallFont, "Outflow: -", Senter
    .db "Inflow: +", Senter
    .db "P/YR: Payments/year", Senter
    .db "C/YR: Compoundings/year", Senter
    .db "BEG: Payments at begin", Senter
    .db "END: Payments at end", Senter
    .db "CLTV: Clear TVM",  Senter
    .db SlBrack, "15/19", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage16:
    .db escapeLargeFont, "TVM Solver", Lenter
    .db escapeSmallFont, "IYR1: I%YR guess 1",  Senter
    .db "IYR2: I%YR guess 2",  Senter
    .db "TMAX: Iteration max",  Senter
    .db "RSTV: Reset TVM Solver",  Senter
    .db Senter
    .db Senter
    .db Senter
    .db SlBrack, "16/19", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage17:
    .db escapeLargeFont, "Date Objects", Lenter
    .db escapeSmallFont, "D{y,m,d}: Date", Senter
    .db "T{h,m,s}: Time", Senter
    .db "DT{D,T}: DateTime", Senter
    .db "TZ{h,m}: TimeZone",  Senter
    .db "DZ{D,T,TZ}: ZonedDateTime", Senter
    .db "DW{dw}: DayOfWeek (Mon=1)", Senter
    .db "DR{d,h,m,s}: Duration", Senter
    .db SlBrack, "17/19", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage18:
    .db escapeLargeFont, "Date Ops", Lenter
    .db escapeSmallFont, "DZ*TZ", Sstore, "DZ: Convert TZ", Senter
    .db "D+n", Sstore, "D: Add", Senter
    .db "D-D", Sstore, "n: Subtract", Senter
    .db "DSHK: Shrink (2ND", Sroot, ")", Senter
    .db "DEXD: Extend (X", Ssquare, ")", Senter
    .db "DCUT: Cut (X", Sinverse, ")", Senter
    .db "DLNK: Link (2ND LINK)", Senter
    .db SlBrack, "18/19", SrBrack, " Any key to continue...", Senter
    .db 0

msgHelpPage19:
    .db escapeLargeFont, "Hardware Clock", Lenter
    .db escapeSmallFont, "TZ,TZ?: Application TZ", Senter
    .db "CTZ,CTZ?: Clock TZ", Senter
    .db "SETC: Set Clock DZ", Senter
    .db "NOW: Get Epochseconds", Senter
    .db "NOWD: Get Date", Senter
    .db "NOWT: Get Time", Senter
    .db "NWDZ: Get ZonedDateTime", Senter
    .db SlBrack, "19/19", SrBrack, " Any key to return.", Senter
    .db 0
