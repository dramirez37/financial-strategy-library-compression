module LockFinancialStrategyLibraryPanelV1

using Dates
using SHA: sha256
using TOML

include(joinpath(@__DIR__, "create_financial_strategy_library_panel_v1_registries.jl"))
using .FinancialStrategyLibraryPanelV1Registries

export create_design_lock,
       dry_run,
       main,
       validate_design,
       verify_design_lock,
       verify_lock_text

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "financial_strategy_library_panel_v1.toml",
)
const LOCK_PATH = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v1",
    "DESIGN_LOCK.json",
)

# These are the complete scientific, implementation, environment, and boundary
# inputs to the registered study. The lock itself is deliberately excluded.
const REQUIRED_FILES = (
    "DATA_ACCESS.md",
    "ARTIFACT_MANIFEST.md",
    "experiments/configs/financial_strategy_library_panel_v1.toml",
    "experiments/financial_strategy_library_panel_v1/DESIGN.md",
    "experiments/financial_strategy_library_panel_v1/ANALYSIS_PLAN.md",
    "experiments/financial_strategy_library_panel_v1/REPORTING_RULES.md",
    "experiments/financial_strategy_library_panel_v1/DATA_CONTRACT.md",
    "experiments/financial_strategy_library_panel_v1/CAPABILITY_OWNERSHIP.md",
    "experiments/financial_strategy_library_panel_v1/BURDEN_CALIBRATION.md",
    "experiments/financial_strategy_library_panel_v1/registry/ORIGIN_REGISTRY.csv",
    "experiments/financial_strategy_library_panel_v1/registry/LIBRARY_CONSTRUCTION_REGISTRY.csv",
    "experiments/financial_strategy_library_panel_v1/registry/CAPABILITY_REGISTRY.csv",
    "experiments/financial_strategy_library_panel_v1/registry/BURDEN_SCHEDULE_REGISTRY.csv",
    "experiments/financial_strategy_library_panel_v1/registry/SEED_REGISTRY.csv",
    "julia/Project.toml",
    "julia/Manifest.toml",
    "julia/src/StrategyInnovation.jl",
    "julia/src/JournalCompressionInstance.jl",
    "julia/src/TaggedCover.jl",
    "julia/src/TaggedCoverPreprocessing.jl",
    "julia/src/ExactJournalCompression.jl",
    "julia/src/GreedyJournalCompression.jl",
    "julia/src/CertifiedDeletionJournalCompression.jl",
    "julia/src/JournalCompressionMIP.jl",
    "julia/src/FinancialAlgorithmComparison.jl",
    "julia/scripts/create_financial_strategy_library_panel_v1_registries.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v1.jl",
    "julia/test/test_financial_strategy_library_panel_v1_registration.jl",
    "julia/test/run_financial_strategy_library_panel_v1_registration_tests.jl",
)

_sha256_file(path::AbstractString) = open(path, "r") do io
    bytes2hex(sha256(io))
end
_sha256_text(text::AbstractString) = bytes2hex(sha256(codeunits(text)))

function _require_equal(actual, expected, label)
    actual == expected || error("registered $label changed: expected $expected, found $actual")
end

