# Developer Notes

Notes for the developers of the RPN83P app, likely myself in 6 months when I
cannot remember how the code works.

**Version**: 0.12.0 (2024-06-24)

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
    - [Complex Delimiters](#complex-delimiters)
- [BASE Menu](#base-menu)
- [Design Guidelines](#design-guidelines)
    - [No Keyboard Overlay](#no-keyboard-overlay)
    - [Utilize TI-OS](#utilize-ti-os)
    - [Flash App](#flash-app)
    - [Traditional RPN System](#traditional-rpn-system)
    - [Hierarchical Menu](#hierarchical-menu)
    - [No System Flags](#no-system-flags)
    - [Includes Useful Features](#includes-useful-features)
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
user for a number, like the `FIX` or `STO` command. Currently 3 modes defined:

- 0 (drawModeNormal): Normal rendering, this is the default.
- 1 (drawModeInputBuf): Show the `inputBuf` (the edit buffer when entering
  digits) in the Debug line just below the Status line. The `X` register is now
  always shown, instead of being overwritten by the `inputBuf` in Edit mode.
  This helps debugging the complex interaction between the input buffer and the
  X register.
- 2 (drawModeTvmSolver): Single step through the `I%YR` TVM Solver calculations,
  waiting for a key before executing the next iteration. Show the following
  parameters:
    - iteration counter (`tvmSolverCount`)
    - internal interest rate variables `tvmI0` and `tvmI1`
    - the `NPMT(i, N)` function evaluated at `tvmI0` and `tvmI1`

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
- In v0.10, the inner loop of the `mod(u32,u16)` function was made 40-50% faster
  through the `modHLSPByBC()` function using the following observations:
    - The Z80 has only 16-bit registers, so the `u32` type must typically be
      stored in 4 bytes of RAM, and the `u32` operations must work against the 4
      bytes of RAM.
    - If the `mod(u32, u16)` function could be written to use only the CPU
      registers, it could be lot faster. But my attempts to rewrite the function
      were unsuccessful because the Z80 do not have enough registers. (Attempts
      to use the `IX` register were not successful because of some peculiar lack
      of certain instructions involving the `IX` register in the Z80 instruction
      set.)
    - However I discovered that I could get half of what I wanted: storing half
      of the `u32` in a register, and the other half in the stack, and using the
      `ex (sp), hl` instruction of the Z80 to swap the 2 halves back and forth.
      This made the `mod(u32,u16)` function about 40-50% faster compared to
      v0.9.0.
- In v0.13.0-dev, the inner loop `mod(u32,u16)` became another ~42% faster:
    - discovered that the Z80 supports `add ix, ix` instruction
    - replacing `ex (sp), hl; add hl, hl` combo with `add ix, ix`: ~29% faster
    - replacing `rl e; rl d` combo with `adc hl, hl`: ~4% faster
    - deleting an unnecessary `or a` instruction: ~5% faster
    - rearranging some code to eliminate a branch in the common case, and
      selecting `jr` or `jp` judiciously: 1-2% faster
- In v1.0.0, the `mod(u32,u16)` became another 140-160% (i.e. 2.4X to 2.6X)
  faster, based on the ideas from [this Cemetech
  thread](https://www.cemetech.net/forum/viewtopic.php?t=19790):
    - initial benchmark: 20.5 s
    - chunking using 8-bit registers, instead of shifting the entire 32-bit
      dividend: 18% faster
    - using DEIX instead of HLIX, eliminating a bunch of 'ex de, hl': 12% faster
    - using a nonrestoring division: 9-13% faster
    - using register A instead of register D for each 8-bit chunk: 5% faster
    - unrolling the 8-bit division loop eight times: 11-15% faster
    - end result: 11.8 s or 74% faster, i.e. 1.74X faster
    - total improvement from v0.12: 2.4X (83+/84+) to 2.6X (Nspire) faster

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
   multiple numbers as the result. Vectors or arrays are not supported.
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

   As far as I know, using a precalculated table of prime numbers would be the
   fastest algorithm, and no further improvements can be made. That means that
   the toughest prime factor problem (factorizing `65521*65521`) could be done
   in about 2.9s (9.5/3.3) on a TI-84+ calculator. However, I don't think the
   difference between 9.5s and 2.9s is worth the extra 16kiB of flash memory.

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

### Complex Delimiters

Internally, the complex delimiter is stored in the `inputBuf` as a single byte.
The following three characters are used:

- `LimagI`: rectangular, when `2ND i` is pressed
- `Ldegree`: polar deg, when `2ND ANGLE` is pressed
- `Langle`: polar rad, when `2ND ANGLE 2ND ANGLE` is pressed

(See `isComplexDelimiter()` routine.) Using a single byte for the delimiter
makes the complex number parsing code simpler.

When the `2ND i` or `2ND ANGLE` key is pressed, the delimiter is overwritten or
toggled between polar-rad and polar-deg modes. The function that perform that
conversion is `SetComplexDelimiter()`.

When the string inside `inputBuf` is rendered (after each press of a digit for
example), the complex delimiter is converted into the following character before
shown on the screen (see `formatInputBuf()`):

- `LimagI`: `LimagI`
- `Ldegree`: `Langle` `Ltemp` (`Ltemp` looks better than `Ldegree`)
- `Langle`: `Langle`

## BASE Menu

Here are some notes about why I implemented the `BASE` menu in the way it is,
(captured from [my post on
MoHPC](https://www.hpmuseum.org/forum/thread-20867-post-187258.html#pid187258):

- There are no dedicated keys on the 83+/84+ related to BASE functions, so I
  have to place all of them under the BASE soft menu.
- The BASE menu folder has too many functions, 8 rows, which can be hard to
  navigate.
    - But a flat hierarchy seemed preferable to nested subfolders which can be
      even more annoying to navigate.
- The A-F digits for HEX numbers require the use of the ALPHA shift key, because
  there isn't any way to expose them through unshifted keys.
    - The 83+/84+ has only 5 buttons across for the soft menu, so it didn't make
      sense to expose only 5 out of 6 HEX digits through the soft menu buttons
      either.
- The integer word size (WSIZ) can only be 8, 16, 24, 32 bits, instead of an
  arbitrary integer between 1 and 64 bits like the 16C.
    - It's probably technically possible to extend RPN83P to support 64 bits,
      but that would require a substantial amount of work.
- There is no support for *signed* integer types in the BASE functions of
  RPN83P.
    - This would not be difficult to add with regards to complexity, but it
      would require a lot of grunt work: All of those extended bitwise and
      integer arithmetic routines would need to be written by hand, since the
      Z80 does not have hardware support for most of them beyond 8 or 16 bits.

## Design Guidelines

In this section, I hope to explain the reasons why I implemented certain
features of the app in certain ways.

### No Keyboard Overlay

TI-83 Plus and TI-84 Plus has buttons which are mostly compatible with an RPN
calculator. In particular, it has an `ENTER` key and a separate `(-)` key which
can act as the `+/-` function. Most other functions can be mapped to something
close enough, like the `MATH` key which can act as the menu `HOME` function.

For something like RPN83P which is expected to be used by only a handful of
users, it did not seem worthwhile to spend any effort creating an overlay. Which
is a little bit ironic because the TI-84 Plus calculator actually has a
removable keyboard faceplate. Different faceplates are available in different
colors. I don't have a 3D printer so I don't know if it's possible to create a
custom faceplate. An injection molding faceplate would be far too expensive.

### Utilize TI-OS

The underlying TI-OS provides an enormous amount of mathematical, numerical, and
formatting functions. To save development time and maintenance costs, RPN83P
will use as much of the TI-OS routines as practical.

### Flash App

There are 2 types of assembly programs possible on these TI calculators: 1)
assembly programs which reside in RAM, and, 2) flash applications which reside
in non-volatile flash memory. Flash applications are far more convenient and
robust because they do not have an arbitrarily 8kB limit in size, and they are
retained when the calculator crashes or loses battery power. RPN83P will be a
flash application.

### Traditional RPN System

It may be a personal preference, but I believe that the traditional RPN system
from older HP calculators are easier to use than the modern RPL calculators
(introduced with the HP-28S series, and continuing through the HP-48/49/50
series.) Consistency with the traditional RPN calculators seems important for
ease of use. For example, even though it is actually slightly easier to
implement an RPN entry system that separates the input buffer from the `X`
register (like RPL systems do), the RPN83P goes out of its way to mimic the
behavior of the traditional RPN calculators.

### Hierarchical Menu

Of the menu systems that I have seen on various calculators, the hierarchical
menu system with soft keys used by the HP-42S seems to be the easiest to use.
All RPN83P features will be accessible through direct key buttons or the menu
systems. I want to avoid secret key sequences which are hard to discover and
remember for end-users.

### No System Flags

RPN83P will not use system flags to customize its behavior. Every calculator
with system flags has its unique set of options. Even for options which overlap,
they are assigned to different numerical flags. For people who use multiple
calculators, it is impossible to remember what all those options do, and which
feature corresponds to which flag number. On older calculators, it is even
difficult to remember how to set or clear these flags, or whether the flag is a
single digit, 2 digits, or 3 digits. RPN83P will expose all system configuration
options through the menu system.

User flags, on the other hand, may be provided in the future if or when
keystroke programming is added. They are definitely useful in calculator
programs.

### Includes Useful Features

The RPN83P app has no need to segment the features of RPN83P to different market
segments (e.g. business, scientific, graphing, computer science). I added
features to RPN83P because they are useful, interesting, and are reasonable to
implement within the constraints of the hardware, the TI-OS, and the Z80
assembly language programming.

### Customizable

Custom key bindings are not supported right now (v0.9), but it seems important
to add that in the future. Users will use the calculator in different ways, and
some people may use some functions more frequently than others.
