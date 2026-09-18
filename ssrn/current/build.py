#!/usr/bin/env python3
"""Build and validate the self-contained current manuscript source package."""
import argparse, hashlib, json, re, shutil, subprocess, tarfile
from pathlib import Path
from pypdf import PdfReader, PdfWriter
from pypdf.constants import PageLabelStyle
from pypdf.generic import TextStringObject, NameObject
from verify_evidence import verify
ROOT = Path(__file__).resolve().parent
TITLE = "Innovation-Safe Compression of Financial Strategy Libraries: Semantics, Complexity, and Algorithms"
VERSION = "v0.3.0-ssrn"
DATE = "2026-09-18"
NAMES = {"article":"financial-strategy-library-compression-preprint.pdf", "supplement":"financial-strategy-library-compression-supplement.pdf", "complete":"financial-strategy-library-compression-ssrn.pdf"}
def run(args, **kw): return subprocess.check_output(args, text=True, **kw)
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()

def namespace_destinations(reader, prefix):
    """Keep article and supplement links distinct when both define section.1, etc."""
    destinations = reader.named_destinations
    names = set(destinations)
    dests = reader.trailer["/Root"].get("/Names", {}).get_object().get("/Dests") if "/Names" in reader.trailer["/Root"] else None
    def rename_tree(node):
        node = node.get_object()
        for child in node.get("/Kids", []):
            rename_tree(child)
        items = node.get("/Names", [])
        for i in range(0, len(items), 2):
            items[i] = TextStringObject(prefix + str(items[i]))
    if dests:
        rename_tree(dests)
    for page in reader.pages:
        for annotation in page.get("/Annots", []):
            annotation = annotation.get_object()
            for container, key in [(annotation, "/Dest"), (annotation.get("/A", {}).get_object() if "/A" in annotation else {}, "/D")]:
                value = container.get(key)
                if isinstance(value, str) and value in names:
                    # Resolve links before merging, so no transient destination
                    # lookup can bind a supplement link to an article page.
                    container[NameObject(key)] = destinations[value].dest_array


def link_targets(reader):
    pages = {page.indirect_reference.idnum: i for i, page in enumerate(reader.pages)}
    named = reader.named_destinations
    result = []
    for page in reader.pages:
        targets = []
        for obj in page.get("/Annots", []):
            ann = obj.get_object()
            action = ann.get("/A", {})
            action = action.get_object() if hasattr(action, "get_object") else action
            if action.get("/S") == "/URI":
                targets.append(("uri", str(action["/URI"])))
            dest = ann.get("/Dest", action.get("/D"))
            if isinstance(dest, str):
                dest = named[dest].dest_array
            if dest is not None:
                assert dest[0].idnum in pages, "PDF link targets a missing page"
                targets.append(("page", pages[dest[0].idnum]))
        result.append(targets)
    return result


def inspect_pdf(path):
    reader = PdfReader(path)
    assert not reader.is_encrypted, f"encrypted PDF: {path.name}"
    assert reader.metadata.title == TITLE or "Online Resource" in reader.metadata.title
    text = run(["pdftotext", str(path), "-"])
    normalized = " ".join(text.split())
    for banned in ["has not yet supplied", "must be replaced", "DRAFT PLACEHOLDER",
                   "subject to release-time verification", "??", "submitted to Annals"]:
        assert banned not in normalized, f"unfinished text {banned!r}: {path.name}"
    for required in ["David Ramirez", "Independent Researcher", "ramirezdavv@gmail.com",
                     "Not peer reviewed", "ChatGPT", "Codex"]:
        assert required in normalized, f"missing {required}: {path.name}"
    font_lines = run(["pdffonts", str(path)]).splitlines()[2:]
    assert font_lines, "no PDF fonts"
    assert all(re.search(r"\byes\s+(yes|no)\s+(yes|no)\s+\d+\s+\d+\s*$", line) for line in font_lines), "unembedded font"
    assert all("Type 3" not in line for line in font_lines), "bitmap fonts"
    assert path.stat().st_size < 100_000_000, "exceeds documented submission-form size"
    named = reader.named_destinations
    links = 0
    page_text = text.split("\f")
    assert len(page_text) >= len(reader.pages)
    assert all(t.strip() for t in page_text[:len(reader.pages)]), "blank/image-only page"
    for page in reader.pages:
        for obj in page.get("/Annots", []):
            ann = obj.get_object()
            action = ann.get("/A", {})
            action = action.get_object() if hasattr(action, "get_object") else action
            dest = ann.get("/Dest", action.get("/D"))
            if dest is not None:
                links += 1
                if isinstance(dest, str):
                    assert dest in named, f"unresolved named PDF link: {dest}"
    return {"pages": len(reader.pages), "bytes": path.stat().st_size,
            "sha256": sha(path), "fonts_embedded": True, "type3_fonts": False,
            "encrypted": False, "searchable_text": True, "internal_links": links}



