#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

TREE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$TREE/../../.." && pwd)"
TEMPLATE="$ROOT/journal/aor/template"
OUT="$TREE/build"

test -f "$TEMPLATE/sn-jnl.cls"
test -f "$TEMPLATE/bst/sn-mathphys-ay.bst"
mkdir -p "$OUT"

export TEXINPUTS="$TREE:$TEMPLATE:"
export BIBINPUTS="$TREE:"
export BSTINPUTS="$TEMPLATE/bst:"

cd "$TREE"
latexmk -pdf -interaction=nonstopmode -halt-on-error -file-line-error \
  -outdir="$OUT" -jobname=aor-journal-scaffold main.tex

printf 'aor-scaffold-build: wrote %s\n' "$OUT/aor-journal-scaffold.pdf"
