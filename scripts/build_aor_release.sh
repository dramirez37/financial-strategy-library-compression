#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="v0.2.0-aor-submission"
RELEASE_ROOT="$ROOT/release/$VERSION"
ARTICLE_PDF="$ROOT/journal/aor/manuscript/build/aor-journal-manuscript.pdf"
RESOURCE_PDF="$ROOT/journal/aor/online_resource/build/aor-online-resource-1.pdf"
SOURCE_ARCHIVE="algolib-$VERSION-source.tar.gz"
BENCHMARK_ARCHIVE="registered-algorithmic-compression-benchmark-v2-public.tar.gz"
MODE="${1:---build}"

fail() {
    printf 'aor-release: %s\n' "$1" >&2
    exit 1
}

for tool in awk cp git lake latexmk mkdir mv pdfinfo pdflatex rg shasum tar; do
    command -v "$tool" >/dev/null 2>&1 || fail "required command is unavailable: $tool"
done

check_inputs() {
    [[ "$(git -C "$ROOT" branch --show-current)" == "journal/aor-v0.2.0" ]] ||
        fail "the AoOR release must be built on journal/aor-v0.2.0"
    for path in \
        "$ROOT/journal/aor/release/CITATION.cff" \
        "$ROOT/journal/aor/release/zenodo.json" \
        "$ROOT/journal/aor/release/RELEASE_NOTES.md" \
        "$ROOT/journal/aor/requirements/OFFICIAL_REQUIREMENTS.md" \
        "$ROOT/journal/aor/requirements/COMPLIANCE_REPORT.md" \
        "$ROOT/experiments/algorithmic_compression_v2/DESIGN_LOCK.json" \
        "$ROOT/experiments/algorithmic_compression_v2/results/final_algorithm_runs.csv" \
        "$ROOT/experiments/algorithmic_compression_v2/results/audit/audit_summary.toml"; do
        [[ -f "$path" ]] || fail "required release input is absent: ${path#"$ROOT/"}"
    done
    rg -qF "version: $VERSION" "$ROOT/journal/aor/release/CITATION.cff" ||
        fail "CITATION.cff does not identify $VERSION"
    rg -qF '"version": "v0.2.0-aor-submission"' "$ROOT/journal/aor/release/zenodo.json" ||
        fail ".zenodo.json does not identify $VERSION"
    if rg -q '"doi"[[:space:]]*:' "$ROOT/journal/aor/release/zenodo.json" ||
       rg -q '^doi:' "$ROOT/journal/aor/release/CITATION.cff"; then
        fail "citation metadata claims a DOI that has not been assigned"
    fi
    rg -q '^passed = true$' \
        "$ROOT/experiments/algorithmic_compression_v2/results/audit/audit_summary.toml" ||
        fail "committed benchmark audit is not PASS"
}

