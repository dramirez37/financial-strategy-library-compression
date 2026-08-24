_coverage_test_identity(::Type{T}, count::Integer) where {T} =
    T[row == column ? 1 : 0 for row in 1:count, column in 1:count]

@testset "coverage occupation operators" begin
    space = FiniteBeliefSpace([:low, :high])
    kernel = MarkovKernel(space, [3 // 4 1 // 4; 1 // 2 1 // 2])
    beta = 1 // 2
    survival = 3 // 4
    q = beta * survival
    transition = Rational{BigInt}[
        3 // 4 1 // 4
        1 // 2 1 // 2
    ]
    identity_matrix = _coverage_test_identity(ExactRational, 2)

    occupation = discounted_occupation_matrix(kernel, beta; survival)
    @test eltype(occupation) == ExactRational
    @test (identity_matrix - q .* transition) * occupation == identity_matrix
    @test occupation * ones(ExactRational, 2) == fill(inv(1 - q), 2)

    gap = ExactRational[1, 3]
    @test discounted_gap_solve(kernel, gap, beta; survival) == occupation * gap
    @test infinite_coverage_potential(kernel, gap, beta; survival) == occupation * gap

    horizon = 7
    finite = finite_discounted_occupation(kernel, beta, horizon; survival)
    remainder = q^horizon .* (transition^horizon * occupation)
    @test finite + remainder == occupation
    @test finite_coverage_potential(kernel, gap, beta, horizon; survival) == finite * gap
    @test finite_discounted_occupation(kernel, 1, 0) == zeros(ExactRational, 2, 2)

    float_kernel = MarkovKernel(
        space,
        [0.75 0.25; 0.5 0.5];
        mode = Float64Mode(),
    )
    float_sum = finite_discounted_occupation(float_kernel, 0.5, 100; survival = 0.75)
    float_solve = discounted_occupation_matrix(float_kernel, 0.5; survival = 0.75)
    @test float_sum ≈ float_solve atol = 1e-14 rtol = 1e-14
    @test discounted_gap_solve(float_kernel, [1.0, 3.0], 0.5; survival = 0.75) ≈
          float_solve * [1.0, 3.0]

    interaction = finite_discount_survival_interaction(
        kernel,
        gap,
        1 // 4,
        3 // 4,
        1 // 3,
        2 // 3,
        5,
    )
    @test interaction.finite_sum_identity_holds
    @test interaction.factorization_holds
    @test interaction.interaction_holds
    @test interaction.potential11 == ExactRational[5053 // 2048, 4867 // 1024]
    @test interaction.cross_difference ==
          ExactRational[43771 // 55296, 24869 // 27648]
    @test all(
        interaction.beta_effect_high_survival .>=
        interaction.beta_effect_low_survival,
    )
    @test_throws ArgumentError finite_discount_survival_interaction(
        kernel,
        gap,
        3 // 4,
        1 // 4,
        1 // 3,
        2 // 3,
        5,
    )
    @test_throws ArgumentError finite_discount_survival_interaction(
        kernel,
        ExactRational[1, -1],
        1 // 4,
        3 // 4,
        1 // 3,
        2 // 3,
        5,
    )

    @test_throws ArgumentError finite_discounted_occupation(kernel, -1 // 2, 3)
    @test_throws ArgumentError finite_discounted_occupation(kernel, 1 // 2, -1)
    @test_throws ArgumentError finite_discounted_occupation(kernel, 1 // 2, 3; survival = 2)
    @test_throws ArgumentError discounted_occupation_matrix(kernel, 1)
    @test_throws DimensionMismatch discounted_gap_solve(kernel, [1 // 1], 1 // 2)
    @test_throws ArgumentError discounted_gap_solve(kernel, [0.5, 1.0], 1 // 2)
end

@testset "Lean S4 exact delayed-coverage fixture" begin
    space = FiniteBeliefSpace([:initial, :future])
    kernel = MarkovKernel(space, [0 1; 0 1])
    gap = ExactRational[0, 2]

    occupation = finite_discounted_occupation(kernel, 1 // 2, 2)
    potential = finite_coverage_potential(kernel, gap, 1 // 2, 2)
    @test occupation == ExactRational[1 1 // 2; 0 3 // 2]
    @test potential == ExactRational[1, 3]
    @test potential[1] == 1 // 1
    @test potential[1] == sum(
        (1 // 2)^date * (date == 0 ? gap[1] : gap[2]) for date in 0:1
    )
end

@testset "candidate and aggregate gap functions" begin
    space = FiniteBeliefSpace(collect(1:5))
    frontier_profile = OperationalProfile(space, [1, 1, 1, 1, 1])
    left_candidate = OperationalProfile(space, [5, 0, 0, 0, 0])
    right_candidate = OperationalProfile(space, [0, 0, 0, 0, 5])

    left_gap = candidate_gap(left_candidate, frontier_profile)
    right_gap = candidate_gap(right_candidate, frontier_profile)
    aggregate = project_gap([left_candidate, right_candidate], frontier_profile)
    @test collect(left_gap.values) == ExactRational[4, 0, 0, 0, 0]
    @test collect(right_gap.values) == ExactRational[0, 0, 0, 0, 4]
    @test collect(aggregate.values) == ExactRational[4, 0, 0, 0, 4]
    @test coverage_potential(_coverage_test_identity(ExactRational, 5), aggregate) == aggregate
    @test_throws ArgumentError project_gap(OperationalProfile{Int,ExactRational}[], frontier_profile)

    other_space = FiniteBeliefSpace(collect(6:10))
    other_candidate = OperationalProfile(other_space, [1, 1, 1, 1, 1])
    @test_throws ArgumentError candidate_gap(other_candidate, frontier_profile)
end

@testset "Lean S5 monotone-gap one-shot threshold and failures" begin
    space = FiniteBeliefSpace([:b1, :b2, :b3, :b4])
    grid = OrderedBeliefGrid(space, ExactRational[0, 1, 2, 3])
    identity_kernel = MarkovKernel(space, _coverage_test_identity(Int, 4))
    gap = ExactRational[0, 1, 2, 3]
    survival = ExactRational[1 // 4, 1 // 2, 3 // 4, 1]
    cost = ExactRational[2, 1, 1 // 2, 0]
    gross = gross_coverage_value(identity_kernel, gap, 1; survival)
    region = cost_covering_set(gross, cost)
    threshold = extract_threshold(grid, region)

    @test is_monotone_sequence(gap)
    @test is_monotone_sequence(survival)
    @test is_antitone_sequence(cost)
    @test is_stochastically_monotone(identity_kernel)
    @test gross == ExactRational[0, 1 // 2, 3 // 2, 3]
    @test is_monotone_sequence(gross)
    @test region == Bool[false, false, true, true]
    @test component_count(region) == 1
    @test threshold.kind == :upper
    @test threshold.cutoff_index == 3
    @test threshold.cutoff_belief == Belief(:b3)
    @test threshold.cutoff_coordinate == 2 // 1

    higher_cost = ExactRational[2, 1, 2, 0]
    higher_cost_region = cost_covering_set(gross, higher_cost)
    @test higher_cost_region == Bool[false, false, false, true]
    @test all(higher_cost_region .<= region)
    @test extract_threshold(grid, higher_cost_region).cutoff_index == 4

    lower_survival = ExactRational[1 // 8, 1 // 4, 3 // 8, 1 // 2]
    higher_survival = survival
    lower_survival_region =
        cost_covering_set(gross_coverage_value(identity_kernel, gap, 1;
            survival = lower_survival), cost)
    higher_survival_region =
        cost_covering_set(gross_coverage_value(identity_kernel, gap, 1;
            survival = higher_survival), cost)
    @test all(lower_survival_region .<= higher_survival_region)
    @test extract_threshold(grid, higher_survival_region).cutoff_index <=
          extract_threshold(grid, lower_survival_region).cutoff_index

    lower_admission = fill(1 // 2, 4)
    higher_admission = fill(1, 4)
    lower_admission_region =
        cost_covering_set(gross_coverage_value(identity_kernel, gap, 1;
            survival = lower_admission), cost)
    higher_admission_region =
        cost_covering_set(gross_coverage_value(identity_kernel, gap, 1;
            survival = higher_admission), cost)
    @test all(lower_admission_region .<= higher_admission_region)
    @test extract_threshold(grid, higher_admission_region).cutoff_index <=
          extract_threshold(grid, lower_admission_region).cutoff_index

    candidate = ExactRational[0, 2, 4, 6]
    frontier0 = ExactRational[0, 0, 0, 0]
    frontier1 = ExactRational[0, 1, 2, 3]
    gap0 = max.(candidate .- frontier0, 0)
    gap1 = max.(candidate .- frontier1, 0)
    frontier0_region =
        cost_covering_set(gross_coverage_value(identity_kernel, gap0, 1), cost)
    frontier1_region =
        cost_covering_set(gross_coverage_value(identity_kernel, gap1, 1), cost)
    @test all(frontier1_region .<= frontier0_region)
    @test extract_threshold(grid, frontier0_region).cutoff_index <=
          extract_threshold(grid, frontier1_region).cutoff_index

    destructive_space = FiniteBeliefSpace([:left, :middle, :right])
    destructive_grid = OrderedBeliefGrid(destructive_space, ExactRational[-1, 0, 1])
    destructive_kernel = MarkovKernel(
        destructive_space,
        [0 1 0; 1 0 0; 0 1 0],
    )
    destructive_gap = ExactRational[0, 1, 0]
    destructive_potential = gross_coverage_value(destructive_kernel, destructive_gap, 1)
    destructive_region = cost_covering_set(destructive_potential, 1 // 2)
    @test destructive_potential == ExactRational[1, 0, 1]
    @test is_single_peaked(destructive_gap)
    @test is_quasiconcave_sequence(destructive_gap)
    @test !is_quasiconcave_sequence(destructive_potential)
    @test !is_stochastically_monotone(destructive_kernel)
    @test connected_components(destructive_region) == [1:1, 3:3]
    @test extract_threshold(destructive_grid, destructive_region).kind == :not_threshold

    increasing_potential = ExactRational[1, 2, 3]
    arbitrary_cost = ExactRational[0, 3, 0]
    @test cost_covering_set(increasing_potential, arbitrary_cost) ==
          Bool[true, false, true]
    @test !is_antitone_sequence(arbitrary_cost)
end

@testset "Lean C2 disconnected multi-gap fixture" begin
    space = FiniteBeliefSpace(collect(0:4))
    grid = OrderedBeliefGrid(space, ExactRational[0, 1, 2, 3, 4])
    kernel = MarkovKernel(
        space,
        [
            1 0 0 0 0
            81 // 256 108 // 256 54 // 256 12 // 256 1 // 256
            1 // 16 4 // 16 6 // 16 4 // 16 1 // 16
            1 // 256 12 // 256 54 // 256 108 // 256 81 // 256
            0 0 0 0 1
        ],
    )
    aggregate_gap = ExactRational[4, 0, 0, 0, 4]
    potential = gross_coverage_value(kernel, aggregate_gap, 1)
    region = cost_covering_set(potential, 1; strict = true)

    @test potential == ExactRational[4, 41 // 32, 1 // 2, 41 // 32, 4]
    @test region == Bool[true, true, false, true, true]
    @test connected_components(region) == [1:2, 4:5]
    @test component_count(region) == 2
    @test extract_threshold(grid, region).kind == :not_threshold

    constant_gap = ExactRational[2, 2, 2, 2, 2]
    variable_cost = ExactRational[0, 3, 0, 3, 0]
    variable_region = cost_covering_set(gross_coverage_value(kernel, constant_gap, 1), variable_cost;
        strict = true)
    @test variable_region == Bool[true, false, true, false, true]
    @test component_count(variable_region) == 3
end

@testset "threshold and boundary diagnostics" begin
    space = FiniteBeliefSpace([:left, :middle, :right])
    grid = OrderedBeliefGrid(space, ExactRational[0, 1, 2])
    @test extract_threshold(grid, falses(3)).kind == :empty
    @test extract_threshold(grid, trues(3)).kind == :full
    @test extract_threshold(grid, Bool[true, true, false]; direction = :lower).kind == :lower
    @test_throws ArgumentError extract_threshold(grid, trues(3); direction = :center)

    crossings = boundary_transversality(
        grid,
        ExactRational[0, 1, 0],
        ExactRational[1 // 2, 1 // 2, 1 // 2],
    )
    @test length(crossings) == 2
    @test getfield.(crossings, :kind) == [:crossing, :crossing]
    @test getfield.(crossings, :location) == ExactRational[1 // 2, 3 // 2]
    @test getfield.(crossings, :slope) == ExactRational[1, -1]
    @test all(diagnostic -> diagnostic.transverse, crossings)

    tangent = boundary_transversality(grid, ExactRational[1, 0, 1], 0)
    @test any(diagnostic -> diagnostic.kind == :grid_zero, tangent)
    @test any(diagnostic -> diagnostic.slope == 0 && !diagnostic.transverse, tangent)
    @test_throws DimensionMismatch boundary_transversality(grid, [1, 2], 0)
end

@testset "coverage sensitivity axes" begin
    space = FiniteBeliefSpace([:low, :high])
    grid = OrderedBeliefGrid(space, [0.0, 1.0])
    kernel = MarkovKernel(
        space,
        [0.8 0.2; 0.2 0.8];
        mode = Float64Mode(),
    )
    precise_kernel = MarkovKernel(
        space,
        [1.0 0.0; 0.0 1.0];
        mode = Float64Mode(),
    )
    rows = coverage_sensitivity(
        grid,
        kernel,
        [0.0, 1.0],
        0.35;
        discount = 0.7,
        survival = 0.9,
        costs = (0.2, 0.5),
        discounts = (0.5, 0.8),
        persistences = (0.0, 0.8),
        delays = (0, 2),
        survivals = (0.6, 0.95),
        signal_kernels = ("high" => precise_kernel,),
    )
    @test length(rows) == 12
    @test Set(row.parameter for row in rows) == Set((
        :baseline,
        :cost,
        :discount,
        :persistence,
        :delay,
        :survival,
        :signal_precision,
    ))
    low_discount = only(filter(row -> row.label == "discount=0.5", rows))
    high_discount = only(filter(row -> row.label == "discount=0.8", rows))
    @test all(low_discount.potential .<= high_discount.potential)
    short_delay = only(filter(row -> row.label == "delay=0", rows))
    long_delay = only(filter(row -> row.label == "delay=2", rows))
    @test all(long_delay.potential .<= short_delay.potential)
    low_survival = only(filter(row -> row.label == "survival=0.6", rows))
    high_survival = only(filter(row -> row.label == "survival=0.95", rows))
    @test all(low_survival.potential .<= high_survival.potential)

    adjusted = persistence_adjusted_kernel(kernel, 0.6)
    @test all(isapprox(sum(row), 1.0; atol = 1e-12) for row in adjusted.rows)
    @test_throws ArgumentError persistence_adjusted_kernel(kernel, 1.1)
    @test_throws ArgumentError delayed_lifetime_coverage_potential(
        kernel,
        [0.0, 1.0],
        0.7;
        delay = -1,
    )
end

@testset "coverage grid-refinement stability" begin
    thresholds = Float64[]
    boundary_locations = Float64[]
    for count in (11, 21, 41, 81)
        coordinates = collect(range(0.0, 1.0; length = count))
        space = FiniteBeliefSpace(collect(1:count))
        grid = OrderedBeliefGrid(space, coordinates)
        transition = zeros(Float64, count, count)
        for index in 1:count
            transition[index, index] = 1.0
        end
        kernel = MarkovKernel(space, transition; mode = Float64Mode())
        potential = infinite_coverage_potential(kernel, coordinates, 0.5)
        cost = 0.87
        region = research_region(potential, cost)
        threshold = extract_threshold(grid, region)
        diagnostics = boundary_transversality(grid, potential, cost)
        push!(thresholds, something(threshold.cutoff_coordinate))
        push!(boundary_locations, only(diagnostics).location)
        @test component_count(region) == 1
        @test threshold.kind == :upper
        @test abs(threshold.cutoff_coordinate - 0.435) <= step(range(0.0, 1.0; length = count))
    end
    @test all(isapprox(location, 0.435; atol = 2e-15) for location in boundary_locations)
    @test abs(thresholds[end] - 0.435) <= abs(thresholds[1] - 0.435)
end

@testset "deterministic small-kernel properties" begin
    rng = research_rng(UInt64(0x434f564552414745))
    for _ in 1:30
        count = rand(rng, 2:5)
        raw = rand(rng, 0:8, count, count)
        for row in 1:count
            all(iszero, raw[row, :]) && (raw[row, rand(rng, 1:count)] = 1)
        end
        probabilities = Matrix{ExactRational}(undef, count, count)
        for row in 1:count
            denominator = sum(raw[row, :])
            for column in 1:count
                probabilities[row, column] = raw[row, column] // denominator
            end
        end
        space = FiniteBeliefSpace(collect(1:count))
        kernel = MarkovKernel(space, probabilities)
        beta = ExactRational(rand(rng, 0:8), 10)
        survival = ExactRational(rand(rng, 1:10), 10)
        beta * survival < 1 || continue
        gap = ExactRational.(rand(rng, 0:6, count))
        occupation = discounted_occupation_matrix(kernel, beta; survival)
        solve = discounted_gap_solve(kernel, gap, beta; survival)
        @test solve == occupation * gap
        @test all(solve .>= gap)
        finite = finite_coverage_potential(kernel, gap, beta, 8; survival)
        @test all(finite .<= solve)
        @test all(finite .>= gap)
    end

    @test_throws ArgumentError MarkovKernel(FiniteBeliefSpace([1, 2]), [1 -1; 0 1])
    @test_throws ArgumentError MarkovKernel(FiniteBeliefSpace([1, 2]), [1 1; 0 1])
    @test_throws ArgumentError OrderedBeliefGrid(
        FiniteBeliefSpace([1, 2]),
        [0.0, 0.0],
    )
end

@testset "coverage experiment outputs" begin
    result = run_coverage_geometry(; grid_size = 41)
    @test result.checks.exact_fixtures
    @test result.checks.baseline_component_count == 1
    @test result.checks.disconnected_component_count == 2
    @test result.checks.baseline_transverse
    @test length(result.sensitivity) == 19

    mktempdir() do directory
        output_dir = joinpath(directory, "summaries")
        figure_dir = joinpath(directory, "figures")
        outputs = write_coverage_outputs(result; output_dir, figure_dir)
        @test isfile(outputs.summary)
        @test length(outputs.data) == 6
        @test length(outputs.figures) == 5
        @test all(isfile, values(outputs.data))
        @test all(isfile, values(outputs.figures))

        summary = read(outputs.summary, String)
        @test occursin("\"experiment_id\": \"coverage-potential-geometry-v1\"", summary)
        @test occursin("\"exact_fixtures\": true", summary)
        potential_header = first(eachline(outputs.data["potential"]))
        @test potential_header ==
              "belief_index,coordinate,gap,potential,cost,net_value,research_region,component"
        for figure_path in values(outputs.figures)
            svg = read(figure_path, String)
            @test startswith(svg, "<svg")
            @test occursin("<title>", svg)
            @test occursin("<desc>", svg)
            @test !occursin("NaN", svg)
            @test !occursin("Inf", svg)
        end
    end
end
