#!/usr/bin/env python3
#
# Copyright 2023 Brian T. Park
# MIT License.

"""
Parse the Menu Definition Language file and produce a TI-OS Z80 assembly
language file.

Usage:
$ parsemenu.py < menusample.txt > menusample.asm
"""

from typing import Dict
from typing import List
from typing import Optional
from typing import TextIO
from typing import TypedDict

# import argparse
# import logging
import sys
from pprint import pp


def main() -> None:
    lexer = Lexer(sys.stdin)

    parser = Parser(lexer)
    root = parser.parse()

    validator = Validator(root)
    validator.validate()

    sym_gen = SymbolGenerator(root)
    sym_gen.generate()

    code_gen = CodeGenerator(sym_gen, root)
    code_gen.generate()

    pp(root)

# -----------------------------------------------------------------------------


MENU_TYPE_ITEM = 0
MENU_TYPE_GROUP = 1

MenuStrip = List["MenuNode"]


class MenuNode(TypedDict, total=False):
    """Representation of the abstract syntax tree."""
    mtype: int  # 0: item, 1: group
    id: int  # TBD, except for Root which is always 1
    parent_id: int
    name: str
    prefix: str
    strips: List[MenuStrip]  # List of MenuNodes in groups of 5


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
        * Trailing comment lines beginning with '#' are stripped.
        * Trailing whitespaces are stripped.
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

            # strip any trailing whitespaces
            line = line.rstrip()

            # skip any blank lines after stripping
            if not line:
                continue

            return line

# -----------------------------------------------------------------------------


class Parser:
    """Create an abstract syntax tree (AST) of MenuNodes that represents the
    items in the menu definition file.
    """
    def __init__(self, lexer: Lexer):
        self.lexer = lexer

    def parse(self) -> MenuNode:
        while True:
            token = self.lexer.get_token_or_none()
            if token is None:
                break

            if token == 'MenuGroup':
                root = self.process_menugroup()
            else:
                raise ValueError(
                    f"Unexpected root token '{token}' "
                    f"at line {self.lexer.line_number}"
                )
        return root

    def process_menugroup(self) -> MenuNode:
        """A MenuGroup is a list of MenuStrips."""
        node = MenuNode()
        node["mtype"] = MENU_TYPE_GROUP
        node["name"] = self.lexer.get_token()
        node["prefix"] = self.lexer.get_token()
        node["id"] = 0  # added early to help debugging with pprint.pp()
        node["parent_id"] = 0

        token = self.lexer.get_token()
        if token != '[':
            raise ValueError(
                f"Unexpected token '{token}' "
                f"at line {self.lexer.line_number}, should be '['"
            )
        # Process list of MenuStrip
        strips: List[MenuStrip] = []
        while True:
            token = self.lexer.get_token()
            if token == 'MenuStrip':
                strip = self.process_menustrip()
            elif token == ']':
                break
            else:
                raise ValueError(
                    f"Unexpected token '{token}' "
                    f"at line {self.lexer.line_number}, should be 'MenuStrip'"
                    " or ']'"
                )
            strips.append(strip)
        node["strips"] = strips
        return node

    def process_menustrip(self) -> MenuStrip:
        """A MenuStrip is a list of MenuItem or MenuGroup."""
        strip: MenuStrip = []
        token = self.lexer.get_token()
        if token != '[':
            raise ValueError(
                f"Unexpected token '{token}' "
                f"at line {self.lexer.line_number}, should be '['"
            )
        # Process list of MenuItems or MenuGroups
        while True:
            token = self.lexer.get_token()
            if token == 'MenuItem':
                node = self.process_menuitem()
            elif token == 'MenuGroup':
                node = self.process_menugroup()
            elif token == ']':
                break
            else:
                raise ValueError(
                    f"Unexpected token '{token}' "
                    f"at line {self.lexer.line_number}"
                )
            strip.append(node)
        return strip

    def process_menuitem(self) -> MenuNode:
        item = MenuNode()
        item["mtype"] = MENU_TYPE_ITEM
        item["name"] = self.lexer.get_token()
        item["prefix"] = self.lexer.get_token()
        return item


