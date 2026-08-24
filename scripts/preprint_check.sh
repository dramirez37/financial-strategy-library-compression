#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPECTED_JULIA_VERSION="1.12.6"
EXPECTED_LEAN_VERSION="4.32.0"
EXPECTED_LEAN_COMMIT="8c9756b28d64dab099da31a4c09229a9e6a2ef35"
EXPECTED_LAKE_VERSION="5.0.0-src+8c9756b"
EXPECTED_TOOLCHAIN="leanprover/lean4:v4.32.0"
EXPECTED_MATHLIB_COMMIT="81a5d257c8e410db227a6665ed08f64fea08e997"

fail() {
    printf 'preprint-check: %s\n' "$1" >&2
    exit 1
}

require_file() {
    [[ -f "$ROOT/$1" ]] || fail "required public file is absent: $1"
}

for tool in awk bibtex git lake latexmk make pdflatex rg sed sort tr; do
    command -v "$tool" >/dev/null 2>&1 || fail "required command is unavailable: $tool"
done

case "$ROOT/" in
    /tmp/*|/private/tmp/*|/var/tmp/*)
        fail "project execution from an operating-system temporary directory is prohibited"
        ;;
esac

for path in \
    README.md \
    REPRODUCIBILITY.md \
    DATA_ACCESS.md \
    ARTIFACT_MANIFEST.md \
    EMPIRICAL_INFORMATION_SET_AUDIT.md \
    THEOREM_LEDGER.md \
    CITATION.cff \
    LICENSE \
    .gitattributes \
    Makefile \
    scripts/audit_public_repository.sh \
    scripts/check_manuscript_sources.sh \
    scripts/formal_check.sh \
    scripts/preprint_check.sh \
    scripts/run_financial_licensed.sh \
    scripts/verify.sh \
    formal/lean-toolchain \
    formal/lake-manifest.json \
    julia/.julia-version \
    julia/Project.toml \
    julia/Manifest.toml \
    experiments/configs/unified_canonical_benchmark.toml \
    experiments/configs/randomized_library_stress_v2.toml \
    experiments/configs/randomized_library_stability_amendment_1.toml \
    experiments/configs/randomized_library_execution_amendment_2.toml \
    experiments/randomized_library_v2/TRIAL_REGISTRY.csv \
    experiments/randomized_library_v2/DESIGN_LOCK.json \
    experiments/randomized_library_v2/DESIGN_LOCK_AMENDMENT_1.json \
    experiments/randomized_library_v2/DESIGN_LOCK_AMENDMENT_2.json \
    experiments/financial_annual_walkforward_audit/DESIGN_LOCK.json \
    experiments/financial_resource_optimization/DESIGN_LOCK.json \
    release/v0.1.0-preprint/RELEASE_METADATA.md \
    release/v0.1.0-preprint/financial-strategy-library-compression-preprint.pdf \
    release/v0.1.0-preprint/financial-strategy-library-compression-online-supplement.pdf \
    manuscript/main.tex \
    manuscript/online_supplement/main.tex; do
    require_file "$path"
done

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
    fail "Julia $EXPECTED_JULIA_VERSION is required; set JULIA_EXE or install Julia"

JULIA_VERSION="$($JULIA_EXE --startup-file=no -e 'print(VERSION)')"
[[ "$JULIA_VERSION" == "$EXPECTED_JULIA_VERSION" ]] ||
    fail "Julia $EXPECTED_JULIA_VERSION is required; found $($JULIA_EXE --version)"
[[ "$(tr -d '\r\n' < "$ROOT/julia/.julia-version")" == "$EXPECTED_JULIA_VERSION" ]] ||
    fail "julia/.julia-version does not match $EXPECTED_JULIA_VERSION"
[[ "$(tr -d '\r\n' < "$ROOT/formal/lean-toolchain")" == "$EXPECTED_TOOLCHAIN" ]] ||
    fail "formal/lean-toolchain does not match $EXPECTED_TOOLCHAIN"

LAKE_VERSION="$(cd "$ROOT/formal" && lake --version)"
LEAN_VERSION="$(cd "$ROOT/formal" && lake env lean --version)"
[[ "$LAKE_VERSION" == *"$EXPECTED_LAKE_VERSION"* ]] ||
    fail "Lake $EXPECTED_LAKE_VERSION is required; found $LAKE_VERSION"
[[ "$LEAN_VERSION" == *"version $EXPECTED_LEAN_VERSION"* ]] ||
    fail "Lean $EXPECTED_LEAN_VERSION is required; found $LEAN_VERSION"
[[ "$LEAN_VERSION" == *"commit $EXPECTED_LEAN_COMMIT"* ]] ||
    fail "Lean commit differs from $EXPECTED_LEAN_COMMIT"
rg -q "\"rev\": \"$EXPECTED_MATHLIB_COMMIT\"" "$ROOT/formal/lake-manifest.json" ||
    fail "formal/lake-manifest.json does not pin the registered mathlib commit"

printf 'Environment expectations passed: Julia %s, Lean %s, Lake %s.\n' \
    "$JULIA_VERSION" "$EXPECTED_LEAN_VERSION" "$EXPECTED_LAKE_VERSION"

cd "$ROOT"
INITIAL_GIT_STATUS="$(git status --porcelain=v1 --untracked-files=all)"

"$ROOT/scripts/audit_public_repository.sh"
"$ROOT/scripts/check_manuscript_sources.sh"

"$JULIA_EXE" --project=julia julia/scripts/solve_unified_canonical_benchmark.jl --check
"$JULIA_EXE" --project=julia julia/scripts/export_exact_fixtures.jl --check
"$JULIA_EXE" --project=julia julia/scripts/lock_randomized_library_design_v2.jl --check
"$JULIA_EXE" --project=julia julia/scripts/lock_randomized_library_stability_amendment.jl --check
"$JULIA_EXE" --project=julia julia/scripts/lock_randomized_library_execution_amendment.jl --check
"$JULIA_EXE" --project=julia julia/scripts/audit_randomized_library_v2_results.jl
"$JULIA_EXE" --project=julia julia/scripts/freeze_financial_annual_walkforward_audit.jl --check
"$JULIA_EXE" --project=julia julia/scripts/lock_financial_resource_optimization.jl --check
"$JULIA_EXE" --project=julia julia/scripts/verify_financial_resource_optimization_outputs.jl
"$JULIA_EXE" --project=julia julia/scripts/generate_strategy_value_figure.jl --check
"$JULIA_EXE" --project=julia julia/scripts/generate_dynamic_policy_figure.jl --check
"$JULIA_EXE" --project=julia julia/scripts/generate_manuscript_numerical_artifacts.jl --check
"$JULIA_EXE" --project=julia julia/scripts/generate_figure_audit_artifacts.jl --check
"$JULIA_EXE" --project=julia julia/scripts/generate_main_text_tables.jl --check

git diff --check
FINAL_GIT_STATUS="$(git status --porcelain=v1 --untracked-files=all)"
[[ "$FINAL_GIT_STATUS" == "$INITIAL_GIT_STATUS" ]] ||
    fail "a check-mode producer changed the worktree"

printf 'Preprint check passed without an N=1024 replay or licensed-data analysis.\n'
