module LockRandomizedLibraryDesignV2

using Dates
using SHA: sha256
using TOML

export design_rows,
    freeze_design,
    main,
    render_registry,
    validate_design,
    verify_design_lock,
    write_registry

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const DEFAULT_CONFIG = joinpath(
    REPOSITORY_ROOT,
    "experiments",
    "configs",
    "randomized_library_stress_v2.toml",
)
const FACTORS = (
    :frontier_density,
    :module_overlap,
    :module_complementarity,
    :project_cost,
    :duration,
    :admission,
    :persistence,
)
const SCHEDULE_SALT = UInt64(0xd1b54a32d192ed03)
const TRIAL_SALT = UInt64(0x94d049bb133111eb)
const CATALOG_SALT = UInt64(0x243f6a8885a308d3)
const PROJECT_SALT = UInt64(0x13198a2e03707344)
const DELETION_SALT = UInt64(0xa4093822299f31d0)
const NONNEGATIVE_INT64_MASK = UInt64(0x7fffffffffffffff)

_require(condition::Bool, message::AbstractString) =
    condition ? true : error(message)

_repo_path(path::AbstractString) =
    isabspath(path) ? normpath(path) :
    normpath(joinpath(REPOSITORY_ROOT, path))

function _sha256_file(path::AbstractString)
    open(path, "r") do io
        return bytes2hex(sha256(io))
    end
end

function _splitmix64(input::UInt64)
    mixed = input + UInt64(0x9e3779b97f4a7c15)
    mixed =
        (mixed ⊻ (mixed >> 30)) * UInt64(0xbf58476d1ce4e5b9)
    mixed =
        (mixed ⊻ (mixed >> 27)) * UInt64(0x94d049bb133111eb)
    return mixed ⊻ (mixed >> 31)
end

function _stable_seed(input::UInt64)
    seed = _splitmix64(input) & NONNEGATIVE_INT64_MASK
    return Int(iszero(seed) ? one(UInt64) : seed)
end

function _factor_level(config, factor::Symbol, high::Bool)
    levels = config["levels"][string(factor)]
    _require(
        length(levels) == 2,
        "principal factor $factor must have exactly two levels",
    )
    return String(levels[high ? 2 : 1])
end

function _boundary_mechanism(batch_id::Int)
    isodd(batch_id) && return "none"
    return batch_id in (2, 6) ?
           "frontier_dependent_generator" :
           "positive_poor_exposure"
end

