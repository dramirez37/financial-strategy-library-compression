module StrategyValueFigure

using StrategyInnovation
using TOML

export load_strategy_value_figure_config,
       strategy_value_figure_fixture,
       check_strategy_value_figure,
       write_strategy_value_figure,
       main

const DEFAULT_CONFIG = normpath(joinpath(
    @__DIR__,
    "..",
    "..",
    "experiments",
    "configs",
    "strategy_value_figure.toml",
))

_rational_string(value::Rational) =
    denominator(value) == 1 ? string(numerator(value)) :
    string(numerator(value), "//", denominator(value))

_decimal(value::Real; digits::Integer = 3) = string(round(Float64(value); digits))

"""Load the deterministic exact configuration for the canonical value plot."""
function load_strategy_value_figure_config(path::AbstractString = DEFAULT_CONFIG)
    config = TOML.parsefile(path)
    config["experiment_id"] == "strategy-value-equation-figure-v1" || throw(
        ArgumentError("unexpected strategy-value figure experiment ID"),
    )
    config["arithmetic"] == "Rational{BigInt}" || throw(
        ArgumentError("the strategy-value figure must use exact rational arithmetic"),
    )
    config["randomness"] == "none" || throw(
        ArgumentError("the strategy-value figure must be deterministic"),
    )
    return config
end

"""Build and exactly validate the finite data behind the canonical plot."""
function strategy_value_figure_fixture(config = load_strategy_value_figure_config())
    belief_ids = Symbol.(config["belief_ids"])
    beliefs = FiniteBeliefSpace(belief_ids)
    frontier_values = exact_rational.(config["frontier"])
    candidate_values = exact_rational.(config["candidate"])
    length(frontier_values) == length(beliefs) ||
        throw(DimensionMismatch("frontier length"))
    length(candidate_values) == length(beliefs) ||
        throw(DimensionMismatch("candidate length"))

    transition_rows = config["transition"]
    transition = ExactRational[
        exact_rational(transition_rows[row][column])
        for row in eachindex(transition_rows), column in eachindex(first(transition_rows))
    ]
    kernel = MarkovKernel(beliefs, transition)
    discount = exact_rational(config["discount"])
    horizon = Int(config["horizon"])
    initial = Belief(Symbol(config["initial_belief"]))

    modules = [GenerativeModule(:token)]
    empty_modules = ModuleSet{Symbol}()
    strategies = [
        Strategy(
            :inactive,
            OperationalProfile(beliefs, zeros(Int, length(beliefs))),
            empty_modules,
        ),
        Strategy(:frontier, OperationalProfile(beliefs, frontier_values), empty_modules),
        Strategy(:candidate, OperationalProfile(beliefs, candidate_values), empty_modules),
    ]
    catalog = StrategyCatalog(beliefs, modules, strategies, StrategyId(:inactive))
    closure = identity_generative_closure(modules)
    library = RawLibrary(catalog, [StrategyId(:inactive), StrategyId(:frontier)])
    inserted = insert_strategy(catalog, library, StrategyId(:candidate))
    states = [
        compressed_state(catalog, closure, library),
        compressed_state(catalog, closure, inserted),
    ]
    process = DiscountedResearchProcess(
        states,
        [ResearchProject(:dummy, empty_modules)],
        kernel,
        (belief, state, project) -> dirac(state),
        (belief, state, project) -> 100,
        project -> 0,
        discount,
    )

    gap = frontier_gap(catalog, library, StrategyId(:candidate))
    occupancy = discounted_belief_occupancy(process, horizon, initial)
    operational_value = passive_operational_innovation(
        process,
        catalog,
        horizon,
        initial,
        library,
        StrategyId(:candidate),
    )
    discounted_gap_value = discounted_gap_sum(
        process,
        catalog,
        horizon,
        initial,
        library,
        StrategyId(:candidate),
    )
    weighted_gap_value = sum(occupancy .* collect(gap.values))
    operational_value == discounted_gap_value == weighted_gap_value || error(
        "the exact finite Strategy Innovation Equation failed in the figure fixture",
    )

    return (;
        experiment_id = config["experiment_id"],
        beliefs,
        catalog,
        library,
        candidate = StrategyId(:candidate),
        frontier = operational_frontier(catalog, library),
        candidate_profile = operational_profile(catalog, StrategyId(:candidate)),
        gap,
        occupancy,
        operational_value,
        discounted_gap_value,
        current_gap = gap[initial],
        horizon,
        discount,
        initial,
    )
end

