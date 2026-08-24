#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORMAL_ROOT="$ROOT/formal"
MANUSCRIPT_ROOT="$ROOT/manuscript"
EXPECTED_JULIA_VERSION="1.12.6"
EXPECTED_LEAN_VERSION="4.32.0"
EXPECTED_LEAN_COMMIT="8c9756b28d64dab099da31a4c09229a9e6a2ef35"
EXPECTED_LAKE_VERSION="5.0.0-src+8c9756b"
EXPECTED_TOOLCHAIN="leanprover/lean4:v4.32.0"
EXPECTED_MATHLIB_COMMIT="81a5d257c8e410db227a6665ed08f64fea08e997"
LICENSED_REPLAYS=0
LICENSED_SKIPS=0

stage() {
    printf '\n[%s/12] %s\n' "$1" "$2"
}

fail() {
    printf 'verify: %s\n' "$1" >&2
    exit 1
}

require_file() {
    [[ -f "$1" ]] || fail "required file is absent: ${1#"$ROOT/"}"
}

require_tool() {
    command -v "$1" >/dev/null 2>&1 || fail "required command is unavailable: $1"
}

run_julia() {
    "$JULIA_EXE" "$@"
}

check_licensed_replay() {
    local label="$1"
    local data_path="$2"
    local provenance_path="$3"
    local runner="$4"
    local missing=()

    [[ -f "$data_path" ]] || missing+=("${data_path#"$ROOT/"}")
    [[ -f "$provenance_path" ]] || missing+=("${provenance_path#"$ROOT/"}")
    if (( ${#missing[@]} == 0 )); then
        printf 'Licensed raw-data replay available: %s\n' "$label"
        run_julia --project="$ROOT/julia" "$runner" --check
        LICENSED_REPLAYS=$((LICENSED_REPLAYS + 1))
    else
        printf 'Licensed raw-data replay skipped: %s; missing %s.\n' \
            "$label" "$(IFS=', '; printf '%s' "${missing[*]}")"
        LICENSED_SKIPS=$((LICENSED_SKIPS + 1))
    fi
}

cd "$ROOT"
INITIAL_GIT_STATUS="$(git status --porcelain=v1 --untracked-files=all)"

stage 1 "environment and version checks"
case "$ROOT/" in
    /tmp/*|/private/tmp/*|/var/tmp/*)
        fail "project execution from an operating-system temporary directory is prohibited"
        ;;
esac

for tool in awk bibtex comm file git grep lake latexmk make pdflatex rg sed sort tee tr uniq; do
    require_tool "$tool"
done
for path in \
    "$FORMAL_ROOT/lean-toolchain" \
    "$FORMAL_ROOT/lake-manifest.json" \
    "$ROOT/julia/.julia-version" \
    "$ROOT/julia/Project.toml" \
    "$ROOT/julia/Manifest.toml" \
    "$ROOT/julia/test/Project.toml" \
    "$ROOT/julia/test/Manifest.toml" \
    "$MANUSCRIPT_ROOT/bibliography/references.bib"; do
    require_file "$path"
done

"$ROOT/scripts/audit_public_repository.sh"

if [[ -n "${JULIA_EXE:-}" ]]; then
    if [[ "$JULIA_EXE" == */* ]]; then
        JULIA_EXE="$(cd "$(dirname "$JULIA_EXE")" && pwd)/$(basename "$JULIA_EXE")"
    else
        JULIA_EXE="$(command -v "$JULIA_EXE" || true)"
    fi
elif [[ -x "$ROOT/.local_runtime/julia-$EXPECTED_JULIA_VERSION/bin/julia" ]]; then
    JULIA_EXE="$ROOT/.local_runtime/julia-$EXPECTED_JULIA_VERSION/bin/julia"
else
    JULIA_EXE="$(command -v julia || true)"
fi
[[ -n "$JULIA_EXE" && -x "$JULIA_EXE" ]] ||
    fail "Julia $EXPECTED_JULIA_VERSION is required; set JULIA_EXE or install the repository-local runtime"

JULIA_VERSION="$($JULIA_EXE -e 'print(VERSION)')"
[[ "$JULIA_VERSION" == "$EXPECTED_JULIA_VERSION" ]] ||
    fail "Julia $EXPECTED_JULIA_VERSION is required; found $($JULIA_EXE --version)"
[[ "$(tr -d '\r\n' < "$ROOT/julia/.julia-version")" == "$EXPECTED_JULIA_VERSION" ]] ||
    fail "julia/.julia-version does not match $EXPECTED_JULIA_VERSION"
[[ "$(tr -d '\r\n' < "$FORMAL_ROOT/lean-toolchain")" == "$EXPECTED_TOOLCHAIN" ]] ||
    fail "formal/lean-toolchain does not match $EXPECTED_TOOLCHAIN"

JULIA_READ_DEPOT="$($JULIA_EXE --startup-file=no -e 'print(join(DEPOT_PATH, ":"))')"
JULIA_WRITE_DEPOT="$ROOT/julia/.julia"
mkdir -p "$JULIA_WRITE_DEPOT"
export JULIA_DEPOT_PATH="$JULIA_WRITE_DEPOT:$JULIA_READ_DEPOT"

LAKE_VERSION="$(cd "$FORMAL_ROOT" && lake --version)"
LEAN_VERSION="$(cd "$FORMAL_ROOT" && lake env lean --version)"
[[ "$LAKE_VERSION" == *"$EXPECTED_LAKE_VERSION"* ]] ||
    fail "Lake $EXPECTED_LAKE_VERSION is required; found $LAKE_VERSION"
[[ "$LEAN_VERSION" == *"version $EXPECTED_LEAN_VERSION"* ]] ||
    fail "Lean $EXPECTED_LEAN_VERSION is required; found $LEAN_VERSION"
[[ "$LEAN_VERSION" == *"commit $EXPECTED_LEAN_COMMIT"* ]] ||
    fail "Lean commit differs from $EXPECTED_LEAN_COMMIT"
rg -q "\"rev\": \"$EXPECTED_MATHLIB_COMMIT\"" "$FORMAL_ROOT/lake-manifest.json" ||
    fail "formal/lake-manifest.json does not pin mathlib at $EXPECTED_MATHLIB_COMMIT"

printf '%s\n' "$LEAN_VERSION"
printf '%s\n' "$LAKE_VERSION"
"$JULIA_EXE" --version
latexmk --version | sed -n '1,2p'
pdflatex --version | sed -n '1p'
bibtex --version | sed -n '1p'

stage 2 "Lean clean build"
"$ROOT/scripts/formal_check.sh" --build

stage 3 "Lean source and axiom audit"
"$ROOT/scripts/formal_check.sh" --audit

stage 4 "Julia instantiate and package test"
run_julia --project="$ROOT/julia" -e 'using Pkg; Pkg.instantiate(); Pkg.test()'

stage 5 "exact theorem fixtures"
run_julia --project="$ROOT/julia/test" -e '
    using StrategyInnovation, Test
    include("julia/scripts/search_resource_optimization_counterexamples.jl")
    using .ResourceOptimizationCounterexampleSearch
    include("julia/test/test_resource_optimization.jl")
'
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/search_resource_optimization_counterexamples.jl" --check
run_julia --project="$ROOT/julia/test" -e '
    using StrategyInnovation, Test
    include("julia/scripts/verify_safe_compression_complexity_reductions.jl")
    using .SafeCompressionComplexityReductionFixture
    include("julia/test/test_safe_compression_complexity.jl")
'
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/verify_safe_compression_complexity_reductions.jl" --check
run_julia --project="$ROOT/julia" "$ROOT/julia/scripts/export_exact_fixtures.jl" --check
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/search_revision_counterexamples.jl" --check

stage 6 "canonical model replication"
run_julia --project="$ROOT/julia" "$ROOT/julia/scripts/search_unified_benchmark.jl" --check
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/solve_unified_canonical_benchmark.jl" --check
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/run_unified_comparative_statics.jl" --check
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/run_unified_resource_benchmark.jl" --check
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/run_unified_elasticity_switching_experiment.jl" --check

stage 7 "registered N=1024 randomized checks"
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/lock_randomized_library_design_v2.jl" --check
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/lock_randomized_library_stability_amendment.jl" --check
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/lock_randomized_library_execution_amendment.jl" --check
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/run_randomized_library_stress_v2.jl" --check
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/audit_randomized_library_v2_results.jl"
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/lock_randomized_library_optimization_extension.jl" --check
run_julia --project="$ROOT/julia/test" -e '
    using StrategyInnovation, Test
    include("julia/scripts/randomized_library_v2_core.jl")
    include("julia/scripts/lock_randomized_library_optimization_extension.jl")
    include("julia/scripts/run_randomized_library_optimization_extension.jl")
    include("julia/test/test_randomized_library_optimization_extension.jl")
'
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/run_randomized_library_optimization_extension.jl" --check

stage 8 "financial aggregate-output and optional licensed-data checks"
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/freeze_financial_annual_walkforward_audit.jl" --check
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/lock_financial_resource_optimization.jl" --check

check_licensed_replay \
    "terminal audit" \
    "$ROOT/experiments/financial_terminal_audit/data/etf_daily.csv" \
    "$ROOT/experiments/financial_terminal_audit/data/provenance.toml" \
    "$ROOT/julia/scripts/run_financial_terminal_audit.jl"
check_licensed_replay \
    "annual walk-forward audit" \
    "$ROOT/experiments/financial_annual_walkforward_audit/data/etf_daily.csv" \
    "$ROOT/experiments/financial_annual_walkforward_audit/data/provenance.toml" \
    "$ROOT/julia/scripts/run_financial_annual_walkforward_audit.jl"

for status_path in \
    "$ROOT/experiments/results/summaries/financial_terminal_audit_status.json" \
    "$ROOT/experiments/results/summaries/financial_annual_walkforward_audit_status.json"; do
    require_file "$status_path"
    rg -q '"aggregate_outputs_publishable":true' "$status_path" ||
        fail "financial status does not mark aggregates publishable: ${status_path#"$ROOT/"}"
    rg -q '"raw_data_redistribution_permitted":false' "$status_path" ||
        fail "financial status does not preserve the raw-data license boundary: ${status_path#"$ROOT/"}"
    rg -q '"status":"empirical_complete_aggregate_publishable"' "$status_path" ||
        fail "financial aggregate status is not complete: ${status_path#"$ROOT/"}"
done

run_julia --project="$ROOT/julia" -e '
    using StrategyInnovation, Test
    include("julia/test/test_financial_resource_optimization.jl")
    include("julia/test/test_financial_resource_identity_milp_regression.jl")
'
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/verify_financial_resource_optimization_outputs.jl"
printf 'Publishable financial aggregate artifacts and exact post-solve certificates passed independently of licensed rows.\n'

stage 9 "figure and table regeneration in check mode"
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/generate_strategy_value_figure.jl" --check
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/generate_dynamic_policy_figure.jl" --check
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/generate_manuscript_numerical_artifacts.jl" --check
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/generate_figure_audit_artifacts.jl" --check
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/generate_main_text_tables.jl" --check

stage 10 "manuscript compilation"
"$MANUSCRIPT_ROOT/build.sh"

stage 11 "remaining registered artifact-drift validation"
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/run_randomized_library_stress.jl" --check
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/run_approximate_compression.jl" --check
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/run_theorem_mechanism_experiments.jl" --check
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/run_system_interaction_surface.jl" --check
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/search_primitive_substitution.jl" --check
run_julia --project="$ROOT/julia" \
    "$ROOT/julia/scripts/search_joint_descendant_bound.jl" --check
git diff --check

FINAL_GIT_STATUS="$(git status --porcelain=v1 --untracked-files=all)"
[[ "$FINAL_GIT_STATUS" == "$INITIAL_GIT_STATUS" ]] || {
    printf 'Tracked or untracked worktree state changed during verification.\n' >&2
    printf 'Before:\n%s\nAfter:\n%s\n' "$INITIAL_GIT_STATUS" "$FINAL_GIT_STATUS" >&2
    exit 1
}
printf 'All registered check-mode producers completed without changing the worktree state.\n'

stage 12 "bibliography and reference checks"
require_file "$MANUSCRIPT_ROOT/build/main.log"
require_file "$MANUSCRIPT_ROOT/build/main.bbl"
require_file "$MANUSCRIPT_ROOT/build/main.blg"

if rg -n \
    'LaTeX Warning: (Citation|Reference).*(undefined|multiply defined)|There were undefined references|Citation .* undefined|Reference .* undefined|multiply defined|destination with the same identifier|No file .*\.bbl|LaTeX Error: File .* not found' \
    "$MANUSCRIPT_ROOT/build/main.log"; then
    fail "compiled manuscript contains a broken citation or reference diagnostic"
fi
if rg -ni 'Warning--|error message|I found no \\citation|Repeated entry' \
    "$MANUSCRIPT_ROOT/build/main.blg"; then
    fail "BibTeX reported a bibliography warning or error"
fi

"$ROOT/scripts/check_manuscript_sources.sh"
printf '\nVerification passed. Licensed raw-data replays: %s completed, %s skipped; publishable aggregate checks passed in all cases.\n' \
    "$LICENSED_REPLAYS" "$LICENSED_SKIPS"
