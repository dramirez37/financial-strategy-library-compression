const JOURNAL_EXACTNESS_AUDIT_SCHEMA_VERSION =
    "journal-compression-exactness-audit-v1"
const JOURNAL_EXACTNESS_MANIFEST_SCHEMA_VERSION =
    "journal-compression-exactness-manifest-v1"


"""One independently recertified representative returned by an algorithm."""
struct JournalExactnessAlgorithmOutcome
    algorithm::Symbol
    completed::Bool
    exact_burden::Union{Missing,ExactRational}
    selected::Union{Nothing,BitVector}
    exact_feasible::Union{Missing,Bool}
    burden_reconciled::Union{Missing,Bool}
    error_type::String
    error_message::String
end


"""
    JournalExactnessAuditResult

Live, three-method audit of one small instance. A passing result requires two
complete exact finite searches and a conclusive HiGHS pipeline, exact equality
of all three burdens, and independent feasibility checks in original instance
coordinates. Equal objectives do not require equal optimizer identities.
"""
struct JournalExactnessAuditResult
    schema_version::String
    instance_sha256::String
    passed::Bool
    all_methods_completed::Bool
    objective_values_agree::Union{Missing,Bool}
    reconstructed_optimizers_compared::Bool
    optimizer_identities_differ::Union{Missing,Bool}
    enumeration_dp_same_optimizer::Union{Missing,Bool}
    enumeration_mip_same_optimizer::Union{Missing,Bool}
    dp_mip_same_optimizer::Union{Missing,Bool}
    enumeration::JournalExactnessAlgorithmOutcome
    dynamic_programming::JournalExactnessAlgorithmOutcome
    mip::JournalExactnessAlgorithmOutcome
    mip_solver_claimed_optimal::Union{Missing,Bool}
    mip_solved_by_exact_preprocessing::Union{Missing,Bool}
    mip_termination_status::String
    mip_best_bound::Union{Missing,Float64}
    mip_reported_relative_gap::Union{Missing,Float64}
    second_solver_status::String
    notes::Vector{String}
    enumeration_result::Union{Nothing,JournalExactSolutionResult}
    dynamic_programming_result::Union{Nothing,JournalExactSolutionResult}
    mip_result::Union{Nothing,JournalMIPSolutionResult}
    minimized_failure_instance::Union{Nothing,JournalCompressionInstance}
    minimization_status::String
end


"""Read-only audit outcome for one certificate bundle."""
struct JournalExactnessBundleAudit
    relative_path::String
    bundle_kind::Symbol
    passed::Bool
    instance_sha256::String
    objective_values_agree::Union{Missing,Bool}
    optimizer_identities_differ::Union{Missing,Bool}
    certified_candidate_available::Bool
    exact_candidate_feasible::Union{Missing,Bool}
    mip_termination_status::String
    mip_best_bound::Union{Missing,Float64}
    mip_reported_relative_gap::Union{Missing,Float64}
    errors::Vector{String}
end


"""Aggregate result returned by the nonmutating result-directory auditor."""
struct JournalExactnessDirectoryAudit
    schema_version::String
    root::String
    passed::Bool
    bundle_count::Int
    small_bundle_count::Int
    mip_only_bundle_count::Int
    bundles::Vector{JournalExactnessBundleAudit}
    errors::Vector{String}
end


function _journal_exactness_outcome(
    algorithm::Symbol,
    instance::JournalCompressionInstance,
    result::JournalExactSolutionResult,
)
    certificate = check_journal_compression_solution(
        instance,
        result.selected;
        expected_burden = result.exact_burden,
    )
    return JournalExactnessAlgorithmOutcome(
        algorithm,
        true,
        result.exact_burden,
        copy(result.selected),
        certificate.exact_feasible,
        certificate.burden_reconciled,
        "",
        "",
    )
end


function _journal_exactness_outcome(
    instance::JournalCompressionInstance,
    result::JournalMIPSolutionResult,
)
    if result.candidate_accepted
        certificate = check_journal_compression_solution(
            instance,
            result.reconstructed_candidate;
            expected_burden = result.exact_burden,
        )
        return JournalExactnessAlgorithmOutcome(
            :jump_highs_tagged_cover,
            true,
            result.exact_burden,
            copy(result.reconstructed_candidate),
            certificate.exact_feasible,
            certificate.burden_reconciled,
            "",
            "",
        )
    end
    return JournalExactnessAlgorithmOutcome(
        :jump_highs_tagged_cover,
        true,
        missing,
        nothing,
        missing,
        missing,
        "",
        "MIP returned no exactly certified candidate: $(result.status)",
    )
end


function _journal_failed_outcome(algorithm::Symbol, error)
    return JournalExactnessAlgorithmOutcome(
        algorithm,
        false,
        missing,
        nothing,
        missing,
        missing,
        string(typeof(error)),
        sprint(showerror, error),
    )
end


function _journal_capture_exact(solve, instance, algorithm::Symbol)
    try
        result = solve()
        return _journal_exactness_outcome(algorithm, instance, result), result
    catch error
        return _journal_failed_outcome(algorithm, error), nothing
    end
end


function _journal_capture_mip(solve, instance)
    try
        result = solve()
        return _journal_exactness_outcome(instance, result), result
    catch error
        return _journal_failed_outcome(:jump_highs_tagged_cover, error), nothing
    end
end


