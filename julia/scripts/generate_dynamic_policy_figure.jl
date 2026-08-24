module DynamicResearchPolicyFigure

using Printf

export check_dynamic_policy_figure,
       dynamic_policy_figure_source,
       load_dynamic_policy_rows,
       main,
       write_dynamic_policy_figure

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_DATA = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "results",
    "summaries",
    "unified_comparative_statics_surface.csv",
)
const DEFAULT_OUTPUT = joinpath(
    REPOSITORY_ROOT,
    "manuscript",
    "figures",
    "dynamic_research_policy_regions.tex",
)
const SCENARIOS = [
    (parameter = "research_cost", value = "0.75", label = "cost \\(0.75\\)"),
    (parameter = "research_cost", value = "2.25", label = "cost \\(2.25\\)"),
    (parameter = "research_cost", value = "3.75", label = "cost \\(3.75\\)"),
    (parameter = "research_duration", value = "1", label = "duration \\(1\\)"),
    (parameter = "research_duration", value = "2", label = "duration \\(2\\)"),
    (parameter = "research_duration", value = "3", label = "duration \\(3\\)"),
    (parameter = "discount_factor", value = "0.66", label = "discount \\(0.66\\)"),
    (parameter = "discount_factor", value = "0.74", label = "discount \\(0.74\\)"),
    (parameter = "discount_factor", value = "0.82", label = "discount \\(0.82\\)"),
]
const ROW_Y = [8.0, 7.0, 6.0, 4.5, 3.5, 2.5, 1.0, 0.0, -1.0]

function _parse_csv(path::AbstractString)
    lines = readlines(path)
    isempty(lines) && error("dynamic-policy summary is empty: $path")
    header = split(first(lines), ',')
    length(unique(header)) == length(header) || error("duplicate CSV header")
    return [
        Dict(header .=> split(line, ',')) for line in Iterators.drop(lines, 1)
        if !isempty(strip(line))
    ]
end

"""Load nine positive-duration unified-model policy rows for the compact view."""
function load_dynamic_policy_rows(path::AbstractString = DEFAULT_DATA)
    rows = _parse_csv(path)
    by_id = Dict((row["parameter"], row["parameter_value"]) => row for row in rows)
    selected = Dict{String,String}[]
    for scenario in SCENARIOS
        key = (scenario.parameter, scenario.value)
        haskey(by_id, key) || error("missing unified policy scenario: $key")
        row = by_id[key]
        row["converged"] == "true" || error("policy scenario did not converge: $scenario")
        row["gate_passed"] == "true" || error("policy scenario failed its numerical gate")
        row["sparse_mode"] == "true" || error("policy scenario is not sparse Float64")
        row["raw_source_of_truth"] == "true" || error(
            "policy scenario was not compiled from the unified raw model",
        )
        parse(Int, row["research_duration"]) > 0 || error(
            "policy scenario has nonpositive research duration",
        )
        kind = row["cutoff_kind"]
        kind in ("empty", "full", "lower", "upper") || error(
            "policy scenario is not a connected finite-grid region: $scenario",
        )
        if kind in ("lower", "upper")
            cutoff = parse(Float64, row["research_cutoff"])
            0.0 <= cutoff <= 1.0 || error("policy cutoff is outside the finite grid")
        end
        frequency = parse(Float64, row["research_frequency"])
        0.0 <= frequency <= 1.0 || error("research frequency is outside [0,1]")
        push!(selected, row)
    end

    cost_frequency = parse.(Float64, getindex.(selected[1:3], "research_frequency"))
    duration_frequency = parse.(Float64, getindex.(selected[4:6], "research_frequency"))
    discount_frequency = parse.(Float64, getindex.(selected[7:9], "research_frequency"))
    issorted(cost_frequency; rev = true) || error("research region did not shrink with cost")
    issorted(duration_frequency; rev = true) || error(
        "research region did not shrink with duration",
    )
    issorted(discount_frequency) || error(
        "research region did not expand with discount",
    )
    return selected
end

_decimal(value::Real; digits::Integer = 4) = string(round(value; digits))

