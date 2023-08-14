# RPN83P

RPN calculator app for the TI-83 Plus and TI-84 Plus inspired by the HP-42S.

RPN83P is an [RPN](https://en.wikipedia.org/wiki/Reverse_Polish_notation)
calculator app for the [TI-83 Plus](https://en.wikipedia.org/wiki/TI-83_series)
(including the Silver Edition) and the [TI-84
Plus](https://en.wikipedia.org/wiki/TI-84_Plus_series) (including the Silver
Edition). The app is inspired mostly by the
[HP-42S](https://en.wikipedia.org/wiki/HP-42S) calculator, with some sprinkles
of some older HP calculators like the
[HP-12C](https://en.wikipedia.org/wiki/HP-12C) and the
[HP-15C](https://en.wikipedia.org/wiki/HP-15C).

The RPN83P is a flash application that consumes one page (16 kB) of flash
memory. Since it is stored in flash, it is preserved if the RAM is cleared. It
consumes a small amount of TI-OS RAM: 2 list variables named `REGS` and `STK`
which are 240 bytes and 59 bytes respectively.

Here the quick summary of its features:

- traditional 4-level RPN stack (`X`, `Y`, `Z`, `T` registers)
- support for `lastX` register
- 25 storage registers (`STO 00`, `RCL 00`, ..., `STO 24`, `RCL 24`)
- hierarchical menu system, inspired by the HP-42S
- support for all math functions with dedicated buttons on the TI-83 Plus and
  TI-84 Plus
    - arithmetic: `/`, `*`, `-`, `+`
    - trigonometric: `SIN`, `COS`, `TAN`, etc.
    - `1/X`, `X^2`, `2ND SQRT`
    - `^` (i.e. `Y^X`),
    - `LOG`, `10^X`, `LN`, `e^X`
    - constants: `pi` and `e`
- additional menu functions:
    - `%`, `%CH`, `GCD`, `LCM`, `PRIM` (is prime)
    - `IP` (integer part), `FP` (fractional part), `FLR` (floor), `CEIL`
    - `ABS`, `SIGN`, `MOD`, `MIN`, `MAX`
      (ceiling), `NEAR` (nearest integer)
    - probability: `PERM`, `COMB`, `N!`, `RAND`, `SEED`
    - hyperbolic: `SINH`, `COSH`, `TANH`, etc.
    - angle conversions: `>DEG`, `>RAD`, `>HR`, `>HMS`, `P>R`, `R>P`
    - unit conversions: `>C`, `>F`, `>km`, `>mi`, etc
    - base conversions: `DEC`, `HEX`, `OCT`, `BIN`
    - bitwise operations: `AND`, `OR`, `XOR`, `NOT`, `NEG`
- various display modes
    - `RAD`, `DEG`
    - `FIX` (fixed point 0-9 digits)
    - `SCI` (scientific 0-9 digits)
    - `ENG` (engineering 0-9 digits)

**Version**: 0.3.3 (2023-08-14)

**Changelog**: [CHANGELOG.md](CHANGELOG.md)

**Project Home**: https://github.com/bxparks/rpn83p

**User Guide**: [USER_GUIDE.md](USER_GUIDE.md)

## Table of Contents

- [Installation](#installation)
- [Supported Hardware](#supported-hardware)
- [Quick Examples](#quick-examples)
    - [Example 1](#example-1)
    - [Example 2](#example-2)
- [User Guide](#user-guide)
- [Compiling from Source](#compiling-from-source)
- [Tools and Resources](#tools-and-resources)
- [License](#license)
- [Feedback](#feedback)
- [Author](#author)

## Installation

RPN83P is a flash application that is packaged as a single file named
`rpn83p.8xk`. Detailed instructions are given in the [RPN83P User
Guide](USER_GUIDE.md), but here is the quick version:

- Download the `rpn83p.8xk` file from the
  [releases page](https://github.com/bxparks/rpn83p/releases).
- Upload the file to the TI-83 Plus or TI-84 Plus calculator. Use one of
  following link programs:
    - Windows: [TI Connect](https://education.ti.com/en/products/computer-software/ti-connect-sw)
    - Linux: [tilp](https://github.com/debrouxl/tilp_and_gfm)
- Run the program using the `APPS`:
    - Press `APPS`
    - Scroll down to the `RPN83P` entry
    - Press `ENTER`
- Exiting:
    - Quit app: `2ND` `QUIT`
    - Turn off device: `2ND` `OFF`

The RPN83P app starts directly into the calculator mode, like this:

> ![RPN83P Hello 1](docs/rpn83p-screenshot-initial.png)

Since the RPN83P is a flash app, it is preserved when the RAM is cleared. It
consumes about 300 bytes of RAM space for its internal RPN and storage
registers.

### Supported Hardware

This app was designed for TI calculators using the Z80 processor:

- TI-83 Plus
- TI-83 Plus Silver Edition (verified)
- TI-84 Plus
- TI-84 Plus Silver Edition (verified)

I have tested it on the two Z80 TI calculators that I have (both Silver
Edition). It *should* work on the others, but I have not actually tested them.

## Quick Examples

### Example 1

Let's compute the volume of a sphere of radius `2.1`. Recall that the volume of
a sphere is `(4/3) pi r^3`. There are many ways to compute this in an RPN
system, but I tend to start with the more complex, inner expression and work
outwards. Enter the following keystrokes:

- Press `2` button
- Press `.` button
- Press `1` button
- Press `x^2` button
- Press `2ND` `ANS` button (invokes the `LastX` functionality)
- Press `*` button (`r^3` is now in the `X` register)
- Press `2ND` `PI` button (above the `^` button)
- Press `*` button (`pi r^3`)
- Press `4` button
- Press `*` button (`4 pi r^3`)
- Press `3` button
- Press `/` button (`4 pi r^3 / 3`)
- the `X` register should show `38.79238609`

Here is an animated GIF that shows this calculation:

> ![RPN83P Example 1 GIF](docs/rpn83p-example1.gif)

(Note that the RPN83P provides a `X^3` menu function that could have been used
for this formula, but I used the `LastX` feature to demonstrate its use.)

### Example 2

Let's calculate the bitwise-and operator between the hexadecimal numbers `B6`
and `65`, then see the result as an octal number, a binary (base-2) number, then
finally as a decimal number:

- Navigate the menu with the DOWN arrow to get to
  ![ROOT MenuStrip 2](docs/rpn83p-screenshot-menu-root-2.png)
- Press `BASE` menu to get to
  ![BASE MenuStrip 1](docs/rpn83p-screenshot-menu-root-base-1.png)
- Press `HEX` menu.
- Press `ALPHA` `B` buttons
- Press `6` button
- Press `ENTER` button
- Press `6` button
- Press `5` button
- Press DOWN arrow to get to
  ![BASE MenuStrip 2](docs/rpn83p-screenshot-menu-root-base-2.png)
- Press `AND` menu, the `X` register should show `00000024`
- Press UP arrow to go back to
  ![BASE MenuStrip 1](docs/rpn83p-screenshot-menu-root-base-1.png)
- Press `OCT` menu, the `X` register should show `00000000044`
- Press `BIN` menu, the `X` register should show `00000000100100`
- Press `DEC` menu, the `X` register should show `36`

Here is the animated GIF that shows this calculation:

> ![RPN83P Example 2 GIF](docs/rpn83p-example2.gif)

Press:

- `ON` button (`ESC/EXIT`) multiple times to back to the home menu, or
- `MATH` button (`HOME`) to go back directly.

> ![ROOT MenuStrip 1](docs/rpn83p-screenshot-menu-root-1.png)

## User Guide

See the [RPN83P User Guide](USER_GUIDE.md).

## Compiling from Source

I use Ubuntu Linux 22.04 for my development. The following instructions have
been verified only on my dev machine.

- Clone this repo:
    - `$ git clone git@github.com:bxparks/rpn83p.git`
    - `develop` branch (default) contains the active development
    - `master` branch contains the stable release
- Install [spasm-ng](https://github.com/alberthdev/spasm-ng).
    - I use the static binary zip file, because the `.deb` file would not
      resolve dependencies.
    - Unpack the zip file so that the `spasm` directory is a *sibling* to the
      `rpn83` directory. (See the `SPASM_DIR` variable inside the `Makefile`).
- `$ cd src`
- `$ make`
- Should produce a file named `rpn83p.8xk`.

## Tools and Resources

Here is the tools and resources that I use for development on Ubuntu Linux
22.04:

- spasm-ng Z80 assembler
    - https://github.com/alberthdev/spasm-ng
    - The `releases` section has various packages:
    - Debian/Ubuntu/Mint (`.deb`): could not get this to work
    - Linux (static, `tar.gz`): works for me
- TILP2
    - https://github.com/debrouxl/tilp_and_gfm
    - Data Link from Linux to TI Calculator
    - `$ apt install tilp2`
- tilem2
    - https://www.ticalc.org/archives/files/fileinfo/372/37211.html
    - TI calculator emulator for Linux
    - `$ apt install tilem`
    - `$ apt install tilem-skinedit`
- rom8x
    - https://www.ticalc.org/archives/files/fileinfo/373/37341.html
    - TI calculator ROM extractor
    - Download and extract the zip file.
    - Follow the instructions to copy 1 or 2 applications to the calculator, run
      them on the calculator to generate App Vars which contain the ROM image,
      copy them back to the Linux host machine, then run `rom8x.exe` to generate
      the ROM image using Wine (see next item).
- Wine
    - https://www.winehq.org/
    - `$ apt install wine`, or download directly from winehq.com
    - Needed to run `rom8x.exe` (a Windows executable) on a Linux box.
- GNU Make
    - https://www.gnu.org/software/make/
    - Should already be installed on Ubuntu Linux.
    - `$ apt install make` to install manually.
- Python 3
    - The `python3` interpreter should already be installed on your Linux box.
    - Required to run the [compilemenu.py](tools/compilemenu.py) script that
      compiles the [menudef.txt](src/menudef.txt) file into the
      [menudef.asm](src/menudef.asm) file.
- TI-83 SDK docs
    - https://archive.org/details/83psdk/83psysroutines/
- Learn TI-83 Plus Assembly in 28 Days
    - https://taricorp.gitlab.io/83pa28d/
    - https://gitlab.com/taricorp/83pa28d/
- Hot Dog's Ti-83+ Z80 ASM for the Absolute Beginner
    - https://www.ticalc.org/archives/files/fileinfo/437/43784.html
    - https://www.omnimaga.org/hot-dog's-ti-83-z80-asm-for-the-absolute-beginner
    - Most of this book is aimed at an assembly language beginner.
    - However, Appendix A (_Creating Flash Applications with SPASM_) is the only
      place that I know which explains how to generate a flash app using the
      `spasm-ng` assembler.

## License

[MIT License](https://opensource.org/licenses/MIT)

## Feedback and Support

If you have any questions, comments, or feature requests for this library,
please use the [GitHub
Discussions](https://github.com/bxparks/rpn83p/discussions) for this project.
If you have bug reports, please file a ticket in [GitHub
Issues](https://github.com/bxparks/rpn83p/issues). Feature requests should go
into Discussions first because they often have alternative solutions which are
useful to remain visible, instead of disappearing from the default view of the
Issue tracker after the ticket is closed.

Please refrain from emailing me directly unless the content is sensitive. The
problem with email is that I cannot reference the email conversation when other
people ask similar questions later.

## Author

Created by Brian T. Park (brian@xparks.net).
