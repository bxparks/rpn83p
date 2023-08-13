# RPN83P

RPN calculator app for the TI-83 Plus and TI-84 Plus inspired by the HP-42S.

**Version**: 0.3 (2023-08-13)

**Changelog**: [CHANGELOG.md](CHANGELOG.md)

**User Guide**: [USER_GUIDE.md](USER_GUIDE.md)

## Table of Contents

- [Installation](#Installation)
- [Supported Hardware](#SupportedHardware)
- [Quick Examples](#QuickExamples)
    - [Example 1](#Example1)
    - [Example 2](#Example2)
- [User Guide](#UserGuide)
- [Compiling from Source](#Compiling)
- [Tools and Resources](#ToolsResources)
- [License](#License)
- [Feedback](#Feedback)
- [Author](#Author)

<a name="Installation"></a>
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

<a name="SupportedHardware"></a>
### Supported Hardware

This app was designed for TI calculators using the Z80 processor:

- TI-83 Plus
- TI-83 Plus Silver Edition (verified)
- TI-84 Plus
- TI-84 Plus Silver Edition (verified)

I have tested it on the two Z80 TI calculators that I have (both Silver
Edition). It *should* work on the others, but I have not actually tested them.

<a name="QuickExamples"></a>
## Quick Examples

<a name="Example1"></a>
### Example 1

When the RPN83P is started, it goes directly into the calculator mode, and looks
like this:

Let's us compute the volume of a sphere of radius `2.1`. Recall that the volume
of a sphere is `(4/3) pi r^3`. There are many ways to compute this in an RPN
system, but I tend to start with the more complex, inner expression and work
outwards. Enter the following keystrokes:

- `2`
- `.`
- `1`
- `x^2`
- `2ND` `ANS` (invokes the `LastX` functionality)
- `*` (`r^3` is now in the `X` register)
- `2ND` `pi` (above the `^` button)
- `*` (`pi r^3`)
- `4`
- `*` (`4 pi r^3`)
- `3`
- `/` (`4 pi r^3 / 3`)
- the `X` register should show `38.79238609`

Here is an animated GIF that shows this calculation:

> ![RPN83P Example 1 GIF](docs/rpn83p-example1.gif)

<a name="Example2"></a>
### Example 2

Let's calculate the binary-and between hexadecimal `B6` and `65`, then see the
result as an octal number, a binary (base-2) number, then finally as a decimal
number:

- Navigate the menu with the DOWN to get to
  ![ROOT MenuStrip 2](docs/rpn83p-screenshot-menu-root-2.png)
- Press the `BASE` menu to get to
  ![BASE MenuStrip 1](docs/rpn83p-screenshot-menu-root-base-1.png)
- Press the `HEX` menu.
- `ALPHA` `B`
- `6`
- `ENTER`
- `6`
- `5`
- Press the DOWN arrow to get to
  ![BASE MenuStrip 2](docs/rpn83p-screenshot-menu-root-base-2.png)
- `AND`, the `X` register should show `00000024`
- Press the UP arrow to go back to
  ![BASE MenuStrip 1](docs/rpn83p-screenshot-menu-root-base-1.png)
- `OCT`, the `X` register should show `00000000044`
- `BIN`, the `X` register should show `00000000100100`
- `DEC`, the `X` register should show `36`

Here is the animated GIF that shows this calculation:

> ![RPN83P Example 2 GIF](docs/rpn83p-example2.gif)

Press:

- `ON` (`ESC/EXIT`) multiple times to back to the home menu, or
- `MATH` (`HOME`) to go back directly.

> ![ROOT MenuStrip 1](docs/rpn83p-screenshot-menu-root-1.png)

<a name="UserGuide"></a>
## User Guide

See the [RPN83P User Guide](USER_GUIDE.md).

<a name="Compiling"></a>
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

<a name="ToolsResources"></a>
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

<a name="License"></a>
## License

[MIT License](https://opensource.org/licenses/MIT)

<a name="Feedback"></a>
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

<a name="Author"></a>
## Author

Created by Brian T. Park (brian@xparks.net).
