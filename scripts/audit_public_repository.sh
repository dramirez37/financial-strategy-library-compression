#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
    printf 'public-audit: %s\n' "$1" >&2
    exit 1
}

print_paths_and_fail() {
    local message="$1"
    local paths="$2"
    printf 'public-audit: %s\n' "$message" >&2
    printf '%s\n' "$paths" | sed 's/^/  /' >&2
    exit 1
}

for tool in awk file find git rg sed shasum sort tr uniq wc; do
    command -v "$tool" >/dev/null 2>&1 || fail "required command is unavailable: $tool"
done

TRACKED_FILES="$(git ls-files)"
[[ -n "$TRACKED_FILES" ]] || fail "Git index contains no files"

TRACKED_IGNORED="$(git ls-files -ci --exclude-standard)"
[[ -z "$TRACKED_IGNORED" ]] ||
    print_paths_and_fail "tracked files are accidentally matched by .gitignore" "$TRACKED_IGNORED"

FORBIDDEN_PATHS="$(printf '%s\n' "$TRACKED_FILES" | rg -i \
    '(^|/)(\.env($|\.)|\.netrc$|\.pgpass$|\.odbc\.ini$|\.npmrc$|\.wrds[^/]*$|wrds_credentials?[^/]*$|credentials?($|[._-])|secrets?($|[._-])|\.ssh/|id_(rsa|ed25519)[^/]*$|data/(raw|cache)/|query_cache/|cached_queries/|\.ipynb_checkpoints/|[^/]+\.ipynb$|[^/]+\.(csv\.gz|tsv\.gz|json\.gz|pem|key|p12|pfx|ppk|sas7bdat|xpt|dta|rds|rdata|parquet|feather|arrow|avro|orc|fst|h5|hdf5|hdf|jld|jld2|jlso|jls|bson|ser|pkl|pickle|joblib|npy|npz|mat|sav|sqlite|sqlite3|duckdb|db)$)' || true)"
[[ -z "$FORBIDDEN_PATHS" ]] ||
    print_paths_and_fail "credential, notebook, or proprietary-data filenames are tracked" "$FORBIDDEN_PATHS"

MACHINE_PATHS="$(printf '%s\n' "$TRACKED_FILES" | rg -i \
    '(^|/)(\.DS_Store|Thumbs\.db|__pycache__|\.pytest_cache|\.cache|\.julia|\.lake|\.ipynb_checkpoints)(/|$)|\.(olean|ilean|trace|ji|o|a|so|dylib|dll|exe|class|wasm|tmp|swp|swo|bak|orig|rej)$' || true)"
[[ -z "$MACHINE_PATHS" ]] ||
    print_paths_and_fail "machine-specific cache, compiled, or temporary files are tracked" "$MACHINE_PATHS"

for licensed_dir in \
    data/licensed \
    experiments/financial_terminal_audit/data \
    experiments/financial_annual_walkforward_audit/data; do
    while IFS= read -r path; do
        case "$path" in
            data/licensed/.gitkeep|"$licensed_dir/README.md"|"$licensed_dir/provenance.template.toml")
                ;;
            *)
                fail "licensed-data directory contains a tracked non-contract file: $path"
                ;;
        esac
    done < <(git ls-files "$licensed_dir")
done

RAW_NAMED_FILES="$(printf '%s\n' "$TRACKED_FILES" | rg -i \
    '(^|/)[^/]*(crsp|wrds)[^/]*\.(csv|tsv|csv\.gz|tsv\.gz|json\.gz|parquet|feather|arrow|avro|orc|fst|h5|hdf5|hdf|jld|jld2|jlso|jls|bson|ser|pkl|pickle|joblib|npy|npz|sas7bdat|xpt|dta|rds|rdata|mat|sav|sqlite|sqlite3|duckdb|db)$' || true)"
[[ -z "$RAW_NAMED_FILES" ]] ||
    print_paths_and_fail "a tracked data filename identifies a licensed provider extract" "$RAW_NAMED_FILES"

