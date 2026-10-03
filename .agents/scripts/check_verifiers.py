"""Real positive/negative adapter qualification; these examples are NOT Candle proofs."""
from pathlib import Path
import json
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "infra"))
from agentinfra.verifiers import verify_one


def main():
    results = []
    with tempfile.TemporaryDirectory(prefix="aegis-verifier-") as td:
        root = Path(td)
        (root / "src").mkdir()
        (root / "Cargo.toml").write_text('[package]\nname="adapter_fixture"\nversion="0.1.0"\nedition="2021"\n')
        for method in ("kani", "verus"):
            for positive in (True, False):
                if method == "kani":
                    (root / "src/lib.rs").write_text('''#[cfg(kani)] mod proofs {
    #[kani::proof] fn identity() {
        let x: u8 = kani::any();
        let y = x.wrapping_add(1);
        assert!(CONDITION);
    }
}
'''.replace("CONDITION", "y.wrapping_sub(1) == x" if positive else "y.wrapping_sub(1) != x"))
                    entry = "proofs::identity"
                else:
                    (root / "proof.rs").write_text('''use vstd::prelude::*;
verus! {
    proof fn identity(x: int) { assert(CONDITION); }
}
fn main() {}
'''.replace("CONDITION", "x == x" if positive else "x != x"))
                    entry = "proof.rs"
                o = {"id": f"{method}-{'positive' if positive else 'negative'}", "method": method,
                     "entry": entry, "expected_checks": 1, "assumptions": ["verifier adapter qualification only"],
                     "limits": ["u8 identity / integer reflexivity; no Candle correspondence claim"]}
                row = verify_one(root, o, 180)
                # Verification failure is required for the negative control; tool/compile errors do not qualify.
                out = row["execution"]["stdout"] + row["execution"]["stderr"]
                if positive:
                    ok = row["status"] == "CHECKED"
                elif method == "kani":
                    ok = row["status"] == "FAILED" and "VERIFICATION:- FAILED" in out
                else:
                    ok = row["status"] == "FAILED" and "verification results" in out and "1 errors" in out
                row["qualification"] = "PASS" if ok else "FAIL"
                results.append(row)
    output = ROOT / ".aegis/verifier-qualification.json"
    output.parent.mkdir(exist_ok=True)
    output.write_text(json.dumps({"claim": "adapter qualification, not Candle verification", "results": results}, indent=2) + "\n")
    print(json.dumps({"results": [{"id": r["id"], "qualification": r["qualification"]} for r in results]}))
    return int(any(r["qualification"] != "PASS" for r in results))


if __name__ == "__main__":
    raise SystemExit(main())
