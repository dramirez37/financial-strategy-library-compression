#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FINAL_RELEASE_ROOT="$ROOT/release/v0.1.1-arxiv"
FINAL_BUNDLE_ROOT="$FINAL_RELEASE_ROOT/arxiv-source"
FINAL_ARCHIVE="$FINAL_RELEASE_ROOT/financial-strategy-library-compression-arxiv-source.tar.gz"
MODE="${1:-write}"

case "$MODE" in
    write)
        RELEASE_ROOT="$FINAL_RELEASE_ROOT"
        ;;
    --check)
        STAGING_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/algolib-arxiv-bundle.XXXXXX")"
        trap 'rm -rf "$STAGING_ROOT"' EXIT
        RELEASE_ROOT="$STAGING_ROOT/release/v0.1.1-arxiv"
        ;;
    *)
        printf 'usage: %s [--check]\n' "$0" >&2
        exit 2
        ;;
esac

BUNDLE_ROOT="$RELEASE_ROOT/arxiv-source"
ARCHIVE="$RELEASE_ROOT/financial-strategy-library-compression-arxiv-source.tar.gz"

fail() {
    printf 'arxiv-bundle: %s\n' "$1" >&2
    exit 1
}

if [[ -f "$ROOT/manuscript/build/main.bbl" ]]; then
    BBL_SOURCE="$ROOT/manuscript/build/main.bbl"
elif [[ "$MODE" == "--check" && -f "$FINAL_BUNDLE_ROOT/paper.bbl" ]]; then
    BBL_SOURCE="$FINAL_BUNDLE_ROOT/paper.bbl"
else
    fail 'manuscript/build/main.bbl is absent; run make manuscript first'
fi
[[ -f "$ROOT/arxiv/00README" ]] || fail 'arxiv/00README is absent'

if [[ "$MODE" == "write" ]]; then
    case "$BUNDLE_ROOT" in
        "$ROOT"/release/v0.1.1-arxiv/arxiv-source) ;;
        *) fail "refusing to replace unexpected destination: $BUNDLE_ROOT" ;;
    esac
fi

rm -rf "$BUNDLE_ROOT"
mkdir -p \
    "$BUNDLE_ROOT/sections" \
    "$BUNDLE_ROOT/appendices" \
    "$BUNDLE_ROOT/supplement_sections" \
    "$BUNDLE_ROOT/bibliography" \
    "$BUNDLE_ROOT/figures" \
    "$BUNDLE_ROOT/tables" \
    "$BUNDLE_ROOT/data"

cp "$ROOT/arxiv/00README" "$BUNDLE_ROOT/00README"
cp "$ROOT/manuscript/main.tex" "$BUNDLE_ROOT/paper.tex"
cp "$ROOT/manuscript/online_supplement/main.tex" "$BUNDLE_ROOT/supplement.tex"
cp "$ROOT/manuscript/bibliography/references.bib" "$BUNDLE_ROOT/bibliography/references.bib"
cp "$BBL_SOURCE" "$BUNDLE_ROOT/paper.bbl"

main_sections=(
    01_introduction.tex
    02_literature_boundary.tex
    03_model.tex
    04_dynamic_innovation_equivalence.tex
    05_innovation_safe_compression.tex
    06_operational_generative_value.tex
    07_belief_space_coverage.tex
    08_dynamic_research_control.tex
    09_canonical_finite_model.tex
    10_financial_compression_audit.tex
    11_limitations_conclusion.tex
)
for name in "${main_sections[@]}"; do
    cp "$ROOT/manuscript/sections/$name" "$BUNDLE_ROOT/sections/$name"
done

appendices=(
    a_additional_formal_definitions.tex
    b_long_proofs.tex
    a_structural_counterexamples.tex
    b_optimization_proofs.tex
    c_comparative_statics.tex
    d_numerical_convergence.tex
    e_experiment_protocol.tex
    f_validation_status.tex
)
for name in "${appendices[@]}"; do
    cp "$ROOT/manuscript/appendices/$name" "$BUNDLE_ROOT/appendices/$name"
done

