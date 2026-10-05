"""Checked OpenTheory/Dedukti/Rocq/PCUIC translation stages."""
from __future__ import annotations
import json, re, shutil, subprocess
from pathlib import Path
from hol4_pcuic_core import ROOT, BUILD_ROOT, checked_name, confined, digest, resolve_tool, run, verify_source

BAD_ROCQ=[(re.compile(r"\bAdmitted\s*\.",re.I),"Admitted"),(re.compile(r"\badmit\b",re.I),"admit"),
          (re.compile(r"\bHOLLight\.theorems\b"),"packaged coq-hol-light theorem axioms")]

def patch_holide_dk(text, *, is_hol):
    if is_hol: return re.sub(r"^#NAME [A-Za-z0-9_]+\.", "", text, flags=re.M)
    text=re.sub(r"^#NAME [A-Za-z0-9_]+\.", "#REQUIRE hol.", text, flags=re.M)
    text=re.sub(r"^\{([A-Za-z0-9_-]*)\}", r"def \1", text, flags=re.M)
    return re.sub(r"^def thm_", "thm thm_", text, flags=re.M)

def scan_rocq(text, *, support=False):
    for pattern,label in BAD_ROCQ:
        if pattern.search(text): raise ValueError(f"generated Rocq rejected: {label}")
    if not support and re.search(r"^\s*(Axiom|Parameter|Parameters)\b",text,flags=re.M):
        raise ValueError("generated theorem module introduces Axiom/Parameter")

def parse_mapping_sources(text): return set(re.findall(r'^\s*builtin\s+"[^"]+"\s*≔\s*([^;]+);',text,flags=re.M))
def support_assumptions(text): return [x.strip() for x in text.splitlines() if re.match(r"^\s*(Axiom|Parameter|Parameters)\b",x)]

def qualify_require_lines(text, modules):
    out=[]
    for line in text.splitlines():
        m=re.match(r"^\s*Require(?:\s+Import)?\s+([A-Za-z][A-Za-z0-9_']*)\.\s*$",line)
        if m:
            if m.group(1) not in modules: raise ValueError(f"generated Rocq requires unexpected module: {m.group(1)}")
            line=re.sub(r"^\s*Require","From Hol4Imported Require",line)
        out.append(line)
    return "\n".join(out)+"\n"

def mapping_report(lock, dk_text):
    root=verify_source("coq_hol_light",lock["repositories"]["coq_hol_light"]); sources=parse_mapping_sources((root/"mappings.lp").read_text())
    exact=sorted(s for s in sources if re.search(rf"(?<![A-Za-z0-9_.]){re.escape(s)}(?![A-Za-z0-9_.])",dk_text))
    return {"catalog_commit":lock["repositories"]["coq_hol_light"]["commit"],"catalog_entries":len(sources),
            "exact_source_symbol_matches":exact,"policy":"catalog only; packaged theorem axioms never imported"}