def metadata():
    article=(ROOT/'article/main.tex').read_text()
    abstract=' '.join(re.search(r'\\abstract\{(.*?)\}\s*\\keywords',article,re.S)[1].split())
    declarations=(ROOT/'article/author_metadata.tex').read_text()
    ai=re.search(r'\\newcommand\{\\AORGenerativeAIDisclosureStatement\}\{(.*?)\}',declarations)[1]
    return {'title':TITLE,'version':VERSION,'date_written':DATE,'content_type':'Preprint','language':'English',
            'authors':[{'given_name':'David','family_name':'Ramirez','affiliation':'Independent Researcher','location':'Orlando, FL, USA','email':'ramirezdavv@gmail.com','orcid':'0009-0000-3128-5123','corresponding_author':True}],
            'abstract':abstract,'ai_disclosure':ai,'abstract_for_ssrn':abstract+'\n\nGenerative-AI disclosure: '+ai,
            'keywords':['financial strategy libraries','innovation-safe compression','weighted set cover','exact algorithms','model governance'],
            'funding':'The author received no funding for this work.','competing_interests':'The author declares no financial or non-financial competing interests.',
            'repository':'https://github.com/dramirez37/financial-strategy-library-compression',
            'submission_status':'Prepared draft; not submitted by this workflow; not peer reviewed','ssrn_id':None,'doi':None,
            'recommended_upload':NAMES['complete']}

def source_files():
    result=[]
    for d in ['article','supplement','evidence']:
        result.extend(p for p in (ROOT/d).rglob('*') if p.is_file())
    for name in ['build.py','verify_evidence.py','README.md','LICENSE','REPRODUCTION_MANIFEST.json','QUALITY_REVIEW.md']:
        p=ROOT/name
        if p.is_file():result.append(p)
    return sorted(result)

def check(release):
    for line in (release/'SHA256SUMS').read_text().splitlines():
        digest,name=line.split('  ',1)
        assert sha(release/name)==digest,name
    for path,digest in json.loads((release/'SOURCE_MANIFEST.json').read_text()).items():
        assert sha(ROOT/path)==digest,path
    verify()
    stats={kind:inspect_pdf(release/name) for kind,name in NAMES.items()}
    print(json.dumps({'passed':True,'pdfs':stats},indent=2))

