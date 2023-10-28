# Changelog

- Unreleased
    - `STAT`
        - fix broken `Sigma+` and `Sigma-` when `Y==0`
        - use alternate equation for `SLOP` (slope) which works when the `Y`
          data points are the same
        - fix "stack lift disable" feature of `Sigma+` and `Sigma-` which
          probably got broken during an earlier refactoring
        - check for division by zero when calculating weighted mean `WMN`, and
          show `9.9999999999999E99` to indicate error, allowing weightedX (or
          weightedY) to be evaluated even if the other is undefined
    - `BASE`
        - implement `WSIZ` (set word size) restricted to 8, 16, 24, and 32
        - display appropriate number of digits for various `WSIZ` values, for
          various base modes (`HEX`, `OCT`, `BIN`)
        - display ellipsis character on left most digit in `BIN` mode if
          the binary number cannot be fully displayed using 14 digits on the
          screen
        - **Breaking Change**: change order of `BDIV` results in `X` and `Y`
          registers
            - now `X=quotient=Y/X` and `Y=remainder=Y%X`
            - allows easier recovery of original `X` using `LastX` `*`
    - add storage register arithmetic operations
        - `STO+`, `STO-`, `STO*`, `STO/`
        - `RCL+`, `RCL-`, `RCL*`, `RCL/`
    - **Potential Breaking Change**: `STO`, `RCL`, `FIX`, `SCI`, `ENG` argument
      prompt is no longer saved and restored on QUIT or OFF
        - a new Command Arg parser was required to support storage register
          arithmetics
        - it uses a secondary `GetKey()` parsing loop which implements its own
          `2ND QUIT` and `2ND OFF` handlers
        - the state of the secondary `GetKey()` parsing loop is not saved and
          restored
- 0.6.0 (2023-09-22)
    - save application state
        - preserve app state into an appvar named `RPN83SAV` upon exit
        - reconstruct the app state upon restart
    - save `X` register to TI-OS `ANS` only on `2ND QUIT` or `2ND OFF`
        - previously saved to `ANS` every time `X` was changed
        - no user-visible change, but is more efficient internally
    - rename `P>R` to `>REC`, and `R>P` to `>POL`
        - for consistency with other conversion functions, and for consistency
          with HP-42S
        - I prefer the `P>R` and `R>P` but the difference is not worth breaking
          consistency
    - support custom MenuGroup handlers
        - absorb `changeMenuGroup()` functionality into the `dispatchMenuNode()`
        - add onExit events into `changeMenuGroup()`
        - add custom `mBaseHandler` for `BASE` menu to activate or deactivate
          the `baseNumber` upon entering or leaving the `BASE` menu hierarchy
    - `BASE` mode
        - make all `BASE` operations use `u32` integers, even `DEC` mode
        - add Carry Flag which is updated for arithmetic, shifting, rotating
          operations
            - add `SCF` (set carry flag),`CCF` (clear carry flag), `CF?` (get
              carry flag)
            - add `C` or `-` display indicator
        - remove base number indicator (`DEC`, `HEX`, `OCT`, `BIN`) from the
          status line (top line)
            - no longer needed since those menu items show a "dot" when selected
            - the base number is only relevant within the `BASE` menu hierarchy
        - add `ASL` (arithmetic shift left), `RLC` (rotate left through carry
          flag), `RRC` (rotate right through carry flag)
        - add `SLn`, `SRn`, `RLn`, `RRn`, `RLCn`, `RRCn` (shift or rotate `Y`
          for `X` times)
        - add `CB` (clear bit), `SB` (set bit), `B?` (get bit)
        - add `REVB` (reverse bits), `CNTB` (count bits)
    - add additional HELP pages
        - CFIT Models
        - BASE Ops