check_release() {
    for path in \
        "$RELEASE_ROOT/aor-journal-manuscript.pdf" \
        "$RELEASE_ROOT/aor-online-resource-1.pdf" \
        "$RELEASE_ROOT/$SOURCE_ARCHIVE" \
        "$RELEASE_ROOT/$BENCHMARK_ARCHIVE" \
        "$RELEASE_ROOT/SHA256SUMS" \
        "$RELEASE_ROOT/COMMIT_METADATA.toml" \
        "$RELEASE_ROOT/SOFTWARE_ENVIRONMENT.md" \
        "$RELEASE_ROOT/CITATION.cff" \
        "$RELEASE_ROOT/zenodo.json" \
        "$RELEASE_ROOT/RELEASE_NOTES.md"; do
        [[ -f "$path" ]] || fail "release artifact is absent: ${path#"$ROOT/"}"
    done

    (
        cd "$RELEASE_ROOT"
        shasum -a 256 -c SHA256SUMS
    ) >/dev/null || fail "release checksum verification failed"
    pdfinfo "$RELEASE_ROOT/aor-journal-manuscript.pdf" >/dev/null
    pdfinfo "$RELEASE_ROOT/aor-online-resource-1.pdf" >/dev/null

    source_listing="$(tar -tzf "$RELEASE_ROOT/$SOURCE_ARCHIVE")"
    benchmark_listing="$(tar -tzf "$RELEASE_ROOT/$BENCHMARK_ARCHIVE")"
    for required in \
        journal/aor/manuscript/main.tex \
        journal/aor/online_resource/main.tex \
        journal/aor/manuscript/sn-jnl.cls \
        journal/aor/manuscript/sn-mathphys-ay.bst \
        julia/Project.toml \
        julia/Manifest.toml \
        formal/lean-toolchain \
        scripts/aor_check.sh; do
        printf '%s\n' "$source_listing" | rg -q "/$required$" ||
            fail "source archive is missing $required"
    done

    if printf '%s\n' "$benchmark_listing" | rg -q '/results/control/'; then
        fail "public benchmark archive contains machine-local process controls"
    fi
    for required in \
        DESIGN_LOCK.json \
        registry/INSTANCE_REGISTRY.csv \
        registry/SEED_REGISTRY.csv \
        results/final_algorithm_runs.csv \
        results/ARTIFACT_MANIFEST.csv \
        results/audit/audit_summary.toml; do
        printf '%s\n' "$benchmark_listing" | rg -q "/$required$" ||
            fail "public benchmark archive is missing $required"
    done

    forbidden='(^|/)(data/licensed|financial_terminal_audit/data/[^/]+|financial_annual_walkforward_audit/data/[^/]+|[^/]*(crsp|wrds)[^/]*\.(csv|tsv|parquet|sas7bdat|xpt|dta|rds|rdata|jld2?))($|/)'
    if printf '%s\n%s\n' "$source_listing" "$benchmark_listing" | rg -qi "$forbidden"; then
        fail "release archive contains a forbidden licensed-data path"
    fi
    if rg -q '"doi"[[:space:]]*:' "$RELEASE_ROOT/zenodo.json" ||
       rg -q '^doi:' "$RELEASE_ROOT/CITATION.cff"; then
        fail "release metadata claims an unassigned DOI"
    fi

    printf '%s\n' 'aor-release: versioned PDFs, archives, metadata, checksums, and licensed-data boundary passed.'
}

