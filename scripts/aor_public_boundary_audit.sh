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

point_in_time_predecision="$ROOT/experiments/financial_strategy_library_panel_v3/predecision_computation/PREDECISION_COMPUTATION_MANIFEST.toml"
point_in_time_proposal="$ROOT/experiments/financial_strategy_library_panel_v3/proposal_policy/PROPOSAL_POLICY_MANIFEST.toml"
point_in_time_evaluation="$ROOT/experiments/financial_strategy_library_panel_v3/evaluation_results/EVALUATION_RESULT_MANIFEST.toml"
for public_manifest in \
    "$point_in_time_predecision" \
    "$point_in_time_proposal" \
    "$point_in_time_evaluation"; do
    rg -q '^return_values_included = false$' "$public_manifest" ||
        fail "point-in-time public manifest permits return redistribution: ${public_manifest#"$ROOT/"}"
done
rg -q '^licensed_security_identifiers_included = false$' "$point_in_time_predecision" ||
    fail "point-in-time predecision manifest contains licensed identifiers"
rg -q '^selected_strategy_identities_included = false$' "$point_in_time_proposal" ||
    fail "point-in-time proposal manifest contains selected identities"
rg -q '^evaluation_values_used = 0$' "$point_in_time_proposal" ||
    fail "evaluation values entered the point-in-time policy interface"
rg -q '^licensed_identifiers_included = false$' "$point_in_time_evaluation" ||
    fail "point-in-time evaluation manifest contains licensed identifiers"

mechanism_result="$ROOT/experiments/financial_strategy_library_panel_v4/results/RESULT_MANIFEST.toml"
mechanism_calibration="$ROOT/experiments/financial_strategy_library_panel_v4/calibration/CALIBRATION.toml"
rg -q '^market_alpha_claim_permitted = false$' "$mechanism_result" ||
    fail "calibrated mechanism result does not prohibit market-alpha claims"
rg -q '^return_values_included = false$' "$mechanism_calibration" ||
    fail "calibrated mechanism public aggregate contains returns"
rg -q '^security_identifiers_included = false$' "$mechanism_calibration" ||
    fail "calibrated mechanism public aggregate contains identifiers"

if [[ -d "$RELEASE_ROOT" ]]; then
    "$ROOT/scripts/build_aor_release.sh" --check
fi

printf '%s\n' \
    'aor-public-boundary: public benchmark, aggregate-financial, and licensed-row boundaries passed.'
