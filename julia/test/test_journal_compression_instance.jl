using SHA: sha256


function _journal_schema_provenance(
    kind::Symbol = :synthetic;
    redistributable::Bool = true,
)
    return JournalCompressionProvenance(
        kind,
        "schema-test-instance",
        "exact in-repository test fixture";
        generator = "test_journal_compression_instance",
        parent_hashes = ["fixture" => repeat("a", 64)],
        attributes = ["evidence_class" => "exact finite computation"],
        redistributable,
    )
end


function _journal_schema_component_fixture()
    return journal_compression_instance_from_components(
        [:inactive, :right, :left],
        Bool[true, false, false],
        [0, 2, 1],
        [:high, :low],
        [
            0 0
            0 3
            2 0
        ],
        [Symbol[], [:m2], [:m1]];
        provenance = _journal_schema_provenance(),
    )
end


function _journal_schema_rebuild(
    instance::JournalCompressionInstance;
    strategy_ids = instance.strategy_ids,
    mandatory = instance.mandatory,
    weights = instance.weights,
    requirements = instance.requirements,
    coverage = instance.coverage,
    operating_profiles = instance.operating_profiles,
    strategy_modules = instance.strategy_modules,
    source_frontier = instance.source_frontier,
    source_closure = instance.source_closure,
    identity_closure = instance.identity_closure,
    preprocessing = instance.preprocessing,
    tie_handling = instance.tie_handling,
    provenance = instance.provenance,
)
    return JournalCompressionInstance(
        JOURNAL_COMPRESSION_INSTANCE_SCHEMA_VERSION,
        Tuple(strategy_ids),
        BitVector(mandatory),
        ExactRational[weights...],
        Tuple(requirements),
        BitMatrix(coverage),
        Matrix{ExactRational}(operating_profiles),
        Tuple(strategy_modules),
        ExactRational[source_frontier...],
        Tuple(source_closure),
        identity_closure,
        preprocessing,
        tie_handling,
        provenance,
    )
end


function _journal_schema_library(catalog, ids::Symbol...)
    return RawLibrary(catalog, StrategyId.(collect(ids)))
end


function _journal_schema_modules(ids::Symbol...)
    return ModuleSet(ModuleId{Symbol}[ModuleId(id) for id in ids])
end


function _journal_schema_raw_fixture()
    beliefs = FiniteBeliefSpace([:zero])
    modules = [GenerativeModule(:m1), GenerativeModule(:m2)]
    strategies = [
        Strategy(
            :inactive,
            OperationalProfile(beliefs, [0]),
            _journal_schema_modules(),
        ),
        Strategy(
            :left_b,
            OperationalProfile(beliefs, [0]),
            _journal_schema_modules(:m1),
        ),
        Strategy(
            :left_a,
            OperationalProfile(beliefs, [0]),
            _journal_schema_modules(:m1),
        ),
        Strategy(
            :right,
            OperationalProfile(beliefs, [0]),
            _journal_schema_modules(:m2),
        ),
    ]
    catalog = StrategyCatalog(
        beliefs,
        modules,
        strategies,
        StrategyId(:inactive),
    )
    closure = identity_generative_closure(modules)
    source = _journal_schema_library(
        catalog,
        :inactive,
        :left_b,
        :left_a,
        :right,
    )
    representation = tagged_cover_representation(
        catalog,
        closure,
        source;
        strategy_weights = [0, 1, 1, 2],
    )
    return (; catalog, closure, source, representation)
end