while IFS= read -r path; do
    [[ "$path" == *.csv ]] || continue
    header="$(sed -n '1p' "$path")"
    raw_columns="$(printf '%s\n' "$header" | tr ',' '\n' | awk '
        BEGIN { count = 0 }
        {
            field = tolower($0)
            gsub(/^"|"$|\r$/, "", field)
            if (field ~ /^(permno|permco|dlycaldt|dlyret|dlyprc|dlyclose|dlyvol|dlydelflg|dlyretmissflg|shrout|cusip|ncusip|secinfostartdt|secinfoenddt|securitytype|securitysubtype)$/) {
                count += 1
            }
        }
        END { print count }
    ')"
    if (( raw_columns >= 3 )); then
        fail "tracked CSV has a raw CRSP-like row schema: $path"
    fi
    read -r date_columns identity_columns market_columns <<< "$(printf '%s\n' "$header" | tr ',' '\n' | awk '
        BEGIN { dates = 0; identities = 0; markets = 0 }
        {
            field = tolower($0)
            gsub(/^"|"$|\r$/, "", field)
            if (field ~ /^(date|trading_date|dlycaldt)$/) dates += 1
            if (field ~ /^(ticker|permno|permco|cusip|ncusip|security_id)$/) identities += 1
            if (field ~ /^(return|ret|total_return|total_return_index|close|price|volume|dlyret|dlyprc|dlyclose|dlyvol)$/) markets += 1
        }
        END { print dates, identities, markets }
    ')"
    if (( date_columns >= 1 && identity_columns >= 1 && market_columns >= 2 )); then
        fail "tracked CSV has a row-level financial-observation schema: $path"
    fi
done <<< "$TRACKED_FILES"

SECRET_PATTERN='(AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{30,}|gh[pousr]_[0-9A-Za-z]{30,}|github_pat_[0-9A-Za-z_]{20,}|sk-[0-9A-Za-z_-]{20,}|xox[baprs]-[0-9A-Za-z-]{10,}|-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----)'
SECRET_FILES="$(git grep -IlE "$SECRET_PATTERN" -- . || true)"
[[ -z "$SECRET_FILES" ]] ||
    print_paths_and_fail "possible credential or private-key signatures found; values suppressed" "$SECRET_FILES"

CREDENTIAL_ASSIGNMENT_PATTERN='(^|[^[:alnum:]_])(api[_-]?key|access[_-]?token|client[_-]?secret|password|passwd|credential)[[:space:]]*[:=][[:space:]]*[^[:space:]#]+'
CREDENTIAL_FILES="$(git grep -IlEi "$CREDENTIAL_ASSIGNMENT_PATTERN" -- . || true)"
[[ -z "$CREDENTIAL_FILES" ]] ||
    print_paths_and_fail "possible credential assignments found; values suppressed" "$CREDENTIAL_FILES"

WRDS_IDENTITY_PATTERN='(^|[^[:alnum:]_])(wrds[_-]?(user(name)?|login)|pguser|pgpassword)[[:space:]]*[:=][[:space:]]*[^[:space:]#]+'
WRDS_IDENTITY_FILES="$(git grep -IlEi "$WRDS_IDENTITY_PATTERN" -- . || true)"
[[ -z "$WRDS_IDENTITY_FILES" ]] ||
    print_paths_and_fail "possible WRDS/database identity assignments found; values suppressed" "$WRDS_IDENTITY_FILES"

JDBC_POSTGRES_PREFIX='jdbc:''postgresql://'
DATABASE_CONNECTION_PATTERN="(postgres(ql)?://[^[:space:]]+:[^[:space:]@]+@|${JDBC_POSTGRES_PREFIX}|(^|[^[:alnum:]_])(dsn|dbname)[[:space:]]*=[[:space:]]*[^[:space:]#]+)"
DATABASE_CONNECTION_FILES="$(git grep -IlEi "$DATABASE_CONNECTION_PATTERN" -- . || true)"
[[ -z "$DATABASE_CONNECTION_FILES" ]] ||
    print_paths_and_fail "possible database connection strings found; values suppressed" "$DATABASE_CONNECTION_FILES"

MAC_HOME_PREFIX="/""Users/"
UNIX_HOME_PREFIX="/""home/"
LOCAL_PATH_PATTERN="(${MAC_HOME_PREFIX}[^/[:space:]]+|${UNIX_HOME_PREFIX}[^/[:space:]]+|[A-Za-z]:\\\\Users\\\\[^\\\\[:space:]]+)"
LOCAL_PATH_FILES="$(git grep -IlE "$LOCAL_PATH_PATTERN" -- . || true)"
[[ -z "$LOCAL_PATH_FILES" ]] ||
    print_paths_and_fail "absolute local home-directory paths found" "$LOCAL_PATH_FILES"

