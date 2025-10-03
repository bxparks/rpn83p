# RPN83P User Guide: UNIT Functions

This document describes the menu functions under the `UNIT` menu in RPN83P.

**Version**: 1.1.0 (2025-09-30)

**Parent Document**: [USER_GUIDE.md](USER_GUIDE.md)

**Project Home**: https://github.com/bxparks/rpn83p

## Table of Contents

- [UNIT Menu](#unit-menu)
- [UNIT Entry and Conversions](#unit-entry-and-conversions)
- [UNIT Arithmetic](#unit-arithmetic)
- [UNIT Misc Functions (UFCN)](#unit-misc-functions-ufcn)
- [UNIT and NUM Functions](#unit-and-num-functions)
- [Catalog of Supported Units](#catalog-of-supported-units)

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

## UNIT Entry and Conversions

The user interface follows the technique used by the
[HP-19BII](https://en.wikipedia.org/wiki/HP-19B) and the
[TI-85](https://en.wikipedia.org/wiki/TI-85) calculators:

- enter the value of into the RPN stack
- press the source UNIT menu to create a Denominate object with the select unit
- press the target UNIT menu of the target unit to convert the Denominate object
  into the target unit

**Terminology**: A Denominate object is composed of a value (a floating point
number) and its unit.

Let's convert 68 degrees Fahrenheit to Celsius, then to Kelvin using the menu
functions of `UNIT > TEMP` folder:

| **Keys**          | **Display**                      |
| ----------------  | ---------------------            |
| `68`              | ![](images/unit/unit-temp-1.png) |
| `°F`              | ![](images/unit/unit-temp-2.png) |
| `°C`              | ![](images/unit/unit-temp-3.png) |
| `°K`              | ![](images/unit/unit-temp-4.png) |

**Note**: The official SI symbol for Kelvin is a K without a degree symbol.
However for UI consistency, it looked better to keep the degree symbol for a
`TEMP` unit.

The Denominate object can only be converted within the units of the same
unitType. For example, we cannot convert a meter of `LENG` type to a kilogram of
`MASS` type:

| **Keys**          | **Display**                      |
| ----------------  | ---------------------            |
| `6` `m`           | ![](images/unit/unit-conversion-invalid-1.png) |
| `kg`              | ![](images/unit/unit-conversion-invalid-2.png) |

## UNIT Arithmetic

Basic arithmetic operations are supported on Denominate objects:

| **Operation**                 | **Result**    |
| -------------------------     | ----------    |
| {Denominate} + {Denominate}   | {Denominate} (using unit of `Y`) |
| {Denominate} - {Denominate}   | {Denominate} (using unit of `Y`) |
| {float} * {Denominate}        | {Denominate}  |
| {Denominate} * {float}        | {Denominate}  |
| {Denominate} / {float}        | {Denominate}  |
| {Denominate} / {Denominate}   | {float}       |

Let's enter "6 feet 2 inches", divide that by 3, then convert that to inches:

| **Keys**          | **Display**                      |
| ----------------  | ---------------------            |
| `6` `ft`          | ![](images/unit/unit-arithmetic-leng-1.png) |
| `2` `in`          | ![](images/unit/unit-arithmetic-leng-2.png) |
| `+`               | ![](images/unit/unit-arithmetic-leng-3.png) |
| `3`               | ![](images/unit/unit-arithmetic-leng-4.png) |
| `/`               | ![](images/unit/unit-arithmetic-leng-5.png) |
| `in`              | ![](images/unit/unit-arithmetic-leng-6.png) |

For the `+` and `-` operations, the result uses the unit of the Denominate
object in the `Y` register (not the `X`). This seemed to be the more convenient
behavior because I was often accumulating multiple measurements or items into
the `Y` register, for example, adding 3 wooden pieces of "3ft 3in", "2ft 1in",
and "1ft 8in", and I wanted to retain the larger unit.

Arithmetic operators are disabled for two unitTypes:

- `TEMP`: arithmetic operations don't make sense for TEMP units (except perhaps
  for Kelvin, but it was less confusing to disallow all TEMP units)
- `FUEL`: fuel consumption units are reciprocals of each other, so arithmetic
  operations do not usually make sense

## UNIT Misc Functions (UFCN)

Two miscellaneous functions are available under the `UFCN` menu folder:

- ![ROOT > UNIT > UFCN](images/menu/root-unit-ufcn.png)
    - ![ROOT > UNIT > UFCN > Row1](images/menu/root-unit-ufcn-1.png)
    - `UVAL`: extract the unit value
    - `UBAS`: convert to the baseUnit of its UnitType

The `UVAL` function extracts the display value of the  Denominate object in `X`,
removing the unit portion.

| **Keys**          | **Display**                      |
| ----------------  | ---------------------            |
| `6` `ft`          | ![](images/unit/unit-uval-1.png) |
| `UVAL` or `2ND v` | ![](images/unit/unit-uval-2.png) |

For convenience, `UVAL` function is also available as the `2ND v` (above the `8`
key) so to avoid the need to traverse the menu hierarchy into the `UFCN` menu.

The `UBAS` function converts the Denominate object in `X` to its base unit.
Every unitType (e.g. `LENG`) has a baseUnit (e.g. `meter`). Every Denominate
object is stored with its value converted in terms of its baseUnit. The `UBAS`
function exposes the internal baseUnit and its baseValue.

| **Keys**          | **Display**                      |
| ----------------  | ---------------------            |
| `6` `ft`          | ![](images/unit/unit-ubas-1.png) |
| `UBAS`            | ![](images/unit/unit-ubas-2.png) |

The `UBAS` function does not have a keyboard shortcut, because it is not
expected to be needed as often as the `UVAL` function.

## UNIT and NUM Functions

Most of the numerical functions under the `ROOT > NUM` menu folder have been
updated to support Denominate objects from `UNIT` (the exceptions are `GCD`,
`LCM`, and `PRIM`):

- `%`: `X` percent of `Y`, leaving `Y` unchanged
- `%CH`: percent change from `Y` to `X`, leaving `Y` unchanged
- `IP`: integer part of `X`, truncating towards 0, preserving sign
- `FP`: fractional part of `X`, preserving sign
- `FLR`: the floor of `X`, the largest integer <= `X`
- `CEIL`: the ceiling of `X`, the smallest integer >= `X`
- `NEAR`: the nearest integer to `X`
- `ABS`: absolute value of `X`
- `SIGN`: return -1, 0, 1 depending on whether `X` is less than, equal, or
    greater than 0, respectively
- `MOD`: `Y` mod `X` (remainder of `Y` after dividing by `X`)
- `MIN`: minimum of `X` and `Y`
- `MAX`: maximum of `X` and `Y`
- `RNDF`: round to `FIX/SCI/ENG` digits after the decimal point
- `RNDN`: round to user-specified `n` digits (0-9) after the decimal point
- `RNDG`: round to remove guard digits, leaving 10 mantissa digits

For example, let's calculate the percent change from 2 kWh to 2000 kcalories
(~2.32 kWh):

| **Keys**          | **Display**                      |
| ----------------  | ---------------------            |
| `2` `kWh`         | ![](images/unit/unit-num-percentch-1.png) |
| `2000` `kcal`     | ![](images/unit/unit-num-percentch-2.png) |
| `MATH` `NUM`      | ![](images/unit/unit-num-percentch-3.png) |
| `%CH`             | ![](images/unit/unit-num-percentch-4.png) |

Some `NUM` functions are not valid for units of 2 unitTypes:

- `TEMP`:
    - Allowed: `IP`, `FP`, `FLR`, `CEIL`, `NEAR`, `RNDF`, `RNDN`, `RNDG`
    - Disallowed: `%`, `%CH`, `ABS`, `SIGN`, `MOD`, `MIN`, `MAX`
- `FUEL`:
    - Allowed: `IP`, `FP`, `FLR`, `CEIL`, `NEAR`, `RNDF`, `RNDN`, `RNDG`
    - Disallowed: `%`, `%CH`, `ABS`, `SIGN`, `MOD`, `MIN`, `MAX`

## Catalog of Supported Units


The following is the complete list of supported units in RPN83P. There are 169
units organized into 12 unit types. All units from both the HP-19BII and the
TI-85 calculators are included. A unit can be converted to any other unit within
the same unit type.

The columns in the table mean the following:

- **Display Name**: the display name of the unit (up to 10 characters)
- **Menu**: the short name on the soft menu (3-4 characters)
- **HP**: the unit is found on the HP-19BII
- **TI**: the unit is found on the TI-85
- **Comment**: definitions of the units and other clarifications

### Length (LENG)

| **Display Name**  | **Menu**  |**HP** |**TI** | **Comment**   |
| -------------     | --------- |------ |------ | ------------  |
| **`LENG`**        |           |       |       |               |
| `fermi`           | `ferm`    |       | TI    | 1e-15 m       |
| `angstrom`        | `angs`    |       | TI    | 1e-10 m       |
| `nm`              | `nm`      |       | TI    | 1e-9 m        |
| `μm`              | `μm`      |       |       | 1e-6 m        |
| `mm`              | `mm`      | HP    | TI    | 1e-3 m        |
| `cm`              | `cm`      | HP    | TI    | 1e-2 m        |
| `m`               | `m`       | HP    | TI    | **base unit** |
| `km`              | `km`      | HP    | TI    | 1e3 m         |
| `mil`             | `mil`     |       | TI    | 1/1000 inch   |
| `inch`            | `in`      | HP    | TI    | 25.4 mm (exact) by defn |
| `foot`            | `ft`      | HP    | TI    | 12 inch       |
| `yard`            | `yd`      | HP    | TI    | 3 ft          |
| `mile`            | `mi`      | HP    | TI    | 1760 yd       |
| **`LENG > TYPO`** |           |       |       |               |
| `twip`            | `twip`    |       |       | 1/20 point    |
| `point`           | `pt`      |       |       | 1/72 inch     |
| `pica`            | `pica`    |       |       | 12 point      |
| **`LENG > SURV`** |           |       |       |               |
| `survey ft`       | `svft`    | HP    | TI    | using pre-2023 defn of 1200/3937 m |
| `rod`             | `rod`     | HP    | TI    | 16.5 ft       |
| `chain`           | `chai`    | HP    | TI    | 4 rods, 66 ft |
| `furlong`         | `frlg`    |       |       | 10 chains     |
| `survey mi`       | `svmi`    | HP    |       | using pre-2023 defn of 6336/3937 km; called "statutory mile" in HP-19BII |
| `league`          | `leag`    |       |       | 3 (normal) miles |
| **`LENG > NAUT`** |           |       |       |               |
| `fathom`          | `fath`    | HP    | TI    | 6 feet        |
| `cable`           | `cabl`    |       |       | 3429/15625 km |
| `nmile`           | `nmi`     | HP    | TI    | 1852 m (exact) by defn |
| **`LENG > ASTR`** |           |       |       |               |
| `light·sec`       | `lsec`    |       |       | 299792458 m (exact) by defn |
| `AU`              | `AU`      |       |       | 1.49597870700e11 (exact) by defn |
| `light·year`      | `ly`      |       | TI    | 9.4607304725808e15 (exact) |
| `parsec`          | `pc`      |       |       | 648000/pi AU = 30856775814913673 m (rounded to 14 digits) |

### Area (AREA)

| **Display Name**  | **Menu**  |**HP** |**TI** | **Comment**   |
| -------------     | --------- |------ |------ | ------------  |
| **`AREA`**        |           |       |       |               |
| `mm²`             | `mm²`     |       |       | 1e-6 m^2      |
| `cm²`             | `cm²`     | HP    | TI    | 1e-4 m^2      |
| `m²`              | `m²`      | HP    | TI    | **base unit** |
| `km²`             | `km²`     | HP    | TI    | 1e+6 m^2      |
| `inch²`           | `in²`     | HP    | TI    | (0.0254m)^2   |
| `foot²`           | `ft²`     | HP    | TI    | (0.3048m)^2   |
| `yard²`           | `yd²`     | HP    | TI    | (0.9144m)^2   |
| `mile²`           | `mi²`     | HP    | TI    | (1609.344m)^2  (exact) |
| `nmile²`          | `nmi²`    |       |       | (1852m)^2 (exact) |
| `acre`            | `acre`    | HP    | TI    | 66ft\*660ft   |
| `hectare`         | `ha`      | HP    | TI    | 100m\*100m    |
| `usftball`        | `usfb`    |       |       | US football field, 100yd\*160ft |
| `caftball`        | `cafb`    |       |       | CA football field, 110yd\*65yd |
| **`AREA > SURV`** |           |       |       |               |
| `rod²`            | `rod²`    | HP    |       | (16.5ft)^2    |
| `chain²`          | `chn²`    |       |       | (66ft)^2      |
| `furlong²`        | `fur²`    |       |       | (660ft)^2     |

### Volume (VOL)

| **Display Name**  | **Menu**  |**HP** |**TI** | **Comment**   |
| -------------     | --------- |------ |------ | ------------  |
| **`VOL`**         |           |       |       |               |
| `mm³`             | `mm³`     |       |       | 1e-9 m^3      |
| `cm³`             | `cm³`     |       | TI    | 1e-6 m^3      |
| `m³`              | `m³`      | HP    | TI    | **base unit** |
| `km³`             | `km³`     |       |       | 1e6 m^3       |
| `inch³`           | `in³`     | HP    | TI    | (0.0254m)^3   |
| `foot³`           | `ft³`     | HP    | TI    | (0.3048m)^3   |
| `yard³`           | `yd³`     | HP    |       | (0.9144m)^3   |
| `mile³`           | `mi³`     |       |       | (1609.344m)^3 |
| `nmile³`          | `nmi³`    |       |       | (1852m)^2 (exact) |
| `microliter`      | `μL`      |       |       | 1e-9 m^3      |
| `milliliter`      | `mL`      | HP    | TI    | 1e-6 m^3      |
| `liter`           | `L`       | HP    | TI    | 1e-3 m^3      |
| `metric tsp`      | `mtsp`    |       |       | metric teaspoon, 5 mL |
| `metric tbsp`     | `mtbs`    |       |       | metric tablespoon, 15 mL |
| **`VOL > US`**    |           |       |       |               |
| `tsp`             | `tsp`     | HP    | TI    | 1/3 tbsp        |
| `tbsp`            | `tbsp`    | HP    | TI    | 1/2 floz        |
| `floz`            | `floz`    | HP    | TI    | 1/4 gill        |
| `gill`            | `gill`    |       |       | 1/2 cup         |
| `cup`             | `cup`     | HP    | TI    | 1/2 pint        |
| `pint`            | `pint`    | HP    | TI    | 1/2 quart       |
| `quart`           | `qt`      | HP    | TI    | 1/4 gallon      |
| `gallon`          | `gal`     | HP    | TI    | 231 inch^3 by defn |
| **`VOL > IMP`**   |           |       |       |               |
| `imp tsp`         | `tsp`     |       |       | **1/4** imp tbsp |
| `imp tbsp`        | `tbsp`    |       |       | 1/2 imp floz     |
| `imp floz`        | `floz`    |       | TI    | **1/5** imp gill |
| `imp gill`        | `gill`    |       |       | 1/2 imp cup      |
| `imp cup`         | `cup`     |       |       | 1/2 imp pint     |
| `imp pint`        | `pint`    |       |       | 1/2 imp quart    |
| `imp quart`       | `qt`      |       |       | 1/4 imp gallon   |
| `imp gallon`      | `gal`     | HP    | TI    | 4.54609 liter (exact) by defn   |
| **`VOL > DRY`**   |           |       |       |               |
| `dry pint`        | `drpt`    |       |       | 33.6003125 inch^3 (exact) by defn |
| `dry quart`       | `drqt`    |       |       | 2 dry pint      |
| `dry gallon`      | `dgal`    | HP    |       | 4 dry quart     |
| `peck`            | `peck`    | HP    |       | 2 dry gallon    |
| `bushel`          | `bush`    | HP    |       | 4 peck          |
| `dry barrel`      | `dbbl`    |       |       | 7056 inch^3 (exact) by defn |
| **`VOL > MISC`**  |           |       |       |               |
| `board·foot`      | `bdft`    | HP    |       | 1/12 ft^3       |
| `oil barrel`      | `bbl`     | HP    |       | 42 US gallon by defn |
| `olmp pool`       | `olmp`    |       |       | Olympic swimming pool, 50m\*25m\*2m |
| `acre·foot`       | `acft`    | HP    |       | 66ft\*660ft\*1ft |

### Temperature (TEMP)

| **Display Name**  | **Menu**  |**HP** |**TI** | **Comment**   |
| -------------     | --------- |------ |------ | ------------  |
| **`TEMP`**        |           |       |       |               |
| `°C`              | `°C`      | HP    | TI    | Celsius = 273.15 + Kelvin |
| `°F`              | `°F`      | HP    | TI    | Fahrenheit = Celsius * 9 / 5 + 32 |
| `°R`              | `°R`      | HP    | TI    | Rankine = Kelvin * 9 / 5 |
| `°K`              | `°K`      | HP    | TI    | **base unit**, Kelvin, degree symbol used for UI consistency |

### Mass (MASS)

| **Display Name**  | **Menu**  |**HP** |**TI** | **Comment** |
| -------------     | --------- |------ |------ | ----------- |
| **`MASS`**        |           |       |       |             |
| `microgram`       | `μg`      |       |       | 1e-9 kg     |
| `milligram`       | `mg`      |       |       | 1e-6 kg     |
| `gram`            | `g`       | HP    | TI    | 1e-3 kg     |
| `kilogram`        | `kg`      | HP    | TI    | **base unit**  |
| `metric ton`      | `t`       | HP    | TI    | also known as tonne, 1000 kg  |
| `amu`             | `amu`     |       | TI    | atomic mass unit, also known as dalton (Da), 1.66053906892e-27 kg (measured) |
| **`MASS > US`**   |           |       |       |             |
| `grain`           | `grai`    | HP    |       | 1/7000 lb |
| `dram`            | `dram`    | HP    |       | 1/16 oz |
| `ounce`           | `oz`      | HP    |       | 1/16 lb |
| `pound`           | `lb`      | HP    | TI    | 0.45359237 kg (exact) by defn |
| `slug`            | `slug`    | HP    | TI    | 14.593902937207 kg (approx) |
| `short cwt`       | `scwt`    | HP    |       | short hundredweight, 100 lbs |
| `short ton`       | `ston`    | HP    | TI    | short ton, 200 cwt, 2000 lbs |
| **`MASS > IMP`**  |           |       |       |             |
| `pound`           | `lb`      | HP    | TI    | 0.45359237 kg (exact) by defn |
| `stone`           | `stne`    | HP    |       | 14 lbs |
| `quarter`         | `qrtr`    |       |       | 2 stones |
| `long cwt`        | `lcwt`    | HP    |       | long hundredweight, 8 stones, 112 lbs |
| `long ton`        | `lton`    | HP    |       | long ton, 200 lcwt, 2240 lbs |
| **`MASS > TROY`** |           |       |       |             |
| `grain`           | `grai`    |       |       | 1/7000 lb |
| `troy dwt`        | `dwt`     |       |       | troy pennyweight, 24 grains |
| `troy ounce`      | `ozt`     | HP    |       | troy ounce, 20 troy pennyweight |
| `troy pound`      | `lbt`     |       |       | troy pound, 12 troy oz |

### Force (FORC)

| **Display Name**  | **Menu**  |**HP** |**TI** | **Comment** |
| -------------     | --------- |------ |------ | ----------- |
| **`FORC`**        |           |       |       |             |
| `dyne`            | `dyne`    |       | TI    | 1e-5 N      |
| `newton`          | `N`       |       | TI    | **base unit**, kg\*m/s^2 |
| `kg force`        | `kgf`     |       | TI    | kilogram force = 9.80665 N (exact) by defn |
| `ton force`       | `tonf`    |       | TI    | metric ton force = 1000 kgf    |
| `poundal`         | `pdl`     |       |       | 1lb * 1ft/s^2 = 0.45359237 * 0.3048 = 0.138254954376 N (exact) |
| `lb force`        | `lbf`     |       | TI    | pound force = 1lb * 9.80665m/s^2 = 0.45359237 * 9.80665 = 4.4482216152605 N (exact) |
| `ston force`      | `stnf`    |       |       | short ton force = 2000 lbf    |
| `lton force`      | `ltnf`    |       |       | long ton force = 2240 lbf    |

### Press (PRES)

| **Display Name**  | **Menu**  |**HP** |**TI** | **Comment** |
| -------------     | --------- |------ |------ | ----------- |
| **`PRES`**        |           |       |       |             |
| `pascal`          | `Pa`      |       | TI    | **base unit**, N/m^2 |
| `hpascal`         | `hPa`     |       |       | 100 Pa      |
| `kpascal`         | `kPa`     |       |       | 1000 Pa     |
| `torr`            | `torr`    |       |       | 1/760 atm   |
| `atm`             | `atm`     |       | TI    | 101.325 kPa by defn |
| `millibar`        | `mbar`    |       |       | 1e-3 bar    |
| `decibar`         | `dbar`    |       |       | 1e-2 bar    |
| `bar`             | `bar`     |       | TI    | 100 kPa by defn |
| `psi`             | `psi`     |       | TI    | pounds per square inch = 6894.7572931684 Pa (rounded to 14 digits) |
| `mmHg`            | `mmH`     |       | TI    | mm of mercury = 133.322387415 Pa (exact) |
| `inHg`            | `inHg`    |       | TI    | inch of mercury = 3386.388640341 Pa (exact) |
| `mmH2O`           | `mmw`     |       | TI    | mm of water gauge = 9.80665 Pa (exact) by defn |
| `inH2O`           | `inwg`    |       | TI    | inch of water gauge = 249.08891 Pa (exact) |

### Energy (ENER)

| **Display Name**  | **Menu**  |**HP** |**TI** | **Comment** |
| -------------     | --------- |------ |------ | ----------- |
| **`ENER`**        |           |       |       |             |
| `eV`              | `eV`      |       | TI    | electron volt, 1.602176634e-19 J (exact) by defn |
| `erg`             | `erg`     |       | TI    | 1e-7 J        |
| `joule`           | `J`       |       | TI    | **base unit**, kg\*m/s^2 |
| `watt·h`          | `Wh`      |       |       | 3600 J        |
| `kwatt·h`         | `kWh`     |       | TI    | 3600e3 J      |
| `calorie`         | `cal`     |       | TI    | 4.184 J (exact) by defn |
| `kcalorie`        | `kcal`    |       |       | 4.184 kJ, used for food energy |
| `ft·lbf`          | `ftlb`    |       | TI    | 1.3558179483314 J (rounded to 14 digits) |
| `Btu`             | `Btu`     |       | TI    | British thermal unit, 1055 (approx, various defns) |
| `tonTNT`          | `tTNT`    |       |       | metric ton of equivalent of TNT, 4.184e9 J (exact) by defn |
| `liter·atm`       | `Latm`    |       | TI    | liter atmosphere, 101.325 J (exact) by defn |

### Power (PWR)

| **Display Name**  | **Menu**  |**HP** |**TI** | **Comment** |
| -------------     | --------- |------ |------ | ----------- |
| **`PWR`**         |           |       |       |             |
| `watt`            | `W`       |       | TI    | **base unit**, joule/s |
| `kilowatt`        | `kW`      |       |       | 1000 W      |
| `ft·lbf/s`        | `fl/s`    |       | TI    | foot-pound energy per second, 1.3558179483314 W (rounded to 14 digits) |
| `Btu/h`           | `Bt/h`    |       |       | Btu/hour, 0.29305555555556 W (rounded to 14 digits) |
| `Btu/min`         | `Bt/m`    |       | TI    | Btu/minute, 17.583333333333 W (rounded to 14 digits) |
| `calorie/s`       | `ca/s`    |       | TI    | calorie/second, 4.184 W (exact) by defn |
| `horsepower`      | `hp`      |       | TI    | horsepower, 745.69987158227 W (rounded to 14 digits) |

### Time (TIME)

| **Display Name**  | **Menu**  |**HP** |**TI** | **Comment**   |
| -------------     | --------- |------ |------ | -----------   |
| **`TIME`**        |           |       |       |               |
| `ns`              | `ns`      |       | TI    | 1e-9 s        |
| `μs`              | `μs`      |       | TI    | 1e-6 s        |
| `ms`              | `ms`      |       | TI    | 1e-3 s        |
| `second`          | `sec`     |       | TI    | **base unit** |
| `minute`          | `min`     |       | TI    | 60 seconds    |
| `hour`            | `hour`    |       | TI    | 60 minutes    |
| `day`             | `day`     |       | TI    | 24 hours      |
| `week`            | `week`    |       | TI    | 7 days        |
| `year`            | `year`    |       | TI    | Julian year, 365.25 days (exact) by defn |

### Speed (SPD)

| **Display Name**  | **Menu**  |**HP** |**TI** | **Comment**   |
| -------------     | --------- |------ |------ | -----------   |
| **`SPD`**         |           |       |       |               |
| `m/s`             | `m/s`     |       | TI    | **base unit** |
| `ft/s`            | `ft/s`    |       | TI    | 0.3048 m/s (exact) by defn |
| `km/hr`           | `kph`     |       | TI    | 1000/3600 m/s |
| `mi/hr`           | `mph`     |       | TI    | 1609.344/3600 m/s  (exact) by defn |
| `knot`            | `knot`    |       | TI    | nautical mile per hour, 1852 m/h (exact) by defn |
| `light c`         | `c`       |       |       | speed of light, 299792458 m/s (exact) by defn |

### Fuel (FUEL)

| **Display Name**  | **Menu**  |**HP** |**TI** | **Comment**   |
| -------------     | --------- |------ |------ | -----------   |
| **`FUEL`**        |           |       |       |               |
| `L/100km`         | `Lkm`     |       |       | **base unit**, liters per 100 km, Lkm = 100 * (liter/gallon) / (km/mile) / mpg |
| `mpg`             | `mpg`     |       |       | miles per US gallon, mpg = 100 * (liter/gallon) / (km/mile) / Lkm |
