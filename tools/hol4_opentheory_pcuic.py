#!/usr/bin/env python3
"""CLI for the fail-closed HOL4 -> OpenTheory -> Rocq -> MetaRocq bridge."""
import argparse, json, subprocess, sys
from pathlib import Path
from hol4_pcuic_core import BUILD_ROOT, build_holide, digest, export_article, load_lock, preflight, sources, write_evidence
from hol4_pcuic_translate import quote_pcuic, rocq_compile, translate_article

def main():
    ap=argparse.ArgumentParser(); ap.add_argument("command",choices=("sources","preflight","build-holide","export","translate","check-rocq","quote","all"))
    ap.add_argument("--theory-dir",default="formal/hol4"); ap.add_argument("--hol4-theory"); ap.add_argument("--hol4-theorem")
    ap.add_argument("--article",default=".metarocq/hol4-pcuic/input.art"); ap.add_argument("--work",default=".metarocq/hol4-pcuic/work")
    ap.add_argument("--rocq-symbol"); ap.add_argument("--output-name",default="hol4_imported_pcuic"); ap.add_argument("--timeout",type=int,default=1800)
    a=ap.parse_args(); lock=load_lock()
    if a.command=="sources": result=sources(lock)
    elif a.command=="preflight": result=preflight(lock)
    elif a.command=="build-holide":
        b=build_holide(lock); result={"status":"HOLIDE_BUILT","path":str(b),"sha256":digest(b.read_bytes())}
    elif a.command=="export":
        if not a.hol4_theory or not a.hol4_theorem: raise ValueError("export requires --hol4-theory and --hol4-theorem")
        result=export_article(lock,theory_dir=Path(a.theory_dir),theory=a.hol4_theory,theorem=a.hol4_theorem,article=Path(a.article),timeout=a.timeout)
    elif a.command=="translate": result=translate_article(lock,article=Path(a.article),work=Path(a.work),timeout=a.timeout)
    elif a.command=="check-rocq": result=rocq_compile(Path(a.work),a.timeout)
    elif a.command=="quote":
        if not a.rocq_symbol: raise ValueError("quote requires --rocq-symbol")
        result=quote_pcuic(lock,work=Path(a.work),import_symbol=a.rocq_symbol,output_name=a.output_name,timeout=a.timeout)
    else:
        if not a.hol4_theory or not a.hol4_theorem or not a.rocq_symbol: raise ValueError("all requires --hol4-theory, --hol4-theorem and --rocq-symbol")
        stages=[export_article(lock,theory_dir=Path(a.theory_dir),theory=a.hol4_theory,theorem=a.hol4_theorem,article=Path(a.article),timeout=a.timeout),
                translate_article(lock,article=Path(a.article),work=Path(a.work),timeout=a.timeout),rocq_compile(Path(a.work),a.timeout),
                quote_pcuic(lock,work=Path(a.work),import_symbol=a.rocq_symbol,output_name=a.output_name,timeout=a.timeout)]
        result={"status":"PIPELINE_CHECKED","stages":stages}
    evidence=write_evidence(a.command,result); print(json.dumps({**result,"evidence":str(evidence)},indent=2)); return 0
if __name__=="__main__":
    try: raise SystemExit(main())
    except (ValueError,OSError,RuntimeError,subprocess.CalledProcessError,subprocess.TimeoutExpired) as e:
        print(json.dumps({"status":"BLOCKED","reason":str(e),"claim":"no translation acceptance"},ensure_ascii=False),file=sys.stderr); raise SystemExit(2)