PRIVATE_SSH_PATTERN="((~|${MAC_HOME_PREFIX}[^/[:space:]]+|${UNIX_HOME_PREFIX}[^/[:space:]]+)/\\.ssh/[^[:space:]]+|IdentityFile[[:space:]]+[^[:space:]]*\\.ssh/[^[:space:]]+)"
PRIVATE_SSH_FILES="$(git grep -IlE "$PRIVATE_SSH_PATTERN" -- . || true)"
[[ -z "$PRIVATE_SSH_FILES" ]] ||
    print_paths_and_fail "private SSH paths found" "$PRIVATE_SSH_FILES"

EMAIL_PATTERN='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
PUBLICATION_EMAIL='ramirezdavv'@'gmail.com'
EMAIL_FILES="$(git grep -IlE "$EMAIL_PATTERN" -- . || true)"
UNAPPROVED_EMAIL_FILES="$(printf '%s\n' "$EMAIL_FILES" | rg -v \
    '^(CITATION\.cff|manuscript/main\.tex|manuscript/online_supplement/main\.tex|release/v0\.1\.1-arxiv/arxiv-source/(paper|supplement)\.tex)$' || true)"
[[ -z "$UNAPPROVED_EMAIL_FILES" ]] ||
    print_paths_and_fail "email addresses require publication review; values suppressed" "$UNAPPROVED_EMAIL_FILES"

EMAIL_VALUES="$(git grep -IhoE "$EMAIL_PATTERN" -- . || true)"
UNAPPROVED_EMAIL_VALUES="$(printf '%s\n' "$EMAIL_VALUES" | rg -vxF "$PUBLICATION_EMAIL" || true)"
[[ -z "$UNAPPROVED_EMAIL_VALUES" ]] ||
    print_paths_and_fail "unapproved email values found; containing paths suppressed" "$EMAIL_FILES"

for publication_email_path in \
    CITATION.cff \
    manuscript/main.tex \
    manuscript/online_supplement/main.tex \
    release/v0.1.1-arxiv/arxiv-source/paper.tex \
    release/v0.1.1-arxiv/arxiv-source/supplement.tex; do
    rg -qF "$PUBLICATION_EMAIL" "$publication_email_path" ||
        fail "publication-approved corresponding email is missing from $publication_email_path"
done

