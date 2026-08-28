#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTICLE_ROOT="$ROOT/journal/aor/manuscript"
RESOURCE_ROOT="$ROOT/journal/aor/online_resource"

fail() {
    printf 'aor-source-completeness: %s\n' "$1" >&2
    exit 1
}

for tool in awk cmp pdfinfo pdftotext rg shasum; do
    command -v "$tool" >/dev/null 2>&1 || fail "required command is unavailable: $tool"
done

audit_recorder() {
    local source_root="$1"
    local recorder="$2"
    local label="$3"
    local recorded_pwd
    local entry
    local resolved

    [[ -f "$recorder" ]] || fail "$label recorder is absent: ${recorder#"$ROOT/"}"
    recorded_pwd="$(awk '$1 == "PWD" { sub(/^PWD /, ""); print; exit }' "$recorder")"
    [[ -n "$recorded_pwd" ]] || fail "$label recorder has no PWD declaration"

    while IFS= read -r entry; do
        [[ -n "$entry" ]] || continue
        if [[ "$entry" == /* ]]; then
            resolved="$entry"
        else
            resolved="$recorded_pwd/$entry"
        fi
        if [[ -e "$resolved" ]]; then
            resolved="$(cd "$(dirname "$resolved")" && pwd -P)/$(basename "$resolved")"
        fi
        case "$resolved" in
            "$ROOT"/*)
                case "$resolved" in
                    "$source_root"/*) ;;
                    *) fail "$label reads a repository file outside its editable source tree: $resolved" ;;
                esac
                ;;
        esac
    done < <(awk '$1 == "INPUT" { sub(/^INPUT /, ""); print }' "$recorder" | sort -u)
}

article_pdf="$ARTICLE_ROOT/build/aor-journal-manuscript.pdf"
resource_pdf="$RESOURCE_ROOT/build/aor-online-resource-1.pdf"
article_log="$ARTICLE_ROOT/build/aor-journal-manuscript.log"
resource_log="$RESOURCE_ROOT/build/aor-online-resource-1.log"

for path in "$article_pdf" "$resource_pdf" "$article_log" "$resource_log"; do
    [[ -f "$path" ]] || fail "expected compiled artifact is absent: ${path#"$ROOT/"}"
done

bad='LaTeX Error|Citation .* undefined|Reference .* undefined|There were undefined references|undefined citations|No file .*\.bbl|File .* not found|multiply defined'
if rg -n "$bad" "$article_log" "$resource_log"; then
    fail "LaTeX log audit failed"
fi

audit_recorder \
    "$ARTICLE_ROOT" \
    "$ARTICLE_ROOT/build/aor-journal-manuscript.fls" \
    "article"
audit_recorder \
    "$RESOURCE_ROOT" \
    "$RESOURCE_ROOT/build/aor-online-resource-1.fls" \
    "Online Resource 1"

cmp -s "$ROOT/journal/aor/template/sn-jnl.cls" "$ARTICLE_ROOT/sn-jnl.cls" ||
    fail "article Springer class differs from the audited vendor copy"
cmp -s "$ROOT/journal/aor/template/bst/sn-mathphys-ay.bst" "$ARTICLE_ROOT/sn-mathphys-ay.bst" ||
    fail "article bibliography style differs from the audited vendor copy"

for tree in "$ARTICLE_ROOT" "$RESOURCE_ROOT"; do
    for required in main.tex sn-jnl.cls sn-mathphys-ay.bst bibliography/references.bib build.sh; do
        [[ -f "$tree/$required" ]] ||
            fail "editable source dependency is absent: ${tree#"$ROOT/"}/$required"
    done
done

pdfinfo "$article_pdf" >/dev/null
pdfinfo "$resource_pdf" >/dev/null

if rg -n '\(AOR[A-Za-z]+' "$ARTICLE_ROOT" "$RESOURCE_ROOT" -g '*.tex'; then
    fail "literal evidence-macro placeholder found in LaTeX source"
fi

article_text="$(mktemp "${TMPDIR:-/tmp}/aor-article-text.XXXXXX")"
resource_text="$(mktemp "${TMPDIR:-/tmp}/aor-resource-text.XXXXXX")"
trap 'rm -f "$article_text" "$resource_text"' EXIT
pdftotext "$article_pdf" "$article_text"
pdftotext "$resource_pdf" "$resource_text"
if rg -n '\(AOR[A-Za-z]+|DRAFT[[:space:]]+PLACEHOLDER|UNVERIFIED[[:space:]]+REQUIREMENT' \
    "$article_text" "$resource_text"; then
    fail "submission placeholder found in compiled PDF text"
fi

principal_theorems=(
    "journal/aor/manuscript/03_model_projection.tex|thm:raw-to-compressed-projection"
    "journal/aor/manuscript/04_cover_complexity.tex|thm:aor-tagged-cover-equivalence"
    "journal/aor/manuscript/04_cover_complexity.tex|thm:aor-safe-compression-complexity"
    "journal/aor/manuscript/05_algorithms.tex|prop:aor-complete-enumeration"
    "journal/aor/manuscript/05_algorithms.tex|thm:aor-requirement-mask-dp"
    "journal/aor/manuscript/05_algorithms.tex|thm:aor-weighted-greedy"
    "journal/aor/manuscript/05_algorithms.tex|prop:aor-certified-deletion-endpoint"
    "journal/aor/manuscript/05_algorithms.tex|thm:aor-heaviest-safe-first-gap"
    "journal/aor/online_resource/sections/09_extended_comparative_statics.tex|thm:or-capacity-value"
    "journal/aor/online_resource/sections/09_extended_comparative_statics.tex|thm:or-penalized-envelope"
)
for record in "${principal_theorems[@]}"; do
    source_path="${record%%|*}"
    theorem_label="${record#*|}"
    full_path="$ROOT/$source_path"
    [[ -f "$full_path" ]] || fail "principal theorem source is absent: $source_path"
    [[ "$(rg -F -c "\\label{$theorem_label}" "$full_path")" -eq 1 ]] ||
        fail "principal theorem label is absent or duplicated in active source: $theorem_label"
    rg -F -q "$theorem_label" "$ROOT/THEOREM_LEDGER.md" ||
        fail "principal theorem label is absent from THEOREM_LEDGER.md: $theorem_label"
    rg -F -q "$source_path" "$ROOT/THEOREM_LEDGER.md" ||
        fail "active theorem source is absent from THEOREM_LEDGER.md: $source_path"
done

printf '%s\n' \
    'aor-source-completeness: PDFs, logs, recorder graphs, Springer files, bibliographies, placeholders, theorem mappings, and local inputs passed.'