function _tikz_source(fixture)
    count = length(fixture.beliefs)
    frontier_path = join(
        ("($index,$(_decimal(fixture.frontier.values[index])))" for index in 1:count),
        " -- ",
    )
    candidate_path = join(
        ("($index,$(_decimal(fixture.candidate_profile.values[index])))" for index in 1:count),
        " -- ",
    )
    positive = findall(>(0), fixture.gap.values)
    isempty(positive) && error("the canonical plot requires a positive frontier gap")
    first_gap = first(positive)
    shade_start = max(1, first_gap - 1)
    shade_indices = shade_start:last(positive)
    upper = join(
        (
            "($index,$(_decimal(fixture.candidate_profile.values[index])))"
            for index in shade_indices
        ),
        " -- ",
    )
    lower = join(
        (
            "($index,$(_decimal(fixture.frontier.values[index])))"
            for index in reverse(shade_indices)
        ),
        " -- ",
    )
    bars = join((
        "\\fill[blue!42] ($(_decimal(index - 0.26)),0) rectangle " *
        "($(_decimal(index + 0.26)),$(_decimal(fixture.occupancy[index])));\n" *
        "\\node[font=\\scriptsize,anchor=south] at " *
        "($index,$(_decimal(fixture.occupancy[index] + 0.035))) " *
        "{$(_decimal(fixture.occupancy[index]; digits = 2))};"
        for index in 1:count
    ), "\n")
    belief_ticks = join((
        "\\node[font=\\small,anchor=north] at ($index,-0.04) {\$b_{$index}\$};"
        for index in 1:count
    ), "\n")
    initial_index = belief_index(fixture.beliefs, fixture.initial)
    beta_text = replace(_rational_string(fixture.discount), "//" => "/")

    return """% Generated by julia/scripts/generate_strategy_value_figure.jl.
% Exact operational-panel data:
% experiments/results/summaries/strategy_value_equation_figure.csv.
% The generative arm is an economic schematic of the unified model.
\\begin{tikzpicture}[font=\\small,>=stealth]
  \\node[font=\\bfseries] at (7.35,5.85)
    {Two channels of strategy insertion value};

  \\node[font=\\bfseries\\small,text=blue!65!black] at (3.15,5.35)
    {Operational channel};
  \\node[font=\\scriptsize,text=black!65] at (3.15,5.04)
    {Exact finite grid; \\(n=$(fixture.horizon)\\), \\(\\beta=$beta_text\\)};
  \\draw[blue!70!black,line width=1.1pt] (0.85,4.68) -- (1.2,4.68);
  \\node[font=\\scriptsize,anchor=west] at (1.28,4.68)
    {existing frontier \\(F_L\\)};
  \\draw[orange!85!black,line width=1.1pt,dashed] (4.25,4.68) -- (4.6,4.68);
  \\node[font=\\scriptsize,anchor=west] at (4.68,4.68)
    {candidate \\(j_s\\)};
  \\begin{scope}[xshift=0cm,yshift=1.35cm,x=1.05cm,y=0.65cm]
    \\draw[->,black!70] (0.65,0) -- (5.55,0);
    \\draw[->,black!70] (0.72,0) -- (0.72,4.55);
    \\foreach \\y in {0,1,2,3,4} {
      \\draw[black!22] (0.68,\\y) -- (5.45,\\y);
      \\node[font=\\scriptsize,anchor=east] at (0.63,\\y) {\\y};
    }
    \\fill[orange!22] $upper -- $lower -- cycle;
    \\draw[blue!70!black,line width=1.15pt] $frontier_path;
    \\draw[orange!85!black,line width=1.15pt,dashed] $candidate_path;
    \\draw[black!55,densely dotted] ($initial_index,0) -- ($initial_index,4.35);
    \\node[rotate=90,font=\\scriptsize] at (0.17,2.25) {payoff};
    \\node[font=\\scriptsize,anchor=west] at (3.2,0.42) {positive gap};
  \\end{scope}

  \\begin{scope}[xshift=0cm,yshift=-1.35cm,x=1.05cm,y=0.9cm]
    \\draw[->,black!70] (0.65,0) -- (5.55,0);
    \\draw[->,black!70] (0.72,0) -- (0.72,1.42);
    \\draw[black!22] (0.68,1) -- (5.45,1);
    \\node[font=\\scriptsize,anchor=east] at (0.63,0) {0};
    \\node[font=\\scriptsize,anchor=east] at (0.63,1) {1};
    $bars
    \\draw[black!55,densely dotted] ($initial_index,0) -- ($initial_index,1.36);
    $belief_ticks
    \\node[rotate=90,font=\\scriptsize,align=center] at (0.13,0.71)
      {future belief\\\\occupancy};
    \\node[font=\\scriptsize,anchor=north] at (3,-0.44)
      {finite belief state};
  \\end{scope}

  \\draw[black!18] (6.55,-1.85) -- (6.55,5.45);
  \\node[font=\\bfseries\\small,text=purple!70!black] at (10.65,5.35)
    {Generative channel};
  \\node[font=\\scriptsize,text=black!65] at (10.65,5.04)
    {Enabled-descendant path};

  \\node[draw=purple!65!black,fill=purple!7,rounded corners,
        align=center,minimum width=4.2cm,minimum height=0.78cm]
        (strategy) at (10.65,4.25)
        {inserted strategy \\(s\\)\\\\
         profile \\(j_s\\), modules \\(\\mods(s)\\)};
  \\node[draw=purple!65!black,fill=purple!7,rounded corners,
        align=center,minimum width=4.2cm,minimum height=0.72cm]
        (module) at (10.65,2.95)
        {module \\(m\\in C_{L\\cup\\{s\\}}\\)};
  \\node[draw=purple!65!black,fill=purple!7,rounded corners,
        align=center,minimum width=4.2cm,minimum height=0.72cm]
        (project) at (10.65,1.65)
        {research project \\(q\\) becomes feasible};
  \\node[draw=orange!80!black,fill=orange!10,rounded corners,
        align=center,minimum width=4.2cm,minimum height=0.82cm]
        (descendant) at (10.65,0.25)
        {generated and admitted descendant \\(g\\)\\\\
         raises future continuation value};

  \\draw[->,purple!70!black,line width=1pt] (strategy) -- node[right,font=\\scriptsize]
    {carries} (module);
  \\draw[->,purple!70!black,line width=1pt] (module) -- node[right,font=\\scriptsize]
    {enables} (project);
  \\draw[->,purple!70!black,line width=1pt] (project) -- node[right,font=\\scriptsize]
    {generates, verifies, admits} (descendant);

  \\node[draw=black!35,fill=black!3,rounded corners,align=center,
        minimum width=4.8cm,minimum height=0.75cm]
        at (10.65,-1.15)
        {generative value depends on descendants,\\\\
         not on module count alone};
\\end{tikzpicture}
"""
end

