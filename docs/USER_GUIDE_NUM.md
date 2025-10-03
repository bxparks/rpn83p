# RPN83P User Guide: Numerical Functions

This document describes the menu functions under the `NUM` menu in RPN83P.

**Version**: 1.0.0 (2024-07-19)\
**Project Home**: https://github.com/bxparks/rpn83p\
**Parent Document**: [USER_GUIDE.md](USER_GUIDE.md)

## Table of Contents

- [NUM Functions](#num-functions)
- [Percent](#percent)
- [Percent Change](#percent-change)
- [Prime Factors](#prime-factors)
- [Rounding](#rounding)

## NUM Functions

The functions under the `NUM` menu folder are numerical functions which don't
quite fit into one of the other major categories:

- ![ROOT > NUM](images/menu/root-num.png)
    - ![ROOT > NUM > Row1](images/menu/root-num-1.png)
    - ![ROOT > NUM > Row2](images/menu/root-num-2.png)
    - ![ROOT > NUM > Row3](images/menu/root-num-3.png)
    - ![ROOT > NUM > Row4](images/menu/root-num-4.png)

The functions are:

- `%`: `X` percent of `Y`, leaving `Y` unchanged
- `%CH`: percent change from `Y` to `X`, leaving `Y` unchanged
- `GCD`: greatest common divisor of `X` and `Y`
- `LCM`: lowest common multiple of `X` and `Y`
- `PRIM`: prime factor of `X`
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
- `RNDF`: round to `FIX/SCI/ENG` digits after the decimal point
- `RNDN`: round to user-specified `n` digits (0-9) after the decimal point
- `RNDG`: round to remove guard digits, leaving 10 mantissa digits

I hope that most of these are self-explanatory. The names roughly follow the
convention used by the HP-42S or other HP calculators, and their placement in
the `NUM` menu folder follows the organization of the TI-OS on the TI-83+/84+
themselves where many of these are placed under the `NUM` menu.

Below are some expanded comments on a few features under the `NUM` menu folder.

## Percent

The `%` function calculates the `X` percent of `Y`, consuming `X` and leaving
the `Y` unchanged. In other words:

```
    Y := Y
    X := Y*X/100
```

**Example:**

Calculate the total price of an item listed as $125 with an 8.625% sales tax:

| **Keys**              | **Display** |
| ----------------      | --------------------- |
| `NUM`                 | ![](images/num/percent-1.png) |
| `125` `ENTER`         | ![](images/num/percent-2.png) |
| `8.625` `%`           | ![](images/num/percent-3.png) |
| `+`                   | ![](images/num/percent-4.png) |

## Percent Change

The `%CH` function calculates the percent change from `Y` to `X`, leaving `Y`
unchanged:

```
    Y := Y
    X := 100*(X-Y)/Y
```

## Prime Factors

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

For example, let's find the prime factors of `2_122_438_477 = 53 * 4001 *
10009`:

| **Keys**              | **Display** |
| ----------------      | --------------------- |
| `NUM`                 | ![](images/num/prime-1.png) |
| `2122438477`          | ![](images/num/prime-2.png) |
|  `PRIM`               | ![](images/num/prime-3.png) |
| `/`                   | ![](images/num/prime-4.png) |
| `PRIM`                | ![](images/num/prime-5.png) |
| `/`                   | ![](images/num/prime-6.png) |
| `PRIM`                | ![](images/num/prime-7.png) |

For computational efficiency, `PRIM` supports only integers between `2` and
`2^32-1` (4 294 967 295). This allows `PRIM` to use integer arithmetic, making
it about 25X faster than the equivalent algorithm using floating point routines.
Any number outside of this range produces an `Err: Domain` message. (The number
`1` is not considered a prime number.)

If the input number is a very large prime, the calculation may take a long time.
The number that takes the longest time is `65521*65521` = `4_293_001_441`,
because 65521 is the largest prime less than `2^16=65536`. Here are the running
times of the `PRIM` function for this number for various TI models that I own:

| **Model**                     | **PRIM Running Time** |
| ---                           | ---                   |
| TI-83+ (6 MHz)                | 8.3 s                 |
| TI-83+SE (15 MHz)             | 3.2 s                 |
| TI-84+SE (15 MHz)             | 3.9 s                 |
| TI-Nspire w/ TI-84+ keypad    | 3.0 s                 |

During the calculation, the "run indicator" on the upper-right corner will be
active. You can press the `ON` key to break from the `PRIM` loop with an `Err:
Break` message.

## Rounding

There are 3 rounding functions under the `ROOT > NUM` menu folder that provide
access to the corresponding rounding functions implemented by the underlying
TI-OS:

- `RNDF`
    - rounds to the number of digits after the decimal point specified by the
      current `FIX/SCI/ENG` mode
    - for example, `FIX4` is rounded to 4 digits after the decimal point
    - for `FIX-`, no rounding is performed
- `RNDN`
    - rounds to the user-specified `n` digits (0-9) after the decimal point
    - `n` is given in the argument of the `RNDN` command which displays a `ROUND
      _` prompt
- `RNDG`
    - rounds to remove the guard digits, leaving 10 mantissa digits
    - the location of the decimal point has no effect
    - useful for a number which looks like an integer but is internally a
      floating point number with rounding errors hidden in the guard digits.
      Applying the `RNDG` function forces the floating point number to become an
      integer.

Here are examples of how the value `1000*PI = 3141.5926535898` becomes rounded
using the various functions.

**RNDF**

Round to the number of digits specified by the current `FIX/SCI/ENG` mode:

| **Keys**              | **Display** |
| ----------------      | --------------------- |
| `PI` `1000` `*`       | ![](images/num/rounding-01.png) |
| `MODE` `FIX 04`       | ![](images/num/rounding-02.png) |
| `MATH` `NUM` `RNDF`   | ![](images/num/rounding-03.png) |
| `2ND ENTRY` (SHOW)    | ![](images/num/rounding-04.png) |

**RNDN**

Round to the number of digits specified by the user:

| **Keys**              | **Display** |
| ----------------      | --------------------- |
| `PI` `1000` `*`       | ![](images/num/rounding-05.png) |
| `MODE` `FIX 04`       | ![](images/num/rounding-06.png) |
| `MATH` `NUM` `RNDN 2` | ![](images/num/rounding-07.png) |
| `2ND ENTRY` (SHOW)    | ![](images/num/rounding-08.png) |

**RNDG**

Round to remove the hidden guard digits:

| **Keys**              | **Display** |
| ----------------      | --------------------- |
| `PI` `1000` `*`       | ![](images/num/rounding-09.png) |
| `MODE` `FIX 04`       | ![](images/num/rounding-10.png) |
| `MATH` `NUM` `RNDG`   | ![](images/num/rounding-11.png) |
| `2ND ENTRY` (SHOW)    | ![](images/num/rounding-12.png) |
