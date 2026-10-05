#!/usr/bin/env python3
"""Check child-launch mutation boundaries; these are not theorem tests."""
import unittest
from materialize_tactictoe_transport import START, END, REPLACEMENT, adapt


class LauncherBoundaries(unittest.TestCase):
    def setUp(self):
        self.prefix = '(* proof search and cache identity before launcher *)\n'
        self.suffix = END + '  original_recording_and_publication script;\n'
        self.launcher = START + '  case Posix.Process.fork () of NONE => launch_child ();\n'
        self.source = self.prefix + self.launcher + self.suffix

    def test_every_byte_outside_the_child_launcher_is_preserved(self):
        self.assertEqual(adapt(self.source), self.prefix + REPLACEMENT + self.suffix)
        self.assertIn('if private_group then raise ERR', REPLACEMENT)
        self.assertIn('else raise ERR', REPLACEMENT)

    def test_changed_or_duplicated_boundaries_are_rejected(self):
        for source in (self.source.replace(START, 'changed launcher\n'),
                       self.source.replace(END, 'changed next function\n'),
                       self.source + START, self.source + END):
            with self.assertRaises(ValueError):
                adapt(source)

    def test_unexpected_original_launcher_is_rejected(self):
        with self.assertRaises(ValueError):
            adapt(self.source.replace('case Posix.Process.fork () of', 'other launch'))

    def test_reordered_boundaries_are_rejected(self):
        with self.assertRaises(ValueError):
            adapt(END + self.launcher)


if __name__ == '__main__':
    unittest.main()
