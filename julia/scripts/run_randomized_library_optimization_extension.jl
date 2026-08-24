module RandomizedLibraryOptimizationExtension

using Printf
using SHA: sha256
using StrategyInnovation
using TOML

if !isdefined(Main, :RandomizedLibraryV2Core)
    Base.include(Main, joinpath(@__DIR__, "randomized_library_v2_core.jl"))
end
if !isdefined(Main, :LockRandomizedLibraryOptimizationExtension)
    Base.include(Main, joinpath(@__DIR__, "lock_randomized_library_optimization_extension.jl"))
end
const Core = Main.RandomizedLibraryV2Core
const DesignLock = Main.LockRandomizedLibraryOptimizationExtension
const ER = ExactRational

export analyze_trial, main, run_extension

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "randomized_library_optimization_extension_v1.toml",
)
const FACTORS = (
    :frontier_density,
    :module_overlap,
    :module_complementarity,
    :project_cost,
    :duration,
    :admission,
    :persistence,
)

_require(condition::Bool, message::AbstractString) =
    condition ? true : error(message)
_repo_path(path::AbstractString) =
    isabspath(path) ? normpath(path) :
    normpath(joinpath(REPOSITORY_ROOT, path))
_er(value) = exact_rational(value)
_mean(values) = sum(values; init = _er(0)) / _er(length(values))
_rat(value::Rational) = "$(numerator(value))//$(denominator(value))"
_rat(value::Integer) = "$(value)//1"
_bool(value::Bool) = value ? "true" : "false"

function _csv_field(value)
    token = if value === missing || value === nothing
        ""
    elseif value isa Rational
        _rat(value)
    elseif value isa Bool
        _bool(value)
    else
        string(value)
    end
    return occursin(r"[,\"\n\r]", token) ?
           "\"$(replace(token, "\"" => "\"\""))\"" : token
end

function _csv_text(rows::AbstractVector{<:NamedTuple})
    isempty(rows) && error("cannot render a headerless empty registered table")
    columns = propertynames(first(rows))
    all(propertynames(row) == columns for row in rows) ||
        error("CSV rows have inconsistent schemas")
    io = IOBuffer()
    println(io, join(string.(columns), ","))
    for row in rows
        println(io, join((_csv_field(getproperty(row, column)) for column in columns), ","))
    end
    return String(take!(io))
end

function _library_ids(library)
    return join(sort(collect(string(strategy_id.id) for strategy_id in library)), ";")
end

function _module_ids(modules)
    return join(sort(collect(string(module_id.id) for module_id in modules)), ";")
end

function _frontier_values(frontier)
    return join((_rat(value) for value in frontier.values), ";")
end

function _factor_fields(row)
    return (
        frontier_density = String(row.frontier_density),
        module_overlap = String(row.module_overlap),
        module_complementarity = String(row.module_complementarity),
        project_cost = String(row.project_cost),
        duration = String(row.duration),
        admission = String(row.admission),
        persistence = String(row.persistence),
    )
end

function _mask_library(model, active_ids, mask::Int)
    ids = [model.catalog.inactive_strategy]
    for (index, strategy_id) in enumerate(active_ids)
        iszero(mask & (1 << (index - 1))) || push!(ids, strategy_id)
    end
    return RawLibrary(model.catalog, ids)
end

function _mask_for_library(library, active_ids)
    mask = 0
    for (index, strategy_id) in enumerate(active_ids)
        strategy_id in library && (mask |= 1 << (index - 1))
    end
    return mask
end

function _joined(values)
    return join((value isa Rational ? _rat(value) : string(value) for value in values), ";")
end

function _optima(libraries, feasible, objective; sense::Symbol = :max)
    indices = [index for index in eachindex(libraries) if feasible(libraries[index])]
    isempty(indices) && error("registered optimization problem is infeasible")
    values = [objective(libraries[index]) for index in indices]
    optimum = sense == :max ? maximum(values) : minimum(values)
    selected = [indices[position] for position in eachindex(indices) if values[position] == optimum]
    return (; optimum, selected)
end

function _capacity_rows(trial_id, libraries, source_burden, source_total, config)
    registered = [
        (
            grid = "registered",
            point_id = String(point_id),
            budget_fraction = fraction,
            budget = fraction * source_burden,
        ) for (point_id, fraction) in zip(
            config["capacity"]["registered_fraction_ids"],
            _er.(config["capacity"]["registered_source_burden_fractions"]),
        )
    ]
    attainable_burdens = sort(unique(library.burden for library in libraries))
    attainable = [
        (
            grid = "attainable",
            point_id = "A$(lpad(string(index - 1), 2, '0'))",
            budget_fraction = nothing,
            budget,
        ) for (index, budget) in enumerate(attainable_burdens)
    ]

    records = NamedTuple[]
    rows = NamedTuple[]
    for point in vcat(registered, attainable)
        solution = _optima(
            libraries,
            library -> library.burden <= point.budget,
            library -> library.total,
        )
        selected = libraries[solution.selected]
        record = (; point..., optimum = solution.optimum, selected)
        push!(records, record)
        push!(
            rows,
            (
                trial_id,
                grid = point.grid,
                point_id = point.point_id,
                budget_fraction = point.budget_fraction,
                budget = point.budget,
                optimal_total_value = solution.optimum,
                normalized_total_value = solution.optimum / source_total,
                optimal_masks = _joined(library.mask for library in selected),
                optimal_library_ids = join((_library_ids(library.library) for library in selected), "|") ,
                optimal_burdens = _joined(sort(unique(library.burden for library in selected))),
                operational_values = _joined(sort(unique(library.operational for library in selected))),
                generative_values = _joined(sort(unique(library.generative for library in selected))),
                optimizer_count = length(selected),
                feasible_library_count = count(library -> library.burden <= point.budget, libraries),
                capacity_feasible_gate = all(library -> library.burden <= point.budget, selected),
                enumeration_certificate = "complete-enumeration:$(length(libraries))",
            ),
        )
    end

    shadow_rows = NamedTuple[]
    nonconcavity = Dict{String,Bool}()
    monotonicity = Dict{String,Bool}()
    for grid in ("registered", "attainable")
        grid_records = filter(record -> record.grid == grid, records)
        monotonicity[grid] = issorted(record.optimum for record in grid_records)
        shadows = ER[]
        for index in 1:(length(grid_records) - 1)
            left = grid_records[index]
            right = grid_records[index + 1]
            shadow = (right.optimum - left.optimum) / (right.budget - left.budget)
            push!(shadows, shadow)
            push!(
                shadow_rows,
                (
                    trial_id,
                    grid,
                    from_point_id = left.point_id,
                    to_point_id = right.point_id,
                    from_budget = left.budget,
                    to_budget = right.budget,
                    shadow_value = shadow,
                ),
            )
        end
        nonconcavity[grid] = any(shadows[index + 1] > shadows[index] for index in 1:(length(shadows) - 1))
    end
    return (; rows, records, shadow_rows, nonconcavity, monotonicity)
