#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JULIA_EXE="${JULIA_EXE:-$ROOT/.local_runtime/julia-1.12.6/bin/julia}"

if [[ "$JULIA_EXE" != */* ]]; then
    JULIA_EXE="$(command -v "$JULIA_EXE" || true)"
fi

fail() {
    printf 'aor-algorithm-tests: %s\n' "$1" >&2
    exit 1
}

[[ -x "$JULIA_EXE" ]] || fail "Julia 1.12.6 executable is absent: $JULIA_EXE"
[[ "$($JULIA_EXE --startup-file=no --version)" == "julia version 1.12.6" ]] ||
    fail "the algorithm gate requires Julia 1.12.6"

cd "$ROOT"
"$JULIA_EXE" --startup-file=no --project="$ROOT/julia/test" \
    "$ROOT/julia/test/run_aor_algorithm_tests.jl"

printf '%s\n' \
    'aor-algorithm-tests: enumeration, DP, greedy, deletion, preprocessing, MIP, and exactness-audit tests passed.'
