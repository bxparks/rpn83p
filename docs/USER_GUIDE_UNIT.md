# RPN83P User Guide: UNIT Functions

This document describes the menu functions under the `UNIT` menu in RPN83P.
It has been extracted from [USER_GUIDE.md](USER_GUIDE.md) due to its length.

**Version**: 1.1.0 (2025-09-30)

**Parent Document**: [USER_GUIDE.md](USER_GUIDE.md)

**Project Home**: https://github.com/bxparks/rpn83p

## Table of Contents

## UNIT Menu

- ![ROOT > UNIT](images/menu/root-unit.png) (ROOT > UNIT)
    - ![ROOT > UNIT > Row1](images/menu/root-unit-1.png)
    - ![ROOT > UNIT > Row2](images/menu/root-unit-2.png)
    - ![ROOT > UNIT > Row3](images/menu/root-unit-3.png)
    - `UFCN` - UNIT functions
    - `LENG` - Length units
    - `AREA` - Area units
    - `VOL` - Volume units
    - `TEMP` - Temperature units
    - `MASS` - Mass units
    - `FORC` - Force units
    - `PRES` - Pressure units
    - `ENER` - Energy units
    - `PWR` - Power units
    - `TIME` - Time units
    - `SPD` - Speed units
    - `FUEL` - Fuel consumption units

There are 162 units organized into 12 unit types. A unit can
be converted to any other unit within the same unit type.

## UNIT Entry and Conversion

The user interface follows the technique used by the
[HP-19BII](https://en.wikipedia.org/wiki/HP-19B) and the
[TI-85](https://en.wikipedia.org/wiki/TI-85) calculators:

- enter the value of into the RPN stack
- press the source UNIT menu to create a Denominate object with the select unit
- press the target UNIT menu of the target unit to convert the Denominate object
  into the target unit

TODO: Insert screenshot of example UNIT to UNIT conversion.

## UNIT Arithmetic

Basic arithmetic operations are supported on Denominate objects:

| **Operation**                 | **Result**    |
| -------------------------     | ----------    |
| {Denominate} + {Denominate}   | {Denominate}  |
| {Denominate} - {Denominate}   | {Denominate}  |
| {float} * {Denominate}        | {Denominate}  |
| {Denominate} * {float}        | {Denominate}  |
| {Denominate} / {float}        | {Denominate}  |

TODO: Insert screenshots of UNIT arithmetics.

## UNIT FCN

Two miscellaneous functions are available under the `UFCN` menu folder:

- `UVAL`: extract the unit value
- `UBAS`: convert to the baseUnit of its UnitType

## Supported Units

The following is the list of all units supported. The column `HP` indicates that
the unit is available on the HP-19BII. The column `TI` indicates that the unit
is available on the TI-85. RPN83P supports *all* units from both of these
calculators.


### Length (LENG)

| **Unit Name** | **Menu**  |**HP**|**TI**| **Comment**   |
| ------------- | --------- |------|------| ------------  |
| **`LENG`**    |           |      |      |               |
| `fermi`       | `ferm`    |      | TI   | 1e-15 m       |
| `angstrom`    | `angs`    |      | TI   | 1e-10 m       |
| `nm`          | `nm`      |      | TI   | 1e-9 m        |
| `μm`          | `μm`      |      |      | 1e-6 m        |
| `mm`          | `mm`      | HP   | TI   |               |
| `cm`          | `cm`      | HP   | TI   |               |
| `m`           | `m`       | HP   | TI   |               |
| `km`          | `km`      | HP   | TI   |               |
| `mil`         | `mil`     |      | TI   | 1/1000 in     |
| `inch`        | `in`      | HP   | TI   | 25.4 mm       |
| `foot`        | `ft`      | HP   | TI   | 12 in         |
| `yard`        | `yd`      | HP   | TI   | 3 ft          |
| `mile`        | `mi`      | HP   | TI   | 1760 yd       |
| **`LENG > TYPO`**    |           |      |      |               |
| `twip`        | `twip`    |      |      | 1/20 pt       |
| `point`       | `pt`      |      |      | 1/72 inch     |
| `pica`        | `pica`    |      |      | 12 pt         |
| **`LENG > SURV`**    |           |      |      |               |
| `survey ft`   | `svft`    | HP   | TI   | using pre-2023 defn of 1200/3937 m |
| `rod`         | `rod`     | HP   | TI   | 16.5 ft       |
| `chain`       | `chai`    | HP   | TI   | 4 rods, 66 ft |
| `furlong`     | `frlg`    |      |      | 10 chains     |
| `survey mi`   | `svmi`    | HP   |      | using pre-2023 defn of 6336/3937 km; called "statutory mile" in HP-19BII |
| `league`      | `leag`    |      |      | 3 (normal) miles |
| **`LENG > NAUT`**    |           |      |      |               |
| `fathom`      | `fath`    | HP   | TI   | 6 feet        |
| `cable`       | `cabl`    |      |      | 3429/15625 km |
| `nmi`         | `nmi`     | HP   | TI   | 1852 m        |
| **`LENG > ASTR`**    |           |      |      |               |
| `light sec`   | `lsec`    |      |      |               |
| `AU`          | `AU`      |      |      |               |
| `light year`  | `ly`      |      | TI   |               |
| `parsec`      | `pc`      |      |      |               |

### Area (AREA)

| **Unit Name** | **Menu**  |**HP**|**TI**| **Comment**   |
| ------------- | --------- |------|------| ------------  |
| **`AREA`**    |           |      |      |               |
| `mm²`         | `mm²`     |      |      |               |
| `cm²`         | `cm²`     | HP   | TI   |               |
| `m²`          | `m²`      | HP   | TI   |               |
| `km²`         | `km²`     | HP   | TI   |               |
| `inch²`       | `in²`     | HP   | TI   |               |
| `foot²`       | `ft²`     | HP   | TI   |               |
| `yard²`       | `yd²`     | HP   | TI   |               |
| `mile²`       | `mi²`     | HP   | TI   |               |
| `nmi²`        | `nmi²`    |      |      |               |
| `acre`        | `acre`    | HP   | TI   | 66ft\*660ft   |
| `hectare`     | `ha`      | HP   | TI   | 100m\*100m    |
| `usftball`    | `usfb`    |      |      | US NFL football field, 100yd\*160ft |
| `caftball`    | `cafb`    |      |      | CA CFL football field, 110yd\*65yd |