end

function _penalty_rows(trial_id, libraries, config)
    lambdas = _er.(config["penalty"]["lambda_grid"])
    ids = String.(config["penalty"]["lambda_ids"])
    records = NamedTuple[]
    rows = NamedTuple[]
    for (lambda_id, lambda) in zip(ids, lambdas)
        solution = _optima(
            libraries,
            _ -> true,
            library -> library.total - lambda * library.burden,
        )
        selected = libraries[solution.selected]
        push!(records, (; lambda_id, lambda, objective = solution.optimum, selected))
        push!(
            rows,
            (
                trial_id,
                lambda_id,
                lambda,
                optimal_net_value = solution.optimum,
                optimal_masks = _joined(library.mask for library in selected),
                optimal_library_ids = join((_library_ids(library.library) for library in selected), "|"),
                optimal_burdens = _joined(sort(unique(library.burden for library in selected))),
                operational_values = _joined(sort(unique(library.operational for library in selected))),
                generative_values = _joined(sort(unique(library.generative for library in selected))),
                total_values = _joined(sort(unique(library.total for library in selected))),
                optimizer_count = length(selected),
                enumeration_certificate = "complete-enumeration:$(length(libraries))",
            ),
        )
    end
    for index in 1:(length(records) - 1)
        low_burdens = [library.burden for library in records[index].selected]
        high_burdens = [library.burden for library in records[index + 1].selected]
        _require(
            maximum(high_burdens) <= minimum(low_burdens),
            "optimal burden correspondence increased with lambda in trial $trial_id",
        )
    end
    return (; rows, records)
end

function _breakpoint_rows(trial_id, libraries)
    candidate_prices = Set{ER}()
    for left_index in eachindex(libraries), right_index in (left_index + 1):length(libraries)
        left = libraries[left_index]
        right = libraries[right_index]
        left.burden == right.burden && continue
        price = (left.total - right.total) / (left.burden - right.burden)
        price >= 0 && push!(candidate_prices, price)
    end
    rows = NamedTuple[]
    for price in sort(collect(candidate_prices))
        solution = _optima(
            libraries,
            _ -> true,
            library -> library.total - price * library.burden,
        )
        selected = libraries[solution.selected]
        burdens = sort(unique(library.burden for library in selected))
        length(burdens) >= 2 || continue
        push!(
            rows,
            (
                trial_id,
                breakpoint_index = length(rows) + 1,
                lambda = price,
                strictly_positive = price > 0,
                optimal_net_value = solution.optimum,
                optimal_masks = _joined(library.mask for library in selected),
                optimal_library_ids = join((_library_ids(library.library) for library in selected), "|"),
                optimal_burdens = _joined(burdens),
                optimizer_count = length(selected),
                pairwise_candidates_checked = length(candidate_prices),
                enumeration_certificate = "complete-enumeration:$(length(libraries))",
            ),
        )
    end
    return rows
end

function _elasticity_rows(trial_id, penalty_records, config)
    by_price = Dict(record.lambda => record for record in penalty_records)
    rows = NamedTuple[]
    for interval in config["elasticity"]["intervals"]
        low_lambda = _er(interval["lower_lambda"])
        high_lambda = _er(interval["upper_lambda"])
        low = by_price[low_lambda]
        high = by_price[high_lambda]
        low_burdens = unique(library.burden for library in low.selected)
        high_burdens = unique(library.burden for library in high.selected)
        demand_defined = length(low_burdens) == 1 && length(high_burdens) == 1 && only(low_burdens) > 0
        demand = demand_defined ?
                 ((only(high_burdens) - only(low_burdens)) / only(low_burdens)) *
                 (low_lambda / (high_lambda - low_lambda)) : nothing

        low_triples = unique((library.burden, library.operational, library.generative) for library in low.selected)
        high_triples = unique((library.burden, library.operational, library.generative) for library in high.selected)
        channel_defined = length(low_triples) == 1 && length(high_triples) == 1 &&
                          (only(low_triples)[2] + only(low_triples)[3]) > 0
        if channel_defined
            low_triple = only(low_triples)
            high_triple = only(high_triples)
            base_total = low_triple[2] + low_triple[3]
            scale = low_lambda / (high_lambda - low_lambda)
            operational = ((high_triple[2] - low_triple[2]) / base_total) * scale
            generative = ((high_triple[3] - low_triple[3]) / base_total) * scale
            productive = (((high_triple[2] + high_triple[3]) - base_total) / base_total) * scale
            _require(operational + generative == productive, "channel elasticity failed exact decomposition in trial $trial_id")
        else
            operational = nothing
            generative = nothing
            productive = nothing
        end
        push!(
            rows,
            (
                trial_id,
                interval_id = String(interval["id"]),
                lower_lambda = low_lambda,
                upper_lambda = high_lambda,
                lower_optimal_burdens = _joined(sort(low_burdens)),
                upper_optimal_burdens = _joined(sort(high_burdens)),
                demand_defined,
                resource_demand_elasticity = demand,
                channel_defined,
                operational_contribution = operational,
                generative_contribution = generative,
                productive_value_elasticity = productive,
                channel_decomposition_gate = !channel_defined || operational + generative == productive,
            ),
        )
    end
    return rows