- 0.5.0 (2023-08-31)
    - `USER_GUIDE.md`, `README.md`
        - Update "Menu Indicator Arrows" section with latest screenshots which
          changed the menu arrows.
        - rename 'Menu Strip' to 'Menu Row' for consistency with HP-42S
          terminology.
    - `BASE`
        - display just a bare `-` for negatives numbers in `BASE` modes (instead
          of `...` which is now reserved for valid numbers which overflows the
          number of digits supported by the display)
        - validate that the `X` and `Y` values are in the range of `[0, 2^32)`
          when performing bitwise operations (e.g. `B+`, `AND`, `XOR`, etc).
          Floating point numbers are truncated to `u32` integers before the
          bitwise operations are performed.
    - Add menu selector dots
        - Replicate HP-42S menu selector dots, where a menu item can be both an
          action (e.g. select `DEG`) and a selection indicator.
        - display modes: `FIX`, `SCI`, `ENG`
        - trig modes: `RAD`, `DEG`
        - base modes: `DEC`, `HEX`, `OCT`, `BIN`
    - Improve menu name centering algorithm.
        - No change for strings which are even-number of pixels wide.
        - Strings which are odd-number of pixels wide are now centered
          perfectly, instead of being off-centered by one-px to the left.
        - Allows strings which are 17px wide to be rendered properly.
    - Add `STAT` menu items
        - 1 or 2 variable statistics
        - `Sigma+` (add data point), `Sigma-` (remove data point)
        - `SUM`, `MEAN`, `WMN` (weighted mean)
        - `SDEV` (sample standard deviation), `SCOV` (sample covariance)
        - `PDEV` (population standard deviation), `PCOV` (population covariance)
    - Add `CFIT` curve fit menu items
        - `Y>X` (forcast X from Y)
        - `X>Y` (forcast Y from X)
        - `SLOP` (least square fit slope)
        - `YINT` (least square fit y-intercept)
        - `CORR` (correlation coefficient)
        - `LINF` (linear curve fit model)
        - `LOGF` (logarithmic curve fit model)
        - `EXPF` (exponential curve fit model)
        - `PWRF` (power curve fit model)
        - `BEST` (choose best curve fit model)
    - Fix RPN stack lift logic for pending input
        - Simplify stack lift logic to handle empty and non-empty pending input
          consistently.
        - If the input buffer is empty (showing just a `_` cursor), then any
          subsequent keystroke that generates a single value (e.g. `PI` or
          `STAT:N`) replaces the empty `X` register.
        - If the input buffer is pending but not empty (i.e. has digits with a
          trailing `_` cursor), then subsequent keystrokes causes a stack lift,
          preserving the pending input into the `Y` register.
        - If the subsequent keystroke is a function that consumes an `X`
          register, then the empty input buffer is assumed to be a `0` value.
    - Allow data transfer between RPN83P and TI-OS through the `ANS` variable.
        - When the RPN83P app starts, the TI-OS `ANS` variable (if Real) is
          available as the `LastX` register.
        - When the RPN83P app exits, the most recent `X` register becomes
          avaiable in TI-OS as the `ANS` variable.
    - Add `X Root Y` menu item under `MATH`
- 0.4.0 (2023-08-16)
    - More `BASE` menu functions:
        - `SL` (shift left), `SR` (shift right), `RL` (rotate left circular),
        `RR` (rotate right circular).
        - `B+`, `B-`, `B*`, `B/`
        - `BDIV` (division with remainder)
    - Map `+`, `-`, `*`, and `/` buttons to their bitwise counterparts when in
      `HEX`, `OCT`, or `BIN` modes.
        - Too confusing to have floating point operations bound to the
          easy-to-reach buttons while in HEX, OCT or BIN modes.
        - This is consistent with the HP-42S.
    - `PRIM` (isPrime)
        - change result values:
            - 1 if the number is a prime, or
            - smallest prime factor (always greater than 1) if not prime.
        - preserve the original `X`, and push it up to `Y`
            - allows the `/` button to be chained with additional `PRIM` to
              calculate all prime factors
            - see [Prime Factors](USER_GUIDE.md#prime-factors) for details
        - improve speed by 7X using u32 integer routines instead of floating
          point routines
- 0.3.3 (2023-08-14)
    - Add `Makefile` targets for converting GitHub markdown files to PDF files.
    - Update some sections in `README.md` and `USER_GUIDE.md`.
    - No code change.
- 0.3.2 (2023-08-13)
    - Add executive summary of the app at the top of README.md.
    - No code change.
- 0.3.1 (2023-08-13)
    - Add animated GIF to illustrate Examples 1 and 2 in README.md.
    - No code change.
- 0.3 (2023-08-13)
    - Move `CLRG` from F1 position to F3. Move `CLX` to F1. If the F1
      is accidentally hit twice when selecting the `CLR` menu group, then
      invoking `CLX` is a lot less destructive than invoking `CLRG`.
    - Move `IP,FP,...` menu rows before the `ABS,SIGN,...` menu row. The
      `IP,FP` functions seem more frequently used than the `ABS,SIGN` functions.
- 0.2.1 (2023-08-13)
    - Update README.md. Test minor version number with new release.
    - No code change.
- 0.2 (2023-08-13)
    - Update downloading and installation instructions.
- 0.1 (2023-08-13)
    - Create a release, with the `.8xk` so that I can see what a GitHub release
      asset looks like, which allows me to write a better Installation guide.
- 0.0 (2023-07-14)
    - Initial extraction and upload to GitHub from my internal playground repo.
