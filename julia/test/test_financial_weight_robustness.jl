using StrategyInnovation
using Test
using TOML

if !isdefined(Main, :FinancialWeightRobustnessV1)
    include(joinpath(
        @__DIR__,
        "..",
        "scripts",
        "run_financial_weight_robustness_v1.jl",
    ))
end
const WeightRobustness = Main.FinancialWeightRobustnessV1


function _forced_weight_robustness_fixture()
    model = (
        source_ids = ["left", "right"],
        rational_profiles = Dict(
            "left" => ExactRational[2, 0],
            "right" => ExactRational[0, 2],
        ),
        source_frontier = ExactRational[2, 2],
        source_modules = Set(["m1", "m2"]),
        lookup = Dict(
            "left" => (modules = ("m1",),),
            "right" => (modules = ("m2",),),
        ),
    )
    return journal_compression_instance_from_financial(
        model,
        Dict("left" => 2 // 1, "right" => 3 // 1);
        tie_handling = JournalTieHandling(
            :declared_representative;
            declaration = "one stable exact test representative",
            stable_selector = "strategy identifier",
        ),
        provenance = JournalCompressionProvenance(
            :financial,
            "synthetic-weight-robustness-certificate",
            "public synthetic exact test fixture; no financial rows",
        ),
    )
end


@testset "empty residual preprocessing gives an exact finite optimum certificate" begin
    instance = _forced_weight_robustness_fixture()
    certificate = WeightRobustness._empty_residual_optimum_certificate(instance)
    @test certificate.certified
    @test certificate.burden == 5 // 1
    @test certificate.selected == BitVector([true, true, true])
    @test check_journal_compression_solution(instance, certificate.selected).exact_feasible
    enumeration = solve_journal_compression_enumeration(instance)
    @test enumeration.exact_burden == certificate.burden
    @test occursin("not Lean verification", certificate.evidence)
    @test occursin("not solver evidence", certificate.evidence)
    raw = certify_empty_residual_optimum(instance)
    @test raw.certified_global_optimum
    @test raw.residual_strategy_count == 0
    @test raw.residual_requirement_count == 0
    payload = empty_residual_certificate_payload(raw, instance.strategy_ids)
    @test payload["lean_verified"] === false
    @test payload["solver_invoked"] === false
    @test payload["solver_status_used_as_proof"] === false
end


@testset "weight robustness schedule declarations are fixed and bounded" begin
    config = TOML.parsefile(WeightRobustness.CONFIG_PATH)
    schedules = WeightRobustness._schedule_declarations(config)
    @test getfield.(schedules, :schedule_id) == [
        "equal_active_strategy",
        "validation_computation",
        "governance_complexity",
    ]
    @test getfield.(schedules, :source_schedule_id) == [
        "uniform_cardinality",
        "validation_computation",
        "documented_complexity",
    ]
    @test [(row.expected_min, row.expected_max) for row in schedules] ==
          [(1, 1), (2, 38), (1, 7)]
    @test config["prior_schedule_outcomes_exist"] === true
    @test config["analysis"]["terminal_annual_units_pooled"] === false
    @test all(value === false for value in values(config["information_boundary"]))
end


@testset "weight robustness aggregate serialization is deterministic" begin
    rows = [(
        audit_id = "a",
        burden = 5 // 2,
        exact = true,
        unavailable = missing,
    )]
    columns = (:audit_id, :burden, :exact, :unavailable)
    first_text = WeightRobustness._csv_text(columns, rows)
    second_text = WeightRobustness._csv_text(columns, rows)
    @test first_text == second_text
    @test first_text == "audit_id,burden,exact,unavailable\na,5//2,true,\n"
end


@testset "weight robustness analysis covers the locked grid" begin
    instance = _forced_weight_robustness_fixture()
    base = compare_financial_algorithm_suite(
        instance;
        audit_id = "locked_terminal_v1",
        audit_label = "Synthetic locked terminal",
        schedule_id = "equal_active_strategy",
        heldout_unit =
            "terminal locked-2020-2024 enabled-descendant net-utility opportunity units",
        current_stepwise_ids = ["left", "right"],
        controls = FinancialAlgorithmComparisonControls(
            dp_requirement_limit = 10,
            multistart_count = 2,
            mip_time_limit_seconds = 30,
        ),
        heldout_evaluator = (_, _) -> 1 // 2,
    )
    config = TOML.parsefile(WeightRobustness.CONFIG_PATH)
    units = Dict(
        "locked_terminal_v1" =>
            "terminal locked-2020-2024 enabled-descendant net-utility opportunity units",
        "annual_walk_forward_v2" =>
            "annual mean next-year enabled-descendant opportunity units",
    )
    instances = JournalCompressionInstance[]
    results = FinancialAlgorithmComparisonResult[]
    for audit_id in WeightRobustness.FinancialComparison.REGISTERED_AUDITS,
        schedule in WeightRobustness._schedule_declarations(config)
        push!(instances, instance)
        push!(results, FinancialAlgorithmComparisonResult(
            base.schema_version,
            audit_id,
            "Synthetic $audit_id",
            schedule.schedule_id,
            units[audit_id],
            base.instance_sha256,
            base.strategy_ids,
            base.structure,
            base.controls,
            base.rows,
            base.selected_by_algorithm,
            base.solver_logs,
            base.benchmark,
            base.heldout_evaluation_phase,
        ))
    end
    mktempdir() do root
        WeightRobustness.FinancialComparison._write_results(root, instances, results)
        analysis = WeightRobustness._analysis_rows(root, config)
        @test length(analysis.summary) == 48
        @test length(analysis.certificates) == 6
        @test all(row.certified_global_optimum for row in analysis.certificates)
        @test all(iszero(row.residual_strategy_count) for row in analysis.certificates)
        @test all(iszero(row.residual_requirement_count) for row in analysis.certificates)
        @test length(analysis.ranks) == 16
        @test !isempty(analysis.overlaps)
        texts = WeightRobustness._analysis_texts(root, config)
        @test Set(keys(texts)) == Set(WeightRobustness.ANALYSIS_FILES)
        @test endswith(texts["results.md"], "\n")
        @test !endswith(texts["results.md"], "\n\n")
    end
end