end

function analyze_trial(row, config)
    model = Core.build_registered_v2_model(row)
    active_ids = sort(
        [strategy_id for strategy_id in model.source if strategy_id != model.catalog.inactive_strategy];
        by = strategy_id -> string(strategy_id.id),
    )
    _require(length(active_ids) == 5, "trial $(row.trial_id) source no longer has five active strategies")
    source_state = compressed_library_state(model.catalog, model.closure, model.source)
    weights = Dict(
        strategy_id => (
            strategy_id == model.catalog.inactive_strategy ? _er(0) :
            _er(1 + length(strategy_modules(model.catalog, strategy_id)))
        ) for strategy_id in model.source
    )
    all(weights[strategy_id] > 0 for strategy_id in active_ids) ||
        error("active registered weight is not positive in trial $(row.trial_id)")
    raw_memo = Dict{Tuple,ER}()
    libraries = NamedTuple[]
    sublibrary_rows = NamedTuple[]
    for mask in 0:((1 << length(active_ids)) - 1)
        library = _mask_library(model, active_ids, mask)
        state = compressed_library_state(model.catalog, model.closure, library)
        values = Core._value_components(model.process, Int(config["horizon"]), library, raw_memo)
        burden = sum((weights[strategy_id] for strategy_id in library); init = _er(0))
        record = (
            mask,
            library,
            state,
            cardinality = length(library),
            burden,
            operational = values.passive,
            generative = values.premium,
            total = values.full,
            frontier_preserved = state.frontier == source_state.frontier,
            closure_preserved = state.closure == source_state.closure,
            safe = state == source_state,
        )
        _require(record.operational + record.generative == record.total, "value channels failed to close in trial $(row.trial_id), mask $mask")
        push!(libraries, record)
        push!(
            sublibrary_rows,
            (
                trial_id = row.trial_id,
                mask,
                library_ids = _library_ids(library),
                cardinality = record.cardinality,
                burden,
                frontier = _frontier_values(state.frontier),
                closure = _module_ids(state.closure),
                frontier_preserved = record.frontier_preserved,
                closure_preserved = record.closure_preserved,
                exact_safe = record.safe,
                operational_value = record.operational,
                generative_value = record.generative,
                total_productive_value = record.total,
                channel_decomposition_gate = record.operational + record.generative == record.total,
            ),
        )
    end
    _require(length(libraries) == 32, "trial $(row.trial_id) did not enumerate all 32 sublibraries")
    source = only(filter(library -> library.library == model.source, libraries))
    _require(source.total > 0, "trial $(row.trial_id) source productive value is not positive")

    minimum_weight = _optima(libraries, library -> library.safe, library -> library.burden; sense = :min)
    minimum_cardinality = _optima(libraries, library -> library.safe, library -> library.cardinality; sense = :min)
    frontier_only = _optima(libraries, library -> library.frontier_preserved, library -> library.burden; sense = :min)
    weighted_selected = libraries[minimum_weight.selected]
    cardinality_selected = libraries[minimum_cardinality.selected]
    frontier_selected = libraries[frontier_only.selected]
    _require(all(library -> library.safe, weighted_selected), "minimum-weight safe optimum failed exact safety")
    _require(all(library -> library.safe, cardinality_selected), "minimum-cardinality safe optimum failed exact safety")
    _require(all(library -> library.total == source.total, vcat(weighted_selected, cardinality_selected)), "exact safe optimum changed productive value")

    rechecked_library = innovation_safe_prune_fixed_point(
        model.catalog,
        model.closure,
        model.source;
        deletion_order = model.deletion_order,
    )
    rechecked_mask = _mask_for_library(rechecked_library, active_ids)
    rechecked = only(filter(library -> library.mask == rechecked_mask, libraries))
    _require(rechecked.safe, "rechecked pruning endpoint failed exact safety")
    _require(rechecked.total == source.total, "rechecked pruning endpoint changed productive value")
    _require(rechecked.burden <= source.burden, "safe pruning raised resource burden")

    certificate = "complete-enumeration:32"
    compression_rows = NamedTuple[]
    for (method, objective_name, optimum, selected) in (
        ("minimum_weight_safe", "burden", minimum_weight.optimum, weighted_selected),
        ("minimum_cardinality_safe", "cardinality", minimum_cardinality.optimum, cardinality_selected),
        ("frontier_only_minimum_weight", "burden", frontier_only.optimum, frontier_selected),
        ("rechecked_safe_pruning_endpoint", "registered_deletion_order", rechecked.burden, [rechecked]),
    )
        push!(
            compression_rows,
            (
                trial_id = row.trial_id,
                method,
                objective_name,
                optimal_objective = optimum,
                selected_masks = _joined(library.mask for library in selected),
                selected_library_ids = join((_library_ids(library.library) for library in selected), "|"),
                selected_burdens = _joined(library.burden for library in selected),
                selected_cardinalities = _joined(library.cardinality for library in selected),
                operational_values = _joined(library.operational for library in selected),
                generative_values = _joined(library.generative for library in selected),
                total_values = _joined(library.total for library in selected),
                optimizer_count = length(selected),
                frontier_preserved = all(library -> library.frontier_preserved, selected),
                closure_preserved = all(library -> library.closure_preserved, selected),
                exact_safe = all(library -> library.safe, selected),
                exact_productive_value_preserved = all(library -> library.total == source.total, selected),
                selected_library_certificate = join(("mask=$(library.mask):$(_library_ids(library.library))" for library in selected), "|"),
                enumeration_certificate = certificate,
            ),
        )
    end

    capacity = _capacity_rows(row.trial_id, libraries, source.burden, source.total, config)
    penalty = _penalty_rows(row.trial_id, libraries, config)
    breakpoints = _breakpoint_rows(row.trial_id, libraries)
    _require(!isempty(breakpoints), "trial $(row.trial_id) has no active resource-price breakpoint")
    elasticities = _elasticity_rows(row.trial_id, penalty.records, config)

    frontier_loss_values = [source.total - library.total for library in frontier_selected]
    frontier_loss = _mean(frontier_loss_values)
    trial_row = (
        trial_id = row.trial_id,
        batch_id = row.batch_id,
        principal_cell_id = row.principal_cell_id,
        _factor_fields(row)...,
        arithmetic = "Rational{BigInt}",
        parent_experiment = String(config["parent_experiment"]),
        extension_version = String(config["experiment_id"]),
        pooled_with_parent_results = false,
        enumerated_sublibraries = length(libraries),
        source_library_ids = _library_ids(model.source),
        source_strategy_weights = join(
            (
                "$(strategy_id.id):$(_rat(weights[strategy_id]))" for
                strategy_id in sort(
                    collect(model.source);
                    by = id -> string(id.id),
                )
            ),
            ";",
        ),
        source_cardinality = source.cardinality,
        source_burden = source.burden,
        source_operational_value = source.operational,
        source_generative_value = source.generative,
        source_total_productive_value = source.total,
        minimum_safe_weight = minimum_weight.optimum,
        minimum_safe_weight_optimizer_count = length(weighted_selected),
        minimum_safe_cardinality = minimum_cardinality.optimum,
        minimum_safe_cardinality_optimizer_count = length(cardinality_selected),
        rechecked_pruning_burden = rechecked.burden,
        rechecked_pruning_cardinality = rechecked.cardinality,
        greedy_optimality_gap = rechecked.burden - minimum_weight.optimum,
        greedy_gap_positive = rechecked.burden > minimum_weight.optimum,
        safe_weight_compression_ratio = (source.burden - minimum_weight.optimum) / source.burden,
        safe_cardinality_compression_ratio = (source.cardinality - minimum_cardinality.optimum) / _er(source.cardinality),
        frontier_only_minimum_weight = frontier_only.optimum,
        frontier_only_optimizer_count = length(frontier_selected),
        frontier_only_value_loss = frontier_loss,
        frontier_only_normalized_value_loss = frontier_loss / source.total,
        frontier_only_any_positive_value_loss = any(>(0), frontier_loss_values),
        registered_capacity_nonconcavity = capacity.nonconcavity["registered"],
        attainable_capacity_nonconcavity = capacity.nonconcavity["attainable"],
        lambda_breakpoint_count = length(breakpoints),
        positive_lambda_breakpoint_count = count(row -> row.strictly_positive, breakpoints),
        all_safe_optima_preserve_frontier_closure = all(library -> library.safe, vcat(weighted_selected, cardinality_selected)),
        all_safe_productive_values_preserved = all(library -> library.total == source.total, vcat(weighted_selected, cardinality_selected, [rechecked])),
        all_channel_decompositions_close = all(library -> library.operational + library.generative == library.total, libraries),
        all_capacity_optima_feasible = all(row -> row.capacity_feasible_gate, capacity.rows),
        capacity_value_monotone = all(values(capacity.monotonicity)),
        safe_pruning_weakly_lowers_burden = rechecked.burden <= source.burden,
        penalty_burden_monotone = true,
        global_enumeration_gate = length(libraries) == 32,
    )
    return (;
        trial_row,
        sublibrary_rows,
        compression_rows,
        capacity_rows = capacity.rows,
        shadow_rows = capacity.shadow_rows,
        penalty_rows = penalty.rows,
        breakpoint_rows = breakpoints,
        elasticity_rows = elasticities,
    )
