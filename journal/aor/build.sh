#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
JOURNAL_ROOT="$ROOT/journal/aor"
JULIA_EXE="${JULIA_EXE:-$ROOT/.local_runtime/julia-1.12.6/bin/julia}"

[[ -x "$JULIA_EXE" ]] || {
    printf 'journal-build: Julia 1.12.6 executable is absent: %s\n' "$JULIA_EXE" >&2
    exit 1
}

mkdir -p "$JOURNAL_ROOT/build/main" "$JOURNAL_ROOT/build/supplement"

"$JULIA_EXE" --startup-file=no --project="$ROOT/julia" \
    "$JOURNAL_ROOT/scripts/generate_journal_artifacts.jl" --check

export TEXINPUTS="$JOURNAL_ROOT/template:$ROOT/manuscript:"
export BIBINPUTS="$ROOT/manuscript:"
export BSTINPUTS="$JOURNAL_ROOT/template/bst:"

(
    cd "$ROOT/manuscript"
    latexmk -pdf -interaction=nonstopmode -halt-on-error -file-line-error \
        -outdir="$JOURNAL_ROOT/build/main" -jobname=aor-journal \
        "$JOURNAL_ROOT/main.tex"
)

(
    cd "$ROOT/manuscript/online_supplement"
    latexmk -pdf -interaction=nonstopmode -halt-on-error -file-line-error \
        -outdir="$JOURNAL_ROOT/build/supplement" -jobname=ESM_1 \
        "$JOURNAL_ROOT/supplement.tex"
)

printf 'journal-build: wrote %s\n' "$JOURNAL_ROOT/build/main/aor-journal.pdf"
printf 'journal-build: wrote %s\n' "$JOURNAL_ROOT/build/supplement/ESM_1.pdf"