def translate_article(lock, *, article, work, timeout):
    article=confined(ROOT,article,must_exist=True); work=confined(ROOT,work)
    if work.exists(): shutil.rmtree(work)
    work.mkdir(parents=True); hs=verify_source("holide",lock["repositories"]["holide"]); ls=verify_source("lambdapi",lock["repositories"]["lambdapi"])
    holide=resolve_tool("holide","HOLIDE_BIN",BUILD_ROOT/"holide/holide"); lp=resolve_tool("lambdapi","LAMBDAPI_BIN")
    run([str(holide),"--just-check",str(article)],cwd=work,timeout=timeout); raw=work/"imported.raw.dk"
    run([str(holide),"-o",str(raw),str(article)],cwd=work,timeout=timeout)
    if not raw.is_file() or not raw.stat().st_size: raise ValueError("Holide produced no Dedukti proof")
    (work/"hol.dk").write_text(patch_holide_dk((hs/"dedukti/hol.dk").read_text(),is_hol=True)); (work/"imported.dk").write_text(patch_holide_dk(raw.read_text(),is_hol=False))
    run([str(lp),"check","--lib-root",".","--no-warnings","hol.dk","imported.dk"],cwd=work,timeout=timeout)
    for n in ("encoding.lp","mapping.lp","renaming.lp","coq.v"): shutil.copyfile(ls/"libraries"/n,work/n)
    hol=(work/"hol.dk").read_text(); names=[]
    for line in hol.splitlines():
        m=re.match(r"^(?:def\s+)?([A-Za-z0-9_]+)(?:\s|$)",line)
        if m:names.append(m.group(1))
    for n in sorted(set(names),key=len,reverse=True): hol=re.sub(rf"(?<![A-Za-z0-9_.]){re.escape(n)}(?![A-Za-z0-9_])",f"hol.{n}",hol)
    hol=re.sub(r"^hol\.","",hol,flags=re.M); hol=re.sub(r"^(def|thm) hol\.",r"\1 ",hol,flags=re.M)
    (work/"hol.dk").write_text(re.sub(r"^type ","typ ",hol,flags=re.M).replace("hol.type","hol.typ")); imported=(work/"imported.dk").read_text().replace("hol.type","hol.typ"); (work/"imported.dk").write_text(imported)
    run([str(lp),"check","--lib-root",".","--no-warnings","hol.dk","imported.dk"],cwd=work,timeout=timeout)
    hashes={}
    for module in ("hol","imported"):
        argv=[str(lp),"export","-o","stt_coq","--encoding","encoding.lp","--mapping","mapping.lp","--renaming","renaming.lp","--requiring","coq","--no-implicits",f"{module}.dk"]
        p=subprocess.run(argv,cwd=work,text=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=timeout,check=False)
        if p.returncode: raise RuntimeError(p.stderr[-4000:])
        text=qualify_require_lines(p.stdout,{"coq","hol"}); scan_rocq(text,support=module=="hol"); (work/f"{module}.v").write_text(text); hashes[module]=digest(text.encode())
    scan_rocq((work/"coq.v").read_text(),support=True); report=mapping_report(lock,imported); report["hol_support_assumptions"]=support_assumptions((work/"hol.v").read_text())
    (work/"coq-hol-light-mapping-report.json").write_text(json.dumps(report,indent=2)+"\n")
    return {"status":"ROCQ_GENERATED","dedukti_sha256":digest((work/"imported.dk").read_bytes()),"rocq_modules_sha256":hashes,"mapping_report":report,"claim":"generated source only; Rocq kernel check required"}

def rocq_compile(work, timeout):
    work=confined(ROOT,work,must_exist=True); rocq=resolve_tool("rocq","ROCQ_BIN"); version=subprocess.check_output([str(rocq),"-v"],text=True)
    if "9.1" not in version: raise ValueError("project-compatible Rocq 9.1 required")
    scan_rocq((work/"coq.v").read_text(),support=True); scan_rocq((work/"hol.v").read_text(),support=True); scan_rocq((work/"imported.v").read_text())
    for m in ("coq","hol","imported"):
        run([str(rocq),"compile","-Q",str(work),"Hol4Imported",str(work/f"{m}.v")],cwd=ROOT,timeout=timeout)
        if not (work/f"{m}.vo").is_file(): raise ValueError(f"missing {m}.vo")
    return {"status":"ROCQ_KERNEL_CHECKED","vo_sha256":{m:digest((work/f"{m}.vo").read_bytes()) for m in ("coq","hol","imported")},"explicit_hol_support_assumptions":support_assumptions((work/"hol.v").read_text())}

def render_quote(template, *, import_module, import_symbol, output_name):
    checked_name(import_module,qualified=True); checked_name(import_symbol,qualified=True); checked_name(output_name)
    return template.replace("@IMPORT_MODULE@",import_module).replace("@IMPORT_SYMBOL@",import_symbol).replace("@OUTPUT_NAME@",output_name)

def quote_pcuic(lock, *, work, import_symbol, output_name, timeout):
    work=confined(ROOT,work,must_exist=True); rocq=resolve_tool("rocq","ROCQ_BIN"); template=(ROOT/"metatheory/bootstrap/Hol4ImportedQuote.v.in").read_text()
    q=work/"QuoteImported.v"; q.write_text(render_quote(template,import_module="Hol4Imported.imported",import_symbol=import_symbol,output_name=output_name))
    run([str(rocq),"compile","-Q",str(work),"Hol4Imported",str(q)],cwd=ROOT,timeout=timeout); vo=work/"QuoteImported.vo"
    if not vo.is_file(): raise ValueError("MetaRocq quotation produced no QuoteImported.vo")
    return {"status":"PCUIC_QUOTED","quote_source_sha256":digest(q.read_bytes()),"quote_vo_sha256":digest(vo.read_bytes()),"output_definition":output_name,"claim":"PCUIC quotation of a Rocq-kernel-checked imported theorem; not arbitrary HOL/PCUIC semantic equivalence"}