"""
    design_rows(config)

Construct the complete locked 1,024-row allocation without instantiating a
library, solving a Bellman equation, or reading any v2 outcome.
"""
function design_rows(config::AbstractDict)
    master_seed = UInt64(config["master_seed"])
    batch_count = Int(config["batch_count"])
    principal_cell_count = Int(config["principal_cell_count"])
    rows = NamedTuple[]
    trial_id = 0
    for batch_id in 1:batch_count
        batch_rows = NamedTuple[]
        for cell_code in 0:(principal_cell_count - 1)
            canonical_index =
                (batch_id - 1) * principal_cell_count + cell_code + 1
            schedule_input =
                master_seed ⊻ SCHEDULE_SALT ⊻
                (UInt64(batch_id) << 32) ⊻ UInt64(cell_code + 1)
            schedule_key = _splitmix64(schedule_input)
            trial_seed = _stable_seed(
                master_seed ⊻ TRIAL_SALT ⊻ UInt64(canonical_index),
            )
            catalog_seed =
                _stable_seed(UInt64(trial_seed) ⊻ CATALOG_SALT)
            project_seed =
                _stable_seed(UInt64(trial_seed) ⊻ PROJECT_SALT)
            deletion_seed =
                _stable_seed(UInt64(trial_seed) ⊻ DELETION_SALT)
            factor_values = ntuple(
                factor_index -> _factor_level(
                    config,
                    FACTORS[factor_index],
                    !iszero(
                        cell_code &
                        (one(Int) << (factor_index - 1)),
                    ),
                ),
                length(FACTORS),
            )
            push!(
                batch_rows,
                (
                    batch_id,
                    principal_cell_id =
                        "C" * lpad(string(cell_code + 1), 3, '0'),
                    canonical_index,
                    replicate_id = batch_id,
                    theorem_regime =
                        isodd(batch_id) ?
                        "primitive_eligible" : "boundary",
                    boundary_mechanism = _boundary_mechanism(batch_id),
                    frontier_density = factor_values[1],
                    module_overlap = factor_values[2],
                    module_complementarity = factor_values[3],
                    project_cost = factor_values[4],
                    duration = factor_values[5],
                    admission = factor_values[6],
                    persistence = factor_values[7],
                    schedule_key,
                    trial_seed,
                    catalog_seed,
                    project_seed,
                    deletion_seed,
                ),
            )
        end
        sort!(
            batch_rows;
            by = row -> (row.schedule_key, row.canonical_index),
        )
        for (within_batch_order, row) in enumerate(batch_rows)
            trial_id += 1
            push!(
                rows,
                (
                    trial_id = trial_id,
                    batch_id = row.batch_id,
                    within_batch_order = within_batch_order,
                    principal_cell_id = row.principal_cell_id,
                    canonical_index = row.canonical_index,
                    replicate_id = row.replicate_id,
                    theorem_regime = row.theorem_regime,
                    boundary_mechanism = row.boundary_mechanism,
                    frontier_density = row.frontier_density,
                    module_overlap = row.module_overlap,
                    module_complementarity =
                        row.module_complementarity,
                    project_cost = row.project_cost,
                    duration = row.duration,
                    admission = row.admission,
                    persistence = row.persistence,
                    schedule_key = row.schedule_key,
                    trial_seed = row.trial_seed,
                    catalog_seed = row.catalog_seed,
                    project_seed = row.project_seed,
                    deletion_seed = row.deletion_seed,
                ),
            )
        end
    end
    return rows
end

function render_registry(config::AbstractDict)
    columns = String.(config["registry"]["columns"])
    rows = design_rows(config)
    io = IOBuffer()
    println(io, join(columns, ","))
    for row in rows
        println(
            io,
            join(
                (
                    string(getproperty(row, Symbol(column))) for
                    column in columns
                ),
                ",",
            ),
        )
    end
    return String(take!(io))
end

function _validate_balance(config, rows)
    trial_count = Int(config["trial_count"])
    cell_count = Int(config["principal_cell_count"])
    replicates = Int(config["replicates_per_principal_cell"])
    _require(length(rows) == trial_count, "registry trial count changed")

    _require(
        length(unique(row.principal_cell_id for row in rows)) == cell_count,
        "registry principal-cell count changed",
    )
    for cell_id in unique(row.principal_cell_id for row in rows)
        cell_rows = filter(row -> row.principal_cell_id == cell_id, rows)
        _require(
            length(cell_rows) == replicates,
            "principal cell $cell_id is not replicated exactly $replicates times",
        )
        _require(
            count(row -> row.theorem_regime == "primitive_eligible", cell_rows) ==
            replicates ÷ 2,
            "principal cell $cell_id is not balanced on theorem regime",
        )
    end

    for factor in FACTORS
        levels = String.(config["levels"][string(factor)])
        counts = [
            count(row -> getproperty(row, factor) == level, rows) for
            level in levels
        ]
        _require(
            counts == fill(trial_count ÷ 2, 2),
            "principal factor $factor is not balanced: $counts",
        )
    end
    _require(
        count(row -> row.theorem_regime == "primitive_eligible", rows) ==
        trial_count ÷ 2,
        "the theorem-regime split is not balanced",
    )

    for prefix_value in Int.(config["stability"]["prefixes"])
        _require(
            prefix_value <= trial_count &&
            iszero(prefix_value % (2 * cell_count)),
            "registered prefix $prefix_value is not a balanced two-batch prefix",
        )
        prefix_rows = rows[1:prefix_value]
        for factor in FACTORS
            levels = String.(config["levels"][string(factor)])
            counts = [
                count(
                    row -> getproperty(row, factor) == level,
                    prefix_rows,
                ) for level in levels
            ]
            _require(
                counts == fill(prefix_value ÷ 2, 2),
                "factor $factor is unbalanced at prefix $prefix_value",
            )
        end
        _require(
            count(
                row -> row.theorem_regime == "primitive_eligible",
                prefix_rows,
            ) == prefix_value ÷ 2,
            "the theorem regime is unbalanced at prefix $prefix_value",
        )
        expected_per_cell = prefix_value ÷ cell_count
        for cell_id in unique(row.principal_cell_id for row in rows)
            _require(
                count(
                    row -> row.principal_cell_id == cell_id,
                    prefix_rows,
                ) == expected_per_cell,
                "cell $cell_id is unbalanced at prefix $prefix_value",
            )
        end
    end
    return true
