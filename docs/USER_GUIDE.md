# RPN83P User Guide

RPN calculator app for the TI-83 Plus and TI-84 Plus inspired by the HP-42S.

**Version**: 1.1.0 (2025-10-07)\
**Project Home**: https://github.com/bxparks/rpn83p

## Introduction

RPN83P is an [RPN](https://en.wikipedia.org/wiki/Reverse_Polish_notation)
calculator app for the [TI-83 Plus
series](https://en.wikipedia.org/wiki/TI-83_series) and the [TI-84 Plus
series](https://en.wikipedia.org/wiki/TI-84_Plus_series) calculators. The app is
inspired mostly by the [HP-42S](https://en.wikipedia.org/wiki/HP-42S)
calculator, with some significant features from the
[HP-12C](https://en.wikipedia.org/wiki/HP-12C) and the
[HP-16C](https://en.wikipedia.org/wiki/HP-16C). RPN83P also hopes to be the
easiest and cheapest gateway app that introduces new users to the beauty and
power of RPN calculators.

RPN83P is a flash application written in Z80 assembly language that consumes 3
pages (48 kiB) of flash memory. Since it is stored in flash, it is preserved if
the RAM is cleared. It consumes about 1025 to 2535 bytes of TI-OS RAM through 4
AppVars, depending on the number of storage registers: `RPN83REG` (500 to 1925
bytes), `RPN83SAV` (140 byte), `RPN83STA` (272 bytes), and `RPN83STK` (120 to
196 bytes).

Summary of features:

- traditional RPN stack (`X`, `Y`, `Z`, `T`), with `LASTX` register
    - configurable stack levels between 4 and 8: `SSIZ`, `SSZ?`
- input edit line with scrollable cursor using arrow keys
    - `LEFT`, `RIGHT`, `2ND LEFT`, `2ND RIGHT`
- 8-line display showing 4 stack registers
- hierarchical menu system similar to HP-42S
- quick reference `HELP` menu
- auto-start capability using the Start-Up app
- storage registers and variables
    - store and recall:`STO nn`, `RCL nn`
    - storage arithmetics: `STO+ nn`, `STO- nn`, `STO* nn`, `STO/ nn`, `RCL+
      nn`, `RCL- nn`, `RCL* nn`, `RCL/ nn`
    - up to 100 numerical storage registers (`nn = 00..99`, default 25)
    - 27 single-letter variables (`nn = A..Z,Theta`)
    - configurable number of storage registers: `RSIZ`, `RSZ?`
- all math functions with dedicated buttons on the TI-83 Plus and TI-84 Plus
    - arithmetic: `/`, `*`, `-`, `+`
    - algebraic: `1/X`, `X^2`, `SQRT`, `^` (i.e. `Y^X`)
    - transcendental: `LOG`, `10^X`, `LN`, `E^X`
    - trigonometric: `SIN`, `COS`, `TAN`, `ASIN`, `ACOS`, `ATAN`
    - constants: `PI` and `E`
- additional menu functions
    - arithmetic: `%`, `%CH`, `GCD`, `LCM`, `PRIM` (prime factor), `IP` (integer
      part), `FP` (fractional part), `FLR` (floor), `CEIL` (ceiling), `NEAR`
      (nearest integer), `ABS`, `SIGN`, `MOD`, `MIN`, `MAX`
    - rounding: `RNDF`, `RNDN`, `RNDG`
    - algebraic: `X^3`, `3RootX`
    - transcendental: `XROOTY`,`2^X`, `LOG2`, `LOGB`, `E^X-` (e^x-1), `LN1+`
      (log(1+x))
    - trigonometric: `ATN2`
    - hyperbolic: `SINH`, `COSH`, `TANH`, `ASNH`, `ACSH`, `ATNH`
    - probability: `PERM`, `COMB`, `N!`, `RAND`, `SEED`
    - angle conversions: `>DEG`, `>RAD`, `>REC`, `>POL`, `>HR`, `>HMS`, `HMS+`,
      `HMS-`
- statistics and curve fitting, inspired by HP-42S
    - statistics: `Σ+`, `Σ-`, `SUM`, `MEAN`, `WMN` (weighted mean),
      `SDEV` (sample standard deviation), `SCOV` (sample covariance),
      `PDEV` (population standard deviation), `PCOV` (population covariance)
    - curve fitting: `Y>X`, `X>Y`, `SLOP` (slope), `YINT` (y intercept), `CORR`
      (correlation coefficient)
    - curve fit models: `LINF` (linear), `LOGF` (logarithmic), `EXPF`
      (exponential), `PWRF` (power)
- base conversion and bitwise operations, inspired by HP-16C and HP-42S
    - base conversions: `DEC`, `HEX`, `OCT`, `BIN`
    - logical operations: `AND`, `OR`, `XOR`, `NOT`, `NEG`
    - rotate and shift: `SL`, `SR`, `ASR`, `RL`, `RR`, `RLC`, `RRC`,
      `SLn`, `SRn`, `RLn`, `RRn`, `RLCn`, `RRCn`
    - bit operations: `CB`, `SB`, `B?`, `REVB` (reverse bits), `CNTB` (count
      bits)
    - arithmetic functions: `BAS+`, `BAS-`, `BAS*`, `BAS/`, `BDIV` (divide with
      remainder)
    - carry flag: `CCF`, `SCF`, `CF?`
    - word sizes: `WSIZ`, `WSZ?`: 8, 16, 24, 32 bits
- time value of money (TVM), inspired by HP-12C, HP-17B, and HP-30b
    - `N`, `I%YR`, `PV`, `PMT`, `FV`
    - `P/YR`, `C/YR`, `BEG`, `END`, `CLTV` (clear TVM)
- complex numbers, inspired by HP-42S and HP-35s
    - stored in RPN stack registers (`X`, `Y`, `Z`, `T`, `LASTX`) and storage
      registers `R00-R99`
    - result modes: `RRES` (real results), `CRES` (complex results)
    - display modes: `RECT`, `PRAD` (polar radians), `PDEG` (polar degrees)
    - linking/unlinking: `2ND LINK` (convert 2 reals to 1 complex, same as
      `COMPLEX` on HP-42S)
    - number entry: `2ND i` (rectangular), `2ND ANGLE` (polar degrees), `2ND
      ANGLE 2ND ANGLE` (polar radians)
    - extended regular functions: `+`, `-`, `*`, `/`, `1/X`, `X^2`, `SQRT`,
      `Y^X`, `X^3`, `3ROOTX`, `XROOTY`, `LOG`, `LN`, `10^X`, `E^X`, `2^X`,
      `LOG2`, `LOGB`
    - complex specific functions: `REAL`, `IMAG`, `CONJ`, `CABS`, `CANG`
    - unsupported: trigonometric and hyperbolic functions (not supported by
      TI-OS)
- unit conversions, inspired by HP-19BII and TI-85
    - ~170 units across 12 unit types (LENG, AREA, VOL, TEMP, MASS, FORC, PRES,
      ENER, PWR, TIME, SPD, FUEL)
    - includes all 63 units on the HP-19BII and all 90 units on the TI-85
- date functions
    - date, time, datetime, timezone, and hardware clock
    - proleptic Gregorian calendar from year 0001 to 9999
    - add or subtract dates, times, datetimes
    - convert datetime to different timezones
    - convert between datetime and epochseconds
    - support alternate Epoch dates (Unix, NTP, GPS, TIOS, Y2K, custom)
    - set and retrieve datetime from the hardware clock (84+/84+SE only)
    - display time and date objects in RFC 3339 (ISO 8601) format
- various modes (`MODE`)
    - floating display: `FIX`, `SCI`, `ENG`
    - trigonometric: `RAD`, `DEG`
    - complex result modes: `RRES`, `CRES`
    - complex display modes: `RECT`, `PRAD`, `PDEG`
    - `SHOW` (`2ND ENTRY`): display all 14 internal digits

Missing features (partial list):

- vectors and matrices
- keystroke programming

## Chapters

- [Chapter 1: Why?](USER_GUIDE_WHY.md)
- [Chapter 2: Installation](USER_GUIDE_INSTALLATION.md)
- [Chapter 3: Basic Concepts](USER_GUIDE_BASIC.md)
- [Chapter 4: Storage Registers and Variables](USER_GUIDE_STORAGE.md)
- [Chapter 5: MODE Functions](USER_GUIDE_MODE.md)
- [Chapter 6: CLR Functions](USER_GUIDE_CLR.md)
- [Chapter 7: STK Functions](USER_GUIDE_STK.md)
- [Chapter 8: MATH Functions](USER_GUIDE_MATH.md)
- [Chapter 9: NUM Functions](USER_GUIDE_NUM.md)
- [Chapter 10: PROB Functions](USER_GUIDE_PROB.md)
- [Chapter 11: Complex Numbers](USER_GUIDE_COMPLEX.md)
- [Chapter 12: BASE Functions](USER_GUIDE_BASE.md)
- [Chapter 13: STAT Functions](USER_GUIDE_STAT.md)
- [Chapter 14: CONV Functions](USER_GUIDE_CONV.md)
- [Chapter 15: TVM Functions](USER_GUIDE_TVM.md)
- [Chapter 16: UNIT Functions](SER_GUIDE_UNIT.md)
- [Chapter 17: DATE Functions](USER_GUIDE_DATE.md)
- [Chapter 18: Catalog of Functions](USER_GUIDE_CATALOG.md)
- [Chapter 19: TI-OS Interaction](USER_GUIDE_TIOS.md)
- [Chapter 20: Troubleshooting](USER_GUIDE_TROUBLESHOOTING.md)
- [Chapter 21: Future Enhancements](USER_GUIDE_FUTURE.md)