_journal_outcome_selection_key(outcome::JournalExactnessAlgorithmOutcome) =
    isnothing(outcome.selected) ? nothing : Tuple(findall(outcome.selected))


function _journal_optional_equality(left, right)
    (isnothing(left) || isnothing(right)) && return missing
    return left == right
end


function _journal_all_equal(values)
    any(ismissing, values) && return missing
    return all(value == first(values) for value in values)
end


function _journal_mip_conclusive(result::Union{Nothing,JournalMIPSolutionResult})
    isnothing(result) && return false, missing, missing
    preprocessing_only = !result.diagnostics.solver_invoked &&
                         result.preprocessing.reduced_strategy_count == 0 &&
                         result.preprocessing.reduced_requirement_count == 0 &&
                         result.candidate_accepted
    return result.solver_claimed_optimal || preprocessing_only,
           result.solver_claimed_optimal,
           preprocessing_only
end


function _journal_small_audit_core(
    instance::JournalCompressionInstance;
    random_seed::Integer,
    time_limit,
    maximum_optional_strategies::Integer,
    maximum_ties::Integer,
)
    validate_journal_compression_instance(instance)
    retain_all_exact_ties = instance.tie_handling.mode == :complete
    enum_outcome, enumeration = _journal_capture_exact(
        instance,
        :complete_enumeration,
    ) do
        solve_journal_compression_enumeration(
            instance;
            retain_all_ties = retain_all_exact_ties,
            maximum_optional_strategies,
            maximum_ties,
        )
    end
    dp_outcome, dynamic_programming = _journal_capture_exact(
        instance,
        :requirement_mask_dp,
    ) do
        solve_journal_compression_dp(
            instance;
            retain_all_ties = retain_all_exact_ties,
            maximum_ties,
        )
    end
    mip_outcome, mip = _journal_capture_mip(instance) do
        solve_journal_compression_mip(
            instance;
            random_seed,
            time_limit,
            relative_mip_gap_tolerance = 0.0,
            absolute_mip_gap_tolerance = 0.0,
            exact_crosscheck = :none,
        )
    end

    outcomes = (enum_outcome, dp_outcome, mip_outcome)
    all_methods_completed = all(outcome.completed for outcome in outcomes)
    burdens = [outcome.exact_burden for outcome in outcomes]
    objective_values_agree = _journal_all_equal(burdens)
    selections = [_journal_outcome_selection_key(outcome) for outcome in outcomes]
    reconstructed = all(!isnothing(selection) for selection in selections)
    enum_dp_same = _journal_optional_equality(selections[1], selections[2])
    enum_mip_same = _journal_optional_equality(selections[1], selections[3])
    dp_mip_same = _journal_optional_equality(selections[2], selections[3])
    identities_differ = reconstructed ? length(Set(selections)) > 1 : missing
    all_exactly_feasible = all(
        outcome.exact_feasible === true && outcome.burden_reconciled === true for
        outcome in outcomes
    )
    mip_conclusive, mip_claimed_optimal, preprocessing_only =
        _journal_mip_conclusive(mip)
    passed = all_methods_completed && reconstructed && all_exactly_feasible &&
             objective_values_agree === true && mip_conclusive
    notes = String[
        "Enumeration and requirement-mask DP are complete exact finite computations.",
        "HiGHS termination status is solver evidence, not a formal or exhaustive proof.",
        "Every representative is rechecked against original frontier, closure, mandatory, and burden data.",
    ]
    identities_differ === true && push!(
        notes,
        "At least two methods returned different optimizer identities with the same exact objective.",
    )
    instance.tie_handling.mode == :complete && push!(
        notes,
        "The input requires complete tie reporting; the representative-only MIP workflow cannot satisfy that declaration.",
    )
    return JournalExactnessAuditResult(
        JOURNAL_EXACTNESS_AUDIT_SCHEMA_VERSION,
        journal_compression_instance_sha256(instance),
        passed,
        all_methods_completed,
        objective_values_agree,
        reconstructed,
        identities_differ,
        enum_dp_same,
        enum_mip_same,
        dp_mip_same,
        enum_outcome,
        dp_outcome,
        mip_outcome,
        mip_claimed_optimal,
        preprocessing_only,
        isnothing(mip) ? "UNAVAILABLE" : mip.diagnostics.termination_status,
        isnothing(mip) ? missing : mip.diagnostics.best_bound,
        isnothing(mip) ? missing : mip.diagnostics.reported_relative_gap,
        "unavailable: no second open-source solver is pinned in the Julia environments",
        notes,
        enumeration,
        dynamic_programming,
        mip,
        nothing,
        "not requested",
    )
end


