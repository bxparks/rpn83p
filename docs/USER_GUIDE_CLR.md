# RPN83P User Guide: Chapter 6: CLR Functions

This document describes the menu functions under the `CLR` menu in RPN83P.

**Version**: 1.1.0 (2025-10-07)\
**Project Home**: https://github.com/bxparks/rpn83p \
**Parent Document**: [USER_GUIDE.md](USER_GUIDE.md)

## Table of Contents

## CLR Menus

The functions under the `CLR` menu folder provide ways to clear various parts of
the RPN83P memory:

- ![ROOT > CLR](images/menu/root-clr.png) (ROOT > CLR)
    - ![ROOT > CLR > Row1](images/menu/root-clr-1.png)
    - ![ROOT > CLR > Row2](images/menu/root-clr-2.png)

The functions are:

- `CLX`: clear `X` stack register (stack lift disabled)
- `CLST`: clear all RPN stack registers
- `CLRG`: clear all storage registers `R00` to `R99`
- `CLΣ`: clear STAT registers (storage registers `R00`-`R99` are not
    affected)
- `CLTV`: clear TVM variables and parameters
- `CLD`: clear display and redraw everything

## Clear X (CLX)

The `CLX` command clears the `X` register of the RPN stack. This is the
command that is invoked when the `CLEAR` button on the keyboard is hit once.

## Clear RPN STack (CLST)

The `CLST` command clears the entire RPN stack, including the current input
buffer. It does *not* clear the LASTX register.

This command is invoked when the `CLEAR` key on the keyboard is pressed 3 times.
The keyboard shortcut is often much easier to use than navigating to the `CLR >
CLST` command in the menu hierarchy.

## Clear Register (CLRG)

The `CLRG` command clears the storage registers (R00 - R99). The `RSIZ` command
determines the number of storage registers.

Beware, just like the HP-42S, no extra warnings are given before all registers
are wiped clean.

This command does *not* terminate the input because it does not depend on the
value of the `X` register.

## Clear Stats Registers (CLΣ)

The `CLΣ` command clears the STAT registers. Unlike the HP-42S and many other HP
calculators, the STAT registers and the storage registers are separate memory
locations. Therefore, the `CLΣ` does *not* affect the storage registers.

This command does *not* terminate the input because it does not depend on the
value of the `X` register.

## Clear TVM Registers (CLTV)

The `CLTV` command clear TVM variables and parameters. This the same command
as the `CLTV` command listed under the `TVM` menu folder. The TVM version is
easier to reach when performing TVM calculations.

This command does *not* terminate the input because it does not depend on the
value of the `X` register.

## Clear Display (CLD)

The `CLD` command clears display then causes the screen to rerender. If the
RPN83P application had no bugs, this command would not be necessary. However, in
practice, a bug might cause the display to become confused, and this command can
be used to clear and redraw the entire screen to fix the UI problem.

This command does *not* terminate the input.
