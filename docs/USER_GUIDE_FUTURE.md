# RPN83P User Guide: Chapter 21: Future Enhancements

There seems to be almost an endless number of features that could go into a
calculator app. I have grouped them into the following subsections, assuming
that I am the only person working on these features. If you are a software
developer with knowledge of Z80 assembly language and the TI-83 Plus SDK, and
are interested in implementing any of these features, please drop me a note. I
estimate that there are at least 5-10 man-years (10,000 to 20,000 man-hours) of
work on this page, more than enough work for everyone.

This document is a superset of the entries in the [GitHub
Issues](https://github.com/bxparks/rpn83p/issues) tab. I use this document
because it is faster and easier to use compared to a web app, especially for
small features that can be described in a few sentences. Usually only the larger
and more complicated features will get their own GitHub tickets.

**Version**: 1.0.0 (2024-07-19) \
**Project Home**: https://github.com/bxparks/rpn83p \
**Parent Document**: [USER_GUIDE.md](USER_GUIDE.md)

## Table of Contents

- [Near Future](#near-future)
- [Medium Future](#medium-future)
- [Far Future](#far-future)
- [Highly Unlikely](#highly-unlikely)
- [Not Planned](#not-planned)

## Near Future

- polynomial solvers
    - Quadratic has an relatively easy, well-understood analytical solutions.
    - Cubic and quartic have analytic solutions but they are quite complex
      (particularly the quartic) and their numerical stability behaviors
      are not straightforward. It may be easier to use iterative methods for
      cubic and quartic equations.
    - Anything higher than 4th degree requires numerical solutions.
- UNIT
    - support conversions between compound unit classes related by simple powers
      of units (e.g. LENG, AREA,and VOL)
    - e.g. type `[3] [ft] [2] [m] [*]` to convert into an AREA unit
- Julian Date functions
    - support [ISO weekdate](https://en.wikipedia.org/wiki/ISO_week_date)
    - support at least one of the
      [Julian dates](https://en.wikipedia.org/wiki/Julian_day)
- add a `ROOT > CLR > CLAL` (Clear All) menu function
    - becomes useful as more features and configuration options are added
- implement a simple "undo" functionality after a `CLX` function
    - we can probably use `2ND INS`, currently unused

## Medium Future

- implement RPL-style stack handling
    - traditional RPN has some quirks
        - a small number of stack slots
        - duplication of the top of the stack upon `DROP`
        - convoluted behavior of `ENTER` and its "disabling of stack lift"
    - the RPL stack is closer to normal computer stack
        - theoretically "infinite" stack, but in practice, limited by memory
        - conceptually simpler (no duplication of top of stack, no "disabling of
          stack lift")
        - better for programming
    - implement something simple, like a fixed-sized RPL stack whose size is
      configurable (e.g. 64 levels, or 100 levels)
- allow numbers in any base to be entered regardless of the BASE mode
    - see [Issue#17](https://github.com/bxparks/rpn83p/issues/17)
- bulk view registers and variables
    - see [Issue#24](https://github.com/bxparks/rpn83p/issues/24)
- custom button bindings
    - a significant number of buttons on the TI-83/TI-84 keyboard are not used
      by RPN83P
    - it would be useful to allow the user to customize some of those buttons
      for quick access
    - among the currently unassigned keys, here are some notes on the ones that
      may be available:
        - reserved for probable future use: `2ND INS`, `2ND LIST`, `2ND TEST`,
          `2ND CATALOG`, `2ND MEM`, `APPS`, `PRGM`, `VARS`, `"` (double quote)
        - reserved for potential future use: `XTTn`, `2ND DISTR`, `2ND MATRIX`,
          `2ND [`, `2ND ]`, `ALPHA space`, `ALPHA ?` (`2ND UP` and `2ND DOWN`
          are used by the TI-OS to control the LCD contrast)
        - probably available: `2ND v`, `2ND w`, `2ND L1` to `2ND L6` (`2ND u`
          now taken by the RollUp command)
        - inaccessible (labeled on the calculator keypad, but the SDK does not
          provide access to them): `ALPHA F1` to `ALPHA F5`, `ALPHA UP`, `ALPHA
          DOWN`, `ALPHA SOLVE`
- custom menu items
    - The HP-42S supports up to 18 (3 rows of 6 menus) to be customized through
      the `ASSIGN` and `CUSTOM` menus.
    - This seems like a useful feature, but may require substantial refactoring
      of the current menu system code.
- keystroke programming
    - The usefulness of RPN83P would be substantially enhanced with keystroke
      programming because it would allow end-users to automate repetitive
      keystrokes.
    - Especially if keystroke programs can be assigned to custom buttons or menu
      items.
    - This is a huge feature that requires at least 7 new subsystems:
        - program entry and editing
        - program listing and display
        - program parsing and interpreter loop
        - byte code formats and storage
        - stable function identifiers for backwards compatibility
        - input and output functions within programs
        - flow control operators and functions (e.g. `LBL`, `GOTO`, `CALL`,
          maybe structured statement, like `IF`, `WHILE`, `FOR`, etc.)
    - I estimate that this feature will take about 1000-2000 hours of
      programming.
- auto-insert an implied `1` when `EE` is pressed in certain conditions
    - on the HP-42S, if the `E` is pressed when the input buffer contains
      digits that can semantically parsed to a `0`, a `1` or `1.` or `-1` or
      `-1.` is auto inserted into the input buffer
        - the actual behavior seems a bit complicated to discern, depending on
          whether `0` or `0.0` or `-0` or `-0.0` or other variations are in the
          input buffer
    - on the HP-50g, the behavior of the `EEX` button is similar, but not quite
      the same
        - it seems to invoke this feature only if the input buffer is empty
        - if it contains a `0` or `-0`, the 50g does not appear to do anything
          special with the `EEX` button
    - the input buffer of RPN83P contains features from both the 42S and the
      50g, so it becomes more difficult define the reasonable behavior of this
      feature
        - RPN83P supports more types than the 42S (complex numbers, Record
          types)
        - PRN83P supports scrollable input buffer like the 50g (where the LEFT
          and RIGHT arrow keys can place the cursor in the middle of the input
          buffer string)
- `GCD` and `LCM` functions are slow
    - Could be made significantly faster using integer operations, instead of
      floating point operations.
    - But not a high priority.
- save and restore state files
    - save the entire state of the app to a single appVar (archived to
      flash memory to save RAM and to be resilient across crashes and power
      cycles)
    - display a menu of state files to user
    - allow user to select a state file
    - restore the entire state of the app from the state file

## Far Future

- automated testing infrastructure
    - assembly language programming is not amenable to unit testing because it
      is difficult if not almost impossible to isolate a piece of code to be
      tested in isolation of its neighboring code and the operating system
      environment (i.e. TI-OS)
    - unfortunately, the RPN83P code base has grown large enough that it is
      becoming painful to add additional features without automated testing
    - two possible solutions:
        - testing through a TI calculator emulator hosted on a desktop/laptop
        - integration testing through keystroke programming within the RPN83P
          app itself
        - I'm not sure which solution would be easier and more maintainable
- interoperability with TI-BASIC
    - If a TI-BASIC program can be called from RPN83P, and a stable data conduit
      (i.e. an API) can be defined between RPN83P and TI-BASIC, then some of the
      need for keystroke programming within RPN83P may be satisfied.
    - Single-letter variables `A` to `Z` and `Theta` are available through `STO`
      and `RCL`, so be conduits between RPN83P and TI-BASIC.
    - Other types may be useful: List, Matrix, and String types.
    - See [Issue #22](https://github.com/bxparks/rpn83p/issues/22)
- indirect `STO` and `RCL` operators
    - `STO IND nn`, `STO+ IND nn`, `STO- IND nn`, `STO* IND nn`, `STO/ IND nn`
    - `RCL IND nn`, `RCL+ IND nn`, `RCL- IND nn`, `RCL* IND nn`, `RCL/ IND nn`
    - These are mainly used in keystroke programs, so I would probably want to
      implement programming before spending time to implement these indirect
      operators.
- `STO` and `RCL` for RPN stack registers
    - `STO ST X`, `STO ST Y`, `STO ST Z`, `STO ST T`
    - `RCL ST X`, `RCL ST Y`, `RCL ST Z`, `RCL ST T`
    - Similar to indirect `STO` and `RCL` operators, I think these are mainly
      useful for keystroke programming, so let's implement keystroke programming
      before this.
    - see also [Issue#19](https://github.com/bxparks/rpn83p/issues/19)
- generalized `X` exchange function (`X<>`)
    - for programming, it is useful to be able to exchange `X` with numeric
      storage registers, storage variables, and potentially other stack
      registers
    - for non-programming use, I don't think this function is essential
- add a String type
    - this becomes most useful if RPN83P becomes programmable
- TZDB rule based DST transitions for DATE objects
    - current only timezones with fixed offsets from UTC are supported
    - can probably implement the
    [IANA Timezone Database](https://www.iana.org/time-zones) with only about
    32-48 kB of additional flash memory (i.e. 2-3 flash pages)
        - probably requires writing some custom development tools which is
          daunting
        - not sure if it's worth implementing the algorithms in Z80 assembly
          language (it's tricky enough in the C language)
- local RPN stack and local storage registers
    - After keystroke programming is added, it may be useful to support local
      RPN and storage registers, on a per-program basis.
- vectors
    - It might be possible to support 3D or 4D vectors with reasonable effort.
    - That allows us to add basic vector functions like dot products and cross
      products.
    - Arbitrary-sized vectors may not be worth the effort.
- root finder (i.e. SOLVE)
    - one of the hallmarks of advanced HP calculators
    - requires keystroke programming
    - the TI-OS already provides a solver (`Solver`), maybe that is sufficient?
    - See [Issue #22](https://github.com/bxparks/rpn83p/issues/22)
- numerical integration
    - another feature of advanced HP calculators
    - depends on keystroke programming
    - the TI-OS already provides an integrator (`fnInt`), is that enough?
    - See [Issue #022](https://github.com/bxparks/rpn83p/issues/22)
- extend BASE functions to larger integer sizes and signed integers
    - signed integers: 1's complement, 2's complement
    - larger integers: 48-bit, 64-bit; maybe all sizes between 1 and 64
      in increments of one?
    - requires new integer type(s)
    - requires rewriting almost all bitwise and integer routines
    - BASE functions can no longer use TIOS floating point numbers, at least not
      for WSIZ > 46 bits
    - handle context switch between BASE mode and non-BASE mode properly when
      new integer types are on the RPN stack
    - if SHOW uses small font for base-2 numbers, it can display 64 digits using
      the 4 lines that are available
- add second menu row
    - the TI-OS supports separate keycodes for the `2ND` versions of `F1` to
      `F5`
    - we could bind those keycodes to a second row of menu items, just above the
      current row
    - this would improve the usability of some menu folders (e.g. `BASE`,
      `DATE`) by reducing the number of menu pages that the user needs to scroll

## Highly Unlikely

These are features which are unlikely to be implemented for various reasons:

- user-defined alphanumeric variables
    - The TI-OS supports only single-letter variables for real or complex types
      and access to these from RPN83P are provided through the `STO` and `RCL`
      commands. The TI-OS supports multi-letter user-defined names only for real
      or complex Lists, which are not currently supported in RPN83P.
    - On the other hand, the HP-42S allows multi-letter user-defined variables
      for all types, and they which are accessible through the menu system.
    - To support multi-letter variables in RPN83P, we would have to write our
      own symbol management and garage collection subsystems to handle these
      user-defined variables. We would also require substantial refactoring of
      the current menu system code.
    - Overall, it doesn't seem worth the effort.
- matrices
    - I don't know how much matrix functionality is provided by TI-OS SDK.
    - Creating a reasonable user-interface in the RPN83P could be a challenge.
    - It is not clear that adding matrix functions into a calculator is worth
      the effort.
    - For non-trivial calculations, it is probably easier to use a desktop
      computer and application (e.g. MATLAB, Octave, Mathematica).
    - The TI-OS also provides substantial number of matrix features and
      functions.
- shortcut key bindings for command arguments for `STO`, `RCL`, `FIX`
    - the HP-41C has a hidden feature where the top 2 rows of buttons are bound
      to 0-9 or 1-10 for certain commands that expect a command argument
    - see [Issue#18](https://github.com/bxparks/rpn83p/issues/18) for details

## Not Planned

- graphing
    - The TI-OS has extensive support for graphing equations.
    - It does not make sense to duplicate that work in the RPN83P application.
- computer algebra system (CAS)
    - The TI-83 Plus and TI-84 Plus do not support CAS, so it is highly unlikely
      that the RPN83P will support CAS either.
- rational numbers
    - Not something that I have ever needed, so I probably will not want to
      spend my time implementing it.