"""Render a compact TikZ view of finite-grid continue/research regions."""
function dynamic_policy_figure_source(rows = load_dynamic_policy_rows())
    body = String[]
    for (index, row) in enumerate(rows)
        scenario = SCENARIOS[index]
        kind = row["cutoff_kind"]
        cutoff = kind in ("lower", "upper") ?
                 parse(Float64, row["research_cutoff"]) :
                 (kind == "full" ? 1.0 : 0.0)
        frequency = parse(Float64, row["research_frequency"])
        y = ROW_Y[index]
        if kind == "full"
            push!(body, "  \\fill[blue!30] (0,$(_decimal(y - 0.34))) rectangle " *
                        "(1,$(_decimal(y + 0.34)));")
        elseif kind == "empty"
            push!(body, "  \\fill[black!10] (0,$(_decimal(y - 0.34))) rectangle " *
                        "(1,$(_decimal(y + 0.34)));")
        elseif kind == "lower"
            push!(body, "  \\fill[blue!30] (0,$(_decimal(y - 0.34))) rectangle " *
                        "($(_decimal(cutoff)),$(_decimal(y + 0.34)));")
            push!(body, "  \\fill[black!10] ($(_decimal(cutoff)),$(_decimal(y - 0.34))) " *
                        "rectangle (1,$(_decimal(y + 0.34)));")
        else
            push!(body, "  \\fill[black!10] (0,$(_decimal(y - 0.34))) rectangle " *
                        "($(_decimal(cutoff)),$(_decimal(y + 0.34)));")
            push!(body, "  \\fill[blue!30] ($(_decimal(cutoff)),$(_decimal(y - 0.34))) " *
                        "rectangle (1,$(_decimal(y + 0.34)));")
        end
        push!(body, "  \\draw[black!45] (0,$(_decimal(y - 0.34))) rectangle " *
                    "(1,$(_decimal(y + 0.34)));")
        if kind in ("lower", "upper")
            push!(body, "  \\draw[black,line width=0.7pt] " *
                        "($(_decimal(cutoff)),$(_decimal(y - 0.42))) -- " *
                        "($(_decimal(cutoff)),$(_decimal(y + 0.42)));")
        end
        push!(body, "  \\node[anchor=east] at (-0.025,$(_decimal(y))) " *
                    "{$(scenario.label)};")
        push!(body, "  \\node[font=\\tiny,anchor=west] at " *
                    "(1.015,$(_decimal(y))) {share $(@sprintf("%.2f", frequency))};")
    end

    return """% Generated by julia/scripts/generate_dynamic_policy_figure.jl.
% Source data: experiments/results/summaries/unified_comparative_statics_surface.csv.
\\begin{tikzpicture}[x=6.0cm,y=0.36cm,font=\\scriptsize]
  \\fill[black!10] (0,9.15) rectangle (0.08,9.7);
  \\draw[black!45] (0,9.15) rectangle (0.08,9.7);
  \\node[anchor=west] at (0.095,9.425) {continue};
  \\fill[blue!30] (0.31,9.15) rectangle (0.39,9.7);
  \\draw[black!45] (0.31,9.15) rectangle (0.39,9.7);
  \\node[anchor=west] at (0.405,9.425) {research};
$(join(body, '\n'))
  \\foreach \\x/\\label in {0/0,0.25/0.25,0.5/0.50,0.75/0.75,1/1} {
    \\draw[black!55] (\\x,-1.42) -- (\\x,-1.57);
    \\node[anchor=north] at (\\x,-1.62) {\\label};
  }
  \\draw[black!55,->] (0,-1.5) -- (1.04,-1.5);
  \\node[anchor=north] at (0.5,-2.18) {41-point belief coordinate};
\\end{tikzpicture}
"""
end

"""Write the compact policy-region TikZ source."""
function write_dynamic_policy_figure(
    output_path::AbstractString = DEFAULT_OUTPUT,
    data_path::AbstractString = DEFAULT_DATA,
)
    source = dynamic_policy_figure_source(load_dynamic_policy_rows(data_path))
    mkpath(dirname(output_path))
    write(output_path, source)
    return output_path
end

"""Reject drift between committed TikZ and the registered policy summary."""
function check_dynamic_policy_figure(
    output_path::AbstractString = DEFAULT_OUTPUT,
    data_path::AbstractString = DEFAULT_DATA,
)
    isfile(output_path) || error("missing dynamic-policy figure: $output_path")
    expected = dynamic_policy_figure_source(load_dynamic_policy_rows(data_path))
    read(output_path, String) == expected || error(
        "dynamic-policy figure drifted from the registered policy summary",
    )
    return output_path
end

function main()
    check_only = ARGS == ["--check"]
    isempty(ARGS) || check_only || throw(
        ArgumentError("usage: generate_dynamic_policy_figure.jl [--check]"),
    )
    output = check_only ? check_dynamic_policy_figure() : write_dynamic_policy_figure()
    println(check_only ? "checked " : "wrote ", output)
    return output
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
