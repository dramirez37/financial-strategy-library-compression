using StrategyInnovation
using Test
using TOML

if !isdefined(Main, :FinancialAlgorithmComparisonV1)
    include(joinpath(
        @__DIR__,
        "..",
        "scripts",
        "run_financial_algorithm_comparison_v1.jl",
    ))
end
const FinancialComparisonCLI = Main.FinancialAlgorithmComparisonV1


function _financial_algorithm_fixture()
    source_ids = ["A", "B", "C", "D", "E", "F", "G"]
    rational_profiles = Dict(
        "A" => ExactRational[3, 0],
        "B" => ExactRational[0, 3],
        "C" => ExactRational[3, 3],
        "D" => ExactRational[3, 0],
        "E" => ExactRational[0, 0],
        "F" => ExactRational[3, 3],
        "G" => ExactRational[3, 0],
    )
    module_map = Dict(
        "A" => ["m1"],
        "B" => ["m2"],
        "C" => ["m1", "m2"],
        "D" => ["m1"],
        "E" => ["m3"],
        "F" => ["m3"],
        "G" => String[],
    )
    model = (
        source_ids,
        rational_profiles,
        source_frontier = ExactRational[3, 3],
        source_modules = Set(["m1", "m2", "m3"]),
        lookup = Dict(id => (modules = Tuple(module_map[id]),) for id in source_ids),
    )
    weights = Dict(
        "A" => 2 // 1,
        "B" => 2 // 1,
        "C" => 5 // 1,
        "D" => 3 // 1,
        "E" => 1 // 1,
        "F" => 6 // 1,
        "G" => 4 // 1,
    )
    provenance = JournalCompressionProvenance(
        :financial,
        "synthetic-financial-algorithm-workflow-fixture",
        "public synthetic unit-test fixture; no financial rows";
        attributes = [
            "evidence_class" => "synthetic workflow validation only",
            "licensed_rows_included" => "false",
        ],
        redistributable = true,
    )
    ties = JournalTieHandling(
        :declared_representative;
        declaration = "return one deterministic representative optimizer",
        stable_selector = "canonical strategy order",
    )
    instance = journal_compression_instance_from_financial(
        model,
        weights;
        inactive_id = "__resource_inactive__",
        tie_handling = ties,
        provenance,
    )
    return (; instance, current = ["A", "B", "E"])
end


@testset "financial algorithm comparison preserves the information boundary" begin
    fixture = _financial_algorithm_fixture()
    callback_count = Ref(0)
    heldout(selected, frozen_rows) = begin
        callback_count[] += 1
        @test all(ismissing(row.heldout_opportunity_diagnostic) for row in frozen_rows)
        @test any(selected)
        return 0.125
    end
    controls = FinancialAlgorithmComparisonControls(
        dp_requirement_limit = 10,
        multistart_count = 4,
        multistart_seed = 417,
        mip_time_limit_seconds = 30,
    )
    result = compare_financial_algorithm_suite(
        fixture.instance;
        audit_id = "synthetic_terminal_fixture",
        audit_label = "Synthetic terminal-shaped fixture",
        schedule_id = "synthetic_exact_weights",
        heldout_unit = "synthetic diagnostic units (not financial evidence)",
        current_stepwise_ids = fixture.current,
        controls,
        heldout_evaluator = heldout,
    )
    expected_algorithms = Set([
        "current_stepwise_safe_deletion",
        "heaviest_safe_first",
        "weighted_greedy",
        "weighted_greedy_reverse_delete",
        "multistart_random_deletion",
        "preprocessed_highs_mip",
        "requirement_mask_dp",
        "optional_second_solver_crosscheck",
    ])
    @test Set(row.algorithm_id for row in result.rows) == expected_algorithms
    feasible = [row for row in result.rows if row.exact_feasible === true]
    @test callback_count[] == length(feasible)
    @test all(row.heldout_opportunity_diagnostic == 0.125 for row in feasible)
    @test all(row.heldout_timing ==
              "EX_POST_AFTER_ALL_OPTIMIZATION_AND_BENCHMARK_ASSIGNMENT" for row in feasible)
    @test result.benchmark.algorithm_id == "requirement_mask_dp"
    @test result.benchmark.burden == 5 // 1
    @test result.benchmark.global_optimum_exactly_verified
    @test only(row for row in result.rows if row.algorithm_id == "preprocessed_highs_mip").exact_reconstructed_burden == 5 // 1
    @test only(row for row in result.rows if row.algorithm_id == "requirement_mask_dp").dp_state_count > 0
    @test result.structure.active_strategy_count == 7
    @test result.structure.frontier_requirement_count == 2
    @test result.structure.module_requirement_count == 3
    @test result.structure.duplicate_coverage_count >= 1
    @test result.structure.dominance_reductions >= 1
    @test result.structure.variables_after_preprocessing <
          result.structure.variables_before_preprocessing
    audit = audit_financial_algorithm_comparison(fixture.instance, result)
    @test audit.passed
    @test audit.checked_selection_count == length(result.selected_by_algorithm)
    payload = TOML.parse(serialize_financial_algorithm_comparison(result))
    @test payload["licensed_rows_included"] === false
    @test payload["audit_id"] == "synthetic_terminal_fixture"
    @test length(payload["rows"]) == length(result.rows)
    @test Set(payload["selections"]["requirement_mask_dp"]["selected_strategy_ids"]) ==
          Set(["__resource_inactive__", "A", "B", "E"])
    mktempdir() do root
        FinancialComparisonCLI._write_results(
            root,
            [fixture.instance],
            [result],
        )
        saved_audit = FinancialComparisonCLI.audit_saved_results(root)
        @test saved_audit["passed"] === true
        @test saved_audit["comparison_count"] == 1
        @test isfile(joinpath(root, "AUDIT.toml"))
    end

    mktempdir() do root
        units = Dict(
            "locked_terminal_v1" =>
                "terminal locked-2020-2024 enabled-descendant net-utility opportunity units",
            "annual_walk_forward_v2" =>
                "annual mean next-year enabled-descendant opportunity units",
        )
        instances = JournalCompressionInstance[]
        grid = FinancialAlgorithmComparisonResult[]
        for audit_id in FinancialComparisonCLI.REGISTERED_AUDITS,
            schedule_id in FinancialComparisonCLI.REGISTERED_SCHEDULES
            push!(instances, fixture.instance)
            push!(grid, FinancialAlgorithmComparisonResult(
                result.schema_version,
                audit_id,
                audit_id,
                schedule_id,
                units[audit_id],
                result.instance_sha256,
                result.strategy_ids,
                result.structure,
                result.controls,
                result.rows,
                result.selected_by_algorithm,
                result.solver_logs,
                result.benchmark,
                result.heldout_evaluation_phase,
            ))
        end
        source_certificates = Dict(
            audit_id => Dict(
                "committed_membership_reused" => true,
                "licensed_validation_profiles_recomputed" => true,
                "exact_frontier_matches_committed" => true,
                "exact_closure_matches_committed" => true,
                "registered_weights_match_committed" => true,
                "stepwise_endpoint_schedule_invariant" => true,
            ) for audit_id in FinancialComparisonCLI.REGISTERED_AUDITS
        )
        FinancialComparisonCLI._write_results(
            root,
            instances,
            grid;
            source_import_certificates = source_certificates,
        )
        FinancialComparisonCLI.audit_saved_results(root)
        validated = FinancialComparisonCLI._validate_public_summary(
            root,
            Dict(
                "experiment_id" =>
                    "retrospective-financial-algorithm-comparison-v1",
                "registered_weight_schedules" =>
                    collect(FinancialComparisonCLI.REGISTERED_SCHEDULES),
            ),
        )
        @test length(validated.rows) == 64
        @test isfile(validated.source_certificate_path)
        report = FinancialComparisonCLI._public_results_report(
            validated.rows,
            "synthetic-public-summary.csv",
            repeat("0", 64),
        )
        @test occursin("AUDITED RETROSPECTIVE FINANCIAL RESULTS", report)
        @test occursin("Every number below is derived", report)
    end