function validate_design(config_path::AbstractString = DEFAULT_CONFIG)
    config = TOML.parsefile(config_path)
    _require_equal(
        config["schema_version"],
        "financial-strategy-library-panel-design-v1",
        "schema version",
    )
    _require_equal(
        config["experiment_id"],
        "financial-strategy-library-panel-v1",
        "experiment identifier",
    )
    _require_equal(config["protocol_date"], "2026-08-28", "protocol date")
    _require_equal(config["julia_version"], "1.12.6", "Julia version")
    config["licensed_rows_read_for_registration"] === false ||
        error("registration cannot read licensed rows")
    config["financial_outcomes_observed_for_registration"] === false ||
        error("study-specific outcomes were observed before registration")
    config["prior_financial_audit_outcomes_known"] === true ||
        error("the registration must acknowledge the prior financial audits")
    config["identity_closure_primary"] === true || error("identity closure must be primary")

    source = config["source"]
    source["revision_vintage_available"] === false ||
        error("the current-snapshot limitation was removed")
    source["raw_redistribution_permitted"] === false || error("raw redistribution cannot be allowed")
    source["aggregate_publication_requires_separate_audit"] === true ||
        error("aggregate promotion must require a separate audit")

    origins = config["origins"]
    _require_equal(origins["first_decision_year"], 2005, "first origin")
    _require_equal(origins["last_decision_year"], 2024, "last origin")
    _require_equal(origins["origin_count"], 20, "origin count")
    origins["postdecision_years_overlap"] === false || error("postdecision years cannot overlap")

    universe = config["universe"]
    universe["require_active_at_origin"] === true || error("origin activity is required")
    for key in (
        "require_active_at_future_endpoint",
        "require_same_ticker_at_future_endpoint",
        "postdecision_return_fields_may_define_universe",
        "future_identity_or_survival_may_define_universe",
        "delisted_after_origin_is_excluded",
    )
        universe[key] === false || error("future-conditioned universe flag is true: $key")
    end
    universe["preorigin_daily_row_count_may_define_universe"] === true ||
        error("the registered pre-origin history-count rule changed")
    _require_equal(
        universe["minimum_preorigin_daily_observations"],
        1000,
        "minimum pre-origin daily history",
    )
    _require_equal(universe["maximum_eligible_by_liquidity"], 150, "universe cap")
    _require_equal(universe["minimum_eligible_for_analysis"], 20, "minimum universe")

    grammar = config["grammar"]
    grammar_product = prod(length(grammar[key]) for key in (
        "directional_signal",
        "entry_filter",
        "holding_horizon",
        "sizing_rule",
        "exit_rule",
        "risk_constraint",
    ))
    _require_equal(grammar_product, 96, "factorial grammar size")
    _require_equal(
        grammar["strategies_per_instrument_full_factorial"],
        96,
        "declared factorial grammar size",
    )
    profiles = config["operating_profiles"]
    _require_equal(
        profiles["construction_score_tie_rule"],
        "bitwise-equal deterministic Float64 score; tolerance is not used to create ties",
        "construction-score tie rule",
    )
    _require_equal(
        profiles["instance_frontier_tie_rule"],
        "exact equality after lossless rational conversion of frozen coordinates",
        "instance-frontier tie rule",
    )

    _require_equal(config["libraries"]["library_count"], 3, "library count")
    config["libraries"]["capability_completion_uses_postorigin_information"] === false ||
        error("capability completion cannot use post-origin information")
    capabilities = config["capabilities"]
    _require_equal(
        capabilities["closure"],
        "identity union of registered atomic and interface capability identifiers carried by retained strategy specifications",
        "closure declaration",
    )
    _require_equal(
        capabilities["unresolved_ownership_policy"],
        "reject the source instance",
        "unresolved ownership policy",
    )

    burdens = config["burdens"]
    _require_equal(burdens["primary_schedule"], "validation_work_units", "primary burden")
    _require_equal(burdens["schedule_count"], 3, "burden count")
    burdens["weights_positive_integer_for_active"] === true ||
        error("active burdens must be positive integers")
    burdens["heldout_may_define_weight"] === false || error("held-out data cannot define burden")

    algorithms = config["algorithms"]
    _require_equal(
        algorithms["algorithm_ids"],
        [
            "jump_highs_tagged_cover",
            "requirement_mask_dp",
            "complete_enumeration",
            "weighted_greedy_reverse_delete",
            "heaviest_safe_first",
            "declared_source_order",
            "multistart_random_rechecked_deletion_32",
        ],
        "algorithm list",
    )
    _require_equal(algorithms["dp_requirement_limit"], 22, "DP limit")
    _require_equal(algorithms["enumeration_optional_strategy_limit"], 24, "enumeration limit")
    _require_equal(algorithms["multistart_count"], 32, "multistart count")
    algorithms["solver_optimal_is_formal_proof"] === false ||
        error("solver optimality cannot be labeled formal proof")
    algorithms["every_returned_solution_exactly_rechecked"] === true ||
        error("exact returned-solution rechecking is required")

    parallel = config["parallel"]
    _require_equal(parallel["supervisor_threads"], 8, "supervisor threads")
    _require_equal(parallel["worker_processes"], 8, "worker count")
    _require_equal(parallel["worker_julia_threads"], 1, "worker Julia threads")
    _require_equal(parallel["worker_blas_threads"], 1, "worker BLAS threads")
    _require_equal(parallel["worker_highs_threads"], 1, "worker HiGHS threads")
    parallel["progress_reads_outcomes"] === false || error("progress cannot read outcomes")

    for (key, value) in config["information_boundary"]
        value === false || error("prohibited information-boundary flag is true: $key")
    end
    publication = config["publication"]
    publication["public_promotion_automatic"] === false ||
        error("public promotion cannot be automatic")
    publication["public_promotion_requires_exact_audit"] === true ||
        error("public promotion must require exact audit")
    config["information_boundary"]["raw_licensed_rows_may_be_committed"] === false ||
        error("raw licensed rows cannot be committed")
    expected_nonclaims = Set(["causal", "forecasting", "alpha", "deployable performance", "population resource savings"])
    Set(String.(publication["nonclaims"])) == expected_nonclaims || error("registered nonclaims changed")

    registry_counts = check_registries()
    for path in REQUIRED_FILES
        isfile(joinpath(REPOSITORY_ROOT, path)) || error("missing lock input: $path")
    end
    return (config = config, registry_counts = registry_counts)