def build(release):
    release.mkdir(parents=True,exist_ok=True)
    evidence=verify()
    for kind in ['article','supplement']:
        out=release/'.build'/kind;out.mkdir(parents=True,exist_ok=True)
        with (out/'stdout.log').open('w') as log:
            subprocess.run(['latexmk','-pdf','-interaction=nonstopmode','-halt-on-error','-file-line-error',f'-outdir={out}','main.tex'],cwd=ROOT/kind,stdout=log,stderr=subprocess.STDOUT,check=True)
        log=(out/'main.log').read_text(errors='replace')
        assert not re.search(r'undefined|multiply defined|Missing character:|Overfull \\[hv]box',log),f'Inspect {out}/main.log'
        shutil.copyfile(out/'main.pdf',release/NAMES[kind])
    data=metadata(); writer=PdfWriter()
    for kind in ['article','supplement']:
        reader=PdfReader(release/NAMES[kind]);namespace_destinations(reader,kind+'-')
        writer.append(reader,outline_item='Research article' if kind=='article' else 'Supporting proofs, methods, and reproduction')
    writer.add_metadata({'/Title':TITLE,'/Author':'David Ramirez','/Subject':VERSION+'; '+DATE+'; not peer reviewed','/Keywords':'; '.join(data['keywords'])})
    writer.root_object[NameObject('/Lang')]=TextStringObject('en-US')
    article_pages=len(PdfReader(release/NAMES['article']).pages)
    writer.set_page_label(0,article_pages-1,style=PageLabelStyle.DECIMAL,start=1)
    writer.set_page_label(article_pages,len(writer.pages)-1,style=PageLabelStyle.DECIMAL,prefix='S',start=1)
    writer.write(release/NAMES['complete'])
    expected=[]
    for kind,offset in [('article',0),('supplement',article_pages)]:
        for targets in link_targets(PdfReader(release/NAMES[kind])):
            expected.append([(typ,target+offset if typ=='page' else target) for typ,target in targets])
    assert link_targets(PdfReader(release/NAMES['complete']))==expected,'Merged destination drift'
    stats={kind:inspect_pdf(release/name) for kind,name in NAMES.items()}
    for name,value in [('submission_metadata.json',data),('PDF_AUDIT.json',stats),('EVIDENCE_CHECK.json',evidence)]:
        (release/name).write_text(json.dumps(value,indent=2)+'\n')
    (release/'abstract_for_ssrn.txt').write_text(data['abstract_for_ssrn']+'\n')
    files=source_files();manifest={p.relative_to(ROOT).as_posix():sha(p) for p in files}
    (release/'SOURCE_MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n')
    with tarfile.open(release/'financial-strategy-library-compression-ssrn-source.tar.gz','w:gz') as archive:
        for p in files:archive.add(p,arcname=p.relative_to(ROOT).as_posix(),recursive=False)
    for name in ['README.md','REPRODUCTION_MANIFEST.json','QUALITY_REVIEW.md']:
        if (ROOT/name).is_file():shutil.copyfile(ROOT/name,release/name)
    notes=f"""# Preprint package {VERSION}

Prepared {DATE}. This is a preprint release; no SSRN submission, identifier or peer review is claimed.

Article: {stats['article']['pages']} pages. Supplement: {stats['supplement']['pages']} pages. Combined PDF: {stats['complete']['pages']} pages.

The editable archive contains all document inputs and public evidence. Scientific code and licensed-input requirements are described in README.md and REPRODUCTION_MANIFEST.json. SOURCE_MANIFEST.json binds the editable archive inputs; SHA256SUMS binds release files. PDF_AUDIT.json records automated PDF checks. EVIDENCE_CHECK.json records read-only public-evidence checks.

Use the combined PDF for review with the complete supporting resource. Author, abstract and declaration fields are in submission_metadata.json. No scientific experiment is rerun by this builder.
"""
    (release/'RELEASE_METADATA.md').write_text(notes)
    (release/'SHA256SUMS').write_text(''.join(f'{sha(p)}  {p.name}\n' for p in sorted(release.iterdir()) if p.is_file() and p.name!='SHA256SUMS'))
    print(json.dumps(stats,indent=2))

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--output',required=True,type=Path);parser.add_argument('--check',action='store_true')
    args=parser.parse_args();release=args.output.resolve()
    if release==ROOT or release.is_relative_to(ROOT/'article') or release.is_relative_to(ROOT/'supplement') or release.is_relative_to(ROOT/'evidence'):
        parser.error('Output must be separate from manuscript/evidence input directories')
    check(release) if args.check else build(release)