@testset "journal compression schema validation boundaries" begin
    instance = _journal_schema_component_fixture()
    @test validate_journal_compression_instance(instance) === instance
    @test instance.schema_version == "journal-compression-instance-v1"
    @test instance.identity_closure
    @test instance.strategy_ids == (
        StrategyId(:inactive),
        StrategyId(:left),
        StrategyId(:right),
    )
    @test all(any(instance.coverage[row, :]) for row in axes(instance.coverage, 1))
    reordered = journal_compression_instance_from_components(
        [:left, :inactive, :right],
        Bool[false, true, false],
        [1, 0, 2],
        [:low, :high],
        [
            0 2
            0 0
            3 0
        ],
        [[:m1], Symbol[], [:m2]];
        provenance = _journal_schema_provenance(),
    )
    @test reordered == instance
    @test journal_compression_instance_sha256(reordered) ==
          journal_compression_instance_sha256(instance)

    missing_carrier = copy(instance.coverage)
    missing_carrier[1, :] .= false
    @test_throws ArgumentError _journal_schema_rebuild(
        instance;
        coverage = missing_carrier,
    )

    duplicate_ids = (
        instance.strategy_ids[1],
        instance.strategy_ids[1],
        instance.strategy_ids[3],
    )
    @test_throws ArgumentError _journal_schema_rebuild(
        instance;
        strategy_ids = duplicate_ids,
    )

    negative_weights = copy(instance.weights)
    negative_weights[2] = -1 // 1
    @test_throws ArgumentError _journal_schema_rebuild(
        instance;
        weights = negative_weights,
    )

    wrong_frontier = copy(instance.source_frontier)
    wrong_frontier[1] += 1 // 1
    @test_throws ArgumentError _journal_schema_rebuild(
        instance;
        source_frontier = wrong_frontier,
    )

    wrong_closure = (
        instance.source_closure...,
        ModuleId(:m3),
    )
    @test_throws ArgumentError _journal_schema_rebuild(
        instance;
        source_closure = wrong_closure,
    )

    permutation = [2, 1, 3]
    @test_throws ArgumentError _journal_schema_rebuild(
        instance;
        strategy_ids = instance.strategy_ids[permutation],
        mandatory = instance.mandatory[permutation],
        weights = instance.weights[permutation],
        coverage = instance.coverage[:, permutation],
        operating_profiles = instance.operating_profiles[permutation, :],
        strategy_modules = instance.strategy_modules[permutation],
    )
    @test_throws ArgumentError _journal_schema_rebuild(
        instance;
        identity_closure = false,
    )

    lossy_map = JournalPreprocessingMap(
        true,
        collect(eachindex(instance.requirements)),
        [2, 3],
        [1],
        0,
        Pair{Int,Tuple{Vararg{Int}}}[];
        all_optimizer_identities_reconstructable = false,
    )
    complete_ties = JournalTieHandling(
        :complete;
        declaration = "all optimizer identities",
        stable_selector = "canonical order",
    )
    @test_throws ArgumentError _journal_schema_rebuild(
        instance;
        preprocessing = lossy_map,
        tie_handling = complete_ties,
    )
end


@testset "journal exact feasibility burden and mandatory semantics" begin
    instance = _journal_schema_component_fixture()
    all_selected = trues(length(instance.strategy_ids))
    unreduced_model = journal_reduced_cover_model(instance)
    @test unreduced_model.mandatory == instance.mandatory
    @test journal_compression_feasible(instance, all_selected)
    @test journal_compression_burden(instance, all_selected) == 3 // 1
    certificate = check_journal_compression_solution(
        instance,
        all_selected;
        expected_burden = "3//1",
    )
    @test certificate.exact_feasible
    @test certificate.mandatory_retained
    @test certificate.tagged_coverage
    @test certificate.frontier_preserved
    @test certificate.closure_preserved
    @test certificate.burden_reconciled

    without_mandatory = copy(all_selected)
    without_mandatory[findfirst(instance.mandatory)] = false
    rejected = check_journal_compression_solution(instance, without_mandatory)
    @test !rejected.exact_feasible
    @test !rejected.mandatory_retained
    @test_throws DimensionMismatch journal_compression_feasible(instance, Bool[true])
end


@testset "journal schema serialization and deterministic hashing" begin
    instance = _journal_schema_component_fixture()
    serialized = serialize_journal_compression_instance(instance)
    restored = deserialize_journal_compression_instance(serialized)
    @test restored == instance
    @test serialize_journal_compression_instance(restored) == serialized
    @test journal_compression_instance_sha256(restored) ==
          journal_compression_instance_sha256(instance)
    @test journal_compression_instance_sha256(instance) ==
          bytes2hex(sha256(serialized))
    io = IOBuffer()
    @test isnothing(write_journal_compression_instance(io, instance))
    seekstart(io)
    @test read_journal_compression_instance(io) == instance
    integer_instance = journal_compression_instance_from_components(
        Int16[0, 2],
        Bool[true, false],
        [0, 1],
        Int8[3],
        [0; 1;;],
        [Int32[], Int32[7]];
        provenance = _journal_schema_provenance(:canonical),
    )
    @test deserialize_journal_compression_instance(
        serialize_journal_compression_instance(integer_instance),
    ) == integer_instance
    unstable = replace(
        serialized,
        "canonical-identifier-order" => "input-iteration-order";
        count = 1,
    )
    @test_throws ArgumentError deserialize_journal_compression_instance(unstable)
end


