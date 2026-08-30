using Random: MersenneTwister, rand


function _preprocessing_selection(mask::Integer, column_count::Int)
    return BitVector(
        !iszero(mask & (Int(1) << (column - 1))) for column in 1:column_count
    )
end


@testset "packed preprocessing scales across duplicate-heavy catalog" begin
    requirement_count = 32
    strategy_count = 14_401
    coverage = falses(requirement_count, strategy_count)
    for column in 2:strategy_count
        mask = UInt64(mod(column - 2, 256) + 1)
        for row in 1:8
            coverage[row, column] = !iszero(mask & (UInt64(1) << (row - 1)))
        end
        for row in 9:requirement_count
            coverage[row, column] = mod(column + row, 17) == 0
        end
    end
    model = ExactTaggedCoverModel(
        [Symbol("r$row") for row in 1:requirement_count],
        [Symbol("s$column") for column in 1:strategy_count],
        coverage,
        [0; [mod(column, 19) + 1 for column in 2:strategy_count]],
        BitVector([true; falses(strategy_count - 1)]),
    )
    result = preprocess_tagged_cover(model)
    @test result.feasible
    @test result.audit["original_variable_count"] == strategy_count
    @test result.audit["original_requirement_count"] == requirement_count
    @test result.audit["rule_counts"]["duplicate_coverage"]["variables_removed"] > 10_000
    @test isempty(result.reduced.requirements)
    @test isempty(result.reduced.strategy_ids)
    selected = falses(strategy_count)
    selected[result.forced_strategy_indices] .= true
    @test exact_tagged_cover_feasible(model, selected)
    @test exact_tagged_cover_burden(model, selected) == result.objective_offset
end


function _preprocessing_mask(selected::AbstractVector{Bool})
    mask = 0
    for column in eachindex(selected)
        selected[column] || continue
        mask |= Int(1) << (column - 1)
    end
    return mask
end


function _preprocessing_optima(model::ExactTaggedCoverModel)
    feasible = BitVector[]
    for mask in 0:((Int(1) << length(model.strategy_ids)) - 1)
        selected = _preprocessing_selection(mask, length(model.strategy_ids))
        exact_tagged_cover_feasible(model, selected) || continue
        push!(feasible, selected)
    end
    isempty(feasible) && return (objective = nothing, selections = BitVector[])
    objective = minimum(exact_tagged_cover_burden(model, row) for row in feasible)
    return (
        objective = objective,
        selections = BitVector[
            row for row in feasible if exact_tagged_cover_burden(model, row) == objective
        ],
    )
end


function _preprocessing_reduced_optima(result::TaggedCoverPreprocessingResult)
    result.feasible || return (objective = nothing, selections = BitVector[])
    feasible = BitVector[]
    column_count = length(result.reduced.strategy_ids)
    for mask in 0:((Int(1) << column_count) - 1)
        selected = _preprocessing_selection(mask, column_count)
        preprocessed_tagged_cover_feasible(result, selected) || continue
        push!(feasible, selected)
    end
    isempty(feasible) && return (objective = nothing, selections = BitVector[])
    objective = minimum(
        preprocessed_tagged_cover_burden(result, row) for row in feasible
    )
    return (
        objective = objective,
        selections = BitVector[
            row for row in feasible if
            preprocessed_tagged_cover_burden(result, row) == objective
        ],
    )
end