end

function _hashes()
    return Dict(
        path => _sha256_file(joinpath(REPOSITORY_ROOT, path)) for path in REQUIRED_FILES
    )
end

function _aggregate(hashes)
    return _sha256_text(join(
        ("$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))),
    ))
end

function _assert_no_study_outputs(config)
    for key in ("local_data_root", "local_results_root", "public_results_root")
        path = joinpath(REPOSITORY_ROOT, config["paths"][key])
        ispath(path) && (!isdir(path) || !isempty(readdir(path))) && error(
            "cannot lock after study-specific data or results exist: $(config["paths"][key])",
        )
    end
    return true
end

function _render_lock(hashes, counts)
    rows = join(
        ("    \"$path\": \"$(hashes[path])\"" for path in sort!(collect(keys(hashes)))),
        ",\n",
    )
    return """{
  "schema_version": "financial-strategy-library-panel-design-lock-v1",
  "experiment_id": "financial-strategy-library-panel-v1",
  "locked_at_utc": "$(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"))",
  "parent_commit": "56f3ad781bc69388e36b7c422e21c32a9a83b7fd",
  "prior_financial_audit_outcomes_known": true,
  "study_specific_licensed_rows_read_before_lock": false,
  "study_specific_outcomes_observed_before_lock": false,
  "study_specific_result_artifacts_present_before_lock": false,
  "origin_count": $(counts.origin_count),
  "library_construction_count": $(counts.library_count),
  "capability_count": $(counts.capability_count),
  "burden_schedule_count": $(counts.burden_count),
  "registered_origin_library_seed_rows": $(counts.seed_count),
  "registered_source_libraries": 60,
  "registered_compression_instances": 180,
  "registered_algorithm_terminal_rows": 1260,
  "aggregate_sha256": "$(_aggregate(hashes))",
  "files": {
$rows
  }
}
"""
end

function verify_lock_text(text::AbstractString, hashes = _hashes())
    occursin(
        "\"schema_version\": \"financial-strategy-library-panel-design-lock-v1\"",
        text,
    ) || error("unexpected or missing panel lock schema")
    occursin("\"study_specific_licensed_rows_read_before_lock\": false", text) ||
        error("invalid licensed-row access declaration")
    occursin("\"study_specific_outcomes_observed_before_lock\": false", text) ||
        error("invalid outcome-access declaration")
    occursin("\"prior_financial_audit_outcomes_known\": true", text) ||
        error("prior financial evidence is not acknowledged")
    for path in keys(hashes)
        occursin("\"$path\": \"$(hashes[path])\"", text) ||
            error("financial panel v1 design-lock mismatch: $path")
    end
    aggregate = _aggregate(hashes)
    occursin("\"aggregate_sha256\": \"$aggregate\"", text) ||
        error("financial panel v1 design-lock aggregate mismatch")
    return aggregate
end

function dry_run(config_path::AbstractString = DEFAULT_CONFIG)
    validated = validate_design(config_path)
    _assert_no_study_outputs(validated.config)
    hashes = _hashes()
    text = _render_lock(hashes, validated.registry_counts)
    aggregate = verify_lock_text(text, hashes)
    return (
        aggregate_sha256 = aggregate,
        registry_counts = validated.registry_counts,
        registered_source_libraries = 20 * 3,
        registered_compression_instances = 20 * 3 * 3,
        registered_algorithm_terminal_rows = 20 * 3 * 3 * 7,
    )
end

function create_design_lock(config_path::AbstractString = DEFAULT_CONFIG)
    isfile(LOCK_PATH) && error("financial panel v1 design lock already exists; do not rewrite it")
    validated = validate_design(config_path)
    _assert_no_study_outputs(validated.config)
    hashes = _hashes()
    text = _render_lock(hashes, validated.registry_counts)
    verify_lock_text(text, hashes)
    temporary = LOCK_PATH * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, text)
    end
    mv(temporary, LOCK_PATH; force = false)
    println("created financial strategy-library panel v1 design lock")
    return LOCK_PATH
end

function verify_design_lock(config_path::AbstractString = DEFAULT_CONFIG)
    validate_design(config_path)
    isfile(LOCK_PATH) || error("financial panel v1 design lock is absent")
    return verify_lock_text(read(LOCK_PATH, String), _hashes())
end

function main(args = ARGS)
    length(args) == 1 || error(
        "usage: lock_financial_strategy_library_panel_v1.jl --dry-run|--create|--check",
    )
    mode = only(args)
    mode == "--dry-run" && return println("financial panel v1 dry run valid: $(dry_run())")
    mode == "--create" && return create_design_lock()
    mode == "--check" && return println(
        "financial panel v1 design lock valid: $(verify_design_lock())",
    )
    error("unknown lock mode: $mode")
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV1.main()
end
