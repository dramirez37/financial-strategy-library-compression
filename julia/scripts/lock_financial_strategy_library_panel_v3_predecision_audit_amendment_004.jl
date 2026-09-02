module LockFinancialStrategyLibraryPanelV3PredecisionAuditAmendment004

using HiGHS
using JuMP
using SHA: sha256
using TOML

export lock_audit_amendment_004, main

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const EXPERIMENT_ROOT = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "financial_strategy_library_panel_v3",
)
const PREVIOUS_LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PREDECISION_BINDING_AMENDMENT_003_LOCK.toml")
const EXPECTED_PREVIOUS_LOCK_SHA256 =
    "16cbf54b20e0bb475665acdfd54c539d820f02f6015dc5e610d1b791424bc8e7"
const LOCK_PATH = joinpath(EXPERIMENT_ROOT, "PREDECISION_AUDIT_AMENDMENT_004_LOCK.toml")
const SEALED_PATHS = [
    "experiments/financial_strategy_library_panel_v3/amendments/PREDECISION_AUDIT_AMENDMENT_004.md",
    "experiments/financial_strategy_library_panel_v3/amendments/PREDECISION_AUDIT_AMENDMENT_004.toml",
    "julia/scripts/check_financial_strategy_library_panel_v3_predecision_binding_replay.jl",
    "julia/scripts/lock_financial_strategy_library_panel_v3_predecision_audit_amendment_004.jl",
]

_sha256_file(path) = open(path, "r") do io
    bytes2hex(sha256(io))
end

_sha256_text(value) = bytes2hex(sha256(codeunits(String(value))))

function _toml_text(payload)
    io = IOBuffer()
    TOML.print(io, payload; sorted = true)
    return String(take!(io))
end

function _aggregate(hashes)
    canonical = join(
        ("$path\0$(hashes[path])\n" for path in sort!(collect(keys(hashes)))),
    )
    return _sha256_text(canonical)
end

function _highs_jll_module()
    matches = Module[
        module_value for (package_id, module_value) in Base.loaded_modules if
        package_id.name == "HiGHS_jll"
    ]
    length(matches) == 1 || error("cannot resolve the loaded HiGHS_jll module")
    return only(matches)
end

function _payload()
    VERSION == v"1.12.6" || error("binding replay requires Julia 1.12.6")
    _sha256_file(PREVIOUS_LOCK_PATH) == EXPECTED_PREVIOUS_LOCK_SHA256 ||
        error("binding amendment 003 lock changed")
    previous = TOML.parsefile(PREVIOUS_LOCK_PATH)
    previous["status"] == "LOCKED_PREDECISION_BINDING_AMENDMENT_003" ||
        error("unexpected preceding binding-amendment status")
    previous_hashes = Dict{String,String}(previous["sealed_file_sha256"])
    for (relative, digest) in previous_hashes
        _sha256_file(joinpath(REPOSITORY_ROOT, relative)) == digest ||
            error("preceding binding-amendment source changed: $relative")
    end

    hashes = Dict{String,String}()
    for relative in SEALED_PATHS
        path = joinpath(REPOSITORY_ROOT, relative)
        isfile(path) || error("replay-correction input is absent: $relative")
        hashes[relative] = _sha256_file(path)
    end
    julia_executable = first(Base.julia_cmd().exec)
    isfile(julia_executable) || error("Julia executable cannot be resolved")
    highs_jll = _highs_jll_module()
    native_solver_path = String(getproperty(highs_jll, :libhighs_path))
    isfile(native_solver_path) || error("native HiGHS library cannot be resolved")
    return Dict{String,Any}(
        "schema_version" => "financial-strategy-library-panel-v3-predecision-audit-amendment-lock-v1",
        "experiment_id" => "financial-strategy-library-panel-v3",
        "status" => "LOCKED_PREDECISION_AUDIT_AMENDMENT_004",
        "language" => "Julia",
        "previous_binding_amendment_lock_sha256" => _sha256_file(PREVIOUS_LOCK_PATH),
        "scientific_design_changed" => false,
        "scientific_choices_changed" => false,
        "first_full_replay_completed" => false,
        "first_full_replay_stopped_at_cell" => 1,
        "first_full_replay_failure_class" => "nondeterministic single-run solver diagnostics",
        "deterministic_mip_fields_excluded" => [
            "runtime_ns",
            "solver_diagnostics.solve_time_seconds",
            "solver_diagnostics.complete_solver_log",
        ],
        "deterministic_scientific_fields_retained" => "all other MIP certificate fields",
        "required_replay_cell_count" => 38,
        "julia_version" => string(VERSION),
        "julia_executable" => julia_executable,
        "julia_executable_sha256" => _sha256_file(julia_executable),
        "highs_julia_version" => string(pkgversion(HiGHS)),
        "jump_version" => string(pkgversion(JuMP)),
        "native_highs_library_path" => native_solver_path,
        "native_highs_library_sha256" => _sha256_file(native_solver_path),
        "sealed_file_count" => length(hashes),
        "sealed_file_sha256" => hashes,
        "sealed_file_aggregate_sha256" => _aggregate(hashes),
        "proposal_return_values_accessed_before_lock" => false,
        "evaluation_return_values_accessed_before_lock" => false,
        "historical_proposal_or_evaluation_return_access_permitted" => false,
        "next_required_action" => "full 38-cell deterministic scientific replay",
        "next_required_seal" => "PREDECISION_COMPUTATION_RESULT_SEAL",
    )
end

function lock_audit_amendment_004(; check = false)
    payload = _payload()
    text = _toml_text(payload)
    if check
        isfile(LOCK_PATH) || error("predecision audit amendment 004 lock is absent")
        read(LOCK_PATH, String) == text || error("predecision audit amendment 004 lock changed")
    elseif isfile(LOCK_PATH)
        read(LOCK_PATH, String) == text ||
            error("refusing to replace nonidentical predecision audit amendment 004 lock")
    else
        open(LOCK_PATH, "w") do io
            write(io, text)
        end
    end
    println("V3_PREDECISION_AUDIT_AMENDMENT_004_PASSED")
    println("Julia runtime bound: $(VERSION)")
    println("scientific design/choices changed: false")
    println("proposal/evaluation returns accessed: false")
    return payload
end

function main(args = ARGS)
    unknown = filter(argument -> argument != "--check", args)
    isempty(unknown) || error("unknown arguments: $(join(unknown, ' '))")
    lock_audit_amendment_004(; check = "--check" in args)
    return nothing
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    LockFinancialStrategyLibraryPanelV3PredecisionAuditAmendment004.main()
end
