#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$ROOT/build"
STDOUT_LOG="$BUILD_DIR/latexmk.stdout.log"

for tool in latexmk pdflatex bibtex rg; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Required LaTeX tool is unavailable: $tool" >&2
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
        -outdir=build \
        main.tex
) 2>&1 | tee "$STDOUT_LOG"

LOG_FILE="$BUILD_DIR/main.log"
if [[ ! -f "$LOG_FILE" || ! -f "$BUILD_DIR/main.pdf" ]]; then
    echo "LaTeX build did not produce the expected log and PDF." >&2
    exit 1
fi

if rg -n \
    'LaTeX Warning: (Citation|Reference).*(undefined|multiply defined)|There were undefined references|Citation .* undefined|No file .*\.bbl|LaTeX Error: File .* not found' \
    "$LOG_FILE"; then
    echo "LaTeX build contains a broken citation, reference, or missing-file warning." >&2
    exit 1
fi

echo "LaTeX build passed: $BUILD_DIR/main.pdf"
