# RPN83P User Guide: Troubleshooting

This document describes some troubleshooting techniques.

**Version**: 1.0.0 (2024-07-19)

**Parent Document**: [USER_GUIDE.md](USER_GUIDE.md)

**Project Home**: https://github.com/bxparks/rpn83p

## Table of Contents

- [Clear Display](#clear-display)
- [Reset MODE to Factory Defaults](#reset-mode-to-factory-defaults)
- [Wipe to Factory State](#wipe-to-factory-state)

## Clear Display

It is possible for the display to contain leftover pixels or line segments that
did not get properly cleared or overwritten due to some bug. When this happens,
clearing the display using the `CLD` (Clear Display) function under the `CLR`
menu folder will probably fix the problem. This function is modeled after the
`CLD` function on the HP-42S.

I have rarely seen display rendering bugs. In all cases that I can remember, I
was doing some internal debugging which would not be performed by normal users.

## Reset MODE to Factory Defaults

The RPN83P currently has only a handful of settings, and they can be reset
relatively easily through the `MODE` menu (or through the `MODE` button). There
is no explicit `CLxx` menu function under the `CLR` menu folder to reset the
MODE settings to their factory defaults.

If for some reason the factory defaults must be explicitly set, the current
workaround is to use the TI-OS:

- `2ND MEM`
- `2` (Mem Mgmt/Del)
- `B` (AppVars)
- scroll down to the `RPN83SAV` variable
- delete it using the `DEL` button

Upon restarting RPN83P, the various MODE parameters will be set to their factory
defaults.

## Wipe to Factory State

I have resisted the temptation to add a `CLAL` (Clear All) menu function because
it seems too dangerous, and because I'm not sure that everyone has the same
idea about what "all" means.

If RPN83P gets into a state where everything must be reset, a complete wipe
can be performed through the TI-OS:

- `2ND MEM`
- `2` (Mem Mgmt/Del)
- `B` (AppVars)
- delete all variables with the pattern `RPN83***` using the `DEL` button:
    - `RPN83REG` (storage registers)
    - `RPN83SAV` (MODE settings)
    - `RPN83STA` (STAT registers)
    - `RPN83STK` (RPN stack)

When RPN83P restarts, those appVars will be recreated with a completely clean
slate.
