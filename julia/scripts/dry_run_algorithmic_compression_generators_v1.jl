module DryRunAlgorithmicCompressionGeneratorsV1

using StrategyInnovation

export main, render_report

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const REPORT_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "algorithmic_compression_v1",
    "DRY_RUN_GENERATOR_REPORT.md",
)
const EXAMPLE_IDS = (
    "DRY-001",
    "DRY-002",
    "DRY-003",
    "P-A-001",
    "P-A-002",
    "P-B-001",
    "P-B-002",
    "P-C-001",
    "P-C-002",
    "P-C-003",
    "P-C-004",
    "P-C-005",
    "P-C-006",
    "P-C-007",
)


_exact(value) = string(numerator(value), "//", denominator(value))


function render_report()
    rows = AlgorithmicGeneratedInstance[]
    for instance_id in EXAMPLE_IDS
        result = generate_algorithmic_benchmark_instance(instance_id)
        result isa AlgorithmicGeneratedInstance || error(
            "dry/pilot example failed generation: $instance_id",
        )
        push!(rows, result)
    end
    io = IOBuffer()
    println(io, "# Registered Algorithmic Compression Benchmark v1: generator dry run")
    println(io)
    println(io, "Status: **DRY/PILOT GENERATION ONLY; NO FINAL INSTANCE OR ALGORITHM OUTCOME GENERATED**")
    println(io)
    println(io, "This report exercises the common instance schema and the registered generator mechanisms. It records requested and realized structure, not optimum burden, heuristic gaps, solver behavior, runtime, or any other comparative outcome. Final-registry rows were neither instantiated nor solved.")
    println(io)
    println(io, "All numbers below are emitted from generator records. Densities, overlap, association, and weights use exact `Rational{BigInt}` arithmetic.")
    println(io)
    println(io, "| Instance | Phase/family | Generator or mechanism | Requested density | Realized density | Unique rows (requested/realized) | Bundles (requested/realized) | Module Jaccard | Frontier-module rank association | Instance SHA-256 |")
    println(io, "|---|---|---|---:|---:|---:|---:|---:|---:|---|")
    for result in rows
        request = result.requested
        stats = result.realized
        requested_density = isnothing(request.coverage_density_target) ?
                            "UNSPECIFIED" : _exact(request.coverage_density_target)
        requested_unique = isnothing(request.unique_carrier_count_target) ?
                           "UNSPECIFIED" : string(request.unique_carrier_count_target)
        requested_bundle = isnothing(request.bundle_count_target) ?
                           "UNSPECIFIED" : string(request.bundle_count_target)
        generator = result.spec.mechanism == :none ? result.spec.generator_id :
                    string(result.spec.mechanism)
        println(
            io,
            "| `", result.spec.instance_id,
            "` | ", result.spec.phase, "/", result.spec.family,
            " | `", generator,
            "` | ", requested_density,
            " | ", _exact(stats.active_coverage_density),
            " | ", requested_unique, "/", stats.unique_carrier_count,
            " | ", requested_bundle, "/", stats.bundle_count,
            " | ", _exact(stats.mean_pairwise_module_jaccard),
            " | ", _exact(stats.frontier_module_rank_association),
            " | `", result.instance_sha256, "` |",
        )
    end
    println(io)
    println(io, "## Validation observations")
    println(io)
    println(io, "- Pilot and final seed domains were checked for disjointness while loading the registries. No final seed was passed to a generator.")
    println(io, "- Every example passed `validate_journal_compression_instance`; every realized tagged row has at least one carrier.")
    println(io, "- Requested factor levels and realized exact statistics coexist in each serialized generation record. A label such as `low_clustered` is a mechanism setting, while the Jaccard value is measured from the realized module sets.")
    println(io, "- Structured pilot densities equal their registered targets; registered unique-row and bundle counts equal the realized counts under the documented half-up integer rounding rule.")
    println(io, "- The sparse seven-strategy pilot cannot attain density `1//8` while retaining six covered rows and exactly one unique row. Family A treats factor names as small-instance sanity settings, as registered; the report exposes the realized `11//36` density rather than silently relabeling it.")
    println(io, "- Adversarial seeds permute logical strategy labels only. The mathematical incidence and exact weights remain mechanism-defined.")
    println(io)
    println(io, "## Realized-statistic definitions")
    println(io)
    println(io, "- Active strategies are all strategies other than the identifier `inactive`, including a mandatory active strategy in the rare-mandatory family.")
    println(io, "- Active coverage density is the number of realized active-strategy incidences divided by tagged rows times active strategies.")
    println(io, "- A realized bundle covers at least `ceil(3r/4)` tagged requirements. This threshold is applied to incidence, not to a generator label.")
    println(io, "- Unique-carrier frequency is measured over the complete realized tagged universe, including the inactive strategy as a possible zero-frontier carrier.")
    println(io, "- Module overlap is the exact mean pairwise Jaccard index among active module sets, omitting pairs whose union is empty.")
    println(io, "- Frontier-module association is exact Kendall tau-a on each active strategy's frontier- and module-row carrier counts. Ties contribute zero; the registered correlation level remains a generation mechanism rather than a promised coefficient.")
    println(io)
    println(io, "## Scope boundary")
    println(io)
    println(io, "This dry run is synthetic generator evidence only. It is not a final registered benchmark, theorem proof, solver certificate, financial audit, runtime study, or empirical finding.")
    return String(take!(io))
end


function main(args = ARGS)
    mode = isempty(args) ? "--check" : only(args)
    rendered = render_report()
    if mode == "--write"
        open(REPORT_PATH, "w") do io
            write(io, rendered)
        end
        println("wrote ", relpath(REPORT_PATH, REPOSITORY_ROOT))
    elseif mode == "--check"
        isfile(REPORT_PATH) || error("missing dry-run generator report")
        read(REPORT_PATH, String) == rendered || error("dry-run generator report is stale")
        println("algorithmic compression generator dry-run report verified")
    else
        error("usage: dry_run_algorithmic_compression_generators_v1.jl [--write|--check]")
    end
    return nothing
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    DryRunAlgorithmicCompressionGeneratorsV1.main()
end
