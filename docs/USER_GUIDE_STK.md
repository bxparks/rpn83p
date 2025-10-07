# RPN83P User Guide: Chapter 7: STK Functions

This document describes the menu functions under the `STK` menu in RPN83P.

**Version**: 1.1.0 (2025-10-06)\
**Project Home**: https://github.com/bxparks/rpn83p \
**Parent Document**: [USER_GUIDE.md](USER_GUIDE.md)

## Table of Contents

## STK Menus

The functions under the `STK` menu folder allow the user to manipulate the RPN
stack:

- ![ROOT > STK](images/menu/root-stk.png) (ROOT > STK)
    - ![ROOT > STK > Row1](images/menu/root-stk-1.png)

The functions are:

- `DUP`: duplicate `X` value and lift stack values up
- `R↑`: roll stack up, also bound to `2ND u` button
- `R↓`: roll stack down, also bound to `(` button
- `DROP`: delete the `X` value and drop stack values down
- `X<>Y`: exchange `X` and `Y`, also bound to `)` button

## Duplicate Top of Stack (DUP)

The `DUP` function duplicates the `X` register, pushing the rest of the RPN
stack up. The operation is very similar to just hitting `ENTER` on the keyboard,
except that `ENTER` disables the stack lift but `DUP` does not.

The `DUP` function is not exposed through a button because it is rarely needed
during normal usage of an RPN calculator. However, it is often useful in RPN
programs (which RPN83P does not yet support). It is included here for
completeness since it was implemented internally, and it was easy to expose it
through the `STK` menu folder.

## Roll Up

The Roll Up `R↑` menu command is identical to the one bound to the `2ND u`
key (above the 7) on the keyboard.

## Roll Down

The Roll Down `R↓` command is identical to the one bound to the left parenthesis
`(` on the RPN83P keyboard.

## Drop Top of Stack (DROP)

The `DROP` command removes the `X` value and drops the rest of the RPN stack
down one level.

It is not bound to a keyboard button because it is not needed often during
normal usage of an RPN calculator. However, it is useful in RPN programs (which
is not supported yet). This command is included in the `STK` menu folder for
completeness and symmetry with the `DUP` command.

## Exchange

The Exchange `X<>Y` command is identical to the one bound to the right
parenthesis `)` on the keyboard.
