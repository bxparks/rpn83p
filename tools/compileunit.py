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
        content = unitdef_parser.parse()

    if args.debug:
        pp(content['unit_types'], stream=sys.stderr)
        pp(content['units'], stream=sys.stderr)

    sym_generator = SymbolGenerator(content)
    sym_generator.generate()

    validator = Validator(content)
    validator.validate()

    s_exploder = StringExploder(content)
    s_exploder.explode()

    f_exploder = FloatExploder(content)
    f_exploder.explode()

    if args.debug:
        pp(content['units'], stream=sys.stderr)

    code_generator = CodeGenerator(args.filename, content)

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
    label: str  # assembly code label of unit type
    name: str  # display name for this unit type
    base_unit: str  # base unit for all units of this type
    # derived fields
    id: int  # integer id of class
    exploded_chars: List[str]  # list of individual chars in name
    exploded_name: str  # exploded version of name
    name_contains_special: bool  # name contains special characters


class Unit(TypedDict, total=False):
    """A Unit inside a Units list. """
    label: str  # assembly code label of unit
    name: str  # display name used with its value
    unit_type: str  # unit type label
    scale: str  # scale of unit measured in base_unit of the unit_type
    # derived fields
    id: int  # integer id of unit
    scale_float: float  # 'scale' string converted into Python float type
    scale_bytes: bytes  # 'scale' converted into 9 bytes of TIOS float type
    scale_db_string: str  # 'scale_bytes' converted into 9 hex digits
    exploded_chars: List[str]  # list of individual chars in name
    exploded_name: str  # exploded version of name
    name_contains_special: bool  # name contains special characters


class ParsedContent(TypedDict, total=False):
    """The parsed content of the unitdef file."""
    units: List[Unit]
    unit_types: List[UnitType]

    unit_types_by_id: Dict[int, UnitType]  # {id -> UnitType}
    unit_types_by_label: Dict[str, UnitType]  # {label -> UnitType}

    units_by_id: Dict[int, Unit]  # {id -> Unit}
    units_by_label: Dict[str, Unit]  # {label -> Unit}


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

    def parse(self) -> ParsedContent:
        content: ParsedContent = {}
        content['unit_types'] = self.process_unit_types()
        content['units'] = self.process_units()
        return content

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
        types: List[UnitType] = []
        while True:
            token = self.lexer.get_token()
            if token == 'UnitType':
                unit_type: UnitType = {}

                token = self.lexer.get_token()
                unit_type['label'] = token

                token = self.lexer.get_token()
                unit_type['name'] = token

                token = self.lexer.get_token()
                unit_type['base_unit'] = token

                types.append(unit_type)
            elif token == ']':
                break
            else:
                raise ValueError(
                    f"Unexpected '{token}' "
                    f"at line {self.lexer.line_number}, expected ']'"
                )
        return types

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
    """Generate the internal ids, symbols, and references."""

    def __init__(self, content: ParsedContent):
        self.content = content

    def generate(self) -> None:
        self.generate_unit_types_by_id()
        self.generate_unit_types_by_label()
        self.generate_units_by_id()
        self.generate_units_by_label()
        self.resolve_base_unit_ids()

    def generate_unit_types_by_id(self) -> None:
        id_counter = 0
        self.content['unit_types_by_id'] = {}
        for unit_type in self.content['unit_types']:
            self.content['unit_types_by_id'][id_counter] = unit_type
            unit_type['id'] = id_counter
            id_counter += 1

    def generate_unit_types_by_label(self) -> None:
        """Throws if duplicate unit label found."""
        self.content['unit_types_by_label'] = {}
        for unit_type in self.content['unit_types']:
            label = unit_type['label']
            existing_unit_type = self.content['unit_types_by_label'].get(label)
            if existing_unit_type is not None:
                raise ValueError(f"Duplicate UnitType '{label}' found")
            self.content['unit_types_by_label'][label] = unit_type

    def generate_units_by_id(self) -> None:
        id_counter = 0
        self.content['units_by_id'] = {}
        for unit in self.content['units']:
            self.content['units_by_id'][id_counter] = unit
            unit['id'] = id_counter
            id_counter += 1

    def generate_units_by_label(self) -> None:
        """Throws if duplicate unitType label found."""
        self.content['units_by_label'] = {}
        for unit in self.content['units']:
            label = unit['label']
            existing_unit = self.content['units_by_label'].get(label)
            if existing_unit is not None:
                raise ValueError(f"Duplicate Unit '{label}' found")
            self.content['units_by_label'][label] = unit

    def resolve_base_unit_ids(self) -> None:
        """Resolve the 'base_unit' reference in the UnitType to the
        id of the Unit object."""