supplement_sections=(
    s1_belief_occupation_coverage.tex
    s2_frontier_closure_interaction.tex
    s3_comparative_statics_counterexamples.tex
    s3_auxiliary_models.tex
    s4_complete_canonical_numerical_records.tex
    s5_complete_registered_randomized_study.tex
    s6_full_financial_audit_secondary_tests.tex
    s7_reproducibility_records.tex
)
for name in "${supplement_sections[@]}"; do
    cp "$ROOT/manuscript/online_supplement/$name" "$BUNDLE_ROOT/supplement_sections/$name"
done

figures=(
    innovation_safe_bridge.tex
    unified_canonical_transition.tex
    unified_economic_geometry.tex
    financial_innovation_safe_compression.tex
    unified_canonical_convergence.tex
    dynamic_research_policy_regions.tex
    financial_coverage_comparison.tex
)
for name in "${figures[@]}"; do
    cp "$ROOT/manuscript/figures/$name" "$BUNDLE_ROOT/figures/$name"
done

tables=(
    main_greedy_global_comparison.tex
    main_canonical_stationary_solution.tex
    main_randomized_optimization_summary.tex
    main_randomized_price_elasticities.tex
    main_financial_resource_compression.tex
    unified_canonical_resource_channel_elasticities.tex
    numerical_mechanism_summary.tex
    financial_design_summary.tex
)
for name in "${tables[@]}"; do
    cp "$ROOT/manuscript/tables/$name" "$BUNDLE_ROOT/tables/$name"
done

data_files=(
    experiments/results/summaries/unified_canonical_convergence.csv
    experiments/results/summaries/unified_canonical_duration_paths.csv
    experiments/results/summaries/unified_canonical_operating_rewards.csv
    experiments/results/summaries/unified_canonical_policies.csv
    experiments/results/summaries/unified_canonical_resource_capacity.csv
    experiments/results/summaries/unified_canonical_resource_penalized_intervals.csv
    experiments/results/summaries/unified_canonical_resource_safe_compression.csv
    experiments/results/summaries/unified_canonical_resource_switching_prices.csv
    experiments/results/summaries/unified_canonical_values.csv
    experiments/results/unified_benchmark_policy_value.csv
)
for path in "${data_files[@]}"; do
    cp "$ROOT/$path" "$BUNDLE_ROOT/data/$(basename "$path")"
done

perl -0pi -e 's/\\input\{(s[1-7]_[^}]+)\}/\\input{supplement_sections\/$1}/g' \
    "$BUNDLE_ROOT/supplement.tex"
for path in "$BUNDLE_ROOT"/supplement_sections/*.tex; do
    perl -0pi -e 's!\.\./tables/!tables/!g; s!\.\./figures/!figures/!g; s!\.\./\.\./experiments/results/summaries/!data/!g; s!\.\./\.\./experiments/results/!data/!g' \
        "$path"
done

if rg -n '\\(input|include|includegraphics|bibliography)\{[^}]*\.\./' "$BUNDLE_ROOT"; then
    fail 'an unresolved repository-relative TeX input escaped into the arXiv bundle'
fi

if [[ "$MODE" == "--check" ]]; then
    [[ -d "$FINAL_BUNDLE_ROOT" ]] || fail "committed bundle is absent: $FINAL_BUNDLE_ROOT"
    [[ -f "$FINAL_ARCHIVE" ]] || fail "committed archive is absent: $FINAL_ARCHIVE"
    diff -ru "$FINAL_BUNDLE_ROOT" "$BUNDLE_ROOT" ||
        fail 'committed arXiv source directory differs from canonical inputs'
    archive_unpack="$STAGING_ROOT/archive-unpack"
    mkdir -p "$archive_unpack"
    tar -xzf "$FINAL_ARCHIVE" -C "$archive_unpack"
    diff -ru "$FINAL_BUNDLE_ROOT" "$archive_unpack/arxiv-source" ||
        fail 'committed arXiv source archive differs from its source directory'
    printf 'arxiv-bundle: committed source directory and archive match canonical inputs\n'
    exit 0
fi

archive_tmp="$RELEASE_ROOT/.arxiv-source.tar"
rm -f "$archive_tmp" "$ARCHIVE"
tar -cf "$archive_tmp" -C "$RELEASE_ROOT" arxiv-source
gzip -n -c "$archive_tmp" > "$ARCHIVE"
rm -f "$archive_tmp"

printf 'arxiv-bundle: wrote %s\n' "$BUNDLE_ROOT"
printf 'arxiv-bundle: wrote %s\n' "$ARCHIVE"
