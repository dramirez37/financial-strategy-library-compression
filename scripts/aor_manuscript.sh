#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$ROOT/journal/aor/manuscript/build.sh"
"$ROOT/journal/aor/online_resource/build.sh"
"$ROOT/scripts/aor_source_completeness.sh"

printf '%s\n' \
    'aor-manuscript: Springer article and Online Resource 1 compiled and passed source-completeness checks.'