end

function _validate_seeds(rows)
    _require(
        length(unique(row.schedule_key for row in rows)) == length(rows),
        "schedule keys are not unique",
    )
    seed_columns = (:trial_seed, :catalog_seed, :project_seed, :deletion_seed)
    for column in seed_columns
        seeds = getproperty.(rows, column)
        _require(all(>=(0), seeds), "$column contains a negative seed")
        _require(
            length(unique(seeds)) == length(seeds),
            "$column contains a repeated seed",
        )
    end
    all_seeds = reduce(
        vcat,
        [getproperty.(rows, column) for column in seed_columns],
    )
    _require(
        length(unique(all_seeds)) == length(all_seeds),
        "domain-separated component seeds collide",
    )
    return true
end

function _validate_pilot(config)
    pilot = config["pilot"]
    for stem in ("config", "summary", "report")
        path = _repo_path(pilot["$(stem)_path"])
        _require(isfile(path), "frozen pilot $stem file is absent")
        observed = _sha256_file(path)
        expected = pilot["$(stem)_sha256"]
        _require(
            observed == expected,
            "frozen pilot $stem hash changed: expected $expected, observed $observed",
        )
    end
    _require(
        pilot["pooled_with_v2"] === false,
        "the frozen pilot may not be pooled with v2",
    )
    return true
end

function _validate_output_paths(config)
    output_paths = String.(collect(values(config["outputs"])))
    _require(
        length(unique(output_paths)) == length(output_paths),
        "v2 output paths are not unique",
    )
    pilot_config = TOML.parsefile(
        _repo_path(config["pilot"]["config_path"]),
    )
    pilot_paths = Set(String.(collect(values(pilot_config["outputs"]))))
    overlap = sort(collect(intersect(Set(output_paths), pilot_paths)))
    _require(
        isempty(overlap),
        "v2 would overwrite frozen v1 outputs: $(join(overlap, ", "))",
    )
    return true
end

function _validate_outcomes_absent(config)
    present = sort(
        collect(
            path for path in
            String.(collect(values(config["outputs"]))) if
            isfile(_repo_path(path))
        ),
    )
    _require(
        isempty(present),
        "v2 outcome artifacts exist before the initial lock: $(join(present, ", "))",
    )
    return true
end