function _journal_cover_failure_embedding(
    instance::JournalCompressionInstance,
    kept_strategies::Vector{Int},
    kept_requirements::Vector{Int},
    suffix::AbstractString,
)
    isempty(kept_strategies) && throw(ArgumentError("failure fixture needs a strategy"))
    any(instance.mandatory[kept_strategies]) || throw(
        ArgumentError("failure fixture must retain a mandatory strategy"),
    )
    for row in kept_requirements
        any(instance.coverage[row, column] for column in kept_strategies) || throw(
            ArgumentError("failure fixture contains a requirement without a carrier"),
        )
    end
    modules = [String[] for _ in kept_strategies]
    module_ids = ["audit_requirement_$(row)" for row in kept_requirements]
    for (new_row, old_row) in enumerate(kept_requirements)
        for (new_column, old_column) in enumerate(kept_strategies)
            instance.coverage[old_row, old_column] &&
                push!(modules[new_column], module_ids[new_row])
        end
    end
    parent_hash = journal_compression_instance_sha256(instance)
    provenance = JournalCompressionProvenance(
        :adversarial,
        "$(instance.provenance.instance_id)-audit-minimized-$suffix",
        "carrier-incidence embedding produced only after an exactness disagreement";
        generator = "JournalExactnessAudit._journal_cover_failure_embedding",
        parent_hashes = ["source_instance" => parent_hash],
        attributes = [
            "evidence_class" => "exact finite failing fixture",
            "minimization" => "deterministic one-deletion fixed point",
        ],
        redistributable = instance.provenance.redistributable,
    )
    return journal_compression_instance_from_components(
        [instance.strategy_ids[index].id for index in kept_strategies],
        instance.mandatory[kept_strategies],
        instance.weights[kept_strategies],
        [:audit_zero_frontier],
        zeros(Int, length(kept_strategies), 1),
        modules;
        tie_handling = instance.tie_handling,
        provenance,
    )
end


function _journal_minimize_failure(instance, failure_predicate)
    strategies = collect(eachindex(instance.strategy_ids))
    requirements = collect(eachindex(instance.requirements))
    candidate = _journal_cover_failure_embedding(
        instance,
        strategies,
        requirements,
        "initial",
    )
    failure_predicate(candidate) || return instance, "embedding did not reproduce disagreement"
    changed = true
    iteration = 0
    while changed
        changed = false
        iteration += 1
        for column in copy(strategies)
            instance.mandatory[column] && continue
            trial_strategies = filter(!=(column), strategies)
            all(
                any(instance.coverage[row, carrier] for carrier in trial_strategies) for
                row in requirements
            ) || continue
            trial = _journal_cover_failure_embedding(
                instance,
                trial_strategies,
                requirements,
                "s$(length(trial_strategies))-r$(length(requirements))-i$iteration",
            )
            failure_predicate(trial) || continue
            strategies = trial_strategies
            candidate = trial
            changed = true
        end
        for row in copy(requirements)
            trial_requirements = filter(!=(row), requirements)
            trial = _journal_cover_failure_embedding(
                instance,
                strategies,
                trial_requirements,
                "s$(length(strategies))-r$(length(trial_requirements))-i$iteration",
            )
            failure_predicate(trial) || continue
            requirements = trial_requirements
            candidate = trial
            changed = true
        end
    end
    return candidate,
           "deterministic one-strategy/one-requirement deletion fixed point"
end


"""
    audit_journal_small_instance(instance; ...)

Run enumeration, requirement-mask DP, and the deterministic HiGHS MIP pipeline
independently. On disagreement, deterministically attempt to minimize a pure
carrier-incidence embedding of the failure. No artifact is written by this
function.
"""
function audit_journal_small_instance(
    instance::JournalCompressionInstance;
    random_seed::Integer = 0,
    time_limit = 30.0,
    maximum_optional_strategies::Integer = 24,
    maximum_ties::Integer = 100_000,
    minimize_failure::Bool = true,
)
    audit = _journal_small_audit_core(
        instance;
        random_seed,
        time_limit,
        maximum_optional_strategies,
        maximum_ties,
    )
    (audit.passed || !minimize_failure) && return audit
    predicate = candidate -> !_journal_small_audit_core(
        candidate;
        random_seed,
        time_limit,
        maximum_optional_strategies,
        maximum_ties,
    ).passed
    minimized, status = _journal_minimize_failure(instance, predicate)
    return JournalExactnessAuditResult(
        audit.schema_version,
        audit.instance_sha256,
        audit.passed,
        audit.all_methods_completed,
        audit.objective_values_agree,
        audit.reconstructed_optimizers_compared,
        audit.optimizer_identities_differ,
        audit.enumeration_dp_same_optimizer,
        audit.enumeration_mip_same_optimizer,
        audit.dp_mip_same_optimizer,
        audit.enumeration,
        audit.dynamic_programming,
        audit.mip,
        audit.mip_solver_claimed_optimal,
        audit.mip_solved_by_exact_preprocessing,
        audit.mip_termination_status,
        audit.mip_best_bound,
        audit.mip_reported_relative_gap,
        audit.second_solver_status,
        audit.notes,
        audit.enumeration_result,
        audit.dynamic_programming_result,
        audit.mip_result,
        minimized,
        status,
    )
end


function _journal_optional_payload(value)
    ismissing(value) && return Dict{String,Any}("available" => false)
    return Dict{String,Any}("available" => true, "value" => value)
end


function _journal_exactness_outcome_payload(outcome)
    return Dict{String,Any}(
        "algorithm" => string(outcome.algorithm),
        "completed" => outcome.completed,
        "exact_burden" => ismissing(outcome.exact_burden) ?
            Dict{String,Any}("available" => false) : Dict{String,Any}(
            "available" => true,
            "value" => encode_exact_rational(outcome.exact_burden),
        ),
        "representative_available" => !isnothing(outcome.selected),
        "selected_strategy_indices" =>
            isnothing(outcome.selected) ? Int[] : findall(outcome.selected),
        "exact_feasible" => _journal_optional_payload(outcome.exact_feasible),
        "burden_reconciled" =>
            _journal_optional_payload(outcome.burden_reconciled),
        "error_type" => outcome.error_type,
        "error_message" => outcome.error_message,
    )
