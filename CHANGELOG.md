# Changelog

- Unreleased
    - **Breaking**: Flip the order of polar-rectangular conversion menu function
      (`>POL` and `>REC`) so that they are consistent with the HP-42S. I don't
      know why I had them reversed.
        - `Y` register holds the `y` or `theta` value, entered first, and
        - `X` register holds the `x` or `r` value, entered second.
    - **Breaking**: Flip the order of `(X, Y)` coordinates of the `ATN2` menu
      function, so that they are consistent with the `>POL` function.
        - `Y` register holds the `y` value, which is entered first, then
        - `X` register holds the `x` value, which is entered second.
    - **Bug Fix**: Tweak the stack-lift enable/disable logic so that certain
      operations (RollDown, RollUp, X<>Y) enable stack lift even if the previous
      command was a `CLEAR` or `CLX`.
    - Increase execution speed by 2.5X on 83+SE, 84+, 84+SE
        - set CPU speed to 15 MHz when supported by hardware
        - remain at 6 MHz on the 83+
    - `SHOW` display mode
        - implement "Show" function using `2ND` `ENTRY` on TI keyboard
        - displays all 14 internal digits of the TI-OS floating point number
            - if integer < 10^14: display as integer
            - otherwise: display in scientific notation
        - `BASE` mode variation
            - `BIN` mode: display `WSIZ` digits in groups of 4, using up to 4
              display lines
            - all other `BASE` modes: display underlying floating point number
        - see [SHOW Mode](USER_GUIDE.md#show-mode) for details
    - `BASE` input limit
        - limit the number of digits that can be entered in `BASE` mode to a
          maximum that is appropriate for the selected `WSIZ` and the baseNumber
          selected by `HEX`, `DEC`, `OCT` and `BIN`
        - for example, selecting `HEX` and `WSIZ` 16 will allow only 4 hex
          digits to be entered
        - see [Base Input Digit Limit](USER_GUIDE.md#base-input-digit-limit) for
          details
    - HELP pages
        - Add page for `CONV` functions to show order of (x, y, r, theta)
          variables on RPN stack
        - Add page for `STAT` functions
        - Add page for `NUM` functions
        - Add page for various display MODEs
- 0.7.0 (2023-11-20)
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
          (inspired by HP-16C and Free42)
        - display appropriate number of digits for various `WSIZ` values, for
          various base modes (`HEX`, `OCT`, `BIN`)
        - display ellipsis character on left most digit in `BIN` mode if
          the binary number cannot be fully displayed using 14 digits on the
          screen
        - **Breaking Change**: change order of `BDIV` results in `X` and `Y`
          registers
            - now `X=quotient=Y/X` and `Y=remainder=Y%X`
            - allows easier recovery of original `X` using `LastX` `*`
    - `MATH`: add `LN1+`, `E^X-`
        - implement `log(1+x)` and `e^x-1` respectively
        - more accurate than their naive implementations when `x` is close to 0
        - use mathematical identities involving hyperbolic `sinh()` and
          `asinh()` functions to avoid roundoff errors
    - `TVM`
        - add TVM (time value of money) submenu hierarchy (inspired by HP-12C
          and HP-30b)
        - implement relatively simple Newton-Secant root solver to calculate
          the `I%YR` from the other 4 TVM variables
        - significant performance and robustness improvements can probably be
          made in the future
    - add storage register arithmetic operations
        - `STO+`, `STO-`, `STO*`, `STO/`
        - `RCL+`, `RCL-`, `RCL*`, `RCL/`
    - convert to multi-page flash application
        - now consumes 2 flash pages (2 x 16 kiB)
    - `CLEAR` multiple times to clear RPN stack
        - If `CLEAR` is pressed on an empty edit line (just a `_` cursor), then
          the message "CLEAR Again to Clear Stack" will be displayed.
        - If `CLEAR` is pressed again right after this message, the RPN stack is
          cleared, invoking the `ROOT > CLR > CLST` menu function.
        - Provides a quick shortcut to the `CLST` function which can be
          difficult to reach when the current menu item is deeply nested in
          another part of the menu hierarchy.
        - The TI-OS does not support `2ND CLEAR`, it returns the same keycode as
          `CLEAR`. So invoking `CLST` on multiple `CLEAR` presses seemed like
          the most reasonable workaround.
    - implement jumpBack for `MODE` button shortcut
        - When `ROOT > MODE` is reached through the hierchical menu, the
          `ON/EXIT/ESC` button goes back up the menu hierarchy to the parent,
          the `ROOT`.
        - When `ROOT > MODE` is invoked through the `MODE` button on the
          keyboard, the `ON/EXIT/ESC` button jumps back to the previous menu
          location, instead of going back up the menu tree.
        - This allows quick changes to the `FIX`, `SCI`, and `ENG` display
          modes, without losing one's place in the menu hierarchy.
    - fix incorrect handling of `DEL` after a `FIX`, `SCI`, or `ENG` mode
        - when the `DEL` (backspace) button is pressed after a 2-digit argument
          of a `FIX` (or `SCI` etc), one of the digits of the 2-digit argument
          remained in the input buffer
        - the fix now correctly clears the input buffer when transitioning into
          edit mode from a normal mode
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