# -----------------------------------------------------------------------------


class Validator:
    """Validate the unit_types and units."""

    def __init__(self, content: ParsedContent):
        self.content = content

    def validate(self) -> None:
        self.validate_unit_types()
        self.validate_units()

    def validate_unit_types(self) -> None:
        """Validate unit_types."""
        # Check for duplicate display names.
        unit_types_by_name: Dict[str, UnitType] = {}
        for unit_type in self.content['unit_types']:
            name = unit_type['name']
            if name in unit_types_by_name:
                raise ValueError(f"Duplicate UnitType name '{name}'")
            unit_types_by_name[name] = unit_type

        # Check that the base_unit refers to an existing unit.
        for unit_type in self.content['unit_types']:
            unit_type_label = unit_type['label']
            base_unit_label = unit_type['base_unit']
            base_unit = self.content['units_by_label'].get(base_unit_label)
            if base_unit is None:
                raise ValueError(
                    f"UnitType '{unit_type_label}': "
                    f"Unknown baseUnit '{base_unit_label}'")

    def validate_units(self) -> None:
        """Validate units."""
        # Check for duplicate display names.
        units_by_name: Dict[str, Unit] = {}
        for unit in self.content['units']:
            name = unit['name']
            if name in units_by_name:
                raise ValueError(f"Duplicate Unit label '{name}'")
            units_by_name[name] = unit

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
    def __init__(self, content: ParsedContent):
        self.content = content

    def explode(self) -> None:
        for unit in self.content['units']:
            self.explode_unit(unit)

        for unit_type in self.content['unit_types']:
            self.explode_unit_type(unit_type)

    def explode_unit(self, unit: Unit) -> None:
        label = unit["label"]
        name = unit["name"]
        unit["name_contains_special"] = (
            name.find('<') >= 0 or name.find('>') >= 0
        )
        try:
            chars = self.explode_str(name)
            unit["exploded_chars"] = chars
            unit["exploded_name"] = ", ".join(chars)
        except ValueError as e:
            raise ValueError(
                f"Invalid syntax in Unit '{label}': {str(e)}"
            )

    def explode_unit_type(self, unit_type: UnitType) -> None:
        label = unit_type["label"]
        name = unit_type["name"]
        unit_type["name_contains_special"] = (
            name.find('<') >= 0 or name.find('>') >= 0
        )
        try:
            chars = self.explode_str(name)
            unit_type["exploded_chars"] = chars
            unit_type["exploded_name"] = ", ".join(chars)
        except ValueError as e:
            raise ValueError(
                f"Invalid syntax in UnitType '{label}': {str(e)}"
            )

    @staticmethod
    def explode_str(s: str) -> List[str]:
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
        return chars


# -----------------------------------------------------------------------------