end


"""Return the machine-readable live small-instance comparison certificate."""
function journal_exactness_audit_certificate(audit::JournalExactnessAuditResult)
    return Dict{String,Any}(
        "schema_version" => audit.schema_version,
        "bundle_kind" => "small_exact_crosscheck",
        "instance_sha256" => audit.instance_sha256,
        "passed" => audit.passed,
        "evidence_classes" => [
            "exact finite enumeration",
            "exact finite requirement-mask dynamic programming",
            "mixed-integer solver evidence plus exact finite post-check",
        ],
        "solver_optimality_is_formal_proof" => false,
        "all_methods_completed" => audit.all_methods_completed,
        "objective_values_agree" =>
            _journal_optional_payload(audit.objective_values_agree),
        "reconstructed_optimizers_compared" =>
            audit.reconstructed_optimizers_compared,
        "optimizer_identities_differ" =>
            _journal_optional_payload(audit.optimizer_identities_differ),
        "enumeration_dp_same_optimizer" =>
            _journal_optional_payload(audit.enumeration_dp_same_optimizer),
        "enumeration_mip_same_optimizer" =>
            _journal_optional_payload(audit.enumeration_mip_same_optimizer),
        "dp_mip_same_optimizer" =>
            _journal_optional_payload(audit.dp_mip_same_optimizer),
        "algorithms" => [
            _journal_exactness_outcome_payload(audit.enumeration),
            _journal_exactness_outcome_payload(audit.dynamic_programming),
            _journal_exactness_outcome_payload(audit.mip),
        ],
        "mip" => Dict{String,Any}(
            "solver_claimed_optimal" =>
                _journal_optional_payload(audit.mip_solver_claimed_optimal),
            "solved_by_exact_preprocessing" => _journal_optional_payload(
                audit.mip_solved_by_exact_preprocessing,
            ),
            "termination_status" => audit.mip_termination_status,
            "best_bound" => _journal_optional_payload(audit.mip_best_bound),
            "reported_relative_gap" =>
                _journal_optional_payload(audit.mip_reported_relative_gap),
        ),
        "second_solver_status" => audit.second_solver_status,
        "notes" => audit.notes,
        "minimized_failure_available" =>
            !isnothing(audit.minimized_failure_instance),
        "minimized_failure_sha256" =>
            isnothing(audit.minimized_failure_instance) ? "" :
            journal_compression_instance_sha256(audit.minimized_failure_instance),
        "minimization_status" => audit.minimization_status,
    )
end