end

function _groups(trial_rows, config)
    groups = [(factor = "overall", level = "all", rows = trial_rows)]
    for factor in FACTORS
        for level in String.(config["factor_slices"]["levels"][string(factor)])
            subset = filter(row -> getproperty(row, factor) == level, trial_rows)
            push!(groups, (factor = string(factor), level, rows = subset))
        end
    end
    return groups
end

function _summary_rows(trial_rows, capacity_rows, shadow_rows, elasticity_rows, config)
    rows = NamedTuple[]
    add(group, metric, parameter, values; aggregator = _mean) = begin
        defined = [value for value in values if value !== nothing]
        push!(rows, (
            slice_factor = group.factor,
            slice_level = group.level,
            n = length(group.rows),
            metric,
            parameter,
            defined_n = length(defined),
            exact_value = isempty(defined) ? nothing : aggregator(defined),
        ))
    end
    for group in _groups(trial_rows, config)
        ids = Set(row.trial_id for row in group.rows)
        add(group, "greedy_positive_frequency", "all", [_er(row.greedy_gap_positive) for row in group.rows])
        add(group, "greedy_optimality_gap_mean", "all", [row.greedy_optimality_gap for row in group.rows])
        add(group, "greedy_optimality_gap_max", "all", [row.greedy_optimality_gap for row in group.rows]; aggregator = maximum)
        add(group, "safe_weight_compression_ratio", "all", [row.safe_weight_compression_ratio for row in group.rows])
        add(group, "safe_cardinality_compression_ratio", "all", [row.safe_cardinality_compression_ratio for row in group.rows])
        add(group, "frontier_only_positive_loss_frequency", "all", [_er(row.frontier_only_any_positive_value_loss) for row in group.rows])
        add(group, "frontier_only_normalized_value_loss", "all", [row.frontier_only_normalized_value_loss for row in group.rows])
        add(group, "registered_capacity_nonconcavity_frequency", "all", [_er(row.registered_capacity_nonconcavity) for row in group.rows])
        add(group, "attainable_capacity_nonconcavity_frequency", "all", [_er(row.attainable_capacity_nonconcavity) for row in group.rows])
        add(group, "lambda_breakpoint_count", "all", [_er(row.lambda_breakpoint_count) for row in group.rows])
        add(group, "positive_lambda_breakpoint_count", "all", [_er(row.positive_lambda_breakpoint_count) for row in group.rows])
        for point_id in String.(config["capacity"]["registered_fraction_ids"])
            selected = filter(row -> row.trial_id in ids && row.grid == "registered" && row.point_id == point_id, capacity_rows)
            add(group, "normalized_value_capacity", point_id, [row.normalized_total_value for row in selected])
        end
        registered_shadows = filter(row -> row.trial_id in ids && row.grid == "registered", shadow_rows)
        for (left, right) in zip(
            config["capacity"]["registered_fraction_ids"][1:end-1],
            config["capacity"]["registered_fraction_ids"][2:end],
        )
            parameter = "$(left)_$(right)"
            selected = filter(row -> row.from_point_id == left && row.to_point_id == right, registered_shadows)
            add(group, "registered_capacity_shadow", parameter, [row.shadow_value for row in selected])
        end
        group_elasticities = filter(row -> row.trial_id in ids, elasticity_rows)
        for interval in config["elasticity"]["intervals"]
            interval_id = String(interval["id"])
            selected = filter(row -> row.interval_id == interval_id, group_elasticities)
            add(group, "resource_demand_elasticity", interval_id, [row.resource_demand_elasticity for row in selected])
            add(group, "operational_elasticity_contribution", interval_id, [row.operational_contribution for row in selected])
            add(group, "generative_elasticity_contribution", interval_id, [row.generative_contribution for row in selected])
            add(group, "productive_value_elasticity", interval_id, [row.productive_value_elasticity for row in selected])
        end
    end
    return rows
