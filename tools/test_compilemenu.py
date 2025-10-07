import unittest

from compilemenu import StringExploder


class TestStringExploder(unittest.TestCase):
    def test_explode_str(self) -> None:
        self.assertEqual(
            ["'N'", "'U'", "'M'"],
            StringExploder.explode_str("NUM"))
        self.assertEqual(
            ["ScapDelta", "Spercent"],
            StringExploder.explode_str("<ScapDelta><Spercent>"))
        self.assertEqual(
            ["ScapDelta", "Sroot"],
            StringExploder.explode_str("<ScapDelta><Sroot>"))
        self.assertEqual(
            ["Sdegree", "'C'"],
            StringExploder.explode_str("<Sdegree>C"))
        self.assertEqual(
            ["Sdegree", "'F'"],
            StringExploder.explode_str("<Sdegree>F"))