function _journal_toml(payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end


_journal_text_sha256(text::AbstractString) = bytes2hex(sha256(String(text)))


function _journal_prepare_bundle_directory(directory::AbstractString)
    path = abspath(String(directory))
    if isdir(path)
        isempty(readdir(path)) || throw(
            ArgumentError("audit bundle directory must be absent or empty: $path"),
        )
    elseif ispath(path)
        throw(ArgumentError("audit bundle path exists and is not a directory: $path"))
    else
        mkpath(path)
    end
    return path
end


function _journal_write_bundle_files(
    directory::AbstractString,
    bundle_kind::AbstractString,
    instance_sha256::AbstractString,
    files::Vector{Pair{String,String}},
)
    path = _journal_prepare_bundle_directory(directory)
    artifacts = Dict{String,Any}[]
    for (name, contents) in files
        occursin('/', name) && throw(ArgumentError("bundle artifact names must be flat"))
        open(joinpath(path, name), "w") do io
            write(io, contents)
        end
        push!(
            artifacts,
            Dict{String,Any}(
                "path" => name,
                "sha256" => _journal_text_sha256(contents),
                "bytes" => ncodeunits(contents),
            ),
        )
    end
    sort!(artifacts; by = artifact -> artifact["path"])
    manifest = Dict{String,Any}(
        "schema_version" => JOURNAL_EXACTNESS_MANIFEST_SCHEMA_VERSION,
        "bundle_kind" => String(bundle_kind),
        "instance_sha256" => String(instance_sha256),
        "hash_algorithm" => "SHA-256",
        "manifest_self_hash_included" => false,
        "artifacts" => artifacts,
    )
    manifest_text = _journal_toml(manifest)
    open(joinpath(path, "certificate_manifest.toml"), "w") do io
        write(io, manifest_text)
    end
    return (
        directory = path,
        manifest_sha256 = _journal_text_sha256(manifest_text),
        artifact_count = length(artifacts),
    )
end


"""
    write_journal_small_exactness_audit_bundle(directory, instance; ...)

Explicit write step for a live small-instance audit. The audit routine itself
is nonmutating. Existing nonempty directories are never overwritten.
"""
function write_journal_small_exactness_audit_bundle(
    directory::AbstractString,
    instance::JournalCompressionInstance;
    kwargs...,
)
    instance.provenance.redistributable || throw(
        ArgumentError("refusing to serialize a nonredistributable instance"),
    )
    audit = audit_journal_small_instance(instance; kwargs...)
    files = Pair{String,String}[
        "instance.toml" => serialize_journal_compression_instance(instance),
        "exactness_audit.toml" =>
            _journal_toml(journal_exactness_audit_certificate(audit)),
    ]
    if isnothing(audit.enumeration_result)
        push!(files, "enumeration_error.toml" => _journal_toml(
            _journal_exactness_outcome_payload(audit.enumeration),
        ))
    else
        push!(files, "enumeration.toml" =>
            serialize_journal_exact_solution(audit.enumeration_result))
    end
    if isnothing(audit.dynamic_programming_result)
        push!(files, "dp_error.toml" => _journal_toml(
            _journal_exactness_outcome_payload(audit.dynamic_programming),
        ))
    else
        push!(files, "dp.toml" =>
            serialize_journal_exact_solution(audit.dynamic_programming_result))
    end
    if isnothing(audit.mip_result)
        push!(files, "mip_error.toml" => _journal_toml(
            _journal_exactness_outcome_payload(audit.mip),
        ))
    else
        push!(files, "mip.toml" => serialize_journal_mip_solution(audit.mip_result))
    end
    if !isnothing(audit.minimized_failure_instance)
        audit.minimized_failure_instance.provenance.redistributable || throw(
            ArgumentError("refusing to serialize a nonredistributable failing fixture"),
        )
        push!(
            files,
            "minimized_failure_instance.toml" =>
                serialize_journal_compression_instance(
                audit.minimized_failure_instance,
            ),
        )
    end
    bundle = _journal_write_bundle_files(
        directory,
        "small_exact_crosscheck",
        audit.instance_sha256,
        files,
    )
    return merge(bundle, (audit = audit,))
end


"""Independently recheck one in-memory MIP output and retain bound diagnostics."""
function audit_journal_mip_output(
    instance::JournalCompressionInstance,
    result::JournalMIPSolutionResult,
)
    validate_journal_compression_instance(instance)
    errors = String[]
    expected_hash = journal_compression_instance_sha256(instance)
    result.instance_sha256 == expected_hash || push!(
        errors,
        "MIP certificate instance hash does not match the supplied instance",
    )
    exact_feasible = missing
    burden_reconciled = missing
    if result.candidate_accepted
        check = check_journal_compression_solution(
            instance,
            result.reconstructed_candidate;
            expected_burden = result.exact_burden,
        )
        exact_feasible = check.exact_feasible
        burden_reconciled = check.burden_reconciled
        check.exact_feasible || push!(errors, "MIP candidate failed exact feasibility")
        check.burden_reconciled || push!(errors, "MIP burden failed exact reconciliation")
    end
    return (
        schema_version = JOURNAL_EXACTNESS_AUDIT_SCHEMA_VERSION,
        bundle_kind = :mip_only,
        instance_sha256 = expected_hash,
        passed = isempty(errors),
        certified_candidate_available = result.candidate_accepted,
        exact_candidate_feasible = exact_feasible,
        burden_reconciled,
        selected_strategy_indices = result.candidate_accepted ?
            findall(result.reconstructed_candidate) : Int[],
        exact_burden = result.exact_burden,
        solver_claimed_optimal = result.solver_claimed_optimal,
        solver_optimality_is_formal_proof = false,
        termination_status = result.diagnostics.termination_status,
        primal_status = result.diagnostics.primal_status,
        dual_status = result.diagnostics.dual_status,
        objective_value = result.diagnostics.objective_value,
        best_bound = result.diagnostics.best_bound,
        reported_relative_gap = result.diagnostics.reported_relative_gap,
        errors,
        second_solver_status =
            "unavailable: no second open-source solver is pinned in the Julia environments",
    )
end


function _journal_mip_audit_payload(audit)
    exact_burden = ismissing(audit.exact_burden) ?
                   Dict{String,Any}("available" => false) :
                   Dict{String,Any}(
        "available" => true,
        "value" => encode_exact_rational(audit.exact_burden),
    )
    return Dict{String,Any}(
        "schema_version" => audit.schema_version,
        "bundle_kind" => string(audit.bundle_kind),
        "instance_sha256" => audit.instance_sha256,
        "passed" => audit.passed,
        "certified_candidate_available" => audit.certified_candidate_available,
        "exact_candidate_feasible" =>
            _journal_optional_payload(audit.exact_candidate_feasible),
        "burden_reconciled" => _journal_optional_payload(audit.burden_reconciled),
        "selected_strategy_indices" => audit.selected_strategy_indices,
        "exact_burden" => exact_burden,
        "solver_claimed_optimal" => audit.solver_claimed_optimal,
        "solver_optimality_is_formal_proof" => false,
        "termination_status" => audit.termination_status,
        "primal_status" => audit.primal_status,
        "dual_status" => audit.dual_status,
        "objective_value" => _journal_optional_payload(audit.objective_value),
        "best_bound" => _journal_optional_payload(audit.best_bound),
        "reported_relative_gap" =>
            _journal_optional_payload(audit.reported_relative_gap),
        "errors" => audit.errors,
        "second_solver_status" => audit.second_solver_status,
    )
end


"""Write an auditable MIP-only bundle for a medium or financial instance."""
function write_journal_mip_exactness_audit_bundle(
    directory::AbstractString,
    instance::JournalCompressionInstance,
    result::JournalMIPSolutionResult,
)
    instance.provenance.redistributable || throw(
        ArgumentError("refusing to serialize a nonredistributable instance"),
    )
    audit = audit_journal_mip_output(instance, result)
    files = Pair{String,String}[
        "instance.toml" => serialize_journal_compression_instance(instance),
        "mip.toml" => serialize_journal_mip_solution(result),
        "exactness_audit.toml" => _journal_toml(
            _journal_mip_audit_payload(audit),
        ),
    ]
    bundle = _journal_write_bundle_files(
        directory,
        "mip_only",
        audit.instance_sha256,
        files,
    )
    return merge(bundle, (audit = audit,))
end


function _journal_payload_optional(payload, key)
    section = get(payload, key, Dict{String,Any}("available" => false))
    Bool(get(section, "available", false)) || return missing
    return get(section, "value", missing)
end


function _journal_payload_selection(payload, strategy_count)
    indices = Int.(get(payload, "selected_strategy_indices", Int[]))
    length(unique(indices)) == length(indices) || throw(
        ArgumentError("certificate repeats a selected strategy index"),
    )
    all(index -> 1 <= index <= strategy_count, indices) || throw(
        ArgumentError("certificate selection index is out of bounds"),
    )
    selected = falses(strategy_count)
    selected[indices] .= true
    return selected
end


function _journal_audit_exact_payload(
    payload,
    instance,
    expected_algorithm::AbstractString,
)
    errors = String[]
    get(payload, "schema_version", "") == JOURNAL_EXACT_SOLUTION_SCHEMA_VERSION ||
        push!(errors, "unsupported exact-solution schema")
    get(payload, "algorithm", "") == expected_algorithm ||
        push!(errors, "unexpected exact algorithm identity")
    get(payload, "instance_sha256", "") ==
    journal_compression_instance_sha256(instance) ||
        push!(errors, "exact certificate instance hash mismatch")
    get(payload, "search_complete", false) === true ||
        push!(errors, "exact certificate does not declare complete search")
    get(payload, "solver_status_used", true) === false ||
        push!(errors, "exact certificate improperly relies on solver status")
    burden = try
        exact_rational(String(payload["exact_burden"]))
    catch error
        push!(errors, "invalid exact burden: $(sprint(showerror, error))")
        missing
    end
    selected = try
        _journal_payload_selection(payload, length(instance.strategy_ids))
    catch error
        push!(errors, sprint(showerror, error))
        nothing
    end
    feasible = missing
    if !isnothing(selected) && !ismissing(burden)
        check = check_journal_compression_solution(
            instance,
            selected;
            expected_burden = burden,
        )
        feasible = check.exact_feasible && check.burden_reconciled
        feasible || push!(errors, "exact representative failed independent recheck")
    end
    for row in get(payload, "optimal_selections", Any[])
        row_selected = try
            _journal_payload_selection(row, length(instance.strategy_ids))
        catch error
            push!(errors, "invalid returned optimum: $(sprint(showerror, error))")
            continue
        end
        row_burden = try
            exact_rational(String(row["exact_burden"]))
        catch error
            push!(errors, "invalid returned optimum burden: $(sprint(showerror, error))")
            continue
        end
        row_check = check_journal_compression_solution(
            instance,
            row_selected;
            expected_burden = row_burden,
        )
        row_check.exact_feasible && row_check.burden_reconciled &&
            row_burden == burden || push!(
            errors,
            "a returned exact optimizer failed feasibility or burden equality",
        )
    end
    return (; burden, selected, feasible, errors)
end


function _journal_audit_mip_payload(payload, instance)
    errors = String[]
    get(payload, "schema_version", "") == JOURNAL_MIP_SOLUTION_SCHEMA_VERSION ||
        push!(errors, "unsupported MIP-solution schema")
    get(payload, "instance_sha256", "") ==
    journal_compression_instance_sha256(instance) ||
        push!(errors, "MIP certificate instance hash mismatch")
    get(payload, "solver_optimality_is_formal_proof", true) === false ||
        push!(errors, "MIP certificate confuses solver status with formal proof")
    diagnostics = get(payload, "solver_diagnostics", Dict{String,Any}())
    get(diagnostics, "solver_name", "") == "HiGHS" ||
        push!(errors, "MIP certificate is not a HiGHS result")
    candidate = Bool(get(payload, "candidate_accepted", false))
    burden_section = get(payload, "exact_burden", Dict{String,Any}())
    burden = if Bool(get(burden_section, "available", false))
        try
            exact_rational(String(burden_section["value"]))
        catch error
            push!(errors, "invalid MIP exact burden: $(sprint(showerror, error))")
            missing
        end
    else
        missing
    end
    selected = nothing
    feasible = missing
    if candidate
        selected = try
            _journal_payload_selection(payload, length(instance.strategy_ids))
        catch error
            push!(errors, sprint(showerror, error))
            nothing
        end
        if isnothing(selected) || ismissing(burden)
            push!(errors, "accepted MIP candidate lacks a usable selection or burden")
        else
            check = check_journal_compression_solution(
                instance,
                selected;
                expected_burden = burden,
            )
            feasible = check.exact_feasible && check.burden_reconciled
            feasible || push!(errors, "MIP representative failed independent exact recheck")
        end
    elseif Bool(get(burden_section, "available", false))
        push!(errors, "rejected MIP result exposes a certified exact burden")
    end
    solver_invoked = Bool(get(diagnostics, "solver_invoked", false))
    termination = String(get(diagnostics, "termination_status", "UNAVAILABLE"))
    solver_claimed_optimal = Bool(get(payload, "solver_claimed_optimal", false))
    formulation = get(payload, "formulation", Dict{String,Any}())
    preprocessing_only = !solver_invoked &&
                         Int(get(formulation, "residual_binary_variable_count", -1)) == 0 &&
                         Int(get(formulation, "residual_tagged_cover_row_count", -1)) == 0 &&
                         candidate
    conclusive = solver_claimed_optimal || preprocessing_only
    best_bound = _journal_payload_optional(diagnostics, "best_bound")
    relative_gap = _journal_payload_optional(diagnostics, "reported_relative_gap")
    return (
        ;
        candidate,
        burden,
        selected,
        feasible,
        conclusive,
        termination,
        best_bound = ismissing(best_bound) ? missing : Float64(best_bound),
        relative_gap = ismissing(relative_gap) ? missing : Float64(relative_gap),
        errors,
    )
end


function _journal_bundle_artifacts(bundle_path, manifest)
    errors = String[]
    rows = get(manifest, "artifacts", Any[])
    names = String[]
    for row in rows
        name = String(get(row, "path", ""))
        isempty(name) && (push!(errors, "manifest contains an empty artifact path"); continue)
        (isabspath(name) || ".." in splitpath(name)) &&
            (push!(errors, "manifest artifact path escapes the bundle: $name"); continue)
        push!(names, name)
        artifact_path = joinpath(bundle_path, name)
        if !isfile(artifact_path)
            push!(errors, "manifest artifact is missing: $name")
            continue
        end
        contents = read(artifact_path, String)
        expected_hash = String(get(row, "sha256", ""))
        _journal_text_sha256(contents) == expected_hash ||
            push!(errors, "SHA-256 mismatch for $name")
        Int(get(row, "bytes", -1)) == ncodeunits(contents) ||
            push!(errors, "byte-count mismatch for $name")
    end
    length(unique(names)) == length(names) ||
        push!(errors, "manifest repeats an artifact path")
    actual = sort(filter(!=("certificate_manifest.toml"), readdir(bundle_path)))
    sort(names) == actual || push!(
        errors,
        "manifest artifact list does not equal the bundle file list",
    )
    return Set(names), errors
end


function _journal_audit_one_bundle(root, manifest_path)
    bundle_path = dirname(manifest_path)
    relative = relpath(bundle_path, root)
    errors = String[]
    manifest = try
        TOML.parsefile(manifest_path)
    catch error
        return JournalExactnessBundleAudit(
            relative,
            :invalid,
            false,
            "",
            missing,
            missing,
            false,
            missing,
            "UNAVAILABLE",
            missing,
            missing,
            ["cannot parse manifest: $(sprint(showerror, error))"],
        )
    end
    get(manifest, "schema_version", "") ==
    JOURNAL_EXACTNESS_MANIFEST_SCHEMA_VERSION ||
        push!(errors, "unsupported exactness manifest schema")
    kind_text = String(get(manifest, "bundle_kind", "invalid"))
    kind = Symbol(kind_text)
    names, hash_errors = _journal_bundle_artifacts(bundle_path, manifest)
    append!(errors, hash_errors)
    "instance.toml" in names || push!(errors, "bundle has no instance.toml")
    instance = try
        deserialize_journal_compression_instance(
            read(joinpath(bundle_path, "instance.toml"), String),
        )
    catch error
        push!(errors, "cannot validate instance: $(sprint(showerror, error))")
        nothing
    end
    instance_hash = isnothing(instance) ? "" :
                    journal_compression_instance_sha256(instance)
    instance_hash == String(get(manifest, "instance_sha256", "")) ||
        push!(errors, "manifest instance hash mismatch")

    objective_agreement = missing
    identities_differ = missing
    candidate_available = false
    candidate_feasible = missing
    termination = "UNAVAILABLE"
    best_bound = missing
    relative_gap = missing
    try
        if !isnothing(instance) && kind == :small_exact_crosscheck
            required = Set(
                [
                    "enumeration.toml",
                    "dp.toml",
                    "mip.toml",
                    "exactness_audit.toml",
                ],
            )
            issubset(required, names) || push!(
                errors,
                "small bundle lacks one or more successful method certificates",
            )
            if issubset(required, names)
                enum = _journal_audit_exact_payload(
                    TOML.parsefile(joinpath(bundle_path, "enumeration.toml")),
                    instance,
                    "complete_enumeration",
                )
                dp = _journal_audit_exact_payload(
                    TOML.parsefile(joinpath(bundle_path, "dp.toml")),
                    instance,
                    "requirement_mask_dp",
                )
                mip = _journal_audit_mip_payload(
                    TOML.parsefile(joinpath(bundle_path, "mip.toml")),
                    instance,
                )
                append!(errors, enum.errors)
                append!(errors, dp.errors)
                append!(errors, mip.errors)
                burdens = [enum.burden, dp.burden, mip.burden]
                objective_agreement = _journal_all_equal(burdens)
                objective_agreement === true ||
                    push!(errors, "three exact burdens disagree")
                selections = (enum.selected, dp.selected, mip.selected)
                if all(!isnothing(selection) for selection in selections)
                    keys = Set(
                        Tuple(findall(selection)) for selection in selections
                    )
                    identities_differ = length(keys) > 1
                end
                enum.feasible === true || push!(
                    errors,
                    "enumeration feasibility is not certified",
                )
                dp.feasible === true ||
                    push!(errors, "DP feasibility is not certified")
                mip.feasible === true ||
                    push!(errors, "MIP feasibility is not certified")
                mip.conclusive || push!(
                    errors,
                    "MIP result is not conclusive for a small benchmark",
                )
                candidate_available = mip.candidate
                candidate_feasible = mip.feasible
                termination = mip.termination
                best_bound = mip.best_bound
                relative_gap = mip.relative_gap
                stored = TOML.parsefile(
                    joinpath(bundle_path, "exactness_audit.toml"),
                )
                Bool(get(stored, "passed", false)) == isempty(errors) || push!(
                    errors,
                    "stored small-audit pass flag disagrees with offline recomputation",
                )
                stored_agreement = _journal_payload_optional(
                    stored,
                    "objective_values_agree",
                )
                stored_agreement === objective_agreement || push!(
                    errors,
                    "stored objective-agreement field disagrees with offline recomputation",
                )
            end
        elseif !isnothing(instance) && kind == :mip_only
            required = Set(["mip.toml", "exactness_audit.toml"])
            issubset(required, names) || push!(
                errors,
                "MIP-only bundle lacks required certificates",
            )
            if issubset(required, names)
                mip = _journal_audit_mip_payload(
                    TOML.parsefile(joinpath(bundle_path, "mip.toml")),
                    instance,
                )
                append!(errors, mip.errors)
                candidate_available = mip.candidate
                candidate_feasible = mip.feasible
                termination = mip.termination
                best_bound = mip.best_bound
                relative_gap = mip.relative_gap
                stored = TOML.parsefile(
                    joinpath(bundle_path, "exactness_audit.toml"),
                )
                Bool(get(stored, "certified_candidate_available", false)) ==
                candidate_available || push!(
                    errors,
                    "stored candidate-availability field disagrees with MIP certificate",
                )
                if candidate_available
                    candidate_feasible === true || push!(
                        errors,
                        "accepted MIP candidate is not exactly feasible",
                    )
                end
            end
        else
            kind in (:small_exact_crosscheck, :mip_only) ||
                push!(errors, "unsupported bundle kind: $kind_text")
        end
    catch error
        push!(
            errors,
            "cannot parse or audit certificate payload: $(sprint(showerror, error))",
        )
    end
    return JournalExactnessBundleAudit(
        relative,
        kind,
        isempty(errors),
        instance_hash,
        objective_agreement,
        identities_differ,
        candidate_available,
        candidate_feasible,
        termination,
        best_bound,
        relative_gap,
        errors,
    )
end


"""
    audit_journal_result_directory(directory)

Read manifests and saved certificates, recompute hashes, exact burdens, and
original-instance feasibility, and compare saved small-instance methods. This
function never invokes enumeration, DP, HiGHS, or any write operation.
"""
function audit_journal_result_directory(directory::AbstractString)
    root = abspath(String(directory))
    isdir(root) || throw(ArgumentError("audit root is not a directory: $root"))
    manifests = String[]
    for (path, _, files) in walkdir(root)
        "certificate_manifest.toml" in files &&
            push!(manifests, joinpath(path, "certificate_manifest.toml"))
    end
    sort!(manifests)
    bundles = JournalExactnessBundleAudit[
        _journal_audit_one_bundle(root, path) for path in manifests
    ]
    errors = isempty(manifests) ? ["no certificate manifests found"] : String[]
    passed = !isempty(manifests) && isempty(errors) && all(bundle.passed for bundle in bundles)
    return JournalExactnessDirectoryAudit(
        JOURNAL_EXACTNESS_AUDIT_SCHEMA_VERSION,
        root,
        passed,
        length(bundles),
        count(bundle -> bundle.bundle_kind == :small_exact_crosscheck, bundles),
        count(bundle -> bundle.bundle_kind == :mip_only, bundles),
        bundles,
        errors,
    )
end


function _journal_directory_optional(value)
    ismissing(value) && return Dict{String,Any}("available" => false)
    return Dict{String,Any}("available" => true, "value" => value)
end


"""Return a machine-readable summary of a nonmutating directory audit."""
function journal_exactness_directory_audit_certificate(
    audit::JournalExactnessDirectoryAudit,
)
    return Dict{String,Any}(
        "schema_version" => audit.schema_version,
        "audit_mode" => "saved-certificates-only; no solver invocation",
        "root" => audit.root,
        "passed" => audit.passed,
        "bundle_count" => audit.bundle_count,
        "small_bundle_count" => audit.small_bundle_count,
        "mip_only_bundle_count" => audit.mip_only_bundle_count,
        "errors" => audit.errors,
        "bundles" => Dict{String,Any}[
            Dict{String,Any}(
                "relative_path" => bundle.relative_path,
                "bundle_kind" => string(bundle.bundle_kind),
                "passed" => bundle.passed,
                "instance_sha256" => bundle.instance_sha256,
                "objective_values_agree" =>
                    _journal_directory_optional(bundle.objective_values_agree),
                "optimizer_identities_differ" =>
                    _journal_directory_optional(bundle.optimizer_identities_differ),
                "certified_candidate_available" =>
                    bundle.certified_candidate_available,
                "exact_candidate_feasible" =>
                    _journal_directory_optional(bundle.exact_candidate_feasible),
                "mip_termination_status" => bundle.mip_termination_status,
                "mip_best_bound" =>
                    _journal_directory_optional(bundle.mip_best_bound),
                "mip_reported_relative_gap" =>
                    _journal_directory_optional(bundle.mip_reported_relative_gap),
                "errors" => bundle.errors,
            ) for bundle in audit.bundles
        ],
    )
end
