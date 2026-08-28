#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASE_ROOT="$ROOT/release/v0.2.0-aor-submission"

fail() {
    printf 'aor-public-boundary: %s\n' "$1" >&2
    exit 1
}

"$ROOT/scripts/audit_public_repository.sh"

rg -qi 'synthetic' "$ROOT/experiments/algorithmic_compression_v2/DESIGN_SUMMARY.md" ||
    fail "registered algorithmic benchmark is not explicitly identified as synthetic"
rg -q '^passed = true$' \
    "$ROOT/experiments/algorithmic_compression_v2/results/audit/audit_summary.toml" ||
    fail "committed public benchmark audit is not PASS"

for status_path in \
    "$ROOT/experiments/results/summaries/financial_terminal_audit_status.json" \
    "$ROOT/experiments/results/summaries/financial_annual_walkforward_audit_status.json"; do
    rg -q '"raw_data_redistribution_permitted":false' "$status_path" ||
        fail "licensed-row prohibition is missing from ${status_path#"$ROOT/"}"
    rg -q '"aggregate_outputs_publishable":true' "$status_path" ||
        fail "aggregate publication permission is missing from ${status_path#"$ROOT/"}"
done

if [[ -d "$RELEASE_ROOT" ]]; then
    "$ROOT/scripts/build_aor_release.sh" --check
fi

printf '%s\n' \
    'aor-public-boundary: public benchmark, aggregate-financial, and licensed-row boundaries passed.'
