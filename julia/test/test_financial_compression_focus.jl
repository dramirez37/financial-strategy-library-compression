@testset "financial innovation-safe compression presentation" begin
    analysis = financial_compression_analysis()
    locked = only(filter(
        summary -> summary.audit == "locked_terminal",
        analysis.summaries,
    ))
    annual = only(filter(
        summary -> summary.audit == "annual_walk_forward",
        analysis.summaries,
    ))

    @test length(analysis.policy_rows) == 125
    @test length(analysis.predictor_rows) == 14
    @test (
        locked.source_library_size,
        locked.frontier_only_library_size,
        locked.innovation_safe_library_size,
    ) == (80, 3, 25)
    @test (
        annual.source_library_size,
        annual.frontier_only_library_size,
        annual.innovation_safe_library_size,
    ) == (202, 5, 100)
    @test locked.frontier_only_current_change == 0.0
    @test locked.innovation_safe_current_change == 0.0
    @test annual.frontier_only_current_change == 0.0
    @test annual.innovation_safe_current_change == 0.0
    @test locked.frontier_only_closure_size == 12
    @test annual.frontier_only_closure_size == 14
    @test locked.frontier_only_descendant_change < 0.0
    @test annual.frontier_only_descendant_change < 0.0
    @test locked.frontier_only_descendant_change == -0.0015556990504919932
    @test annual.frontier_only_descendant_change == -0.10203275907184432
    @test locked.innovation_safe_descendant_change == 0.0
    @test annual.innovation_safe_descendant_change == 0.0
    @test locked.source_closure_size == locked.innovation_safe_closure_size == 38
    @test annual.source_closure_size == annual.innovation_safe_closure_size == 113
    @test (
        locked.operational_only_count,
        locked.generative_only_count,
        locked.both_count,
        locked.neither_count,
    ) == (3, 1, 0, 21)
    @test (
        annual.operational_only_count,
        annual.generative_only_count,
        annual.both_count,
        annual.neither_count,
    ) == (5, 1, 0, 94)

    valuable = filter(row -> row.generatively_valuable, analysis.policy_rows)
    @test length(valuable) == 2
    @test all(row -> row.sparse_frontier_indicator, valuable)
    @test all(row -> row.supports_best_descendant, valuable)
    @test Set(row.ticker for row in valuable) == Set(["GLD", "UNG"])
    @test all(
        row -> isapprox(
            row.module_uniqueness_share,
            1 / 7;
            atol = 1.0e-12,
            rtol = 0,
        ),
        analysis.policy_rows,
    )

    unidentified = filter(
        row -> row.characteristic == "module_uniqueness",
        analysis.predictor_rows,
    )
    @test length(unidentified) == 2
    @test all(row -> !row.comparison_identified, unidentified)
    @test all(row -> !row.theorem_evidence, analysis.policy_rows)
    @test all(row -> !row.theorem_evidence, analysis.predictor_rows)

    outputs = check_manuscript_numerical_artifacts()
    @test all(isfile, values(outputs))
    repository_root = normpath(joinpath(@__DIR__, "..", ".."))
    primary_figure = read(
        joinpath(
            repository_root,
            "manuscript",
            "figures",
            "financial_innovation_safe_compression.tex",
        ),
        String,
    )
    secondary_figure = read(
        joinpath(
            repository_root,
            "manuscript",
            "figures",
            "financial_coverage_comparison.tex",
        ),
        String,
    )
    design_table = read(
        joinpath(repository_root, "manuscript", "tables", "financial_design_summary.tex"),
        String,
    )
    estimand_metadata = read(
        joinpath(
            repository_root,
            "experiments",
            "results",
            "summaries",
            "financial_compression_estimand_metadata.csv",
        ),
        String,
    )
    information_set_audit = read(
        joinpath(repository_root, "EMPIRICAL_INFORMATION_SET_AUDIT.md"),
        String,
    )
    financial_section = read(
        joinpath(
            repository_root,
            "manuscript",
            "sections",
            "10_financial_compression_audit.tex",
        ),
        String,
    )
    experiment_protocol = read(
        joinpath(
            repository_root,
            "manuscript",
            "appendices",
            "e_experiment_protocol.tex",
        ),
        String,
    )
    for panel_title in (
        "(a) Strategies retained from the source",
        "(b) Modules retained from the source",
        "(c) Ex post enabled-descendant opportunity quality",
    )
        @test occursin(panel_title, primary_figure)
    end
    @test occursin(
        raw"\begin{tikzpicture}[x=1cm,y=1cm,font=\scriptsize]",
        primary_figure,
    )
    @test occursin(
        raw"title/.style={font=\bfseries\footnotesize,anchor=north west}",
        primary_figure,
    )
    @test !occursin(
        raw"\begin{tikzpicture}[x=0.88cm,y=0.50cm,font=\tiny]",
        primary_figure,
    )
    @test !occursin(raw"font=\tiny", primary_figure)
    @test !occursin(raw"\resizebox", primary_figure)
    @test !occursin(raw"\scalebox", primary_figure)
    @test !occursin(raw"\begin{adjustbox}", primary_figure)
    for obsolete_title in (
        "{(a) Source and pruned library sizes}",
        "{(b) Current frontier preservation}",
        "{(c) Module-closure preservation}",
        "{(d) Ex post enabled-descendant",
        "{(e) Retained policy roles}",
        "{(f) Carrier-to-descendant mechanism}",
    )
        @test !occursin(obsolete_title, primary_figure)
    end
    for exact_count in ("3/80", "25/80", "5/202", "100/202", "12/38", "113/113")
        @test occursin(exact_count, primary_figure)
    end
    @test occursin(
        "separate audit-specific scales and no pooled magnitude",
        primary_figure,
    )
    @test occursin("Locked terminal audit", secondary_figure)
    @test occursin("Annual walk-forward audit", secondary_figure)
    @test occursin("Locked terminal audit", design_table)
    @test occursin("Annual walk-forward audit", design_table)
    @test occursin(raw"ex post \(\Delta Q_a=-0.0016\)", design_table)
    @test occursin(
        "not an input, forecast, policy score, or deployable criterion",
        design_table,
    )
    @test occursin(
        "Validation frontier; innovation-safe also uses structural closure",
        design_table,
    )
    @test occursin(
        raw"Trailing-through-\(y-1\) score fixed after compression and before target \(y\)",
        design_table,
    )
    @test occursin(
        "Compression, uniqueness, and dependence are retrospective",
        design_table,
    )
    @test occursin("realized coverage and oracle regret are held out", design_table)
    metadata_rows = ManuscriptNumericalArtifacts._parse_csv(
        joinpath(
            repository_root,
            "experiments",
            "results",
            "summaries",
            "financial_compression_estimand_metadata.csv",
        ),
    )
    @test length(metadata_rows) == 2
    @test Set(row["audit"] for row in metadata_rows) ==
          Set(["locked_terminal", "annual_walk_forward"])
    @test all(
        row -> row["estimand_name"] ==
               "ex post enabled-descendant opportunity quality",
        metadata_rows,
    )
    @test all(row -> row["outcome_source"] == "held-out audit outcomes", metadata_rows)
    @test all(row -> row["algorithm_input"] == "false", metadata_rows)
    @test all(row -> row["forecast"] == "false", metadata_rows)
    @test all(row -> row["policy_score"] == "false", metadata_rows)
    @test all(
        row -> row["deployable_selection_criterion"] == "false",
        metadata_rows,
    )
    @test all(
        row -> row["innovation_safe_acceptance_test"] ==
               "frontier equality and closure equality",
        metadata_rows,
    )
    @test all(
        row -> row["frontier_only_acceptance_test"] == "frontier equality",
        metadata_rows,
    )
    @test all(row -> row["theorem_evidence"] == "false", metadata_rows)
    @test occursin(
        "whether retained modules preserve access to high-quality held-out candidates",
        estimand_metadata,
    )
    audit_rows = filter(
        line -> startswith(line, "| **"),
        split(information_set_audit, '\n'),
    )
    for (quantity, classification) in (
        ("Current frontier", "Available at pruning time"),
        ("Module closure", "Available at pruning time"),
        ("Compression ratio", "Retrospective descriptive statistic"),
        ("Enabled candidate set", "Available at pruning time"),
        (
            "Ex post enabled-descendant opportunity quality",
            "Available only in the held-out audit",
        ),
        ("Coverage ranking score", "Available during validation"),
        ("Locked net utility", "Available only in the held-out audit"),
        ("Annual realized coverage", "Available only in the held-out audit"),
        ("Greedy-oracle regret", "Oracle comparator"),
        ("Module uniqueness", "Retrospective descriptive statistic"),
        ("Descendant dependence", "Retrospective descriptive statistic"),
    )
        matching_rows = filter(row -> occursin(quantity, row), audit_rows)
        @test length(matching_rows) == 1 &&
              occursin(classification, only(matching_rows))
    end
    @test occursin(
        "No held-out outcome, candidate-quality measure, coverage-ranking score",
        information_set_audit,
    )
    @test occursin(
        r"neither pruning rule tests candidate-set\s+equality",
        financial_section,
    )
    @test occursin(
        "Coverage scores are post-compression ranking inputs",
        financial_section,
    )
    @test occursin("Empirical information-set classification", experiment_protocol)
    @test !occursin(r"\bN2\b|\bN3\b", primary_figure)
    @test !occursin(r"\bN2\b|\bN3\b", secondary_figure)
    @test !occursin(r"\bN2\b|\bN3\b", design_table)
end