end

function _overall_map(summary_rows)
    return Dict(
        (row.metric, row.parameter) => row for row in summary_rows if
        row.slice_factor == "overall" && row.slice_level == "all"
    )
end

function _json_escape(value::AbstractString)
    return replace(value, "\\" => "\\\\", "\"" => "\\\"", "\n" => "\\n")
end

function _summary_json(config, trial_rows, summary_rows, hashes)
    overall = _overall_map(summary_rows)
    metrics = sort(collect(keys(overall)))
    metric_rows = join((
        "    \"$(_json_escape(metric))::$(_json_escape(parameter))\": " *
        (overall[(metric, parameter)].exact_value === nothing ? "null" : "\"$(_rat(overall[(metric, parameter)].exact_value))\"")
        for (metric, parameter) in metrics
    ), ",\n")
    all_gates = all(
        row -> row.all_safe_optima_preserve_frontier_closure &&
               row.all_safe_productive_values_preserved &&
               row.all_channel_decompositions_close &&
               row.all_capacity_optima_feasible &&
               row.capacity_value_monotone &&
               row.safe_pruning_weakly_lowers_burden &&
               row.penalty_burden_monotone &&
               row.global_enumeration_gate,
        trial_rows,
    )
    return """{
  \"schema_version\": \"randomized-library-v2-optimization-extension-results-v1\",
  \"experiment_id\": \"$(_json_escape(config["experiment_id"]))\",
  \"parent_experiment\": \"$(_json_escape(config["parent_experiment"]))\",
  \"parent_outcomes_are_inputs\": false,
  \"pooled_with_parent_results\": false,
  \"arithmetic\": \"Rational{BigInt}\",
  \"trial_count\": $(length(trial_rows)),
  \"sublibraries_per_trial\": 32,
  \"all_hard_gates_pass\": $(_bool(all_gates)),
  \"design_lock_sha256\": \"$(hashes.design_lock)\",
  \"parent_registry_sha256\": \"$(hashes.parent_registry)\",
  \"primary_exact_metrics\": {
$metric_rows
  }
}
"""
end

function _report_text(config, trial_rows, summary_rows, hashes)
    overall = _overall_map(summary_rows)
    value(metric, parameter = "all") = begin
        exact = overall[(metric, parameter)].exact_value
        if exact === nothing
            "undefined"
        else
            token = _rat(exact)
            length(token) <= 72 ? token :
            @sprintf(
                "%.8f (full exact value in the factor-summary CSV)",
                Float64(exact),
            )
        end
    end
    defined(metric, parameter) = overall[(metric, parameter)].defined_n
    capacity_lines = join((
        "| $(point_id) | $(value("normalized_value_capacity", String(point_id))) |" for
        point_id in config["capacity"]["registered_fraction_ids"]
    ), "\n")
    elasticity_lines = join((
        "| $(interval["id"]) | $(value("resource_demand_elasticity", String(interval["id"]))) | " *
        "$(value("operational_elasticity_contribution", String(interval["id"]))) | " *
        "$(value("generative_elasticity_contribution", String(interval["id"]))) | " *
        "$(defined("resource_demand_elasticity", String(interval["id"]))) / $(defined("operational_elasticity_contribution", String(interval["id"]))) |" for
        interval in config["elasticity"]["intervals"]
    ), "\n")
    return """# Registered randomized-library optimization extension v1

This is a separately versioned exact optimization extension of the frozen
`N = $(length(trial_rows))` randomized-library v2 registry. It does not read,
overwrite, or pool the parent outcome tables. Every trial enumerates all 32
inactive-containing sublibraries and all primary numbers below are exact
`Rational{BigInt}` values.

Compact exact fractions appear directly. When an across-trial mean has a very
large reduced denominator, this report prints a secondary decimal and the
factor-summary CSV retains the complete exact rational.

## Registered design

- Outcome-blind burden is zero for inactive and `1 + |raw modules|` for each
  active source strategy.
- Registered capacity fractions are `0, 1/4, 1/2, 3/4, 1`; registered prices
  are `0, 1/4, 1/2, 1, 2, 4`.
- The design lock is `$(hashes.design_lock)` and the frozen parent registry is
  `$(hashes.parent_registry)`.

## Primary exact results

- Positive greedy-gap frequency: `$(value("greedy_positive_frequency"))`.
- Mean / maximum greedy burden gap: `$(value("greedy_optimality_gap_mean"))` /
  `$(value("greedy_optimality_gap_max"))`.
- Mean weighted / cardinality safe-compression ratio:
  `$(value("safe_weight_compression_ratio"))` /
  `$(value("safe_cardinality_compression_ratio"))`.
- Frontier-only positive-loss frequency and mean normalized signed loss:
  `$(value("frontier_only_positive_loss_frequency"))` /
  `$(value("frontier_only_normalized_value_loss"))`.
- Registered-grid / attainable-grid nonconcavity frequency:
  `$(value("registered_capacity_nonconcavity_frequency"))` /
  `$(value("attainable_capacity_nonconcavity_frequency"))`.
- Mean total / positive active price breakpoints:
  `$(value("lambda_breakpoint_count"))` /
  `$(value("positive_lambda_breakpoint_count"))`.

| Capacity point | Mean exact normalized productive value |
|---|---:|
$capacity_lines

| Price interval | Demand elasticity | Operational contribution | Generative contribution | Defined demand / channel trials |
|---|---:|---:|---:|---:|
$elasticity_lines

## Hard gates

All registered hard gates passed: every reported global optimizer is the full
argmin or argmax correspondence from complete enumeration; all safe optima
preserve frontier and general closure; their productive values equal the
source exactly; channel decompositions close exactly; capacity optima are
feasible; and optimal burden correspondences are weakly decreasing in the
registered price grid. These are finite-instance Julia validation results,
not Lean theorem evidence.
"""
end

