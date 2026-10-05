import unittest

from materialize_peregrine_replay_roots import materialize


MANIFEST = '''Definition peregrine_modules : list qualid := [
  "Peregrine.A"%bs; "Peregrine.B"%bs].'''
LOG = "\n".join([
    "PEREGRINE_REPLAY_MODULE Peregrine.A",
    "PEREGRINE_REPLAY_ROOT CONST Peregrine.A.opaque_proof",
    "PEREGRINE_REPLAY_ROOT IND Peregrine.A.tree",
    "PEREGRINE_REPLAY_MODULE_DONE Peregrine.A 2",
    "PEREGRINE_REPLAY_MODULE Peregrine.B",
    "PEREGRINE_REPLAY_ROOT CONST Peregrine.A.opaque_proof",
    "PEREGRINE_REPLAY_ROOT CONST Peregrine.B.unrelated_proof",
    "PEREGRINE_REPLAY_MODULE_DONE Peregrine.B 2",
    "PEREGRINE_REPLAY_COMPLETE",
])


class CorpusRootTests(unittest.TestCase):
    def test_unified_protocol_reuses_complete_renderer_and_retains_assumptions(self):
        manifest = MANIFEST.replace("peregrine_modules", "unified_modules")
        log = LOG.replace("PEREGRINE_REPLAY", "UNIFIED_REPLAY")
        log = log.replace("ROOT CONST Peregrine.B.unrelated_proof", "ROOT ASSUMPTION Peregrine.B.unrelated_proof")
        source, receipt = materialize(log, manifest, module_list="unified_modules",
                                     marker_prefix="UNIFIED_REPLAY", root_prefix="unified",
                                     import_module="MetaRocqRs.UnifiedGenerated.UnifiedLoadAll", coverage_ledger=True)
        self.assertEqual(receipt["unique_declaration_roots"], 3)
        self.assertIn("Definition unified_all_declarations_root", source)
        self.assertIn('"Peregrine.A.opaque_proof"%bs', source)
        self.assertIn("Definition unified_expected_assumption_names", source)
        self.assertIn('"Peregrine.B.unrelated_proof"%bs', source)

    def test_generated_namespace_and_identifiers_cannot_inject_code(self):
        for option in ({"module_list": "x;Admitted."}, {"root_prefix": "../x"},
                       {"import_module": "X;Admitted."}, {"marker_prefix": "x\nUNIFIED_REPLAY"}):
            with self.subTest(option=option), self.assertRaises(ValueError):
                materialize(LOG, MANIFEST, **option)

    def test_contradictory_body_classification_is_rejected(self):
        changed = LOG.replace("PEREGRINE_REPLAY_MODULE Peregrine.B\nPEREGRINE_REPLAY_ROOT CONST", "PEREGRINE_REPLAY_MODULE Peregrine.B\nPEREGRINE_REPLAY_ROOT ASSUMPTION")
        with self.assertRaisesRegex(ValueError, "contradictory"):
            materialize(changed, MANIFEST)

    def test_opaque_and_unrelated_proofs_survive_without_duplicate_roots(self):
        source, receipt = materialize(LOG, MANIFEST)
        self.assertEqual(receipt["unique_declaration_roots"], 3)
        self.assertEqual(source.count("@Peregrine.A.opaque_proof"), 1)
        self.assertIn("@Peregrine.B.unrelated_proof", source)
        self.assertEqual(len(receipt["exports"]["Peregrine.B"]), 2)

    def test_truncated_last_module_cannot_pass(self):
        with self.assertRaises(ValueError):
            materialize(LOG.rsplit("PEREGRINE_REPLAY_MODULE_DONE", 1)[0], MANIFEST)

    def test_complete_marker_cannot_hide_a_missing_root(self):
        with self.assertRaises(ValueError):
            materialize(LOG.replace("PEREGRINE_REPLAY_ROOT CONST Peregrine.B.unrelated_proof\n", ""), MANIFEST)

    def test_theorem_source_injection_is_rejected(self):
        with self.assertRaises(ValueError):
            materialize(LOG.replace("Peregrine.B.unrelated_proof", "Peregrine.B.x;Admitted."), MANIFEST)

    def test_unknown_or_malformed_record_is_not_silently_dropped(self):
        for bad in ("PEREGRINE_REPLAY_ROOT FOO Peregrine.B.x", "PEREGRINE_REPLAY_ROOTbad"):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                materialize(LOG.replace("PEREGRINE_REPLAY_COMPLETE", bad + "\nPEREGRINE_REPLAY_COMPLETE"), MANIFEST)

    def test_empty_corpus_is_rejected(self):
        empty = "\n".join([
            "PEREGRINE_REPLAY_MODULE Peregrine.A",
            "PEREGRINE_REPLAY_MODULE_DONE Peregrine.A 0",
            "PEREGRINE_REPLAY_MODULE Peregrine.B",
            "PEREGRINE_REPLAY_MODULE_DONE Peregrine.B 0",
            "PEREGRINE_REPLAY_COMPLETE",
        ])
        with self.assertRaises(ValueError):
            materialize(empty, MANIFEST)

    def test_module_order_and_duplicate_markers_are_checked(self):
        for bad in (LOG.replace("Peregrine.B", "Peregrine.C"), LOG + "\nPEREGRINE_REPLAY_COMPLETE"):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                materialize(bad, MANIFEST)

    def test_chunking_does_not_drop_any_root(self):
        manifest = 'Definition peregrine_modules : list qualid := ["Peregrine.A"%bs].'
        roots = [f"Peregrine.A.proof_{i}" for i in range(130)]
        log = "\n".join([
            "PEREGRINE_REPLAY_MODULE Peregrine.A",
            *(f"PEREGRINE_REPLAY_ROOT CONST {name}" for name in roots),
            "PEREGRINE_REPLAY_MODULE_DONE Peregrine.A 130",
            "PEREGRINE_REPLAY_COMPLETE",
        ])
        source, receipt = materialize(log, manifest)
        self.assertEqual(receipt["roots"], roots)
        for name in roots:
            self.assertEqual(source.count(f"@{name} in"), 1)
        self.assertIn("let _ := peregrine_replay_roots_0002 in", source)


if __name__ == "__main__":
    unittest.main()
