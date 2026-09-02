module AuditFinancialStrategyLibraryPanelV2

using SHA: sha256
using TOML

include(joinpath(@__DIR__, "create_financial_strategy_library_panel_v2_flagship_registries.jl"))
using .FinancialStrategyLibraryPanelV2FlagshipRegistries
const FinancialStrategyLibraryPanelV2Registries =
    FinancialStrategyLibraryPanelV2FlagshipRegistries

export audit_and_promote, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v2",
)
const LOCAL_DATA_ROOT = joinpath(EXPERIMENT_ROOT, "local_data")
const LOCAL_RESULTS_ROOT = joinpath(EXPERIMENT_ROOT, "local_results")
const PREDECISION_ROOT = joinpath(LOCAL_RESULTS_ROOT, "predecision")
const POSTDECISION_ROOT = joinpath(LOCAL_RESULTS_ROOT, "postdecision")
const ANALYSIS_ROOT = joinpath(LOCAL_RESULTS_ROOT, "analysis")
const PUBLIC_ROOT = joinpath(EXPERIMENT_ROOT, "results")

_sha256_text(text) = bytes2hex(sha256(codeunits(text)))
_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

function _directory_aggregate(directory)
    entries = Dict{String,String}()
    for (root, _, files) in walkdir(directory), file in files
        path = joinpath(root, file)
        entries[relpath(path, directory)] = _sha256_file(path)
    end
    return _sha256_text(join(
        ("$path\0$(entries[path])\n" for path in sort!(collect(keys(entries)))),
    ))
end

