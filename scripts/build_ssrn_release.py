#!/usr/bin/env python3
"""Build, inspect, and package the SSRN preprint from the active research sources.

Requires latexmk, pdfTeX/BibTeX, Poppler, and Python pypdf (see ssrn/README.md).
"""
import argparse
import hashlib
import json
import re
import shutil
import subprocess
import tarfile
from pathlib import Path

from pypdf import PdfReader, PdfWriter
from pypdf.constants import PageLabelStyle
from pypdf.generic import TextStringObject, NameObject

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "ssrn/build"
RELEASE = ROOT / "release/v0.2.0-ssrn"
TITLE = "Innovation-Safe Compression of Financial Strategy Libraries: Semantics, Complexity, and Algorithms"
VERSION = "v0.2.0-ssrn"
DATE = "2026-09-13"
NAMES = {
    "article": "financial-strategy-library-compression-preprint.pdf",
    "supplement": "financial-strategy-library-compression-supplement.pdf",
    "complete": "financial-strategy-library-compression-ssrn.pdf",
}


def run(args, **kwargs):
    return subprocess.check_output(args, text=True, **kwargs)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def metadata():
    article = (ROOT / "journal/aor/manuscript/main.tex").read_text()
    assert re.search(r"\\title\[.*?\]\{(.*?)\}", article)[1] == TITLE, "title drift"
    declarations = (ROOT / "journal/aor/manuscript/author_metadata.tex").read_text()
    abstract = re.search(r"\\abstract\{(.*?)\}\s*\\keywords", article, re.S)[1]
    abstract = " ".join(abstract.split())
    ai = re.search(r"\\newcommand\{\\AORGenerativeAIDisclosureStatement\}\{(.*?)\}", declarations)[1]
    assert "has not yet supplied" not in declarations, "unfinished author declaration"
    assert r"The author declares no financial or non-financial competing interests." in declarations
    return {
        "title": TITLE, "version": VERSION, "date_written": DATE,
        "content_type": "Preprint", "language": "English",
        "authors": [{"given_name": "David", "family_name": "Ramirez",
                     "affiliation": "Independent Researcher", "location": "Orlando, FL, USA",
                     "email": "ramirezdavv@gmail.com", "orcid": "0009-0000-3128-5123",
                     "corresponding_author": True}],
        "abstract": abstract, "ai_disclosure": ai,
        "abstract_for_ssrn": abstract + "\n\nGenerative-AI disclosure: " + ai,
        "keywords": ["financial strategy libraries", "innovation-safe compression",
                     "weighted set cover", "exact algorithms", "model governance"],
        "funding": "The author received no funding for this work.",
        "competing_interests": "The author declares no financial or non-financial competing interests.",
        "repository": "https://github.com/dramirez37/financial-strategy-library-compression",
        "manuscript_license": "CC BY 4.0; third-party and licensed-data exclusions apply",
        "submission_status": "Prepared for SSRN; not submitted by this workflow; not peer reviewed",
        "ssrn_id": None, "doi": None, "recommended_upload": NAMES["complete"],
    }


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
    for page in reader.pages:
        assert len(page.extract_text().strip()) > 0, "blank/image-only page"
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


def build():
    for kind, folder, driver, job in [
        ("article", "manuscript", "paper", "ssrn-paper"),
        ("supplement", "online_resource", "supplement", "ssrn-supplement"),
    ]:
        out = BUILD / kind
        out.mkdir(parents=True, exist_ok=True)
        with (out / "build.stdout.log").open("w") as log:
            subprocess.run(["latexmk", "-pdf", "-interaction=nonstopmode", "-halt-on-error",
                            "-file-line-error", f"-outdir={out}", f"-jobname={job}",
                            str(ROOT / "ssrn" / (driver + ".tex"))],
                           cwd=ROOT / "journal/aor" / folder, stdout=log, stderr=subprocess.STDOUT, check=True)
        text = (out / (job + ".log")).read_text(errors="replace")
        assert not re.search(r"undefined|multiply defined|Missing character:|Overfull \\[hv]box", text), f"PDF build needs attention: {out}"
        shutil.copyfile(out / (job + ".pdf"), RELEASE / NAMES[kind])