build_release() {
    check_inputs
    [[ -f "$ARTICLE_PDF" ]] || fail "journal PDF is absent; run make aor-manuscript"
    [[ -f "$RESOURCE_PDF" ]] || fail "Online Resource PDF is absent; run make aor-manuscript"
    if rg -q 'not yet supplied|AUTHOR CONFIRMATION REQUIRED|pending author confirmation' \
        "$ROOT/journal/aor/manuscript/author_metadata.tex"; then
        fail "funding or competing-interest declarations remain unconfirmed"
    fi
    if rg -q '^overall_status: BLOCKED_' \
        "$ROOT/journal/aor/requirements/COMPLIANCE_REPORT.md"; then
        fail "the official-requirements compliance report remains blocked"
    fi
    [[ -z "$(git -C "$ROOT" status --porcelain=v1 --untracked-files=all)" ]] ||
        fail "build from a clean committed worktree so archive and commit provenance agree"

    source_commit="$(git -C "$ROOT" rev-parse HEAD)"
    source_commit_date="$(git -C "$ROOT" show -s --format=%cI HEAD)"
    source_branch="$(git -C "$ROOT" branch --show-current)"
    temporary_root="$(mktemp -d "$ROOT/release/.aor-release.XXXXXX")"
    trap 'rm -rf "$temporary_root"' EXIT
    payload="$temporary_root/$VERSION"
    mkdir -p "$payload"

    source_paths=(
        .gitattributes .gitignore .github/workflows/aor.yml .zenodo.json
        ARTIFACT_MANIFEST.md CITATION.cff DATA_ACCESS.md LICENSE Makefile README.md
        REPRODUCIBILITY.md THEOREM_LEDGER.md
        scripts julia formal shared journal/aor experiments/configs
        experiments/financial_algorithm_comparison_v1
        experiments/financial_resource_optimization
    )
    git -C "$ROOT" archive \
        --format=tar.gz \
        --prefix="algolib-$VERSION/" \
        --output="$payload/$SOURCE_ARCHIVE" \
        "$source_commit" -- "${source_paths[@]}"
    git -C "$ROOT" archive \
        --format=tar.gz \
        --prefix="algorithmic_compression_v2/" \
        --output="$payload/$BENCHMARK_ARCHIVE" \
        "$source_commit" -- experiments/algorithmic_compression_v2

    cp "$ARTICLE_PDF" "$payload/aor-journal-manuscript.pdf"
    cp "$RESOURCE_PDF" "$payload/aor-online-resource-1.pdf"
    cp "$ROOT/journal/aor/release/CITATION.cff" "$payload/CITATION.cff"
    cp "$ROOT/journal/aor/release/zenodo.json" "$payload/zenodo.json"
    cp "$ROOT/journal/aor/release/RELEASE_NOTES.md" "$payload/RELEASE_NOTES.md"

    source_hash="$(shasum -a 256 "$payload/$SOURCE_ARCHIVE" | awk '{print $1}')"
    benchmark_hash="$(shasum -a 256 "$payload/$BENCHMARK_ARCHIVE" | awk '{print $1}')"
    cat > "$payload/COMMIT_METADATA.toml" <<EOF
release_version = "$VERSION"
source_branch = "$source_branch"
source_commit = "$source_commit"
source_commit_date = "$source_commit_date"
source_worktree_clean = true
source_archive_sha256 = "$source_hash"
public_benchmark_archive_sha256 = "$benchmark_hash"
commit_self_reference = "The release-artifact commit necessarily follows the recorded source commit; archive hashes identify the exact released bytes."
EOF

    julia_version="${JULIA_EXE:-$ROOT/.local_runtime/julia-1.12.6/bin/julia}"
    julia_version="$($julia_version --startup-file=no --version)"
    lean_version="$(cd "$ROOT/formal" && lake env lean --version | sed -n '1p')"
    latexmk_version="$(latexmk --version | sed -n '1p')"
    pdftex_version="$(pdflatex --version | sed -n '1p')"
    cat > "$payload/SOFTWARE_ENVIRONMENT.md" <<EOF
# Software environment record

- Release: \`$VERSION\`
- Source commit: \`$source_commit\`
- Julia: \`$julia_version\`
- Julia manifest SHA-256: \`$(shasum -a 256 "$ROOT/julia/Manifest.toml" | awk '{print $1}')\`
- Julia test manifest SHA-256: \`$(shasum -a 256 "$ROOT/julia/test/Manifest.toml" | awk '{print $1}')\`
- Lean: \`$lean_version\`
- Lean toolchain: \`$(tr -d '\r\n' < "$ROOT/formal/lean-toolchain")\`
- Lake manifest SHA-256: \`$(shasum -a 256 "$ROOT/formal/lake-manifest.json" | awk '{print $1}')\`
- latexmk: \`$latexmk_version\`
- pdfTeX: \`$pdftex_version\`
- Springer class SHA-256: \`$(shasum -a 256 "$ROOT/journal/aor/manuscript/sn-jnl.cls" | awk '{print $1}')\`
- Springer author-year BST SHA-256: \`$(shasum -a 256 "$ROOT/journal/aor/manuscript/sn-mathphys-ay.bst" | awk '{print $1}')\`
- Build OS: \`$(uname -srm)\`

The final algorithmic benchmark was not rerun while building this release. Its
recorded execution environment remains in the public benchmark archive. No
licensed financial workflow was invoked.
EOF

    (
        cd "$payload"
        for path in \
            CITATION.cff COMMIT_METADATA.toml RELEASE_NOTES.md SOFTWARE_ENVIRONMENT.md \
            aor-journal-manuscript.pdf aor-online-resource-1.pdf \
            "$SOURCE_ARCHIVE" "$BENCHMARK_ARCHIVE" zenodo.json; do
            shasum -a 256 "$path"
        done | sort -k2 > SHA256SUMS
    )

    case "$RELEASE_ROOT" in
        "$ROOT/release/$VERSION") ;;
        *) fail "refusing to replace unexpected release path: $RELEASE_ROOT" ;;
    esac
    rm -rf "$RELEASE_ROOT"
    mv "$payload" "$RELEASE_ROOT"
    trap - EXIT
    rm -rf "$temporary_root"
    check_release
}

case "$MODE" in
    --check-inputs) check_inputs ;;
    --check) check_inputs; check_release ;;
    --build) build_release ;;
    *) fail "usage: build_aor_release.sh [--build|--check|--check-inputs]" ;;
esac
