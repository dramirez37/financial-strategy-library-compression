#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$ROOT/build"
STDOUT_LOG="$BUILD_DIR/latexmk.stdout.log"

for tool in latexmk pdflatex bibtex rg; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Required Online Resource build tool is unavailable: $tool" >&2
        exit 1
    fi
done

mkdir -p "$BUILD_DIR"

(
    cd "$ROOT"
    latexmk \
        -g \
        -pdf \
        -interaction=nonstopmode \
        -halt-on-error \
        -file-line-error \
        -outdir="$BUILD_DIR" \
        -jobname=aor-online-resource-1 \
        main.tex
) 2>&1 | tee "$STDOUT_LOG"

LOG_FILE="$BUILD_DIR/aor-online-resource-1.log"
PDF_FILE="$BUILD_DIR/aor-online-resource-1.pdf"
AUX_FILE="$BUILD_DIR/aor-online-resource-1.aux"

if [[ ! -f "$LOG_FILE" || ! -f "$PDF_FILE" || ! -f "$AUX_FILE" ]]; then
    echo "Online Resource build did not produce the expected log, aux, and PDF." >&2
    exit 1
fi

if rg -n \
    'LaTeX Warning: (Citation|Reference).*(undefined|multiply defined)|There were undefined references|Citation .* undefined|No file .*\.bbl|LaTeX Error: File .* not found' \
    "$LOG_FILE"; then
    echo "Online Resource contains a broken citation, reference, or input." >&2
    exit 1
fi

if rg -n 'multiply defined' "$LOG_FILE"; then
    echo "Online Resource contains duplicate labels." >&2
    exit 1
fi

if rg -n '\\newlabel\{(?![^}]*@cref)[^}]+\}\{\{(?!S)' "$AUX_FILE" --pcre2; then
    echo "A numbered Online Resource label lacks the required S prefix." >&2
    exit 1
fi

echo "Online Resource build and reference audit passed: $PDF_FILE"
