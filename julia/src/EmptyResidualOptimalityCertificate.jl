const EMPTY_RESIDUAL_OPTIMALITY_CERTIFICATE_SCHEMA_VERSION =
    "empty-residual-optimality-certificate-v1"


"""
Exact finite certificate for the special case in which the human-proved,
optimum-preserving tagged-cover preprocessing rules remove every residual
strategy and requirement. This is not a Lean or solver certificate.
"""
struct EmptyResidualOptimalityCertificate
    schema_version::String
    instance_sha256::String
    status::Symbol
    certified_global_optimum::Bool
    preprocessing_feasible::Bool
    residual_strategy_count::Int
    residual_requirement_count::Int
    forced_strategy_indices::Vector{Int}
    selected::Union{Nothing,BitVector}
    exact_optimum_burden::Union{Missing,ExactRational}
    exact_mandatory_retention::Union{Missing,Bool}
    exact_tagged_coverage::Union{Missing,Bool}
    exact_frontier_preservation::Union{Missing,Bool}
    exact_closure_preservation::Union{Missing,Bool}
    exact_feasible::Union{Missing,Bool}
    theorem_basis::String
    evidence_class::String
end


"""
    certify_empty_residual_optimum(instance)

Apply exact tagged-cover preprocessing independently of any solver. If the
feasible residual has no variables and no requirements, lift the forced
selection and recheck the original semantic instance exactly. By the
human-proved optimum-value preservation of the preprocessing rules, the exact
objective offset is then the global optimum. The function does not claim Lean
kernel verification or infer anything from a solver status.
"""
function certify_empty_residual_optimum(
    instance::JournalCompressionInstance,
)
    validate_journal_compression_instance(instance)
    instance.identity_closure || throw(
        ArgumentError("the empty-residual source certificate requires identity closure"),
    )
    preprocessing = preprocess_tagged_cover(exact_tagged_cover_model(instance))
    residual_strategy_count = length(preprocessing.reduced.strategy_ids)
    residual_requirement_count = length(preprocessing.reduced.requirements)
    theorem_basis =
        "optimum-value preservation of mandatory propagation, redundant-row merging, unique-carrier forcing, empty-column deletion, duplicate-coverage reduction, and exact coverage dominance"
    evidence_class =
        "human-readable preprocessing theorem plus exact finite computation and original-instance recheck; not Lean verification and not solver evidence"
    solved = preprocessing.feasible &&
             iszero(residual_strategy_count) &&
             iszero(residual_requirement_count)
    if !solved
        status = preprocessing.feasible ? :residual_model_nonempty :
                 :preprocessing_infeasible
        return EmptyResidualOptimalityCertificate(
            EMPTY_RESIDUAL_OPTIMALITY_CERTIFICATE_SCHEMA_VERSION,
            journal_compression_instance_sha256(instance),
            status,
            false,
            preprocessing.feasible,
            residual_strategy_count,
            residual_requirement_count,
            copy(preprocessing.forced_strategy_indices),
            nothing,
            missing,
            missing,
            missing,
            missing,
            missing,
            missing,
            theorem_basis,
            evidence_class,
        )
    end
    selected = lift_preprocessed_tagged_selection(preprocessing, falses(0))
    check = check_journal_compression_solution(instance, selected)
    check.exact_feasible || throw(
        ArgumentError("empty-residual preprocessing failed the original-instance exact recheck"),
    )
    check.exact_burden == preprocessing.objective_offset || throw(
        ArgumentError("lifted exact burden differs from the preprocessing objective offset"),
    )
    return EmptyResidualOptimalityCertificate(
        EMPTY_RESIDUAL_OPTIMALITY_CERTIFICATE_SCHEMA_VERSION,
        journal_compression_instance_sha256(instance),
        :certified_exact_global_optimum,
        true,
        true,
        0,
        0,
        copy(preprocessing.forced_strategy_indices),
        selected,
        check.exact_burden,
        check.mandatory_retained,
        check.tagged_coverage,
        check.frontier_preserved,
        check.closure_preserved,
        check.exact_feasible,
        theorem_basis,
        evidence_class,
    )
end


function empty_residual_certificate_payload(
    certificate::EmptyResidualOptimalityCertificate,
    strategy_ids,
)
    selected_indices = isnothing(certificate.selected) ? Int[] :
                       findall(certificate.selected)
    return Dict{String,Any}(
        "schema_version" => certificate.schema_version,
        "instance_sha256" => certificate.instance_sha256,
        "status" => string(certificate.status),
        "certified_global_optimum" => certificate.certified_global_optimum,
        "preprocessing_feasible" => certificate.preprocessing_feasible,
        "residual_strategy_count" => certificate.residual_strategy_count,
        "residual_requirement_count" => certificate.residual_requirement_count,
        "forced_strategy_indices" => certificate.forced_strategy_indices,
        "selected_strategy_indices" => selected_indices,
        "selected_strategy_ids" => [
            string(strategy_ids[index].id) for index in selected_indices
        ],
        "exact_optimum_burden" => ismissing(certificate.exact_optimum_burden) ?
            Dict("available" => false) :
            encode_exact_rational(certificate.exact_optimum_burden),
        "exact_mandatory_retention" => ismissing(
            certificate.exact_mandatory_retention,
        ) ? Dict("available" => false) : certificate.exact_mandatory_retention,
        "exact_tagged_coverage" => ismissing(certificate.exact_tagged_coverage) ?
            Dict("available" => false) : certificate.exact_tagged_coverage,
        "exact_frontier_preservation" => ismissing(
            certificate.exact_frontier_preservation,
        ) ? Dict("available" => false) : certificate.exact_frontier_preservation,
        "exact_closure_preservation" => ismissing(
            certificate.exact_closure_preservation,
        ) ? Dict("available" => false) : certificate.exact_closure_preservation,
        "exact_feasible" => ismissing(certificate.exact_feasible) ?
            Dict("available" => false) : certificate.exact_feasible,
        "theorem_basis" => certificate.theorem_basis,
        "evidence_class" => certificate.evidence_class,
        "lean_verified" => false,
        "solver_invoked" => false,
        "solver_status_used_as_proof" => false,
    )
end


function serialize_empty_residual_certificate(
    certificate::EmptyResidualOptimalityCertificate,
    strategy_ids,
)
    io = IOBuffer()
    TOML.print(
        io,
        empty_residual_certificate_payload(certificate, strategy_ids);
        sorted = true,
    )
    return String(take!(io))
end
