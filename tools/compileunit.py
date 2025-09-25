#!/usr/bin/env python3
#
# Copyright 2025 Brian T. Park
# MIT License.

"""
Compile the Unit Definition Language file into a TI-OS Z80 assembly language
file.

Usage:
$ compileunit.py [--debug] [--output unitdef.asm] unitdef.txt

"""

from typing import Dict
from typing import List
from typing import Optional
from typing import TextIO
from typing import Tuple
from typing import TypedDict

import argparse
import logging
import sys
import os
import math
from pprint import pp


def main() -> None:
    # Configure command line flags.
    parser = argparse.ArgumentParser(
        description='Compile the RPN83P unit definition file'
    )
    parser.add_argument(
        '--output', '-o',
        help='Assembly code output file',
        required=False,
    )
    parser.add_argument(
        '--debug',
        help='Print the AST for debugging',
        action='store_true',
        default=False,
    )
    parser.add_argument(
        'filename',
        help='Unit definition file',
    )
    args = parser.parse_args()

    # Configure logging. This should normally be executed after the
    # parser.parse_args() because it allows us set the logging.level using a
    # flag.
    logging.basicConfig(level=logging.INFO)

    # Open the input file and parse.
    logging.info(f"Reading {args.filename}")
    with open(args.filename) as file:
        lexer = Lexer(file)
        unitdef_parser = UnitDefParser(lexer)
        unit_types, units = unitdef_parser.parse()

    if args.debug:
        pp(unit_types, stream=sys.stderr)
        pp(units, stream=sys.stderr)

    validator = Validator(unit_types, units)
    validator.validate()

    sym_generator = SymbolGenerator(unit_types, units)
    sym_generator.generate()

    s_exploder = StringExploder(units)
    s_exploder.explode()

    f_exploder = FloatExploder(units)
    f_exploder.explode()

    if args.debug:
        pp(units, stream=sys.stderr)

    code_generator = CodeGenerator(
        args.filename, sym_generator, unit_types, units)

    # Determine the output file name.
    if args.output:
        outputname = args.output
    else:
        outputname = os.path.splitext(args.filename)[0] + ".asm"
    logging.info(f"Generating {outputname}")

    # Open the output file and generate
    with open(outputname, "w", encoding="utf-8") as file:
        code_generator.generate(file)


# -----------------------------------------------------------------------------


class UnitType(TypedDict, total=False):
    """A UnitType inside a UnitTypes list"""
    label: str  # source code label of unit type
    # derived fields
    id: int  # integer id of class


class Unit(TypedDict, total=False):
    """A Unit inside a Units list. """
    label: str  # source code label of unit
    name: str  # display name used with its value
    unit_type: str  # unit type
    scale: str  # size of unit measured in base_unit
    base_unit: str  # base unit
    # derived fields
    id: int  # integer id of unit
    scale_float: float  # optional group handler
    scale_bytes: bytes  # scale converted into 9 bytes
    scale_db_string: str  # bytes converted into 9 hex digits
    exploded_name: str  # exploded version of name
    name_contains_special: bool  # name contains special characters


# -----------------------------------------------------------------------------


class Lexer:
    """Read the sys.stdin and tokenize by spliting on white spaces. Comments
    begin with '#'.
    """
    def __init__(self, input: TextIO):
        self.input = input

        # Input line number, for error messages
        self.line_number = 0
        # Internal buffer to hold batches of tokens from each line.
        self.current_tokens: List[str] = []

    def get_token(self) -> str:
        token = self.get_token_or_none()
        if token is None:
            raise ValueError("Unexpected EOF")
        return token

    def get_token_or_none(self) -> Optional[str]:
        """Read the next token. Return None if EOF."""
        if len(self.current_tokens) == 0:
            current_line = self.read_line()
            if current_line is None:
                return None
            self.current_tokens = current_line.split()

        token = self.current_tokens[0]
        self.current_tokens = self.current_tokens[1:]
        return token

    def read_line(self) -> Optional[str]:
        """Return the next line. Return None if EOF reached.

        * Comment lines beginning with a '#' character are skipped.
        * Trailing comment lines beginning with '#' are rowped.
        * Trailing whitespaces are rowped.
        * Blank lines are skipped.
        * Leading whitespaces are kept.
        """
        while True:
            line = self.input.readline()
            self.line_number += 1

            # EOF returns ''. A blank line returns '\n'.
            if line == '':
                return None

            # remove trailing comments
            i = line.find('#')
            if i >= 0:
                line = line[:i]

            # row any trailing whitespaces
            line = line.rstrip()

            # skip any blank lines after rowping
            if not line:
                continue

            return line