function _toml_text(payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end

function _atomic_toml(path, payload)
    mkpath(dirname(path))
    temporary = path * ".tmp.$(getpid())"
    open(temporary, "w") do io
        write(io, _toml_text(payload))
    end
    mv(temporary, path; force = false)
    return path
end

function _rational(text)
    numerator, denominator = split(String(text), "//")
    return parse(BigInt, numerator) // parse(BigInt, denominator)
end

function _certificate(id, errors, checks)
    return Dict{String,Any}(
        "audit_id" => id,
        "passed" => isempty(errors),
        "check_count" => checks,
        "errors" => errors,
    )
end

function _source_audit()
    errors = String[]
    path = joinpath(LOCAL_RESULTS_ROOT, "SOURCE_AUDIT.toml")
    isfile(path) || push!(errors, "source audit artifact is absent")
    checks = 1
    if isempty(errors)
        payload = TOML.parsefile(path)
        payload["required_schema_passed"] === true || push!(errors, "required schema did not pass")
        length(payload["source_files"]) == 4 || push!(errors, "source audit does not bind four files")
        all(row -> occursin(r"^[0-9a-f]{64}$", row["sha256"]), payload["source_files"]) ||
            push!(errors, "source file digest is malformed")
        checks += 3
    end
    return _certificate("source_schema_duplicate_and_point_in_time_access", errors, checks)
end

function _registry_seed_audit(pre_files)
    errors = String[]
    checks = 0
    seed_lookup = Dict(
        (row.origin_id, row.docket_id) => row for
        row in FinancialStrategyLibraryPanelV2Registries.seed_rows()
    )
    for path in pre_files
        payload = TOML.parsefile(path)
        key = (String(payload["origin_id"]), String(payload["docket_id"]))
        row = get(seed_lookup, key, nothing)
        !isnothing(row) && string(row.menu_seed) == payload["menu_seed"] ||
            push!(errors, "registered menu seed mismatch for $(join(key, '/'))")
        !isnothing(row) && string(row.multistart_seed) == payload["multistart_seed"] ||
            push!(errors, "registered multistart seed mismatch for $(join(key, '/'))")
        payload["seed_namespace"] == FinancialStrategyLibraryPanelV2Registries.seed_namespace() ||
            push!(errors, "seed namespace mismatch for $(join(key, '/'))")
        payload["menu_generation_algorithm"] == "stable_rng_rotating_12_strata_v1" ||
            push!(errors, "menu generator mismatch for $(join(key, '/'))")
        checks += 4
    end
    return _certificate("registry_and_seed_replay", errors, checks)
end

function _master_panel_audit()
    errors = String[]
    checks = 0
    root = joinpath(LOCAL_DATA_ROOT, "master_market_panel")
    manifest_path = joinpath(root, "MASTER_MANIFEST.toml")
    isfile(manifest_path) || return _certificate("adopted_master_panel", ["master manifest absent"], 1)
    manifest = TOML.parsefile(manifest_path)
    expected_aggregate = "585fe9f1312dd00c5633e750021cafef83e830b2e0da9029d20576c6c0bd5a61"
    expected_manifest = "0aaec2b748a9e2043b8ce6583b4318874b4efd8abbfa9a10b197df6d5e124e2d"
    _sha256_file(manifest_path) == expected_manifest || push!(errors, "master manifest digest changed")
    _directory_aggregate(root) == expected_aggregate || push!(errors, "master directory aggregate changed")
    manifest["schema_version"] == "financial-panel-v2-master-market-panel-v1" ||
        push!(errors, "master schema changed")
    manifest["study_start"] == "2000-01-01" || push!(errors, "master start changed")
    manifest["study_end"] == "2025-12-31" || push!(errors, "master end changed")
    manifest["instrument_classes"] == ["common_equity", "plain_etf"] ||
        push!(errors, "master instrument classes changed")
    manifest["chunk_count"] == 155 || push!(errors, "master chunk count changed")
    manifest["retained_master_rows"] == 38_327_975 || push!(errors, "master row count changed")
    sum(Int(row["row_count"]) for row in manifest["chunks"]) == 38_327_975 ||
        push!(errors, "manifest chunk rows do not reconcile")
    names = Set(String(row["path"]) for row in manifest["chunks"])
    actual = Set(relpath(joinpath(dir, file), root) for (dir, _, files) in walkdir(root) for file in files)
    expected = union(names, Set(("MASTER_MANIFEST.toml", "security_intervals.parquet", "security_intervals.toml")))
    actual == expected || push!(errors, "master file set differs from manifest")
    intervals = TOML.parsefile(joinpath(root, "security_intervals.toml"))
    _sha256_file(joinpath(root, "security_intervals.parquet")) == intervals["parquet_sha256"] ||
        push!(errors, "security interval digest changed")
    lock_text = read(joinpath(EXPERIMENT_ROOT, "EXECUTION_LOCK_011.json"), String)
    occursin("\"adopted_master_directory_aggregate_sha256\": \"$expected_aggregate\"", lock_text) ||
        push!(errors, "execution lock does not adopt master aggregate")
    checks += 12
    return _certificate("adopted_master_panel", errors, checks)
end

function _origin_universe_audit(origin_status_files)
    errors = String[]
    checks = 0
    for path in origin_status_files
        payload = TOML.parsefile(path)
        payload["terminal"] === true || push!(errors, "nonterminal origin status")
        payload["structurally_evaluable"] === true ||
            push!(errors, "flagship origin was not structurally evaluable: " * String(payload["origin_id"]))
        payload["hard_profile_support_eligibility_gate"] === false ||
            push!(errors, "legacy profile gate remained active")
        payload["complete_predecision_count"] >= 100 ||
            push!(errors, "fewer than 100 complete securities")
        selected = payload["selected"]
        length(selected) == 100 || push!(errors, "origin did not retain exactly 100 securities")
        any(row -> row["ticker"] == "SPY", selected) || push!(errors, "SPY not retained")
        ordering = [(Float64(row["median_dollar_volume"]), Int(row["permno"])) for row in selected]
        issorted(ordering; by = row -> (-row[1], row[2])) || push!(errors, "liquidity ordering changed")
        sum(values(payload["selected_instrument_class_counts"])) == length(selected) ||
            push!(errors, "instrument-class census does not reconcile")
        checks += 8
    end
    return _certificate("complete_calendar_liquid_universe", errors, checks)
end

function _arm_audit(pre_files)
    errors = String[]
    checks = 0
    required_arms = Set(row.arm_id for row in FinancialStrategyLibraryPanelV2Registries.arm_rows())
    required_schedules = Set(row.schedule_id for row in FinancialStrategyLibraryPanelV2Registries.burden_rows())
    for path in pre_files
        payload = TOML.parsefile(path)
        Set(keys(payload["arms"])) == required_schedules ||
            push!(errors, "schedule coverage mismatch in $(basename(path))")
        for (schedule_id, arms) in payload["arms"]
            Set(keys(arms)) == required_arms ||
                push!(errors, "arm coverage mismatch in $(basename(path))/$schedule_id")
            for arm in values(arms)
                arm["terminal"] === true || push!(errors, "nonterminal arm row")
            end
            safe = arms[String(payload["primary_safe_arm_id"])]
            comparator = arms["frontier_only_budget_matched"]
            if safe["candidate_returned"] === true
                safe["selection"]["exact_feasible"] === true || push!(errors, "safe arm infeasible")
                safe["selection"]["frontier_preserved"] === true || push!(errors, "safe frontier lost")
                safe["selection"]["closure_preserved"] === true || push!(errors, "safe closure lost")
            end
            if comparator["candidate_returned"] === true
                comparator["selection"]["exact_feasible"] === true || push!(errors, "comparator infeasible")
                comparator["selection"]["frontier_preserved"] === true || push!(errors, "comparator frontier lost")
                burden = _rational(comparator["selection"]["exact_burden"])
                cap = _rational(comparator["exact_burden_cap"])
                slack = _rational(comparator["exact_unused_slack"])
                burden <= cap || push!(errors, "comparator exceeds safe budget")
                cap - burden == slack || push!(errors, "comparator slack does not reconcile")
            end
            checks += 12
        end
    end
    return _certificate("frontier_closure_burden_order_and_arm_certificates", errors, checks)
end

function _challenge_audit(pre_files)
    errors = String[]
    checks = 0
    for path in pre_files
        payload = TOML.parsefile(path)
        source_ids = Set(String.(payload["source_strategy_ids"]))
        length(payload["menus"]) == 32 || push!(errors, "menu count mismatch")
        for menu in payload["menus"]
            ids = String.(menu["candidate_ids"])
            length(ids) == 8 && length(unique(ids)) == 8 ||
                push!(errors, "menu candidate count/distinctness mismatch")
            isempty(intersect(Set(ids), source_ids)) || push!(errors, "menu contains source candidate")
            strata = Set{Tuple{String,String,String}}()
            for id in ids
                parts = split(id, '|')
                length(parts) == 8 || begin
                    push!(errors, "malformed menu candidate identifier")
                    continue
                end
                push!(strata, (parts[3], "$(parts[3])+$(parts[4])", parts[8]))
            end
            length(strata) == 8 || push!(errors, "menu does not use eight distinct combined strata")
            checks += 4
        end
        source_choices = payload["choices"]["source"]
        safe_choices = payload["choices"][String(payload["primary_safe_arm_id"])]
        for index in eachindex(source_choices)
            get(source_choices[index], "candidate_id", "") ==
            get(safe_choices[index], "candidate_id", "") ||
                push!(errors, "source and safe frozen choices disagree")
            checks += 1
        end
    end
    return _certificate("challenge_generation_frozen_choice_and_predecision_seal", errors, checks)
end

function _seal_audit(pre_files)
    errors = String[]
    path = joinpath(LOCAL_RESULTS_ROOT, "PREDECISION_SEAL.toml")
    isfile(path) || push!(errors, "predecision seal is absent")
    checks = 1
    if isempty(errors)
        seal = TOML.parsefile(path)
        seal["postdecision_opened_before_seal"] === false || push!(errors, "postdecision opened before seal")
        seal["verified_before_postdecision_open"] === true || push!(errors, "seal was not verified")
        seal["predecision_file_count"] == length(pre_files) || push!(errors, "sealed file count mismatch")
        _directory_aggregate(PREDECISION_ROOT) == seal["predecision_directory_sha256"] ||
            push!(errors, "predecision directory digest mismatch")
        checks += 4
    end
    return _certificate("information_firewall_and_hash_chain", errors, checks)
end

function _calendar_availability_audit(post_files)
    errors = String[]
    checks = 0
    for path in post_files
        payload = TOML.parsefile(path)
        payload["predecision_seal_verified_before_open"] === true ||
            push!(errors, "postdecision payload lacks verified seal")
        length(payload["menus"]) == 32 || push!(errors, "postdecision menu count mismatch")
        observed_complete = count(row -> row["complete_primary_pair"] === true, payload["menus"])
        observed_complete == payload["complete_primary_menu_pairs"] ||
            push!(errors, "complete-pair count mismatch")
        (observed_complete >= 24) == payload["origin_docket_menu_gate_passed"] ||
            push!(errors, "origin-docket menu gate mismatch")
        all(row -> row["terminal"] === true, payload["menus"]) ||
            push!(errors, "nonterminal menu result")
        checks += 5
    end
    return _certificate("calendar_delisting_missingness_and_availability_gate", errors, checks)
end

function _estimand_audit(post_files)
    errors = String[]
    checks = 0
    docket_estimates = Dict{Tuple{String,String},Tuple{Bool,Float64,Int}}()
    for path in post_files
        payload = TOML.parsefile(path)
        values = Float64[
            row["heldout_innovation_utility_delta"] for row in payload["menus"] if
            row["complete_primary_pair"] === true
        ]
        gate = length(values) >= 24
        mean_value = gate ? sum(values) / length(values) : 0.0
        docket_estimates[(payload["origin_id"], payload["docket_id"])] =
            (gate, mean_value, length(values))
    end
    recorded = TOML.parsefile(joinpath(ANALYSIS_ROOT, "ORIGIN_DOCKET_CONTRASTS.toml"))["rows"]
    for row in recorded
        key = (String(row["origin_id"]), String(row["docket_id"]))
        gate, mean_value, count_value = docket_estimates[key]
        gate == row["menu_gate_passed"] || push!(errors, "replayed docket gate mismatch")
        count_value == row["complete_menu_pairs"] || push!(errors, "replayed docket denominator mismatch")
        isapprox(mean_value, Float64(row["origin_docket_mean"]); atol = 0, rtol = 1e-14) ||
            push!(errors, "replayed docket mean mismatch")
        checks += 3
    end
    return _certificate("estimand_and_bootstrap_replay", errors, checks)
end

function _stress_audit(pre_files)
    errors = String[]
    checks = 0
    for path in pre_files
        payload = TOML.parsefile(path)
        for arms in values(payload["arms"])
            stress = arms["innovation_safe_exact"]["stress_block"]
            stress["warmup_outside_timed_region"] === true || push!(errors, "stress warmup is inside timing")
            stress["timed_scope"] == "HiGHS optimization search only" || push!(errors, "stress timing scope mismatch")
            if stress["admitted"] === true
                if stress["timing_deferred_to_separate_benchmark"] === true
                    isempty(stress["search_wall_ns"]) ||
                        push!(errors, "deferred stress cell contains inline timings")
                else
                    length(stress["search_wall_ns"]) == stress["steady_state_repetitions"] ||
                        push!(errors, "stress repetition count mismatch")
                end
            else
                isempty(stress["search_wall_ns"]) || push!(errors, "rejected stress cell contains timings")
            end
            checks += 3
        end
    end
    return _certificate("computational_stress_membership_and_timing_scope", errors, checks)
end

function _public_boundary_audit()
    errors = String[]
    summary = TOML.parsefile(joinpath(ANALYSIS_ROOT, "PRIMARY_SUMMARY.toml"))
    summary["licensed_rows_included"] === false || push!(errors, "analysis summary flags licensed rows")
    origins = TOML.parsefile(joinpath(ANALYSIS_ROOT, "ORIGIN_CONTRASTS.toml"))["rows"]
    for row in origins
        Set(keys(row)) <= Set((
            "origin_id",
            "menu_gate_passed_both_dockets",
            "available_docket_count",
            "cross_docket_origin_mean",
            "reason",
        )) || push!(errors, "origin contrast contains a non-whitelisted field")
    end
    return _certificate("public_whitelist_and_licensed_data_boundary", errors, length(origins) + 1)
end

function _public_csv(rows)
    header = [
        "origin_id",
        "menu_gate_passed_both_dockets",
        "available_docket_count",
        "cross_docket_origin_mean",
        "reason",
    ]
    output = IOBuffer()
    println(output, join(header, ','))
    for row in rows
        println(output, join((string(get(row, key, "")) for key in header), ','))
    end
    return String(take!(output))
end

function audit_and_promote()
    origin_status_files = sort!(filter(
        path -> endswith(path, ".toml"),
        [joinpath(root, file) for (root, _, files) in walkdir(joinpath(LOCAL_DATA_ROOT, "origin_status")) for file in files],
    ))
    length(origin_status_files) == 20 || error("origin status census is not 20")
    all(path -> TOML.parsefile(path)["terminal"] === true, origin_status_files) ||
        error("origin status census contains a nonterminal row")
    pre_files = sort!(filter(
        path -> endswith(path, ".toml"),
        [joinpath(root, file) for (root, _, files) in walkdir(PREDECISION_ROOT) for file in files],
    ))
    post_files = sort!(filter(
        path -> endswith(path, ".toml"),
        [joinpath(root, file) for (root, _, files) in walkdir(POSTDECISION_ROOT) for file in files],
    ))
    length(pre_files) == 40 || error("flagship predecision file census is not 40")
    length(post_files) == 40 || error("flagship postdecision file census is not 40")
    certificates = [
        _source_audit(),
        _master_panel_audit(),
        _origin_universe_audit(origin_status_files),
        _registry_seed_audit(pre_files),
        _arm_audit(pre_files),
        _challenge_audit(pre_files),
        _seal_audit(pre_files),
        _calendar_availability_audit(post_files),
        _estimand_audit(post_files),
        _stress_audit(pre_files),
        _public_boundary_audit(),
    ]
    passed = all(certificate -> certificate["passed"] === true, certificates)
    payload = Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v2-independent-audit-v1",
        "passed" => passed,
        "certificate_count" => length(certificates),
        "certificates" => certificates,
        "public_promotion_authorized" => passed,
        "licensed_rows_included" => false,
    )
    _atomic_toml(joinpath(LOCAL_RESULTS_ROOT, "INDEPENDENT_AUDIT.toml"), payload)
    passed || error("v2 independent audit failed; public promotion is blocked")
    isdir(PUBLIC_ROOT) && !isempty(readdir(PUBLIC_ROOT)) &&
        error("v2 public result directory already exists and will not be overwritten")
    mkpath(PUBLIC_ROOT)
    summary = TOML.parsefile(joinpath(ANALYSIS_ROOT, "PRIMARY_SUMMARY.toml"))
    origin_rows = TOML.parsefile(joinpath(ANALYSIS_ROOT, "ORIGIN_CONTRASTS.toml"))["rows"]
    _atomic_toml(joinpath(PUBLIC_ROOT, "PRIMARY_SUMMARY.toml"), summary)
    _atomic_toml(joinpath(PUBLIC_ROOT, "AUDIT_CERTIFICATES.toml"), payload)
    open(joinpath(PUBLIC_ROOT, "ORIGIN_LEVEL_PAIRED_CONTRASTS.csv"), "w") do io
        write(io, _public_csv(origin_rows))
    end
    return payload
end

function main(args = ARGS)
    length(args) == 1 && only(args) == "--audit-and-promote" || error(
        "usage: audit_financial_strategy_library_panel_v2.jl --audit-and-promote",
    )
    println(audit_and_promote())
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    AuditFinancialStrategyLibraryPanelV2.main()
end