LARGE_TEXT_COUNT=0
LARGE_CSV_COUNT=0
while IFS= read -r path; do
    bytes="$(wc -c < "$path" | tr -d ' ')"
    if [[ "$path" == *.csv ]] && (( bytes >= 1000000 )); then
        LARGE_CSV_COUNT=$((LARGE_CSV_COUNT + 1))
    fi
    if (( bytes >= 5000000 )); then
        mime="$(file -b --mime-type "$path")"
        case "$mime" in
            text/*|application/json|image/svg+xml)
                LARGE_TEXT_COUNT=$((LARGE_TEXT_COUNT + 1))
                ;;
            *)
                fail "tracked binary artifact exceeds 5 MB: $path ($bytes bytes, $mime)"
                ;;
        esac
    fi
    (( bytes < 40000000 )) || fail "tracked artifact exceeds the 40 MB public-tree ceiling: $path"
done <<< "$TRACKED_FILES"

LICENSED_INPUT_MESSAGE='Licensed CRSP/WRDS inputs are not distributed with this repository. See DATA_ACCESS.md.'
rg -qF "$LICENSED_INPUT_MESSAGE" julia/scripts/prepare_financial_terminal_audit_data.jl ||
    fail "the financial preparation failure message is missing"
rg -qF "$LICENSED_INPUT_MESSAGE" julia/scripts/audit_financial_annual_universe.jl ||
    fail "the annual universe-audit licensed-input failure message is missing"
rg -qF 'TerminalPreparation._require_licensed_source(config["source"])' julia/scripts/prepare_financial_annual_walkforward_audit_data.jl ||
    fail "the annual walk-forward preparation script does not use the licensed-input guard"
for contract_path in data/README.md DATA_ACCESS.md; do
    rg -qF 'ALGOLIB_CRSP_ROOT' "$contract_path" ||
        fail "the licensed source-root override is undocumented in $contract_path"
done

for status_path in \
    experiments/results/summaries/financial_terminal_audit_status.json \
    experiments/results/summaries/financial_annual_walkforward_audit_status.json; do
    [[ -f "$status_path" ]] || fail "required public aggregate status is absent: $status_path"
    rg -q '"raw_data_redistribution_permitted":false' "$status_path" ||
        fail "raw-data redistribution boundary is missing from $status_path"
    rg -q '"aggregate_outputs_publishable":true' "$status_path" ||
        fail "aggregate-publication boundary is missing from $status_path"
done

LOCAL_LICENSED_COUNT=0
for licensed_dir in \
    data/licensed \
    experiments/financial_terminal_audit/data \
    experiments/financial_annual_walkforward_audit/data; do
    while IFS= read -r path; do
        case "$path" in
            data/licensed/.gitkeep|"$licensed_dir/README.md"|"$licensed_dir/provenance.template.toml")
                ;;
            *)
                git check-ignore -q "$path" || fail "local licensed file is not ignored: $path"
                LOCAL_LICENSED_COUNT=$((LOCAL_LICENSED_COUNT + 1))
                ;;
        esac
    done < <(find "$licensed_dir" -type f -print)
done

RELEASE_VERSION='v0.1.1-arxiv'
RELEASE_DATE='2026-08-25'
RELEASE_DISPLAY_DATE='August 2026'
REPOSITORY_URL='https://github.com/dramirez37/financial-strategy-library-compression'
RELEASE_ROOT="release/$RELEASE_VERSION"
RELEASE_METADATA="$RELEASE_ROOT/RELEASE_METADATA.md"
MAIN_RELEASE_PDF="$RELEASE_ROOT/financial-strategy-library-compression-preprint.pdf"
SUPPLEMENT_RELEASE_PDF="$RELEASE_ROOT/financial-strategy-library-compression-online-supplement.pdf"
ARXIV_SOURCE_ARCHIVE="$RELEASE_ROOT/financial-strategy-library-compression-arxiv-source.tar.gz"

for release_path in \
    .gitattributes \
    "$RELEASE_METADATA" \
    "$MAIN_RELEASE_PDF" \
    "$SUPPLEMENT_RELEASE_PDF" \
    "$ARXIV_SOURCE_ARCHIVE" \
    "$RELEASE_ROOT/arxiv-source/paper.tex" \
    "$RELEASE_ROOT/arxiv-source/supplement.tex"; do
    [[ -f "$release_path" ]] || fail "required release file is absent: $release_path"
    git ls-files --error-unmatch "$release_path" >/dev/null 2>&1 ||
        fail "required release file is not tracked: $release_path"
done

for metadata_path in README.md CITATION.cff manuscript/main.tex manuscript/online_supplement/main.tex "$RELEASE_METADATA"; do
    rg -qF "$RELEASE_VERSION" "$metadata_path" ||
        fail "release identifier is missing from $metadata_path"
done
for metadata_path in CITATION.cff "$RELEASE_METADATA"; do
    rg -qF "$RELEASE_DATE" "$metadata_path" ||
        fail "release date is missing from $metadata_path"
done
for metadata_path in manuscript/main.tex manuscript/online_supplement/main.tex; do
    rg -qF "$RELEASE_DISPLAY_DATE" "$metadata_path" ||
        fail "display release date is missing from $metadata_path"
done
for metadata_path in README.md CITATION.cff manuscript/main.tex \
    manuscript/online_supplement/s7_reproducibility_records.tex "$RELEASE_METADATA"; do
    rg -qF "$REPOSITORY_URL" "$metadata_path" ||
        fail "permanent repository URL is missing from $metadata_path"
done
if rg -qF 'is intended to provide' manuscript/main.tex; then
    fail "main-paper Data and Code Availability language is still future-facing"
fi

MAIN_RECORDED_HASH="$(awk -F': ' '/^- Main PDF SHA-256:/ {print $2}' "$RELEASE_METADATA")"
SUPPLEMENT_RECORDED_HASH="$(awk -F': ' '/^- Supplement PDF SHA-256:/ {print $2}' "$RELEASE_METADATA")"
ARXIV_RECORDED_HASH="$(awk -F': ' '/^- arXiv source archive SHA-256:/ {print $2}' "$RELEASE_METADATA")"
MAIN_CURRENT_HASH="$(shasum -a 256 "$MAIN_RELEASE_PDF" | awk '{print $1}')"
SUPPLEMENT_CURRENT_HASH="$(shasum -a 256 "$SUPPLEMENT_RELEASE_PDF" | awk '{print $1}')"
ARXIV_CURRENT_HASH="$(shasum -a 256 "$ARXIV_SOURCE_ARCHIVE" | awk '{print $1}')"
[[ "$MAIN_RECORDED_HASH" == "$MAIN_CURRENT_HASH" ]] ||
    fail "main release PDF hash does not match $RELEASE_METADATA"
[[ "$SUPPLEMENT_RECORDED_HASH" == "$SUPPLEMENT_CURRENT_HASH" ]] ||
    fail "supplement release PDF hash does not match $RELEASE_METADATA"
[[ "$ARXIV_RECORDED_HASH" == "$ARXIV_CURRENT_HASH" ]] ||
    fail "arXiv source archive hash does not match $RELEASE_METADATA"

RELEASE_EXCLUDED_PATHS=(
    scripts/full_check.sh
)

for excluded_path in "${RELEASE_EXCLUDED_PATHS[@]}"; do
    [[ "$(git check-attr export-ignore -- "$excluded_path")" == "$excluded_path: export-ignore: set" ]] ||
        fail "release-excluded path lacks export-ignore: $excluded_path"
    if ! git ls-files --error-unmatch "$excluded_path" >/dev/null 2>&1 &&
        [[ -e "$excluded_path" ]]; then
        fail "release-excluded internal record is present but untracked: $excluded_path"
    fi
done
[[ "$(git check-attr export-subst -- "$RELEASE_METADATA")" == "$RELEASE_METADATA: export-subst: set" ]] ||
    fail "release metadata lacks export-subst"

is_release_excluded() {
    local candidate="$1"
    local excluded_path
    for excluded_path in "${RELEASE_EXCLUDED_PATHS[@]}"; do
        [[ "$candidate" == "$excluded_path" ]] && return 0
    done
    return 1
}

PUBLIC_COUNT=0
GENERATED_PUBLIC_COUNT=0
RELEASE_EXCLUDED_COUNT=0
while IFS= read -r path; do
    if is_release_excluded "$path"; then
        RELEASE_EXCLUDED_COUNT=$((RELEASE_EXCLUDED_COUNT + 1))
        continue
    fi
    case "$path" in
        experiments/results/*|manuscript/figures/*|manuscript/tables/*|shared/exact_fixtures/*.json|formal/StrategyInnovation/Fixtures/Generated.lean|release/*/*.pdf|release/*/*.tar.gz|release/*/arxiv-source/*)
            GENERATED_PUBLIC_COUNT=$((GENERATED_PUBLIC_COUNT + 1))
            ;;
        *)
            PUBLIC_COUNT=$((PUBLIC_COUNT + 1))
            ;;
    esac
done <<< "$TRACKED_FILES"

if [[ "$RELEASE_EXCLUDED_COUNT" -ne 0 &&
    "$RELEASE_EXCLUDED_COUNT" -ne "${#RELEASE_EXCLUDED_PATHS[@]}" ]]; then
    fail "release-excluded classification is partial: found $RELEASE_EXCLUDED_COUNT of ${#RELEASE_EXCLUDED_PATHS[@]} paths"
fi

printf 'Public repository audit passed: PUBLIC CORE=%s, PUBLIC GENERATED=%s, RELEASE EXCLUDED=%s, LICENSED tracked=0, PRIVATE tracked=0.\n' \
    "$PUBLIC_COUNT" "$GENERATED_PUBLIC_COUNT" "$RELEASE_EXCLUDED_COUNT"
printf 'Ignored local licensed files detected=%s; large CSVs schema-checked=%s; large distributable text artifacts checked=%s.\n' \
    "$LOCAL_LICENSED_COUNT" "$LARGE_CSV_COUNT" "$LARGE_TEXT_COUNT"
