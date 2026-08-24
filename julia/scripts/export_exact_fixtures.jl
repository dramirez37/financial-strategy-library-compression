module ExactFixtureExporter

using StrategyInnovation

export BRIDGE_SCHEMA_VERSION,
       ExactBridgeFixture,
       build_exact_fixtures,
       main,
       render_fixture_json,
       render_generated_lean,
       validate_fixture,
       write_exact_fixtures

"""Stable schema identifier embedded in every exact bridge artifact."""
const BRIDGE_SCHEMA_VERSION = "lean-julia-exact-fixture-v2"

struct FixtureStrategy
    id::String
    operational_profile::Vector{ExactRational}
    modules::Vector{String}
end

struct FixtureLibrary
    id::String
    strategies::Vector{String}
end

struct FixtureProject
    id::String
    cost::Vector{ExactRational}
    duration::Int
    survival::ExactRational
    strict_cost::Bool
    required_modules::Vector{String}
    candidate_strategies::Vector{String}
end

struct FixtureExpected
    rational_scalars::Vector{Pair{String,ExactRational}}
    rational_vectors::Vector{Pair{String,Vector{ExactRational}}}
    boolean_scalars::Vector{Pair{String,Bool}}
    boolean_vectors::Vector{Pair{String,Vector{Bool}}}
    string_vectors::Vector{Pair{String,Vector{String}}}
end

"""Validated exact finite model rendered identically into JSON and Lean."""
struct ExactBridgeFixture
    schema_version::String
    fixture_id::String
    theorem_family::String
    beliefs::Vector{String}
    transition_rows::Matrix{ExactRational}
    discount::ExactRational
    modules::Vector{String}
    strategies::Vector{FixtureStrategy}
    libraries::Vector{FixtureLibrary}
    projects::Vector{FixtureProject}
    expected::FixtureExpected
end

_rat(value) = exact_rational(value)
_rats(values) = ExactRational[_rat(value) for value in values]

function _identifier(value::AbstractString, label::AbstractString)
    occursin(r"^[a-z][a-z0-9_]*$", value) ||
        throw(ArgumentError("$label must be a lower-snake-case identifier: $(repr(value))"))
    return value
end

function _unique(values, label::AbstractString)
    length(values) == length(Set(values)) || throw(ArgumentError("$label must be unique"))
    return values
end

function _context(fixture::ExactBridgeFixture)
    belief_space = FiniteBeliefSpace(Symbol.(fixture.beliefs))
    module_rows = GenerativeModule.(Symbol.(fixture.modules))
    strategies = [
        Strategy(
            Symbol(row.id),
            OperationalProfile(belief_space, row.operational_profile),
            ModuleSet(ModuleId.(Symbol.(row.modules))),
        ) for row in fixture.strategies
    ]
    catalog = StrategyCatalog(
        belief_space,
        module_rows,
        strategies,
        StrategyId(:inactive),
    )
    closure = identity_generative_closure(module_rows)
    libraries = Dict(
        row.id => RawLibrary(catalog, StrategyId.(Symbol.(row.strategies))) for
        row in fixture.libraries
    )
    kernel = MarkovKernel(belief_space, fixture.transition_rows)
    return (; belief_space, catalog, closure, libraries, kernel)
end

"""Validate one exact bridge fixture, including all finite-model references."""
function validate_fixture(fixture::ExactBridgeFixture)
    fixture.schema_version == BRIDGE_SCHEMA_VERSION || throw(
        ArgumentError("unsupported exact-fixture schema version $(repr(fixture.schema_version))"),
    )
    _identifier(fixture.fixture_id, "fixture ID")
    isempty(fixture.theorem_family) && throw(ArgumentError("theorem family cannot be empty"))
    isempty(fixture.beliefs) && throw(ArgumentError("beliefs cannot be empty"))
    _unique(fixture.beliefs, "belief IDs")
    foreach(id -> _identifier(id, "belief ID"), fixture.beliefs)
    size(fixture.transition_rows) == (length(fixture.beliefs), length(fixture.beliefs)) ||
        throw(DimensionMismatch("transition rows must form a square belief kernel"))
    0 <= fixture.discount <= 1 ||
        throw(ArgumentError("the finite exact discount must lie in [0, 1]"))
    isempty(fixture.modules) && throw(ArgumentError("module carrier cannot be empty"))
    _unique(fixture.modules, "module IDs")
    foreach(id -> _identifier(id, "module ID"), fixture.modules)

    strategy_ids = [row.id for row in fixture.strategies]
    _unique(strategy_ids, "strategy IDs")
    foreach(id -> _identifier(id, "strategy ID"), strategy_ids)
    "inactive" in strategy_ids || throw(ArgumentError("the inactive strategy must resolve"))
    for row in fixture.strategies
        length(row.operational_profile) == length(fixture.beliefs) || throw(
            DimensionMismatch("strategy $(row.id) has the wrong operational-profile length"),
        )
        _unique(row.modules, "module references on strategy $(row.id)")
        all(module_id -> module_id in fixture.modules, row.modules) || throw(
            ArgumentError("strategy $(row.id) contains an unresolved module reference"),
        )
    end

    library_ids = [row.id for row in fixture.libraries]
    _unique(library_ids, "library IDs")
    foreach(id -> _identifier(id, "library ID"), library_ids)
    for row in fixture.libraries
        isempty(row.strategies) && throw(ArgumentError("library $(row.id) cannot be empty"))
        _unique(row.strategies, "strategy references in library $(row.id)")
        "inactive" in row.strategies ||
            throw(ArgumentError("library $(row.id) must contain inactive"))
        all(strategy_id -> strategy_id in strategy_ids, row.strategies) || throw(
            ArgumentError("library $(row.id) contains an unresolved strategy reference"),
        )
    end

    project_ids = [row.id for row in fixture.projects]
    _unique(project_ids, "project IDs")
    foreach(id -> _identifier(id, "project ID"), project_ids)
    isempty(project_ids) && throw(ArgumentError("project carrier cannot be empty"))
    for row in fixture.projects
        length(row.cost) == length(fixture.beliefs) ||
            throw(DimensionMismatch("project $(row.id) has the wrong cost-vector length"))
        all(>=(zero(ExactRational)), row.cost) ||
            throw(ArgumentError("project $(row.id) has a negative cost"))
        row.duration >= 1 ||
            throw(ArgumentError("project $(row.id) must have positive duration"))
        0 <= row.survival <= 1 ||
            throw(ArgumentError("project $(row.id) survival must lie in [0, 1]"))
        _unique(row.required_modules, "requirements of project $(row.id)")
        all(module_id -> module_id in fixture.modules, row.required_modules) || throw(
            ArgumentError("project $(row.id) has an unresolved module requirement"),
        )
        isempty(row.candidate_strategies) &&
            throw(ArgumentError("project $(row.id) needs at least one candidate"))
        _unique(row.candidate_strategies, "candidates of project $(row.id)")
        all(strategy_id -> strategy_id in strategy_ids, row.candidate_strategies) || throw(
            ArgumentError("project $(row.id) has an unresolved candidate reference"),
        )
    end

    for pairs in (
        fixture.expected.rational_scalars,
        fixture.expected.rational_vectors,
        fixture.expected.boolean_scalars,
        fixture.expected.boolean_vectors,
        fixture.expected.string_vectors,
    )
        _unique(first.(pairs), "expected-output IDs")
        foreach(id -> _identifier(id, "expected-output ID"), first.(pairs))
    end

    _context(fixture) # Reuse package constructors to check row stochasticity and invariants.
    return fixture
end

function _base_fixture(
    fixture_id,
    theorem_family,
    beliefs,
    transition_rows,
    discount,
    modules,
    strategies,
    libraries,
    projects,
    expected,
)
    fixture = ExactBridgeFixture(
        BRIDGE_SCHEMA_VERSION,
        fixture_id,
        theorem_family,
        beliefs,
        ExactRational.(_rat.(transition_rows)),
        _rat(discount),
        modules,
        strategies,
        libraries,
        projects,
        expected,
    )
    return validate_fixture(fixture)
end

_blank_expected() = FixtureExpected(
    Pair{String,ExactRational}[],
    Pair{String,Vector{ExactRational}}[],
    Pair{String,Bool}[],
    Pair{String,Vector{Bool}}[],
    Pair{String,Vector{String}}[],
)

