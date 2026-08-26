#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
JOURNAL_ROOT="$ROOT/journal/aor"
DESTINATION="$JOURNAL_ROOT/submission"

"$JOURNAL_ROOT/check.sh" --submission-ready

rm -rf "$DESTINATION"
mkdir -p "$DESTINATION"

(
    cd "$ROOT/manuscript"
    latexpand --empty-comments "$JOURNAL_ROOT/main.tex" > "$DESTINATION/manuscript.tex"
)
perl -0pi -e 's/\\bibliography\{bibliography\/references\}/\\bibliography{references}/g' \
    "$DESTINATION/manuscript.tex"

cp "$JOURNAL_ROOT/template/sn-jnl.cls" "$DESTINATION/sn-jnl.cls"
cp "$JOURNAL_ROOT/template/bst/sn-mathphys-ay.bst" "$DESTINATION/sn-mathphys-ay.bst"
cp "$ROOT/manuscript/bibliography/references.bib" "$DESTINATION/references.bib"
cp "$JOURNAL_ROOT/build/main/aor-journal.pdf" "$DESTINATION/manuscript.pdf"
cp "$JOURNAL_ROOT/build/supplement/ESM_1.pdf" "$DESTINATION/ESM_1.pdf"
cp "$JOURNAL_ROOT/cover_letter.md" "$DESTINATION/cover_letter.md"

if rg -n '\\input\{|\\include\{' "$DESTINATION/manuscript.tex"; then
    printf '%s\n' 'journal-bundle: flattened manuscript retains an input/include' >&2
    exit 1
fi

printf 'journal-bundle: wrote %s\n' "$DESTINATION"
