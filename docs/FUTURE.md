# Future Enhancements

There seems to be almost an endless number of features that could go into a
calculator app. I have grouped them into the following subsections, since my
time and energy are limited.

**Version**: 0.9.0 (2024-01-06)

**Project Home**: https://github.com/bxparks/rpn83p

## Table of Contents

- [Near Future](#near-future)
- [Medium Future](#medium-future)
- [Far Future](#far-future)
- [Highly Unlikely](#highly-unlikely)
- [Not Planned](#not-planned)

## Near Future

- datetime conversions
    - date/time components to and from epoch seconds
- allow resize of storage registers using `SIZE` command
    - The current default is fixed at 25.
    - It should be relatively straightforward to allow this to be
      user-definable, up to a `SIZE` of 100.
- decouple STAT registers from regular storage registers
    - STAT registers use R11-R23 storage registers, following the convention
      used by the HP-42S
    - there is no technical reason why RPN83P needs to follow this
    - a better solution is to create a separate set of registers (e.g. an
      `RPN83STA` appVar) just for STAT so that they don't interfere with normal
      storage registers
- bigger RPN stack
    - linking and unlinking a complex number to and from its 2 components
      effectively reduces the stack size by 1
    - an option to increase the size to 5 or maybe 8 seems worthwhile
    - should the stack size be user-configurable, say between 4 and 8?
    - regardless of whether it should be 5 or 8 levels, an infinite stack (like
      RPL or the NSTK mode of Free42) is *not* a feature that is appealing to me
- add a `ROOT > CLR > CLAL` (Clear All) menu function
    - becomes useful as more features and configuration options are added
- allow CPLX functions to operate on Real numbers
    - see [Issue#16](https://github.com/bxparks/rpn83p/issues/16)
- allow numbers in any base to be entered regardless of the BASE mode
    - see [Issue#17](https://github.com/bxparks/rpn83p/issues/17)

## Medium Future

- custom button bindings
    - a significant number of buttons on the TI-83/TI-84 keyboard are not used
      by RPN83P
    - it would be useful to allow the user to customize some of those buttons
      for quick access
    - among the currently unassigned keys, here are some notes on which may or
      may not be be available:
        - reserved for probable future use: `2ND INS`, `2ND LIST`, `2ND TEST`,
          `2ND MATRIX` `2ND CATALOG`, `2ND MEM`, `APPS`, `PRGM`, `VARS`
        - reserved for potential future use: `2ND DISTR`, `2ND {`, `2ND }`, `2ND
          [`, `2ND ]`
        - potentially available: all `ALPHA` keys, except maybe `A`-`F`, ` `
          (space), `"` (double quote), `:` (colon)
        - probably available: `2ND u`, `2ND v`, `2ND w`, `XTTn`
        - definitely available:`2ND L1` to `2ND L6` (no obvious purpose in
          RPN83P)
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
- polynomial solvers
    - Quadratic, cubic, and quartic equations have analytical solutions so
      should be relatively straightforward... Except that they need complex
      number support. And we need to work around numerical cancellation or
      roundoff errors.
- `UNIT` conversions for imperial (not just US) units
    - several places assume US customary units (e.g. US gallons) instead of
      British or Canadian imperial units
    - it'd be nice to support both types, if we can make the menu labels
      self-documenting and distinctive
- `TVM` (time value of money)
    - Improve TVM Solver for `I%YR`.
    - The current default initial guess is 0% and 100% so that positive interest
      rates are required (because a sign change over the initial guesses are
      required). If there is a rounding error, the actual numerical solution
      could be slighlty negative, which would cause an `TVM Not Fount` error
      message because a sign-change is currently required over the 2 initial
      guesses.
    - One solution could be use something like `-1%` for the lower guess, and
      then check for a sign change over 2 sub-intervals: `[-1%,0%]` and
      `[0%,100%]`. We also have to careful to detect cases where expected
      solution is exactly `0%`.
    - The terminating tolerance could be selectable or more intelligent.
    - Maybe change the root solving algorithm from Secant method to Newton's
      method for faster convergence.
- support insertion cursor using LEFT and RIGHT arrow keys
    - currently the cursor always appears at the end of the input buffer
    - it may be useful to support moving the cursor into the interior of the
      input string using the LEFT and RIGHT arrow keys
    - the DEL key would probably continue to delete to the left
    - any other input would probably insert at the cursor position
- auto-insert an implied `1` when `EE` is pressed in certain conditions
    - if the `E` is pressed on the HP-42S, a `1` or `1.` or `-1` or `-1.` is
      auto inserted into the input buffer under certain conditions
    - this feature inserts extra characters into the input buffer instead of
      changing the behavior of the input *parser*
    - therefore, this so is more difficult to implement in RPN83P versus the
      HP-42S, because the RPN83P has far more data types (e.g. complex numbers,
      Record types) so the input buffer code needs to understand the format of
      those data types to do the right thing
    - not sure if the amount of time and effort of this feature is worth the
      saving of a single keystroke
- `GCD` and `LCM` functions are slow
    - Could be made significantly faster using integer operations, instead of
      floating point operations.
    - But not a high priority.
- interoperability with TI-BASIC
    - If a TI-BASIC can be called from RPN83P, and a stable data conduit (i.e.
      an API) can be defined between RPN83P and TI-BASIC, then it may be
      possible to offload some advanced features to the TI-OS and TI-BASIC
      programs instead (see `Solver` and `fnInt` below)
    - For example, single-letter variables `A` to `Z` and `Theta` are now
      (v0.10.0) available through `STO` and `RCL`.
    - Other types may be useful: List, Matrix, and String types.
- add UI marker for menu items which are folders/groups
    - see [Issue#20](https://github.com/bxparks/rpn83p/issues/20)

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
- local RPN stack and local storage registers
    - After keystroke programming is added, it may be useful to support local
      RPN and storage registers, on a per-program basis.
- vectors
    - It might be possible to support 3D or 4D vectors with reasonable effort.
    - That allows us to add basic vector functions like dot products and cross
      products.
    - Arbitrary-sized vectors may not be worth the effort.

## Highly Unlikely

These are useful features which are estimated to take too much time and effort,
especially using low-level Z80 assembly language, so they will likely never get
added to RPN83P.

- user-defined alphanumeric variables
    - TI-OS supports only single-letter variables for real or complex types.
      Access to these are provided in v0.10.0. Multi-letter user-defined names
      are available only for real or complex Lists.
    - The HP-42S allows multi-letter user-defined variables which are accessible
      through the menu system.
    - We would have to write our own symbol management and garage collection
      subsystem to handle user-defined variables, which does not seem worth it.
    - We would also require substantial refactoring of the current menu system
      code.
    - Overall, it doesn't seem worth the effort.
- root finder (i.e. SOLVE)
    - one of the hallmarks of advanced HP calculators
    - requires keystroke programming
    - the TI-OS already provides a solver (`Solver`), maybe that is
      sufficient?
- numerical integration
    - another feature of advanced HP calculators
    - depends on keystroke programming
    - the TI-OS already provides an integrator (`fnInt`), is that enough?
- matrices
    - I don't know how much matrix functionality is provided by TI-OS SDK.
    - Creating a reasonable user-interface in the RPN83P could be a challenge.
    - It is not clear that adding matrix functions into a calculator is worth
      the effort.
    - For non-trivial calculations, it is probably easier to use a desktop
      computer and application (e.g. MATLAB, Octave, Mathematica).
    - The TI-OS also provides substantial number of matrix features and
      functions.

### Not Planned

- graphing
    - The TI-OS has extensive support for graphing equations.
    - It does not make sense to duplicate that work in the RPN83P application.
- computer algebra system (CAS)
    - The TI-83 Plus and TI-84 Plus do not support CAS, so it is highly unlikely
      that the RPN83P will support CAS either.
- rational numbers
    - Not something that I have ever needed, so I probably will not want to
      spend my time implementing it.
