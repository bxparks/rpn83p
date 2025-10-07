# RPN83P User Guide: Chapter 5: MODE Functions

This document describes the menu functions under the `MODE` menu in RPN83P.

**Version**: 1.0.0 (2024-07-19)\
**Project Home**: https://github.com/bxparks/rpn83p \
**Parent Document**: [USER_GUIDE.md](USER_GUIDE.md)

## Table of Contents

- [MODE Menu](#mode-menu)
- [Floating Point Display Modes](#floating-point-display-modes)
- [Trigonometric Modes](#trigonometric-modes)
- [Complex Result and Display Modes](#complex-result-and-display-modes)
- [Register and Stack Sizes](#register-and-stack-sizes)
- [Comma-EE Button Mode](#comma-ee-button-mode)
- [Raw Versus String Format](#raw-versus-string-format)

## MODE Menu

The `MODE` menu folder contains a number of menu items which control the
operating modes or the display modes of the calculator.

- ![ROOT > MODE](images/menu/root-mode.png)
    - ![ROOT > MODE > Row1](images/menu/root-mode-1.png)
    - ![ROOT > MODE > Row2](images/menu/root-mode-2.png)
    - ![ROOT > MODE > Row3](images/menu/root-mode-3.png)
    - ![ROOT > MODE > Row4](images/menu/root-mode-4.png)

The quickest way to reach this menu folder is to use the `MODE` button on the
keypad, instead of navigating the menu hierarchy. Using the `MODE` button allows
the [Menu Shortcut Jump Back](#menu-shortcut-jump-back) feature to work, so that
pressing `ON/EXIT` takes you right back to the menu before the `MODE` button was
pressed.

## Floating Point Display Modes

The RPN83P app provides access to the same floating point display modes as the
original TI-OS. For reference, here are the options available in the TI-OS when
the `MODE` button is pressed:

![TI-OS Display Modes](images/mode/tios-display-modes.png)

In RPN83P, the `MODE` button presents a menu bar instead:

![RPN83P Display Modes](images/mode/rpn83p-display-modes.png)

**HP-42S Compatibility Note**: The HP-42S uses the `DISP` button to access this
functionality. For the RPN83P, it seemed to make more sense to the follow the
TI-OS convention which places the floating display modes under the `MODE`
button.

The `NORMAL` mode in TI-OS is named `FIX` in RPN83P following the lead of the
HP-42S. It is also short enough to fit into the menu label nicely, and has the
same number of letters as the `SCI` and `ENG` modes which helps with the
top-line indicator.

Suppose the RPN stack has the following numbers:

![RPN83P Display Modes](images/mode/display-mode-start.png)

Let's see how these numbers are displayed in the various floating point modes.

**FIX Mode**

Here are the numbers rendered in `FIX` mode:

| **Keys**              | **Display** |
| ----------------      | --------------------- |
| `MODE` `FIX` `4`      | ![](images/mode/display-mode-fix-1.png) |
| `ENTER`               | ![](images/mode/display-mode-fix-2.png) |
| `FIX` `99`            | ![](images/mode/display-mode-fix-3.png) |

Setting `FIX 99` goes back to the default floating number of fractional digits
(i.e. the equivalent of `FLOAT` option in the TI-OS `MODE` menu). Any number
greater than `9` would work (e.g. `11`) but I usually use `99`.

**SCI Mode**

Here are the numbers rendered in `SCI` mode:

| **Keys**              | **Display** |
| ----------------      | --------------------- |
| `MODE` `SCI` `4`      | ![](images/mode/display-mode-sci-1.png) |
| `ENTER`               | ![](images/mode/display-mode-sci-2.png) |
| `SCI` `99`            | ![](images/mode/display-mode-sci-3.png) |

Setting `99` as the number of digits in `SCI` mode makes the number of digits
after the decimal point to be dynamic (i.e. the equivalent of `FLOAT` option in
the TI-OS `MODE` menu), but retains the `SCI` notation.

**ENG Mode**

Here are the numbers rendered in `ENG` mode:

| **Keys**              | **Display** |
| ----------------      | --------------------- |
| `MODE` `ENG` `4`      | ![](images/mode/display-mode-eng-1.png) |
| `ENTER`               | ![](images/mode/display-mode-eng-2.png) |
| `ENG` `99`            | ![](images/mode/display-mode-eng-3.png) |

Setting `99` as the number of digits in `ENG` mode makes the number of digits
after the decimal point to be dynamic (i.e. the equivalent of `FLOAT` option in
the TI-OS `MODE` menu), but retains the `ENG` notation.

**HP-42S Compatibility Note**: The RPN83P uses the underlying TI-OS floating
point display modes, so it cannot emulate the HP-42S exactly. In particular, the
`ALL` display mode of the HP-42S is not directly available, but it is basically
equivalent to `FIX 99` on the RPN83P.

## Trigonometric Modes

Just like the TI-OS, the RPN83P supports two angle modes, `RAD` (radians) and
`DEG` (degrees), when calculating trigonometric functions. These are selected
using the options under the `MODE` menu folder, and the current trig mode is
shown on the top status line.

| **Keys**              | **Display** |
| ----------------      | --------------------- |
| `MODE` `RAD`          | ![](images/mode/trig-mode-1.png) |
| `PI` `6` `/` `SIN`    | ![](images/mode/trig-mode-2.png) |
| `MODE` `DEG`          | ![](images/mode/trig-mode-3.png) |
| `30` `SIN`            | ![](images/mode/trig-mode-4.png) |

**Warning**: The polar to rectangular conversion functions (`>REC` and `>POL`)
are also affected by the current Trig Mode setting.

**HP-42S Compatibility Note**: The RPN83P does not offer the
[gradian](https://en.wikipedia.org/wiki/Gradian) mode `GRAD` because the
underlying TI-OS does not support the gradian mode directly. It is probably
possible to add this feature by intercepting the trig functions and performing
some pre and post unit conversions. But I'm not sure if it's worth the effort
since gradian trig mode is not commonly used.

## Complex Result and Display Modes

The `RRES` and `CRES` menu items control how complex numbers are calculated. The
`RECT`, `PRAD`, and `PDEG` modes control how complex numbers are displayed. All
of these are explained in the [USER_GUIDE_COMPLEX.md](USER_GUIDE_COMPLEX.md)
document.

## Register and Stack Sizes

The `RSIZ` and `RSZ?` menu items control the storage register size. Those are
explained below in [Storage Register Size](#storage-register-size).

The `SSIZ` and `SSZ?` menu items control the RPN stack size. Those were
explained above in [RPN Stack Size](#rpn-stack-size).

## Comma-EE Button Mode

The `,EE` and `EE,` selectors under `ROOT > MODE` configure the behavior of the
`Comma-EE` button:

- ![ROOT > MODE](images/menu/root-mode.png) (`ROOT > MODE`)
    - ![ROOT > MODE > CommaEE](images/menu/root-mode-commaee.png)
    - `,EE`: the `Comma-EE` button behaves as labeled on the keyboard (factory
      default)
    - `EE,`: the `Comma-EE` button is inverted

Prior to v0.10, the `Comma-EE` button invoked the `EE` function for *both* comma
`,` and `2ND EE`. This allowed scientific notation numbers to be entered easily,
without having to press the `2ND` button.

However, in v0.10 when record objects were added to support DATE functions (see
[USER_GUIDE_DATE.md](USER_GUIDE_DATE.md)), the comma symbol was selected to be
the separator between the components of those objects. But that meant that
entering numbers in scientific notation would require the `2ND` key again. For
users who rarely or never use the DATE functions, the `EE,` option can be used
to invert key bindings of the `Comma-EE` button to allow easier entry of
scientific notation.

## Raw Versus String Format

The `{..}` (raw) and `".."` (string) modes control how Record objects (e.g.
Date, Time, DateTime) are displayed. These are explained in the
[USER_GUIDE_DATE.md](USER_GUIDE_DATE.md) document.

