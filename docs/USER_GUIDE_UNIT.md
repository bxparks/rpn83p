# RPN83P User Guide: UNIT Functions

This document describes the menu functions under the `UNIT` menu in RPN83P.
It has been extracted from [USER_GUIDE.md](USER_GUIDE.md) due to its length.

**Version**: 1.1.0 (2025-09-30)

**Parent Document**: [USER_GUIDE.md](USER_GUIDE.md)

**Project Home**: https://github.com/bxparks/rpn83p

## Table of Contents

- [UNIT Menu](#unit-menu)
- [UNIT Entry and Conversions](#unit-entry-and-conversions)
- [UNIT Arithmetic](#unit-arthimetic)
- [Supported Units](#supported-units)

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

The following is the complete list of supported units in RPN83P. It includes
*all* units from both the HP-19BII and the TI-85 calculators. The columns mean
the following:

- **Display Name**: the display name of the unit (up to 10 characters)
- **Menu**: the short name on the soft menu (3-4 characters)
- **HP**: the unit is found on the HP-19BII
- **TI**: the unit is found on the TI-85
- **Comment**: definitions of the less common units, and other comments

### Length (LENG)

| **Display Name**  | **Menu**  |**HP** |**TI** | **Comment**   |
| -------------     | --------- |------ |------ | ------------  |
| **`LENG`**        |           |       |       |               |
| `fermi`           | `ferm`    |       | TI    | 1e-15 m       |
| `angstrom`        | `angs`    |       | TI    | 1e-10 m       |
| `nm`              | `nm`      |       | TI    | 1e-9 m        |
| `μm`              | `μm`      |       |       | 1e-6 m        |
| `mm`              | `mm`      | HP    | TI    |               |
| `cm`              | `cm`      | HP    | TI    |               |
| `m`               | `m`       | HP    | TI    |               |
| `km`              | `km`      | HP    | TI    |               |
| `mil`             | `mil`     |       | TI    | 1/1000 in     |
| `inch`            | `in`      | HP    | TI    | 25.4 mm       |
| `foot`            | `ft`      | HP    | TI    | 12 in         |
| `yard`            | `yd`      | HP    | TI    | 3 ft          |
| `mile`            | `mi`      | HP    | TI    | 1760 yd       |
| **`LENG > TYPO`** |           |       |       |               |
| `twip`            | `twip`    |       |       | 1/20 pt       |
| `point`           | `pt`      |       |       | 1/72 inch     |
| `pica`            | `pica`    |       |       | 12 pt         |
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
| `nmi`             | `nmi`     | HP    | TI    | 1852 m (exact) by defn |
| **`LENG > ASTR`** |           |       |       |               |
| `light·sec`       | `lsec`    |       |       |               |
| `AU`              | `AU`      |       |       |               |
| `light·year`      | `ly`      |       | TI    |               |
| `parsec`          | `pc`      |       |       |               |

### Area (AREA)

| **Display Name**  | **Menu**  |**HP** |**TI** | **Comment**   |
| -------------     | --------- |------ |------ | ------------  |
| **`AREA`**        |           |       |       |               |
| `mm²`             | `mm²`     |       |       |               |
| `cm²`             | `cm²`     | HP    | TI    |               |
| `m²`              | `m²`      | HP    | TI    |               |
| `km²`             | `km²`     | HP    | TI    |               |
| `inch²`           | `in²`     | HP    | TI    |               |
| `foot²`           | `ft²`     | HP    | TI    |               |
| `yard²`           | `yd²`     | HP    | TI    |               |
| `mile²`           | `mi²`     | HP    | TI    |               |
| `nmi²`            | `nmi²`    |       |       |               |
| `acre`            | `acre`    | HP    | TI    | 66ft\*660ft   |
| `hectare`         | `ha`      | HP    | TI    | 100m\*100m    |
| `usftball`        | `usfb`    |       |       | US football field, 100yd\*160ft |
| `caftball`        | `cafb`    |       |       | CA football field, 110yd\*65yd |

### Volume (VOL)

| **Display Name**  | **Menu**  |**HP** |**TI** | **Comment**   |
| -------------     | --------- |------ |------ | ------------  |
| **`VOL`**         |           |       |       |               |
| `mm³`             | `mm³`     |       |       |               |
| `cm³`             | `cm³`     |       | TI    |               |
| `m³`              | `m³`      | HP    | TI    |               |
| `km³`             | `km³`     |       |       |               |
| `inch³`           | `in³`     | HP    | TI    |               |
| `foot³`           | `ft³`     | HP    | TI    |               |
| `yard³`           | `yd³`     | HP    |       |               |
| `mile³`           | `mi³`     |       |       |               |
| `nmi³`            | `nmi³`    |       |       |               |
| `μL`              | `μL`      |       |       |               |
| `mL`              | `mL`      | HP    | TI    |               |
| `L`               | `L`       | HP    | TI    |               |
| `met tsp`         | `mtsp`    |       |       | metric teaspoon, 5 mL |
| `met tbsp`        | `mtbs`    |       |       | metric tablespoon, 15 mL |
| **`VOL > US`**    |           |       |       |               |
| `tsp`             | `tsp`     | HP    | TI    | 1/3 tbsp        |
| `tbsp`            | `tbsp`    | HP    | TI    | 1/2 floz        |
| `floz`            | `floz`    | HP    | TI    | 1/4 gill        |
| `gill`            | `gill`    |       |       | 1/2 cup         |
| `cup`             | `cup`     | HP    | TI    | 1/2 pint        |
| `pint`            | `pint`    | HP    | TI    | 1/2 quart       |
| `quart`           | `qt`      | HP    | TI    | 1/4 gal         |
| `gal`             | `gal`     | HP    | TI    | 231 in^3 by defn|
| **`VOL > IMP`**   |           |       |       |               |
| `imp tsp`         | `tsp`     |       |       | **1/4** imp tbsp |
| `imp tbsp`        | `tbsp`    |       |       | 1/2 imp floz     |
| `imp floz`        | `floz`    |       | TI    | **1/5** imp gill |
| `imp gill`        | `gill`    |       |       | 1/2 imp cup      |
| `imp cup`         | `cup`     |       |       | 1/2 imp pint     |
| `imp pint`        | `pint`    |       |       | 1/2 imp quart    |
| `imp quart`       | `qt`      |       |       | 1/4 imp gal      |
| `imp gal`         | `gal`     | HP    | TI    | 4.54609 liter (exact) by defn   |
| **`VOL > DRY`**   |           |       |       |               |
| `dry pt`          | `drpt`    |       |       | 33.6003125 in^3 (exact) by defn |
| `dry qt`          | `drqt`    |       |       | 2 dry pint      |
| `dry gal`         | `dgal`    | HP    |       | 4 dry quart     |
| `peck`            | `peck`    | HP    |       | 2 dry gallon    |
| `bushel`          | `bush`    | HP    |       | 4 peck          |
| `dry bbl`         | `dbbl`    |       |       | 7056 in^3       |
| **`VOL > MISC`**  |           |       |       |               |
| `board·foot`      | `bdft`    | HP    |       | 1/12 ft^3       |
| `barrel`          | `bbl`     | HP    |       | oil barrel, 42 US gal by defn |
| `olmp pool`       | `olmp`    |       |       | Olympic swimming pool, 50m\*25m\*2m |
| `acre·foot`       | `acft`    | HP    |       | acre-foot, 66ft\*660ft\*1ft |

### Temperature (TEMP)

| **Display Name**  | **Menu**  |**HP** |**TI** | **Comment**   |
| -------------     | --------- |------ |------ | ------------  |
| **`TEMP`**        |           |       |       |               |
| `°C`              | `°C`      | HP    | TI    | Celsius = 273.15 + Kelvin |
| `°F`              | `°F`      | HP    | TI    | Fahrenheit = Celsius * 9 / 5 + 32 |
| `°R`              | `°R`      | HP    | TI    | Rankine = Kelvin * 9 / 5 |
| `°K`              | `°K`      | HP    | TI    | Kelvin, degree symbol used for UI consistency |

### Mass (MASS)

| **Display Name**  | **Menu**  |**HP** |**TI** | **Comment** |
| -------------     | --------- |------ |------ | ----------- |
| **`MASS`**        |           |       |       |             |
| `μg`              | `μg`      |       |       | 1e-6 g      |
| `mg`              | `mg`      | HP    |       |             |
| `g`               | `g`       | HP    | TI    |             |
| `kg`              | `kg`      | HP    | TI    |             |
| `met ton`         | `t`       | HP    | TI    | metric ton, also known as tonne, 1000 kg  |
| `amu`             | `amu`     |       | TI    | atomic mass unit, also known as Dalton, 1.66053906892e-27 kg (measured) |
| **`MASS > US`**   |           |       |       |             |
| `grain`           | `grai`    | HP    |       | 1/7000 lb |
| `dram`            | `dram`    | HP    |       | 1/16 oz |
| `ounce`           | `oz`      | HP    |       | 1/16 lb |
| `pound`           | `lb`      | HP    | TI    | 0.45359237 kg (exact) by defn |
| `slug`            | `slug`    | HP    | TI    | 14.593902937207 kg (approx) |
| `cwt`             | `cwt`     | HP    |       | hundredweight, 100 lbs |
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
| `troy ozt`        | `ozt`     | HP    |       | troy ounce, 20 troy pennyweight |
| `troy lbt`        | `lbt`     |       |       | troy pound, 12 troy oz |

### Force (FORC)

| **Display Name**  | **Menu**  |**HP** |**TI** | **Comment** |
| -------------     | --------- |------ |------ | ----------- |
| **`FORC`**        |           |       |       |             |
| `dyne`            | `dyne`    |       | TI    | 1e-5 N      |
| `newton`          | `N`       |       | TI    | base unit, kg\*m/s^2 |
| `kgf`             | `kgf`     |       | TI    | kilogram force = 9.80665 N (exact) by defn |
| `tonf`            | `tonf`    |       | TI    | metric ton force = 1000 kgf    |
| `poundal`         | `pdl`     |       |       | 1lb * 1ft/s^2 = 0.45359237 * 0.3048 = 0.138254954376 N (exact) |
| `lbf`             | `lbf`     |       | TI    | pound force = 1lb * 9.80665m/s^2 = 0.45359237 * 9.80665 = 4.4482216152605 N (exact) |
| `stonf`           | `stonf`   |       |       | short ton force = 2000 lbf    |
| `ltonf`           | `ltonf`   |       |       | long ton force = 2240 lbf    |

### Press (PRES)

| **Display Name**  | **Menu**  |**HP** |**TI** | **Comment** |
| -------------     | --------- |------ |------ | ----------- |
| **`PRES`**        |           |       |       |             |
| `Pa`              | `Pa`      |       | TI    | base unit, N/m^2 |
| `hPa`             | `hPa`     |       |       | 100 Pa      |
| `kPa`             | `kPa`     |       |       | 1000 Pa     |
| `torr`            | `torr`    |       |       | 1/760 atm   |
| `atm`             | `atm`     |       | TI    | 101.325 kPa by defn |
| `mbar`            | `mbar`    |       |       | 1e-3 bar    |
| `dbar`            | `dbar`    |       |       | 1e-2 bar    |
| `bar`             | `bar`     |       | TI    | 100 kPa by defn |
| `psi`             | `psi`     |       | TI    | lbs per sq inch = 6894.7572931684 Pa (rounded to 14 digits) |
| `mmHg`            | `mmH`     |       | TI    | mm of mercury = 133.322387415 Pa (exact) |
| `inHg`            | `inHg`    |       | TI    | inch of mercurcy = 3386.388640341 Pa (exact) |
| `mmH2O`           | `mmw`     |       | TI    | mm of water gauge = 9.80665 (exact) by defn |
| `inH2O`           | `inwg`    |       | TI    | inch of water gauge = 249.08891 Pa (exact) |

### Energy (ENER)

| **Display Name**  | **Menu**  |**HP** |**TI** | **Comment** |
| -------------     | --------- |------ |------ | ----------- |
| **`ENER`**        |           |       |       |             |
| `eV`              | `eV`      |       | TI    | electron volt |
| `erg`             | `erg`     |       | TI    | 1e-7 J        |
| `J`               | `J`       |       |       | base unit, kg\*m/s^2 |
| `Wh`              | `Wh`      |       |       | 3600 J        |
| `kWh`             | `kWh`     |       | TI    | 3600e3 J      |
| `cal`             | `cal`     |       | TI    | 4.184 J (exact) by defn |
| `kcal`            | `kcal`    |       |       | 4.184 kJ, used for food energy |
| `ft·lbf`          | `ftlb`    |       | TI    | 1.3558179483314 J (rounded to 14 digits) |
| `Btu`             | `Btu`     |       | TI    | British thermal unit, 1055 (approx, various defns) |
| `tonTNT`          | `tTNT`    |       |       | metric ton of equivalent of TNT, 4.184e9 J (exact) by defn |
| `liter·atm`       | `Latm`    |       | TI    | liter atmosphere, 101.325 J (exact) by defn |

### Power (PWR)

| **Display Name**  | **Menu**  |**HP** |**TI** | **Comment** |
| -------------     | --------- |------ |------ | ----------- |
| **`PWR`**         |           |       |       |             |
| `W`               | `W`       |       | TI    | base unit, joule/s |
| `kW`              | `kW`      |       |       | 1000 W      |
| `ft·lbf/s`        | `fl/s`    |       | TI    | foot-pound energy per second, 1.3558179483314 W (rounded to 14 digits) |
| `Btu/h`           | `Bt/h`    |       |       | Btu/hour, .29305555555556 W (rounded to 14 digits) |
| `Btu/min`         | `Bt/m`    |       | TI    | Btu/minute, 17.583333333333 W (rounded to 14 digits) |
| `cal/s`           | `ca/s`    |       | TI    | calorie/second, 4.184 W (exact) by defn |
| `hp`              | `hp`      |       | TI    | horsepower, 745.69987158227 W (rounded to 14 digits) |

### Time (TIME)

| **Display Name**  | **Menu**  |**HP** |**TI** | **Comment**   |
| -------------     | --------- |------ |------ | -----------   |
| **`TIME`**        |           |       |       |               |
| `ns`              | `ns`      |       | TI    | 1e-9 s        |
| `μs`              | `μs`      |       | TI    | 1e-6 s        |
| `ms`              | `ms`      |       | TI    | 1e-3 s        |
| `second`          | `sec`     |       | TI    | base unit     |
| `minute`          | `min`     |       | TI    | 60 seconds    |
| `hour`            | `hour`    |       | TI    | 60 minutes    |
| `day`             | `day`     |       | TI    | 24 hours      |
| `week`            | `week`    |       | TI    | 7 days        |
| `year`            | `year`    |       | TI    | Julian year, 365.25 days (exact) by defn |

### Speed (SPD)

| **Display Name**  | **Menu**  |**HP** |**TI** | **Comment**   |
| -------------     | --------- |------ |------ | -----------   |
| **`SPD`**         |           |       |       |               |
| `m/s`             | `m/s`     |       | TI    | base unit     |
| `ft/s`            | `ft/s`    |       | TI    | 0.3048 m/s (exact) by defn |
| `km/hr`           | `kph`     |       | TI    | 1000/3600 m/s |
| `mi/hr`           | `mph`     |       | TI    | 1609.344/3600 m/s  (exact) by defn |
| `knot`            | `knot`    |       | TI    | nautical mile per hour, 1852 m/h (exact) by defn |
| `light c`         | `c`       |       |       | speed of light, 299792458 m/s (exact) by defn |

### Fuel (FUEL)

| **Display Name**  | **Menu**  |**HP** |**TI** | **Comment**   |
| -------------     | --------- |------ |------ | -----------   |
| **`FUEL`**        |           |       |       |               |
| `L/100km`         | `Lkm`     |       |       | liters per 100 km, Lkm = 100 * (liter/gal) / (km/mile) / mpg |
| `mpg`             | `mpg`     |       |       | miles per US gal, mpg = 100 * (liter/gal) / (km/mile) / Lkm |
