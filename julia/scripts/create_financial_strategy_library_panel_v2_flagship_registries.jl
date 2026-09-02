module FinancialStrategyLibraryPanelV2FlagshipRegistries

include(joinpath(@__DIR__, "create_financial_strategy_library_panel_v2_registries.jl"))
const BaseRegistries = FinancialStrategyLibraryPanelV2Registries

export arm_rows,
       burden_rows,
       capability_ids_for_spec,
       capability_rows,
       docket_rows,
       governance_review_units,
       origin_rows,
       scenario_rows,
       seed_namespace,
       seed_rows,
       validate_registry_design,
       validation_work_units,
       write_seed_registry

const DEFAULT_SEED_NAMESPACE = "financial-strategy-library-panel-v2"
const arm_rows = BaseRegistries.arm_rows
const burden_rows = BaseRegistries.burden_rows
const capability_ids_for_spec = BaseRegistries.capability_ids_for_spec
const capability_rows = BaseRegistries.capability_rows
const docket_rows = BaseRegistries.docket_rows
const governance_review_units = BaseRegistries.governance_review_units
const origin_rows = BaseRegistries.origin_rows
const scenario_rows = BaseRegistries.scenario_rows
const validation_work_units = BaseRegistries.validation_work_units
const _render_csv = BaseRegistries._render_csv

seed_namespace() = get(
    ENV,
    "ALGOLIB_FINANCIAL_PANEL_SEED_NAMESPACE",
    DEFAULT_SEED_NAMESPACE,
)

function seed_rows()
    namespace = seed_namespace()
    rows = NamedTuple[]
    for origin in origin_rows(), docket in docket_rows()
        push!(rows, (
            origin_id = origin.origin_id,
            docket_id = docket.docket_id,
            seed_role = "final",
            menu_seed = BaseRegistries._seed(namespace, origin.origin_id, docket.docket_id, "menus"),
            multistart_seed = BaseRegistries._seed(namespace, origin.origin_id, docket.docket_id, "multistart"),
            origin_bootstrap_seed = BaseRegistries._seed(namespace, origin.origin_id, docket.docket_id, "bootstrap"),
        ))
    end
    return rows
end

function validate_registry_design()
    counts = BaseRegistries.validate_registry_design()
    seeds = seed_rows()
    values = vcat(
        getfield.(seeds, :menu_seed),
        getfield.(seeds, :multistart_seed),
        getfield.(seeds, :origin_bootstrap_seed),
    )
    length(unique(values)) == length(values) || error("flagship seed collision")
    return counts
end

function write_seed_registry(path::AbstractString)
    validate_registry_design()
    mkpath(dirname(path))
    open(path, "w") do io
        write(io, _render_csv(seed_rows()))
    end
    return path
end

end