def package():
    data = metadata()
    writer = PdfWriter()
    for kind, prefix in [("article", "article-"), ("supplement", "supplement-")]:
        reader = PdfReader(RELEASE / NAMES[kind])
        namespace_destinations(reader, prefix)
        writer.append(reader, outline_item="Research article" if kind == "article" else "Online Resource 1: supporting proofs and records")
    writer.add_metadata({"/Title": TITLE, "/Author": "David Ramirez",
                         "/Subject": f"{VERSION}; {DATE}; article and complete supplement; not peer reviewed",
                         "/Keywords": "; ".join(data["keywords"])})
    writer.root_object[NameObject("/Lang")] = TextStringObject("en-US")
    article_pages = len(PdfReader(RELEASE / NAMES["article"]).pages)
    writer.set_page_label(0, article_pages - 1, style=PageLabelStyle.DECIMAL, start=1)
    writer.set_page_label(article_pages, len(writer.pages) - 1,
                          style=PageLabelStyle.DECIMAL, prefix="S", start=1)
    writer.write(RELEASE / NAMES["complete"])
    expected_links = []
    for kind, offset in [("article", 0), ("supplement", article_pages)]:
        for targets in link_targets(PdfReader(RELEASE / NAMES[kind])):
            expected_links.append([(kind, target + offset if kind == "page" else target)
                                   for kind, target in targets])
    assert link_targets(PdfReader(RELEASE / NAMES["complete"])) == expected_links, "merged PDF link target drift"
    stats = {kind: inspect_pdf(RELEASE / name) for kind, name in NAMES.items()}
    assert stats["complete"]["pages"] == stats["article"]["pages"] + stats["supplement"]["pages"]
    assert stats["complete"]["internal_links"] == stats["article"]["internal_links"] + stats["supplement"]["internal_links"]
    (RELEASE / "submission_metadata.json").write_text(json.dumps(data, indent=2) + "\n")
    (RELEASE / "abstract_for_ssrn.txt").write_text(data["abstract_for_ssrn"] + "\n")
    (RELEASE / "PDF_AUDIT.json").write_text(json.dumps(stats, indent=2) + "\n")
    source_paths = set()
    for recorder in [BUILD / "article/ssrn-paper.fls", BUILD / "supplement/ssrn-supplement.fls"]:
        lines = recorder.read_text().splitlines()
        cwd = Path(next(line[4:] for line in lines if line.startswith("PWD ")))
        for line in lines:
            if not line.startswith("INPUT "):
                continue
            file = (cwd / line[6:]).resolve()
            if file.is_relative_to(ROOT) and not file.is_relative_to(BUILD) and file.suffix in {".tex", ".bib", ".bst", ".cls", ".csv"}:
                source_paths.add(file.relative_to(ROOT).as_posix())
    source_paths.update(["scripts/build_ssrn_release.py", "scripts/build_ssrn_tables.py", "ssrn/README.md", "ssrn/REQUIREMENTS.md", "ssrn/QUALITY_REVIEW.md", "LICENSE"])
    # pdfTeX's recorder excludes files read by BibTeX. Include these explicitly;
    # otherwise a warm working tree can hide a broken editable-source archive.
    for folder in ("manuscript", "online_resource"):
        source_paths.update({f"journal/aor/{folder}/bibliography/references.bib",
                             f"journal/aor/{folder}/sn-mathphys-ay.bst"})
    for stem in ("exact_method_agreement", "registered_design_realized", "computational_scaling",
                 "failure_statuses", "registered_model_diagnostics"):
        source_paths.add(f"journal/aor/online_resource/tables/{stem}.tex")
    sources = {relative: sha(ROOT / relative) for relative in sorted(source_paths)}
    (RELEASE / "SOURCE_MANIFEST.json").write_text(json.dumps(sources, indent=2) + "\n")
    with tarfile.open(RELEASE / "financial-strategy-library-compression-ssrn-source.tar.gz", "w:gz") as archive:
        for relative in sorted(source_paths):
            archive.add(ROOT / relative, arcname=relative, recursive=False)
    git_commit = run(["git", "rev-parse", "HEAD"], cwd=ROOT).strip() if (ROOT / ".git").exists() else "source-archive"
    notes = f"""# SSRN preprint package {VERSION}

Prepared {DATE}. No SSRN submission, SSRN identifier, DOI, or peer review is claimed.

- Recommended upload: `{NAMES['complete']}` ({stats['complete']['pages']} pages; article followed by Online Resource 1).
- Separate article: `{NAMES['article']}` ({stats['article']['pages']} pages).
- Separate supplement: `{NAMES['supplement']}` ({stats['supplement']['pages']} pages, S-prefixed numbering).
- Paste `abstract_for_ssrn.txt` into SSRN's abstract field, including its AI disclosure paragraph.
- All portal fields are recorded in `submission_metadata.json`; see `ssrn/README.md` for the upload sequence.
- Build base commit: `{git_commit}`. This is the commit preceding packaging, not a claim that uncommitted edits were already committed.
- `SOURCE_MANIFEST.json` binds the exact source bytes, including any changes since that base commit.
- `SHA256SUMS` binds the delivered package files; `PDF_AUDIT.json` records structural PDF checks.
- The editable source archive contains only recorded public document inputs and builders. It is not the full computational replication repository.

Use the repository's `LICENSE` for original manuscript (CC BY 4.0), software (MIT), and third-party exclusions. Raw and row-level CRSP/WRDS data are excluded.
"""
    (RELEASE / "RELEASE_METADATA.md").write_text(notes)
    files = sorted(p for p in RELEASE.iterdir() if p.is_file() and p.name != "SHA256SUMS")
    (RELEASE / "SHA256SUMS").write_text("".join(f"{sha(p)}  {p.name}\n" for p in files))
    print(json.dumps(stats, indent=2))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package-only", action="store_true", help="reuse checked component builds")
    parser.add_argument("--check", action="store_true", help="verify frozen package and source checksums")
    args = parser.parse_args()
    if args.check:
        for line in (RELEASE / "SHA256SUMS").read_text().splitlines():
            digest, name = line.split("  ", 1)
            assert sha(RELEASE / name) == digest, f"package drift: {name}"
        for name, digest in json.loads((RELEASE / "SOURCE_MANIFEST.json").read_text()).items():
            assert sha(ROOT / name) == digest, f"source drift: {name}"
        assert json.loads((RELEASE / "submission_metadata.json").read_text()) == metadata(), "metadata drift"
        for name in NAMES.values():
            inspect_pdf(RELEASE / name)
        print("SSRN package, source hashes, metadata, PDF fonts, text, and links: PASS")
        return
    RELEASE.mkdir(parents=True, exist_ok=True)
    if not args.package_only:
        build()
    package()


if __name__ == "__main__":
    main()
