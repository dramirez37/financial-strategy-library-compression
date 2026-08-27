using SHA: sha256
using TOML


function _exactness_provenance(instance_id; redistributable = true)
    return JournalCompressionProvenance(
        :synthetic,
        String(instance_id),
        "independent exactness-audit test fixture";
        generator = "test_journal_exactness_audit",
        attributes = ["evidence_class" => "exact finite solver fixture"],
        redistributable,
    )
end


function _exactness_fixture(
    instance_id,
    ids,
    mandatory,
    weights,
    modules;
    redistributable = true,
    tie_handling = default_journal_tie_handling(),
)
    return journal_compression_instance_from_components(
        ids,
        mandatory,
        weights,
        [:zero_frontier],
        zeros(Int, length(ids), 1),
        modules;
        tie_handling,
        provenance = _exactness_provenance(
            instance_id;
            redistributable,
        ),
    )
end


function _directory_content_hashes(directory)
    rows = Pair{String,String}[]
    for (path, _, files) in walkdir(directory), file in sort(files)
        full_path = joinpath(path, file)
        push!(
            rows,
            relpath(full_path, directory) => bytes2hex(sha256(read(full_path))),
        )
    end
    sort!(rows; by = first)
    return rows
end


@testset "live three-method exactness audit" begin
    instance = _exactness_fixture(
        "triangle",
        [:inactive, :a, :b, :c],
        Bool[true, false, false, false],
        [0, 2, 2, 2],
        [Symbol[], [:m1, :m2], [:m2, :m3], [:m1, :m3]],
    )
    audit = audit_journal_small_instance(
        instance;
        random_seed = 31,
        time_limit = 10.0,
    )
    @test audit.passed
    @test audit.all_methods_completed
    @test audit.objective_values_agree === true
    @test audit.reconstructed_optimizers_compared
    @test audit.enumeration.exact_burden == 4
    @test audit.dynamic_programming.exact_burden == 4
    @test audit.mip.exact_burden == 4
    @test audit.enumeration.exact_feasible === true
    @test audit.dynamic_programming.exact_feasible === true
    @test audit.mip.exact_feasible === true
    @test audit.mip_solver_claimed_optimal === true
    @test audit.second_solver_status ==
          "unavailable: no second open-source solver is pinned in the Julia environments"
    keys = [
        Tuple(findall(audit.enumeration.selected)),
        Tuple(findall(audit.dynamic_programming.selected)),
        Tuple(findall(audit.mip.selected)),
    ]
    @test audit.optimizer_identities_differ == (length(Set(keys)) > 1)
    @test audit.enumeration_dp_same_optimizer == (keys[1] == keys[2])
    @test audit.enumeration_mip_same_optimizer == (keys[1] == keys[3])

    payload = journal_exactness_audit_certificate(audit)
    @test payload["solver_optimality_is_formal_proof"] == false
    @test payload["objective_values_agree"]["value"] == true
    @test length(payload["algorithms"]) == 3
end


@testset "small exactness certificate bundles and nonmutating offline audit" begin
    instance = _exactness_fixture(
        "bundle",
        [:inactive, :left, :right, :bundle],
        Bool[true, false, false, false],
        [0, 1, 1, 3],
        [Symbol[], [:m1], [:m2], [:m1, :m2]],
    )
    mktempdir() do root
        bundle_path = joinpath(root, "small")
        written = write_journal_small_exactness_audit_bundle(
            bundle_path,
            instance;
            random_seed = 4,
            time_limit = 10.0,
        )
        @test written.audit.passed
        @test written.artifact_count == 5
        @test occursin(r"^[0-9a-f]{64}$", written.manifest_sha256)
        @test sort(readdir(bundle_path)) == [
            "certificate_manifest.toml",
            "dp.toml",
            "enumeration.toml",
            "exactness_audit.toml",
            "instance.toml",
            "mip.toml",
        ]
        manifest = TOML.parsefile(joinpath(bundle_path, "certificate_manifest.toml"))
        @test manifest["hash_algorithm"] == "SHA-256"
        @test length(manifest["artifacts"]) == 5

        before = _directory_content_hashes(root)
        offline = audit_journal_result_directory(root)
        after = _directory_content_hashes(root)
        @test before == after
        @test offline.passed
        @test offline.bundle_count == 1
        @test offline.small_bundle_count == 1
        @test offline.bundles[1].objective_values_agree === true
        @test offline.bundles[1].exact_candidate_feasible === true

        cli_output = IOBuffer()
        cli_audit = JournalExactnessAuditCLI.main([root]; output = cli_output)
        @test cli_audit.passed
        @test TOML.parse(String(take!(cli_output)))["audit_mode"] ==
              "saved-certificates-only; no solver invocation"
        @test before == _directory_content_hashes(root)

        @test_throws ArgumentError write_journal_small_exactness_audit_bundle(
            bundle_path,
            instance;
            minimize_failure = false,
        )
    end
end


@testset "MIP-only bound diagnostics and exact recheck" begin
    instance = _exactness_fixture(
        "mip-only",
        [:inactive, :left, :right, :bundle],
        Bool[true, false, false, false],
        [0, 2, 3, 6],
        [Symbol[], [:m1], [:m2], [:m1, :m2]],
    )
    mip = solve_journal_compression_mip(
        instance;
        random_seed = 7,
        time_limit = 10.0,
        exact_crosscheck = :none,
    )
    live = audit_journal_mip_output(instance, mip)
    @test live.passed
    @test live.certified_candidate_available
    @test live.exact_candidate_feasible === true
    @test live.burden_reconciled === true
    @test live.solver_optimality_is_formal_proof == false
    @test live.termination_status == "OPTIMAL"
    @test !ismissing(live.best_bound)

    mktempdir() do root
        bundle = write_journal_mip_exactness_audit_bundle(
            joinpath(root, "medium"),
            instance,
            mip,
        )
        @test bundle.artifact_count == 3
        offline = audit_journal_result_directory(root)
        @test offline.passed
        @test offline.mip_only_bundle_count == 1
        @test offline.bundles[1].certified_candidate_available
        @test offline.bundles[1].mip_termination_status == "OPTIMAL"
        @test !ismissing(offline.bundles[1].mip_best_bound)
    end
