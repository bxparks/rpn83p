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
    #
    parser = Parser(lexer)
    root = parser.parse()
    #
    normalizer = Normalizer(root)
    normalizer.normalize()
    #
    generator = SymbolGenerator(root)
    generator.generate()
    #
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

class Normalizer:
    """Normalize the AST, filling in various implicit nodes.
    """
    def __init__(self, root: MenuNode):
        self.root = root
        self.blank_counter = 0

    def normalize(self) -> None:
        self.normalize_group(self.root)

    def normalize_group(self, node: MenuNode) -> None:
        # Process the current group.
        self.verify_at_least_one_strip(node)
        self.normalize_partial_strips(node)
        self.add_blank_prefixes(node)

        # Recursively descend the subgroups if any.
        strips = node["strips"]
        for strip in strips:
            for slot in strip:
                mtype = slot["mtype"]
                if mtype == MENU_TYPE_GROUP:
                    self.normalize_group(slot)

    def verify_at_least_one_strip(self, node: MenuNode) -> None:
        """Verify that each ModeGroup has at least one MenuStrip."""
        name = node["name"]
        strips = node["strips"]
        if len(strips) == 0:
            raise ValueError(
                f"MenGroup {name} must have at least one MenuStrip"
            )

    def normalize_partial_strips(self, node: MenuNode) -> None:
        """Add implicit MenuNodes to any partial MenuStrip (i.e. strips which do
        not contain exact 5 MenuNodes)."""
        name = node["name"]
        strips = node["strips"]
        strip_index = 1
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

    def add_blank_prefixes(self, node: MenuNode) -> None:
        """Add 'mBlankXX' as prefixes of blank menus."""
        strips = node["strips"]
        for strip in strips:
            for slot in strip:
                name = slot["name"]
                if name == "*":
                    prefix = f"mBlank{self.blank_counter:02}"
                    slot["prefix"] = prefix
                    self.blank_counter += 1

# -----------------------------------------------------------------------------


class SymbolGenerator:
    def __init__(self, root: MenuNode):
        self.root = root
        self.id_map: Dict[int, MenuNode] = {}
        self.name_map: Dict[str, MenuNode] = {}
        self.id_counter = 1  # Root starts at id=1

    def generate(self) -> None:
        self.generate_entry(self.root, 0)
        self.generate_group(self.root)

    def generate_group(self, node: MenuNode) -> None:
        # Process the current group.
        id = node["id"]
        strips = node["strips"]
        for strip in strips:
            for slot in strip:
                self.generate_entry(slot, id)

        # Recursively descend subgroups if any.
        for strip in strips:
            for slot in strip:
                mtype = slot["mtype"]
                if mtype == MENU_TYPE_GROUP:
                    self.generate_group(slot)

    def generate_entry(self, node: MenuNode, parent_id: int) -> None:
        # Add menu name to the name_map[] table
        name = node["name"]
        if name != "*":
            entry = self.name_map.get(name)
            if entry is not None:
                raise ValueError(
                    f"MenuItem '{name}' already exists"
                )
        id = self.id_counter
        node["id"] = id
        node["parent_id"] = parent_id
        self.name_map[name] = node
        self.id_map[id] = node
        self.id_counter += 1


# -----------------------------------------------------------------------------


if __name__ == '__main__':
    main()
