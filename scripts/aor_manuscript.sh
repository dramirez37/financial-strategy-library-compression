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

"$JULIA_CMD" --startup-file=no --project="$ROOT/julia" \
    "$ROOT/julia/scripts/build_aor_manuscript_evidence_inputs.jl" --check

"$ROOT/journal/aor/manuscript/build.sh"
"$ROOT/journal/aor/online_resource/build.sh"
"$ROOT/scripts/aor_source_completeness.sh"

printf '%s\n' \
    'aor-manuscript: Springer article and Online Resource 1 compiled and passed source-completeness checks.'