end


@testset "hash disagreement is retained and fails offline audit" begin
    instance = _exactness_fixture(
        "tamper",
        [:inactive, :carrier],
        Bool[true, false],
        [0, 1],
        [Symbol[], [:m]],
    )
    mktempdir() do root
        bundle_path = joinpath(root, "small")
        write_journal_small_exactness_audit_bundle(
            bundle_path,
            instance;
            random_seed = 9,
            time_limit = 10.0,
        )
        mip_path = joinpath(bundle_path, "mip.toml")
        open(mip_path, "a") do io
            write(io, "\n# deliberate test corruption\n")
        end
        audit = audit_journal_result_directory(root)
        @test !audit.passed
        @test any(occursin("SHA-256 mismatch", error) for error in audit.bundles[1].errors)

        open(mip_path, "w") do io
            write(io, "[invalid")
        end
        parse_audit = audit_journal_result_directory(root)
        @test !parse_audit.passed
        @test any(
            occursin("cannot parse or audit certificate payload", error) for
            error in parse_audit.bundles[1].errors
        )
    end
    mktempdir() do empty_root
        audit = audit_journal_result_directory(empty_root)
        @test !audit.passed
        @test audit.errors == ["no certificate manifests found"]
    end
end


@testset "failing-fixture minimizer and licensed-data write guard" begin
    instance = _exactness_fixture(
        "minimize",
        [:inactive, :a, :b, :c],
        Bool[true, false, false, false],
        [0, 1, 1, 1],
        [Symbol[], [:m1], [:m2], [:m1, :m2]],
    )
    predicate = candidate ->
        length(candidate.strategy_ids) >= 2 &&
        length(candidate.source_closure) >= 1
    minimized, status = StrategyInnovation._journal_minimize_failure(
        instance,
        predicate,
    )
    @test predicate(minimized)
    @test length(minimized.strategy_ids) == 2
    @test length(minimized.source_closure) == 1
    @test occursin("deletion fixed point", status)
    for index in eachindex(minimized.strategy_ids)
        minimized.mandatory[index] && continue
        @test !all(
            any(
                minimized.coverage[row, column] for
                column in eachindex(minimized.strategy_ids) if column != index
            ) for row in axes(minimized.coverage, 1)
        )
    end

    complete_ties = JournalTieHandling(
        :complete;
        declaration = "all optimizer identities required",
        stable_selector = "canonical strategy order",
    )
    unsupported = _exactness_fixture(
        "complete-tie-mip-boundary",
        [:inactive, :left, :right],
        Bool[true, false, false],
        [0, 1, 1],
        [Symbol[], [:m], [:m]];
        tie_handling = complete_ties,
    )
    failed = audit_journal_small_instance(
        unsupported;
        random_seed = 2,
        time_limit = 10.0,
    )
    @test !failed.passed
    @test !isnothing(failed.minimized_failure_instance)
    @test failed.enumeration.completed
    @test failed.dynamic_programming.completed
    @test !failed.mip.completed
    mktempdir() do root
        bundle = write_journal_small_exactness_audit_bundle(
            joinpath(root, "failure"),
            unsupported;
            random_seed = 2,
            time_limit = 10.0,
        )
        @test isfile(joinpath(bundle.directory, "minimized_failure_instance.toml"))
        @test isfile(joinpath(bundle.directory, "mip_error.toml"))
        @test !audit_journal_result_directory(root).passed
    end

    restricted = _exactness_fixture(
        "licensed-boundary",
        [:inactive, :carrier],
        Bool[true, false],
        [0, 1],
        [Symbol[], [:m]];
        redistributable = false,
    )
    mktempdir() do root
        @test_throws ArgumentError write_journal_small_exactness_audit_bundle(
            joinpath(root, "forbidden"),
            restricted;
            minimize_failure = false,
        )
    end
end


@testset "committed small benchmark matrix triangulates exactly" begin
    audited = 0
    for active_count in 1:2, module_count in 1:3
        carrier_pattern_count = (1 << active_count) - 1
        for encoded_system in 0:(carrier_pattern_count^module_count - 1)
            digits = Int[]
            remainder = encoded_system
            for _ in 1:module_count
                push!(digits, (remainder % carrier_pattern_count) + 1)
                remainder = div(remainder, carrier_pattern_count)
            end
            ids = Symbol[:inactive; [Symbol("s$index") for index in 1:active_count]]
            modules = [Symbol[] for _ in ids]
            for module_index in 1:module_count
                carrier_mask = digits[module_index]
                for active_index in 1:active_count
                    iszero(carrier_mask & (1 << (active_index - 1))) && continue
                    push!(modules[active_index + 1], Symbol("m$module_index"))
                end
            end
            weights = Any[0; [BigInt(index + encoded_system % 2) // BigInt(1) for index in 1:active_count]]
            instance = _exactness_fixture(
                "matrix-a$(active_count)-m$(module_count)-$encoded_system",
                ids,
                Bool[true; falses(active_count)],
                weights,
                modules,
            )
            audit = audit_journal_small_instance(
                instance;
                random_seed = 100 + audited,
                time_limit = 10.0,
                minimize_failure = true,
            )
            @test audit.passed
            @test isnothing(audit.minimized_failure_instance)
            audited += 1
        end
    end
    @test audited == 42
end
