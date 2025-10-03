# RPN83P User Guide

RPN calculator app for the TI-83 Plus and TI-84 Plus inspired by the HP-42S.

**Version**: 1.0.0 (2024-07-19)

**Project Home**: https://github.com/bxparks/rpn83p

## Table of Contents

- [Introduction](#introduction)
- [Why?](#why)
    - [Short Answer](#short-answer)
    - [Long Answer](#long-answer)
- [Installation](#installation)
- [Basic Usage](#basic-usage)
- [Catalog of Functions](#catalog-of-functions)
- [Advanced Topics](#advanced-topics)
    - [Storage Registers and Variables](#storage-registers-and-variables)
    - [MODE Functions](#mode-functions)
    - [NUM Functions](#num-functions)
    - [BASE Functions](#base-functions)
    - [STAT Functions](#stat-functions)
    - [TVM Functions](#tvm-functions)
    - [Complex Numbers](#complex-numbers)
    - [UNIT Functions](#unit-functions)
    - [DATE Functions](#date-functions)
- [TI-OS Interaction](#ti-os-interaction)
- [Troubleshooting](#troubleshooting)
- [Future Enhancements](#future-enhancements)

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
    - 169 units across 12 unit types (LENG, AREA, VOL, TEMP, MASS, FORC, PRES,
      ENER, PWR, TIME, SPD, FUEL)
    - all units of the HP-19BII and TI-85 are supported
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

## Why?

### Short Answer

The initial motivation for this project was for me to relearn Z80 assembly
language programming through the process of creating a useful RPN calculator in
the spirit of the HP-42S. Now that I have done more Z80 programming than I had
intended, I continue to work on this project to explore various programming
ideas, numerical algorithms, and mathematical concepts.

In addition, I have added another goal for RPN83P. I want RPN83P to be one of
the most affordable ways for new users to learn and use a full-featured
scientific RPN calculator. HP no longer makes scientific RPN calculators (except
perhaps the reissued HP-15C Collector's Edition which may be a limited release).
The prices for used HP calculators are unreasonably high. The only other
alternatives are the offerings from SwissMicros which are in the $150-$300
range. RPN83P offers access to a scientific RPN app on readily obtainable
TI-83+/84+ calculators in the $20-$50 range. I hope RPN83P can be the gateway
application that introduces a new generation of users to the usefulness of RPN
calculators.

### Long Answer

There are many facets to the "Why?" question. I will try to answer some of them.

**Why HP-42S?**

RPN83P is inspired by the HP-42S because it is the RPN calculator that I know
best. I used it extensively in grad school. After graduating, I sold the
calculator, which I regretted later. Some people consider the HP-42S close to
["peak of perfection for the classic HP
calcs"](https://www.hpmuseum.org/cgi-sys/cgiwrap/hpmuseum/archv017.cgi?read=118462) and I am probably in general agreement with that sentiment.

The HP-42S also has the advantage of having the
[Free42](https://thomasokken.com/free42/) app (Android, iOS, Windows, MacOS,
Linux) which faithfully reproduces every feature of the HP-42S. This is
essential because I don't own an actual HP-42S anymore to verify obscure edge
cases which may not be documented. Another advantage of the HP-42S is that a
hardware clone is currently in production by SwissMicros as the
[DM42](https://www.swissmicros.com/product/dm42). This increases the number of
users who may be familiar with the user interface and behavior of the HP-42S.

**Why Is RPN83P Different From HP-42S?**

The RPN83P app is not a clone of the HP-42S for several reasons:

- The keyboard layout and labels of the TI-83 and TI-84 calculators are
  different. As an obvious example, the TI calculators have 5 menu buttons below
  the LCD screen, but the HP-42S has 6 menu buttons.
- The LCD screen width allows each menu to contain only 4 letters instead of the
  5 supported by the HP-42S. I cannot even use the same menu names as the
  HP-42S.
- The RPN83P app does not implement its own floating point routines, but uses
  the ones provided by the underlying TI-OS. There are functions missing from
  the TI-OS compared to the HP-42S (e.g. trigonometric functions on complex
  numbers). The HP-42S supports exponents up to +/-499, but the TI-OS supports
  exponents only to +/-99.
- I have added additional features to RPN83P which were not originally included
  in the HP-42S (e.g. BASE operations from the HP-16C, and TVM functions from
  the HP-12C).
- The larger LCD screen of the TI-83+/84+ allows 4 registers of the RPN stack to
  be shown, instead of just the `X` and `Y` registers on the HP-42S. There is
  also enough room to show the hierarchical menu bar at all times.

**Why TI-83+/84+?**

The TI-83+ and 84+ series of calculators have been in production since 1999. I
believe the TI-84 Plus model is the last model still in production in 2024. They
are ubiquitous and extremely affordable on the used market ($20-$50 range on
ebay.com, sometimes cheaper when purchased locally). They are programmable in
Z80 assembly language and Texas Instruments published a [TI-83 Plus
SDK](https://archive.org/details/83psdk/83psysroutines/) which is still
available on [Internet Archive](https://archive.org).

The TI-83+/84+ calculators also have an active third party software development
community around them. People have written many essential tools and resources:
Z80 assemblers, ROM extraction tools, desktop emulators, file transfer and
linking tools, and additional online documentation containing information beyond
the official SDK documentation.

The TI-83+/84+ calculators also allow the installation of flash applications.
These are assembly language programs that live in flash memory instead of
volatile RAM. Flash applications survive crashes or power losses, and they can
be far larger than the ~8 kB limit imposed on assembly language programs that
live in RAM. RPN83P is currently about 48 kB and could not have been implemented
as a normal assembly language program.

**Why Not TI-84 Plus CE**

The TI-84 Plus CE model is the next generation of calculators after the TI-84
Plus series. It is based on the eZ80 processor instead of the Z80 processor used
by earlier models. The eZ80 processor is faster and supports larger memory sizes
through the use of a 24-bit address bus and internal registers instead of the
16-bit address bus and registers of the Z80.

Unfortunately in 2020, Texas Instruments decided to [disable assembly language
programming](https://www.cemetech.net/news/2020/5/950/_/ti-83-premium-ceti-84-plus-ce-asmc-removal-updates)
for the 84+CE model with the release of OS 5.3.1 That forced the community to
create a jailbreak for the 84+CE model named
[arTIfiCE](https://www.cemetech.net/news/2020/9/959/_/artifice-restores-ce-native-code-for-now)
in 2020. Furthermore, Texas Instruments does not provide the signing keys
necessary for third party developers to create flash applications which reside
in flash memory. That means that third party software are restricted to assembly
language programs that must live in volatile RAM. Texas Instruments clearly does
not want to support third party software development, and went out of its way to
add friction to the process.

An additional disadvantage of the 84+CE, for me personally, is that it uses a
rechargeable Li-Polymer battery instead of the standard AAA batteries used by
earlier models. These Li-Poly batteries have a finite lifetime, 3-5 years, and
there are many reports of defective batteries on brand new units. In the future,
these batteries will become difficult find, and may cost more than the
calculator itself is worth.

Considering all of the above, I felt that there are better uses of my time than
investing in the 84+CE platform.

**Why Not TI-89, 92+, Voyage 200?**

The TI-89, 89 Titanium, 92 Plus, and Voyage 200 series of calculators use the
Motorola 68000 microprocessor instead of the Z80 processor. Although they can be
programmed in assembly language, a C compiler (or two?) is available for these
calculators. But when I researched the state of third party development tools
for these calculators, I found that the development community was no longer
active.

I could not find a set of understandable documentation that would tell me how to
create a "hello world" application to get started on these calculators. In
contrast, the documentation for the 83+/84+ calculators were relatively easy to
find.

**Why Not Casio?**

Casio calculators are powerful and affordable. In some countries, particularly
in Europe, they are more popular than Texas Instruments calculators. A port of
RPN83P may be created in the future for models of Casio calculators which
support third-party applications.

**Why Not A Smartphone?**

There are already many RPN calculator apps available for smartphones. But using
a calculator on a smartphone has some drawbacks:

- the touchscreen of a phone does not give tactile feedback,
- the smartphone can impose some friction in usage, because we have to take the
  phone out from a pocket, unlock the phone, then find and fire up the
  calculator app,
- the battery life of a smartphone is relatively short compared to a calculator
  which is measured in weeks or months.

**Why Z80 Assembly Language?**

Normally a higher level language like C would be far more productive than Z80
assembly. However, C compilers for the Z80 processor are apparently quite
inefficient because the Z80 processor is not a good match for the language. It
does not have enough general purpose registers and its instruction set lacks
certain stack-relative addressing modes which are crucial to generating
efficient code using the C ABI.

In addition, the TI-83 Plus SDK is written in Z80 assembly language. All of the
TI-OS system calls assume that the calling code is written in assembly language.
Almost all third party documentation available on the internet is written in Z80
assembly language. Documentation for how to write a C program for the 83+/84+
calculators is almost non-existent (I think I came across a single forum post
about it.) Writing RPN83P in assembly seemed like the most reasonable choice.

**Why RPN?**

The first calculators that I used starting in middle school were algebraic
calculators. Once I got my first HP calculator (the HP-42S) in grad school,
there was no going back. RPN is the fastest and easiest way to do certain types
of calculation on a hand-held device.

There are currently almost no manufacturers of RPN calculators anymore.
Hewlett-Packard is no longer in the business of making calculators. It sold off
its calculator division to a company named Moravia in Europe. Moravia continues
to make the HP-12C, the HP Prime, and a few other generic calculators using its
HP license. Moravia reissued the HP-15C Collector's Edition a year ago, but that
may be only a limited run production.

The used market for old HP calculators can seem out of control. The HP-42S in
good working condition becomes more rare with each passing year, and now sells
for $200-$400 on eBay. The HP-35s model is even worse, going for $300-$600.

The SwissMicros company designs and sells a handful of RPN calculators based on
a number of classic HP calculators (e.g. HP-12C, HP-15C, HP-41C, HP-42S,
HP-32SII). They range from $150-$300 in price. The reviews of the SwissMicros
calculators are generally excellent and these are probably the best RPN
calculators that you can buy right now, if money is no object.

At the other end of the spectrum, there are no affordable, entry-level,
scientific RPN calculators made in the world today. This means that students on
limited budget are unlikely to be exposed to an RPN calculator. Without an
influx of new RPN users, RPN calculators will slowly disappear as the previous
generation of RPN users slowly drifts into old age.

RPN83P hopes to be the easiest and cheapest gateway into the world of RPN
calculators for the next generation of users.

**Why Not RPL?**

The easiest answer is that I do not know RPL. I have recently tried to learn RPL
using the (discontinued) HP-50g calculator, but I have not been successful so
far with my limited time. Even if I did learn RPL, I think it would be extremely
difficult to implement RPL on a TI-83+/84+ series using Z80 assembly language.
Assembly language is far less productive compared to a high level language like
C or C++. I also think that the number of potential users of RPL would be far
smaller than RPN, which makes me less motivated.

There are other projects trying to keep RPL alive:

- [newRPL](https://hpgcc3.org/projects/newrpl): reimplementation of HP 48/49/50
  series on the HP-50g (and related) hardware
- [DB48x](https://github.com/c3d/db48x): an RPL implementation on the
  SwissMicros DM42 and DM32 calculators

I don't think that it would be useful for me to duplicate those efforts.

**Why Are Some Features Included and Others Missing?**

Probably just a result of what features were interesting to me, what features
were easy to implement, and what features seemed too difficult or time consuming
to implement for now. See [FUTURE.md](FUTURE.md) for a list of features that
may be implemented in the future.

## Installation

See [USER_GUIDE_INSTALLATION.md](USER_GUIDE_INSTALLATION.md).

## Basic Usage

See [USER_GUIDE_BASIC_USAGE.md](USER_GUIDE_BASIC_USAGE.md).

## Catalog of Functions

All direct and menu functions supported by RPN83P are listed for reference in
[USER_GUIDE_FUNCTIONS.md](USER_GUIDE_FUNCTIONS.md).

## Advanced Topics

Each module below is a collection of functions and features that are related in
some consistent way. The modules can interact with other parts of the RPN83P
application through the RPN stack or storage registers. But for the most part,
they are self-contained. Each module is large enough that its documentation was
extracted into a separate document for ease of maintenance.

### MODE Functions

See [USER_GUIDE_MODE.md](USER_GUIDE_MODE.md).

### Storage Registers and Variables

See [USER_GUIDE_STORAGE.md](USER_GUIDE_STORAGE.md).

### NUM Functions

The `NUM` numerical functions are described in
[USER_GUIDE_NUM.md](USER_GUIDE_NUM.md).

### BASE Functions

The `BASE` functions allow numbers to be converted between 4 different bases
(DEC, HEX, OCT, and BIN) and support various arithmetic and bitwise operations
similar to the HP-16C.

See [USER_GUIDE_BASE.md](USER_GUIDE_BASE.md) for full details.

### STAT Functions

The RPN83P implements *all* 1 and 2 variable statistical and curve fitting
functionality of the HP-42S, as described in Ch. 15 of the _HP-42S User's
Manual_.

See [USER_GUIDE_STAT.md](USER_GUIDE_STAT.md) for full details.

### TVM Functions

The Time Value of Money (TVM) functionality is inspired by RPN financial
calculators such as the HP-12C, HP-17B, and the HP-30b. They are available
through the `ROOT > TVM` menu.

See [USER_GUIDE_TVM.md](USER_GUIDE_TVM.md) for full details.

### Complex Numbers

The RPN83P has extensive support for complex numbers. They can be entered in
rectangular form `a+bi`, polar radian form `r e^(i theta)`, or polar degree form
(`theta` in degrees). They can be also be displayed in all three forms. The
entry modes and the display modes are independent of each other. Most math
functions are able to operate on complex numbers.

See [USER_GUIDE_COMPLEX.md](USER_GUIDE_COMPLEX.md) for full details.

### UNIT Functions

The RPN83P provides unit conversions among 169 units across 12 unit types.

See [USER_GUIDE_UNIT.md](USER_GUIDE_UNIT.md) for full details.

### DATE Functions

The functions under the `DATE` menu allow arithmetic and conversion operations
on various objects (Date, Time, DateTime, TimeZone, ZonedDateTime, DayOfWeek,
Duration) that represent the Gregorian Calendar dates and UTC times. Timezones
are implemented as fixed offsets from UTC, and datetimes can be converted into
different timezones easily. In addition, the DATE functions can access the
hardware real-time clock (RTC) incorporated into some calculators (TI-84+,
TI-84+SE, TI-Nspire).

See [USER_GUIDE_DATE.md](USER_GUIDE_DATE.md) for full details.

## TI-OS Interaction

See [USER_GUIDE_TIOS.md](USER_GUIDE_TIOS.md).

## Troubleshooting

See [USER_GUIDE_TROUBLESHOOTING.md](USER_GUIDE_TROUBLESHOOTING.md).

## Future Enhancements

Moved to [FUTURE.md](FUTURE.md).