class FloatExploder:
    """Convert the floating point number in 'scale' to the 9-byte native
    format used by TI-OS."""

    def __init__(self, content: ParsedContent):
        self.units = content['units']

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
    """Generate the Z80 assembly statements. There are 4 sections:
    1) 'unitTypeTable' with the list of UnitTypes
    2) the C-strings used by the unitTypes, composed of the pool of c-strings
    concatenated together.
    3) 'unitTable' with the list of Units
    4) the C-strings used by the units, composed of the pool of c-strings
    concatenated together.
    """
    def __init__(
        self,
        inputfile: str,
        content: ParsedContent,
    ):
        self.inputfile = inputfile
        self.content = content

    def generate(self, output: TextIO) -> None:
        self.output = output

        print(f"""\
;-----------------------------------------------------------------------------
; Unit definitions, generated from {self.inputfile}.
; See unit1.asm for the equivalent C struct declaration.
;
; There are 4 sections:
; - list of UnitTypes
; - list of UnitType names
; - list of Units
; - list of Unit names
;
; DO NOT EDIT: This file was autogenerated.
;-----------------------------------------------------------------------------

""", file=self.output, end='')

        logging.info("  Generating UnitTypes")
        self.generate_unit_types()

        logging.info("  Generating UnitType names")
        self.generate_unit_type_names()

        logging.info("  Generating Units")
        self.generate_units()

        logging.info("  Generating Unit names")
        self.generate_unit_names()

    def generate_unit_types(self) -> None:
        unit_types_count = len(self.content['unit_types'])
        print(f"""\
;-----------------------------------------------------------------------------
; List of UnitTypes.
;-----------------------------------------------------------------------------

unitTypesCount equ {unit_types_count} ; number of unit types
unitTypeTable:

""", file=self.output, end='')

        for unit_type in self.content['unit_types']:
            label = unit_type['label']
            base_unit = unit_type['base_unit']
            id = unit_type['id']
            print(f"""\
unitType{label}Info:
unitType{label}Id equ {id}
    .dw unitType{label}Name ; name
    .db unit{base_unit}Id ; baseUnit
""", file=self.output, end='')

    def generate_unit_type_names(self) -> None:
        unit_type_names_count = len(self.content['units'])

        # Calculate total size of string pool
        unit_type_names_pool_size = 0
        for unit in self.content['unit_types']:
            chars = unit['exploded_chars']
            unit_type_names_pool_size += len(chars) + 1  # include NUL

        print(f"""\

;-----------------------------------------------------------------------------
; List of UnitType names.
;-----------------------------------------------------------------------------

unitTypeNamesCount equ {unit_type_names_count} ; number of unit type names
unitTypeNamesPoolSize equ {unit_type_names_pool_size} \
; size of unit type names string pool

""", file=self.output, end='')

        for unit_type in self.content['unit_types']:
            label = unit_type['label']
            name_contains_special = unit_type["name_contains_special"]
            if name_contains_special:
                name = unit_type['exploded_name']
            else:
                name = unit_type['name']
                name = f'"{name}"'

            print(f"""\
unitType{label}Name:
    .db {name}, 0
""", file=self.output, end='')

    def generate_units(self) -> None:
        units_count = len(self.content['units'])
        print(f"""\

;-----------------------------------------------------------------------------
; List of Units.
;-----------------------------------------------------------------------------

unitsCount equ {units_count} ; number of units
unitTable:

""", file=self.output, end='')

        for unit in self.content['units']:
            label = unit['label']
            id = unit['id']
            unit_type = unit['unit_type']
            scale = unit['scale']
            scale_db_string = unit['scale_db_string']

            print(f"""\
unit{label}Info:
unit{label}Id equ {id}
    .dw unit{label}Name ; name
    .db unitType{unit_type}Id ; unitTypeId
    .db {scale_db_string} ; scale={scale}
""", file=self.output, end='')

    def generate_unit_names(self) -> None:
        unit_names_count = len(self.content['units'])

        # Calculate total size of string pool
        unit_names_pool_size = 0
        for unit in self.content['units']:
            exploded_chars = unit['exploded_chars']
            unit_names_pool_size += len(exploded_chars) + 1  # include NUL

        print(f"""\

;-----------------------------------------------------------------------------
; List of Unit names.
;-----------------------------------------------------------------------------

unitNamesCount equ {unit_names_count} ; number of unit names
unitNamesPoolSize equ {unit_names_pool_size} ; size of unit names string pool

""", file=self.output, end='')

        for unit in self.content['units']:
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