function _preprocessing_oracle_check(model::ExactTaggedCoverModel)
    original = _preprocessing_optima(model)
    result = preprocess_tagged_cover(model)
    reduced = _preprocessing_reduced_optima(result)

    @test result.audit["fixed_point"]
    @test result.feasible == !isnothing(original.objective)
    @test reduced.objective == original.objective
    @test !isempty(reduced.selections)

    reconstructed = BitVector[]
    for selected in reduced.selections
        canonical = lift_preprocessed_tagged_selection(result, selected)
        @test exact_tagged_cover_feasible(model, canonical)
        @test exact_tagged_cover_burden(model, canonical) == original.objective
        ties = reconstruct_equal_coverage_ties(result, selected)
        @test !isempty(ties)
        for candidate in ties
            @test exact_tagged_cover_feasible(model, candidate)
            @test exact_tagged_cover_burden(model, candidate) == original.objective
            push!(reconstructed, candidate)
        end
    end

    original_masks = Set(_preprocessing_mask(row) for row in original.selections)
    reconstructed_masks = Set(_preprocessing_mask(row) for row in reconstructed)
    @test !isempty(intersect(original_masks, reconstructed_masks))
    @test issubset(reconstructed_masks, original_masks)
    if result.all_optimizer_identities_reconstructable
        @test reconstructed_masks == original_masks
    end

    residual = preprocess_tagged_cover(result.reduced)
    @test residual.reduced.requirements == result.reduced.requirements
    @test residual.reduced.strategy_ids == result.reduced.strategy_ids
    @test residual.reduced.coverage == result.reduced.coverage
    @test residual.reduced.weights == result.reduced.weights
    @test isempty(residual.audit["events"])
    @test iszero(residual.objective_offset)

    return (
        original_masks_checked = Int(1) << length(model.strategy_ids),
        reduced_masks_checked = Int(1) << length(result.reduced.strategy_ids),
        reconstructed_optimizer_count = length(reconstructed_masks),
        identity_loss_flagged = !result.all_optimizer_identities_reconstructable,
    )
end


function _preprocessing_model(coverage, weights; mandatory = nothing)
    row_count, column_count = size(coverage)
    mandatory_flags = isnothing(mandatory) ?
        BitVector([true; falses(column_count - 1)]) : BitVector(mandatory)
    return ExactTaggedCoverModel(
        [Symbol("r$row") for row in 1:row_count],
        [Symbol("s$column") for column in 1:column_count],
        Bool.(coverage),
        weights,
        mandatory_flags,
    )
end