# -----------------------------------------------------------------------------


class UnitDefParser:
    """Create an abstract syntax tree (AST) of UnitTypes and Units in the
    unit definition file.
    """
    def __init__(self, lexer: Lexer):
        self.lexer = lexer

    def parse(self) -> Tuple[List[UnitType], List[Unit]]:
        unit_types = self.process_unit_types()
        units = self.process_units()
        return unit_types, units

    def process_unit_types(self) -> List[UnitType]:
        token = self.lexer.get_token()
        if token != 'UnitTypes':
            raise ValueError(
                f"Unexpected '{token}' "
                f"at line {self.lexer.line_number}, expected 'UnitTypes'"
            )
        token = self.lexer.get_token()
        if token != '[':
            raise ValueError(
                f"Unexpected '{token}' "
                f"at line {self.lexer.line_number}, expected '['"
            )
        classes: List[UnitType] = []
        while True:
            token = self.lexer.get_token()
            if token == 'UnitType':
                unit_type: UnitType = {}
                token = self.lexer.get_token()
                unit_type['label'] = token
                classes.append(unit_type)
            elif token == ']':
                break
            else:
                raise ValueError(
                    f"Unexpected '{token}' "
                    f"at line {self.lexer.line_number}, expected ']'"
                )
        return classes

    def process_units(self) -> List[Unit]:
        token = self.lexer.get_token()
        if token != 'Units':
            raise ValueError(
                f"Unexpected '{token}' "
                f"at line {self.lexer.line_number}, expected 'Units'"
            )
        token = self.lexer.get_token()
        if token != '[':
            raise ValueError(
                f"Unexpected '{token}' "
                f"at line {self.lexer.line_number}, expected '['"
            )
        units: List[Unit] = []
        while True:
            token = self.lexer.get_token()
            if token == 'Unit':
                unit: Unit = {}

                token = self.lexer.get_token()
                unit['label'] = token

                token = self.lexer.get_token()
                unit['name'] = token

                token = self.lexer.get_token()
                unit['unit_type'] = token

                token = self.lexer.get_token()
                unit['scale'] = token

                token = self.lexer.get_token()
                unit['base_unit'] = token

                units.append(unit)
            elif token == ']':
                break
            else:
                raise ValueError(
                    f"Unexpected '{token}' "
                    f"at line {self.lexer.line_number}, expected ']'"
                )
        return units


# -----------------------------------------------------------------------------


class SymbolGenerator:
    """Generate the internal ids and symbols."""

    def __init__(self, unit_types: List[UnitType], units: List[Unit]):
        self.unit_types = unit_types  # unit_types by id
        self.units = units
        self.units = units

        self.unit_by_id: Dict[int, Unit] = {}  # {id -> Unit}
        self.unit_type_by_id: Dict[int, UnitType] = {}  # {id -> UnitType}

    def generate(self) -> None:
        self.generate_unit_type_ids()
        self.generate_unit_ids()

    def generate_unit_type_ids(self) -> None:
        id_counter = 0
        for unit_type in self.unit_types:
            self.unit_type_by_id[id_counter] = unit_type
            unit_type['id'] = id_counter
            id_counter += 1

    def generate_unit_ids(self) -> None:
        id_counter = 0
        for unit in self.units:
            self.unit_by_id[id_counter] = unit
            unit['id'] = id_counter
            id_counter += 1


# -----------------------------------------------------------------------------


