# Developer Notes

Notes for the developers of the RPN83P app, likely myself in 6 months when I
cannot remember how the code works.

**Version**: 0.9.0-dev (2024-01-05)

**Project Home**: https://github.com/bxparks/rpn83p

## Table of Contents

- [Debug Statements](#debug-statements)
- [DRAW Mode](#draw-mode)
- [PRIM Prime Factor](#prim-prime-factor)
    - [Prime Factor Algorithm](#prime-factor-algorithm)
    - [Prime Factor Improvements](#prime-factor-improvements)
- [TVM Algorithms](#tvm-algorithms)
- [Complex Numbers](#complex-numbers)
    - [Complex Number Font](#complex-number-font)
    - [Complex Number Rendering](#complex-number-rendering)
- [Design Guidelines](#design-guidelines)
    - [Discoverable](#discoverable)
    - [Easy to Use](#easy-to-use)
    - [Practical](#practical)
    - [Customizable](#customizable)

## Debug Statements

Debugging a TI calculator app written in Z80 assembly language is a royal pain
in the neck. Maybe there exist Z80 debuggers that are useful, but I don't know
how to use any of them. The `debug.asm` file contains a number of routines that
I have incrementally added to help me debug this app.

They are normally excluded from the binary. They are included only when the
`DEBUG` macro is defined with the `-DDEBUG` flag like this in the `Makefile`:

```
$(SPASM) -DDEBUG -I $(SPASM_INC) -N rpn83p.asm $@
```

Currently, all debug routines are placed in Flash Page 1, but they could easily
be moved to another Flash Page if needed. The routines are placed in the branch
table in `rpn83p.asm`, and all of them start with the prefix `_Debug`:

- `_DebugInputBuf`
- `_DebugParseBuf`
- `_DebugString`
- `_DebugPString`
- `_DebugClear`
- `_DebugOP1`
- `_DebugEEPos`
- `_DebugUnsignedA`
- `_DebugSignedA`
- `_DebugFlags`
- `_DebugU32AsHex`
- `_DebugHLAsHex`
- `_DebugPause`
- `_DebugU32DEAsHex`

They are called with the usual `bcall()` convention like
`bcall(_DebugUnsignedA)`. Most of these debugging functions write to the empty
line on the LCD, just below the top Status line. That line is purposely left
unused in the RPN83P app, for the explicit goal of allowing these debug routines
to print to that line without interfering with the normal operation of the app.

These debug statements are intended to have no side effects so that they can be
inserted into most places in the application code, without affecting the logic
of the code being debugged. They should save all modified registers (including
the accumulator A and the flags with the `AF` register), save the display cursor
variables `CurRow` and `CurCol`, and restore these variables at the end of the
routine. It is probably a bug if any of these routines cause side effects,
because that means that adding a debug statement would cause the normal flow of
the application code to change.

## DRAW Mode

The secret `DRAW` modes are activated by the `2ND DRAW` command. It prompts the
user for a number, like the `FIX` or `STO` command. Currently 4 modes defined:

- 0 (drawModeNormal): Normal rendering, this is the default.
- 1 (drawModeTvmSolverI): Single step through the `I%YR` TVM Solver
  calculations, and show the iteration counter (`tvmSolverCount`), and the
  internal interest rate variables (`tvmI0`, `tvmI1`) in place of the RPN stack
  variables (T,Z,Y,X). The program waits for a key before executing the next
  iteration.
- 2 (drawModeTvmSolverF): Same as (1), except show the values of the function
  whose roots we are trying to solve at `tvmI0` and `tvmI1`, in other words,
  show the variables `tvmNPMT0` and `tvmNPMT1`.
- 3 (drawModeInputBuf): Show the `inputBuf` (the edit buffer when entering
  digits) in the Debug line just below the Status line. The `X` register is now
  always shown, instead of being overwritten by the `inputBuf` in Edit mode.
  This helps debugging the complex interaction between the input buffer and the
  X register.

Any other value is treated to be the same as 0 (drawModeNormal).

## PRIM Prime Factor

### Prime Factor Algorithm

The [USER_GUIDE.md#prime-factors](USER_GUIDE.md#prime-factors) section explains
how to use the `PRIM` menu function to successively calculate all the prime
factors of an integer `N` from `[0, 2^32)`. The largest prime less than 2^16 is
`65521`. Therefore the longest time that `PRIM` can spend is the factorization
of `65521*65521=4 293 001 441`. On a TI-84 Plus, that calculation takes 33
seconds (at 6 MHz) and 13 seconds (at 15 MHz).

Here are some notes about how the `PRIM` algorithm works:

- The basics of the algorithm is to test all the candidate prime factors from 2
  to `sqrt(N)`.
- We could simply start at 3 and increment by 2 to test every odd number to
  `sqrt(N)`. But we can do slightly better. All prime numbers `>=5` are of the
  form `6k-1` and `6k+1`. So each iteration can increment by 6, but perform 2
  checks. This effectively means that we step by 3 through the candidate prime
  factors, instead of just by 2 (for all odd numbers),  which makes the loop 50%
  faster.
- We use integer operations instead of TI-OS floating point ops. If I recall,
  this makes it about 2-3X faster (floating point ops in TI-OS are surprisingly
  fast).
- Z80 does not support integer division operations in hardware, so we have to
  write our own in software. The integer size of `N` is limited to 32 bits, so
  we need to write a `div(u32, u32)` routine.
- But the loop only needs to go up to `sqrt(N)`, so we actually only need a
  `div(u32, u16)` routine, which if I recall is about 2X faster. This is because
  the bit-wise loop is reduced by 2X, but also because the dividend can be
  stored in a 16-bit Z80 register, instead of stored in 4 bytes of RAM.
- Finally, we actually don't need a full `div()` operation for the `PRIM`
  function. We don't need the quotient, we need only the remainder. So we
  implement a custom `mod(u32, u16)` function which is about 25% faster than the
  full `div(u32, u16)` function.

I think there are additional micro-optimizations left on the table that could
make the `PRIM` function maybe 1.5X to 2X faster, without resorting to a
completely different algorithm. But I suspect that the resulting code would be
difficult to understand and maintain. So I decided to stop here.

### Prime Factor Improvements

For completeness, here are some improvements that could be made in the prime
factoring algorithm:

1. The `PRIM` function currently returns only the smallest prime factor. It must
   be manually called repeatedly to get additional prime factors. But each time
   it is called, the search for the next prime factor restarts at 2 and loops to
   sqrt(N).

   This is inefficient because the search should have started at the *last*
   prime factor, since all candidates smaller than that number have already been
   tested. We could implement another function (maybe call it`PRFS`) that
   returned *all* prime factors of a number `N` . It could be more efficient
   by restarting the loop at the previous prime factor. However, this new
   function would need support for vectors or arrays so that it can return
   multiple numbers as the result. Vectors or arrays are not currently (v0.8.0)
   supported.
1. The [Prime Number
   Theorem](https://en.wikipedia.org/wiki/Prime_number_theorem) tells us that
   the number of prime numbers less than `n` is roughly `n/ln(n)`. Since we
   restrict our input to the `PRIM` function to 32-bit unsigned integers, the
   largest prime factor that we need to consider is `sqrt(2^32)` or `2^16`. That
   means that the number of candidate prime factors that we need to consider is
   roughly `65536/ln(65535)` or about `5909`. According to the [Prime Counting
   Function](https://www.dcode.fr/prime-number-pi-count), the actual number is
   `6542`. (Apparently, the `n/ln(n)` expression *underestimates* the actual
   number of primes).

   We could pre-calculate those 6542 prime numbers into a table, consuming 13084
   bytes (using 16-bit integers), which is less than one flash page (16 kiB) of
   a TI calculator. The `PRIM` function would need to iterate only 6542 times
   through this table. In comparison, the current algorithm effectively
   increments through the candidates by 3, up to `2^16`, so about 21845
   iterations. The lookup table method would be 3.3X faster, but would increase
   the app flash memory size by at least 13084 bytes (most likely another flash
   page, so 16 kiB).

   I'm not sure if the increase in flash size is worth it, but the `PRIM`
   function could be made blindingly fast, finishing the toughest prime factor
   problem (of less than `2^32`) in about 4 seconds (13.0/3.3) on a TI-84+
   calculator.

## TVM Algorithms

See [TVM Algorithms](TVM.md).

## Complex Numbers

### Complex Number Font

The screen size of a TI-83 and TI-84 calculator is 96 pixels wide, which is
enough to hold 16 characters using the Large Font. But a complex number needs 2
floating point numbers, with at least one delimiter character between the 2
numbers, which gives us only 7 characters per number. In scientific notation, we
lose up to 6 characters due to the overhead of the format (decimal point, the
optional minus sign on the mantissa, the `E` symbol, the optional minus sign on
the exponent, and up to 2 digits for the exponent). That means that we would be
able to print only a single significant digit for certain numbers like
`-1.E-23`. This is not reasonable.

We could use 2 lines to display a single complex number, but that means we would
see only 2 registers (`X` and `Y`) of the RPN stack instead of 4. That also did
not seem reasonable. The most workable solution was to use the Small Font of
the TI-OS. The Small Font is a proportional font, but most digits and symbols
needed for printing numbers are 4 pixels wide, which gives us 24 characters.
Taking account of overhead, each floating component can consume up 10
characters when a complex number is printed on a single line.

### Complex Number Rendering

The Large Font is a monospaced font where each character fits inside an 6x8
(hxw) grid. The Small Font is a proportional font where most digits and letters
fit into a 4x7 grid, but some characters (e.g. '.' and ' ') take up less width.

Since a complex number is rendered using the Small Font, the app must take
special precautions to prevent artifacts from the previously rendered number in
the Large Font from showing through the Small Font. The easiest way to do that
is to erase the line before printing the complex number in Small Font.
Unfortunately, if the erase algorithm is applied naively, it causes unnecessary
flickering of the display when numbers are updated. A significant amount of
complexity was added to the rendering code (`display.asm`) to keep the
flickering to a minimum. For example, when a Large Font is rendered over a Small
Font, or when a Small Font line is written over a previous Small Font line, no
erasure is required. The bookkeeping algorithm was made more complex due to the
rendering of the `argBuf` (the input buffer used for command arguments in `STO`,
`FIX`, etc) which uses the Large Font, over the same line as the `X` register.

Developers who dig into the rendering code may wonder why all that complexity
exists. Ironically, it's all there so that the vast majority end-users will
never notice anything.

## Design Guidelines

In this section, I hope to explain some of my design guidelines which determine
how and why I have implemented certain features of the app in certain ways.

### Discoverable

A modern scientific calculator has hundreds (if not thousands) of built-in
functions. I hope to make almost all functions of the RPN83P app easily
discoverable.

A consistent, well-organized, hierarchical menu system (inspired by the HP-42S)
should help. The RPN83P app hijacks the TI-83 and 84 keyboards for its purpose.
Functions which normally would fit better as a direct button or shifted-button
(`2ND`) have to go into the menu system.

RPN83P will not use numerical configuration flags to customize its behavior.
Every calculator with system flags has its unique set of options. Even for
options which overlap, they are assigned to different numerical flags. For
people who use multiple calculators, it is impossible to remember what all those
options do, and which feature corresponds to which flag number. On older
calculators, itis even difficult to remember how to set or clear these flags, or
whether the flag is a single digit, 2 digits, or 3 digits. RPN83P will expose
all system configuration options through the menu system.

### Easy to Use

RPN83P should be as easy to use as possible. This includes reducing the number
of keystrokes as reasonable as possible.

It may be a personal preference, but I believe that the traditional RPN system
from older HP calculators are easier to use than the modern RPL calculators
(introduced with the HP-28S series, and continuing through the HP-48/49/50
series.) Consistency with the traditional RPN calculators seems important to
achieve ease of use. For example, even though it is actually be slightly easier
to implement an RPN entry system that separates the input buffer from the `X`
register (like RPL systems do), the RPN83P goes out of its to mimic the behavior
of the traditional RPN calculators.

### Practical

The feature set of most calculators seems to be determined by market
segmentation. For example, there are separate calculators for the business
market, the scientific market, the educational market, the computer science
field (e.g. the HP-16C), and so on. I want RPN83P to provide useful features
without any regard to market segmentation. Therefore, it has features related to
business (TVM), features related to computer science (BASE), features related to
engineering (complex numbers), features related to data analysis (STAT), and so
on.

### Customizable

Users will use the calculator in different ways, and some people may use certain
functions more frequently than other functions. It seems important to allow
users to make custom key-bindings for certain functions to help the ease of use.

RPN83P does not currently support custom key bindings, but it seems important to
include that in the future.
