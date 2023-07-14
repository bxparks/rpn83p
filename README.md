# rpn83p

RPN calculator app for TI-83 Plus and TI-84 Plus inspired by HP42S.

**Version**: 0.0 (2023-07-14)

**Changelog**: [CHANGELOG.md](CHANGELOG.md)

## Table of Contents

- [Installation](#Installation)
- [Supported Hardware](#SupportedHardware)
- [User Guide](#UserGuide)
- [Compiling from Source](#Compiling)
- [Tools and Resources](#ToolsResources)
- [License](#License)
- [Feedback](#Feedback)
- [Author](#Author)

<a name="Installation"></a>
## Installation

- Copy the `rpn83p.8xp` file to the TI-83/TI-84 calculator.
    - Windows: TI Connect
    - Linux: `tilp`
- Run the program using `Asm(prgmRPN83P)`:
    - `2ND CATALOG`
    - `Down Arrow` 6 times to `Asm(`
    - `ENTER`
    - `PRGM`
    - `Down Arrow` to select `RPN83P`
    - `ENTER`
    - `ENTER` again to run
- To quit:
    - `2ND QUIT`

<a name="SupportedHardware"></a>
### Supported Hardware

This app was designed for TI calculators using the Z80 processor:

- TI-83 Plus
- TI-83 Plus Silver Edition
- TI-84 Plus
- TI-84 Plus Silver Edition

<a name="UserGuide"></a>
## User Guide

TBD

<a name="Compiling"></a>
## Compiling from Source

I use Ubuntu Linux 22.04 for my development. The following instructions have
been verified only on my dev machine.

- Install [Supported Hardware](https://github.com/alberthdev/spasm-ng).
    - I use the static binary zip file, because the `.deb` file would not
      resolve dependencies.
    - Unpack the zip file so that the `spasm` directory is a *sibling* to the
      `rpn83` directory. (See the `SPASM_DIR` variable inside the `Makefile`).
- `$ cd src`
- `$ make`
- Should produce a file called `rpn83p.8xp`.

<a name="ToolsResources"></a>
## Tools and Resources

Here is what I use for development on Ubuntu Linux 22.04:

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
      them on the calucator to generate App Vars which contain the ROM image,
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
- TI-83 SDK docs
    - https://archive.org/details/83psdk/83psysroutines/
- Learn TI-83 Plus Assembly in 28 Days
    - https://taricorp.gitlab.io/83pa28d/
    - https://gitlab.com/taricorp/83pa28d/

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
