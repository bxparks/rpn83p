# Changelog

- Unreleased
- 1.0.0 (2024-07-19)
    - RPN83P is now out of beta!
    - Documentation
        - add "Troubleshooting" section to `USER_GUIDE.md`
    - User Interface
        - `CLEAR` button clears only to the end of the line if the cursor is in
          the interior of the input buffer
            - if the cursor is at the beginning or the end of the input buffer,
              the entire buffer is cleared
            - identical to the CLEAR button on the TI-89/92+/Voyage 200
            - similar to 2ND CLEAR on HP-50g in Algebraic mode (but not in RPN
              mode)
    - Variables
        - print 'Err: Archived' error message if `STO` or `RCL` acts on
          a variable (A-Z,Theta) that is archived
    - TVM
        - Change the criteria for using the small-i approximation to the
          following: N*i <~ 6e-5.
    - Improve performance of `PRIM` by 2.4X
        - convert `modOP1ByBC()` to use the `IX` register instead of the stack
          `(SP)`: 43-67% faster
        - use DEIX instead of HLIX: ~12% faster
        - process using in 8-bit chunks instead of 1-bit: ~18% faster
        - use `A` register instead of `D` register for chunks: ~5% faster
        - use nonrestoring division algorithm: ~11% faster
        - unroll the 8-bit division loop 8 times: ~11% faster
        - thanks go to the responders of [this Cemetech
          thread](https://www.cemetech.net/forum/viewtopic.php?p=307636) for
          improving the `modHLIXByBC()` algorithm
    - MODE
        - set Trig, Floating Display, and Display Digits settings to a known
          state if the restoration of RPN83SAV fails, instead of inheriting the
          modes from the TI-OS
            - trig mode: RAD
            - floating display: FIX
            - display digits: floating
    - CLR folder
        - add `CLD` (clear display) menu item
            - clear the display and re-render everything
            - should almost never be needed, except during debugging
            - analogous to the `CLD` command on the HP-42S
    - UNIT
        - car fuel consumption
            - add `>Lkm`: convert mpg (miles per US gallon) to L/100km (liters
              per 100 km)
            - add `>mpg`: convert L/100km to mpg
        - car tire pressure
            - add `>kPa`: convert psi (pounds per square inch) to kPa
              (kiloPascal)
            - add `>psi`: convert kPa to psi
        - land area
            - add `>ha`: convert acre to hectare
            - add `>acr`: convert hectare to acre
- 0.12.0 (2024-06-24)
    - **Bug Fix**: update logic that determines when the comma `,` character can
      be inserted into the input buffer
        - some internal routines were still looking at the last character in the
          input buffer, instead of the character to the left of the current
          cursor
            - prevented comma insertion when the cursor was scrolled into the
              middle of the input buffer
            - updated to look at the char to the left of cursor
        - update logic that handles left and right braces `{ }`
            - comma now allowed only inside an open left-brace `{`
            - comma no longer allowed after the last closing right-brace `}`
    - TVM
        - reduce rounding errors when `PYR==CYR`, the most common case in the US
          at least
        - improve logic for appending the "overridden" dot after the `IYR1`,
          `IYR2`, and `TMAX` menu items
        - add `C/YR` menu (number of compoundings per year)
            - uses the same variable as the `C/Y` variable of the "Finance" app
              in TI-OS
            - supports `2ND C/YR` to retrieve its value, just like `2ND P/YR`
            - setting `P/YR` also sets `C/YR` (consistent with the behavior of
              the "Finance" app in TI-OS
            - setting `C/YR` does *not* change `P/YR` (same as "Finance" app)
        - add a dot to `P/YR` and `C/YR` if they differ from their default value
          of 12, allows users to quickly see if those values are different from
          the default
        - make TVM Solver more robust under certain edge cases, especially near
          `I%YR ~ 0%`
        - change initial guess of `IYR1` to `-50%` to support negative interest
          rates by default
            - keep default value of `IYR2` at `100%`
        - synchronize the `BEG`/`END` flag of RPN83P with the `BEGIN`/`END`
          flag of the "Finance" app provided by TI-OS
        - display status message 'TVM Calculated (Multiple)' if the TVM equation
          has 2 solutions, but only one of them was found
    - docs
        - simplify pandoc processing pipeline
        - change PDF font to FreeSerif and FreeMono to render the U+2220 (angle)
          symbol properly
- 0.11.0 (2024-05-28)
    - **Warning**: Previously saved RPN stack and storage registers are
      incompatible and are lost when upgrading to this version.
    - support resizing the number of storage registers
        - `MODE > RSIZ` command supports a minimum of 25 to a maximum of 100
        - `MODE > RSZ?` returns the current size of storage registers
        - size of the `RPN83REG` appVar varies:
            - 500 bytes at RSIZ=25
            - 1925 bytes at RSIZ=100
    - support resizing the RPN stack size
        - `MODE > SSIZ` command supports a minimum of 4 to a maximum of 8
        - `MODE > SSZ?` returns the current size of stack
        - size of the `RPN83STK` appVar varies:
            - 120 bytes at SSIZ=4
            - 196 bytes at SSIZ=8
    - add additional stack operators
        - soft menu `DROP`
            - drops the stack by one, duplicating the top register
            - already implemented in the code, just exposing the functionality
              to the user
        - soft menu `DUP`
            - lifts the stack by one, duplicating X (similar to `ENTER` without
              disabling the stack-lift)
            - already implemented in the code, just exposing the functionality
              to the user
        - button `2ND u`
            - bound to the `RollUp` functionality, same as the existing `RollUp`
              soft menu item
            - becomes useful when the stack size `SSIZ` is greater than 4
    - DATE
        - simplify DATE menu hierarchy
            - move RTC (hardware clock) menus and TZ config menus under new CLK
            menu folder
            - move DSHK, DEXD, DCUT, DLNK menu items under new DOPS menu folder
        - support arithmetic operations on Offset
            - {Offset} + {hours}, {hours} + {Offset}
            - {Offset} - {hours}
            - {Offset} - {Offset} => {hours}
            - plus the same operations with {hours} replaced with an appropriate
            {Duration} (in multiples of 15 minutes)
    - STAT
        - extract the 13 STAT registers (R11-R23) from regular storage registers
          (appVar `RPN83REG`) into its own registers (appVar `RPN83STA`)
        - add `Σ` (Sigma) menu folder containing various `ΣXXX` menu items to
          recall the 13 stat registers (essentially the same as the Plus42 app)
        - See [USER_GUIDE_STAT.md](docs/USER_GUIDE_STAT.md)
    - BASE
        - format HEX numbers in groups of 2 digits for readability
        - format OCT numbers in groups of 3 digits for readability
        - format BIN numbers in groups of 4 digits using small font,
            allowing 16 digits to be displayed on a single line
        - no digit grouping for DEC numbers (no change)
        - move formatting routines to Flash Page 2
        - See [USER_GUIDE_BASE.md](docs/USER_GUIDE_BASE.md)
    - show MenuFolders using a file folder icon
        - fixes [Issue#20](https://github.com/bxparks/rpn83p/issues/20)
        - draw a small 5px wide line above the menu box if the menu is a folder
        - inspired by the menus on the HP-48 series calculators
        - change cursor to be rectangular block, instead of an underline, to
          avoid visual conflict with the short dash line of menu folders just
          below the editing line
    - support insertion cursor using `LEFT` and `RIGHT` arrow keys
        - support `2ND LEFT` (beginning of line) and `2ND RIGHT` (end of line)
          key bindings
        - update CHS `(-)` to change the sign of the interior number component
          identified by the cursor instead of the right most component in the
          inputBuf
        - this allows easier correction of typos during long input
    - storage formats
        - encode RpnObject type field using 2 bytes instead of 1 byte
            - allows additional RpnObjects in the future without violating the
              83 Plus SDK documentation
        - update storage format of the TIOS appVars (RPN83SAV, RPN83STA,
          RPN83STK, RPN83REG)
            - makes adding additional appVar types in the future easier
    - **Bug Fix** More robust data validation for appVars
        - add `schemaVersion` field for RpnElementList
        - add `rpnVarType` field, to allow future appVar types
        - validate size of RpnElementList appVar has no extraneous bytes
    - **Bug Fix** Validate Duration objects entered through colon-modifier
      syntax
        - prevents entry of things like `61:S` or `25:H`
    - **Bug Fix** Display error for negative numbers correctly for BASE mode
      when WSIZ < 32
        - If the floating point number is negative, the validation for
          determining if the WSIZ is exceeded was incorrectly handled. Which
          caused negative numbers to be displayed with `...` instead of `-`, but
          the bug occurred only for WSIZ < 32.
        - Fixed so that `-` is correctly displayed for all WSIZ.
- 0.10.0 (2024-03-31)
    - **Bug Fix** Fix broken `CLRG`
        - broke when 'REGS' was replaced by 'RPN83REG'
    - **Bug Fix** Parse floating numbers equivalent to 0.0 more correctly.
        - The canonical internal representation of 0.0 in TI-OS has an exponent
          value of `$80` (i.e. 0), with all mantissa digits set to `0`.
        - The previous code set the mantissa digits correctly, but incorrectly
          set the exponent to `$7F` or some other value depending on the
          position of the decimal point relative to the `0` digits.
        - It made almost no difference because various floating point routines
          seem to canonicalize the exponent to the correct `$80` before
          continuing.
        - However, in an upcoming feature, the validation `CkPosInt()` is called
          before canonicalization can take place, the `CkPosInt()` returns an
          incorrect result.
        - The fix correctly detects all variations of a 0.0 (e.g. an empty
          string "", "0.0", "000.0", "-000.000E1", "00.00E0") and correctly
          returns the canonical representation of 0.0 which works with
          `CkPosInt()`.
    - **Bug Fix** Validate data type for `STAT` functions
        - allow only Real numbers for `Sigma+` and `Sigma-`
    - **Bug Fix** Validate data type for `TVM` functions
        - allow only Real numbers for TVM functions
    - **Bug Fix** Validate data type for `%` function
        - allow only Real numbers for `X` and `Y`
    - **Bug Fix** Validate data type when storing to `ANS` upon app exit
        - allow only Real or Complex numbers to stored to `ANS`
    - **Bug Fix** Support real arguments for `CPLX` menu functions (`REAL`,
      `IMAG`, `CONJ`, `CABS`, `CANG`)
        - fixes [Issue#16](https://github.com/bxparks/rpn83p/issues/16)
    - RPN83P now consumes 3 flash pages (48 kiB)
    - Verify compatibility with TI-Nspire with TI-84 Plus Keypad
        - the TI-84 Plus Keypad causes the ARM processor to emulate a Z80
          processor and the whole calculator essentially becomes a TI-84+SE
    - Store and recall TI-OS single-letter variables
        - TI-OS supports 27 single-letter variables (A-Z, Theta) for real and
          complex numbers
        - extend `STO`, `RCL`, `STO{op}`, and `RCL{op}` to accept a
          single-letter in addition to digits (e.g. `STO ALPHA A`, `RCL+
          ALPHA B`)
    - Add `RNDF`, `RNDN`, `RNDG` rounding functions
        - `RNDF`: round to current FIX/SCI/ENG digits
        - `RNDN`: round to user-specified `N` digits (0-9)
        - `RNDG`: round to 10 digits, removing guard digits
    - Change complex number type error to `Err:DataType`
        - when a function does not accept a complex number, an error message is
          shown
        - change the message from `Err:Domain` to `Err:DataType`
    - Add `MODE` option to invert the behavior of `,` and `2ND EE` button
        - previously, both the `,` button and `2ND EE` button were mapped to
          `EE`, to make entry of floating point numbers with exponents easier.
        - But the new Date/Time records require the `,` button for entry.
        - add 2 selectors into `MODE` menu:
            - `,EE` causes the button to behave as labeled (default)
            - `EE,` inverts the mapping, so that `,` invokes the `EE` function,
              and `2ND EE` invokes the `,` function
        - allows the end user to select the most convenient behavior.
    - Update menu compiler and menu routines to support more than 255 items.
        - move most menu routines into Flash Page 1.
    - add date functions
        - date, time, datetime, timezone, and hardware clock
        - add or subtract dates, times, datetimes
        - convert datetime to different timezones
        - convert between datetime and epochseconds
        - support alternate Epoch dates (Unix, NTP, GPS, TIOS, Y2K, custom)
        - set and retrieve datetime from the hardware clock (84+/84+SE only)
        - display time and date objects in RFC 3339 (ISO 8601) format
        - see [RPN83P User Guide: DATE](docs/USER_GUIDE_DATE.md)
    - increase performance of `PRIM` (prime factor) function by 40-50%.
        - see [RPN83P User Guide: Prime
          Factors](docs/USER_GUIDE.md#prime-factors)
    - update pandoc scripts that convert GitHub flavored Markdown to PDF
        - pandoc was generating images which were 33% too large
        - fixed by using ImageMagick to prescale the images to 75%
- 0.9.0 (2024-01-06)
    - **Breaking**: Change names and internal formats of various appVars
        - `STK` list variable replaced with `RPN83STK`
        - `REGS` list variable replaced with `RPN83REG`
        - `RPN83SAV` remains unchanged
        - the old `STK` and `REGS` variables can be manually removed
        - see [TI-OS Interaction](docs/USER_GUIDE.md#ti-os-interaction) for more
          details
    - **Breaking**: Add `CPLX` menu at the previous location of `CONV`
        - `CPLX` menu seemed most convenient on row 1 of the `ROOT` menu where
          the old `CONV` was located
        - `CONV` got pushed to row 2, where the `UNIT` menu was previously
          located
        - `UNIT` got pushed to row 3, into an empty slot
        - the RPN83P home menu row now has exactly the same items as the `MATH`
          menu on the TI-OS:
            - RPN83P: `MATH`, `NUM`, `PROB`, `CPLX`
            - TI-OS: `MATH`, `NUM`, `CPX`, `PROB`
    - Support more than 14 digits during edit/input
        - When more than 14 digits are entered, the left most digits scroll off
          to the left, with the left most digit replaced with an ellipsis
          character indicates existence of extra digits.
        - Normal mode:
            - accepts maximum of 20 digits, which supports entering all 14
              digits encoded by the TI-OS floating point number format
        - Complex mode:
            - accepts maximum of 41 digits to allow 2 floating point numbers
        - `BASE BIN` mode
            - accepts up to 32 digits, to allow a 32-bit binary number when the
              `WSIZ` is 32.
        - see [Input Limits and Long
          Numbers](docs/USER_GUIDE.md#input-limits-and-long-numbers) for more
          details
    - `PROB`
        - Expand range of `COMB(n,r)` and `PERM(n,r)` arguments to `n,r<=65535`
          from `n,r<=255`.
        - Improve performance of `COMB(n,r)` when `r>(n-r)` by taking advantage
          of the symmetry of `COMB(n,r)==COMB(n,n-r)`.
        - Eliminate floating point round-off errors in computing `COMB(n,r)` by
          incrementing the divisor from 1 to `r`, instead of decrementing it
          from `r` to 1.
    - Complex Numbers
        - redesign RPN stack and storage registers to support both real and
          complex numbers
        - extend arithmetic, algebraic, transcendental handlers to support
          complex numbers
        - add explicit CPLX menu group with: REAL, IMAG, CONJ, CABS, CANG
        - support RRES (real result) and CRES (complex result) menu settings
        - support RECT (rectangular), PRAD (polar radian), PDEG (polar degree)
          menu settings
        - display complex numbers in RPN stack in rect and polar modes
        - support complex numbers in SHOW in rect and polar modes
        - support Linking/Unlinking a complex number and its 2 real components
          using 2ND LINK (equivalent to COMPLEX button on the HP-42S)
        - support entry of complex numbers on a single line in RECT, PRAD, and
          PDEG modes using the `2ND i` and `2ND ANGLE` keys.
        - see [Complex Numbers](docs/USER_GUIDE.md#complex-numbers) for more
          details.
    - Save and restore app MODE settings independently from the TI-OS settings
        - decouple the TI-OS MODE settings from the RPN83P MODE settings
        - the TI-OS MODE settings are saved upon app start, and restored upon
          app exit
        - the app MODE settings are saved and restore independently
        - for example, it is now possible to set the TI-OS to FIX(2) and DEG,
          while setting RPN83P to SCI(4) and RAD and the 2 settings are managed
          separately, even though there is only a single set of global OS
          settings
    - **Bug Fix**: Render 3-digit EE exponents correctly in `SHOW` mode.
        - 3-digit exponents can only be shown for complex numbers, so the bug
          was latent until complex numbers were added
    - **Bug Fix**: Fix overflow in rectangular to polar conversion `>POL`
        - the built-in TI-OS `RToP()` function has a bug which throws an
          exception when `x^2+y^2` becomes `>=1e100`, which can happen for `x`
          or `y` as low as `7.07e49`.
        - reimplement using a custom `rectToPolar()` without the scaling bug
- 0.8.0 (2023-12-03)
    - **Breaking**: Flip the order of polar-rectangular conversion menu function
      (`>POL` and `>REC`) so that they are consistent with the HP-42S. I don't
      know why I had them reversed.
        - `Y` register holds the `y` or `theta` value, entered first, and
        - `X` register holds the `x` or `r` value, entered second.
    - **Breaking**: Flip the order of `(X, Y)` coordinates of the `ATN2` menu
      function, so that they are consistent with the `>POL` function.
        - `Y` register holds the `y` value, which is entered first, then
        - `X` register holds the `x` value, which is entered second.
    - **Breaking**: Change `WSIZ` to prompt the user for the base word size
      using `WSIZ _ _` prompt, instead of using the value in the `X` register.
        - Solves a major usability problem where the user was forced to enter
          the word size using the currently selected base mode (e.g. `HEX` or
          `BIN`). For example, the word size `16` was required to be entered as
          `10000` in `BIN` mode, which was too confusing.
        - See [Base Word Size](USER_GUIDE.md#base-word-size) for more details.
    - **Bug Fix**: Tweak the stack-lift logic so that certain operations
      (RollDown, RollUp, X<>Y) enable stack lift even if the previous command
      was a `CLEAR` or `CLX`.
        - The `rpnFlagsLiftEnabled` was not set properly for RollDown, RollUp,
          X<>Y and potentially other commands.
        - So a `CLEAR RollDown RollDown RollDown RollDown` followed by a number
          would overwrite the `X` register, instead of doing a stack lift.
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
