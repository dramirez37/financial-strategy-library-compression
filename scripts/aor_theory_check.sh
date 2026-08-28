#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JULIA_EXE="${JULIA_EXE:-$ROOT/.local_runtime/julia-1.12.6/bin/julia}"

if [[ "$JULIA_EXE" != */* ]]; then
    JULIA_EXE="$(command -v "$JULIA_EXE" || true)"
fi

fail() {
    printf 'aor-theory-check: %s\n' "$1" >&2
    exit 1
}

[[ -x "$JULIA_EXE" ]] || fail "Julia 1.12.6 executable is absent: $JULIA_EXE"
[[ "$($JULIA_EXE --startup-file=no --version)" == "julia version 1.12.6" ]] ||
    fail "the theorem gate requires Julia 1.12.6"

cd "$ROOT"

"$JULIA_EXE" --startup-file=no --project="$ROOT/julia/test" -e '
    using StrategyInnovation, Test
    include("julia/scripts/verify_safe_compression_complexity_reductions.jl")
    using .SafeCompressionComplexityReductionFixture
    include("julia/test/test_safe_compression_complexity.jl")
'
"$JULIA_EXE" --startup-file=no --project="$ROOT/julia/test" -e '
    using StrategyInnovation, Test
    include("julia/scripts/export_safe_deletion_gap_family.jl")
    using .SafeDeletionGapFamilyFixture
    include("julia/test/test_safe_deletion_gap_family.jl")
'
"$JULIA_EXE" --startup-file=no --project="$ROOT/julia/test" -e '
    using StrategyInnovation, Test
    include("julia/scripts/export_tagged_cover_theorem_fixture.jl")
    using .TaggedCoverTheoremFixture
    include("julia/test/test_tagged_cover.jl")
'
"$JULIA_EXE" --startup-file=no --project="$ROOT/julia/test" -e '
    using StrategyInnovation, Test
    include("julia/scripts/export_journal_evidence_fixtures.jl")
    using .JournalEvidenceFixtureExporter
    include("julia/test/test_journal_evidence_fixtures.jl")
'

"$JULIA_EXE" --startup-file=no --project="$ROOT/julia" \
    "$ROOT/julia/scripts/verify_safe_compression_complexity_reductions.jl" --check
"$JULIA_EXE" --startup-file=no --project="$ROOT/julia" \
    "$ROOT/julia/scripts/export_safe_deletion_gap_family.jl" --check
"$JULIA_EXE" --startup-file=no --project="$ROOT/julia" \
    "$ROOT/julia/scripts/export_tagged_cover_theorem_fixture.jl" --check
"$JULIA_EXE" --startup-file=no --project="$ROOT/julia" \
    "$ROOT/julia/scripts/export_journal_evidence_fixtures.jl" --check

(
    cd "$ROOT/formal"
    lake build
)
"$ROOT/scripts/formal_check.sh" --audit

printf '%s\n' \
    'aor-theory-check: exact theorem fixtures, Lean build, manuscript lint, and axiom audit passed.'