class Validator:
    """Validate the unit_types and units."""

    def __init__(self, unit_types: List[UnitType], units: List[Unit]):
        self.unit_types = unit_types
        self.units = units

    def validate(self) -> None:
        self.validate_unit_types()
        self.validate_units()

    def validate_unit_types(self) -> None:
        # Check for duplicate labels.
        self.unit_type_by_label: Dict[str, UnitType] = {}
        for unit_type in self.unit_types:
            label = unit_type['label']
            if label in self.unit_type_by_label:
                raise ValueError(f"Duplicate UnitType label '{label}'")
            self.unit_type_by_label[label] = unit_type

    def validate_units(self) -> None:
        # Check for duplicate labels.
        self.unit_by_label: Dict[str, Unit] = {}
        for unit in self.units:
            label = unit['label']
            if label in self.unit_by_label:
                raise ValueError(f"Duplicate Unit label '{label}'")
            self.unit_by_label[label] = unit

        # Check Unit.unit_type points to a valid UnitType
        for unit in self.units:
            label = unit['label']
            unit_type_label = unit['unit_type']
            if unit_type_label not in self.unit_type_by_label:
                raise ValueError(
                    f"Unknown UnitType '{unit_type_label}' "
                    + f"for Unit '{label}'"
                )

        # Check that the baseUnit of the unit is the same type as the unit
        # itself. Otherwise, the baseUnit doesn't make sense.
        for unit in self.units:
            label = unit['label']
            unit_type_label = unit['unit_type']
            base_unit_label = unit['base_unit']
            base_unit = self.unit_by_label[base_unit_label]
            base_unit_type_label = base_unit['unit_type']
            if unit_type_label != base_unit_type_label:
                raise ValueError(
                    f"Invalid baseUnit '{base_unit_label}' for unit '{label}': "
                    f"baseUnitType is '{base_unit_type_label}' "
                    f"but should be '{unit_type_label}'")

# -----------------------------------------------------------------------------