function _csv_source(fixture)
    return sprint() do io
        println(
            io,
            "belief,index,frontier,candidate,gap,discounted_occupancy,weighted_gap",
        )
        for (index, belief) in enumerate(fixture.beliefs)
            values = (
                belief.id,
                index,
                _rational_string(fixture.frontier.values[index]),
                _rational_string(fixture.candidate_profile.values[index]),
                _rational_string(fixture.gap.values[index]),
                _rational_string(fixture.occupancy[index]),
                _rational_string(fixture.occupancy[index] * fixture.gap.values[index]),
            )
            println(io, join(values, ','))
        end
    end
end

"""Write the complete exact CSV and generated TikZ figure source."""
function write_strategy_value_figure(
    repository_root::AbstractString,
    config = load_strategy_value_figure_config(),
)
    fixture = strategy_value_figure_fixture(config)
    data_path = joinpath(repository_root, config["outputs"]["data"])
    figure_path = joinpath(repository_root, config["outputs"]["figure"])
    mkpath(dirname(data_path))
    mkpath(dirname(figure_path))
    write(data_path, _csv_source(fixture))
    write(figure_path, _tikz_source(fixture))
    return (; data_path, figure_path, fixture)
end

"""Check committed figure artifacts against exact in-memory regeneration."""
function check_strategy_value_figure(
    repository_root::AbstractString,
    config = load_strategy_value_figure_config(),
)
    fixture = strategy_value_figure_fixture(config)
    data_path = joinpath(repository_root, config["outputs"]["data"])
    figure_path = joinpath(repository_root, config["outputs"]["figure"])
    isfile(data_path) || error("missing strategy-value figure data: $data_path")
    isfile(figure_path) || error("missing strategy-value figure source: $figure_path")
    read(data_path, String) == _csv_source(fixture) || error(
        "strategy-value figure data drifted from exact regeneration",
    )
    read(figure_path, String) == _tikz_source(fixture) || error(
        "strategy-value figure source drifted from exact regeneration",
    )
    return (; data_path, figure_path, fixture)
end

function main()
    repository_root = normpath(joinpath(@__DIR__, "..", ".."))
    check_only = ARGS == ["--check"]
    isempty(ARGS) || check_only || throw(
        ArgumentError("usage: generate_strategy_value_figure.jl [--check]"),
    )
    result = check_only ? check_strategy_value_figure(repository_root) :
             write_strategy_value_figure(repository_root)
    verb = check_only ? "checked " : "wrote "
    println(verb, result.data_path)
    println(verb, result.figure_path)
    println("exact operational value = ", _rational_string(result.fixture.operational_value))
    return result
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
