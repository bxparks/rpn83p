# Changelog

- Unreleased
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
          action (e.g. select `DEG`) and a current mode indicator.
        - display modes: `FIX`, `SCI`, `ENG`
        - trig modes: `RAD`, `DEG`
        - base modes: `DEC`, `HEX`, `OCT`, `BIN`
    - Improve menu name centering algorithm.
        - No change for strings which are even-number of pixels wide.
        - Strings which are odd-number of pixels wide are now centered
          perfectly, instead of being off-centered by one-px to the left.
        - Allows strings which are 17px wide to be rendered properly.
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
