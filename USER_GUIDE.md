# RPN83P User Guide

RPN calculator app for the TI-83 Plus and TI-84 Plus inspired by the HP-42S.

**Version**: 0.0 (2023-08-07)

**Project Home**: https://github.com/bxparks/rpn83p

## Table of Contents

- [Introduction](#Introduction)
- [Installation](#Installation)
- [Basic Usage](#BasicUsage)
    - [Screen Areas](#ScreenAreas)
    - [Input and Editing](#InputAndEditing)
    - [RPN Stack](#RPNStack)
    - [Menu Hierarchy and Navigation](#MenuHierarchy)
- [Functions](#Functions)
    - [Direct Functions](#DirectFunctions)
    - [Menu Functions](#MenuFunctions)
- [Future Enhancements](#FutureEnhancements)
    - [Near Future](#NearFuture)
    - [Medium Future](#MediumFuture)
    - [Far Future](#FarFuture)
    - [Not Planned](#NotPlanned)
- [Bugs and Limitations](#BugsAndLimitations)

<a name="Introduction"></a>
## Introduction

The RPN83P is an [RPN](https://en.wikipedia.org/wiki/Reverse_Polish_notation)
calculator app for the [TI-83 Plus](https://en.wikipedia.org/wiki/TI-83_series)
(including the Silver Edition) and the [TI-84
Plus](https://en.wikipedia.org/wiki/TI-84_Plus_series) (including the Silver
Edition). The app is inspired mostly by the
[HP-42S](https://en.wikipedia.org/wiki/HP-42S) calculator, with some sprinkles
of some older HP calculators like the
[HP-12C](https://en.wikipedia.org/wiki/HP-12C) and the
[HP-15C](https://en.wikipedia.org/wiki/HP-15C). The RPN83P is a flash
application that consumes one page (16 kB) of flash memory. Since it is stored
in flash, it is preserved if the RAM is cleared. It consumes very little RAM:
only 5 variables of 18 bytes or about 90 bytes.

Here are some of the high level features:

- traditional 4-level RPN stack (`X`, `Y`, `Z`, `T` registers)
- support for `lastX` register
- hierarchical menu system, inspired by the HP-42S
- probability functions (`P(n,r)`, `C(n,r)`, `n!`, random number)
- support for all math functions with dedicated buttons
    - arithmetic: `/`, `*`, `-`, `+`
    - trigonometric: `SIN`, `COS`, `TAN`, etc.
    - `1/X`, `X^2`, `2ND SQRT`, 
    - `^` (i.e. `Y^X`), 
    - `LOG`, `10^X`, `LN`, `e^X`
    - constants: `pi` and `e`
- additional menu functions:
    - `%`, `Delta%`, `GCD`, `LCM`, `PRIM` (is prime?)
    - `ABS`, `SIGN`, `MOD`, `MIN`, `MAX`
    - `IP` (integer part`, `FP` (fractional part)`, `FLR` (floor), `CEIL`
        (ceiling), `NEAR` (nearest integer)
    - hyperbolic: `SINH`, `COSH`, `TANH`, etc.
    - conversions: `>DEG`, `>RAD`, `>HR`, `>HMS`, `P>R`, `R>P`
    - unit conversions: `>C`, `>F`, `>km`, `>mi`, etc
    - base conversions: `DEC`, `HEX`, `OCT`, `BIN`
- various display modes
    - `RAD`, `DEG`
    - `FIX` (fixed point 0-9 digits)
    - `SCI` (scientific 0-9 digits)
    - `ENG` (engineering 0-9 digits)

Here are some missing features which may be added in the future:

- user registers (`STO 00`, `RCL 00`, etc)
- statistics functions (sum, mean, variance, standard deviation)
- complex numbers
- programming

<a name="Installation"></a>
## Installation

The app is provided as a single file named `rpn83p.8xk`. It must be uploaded
to the calculator using a "link" program from a host computer. There are a
number of options:

**Linux**
- [tilp](https://github.com/debrouxl/tilp_and_gfm)
- On Ubuntu 22.04 machines, you can install this using `$ apt install tilp2`
- (I'm not actually sure whether the `tilp2` binary is actually compiled
    from the `tilp_and_gfm` source code mentioned above)

**Windows** or **MacOS**
- [TI Connect](https://education.ti.com/en/products/computer-software/ti-connect-sw)

After installing `rpn83p.8xk` file, go to the calculator:

- Press the `APPS` key
- Scroll down to the `RPN83P` entry
- Press the `ENTER` key

You should see a screen that looks like:

[TBD: Insert screen shot]

The following are various ways to quit or exit out of certain contexts:

- `2ND` `QUIT`: to exit to normal TI calculator
- `2ND` `OFF`: to turn the calculator off (the RPN registers will be preserved)
- `ON`: to incrementally back out from nested menus

<a name="BasicUsage"></a>
## Basic Usage

This guide assumes that you already know to use an RPN calculator. In
particular, this guide assumes that you are familiar with the traditional RPN
system used by Hewlett-Packard calculators such as the HP-12C, HP-15C, and the
HP-42S. (The RPN83P does not use the newer RPN system used by the HP-48SX.)

<a name="ScreenAreas"></a>
### Screen Areas

Here are the elements rendered on the LCD screen:

[TODO: Insert screen shot with pointers to different areas]

The LCD screen on the TI calculator is 96 pixels (width) by 64 pixels (height).
That is large enough to display 8 rows of numbers and letters. They are divided
in the following:

- 1: status line
- 2: (currently unused)
- 3: error code line
- 4: T register line
- 5: Z register line
- 6: Y register line
- 7: X register/input line
- 8: menu line

The X register line is also used as the input line when entering new numbers. It
is also used to prompt for command line argument, for example `FIX __` to set
the fixed display mode.)

<a name="InputAndEditing"></a>
### Input and Editing

The following buttons are used to enter and edit a number in the input buffer:

- `0`-`9`: digits
- `(-)`: change sign (same as `+/-` or `CHS` on HP calculators)
- `.`: decimal point
- `2ND` `EE`: exponent for scientific notation (same as `E` or `EEX` on HP
  calculators)
- `,`: same as `2ND` `EE` for convenience
- `DEL`: Backspace (same as `<-` on many HP calculators)
- `CLEAR`: Clear `X` register (same as `CLx` or `CLX` on HP calculators)

When the cursor (`_`) is shown, indicating the **edit** mode, the `DEL` key acts
like the *backspace* key on HP calculators. The `DEL` key always removes the
right-most digit, because the cursor is always at the end of the input string of
digits.

The `CLEAR` key clears the entire input buffer, leaving just a cursor at the end
of an empty string. An empty string will be interpreted as a `0`. Note that when
the cursor is *not* shown, the `DEL` key also acts like the `CLEAR` key.

The comma `,` button is not used in the RPN system, so it has been mapped to
behave exactly like the `2ND` `EE` button. This allows scientific notation
numbers to be entered quickly without having to press the `2ND` button
repeatedly.

<a name="RPNStack"></a>
### RPN Stack

The RPN83P tries to implement the traditional 4-level stack used by many HP
calculators as closely as possible, including some features which some people
may find idiosyncratic. There are 4 slots in the RPN stack named `X`, `Y`, `Z`,
and `T`. The LCD screen on the TI calculators is big enough that all 4 RPN
registers can be shown at all times. (For comparison, the HP-12C and HP-15C have
only a single line display. The HP-42S has a 2-line display, with the bottom
line often commandeered by the menu line so that only the `X` register is
shown.)

There are 4 keys which are relevant for the RPN stack:

- `(`: rotates RPN stack down (known as `R(downarrow)` on HP calculators)
- `2ND` `{`: rotate RPN stack up (known as `R(uparrow)` on HP calculators)
- `)`: exchanges `X` and `Y` registers
- `ENTER`: saves the input buffer to the `X` register, and *disables* the
  stack lift for the next number entry
- `2ND` `ANS`: recalls the last `X`

When a new number is entered (using the `0`-`9` digit keys), the press of the
first digit causes the stack to **lift**, and the calculator enters into the
**edit** mode. This mode is indicated by the appearance of an underscore `_`
cursor.

A stack **lift** causes the previous `X` value to shift into the `Y` register,
the previous `Y` value into the `Z` register, and the previous `Z` value into
the `T` register. The previous `T` value is lost. Conceptually, additional
digits are appended to the number in the `X` register.

The `Enter` key performs 2 functions:

- it *duplicates* the `X` register into the `Y` register
- it temporarily *disables* the stack lift for the next number

This is consistent with traditional RPN system used by HP calculators up to and
including the HP-42S. It allows one to press: `2` `ENTER` `3` `*` to multiply
`2*3` and get `6` as the result, because the second number `3` does not lift the
stack.

The parenthesis `(` and `)` are not used in an RPN entry system, so they have
been repurposed for stack manipulation.

The `(` key rotates the stack down, exactly as the same as the `R(downarrow)` or
just a single `(downarrow)` on the HP calculators. The `2ND` `{` key (above the
`(` key) performs the opposite stack rotation, rotating the stack up. This
functionality is not used as often, so it is bound to a key stroke with the
`2ND` key.

The `)` key performs an exchange of the `X` and `Y` registers. That
functionality is usually marked as `X<>Y` on HP calculators. 

This mapping of the `(` and `)` to these stack functions is identical to the
mapping used by the [HP-30b](https://en.wikipedia.org/wiki/HP_30b) when it is in
RPN mode. (The HP-30b supports both algebraic and RPN entry modes.)

The `2ND` `ANS` button is mapped to the `LastX` functionality of HP calculators.
It is the value of the `X` register of the most recent operation. It can be used
to bring back a number that was accidentally consumed, or sometimes it can be
used as part of a longer sequence of calculations.

<a name="MenuHierarchy"></a>
### Menu Hierarchy and Navigation

The menu system of the RPN83P was borrowed directly from the HP-42S calculator.
There are 5 buttons directly under the LCD screen. Those buttons will activate
different functions depending on the menu shown on the bottom row of the LCD
screen.

The menu items form a singly-rooted tree of menu items and groups. There are
over 100 menu items in the RPN83P hierarchy. The menu hierarchy look like this
conceptually:

[TODO: add link to menu hierarchy diagram]

There are 4 buttons which are used for menu navigation:

- `UP_ARROW`: go to previous MenuStrip of 5 menu items
- `DOWN_ARROW`: go to next MenuStrip of 5 menu items
- `ON`: go up the menu hierarchy (similar to the `ON/EXIT` button on the HP-42S)
- `MATH`: go to the root (home) of the menu tree

The `UP_ARROW` and `DOWN_ARROW` keys move from one MenuStrip of 5 menu items to
the next set, within the same MenuGroup. Pressing `UP` at the first MenuStrip
will wrap around to the last MenuStrip. Pressing `DOWN` at the last MenuStrip
will wrap around to the first MenuStrip.

To move from a child MenuGroup back up to the parent MenuGroup, the appropriate
key would have been an `ESC` button. But the TI-83 and TI-84 calculators do not
have an `ESC` key (unlike the TI-92 and TI Voyager 200 calculators), so the `ON`
button was recruited for this functionality. The choice of the `ON` button was
not completely random, because the HP-42S uses the `ON` key which doubles as the
`EXIT` key to perform implement this functionality.

Pressing the `ON` button multiple times will eventually bring you back to the
root of the menu hierarchy. Sometimes, it is convenient to be able to go back to
the root in a single press. That button would be the `HOME` button, but the
TI-83 and TI-84 calculators do not have a `HOME` button (unlike the TI-92 and TI
Voyager 200 series again). Instead, the RPN83P app takes over the `MATH` button
as the `HOME` key. This choice is again not completely random: First, the `HOME`
button on the TI-89 Titanium is located exactly where the `MATH` is. Two, when
the menu is at the root, the first menu item on the left is a MenuGroup named
`MATH`, which may help to remember this button mapping.

<a name="Functions"></a>
## Functions

<a name="DirectFunctions"></a>
### Direct Functions

These functions are available directly from the physical buttons on the
calculator keyboard.

- arithmetic
    - `/`, `*`, `-`, `+`
- trigonometric
    - `SIN`, `COS`, `TAN`
    - `2ND` `SIN^-1`, `2ND` `COS^-1`, `2ND` `TAN^-1`
- algebraic
    - `X^-1`, `X^2`, `sqrt`, `^` (Y^X)
- transcendental
    - `LOG`, `10^X`, `LN`, `e^X`
- constants
    - `pi`, `e`

<a name="MenuFunctions"></a>
### Menu Functions

These functions are accessed through the hierarchical menu, using the 5 menu
buttons just under the LCD screen. Use the `UP`, `DOWN`, `ON` (back), and `MATH`
(home) keys to navigate the menu hierarchy.

- `MATH`
    - `X^3`: cube of `X`
    - `3 Root X`: cube root of `X`
    - `ATN2`: `atan2(Y, X)` in degrees or radians, depending on current mode
        - `Y` register is the x-component entered first
        - `X` register is the y-component entered second
    - `2^X`: `2` to the power of `X`
    - `LOG2`: log base 2 of `X`
    - `LOGB`: log base `X` of `Y` 
- `NUM`
    - `%`: `X` percent of `Y`, leaving `Y` unchanged
    - `Delta %`: percent change from `Y` to `X`, leaving `Y` unchanged
    - `GCD`: greatest common divisor of `X` and `Y`
    - `LCM`: lowest common multiple of `X` and `Y`
    - `PRIM`: determine if `X` is a prime, returning 1 if prime, 0 otherwise
    - `ABS`: absolute value of `X`
    - `SIGN`: return -1, 0, 1 depending on whether `X` is less than, equal, or
      greater than 0, respectively
    - `MIN`: minimum of `X` and `Y`
    - `MAX`: maximum of `X` and `Y`
    - `IP`: integer part of `X`, truncating towards 0, preserving sign
    - `FP`: fractional part of `X`, preserving sign
    - `FLR`: the floor of `X`, the largest integer <= `X`
    - `CEIL`: the ceiling of `X`, the smallest integer >= `X`
    - `NEAR`: the nearest integer to `X`
- `PROB`
    - `COMB`: combination `C(n,r)` = `C(Y, X)`
    - `PERM`: permutation `P(n,r)` = `P(Y, X)`
    - `N!`: factorial of `X`
    - `RAND`: random number in the range `[0,1)`
    - `SEED`: set the random number generator seed to `X`
- `CONV`
    - `>DEG`: convert radians to degrees
    - `>RAD`: convert degrees to radians
    - `P>R`: polar to rectangular
        - input (`Y`, `X`) = `r`, `theta`
        - output (`Y`, `X`) = `x`, `y`
    - `R>P`: rectangular to polar
        - input (`Y`, `X`) = (`x`, `y`)
        - output (`Y`, `X`) = (`r`, `theta`)
    - `>HR`: convert `hh.mmssnnnn` to `hh.mmmm`
    - `>HMS`: convert `hh.mmmm` to `hh.mmssnnnn`
- `HELP`: display the help pages
    - use arrow keys to go back and forth
- `MODE`
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
- `HYP`
    - `SINH`: hyperbolic `sin()`
    - `COSH`: hyperbolic `cos()`
    - `TANH`: hyperbolic `tan()`
    - `ASNH`: hyperbolic `asin()`
    - `ACSH`: hyperbolic `acos()`
    - `ATNH`: hyperbolic `atan()`
- `UNIT`
    - `>C`: Fahrenheit to Celsius
    - `>F`: Celsius to Fahrenheit
    - `>hPa`: hecto Pascal (i.e. millibar) to inch Mercury
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
- `BASE`
    - `DEC`: use decimal base 10, set base indicator to `DEC`
    - `HEX`: use hexadecimal base 16, set base indicator to `HEX`
        - display all register values as 32-bit unsigned integer
    - `OCT`: use octal base 8, set base indicator to `OCT`
        - display all register values as 32-bit unsigned integer
    - `BIN`: use binary base 2, set base indicator to `BIN`
        - display all register values as 32-bit unsigned integer
        - max of 13 digits
    - `AND`: binary (`X` `and` `Y`) as 32-bit unsigned integers
    - `OR`: binary (`X` `or` `Y`) as 32-bit unsigned integers
    - `XOR`: binary (`X` `xor` `Y`) as 32-bit unsigned integers
    - `NOT`: binary 1's complement of `X`, as 32-bit unsigned integer
    - `NEG`: binary 2's complement of `X`, as 32-bit unsigned integer

<a name="FutureEnhancements"></a>
## Future Enhancements

There are a number of features which I would like to add in the future. I have
grouped them as follows:

<a name="NearFuture"></a>
### Near Future

- bit shift and rotation operators
    - shift left
    - shift right
    - rotate left
    - rotate right
    - arithmetic shift right (preserve sign bit)
- user-accessible registers
    - Most HP calculators provide user-accessible registers identified by a
      number. For example `STO 00` stores the current `X` value to Register
      `00`.
    - I hope to add most of these in the near future:
        - `RCL NN`, `STO NN`, `STO+ NN`, `STO- NN`, `STO* NN`, `STO/ NN`
    - The HP-42S supports registers identified by a string. Not sure if this
      feature is worth the effort.
- user selectable integer size for `BASE` functions
    - currently, binary, octal, hexadecimal routines are implemented internally
      using 32-bit unsigned numbers
    - the user ought to be able to specify the integer size for those
      operations: 8 bits, 16 bits, 32 bits, maybe 48 bits and 64 bits
    - the user-interface will be a challenge: for large integer sizes, the
      number of digits will no longer fit inside the 14-15 digits available on a
      single line.
- system memory
    - It might be useful to expose some system status functions, like memory.
    - But since we can always drop into the TI-OS and use `2ND` `MEM` to get
      that information, it is not clear that this is worth the effort.

<a name="MediumFuture"></a>
### Medium Future

- complex numbers
    - The TI-OS provides internal subroutines to handle complex numbers, so in
      theory, this should be relatively easy.
    - I think the difficulty will be the user interface. A complex number
      requires 2 floating point numbers to be entered and displayed, and I have
      not figured out how to do that within the UI of the RPN83P application.
- `STAT` functions
    - There are lot of features that I need to research:
        - average, std deviation, variance
        - linear fitting
        - logarithmic fitting
        - exponential fitting
        - power law fitting
- real time clock
    - I believe the TI-84 Plus has an RTC.
    - It would be interesting to expose some time, date, and timezone features.

<a name="FarFuture"></a>
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
    - Making the user-interface reasonable could be a challenge.
    - I'm not sure that adding matrix functions into a calculator is worth the
      effort. For any non-trivial calculations, it is probably easier to use a
      desktop computer and application (e.g. MATLAB, Octave, Mathematica).

<a name="NotPlanned"></a>
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

<a name="BugsAndLimitations"></a>
## Bugs and Limitations

- `PRIM` (isPrime) is quite slow, about as slow as a TI-BASIC program.
    - Uses the TI-OS floating numbers and subroutines, which works pretty
      well for smallish integers.
    - Can probably make this significantly faster by implementing the algorithm
      using native Z80 integer operations.
    - (Need to write a `div(u32, u16) -> u32` function).
- `PROB` and `COMB` arguments are limited to `< 256`
    - Should be relatively easy to extend this to `< 2^16` or `<2^32`.
- `GCD` and `LCM` functions are slow
    - Could be made significantly faster.
- Too many digits when using `BASE 2`
    - A single line in the RPN83P app can display 14 digits.
    - A 32-bit integer in base 2 requires 32 digits, so the display will often
      overflow when using base 2.