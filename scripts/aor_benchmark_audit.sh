#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JULIA_EXE="${JULIA_EXE:-$ROOT/.local_runtime/julia-1.12.6/bin/julia}"
STUDY_PATH="experiments/algorithmic_compression_v2"

if [[ "$JULIA_EXE" != */* ]]; then
    JULIA_EXE="$(command -v "$JULIA_EXE" || true)"
fi

fail() {
    printf 'aor-benchmark-audit: %s\n' "$1" >&2
    exit 1
}

[[ -x "$JULIA_EXE" ]] || fail "Julia 1.12.6 executable is absent: $JULIA_EXE"
[[ "$($JULIA_EXE --startup-file=no --version)" == "julia version 1.12.6" ]] ||
    fail "the benchmark audit requires Julia 1.12.6"

cd "$ROOT"

"$JULIA_EXE" --startup-file=no --project="$ROOT/julia" \
    "$ROOT/julia/test/test_historical_benchmark_environment.jl"

before_status="$(git status --porcelain=v1 --untracked-files=all -- "$STUDY_PATH")"
before_diff="$(git diff --binary HEAD -- "$STUDY_PATH" | shasum -a 256 | awk '{print $1}')"

"$JULIA_EXE" --threads=8 --startup-file=no --project="$ROOT/julia" \
    "$ROOT/julia/scripts/check_algorithmic_compression_final_v2.jl"

after_status="$(git status --porcelain=v1 --untracked-files=all -- "$STUDY_PATH")"
after_diff="$(git diff --binary HEAD -- "$STUDY_PATH" | shasum -a 256 | awk '{print $1}')"

[[ "$before_status" == "$after_status" ]] ||
    fail "the read-only audit changed the benchmark worktree status"
[[ "$before_diff" == "$after_diff" ]] ||
    fail "the read-only audit changed committed benchmark content"

printf '%s\n' \
    'aor-benchmark-audit: committed v2 final results and exact certificates passed without rerunning or rewriting outcomes.'
