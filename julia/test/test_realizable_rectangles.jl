@testset "exact raw-first realizable frontier--closure rectangles" begin
    fixtures = exact_realizable_rectangle_fixtures()
    @test length(fixtures) == 2
    @test all(fixture -> fixture.arithmetic == "Rational{BigInt}", fixtures)
    @test all(fixture -> fixture.consistency.all_pass, fixtures)
    @test all(fixture -> length(fixture.transitions) == 20, fixtures)
    @test all(fixture -> length(fixture.values) == 8, fixtures)

    expected_menus = (
        L00 = ["continue", "research:core_project"],
        L01 = [
            "continue",
            "research:core_project",
            "research:expanded_project",
        ],
        L10 = ["continue", "research:core_project"],
        L11 = [
            "continue",
            "research:core_project",
            "research:expanded_project",
        ],
    )

    for fixture in fixtures
        rectangle = fixture.rectangle
        catalog = rectangle.catalog
        closure = rectangle.closure
        libraries = rectangle_libraries(rectangle)
        states = rectangle_states(rectangle)

        @test keys(libraries) == (:L00, :L01, :L10, :L11)
        @test all(
            library -> validate_library(catalog, library) === library,
            values(libraries),
        )
        @test libraries.L01 ==
              insert_strategy(
            catalog,
            libraries.L00,
            only(rectangle.closure_strategies),
        )
        @test libraries.L10 ==
              insert_strategy(
            catalog,
            libraries.L00,
            only(rectangle.frontier_strategies),
        )
        @test libraries.L11 ==
              insert_strategy(
            catalog,
            libraries.L01,
            only(rectangle.frontier_strategies),
        )
        @test libraries.L11 ==
              insert_strategy(
            catalog,
            libraries.L10,
            only(rectangle.closure_strategies),
        )

        @test states.L00 ==
              compressed_library_state(catalog, closure, libraries.L00)
        @test states.L01 ==
              compressed_library_state(catalog, closure, libraries.L01)
        @test states.L10 ==
              compressed_library_state(catalog, closure, libraries.L10)
        @test states.L11 ==
              compressed_library_state(catalog, closure, libraries.L11)
        @test collect(states.L00.frontier.values) == ExactRational[2, 3]
        @test states.L01.frontier == states.L00.frontier
        @test collect(states.L10.frontier.values) == ExactRational[4, 5]
        @test states.L11.frontier == states.L10.frontier
        @test states.L10.closure == states.L00.closure
        @test states.L11.closure == states.L01.closure
        @test issubset(states.L00.closure, states.L01.closure)

        menus = NamedTuple{keys(fixture.menus)}(
            Tuple(action_label.(menu) for menu in values(fixture.menus)),
        )
        @test menus == expected_menus
        @test all(
            row -> row.law ==
                   raw_embedded_transition(
                fixture.process,
                row.belief,
                row.library,
                row.action,
            ),
            fixture.transitions,
        )
        @test all(
            row -> row.value ==
                   raw_finite_horizon_value(
                fixture.process,
                row.horizon,
                row.belief,
                getproperty(libraries, row.corner),
            ),
            fixture.values,
        )
        @test fixture.consistency.project_laws_follow_corner_closure
        @test fixture.consistency.transition_pushforwards_agree
        @test fixture.consistency.finite_values_agree
    end

    identity_fixture = first(fixtures)
    identity_states = rectangle_states(identity_fixture.rectangle)
    @test identity_states.L00.closure == ModuleSet([ModuleId(:core)])
    @test identity_states.L01.closure ==
          ModuleSet([ModuleId(:core), ModuleId(:expansion)])
    @test all(
        iszero,
        operational_profile(
            identity_fixture.rectangle.catalog,
            only(identity_fixture.rectangle.closure_strategies),
        ).values,
    )

    generated_fixture = last(fixtures)
    generated_rectangle = generated_fixture.rectangle
    generated_states = rectangle_states(generated_rectangle)
    @test raw_module_union(
        generated_rectangle.catalog,
        generated_rectangle.L01,
    ) == ModuleSet([ModuleId(:core), ModuleId(:trigger)])
    @test generated_states.L01.closure ==
          ModuleSet([
        ModuleId(:core),
        ModuleId(:trigger),
        ModuleId(:bridge),
    ])
    @test collect(
        operational_profile(
            generated_rectangle.catalog,
            only(generated_rectangle.closure_strategies),
        ).values,
    ) == ExactRational[1, 2]
    @test generated_states.L01.frontier == generated_states.L00.frontier

    @test_throws ArgumentError construct_realizable_rectangle(
        identity_fixture.rectangle.catalog,
        identity_fixture.rectangle.closure,
        identity_fixture.rectangle.L00,
        only(identity_fixture.rectangle.closure_strategies),
        only(identity_fixture.rectangle.frontier_strategies),
    )
    @test_throws ArgumentError construct_realizable_rectangle(
        identity_fixture.rectangle.catalog,
        identity_fixture.rectangle.closure,
        identity_fixture.rectangle.L00,
        StrategyId(:base),
        only(identity_fixture.rectangle.closure_strategies),
    )
    multi_frontier = construct_realizable_rectangle(
        identity_fixture.rectangle.catalog,
        identity_fixture.rectangle.closure,
        identity_fixture.rectangle.L00,
        [StrategyId(:frontier_only), StrategyId(:core_descendant)],
        collect(identity_fixture.rectangle.closure_strategies),
    )
    @test length(multi_frontier.frontier_strategies) == 2
    @test collect(rectangle_states(multi_frontier).L10.frontier.values) ==
          ExactRational[8, 10]
    @test_throws ArgumentError rectangle_raw_values(
        identity_fixture.rectangle,
        identity_fixture.process,
        0,
    )
end