@testset "exact tagged-cover preprocessing input boundary" begin
    model = _preprocessing_model(
        Bool[0 1; 1 0],
        [0, 1 // 2],
    )
    @test model.weights == ExactRational[0, 1 // 2]
    @test model.mandatory == Bool[true, false]
    @test_throws ArgumentError _preprocessing_model(Bool[0 1], [0, 0.5])
    @test_throws ArgumentError _preprocessing_model(Bool[0 1], [0, 0])
    @test_throws ArgumentError ExactTaggedCoverModel(
        [:r], [:duplicate, :duplicate], Bool[0 1], [0, 1], Bool[1, 0]
    )
end


@testset "forced carrier and propagation" begin
    model = _preprocessing_model(Bool[0 1], [0, 3 // 2])
    result = preprocess_tagged_cover(model)
    counts = result.audit["rule_counts"]

    @test result.feasible
    @test isempty(result.reduced.requirements)
    @test isempty(result.reduced.strategy_ids)
    @test result.forced_strategy_indices == [1, 2]
    @test result.objective_offset == 3 // 2
    @test counts["mandatory_strategy"]["variables_removed"] == 1
    @test counts["mandatory_requirement_carrier"]["variables_removed"] == 1
    @test counts["forced_selection_propagation"]["requirements_removed"] == 1
    @test _preprocessing_oracle_check(model).reconstructed_optimizer_count == 1
end


@testset "coverage dominance preservation boundary" begin
    coverage = Bool[
        0 1 1 0 0
        0 0 1 1 0
        0 0 0 1 1
    ]

    strict_model = _preprocessing_model(coverage, [0, 2, 1, 1, 2])
    strict_result = preprocess_tagged_cover(strict_model)
    strict_original = _preprocessing_optima(strict_model)
    strict_reduced = _preprocessing_reduced_optima(strict_result)
    strict_reconstructed = Set(
        _preprocessing_mask(row) for selected in strict_reduced.selections for
        row in reconstruct_equal_coverage_ties(strict_result, selected)
    )
    @test strict_result.strategy_status[2] == :dominated_strict_weight
    @test strict_result.strategy_elimination_target[2] == 3
    @test strict_result.all_optimizer_identities_reconstructable
    @test strict_reconstructed ==
          Set(_preprocessing_mask(row) for row in strict_original.selections)
    @test _preprocessing_oracle_check(strict_model).identity_loss_flagged == false

    equal_model = _preprocessing_model(coverage, [0, 1, 1, 1, 1])
    equal_result = preprocess_tagged_cover(equal_model)
    equal_original = _preprocessing_optima(equal_model)
    equal_reduced = _preprocessing_reduced_optima(equal_result)
    equal_reconstructed = Set(
        _preprocessing_mask(row) for selected in equal_reduced.selections for
        row in reconstruct_equal_coverage_ties(equal_result, selected)
    )
    original_masks = Set(
        _preprocessing_mask(row) for row in equal_original.selections
    )
    @test equal_result.strategy_status[2] == :dominated_equal_weight
    @test !equal_result.all_optimizer_identities_reconstructable
    @test equal_reconstructed ⊊ original_masks
    @test _preprocessing_mask(BitVector([true, true, false, true, false])) in
          setdiff(original_masks, equal_reconstructed)
    @test _preprocessing_oracle_check(equal_model).identity_loss_flagged
end


@testset "duplicate coverage and exact tie reconstruction" begin
    equal_model = _preprocessing_model(
        Bool[
            0 1 1
            0 1 1
        ],
        [0, 1 // 2, 1 // 2],
    )
    equal_result = preprocess_tagged_cover(equal_model)
    equal_reduced = _preprocessing_reduced_optima(equal_result)
    reconstructed = Set(
        _preprocessing_mask(row) for selected in equal_reduced.selections for
        row in reconstruct_equal_coverage_ties(equal_result, selected)
    )
    @test equal_result.equal_coverage_choices == Dict(2 => [2, 3])
    @test equal_result.all_optimizer_identities_reconstructable
    @test reconstructed == Set((0b011, 0b101))
    @test equal_result.audit["rule_counts"]["redundant_requirement"][
        "requirements_removed"
    ] == 1
    @test equal_result.audit["rule_counts"]["duplicate_coverage"][
        "variables_removed"
    ] == 1
    @test _preprocessing_oracle_check(equal_model).reconstructed_optimizer_count == 2

    unequal_model = _preprocessing_model(
        Bool[
            0 1 1
            0 1 1
        ],
        [0, 1 // 2, 3 // 2],
    )
    unequal_result = preprocess_tagged_cover(unequal_model)
    @test unequal_result.strategy_status[3] == :duplicate_heavier
    @test isempty(unequal_result.equal_coverage_choices)
    @test unequal_result.all_optimizer_identities_reconstructable
    @test _preprocessing_oracle_check(unequal_model).reconstructed_optimizer_count == 1
end


@testset "empty contribution and mandatory semantics" begin
    model = _preprocessing_model(Bool[1 1], [0, 2])
    result = preprocess_tagged_cover(model)
    @test result.strategy_status[1] == :mandatory_selected
    @test result.strategy_status[2] == :empty_contribution
    @test result.forced_strategy_indices == [1]
    @test result.audit["rule_counts"]["mandatory_strategy_propagation"][
        "requirements_removed"
    ] == 1
    @test result.audit["rule_counts"]["empty_contribution"][
        "variables_removed"
    ] == 1
    @test _preprocessing_oracle_check(model).reconstructed_optimizer_count == 1
end


@testset "infeasible residual fails closed" begin
    model = _preprocessing_model(Bool[0 0], [0, 1])
    result = preprocess_tagged_cover(model)
    @test !result.feasible
    @test !result.audit["fixed_point"]
    @test result.audit["rule_counts"]["infeasible_requirement"][
        "applications"
    ] == 1
    @test _preprocessing_optima(model).objective === nothing
    @test _preprocessing_reduced_optima(result).objective === nothing
end


function _preprocessing_identity_library(catalog, ids::Symbol...)
    return RawLibrary(catalog, StrategyId.(collect(ids)))
end


function _preprocessing_module_set(ids::Symbol...)
    return ModuleSet(ModuleId{Symbol}[ModuleId(id) for id in ids])
end


@testset "identity-closure adapter and original-library certificates" begin
    beliefs = FiniteBeliefSpace([:zero])
    modules = [GenerativeModule(:m1), GenerativeModule(:m2)]
    strategies = [
        Strategy(
            :inactive,
            OperationalProfile(beliefs, [0]),
            _preprocessing_module_set(),
        ),
        Strategy(
            :left_a,
            OperationalProfile(beliefs, [0]),
            _preprocessing_module_set(:m1),
        ),
        Strategy(
            :left_b,
            OperationalProfile(beliefs, [0]),
            _preprocessing_module_set(:m1),
        ),
        Strategy(
            :right,
            OperationalProfile(beliefs, [0]),
            _preprocessing_module_set(:m2),
        ),
    ]
    catalog = StrategyCatalog(
        beliefs,
        modules,
        strategies,
        StrategyId(:inactive),
    )
    closure = identity_generative_closure(modules)
    source = _preprocessing_identity_library(
        catalog,
        :inactive,
        :left_a,
        :left_b,
        :right,
    )
    representation = tagged_cover_representation(
        catalog,
        closure,
        source;
        strategy_weights = [0, 1, 1, 2],
    )
    result = preprocess_tagged_cover(representation)
    reduced = _preprocessing_reduced_optima(result)
    reconstructions = BitVector[
        row for selected in reduced.selections for
        row in reconstruct_equal_coverage_ties(result, selected)
    ]
    @test length(reconstructions) == 2
    @test all(
        begin
            ids = Symbol[
                representation.strategy_ids[column].id for
                column in eachindex(row) if row[column]
            ]
            candidate = _preprocessing_identity_library(catalog, ids...)
            certificate = tagged_cover_certificate(representation, candidate)
            certificate.exact_safe_feasible &&
            certificate.tagged_cover_feasible &&
            certificate.exact_burden == 3 // 1
        end for row in reconstructions
    )
    adapter_audit = _preprocessing_oracle_check(
        exact_tagged_cover_model(representation),
    )
    @test adapter_audit.reconstructed_optimizer_count == 2
end


@testset "seeded randomized exhaustive preprocessing oracle" begin
    rng = MersenneTwister(0x70_72_65_70_72_6f_63)
    trial_count = 512
    original_masks_checked = 0
    reduced_masks_checked = 0
    reconstructed_optimizers = 0
    identity_loss_flags = 0

    for trial in 1:trial_count
        module_count = rand(rng, 1:4)
        active_count = rand(rng, 2:5)
        row_count = module_count + 1
        column_count = active_count + 1
        coverage = falses(row_count, column_count)
        coverage[1, :] .= true
        for row in 2:row_count
            while !any(coverage[row, 2:end])
                coverage[row, 2:end] .= rand(rng, Bool, active_count)
            end
        end
        requirements = TaggedRequirement[
            FrontierRequirement(Belief(Symbol("b$trial"))),
            [
                ModuleRequirement(ModuleId(Symbol("m$(trial)_$index"))) for
                index in 1:module_count
            ]...,
        ]
        strategy_ids = StrategyId{Symbol}[
            StrategyId(:inactive),
            [
                StrategyId(Symbol("s$(trial)_$index")) for
                index in 1:active_count
            ]...,
        ]
        weights = ExactRational[
            0 // 1,
            [rand(rng, 1:5) // rand(rng, 1:3) for _ in 1:active_count]...,
        ]
        model = ExactTaggedCoverModel(
            requirements,
            strategy_ids,
            coverage,
            weights,
            BitVector([true; falses(active_count)]),
        )
        audit = _preprocessing_oracle_check(model)
        original_masks_checked += audit.original_masks_checked
        reduced_masks_checked += audit.reduced_masks_checked
        reconstructed_optimizers += audit.reconstructed_optimizer_count
        identity_loss_flags += audit.identity_loss_flagged
    end

    @test original_masks_checked > 0
    @test reduced_masks_checked > 0
    @test reconstructed_optimizers >= trial_count
    @test identity_loss_flags > 0
end