# -----------------------------------------------------------------------------

class Validator:
    """Validate the AST, adding implicit blank MenuItem nodes if necessary.
    TODO: Validate len(strips) == 0 for MenuItem.
    """
    def __init__(self, root: MenuNode):
        self.root = root

    def validate(self) -> None:
        self.validate_node(self.root)
        self.validate_group(self.root)

    def validate_node(self, node: MenuNode) -> None:
        """Validate the current node, no recursion."""
        self.validate_prefix(node)
        if node["mtype"] == MENU_TYPE_GROUP:
            self.verify_at_least_one_strip(node)
            self.normalize_partial_strips(node)

    def validate_group(self, node: MenuNode) -> None:
        """Validate the strips of the current MenuGroup. Then recursively
        descend any sub groups.
        """
        # Process the direct children of the current group.
        strips = node["strips"]
        for strip in strips:
            for slot in strip:
                self.validate_node(slot)

        # Recursively descend the subgroups if any.
        for strip in strips:
            for slot in strip:
                mtype = slot["mtype"]
                if mtype == MENU_TYPE_GROUP:
                    self.validate_group(slot)

    def verify_at_least_one_strip(self, node: MenuNode) -> None:
        """Verify that each ModeGroup has at least one MenuStrip."""
        name = node["name"]
        strips = node["strips"]
        if len(strips) == 0:
            raise ValueError(
                f"MenuGroup '{name}' must have at least one MenuStrip"
            )

    def normalize_partial_strips(self, node: MenuNode) -> None:
        """Add implicit MenuNodes to any partial MenuStrip (i.e. strips which do
        not contain exact 5 MenuNodes)."""
        name = node["name"]
        strips = node["strips"]
        strip_index = 0
        for strip in strips:
            num_nodes = len(strip)
            if num_nodes > 5:
                raise ValueError(
                    f"MenGroup {name}, strip {strip_index} has too "
                    f"many ({num_nodes}) nodes, must be <= 5"
                )
            if num_nodes == 0:
                raise ValueError(
                    f"MenGroup {name}, strip {strip_index} has 0 nodes"
                )
            # Add implicit blank menu items
            for i in range(5 - num_nodes):
                blank: MenuNode = {
                    "mtype": MENU_TYPE_ITEM,
                    "name": "*",
                    "prefix": "*",
                }
                strip.append(blank)

            strip_index += 1

    def validate_prefix(self, node: MenuNode) -> None:
        """Validate that the 'prefix' does not begin with reserved prefixes:
        'mBlank', '*'
        """
        name = node["name"]
        prefix = node["prefix"]
        if prefix.startswith("mBlank"):
            raise ValueError(
                f"Illegal prefix '{prefix}' for Menu '{name}'"
            )
        if name == '*':
            mtype = node["mtype"]
            if mtype != MENU_TYPE_ITEM:
                raise ValueError(
                    f"Invalid name '{name}' for MenuGroup"
                )
            if prefix != '*':
                raise ValueError(
                    f"Illegal prefix '{prefix}' for blank Menu '{name}'"
                )
        else:
            if not prefix[0].isalpha():
                raise ValueError(
                    f"Illegal prefix '{prefix}' for regular Menu '{name}'"
                )
            if prefix == '*':
                raise ValueError(
                    f"Illegal prefix '{prefix}' for regular Menu '{name}'"
                )

# -----------------------------------------------------------------------------


