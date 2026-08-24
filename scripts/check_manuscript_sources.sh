#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANUSCRIPT_ROOT="$ROOT/manuscript"
SUPPLEMENT_ROOT="$MANUSCRIPT_ROOT/online_supplement"
WORK_ROOT="$(mktemp -d)"
trap 'rm -rf "$WORK_ROOT"' EXIT

fail() {
    printf 'manuscript-source-check: %s\n' "$1" >&2
    exit 1
}

for tool in comm mktemp rg sed sort tr uniq wc; do
    command -v "$tool" >/dev/null 2>&1 || fail "required command is unavailable: $tool"
done

for path in \
    "$MANUSCRIPT_ROOT/main.tex" \
    "$MANUSCRIPT_ROOT/bibliography/references.bib" \
    "$SUPPLEMENT_ROOT/main.tex"; do
    [[ -f "$path" ]] || fail "required manuscript source is absent: ${path#"$ROOT/"}"
done

collect_active_sources() {
    local base="$1"
    local entry="$2"
    local label="$3"
    local file_list="$4"
    local pending=("$entry")
    local source
    local input
    local candidate
    local resolved
    local relative

    : > "$file_list"
    while ((${#pending[@]} > 0)); do
        source="${pending[0]}"
        pending=("${pending[@]:1}")
        [[ -f "$source" ]] || fail "$label source is absent: ${source#"$base/"}"
        resolved="$(cd "$(dirname "$source")" && pwd -P)/$(basename "$source")"
        case "$resolved" in
            "$ROOT"/*) ;;
            *) fail "$label input resolves outside the repository: $resolved" ;;
        esac
        relative="${resolved#"$ROOT/"}"
        rg -Fqx "$relative" "$file_list" && continue
        printf '%s\n' "$relative" >> "$file_list"

        while IFS= read -r input; do
            [[ -n "$input" ]] || continue
            case "$input" in
                /*) fail "$label input must be repository-relative: $input" ;;
            esac
            [[ "$input" == *.tex ]] || input="$input.tex"
            candidate="$base/$input"
            [[ -f "$candidate" ]] || fail "$label input is absent: $input"
            pending+=("$candidate")
        done < <(
            rg -o --no-filename '\\input\{[^}]+\}' "$resolved" 2>/dev/null |
                sed -E 's/^\\input\{//; s/\}$//' || true
        )
    done
}

collect_labels_and_references() {
    local file_list="$1"
    local label="$2"
    local source
    local labels="$WORK_ROOT/$label-labels.txt"
    local references="$WORK_ROOT/$label-references.txt"
    local duplicates="$WORK_ROOT/$label-duplicates.txt"
    local missing="$WORK_ROOT/$label-missing.txt"

    : > "$labels"
    : > "$references"
    while IFS= read -r source; do
        rg -o --no-filename '\\label\{[^}]+\}' "$ROOT/$source" 2>/dev/null || true
    done < "$file_list" | sed -E 's/^\\label\{//; s/\}$//' | sort > "$labels"
    while IFS= read -r source; do
        rg -o --no-filename '\\(auto|page|eq|[cC])?ref\{[^}]+\}' "$ROOT/$source" 2>/dev/null || true
    done < "$file_list" |
        sed -E 's/^\\(auto|page|eq|[cC])?ref\{//; s/\}$//' |
        tr ',' '\n' |
        sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' |
        sort -u > "$references"

    uniq -d "$labels" > "$duplicates"
    [[ ! -s "$duplicates" ]] || {
        sed "s/^/$label duplicate LaTeX label: /" "$duplicates" >&2
        exit 1
    }
    comm -23 "$references" "$labels" > "$missing"
    [[ ! -s "$missing" ]] || {
        sed "s/^/$label missing LaTeX label: /" "$missing" >&2
        exit 1
    }
    printf '%s source references passed: %s labels, %s references.\n' \
        "$label" "$(wc -l < "$labels" | tr -d ' ')" "$(wc -l < "$references" | tr -d ' ')"
}

collect_active_sources "$MANUSCRIPT_ROOT" "$MANUSCRIPT_ROOT/main.tex" main \
    "$WORK_ROOT/main-files.txt"
collect_active_sources "$SUPPLEMENT_ROOT" "$SUPPLEMENT_ROOT/main.tex" supplement \
    "$WORK_ROOT/supplement-files.txt"
collect_labels_and_references "$WORK_ROOT/main-files.txt" main
collect_labels_and_references "$WORK_ROOT/supplement-files.txt" supplement

BIB_KEYS="$WORK_ROOT/bib-keys.txt"
CITED_KEYS="$WORK_ROOT/cited-keys.txt"
DUPLICATES="$WORK_ROOT/bib-duplicates.txt"
MISSING="$WORK_ROOT/bib-missing.txt"
rg -o --no-filename --replace '$1' \
    '^@[[:alpha:]]+[[:space:]]*\{([^,[:space:]]+),' \
    "$MANUSCRIPT_ROOT/bibliography/references.bib" | sort > "$BIB_KEYS"
while IFS= read -r source; do
    rg -o --no-filename '\\cite[a-zA-Z*]*\{[^}]+\}' "$ROOT/$source" 2>/dev/null || true
done < <(sort -u "$WORK_ROOT/main-files.txt" "$WORK_ROOT/supplement-files.txt") |
    sed -E 's/^[^{]*\{//; s/\}$//' |
    tr ',' '\n' |
    sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' |
    sort -u > "$CITED_KEYS"
uniq -d "$BIB_KEYS" > "$DUPLICATES"
[[ ! -s "$DUPLICATES" ]] || {
    sed 's/^/duplicate bibliography key: /' "$DUPLICATES" >&2
    exit 1
}
comm -23 "$CITED_KEYS" "$BIB_KEYS" > "$MISSING"
[[ ! -s "$MISSING" ]] || {
    sed 's/^/missing bibliography key: /' "$MISSING" >&2
    exit 1
}

printf 'Bibliography source audit passed: %s entries, %s cited keys.\n' \
    "$(wc -l < "$BIB_KEYS" | tr -d ' ')" "$(wc -l < "$CITED_KEYS" | tr -d ' ')"
