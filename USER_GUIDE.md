# RPN83P User Guide

RPN calculator app for the TI-83 Plus and TI-84 Plus inspired by the HP-42S.

**Version**: 0.6.0-dev (2023-09-13)

**Project Home**: https://github.com/bxparks/rpn83p

## Table of Contents

- [Introduction](#introduction)
- [Why?](#why)
    - [Short Answer](#short-answer)
    - [Long Answer](#long-answer)
- [Installation](#installation)
    - [Obtaining the Program File](#obtaining-the-program-file)
    - [Uploading](#uploading)
    - [Starting](#starting)
    - [Quitting](#quitting)
- [Basic Usage](#basic-usage)
    - [Screen Areas](#screen-areas)
    - [Input and Editing](#input-and-editing)
    - [RPN Stack](#rpn-stack)
    - [Menu System](#menu-system)
        - [Menu Hierarchy](#menu-hierarchy)
        - [Menu Buttons](#menu-buttons)
        - [Menu Indicator Arrows](#menu-indicator-arrows)
        - [Menu Shortcuts](#menu-shortcuts)
    - [Built In Help](#built-in-help)
    - [Error Codes](#error-codes)
- [Functions](#functions)
    - [Direct Functions](#direct-functions)
    - [Menu Functions](#menu-functions)
- [Advanced Usage](#advanced-usage)
    - [Auto-start](#auto-start)
    - [Floating Point Display Modes](#floating-point-display-modes)
    - [Trigonometric Modes](#trig-modes)
    - [BASE Functions](#base-functions)
        - [Base Modes](#base-modes)
        - [Shift and Rotate](#shift-and-rotate)
        - [Base Arithmetic](#base-arithmetic)
        - [Carry Flag](#carry-flag)
        - [Bit Operations](#bit-operations)
        - [Base Integer Size](#base-integer-size)
        - [Base Mode Retention](#base-mode-retention)
    - [Storage Registers](#storage-registers)
    - [Prime Factors](#prime-factors)
    - [STAT Functions](#stat-functions)
- [TI-OS Interaction](#ti-os-interaction)
- [Future Enhancements](#future-enhancements)
    - [Near Future](#near-future)
    - [Medium Future](#medium-future)
    - [Far Future](#far-future)
    - [Not Planned](#not-planned)

## Introduction

RPN83P is an [RPN](https://en.wikipedia.org/wiki/Reverse_Polish_notation)
calculator app for the [TI-83 Plus](https://en.wikipedia.org/wiki/TI-83_series)
(including the Silver Edition) and the [TI-84
Plus](https://en.wikipedia.org/wiki/TI-84_Plus_series) (including the Silver
Edition). The app is inspired mostly by the
[HP-42S](https://en.wikipedia.org/wiki/HP-42S) calculator, with some sprinkles
of some older HP calculators like the
[HP-12C](https://en.wikipedia.org/wiki/HP-12C) and the
[HP-15C](https://en.wikipedia.org/wiki/HP-15C).

The RPN83P is a flash application that consumes one page (16 kB) of flash
memory. Since it is stored in flash, it is preserved if the RAM is cleared. It
consumes a small amount of TI-OS RAM: 2 list variables named `REGS` (240 bytes)
and `STK` (59 byte), and an appVar named `RPN83SAV` (76 bytes).

Here the quick summary of its features:

- traditional 4-level RPN stack (`X`, `Y`, `Z`, `T` registers)
- support for `lastX` register
- 8-line display showing all stack registers
- 25 storage registers (`STO 00`, `RCL 00`, ..., `STO 24`, `RCL 24`)
- hierarchical menu system, inspired by the HP-42S
- support for all math functions with dedicated buttons on the TI-83 Plus and
  TI-84 Plus
    - arithmetic: `/`, `*`, `-`, `+`
    - trigonometric: `SIN`, `COS`, `TAN`, etc.
    - `1/X`, `X^2`, `SQRT`
    - `^` (i.e. `Y^X`),
    - `LOG`, `10^X`, `LN`, `e^X`
    - constants: `pi` and `e`
- additional menu functions:
    - `X^3`, `CBRT`, `XRootY`, `ATN2`, `2^X`, `LOG2`, `LOGB`
    - `%`, `%CH`, `GCD`, `LCM`, `PRIM` (is prime)
    - `IP` (integer part), `FP` (fractional part), `FLR` (floor), `CEIL`
      (ceiling), `NEAR` (nearest integer)
    - `ABS`, `SIGN`, `MOD`, `MIN`, `MAX`
    - probability: `PERM`, `COMB`, `N!`, `RAND`, `SEED`
    - hyperbolic: `SINH`, `COSH`, `TANH`, etc.
    - angle conversions: `>DEG`, `>RAD`, `>HR`, `>HMS`, `>REC`, `>POL`
    - unit conversions: `>C`, `>F`, `>km`, `>mi`, etc
    - base conversions: `DEC`, `HEX`, `OCT`, `BIN`
    - bitwise operations: `AND`, `OR`, `XOR`, `NOT`, `NEG`, `B+`, `B-`, `B*`,
      `B/`, `BDIV`, REVB (reverse bits), CNTB (count bits)
    - shift and rotate operations: `SL`, `SR`, `ASR`, `RL`, `RR`, `RLC`, `RRC`,
      `SLn`, `SRn`, `RLn`, `RRn`, `RLCn`, `RRCn`
    - carry flags and bit masks: `CCF`, `SCF`, `CF?`, `CB`, `SB`, `B?`
    - statistics: `Sigma+`, `Sigma-`, `SUM`, `MEAN`, `WMN` (weighted mean),
      `SDEV` (sample standard deviation), `SCOV` (sample covariance),
      `PDEV` (population standard deviation), `PCOV` (population covariance)
    - curve fitting: `Y>X`, `X>Y`, `SLOP` (slope), `YINT` (y intercept), `CORR`
      (correlation coefficent)
    - curve fit models: `LINF` (linear), `LOGF` (logarithmic), `EXPF`
      (exponential), `PWRF` (power)
- various display modes
    - `RAD`, `DEG`
    - `FIX` (fixed point 0-9 digits)
    - `SCI` (scientific 0-9 digits)
    - `ENG` (engineering 0-9 digits)

Here are some missing features which may be added in the future:

- vectors and matrices
- complex numbers
- keystroke programming

## Why?

### Short Answer

This was a fun project that helped me learn Z80 assembly language programming on
TI calculators. It also produced an app that converts a TI calculator into an
RPN calculator that I can actually use.

### Long Answer

When I was in grad school, I used the HP-42S extensively. After graduating, I
sold the calculator, which I have regretted later. The old HP-42S calculators
now sell for $200-$300 on eBay, which is a sum of money that I cannot justify
spending.

I finished my formal school education before graphing calculators became
popular, so I didn't know anything about them until a few months ago. I did not
know that the early TI graphing calculators used the Z80 processor, and more
importantly, I did not know that they were programmable in assembly language.

I realized that I could probably create an app that could turn them into
passable, maybe even useful, RPN calculators. The debate over RPN mode versus
algebraic mode has probably been going on for 40-50 years, so I probably cannot
add more. Personally, I use algebraic notation for doing math equations on paper
or writing high-level computer programs. But when I do numerical *computation*
on a hand-held device, I am most comfortable using the RPN mode.

The RPN83P app is inspired by the HP-42S. It is the RPN calculator that I know
best. It also has the advantage of having the
[Free42](https://thomasokken.com/free42/) app (Android, iOS, Windows, MacOS,
Linux) which faithfully reproduces every feature of the HP-42S. This is
essential because I don't own an actual HP-42S anymore to verify obscure edge
cases which may not be documented.

The RPN83P app cannot be a clone of the HP-42S for several reasons:

- The keyboard layout and labels of the TI-83 and TI-84 calculators are
  different. As an obvious example, the TI calculators have 5 menu buttons below
  the LCD screen, but the HP-42S has 6 menu buttons.
- The RPN83P does not implement its own floating point routines, but uses the
  ones provided by the underlying TI-OS. There are essential differences between
  the two systems. For example, the HP-42S supports exponents up to +/-499, but
  the TI-OS supports exponents only to +/-99.

Although the HP-42S may be close to ["peak of perfection for the classic HP
calcs"](https://www.hpmuseum.org/cgi-sys/cgiwrap/hpmuseum/archv017.cgi?read=118462),
I think there are features of the HP-42S that could be improved. For example,
the HP-42S has a 2-line LCD display which is better than the single-line display
of earlier HP calculators. But the TI-83 and TI-84 LCD screens are big enough to
show the entire RPN stack as well as the hierarchical menu bar at all times, so
it makes sense to take advantage of the larger LCD screen size.

The purpose of the RPN83P project was to help me learn Z80 programming on a TI
calculator, and to convert an old TI calculator into an RPN calculator that I
can actually use. I hope other people find it useful.

## Installation

### Obtaining the Program File

The RPN83P app is packaged as a single file named `rpn83p.8xk`. There are at
least 2 ways to obtain this:

- [RPN83P release page on GitHub](https://github.com/bxparks/rpn83p/releases)
    - go to the latest release
    - click and download the `rpn83p.8xk` file
- Compile the binary locally
    - See [Compiling from Source](#Compiling) section below

### Uploading

The `rpn83p.8xk` file must be uploaded to the calculator using a "link" program
from a host computer. There are a number of options:

- **Linux**: Use the [tilp](https://github.com/debrouxl/tilp_and_gfm) program.
  On Ubuntu Linux 22.04 systems, the precompiled package can be installed using
  `$ apt install tilp2`. (I'm not actually sure if the `tilp2` binary is
  actually compiled from the `tilp_and_gfm` source code mentioned above)

- **Windows** or **MacOS**: Use the [TI
  Connect](https://education.ti.com/en/products/computer-software/ti-connect-sw)
  software and follow the instructions in [Transferring FLASH
  Applications](https://education.ti.com/en/customer-support/knowledge-base/sofware-apps/product-usage/11506).

### Starting

After installing `rpn83p.8xk` file, go to the calculator:

- Press the `APPS` key
- Scroll down to the `RPN83P` entry
- Press the `ENTER` key

> ![TIOS APPS](docs/tios-apps.png)

The RPN83P starts directly into the calculator mode, no fancy splash screen. You
should see a screen that looks like:

> ![RPN83P screenshot 1](docs/rpn83p-screenshot-initial.png)

### Quitting

The RPN83P application can be quit using:

- `2ND` `QUIT`: to exit to normal TI calculator
- `2ND` `OFF`: to turn the calculator off (the RPN registers and storage
  registers will be preserved)

Upon exit, the state of the RPN83P app will be saved in an AppVar named
`RPN83SAV`. When the app is restarted, the calculator will resume from exactly
where it left off, including the exact cursor position of any pending input.
When restarted, if the `RPN83SAV` variable does not pass validation (e.g. does
not exist; was archived; is wrong size; contains an incompatible schema version;
does not pass a CRC checksum) then the application starts from a clean slate.

## Basic Usage

This guide assumes that you already know to use an RPN calculator. In
particular, the RPN83P implements the traditional RPN system used by
Hewlett-Packard calculators such as the HP-12C, HP-15C, and the HP-42S. (The
RPN83P does not use the newer RPN system used by the HP-48SX.)

It is beyond the scope of this document to explain how to use an RPN calculator.
One way to learn is to download the [Free42](https://thomasokken.com/free42/)
emulator for the HP-42S (available for Android, iOS, Windows, MacOS, and Linux)
and then download the [HP-42S Owner's
Manual](https://literature.hpcalc.org/items/929).

### Screen Areas

Here are the various UI elements on the LCD screen used by the RPN83P app:

> ![RPN83P screen areas](docs/rpn83p-screen-areas-annotated.png)

The LCD screen is 96 pixels (width) by 64 pixels (height). That is large enough
to display 8 rows of numbers and letters. They are divided into the following:

- 1: status line
- 2: (currently unused)
- 3: error code line
- 4: T register line
- 5: Z register line
- 6: Y register line
- 7: X register/input line
- 8: menu line

The X register line is also used as the input line when entering new numbers. It
is also used to prompt for command line argument, for example `FIX _ _` to set
the fixed display mode.)

### Input and Editing

The following buttons are used to enter and edit a number in the input buffer:

![Input and Edit Buttons](docs/rpn83p-fullshot-inputedit-buttons.jpg)

- `0`-`9`: digits
- `.`: decimal point
- `(-)`: enters a negative sign, or changes the sign (same as `+/-` or `CHS` on
  HP calculators)
- `DEL`: Backspace (same as `<-` on many HP calculators)
- `CLEAR`: Clear `X` register (same as `CLx` or `CLX` on HP calculators)
- `2ND` `EE`: adds an `E` to allow entry of scientific notation exponent (same
  as `E` or `EEX` on HP calculators)
- `,`: same as `2ND` `EE`, allowing the `2ND` to be omitted for convenience

The `(-)` button acts like the `+/-` or `CHS` button on HP calculators. It
toggles the negative sign, adding it if it does not exist, and removing it if it
does.

The `DEL` key acts like the *backspace* key on HP calculators (usually marked
with a `LEFTARROW` symbol. This is different from the TI-OS where the `DEL` key
removes the character under the cursor. In RPN83P, the cursor is *always* at the
end of the input buffer, so `DEL` is programmed to delete the right-most digit.
If the `X` line is *not* in edit mode (i.e. the cursor is not shown), then the
`DEL` key acts like the `CLEAR` key (see below).

The `CLEAR` key clears the entire input buffer, leaving just a cursor at the end
of an empty string. An empty string will be interpreted as a `0` if the `ENTER`
key or a function key is pressed.

The comma `,` button is not used in the RPN system, so it has been mapped to
behave exactly like the `2ND` `EE` button. This allows scientific notation
numbers to be entered quickly without having to press the `2ND` button
repeatedly.

Emulating the input system of the HP-42S was surprisingly complex and subtle,
and some features and idiosyncrasies of the HP-42S could not be carried over due
to incompatibilities with the underlying TI-OS. I'm not sure that documenting
all the corner cases would be useful because it would probably be tedious to
read. I hope that the input system is intuitive and self-consistent enough that
you can just play around with it and learn how it works.

### RPN Stack

The RPN83P tries to implement the traditional 4-level stack used by many HP
calculators as closely as possible, including some features which some people
may find idiosyncratic. There are 4 slots in the RPN stack named `X`, `Y`, `Z`,
and `T`. The LCD screen on the TI calculators is big enough that all 4 RPN
registers can be shown at all times. (For comparison, the HP-12C and HP-15C have
only a single line display. The HP-42S has a 2-line display, with the bottom
line often commandeered by the menu line so that only the `X` register is
shown.)

These are the buttons which manipulate the RPN stack:

![Input and Edit Buttons](docs/rpn83p-fullshot-rpn-buttons.jpg)

- `(`: rotates RPN stack down (known as `R(downarrow)` on HP calculators)
- `)`: exchanges `X` and `Y` registers
- `ENTER`: saves the input buffer to the `X` register
- `2ND` `ANS`: recalls the last `X`

This mapping of the `(` and `)` to these stack functions is identical to the
mapping used by the [HP-30b](https://en.wikipedia.org/wiki/HP_30b) when it is in
RPN mode. (The HP-30b supports both algebraic and RPN entry modes.)

When a new number is entered (using the `0`-`9` digit keys), the press of the
first digit causes the stack to **lift**, and the calculator enters into the
**edit** mode. This mode is indicated by the appearance of an underscore `_`
cursor.

A stack **lift** causes the previous `X` value to shift into the `Y` register,
the previous `Y` value into the `Z` register, and the previous `Z` value into
the `T` register. The previous `T` value is lost.

The `ENTER` key performs the following actions:

- if the `X` register was in edit mode, the input buffer is closed and the
  number is placed into the `X` register,
- the `X` register is then duplicated into the `Y` register,
- the stack lift is *disabled* for the next number.

This is consistent with the traditional RPN system used by HP calculators up to
and including the HP-42S. It allows the user to press: `2` `ENTER` `3` `*` to
multiply `2*3` and get `6` as the result, because the second number `3` does not
lift the stack.

The parenthesis `(` and `)` buttons are not used in an RPN entry system, so they
have been repurposed for stack manipulation:

- `(` key rotates the stack *down*, exactly as the same as the `R(downarrow)` or
  just a single `(downarrow)` on the HP calculators.
- `)` key performs an exchange of the `X` and `Y` registers. That functionality
  is usually marked as `X<>Y` on HP calculators.

The `2ND` `ANS` functionality of the TI-OS algebraic mode is unnecessary in the
RPN system because the `X` register is always the most recent result that would
have been stored in `2ND` `ANS`. Therefore, the `2ND` `ANS` has been repurposed
to be the `LastX` functionality of HP calculators. The `LastX` is the value of
the `X` register just before the most recent operation. It can be used to bring
back a number that was accidentally consumed, or it can be used as part of a
longer sequence of calculations.

### Menu System

#### Menu Hierarchy

The menu system of the RPN83P was directly inspired by the HP-42S calculator.
There are over 150 functions supported by the RPN83P menu system, so it is
convenient to arrange them into a nested folder structure. There are 5 buttons
directly under the LCD screen so it makes sense to present the menu items as
sets of 5 items corresponding to those buttons.

The menu system forms a singly-rooted tree of menu items and groups, which look
like this conceptually:

![Menu Structure](docs/menu-structure.png)

There are 4 components:

- `MenuGroup`: a folder of 1 or more `MenuRows`
- `MenuRow`: a list of exactly 5 `MenuNodes` corresponding to the 5 menu
  buttons below the LCD
- `MenuNode`: one slot in the `MenuRow`, can be *either* a `MenuGroup` or a
  `MenuItem`
- `MenuItem`: a leaf-node that maps directly to a function (e.g. `ASNH`) when
  the corresponding menu button is pressed

#### Menu Buttons

The LCD screen always shows a `MenuRow` of 5 `MenuItems`. Here are the buttons
which are used to navigate the menu hierarchy:

![Menu Buttons](docs/rpn83p-fullshot-menu-buttons.jpg)

- `F1`- `F5`: invokes the function shown by the respective menu
- `UP_ARROW`: goes to previous `MenuRow` of 5 `MenuItems`, within the current
  `MenuGroup`
- `DOWN_ARROW`: goes to next `MenuRow` of 5 `MenuItems`, within the current
  `MenuGroup`
- `ON`: goes back to the parent `MenuGroup` (similar to the `ON/EXIT` button on
  the HP-42S)
- `MATH`: goes directly to the root `MenuGroup` no matter where you are in the
  menu hierarchy

The appropriate key for the "menu back to parent" function would have been an
`ESC` button. But the TI-83 and TI-84 calculators do not have an `ESC` button
(unlike the TI-92 and TI Voyager 200 series calculators), so the `ON` button was
recruited for this functionality. This seemed to make sense because the HP-42S
uses the `ON` key which doubles as the `EXIT` key to perform this function.

The `HOME` button is useful to go directly to the top of the menu hierarchy from
anywhere in the menu hierarchy. The TI-83 and TI-84 calculators do not have a
`HOME` button (unlike the TI-92 and TI Voyager 200 series again), so the `MATH`
button was taken over to act as the `HOME` key. This choice was not completely
random:

1. The `HOME` button on the [TI-89 series
calculator](https://en.wikipedia.org/wiki/TI-89_series) is located exactly where
the `MATH` is.
2. The RPN83P app does not need the `MATH` button as implemented by the TI-OS,
which opens a dialog box of mathematical functions. In the RPN83P app, that
functionality is already provided by the menu system.
3. When the menu system is at the root, the first menu item on the left is a
menu group named `MATH`, which may help to remember this button mapping.

#### Menu Indicator Arrows

There are 3 menu arrows at the top-left corner of the LCD screen. The
`downarrow` indicates that additional menu rows are available:

> ![Menu Arrows 1](docs/rpn83p-screenshot-menu-arrows-1.png)

When the `DOWN` button is pressed, the menu changes to the next set of 5 menu
items in the next menu row, and the menu arrows show both an `uparrow` and a
`downarrow` to indicate that there are more menu items above and below the
current menu bar:

> ![Menu Arrows 2](docs/rpn83p-screenshot-menu-arrows-2.png)

Pressing `DOWN` goes to the last set of 5 menu items, and the menu arrows show
only the `uparrow` to indicate that this is the last of the series:

> ![Menu Arrows 3](docs/rpn83p-screenshot-menu-arrows-3.png)

You can press `UP` twice goes back to the first menu row, or you can press
`DOWN` from the last menu row to wrap around to the beginning:

> ![Menu Arrows 1](docs/rpn83p-screenshot-menu-arrows-1.png)

Pressing the `F2/WINDOW` button from here invokes the `NUM` menu item. This menu
item is actually a `MenuGroup`, so the menu system descends into this folder,
and displays the 5 menu items in the first menu row:

> ![Menu Arrows NUM 1](docs/rpn83p-screenshot-menu-arrows-num-1.png)

Pressing the `DOWN` arrow button shows the next menu row:

> ![Menu Arrows NUM 2](docs/rpn83p-screenshot-menu-arrows-num-2.png)

Pressing the `DOWN` arrow button goes to the final menu row:

> ![Menu Arrows NUM 3](docs/rpn83p-screenshot-menu-arrows-num-3.png)

Notice that inside the `NUM` menu group, the menu arrows show a `back` arrow.
This means that the `ON` button (which implements the "BACK", "EXIT", or "ESC"
functionality) can be used to go back to the parent menu group:

> ![Menu Arrows 1](docs/rpn83p-screenshot-menu-arrows-1.png)

#### Menu Shortcuts

Some menu groups can be accessed quickly through dedicated keys on the TI
calculator which happen to have the same label as the menu item:

- `MODE`: bound to `ROOT > MODE`
- `STAT`: bound to `ROOT > STAT`
- `MATH`: repurposed to be `HOME` (aka `ROOT`)

The `MATH` button is slightly different. It is not bound to `ROOT > MATH`.
Rather it has been repurposed to be the `HOME` button which goes to the top of
the menu hierarchy `ROOT`.

## Built In Help

Pressing the `HELP` menu button at the root menu:

> ![ROOT MenuRow 1](docs/rpn83p-screenshot-menu-root-1.png)

activates the Help pages:

> ![Help Page 1](docs/rpn83p-help-page-1.png)

> ![Help Page 2](docs/rpn83p-help-page-2.png)

> ![Help Page 3](docs/rpn83p-help-page-3.png)

> ![Help Page 4](docs/rpn83p-help-page-4.png)

> ![Help Page 5](docs/rpn83p-help-page-5.png)

Hopefully they are useful for remembering the mapping of the buttons whose TI-OS
keyboard labels do not match the functionality assigned by the RPN83P program.

## Error Codes

The RPN83P supports all error messages from the underlying TI-OS which are
documented in the TI-83 SDK:

- `Err: Argument`
- `Err: Bad Guess`
- `Err: Break`
- `Err: Domain` (`*`)
- `Err: Data Type`
- `Err: Invalid Dim` (`*`)
- `Err: Dim Mismatch`
- `Err: Divide By 0` (`*`)
- `Err: Increment`
- `Err: Invalid`
- `Err: Iterations`
- `Err: In Xmit`
- `Err: Memory`
- `Err: Non Real`
- `Err: Overflow` (`*`)
- `Err: No Sign Change`
- `Err: Singularity`
- `Err: Stat`
- `Err: StatPlot`
- `Err: Syntax`
- `Err: Tol Not Met`
- `Err: Undefined`

These are shown in the Error Code line on the screen. For example, division by 0
shows this:

> ![Err: Division By 0](docs/rpn83p-errorcode-division-by-0.png)

The TI SDK documentation does not explain the source of most of these error
codes, and I can reproduce only a small number of errors in the RPN83P app,
marked by (`*`) above.

If an unknown error code is detected the RPN83P will print `Err: UNKNOWN (##)`
message like this:

> ![Err: UNKNOWN](docs/rpn83p-errorcode-unknown.png)

The number in parenthesis is the internal numerical value of the error code. If
the error is reproducible, please file a bug report containing the numerical
error code so that I can add it to the list of error messages supported by
RPN83P.

## Functions

This section contains a description of all functions implemented by the RPN83P
app, accessed through buttons or through the menu system.

### Direct Functions

Most of the mathematical functions that are exposed through physical buttons
are supported by the RPN83P app.

- arithmetic
    - `/`, `*`, `-`, `+`
- trigonometric
    - `SIN`, `COS`, `TAN`
    - `2ND` `SIN^-1`, `2ND` `COS^-1`, `2ND` `TAN^-1`
- algebraic
    - `X^-1`, `X^2`, `sqrt`, `^` (i.e. `Y^X`)
- transcendental
    - `LOG`, `10^X`, `LN`, `e^X`
- constants
    - `pi`, `e`

### Menu Functions

These functions are accessed through the hierarchical menu, using the 5 menu
buttons just under the LCD screen. Use the `UP`, `DOWN`, `ON` (back), and `MATH`
(home) keys to navigate the menu hierarchy.

- `ROOT` (implicit)
    - ![ROOT MenuRow 1](docs/rpn83p-screenshot-menu-root-1.png)
    - ![ROOT MenuRow 2](docs/rpn83p-screenshot-menu-root-2.png)
    - ![ROOT MenuRow 3](docs/rpn83p-screenshot-menu-root-3.png)
- `ROOT` > `MATH`
    - ![MATH MenuRow 1](docs/rpn83p-screenshot-menu-root-math-1.png)
    - ![MATH MenuRow 2](docs/rpn83p-screenshot-menu-root-math-2.png)
    - `X^3`: cube of `X`
    - `3 Root X`: cube root of `X`
    - `X Root Y`: `X` root of `Y`
    - `ATN2`: `atan2(Y, X)` in degrees or radians, depending on current mode
        - `Y` register is the x-component entered first
        - `X` register is the y-component entered second
    - `2^X`: `2` to the power of `X`
    - `LOG2`: log base 2 of `X`
    - `LOGB`: log base `X` of `Y`
- `ROOT` > `NUM`
    - ![NUM MenuRow 1](docs/rpn83p-screenshot-menu-root-num-1.png)
    - ![NUM MenuRow 2](docs/rpn83p-screenshot-menu-root-num-2.png)
    - ![NUM MenuRow 3](docs/rpn83p-screenshot-menu-root-num-3.png)
    - `%`: `X` percent of `Y`, leaving `Y` unchanged
    - `%CH`: percent change from `Y` to `X`, leaving `Y` unchanged
    - `GCD`: greatest common divisor of `X` and `Y`
    - `LCM`: lowest common multiple of `X` and `Y`
    - `PRIM`: determine if `X` is a prime
        - returns 1 if prime
        - returns the smallest prime factor otherwise
        - See [Prime Factors](#prime-factors) section below.
    - `IP`: integer part of `X`, truncating towards 0, preserving sign
    - `FP`: fractional part of `X`, preserving sign
    - `FLR`: the floor of `X`, the largest integer <= `X`
    - `CEIL`: the ceiling of `X`, the smallest integer >= `X`
    - `NEAR`: the nearest integer to `X`
    - `ABS`: absolute value of `X`
    - `SIGN`: return -1, 0, 1 depending on whether `X` is less than, equal, or
      greater than 0, respectively
    - `MOD`: `Y` mod `X` (remainder of `Y` after dividing by `X`)
    - `MIN`: minimum of `X` and `Y`
    - `MAX`: maximum of `X` and `Y`
- `ROOT` > `PROB`
    - ![PROB MenuRow 1](docs/rpn83p-screenshot-menu-root-prob-1.png)
    - `COMB`: combination `C(n,r)` = `C(Y, X)`
    - `PERM`: permutation `P(n,r)` = `P(Y, X)`
    - `N!`: factorial of `X`
    - `RAND`: random number in the range `[0,1)`
    - `SEED`: set the random number generator seed to `X`
- `ROOT` > `CONV`
    - ![CONV MenuRow 1](docs/rpn83p-screenshot-menu-root-conv-1.png)
    - ![CONV MenuRow 2](docs/rpn83p-screenshot-menu-root-conv-2.png)
    - `>DEG`: convert radians to degrees
    - `>RAD`: convert degrees to radians
    - `>REC`: polar to rectangular
        - input (`Y`, `X`) = `r`, `theta`
        - output (`Y`, `X`) = `x`, `y`
    - `>POL`: rectangular to polar
        - input (`Y`, `X`) = (`x`, `y`)
        - output (`Y`, `X`) = (`r`, `theta`)
    - `>HR`: convert `HH.MMSSssss` to `HH.hhhh`
    - `>HMS`: convert `HH.hhhh` to `HH.MMSSssss`
- `ROOT` > `HELP`: display the help pages
    - use arrow keys to view each help page
- `ROOT` > `BASE`
    - ![BASE MenuRow 1](docs/rpn83p-screenshot-menu-root-base-1.png)
    - ![BASE MenuRow 2](docs/rpn83p-screenshot-menu-root-base-2.png)
    - ![BASE MenuRow 3](docs/rpn83p-screenshot-menu-root-base-3.png)
    - ![BASE MenuRow 4](docs/rpn83p-screenshot-menu-root-base-4.png)
    - ![BASE MenuRow 5](docs/rpn83p-screenshot-menu-root-base-5.png)
    - ![BASE MenuRow 6](docs/rpn83p-screenshot-menu-root-base-6.png)
    - ![BASE MenuRow 7](docs/rpn83p-screenshot-menu-root-base-7.png)
    - ![BASE MenuRow 8](docs/rpn83p-screenshot-menu-root-base-8.png)
    - `DEC`: use decimal base 10
    - `HEX`: use hexadecimal base 16
        - display all register values as 32-bit unsigned integer
    - `OCT`: use octal base 8
        - display all register values as 32-bit unsigned integer
    - `BIN`: use binary base 2
        - display all register values as 32-bit unsigned integer
        - max of 13 digits
    - `AND`: `X` `bit-and` `Y`
    - `OR`: `X` `bit-or` `Y`
    - `XOR`: `X` `bit-xor` `Y`
    - `NOT`: one's complement of `X`
    - `NEG`: two's complement of `X`
    - `SL`: shift left logical one bit
    - `SR`: shift right logical one bit
    - `ASR`: arithmetic shift right one bit
    - `SLn`: shift left logical `Y` by `X` bits
    - `SRn`: shift right logical `Y` by `X` bits
    - `RL`: rotate left circular one bit
    - `RR`: rotate right circular one bit
    - `RLC`: rotate left through carry flag one bit
    - `RRC`: rotate right through carry flag one bit
    - `RLn`: rotate left circular `Y` by `X` bits
    - `RRn`: rotate right circular `Y` by `X` bits
    - `RLCn`: rotate left through carry flag `Y` by `X` bits
    - `RRCn`: rotate right through carry flag `Y` by `X` bits
    - `CB`: clear bit `X` of `Y`
    - `SB`: set bit `X` of `Y`
    - `B?`: get bit `X` of `Y` as 0 or 1
    - `REVB`: reverse bits of `X`
    - `CNTB`: count number of 1 bits of `X` (same as `#B` on HP-16C)
    - `B+`: add `X` and `Y` using unsigned 32-bit integer math
    - `B-`: subtract `X` from `Y` using unsigned 32-bit integer math
    - `B*`: multiply `X` and `Y` using unsigned 32-bit integer math
    - `B/`: divide `X` into `Y` using unsigned 32-bit integer math
    - `BDIV`: divide `X` into `Y` with remainder, placing the quotient in `Y`
      and the remainder in `X`
    - `CCF`: clear carry flag
    - `SCF`: set carry flag
    - `CF?`: return carry flag state as 0 or 1
    - `WSIZ`: set integer word size (not implemented)
    - `WSZ?`: return current integer word size (normally 32)
- `ROOT` > `HYP`
    - ![HYP MenuRow 1](docs/rpn83p-screenshot-menu-root-hyp-1.png)
    - ![HYP MenuRow 2](docs/rpn83p-screenshot-menu-root-hyp-2.png)
    - `SINH`: hyperbolic `sin()`
    - `COSH`: hyperbolic `cos()`
    - `TANH`: hyperbolic `tan()`
    - `ASNH`: hyperbolic `asin()`
    - `ACSH`: hyperbolic `acos()`
    - `ATNH`: hyperbolic `atan()`
- `ROOT` > `STAT`
    - See Chapter 15 of the _HP-42S User's Manual_
    - ![STAT MenuRow 1](docs/rpn83p-screenshot-menu-root-stat-1.png)
    - ![STAT MenuRow 2](docs/rpn83p-screenshot-menu-root-stat-2.png)
    - ![STAT MenuRow 3](docs/rpn83p-screenshot-menu-root-stat-3.png)
    - `Sigma+`: add `Y` and `X` data point to STAT registers
    - `Sigma-`: remove `Y` and `X` data point from STAT registers
    - `ALLSigma`: collect statistical sums for all curve fit models
    - `LINSigma`: collect statistical sums for the linear curve fit model
    - `CLSigma`: clear STAT registers `[R11,R16]` (if LINSigma selected) or
      `[R11,R23]` (if AllSigma selected)
    - `SUM`: return Sum of `Y` and Sum of `X` in the `Y` and `X` registers
    - `MEAN`: return average `<Y>` and `<X>` in the `Y` and `X` registers
    - `WMN`: return the weighted mean of `Y` and weighted mean of `X` in the `Y`
      and `X` registers
        - `weighted mean Y = Sum(XY)/Sum(X)`
        - `weighted mean X = Sum(XY)/Sum(Y)`
    - `N`: return the number of data items entered
    - `SDEV`: sample standard deviation of `Y` and `X`
        - `sdev(X) = sqrt(N/(N-1)) pdev(X)`
        - `sdev(Y) = sqrt(N/(N-1)) pdev(Y)`
    - `SCOV`: sample covariance
        - `scov(X,Y) = (N/(N-1)) pcov(X,Y)`
    - `PDEV`: population standard deviation of `Y` and `X`
        - `pdev(X) = <X^2> - <X>^2`
        - `pdev(Y) = <Y^2> - <Y>^2`
    - `PCOV`: population covariance
        - `pcov(X,Y) = <XY> - <X><Y>`
    - `ROOT` > `STAT` > `CFIT`
        - See Chapter 15 of the _HP-42S User's Manual_
        - ![CFIT MenuRow 1](docs/rpn83p-screenshot-menu-root-stat-cfit-1.png)
        - ![CFIT MenuRow 2](docs/rpn83p-screenshot-menu-root-stat-cfit-2.png)
        - `Y>X`: forecast X from Y
        - `X>Y`: forecast Y from X
        - `SLOP`: slope of curve fit model, i.e. `m` parameter
        - `YINT`: y-intercept of curve fit model, i.e. `b` parameter
        - `CORR`: correlation coefficient of the least square curve fit
        - `LINF`: linear fit model, `y = mx + b`
        - `LOGF`: logarithmic fit model, `y = m ln(x) + b`
        - `EXPF`: exponential fit model, `y = b e^(mx)`
        - `PWRF`: power fit model, `y = b x^m`
        - `BEST`: automatically select the best model, i.e. the one with the
          largest absolute value of the correlation coefficient. The `CORR`
          value is returned in the `X` register for reference.
- `ROOT` > `UNIT`
    - ![UNIT MenuRow 1](docs/rpn83p-screenshot-menu-root-unit-1.png)
    - ![UNIT MenuRow 2](docs/rpn83p-screenshot-menu-root-unit-2.png)
    - ![UNIT MenuRow 3](docs/rpn83p-screenshot-menu-root-unit-3.png)
    - ![UNIT MenuRow 4](docs/rpn83p-screenshot-menu-root-unit-4.png)
    - ![UNIT MenuRow 5](docs/rpn83p-screenshot-menu-root-unit-5.png)
    - ![UNIT MenuRow 6](docs/rpn83p-screenshot-menu-root-unit-6.png)
    - `>C`: Fahrenheit to Celsius
    - `>F`: Celsius to Fahrenheit
    - `>hPa`: hectopascals (i.e. millibars) to inches of mercury (Hg)
    - `>iHg`: inches of mercury (Hg) to hectopascals (i.e. millibars)
    - `>km`: miles to kilometers
    - `>mi`: kilometers to miles
    - `>m`: feet to meters
    - `>ft`: meters to feet
    - `>cm`: inches to centimeters
    - `>in`: centimeters to inches
    - `>um`: mils (1/1000 of inch) to micrometers
    - `>mil`: micrometers to mils (1/1000 of inch)
    - `>kg`: pounds to kilograms
    - `>lbs`: kilograms to pounds
    - `>g`: ounces to grams
    - `>oz`: grams to ounces
    - `>L`: US gallons to liters
    - `>gal`: liters to US gallons
    - `>mL`: fluid ounces to milliliters
    - `>foz`: milliliters to fluid ounces
    - `>kJ`: kilo calories to kilo Joules
    - `>cal`: kilo Joules to kilo calories
    - `>kW`: horsepowers (mechanical) to kilo Watts
    - `>hp`: kilo Watts to horsepowers (mechanical)
- `ROOT` > `CLR`
    - ![CLR MenuRow 1](docs/rpn83p-screenshot-menu-root-clr-1.png)
    - `CLX`: clear `X` stack register (stack lift disabled)
    - `CLST`: clear all RPN stack registers
    - `CLRG`: clear all storage registers `R00` to `R24`
    - `CLSigma`: clear STAT storage registers [`R11`, `R16`] or [`R11`, `R23`]
- `ROOT` > `MODE`
    - ![MODE MenuRow 1](docs/rpn83p-screenshot-menu-root-mode-1.png)
    - `FIX`: fixed mode with `N` digits after the decimal point
        - set `N` to `99` for floating number of digits
        - status line indicator is `FIX(N)`
    - `SCI`: scientific notation with `N` digits after the decimal point
        - set `N` to `99` for floating number of digits
        - status line indicator is `SCI(N)`
    - `ENG`: engineering notation with `N` digits after the decimal point
        - set `N` to `99` for floating number of digits
        - status line indicator is `ENG(N)`
    - `RAD`: use radians for trigonometric functions
    - `DEG`: use degrees for trigonometric functions
- `ROOT` > `STK`
    - ![STK MenuRow 1](docs/rpn83p-screenshot-menu-root-stk-1.png)
    - `R(up)`: rotate stack up
    - `R(down)`: rotate stack down, also bound to `(` button
    - `X<>Y`: exchange `X` and `Y`, also bound to `)` button

## Advanced Usage

### Auto-start

For convenience, you may choose to auto-start the RPN83P application as soon as
you turn on the calculator.

- Download the
  [Start-Up](https://education.ti.com/en/software/details/en/77ec7de5d3694f4595c262fdfc2acc4b/83startupcustomization) application from TI
- Press `APPS`, then scroll down to `Start-up`
- Configure:
    - Display: `ON`
    - Type: `APP`
    - Name: `RPN83P` (hit `ENTER` and scroll down to select this)
- Select `FINISH` and hit `ENTER`

The LCD screen should look like this before hitting `FINISH`:

> ![Start-up app screenshot](docs/start-up-app-screenshot.png)

Turn off the calculator and turn it back on. It should directly go into the
RPN83P application.

### Floating Point Display Modes

The RPN83P app provides access to the same floating point display modes as the
original TI-OS. For reference, here are the options available in the TI-OS when
the `MODE` button is pressed:

> ![TI-OS Display Modes](docs/tios-display-modes.png)

In RPN83P, the `MODE` button presents a menu bar instead:

> ![RPN83P Display Modes](docs/rpn83p-display-modes.png)

**HP-42S Compatibility Note**: The HP-42S uses the `DISP` button to access this
functionality. For the RPN83P, it seemed to make more sense to the follow the
TI-OS convention which places the floating display modes under the `MODE`
button.

The `NORMAL` mode in TI-OS is named `FIX` in RPN83P following the lead of the
HP-42S. It is also short enough to fit into the menu label nicely, and has the
same number of letters as the `SCI` and `ENG` modes which helps with the
top-line indicator.

Suppose the RPN stack has the following numbers:

> ![RPN83P Display Modes](docs/rpn83p-display-mode-start.png)

Pressing the `FIX` menu item shows a `FIX _ _` prompt for the number of digits
after the decimal point, like this:

> ![RPN83P FIX Prompt](docs/rpn83p-display-mode-fix.png)

Type `4` then `ENTER`. The display changes to this:

> ![RPN83P FIX 4](docs/rpn83p-display-mode-fix-4.png)

(You can also press `FIX` `04` which will automatically invoke the `ENTER` to
apply the change.)

Notice that the floating point mode indicator at the top of the screen now shows
`FIX(4)`.

Try changing to scientific notation mode, by pressing: `SCI` `04` to get this:

> ![RPN83P SCI 4](docs/rpn83p-display-mode-sci-4.png)

The top-line indicator shows `SCI(4)`.

You can change to engineering notation mode, by pressing: `ENG` `04`, to
get this:

> ![RPN83P ENG 4](docs/rpn83p-display-mode-eng-4.png)

The top-line indicator shows `ENG(4)`.

To set the number of digits after the decimal point to be dynamic (i.e. the
equivalent of `FLOAT` option in the TI-OS `MODE` menu), type in a number greater
than 9 when prompted for `FIX _ _`, `SCI _ _`, or `ENG _ _`. I usually use
`99`, but `11` would also work. For example, to use scientific notation mode
with a variable number of fractional digits, press `SCI` `99` to get this:

> ![RPN83P SCI 99](docs/rpn83p-display-mode-sci-99.png)

Notice that the top-line floating point indicator now shows `SCI(-)`.

Finally, type `FIX` `99` to go back to the default floating point mode.

> ![RPN83P FIX 99](docs/rpn83p-display-mode-fix-99.png)

**HP-42S Compatibility Note**: The RPN83P uses the underlying TI-OS floating
point display modes, so it cannot emulate the HP-42S exactly. In particular, the
`ALL` display mode of the HP-42S is not directly available, but it is basically
equivalent to `FIX 99` on the RPN83P.

### Trigonometric Modes

Just like the TI-OS, the RPN83P uses the radian mode by default when calculating
trigonometric functions. The top status line shows `RAD`:

> ![RPN83P FIX 99](docs/rpn83p-trig-mode-rad-1.png)

If we calculate `sin(pi/6)` in radian mode, by typing `PI` `6` `/` `SIN`, we get
`0.5` as expected.

Press the `DEG` menu button to change to degree mode. The top status line shows
`DEG`:

> ![RPN83P FIX 99](docs/rpn83p-trig-mode-deg-1.png)

We can calculate `sin(30deg)` by typing: `30` `SIN` to get `0.5`.

**Warning**: The polar to rectangular conversion functions (`>REC` and `>POL`)
are also affected by the current Trig Mode setting.

**HP-42S Compatibility Note**: The RPN83P does not offer the
[gradian](https://en.wikipedia.org/wiki/Gradian) mode `GRAD` because the
underlying TI-OS does not support the gradian mode directly. It is probably
possible to add this feature by intercepting the trig functions and performing
some pre and post unit conversions. But I'm not sure if it's worth the effort
since gradian trig mode is not commonly used.

### BASE Functions

The `BASE` functions are available through the `ROOT` > `BASE` hierarchy:

- ![ROOT MenuRow 2](docs/rpn83p-screenshot-menu-root-2.png)
    - ![BASE MenuRow 1](docs/rpn83p-screenshot-menu-root-base-1.png)
    - ![BASE MenuRow 2](docs/rpn83p-screenshot-menu-root-base-2.png)
    - ![BASE MenuRow 3](docs/rpn83p-screenshot-menu-root-base-3.png)
    - ![BASE MenuRow 4](docs/rpn83p-screenshot-menu-root-base-4.png)
    - ![BASE MenuRow 5](docs/rpn83p-screenshot-menu-root-base-5.png)
    - ![BASE MenuRow 6](docs/rpn83p-screenshot-menu-root-base-6.png)
    - ![BASE MenuRow 7](docs/rpn83p-screenshot-menu-root-base-7.png)
    - ![BASE MenuRow 8](docs/rpn83p-screenshot-menu-root-base-8.png)

These functions allow conversion of integers into different bases (10, 16, 8,
2), as well as performing bitwise functions on those integers (bit-and, bit-or,
bit-xor, etc). They are useful for computer science and programming. Many of the
`BASE` mode functions were inspired by the HP-16C, which has more extensive
functions in this area compared to the HP-42S.

All menu functions under the `BASE` menu operate on *integer* values instead of
floating point values. Currently, the RPN83P app supports only unsigned 32-bit
integers. (Support for 8-bit, 16-bit, and 24-bit integers may be implemented in
the near future.) Any floating point values on the RPN stack (e.g. `X` or `Y`
registers) are converted into an unsigned 32-bit integer before being passed
into a logical, bitwise, or arithmetic function. This includes the `DEC` (base
10) mode.

#### Base Modes

**DEC** (decimal)

The `DEC` (decimal) mode is the default. All numbers on the RPN stack are
displayed as an integer, after being converted to an unsigned 32-bit integer.

> ![Numbers in Decimal Mode](docs/rpn83p-screenshot-base-dec.png)

If the value on the RPN stack is negative, a single `-` sign is shown. If the
value is greater than or equal to `2^32`, then 3 dots `...` are shown. If the
floating point value is within the range of `[0, 2^32]` but has non-zero
fractional value, a decimal point is shown after converting the integer part
into a 32-bit unsigned integer.

**HEX** (hexadecimal)

The `HEX` (hexadecimal) mode displays all numbers on the RPN stack using base
16. Only the integer part is rendered. It is converted into an unsigned 32-bit
integer, and printed using 8 hexadecimal digits. If there are fractional digits
after the decimal point, a decimal point `.` is printed at the end of the 8
digits to indicate that the fractional part is not shown. Negative numbers are
not valid and a single `-` character is printed instead. Three dots are printed
if the integer part is `>= 2^32`.

The hexadecimal digits `A` through `F` are entered using `ALPHA` `A`, through
`ALPHA` `F`. You can lock the `ALPHA` mode using `2ND` `A-LOCK`, but that causes
the decimal buttons `0` to `9` to send letters instead which prevents those
digits to be entered, so it is not clear that the Alpha Lock mode is actually
useful in this context.

> ![Numbers in Hexadecimal Mode](docs/rpn83p-screenshot-base-hex.png)

**OCT** (octal)

The `OCT` (octal) mode displays all numbers on the RPN stack using base 8. Only
the integer part is rendered. It is converted into an unsigned 32-bit integer,
and printed using 11 octal digits. If there are fractional digits after the
decimal point, a decimal point `.` is printed at the end of the 11 digits to
indicate that the fractional part is not shown. Negative numbers are not valid
and a single `-` character is printed instead. Three dots are printed if the
integer part is `>= 2^32`.

The button digits `0` through `7` are entered normally. The button digits `8`
and `9` are disabled in octal mode.

> ![Numbers in Octal Mode](docs/rpn83p-screenshot-base-oct.png)

**BIN** (binary)

The `BIN` (binary) mode displays all numbers on the RPN stack using base 2. Only
the integer part is rendered. It is converted into an unsigned 32-bit integer,
and printed using 14 binary digits (the maximum allowed by the width of the LCD
screen). If there are fractional digits after the decimal point, a decimal point
`.` is printed at the end of the 14 digits to indicate that the fractional part
is not shown. Negative numbers are not valid and a single `-` character is
printed instead. Three dots are also printed if the integer part is `>= 2^14`
(i.e. `>= 16384`).

Only the button digits `0` and `1` are active in the binary mode. The rest are
disabled.

> ![Numbers in Binary Mode](docs/rpn83p-screenshot-base-bin.png)

#### Shift and Rotate

The RPN83P supports most of the common shift and rotate operations implemented
by modern microprocessors, including the Z80 processor used in the TI-83 Plus
and TI-84 Plus calculators. Unfortunately, there seems to be no standard
mnemonics for these shift and rotate operations, and different processors and
calculators use conflicting names. The RPN83P follows the conventions of the
HP-16C for consistency, even though the conventions are sometimes contrary to
the conventions of the Z80 processor:

- `SL` - shift left logical
    - named `SLA` on the Z80 (see Note below regarding `SLL` instruction)
    - named `SL` on the HP-16C
- `SR` - shift right logical
    - named `SRL` on the Z80
    - named `SR` on the HP-16C
- `ASR` - arithmetic shift right
    - named `SRA` on the Z80
    - named `ASR` on the HP-16C
- `SLn` - shift left logical of `Y` for `X` times
    - no equivalent on Z80 or HP-16C
- `SRn` - shift right logical of `Y` for `X` times
    - no equivalent on Z80 or HP-16C
- `RL` - rotate left circular
    - named `RLC` on the Z80
    - named `RL` on the HP-16C
- `RR` - rotate right circular
    - named `RRC` on the Z80
    - named `RR` on the HP-16C
- `RLC` - rotate left through carry flag
    - named `RL` on the Z80
    - named `RLC` on the HP-16C
- `RRC` - rotate right through carry flag
    - named `RR` on the Z80
    - named `RRC` on the HP-16C
- `RLn` - rotate left circular of `Y` for `X` times
    - no equivalent on Z80
    - named `RLn` on the HP-16C
- `RRn` - rotate right circular of `Y` for `X` times
    - no equivalent on Z80
    - named `RRn` on the HP-16C
- `RLCn` - rotate left through carry flag of `Y` for `X` times
    - no equivalent on Z80
    - named `RLCn` on the HP-16C
- `RRCn` - rotate right through carry flag of `Y` for `X` times
    - no equivalent on Z80
    - named `RRCn` on the HP-16C

For all `XXn` operations, if the `n` value (i.e. `X` register) is 0, the
operation does not change the value of `Y`, but the RPN stack collapses by one
position so the `X` value disappears. If the `n` value is `>=` to the `BASE`
word size (`WSZ?`), normally 32, an error message will be displayed.

**Note**: The Z80 apparently has an undocumented instruction named [shift left
logical](https://worldofspectrum.org/z88forever/dn327/z80undoc.htm) which is
shortened to `SLL` or `SL1`. It places a 1 into bit 0 of the register, instead
of a 0. It is unfortunate that term "logical" is used in the exact opposite
to the meaning that I would have expected.

#### Base Arithmetic

Similar to the HP-42S, activating the `BASE` hierarchy of menus changes the
behavior of keyboard arithmetic functions. Specifically, the buttons `+`, `-`,
`*`, `/` are re-bound to their integer counterparts `B+`, `B-`, `B*`, `B/` which
perform 32-bit unsigned arithmetic operations instead of floating point
operations. The numbers in the `X` and `Y` registers are converted into 32-bit
unsigned integers before the integer subroutines are called.

**HP-42S Compatibility Note**: The HP-42S calls these integer functions `BASE+`,
`BASE-`, `BASE*`, and `BASE/`. The RPN83P can only display 4-characters in the
menu bar so I had to use shorter names. The HP-42S function called `B+/-` is
called `NEG` on the RPN83P. Early versions of the RPN83P retained the keyboard
arithmetic buttons bound to their floating point operations, but it became too
confusing to see hex, octal, or binary digits on the display, but get floating
point results when performing an arithmetic operation such as `/`. The RPN83P
follows the lead of the HP-42S to change the arithmetic operations to integer
operations.

For example, suppose the following numbers are in the RPN stack *before*
entering the `BASE` menu:

> ![Base Arithmetic Part 1](docs/rpn83p-screenshot-base-arithmetic-1-float.png)

Entering the `BASE` menu shows this (assuming that the default base number was
`DEC`):

> ![Base Arithmetic Part 2](docs/rpn83p-screenshot-base-arithmetic-2-dec.png)

Changing to `HEX` mode shows this:

> ![Base Arithmetic Part 3](docs/rpn83p-screenshot-base-arithmetic-3-hex.png)

Pressing the `+` button adds the `X` and `Y` registers, converting the
values to 32-bit unsigned integers before the addition:

> ![Base Arithmetic Part 4](docs/rpn83p-screenshot-base-arithmetic-4-plus.png)

Changing back to `DEC` mode shows that the numbers were added using integer
functions, and the fractional digits were truncated:

> ![Base Arithmetic Part 5](docs/rpn83p-screenshot-base-arithmetic-5-dec.png)

#### Carry Flag

The RPN83P supports the *Carry Flag* implemented by most (all?) microprocessors.
The Carry Flag is supported by the HP-16C but not by the HP-42S. When the Carry
Flag is set, a small `C` letter appears on the display like this:

> ![Carry Flag On](docs/rpn83p-carry-flag-on.png)

When the flag is off, a dash `-` is shown like this:

> ![Carry Flag On](docs/rpn83p-carry-flag-off.png)

The Carry Flag can be explicitly cleared, set, and retrieved using the following
menu items:

- `CCF`: clear carry flag
- `SCF`: set carry flag
- `CF?`: get carry flag

Many operations affect the Carry Flag (CF). All shift and rotate operations
affect the CF:

- `SL`: bit 31 shifted into CF
- `SR`: bit 0 shifted into CF
- `ASR`: bit 0 shifted into CF
- `SLn`: bit 31 shifted into CF after shifting `n` positions
- `SRn`: bit 0 shifted into CF after shifting `n` positions
- `RL`: bit 31 shifted into CF
- `RR`: bit 0 shifted into CF
- `RLC`: CF into bit 0; bit 31 into CF
- `RRC`: CF into bit 31; bit 0 into CF
- `RLn`: bit 31 shifted into CF after rotating `n` positions
- `RRn`: bit 0 shifted into CF after rotating `n` positions
- `RLCn`: CF into bit 0; bit 31 into CF after rotating `n` positions
- `RRCn`: CF into bit 31; bit 0 into CF after rotating `n` positions

All integer arithmetic functions affect the CF:

- `B+`: CF set on overflow
- `B-`: CF set on borrow
- `B*`: CF set on overflow
- `B/`: CF always set to 0
- `BDIV`: CF always set to 0

On most microprocessors, the bitwise operations clear the Carry Flag to zero.
However the RPN83P follows the lead of the HP-16C calculator where these
operations do *not* affect the Carry Flag at all:

- `AND`, `OR`, `XOR`, `NEG`, `NOT`, `REVB`, `CNTB`

#### Bit Operations

Specific bits can be cleared or set using the `CB` and `SB` menu items.

- `CB`: clear the `X` bit of `Y`
- `SB`: set the `X` bit of `Y`
- `B?`: get the `X` bit of `Y` as 1 or 0

The range of `X` must be between 0 and 31, or an error code will be generated.

This menu row contains a couple of additional bit manipulation functions:

- `REVB`: reverse the bit patterns of `X`
- `CNTB`: count the number of 1 bits in `X`

None of these bit operations affect the Carry Flag.

#### Base Integer Size

The HP-42S uses a 36-bit *signed* integer for BASE rendering and operations. To
be honest, I have never been able to fully understand and become comfortable
with the HP-42S implementation of the BASE operations. First, 36 bits is a
strange number, it is not an integer size used by modern microprocessors (8, 16,
32, 64 bits). Second, the HP-42S does not display leading zeros in `HEX` `OCT`,
or `BIN` modes. While this is consistent with the decimal mode, I find it
confusing to see the number of rendered digits change depending on its value.

The RPN83P deviates from the HP-42S by using a 32-bit *unsigned* integer
internally, and rendering the various HEX, OCT, and BIN numbers using the same
number of digits all the time. This means that `HEX` mode always displays 8
digits, `OCT` mode always displays 11 digits, and `BIN` mode always displays 14
digits (due to size limitation of the LCD screen). I find this far less
confusing when doing bitwise operations (e.g. bit-and, bit-or, bit-xor).

Since the internal integer representation is *unsigned*, the `(-)` (change sign)
button is disabled. Instead, the menu system provides a `NEG` function which
performs a [two's complement](https://en.wikipedia.org/wiki/Two%27s_complement)
operation which turns a `00000001` hex number into `FFFFFFFF`. The `NEG`
function is closely related to the `NOT` function which performs a [one's
complement](https://en.wikipedia.org/wiki/Ones%27_complement) operation where
the `00000001` becomes `FFFFFFFE`.

If you want to see the decimal value of a hex number that has its sign-bit (the
most significant bit) turned on (so it would be interpreted as a negative number
if it were interpreted as a 32-bit signed integer), you can run the `NEG`
function on it, then hit the `DEC` menu item to convert it to decimal. The
displayed value will be the decimal value of the original hex number, without
the negative sign.

Currently, the integer size for base conversions and functions is hardcoded to
be 32 bits. I hope to add the ability to change the integer size in the future.

#### Base Number Retention

Since the `DEC`, `HEX`, `OCT` and `BIN` modes are useful only within the `BASE`
hierarchy of menus. When the menu leaves the `BASE` hierarchy, the numbers on
the RPN stack revert back to using floating points. This is similar to the
HP-42S. However, unlike the HP-42S, the RPN83P remembers the most recent base
number and restores its setting if the `BASE` menu hierarchy is selected again.

### Storage Registers

Similar to the HP-42S, the RPN83P provides **25** storage registers labeled
`R00` to `R24`. They are accessed using the `STO` and `2ND` `RCL` keys. To store
a number into register `R00`, press:

- `STO` `00`

To recall register `R00`, press:

- `2ND` `RCL` `00`

To clear the all storage registers, use the arrow keys for the menu system to
get to:

- ![ROOT MenuRow 3](docs/rpn83p-screenshot-menu-root-3.png)
- Press `CLR` to get
  ![CLR MenuRow 1](docs/rpn83p-screenshot-menu-root-clr-1.png)
- Press `CLRG`

The message `REGS cleared` will be displayed on the screen.

### Prime Factors

The `PRIM` function calculates the lowest prime factor of the number in `X`. The
result will be `1` if the number is a prime. Unlike almost all other functions
implemented by RPN83P, the `PRIM` function does not replace the original `X`.
Instead it pushes the prime factor onto the stack, causing the original `X` to
move to the `Y` register. This behavior was implemented to allow easier
calculation of all prime factors of a number as follows.

After the first prime factor is calculated, the `/` can be pressed to calculate
the remaining factor in the `X` register. We can now press `PRIM` again to
calculate the next prime factor. Since the `PRIM` preserves the original number
in the `Y` register, this process can be repeated multiple times to calculate
all prime factors of the original number.

For example, let's find the prime factors of `119886 = 2 * 3 * 13 * 29 * 53`:

- Press `119886`
- Press `PRIM` to get `2`
- Press `/` to divide down to `59943`
- Press `PRIM` to get `3`
- Press `/` to divide down to `19981`
- Press `PRIM` to get `13`
- Press `/` to divide down to `1537`
- Press `PRIM` to get `29`
- Press `/` to divide down to `53`
- Press `PRIM` to get `1`, which makes `53` the last prime factor.

For computational efficiency, `PRIM` supports only integers between `2` and
`2^32-1` (4 294 967 295). This allows `PRIM` to use integer arithmetic, making
it about 7X faster than the equivalent algorithm using floating point routines.
Any number outside of this range produces an `Err: Domain` message. (The number
`1` is not considered a prime number.)

If the input number is a very large prime, the calculation may take a long time.
However, testing has verified that the `PRIM` algorithm will always finish in
less than about 30 seconds on a TI-83 Plus or TI-84 Plus calculator, no matter
how large the input number. During the calculation, the "run indicator" on the
upper-right corner will be active. You can press `ON` key to break from the
`PRIM` loop with an `Err: Break` message.

### STAT Functions

The RPN83P implements *all* statistical and curve fitting functionality of the
HP-42S, as described in Ch. 15 of the _HP-42S User's Manual_. Additional
reference material can be found at:

- https://en.wikipedia.org/wiki/Algorithms_for_calculating_variance
- https://en.wikipedia.org/wiki/Simple_linear_regression
- https://en.wikipedia.org/wiki/Covariance_and_correlation

Most of the menu names are the same as the HP-42S. Here are some of the
differences:

- The organization of the menu items is different because the TI calculator has
  only 5 menu buttons instead of 6 on the HP-42S. I also did not like the
  complexity of the HP-42S menus for the `STAT` functions; it is nested
  unnecessarily deeply. I have simplified the menu hierarchy for the RPN83P to
  just 2-levels instead of 3.
- The HP-42S `WMN` (weighted mean) returns only the weighted mean of `X`. If you
  wanted the weighted mean of `Y` instead, you are forced to re-enter the data
  points by swapping the `X` and `Y` values, or manually calculate it from the
  raw summation registers. The RPN83P calculates both weighted means so that you
  can choose the appropriate value.
- The RPN83P contains an `N` menu item that simply returns the number of data
  points entered for convenience. This value can be retrieved using `2ND RCL
  16`, but it is unreasonable to expect users to remember this storage register
  number.
- The HP-42S calculates only the sample standard deviation `SDEV`. The RPN83P
  supports both the sample standard deviation `SDEV` or the population standard
  deviation `PDEV`. The ratio of `SDEV/PDEV` is `sqrt(N/(N-1))` but it is
  convenient to have both types available in the menu.
- The RPN83P supports the calculation of the
  [covariance](https://en.wikipedia.org/wiki/Covariance_and_correlation) in 2
  forms, the sample covariance `SCOV` and population covariance `PCOV`. They are
  needed internally for least square curve fitting, so it seemed appropriate to
  expose them to the user through the menu buttons. The ratio of
  `SCOV(X,Y)/PCOV(X,Y)` is `N/(N-1)`.

The curve fit models under the `CFIT` menu group are identical to the HP-42S.
The linear curve fit `LINF` is available with either `LINSigma` or `ALLSigma`
selected. The other models (`LOGF`, `EXPF`, `PWRF`) are available only when the
`ALLSigma` option is selected, because they require additional summation
registers to be active and updated.

On the HP-42S, the clear menu item `CLSigma` is available only under the `CLEAR`
menu hierarchy. On the RPN83P, the `CLSigma` menu appears in 2 places for
convenience, under the `CLR` hierarchy *and* under the `STAT` hierarchy. The
number of storage registers that are cleared depends on whether `LINSigma` or
`ALLSigma` are selected, just like the HP-42S.

There are a few STAT features which are _not_ implemented on the RPN83P:

- The storage registers allocated to the `STAT` functions are hardcoded to be
  `R11-R23`. On the HP-42S, the register allocation can be changed.
- RPN83P does not (yet) support vectors and matrices, so it is not possible to
  enter the data into a matrix first, then perform the `STAT` functions over the
  matrix.

**Example**

Let's enter the data points given in the HP-42S manual, the "maximum and minimum
monthly winter rainfall values in Corvallis, Oregon".

```
Month   Y(max)  X(min)
-----   ----    ----
Oct      9.70   0.10
Nov     18.28   0.22
Dec     14.47   2.33
Jan     15.51   1.99
Feb     15.23   0.12
Mar     11.70   0.43
```

We would enter these data points like this:

- Press `STAT` to see
  ![STAT MenuRow 1](docs/rpn83p-screenshot-menu-root-stat-1.png)
- Press `ALLSigma` (select all curve fit models)
- Press `CLSigma` to clear the summation registers. You should see a status
  message `STAT cleared`.
- Enter the data points in pairs, with the `Y` value first, then `X`:
    - `9.70` `ENTER` `0.10` `Sigma+`. You should see a `1`.
    - `18.28` `ENTER` `0.22` `Sigma+`. You should see a `2`.
    - `14.47` `ENTER` `2.33` `Sigma+`. You should see a `3`.
    - `15.51` `ENTER` `1.99` `Sigma+`. You should see a `4`.
    - `15.23` `ENTER` `0.12` `Sigma+`. You should see a `5`.
    - `11.70` `ENTER` `0.43` `Sigma+`. You should see a `6`.

(Note that the "stack lift" is disabled by the `Sigma+` and `Sigma-` buttons,
similar to the `ENTER` key. So the `N` values will be replaced by the next
`Ymax` value.)

Let's calculate the basic statistics measures:

- Press `DOWN` arrow key to see
  ![STAT MenuRow 2](docs/rpn83p-screenshot-menu-root-stat-2.png)
- Press `SUM` to get `Y:84.89` and `X:5.19`
- Press `MEAN` to get `Y:14.14833333` and `X:.865`
- Press `WMN` to get `Y:14.72643545` and `X:.9003439746`
- Press `N` to get `X:6`
- Press `DOWN` arrow key to see
  ![STAT MenuRow 3](docs/rpn83p-screenshot-menu-root-stat-3.png)
- Press `SDEV` to get `Y:3.032500069` and `X:1.015613115`
- Press `SCOV` to get `X:.60007`
- Press `PDEV` to get `Y:2.768281155` and `X:.9271236883`
- Press `PCOV` to get `X:.5000583333`

Let's perform some curve fits. It is not obvious that the maximum rainfall
for a given month is correlated with the minimum rainfall for the same month. We
can use the CFIT routines to figure this out:

- Press `CFIT` to see
  ![CFIT MenuRow 1](docs/rpn83p-screenshot-menu-root-stat-cfit-1.png)
- Press the `DOWN` arrow to see
  ![CFIT MenuRow 2](docs/rpn83p-screenshot-menu-root-stat-cfit-2.png)
- Verify that the `LINF` (linear fit) is selected
- Press the `UP` arrow to get back to the main `CFIT` row.
- Press `SLOP` to get `X:.5817619514`. This is the slope variable `m`.
- Press `YINT` to get `X:13.64510925`. This is the y-intercept variable `b`.
- Press `CORR` to get `X:.1948376107`. This is the correlation coefficient `r`.
  A value of `0.19` means that the correlation between min and max rainfall is
  fairly weak. A high correlation would be close to 1.0.

Let's see if a different curve fit model does better.

- Press `DOWN` arrow to get to
  ![CFIT MenuRow 2](docs/rpn83p-screenshot-menu-root-stat-cfit-2.png)
- Press `BEST` button to request the app to automatically determine the
  best curve model. You should see `X:.2963586116` and the menu should have
  changed to select `PWRF`, like this:
  ![CFIT BEST](docs/rpn83p-cfit-best.png)

**HP-42S Compatibility Note**: Unlike the HP-42S, `BEST` menu on the RPN83P
returns the `CORR` value of the best curve fit model. It seemed like a useful
bit of information to see, and it provides visual feedback that the `BEST`
function has finished, since the RPN83P seems significantly slower than the
HP-42S, at least on the emulators.

The RPN83P app has determined that the best curve fit model for the data is the
power curve `y = b x^m`, with a correlation coefficient `r = .2963586116`. It is
still a weak correlation, but better than the linear model.

You can perform forecasting with the `Y>X` and `X>Y` menus:

- Enter `1.5` (min rainfall) then press `X>Y`. It predicts a maximum rainfall of
  `14.75`.
- Enter `12` (max  rainfall) then press `Y>X`. It predicts a minimum rainfall of
  `0.02188`.

These predictions should be regarded with suspicion because the correlation
coefficient of `r=.29635` is quite low, and the power fit may not be a good
model for this data. For example, typing `20` `Y>X` (max rainfall of 20.0) gives
an `X=752.098` (a minimum rainfall of 752) which is not reasonable.

### TI-OS Interaction

The RPN83P app interacts with the underlying TI-OS in the following ways.

- Two TI-OS List variables are used to store its internal floating point
  numbers:
    - `STK` holds the RPN stack registers (`X`, `Y`, `Z`, `T`, `LastX`)
    - `REGS` holds the 25 storage registers `R00` to `R24`

  A TI-BASIC program can access these List variables since they hold just normal
  9-byte floating point numbers.
- An appVar named `RPN83SAV` is used to preserve the internal state of the app
  upon exiting. When the app is restarted, the appVar is read back in, so that
  it can continue exactly where it had left off.
- The `X` register of RPN83P is copied to the `ANS` variable in the TI-OS when
  the RPN83P app exits. This means that the most recent `X` register from RPN83P
  is available in the TI-OS calculator using `2ND` `ANS`.
- When the RPN83P app is started, it examines the content of the `ANS` variable.
  If it is a Real value (i.e. not complex, not a matrix, not a string, etc),
  then it is copied into the `LastX` register of the RPN83P. Since the `LastX`
  functionality is invoked in RPN83P as `2ND` `ANS`, this means that the TI-OS
  `ANS` value becomes available in RPN83P as `2ND` `ANS`.

For a handful of configuration parameters, the RPN83P uses the same flags and
global variables as the TI-OS. Changing these settings in RPN83P will cause the
same change in the TI-OS (and vice versa) because the configuration parameters
are shared:

- trigonometric mode: `RAD` or `DEG`
- floating point number settings: `FIX` (i.e. `NORMAL` in TI-OS), `SCI`, `ENG`

## Future Enhancements

There seems to be almost an endless number of features that could go into a
calculator app. I have grouped them as follows, since my time and energy is
limited:

### Near Future

- `PROB` and `COMB` arguments are limited to `< 256`
    - Maybe extend this to `< 2^16` or `<2^32`.
- `GCD` and `LCM` functions are slow
    - Could be made significantly faster.
- datetime conversions
    - date/time components to and from epoch seconds
- compound `STO` and `RCL` operators
    - `STO+ nn`, `STO- nn`, `STO* nn`, `STO/ nn`
    - `RCL+ nn`, `RCL- nn`, `RCL* nn`, `RCL/ nn`

### Medium Future

- user-defined variables
    - The HP-42S shows user-defined variables through the menu system.
    - Nice feature, but would require substantial refactoring of the current
      menu system code.
- custom menu items
    - The HP-42S supports up to 18 (3 rows of 6 menus) to be customized through
      the `ASSIGN` and `CUSTOM` menus.
    - This seems like a useful feature, but would require substantial
      refactoring of the currnet menu system code, like user-defined variables.
- complex numbers
    - The TI-OS provides internal subroutines to handle complex numbers, so in
      theory, this should be relatively easy.
    - I think the difficulty will be the user interface. A complex number
      requires 2 floating point numbers to be entered and displayed, and I have
      not figured out how to do that within the UI of the RPN83P application.
- `UNIT` conversions
    - several places assume US customary units (e.g. US gallons) instead of
      British or Canadian imperial units
    - it'd be nice to support both types, if we can make the menu labels
      self-documenting and distinctive
- user selectable integer size for `BASE` functions
    - currently, binary, octal, hexadecimal routines are implemented internally
      using 32-bit unsigned numbers
    - the user ought to be able to specify the integer size for those
      operations: 8 bits, 16 bits, 32 bits, maybe 48 bits and 64 bits
    - 48-bits seems to be a reasonable goal because the TI-OS floating point
      number supports 14 decimal digits, which corresonds to 46.5 bits, which
      fits nicely into 48 bits.
    - the user-interface will be a challenge: for large integer sizes, the
      number of digits will no longer fit inside the 14-15 digits available on a
      single line.
- Support more than 14 digits using `BASE 2`
    - The underlying integer representation is 32 bit, it would be nice to be
      able to display all of those digits.
    - But this could be a difficult UI problem, because 32 digits will require 3
      lines on the display, as each line currently can support only 14, maybe
      15 digits.
- system memory
    - Might be useful to expose some system status functions, like memory.
    - We can always drop into the TI-OS and use `2ND` `MEM` to get that
      information, so it's not clear that this is worth the effort.
- TVM (time value of money)
    - the TI-84 Plus is bundled with a TVM app, but I find it unintuitive and
      difficult to remember how to use
    - the most intuitive UI in my opinion is the one used by the HP-12C
    - if I recall, this requires implementing a root finder, since at least one
      of the TVM variables does not have a closed-form solution

### Far Future

I'm not sure these features are worth the effort, but I may do them for
curiosity and the technical challenge:

- programming
    - Although I think it is technically possible for the RPN83P app to support
      keystroke programming, like the HP-42S, I am not sure that the calculator
      world needs yet another calculator programming language.
    - Is it sufficient that the user can drop into TI-BASIC programming if that
      is required?
- matrix and vectors
    - I don't know how much matrix functionality is provided by TI-OS SDK.
    - Creating a reasonable user-interface in the RPN83P could be a challenge.
    - It is not clear that adding matrix functions into a calculator is worth
      the effort. For non-trivial calculations, it is probably easier to use
      a desktop computer and application (e.g. MATLAB, Octave, Mathematica).
- root finder (i.e. SOLVE)
    - one of the hallmarks of advanced HP calculators, but I think this feature
      would only be useful with keystroke programming
- integration
    - another feature of advanced HP calculators which also depends on keystroke
      programming

### Not Planned

- graphing
    - The TI-OS has extensive support for graphing equations.
    - It does not make sense to duplicate that work in the RPN83P application.
- computer algebra system (CAS)
    - The TI-83 Plus and TI-84 Plus do not support CAS, so it is highly unlikely
      that the RPN83P will support CAS either.
- rational numbers
    - Not something that I have ever needed, so I probably will not want to
      spend my time implementing it.
