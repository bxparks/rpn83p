# RPN83P User Guide: TI-OS Interactions

This document describes the interactions between RPN83P and the underlying
TI-OS of the calculator.

**Version**: 1.0.0 (2024-07-19)

**Parent Document**: [USER_GUIDE.md](USER_GUIDE.md)

**Project Home**: https://github.com/bxparks/rpn83p

The RPN83P app interacts with the underlying TI-OS in the following ways.

- AppVar (application variables)
    - `RPN83REG` holds the storage registers (`R00` to `R99`).
    - `RPN83SAV` preserves the internal state of the app upon exiting.
    - `RPN83STA` holds the STAT registers (`ΣX` to `ΣYLX`).
    - `RPN83STK` holds the RPN stack registers (`X`, `Y`, `Z`, `T`, `LASTX`,
      etc).
    - When the app is restarted, the appVars are read back in, so that RPN83P
      can continue exactly where it had left off.
- ANS variable
    - On RPN83P start:
        - If `ANS` is a Real or Complex value (i.e. not a matrix, not a string,
          etc.), then it is copied into the `LASTX` register of the RPN83P.
        - The `2ND ANS` key in RPN83P invokes the `LASTX` functionality which
          then retrieves the TI-OS `ANS` value.
    - On RPN83P exit:
        - The `X` register of RPN83P is copied to the `ANS` variable in TI-OS.
        - The `2ND ANS` key in TI-OS retrieves the `X` register from RPN83P.
- 27 single-letter TI-OS variables (A-Z,Theta)
    - Accessible through the `STO {letter}` and `RCL {letter}` commands.
    - These variables provide another conduit for transferring numbers between
      RPN83P and TI-OS (in addition to the `ANS` variable).
- MODE configurations
    - RPN83P `MODE` menu uses some of the same flags and global variables as the
      TI-OS `MODE` command
        - trigonometric mode: `RAD` or `DEG`
        - floating point number settings: `FIX` (named `NORMAL` in TI-OS),
          `SCI`, `ENG`
    - These configurations are saved upon entering RPN83P then restored upon
      exiting. Changing the `MODE` settings in one app will not cause changes to
      the other.
- TVM variables
    - RPN83P uses the exact same TI-OS floating point variables and flags used
      by the `Finance` app (automatically provided by the TI-OS on the TI-84
      Plus). When these variables are changed in RPN83P, they automatically
      appear in the `Finance` app, and vise versa:
    - RPN83P variable names:
        - `N`, `I%YR`, `PV`, `PMT`, `FV`, `P/YR`, `C/YR`, `BEG`, `END`
    - TI-OS Finance app variable names:
        - `N`, `I%`, `PV`, `PMT`, `FV`, `P/Y`, `C/Y`, `BEGIN`, `END`
    - An interesting consequence of sharing these variables with the TI-OS
      Finance app is that these are the only RPN83P variables which are *not*
      saved in the `RPN83SAV` appVar.