function validate_design(
    config::AbstractDict;
    require_registry::Bool = true,
)
    _require(
        config["schema_version"] ==
        "randomized-finite-library-stress-v2-design",
        "unsupported randomized-library v2 design schema",
    )
    _require(
        config["registration_status"] ==
        "design_locked_outcomes_not_run",
        "v2 config is not in the pre-outcome registration state",
    )
    _require(
        config["arithmetic"] == "Rational{BigInt}",
        "theorem-facing v2 arithmetic must remain Rational{BigInt}",
    )
    _require(
        config["theorem_evidence"] === false,
        "randomized v2 rows cannot be theorem evidence",
    )
    _require(Int(config["trial_count"]) == 1024, "registered N must be 1024")
    _require(
        Int(config["principal_factor_count"]) == length(FACTORS),
        "principal factor count changed",
    )
    _require(
        Int(config["principal_cell_count"]) == 2^length(FACTORS),
        "principal cell count changed",
    )
    _require(
        Int(config["trial_count"]) ==
        Int(config["principal_cell_count"]) *
        Int(config["replicates_per_principal_cell"]),
        "trial count does not equal cells times replicates",
    )
    _require(
        Int(config["batch_count"]) * Int(config["batch_size"]) ==
        Int(config["trial_count"]),
        "batch allocation does not sum to N",
    )
    _require(
        config["registry"]["unrecorded_random_streams_permitted"] ===
        false,
        "unrecorded v2 random streams are prohibited",
    )
    _require(
        config["raw_generator"]["direct_compressed_state_construction"] ===
        false,
        "direct compressed-state construction is prohibited",
    )
    _require(
        config["raw_generator"]["resampling_after_outcome_evaluation"] ===
        false,
        "outcome-dependent resampling is prohibited",
    )
    _require(
        config["stability"]["fixed_sample_no_outcome_stopping"] === true,
        "v2 must use a fixed sample without outcome stopping",
    )
    _require(
        config["design_lock"]["outcomes_read_before_lock"] === false,
        "the initial lock must attest that no v2 outcome was read",
    )
    _require(
        config["design_lock"]["candidate_v2_results_used_to_change_specification"] ===
        false,
        "candidate v2 results cannot change the initial specification",
    )
    _validate_pilot(config)
    _validate_output_paths(config)
    rows = design_rows(config)
    _validate_balance(config, rows)
    _validate_seeds(rows)
    if require_registry
        registry_path = _repo_path(config["registry"]["path"])
        _require(isfile(registry_path), "v2 trial registry is absent")
        _require(
            read(registry_path, String) == render_registry(config),
            "v2 trial registry differs from the locked deterministic design",
        )
    end
    return (
        trials = length(rows),
        cells = length(unique(row.principal_cell_id for row in rows)),
        seeds = 4 * length(rows),
        prefixes = Tuple(Int.(config["stability"]["prefixes"])),
    )
end

function write_registry(config_path::AbstractString = DEFAULT_CONFIG)
    config = TOML.parsefile(config_path)
    validate_design(config; require_registry = false)
    registry_path = _repo_path(config["registry"]["path"])
    text = render_registry(config)
    if isfile(registry_path)
        _require(
            read(registry_path, String) == text,
            "refusing to overwrite a nonmatching v2 registry",
        )
    else
        mkpath(dirname(registry_path))
        open(registry_path, "w") do io
            write(io, text)
        end
    end
    println(
        "registered $(config["trial_count"]) trials and " *
        "$(4 * config["trial_count"]) component seeds at " *
        relpath(registry_path, REPOSITORY_ROOT),
    )
    return registry_path
end

function _design_hashes(config::AbstractDict)
    paths = String.(config["design_lock"]["files"])
    for path in paths
        _require(
            isfile(_repo_path(path)),
            "design-lock input is absent: $path",
        )
    end
    hashes =
        Dict(path => _sha256_file(_repo_path(path)) for path in paths)
    aggregate = bytes2hex(
        sha256(
            join(
                ("$path:$(hashes[path])" for path in paths),
                "\n",
            ),
        ),
    )
    return (; paths, hashes, aggregate)
end

_json_escape(value::AbstractString) =
    replace(value, "\\" => "\\\\", "\"" => "\\\"")