class SymbolGenerator:
    def __init__(self, root: MenuNode):
        self.root = root
        self.id_map: Dict[int, MenuNode] = {}
        self.name_map: Dict[str, MenuNode] = {}
        self.prefix_map: Dict[str, MenuNode] = {}
        self.id_counter = 1  # Root starts at id=1

    def generate(self) -> None:
        self.generate_node(self.root, 0)
        self.generate_group(self.root)

    def generate_group(self, node: MenuNode) -> None:
        """Process the strips of the current MenuGroup. Then recursively descend
        any sub groups.
        """
        # Process the direct children of the current group.
        id = node["id"]
        strips = node["strips"]
        for strip in strips:
            for slot in strip:
                self.generate_node(slot, id)

        # Recursively descend subgroups if any.
        for strip in strips:
            for slot in strip:
                mtype = slot["mtype"]
                if mtype == MENU_TYPE_GROUP:
                    self.generate_group(slot)

    def generate_node(self, node: MenuNode, parent_id: int) -> None:
        """Process the given node, no recursion."""
        # Add menu name to the name_map[] table
        name = node["name"]
        if name != "*":
            entry = self.name_map.get(name)
            if entry is not None:
                raise ValueError(f"Duplicate MenuItem.name '{name}'")
            self.name_map[name] = node

            prefix = node["prefix"]
            entry = self.prefix_map.get(prefix)
            if entry is not None:
                raise ValueError(f"Duplicate MenuItem.prefix '{prefix}'")
            self.prefix_map[prefix] = node

        # Add id and parent_id.
        id = self.id_counter
        node["id"] = id
        node["parent_id"] = parent_id
        self.id_map[id] = node
        self.id_counter += 1

        # Set prefix='mBlankXXX' for blank menus
        if name == "*":
            prefix = f"mBlank{id:03}"
            node["prefix"] = prefix

# -----------------------------------------------------------------------------


class CodeGenerator:
    def __init__(self, symbols: SymbolGenerator, root: MenuNode):
        self.root = root
        self.id_map = symbols.id_map
        self.name_map = symbols.name_map
        self.prefix_map = symbols.prefix_map

    def generate(self) -> None:
        self.generate_menu(self.root)
        # self.generate_names(self.root)

    def generate_menu(self, node: MenuNode) -> None:
        print("""\
;-----------------------------------------------------------------------------
; Menu hierarchy definitions, generated from XXX.
; See menu.asm for the equivalent C struct declaration.
;
; The following symbols are reserved and pre-generated by the parsemenu.py
; script:
;   - mNullId
;   - mNullNameId
;   - mNullHandler
;   - mGroupHandler
;
; The following symbol is are reserved, but recommended to be used
; for the root menu:
;   - mRootId
;   - mRootNameId
;-----------------------------------------------------------------------------

mMenuTable:
mNull:
mNullId equ 0
    .db mNullId ; id
    .db mNullId ; parentId
    .db mNullNameId ; nameId
    .db 0 ; numStrips
    .db 0 ; stripBeginId
    .dw mNullHandler
""")
        self.generate_menu_node(self.root)
        self.generate_menu_group(self.root)

    def generate_menu_node(self, node: MenuNode) -> None:
        mtype = node["mtype"]
        name = node["name"]
        prefix = node["prefix"]
        id = node["id"]
        parent_id = node["parent_id"]
        if parent_id == 0:
            parent_node = None
            parent_node_prefix = "mNull"
        else:
            parent_node = self.id_map[parent_id]
            parent_node_prefix = parent_node["prefix"]

        if mtype == MENU_TYPE_ITEM:
            num_strips = 0
            strip_begin_id = 0
            if name == '*':
                handler = "mNullHandler"
            else:
                handler = f"{prefix}Handler"
        else:
            strips = node["strips"]
            num_strips = len(strips)
            strip_begin_id = strips[0][0]["id"]
            handler = "mGroupHandler"

        print(f"""\
{prefix}:
{prefix}Id equ {id}
    .db {prefix}Id ; id
    .db {parent_node_prefix}Id ; parentId
    .db {prefix}NameId ; nameId
    .db {num_strips} ; numStrips
    .db {strip_begin_id} ; stripBeginId
    .dw {handler} ; handler
""")

    def generate_menu_group(self, node: MenuNode) -> None:
        # Process the direct children of the current group.
        strips = node["strips"]
        for strip in strips:
            for slot in strip:
                self.generate_menu_node(slot)

        # Recursively descend subgroups if any.
        for strip in strips:
            for slot in strip:
                mtype = slot["mtype"]
                if mtype == MENU_TYPE_GROUP:
                    self.generate_menu_group(slot)

# -----------------------------------------------------------------------------


if __name__ == '__main__':
    main()
