# RPN83P User Guide: Chapter 14: CONV Functions

This document describes the menu functions under the `CONV` menu in RPN83P.

**Version**: 1.1.1 (2025-11-14)\
**Project Home**: https://github.com/bxparks/rpn83p \
**Parent Document**: [USER_GUIDE.md](USER_GUIDE.md)

## Table of Contents

- [CONV Menus](#conv-menus)
- [Degree and Radian](#degree-and-radian)
- [Polar and Rectangular](#polar-and-rectangular)
- [Hours Minutes Seconds (HMS)](#hours-minutes-seconds-hms)
- [HMS Arithmetic](#hms-arithmetic)
- [Alternative to HMS](#alternative-to-hms)

## CONV Menus

The functions under the `CONV` menu folder are related to various angle
conversion routines.

- ![ROOT > CONV](images/menu/root-conv.png) (ROOT > CONV)
    - ![ROOT > CONV > Row1](images/menu/root-conv-1.png)
    - ![ROOT > CONV > Row2](images/menu/root-conv-2.png)

The functions are:

- `>DEG`: convert radians to degrees
- `>RAD`: convert degrees to radians
- `>REC`: polar to rectangular
    - input: `Y`=y, `X`=x
    - output: `Y`=θ, `X`=r
    - (consistent with HP-42S)
- `>POL`: rectangular to polar
    - input: `Y`=θ, `X`=r
    - output: `Y`=y, `X`=x
    - (consistent with HP-42S)
- `>HR`: convert `HH.MMSSssss` to `HH.hhhh`
- `>HMS`: convert `HH.hhhh` to `HH.MMSSssss`
- `HMS+`: add `X` and `Y` assuming HMS format
- `HMS-`: subtract `X` from `Y` assuming HMS format

The `HMS` functions are related to angle conversions because a degree unit can
be subdivided into "minutes" and "seconds" as well. On some calculators, `HMS`
is labeled `DMS` instead. RPM83P follows the convention of HP-42S by using
`HMS`.

## Degree and Radian

The `>DEG` function converts radians into degrees. The `>RAD` converts radians
into degrees.

| **Keys**              | **Display** |
| ----------------      | --------------------- |
| `10` `>RAD`           | ![](images/conv/deg-rad-1.png) |
| `>DEG`                | ![](images/conv/deg-rad-2.png) |

## Polar and Rectangular

The `>REC` and `>POL` functions convert between rectangular (x,y) and polar
(r,θ) representations of a coordinate in 2 dimensions.

The `>POL` function converts from rectangular to polar, with the `X` and `Y`
registers containing the `x` and `y` coordinates. Therefore, the coordinates
must be entered in reverse. For example, let's convert (3,4) into polar
coordinates:

| **Keys**                  | **Display** |
| ----------------          | --------------------- |
| `MODE` `DEG`              | ![](images/conv/to-pol-1.png) |
| `ON/EXIT` `4` `ENTER` `3` | ![](images/conv/to-pol-2.png) |
| `>POL`                    | ![](images/conv/to-pol-3.png) |

The `X` and `Y` registers are replaced with the polar (r,θ) values so that `Y=θ`
and `X=r`. The value of the angle θ depends on the TRIG mode. Since we are in
`DEG` mode, θ=53.13010235° and r=5. In `RAD` mode, the angle would be
0.927295218.

The `>REC` function converts from polar to rectangular, with `X=r` and `Y=θ`.
Therefore, the coordinates must be entered in opposite order of their usual
written form (r,θ). For example, let's convert (1, 30°) into rectangular
coordinates:

| **Keys**                  | **Display** |
| ----------------          | --------------------- |
| `MODE` `DEG`              | ![](images/conv/to-rec-1.png) |
| `ON/EXIT` `30` `ENTER` `1`| ![](images/conv/to-rec-2.png) |
| `>REC`                    | ![](images/conv/to-rec-3.png) |

## Hours Minutes Seconds (HMS)

One hour is divided into 60 minutes, and one minute is divided into 60 seconds.
Similarly for one degree angle.

The `>HR` function converts an HMS value in the form of `HH.MMSS` to decimal
hours in the form of `HH.hhhh`. For example, to convert 1h14m20s to decimal
hours:

| **Keys**              | **Display** |
| ----------------      | --------------------- |
| `1.1420` `>HR`        | ![](images/conv/to-hr1-1.png) |

Any digit after the 4th fractional decimal place is interpreted as fractional
seconds. For example, converting 1h14m20.5s to decimal hours, we get

| **Keys**              | **Display** |
| ----------------      | --------------------- |
| `1.14205` `>HR`       | ![](images/conv/to-hr2-1.png) |

The difference is 0.5s/3600s or 1.38888888e-4 hours.

The `>HMS` function converts decimal hours into HMS format. For example, convert
1.52 hours into HMS format:

| **Keys**              | **Display** |
| ----------------      | --------------------- |
| `1.52` `>HMS`         | ![](images/conv/to-hms-1.png) |

The value of 1.3112 means 1h31m12s.

## HMS Arithmetic

Sometimes we want to directly add and subtract numbers formatted as HMS,
without having to convert them to decimal numbers. For example, let's add and
subtract the following HMS numbers:

- \+ 5h3m14s
- \+ 2h39m
- \- 1h58s

| **Keys**              | **Display** |
| ----------------      | --------------------- |
| `5.0314` `ENTER`      | ![](images/conv/hms-add-sub-1.png) |
| `2.39`  `HMS+`        | ![](images/conv/hms-add-sub-2.png) |
| `1.0058` `HMS-`       | ![](images/conv/hms-add-sub-3.png) |

The final result is 6h41m16s.

## Alternative to HMS

Another way to perform time and date related calculations is to use the `DATE`
menu functions. In particular, the Duration object and its menu functions
under `DATE > DR` are comparable to the HMS functions.

One advantage of using a Duration object is that it cannot be accidentally
interpreted as a normal floating point number. A Duration object of 1h31m12s
will always appear as `DR{0,1,31,12}` or `1m31m12s` and cannot be comingled with
normal numbers unless explicitly converted.

In contrast, when we see a number such as `1.3112`, we cannot be sure whether
that means 1h31m12s or 1.3112 hours.

The HMS does have one advantage over a Duration object: the HMS format can
handle fractional seconds. The Duration object (and all DATE functions) can
handle only whole number of seconds.
