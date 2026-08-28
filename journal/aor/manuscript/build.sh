#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

TREE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$TREE/../../.." && pwd)"
OUT="$TREE/build"

test -f "$TREE/sn-jnl.cls"
test -f "$TREE/sn-mathphys-ay.bst"
mkdir -p "$OUT"

export TEXINPUTS="$TREE:"
export BIBINPUTS="$TREE:"
export BSTINPUTS="$TREE:"

cd "$TREE"
latexmk -pdf -interaction=nonstopmode -halt-on-error -file-line-error \
  -outdir="$OUT" -jobname=aor-journal-manuscript main.tex

printf 'aor-journal-build: wrote %s\n' "$OUT/aor-journal-manuscript.pdf"
