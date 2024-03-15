# RPN83P User Guide: DATE

This document describes the `DATE` features of the RPN83P application. It has
been extracted from [RPN83P User Guide](USER_GUIDE.md) due to its length.

The `DATE` features are available under the `ROOT > DATE` menu item in the 3rd
row. [TODO: Insert screenshot of menu row]. Here is a quick summary of the
features:

- determine if a given year is a leap year
- calculate day of week (Monday-Sunday) from date
- add or subtract duration from Date
- calculate duration difference between 2 Dates
- add or subtract duration from Time
- calculate duration difference between 2 Times
- add or subtract duration from DateTime
- calculate duration difference between 2 DateTimes
- convert DateTime to different (fixed) timezones
- convert between DateTime to epoch seconds from a fixed Epoch date
- support multiple Epoch dates (Unix, NTP, GPS, custom, etc)
- set and retrieve the current date and time from the real time clock (RTC) of
  83+SE, 84+, and 84+SE (not supported on the 83+)

**Version**: 0.10.0 (2024-03-14)

**Project Home**: https://github.com/bxparks/rpn83p

## Table of Content

- [Calendar, Time, and Timezones](#calendar-time-and-timezones)
    - [Gregorian Calendar](#gregorian-calendar)
    - [POSIX time](#posix-time)
    - [Timezones](#timezones)
    - [Date and Time Formats](#date-and-time-formats)
- [Date Menus](#)
- [Date Buttons](#)
- [Date Objects](#)
    - [Data Entry](#)
    - [Display Formats](#)
    - [Date Record](#)
    - [Time Record](#)
    - [Duration Record](#)
    - [TimeZone Record](#)
    - [ZonedDateTime Record](#)
    - [DayOfWeek Record](#)
- [Timezone Conversion](#)
- [Epoch Date](#)
- [Real Time Clock](#)

## Calendar, Time, and Timezones

The following is a quick summary of the fundamental date and time concepts
used by the `DATE` functions in RPN83P. If you already know most of this,
you can skip this section and continue with the [DATE Menus](#date-menus).

The `DATE` functions of the RPN83P uses the [Proleptic Gregorian
calendar](https://en.wikipedia.org/wiki/Proleptic_Gregorian_calendar) with the
year restricted to `[1,9999]`. The [UNIX
time](https://en.wikipedia.org/wiki/Unix_time) (aka POSIX time) system is used
for counting the number of seconds per day. POSIX time is similar to [UTC
time](https://en.wikipedia.org/wiki/Coordinated_Universal_Time). The major
difference is that the duration of a POSIX *second* is not a constant, in
contrast to the SI *second* used by UTC, and POSIX time does not support [leap
seconds](https://en.wikipedia.org/wiki/Leap_second). Time zones are supported as
fixed offsets from UTC. Therefore, [daylight saving
time](https://en.wikipedia.org/wiki/Daylight_saving_time) transitions are *not*
supported. When date and time objects are displayed to the user, the RPN83P uses
the [RFC 3339](https://datatracker.ietf.org/doc/html/rfc3339) standard which is
a standard that is readily accessible, unlike the similar [ISO
8601](https://en.wikipedia.org/wiki/ISO_8601) standard which is paywalled and
more difficult to access. The RPN83P also provides access to the real time clock
(RTC) included in several of the TI calculators that it is compatible with
(83+SE, 84+, 84+SE, but not the 83+). The RPN83P supports quickly converting the
current date and time from the RTC into different timezones.

### Gregorian Calendar

Most of the world currently uses the [Gregorian
Calendar](https://en.wikipedia.org/wiki/Gregorian_calendar) system. The calendar
has a 400-year cycle, with each cycle containing 146097 days. Since 146097 is
divisible by 7, the day of the week (Monday to Sunday) associated with a given
date repeats itself every 400 years as well.

The Gregorian calendar was first introduced on October 15, 1582, but different
countries adopted the calendar at different times over the course of the
subsequent 400+ years. For simplicity, RPN83P does not support exact historical
dates, so it adopts the [Proleptic Gregorian
calendar](https://en.wikipedia.org/wiki/Proleptic_Gregorian_calendar) which
extends the Gregorian calendar backwards from 1582 even for those dates when the
Gregorian calendar did not exist.

There are 2 sources of time keeping that are convenient for humans:
1) the **solar day**, which is the length of time of one cycle of the apparent
motion of the sun across the sky due to the rotation of the earth, and
2) the **solar year** (or tropical year) which is the average length of time
that the sun takes to complete the astronomical seasons (equinox to equinox) due
the motion of the earth around the sun.

Roughly speaking, the solar day is defined to be 86400 seconds (or more
accurately, the second was originally defined to be 1/86400 of a mean solar
day). The solar year is slightly variable, but the mean is [365.2422 mean solar
days](https://en.wikipedia.org/wiki/Tropical_year). The complex leap year rules
of the Gregorian calendar arises from the fact that the solar year is not a
simple integral multiple of the solar day. Since humans find it convenient for
the calendar year to synchronize with the solar year, the Gregorian calendar
inserts leap days into various years occasionally so that the solar year and the
calendar year align. In the Gregorian system, the year is 146097/400 =
365.2425 days averaged over its 400-year cycle. This is close enough to the mean
solar year of 365.2422 days until about the year 3200 when the Gregorian
calendar year will be about [a day behind the actual solar
year](https://en.wikipedia.org/wiki/Tropical_year).

For practical reasons, the RPN83P limits the year range from 0001 to 9999. The
year 0 does not exist because the calendar system increments from 1 BC to 1 AD.
In effect, 1 BC is the year 0000. We avoid the complexity of dealing with
negative years by restricting the year range to be >= 0001. The maximum year of
9999 simplifies the user interface because it can restrict the rendering of the
year component to a maximum of 4 digits.

### POSIX Time

The *second* time unit was originally defined as 1/86400 of a solar day. The
problem with this definition is that the rate of earth's rotation is not a
constant. Eventually, the *second* was redefined to use highly accurate [atomic
clocks](https://en.wikipedia.org/wiki/Atomic_clock) resulting in the definition
of the [SI second](https://en.wikipedia.org/wiki/Second). The [Coordinated
Universal Time (UTC)](https://en.wikipedia.org/wiki/Coordinated_Universal_Time)
system uses the SI *second* unit to track the solar day of the earth in terms of
the SI *seconds*.

Since earth's rotation speed is irregular and slows down by [a few milliseconds
per century](https://en.wikipedia.org/wiki/Earth's_rotation). The UTC time
system resynchronizes the solar day with the day composed of 86400 *SI seconds*
by inserting a [leap second](https://en.wikipedia.org/wiki/Leap_second) every
few years, so that the difference between a UTC day and a solar day is no more
than 0.9s. During a leap second, which happens at the very last second of the
day, so that the final minute has 61 seconds instead of 60 seconds. A conforming
UTC clock goes from `23:59:59` to `23:59:60`, then rolls over to `00:00:00` to
start the next day. In theory, a negative leap second is possible, in which case
the clock would skip from `23:59:58` to `00:00:00` over a single second.

A [UNIX time](https://en.wikipedia.org/wiki/Unix_time) (aka POSIX time), is a
time measuring system originally implemented on UNIX systems, where the leap
second is ignored for simplicity. More precisely, POSIX time is a time system
where a *POSIX second* is a variable size. During a positive leap second, a
POSIX second equals 2 *SI seconds*, and a POSIX clock goes from `23:59:58` to
`23:59:59`, which is held for 2 seconds, before rolling over to `00:00:00`.
During a negative leap second, the POSIX second becomes reduced to 0 *SI
seconds*, so that a POSIX clock goes from `23:59:58` to `00:00:00` one second
later, skipping `23:59:59` instantly because the duration of `23:59:59` is
0-seconds long.

For simplicity, like many software libraries, the RPN83P calculator implements
POSIX time not UTC time. Leap seconds are *not* considered in any calculations.
If two datetimes are subtracted to calculate the duration between them, the
resulting number of seconds is calculated in terms POSIX seconds, not SI
seconds. To obtain the *actual* number of seconds between those 2 datetimes, we
would need to consult a table of leap seconds, and add the number of leap
seconds that were added between those 2 datetimes.

### Timezones

To maintain the convenience of having the location of the Sun near its highest
point in the sky when the local time is 12:00 noon, the world is divided into
[time zones](https://en.wikipedia.org/wiki/Time_zone). The local time is shifted
from the UTC time, usually in integral multiples of one hour, but locations
which are shifted by a multiple of 30 minutes or 15 minutes exist in the world.

Further complicating the calculation of the local time, many places observe
[daylight saving time](https://en.wikipedia.org/wiki/Daylight_saving_time) (DST)
during the summer months. The rules for when those DST transitions occur and the
size of the DST shift are determined by each country or jurisdiction. The most
complete database of all such rules is the [IANA TZ
database](https://en.wikipedia.org/wiki/Tz_database), incorporating between 350
to 600 timezones around the world (depending on how a "timezone" is defined).
The RPN83P does not currently support the IANA TZ database. It supports only
fixed UTC offsets.

### Date and Time Formats

The 2 commonly used conventions for representing dates and times on a computer
system is [RFC 3339](https://www.rfc-wiki.org/wiki/RFC3339) and [ISO
8601](https://en.wikipedia.org/wiki/ISO_8601). The ISO 8601 document, like all
ISO documents, is paywalled so most software developers have never seen the
actual document. There is a significant amount of overlap between the 2
standards, as shown in this [RFC 3339 vs ISO 8601 Venn
diagram](https://ijmacd.github.io/rfc3339-iso8601/).

The RPN83P follows the RFC 3339 conventions more closely than the ISO 8601. Here
are some examples:

- Date: `2024-03-14` (Mar 14, 2024)
- Time: `21:10:11` (9:10:11 pm)
- DateTime: `2024-03-14 21:10:11`
- UTC DateTime: `2024-03-15 05:10:11Z`
- ZonedDateTime: `2024-03-15 21:10:11-08:00`

Other conventions, such as the examples given in [List of date formats by
country](https://en.wikipedia.org/wiki/List_of_date_formats_by_country), are not
supported because they cause too many ambiguities for a calculator app whose
main purpose is to perform calculations on those quantities, instead of
displaying a date and time to the user. Here is a sample of date formats which
are *not* supported in the `DATE` functions of RPN83P:

- US dates `mm/dd/yyyy`, not supported
- Canadian dates `dd/mm/yyyy`, not supported
- French dates `dd/mm/yyyy`, not supported
- German dates `dd.mm.yyyy`, not supported
- Indian dates `dd-mm-yyyy`, not supported
- HP calculator dates `mm.ddyyyy`, not supported
- HP calculator dates `dd.mmyyyyy`, not supported
- 2-digit years, absolutely not supported
- 12-hour format `hh:mm:ss AM/PM`, not supported

## DATE Menus

The following menus items are located under the `DATE` menu:

- [TODO: screenshot of [DATE] menu]
    - [TODO: screenshot of [LEAP DOW DY>D D>DY]]
    - [TODO: screenshot of [Dx>S S>DR S>T S>DZ S>UT]]
    - [TODO: screenshot of [H>TZ TZ>H EPCH]]
        - [TODO: screenshot of [UNIX NTP GPS TIOS Y2K]]
        - [TODO: screenshot of [CEPC EPC EPC?]]
    - [TODO: screenshot of [DSHK DEXD DCUT DLNK]]
    - [TODO: screenshot of [NOW NOWD NOWT NWDZ NWUT]]
    - [TODO: screenshot of [TZ TZ? CTZ CTZ? SETC]]

## DATE Buttons

Here is a screenshot of the calculator with various buttons that are assigned to
`DATE` related functions:

[TODO: screenshot of calculator]

## Date-related Objects

Prior to the addition of DATE functions, the RPN83P supported 2 data types: real
and complex numbers. The DATE functions add 7 new data types which are *record*
types, composed of fields of more primitive integer types.

- Date `D{year:u16, month:u8, day:u8}`
- Time `T{hour:u8, minute:u8, second:u8}`
- DateTime `DT{year:u16, month:u8, day:u8, hour:u8, minute:u8, second:u8}`
- Duration `DR{days:i16, hours:i8, minutes:i8, seconds:i8}`
- TimeZone `TZ{hour:i8, minute:i8}`
- ZonedDateTime `DZ{year:u16, month:u8, day:u8, hour:u8, minute:u8, second:u8,
  tzhour:i8, tzminute:i8}`
- DayOfWeek `DW{dow:u8}`

If you are familiar with the C++ language, you may think of these Record
specifications as class constructors using brace-initialization, with the class
names being `D`, `T`, `DT`, `DR`, `TZ`, `DZ`, and `DW`.

The primitive integer types are:

- `u16`: unsigned 16-bit integer, [0, 65535]
- `u8`: unsigned 8-bit integer, [0, 255]
- `i16`: signed 32-bit integer, [-32768, 32767]
- `i8`: signed 8-bit integer, [-128, 127]

The RPN stack registers and storage registers have been upgraded to hold these
additional data types.

### Data Entry

To allow these Record types to be entered using the calculator buttons, the
following keys have been activated:

- `2ND {` and `2ND }`
- `ALPHA A` to `ALPHA Z`
- `,`

Prior to v0.10, both the `,` and `2ND EE` keystrokes were mapped to the `EE`
function to allow numbers in scientific notation to be entered easily. However
the entry of the Date Record objects requires the use of the comma `,` key, so
the app now contains an option to control the behavior of this button under the
`MODE` menu:

- [TODO: screenshot of [,EE EE, {..}, ".."]]

If the `,EE` option is selected, the button behaves as labeled on the keyboard:
- hitting `,` invokes the `,` function, and
- hitting `2ND EE` invokes the `EE` function.

If the `EE,` option is selected, the button actions are reversed:
- hitting `,` invokes the `EE` function, and
- hitting `2ND EE` invokes the `,` function.

The date record types are entered using the `ALPHA` key to enter the record
name, and the left brace `{` and right brace `}` keys to delimit the components
of the records. For example, to enter the Date value `D{2024,3,14}`, the
following keystrokes would be used:

```
ALPHA D
2ND {
2024
,
3
,
14
2ND }
```

For brevity and readability, this long sequence of keystrokes will be shortened
to something like `D{2024,3,14}` in the subsequent sections.

### Display Format

In the `MODE` menu, there are 2 settings that affect how date record objects are
displayed:

- [TODO: insert `MODE` menu]
    - [TODO: insert [,EE EE, {..} ".."]]

If the `{..}` option is selected (factory default), the records will be
displayed in their entry form using the curly braces. For example, the
`Date` record will be displayed as

```
D{2024,3,14}
```

If the `".."` option is selected, the records will be displayed as a
human-readable string. For example, the `D{2024,3,14}` record will be displayed
as

```
2024-03-14
```

Recall that when the `MODE` menu is activated using the `MODE` button, the "Jump
Back" feature is enabled, so that when the `ON/EXIT` button is pressed, the menu
jumps back to the prior menu location. This makes it easier to quickly change
the `{..}` or `".."` display modes.

### Date Record

The `Date` record has the form `D{year:u16, month:u8, day:u8}` and represents a
Gregorian calendar date. For example, the date `2024-03-14` is entered into the
calculator as `D{2024,3,14,}`. The human-readable string of this object when the
`".."` option is selected is `2024-03-14`.

#### Date Record Validation

Upon input termination, Date components are validated to make sure that it
represents a proper Gregorian calendar date. If the component is invalid, an
`Err:Invalid` error message is displayed. For example, if we try to enter the
invalid date `2024-02-30`, we get:

```
D{2024,2,30}
ENTER
(displays Err:Invalid)
```

Here is an incomplete list of validation rules:

- `year` component must be between 1 and 9999
- `month` component must be between 1 and 12
- `day` component must be between 1 and 31, and must be valid for the given
  month

#### Date Record Operations

Addition and subtraction operations are supported as shown in the following
table:

```
+---------------------------+-----------+
| Operation                 | Result    |
+---------------------------+-----------+
| {Date} + {integer}        | {Date}    |
| {integer} + {Date}        | {Date}    |
+---------------------------+-----------+
| {Date} - {integer}        | {Date}    |
| {Date} - {Date}           | {integer} |
+---------------------------+-----------+
| {integer} - {Date}        | INVALID   |
+---------------------------+-----------+
```

When operating on `Date` objects, integer values are assumed to be in units of
`days`. For example, let's add 20 days to the date of 2024-03-14:

```
D{2024,3,14} ENTER
20 +
(displays D{2024,4,3})
```

Let's subtract 30 days from that result, by typing
```
30 -
(displays D{2024,3,4})
```

We can subtract 2 Date records to obtain the number of whole days between the 2
dates:

```
D{2024,12,25} ENTER
D{2024,3,14} -
(displays 286)
```

There are 286 days from March 14 to Dec 25, 2024.

### Time Record

The `Time` record has the form `T{hour:u8, minute:u8, second:u8}`. For example,
the time `15:36:01` is entered into the calculator like this:

```
T{15,36,1}
```

If we switch the `MODE` setting from `{..}` to `".."`, the display will look
like:

```
15:36:01
```

#### Time Record Validation

The validation rules for a `Time` record is more straightforward than a `Date`
record:

- the `hour` component must be in the interval [0, 23]
- the `minute` component must be in the interval [0, 59]
- the `second` component must be in the interval [0, 59], leap seconds not
  supported

#### Time Record Operations

Just like `Date` records, addition and subtraction operations are supported as
summarized in the following table:

```
+---------------------------+-----------+
| Operation                 | Result    |
+---------------------------+-----------+
| {Time} + {integer}        | {Time}    |
| {integer} + {Time}        | {Time}    |
+---------------------------+-----------+
| {Time} - {integer}        | {Time}    |
| {Time} - {Time}           | {integer} |
+---------------------------+-----------+
| {integer} - {Time}        | INVALID   |
+---------------------------+-----------+
```

There 2 important differences:

1. The integers are in units of *seconds*, not *days*, and
2. If the resulting `Time` is less than `00:00:00` or greater than `24:00:00`,
the resulting time is renormalized so that it becomes within those bounds. In
other words, addition and subtraction operations are performed modulo 86400
seconds.

Let's add 234 seconds to `15:36:01`:

```
T{15,36,1} ENTER
234 +
(displays T{15,39,55})
```

Let's subtract 100_000 seconds (over a day) from `15:39:55`, which causes
wrapping around to the previous day:

```
100000 -
(displays T{11,53,15})
```

We can subtract 2 Time records to obtain the number of seconds between the 2
times:

```
T{15,36,1} ENTER
T{17,0,0} ENTER
-
(displays -5039)
```

There are 5039 seconds between `15:36:01` and `17:00:00`.

### DateTime Record

A DateTime record is a concatenation of the Date record and a Time record. It
has the format `DateTime `DT{year:u16, month:u8, day:u8, hour:u8, minute:u8,
second:u8}`. For example, the date `2024-03-14 15:36:01` would be entered like
this:

```
DT{2024,3,14,15,36,1}
```

When the `".."` display mode is selected, this object is displayed as the
following upon `ENTER`:

```
2024-03-14 15:35:01
```

#### DateTime Record Validation

The validation rules of the `DateTime` is the union of the validation rules
for the `Date` record and the rules for the `Time` record.

#### DateTime Record Operations

The addition and subtraction operations are available on the `DateTime` object,
just like `Date` and `Time`. The unit of integer numbers are *seconds*.

```
+---------------------------+---------------+
| Operation                 | Result        |
+---------------------------+---------------+
| {DateTime} + {integer}    | {DateTime}    |
| {integer} + {DateTime}    | {DateTime}    |
+---------------------------+---------------+
| {DateTime} - {integer}    | {DateTime}    |
| {DateTime} - {DateTime}   | {integer}     |
+---------------------------+---------------+
| {integer} - {DateTime}    | INVALID       |
+---------------------------+---------------+
```

For example, let's subtract 100_000 seconds from `2024-03-14 15:39:55`:

```
DT{2024,3,14,15,39,55 ENTER
100000 -
(displays DT{2024,3,13,11,53,15})
```

We can subtract 2 `DateTime` objects:

```
DT{2024,12,25,0,0,0} ENTER
DT{2024,3,14,15,36,1} -
(displays 24654239)
```

There are 24654239 seconds until Christmas Dec 25, 2024. We can convert this
into a `Duration` object (see below) by clicking on the `S>DR` menu item:

```
S>DR
(displays DR{285,8,23,59})
MODE
".."
(displays 285d 8h 23m 59s)
```

### Duration Record

The `Duration` object has the form `DR{days:i16, hours:i8, minutes:i8,
seconds:i8}`. It can be a positive or a negative quantity. For example, a
positive `Duration` object would be:

```
DR{1,2,3,4}
```

This is displayed as the following if the string display mode `".."` is
selected:

```
1d 2h 3m 4s
```

A negative duration would be:

```
DR{-4,0,-2,0}
```

which would be displayed as

```
-4d 2m
```

Notice that for negative durations, all the components must be negative (or
zero). Also notice that when a Duration component is exactly 0, that component
is omitted from the human-readable string format (in the case above, the `0h`
and `0s` components).

The `days` component is restricted to 4 digits, so the largest magnitude is
9999. Therefore, the largest duration that can be represented by the `Duration`
object is `9999d 23h 59m 59s` or about 24.3 years.

#### Duration Record Shorthand Entry

Often, we want to enter a single component without having to enter a `0` for the
other components. For example, to enter just "2 minutes", we would have to enter
`DR{0,0,2,0}`, and for "12 hours", we would need to enter `DR{0,12,0,0}`. The
RPN83P has an alternative "short modifier" entry format, using the `ALPHA :`
character. The following suffixes are recognized by the input system:

- `ss:S` - shorthand for `DR{0,0,0,ss}`, i.e. "ss seconds"
- `mm:M` - shorthand for `DR{0,0,mm,0}`, i.e. "mm minutes"
- `hh:H` - shorthand for `DR{0,hh,0,0}`, i.e. "hh hours"
- `dddd:D` - shorthand for `DR{dddd,0,0,0}`, i.e. "dddd days"

For example, to enter 2 minutes, we can type:

```
2:M
```

Hitting `ENTER` shows;

```
DR{0,0,2,0} (in MODE {..})
2m (in MODE "..")
```

To enter 12 hours, we can type:

```
12:H
```

Hitting `ENTER` shows:

```
DR{0,12,0,0} (in MODE {..})
12h (in MODE "..")
```

#### Duration Record Validation

The components of the Duration record has the following validation rules:

- the `days` component is currently limited to 4 digits [-9999,9999] (it could
  be extended to +/- 32767 with a little bit of coding)
- `hours` must be in the interval [-23,23]
- `minutes` must be in the interval [-59,59]
- `seconds` must be in the interval [-59,59]
- all components must have the same sign (or zero)

For example, if the signs are not consistent, an `Err:Invalid` will be shown:

```
DR{1, -2, 0, 1} ENTER
Err:Invalid
```

### Duration Record Operations

The Duration object is a convenient object because the addition and subtraction
operations are defined on the Duration object as well as the Date, Time, and
DateTime objects:

```
+---------------------------+---------------+
| Operation                 | Result        |
+---------------------------+---------------+
| {Duration} + {integer}    | {Duration}    |
| {integer} + {Duration}    | {Duration}    |
| {Duration} + {Duration}   | {Duration}    |
+---------------------------+---------------+
| {Duration} - {integer}    | {Duration}    |
| {Duration} - {Duration}   | {Duration}[*] |
+---------------------------+---------------+
| {integer} - {Duration}    | INVALID       |
+===========================+===============+
| {Date} + {Duration}       | {Date}        |
| {Duration} + {Date}       | {Date}        |
+---------------------------+---------------+
| {Date} - {Duration}       | {Date}        |
| {Duration} - {Date}       | INVALID       |
+===========================+===============+
| {Time} + {Duration}       | {Time}        |
| {Duration} + {Time}       | {Time}        |
+---------------------------+---------------+
| {Time} - {Duration}       | {Time}        |
| {Duration} - {Time}       | INVALID       |
+===========================+===============+
| {DateTime} + {Duration}   | {DateTime}    |
| {Duration} + {DateTime}   | {DateTime}    |
+---------------------------+---------------+
| {DateTime} - {Duration}   | {DateTime}    |
| {Duration} - {DateTime}   | INVALID       |
+---------------------------+---------------+

[*] For other record types, subtracting 2 objects of the same type produces an
integer. For Duration objects, it seemed more convenient to return a Duration
instead.
```

A good rule of thumb is that anywhere an integer can be used in a binary
operator involving a Date, Time, or DateTime object, a Duration object can be
used instead.

For example, let's add 2h 33m to the Time `12:58:32`:

```
T{12:58:32} ENTER
DR{0,2,33,0} +
(displays T{15,31,32})
```

For example, let's add 30d to the DateTime `2024-03-14 12:58:32`:

```
DT{2024,3,14,12:58:32} ENTER
30:D +
(displays DT{2024,4,13,12,58,32})
```

### TimeZone Record

### ZonedDateTime Record

### DayOfWeek Record

The `DayOfWeek` record has the form `DW{dow:u8}`, where the `dow` field is a
single integer containing the [ISO Weekday
number](https://en.wikipedia.org/wiki/ISO_8601), where Monday is represented by
1 and Sunday is represented by 7. For example, Thursday has an ISO weekday value
of 4 and can be entered as:

```
DW{4}
```

If we set the display `MODE` to `".."` string mode, the display will show:

```
Thu
```

#### DayOfWeek Record Validation

Upon input termination, the `dow` component is validated and if the component is
invalid, an `Err:Invalid` error message is displayed. For example, if we try to
enter the invalid DayOfWeek value of `DW{0}`, an error is shown:

```
DW{0}
ENTER
(displays Err:Invalid)
```

#### DayOfWeek Record Operations

Although it is unlikely to be needed often, addition and subtraction operations
have been implemented for the DayOfWeek object, mostly for consistency. To add 6
days to Thursday, we can enter:

```
DW{4} ENTER
6 +
(displays DW{3})
```

You can subtract 2 DayOfWeek objects, to get the number of days between them,
modulo 7:

```
DW{3} ENTER
DW{4} -
(displays -1)
```

There are -1 days from Thursday to Wednesday.

## Timezone Conversion

## Epoch Date

## Real Time Clock

## Date and Time Record Manipulations

### DCUT - Cut

### DLNK - Link

### DEXD - Extend

### DSHK - Shrink