function _chart_label(value)
    token = _rat(value)
    return length(token) <= 12 ? token : @sprintf("%.4f", Float64(value))
end

function _svg_text(title, subtitle, categories, series; horizontal::Bool = false)
    width, height = 960, max(520, 160 + 40 * length(categories))
    left, right, top, bottom = horizontal ? (245, 70, 100, 65) : (90, 55, 105, 110)
    plot_width, plot_height = width - left - right, height - top - bottom
    values = reduce(vcat, [Float64.(entry.values) for entry in series])
    minimum_value = min(0.0, minimum(values))
    maximum_value = max(0.0, maximum(values))
    minimum_value == maximum_value && (maximum_value = minimum_value + 1.0)
    padding = 0.08 * (maximum_value - minimum_value)
    lo, hi = minimum_value - padding, maximum_value + padding
    xscale(value) = left + (Float64(value) - lo) / (hi - lo) * plot_width
    yscale(value) = top + (hi - Float64(value)) / (hi - lo) * plot_height
    colors = ["#2463A6", "#C99523"]
    io = IOBuffer()
    println(io, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$width\" height=\"$height\" viewBox=\"0 0 $width $height\">")
    println(io, "<rect width=\"100%\" height=\"100%\" fill=\"#ffffff\"/>")
    println(io, "<style>text{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;fill:#20242A}.mono{font-family:ui-monospace,SFMono-Regular,Menlo,monospace}.axis{stroke:#59616B;stroke-width:1}.grid{stroke:#D9DEE5;stroke-width:1}</style>")
    println(io, "<text x=\"$left\" y=\"38\" font-size=\"24\" font-weight=\"650\">$title</text>")
    println(io, "<text x=\"$left\" y=\"65\" font-size=\"14\" fill=\"#59616B\">$subtitle</text>")
    if horizontal
        zero_x = xscale(0)
        println(io, "<line class=\"axis\" x1=\"$zero_x\" y1=\"$top\" x2=\"$zero_x\" y2=\"$(top + plot_height)\"/>")
        band = plot_height / length(categories)
        bar_height = min(16.0, 0.6 * band / length(series))
        for (category_index, category) in enumerate(categories)
            base_y = top + (category_index - 0.5) * band
            println(io, "<text x=\"$(left - 12)\" y=\"$(base_y + 5)\" font-size=\"13\" text-anchor=\"end\">$category</text>")
            for (series_index, entry) in enumerate(series)
                value = entry.values[category_index]
                y = base_y + (series_index - (length(series) + 1) / 2) * (bar_height + 4) - bar_height / 2
                x0, x1 = xscale(0), xscale(value)
                println(io, "<rect x=\"$(min(x0, x1))\" y=\"$y\" width=\"$(abs(x1 - x0))\" height=\"$bar_height\" fill=\"$(colors[series_index])\" stroke=\"#20242A\" stroke-width=\"0.6\"><title>exact=$(_rat(entry.exact[category_index]))</title></rect>")
                anchor = value >= 0 ? "start" : "end"
                label_x = value >= 0 ? x1 + 6 : x1 - 6
                println(io, "<text class=\"mono\" x=\"$label_x\" y=\"$(y + bar_height - 2)\" font-size=\"11\" text-anchor=\"$anchor\">$(_chart_label(entry.exact[category_index]))</text>")
            end
        end
    else
        zero_y = yscale(0)
        println(io, "<line class=\"axis\" x1=\"$left\" y1=\"$zero_y\" x2=\"$(left + plot_width)\" y2=\"$zero_y\"/>")
        band = plot_width / length(categories)
        bar_width = min(46.0, 0.7 * band / length(series))
        for (category_index, category) in enumerate(categories)
            center_x = left + (category_index - 0.5) * band
            println(io, "<text x=\"$center_x\" y=\"$(top + plot_height + 28)\" font-size=\"13\" text-anchor=\"middle\">$category</text>")
            for (series_index, entry) in enumerate(series)
                value = entry.values[category_index]
                x = center_x + (series_index - (length(series) + 1) / 2) * (bar_width + 6) - bar_width / 2
                y0, y1 = yscale(0), yscale(value)
                println(io, "<rect x=\"$x\" y=\"$(min(y0, y1))\" width=\"$bar_width\" height=\"$(abs(y1 - y0))\" fill=\"$(colors[series_index])\" stroke=\"#20242A\" stroke-width=\"0.6\"><title>exact=$(_rat(entry.exact[category_index]))</title></rect>")
                label_y = value >= 0 ? y1 - 7 : y1 + 16
                println(io, "<text class=\"mono\" x=\"$(x + bar_width / 2)\" y=\"$label_y\" font-size=\"11\" text-anchor=\"middle\">$(_chart_label(entry.exact[category_index]))</text>")
            end
        end
    end
    if length(series) > 1
        for (index, entry) in enumerate(series)
            x = left + (index - 1) * 185
            println(io, "<rect x=\"$x\" y=\"$(height - 55)\" width=\"13\" height=\"13\" fill=\"$(colors[index])\" stroke=\"#20242A\" stroke-width=\"0.6\"/>")
            println(io, "<text x=\"$(x + 20)\" y=\"$(height - 44)\" font-size=\"12\">$(entry.name)</text>")
        end
    end
    println(io, "</svg>")
    return String(take!(io))