class StringExploder:
    """Determine if the unit 'name' contains special characters, and
    explode the name string into a list of single characters.

    1) If the string contains only simple letters ([a-zA-Z0-9]), then the
    CodeGenerator will use the string unchanged. For example, if the name is
    "NUM", then the generated assembly code will look like:

    .db "NUM", 0

    2) If the string contains any special characters, those must be referenced
    using the identifier from the Small Font table, and enclosed in '<' and '>'.
    The CodeGenerator will generate a list of single characters for the name.
    For example, if the unit name is "<Sdegree>F", then the exploded_name will
    contain "Sdegree, 'F'", so that the .db statement in the generated assembly
    code will look like:

    .db Sdegree, 'F', 0
    """
    def __init__(self, units: List[Unit]):
        self.units = units

    def explode(self) -> None:
        for unit in self.units:
            self.explode_unit(unit)

    def explode_unit(self, unit: Unit) -> None:
        # name
        label = unit["label"]
        name = unit["name"]
        unit["name_contains_special"] = (
            name.find('<') >= 0 or name.find('>') >= 0
        )
        try:
            unit["exploded_name"] = self.explode_str(name)
        except ValueError as e:
            raise ValueError(
                f"Invalid syntax in unit '{label}': {str(e)}"
            )

    @staticmethod
    def explode_str(s: str) -> str:
        i = 0
        chars: List[str] = []
        while i < len(s):
            c = s[i]
            if (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or \
                    (c >= '0' and c <= '9'):
                chars.append(f"'{c}'")
            elif c == '<':
                j = s.find('>', i)
                if j < 0:
                    raise ValueError(f"Missing '>' in string '{s}'")
                fonttag = s[i + 1:j]  # extract word inside <...>
                if not fonttag:
                    raise ValueError(f"Empty <> in string '{s}'")
                chars.append(fonttag)
                i = j
            else:
                raise ValueError(f"Unsupported character '{c}'")
            i += 1
        return ", ".join(chars)


# -----------------------------------------------------------------------------


class FloatExploder:
    """Convert the floating point number in 'scale' to the 9-byte native
    format used by TI-OS."""

    def __init__(self, units: List[Unit]):
        self.units = units

    def explode(self) -> None:
        for unit in self.units:
            self.explode_unit(unit)

    def explode_unit(self, unit: Unit) -> None:
        scale = unit['scale']
        scale_float = float(scale)
        unit['scale_float'] = scale_float
        scale_bytes = self.explode_float(scale_float)
        unit['scale_bytes'] = scale_bytes
        unit['scale_db_string'] = self.convert_to_db_string(scale_bytes)

    @staticmethod
    def explode_float(x: float) -> bytes:
        """Convert the float into TIOS float in scientific notation with 14
        significant digits."""

        # Human readable version of TIOS float number
        tios_str = f"{x:.14e}"

        # Exponent
        exponent = math.floor(math.log10(x))
        if exponent < -99 or exponent > 99:
            raise ValueError(f"Exponent too large: '{tios_str}'")
        ti_exponent = exponent + 128

        # Mantissa
        ti_digits = tios_str[0:16]
        ti_digits = ti_digits.replace('.', '')

        # Convert to the 9-byte binary representation TIOS floating number
        hexes = bytearray()
        hexes.append(0)  # objectType
        hexes.append(ti_exponent)  # exponent as one binary byte
        for i in range(0, 14, 2):
            # Convert 7 pairs of digits to BCD notation
            byte = int(ti_digits[i]) * 16 + int(ti_digits[i + 1])
            hexes.append(byte)

        return bytes(hexes)

    @staticmethod
    def convert_to_db_string(scale_bytes: bytes) -> str:
        # TODO: Use io.StringIO() for more efficient creation of string
        s = ""
        counter = 0
        for b in scale_bytes:
            hex_string = f"${b:02X}"
            separator = "" if counter == 8 else ", "
            s += hex_string + separator
            counter += 1
        return s


# -----------------------------------------------------------------------------


class CodeGenerator:
    """Generate the Z80 assembly statements. There are 3 sections:
    1) the list of unit types
    2) 'unitTable' with the list of units
    3) the C-strings used by the units, composed of the pool of c-strings
    concatenated together.
    """
    def __init__(
        self,
        inputfile: str,
        symbols: SymbolGenerator,
        unit_types: List[UnitType],
        units: List[Unit],
    ):
        self.inputfile = inputfile
        self.unit_types = unit_types
        self.units = units
        self.symbols = symbols

    def generate(self, output: TextIO) -> None:
        self.output = output

        print(f"""\
;-----------------------------------------------------------------------------
; Unit definitions, generated from {self.inputfile}.
; See unit1.asm for the equivalent C struct declaration.
;
; There are 3 sections:
;   - list of unit types
;   - list of units
;   - list of unit names
;
; DO NOT EDIT: This file was autogenerated.
;-----------------------------------------------------------------------------

""", file=self.output, end='')

        logging.info("  Generating unit types")
        self.generate_unit_types()
        #
        logging.info("  Generating units")
        self.generate_units()
        #
        logging.info("  Generating names")
        self.generate_names()

    def generate_unit_types(self) -> None:
        unit_types_count = len(self.unit_types)
        print(f"""\
;-----------------------------------------------------------------------------
; List of unit types.
;-----------------------------------------------------------------------------

unitTypesCount equ {unit_types_count} ; number of unit types

""", file=self.output, end='')

        for unit_type in self.unit_types:
            label = unit_type['label']
            id = unit_type['id']
            print(f"unitType{label} equ {id}", file=self.output)

    def generate_units(self) -> None:
        units_count = len(self.units)
        print(f"""\

;-----------------------------------------------------------------------------
; List of units.
;-----------------------------------------------------------------------------

unitsCount equ {units_count} ; number of units
unitInfoTable:

""", file=self.output, end='')

        for unit in self.units:
            label = unit['label']
            id = unit['id']
            unit_type = unit['unit_type']
            base_unit = unit['base_unit']
            scale = unit['scale']
            scale_db_string = unit['scale_db_string']

            print(f"""\
unit{label}Info:
unit{label}Id equ {id}
    .dw unit{label}Name ; name
    .db unitType{unit_type} ; unitType
    .db unit{base_unit}Id ; baseUnitId
    .db {scale_db_string} ; scale={scale}
""", file=self.output, end='')

    def generate_names(self) -> None:
        unit_names_count = len(self.units)

        # Calculate total size of string pool
        unit_names_pool_size = 0
        for unit in self.units:
            name = unit['name']
            unit_names_pool_size += len(name) + 1  # include NUL

        print(f"""\

;-----------------------------------------------------------------------------
; List of unit names.
;-----------------------------------------------------------------------------

unitNamesCount equ {unit_names_count} ; number of unit names
unitNamesPoolSize equ {unit_names_pool_size} ; size of unit names string pool

""", file=self.output, end='')

        for unit in self.units:
            label = unit['label']
            name_contains_special = unit["name_contains_special"]
            if name_contains_special:
                name = unit['exploded_name']
            else:
                name = unit['name']
                name = f'"{name}"'

            print(f"""\
unit{label}Name:
    .db {name}, 0
""", file=self.output, end='')


# -----------------------------------------------------------------------------


if __name__ == '__main__':
    main()