function _lock_text(config, hashes, locked_at_utc)
    file_rows = join(
        (
            "    \"$(_json_escape(path))\": \"$(hashes.hashes[path])\"" for
            path in hashes.paths
        ),
        ",\n",
    )
    return """{
  \"schema_version\": \"$(config["design_lock"]["schema_version"])\",
  \"experiment_id\": \"$(config["experiment_id"])\",
  \"locked_at_utc\": \"$locked_at_utc\",
  \"lock_stage\": \"$(config["design_lock"]["lock_stage"])\",
  \"outcomes_read_before_lock\": false,
  \"outcome_files_absent_at_lock\": true,
  \"pilot_results_known_before_lock\": true,
  \"candidate_v2_results_used_to_change_specification\": false,
  \"trial_count\": $(config["trial_count"]),
  \"master_seed\": $(config["master_seed"]),
  \"registered_component_seed_count\": $(4 * config["trial_count"]),
  \"design_sha256\": \"$(hashes.aggregate)\",
  \"files\": {
$file_rows
  }
}
"""
end

function freeze_design(config_path::AbstractString = DEFAULT_CONFIG)
    config = TOML.parsefile(config_path)
    validate_design(config)
    _validate_outcomes_absent(config)
    lock_path = _repo_path(config["design_lock"]["path"])
    _require(
        !isfile(lock_path),
        "initial v2 design lock already exists; verify it instead of overwriting it",
    )
    hashes = _design_hashes(config)
    locked_at_utc = Dates.format(
        Dates.now(Dates.UTC),
        dateformat"yyyy-mm-ddTHH:MM:SSZ",
    )
    mkpath(dirname(lock_path))
    open(lock_path, "w") do io
        write(io, _lock_text(config, hashes, locked_at_utc))
    end
    println(
        "locked randomized-library v2 design=$(hashes.aggregate) at " *
        locked_at_utc,
    )
    return hashes.aggregate
end

function verify_design_lock(config_path::AbstractString = DEFAULT_CONFIG)
    config = TOML.parsefile(config_path)
    validation = validate_design(config)
    lock_path = _repo_path(config["design_lock"]["path"])
    _require(isfile(lock_path), "randomized-library v2 design lock is absent")
    text = read(lock_path, String)
    hashes = _design_hashes(config)
    required_fragments = (
        "\"outcomes_read_before_lock\": false",
        "\"outcome_files_absent_at_lock\": true",
        "\"pilot_results_known_before_lock\": true",
        "\"candidate_v2_results_used_to_change_specification\": false",
        "\"trial_count\": $(config["trial_count"])",
        "\"master_seed\": $(config["master_seed"])",
        "\"registered_component_seed_count\": $(4 * config["trial_count"])",
        "\"design_sha256\": \"$(hashes.aggregate)\"",
    )
    for fragment in required_fragments
        _require(
            occursin(fragment, text),
            "v2 lock is missing required field: $fragment",
        )
    end
    for path in hashes.paths
        fragment =
            "\"$(_json_escape(path))\": \"$(hashes.hashes[path])\""
        _require(
            occursin(fragment, text),
            "v2 lock is missing or stale for $path",
        )
    end
    println(
        "randomized-library v2 design lock current: $(hashes.aggregate); " *
        "N=$(validation.trials), cells=$(validation.cells), " *
        "component_seeds=$(validation.seeds)",
    )
    return hashes.aggregate
end

function main(args = ARGS)
    positional = [
        argument for argument in args if
        !startswith(argument, "--")
    ]
    length(positional) <= 1 || error(
        "usage: lock_randomized_library_design_v2.jl " *
        "[config] [--write-registry|--freeze|--check]",
    )
    config_path = isempty(positional) ? DEFAULT_CONFIG : only(positional)
    modes = filter(
        argument -> argument in
                    ("--write-registry", "--freeze", "--check"),
        args,
    )
    length(modes) <= 1 || error("choose exactly one v2 design-lock mode")
    mode = isempty(modes) ? "--check" : only(modes)
    if mode == "--write-registry"
        return write_registry(config_path)
    elseif mode == "--freeze"
        return freeze_design(config_path)
    end
    return verify_design_lock(config_path)
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    LockRandomizedLibraryDesignV2.main()
end