end

function _line_svg_text(title, subtitle, categories, exact_values)
    width, height = 960, 540
    left, right, top, bottom = 90, 55, 105, 90
    plot_width, plot_height = width - left - right, height - top - bottom
    values = Float64.(exact_values)
    lo = 0.0
    hi = max(1.0, maximum(values))
    xscale(index) = left + (index - 1) / (length(categories) - 1) * plot_width
    yscale(value) = top + (hi - Float64(value)) / (hi - lo) * plot_height
    io = IOBuffer()
    println(io, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$width\" height=\"$height\" viewBox=\"0 0 $width $height\">")
    println(io, "<rect width=\"100%\" height=\"100%\" fill=\"#ffffff\"/>")
    println(io, "<style>text{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;fill:#20242A}.mono{font-family:ui-monospace,SFMono-Regular,Menlo,monospace}.axis{stroke:#59616B;stroke-width:1}.grid{stroke:#D9DEE5;stroke-width:1}</style>")
    println(io, "<text x=\"$left\" y=\"38\" font-size=\"24\" font-weight=\"650\">$title</text>")
    println(io, "<text x=\"$left\" y=\"65\" font-size=\"14\" fill=\"#59616B\">$subtitle</text>")
    for tick in 0:4
        value = hi * tick / 4
        y = yscale(value)
        println(io, "<line class=\"grid\" x1=\"$left\" y1=\"$y\" x2=\"$(left + plot_width)\" y2=\"$y\"/>")
        println(io, "<text class=\"mono\" x=\"$(left - 12)\" y=\"$(y + 4)\" font-size=\"11\" text-anchor=\"end\">$(@sprintf("%.2f", value))</text>")
    end
    println(io, "<line class=\"axis\" x1=\"$left\" y1=\"$(top + plot_height)\" x2=\"$(left + plot_width)\" y2=\"$(top + plot_height)\"/>")
    points = join(("$(xscale(index)),$(yscale(value))" for (index, value) in enumerate(values)), " ")
    println(io, "<polyline points=\"$points\" fill=\"none\" stroke=\"#2463A6\" stroke-width=\"3\"/>")
    for (index, (category, value, exact)) in enumerate(zip(categories, values, exact_values))
        x, y = xscale(index), yscale(value)
        println(io, "<circle cx=\"$x\" cy=\"$y\" r=\"6\" fill=\"#ffffff\" stroke=\"#2463A6\" stroke-width=\"3\"><title>exact=$(_rat(exact))</title></circle>")
        println(io, "<text class=\"mono\" x=\"$x\" y=\"$(y - 14)\" font-size=\"11\" text-anchor=\"middle\">$(_chart_label(exact))</text>")
        println(io, "<text x=\"$x\" y=\"$(top + plot_height + 29)\" font-size=\"13\" text-anchor=\"middle\">$category</text>")
    end
    println(io, "</svg>")
    return String(take!(io))
end

function _figure_texts(config, summary_rows)
    overall = _overall_map(summary_rows)
    intervals = String.(getindex.(config["elasticity"]["intervals"], "id"))
    capacity_ids = String.(config["capacity"]["registered_fraction_ids"])
    capacity_exact = [overall[("normalized_value_capacity", id)].exact_value for id in capacity_ids]
    demand_exact = [overall[("resource_demand_elasticity", id)].exact_value for id in intervals]
    demand_plot = [value === nothing ? _er(0) : value for value in demand_exact]
    operational = [overall[("operational_elasticity_contribution", id)].exact_value for id in intervals]
    generative = [overall[("generative_elasticity_contribution", id)].exact_value for id in intervals]
    operational_plot = [value === nothing ? _er(0) : value for value in operational]
    generative_plot = [value === nothing ? _er(0) : value for value in generative]
    factor_rows = filter(row -> row.metric == "greedy_positive_frequency" && row.slice_factor != "overall", summary_rows)
    factor_labels = [replace(row.slice_factor, "_" => " ") * ": " * row.slice_level for row in factor_rows]
    factor_values = [row.exact_value for row in factor_rows]
    outputs = config["outputs"]
    return Dict(
        String(outputs["value_capacity_figure"]) => _line_svg_text(
            "Value–capacity curve",
            "Exact values in point metadata/CSV; compact labels and mark positions are secondary; N=$(config["sample_size"])",
            capacity_ids,
            capacity_exact,
        ),
        String(outputs["resource_demand_figure"]) => _svg_text(
            "Resource-demand elasticity",
            "Exact values in bar metadata/CSV; compact labels are secondary; defined N=$(config["sample_size"])",
            intervals,
            [(name = "resource demand", exact = demand_plot, values = demand_plot)],
        ),
        String(outputs["greedy_gap_figure"]) => _svg_text(
            "Positive greedy-gap frequency by factor slice",
            "Fourteen preregistered 512-trial slices; exact frequencies",
            factor_labels,
            [(name = "positive gap", exact = factor_values, values = factor_values)];
            horizontal = true,
        ),
        String(outputs["channel_figure"]) => _svg_text(
            "Operational and generative elasticity contributions",
            "Exact values in bar metadata/CSV; compact labels are secondary; defined N=$(config["sample_size"])",
            intervals,
            [
                (name = "operational", exact = operational_plot, values = operational_plot),
                (name = "generative", exact = generative_plot, values = generative_plot),
            ],
        ),
    )
