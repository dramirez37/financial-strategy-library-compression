#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -n "${JULIA_EXE:-}" ]]; then
    JULIA_CMD="$JULIA_EXE"
elif [[ -x "$ROOT/.local_runtime/julia-1.12.6/bin/julia" ]]; then
    JULIA_CMD="$ROOT/.local_runtime/julia-1.12.6/bin/julia"
else
    JULIA_CMD="julia"
fi

fail() {
    printf 'aor-check: %s\n' "$1" >&2
    exit 1
}

cd "$ROOT"

status_before="$(git status --porcelain=v1 --untracked-files=all)"
diff_before="$(git diff --binary HEAD | shasum -a 256 | awk '{print $1}')"
cached_before="$(git diff --cached --binary HEAD | shasum -a 256 | awk '{print $1}')"

"$ROOT/scripts/aor_theory_check.sh"
"$ROOT/scripts/aor_algorithm_tests.sh"
"$ROOT/scripts/aor_benchmark_audit.sh"
"$JULIA_CMD" --startup-file=no --project=julia \
    julia/scripts/create_financial_strategy_library_panel_v1_registries.jl --check
"$JULIA_CMD" --startup-file=no --project=julia \
    julia/scripts/lock_financial_strategy_library_panel_v1.jl --check
"$JULIA_CMD" --startup-file=no --project=julia \
    julia/test/run_financial_strategy_library_panel_v1_registration_tests.jl
"$JULIA_CMD" --threads=8 --startup-file=no --project=julia \
    julia/scripts/lock_financial_strategy_library_panel_v1_execution.jl --check
"$JULIA_CMD" --threads=8 --startup-file=no --project=julia \
    julia/test/run_financial_strategy_library_panel_v1_execution_tests.jl
"$ROOT/scripts/aor_manuscript.sh"
"$ROOT/scripts/aor_public_boundary_audit.sh"
"$ROOT/scripts/build_aor_release.sh" --check-inputs

status_after="$(git status --porcelain=v1 --untracked-files=all)"
diff_after="$(git diff --binary HEAD | shasum -a 256 | awk '{print $1}')"
cached_after="$(git diff --cached --binary HEAD | shasum -a 256 | awk '{print $1}')"

[[ "$status_before" == "$status_after" ]] ||
    fail "a nonmutating journal check changed the worktree status"
[[ "$diff_before" == "$diff_after" ]] ||
    fail "a nonmutating journal check changed tracked worktree content"
[[ "$cached_before" == "$cached_after" ]] ||
    fail "a nonmutating journal check changed the index"

printf '%s\n' \
    'aor-check: all nonmutating journal gates passed; no final benchmark or licensed financial workflow was run.'
