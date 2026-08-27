#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
JOURNAL_ROOT="$ROOT/journal/aor"
BASELINE_COMMIT="1f414769459e314e594a8a2b9b679996b04597ba"
MODE="${1:-development}"
JULIA_EXE="${JULIA_EXE:-$ROOT/.local_runtime/julia-1.12.6/bin/julia}"

case "$MODE" in
    development|--submission-ready) ;;
    *) printf 'usage: %s [--submission-ready]\n' "$0" >&2; exit 2 ;;
esac

fail() {
    printf 'journal-check: %s\n' "$1" >&2
    exit 1
}

cd "$ROOT"

[[ "$(git branch --show-current)" == "journal/aor-v0.2.0" ]] ||
    fail "the journal gate must run on journal/aor-v0.2.0"

git diff --quiet "$BASELINE_COMMIT" -- release/v0.1.1-arxiv ||
    fail "immutable release/v0.1.1-arxiv differs from the journal baseline"

git diff --quiet "$BASELINE_COMMIT" -- \
    RANDOMIZED_DESIGN_V2.md \
    RANDOMIZED_DESIGN_V2_AMENDMENT_1.md \
    RANDOMIZED_DESIGN_V2_AMENDMENT_2.md \
    RANDOMIZED_LIBRARY_OPTIMIZATION_EXTENSION_V1.md \
    RANDOMIZED_LIBRARY_REPORT_V2.md \
    experiments/randomized_library_v2 \
    experiments/randomized_library_v2_optimization \
    experiments/configs/randomized_library_stress_v2.toml \
    experiments/configs/randomized_library_stability_amendment_1.toml \
    experiments/configs/randomized_library_execution_amendment_2.toml \
    experiments/configs/randomized_library_optimization_extension_v1.toml \
    ':(glob)experiments/results/summaries/randomized_library_v2_*' \
    ':(glob)manuscript/figures/randomized_library_v2_*' \
    ':(glob)manuscript/tables/main_randomized_*' ||
    fail "the frozen N=1024 randomized-study surface differs from the journal baseline"

[[ "$(shasum -a 256 "$JOURNAL_ROOT/template/sn-jnl.cls" | awk '{print $1}')" == \
   "36d0c3273a59d48dc6a9c7b080dfa1ec50dc10229d8751568d1f2e490ffa5ecc" ]] ||
    fail "Springer Nature class file hash drift"
[[ "$(shasum -a 256 "$JOURNAL_ROOT/template/bst/sn-mathphys-ay.bst" | awk '{print $1}')" == \
   "6a2306683997db76b5e58190acea4dac360c742044114f6a923a4380fbab9008" ]] ||
    fail "Springer Nature bibliography style hash drift"

ABSTRACT_WORDS="$(
    perl -0777 -ne '
        if (/\\abstract\{(.*?)\}\s*\\keywords/s) {
            my $text = $1;
            $text =~ s/--/ /g;
            $text =~ s/[^[:alnum:]-]+/ /g;
            my @words = grep { length($_) } split(/\s+/, $text);
            print scalar(@words);
        }
    ' "$JOURNAL_ROOT/main.tex"
)"
[[ "$ABSTRACT_WORDS" =~ ^[0-9]+$ ]] ||
    fail "could not count journal abstract words"
(( ABSTRACT_WORDS >= 150 && ABSTRACT_WORDS <= 250 )) ||
    fail "journal abstract has $ABSTRACT_WORDS words; Springer requires 150--250"

KEYWORD_COUNT="$(
    perl -0777 -ne '
        if (/\\keywords\{(.*?)\}\s*\\maketitle/s) {
            my @keywords = split(/,/, $1);
            print scalar(@keywords);
        }
    ' "$JOURNAL_ROOT/main.tex"
)"
[[ "$KEYWORD_COUNT" =~ ^[0-9]+$ ]] ||
    fail "could not count journal keywords"
(( KEYWORD_COUNT >= 4 && KEYWORD_COUNT <= 6 )) ||
    fail "journal has $KEYWORD_COUNT keywords; Springer requires 4--6"

"$JULIA_EXE" --startup-file=no --project="$ROOT/julia/test" -e '
    using StrategyInnovation, Test
    include("julia/scripts/verify_safe_compression_complexity_reductions.jl")
    using .SafeCompressionComplexityReductionFixture
    include("julia/test/test_safe_compression_complexity.jl")
'

"$JULIA_EXE" --startup-file=no --project="$ROOT/julia" \
    "$ROOT/julia/scripts/verify_safe_compression_complexity_reductions.jl" --check

"$JULIA_EXE" --startup-file=no --project="$ROOT/julia/test" -e '
    using StrategyInnovation, Test
    include("julia/scripts/export_tagged_cover_theorem_fixture.jl")
    using .TaggedCoverTheoremFixture
    include("julia/test/test_tagged_cover.jl")
'
"$JULIA_EXE" --startup-file=no --project="$ROOT/julia" \
    "$ROOT/julia/scripts/export_tagged_cover_theorem_fixture.jl" --check

"$JULIA_EXE" --startup-file=no --project="$ROOT/julia" \
    "$JOURNAL_ROOT/scripts/generate_journal_artifacts.jl" --check

"$ROOT/scripts/check_manuscript_sources.sh"
"$JOURNAL_ROOT/build.sh"

for log in \
    "$JOURNAL_ROOT/build/main/aor-journal.log" \
    "$JOURNAL_ROOT/build/supplement/ESM_1.log"; do
    [[ -f "$log" ]] || fail "expected LaTeX log is absent: $log"
    if rg -n 'Citation .* undefined|Reference .* undefined|There were undefined references|undefined citations' "$log"; then
        fail "unresolved citation or reference in $log"
    fi
done

[[ -f "$JOURNAL_ROOT/build/main/aor-journal.bbl" ]] ||
    fail "expected bibliography output is absent"
if rg -n '\?\?\?' "$JOURNAL_ROOT/build/main/aor-journal.bbl"; then
    fail "bibliography contains an unresolved placeholder"
fi

pdfinfo "$JOURNAL_ROOT/build/main/aor-journal.pdf" >/dev/null
pdfinfo "$JOURNAL_ROOT/build/supplement/ESM_1.pdf" >/dev/null
git diff --check

if rg -q 'AUTHOR CONFIRMATION REQUIRED|Author confirmation required' \
    "$JOURNAL_ROOT/author_metadata.tex" "$JOURNAL_ROOT/cover_letter.md"; then
    if [[ "$MODE" == "--submission-ready" ]]; then
        fail "author affiliation, funding, competing interests, or contribution confirmation is unresolved"
    fi
    printf '%s\n' 'journal-check: scientific and source gate passed; author confirmations remain pending.'
else
    printf '%s\n' 'journal-check: submission-ready gate passed.'
fi
