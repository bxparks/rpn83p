#!/usr/bin/env python3
#
# Copyright 2023 Brian T. Park
# MIT License.

"""
Parse the Menu Definition Language file and produce a TI-OS Z80 assembly
language file.

Usage:
$ parsemenu.py < menudef.txt > menudef.asm
"""

from typing import Dict
from typing import List
from typing import Optional
from typing import TextIO
from typing import TypedDict

# import argparse
# import logging
import sys


def main() -> None:
    lexer = Lexer(sys.stdin)
    parser = Parser(lexer)
    parser.parse()


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

    def get_token(self) -> Optional[str]:
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


class MenuNode(TypedDict, total=False):
    type: int  # 0: item, 1: group
    id: int
    parent_id: int
    id_prefix: str
    name: str
    num_strips: int
    first_strip_id: int
    children: List["MenuNode"]


class Parser:
    def __init__(self, lexer: Lexer):
        self.lexer = lexer

        # Monotonic counter for 'MenuItem * *' declarations.
        self.blank_menu_item_index = 0

        self.root_node: MenuNode = {
            "type": 1,
            "id": 1,
            "parent_id": 0,
            "name": "root",
            "id_prefix": None,  # TDB
            "num_strips": 0,  # TDB
            "first_strip_id": 0,  # TDB
            "children": [],
        }

        self.nodes: Dict[int, MenuNode] = {
            1: self.root_node,
        }

    def parse(self) -> None:
        while True:
            token = self.lexer.get_token()
            if not token:
                break
            print(token)

            if token == 'MenuGroup':
                self.process_menugroup()
            else:
                raise ValueError(
                    f"Unexpected token '{token}' "
                    f"at line {self.lexer.line_number}"
                )

    def process_menugroup(self) -> None:
        pass


if __name__ == '__main__':
    main()