end


@testset "financial comparison records inapplicable exact DP and unavailable solver" begin
    fixture = _financial_algorithm_fixture()
    result = compare_financial_algorithm_suite(
        fixture.instance;
        audit_id = "synthetic_annual_fixture",
        audit_label = "Synthetic annual-shaped fixture",
        schedule_id = "synthetic_exact_weights",
        heldout_unit = "synthetic annual diagnostic units (not financial evidence)",
        current_stepwise_ids = fixture.current,
        controls = FinancialAlgorithmComparisonControls(
            dp_requirement_limit = 0,
            multistart_count = 2,
            mip_time_limit_seconds = 30,
        ),
    )
    dp = only(row for row in result.rows if row.algorithm_id == "requirement_mask_dp")
    @test dp.applicability == "NOT_APPLICABLE_REQUIREMENT_LIMIT"
    @test ismissing(dp.exact_feasible)
    second = only(row for row in result.rows if row.algorithm_id == "optional_second_solver_crosscheck")
    @test second.status == "UNAVAILABLE_NO_SECOND_SOLVER_DECLARED"
    @test all(ismissing(row.heldout_opportunity_diagnostic) for row in result.rows)
    @test audit_financial_algorithm_comparison(fixture.instance, result).passed
    @test_throws ArgumentError compare_financial_algorithm_suite(
        fixture.instance;
        audit_id = "bad",
        audit_label = "bad",
        schedule_id = "bad",
        heldout_unit = "bad",
        current_stepwise_ids = ["UNKNOWN"],
    )
end


@testset "financial comparison CSV parser is exact and rejects malformed rows" begin
    @test FinancialComparisonCLI._parse_csv_line("a,\"b,c\",\"d\"\"e\"") ==
          ["a", "b,c", "d\"e"]
    @test_throws ErrorException FinancialComparisonCLI._parse_csv_line("a,\"b")
    mktempdir() do root
        path = joinpath(root, "fixture.csv")
        write(path, "x,y\n1,\"two,three\"\n")
        @test FinancialComparisonCLI._read_csv_rows(path) ==
              [Dict("x" => "1", "y" => "two,three")]
    end
end


@testset "financial held-out units remain distinct strings" begin
    terminal = FinancialComparisonCLI._heldout_unit((; audit_id = "locked_terminal_v1"))
    annual = FinancialComparisonCLI._heldout_unit((; audit_id = "annual_walk_forward_v2"))
    @test terminal isa String
    @test annual isa String
    @test terminal != annual
    @test occursin("terminal", terminal)
    @test occursin("annual", annual)
    @test_throws ErrorException FinancialComparisonCLI._heldout_unit((; audit_id = "unknown"))
end
