#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPECTED_JULIA_VERSION="1.12.6"
LICENSED_MESSAGE='Licensed CRSP/WRDS inputs are not distributed with this repository. See DATA_ACCESS.md.'

fail() {
    printf 'financial-licensed: %s\n' "$1" >&2
    exit 1
}

[[ -n "${ALGOLIB_CRSP_ROOT:-}" ]] ||
    fail "$LICENSED_MESSAGE Set ALGOLIB_CRSP_ROOT to your independently licensed source root."

if [[ "$ALGOLIB_CRSP_ROOT" == /* ]]; then
    SOURCE_ROOT="$ALGOLIB_CRSP_ROOT"
else
    SOURCE_ROOT="$ROOT/$ALGOLIB_CRSP_ROOT"
fi
[[ -d "$SOURCE_ROOT" ]] ||
    fail "$LICENSED_MESSAGE Licensed source root is absent: $SOURCE_ROOT"

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
[[ "$($JULIA_EXE --startup-file=no -e 'print(VERSION)')" == "$EXPECTED_JULIA_VERSION" ]] ||
    fail "Julia $EXPECTED_JULIA_VERSION is required; found $($JULIA_EXE --version)"

cd "$ROOT"

# These authoritative preparation entry points validate the licensed source
# paths, schemas, identities, and registered selection before writing ignored
# local panels. No wrapper-level scientific logic is duplicated here.
"$JULIA_EXE" --project=julia julia/scripts/audit_financial_annual_universe.jl
"$JULIA_EXE" --project=julia julia/scripts/freeze_financial_annual_walkforward_audit.jl --check
"$JULIA_EXE" --project=julia julia/scripts/prepare_financial_terminal_audit_data.jl
"$JULIA_EXE" --project=julia julia/scripts/prepare_financial_annual_walkforward_audit_data.jl

"$JULIA_EXE" --project=julia julia/scripts/run_financial_terminal_audit.jl
"$JULIA_EXE" --project=julia julia/scripts/run_financial_terminal_audit.jl --check
"$JULIA_EXE" --project=julia julia/scripts/run_financial_annual_walkforward_audit.jl
"$JULIA_EXE" --project=julia julia/scripts/run_financial_annual_walkforward_audit.jl --check

"$JULIA_EXE" --project=julia julia/scripts/lock_financial_resource_optimization.jl --check
"$JULIA_EXE" --project=julia julia/scripts/run_financial_resource_optimization.jl
"$JULIA_EXE" --project=julia julia/scripts/run_financial_resource_optimization.jl --check
"$JULIA_EXE" --project=julia julia/scripts/verify_financial_resource_optimization_outputs.jl

printf 'Licensed financial workflow passed. Raw and row-level files remain local and ignored.\n'