@testset "raw tagged and preprocessing conversions" begin
    fixture = _journal_schema_raw_fixture()
    provenance = _journal_schema_provenance(:adversarial)
    tie_handling = JournalTieHandling(
        :complete;
        declaration = "all exact equal-coverage identities are reconstructed",
        stable_selector = "canonical strategy order for presentation",
    )
    from_raw = journal_compression_instance(
        fixture.catalog,
        fixture.closure,
        fixture.source;
        strategy_weights = [0, 1, 1, 2],
        tie_handling,
        provenance,
    )
    from_tagged = journal_compression_instance(
        fixture.representation;
        tie_handling,
        provenance,
    )
    @test from_raw == from_tagged
    @test journal_compression_feasible(from_raw, trues(4))
    @test from_raw.requirements[1] isa FrontierRequirement
    @test all(
        requirement isa ModuleRequirement for requirement in from_raw.requirements[2:end]
    )

    preprocessing = preprocess_tagged_cover(fixture.representation)
    reduced_instance = journal_compression_instance(
        fixture.representation;
        preprocessing,
        tie_handling,
        provenance,
    )
    reduced_model = journal_reduced_cover_model(reduced_instance)
    @test isempty(reduced_model.strategy_ids)
    @test isempty(reduced_model.requirements)
    reconstructed = reconstruct_journal_compression_solutions(
        reduced_instance,
        Bool[],
    )
    @test length(reconstructed) == 2
    @test all(journal_compression_feasible(reduced_instance, row) for row in reconstructed)
    @test all(
        journal_compression_burden(reduced_instance, row) == 3 // 1 for
        row in reconstructed
    )
    @test Set(
        Tuple(
            reduced_instance.strategy_ids[index].id for index in findall(row)
        ) for row in reconstructed
    ) == Set(((:inactive, :left_a, :right), (:inactive, :left_b, :right)))
    @test deserialize_journal_compression_instance(
        serialize_journal_compression_instance(reduced_instance),
    ) == reduced_instance
end


@testset "legally distributable financial aggregate conversion" begin
    model = (
        source_ids = ["B", "A"],
        rational_profiles = Dict(
            "A" => ExactRational[2, 0, -2],
            "B" => ExactRational[0, 3, -3],
        ),
        source_frontier = ExactRational[2, 3, -2],
        source_modules = Set(["module:B", "module:A"]),
        lookup = Dict(
            "A" => (modules = ("module:A",),),
            "B" => (modules = ("module:B",),),
        ),
    )
    weights = Dict("A" => 2 // 1, "B" => 3 // 1)
    provenance = JournalCompressionProvenance(
        :financial,
        "public-financial-aggregate-fixture",
        "legally distributable exact aggregate fixture";
        attributes = ["licensed_rows_included" => "false"],
        redistributable = true,
    )
    instance = journal_compression_instance_from_financial(
        model,
        weights;
        provenance,
    )
    @test journal_compression_feasible(instance, trues(3))
    @test journal_compression_burden(instance, trues(3)) == 5 // 1
    @test instance.provenance.instance_kind == :financial
    @test instance.provenance.redistributable
    @test instance.source_frontier == ExactRational[2, 3, -2]
    @test Set(module_id.id for module_id in instance.source_closure) ==
          Set(["module:A", "module:B"])

    private_provenance = _journal_schema_provenance(
        :financial;
        redistributable = false,
    )
    @test_throws ArgumentError journal_compression_instance_from_financial(
        model,
        weights;
        provenance = private_provenance,
    )
end


@testset "synthetic mask-generator conversion" begin
    if !isdefined(Main, :ResourceOptimization)
        include(joinpath(@__DIR__, "..", "src", "ResourceOptimization.jl"))
    end
    family = Main.ResourceOptimization.safe_deletion_gap_problem(3, 1 // 2)
    provenance = JournalCompressionProvenance(
        :adversarial,
        "safe-deletion-gap-k3",
        "ResourceOptimization.safe_deletion_gap_problem";
        generator = "safe_deletion_gap_problem",
    )
    instance = journal_compression_instance_from_mask_problem(
        family.problem;
        source_mask = family.source_mask,
        provenance,
    )
    @test length(instance.strategy_ids) == 5
    @test length(instance.source_closure) == 3
    @test journal_compression_feasible(instance, trues(5))
    @test journal_compression_burden(instance, trues(5)) == 9 // 2
    @test instance.provenance.instance_kind == :adversarial
    @test deserialize_journal_compression_instance(
        serialize_journal_compression_instance(instance),
    ) == instance
end