end

function _sha256_file(path)
    return open(path, "r") do io
        bytes2hex(sha256(io))
    end
end

function _verify_lock(config)
    DesignLock.verify_design_lock(DEFAULT_CONFIG)
    lock_path = _repo_path(config["design_lock"]["path"])
    _require(isfile(lock_path), "optimization-extension design lock is absent")
    lock_text = read(lock_path, String)
    _require(occursin("\"extension_outcomes_read_before_lock\": false", lock_text), "design lock lacks the pre-outcome attestation")
    _require(occursin("\"outputs_absent_at_freeze\": true", lock_text), "design lock lacks the absent-output attestation")
    return _sha256_file(lock_path)
end

function _render_artifacts(config, trial_results)
    trial_rows = [result.trial_row for result in trial_results]
    sublibrary_rows = reduce(vcat, (result.sublibrary_rows for result in trial_results))
    compression_rows = reduce(vcat, (result.compression_rows for result in trial_results))
    capacity_rows = reduce(vcat, (result.capacity_rows for result in trial_results))
    shadow_rows = reduce(vcat, (result.shadow_rows for result in trial_results))
    penalty_rows = reduce(vcat, (result.penalty_rows for result in trial_results))
    breakpoint_rows = reduce(vcat, (result.breakpoint_rows for result in trial_results))
    elasticity_rows = reduce(vcat, (result.elasticity_rows for result in trial_results))
    summary_rows = _summary_rows(trial_rows, capacity_rows, shadow_rows, elasticity_rows, config)
    shadow_lookup = Dict(
        (row.trial_id, row.grid, row.from_point_id) => row for row in shadow_rows
    )
    capacity_output_rows = [
        begin
            shadow = get(
                shadow_lookup,
                (row.trial_id, row.grid, row.point_id),
                nothing,
            )
            (;
                row...,
                next_point_id =
                    shadow === nothing ? nothing : shadow.to_point_id,
                next_budget =
                    shadow === nothing ? nothing : shadow.to_budget,
                forward_shadow_value =
                    shadow === nothing ? nothing : shadow.shadow_value,
            )
        end for row in capacity_rows
    ]
    hashes = (
        design_lock = _verify_lock(config),
        parent_registry = _sha256_file(_repo_path(config["parent_registry"])),
    )
    outputs = config["outputs"]
    artifacts = Dict{String,String}(
        String(outputs["trials"]) => _csv_text(trial_rows),
        String(outputs["sublibraries"]) => _csv_text(sublibrary_rows),
        String(outputs["compression"]) => _csv_text(compression_rows),
        String(outputs["capacity"]) => _csv_text(capacity_output_rows),
        String(outputs["penalized"]) => _csv_text(penalty_rows),
        String(outputs["breakpoints"]) => _csv_text(breakpoint_rows),
        String(outputs["elasticities"]) => _csv_text(elasticity_rows),
        String(outputs["factor_summary"]) => _csv_text(summary_rows),
        String(outputs["summary"]) => _summary_json(config, trial_rows, summary_rows, hashes),
        String(outputs["report"]) => _report_text(config, trial_rows, summary_rows, hashes),
    )
    merge!(artifacts, _figure_texts(config, summary_rows))
    return artifacts
end

function run_extension(config_path::AbstractString = DEFAULT_CONFIG; check::Bool = false, trial_limit = nothing)
    config = TOML.parsefile(config_path)
    _require(config["schema_version"] == "randomized-library-v2-optimization-extension-v1", "unsupported optimization-extension config")
    _require(config["arithmetic"] == "Rational{BigInt}", "registered exact arithmetic changed")
    _require(config["parent_outcomes_are_inputs"] === false, "parent outcomes may not be inputs")
    _require(config["pooled_with_parent_results"] === false, "parent and extension results may not be pooled")
    _verify_lock(config)
    rows = Core.read_registered_v2_trials(_repo_path(config["parent_registry"]))
    _require(length(rows) == Int(config["sample_size"]), "parent registry sample size changed")
    selected_rows = trial_limit === nothing ? rows : rows[1:Int(trial_limit)]
    check && trial_limit !== nothing && error("artifact check cannot use a trial limit")
    results = Vector{Any}(undef, length(selected_rows))
    completed = Threads.Atomic{Int}(0)
    Threads.@threads for index in eachindex(selected_rows)
        results[index] = analyze_trial(selected_rows[index], config)
        count = Threads.atomic_add!(completed, 1) + 1
        if iszero(count % 64) || count == length(selected_rows)
            println("optimization extension: completed $count / $(length(selected_rows)) registered trials")
        end
    end
    trial_limit === nothing || return results
    artifacts = _render_artifacts(config, results)
    for (relative_path, content) in sort(collect(artifacts); by = first)
        path = _repo_path(relative_path)
        if check
            _require(isfile(path), "registered optimization artifact is absent: $relative_path")
            _require(read(path, String) == content, "registered optimization artifact drifted: $relative_path")
        else
            mkpath(dirname(path))
            open(path, "w") do io
                write(io, content)
            end
        end
    end
    println(check ? "registered optimization extension artifacts are current" : "wrote registered optimization extension artifacts")
    return artifacts
end

function main(args = ARGS)
    positional = [argument for argument in args if !startswith(argument, "--")]
    length(positional) <= 1 || error("usage: run_randomized_library_optimization_extension.jl [config] [--check]")
    config_path = isempty(positional) ? DEFAULT_CONFIG : only(positional)
    return run_extension(config_path; check = "--check" in args)
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    RandomizedLibraryOptimizationExtension.main()
end