function _raw_bridge_bundle()
    beliefs = FiniteBeliefSpace([:only])
    modules = [GenerativeModule(:key)]
    empty_modules = ModuleSet{Symbol}()
    key_modules = ModuleSet([ModuleId(:key)])
    strategies = [
        Strategy(:inactive, OperationalProfile(beliefs, [0]), empty_modules),
        Strategy(:bridge, OperationalProfile(beliefs, [0]), key_modules),
        Strategy(:candidate, OperationalProfile(beliefs, [2]), empty_modules),
    ]
    catalog = StrategyCatalog(
        beliefs,
        modules,
        strategies,
        StrategyId(:inactive),
    )
    closure = identity_generative_closure(modules)
    kernel = MarkovKernel(beliefs, reshape([1 // 1], 1, 1))
    project = UnifiedResearchProject(:innovate, key_modules, 1, true)
    failure = CandidateOutcome{Symbol}()
    candidate = CandidateOutcome(StrategyId(:candidate))
    generation(project, belief, available) =
        ModuleId(:key) in available ? dirac(candidate) : dirac(failure)
    verification(project, belief, available, strategy_id) = 1 // 2
    cost(belief, state, project) = 0 // 1
    function completion(project, belief, state)
        if ModuleId(:key) in state.closure
            return RatProb(
                [
                    ProjectCompletionOutcome([belief, belief], failure),
                    ProjectCompletionOutcome([belief, belief], candidate),
                ],
                [1 // 2, 1 // 2],
            )
        end
        return dirac(ProjectCompletionOutcome([belief, belief], failure))
    end
    process = RawInnovationProcess(
        catalog,
        closure,
        kernel,
        [project],
        generation,
        verification,
        cost,
        completion,
        1 // 2,
    )
    base = RawLibrary(
        catalog,
        [StrategyId(:inactive), StrategyId(:bridge)],
    )
    state = compressed_library_state(catalog, closure, base)
    return (; beliefs, catalog, closure, project, process, base, state)
end

function _raw_bridge_fixture(fixture_id, theorem_family, expected)
    return _base_fixture(
        fixture_id,
        theorem_family,
        ["only"],
        _rats(reshape([1], 1, 1)),
        1 // 2,
        ["key"],
        [
            FixtureStrategy("inactive", _rats([0]), String[]),
            FixtureStrategy("bridge", _rats([0]), ["key"]),
            FixtureStrategy("candidate", _rats([2]), String[]),
        ],
        [
            FixtureLibrary("base", ["inactive", "bridge"]),
            FixtureLibrary(
                "candidate_library",
                ["inactive", "bridge", "candidate"],
            ),
        ],
        [
            FixtureProject(
                "innovate",
                _rats([0]),
                1,
                _rat(1),
                false,
                ["key"],
                ["candidate"],
            ),
        ],
        expected,
    )
end

function _raw_compressed_transition_fixture()
    bundle = _raw_bridge_bundle()
    belief = first(bundle.beliefs.states)
    raw = projected_raw_project_transition(
        bundle.process,
        belief,
        bundle.base,
        bundle.project,
    )
    compressed = compressed_project_transition(
        bundle.process,
        belief,
        bundle.state,
        bundle.project,
    )
    raw_frontiers = ExactRational[
        first(outcome.state.frontier.values) for outcome in raw.outcomes
    ]
    compressed_frontiers = ExactRational[
        first(outcome.state.frontier.values) for outcome in compressed.outcomes
    ]
    expected = FixtureExpected(
        Pair{String,ExactRational}[],
        [
            "compressed_probabilities" => collect(compressed.probabilities),
            "compressed_terminal_frontiers" => compressed_frontiers,
            "raw_projected_probabilities" => collect(raw.probabilities),
            "raw_projected_terminal_frontiers" => raw_frontiers,
        ],
        ["transition_law_equal" => (raw == compressed)],
        Pair{String,Vector{Bool}}[],
        Pair{String,Vector{String}}[],
    )
    return _raw_bridge_fixture(
        "raw_compressed_transition_identity",
        "T1 raw-to-compressed transition identity",
        expected,
    )
end

function _raw_compressed_value_fixture()
    bundle = _raw_bridge_bundle()
    belief = first(bundle.beliefs.states)
    horizons = 0:5
    raw_finite = ExactRational[
        raw_finite_horizon_value(bundle.process, horizon, belief, bundle.base) for
        horizon in horizons
    ]
    compressed_finite = ExactRational[
        compressed_finite_horizon_value(
            bundle.process,
            horizon,
            belief,
            bundle.state,
        ) for horizon in horizons
    ]
    raw_stationary = raw_infinite_horizon_policy_iteration(bundle.process)
    compressed_stationary =
        compressed_infinite_horizon_policy_iteration(bundle.process)
    raw_infinite = state_value(raw_stationary, belief, bundle.base)
    compressed_infinite =
        state_value(compressed_stationary, belief, bundle.state)
    raw_action = policy_action(raw_stationary, belief, bundle.base)
    compressed_action =
        policy_action(compressed_stationary, belief, bundle.state)
    expected = FixtureExpected(
        [
            "compressed_bellman_residual" =>
                compressed_stationary.bellman_residual,
            "compressed_infinite_value" => compressed_infinite,
            "raw_bellman_residual" => raw_stationary.bellman_residual,
            "raw_infinite_value" => raw_infinite,
        ],
        [
            "compressed_finite_values_horizon_zero_to_five" =>
                compressed_finite,
            "raw_finite_values_horizon_zero_to_five" => raw_finite,
        ],
        [
            "finite_values_equal" => (raw_finite == compressed_finite),
            "infinite_values_equal" => (raw_infinite == compressed_infinite),
            "stationary_actions_equal" => (raw_action == compressed_action),
        ],
        Pair{String,Vector{Bool}}[],
        [
            "compressed_stationary_action" => [action_label(compressed_action)],
            "raw_stationary_action" => [action_label(raw_action)],
        ],
    )
    return _raw_bridge_fixture(
        "raw_compressed_value_equality",
        "T1 raw/compressed value equality",
        expected,
    )
end

function _safe_deletion_fixture()
    beliefs = ["low", "high"]
    strategies = [
        FixtureStrategy("inactive", _rats([0, 0]), String[]),
        FixtureStrategy("leader", _rats([2, 1]), ["signal"]),
        FixtureStrategy("duplicate", _rats([1, 1]), ["signal"]),
    ]
    libraries = [
        FixtureLibrary("after", ["inactive", "leader"]),
        FixtureLibrary("before", ["inactive", "leader", "duplicate"]),
    ]
    projects = [
        FixtureProject(
            "observe",
            _rats([0, 0]),
            1,
            _rat(1),
            false,
            ["signal"],
            ["leader"],
        ),
    ]
    seed = _base_fixture(
        "safe_deletion",
        "T3 safe deletion",
        beliefs,
        _rats([1 0; 0 1]),
        1 // 2,
        ["signal"],
        strategies,
        libraries,
        projects,
        _blank_expected(),
    )
    context = _context(seed)
    before = context.libraries["before"]
    after = context.libraries["after"]
    before_state =
        compressed_library_state(context.catalog, context.closure, before)
    after_state =
        compressed_library_state(context.catalog, context.closure, after)
    expected = FixtureExpected(
        Pair{String,ExactRational}[],
        [
            "frontier_after" => collect(after_state.frontier.values),
            "frontier_before" => collect(before_state.frontier.values),
        ],
        [
            "compressed_state_equal" => (before_state == after_state),
            "generatively_redundant" => generatively_redundant(
                context.catalog,
                context.closure,
                before,
                StrategyId(:duplicate),
            ),
            "operationally_redundant" => operationally_redundant(
                context.catalog,
                before,
                StrategyId(:duplicate),
            ),
        ],
        Pair{String,Vector{Bool}}[],
        [
            "modules_after" => ["signal"],
            "modules_before" => ["signal"],
        ],
    )
    return _base_fixture(
        "safe_deletion",
        "T3 safe deletion",
        beliefs,
        _rats([1 0; 0 1]),
        1 // 2,
        ["signal"],
        strategies,
        libraries,
        projects,
        expected,
    )
end

function _normalized_pruning_loss_fixture()
    discount = _rat(1 // 2)
    duration = 1
    survival = _rat(1)
    admission = _rat(1)
    reward_cap = _rat(2)
    cost = _rat(0)
    maximum_net = generative_strategy_lower_bound(
        discount,
        duration,
        cost,
        admission,
        survival,
        reward_cap,
    )
    pruned_value = zero(ExactRational)
    loss = maximum_net - pruned_value
    normalized_loss = loss / maximum_net
    expected = FixtureExpected(
        [
            "admission_probability" => admission,
            "maximum_net_descendant_value" => maximum_net,
            "normalized_pruning_loss" => normalized_loss,
            "pruned_value" => pruned_value,
            "research_cost" => cost,
            "reward_cap" => reward_cap,
            "unpruned_value" => maximum_net,
            "value_loss" => loss,
        ],
        [
            "frontier_pruned" => _rats([0]),
            "frontier_unpruned" => _rats([0]),
        ],
        [
            "frontier_preserved" => true,
            "normalization_attained" => (normalized_loss == 1),
        ],
        Pair{String,Vector{Bool}}[],
        [
            "modules_pruned" => String[],
            "modules_unpruned" => ["key"],
        ],
    )
    return _base_fixture(
        "normalized_pruning_loss",
        "T4 sharp normalized pruning loss",
        ["only"],
        _rats(reshape([1], 1, 1)),
        discount,
        ["key"],
        [
            FixtureStrategy("inactive", _rats([0]), String[]),
            FixtureStrategy("bridge", _rats([0]), ["key"]),
            FixtureStrategy("candidate", _rats([reward_cap]), String[]),
        ],
        [
            FixtureLibrary("pruned", ["inactive"]),
            FixtureLibrary("unpruned", ["inactive", "bridge"]),
        ],
        [
            FixtureProject(
                "innovate",
                _rats([cost]),
                duration,
                survival,
                false,
                ["key"],
                ["candidate"],
            ),
        ],
        expected,
    )
end

function _decomposition_fixture()
    beliefs = ["only"]
    strategies = [
        FixtureStrategy("inactive", _rats([0]), String[]),
        FixtureStrategy("bridge", _rats([0]), ["key"]),
        FixtureStrategy("candidate", _rats([2]), String[]),
    ]
    libraries = [
        FixtureLibrary("baseline", ["inactive"]),
        FixtureLibrary("inserted", ["inactive", "bridge"]),
    ]
    projects = [
        FixtureProject(
            "innovate",
            _rats([0]),
            1,
            _rat(1),
            false,
            ["key"],
            ["candidate"],
        ),
    ]
    seed = _base_fixture(
        "operational_generative_decomposition",
        "T5 operational-generative decomposition",
        beliefs,
        _rats(reshape([1], 1, 1)),
        1 // 2,
        ["key"],
        strategies,
        libraries,
        projects,
        _blank_expected(),
    )
    context = _context(seed)
    passive_baseline =
        frontier(context.catalog, context.libraries["baseline"]).values[1]
    passive_inserted =
        frontier(context.catalog, context.libraries["inserted"]).values[1]
    full_baseline = passive_baseline
    full_inserted =
        passive_inserted +
        seed.discount *
        operational_profile(context.catalog, StrategyId(:candidate)).values[1]
    total = full_inserted - full_baseline
    operational = passive_inserted - passive_baseline
    generative = total - operational
    expected = FixtureExpected(
        [
            "full_baseline" => full_baseline,
            "full_inserted" => full_inserted,
            "generative_component" => generative,
            "operational_component" => operational,
            "passive_baseline" => passive_baseline,
            "passive_inserted" => passive_inserted,
            "total_increment" => total,
        ],
        Pair{String,Vector{ExactRational}}[],
        [
            "decomposition_identity" =>
                (total == operational + generative),
            "generative_component_positive" => (generative > 0),
        ],
        Pair{String,Vector{Bool}}[],
        Pair{String,Vector{String}}[],
    )
    return _base_fixture(
        "operational_generative_decomposition",
        "T5 operational-generative decomposition",
        beliefs,
        _rats(reshape([1], 1, 1)),
        1 // 2,
        ["key"],
        strategies,
        libraries,
        projects,
        expected,
    )
end

function _generative_lower_bound_fixture()
    witness = generative_lower_bound_fixture()
    expected = FixtureExpected(
        [
            "admission_probability" => witness.admission_probability,
            "expected_completion_gain" => witness.expected_completion_gain,
            "lower_bound" => witness.lower_bound,
            "operating_adjustment" => witness.operating_adjustment,
            "research_cost" => witness.research_cost,
            "survival_factor" => witness.survival_factor,
        ],
        [
            "completion_gains" => witness.completion_gains,
            "occupation_weights" => witness.occupation_weights,
        ],
        ["lower_bound_positive" => (witness.lower_bound > 0)],
        Pair{String,Vector{Bool}}[],
        Pair{String,Vector{String}}[],
    )
    return _base_fixture(
        "generative_lower_bound",
        "T6 retained-carrier generative lower bound",
        ["only"],
        _rats(reshape([1], 1, 1)),
        witness.discount,
        ["key"],
        [
            FixtureStrategy("inactive", _rats([0]), String[]),
            FixtureStrategy("bridge", _rats([0]), ["key"]),
            FixtureStrategy(
                "candidate",
                _rats(witness.completion_gains),
                String[],
            ),
        ],
        [FixtureLibrary("current", ["inactive", "bridge"])],
        [
            FixtureProject(
                "innovate",
                _rats([witness.research_cost]),
                witness.duration,
                witness.survival_factor,
                false,
                ["key"],
                ["candidate"],
            ),
        ],
        expected,
    )
end

function _discount_survival_fixture()
    beliefs = ["low", "high"]
    transition = _rats([3 // 4 1 // 4; 1 // 2 1 // 2])
    seed = _base_fixture(
        "discount_survival_complementarity",
        "S6 discount-survival complementarity",
        beliefs,
        transition,
        3 // 4,
        ["marker"],
        [
            FixtureStrategy("inactive", _rats([0, 0]), String[]),
            FixtureStrategy("candidate", _rats([1, 3]), ["marker"]),
        ],
        [FixtureLibrary("current", ["inactive"])],
        [
            FixtureProject(
                "innovate",
                _rats([0, 0]),
                1,
                _rat(2 // 3),
                false,
                String[],
                ["candidate"],
            ),
        ],
        _blank_expected(),
    )
    context = _context(seed)
    interaction = finite_discount_survival_interaction(
        context.kernel,
        ExactRational[1, 3],
        1 // 4,
        3 // 4,
        1 // 3,
        2 // 3,
        5,
    )
    expected = FixtureExpected(
        [
            "beta_high" => _rat(3 // 4),
            "beta_low" => _rat(1 // 4),
            "horizon" => _rat(5),
            "survival_high" => _rat(2 // 3),
            "survival_low" => _rat(1 // 3),
        ],
        [
            "cross_difference" => interaction.cross_difference,
            "factorized_cross_difference" =>
                interaction.factorized_cross_difference,
            "potential_high_beta_high_survival" => interaction.potential11,
            "potential_high_beta_low_survival" => interaction.potential10,
            "potential_low_beta_high_survival" => interaction.potential01,
            "potential_low_beta_low_survival" => interaction.potential00,
        ],
        [
            "cross_difference_nonnegative" =>
                all(interaction.cross_difference .>= 0),
            "factorization_holds" => interaction.factorization_holds,
        ],
        Pair{String,Vector{Bool}}[],
        Pair{String,Vector{String}}[],
    )
    return _base_fixture(
        seed.fixture_id,
        seed.theorem_family,
        seed.beliefs,
        seed.transition_rows,
        seed.discount,
        seed.modules,
        seed.strategies,
        seed.libraries,
        seed.projects,
        expected,
    )
end

function _persistence_fixture(increases::Bool)
    fixture_id = increases ? "persistence_increases_coverage" :
                 "persistence_decreases_coverage"
    theorem_family = increases ?
                     "S7 persistence-increases-coverage example" :
                     "S7 persistence-decreases-coverage example"
    gap = increases ? ExactRational[1, 0] : ExactRational[0, 1]
    beliefs = ["current", "other"]
    transition = _rats([0 1; 1 0])
    seed = _base_fixture(
        fixture_id,
        theorem_family,
        beliefs,
        transition,
        1 // 2,
        ["marker"],
        [
            FixtureStrategy("inactive", _rats([0, 0]), String[]),
            FixtureStrategy("candidate", gap, ["marker"]),
        ],
        [FixtureLibrary("current", ["inactive"])],
        [
            FixtureProject(
                "innovate",
                _rats([0, 0]),
                1,
                _rat(1),
                false,
                String[],
                ["candidate"],
            ),
        ],
        _blank_expected(),
    )
    context = _context(seed)
    rows = persistence_coverage_response_surface(
        context.kernel,
        gap,
        ExactRational[1 // 4, 3 // 4],
        ExactRational[1 // 2],
        2,
    )
    low = rows[1].coverage
    high = rows[2].coverage
    expected = FixtureExpected(
        [
            "coverage_high_persistence" => high,
            "coverage_low_persistence" => low,
            "effective_discount" => _rat(1 // 2),
            "persistence_high" => _rat(3 // 4),
            "persistence_low" => _rat(1 // 4),
        ],
        ["gap" => gap],
        [
            "coverage_increases" => (high > low),
            "coverage_decreases" => (high < low),
        ],
        Pair{String,Vector{Bool}}[],
        Pair{String,Vector{String}}[],
    )
    return _base_fixture(
        seed.fixture_id,
        seed.theorem_family,
        seed.beliefs,
        seed.transition_rows,
        seed.discount,
        seed.modules,
        seed.strategies,
        seed.libraries,
        seed.projects,
        expected,
    )
end

function _frontier_closure_fixture(complements::Bool)
    surface = frontier_closure_interaction_surface(
        ExactRational[0, 2, 8],
        ExactRational[4, 10],
        ExactRational[0, 1 // 2, 1],
        ExactRational[0, 1 // 2, 1],
        ExactRational[0, 2],
        ExactRational[0, 2];
        discount = _rat(1 // 2),
    )
    row = if complements
        only(
            candidate for candidate in surface if
            candidate.frontier0 == 0 &&
            candidate.frontier1 == 8 &&
            candidate.candidate == 10 &&
            candidate.old_success == 1 &&
            candidate.added_success == 1 // 2 &&
            candidate.old_cost == 2 &&
            candidate.added_cost == 0
        )
    else
        only(
            candidate for candidate in surface if
            candidate.frontier0 == 0 &&
            candidate.frontier1 == 2 &&
            candidate.candidate == 4 &&
            candidate.old_success == 0 &&
            candidate.added_success == 1 &&
            candidate.old_cost == 0 &&
            candidate.added_cost == 0
        )
    end
    fixture_id = complements ? "frontier_closure_complementarity" :
                 "frontier_closure_substitution"
    theorem_family = complements ?
                     "T7 frontier-closure complementarity boundary" :
                     "T7 frontier-closure substitution"
    expected = FixtureExpected(
        [
            "added_cost" => row.added_cost,
            "added_success" => row.added_success,
            "candidate_quality" => row.candidate,
            "closure_increment_high_frontier" => row.closure_increment1,
            "closure_increment_low_frontier" => row.closure_increment0,
            "cross_difference" => row.interaction,
            "frontier_high" => row.frontier1,
            "frontier_low" => row.frontier0,
            "old_cost" => row.old_cost,
            "old_success" => row.old_success,
        ],
        Pair{String,Vector{ExactRational}}[],
        [
            "is_complementarity" => (row.interaction > 0),
            "is_substitution" => (row.interaction < 0),
        ],
        Pair{String,Vector{Bool}}[],
        Pair{String,Vector{String}}[],
    )
    return _base_fixture(
        fixture_id,
        theorem_family,
        ["only"],
        _rats(reshape([1], 1, 1)),
        1 // 2,
        ["old", "added"],
        [
            FixtureStrategy("inactive", _rats([0]), String[]),
            FixtureStrategy("frontier_high", _rats([row.frontier1]), String[]),
            FixtureStrategy("candidate", _rats([row.candidate]), String[]),
        ],
        [
            FixtureLibrary("frontier_low", ["inactive"]),
            FixtureLibrary(
                "frontier_high",
                ["inactive", "frontier_high"],
            ),
        ],
        [
            FixtureProject(
                "old_project",
                _rats([row.old_cost]),
                1,
                row.old_success,
                false,
                ["old"],
                ["candidate"],
            ),
            FixtureProject(
                "added_project",
                _rats([row.added_cost]),
                1,
                row.added_success,
                false,
                ["added"],
                ["candidate"],
            ),
        ],
        expected,
    )
end

function _monotone_gap_threshold_fixture()
    beliefs = ["b1", "b2", "b3", "b4"]
    gap = _rats([0, 1 // 2, 3 // 2, 3])
    costs = _rats([2, 1, 1 // 2, 0])
    transition = _rats([
        row == column ? 1 : 0 for row in 1:4, column in 1:4
    ])
    seed = _base_fixture(
        "monotone_gap_threshold",
        "S5 monotone-gap threshold",
        beliefs,
        transition,
        1,
        ["marker"],
        [
            FixtureStrategy("inactive", _rats([0, 0, 0, 0]), String[]),
            FixtureStrategy("candidate", gap, ["marker"]),
        ],
        [FixtureLibrary("current", ["inactive"])],
        [
            FixtureProject(
                "innovate",
                costs,
                1,
                _rat(1),
                false,
                String[],
                ["candidate"],
            ),
        ],
        _blank_expected(),
    )
    context = _context(seed)
    potential = gross_coverage_value(context.kernel, gap, seed.discount)
    region = collect(research_region(potential, costs))
    expected = FixtureExpected(
        [
            "connected_components" => _rat(component_count(region)),
            "threshold_cutoff_index" => _rat(findfirst(region)),
        ],
        [
            "candidate_gap" => gap,
            "coverage_potential" => potential,
            "research_cost" => costs,
        ],
        [
            "cost_antitone" => is_antitone_sequence(costs),
            "gap_monotone" => is_monotone_sequence(gap),
            "kernel_stochastically_monotone" =>
                is_stochastically_monotone(context.kernel),
            "upper_threshold" => (region == [false, false, true, true]),
        ],
        ["research_region" => region],
        Pair{String,Vector{String}}[],
    )
    return _base_fixture(
        seed.fixture_id,
        seed.theorem_family,
        seed.beliefs,
        seed.transition_rows,
        seed.discount,
        seed.modules,
        seed.strategies,
        seed.libraries,
        seed.projects,
        expected,
    )
end

function _legacy_frontier_pruning_fixture()
    beliefs = ["only"]
    strategies = [
        FixtureStrategy("inactive", _rats([0]), String[]),
        FixtureStrategy("bridge", _rats([0]), ["key"]),
        FixtureStrategy("future", _rats([10]), String[]),
    ]
    libraries = [
        FixtureLibrary("pruned", ["inactive"]),
        FixtureLibrary("unpruned", ["inactive", "bridge"]),
    ]
    projects = [
        FixtureProject(
            "innovate",
            _rats([0]),
            1,
            _rat(1),
            false,
            ["key"],
            ["future"],
        ),
    ]
    seed = _base_fixture(
        "frontier_pruning_loss",
        "F4 arbitrary frontier-pruning loss compatibility fixture",
        beliefs,
        _rats(reshape([1], 1, 1)),
        1 // 2,
        ["key"],
        strategies,
        libraries,
        projects,
        _blank_expected(),
    )
    context = _context(seed)
    unpruned = context.libraries["unpruned"]
    pruned = context.libraries["pruned"]
    reward =
        operational_profile(context.catalog, StrategyId(:future)).values[1]
    retained = seed.discount * reward
    lost = zero(ExactRational)
    expected = FixtureExpected(
        [
            "pruned_research_value" => lost,
            "research_value_loss" => retained - lost,
            "unpruned_research_value" => retained,
        ],
        [
            "frontier_pruned" =>
                collect(frontier(context.catalog, pruned).values),
            "frontier_unpruned" =>
                collect(frontier(context.catalog, unpruned).values),
        ],
        [
            "frontier_preserved" =>
                (frontier(context.catalog, pruned) ==
                 frontier(context.catalog, unpruned)),
            "generative_closure_preserved" =>
                (generative_closure(
                    context.catalog,
                    context.closure,
                    pruned,
                ) ==
                 generative_closure(
                    context.catalog,
                    context.closure,
                    unpruned,
                )),
            "loss_positive" => (retained - lost > 0),
        ],
        Pair{String,Vector{Bool}}[],
        [
            "modules_pruned" => String[],
            "modules_unpruned" => ["key"],
        ],
    )
    return _base_fixture(
        seed.fixture_id,
        seed.theorem_family,
        seed.beliefs,
        seed.transition_rows,
        seed.discount,
        seed.modules,
        seed.strategies,
        seed.libraries,
        seed.projects,
        expected,
    )
end

function _legacy_innovation_equation_fixture()
    beliefs = ["current", "future"]
    strategies = [
        FixtureStrategy("inactive", _rats([0, 0]), String[]),
        FixtureStrategy("candidate", _rats([1, 2]), ["marker"]),
    ]
    libraries = [FixtureLibrary("current", ["inactive"])]
    projects = [
        FixtureProject(
            "innovate",
            _rats([0, 0]),
            1,
            _rat(1),
            false,
            String[],
            ["candidate"],
        ),
    ]
    seed = _base_fixture(
        "strategy_innovation_equation",
        "S4 Strategy Innovation Equation compatibility fixture",
        beliefs,
        _rats([0 1; 0 1]),
        1 // 2,
        ["marker"],
        strategies,
        libraries,
        projects,
        _blank_expected(),
    )
    context = _context(seed)
    gap = collect(
        candidate_gap(
            operational_profile(context.catalog, StrategyId(:candidate)),
            frontier(context.catalog, context.libraries["current"]),
        ).values,
    )
    potential =
        finite_coverage_potential(context.kernel, gap, seed.discount, 3)
    expected = FixtureExpected(
        ["initial_innovation_value" => potential[1]],
        [
            "candidate_gap" => gap,
            "discounted_gap_sum_horizon_three" => potential,
        ],
        ["innovation_equation_identity" => (potential[1] == 5 // 2)],
        Pair{String,Vector{Bool}}[],
        Pair{String,Vector{String}}[],
    )
    return _base_fixture(
        seed.fixture_id,
        seed.theorem_family,
        seed.beliefs,
        seed.transition_rows,
        seed.discount,
        seed.modules,
        seed.strategies,
        seed.libraries,
        seed.projects,
        expected,
    )
end

function _legacy_delayed_innovation_fixture()
    beliefs = ["current", "future"]
    strategies = [
        FixtureStrategy("inactive", _rats([0, 0]), String[]),
        FixtureStrategy("candidate", _rats([0, 2]), ["marker"]),
    ]
    libraries = [FixtureLibrary("current", ["inactive"])]
    projects = [
        FixtureProject(
            "innovate",
            _rats([0, 0]),
            1,
            _rat(1),
            false,
            String[],
            ["candidate"],
        ),
    ]
    seed = _base_fixture(
        "current_zero_future_positive",
        "F7 current-zero future-positive compatibility fixture",
        beliefs,
        _rats([0 1; 0 1]),
        1 // 2,
        ["marker"],
        strategies,
        libraries,
        projects,
        _blank_expected(),
    )
    context = _context(seed)
    gap = collect(
        candidate_gap(
            operational_profile(context.catalog, StrategyId(:candidate)),
            frontier(context.catalog, context.libraries["current"]),
        ).values,
    )
    potential =
        finite_coverage_potential(context.kernel, gap, seed.discount, 2)
    expected = FixtureExpected(
        [
            "current_gap" => gap[1],
            "future_gap" => gap[2],
            "initial_innovation_value" => potential[1],
        ],
        [
            "candidate_gap" => gap,
            "discounted_gap_sum_horizon_two" => potential,
        ],
        [
            "current_gap_zero" => iszero(gap[1]),
            "future_gap_positive" => (gap[2] > 0),
            "innovation_value_positive" => (potential[1] > 0),
        ],
        Pair{String,Vector{Bool}}[],
        Pair{String,Vector{String}}[],
    )
    return _base_fixture(
        seed.fixture_id,
        seed.theorem_family,
        seed.beliefs,
        seed.transition_rows,
        seed.discount,
        seed.modules,
        seed.strategies,
        seed.libraries,
        seed.projects,
        expected,
    )
end

function _legacy_single_gap_fixture()
    beliefs = ["left", "middle", "right"]
    strategies = [
        FixtureStrategy("inactive", _rats([0, 0, 0]), String[]),
        FixtureStrategy("candidate", _rats([0, 1, 0]), ["marker"]),
    ]
    libraries = [FixtureLibrary("current", ["inactive"])]
    projects = [
        FixtureProject(
            "innovate",
            _rats([1 // 2, 1 // 2, 1 // 2]),
            1,
            _rat(1),
            false,
            String[],
            ["candidate"],
        ),
    ]
    seed = _base_fixture(
        "single_gap_research_region",
        "S5 destructive-kernel compatibility fixture",
        beliefs,
        _rats([0 1 0; 1 0 0; 0 1 0]),
        1,
        ["marker"],
        strategies,
        libraries,
        projects,
        _blank_expected(),
    )
    context = _context(seed)
    gap = collect(
        candidate_gap(
            operational_profile(context.catalog, StrategyId(:candidate)),
            frontier(context.catalog, context.libraries["current"]),
        ).values,
    )
    potential = gross_coverage_value(context.kernel, gap, seed.discount)
    region = collect(research_region(potential, projects[1].cost))
    expected = FixtureExpected(
        ["connected_components" => _rat(component_count(region))],
        ["candidate_gap" => gap, "coverage_potential" => potential],
        [
            "kernel_stochastically_monotone" =>
                is_stochastically_monotone(context.kernel),
            "region_disconnected" => (component_count(region) > 1),
        ],
        ["research_region" => region],
        Pair{String,Vector{String}}[],
    )
    return _base_fixture(
        seed.fixture_id,
        seed.theorem_family,
        seed.beliefs,
        seed.transition_rows,
        seed.discount,
        seed.modules,
        seed.strategies,
        seed.libraries,
        seed.projects,
        expected,
    )
end

function _multi_gap_fixture()
    beliefs = ["b0", "b1", "b2", "b3", "b4"]
    strategies = [
        FixtureStrategy("inactive", _rats(zeros(Int, 5)), String[]),
        FixtureStrategy("left_candidate", _rats([4, 0, 0, 0, 0]), ["marker"]),
        FixtureStrategy("right_candidate", _rats([0, 0, 0, 0, 4]), ["marker"]),
    ]
    libraries = [FixtureLibrary("current", ["inactive"])]
    projects = [FixtureProject("innovate", _rats(ones(Int, 5)), 1, _rat(1), true, String[], ["left_candidate", "right_candidate"])]
    transition = _rats([
        1 0 0 0 0
        81 // 256 108 // 256 54 // 256 12 // 256 1 // 256
        1 // 16 4 // 16 6 // 16 4 // 16 1 // 16
        1 // 256 12 // 256 54 // 256 108 // 256 81 // 256
        0 0 0 0 1
    ])
    seed = _base_fixture("multi_gap_disconnection", "C2 multi-gap disconnection", beliefs, transition, 1, ["marker"], strategies, libraries, projects, _blank_expected())
    context = _context(seed)
    current_frontier = frontier(context.catalog, context.libraries["current"])
    left_gap = collect(candidate_gap(operational_profile(context.catalog, StrategyId(:left_candidate)), current_frontier).values)
    right_gap = collect(candidate_gap(operational_profile(context.catalog, StrategyId(:right_candidate)), current_frontier).values)
    aggregate_gap = collect(project_gap([
        operational_profile(context.catalog, StrategyId(:left_candidate)),
        operational_profile(context.catalog, StrategyId(:right_candidate)),
    ], current_frontier).values)
    potential = gross_coverage_value(context.kernel, aggregate_gap, seed.discount)
    region = collect(research_region(potential, projects[1].cost; strict = true))
    expected = FixtureExpected(
        ["connected_components" => _rat(component_count(region))],
        ["aggregate_gap" => aggregate_gap, "coverage_potential" => potential, "left_gap" => left_gap, "right_gap" => right_gap],
        ["region_disconnected" => (component_count(region) > 1)],
        ["research_region" => region],
        Pair{String,Vector{String}}[],
    )
    return _base_fixture("multi_gap_disconnection", "C2 multi-gap disconnection", beliefs, transition, 1, ["marker"], strategies, libraries, projects, expected)
end

function _legacy_multi_gap_fixture()
    current = _multi_gap_fixture()
    return _base_fixture(
        "multi_gap_disconnected_region",
        "C2 disconnected-region compatibility fixture",
        current.beliefs,
        current.transition_rows,
        current.discount,
        current.modules,
        current.strategies,
        current.libraries,
        current.projects,
        current.expected,
    )
end

"""
Build the thirteen requested exact bridge fixtures plus five retained
compatibility fixtures in deterministic fixture-ID order.
"""
function build_exact_fixtures()
    fixtures = [
        _raw_compressed_transition_fixture(),
        _raw_compressed_value_fixture(),
        _safe_deletion_fixture(),
        _normalized_pruning_loss_fixture(),
        _decomposition_fixture(),
        _generative_lower_bound_fixture(),
        _discount_survival_fixture(),
        _persistence_fixture(true),
        _persistence_fixture(false),
        _frontier_closure_fixture(false),
        _frontier_closure_fixture(true),
        _monotone_gap_threshold_fixture(),
        _multi_gap_fixture(),
        _legacy_frontier_pruning_fixture(),
        _legacy_innovation_equation_fixture(),
        _legacy_delayed_innovation_fixture(),
        _legacy_single_gap_fixture(),
        _legacy_multi_gap_fixture(),
    ]
    sort!(fixtures; by = fixture -> fixture.fixture_id)
    return fixtures
end

_rational_token(value::ExactRational) = "$(numerator(value))//$(denominator(value))"

function _json_string(value::AbstractString)
    escaped = replace(value, '\\' => "\\\\", '"' => "\\\"", '\n' => "\\n", '\r' => "\\r", '\t' => "\\t")
    return "\"$escaped\""
end

_json_bool(value::Bool) = value ? "true" : "false"
_indent(level) = repeat("  ", level)

function _json_array(values, render; level = 0, inline = false)
    isempty(values) && return "[]"
    if inline
        return "[" * join((render(value) for value in values), ", ") * "]"
    end
    inner = join((_indent(level + 1) * render(value) for value in values), ",\n")
    return "[\n$inner\n$(_indent(level))]"
end

function _json_object(fields::Vector{Pair{String,String}}; level = 0)
    inner = join((_indent(level + 1) * _json_string(key) * ": " * value for (key, value) in fields), ",\n")
    return "{\n$inner\n$(_indent(level))}"
end

function _expected_json(expected::FixtureExpected, level::Int)
    rational_scalars = _json_array(expected.rational_scalars, pair -> _json_object([
        "id" => _json_string(first(pair)), "value" => _json_string(_rational_token(last(pair))),
    ]; level = level + 1); level = level)
    rational_vectors = _json_array(expected.rational_vectors, pair -> _json_object([
        "id" => _json_string(first(pair)),
        "values" => _json_array(last(pair), value -> _json_string(_rational_token(value)); inline = true),
    ]; level = level + 1); level = level)
    boolean_scalars = _json_array(expected.boolean_scalars, pair -> _json_object([
        "id" => _json_string(first(pair)), "value" => _json_bool(last(pair)),
    ]; level = level + 1); level = level)
    boolean_vectors = _json_array(expected.boolean_vectors, pair -> _json_object([
        "id" => _json_string(first(pair)),
        "values" => _json_array(last(pair), _json_bool; inline = true),
    ]; level = level + 1); level = level)
    string_vectors = _json_array(expected.string_vectors, pair -> _json_object([
        "id" => _json_string(first(pair)),
        "values" => _json_array(last(pair), _json_string; inline = true),
    ]; level = level + 1); level = level)
    return _json_object([
        "rational_scalars" => rational_scalars,
        "rational_vectors" => rational_vectors,
        "boolean_scalars" => boolean_scalars,
        "boolean_vectors" => boolean_vectors,
        "string_vectors" => string_vectors,
    ]; level)
end

"""Render one fixture as deterministic, dependency-free, canonical JSON."""
function render_fixture_json(fixture::ExactBridgeFixture)
    validate_fixture(fixture)
    rows = _json_array(eachrow(fixture.transition_rows), row -> _json_array(collect(row), value -> _json_string(_rational_token(value)); inline = true); level = 1)
    strategies = _json_array(fixture.strategies, row -> _json_object([
        "id" => _json_string(row.id),
        "operational_profile" => _json_array(row.operational_profile, value -> _json_string(_rational_token(value)); inline = true),
        "modules" => _json_array(row.modules, _json_string; inline = true),
    ]; level = 2); level = 1)
    libraries = _json_array(fixture.libraries, row -> _json_object([
        "id" => _json_string(row.id),
        "strategies" => _json_array(row.strategies, _json_string; inline = true),
    ]; level = 2); level = 1)
    projects = _json_array(fixture.projects, row -> _json_object([
        "id" => _json_string(row.id),
        "cost" => _json_array(row.cost, value -> _json_string(_rational_token(value)); inline = true),
        "duration" => string(row.duration),
        "survival" => _json_string(_rational_token(row.survival)),
        "strict_cost" => _json_bool(row.strict_cost),
        "required_modules" => _json_array(row.required_modules, _json_string; inline = true),
        "candidate_strategies" => _json_array(row.candidate_strategies, _json_string; inline = true),
    ]; level = 2); level = 1)
    return _json_object([
        "schema_version" => _json_string(fixture.schema_version),
        "fixture_id" => _json_string(fixture.fixture_id),
        "theorem_family" => _json_string(fixture.theorem_family),
        "beliefs" => _json_array(fixture.beliefs, _json_string; inline = true),
        "transition_rows" => rows,
        "discount" => _json_string(_rational_token(fixture.discount)),
        "modules" => _json_array(fixture.modules, _json_string; inline = true),
        "strategies" => strategies,
        "libraries" => libraries,
        "projects" => projects,
        "expected" => _expected_json(fixture.expected, 1),
    ]) * "\n"
end

_lean_string(value::AbstractString) = _json_string(value)
_lean_rat(value::ExactRational) = denominator(value) == 1 ? string(numerator(value)) : "($(numerator(value)) / $(denominator(value)) : ℚ)"
_lean_bool(value::Bool) = value ? "true" : "false"
_lean_list(values, render) = "[" * join((render(value) for value in values), ", ") * "]"

function _lean_fixture(fixture::ExactBridgeFixture)
    strategies = _lean_list(fixture.strategies, row ->
        "ExactStrategy.mk $(_lean_string(row.id)) $(_lean_list(row.operational_profile, _lean_rat)) $(_lean_list(row.modules, _lean_string))")
    libraries = _lean_list(fixture.libraries, row ->
        "ExactLibrary.mk $(_lean_string(row.id)) $(_lean_list(row.strategies, _lean_string))")
    projects = _lean_list(fixture.projects, row ->
        "ExactProject.mk $(_lean_string(row.id)) $(_lean_list(row.cost, _lean_rat)) $(row.duration) $(_lean_rat(row.survival)) $(_lean_bool(row.strict_cost)) $(_lean_list(row.required_modules, _lean_string)) $(_lean_list(row.candidate_strategies, _lean_string))")
    expected = fixture.expected
    rational_scalars = _lean_list(expected.rational_scalars, pair -> "($(_lean_string(first(pair))), $(_lean_rat(last(pair))))")
    rational_vectors = _lean_list(expected.rational_vectors, pair -> "($(_lean_string(first(pair))), $(_lean_list(last(pair), _lean_rat)))")
    boolean_scalars = _lean_list(expected.boolean_scalars, pair -> "($(_lean_string(first(pair))), $(_lean_bool(last(pair))))")
    boolean_vectors = _lean_list(expected.boolean_vectors, pair -> "($(_lean_string(first(pair))), $(_lean_list(last(pair), _lean_bool)))")
    string_vectors = _lean_list(expected.string_vectors, pair -> "($(_lean_string(first(pair))), $(_lean_list(last(pair), _lean_string)))")
    transition = _lean_list(eachrow(fixture.transition_rows), row -> _lean_list(collect(row), _lean_rat))
    return """ExactFixture.mk
    $(_lean_string(fixture.schema_version))
    $(_lean_string(fixture.fixture_id))
    $(_lean_string(fixture.theorem_family))
    $(_lean_list(fixture.beliefs, _lean_string))
    $transition
    $(_lean_rat(fixture.discount))
    $(_lean_list(fixture.modules, _lean_string))
    $strategies
    $libraries
    $projects
    (ExactExpected.mk
      $rational_scalars
      $rational_vectors
      $boolean_scalars
      $boolean_vectors
      $string_vectors)"""
end

const _LEAN_PREAMBLE = """import Mathlib.Data.Rat.Defs
import Mathlib.Tactic.NormNum

/-!
# Generated exact Lean–Julia consistency fixtures

This file is generated by `julia/scripts/export_exact_fixtures.jl` from the
same validated exact Julia objects that produce `shared/exact_fixtures/*.json`.
The examples below are kernel-checked fixture calculations. They establish
implementation agreement on these finite instances, not the corresponding
general mathematical theorems.
-/

namespace StrategyInnovation.Fixtures.Generated

set_option linter.unnecessarySeqFocus false
set_option linter.unreachableTactic false
set_option linter.unusedSimpArgs false
set_option linter.unusedTactic false

structure ExactStrategy where
  id : String
  operationalProfile : List ℚ
  modules : List String
  deriving Repr, DecidableEq

structure ExactLibrary where
  id : String
  strategies : List String
  deriving Repr, DecidableEq

structure ExactProject where
  id : String
  cost : List ℚ
  duration : Nat
  survival : ℚ
  strictCost : Bool
  requiredModules : List String
  candidateStrategies : List String
  deriving Repr, DecidableEq

structure ExactExpected where
  rationalScalars : List (String × ℚ)
  rationalVectors : List (String × List ℚ)
  booleanScalars : List (String × Bool)
  booleanVectors : List (String × List Bool)
  stringVectors : List (String × List String)
  deriving Repr, DecidableEq

structure ExactFixture where
  schemaVersion : String
  fixtureId : String
  theoremFamily : String
  beliefs : List String
  transitionRows : List (List ℚ)
  discount : ℚ
  modules : List String
  strategies : List ExactStrategy
  libraries : List ExactLibrary
  projects : List ExactProject
  expected : ExactExpected
  deriving Repr, DecidableEq

def lookupStrategy : List ExactStrategy → String → Option ExactStrategy
  | [], _ => none
  | row :: rows, id => if row.id = id then some row else lookupStrategy rows id

def lookupLibrary : List ExactLibrary → String → Option ExactLibrary
  | [], _ => none
  | row :: rows, id => if row.id = id then some row else lookupLibrary rows id

def lookupProject : List ExactProject → String → Option ExactProject
  | [], _ => none
  | row :: rows, id => if row.id = id then some row else lookupProject rows id

@[simp] def lookupRationalScalar : List (String × ℚ) → String → ℚ
  | [], _ => 0
  | row :: rows, id => if row.1 = id then row.2 else lookupRationalScalar rows id

@[simp] def lookupRationalVector : List (String × List ℚ) → String → List ℚ
  | [], _ => []
  | row :: rows, id => if row.1 = id then row.2 else lookupRationalVector rows id

@[simp] def lookupBooleanVector : List (String × List Bool) → String → List Bool
  | [], _ => []
  | row :: rows, id => if row.1 = id then row.2 else lookupBooleanVector rows id

def expectedRationalScalar (fixture : ExactFixture) (id : String) : ℚ :=
  lookupRationalScalar fixture.expected.rationalScalars id

def expectedRationalVector (fixture : ExactFixture) (id : String) : List ℚ :=
  lookupRationalVector fixture.expected.rationalVectors id

def expectedBooleanVector (fixture : ExactFixture) (id : String) : List Bool :=
  lookupBooleanVector fixture.expected.booleanVectors id

def atOr (values : List ℚ) (index : Nat) : ℚ := values.getD index 0

def profileAt (fixture : ExactFixture) (strategyId : String) (belief : Nat) : ℚ :=
  match lookupStrategy fixture.strategies strategyId with
  | none => 0
  | some row => atOr row.operationalProfile belief

def libraryStrategies (fixture : ExactFixture) (libraryId : String) : List String :=
  match lookupLibrary fixture.libraries libraryId with
  | none => []
  | some row => row.strategies

def frontierAt (fixture : ExactFixture) (libraryId : String) (belief : Nat) : ℚ :=
  (libraryStrategies fixture libraryId).foldl
    (fun best strategyId => max best (profileAt fixture strategyId belief)) 0

@[simp] def frontierAux
    (fixture : ExactFixture) (libraryId : String) : List String → Nat → List ℚ
  | [], _ => []
  | _ :: beliefs, index =>
      frontierAt fixture libraryId index :: frontierAux fixture libraryId beliefs (index + 1)

def frontier (fixture : ExactFixture) (libraryId : String) : List ℚ :=
  frontierAux fixture libraryId fixture.beliefs 0

@[simp] def strategySupplies (fixture : ExactFixture) (strategyId moduleId : String) : Bool :=
  match lookupStrategy fixture.strategies strategyId with
  | none => false
  | some row => row.modules.contains moduleId

@[simp] def moduleSupplied (fixture : ExactFixture) (libraryId moduleId : String) : Bool :=
  (libraryStrategies fixture libraryId).any
    (fun strategyId => strategySupplies fixture strategyId moduleId)

@[simp] def projectAvailable (fixture : ExactFixture) (libraryId projectId : String) : Bool :=
  match lookupProject fixture.projects projectId with
  | none => false
  | some row => row.requiredModules.all (moduleSupplied fixture libraryId)

def candidateGapAt
    (fixture : ExactFixture) (libraryId candidateId : String) (belief : Nat) : ℚ :=
  max (profileAt fixture candidateId belief - frontierAt fixture libraryId belief) 0

@[simp] def candidateGapAux
    (fixture : ExactFixture) (libraryId candidateId : String) : List String → Nat → List ℚ
  | [], _ => []
  | _ :: beliefs, index =>
      candidateGapAt fixture libraryId candidateId index ::
        candidateGapAux fixture libraryId candidateId beliefs (index + 1)

def candidateGap (fixture : ExactFixture) (libraryId candidateId : String) : List ℚ :=
  candidateGapAux fixture libraryId candidateId fixture.beliefs 0

def projectGapAt
    (fixture : ExactFixture) (libraryId : String) (candidateIds : List String)
    (belief : Nat) : ℚ :=
  candidateIds.foldl
    (fun total candidateId => total + candidateGapAt fixture libraryId candidateId belief) 0

@[simp] def projectGapAux
    (fixture : ExactFixture) (libraryId : String) (candidateIds : List String) :
    List String → Nat → List ℚ
  | [], _ => []
  | _ :: beliefs, index =>
      projectGapAt fixture libraryId candidateIds index ::
        projectGapAux fixture libraryId candidateIds beliefs (index + 1)

def projectGap (fixture : ExactFixture) (libraryId projectId : String) : List ℚ :=
  match lookupProject fixture.projects projectId with
  | none => []
  | some row => projectGapAux fixture libraryId row.candidateStrategies fixture.beliefs 0

def dot : List ℚ → List ℚ → ℚ
  | x :: xs, y :: ys => x * y + dot xs ys
  | _, _ => 0

def matrixVector (matrix : List (List ℚ)) (values : List ℚ) : List ℚ :=
  matrix.map (fun row => dot row values)

def addVectors : List ℚ → List ℚ → List ℚ
  | x :: xs, y :: ys => (x + y) :: addVectors xs ys
  | _, _ => []

def subVectors : List ℚ → List ℚ → List ℚ
  | x :: xs, y :: ys => (x - y) :: subVectors xs ys
  | _, _ => []

def scaleVector (scale : ℚ) : List ℚ → List ℚ
  | [] => []
  | x :: xs => scale * x :: scaleVector scale xs

def grossCoverage (fixture : ExactFixture) (libraryId projectId : String) : List ℚ :=
  scaleVector fixture.discount
    (matrixVector fixture.transitionRows (projectGap fixture libraryId projectId))

def eligibleGrossCoverage
    (fixture : ExactFixture) (libraryId projectId : String) : List ℚ :=
  if projectAvailable fixture libraryId projectId then
    grossCoverage fixture libraryId projectId
  else
    List.replicate fixture.beliefs.length 0

def discountedGapSum
    (transition : List (List ℚ)) (discount : ℚ) : Nat → List ℚ → List ℚ
  | 0, gap => List.replicate gap.length 0
  | horizon + 1, gap =>
      addVectors gap (scaleVector discount
        (matrixVector transition (discountedGapSum transition discount horizon gap)))

def persistenceKernel (persistence : ℚ) : List (List ℚ) :=
  [[persistence, 1 - persistence], [1 - persistence, persistence]]

def oneProjectPremium
    (discount frontier success cost candidate : ℚ) : ℚ :=
  max (discount * success * max (candidate - frontier) 0 - cost) 0

def closureIncrement
    (discount frontier oldSuccess addedSuccess oldCost addedCost candidate : ℚ) : ℚ :=
  max
      (oneProjectPremium discount frontier oldSuccess oldCost candidate)
      (oneProjectPremium discount frontier addedSuccess addedCost candidate) -
    oneProjectPremium discount frontier oldSuccess oldCost candidate

def projectCost (fixture : ExactFixture) (projectId : String) : List ℚ :=
  match lookupProject fixture.projects projectId with
  | none => []
  | some row => row.cost

def weakRegion : List ℚ → List ℚ → List Bool
  | value :: values, cost :: costs => decide (cost ≤ value) :: weakRegion values costs
  | _, _ => []

def strictRegion : List ℚ → List ℚ → List Bool
  | value :: values, cost :: costs => decide (cost < value) :: strictRegion values costs
  | _, _ => []

def researchRegion (fixture : ExactFixture) (libraryId projectId : String) : List Bool :=
  match lookupProject fixture.projects projectId with
  | none => []
  | some row =>
      if row.strictCost then
        strictRegion (grossCoverage fixture libraryId projectId) row.cost
      else
        weakRegion (grossCoverage fixture libraryId projectId) row.cost

def componentCountAux : List Bool → Bool → Nat
  | [], _ => 0
  | value :: values, inside =>
      (if value && !inside then 1 else 0) + componentCountAux values value

def componentCount (region : List Bool) : Nat := componentCountAux region false

def passiveValue (fixture : ExactFixture) (libraryId : String) : ℚ :=
  frontierAt fixture libraryId 0

def fullValue (fixture : ExactFixture) (libraryId projectId : String) : ℚ :=
  passiveValue fixture libraryId + atOr (eligibleGrossCoverage fixture libraryId projectId) 0

"""

function _lean_fixture_section(fixture::ExactBridgeFixture)
    namespace_name = join(uppercasefirst.(split(fixture.fixture_id, '_')))
    record = replace(_lean_fixture(fixture), "\n" => "\n  ")
    bodies = Dict(
        "raw_compressed_transition_identity" => """
def rawMasses : List ℚ :=
  expectedRationalVector fixture "raw_projected_probabilities"
def compressedMasses : List ℚ :=
  expectedRationalVector fixture "compressed_probabilities"
def rawFrontiers : List ℚ :=
  expectedRationalVector fixture "raw_projected_terminal_frontiers"
def compressedFrontiers : List ℚ :=
  expectedRationalVector fixture "compressed_terminal_frontiers"
example : rawMasses = [(1 / 2 : ℚ), (1 / 2 : ℚ)] := by norm_num [rawMasses, expectedRationalVector, fixture]
example : rawMasses = compressedMasses := by norm_num [rawMasses, compressedMasses, expectedRationalVector, fixture]
example : rawFrontiers = compressedFrontiers := by norm_num [rawFrontiers, compressedFrontiers, expectedRationalVector, fixture]
""",
        "raw_compressed_value_equality" => """
def rawFiniteValues : List ℚ :=
  expectedRationalVector fixture "raw_finite_values_horizon_zero_to_five"
def compressedFiniteValues : List ℚ :=
  expectedRationalVector fixture "compressed_finite_values_horizon_zero_to_five"
def rawInfiniteValue : ℚ :=
  expectedRationalScalar fixture "raw_infinite_value"
def compressedInfiniteValue : ℚ :=
  expectedRationalScalar fixture "compressed_infinite_value"
example : rawFiniteValues = compressedFiniteValues := by norm_num [rawFiniteValues, compressedFiniteValues, expectedRationalVector, fixture]
example : rawInfiniteValue = compressedInfiniteValue := by norm_num [rawInfiniteValue, compressedInfiniteValue, expectedRationalScalar, fixture]
example : expectedRationalScalar fixture "raw_bellman_residual" = 0 := by norm_num [expectedRationalScalar, fixture]
example : expectedRationalScalar fixture "compressed_bellman_residual" = 0 := by norm_num [expectedRationalScalar, fixture]
""",
        "current_zero_future_positive" => """
def gap : List ℚ := candidateGap fixture "current" "candidate"
def innovationValue : List ℚ := discountedGapSum fixture.transitionRows fixture.discount 2 gap
example : gap = [0, 2] := by norm_num [gap, candidateGap, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupLibrary, lookupStrategy, atOr, fixture]
example : atOr gap 0 = 0 := by norm_num [gap, candidateGap, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupLibrary, lookupStrategy, atOr, fixture]
example : atOr gap 1 > 0 := by norm_num [gap, candidateGap, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupLibrary, lookupStrategy, atOr, fixture]
example : innovationValue = [1, 3] := by norm_num [innovationValue, discountedGapSum, gap, candidateGap, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupLibrary, lookupStrategy, matrixVector, dot, addVectors, scaleVector, atOr, fixture]
example : innovationValue = expectedRationalVector fixture "discounted_gap_sum_horizon_two" := by norm_num [expectedRationalVector, innovationValue, discountedGapSum, gap, candidateGap, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupLibrary, lookupStrategy, matrixVector, dot, addVectors, scaleVector, atOr, fixture]
""",
        "frontier_pruning_loss" => """
example : frontier fixture "unpruned" = frontier fixture "pruned" := by norm_num [frontier, frontierAt, libraryStrategies, profileAt, lookupLibrary, lookupStrategy, atOr, fixture]
example : moduleSupplied fixture "unpruned" "key" = true := by norm_num [moduleSupplied, libraryStrategies, strategySupplies, lookupLibrary, lookupStrategy, fixture]
example : moduleSupplied fixture "pruned" "key" = false := by norm_num [moduleSupplied, libraryStrategies, strategySupplies, lookupLibrary, lookupStrategy, fixture]
example : atOr (eligibleGrossCoverage fixture "unpruned" "innovate") 0 = 5 := by norm_num [eligibleGrossCoverage, projectAvailable, grossCoverage, projectGap, projectGapAt, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupProject, lookupLibrary, lookupStrategy, matrixVector, dot, scaleVector, atOr, fixture]
example : atOr (eligibleGrossCoverage fixture "pruned" "innovate") 0 = 0 := by norm_num [eligibleGrossCoverage, projectAvailable, libraryStrategies, strategySupplies, lookupProject, lookupLibrary, lookupStrategy, atOr, fixture]
example : atOr (eligibleGrossCoverage fixture "unpruned" "innovate") 0 = expectedRationalScalar fixture "unpruned_research_value" := by norm_num [expectedRationalScalar, eligibleGrossCoverage, projectAvailable, grossCoverage, projectGap, projectGapAt, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupProject, lookupLibrary, lookupStrategy, matrixVector, dot, scaleVector, atOr, fixture]
""",
        "safe_deletion" => """
example : frontier fixture "before" = [2, 1] := by norm_num [frontier, frontierAt, libraryStrategies, profileAt, lookupLibrary, lookupStrategy, atOr, fixture]
example : frontier fixture "after" = [2, 1] := by norm_num [frontier, frontierAt, libraryStrategies, profileAt, lookupLibrary, lookupStrategy, atOr, fixture]
example : moduleSupplied fixture "before" "signal" = true := by norm_num [moduleSupplied, libraryStrategies, strategySupplies, lookupLibrary, lookupStrategy, fixture]
example : moduleSupplied fixture "after" "signal" = true := by norm_num [moduleSupplied, libraryStrategies, strategySupplies, lookupLibrary, lookupStrategy, fixture]
example : frontier fixture "before" = expectedRationalVector fixture "frontier_before" := by norm_num [expectedRationalVector, frontier, frontierAt, libraryStrategies, profileAt, lookupLibrary, lookupStrategy, atOr, fixture]
""",
        "normalized_pruning_loss" => """
def lossFormula : ℚ :=
  max
    (fixture.discount *
      expectedRationalScalar fixture "admission_probability" *
      expectedRationalScalar fixture "reward_cap" -
      expectedRationalScalar fixture "research_cost")
    0
example : frontier fixture "unpruned" = frontier fixture "pruned" := by norm_num [frontier, frontierAt, libraryStrategies, profileAt, lookupLibrary, lookupStrategy, atOr, fixture]
example : moduleSupplied fixture "unpruned" "key" = true := by norm_num [moduleSupplied, libraryStrategies, strategySupplies, lookupLibrary, lookupStrategy, fixture]
example : moduleSupplied fixture "pruned" "key" = false := by norm_num [moduleSupplied, libraryStrategies, strategySupplies, lookupLibrary, lookupStrategy, fixture]
example : lossFormula = 1 := by norm_num [lossFormula, expectedRationalScalar, fixture]
example : lossFormula = expectedRationalScalar fixture "value_loss" := by norm_num [lossFormula, expectedRationalScalar, fixture]
example : expectedRationalScalar fixture "normalized_pruning_loss" = 1 := by norm_num [expectedRationalScalar, fixture]
""",
        "operational_generative_decomposition" => """
def totalIncrement : ℚ := fullValue fixture "inserted" "innovate" - fullValue fixture "baseline" "innovate"
def operationalComponent : ℚ := passiveValue fixture "inserted" - passiveValue fixture "baseline"
def generativeComponent : ℚ := totalIncrement - operationalComponent
example : totalIncrement = 1 := by norm_num [totalIncrement, fullValue, passiveValue, eligibleGrossCoverage, projectAvailable, grossCoverage, projectGap, projectGapAt, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupProject, lookupLibrary, lookupStrategy, matrixVector, dot, scaleVector, atOr, fixture]
example : operationalComponent = 0 := by norm_num [operationalComponent, passiveValue, frontierAt, libraryStrategies, profileAt, lookupLibrary, lookupStrategy, atOr, fixture]
example : generativeComponent = 1 := by norm_num [generativeComponent, totalIncrement, operationalComponent, fullValue, passiveValue, eligibleGrossCoverage, projectAvailable, grossCoverage, projectGap, projectGapAt, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupProject, lookupLibrary, lookupStrategy, matrixVector, dot, scaleVector, atOr, fixture]
example : totalIncrement = operationalComponent + generativeComponent := by norm_num [totalIncrement, operationalComponent, generativeComponent]
example : totalIncrement = expectedRationalScalar fixture "total_increment" := by norm_num [expectedRationalScalar, totalIncrement, fullValue, passiveValue, eligibleGrossCoverage, projectAvailable, grossCoverage, projectGap, projectGapAt, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupProject, lookupLibrary, lookupStrategy, matrixVector, dot, scaleVector, atOr, fixture]
""",
        "generative_lower_bound" => """
def lowerBoundFormula : ℚ :=
  max
    (-expectedRationalScalar fixture "research_cost" +
      expectedRationalScalar fixture "operating_adjustment" +
      fixture.discount *
      expectedRationalScalar fixture "admission_probability" *
      expectedRationalScalar fixture "survival_factor" *
      expectedRationalScalar fixture "expected_completion_gain")
    0
example : lowerBoundFormula = 1 := by norm_num [lowerBoundFormula, expectedRationalScalar, fixture]
example : lowerBoundFormula = expectedRationalScalar fixture "lower_bound" := by norm_num [lowerBoundFormula, expectedRationalScalar, fixture]
example : expectedRationalScalar fixture "lower_bound" > 0 := by norm_num [expectedRationalScalar, fixture]
""",
        "discount_survival_complementarity" => """
def gap : List ℚ := candidateGap fixture "current" "candidate"
def potential00 : List ℚ := discountedGapSum fixture.transitionRows ((1 / 4 : ℚ) * (1 / 3 : ℚ)) 5 gap
def potential10 : List ℚ := discountedGapSum fixture.transitionRows ((3 / 4 : ℚ) * (1 / 3 : ℚ)) 5 gap
def potential01 : List ℚ := discountedGapSum fixture.transitionRows ((1 / 4 : ℚ) * (2 / 3 : ℚ)) 5 gap
def potential11 : List ℚ := discountedGapSum fixture.transitionRows ((3 / 4 : ℚ) * (2 / 3 : ℚ)) 5 gap
def crossDifference : List ℚ :=
  subVectors (addVectors potential11 potential00) (addVectors potential10 potential01)
example : potential00 = expectedRationalVector fixture "potential_low_beta_low_survival" := by norm_num [potential00, gap, discountedGapSum, candidateGap, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupLibrary, lookupStrategy, matrixVector, dot, addVectors, scaleVector, atOr, expectedRationalVector, fixture]
example : potential11 = expectedRationalVector fixture "potential_high_beta_high_survival" := by norm_num [potential11, gap, discountedGapSum, candidateGap, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupLibrary, lookupStrategy, matrixVector, dot, addVectors, scaleVector, atOr, expectedRationalVector, fixture]
example : crossDifference = expectedRationalVector fixture "cross_difference" := by norm_num [crossDifference, potential00, potential10, potential01, potential11, gap, discountedGapSum, candidateGap, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupLibrary, lookupStrategy, matrixVector, dot, addVectors, subVectors, scaleVector, atOr, expectedRationalVector, fixture]
example : crossDifference = [(43771 / 55296 : ℚ), (24869 / 27648 : ℚ)] := by norm_num [crossDifference, potential00, potential10, potential01, potential11, gap, discountedGapSum, candidateGap, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupLibrary, lookupStrategy, matrixVector, dot, addVectors, subVectors, scaleVector, atOr, fixture]
""",
        "persistence_increases_coverage" => """
def gap : List ℚ := expectedRationalVector fixture "gap"
def lowCoverage : ℚ := atOr (discountedGapSum (persistenceKernel (1 / 4 : ℚ)) (1 / 2 : ℚ) 2 gap) 0
def highCoverage : ℚ := atOr (discountedGapSum (persistenceKernel (3 / 4 : ℚ)) (1 / 2 : ℚ) 2 gap) 0
example : lowCoverage = (9 / 8 : ℚ) := by norm_num [lowCoverage, gap, expectedRationalVector, discountedGapSum, persistenceKernel, matrixVector, dot, addVectors, scaleVector, atOr, fixture]
example : highCoverage = (11 / 8 : ℚ) := by norm_num [highCoverage, gap, expectedRationalVector, discountedGapSum, persistenceKernel, matrixVector, dot, addVectors, scaleVector, atOr, fixture]
example : lowCoverage < highCoverage := by norm_num [lowCoverage, highCoverage, gap, expectedRationalVector, discountedGapSum, persistenceKernel, matrixVector, dot, addVectors, scaleVector, atOr, fixture]
""",
        "persistence_decreases_coverage" => """
def gap : List ℚ := expectedRationalVector fixture "gap"
def lowCoverage : ℚ := atOr (discountedGapSum (persistenceKernel (1 / 4 : ℚ)) (1 / 2 : ℚ) 2 gap) 0
def highCoverage : ℚ := atOr (discountedGapSum (persistenceKernel (3 / 4 : ℚ)) (1 / 2 : ℚ) 2 gap) 0
example : lowCoverage = (3 / 8 : ℚ) := by norm_num [lowCoverage, gap, expectedRationalVector, discountedGapSum, persistenceKernel, matrixVector, dot, addVectors, scaleVector, atOr, fixture]
example : highCoverage = (1 / 8 : ℚ) := by norm_num [highCoverage, gap, expectedRationalVector, discountedGapSum, persistenceKernel, matrixVector, dot, addVectors, scaleVector, atOr, fixture]
example : highCoverage < lowCoverage := by norm_num [lowCoverage, highCoverage, gap, expectedRationalVector, discountedGapSum, persistenceKernel, matrixVector, dot, addVectors, scaleVector, atOr, fixture]
""",
        "frontier_closure_substitution" => """
def lowIncrement : ℚ := closureIncrement fixture.discount 0 0 1 0 0 4
def highIncrement : ℚ := closureIncrement fixture.discount 2 0 1 0 0 4
def interaction : ℚ := highIncrement - lowIncrement
example : lowIncrement = 2 := by norm_num [lowIncrement, closureIncrement, oneProjectPremium, fixture]
example : highIncrement = 1 := by norm_num [highIncrement, closureIncrement, oneProjectPremium, fixture]
example : interaction = -1 := by norm_num [interaction, lowIncrement, highIncrement, closureIncrement, oneProjectPremium, fixture]
example : interaction = expectedRationalScalar fixture "cross_difference" := by norm_num [interaction, lowIncrement, highIncrement, closureIncrement, oneProjectPremium, expectedRationalScalar, fixture]
""",
        "frontier_closure_complementarity" => """
def lowIncrement : ℚ := closureIncrement fixture.discount 0 1 (1 / 2 : ℚ) 2 0 10
def highIncrement : ℚ := closureIncrement fixture.discount 8 1 (1 / 2 : ℚ) 2 0 10
def interaction : ℚ := highIncrement - lowIncrement
example : lowIncrement = 0 := by norm_num [lowIncrement, closureIncrement, oneProjectPremium, fixture]
example : highIncrement = (1 / 2 : ℚ) := by norm_num [highIncrement, closureIncrement, oneProjectPremium, fixture]
example : interaction = (1 / 2 : ℚ) := by norm_num [interaction, lowIncrement, highIncrement, closureIncrement, oneProjectPremium, fixture]
example : interaction = expectedRationalScalar fixture "cross_difference" := by norm_num [interaction, lowIncrement, highIncrement, closureIncrement, oneProjectPremium, expectedRationalScalar, fixture]
""",
        "monotone_gap_threshold" => """
example : projectGap fixture "current" "innovate" = [0, (1 / 2 : ℚ), (3 / 2 : ℚ), 3] := by norm_num [projectGap, projectGapAt, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupProject, lookupLibrary, lookupStrategy, atOr, fixture]
example : grossCoverage fixture "current" "innovate" = [0, (1 / 2 : ℚ), (3 / 2 : ℚ), 3] := by norm_num [grossCoverage, projectGap, projectGapAt, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupProject, lookupLibrary, lookupStrategy, matrixVector, dot, scaleVector, atOr, fixture]
example : researchRegion fixture "current" "innovate" = [false, false, true, true] := by norm_num [researchRegion, weakRegion, grossCoverage, projectGap, projectGapAt, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupProject, lookupLibrary, lookupStrategy, matrixVector, dot, scaleVector, atOr, fixture]
example : componentCount (researchRegion fixture "current" "innovate") = 1 := by norm_num [componentCount, componentCountAux, researchRegion, weakRegion, grossCoverage, projectGap, projectGapAt, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupProject, lookupLibrary, lookupStrategy, matrixVector, dot, scaleVector, atOr, fixture]
example : researchRegion fixture "current" "innovate" = expectedBooleanVector fixture "research_region" := by norm_num [expectedBooleanVector, researchRegion, weakRegion, grossCoverage, projectGap, projectGapAt, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupProject, lookupLibrary, lookupStrategy, matrixVector, dot, scaleVector, atOr, fixture]
""",
        "single_gap_research_region" => """
example : projectGap fixture "current" "innovate" = [0, 1, 0] := by norm_num [projectGap, projectGapAt, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupProject, lookupLibrary, lookupStrategy, atOr, fixture]
example : grossCoverage fixture "current" "innovate" = [1, 0, 1] := by norm_num [grossCoverage, projectGap, projectGapAt, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupProject, lookupLibrary, lookupStrategy, matrixVector, dot, scaleVector, atOr, fixture]
example : researchRegion fixture "current" "innovate" = [true, false, true] := by norm_num [researchRegion, weakRegion, grossCoverage, projectGap, projectGapAt, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupProject, lookupLibrary, lookupStrategy, matrixVector, dot, scaleVector, atOr, fixture]
example : componentCount (researchRegion fixture "current" "innovate") = 2 := by norm_num [componentCount, componentCountAux, researchRegion, weakRegion, grossCoverage, projectGap, projectGapAt, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupProject, lookupLibrary, lookupStrategy, matrixVector, dot, scaleVector, atOr, fixture]
example : researchRegion fixture "current" "innovate" = expectedBooleanVector fixture "research_region" := by norm_num [expectedBooleanVector, researchRegion, weakRegion, grossCoverage, projectGap, projectGapAt, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupProject, lookupLibrary, lookupStrategy, matrixVector, dot, scaleVector, atOr, fixture]
""",
        "multi_gap_disconnection" => """
example : projectGap fixture "current" "innovate" = [4, 0, 0, 0, 4] := by norm_num [projectGap, projectGapAt, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupProject, lookupLibrary, lookupStrategy, atOr, fixture]
example : grossCoverage fixture "current" "innovate" = [4, (41 / 32 : ℚ), (1 / 2 : ℚ), (41 / 32 : ℚ), 4] := by norm_num [grossCoverage, projectGap, projectGapAt, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupProject, lookupLibrary, lookupStrategy, matrixVector, dot, scaleVector, atOr, fixture]
example : researchRegion fixture "current" "innovate" = [true, true, false, true, true] := by norm_num [researchRegion, strictRegion, grossCoverage, projectGap, projectGapAt, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupProject, lookupLibrary, lookupStrategy, matrixVector, dot, scaleVector, atOr, fixture]
example : componentCount (researchRegion fixture "current" "innovate") = 2 := by norm_num [componentCount, componentCountAux, researchRegion, strictRegion, grossCoverage, projectGap, projectGapAt, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupProject, lookupLibrary, lookupStrategy, matrixVector, dot, scaleVector, atOr, fixture]
example : researchRegion fixture "current" "innovate" = expectedBooleanVector fixture "research_region" := by norm_num [expectedBooleanVector, researchRegion, strictRegion, grossCoverage, projectGap, projectGapAt, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupProject, lookupLibrary, lookupStrategy, matrixVector, dot, scaleVector, atOr, fixture]
""",
        "multi_gap_disconnected_region" => """
example : projectGap fixture "current" "innovate" = [4, 0, 0, 0, 4] := by norm_num [projectGap, projectGapAt, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupProject, lookupLibrary, lookupStrategy, atOr, fixture]
example : grossCoverage fixture "current" "innovate" = [4, (41 / 32 : ℚ), (1 / 2 : ℚ), (41 / 32 : ℚ), 4] := by norm_num [grossCoverage, projectGap, projectGapAt, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupProject, lookupLibrary, lookupStrategy, matrixVector, dot, scaleVector, atOr, fixture]
example : researchRegion fixture "current" "innovate" = [true, true, false, true, true] := by norm_num [researchRegion, strictRegion, grossCoverage, projectGap, projectGapAt, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupProject, lookupLibrary, lookupStrategy, matrixVector, dot, scaleVector, atOr, fixture]
example : componentCount (researchRegion fixture "current" "innovate") = 2 := by norm_num [componentCount, componentCountAux, researchRegion, strictRegion, grossCoverage, projectGap, projectGapAt, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupProject, lookupLibrary, lookupStrategy, matrixVector, dot, scaleVector, atOr, fixture]
example : researchRegion fixture "current" "innovate" = expectedBooleanVector fixture "research_region" := by norm_num [expectedBooleanVector, researchRegion, strictRegion, grossCoverage, projectGap, projectGapAt, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupProject, lookupLibrary, lookupStrategy, matrixVector, dot, scaleVector, atOr, fixture]
""",
        "strategy_innovation_equation" => """
def gap : List ℚ := candidateGap fixture "current" "candidate"
def innovationValue : List ℚ := discountedGapSum fixture.transitionRows fixture.discount 3 gap
example : gap = [1, 2] := by norm_num [gap, candidateGap, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupLibrary, lookupStrategy, atOr, fixture]
example : innovationValue = [(5 / 2 : ℚ), (7 / 2 : ℚ)] := by norm_num [innovationValue, discountedGapSum, gap, candidateGap, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupLibrary, lookupStrategy, matrixVector, dot, addVectors, scaleVector, atOr, fixture]
example : atOr innovationValue 0 = (5 / 2 : ℚ) := by norm_num [innovationValue, discountedGapSum, gap, candidateGap, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupLibrary, lookupStrategy, matrixVector, dot, addVectors, scaleVector, atOr, fixture]
example : innovationValue = expectedRationalVector fixture "discounted_gap_sum_horizon_three" := by norm_num [expectedRationalVector, innovationValue, discountedGapSum, gap, candidateGap, candidateGapAt, frontierAt, libraryStrategies, profileAt, lookupLibrary, lookupStrategy, matrixVector, dot, addVectors, scaleVector, atOr, fixture]
""",
    )
    body = replace(
        bodies[fixture.fixture_id],
        r"by norm_num (\[[^\n]*\])" => s"by simp \1 <;> norm_num",
    )
    return """
namespace $namespace_name

def fixture : ExactFixture :=
  $record

$body
end $namespace_name
"""
end

"""Render the generated Lean module containing exact data and checked examples."""
function render_generated_lean(fixtures::AbstractVector{<:ExactBridgeFixture})
    sorted = sort(collect(fixtures); by = fixture -> fixture.fixture_id)
    foreach(validate_fixture, sorted)
    sections = join((_lean_fixture_section(fixture) for fixture in sorted), "\n")
    return _LEAN_PREAMBLE * sections * "\nend StrategyInnovation.Fixtures.Generated\n"
end

function _repository_root()
    return normpath(joinpath(@__DIR__, "..", ".."))
end

function _write_if_changed(path::AbstractString, contents::AbstractString)
    if isfile(path) && read(path, String) == contents
        return false
    end
    mkpath(dirname(path))
    open(path, "w") do io
        write(io, contents)
    end
    return true
end

"""
    write_exact_fixtures(; repository_root, check=false)

Generate all versioned JSON fixtures and the single Lean module. With
`check=true`, perform no writes and fail if any committed artifact is stale.
"""
function write_exact_fixtures(; repository_root::AbstractString = _repository_root(), check::Bool = false)
    fixtures = build_exact_fixtures()
    outputs = Pair{String,String}[]
    fixture_directory = joinpath(repository_root, "shared", "exact_fixtures")
    for fixture in fixtures
        push!(outputs, joinpath(fixture_directory, fixture.fixture_id * ".json") => render_fixture_json(fixture))
    end
    push!(outputs, joinpath(repository_root, "formal", "StrategyInnovation", "Fixtures", "Generated.lean") => render_generated_lean(fixtures))
    if isdir(fixture_directory)
        expected_json = Set(basename(path) for (path, _) in outputs if endswith(path, ".json"))
        existing_json = Set(filter(name -> endswith(name, ".json"), readdir(fixture_directory)))
        unexpected = sort!(collect(setdiff(existing_json, expected_json)))
        isempty(unexpected) || error(
            "unexpected exact fixture JSON files; update the catalog or remove stale artifacts:\n" *
            join(unexpected, "\n"),
        )
    end
    if check
        stale = String[path for (path, contents) in outputs if !isfile(path) || read(path, String) != contents]
        isempty(stale) || error("exact fixture bridge is stale; regenerate:\n" * join(stale, "\n"))
        return (; fixtures, changed = String[])
    end
    changed = String[]
    for (path, contents) in outputs
        _write_if_changed(path, contents) && push!(changed, path)
    end
    return (; fixtures, changed)
end

"""Command-line entry point; accepts only the optional non-mutating `--check`."""
function main(args = ARGS)
    all(argument -> argument == "--check", args) ||
        throw(ArgumentError("usage: export_exact_fixtures.jl [--check]"))
    result = write_exact_fixtures(; check = "--check" in args)
    println("exact fixture bridge: $(length(result.fixtures)) fixtures; $(length(result.changed)) files changed")
    return result
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    using .ExactFixtureExporter
    ExactFixtureExporter.main()
end
