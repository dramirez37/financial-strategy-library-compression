# Artifact Manifest

## How to use this manifest

This is the public lineage index for the preprint's formal sources, exact
fixtures, registered experiments, generated manuscript artifacts, and
redistributable financial aggregates. Start with `README.md` for the paper and
repository overview, use `REPRODUCIBILITY.md` for commands and environments,
and consult `DATA_ACCESS.md` before any financial replay.

An artifact's presence in this manifest does not collapse evidence classes.
Lean source records kernel verification of an encoded statement; exact Julia
artifacts record finite computations; randomized outputs record evidence under
the registered synthetic generator; and financial outputs record
retrospective licensed-data diagnostics. `THEOREM_LEDGER.md` and
the manuscript validation-status appendix are authoritative for claim status.

The tables below preserve registered identifiers, paths, hashes, producers,
and validation boundaries. PUBLIC GENERATED paths are redistributable under
the rights and third-party exclusions in `LICENSE`; licensed rows and local
provenance are outside this manifest's distributable artifact surface.

## Reader index

| Reader need | Canonical record |
|---|---|
| Paper overview and minimum commands | `README.md` |
| Environment, seeds, configurations, and exact commands | `REPRODUCIBILITY.md` |
| Formal claim and axiom status | `THEOREM_LEDGER.md` and `formal/StrategyInnovation/Audit/AxiomAudit.lean` |
| Licensed-data input contract | `DATA_ACCESS.md` |
| Public/private packaging boundary | `make public-audit`, `.gitignore`, and `DATA_ACCESS.md` |
| Citation metadata | `CITATION.cff` |
| Software, content, and third-party rights | `LICENSE` |

## Preprint v0.1.1-arxiv manuscript-facing release inventory

This table is the complete inventory of generated files read by the final
main-paper and Online Supplement source graphs, plus the two distributed PDFs.
The source-graph membership was taken from the successful final LaTeX recorder
files. “Exact” means exact finite arithmetic for the source computation; TikZ
coordinates and displayed decimal summaries remain presentation layers.

| Public artifact | Producing script | Source configuration or registered inputs | Arithmetic | SHA-256 | Release status |
|---|---|---|---|---|---|
| `manuscript/figures/financial_innovation_safe_compression.tex` | `julia/scripts/generate_manuscript_numerical_artifacts.jl` | `financial_terminal_audit.toml`, `financial_annual_walkforward_audit.toml`, committed audit aggregates | exact counts with Float64 displayed diagnostics | `0d4c929f91e8c5c7230cfb09ed26663274ef91193450a5793f417ed6fc85c35f` | PUBLIC GENERATED; main paper |
| `manuscript/figures/innovation_safe_bridge.tex` | `julia/scripts/generate_figure_audit_artifacts.jl` | `innovation_safe_bridge.csv` exact fixture | `Rational{BigInt}`; rendered coordinates | `54de1ee03fdfc17fbadc8177d4b541a0c6b1e756bbb28b95f1ba74fa2e85d036` | PUBLIC GENERATED; main paper |
| `manuscript/figures/unified_canonical_transition.tex` | `julia/scripts/solve_unified_canonical_benchmark.jl` | `unified_canonical_benchmark.toml` | `Rational{BigInt}`; rendered coordinates | `cbabe6b670f089eeb7aed6267abde4e8d3ce4bab578b027d304bc25147c076f8` | PUBLIC GENERATED; main paper |
| `manuscript/figures/unified_economic_geometry.tex` | `julia/scripts/generate_figure_audit_artifacts.jl` | `unified_elasticity_switching_v1.toml` and exact capacity/penalized-path CSVs using the translated display burden | `Rational{BigInt}`; rendered coordinates | `064408990db6a515ed7124a2b8c52b1874c625cf7d2bbec4fb3a4b88e2c1fe3a` | PUBLIC GENERATED; main paper |
| `manuscript/figures/dynamic_research_policy_regions.tex` | `julia/scripts/generate_dynamic_policy_figure.jl` | `unified_comparative_statics.toml` and frozen family-G rows in `unified_comparative_statics_surface.csv` | Float64 numerical diagnostic | `8df3b8f2d9ebfbfadaaa468327bc03dc56ef565bb4cb27f4202886383309ba33` | PUBLIC GENERATED; supplement |
| `manuscript/figures/financial_coverage_comparison.tex` | `julia/scripts/generate_manuscript_numerical_artifacts.jl` | the two financial-audit configs and committed uncertainty aggregates | Float64 displayed audit summaries | `5bb05e80ab93ee77423d1c03b6aa2d925a262447e107feadca8256fb40357faa` | PUBLIC GENERATED; supplement |
| `manuscript/figures/unified_canonical_convergence.tex` | `julia/scripts/generate_manuscript_numerical_artifacts.jl` | `unified_canonical_benchmark.toml`, committed canonical convergence CSV | Float64 diagnostics; exact reference solution separate | `5e2b0a349b34d99eb0c574aa3a74aae1305365ff477e81957fe8d0086042aa5f` | PUBLIC GENERATED; supplement |
| `manuscript/tables/main_canonical_stationary_solution.tex` | `julia/scripts/generate_main_text_tables.jl` | exact canonical stationary/resource summaries from `unified_canonical_benchmark.toml` | `Rational{BigInt}` | `a7d4074c9229c175f969f80293f398db924357f8d65a3bc3b7a74c55f74d2b0b` | PUBLIC GENERATED; main and supplement |
| `manuscript/tables/main_financial_resource_compression.tex` | `julia/scripts/generate_main_text_tables.jl` | `financial_resource_optimization.toml`, certified solution CSV | exact post-solve rationals; HiGHS-qualified selection | `77a67eeb9df5cf741ac7b235f4c251270e64e1715e5caa71cad07c7f8391cde7` | PUBLIC GENERATED; main paper |
| `manuscript/tables/main_greedy_global_comparison.tex` | `julia/scripts/generate_main_text_tables.jl` | `resource_optimization_counterexamples.toml`, exact fixture JSON | `Rational{BigInt}` | `d0a25ace263c4cfc46c1c6690b484bf1156bf31f39b7f873dc402f2754272b38` | PUBLIC GENERATED; main paper |
| `manuscript/tables/main_randomized_optimization_summary.tex` | `julia/scripts/generate_main_text_tables.jl` | `randomized_library_optimization_extension_v1.toml`, frozen v2 registry/locks and aggregates | exact counts/fractions; approximate displayed means | `e17cc3c48196a95190b53bdebf58b5405d2fe3f4bfb2dbf76ee3c5387f8ee89d` | PUBLIC GENERATED; main paper |
| `manuscript/tables/main_randomized_price_elasticities.tex` | `julia/scripts/generate_main_text_tables.jl` | same registered randomized optimization inputs | exact rational source rows; approximate displayed means | `ea9d9259c5109b36457d0dbbdda08e2cea368f982ffe592bddf26f52bc9d1a0d` | PUBLIC GENERATED; main paper |
| `manuscript/tables/unified_canonical_resource_channel_elasticities.tex` | `julia/scripts/run_unified_resource_benchmark.jl` | `unified_canonical_resources.toml` | `Rational{BigInt}` | `bc419c4a344ae2d5c6a2991e169939886ddf8ea42a08a1bc07b72e0de15861c9` | PUBLIC GENERATED; main paper |
| `manuscript/tables/financial_design_summary.tex` | `julia/scripts/generate_manuscript_numerical_artifacts.jl` | the two financial-audit configs and committed aggregates | exact counts with Float64 audit summaries | `c888dd869a630cd34618aa3c326728f989f67c947ef7a261e9583a20318084e0` | PUBLIC GENERATED; supplement |
| `manuscript/tables/numerical_mechanism_summary.tex` | `julia/scripts/generate_manuscript_numerical_artifacts.jl` | `compression_experiments.csv` and `theorem_mechanism_{pruning_loss,decomposition,coverage_geometry}.csv` | `Rational{BigInt}` | `61a85ebb33fe920d8430de1c8a80af0cc1c37113ad6c7eba82a265f38663d7b1` | PUBLIC GENERATED; supplement |
| `release/v0.1.1-arxiv/financial-strategy-library-compression-preprint.pdf` | `manuscript/build.sh` | committed main-paper source graph and bibliography | not applicable; compiled presentation of separately classified evidence | `6f4097b450b3dcb0413513f8fbf9d2f7c4c91091a996cf38a988d1d230a4fde1` | PUBLIC GENERATED; final 43-page release-candidate PDF |
| `release/v0.1.1-arxiv/financial-strategy-library-compression-online-supplement.pdf` | `manuscript/online_supplement/build.sh` | committed supplement source graph and public generated inputs | not applicable; compiled presentation of separately classified evidence | `85e4e28a52aaad72edcca2a1611be927b65f69c76c0836030b0abf7ae384f481` | PUBLIC GENERATED; final 41-page release-candidate PDF |
| `release/v0.1.1-arxiv/financial-strategy-library-compression-arxiv-source.tar.gz` | `scripts/build_arxiv_bundle.sh` | the two active LaTeX source graphs, matching bibliography and `paper.bbl`, and only their required public figures, tables, and displayed CSV records | not applicable; packaging artifact only | `d7270f2aad722cd6560c4d549624a988fe1658c035d8a1f8d3ad1f10b8272606` | PUBLIC GENERATED; arXiv upload source with `paper.tex` first and `supplement.tex` second |

`release/v0.1.1-arxiv/RELEASE_METADATA.md` records the release identifier,
date, exact PDF hashes, and an `export-subst` commit placeholder. In a release
archive that placeholder expands to the exact source commit without creating
an impossible self-referential commit hash in the committed file.

## Exact Lean–Julia bridge artifacts

| Artifact ID | Path | SHA-256 | Producer and validation |
|---|---|---|---|
| `LJB-SCHEMA-v1` | `shared/schemas/exact_fixture.schema.json` | `154bf02cc432bd1bdf14f4f5830d9ef514dacd1fcbd0ba0b9f9829f1a195e61a` | adopted version-1 exact finite interchange schema |
| `LJB-CODE-v1` | `julia/scripts/export_exact_fixtures.jl` | `9f1da361c6cc3af48d3ce5cde665e1b54d8d849cc9f48b374577fe32286c2a2f` | deterministic dependency-free JSON/Lean renderer with semantic validation, cost-covering fixture labels, and `--check` |
| `LJB-TEST-v1` | `julia/test/test_exact_fixture_bridge.jl` | `23ad553ffc22fdcaa1da61f707defa9b4a3582860f779395895fe27e9cb46c2c` | 45 exact output, drift, invalid-input, and deterministic-order checks |
| `LJB-LEAN-v1` | `formal/StrategyInnovation/Fixtures/Generated.lean` | `c35ef10fab4857df19f5c13394a4bd08c71ac58073aa65af5cc86e7816918534` | exact definitions and kernel-checked equality/inequality examples |
| `LJB-CURRENT-FUTURE-v1` | `shared/exact_fixtures/current_zero_future_positive.json` | `9d3a55176d5cdc0a23e17c5d2216dea5df8a64942fa0656de7ecf79a76b76cc4` | generated from the exact Julia fixture catalog |
| `LJB-FRONTIER-LOSS-v1` | `shared/exact_fixtures/frontier_pruning_loss.json` | `3f27b23764620fadc98a25493f714bef7ee75d07f57d95f390aa466904183e56` | generated from the exact Julia fixture catalog |
| `LJB-MULTIGAP-v1` | `shared/exact_fixtures/multi_gap_disconnected_region.json` | `06020cc5f97213e5c11fb65880b24222877ac53281339893c24c67dda48aacd9` | generated from the exact Julia fixture catalog |
| `LJB-DECOMPOSITION-v1` | `shared/exact_fixtures/operational_generative_decomposition.json` | `f65488c3a41fe8e453200cbc94fcac183398aed906ef8e2100cc806cb09889f6` | generated from the exact Julia fixture catalog |
| `LJB-SAFE-DELETE-v1` | `shared/exact_fixtures/safe_deletion.json` | `69ae7488ecd6a465ad09fc3ead63169a1783d60270bc8c78c4aafd903ba5188a` | generated from the exact Julia fixture catalog |
| `LJB-SINGLE-GAP-v1` | `shared/exact_fixtures/single_gap_research_region.json` | `0f4d82bd74705dce9563775c14ac27fa4e76d6d7b445aeb39f820a50f239460d` | generated from the exact Julia fixture catalog; legacy filename retained, publication label says cost-covering set |
| `LJB-INNOVATION-EQUATION-v1` | `shared/exact_fixtures/strategy_innovation_equation.json` | `f33c4e30f48dcec864d631c47fcde1097ca2b9664090431c72ef8e37a37222d0` | generated from the exact Julia fixture catalog |

These artifacts show exact agreement on seven selected finite inputs. They do
not replace any named Lean theorem, axiom report, or raw-model adapter.

## Unified comparative-statics artifacts

| Artifact ID | Path | SHA-256 | Producer and validation |
|---|---|---|---|
| `UCS-CORE-v1` | `julia/src/ComparativeStatics.jl` | `c6c6f1e8436d25eff426442ccf0e1f57986dd5cc49b63bf1b4499230fb764148` | unified twelve-primitive exact/raw and sparse Float64 engine with Bellman gates, theorem-tagged sign checks, and explicit counterexample-regime flags |
| `UCS-CODE-v1` | `julia/scripts/run_unified_comparative_statics.jl` | `76d52826f97af1ede9db5d1e0868914dfbf395b297ab27c6d3b92ae0f0eceb0b` | deterministic configuration runner, machine-output renderer, publication-SVG renderer, and nonmutating `--check` |
| `UCS-TEST-v1` | `julia/test/test_comparative_statics.jl` | `d080c39fbea417d90c58fcf70f69972a3c5693aa47694f006cc49ec4382f6dca` | exact/raw routing, exact-fixture, sparse-gate, sign-boundary, determinism, output, exact categorical/structural drift, and tolerance-bounded cross-platform Float64 rendering checks |
| `UCS-CONFIG-v1` | `experiments/configs/unified_comparative_statics.toml` | `f1f1c9fe77e96ad0be5d16de9c2f79c9c2bbb99df27464cb97d4955a53033633` | committed baseline, 12 one-at-a-time parameter axes, frontier--closure grid, solver gates, and output paths; no randomness |
| `UCS-SURFACE-v1` | `experiments/results/summaries/unified_comparative_statics_surface.csv` | `02a00ad0034d69341581a7568dacc240f634b0badf740b093274c220d6bf8f7c` | 78 sparse Float64 response rows with every requested outcome, diagnostics, and regime flags |
| `UCS-INTERACTION-v1` | `experiments/results/summaries/unified_comparative_statics_interaction.csv` | `81d6e43b046c9fe1ccaf40edba5b4ad367fb96f3421fc58efdb1ea46365e0b3d` | 36 deterministic frontier--closure cells with value, research-frequency, action, and $J$ channels |
| `UCS-SIGNS-v1` | `experiments/results/summaries/unified_comparative_statics_sign_checks.csv` | `15e21edf2a9dcfb09ff037a14082fe5ce08e80b9e1f2aa008efc49077a2d718e` | 11 theorem-tagged checks separating applicable sign restrictions from persistence, delay, cutoff, and T7 boundary regimes |
| `UCS-FIXTURES-v1` | `experiments/results/summaries/unified_comparative_statics_exact_fixtures.csv` | `c415aeaa5b6bd98a952f718b33550bb4504ad760aaca5d26b81657f9f965798f` | eight exact Rational rows reproducing selected T4, S2, T6, S6, S7, and T7 Lean fixtures |
| `UCS-SUMMARY-v1` | `experiments/results/summaries/unified_comparative_statics_summary.json` | `81ae2dc1e6f90005365ecc3f2fd1db0645fa0fe33df6442b375ac7a01b9e3d1c` | baseline outcomes, row counts, solver gates, applicable-sign result, fixture result, determinism result, and explicit boundary flags |
| `UCS-FIG-VALUE-v1` | `manuscript/figures/unified_comparative_statics_value.svg` | `36e155443061567a46de35dd4c74549049ee987806bd22f4dd652ac61e6bb737` | publication value-response panels rendered directly from `UCS-SURFACE-v1`; XML-valid and visually inspected |
| `UCS-FIG-POLICY-v1` | `manuscript/figures/unified_comparative_statics_policy.svg` | `4744bc4cb4dccff10e640c246ce642cd803d76dce3f1d15f02ea32f1aa3c0f7a` | publication policy-response and frontier--closure heat-map panels rendered from registered CSV rows; XML-valid and visually inspected |

The exact fixture rows validate computations against selected encoded
statements but do not replace their Lean proofs. Float64 response surfaces are
numerical diagnostics. Inapplicable sign claims remain machine-visible as
counterexample or missing-certificate regimes rather than being reported as
passes. The artifact test compares exact fixtures, schemas, row ordering,
categorical fields, policies, flags, and non-Float64 outputs byte-for-byte.
Declared Float64 result columns and numeric value-figure coordinates use
absolute and relative tolerances of `2e-12`, below the recorded response-surface
value-error certificate, so Linux/macOS last-digit rendering differences do not
mask structural or material numerical drift.

## Registered exact elasticity and switching artifacts

| Artifact ID | Path | SHA-256 | Producer and validation |
|---|---|---|---|
| `UES-CONFIG-v1` | `experiments/configs/unified_elasticity_switching_v1.toml` | `1a6d6f1a41def79773751216101f17169f58bc928e2191ba8362715edcd9c3db` | pre-outcome exact grid, estimand, gate, source-table, and figure contract |
| `UES-LOCK-v1` | `experiments/unified_elasticity_switching_v1/DESIGN_LOCK.json` | `6c0053bf38e503c1b96122ecb6eec26463b08bd92b4b6953facacd2636475aa0` | source hashes and output-absence attestation frozen before extension outcomes |
| `UES-CODE-v1` | `julia/scripts/run_unified_elasticity_switching_experiment.jl` | `81049bcee26a8c6e22e22282ebdd42c5644bc19d4f23f51cb4e3bff81721cd25` | exact bridge, fixed-policy derivative, curvature, robustness, resource-path, CSV/JSON/SVG, and nonmutating drift runner; publication renderers label the common-unit burden as a display quantity |
| `UES-TEST-v1` | `julia/test/test_unified_elasticity_switching_experiment.jl` | `6ed4d0afcc9cfce960748c457ee8923c2e893ed273895dc3a4117e6c4529f6a2` | 143 focused exact registration, identity, monotonicity, breakpoint, source, and artifact checks |
| `UES-BRIDGE-v1` | `experiments/results/summaries/unified_elasticity_switching_v1_bridge.csv` | `e7c89be96c7e1a62f70e2e5189b7d91d1892f3d84849ac546037312eb8450aca` | 45 exact bridge-margin rows with five primitive elasticities and identity gates |
| `UES-DURATION-v1` | `experiments/results/summaries/unified_elasticity_switching_v1_duration_convexity.csv` | `5d2887efbe6240923b4b4b6b5c87ea5ab3256bfb181db811eb9e9eb4886e8933` | 25 exact duration--belief rows with channel derivatives, Q gaps, and belief curvature |
| `UES-CHANNEL-v1` | `experiments/results/summaries/unified_elasticity_switching_v1_channel_contributions.csv` | `7e36ff4a355731c7ea2d26bd838a7f2d6e609505326358b60156ce4310c44265` | 16 exact operational/generative value and discount-contribution rows |
| `UES-CAPACITY-v1` | `experiments/results/summaries/unified_elasticity_switching_v1_capacity.csv` | `79eed7b19cb99eef994ee78fb78408e73712e5185b6efac1fb1da8dc341b0ca9` | 30 exact attainable display-capacity optimizers, shadows, elasticities, and enumeration certificates |
| `UES-PENALTY-v1` | `experiments/results/summaries/unified_elasticity_switching_v1_penalized_path.csv` | `9fd0cbe51d1dc3d5c8a49994c57e4fc6164abcd6a3b35bb6877414876b9d64cf` | 24 exact breakpoint/open/terminal price cells with complete optimizer ties, display burdens, translated penalized values, and selected actions |
| `UES-LIBRARY-SWITCH-v1` | `experiments/results/summaries/unified_elasticity_switching_v1_library_breakpoints.csv` | `f6a32883cc8da556c2e1d2dca45c1a8e4a1bed0ecfd9fce28117f995d9b70918` | all 168 pairwise intersections with globally active exact switches labeled |
| `UES-BELLMAN-SWITCH-v1` | `experiments/results/summaries/unified_elasticity_switching_v1_bellman_breakpoints.csv` | `e5a585744e92c38292aa821155bfeaeba83a883424f3ac9c698252f925b99647` | 118 exact Q-gap distances and explicitly nonexact registered primitive switch brackets |
| `UES-ROBUSTNESS-v1` | `experiments/results/summaries/unified_elasticity_switching_v1_robustness.csv` | `894347c46194c92f73eeb8153da3f9fe87d8dbf1e53268a409ca885706bbd46c` | 75 exact one-at-a-time admission, survival, discount, cost, and payoff-scale rows |
| `UES-SUMMARY-v1` | `experiments/results/summaries/unified_elasticity_switching_v1_summary.json` | `783b6fe255232bf4bb77dcaa3ac115ee3cb29c5df097cb9a688333374864c6e0` | row counts, design identity, definitions, and all exact hard gates |
| `UES-FIG-MARGIN-v1` | `manuscript/figures/unified_elasticity_switching_v1_margin_elasticity.svg` | `fe0949c59be59f8a6736910cfabb2195e47027e0085e41059b697394c091ad11` | exact-source net-margin elasticity curves; visually inspected |
| `UES-FIG-CAPACITY-v1` | `manuscript/figures/unified_elasticity_switching_v1_value_capacity.svg` | `f84e885960a1bedf9460132b0176dd73d21c699508dcbae7b5c339b727c8232e` | exact-source display-capacity stairs with the common mandatory unit identified; visually inspected |
| `UES-FIG-ENVELOPE-v1` | `manuscript/figures/unified_elasticity_switching_v1_penalized_envelope.svg` | `9dd4f6d6ceb359056dc943094699e3c1fa5fa34834cb1c94e3f76340b381108b` | exact active affine branches of the translated display penalized value; visually inspected |
| `UES-FIG-BURDEN-v1` | `manuscript/figures/unified_elasticity_switching_v1_selected_burden.svg` | `d390d32f8aeec43684b935fa083afe1bc9297aae482929a60bfcea238c833e1b` | exact-source weakly decreasing display-burden paths; visually inspected |
| `UES-FIG-DURATION-v1` | `manuscript/figures/unified_elasticity_switching_v1_innovation_duration.svg` | `0b43b58d158bdacd373394a3a94ead07995cc162036de771f3dde338a0382ee3` | exact-source duration heat map and local curvature symbols; visually inspected |
| `UES-FIG-SWITCH-v1` | `manuscript/figures/unified_elasticity_switching_v1_switching_map.svg` | `efe0a3c8a49490f2c8e18af01ef09fbdbd29cafe3dbc188975d161f629c099c8` | exact library-price cells with Bellman action labels and breakpoint metadata; visually inspected |

These artifacts validate one preregistered finite Julia design. The fixed-policy
derivatives are local branch derivatives, the adjacent primitive switches are
brackets rather than exact roots, and none of the rows changes Lean theorem
status.

## Randomized finite-library stress artifacts

| Artifact ID | Path | SHA-256 | Producer and validation |
|---|---|---|---|
| `RLS-CORE-v1` | `julia/src/RandomizedLibraries.jl` | `0fc65d721d6093cfbac085065f01fdc902f07c9d6aba4f64f17a144f02304492` | exact raw-library generator, public deterministic model builder, four pruning evaluators, Bellman/value decomposition, synthetic $J$, and complete source-row construction |
| `RLS-CODE-v1` | `julia/scripts/run_randomized_library_stress.jl` | `bcb2761a442a4b12c2cb5b78fc8ef4c5eaacf1bd42877efba2af1b9feb434572` | deterministic runner, exact aggregation, report/CSV/JSON/SVG renderers, Wilson intervals, gates, and nonmutating `--check` |
| `RLS-TEST-v1` | `julia/test/test_randomized_libraries.jl` | `329088bee5bf6252ce824caad0ca7ea2ad4fb75b955d18729505d957829043d4` | 102 design, exact-fixture, determinism, row-contract, gate, report, figure, and artifact-drift checks |
| `RLS-CONFIG-v1` | `experiments/configs/randomized_library_stress.toml` | `aa3c04898123b50546dcbf142bd91bbd9da9f926b71ae910e6819b9f5ad31794` | 90 marginally balanced trials, StableRNG seed, exact factors, horizon, budgets, and output contract |
| `RLS-REPORT-v1` | `RANDOMIZED_LIBRARY_REPORT.md` | `ecaba2b6a19cee7333da7b8a36c5a480d2548f80e2d3d2057e41ff6cc444b559` | answer-first technical report with estimands, findings, evidence boundary, limitations, and complete source-data links |
| `RLS-TRIALS-v1` | `experiments/results/summaries/randomized_library_trials.csv` | `ebf50ebd233acf7788d05b6aa57eb783227d8a798a727bf730752766c3dd2923` | 90 exact trial/factor/value/$J$/gate rows |
| `RLS-PRUNING-v1` | `experiments/results/summaries/randomized_library_pruning.csv` | `95d51a7bf10f8771fc71c562b212654ac47e4f25bf6810d4edfd448b1c4209dc` | 360 exact method comparisons with budgets, signed components, positive losses, and retained IDs |
| `RLS-CARRIERS-v1` | `experiments/results/summaries/randomized_library_carriers.csv` | `84d3e35cb482f3e282f89c5f15f6b9256b36f8deff0212426d336492ff7a84fb` | 360 one-carrier deletion diagnostics |
| `RLS-PROFILES-v1` | `experiments/results/summaries/randomized_library_profiles.csv` | `43d9c315b78b07ad14c62634cc63048d3f0804ddae57a3c59cfe119a335b5fa7` | complete 1,884-row exact strategy-by-belief profiles |
| `RLS-MODULES-v1` | `experiments/results/summaries/randomized_library_modules.csv` | `b31965123c85b4d0cbc8c0393c99d3323311d8011676615313e2f86c40f568d8` | complete 2,531-row strategy-module incidence |
| `RLS-CLOSURES-v1` | `experiments/results/summaries/randomized_library_closures.csv` | `eb674fd7a4c3a1c2a22eedd19b782ce87256a59d6be776f2c1c9551d189a92c5` | all 1,680 closure-table input/output rows |
| `RLS-KERNELS-v1` | `experiments/results/summaries/randomized_library_kernels.csv` | `e7e9dd2e84acd92ffba465f8fbdbf001773a5504481cb9c190c0e0860827e88e` | all 870 exact belief-transition rows |
| `RLS-PROJECTS-v1` | `experiments/results/summaries/randomized_library_projects.csv` | `c6db4a443d37db50215b1e7517a60bccf4fe22919d3a7ff6dcd0ef2105e2e9b5` | 180 complete project/candidate/requirement/timing rows |
| `RLS-METHOD-SUMMARY-v1` | `experiments/results/summaries/randomized_library_method_summary.csv` | `170fece967015f801734b639b905cc6fc337374e2f7e020e33bc51b59fc8f9c6` | four exact method-level reduction and loss summaries |
| `RLS-FACTOR-SUMMARY-v1` | `experiments/results/summaries/randomized_library_factor_summary.csv` | `1eb6bfa35025962c460c7e423a414b3f790a486f17379282a24e5179e7b466cf` | 36 exact factor-level prevalence, magnitude, interaction, and reduction rows |
| `RLS-SUMMARY-v1` | `experiments/results/summaries/randomized_library_summary.json` | `82340ff1a92219cd653f8741996a615d21d93667d37bee81048b37c462805571` | schema, environment, row counts, prevalence, method results, source paths, and all hard gates |
| `RLS-FIG-METHOD-v1` | `manuscript/figures/randomized_library_method_comparison.svg` | `6e3bafab27e695167f162c697f06ac4416fecea4e645c9c180e2b5aa53e61f2a` | four-panel pruning trade-off figure; full-canvas visually inspected |
| `RLS-FIG-PREVALENCE-v1` | `manuscript/figures/randomized_library_prevalence.svg` | `64917f1fc75c1340c9108deac5ac935dcf3fe411a0e9ec0699e82266cf95f495` | denominator-explicit frequency and Wilson-interval figure; visually inspected |
| `RLS-FIG-FACTORS-v1` | `manuscript/figures/randomized_library_factor_contrasts.svg` | `8abb612511783e47c1c0eb07d5be9040205d128bf437d832be57ab63330cdcd2` | all 36 factor-cell loss frequencies with non-color labels; visually inspected |
| `RLS-DESIGN-v2` | `RANDOMIZED_DESIGN_V2.md` | `61e3a821d2b0f0af8385a9e19629abda04b8a72de5da4cb9f29182520611bcf9` | pre-outcome raw-generator, realizable-rectangle, exact-estimand, stability, precision, failure-gate, and amendment protocol |
| `RLS-CONFIG-v2` | `experiments/configs/randomized_library_stress_v2.toml` | `a1e99be2a59e4208e425f5050f397ebfa72e381c0adb762084d856f459b5033d` | 1,024-trial complete seven-factor cross, exact primitive levels, all output paths, pilot hashes, and lock contract |
| `RLS-REGISTRY-v2` | `experiments/randomized_library_v2/TRIAL_REGISTRY.csv` | `669c055f54c86706bd9b2003c6c9f4628c647245909940eea393f3bd40af115c` | complete 1,024-row pre-outcome allocation with schedule keys and all 4,096 permitted component seeds |
| `RLS-LOCK-CODE-v2` | `julia/scripts/lock_randomized_library_design_v2.jl` | `f5bf8aeba3406c12dd6084955fd7315e639daa6f95b12260a475ca295ad11f4c` | deterministic SplitMix64 registry renderer, balance/seed/pilot/output validation, and immutable freeze/check modes |
| `RLS-LOCK-v2` | `experiments/randomized_library_v2/DESIGN_LOCK.json` | `3ad48c4c1fc7965705a41cfc1d9dd8b73414d0aca57f5f68d5afb7d79d2be63d` | initial pre-outcome hash envelope; aggregate design SHA-256 `0b012dfc14f4ea57b0d34877a68d9a546cd499d2270903e772d78b21425d14db`; records all declared v2 outcome paths absent |
| `RLS-LOCK-TEST-v2` | `julia/test/test_randomized_design_v2.jl` | `7eaa3417aedf3e6558036ebd154965cee87bae59d84b38f04a9cb16685593fef` | exact row/cell/prefix/regime/seed fixtures and aggregate-lock validation without outcome generation |
| `RLS-STABILITY-DESIGN-v2a1` | `RANDOMIZED_DESIGN_V2_AMENDMENT_1.md` | `c71d8bcce6165921de3b06e83b37bd9d69c28fdd7fe0106d9676e16ac16672e0` | pre-outcome sequential schedule, exact estimands, interval/MCSE definitions, factor slices, warnings, plot contract, and fixed-final-N rule |
| `RLS-STABILITY-CONFIG-v2a1` | `experiments/configs/randomized_library_stability_amendment_1.toml` | `b34cb219d7395d98a953f2b475e00ef3c64e5bad30cf126c25a1f5a302ac5d49` | machine-readable eight-prefix, eight-estimand, seven-factor precision protocol with no stopping rule |
| `RLS-STABILITY-CODE-v2a1` | `julia/src/RandomizedStability.jl` | `edafb7a71cea8c1b0a489bbd2d13eb278ad734e77c995cf60c83f0361788781b` | exact cumulative/factor summaries, Wilson displays, exact-variance mean MCSEs, sparse warnings, CSV renderers, and dependency-free four-panel SVG |
| `RLS-STABILITY-LOCK-CODE-v2a1` | `julia/scripts/lock_randomized_library_stability_amendment.jl` | `1486c3db118d4d258f822d1efa40f8ea5118e0b185ece833f58d935becb13857` | parent-lock, no-outcome, specification, file-hash, immutable-freeze, current-lock validation, and the taxonomy-migration receipt check below |
| `RLS-STABILITY-LOCK-v2a1` | `experiments/randomized_library_v2/DESIGN_LOCK_AMENDMENT_1.json` | `caca056dcba81aa6caaff75adeb6b6ab7b8db6a0b03050a7c7eca5ffa6406f25` | pre-outcome amendment envelope; aggregate design SHA-256 `d9122d258b8fe62d5872c41b0a418b1351a5798b25ddb99ec73b726e324d244f`; records parent current and all v2 outcome paths absent |
| `RLS-STABILITY-TAXONOMY-v2a1` | `experiments/randomized_library_v2/STABILITY_LOCK_TAXONOMY_MIGRATION.toml` | `bfab2175fcd8d4630fb3c81d058faa8088bd0db37790836241d4541d3c0f883b` | post-outcome administrative receipt preserving the registered lock and hash while proving that the global test wrapper changed only by the six registered financial-audit name substitutions |
| `RLS-STABILITY-TEST-v2a1` | `julia/test/test_randomized_stability.jl` | `85a103c417ad03efaaa2d6faa77fcd6b529caa837bff25b28d7957ff029c7943` | 48 exact synthetic-fixture checks for prefixes, counts, estimates, intervals, variances, MCSEs, factor rows, warnings, CSVs, SVG, and rejection gates |
| `RLS-STABILITY-LOCK-TEST-v2a1` | `julia/test/test_randomized_stability_amendment.jl` | `2af2ba99fadc06ce8de10b0fb85e4eb7400d51c677fe91ace3d5372c68ad5b53` | amendment schema, fixed-maximum, prefix/factor/estimand, immutable-lock, and negative mutation checks |
| `RLS-EXEC-DESIGN-v2a2` | `RANDOMIZED_DESIGN_V2_AMENDMENT_2.md` | `c4da5f5c4ba12e85026ad50e2042570f06bbb6341fce3bfda06e1f6bac614bee` | prospective executable-generator, raw-witness, state-dependent-law, audit, abort, and serialization contract |
| `RLS-EXEC-CONFIG-v2a2` | `experiments/configs/randomized_library_execution_amendment_2.toml` | `a585a51b872b4eb813246ef87220f03de5130013f09f980b59669fe2a3155bf5` | machine-readable execution choices and two prospectively added output paths |
| `RLS-EXEC-LOCK-v2a2` | `experiments/randomized_library_v2/DESIGN_LOCK_AMENDMENT_2.json` | `7e6d19c1f29312a3ca42d1182687d744af35b75a1d6d1b709fc20c50162141f0` | immutable pre-outcome envelope; aggregate SHA-256 `8c278c07d998ba118d98c78cc1373a47ab63127f00d606c0042c006dac11e7be` |
| `RLS-EXEC-LOCK-CODE-v2a2` | `julia/scripts/lock_randomized_library_execution_amendment.jl` | `c4f86a221d8fbe0e0efe2d7a0469bd70e4ae86b012c2ccb9fdd58f1954c858d0` | parent-lock, output-absence, frozen-file, and immutable-amendment checks |
| `RLS-EXEC-CORE-v2` | `julia/scripts/randomized_library_v2_core.jl` | `edb755cdbc2f0f4777f781b0df75a3361ed24257ebac6ab838aeb63c4cc39e17` | exact registered raw-library generator, four-corner audit, pruning and interaction calculations, source rows, and hard gates |
| `RLS-EXEC-CODE-v2` | `julia/scripts/run_randomized_library_stress_v2.jl` | `f974da631598162193d3460f5874b6502a169ef34a564ee9a2825c1fa7a7f2b2` | fixed-N runner, abort-before-write gate, exact CSV/JSON/report renderers, four SVG producers, and byte-current replay |
| `RLS-EXEC-AUDIT-v2` | `julia/scripts/audit_randomized_library_v2_results.jl` | `f4fab164b3a83393ee50f50869160e3618bacc0ebd07c93a763c8ba86da09a3e` | independent result-reader reconciliation of row counts, raw witnesses, exact losses/signs, balance, stability totals, summary fields, and pilot hashes |
| `RLS-EXEC-TEST-v2` | `julia/test/test_randomized_libraries_v2_execution.jl` | `7162cbaf8e2ef9dc8df76ff27256eccf52f5b2166d29bd4fa0cdae80211f3f32` | 36 exact eligible/boundary raw-generation, witness, value, decomposition, safe-zero, and mechanical-predicate checks |
| `RLS-REPORT-v2` | `RANDOMIZED_LIBRARY_REPORT_V2.md` | `299dcde59cf6577b5b7e9561c29b59b9b8c50b1b9e085470574800531940efbb` | fixed-N result overview, hard gates, precision boundary, artifact index, and simulation-only scope |
| `RLS-TRIALS-v2` | `experiments/results/summaries/randomized_library_v2_trials.csv` | `38651b81826bc3bc2df88124c415e173917d7b25ca2c7f78f981a3acc67f4f42` | all 1,024 registered trials, seeds, exact values, mechanical flags, interactions, and hard gates |
| `RLS-CORNERS-v2` | `experiments/results/summaries/randomized_library_v2_rectangle_corners.csv` | `224a11c4ce768475c91415e557ef5186a4da894e7af0400a8d88e523643ff415` | all 4,096 actual raw corners with shared catalog/closure and value gates |
| `RLS-TRANSITIONS-v2` | `experiments/results/summaries/randomized_library_v2_rectangle_transitions.csv` | `8f1b6f3f051a933582eb414e3031b5a0590b5d47c4d6894dd6048a8c218f79b4` | all 150,882 raw-derived corner transition rows |
| `RLS-PRUNING-v2` | `experiments/results/summaries/randomized_library_v2_pruning.csv` | `3528f2d79740f8728d876f520764fb29309c4689c172e0090ec1a5c6392bb78a` | 4,096 exact method comparisons, loss components, decompositions, and retained raw IDs |
| `RLS-ASSETS-v2` | `experiments/results/summaries/randomized_library_v2_assets.csv` | `52528db64bc9ee8f1fe1856a86592d4cf3a209791e459b4d910597c4afaa1179` | 5,120 one-asset operational/generative diagnostics |
| `RLS-ACTIONS-v2` | `experiments/results/summaries/randomized_library_v2_actions.csv` | `130300ac0c56a8b50d19808ea86d948bae12bbad661604ad6d98cd822573cc8b` | 135,678 exact derived action-menu and switching observations |
| `RLS-PROFILES-v2` | `experiments/results/summaries/randomized_library_v2_profiles.csv` | `5bfb889b734de849902b050030367e1d8a3c2973c0c8049163252f0e664ddef3` | 24,576 exact raw strategy-profile rows |
| `RLS-MODULES-v2` | `experiments/results/summaries/randomized_library_v2_modules.csv` | `5ad49395ba13e7a787d029ab9ba1adc29ea72a9561b4cac924c52bb6fd38a701` | 57,344 raw strategy-module incidence rows |
| `RLS-CLOSURES-v2` | `experiments/results/summaries/randomized_library_v2_closures.csv` | `0e4ba68d3d1765c7b75ebd6bfad48b9e72c029900c4cbe34262ac375722faa35` | all 131,072 registered closure input/output rows |
| `RLS-KERNELS-v2` | `experiments/results/summaries/randomized_library_v2_kernels.csv` | `d6f5ee4f709a3f276f17d796a2eed5d7ee70070d4fd760c5db9562e51a0c2c17` | all 9,216 exact belief-transition rows |
| `RLS-PROJECTS-v2` | `experiments/results/summaries/randomized_library_v2_projects.csv` | `6c280c8b9a05bfedbbca57973145f71f85f50f0e8507ccf6a1ede29b362ddcbe` | 8,192 project/corner requirement, cost, duration, admission, and generation-law rows |
| `RLS-WITNESSES-v2` | `experiments/results/summaries/randomized_library_v2_raw_witness_manifest.csv` | `f0d42446ec8aa7e0bf23232dee5dda6e181bd34ed1788fae83f629ab84c76fca` | 47,458 compressed-state-to-raw-library witness records |
| `RLS-METHOD-SUMMARY-v2` | `experiments/results/summaries/randomized_library_v2_method_summary.csv` | `8eb34bf04224c42d0f33eed4a538d55331795b8c75354afc221adba303af2a0c` | four exact method-level compression and loss summaries |
| `RLS-FACTOR-SUMMARY-v2` | `experiments/results/summaries/randomized_library_v2_factor_summary.csv` | `bc7058eb9117f113fe5f8495965ba89fa95556b44081561744ba2ca8b001a4cd` | fourteen balanced factor-level exact summaries |
| `RLS-RELATIONSHIPS-v2` | `experiments/results/summaries/randomized_library_v2_relationship_summary.csv` | `4902818c9ca8a2dfff3e9b3dcc116452192c10142aa5dfe35d10ab9c839402c9` | ten registered action-switching and relationship summaries |
| `RLS-STABILITY-v2` | `experiments/results/summaries/randomized_library_v2_stability_summary.csv` | `ff4a0e9c17528367c383c74befd7293ecd1522abb3c94db9e6e5ef98c890d0e3` | 64 cumulative exact estimates with counts, intervals, MCSEs, and sparse warnings |
| `RLS-STABILITY-FACTORS-v2` | `experiments/results/summaries/randomized_library_v2_stability_factor_summary.csv` | `78af20ae0e3e7a629ccd2b591c34325231876d1fb0bdd56101f2fe432fecbd13` | 896 factor-stratified sequential-precision rows |
| `RLS-INTERACTIONS-v2` | `experiments/results/summaries/randomized_library_v2_interaction_signs.csv` | `5bc377252875af4cd7cd91b6078a8aa0f0c88562f3fb764b1430ba4c1d8d845a` | overall and mechanically conditioned exact interaction-sign counts |
| `RLS-SUMMARY-v2` | `experiments/results/summaries/randomized_library_v2_summary.json` | `9702eafc9b165edc55cec1bdf2ef2c1b6886297ae746ded734605a0188831076` | schema, locks, row counts, exact primary estimates, and all aggregate hard gates |
| `RLS-FIG-METHOD-v2` | `manuscript/figures/randomized_library_v2_method_comparison.svg` | `21e90cab182f72bbed0174e44f202e3760bbd2115b140a485dab9d09028bf229` | data-linked method compression/loss comparison |
| `RLS-FIG-PREVALENCE-v2` | `manuscript/figures/randomized_library_v2_prevalence.svg` | `2042e948c2e0969345f39bee6dff8e54a2e7e302a19089e38c39d5962fe50d42` | exact-count prevalence display with descriptive intervals |
| `RLS-FIG-FACTORS-v2` | `manuscript/figures/randomized_library_v2_factor_contrasts.svg` | `2df7bb3258d1f109ebc39f49dfc2ae2f83a4e1f3db28e43cee8eedd6863a6337` | balanced seven-factor contrast figure |
| `RLS-FIG-STABILITY-v2` | `manuscript/figures/randomized_library_v2_stability.svg` | `e20ad213d9c62a5816e13029942c0d3330a80cd7dc2bdcca066addecc58df45b` | four-panel registered-prefix stabilization figure |

All RLS model calculations are exact; Wilson intervals and displayed decimal
rounding are presentation transforms. The randomized frequencies establish
only robustness/economic relevance under the registered generator. They do
not verify, prove, or change any Lean theorem.

No v2 library, value, loss, interaction sign, estimate, summary, report, or
figure existed when any of the three prospective locks was created. The v2
outcome rows above were generated only after the execution amendment froze.
The v1 artifacts remain the frozen pilot and are not pooled with the v2 run.

## Approximate library-compression artifacts

| Artifact ID | Path | SHA-256 | Producer and validation |
|---|---|---|---|
| `ALC-CORE-v1` | `julia/src/ApproximateCompression.jl` | `a600e485b4e2cca0bdee84ceee3702071c0a77cee797c8fbb205b8df9cdab1ac` | exact signed loss evaluator, complete subset/Pareto enumeration, deterministic greedy and beam searches, and solver-neutral operational-cover/lazy-cut formulation |
| `ALC-CODE-v1` | `julia/scripts/run_approximate_compression.jl` | `661ab3f08f001337ee03142cb46bd9e04c6edc8c17cd30d3e4ab55861d1e6973` | deterministic benchmark runner, exact CSV/JSON/report/SVG renderers, hard gates, and nonmutating `--check` |
| `ALC-TEST-v1` | `julia/test/test_approximate_compression.jl` | `be290fa2d332f2d4e4edde0b3a086a29372300dad546e645e990420e3477260c` | 119 definition, enumeration, Pareto, heuristic, 0--1, benchmark, serialization, figure, and artifact-drift checks |
| `ALC-CONFIG-v1` | `experiments/configs/approximate_compression.toml` | `6daaadfc8c64fd9d4434c664a19ab1d71d64bc8355c45d4086cd041a1df07103` | exact fixture identity, horizon, reference belief, signed budgets, enumeration cap, beam widths, and output contract |
| `ALC-REPORT-v1` | `APPROXIMATE_COMPRESSION_REPORT.md` | `354cc2cd2b3bd9f9c9d332407edd54f6c6166c5076223ea0e1aa2bb369c13f41` | answer-first technical report with definitions, methods, findings, validation, limitations, and explicit numerical-only boundary |
| `ALC-SUBSETS-v1` | `experiments/results/summaries/approximate_compression_subsets.csv` | `583cf212ff4ebb43d5e8c8af7d790212a822e798129f6ff2665adb0ad55ecf02` | all 160 exact source sublibraries with signed losses, budgets, Pareto flags, and decomposition gates |
| `ALC-PARETO-v1` | `experiments/results/summaries/approximate_compression_pareto.csv` | `27afd98f19cd61f2824170962c2e39b398a00400eba1921a3c32f2f7d5771926` | all 16 exact three-criterion nondominated rows |
| `ALC-ALGORITHMS-v1` | `experiments/results/summaries/approximate_compression_algorithms.csv` | `849618e37b6301a03c97d1bc14346fd256f36e6f1497b55fe60895a5642ceae0` | 20 exact and heuristic solutions with evaluated counts, pool-effort ratios, budget flags, and certificate status |
| `ALC-IP-v1` | `experiments/results/summaries/approximate_compression_ip.csv` | `8966f694c6dc7e8cb637ebe130211084ed5bb37f2ad602045194e311b72a35d1` | both operational-cover lower bounds, generative-cut counts, full optima, and external-dependency flag |
| `ALC-SUMMARY-v1` | `experiments/results/summaries/approximate_compression_summary.json` | `cbf582fe2f15a6452037ce362beeb481b241713c15032acc46b82c2a208a85aa` | exact source sizes, minima, losses, Pareto counts, config hash, all-gates result, and theorem-evidence boundary |
| `ALC-FIG-PARETO-v1` | `manuscript/figures/approximate_compression_pareto.svg` | `06d185a1bae03d3f1379997d6bf47d6982569f87a7b5d932612c57c4013e64b9` | exact size--operational--generative loss surface; XML-valid and full-canvas visually inspected |
| `ALC-FIG-SEARCH-v1` | `manuscript/figures/approximate_compression_search.svg` | `74e8dbc9dddfa6b5fce764b7c7bcf3506616a04f8a170750474e40d976ecc400` | exact-versus-heuristic cardinality and evaluation-effort comparison; XML-valid and full-canvas visually inspected |

The exact rational subset surface and complete enumeration certify only the
two registered finite optima. Incomplete beams and greedy rows have no
approximation guarantee. The generative 0--1 constraint is exact only when
the Bellman-oracle cut pool is complete. These are N6 numerical artifacts and
do not verify, prove, or change a Lean theorem.

## Exact theorem-feasibility artifacts

| Artifact ID | Path | SHA-256 | Producer and validation |
|---|---|---|---|
| `TF-CODE-v1` | `julia/scripts/search_counterexamples.jl` | `6c08ed76550a5175a510f9e0260edcc8d2dea73494700218f0879fb94af7b9ee` | reviewed Julia source; package tests pass |
| `TF-CONFIG-v1` | `experiments/configs/theorem_feasibility.toml` | `a84117135ef15086af78c90decc368f6ab6e3c2ffc0221eeb864f5405f56361c` | committed exact bounds and seed |
| `TF-RESULT-v1` | `experiments/results/theorem_feasibility.json` | `fbc62f52633b12a499bb64f7848d7bc425cdf5cfff330331ab520d5dc0a79a00` | generated twice byte-identically by `TF-CODE-v1` under Julia 1.12.6 |
| `TF-LEAN-DATA-v1` | `formal/StrategyInnovation/Fixtures/TheoremFeasibility.lean` | `98605b801c3ab149d380ace955fccd4528ce854d65bd06693979a578f6264b27` | generated by `TF-CODE-v1`; `lake env lean` succeeds |

The Lean fixture is data-only and has no manuscript-theorem declaration or
axiom claim. `expectedFacts` must later become typed propositions.

## Joint descendant-event falsification artifacts

| Artifact ID | Path | SHA-256 | Producer and validation |
|---|---|---|---|
| `JDB-CONFIG-v1` | `experiments/configs/joint_descendant_bound_gauntlet.toml` | `9110fdb62b04ee24f27a6022edc99dda41180805eb6e2e2d98358c8f85469e89` | committed exact enumeration bounds, rational grids, outcome labels, fixture registry, and output contract |
| `JDB-CODE-v1` | `julia/scripts/search_joint_descendant_bound.jl` | `58f486dca104eabc28eac2e0d8c4051424456aaa1ecf8a29f7c4d7549543ba15` | deterministic `Rational{BigInt}` enumerator, twelve computed minimal fixtures, result renderer, and nonmutating `--check` |
| `JDB-TEST-v1` | `julia/test/test_joint_descendant_bound.jl` | `d599975bc725f98fd72913a8ddb0f95b62d05ba56f1dc76df03d7f1b58e749a1` | 37 exact assertions covering all requested failure channels, corrected bounds, artifact drift, and fixture uniqueness |
| `JDB-COUNTEREXAMPLES-v1` | `experiments/results/summaries/joint_descendant_bound_counterexamples.csv` | `460597f7deb641c19067a276846e1b7c9cea58210a9901fa421cb66b55a366c8` | eight preserved minimal failures and four survivor fixtures, with exact actual, attacked, and revised rational values |
| `JDB-SUMMARY-v1` | `experiments/results/summaries/joint_descendant_bound_summary.json` | `dc64d55551dc175cfadfa44163055cdc92f65e21a056ee592127ef078707e243` | 21 normalized joint laws; 2,204,496 primary checks with zero failures; explicit failing and corrected attack-channel counts |

The JDB search is exact finite falsification evidence. It is the gate that
preceded the joint-law Lean theorem, but it does not itself prove that theorem.
The harmful-outcome, path-memory, and multiple-descendant extensions remain
specification/Julia results until separately encoded and audited in Lean.

## Unified semi-Markov falsification artifacts

| Artifact ID | Path | SHA-256 | Producer and validation |
|---|---|---|---|
| `RCG-CODE-v1` | `julia/scripts/search_revision_counterexamples.jl` | `3616e69dfa628722f39ece9df2ebeed8f7c11c0325c1793e6ed9fd1471b49769` | exact raw/compressed calendar oracle, T1--T7 search, unified S2 stationary policy evaluation, reduced comparative-static fixtures, and non-mutating result check |
| `RCG-CONFIG-v1` | `experiments/configs/revision_counterexample_gauntlet.toml` | `466d284b7af9f1fc2a65a92abb3a60df54b960918057451b7995858a97aa4e7e` | committed seed, finite bounds, durations, operation flags, discounts, stationary fixture, and output contract |
| `RCG-RESULT-v1` | `experiments/results/revision_counterexample_gauntlet.json` | `c90582f41a18751bdfa84d36712b91abb6c5b6e3feb35d1e3ed280099cc2fd6a` | 512 semi-Markov models, 512 T6 models, 512 T7 pairs, explicit correlated-law checks, exact zero-residual S2 selector fixture, complete reduced exact fixtures, and preserved exhaustive T3 counts under Julia 1.12.6 |
| `RCG-TEST-v1` | `julia/test/test_revision_counterexamples.jl` | `cdaae942effe303f7d84adb58264ecd0c40b58fbf99999cbe74df475239edea7` | 35 exact unified fixture assertions and eight deterministic smoke-gauntlet assertions |

These are falsification and regression artifacts only. They do not generate a
Lean module, change any existing Lean declaration, or establish T1--T7.

## Innovation-safe compression artifacts

| Artifact ID | Path | SHA-256 | Producer and validation |
|---|---|---|---|
| `CMP-CORE-v1` | `julia/src/Compression.jl` | `c77dc737a459120c9e30d5f3527906768614c1a347b387f0205c3427c4a6ab7c` | reviewed exact-first package source; 1,495 compression checks and Aqua pass |
| `CMP-CODE-v1` | `julia/scripts/run_compression_experiments.jl` | `9fb77fbc9a86ae5e4a9efac364fe0ca14a7ce498f9713e5422282f7efe35a2fa` | generates exact F3/F4 and deterministic Float64 scaling summaries under Julia 1.12.6 |
| `CMP-CONFIG-v1` | `experiments/configs/compression_experiments.toml` | `7c012a34742bb3773c5d6b72b111dda2c49fb94095b062192de71c07c0aed565` | committed seed, exact fixture, exhaustive-search cap, and scaling sizes |
| `CMP-RESULT-JSON-v1` | `experiments/results/summaries/compression_experiments.json` | `da20d0eb49ed152c346de655429f442619504aa458524f6e7b0ba4777523a1b9` | eight machine-readable rows generated by `CMP-CODE-v1`; runtime fields are host-dependent |
| `CMP-RESULT-CSV-v1` | `experiments/results/summaries/compression_experiments.csv` | `6c85229c11296bdd7e76d8da0e054e78ccd8e260663e42ab0a625ec380570075` | tabular encoding of the same eight rows; exact rationals remain canonical strings |
| `CMP-TEST-v1` | `julia/test/test_compression.jl` | `df5fbf0f5041429072c96eee4fc1886e9f4d4212ba78e12f141bf54896c69d97` | exact F3/F4 fixtures, batch boundary, exhaustive minima/formulation checks, 40 seeded properties, and output tests |

The exact rows are theorem-fixture validation, not Lean proof. The Float64
rows are synthetic scaling diagnostics, not theorem or empirical evidence. No
MILP solver was invoked; `CMP-CORE-v1` records formulation data only.

## Exact resource-optimization audit artifacts

| Artifact ID | Path | SHA-256 | Role |
|---|---|---|---|
| `RO-CORE-v1` | `julia/src/ResourceOptimization.jl` | `96f626435a6bb47447972ed6594353091c616935b7d665c7e12e4005653b4682` | standalone exact `Rational{BigInt}` finite-library burden, safety, capacity, penalty, breakpoint, and supporting-price algebra; isolation preserves the locked productive package entry point |
| `RO-SEARCH-v1` | `julia/scripts/search_resource_optimization_counterexamples.jl` | `a4291923677005de9f5bf8cce841270cb538fcce16c95330f86ce57f0eb4300d` | exhaustive minimized search and deterministic JSON renderer for all 14 proposed claims |
| `RO-TEST-v1` | `julia/test/test_resource_optimization.jl` | `c3a973e532a4a5ff746880da95e6ccb09d113faac7562bd2858d559d74d7f19a` | standalone exact primitive, witness-property, survivor, and artifact-drift checks |
| `RO-CONFIG-v1` | `experiments/configs/resource_optimization_counterexamples.toml` | `197d39550971181e11a421547bcfc4de393541b4819a101cd2c5833247bd6476` | versioned search bounds, arithmetic declaration, and output paths |
| `RO-AUDIT-v1` | `experiments/results/resource_optimization_claim_audit.json` | `9eb6008891991c67a955fffcc1c37d8fc3e886a4cb25ad1a791621458f3f0f5f` | Julia 1.12.6 record of 13 exact counterexamples, one surviving claim, search counts, theorem revisions, and per-fixture SHA-256 manifest |
| `BEM-SPEC-v1` | `BRIDGE_ELASTICITY_SPEC.md` | `5253b0313c0e07f395291f46bf0443a234717a5483d5663139a20f3a11bda7ad` | complete human algebra plus Lean-verified named-coordinate derivatives, elasticities, corrected normalized-margin and fixed-threshold divergence, boundary, and exact example; no reusable Julia implementation |

`RO-AUDIT-v1` links 14 committed per-target fixtures under
`experiments/results/resource_optimization_fixtures/` and records the hash of
each. The audit is exact Julia evidence, not Lean proof or an empirical
experiment.

## Exact safe-compression complexity artifacts

| Artifact ID | Path | SHA-256 | Role |
|---|---|---|---|
| `SCX-CORE-v1` | `julia/src/SafeCompressionComplexity.jl` | `474a227fe9e8d7ed960a86e45d8cfbb1c0f27c7d85a8b11a06226e93e7d769c9` | polynomial-size exact decision-instance and weight-preserving closure-only, frontier-only, and combined constructors |
| `SCX-CODE-v1` | `julia/scripts/verify_safe_compression_complexity_reductions.jl` | `81cd3a814f0c3e495bdfe62b9eb5da727798216d33592a5e74ae29d299dc168a` | deterministic exact correspondence renderer for the registered weighted-set-cover fixture |
| `SCX-TEST-v1` | `julia/test/test_safe_compression_complexity.jl` | `5bacfdca5bc7204ce6448ac531e68f1db310239141ed57612b89044c00c677f9` | fixture-mask, exhaustive small-incidence, optimizer, and artifact-drift checks |
| `SCX-FIXTURE-v1` | `experiments/results/safe_compression_complexity_reduction_fixture.json` | `e9b9dd98c7ebad8f3dc7e1b7a1daefcd5df46f44f83d0aaba4a9bda77085b050` | exact closure-only, frontier-only, and combined feasibility/weight/optimizer correspondence record |

The constructors are polynomial in their explicitly listed incidence input.
Exhaustive optimizer enumeration is used only to validate small fixtures. The
artifact is not a universal proof; SC-COMP has no Lean declaration or axiom
audit.

## Finite discounted dynamic-program artifacts

| Artifact ID | Path | SHA-256 | Producer and validation |
|---|---|---|---|
| `DP-CORE-v1` | `julia/src/DynamicProgramming.jl` | `a3203810d833a53ddfa02496fcdbab988333fc813ebdf0f696801a8d71a15925` | exact dense and explicit Float64 sparse F5/F8 compatibility process, Bellman, value-iteration, residual/bound, DI, and exact policy solvers; package tests and Aqua pass |
| `DP-CODE-v1` | `julia/scripts/solve_canonical_model.jl` | `af079f24aa6362654a8f6bea189bba6868c216994b0f04dc9283c9adcfc6c191` | deprecated primitive F5/F8 exact/Float64 regression solver and exact arbitrary-loss fixture under Julia 1.12.6 |
| `DP-TEST-v1` | `julia/test/test_dynamic_programming.jl` | `c6e2e61cbd0d9026aad82b94474335a7defbc572c08ae999a0a512cbd0b62bb4` | 226 validation, exact fixture, edge, contraction, equivalence, seeded property, and output checks |
| `DP-CONFIG-v1` | `experiments/configs/canonical_discounted_dp.toml` | `750c43a04d98478aa4260f808fce7a7ee8f073077c088f70f55123b3a754de7f` | unchanged legacy state counts, primitive timing, exact horizon, Float64 tolerance, and iteration cap; no randomness |
| `DP-RESULT-JSON-v1` | `experiments/results/summaries/canonical_model_summary.json` | `7c87a3ac4f93e51fa6bcfd538b4f2b3134305f6b682575b35edd3774253e6561` | unchanged legacy exact horizon/policy and sparse Float64 convergence summary; runtime fields are host-dependent |
| `DP-RESULT-CONVERGENCE-v1` | `experiments/results/summaries/canonical_model_convergence.csv` | `7219dd39aff5d7efcce7052a25fb12f6cf2d6d5effe561bbcc4e32377f24d874` | 86 deterministic iteration rows with increments, residuals, and both error bounds |
| `DP-RESULT-POLICY-v1` | `experiments/results/summaries/canonical_model_policy.csv` | `417b6ffe2dffb553ff36f9a3267200a8c719f2b5b4ac00d2964af9ecd23cbcd4` | exact and Float64 action/value rows for all six joint states |

The exact rows are computational counterparts of primitive F5/F8 and do not
replace Lean verification. They are a legacy timing cross-check; the unified
S2 selector and policy-evaluation theorem has a separate same-timing exact
fixture. Float64 rows are numerical diagnostics only.

## Unified positive-duration canonical benchmark artifacts

| Artifact ID | Path | SHA-256 | Producer and validation |
|---|---|---|---|
| `UB-SPEC-v1` | `UNIFIED_CANONICAL_BENCHMARK_SPEC.md` | `416a4deb43a0f4daff803ff8247c4d2b49d4f0b1c87e1bedc355f38996c4593c` | internally checked structural reference specification retained as the D-0084 regression calibration |
| `UB-CODE-v1` | `julia/scripts/search_unified_benchmark.jl` | `ee3040db45439ce2db0f7c85d488439ba58c6db0838557760dd21e038ebe3951` | exact 972-candidate raw-law search, rational PI/VI diagnostics, perturbation and comparative-static gates, deterministic artifact renderers, and nonmutating `--check` |
| `UB-TEST-v1` | `julia/test/test_unified_benchmark_search.jl` | `e848fd15c30373cefe8dcb787099a35361972baaaa19d0223b524d09797592e5` | frozen-reference regression, selected exact policy/value/margin, full-path, raw-lift, perturbation, comparative-static, and deep solver checks |
| `UB-SEARCH-CONFIG-v1` | `experiments/configs/unified_benchmark_search.toml` | `6319fd7ac57d0dfdc8a1978696601c95542b84ab09eda0b6a4086a7867059531` | exact rational grids, fixed raw-law structure, solver/margin gates, perturbations, comparative-static contrasts, ranking rule, and output contract |
| `UB-SELECTED-CONFIG-v1` | `experiments/configs/unified_benchmark_selected.toml` | `f05dc4ba1ec7590cde8996a1fdfbf4371cd47bb4a69a308f33c5d2357a34f184` | generated C0424 primitives, state counts, policy signature, action gaps, exact residuals, raw/compressed equality, and policy-lift certificates |
| `UB-SEARCH-v1` | `experiments/results/unified_benchmark_search.csv` | `84209d4d6eba5a958a405993a87335946f70218a1d06e1ac6b14a545481cdac7` | all 972 candidates with primitives, effective success, exact policy, margins, residuals, selection status, and alternative-candidate rejection reasons |
| `UB-REPORT-v1` | `experiments/results/UNIFIED_BENCHMARK_ACTION_MARGIN_REPORT.md` | `4cb9b97afe2e680c45d8cfb6967b71100d1a145c9ef7dc925bb3fb8979a8bf36` | answer-first exact action-margin, structural, PI/VI, raw-lift, perturbation, comparative-static, and rejection report |
| `UB-POLICY-v1` | `experiments/results/unified_benchmark_policy_value.csv` | `a4fb291ba4b010a9c8234710a0a22191e9accfd5006341678e34ad87042c5962` | all six selected compressed states with exact values, action Q values, reward blocks, continuation blocks, and gaps |
| `UB-REJECTIONS-v1` | `experiments/results/unified_benchmark_rejections.csv` | `dbdc59d7e660ddd982262a13c6cb515eb0c634e4f21629e8359ab62bd6869ff5` | aggregate exact-search rejection accounting, including dominated eligible alternatives |
| `UB-STABILITY-v1` | `experiments/results/unified_benchmark_perturbation_stability.csv` | `018b58be53241e4822fde481ea819fd296b34fd1486d2b7b6d5ed84f9c09e238` | all 11 feasible local rational perturbations with unchanged policy signatures and exact minimum margins |
| `UB-COMPARATIVES-v1` | `experiments/results/unified_benchmark_comparative_statics.csv` | `cd1a81f6362b07b096e7458e4b860210c7ed0a2c915f5868ec3abfc2092c5c26` | exact low/high cost, duration, discount, admission, and survival comparisons with K1 values, margins, and policies |
| `UB-CANONICAL-CODE-v1` | `julia/scripts/solve_unified_canonical_benchmark.jl` | `2359e1c97148648e4ddf58361c58af420fb4e452c1ff9c59b8ae074244c3836e` | raw-derived exact finite-horizon and policy-iteration solver, Float64 value iteration and a-posteriori contraction bound, exact rational reevaluation certificate, exact/Float stationary evaluation, equality audit, deterministic renderers, and nonmutating `--check` |
| `UB-CANONICAL-TEST-v1` | `julia/test/test_unified_canonical_benchmark.jl` | `dafb142ede6289518079e06634546e345b07aaaba4a2b613353a6ceeae860896` | 201 raw-structure, exact/Float solver, full-duration path, operating-block, transition, residual-bound, action-gap, and validation assertions, plus resource-extension test wiring |
| `UB-CANONICAL-CONFIG-v1` | `experiments/configs/unified_canonical_benchmark.toml` | `8674f9136ce0b7a245de6665e46a8c9b3bc13e3472d2080af5089108a6d2e1c8` | selected C0424 pointer, exact horizon and solver limits, five comparative-static fixtures, output contract, and explicit legacy regression pointer |
| `UB-CANONICAL-SUMMARY-v1` | `experiments/results/summaries/unified_canonical_summary.json` | `84d0498b6a1f71c1752b7a51c4c55a9fad918d2011b88a55550e33ae9dd5f1d6` | exact zero residuals and action gap, 42-iteration Float64 convergence and a-posteriori contraction bound, exactly re-evaluated residual-based certificate for the rationalized Float64 iterate, equality-audit counts, and legacy exclusion flag |
| `UB-CANONICAL-VALUES-v1` | `experiments/results/summaries/unified_canonical_values.csv` | `a4baff6bf860365a9b6df4a2ea97ef2ddcdac634982fb92d6463e80ee8280b54` | exact horizons zero through eight plus exact policy-iteration, exact policy-evaluation, Float64 value-iteration, and Float64 policy-evaluation stationary tables |
| `UB-CANONICAL-POLICIES-v1` | `experiments/results/summaries/unified_canonical_policies.csv` | `3d32879cd592ba2f6bee6558c0b9d8c1f05b30b75dbd63b8b659098cd6572864` | exact horizons one through eight plus identical exact and Float64 stationary action maps |
| `UB-CANONICAL-TRANSITIONS-v1` | `experiments/results/summaries/unified_canonical_transition_edges.csv` | `7cf1ca735b69f47053b84485e17f51583ad822217309169e2a4708f5e49d6734` | eight programmatically derived compressed Continue, Discover, and Scale edges with exact masses and positive durations |
| `UB-CANONICAL-PATHS-v1` | `experiments/results/summaries/unified_canonical_duration_paths.csv` | `9ae807813f02501f5b27f09b1cd98fe2d8b0328137c55c15ab114697524e016c` | all 36 positive-mass full belief-path/admitted-outcome atoms, their Markov path masses, and conditional admission masses |
| `UB-CANONICAL-REWARDS-v1` | `experiments/results/summaries/unified_canonical_operating_rewards.csv` | `c4fba22256f13234c5ee3babe3049204f073138cd310d6241c068aace847c855` | all 12 Continue/research operating blocks, initiation costs, unified operating flags, and exact net reward blocks |
| `UB-CANONICAL-CONVERGENCE-v1` | `experiments/results/summaries/unified_canonical_convergence.csv` | `3ccc56f2f445ef9ea2497eca1b777eb2587ad8460275bd7b44accfd01fd92db1` | all 42 Float64 iterations with explicitly labeled increments, Bellman residuals, and a-priori and a-posteriori contraction bounds; the exact reevaluation certificate is stored only in the summary artifact |
| `UB-CANONICAL-COMPARATIVES-v1` | `experiments/results/summaries/unified_canonical_comparative_statics.csv` | `aa0d190b9894e75293be65bad9b00a7bc4383d38adbae05dca17f7789bdbc4b4` | exact low/high cost, duration, discount, admission, and survival fixtures regenerated through the raw source of truth |
| `UB-RESOURCE-CODE-v1` | `julia/scripts/run_unified_resource_benchmark.jl` | `6a03eb7690dd5f5366808564585568d6d5660b2214ee35bdecd847b35a20606b` | exact C0424 resource evaluator, exhaustive optimizer certificates, analytic fixed-policy discount derivatives, deterministic exact-table/SVG renderer, and nonmutating `--check` |
| `UB-RESOURCE-TEST-v1` | `julia/test/test_unified_resource_benchmark.jl` | `005116c399899fb9cba05137fba8b64cbecb8bc8a845a8ff8e0a1c91c270817f` | 385 preregistration, channel, exhaustive safe/capacity/penalty, monotonicity, breakpoint, and artifact assertions |
| `UB-RESOURCE-CONFIG-v1` | `experiments/configs/unified_canonical_resources.toml` | `9a3899ae1baeecb023f4689b47db84a853e3c9ccc6f5fc7f281b1672162c17a1` | D-0131 preregistered equal-active, carrier-heavy, and descendant-heavy exact active weights, common display addend, and twelve-output contract |
| `UB-RESOURCE-SUMMARY-v1` | `experiments/results/summaries/unified_canonical_resource_summary.json` | `ec66b1d64617813a224debc223eedad9a609eb6fad81c31392ac04c7c845d93d` | schedule and artifact counts plus aggregate exact safety, tie, channel, duration, and monotonicity certificates |
| `UB-RESOURCE-LIBRARIES-v1` | `experiments/results/summaries/unified_canonical_resource_libraries.csv` | `2d0affc8f10fb7bae0c70088fdc1e42eeef7449900ff16d2dec22efb91f08caf` | all schedule/belief/raw-library display burdens, productive/display-net and channel values, duration, actions, margins, frontiers, and closures |
| `UB-RESOURCE-SAFE-v1` | `experiments/results/summaries/unified_canonical_resource_safe_compression.csv` | `03efd35881ac2c19e221ce3de6e4e349e90b6973b8c4f81edd1b266b8a9c6f32` | every raw source, complete exact-safe set and minimum-weight tie set, burden reduction, productive values, and enumeration certificates |
| `UB-RESOURCE-CAPACITY-v1` | `experiments/results/summaries/unified_canonical_resource_capacity.csv` | `79eed7b19cb99eef994ee78fb78408e73712e5185b6efac1fb1da8dc341b0ca9` | every attainable display capacity, complete optimizer correspondence, channel values, forward shadows, exact arc elasticities, and certificates |
| `UB-RESOURCE-PENALTY-v1` | `experiments/results/summaries/unified_canonical_resource_penalized_intervals.csv` | `18133e7bb0087d0e24b31c5eedfbeeb98201cc3aa614a4317492b3de63436db0` | every actual price breakpoint and intervening interval with complete ties, display-burden selection, translated penalized values, channel values, and library/action distances |
| `UB-RESOURCE-SWITCH-v1` | `experiments/results/summaries/unified_canonical_resource_switching_prices.csv` | `f6a32883cc8da556c2e1d2dca45c1a8e4a1bed0ecfd9fce28117f995d9b70918` | all 168 unordered library pairs classified as coincident, parallel, inactive candidate, or globally active intersection |
| `UB-RESOURCE-CHANNEL-v1` | `experiments/results/summaries/unified_canonical_resource_channel_elasticities.csv` | `7e36ff4a355731c7ea2d26bd838a7f2d6e609505326358b60156ce4310c44265` | exact productive/passive/generative levels, derivatives, scaled sensitivities, innovation duration, elasticities, contributions, and action gaps |
| `UB-RESOURCE-CHANNEL-TEX-v1` | `manuscript/tables/unified_canonical_resource_channel_elasticities.tex` | `bc419c4a344ae2d5c6a2991e169939886ddf8ea42a08a1bc07b72e0de15861c9` | exact six-row compressed-state/belief channel-duration lookup generated from the full channel CSV |
| `UB-RESOURCE-FIG-CAP-v1` | `manuscript/figures/unified_canonical_resource_value_capacity.svg` | `ef820f74a5e32f77534f669cf27e74ee4cf7689244c61953ad74d4159011334e` | frozen renderer output: its labels `capacity` and `B` mean display capacity including the common unit; exact-source tooltips and preregistered schedule styles |
| `UB-RESOURCE-FIG-PRICE-v1` | `manuscript/figures/unified_canonical_resource_value_price.svg` | `2f182595fb1cc8a3b827575f84ded2187418c8bc44294db639b091c40e49f5d0` | frozen renderer output: its `W` and `J` labels mean display burden and translated penalized value; sampled only for secondary display from exact affine branches |
| `UB-RESOURCE-FIG-PATH-v1` | `manuscript/figures/unified_canonical_resource_library_path.svg` | `a1b1dfca54cc693274eaabf8bd94f4c6a83ff7da75901070138a7c962c25ea62` | frozen renderer output: its capacity labels mean display capacity; declared minimum-burden/lowest-mask display selection |
| `UB-RESOURCE-FIG-SWITCH-v1` | `manuscript/figures/unified_canonical_resource_switching.svg` | `1efc32203bb6787b5ede4e825536af3a77ff1a52b4d46554b7e724162e133f9e` | visually inspected exact active-switch diagram with complete candidate intersections retained in the source CSV |

These artifacts implement the unified raw candidate-generation,
verification/admission, full belief-path completion, deterministic update, and
positive-duration operating law. They are exact finite-instance validation,
not Lean proof or universal comparative-static evidence. `DP-*` remains the
unchanged obsolete-timing appendix compatibility fixture, and the D-0084
reference calibration remains checked separately from selected C0424.

## Manuscript numerical-presentation artifacts

| Artifact ID | Path | SHA-256 | Producer and validation |
|---|---|---|---|
| `MN-CODE-v4` | `julia/scripts/generate_manuscript_numerical_artifacts.jl` | `1d6a0288735584a04a5e3a93cb8e10abc778e41be52992768c66d08ce1535fcb` | dependency-light Julia renderer; uses all 42 unified convergence rows with discrete markers, validates every selected committed source row, derives the aggregate-only compression audit and ex post estimand metadata, renders the natural-size three-panel financial safety--compression figure and information-timing rows, and supports nonmutating `--check` |
| `MN-FIG-CONV-v1` | `manuscript/figures/canonical_convergence.tex` | `87e68d5443da91e04f2cfe8822d3ee4d10c45f577685c4b39194c3cc0a5adaaf` | unchanged historical 86-row primitive F5/F8 convergence plot retained only for appendix compatibility |
| `MN-FIG-UNIFIED-TRANSITION-v1` | `manuscript/figures/unified_canonical_transition.tex` | `cbabe6b670f089eeb7aed6267abde4e8d3ce4bab578b027d304bc25147c076f8` | generated raw-derived $K_0$-$K_1$-$K_2$ Continue, Discover, and Scale transition diagram used by the main manuscript |
| `MN-FIG-UNIFIED-CONV-v1` | `manuscript/figures/unified_canonical_convergence.tex` | `5e2b0a349b34d99eb0c574aa3a74aae1305365ff477e81957fe8d0086042aa5f` | TikZ convergence plot generated from all 42 `UB-CANONICAL-CONVERGENCE-v1` rows, explicitly labeling the dotted series as the Float64 a-posteriori contraction bound, with a marker at every integer iteration, joined segments used only as visual guides, and a collision-free inset legend; used by Appendix D |
| `MN-TABLE-SYNTH-v1` | `manuscript/tables/numerical_mechanism_summary.tex` | `61a85ebb33fe920d8430de1c8a80af0cc1c37113ad6c7eba82a265f38663d7b1` | exact safe-compression, scaled-loss, decomposition, and single-/multi-gap lookup generated from registered summaries after identity checks |
| `MN-FIG-FIN-COMP-v2` | `manuscript/figures/financial_innovation_safe_compression.tex` | `0d4c929f91e8c5c7230cfb09ed26663274ef91193450a5793f417ed6fc85c35f` | primary three-panel safety--compression audit: exact strategy and module retention fractions plus separately scaled ex post enabled-descendant opportunity-quality changes; natural-size `\scriptsize` body text, no enclosing resize, no outcome-prediction interpretation, and no pooled quality magnitude |
| `MN-FIG-FIN-v2` | `manuscript/figures/financial_coverage_comparison.tex` | `5bb05e80ab93ee77423d1c03b6aa2d925a262447e107feadca8256fb40357faa` | secondary separate-axis locked-terminal/annual uncertainty plot generated from the unchanged committed financial uncertainty tables; markers and zero lines visually inspected |
| `MN-TABLE-FIN-v2` | `manuscript/tables/financial_design_summary.tex` | `c888dd869a630cd34618aa3c326728f989f67c947ef7a261e9583a20318084e0` | financial design, pruning, decomposition, and coverage audit; separates pruning information, post-compression ranking information, held-out outcomes, retrospective policy summaries, and oracle regret |
| `FI-COMP-POLICY-v1` | `experiments/results/summaries/financial_compression_policy_characteristics.csv` | `2886473f435527ebd0a82f5bdc8cfeccd5aa3f4b1510893530a9ac859187e86d` | 125 retained-policy rows with operational/generative contributions, module uniqueness, candidate dependence, and best-descendant support; `theorem_evidence=false` |
| `FI-COMP-PRED-v1` | `experiments/results/summaries/financial_compression_predictor_summary.csv` | `97cc8a4f469cf98389fdc21ac00781aced86608829d48895ed56cb4ba4a8bd07` | 14 grouped descriptive rows; explicitly marks constant module uniqueness as unidentified and all rows as non-theorem evidence |
| `FI-COMP-ESTIMAND-META-v1` | `experiments/results/summaries/financial_compression_estimand_metadata.csv` | `4f339f3f51eb70d2a77196501490d597a1150a2a921e7b732e726d5f08c8351b` | two-row audit metadata naming $Q_a$ as ex post enabled-descendant opportunity quality; records held-out timing, `algorithm_input=false`, nonforecast/nondeployment status, diagnostic purpose, both pruning acceptance tests, and `theorem_evidence=false` |
| `EMP-INFOSET-AUDIT-v1` | `EMPIRICAL_INFORMATION_SET_AUDIT.md` | `9e139fc59bc06ff9ed94a5aa3f970affc0dc15931c81f3d03fabfbb2b8c7aee4` | object-by-object classification of pruning-time, validation/pre-target, held-out, retrospective descriptive, and oracle quantities; records actual algorithm use, both decision-hash boundaries, and the inactive status of legacy locked prose |
| `MN-TEST-FIN-COMP-v1` | `julia/test/test_financial_compression_focus.jl` | `70fc1bb5c4e8800df100d40eb439f44db5df5b84a12c8901fc4e9a8f6d5d57b6` | focused checks for locked sizes and losses, exact frontier/closure/descendant identities, all four policy roles, unique positive-carrier traits, separate audit units, identification flags, exact information-set classifications, the three current panel titles and exact count labels, absence of obsolete six-panel titles or font-reducing wrappers, and generated-artifact drift |
| `FIG-AUDIT-CODE-v1` | `julia/scripts/generate_figure_audit_artifacts.jl` | `5fae4214784d48e6422f762b389da957a1b1827427eb0c3796d446820b088604` | exact-source Julia renderer for the bridge and combined economic geometry; labels the canonical common-unit translation explicitly, validates fixture identities, optimizer completeness, and tie completeness, and supports nonmutating `--check` |
| `FIG-AUDIT-BRIDGE-DATA-v1` | `experiments/results/summaries/innovation_safe_bridge.csv` | `b7b2549db0f3ef399d9a86e43f19d48c96ba94ea49e554875fd415e1d34e6d50` | five exact strategy/module/project/descendant rows used by the main bridge-mechanism figure |
| `FIG-AUDIT-BRIDGE-v1` | `manuscript/figures/innovation_safe_bridge.tex` | `54de1ee03fdfc17fbadc8177d4b541a0c6b1e756bbb28b95f1ba74fa2e85d036` | main-text exact bridge-mechanism TikZ figure; coordinates are presentation-only and the diagram asserts no additional path |
| `FIG-AUDIT-GEOMETRY-v1` | `manuscript/figures/unified_economic_geometry.tex` | `064408990db6a515ed7124a2b8c52b1874c625cf7d2bbec4fb3a4b88e2c1fe3a` | six-facet main-text economic geometry generated from exact capacity and penalized-path rows; labels $\widetilde B$, $\widetilde J$, and $\widetilde W$, and uses right-continuous stairs, exact affine branches, and open/filled exact tie endpoints |
| `TABLE-AUDIT-CODE-v1` | `julia/scripts/generate_main_text_tables.jl` | `5d56c3fb19a6810dcfd484b181040368bb1ea19eefa8cd94eb2124e05168afb4` | exact-source Julia renderer and nonmutating drift gate for every retained main-text table plus the two compact canonical correspondence artifacts |
| `TABLE-MAIN-GREEDY-v1` | `manuscript/tables/main_greedy_global_comparison.tex` | `d0a25ace263c4cfc46c1c6690b484bf1156bf31f39b7f873dc402f2754272b38` | complete exact three-row local-versus-global safe-compression witness |
| `TABLE-MAIN-STATIONARY-v1` | `manuscript/tables/main_canonical_stationary_solution.tex` | `a7d4074c9229c175f969f80293f398db924357f8d65a3bc3b7a74c55f74d2b0b` | complete exact six-state productive value, selected action, and winning-margin table |
| `TABLE-MAIN-RANDOMIZED-v1` | `manuscript/tables/main_randomized_optimization_summary.tex` | `e17cc3c48196a95190b53bdebf58b5405d2fe3f4bfb2dbf76ee3c5387f8ee89d` | condensed six-row registered optimization summary with exact fractions/counts, safe-compression reduction shares correctly labeled as removed shares, and explicitly approximate rendered means |
| `TABLE-MAIN-PRICE-v1` | `manuscript/tables/main_randomized_price_elasticities.tex` | `ea9d9259c5109b36457d0dbbdda08e2cea368f982ffe592bddf26f52bc9d1a0d` | four complete registered price arcs with explicitly approximate rendered means, negative demand/value responses, and mixed generative contributions retained |
| `TABLE-MAIN-FINANCIAL-v1` | `manuscript/tables/main_financial_resource_compression.tex` | `77a67eeb9df5cf741ac7b235f4c251270e64e1715e5caa71cad07c7f8391cde7` | two-audit comparison with HiGHS-qualified minimum-cardinality and minimum-resource candidates and exact post-solve quantities |
| `TABLE-APP-SAFE-v1` | `manuscript/tables/appendix_canonical_safe_compression.tex` | `0620ab672dc1f33bb932087ae264949ae00939244d2afc58f4317ffa436487e6` | compact exact canonical safe-compression correspondence; absolute reductions identify $\Delta\widetilde W=\Delta W$ |
| `TABLE-APP-RESOURCE-v1` | `manuscript/tables/appendix_canonical_resource_summary.tex` | `ddae6c8ba6517ed4d3dcd42962e261a1e170b891015cae9ea00bf9961c161e14` | compact exact canonical display-capacity paths, optimizer ties, and unchanged active switch prices |

The renderer consumes immutable registered summaries and never reads licensed
raw rows. Its tables, figures, and estimand metadata are presentation
artifacts, not additional experiments or proof evidence. The $Q_a$ metadata
does not alter either locked scoring engine, pruning decision, decision hash,
or numerical column. The companion information-set audit likewise changes no
runner or result. Section 9 occupies four compiled pages and Section 10
occupies two full pages plus its partial opening on the preceding shared page;
every displayed page was checked in the final PDF.

## Operational and generative strategy-value artifacts

| Artifact ID | Path | SHA-256 | Producer and validation |
|---|---|---|---|
| `SVE-CORE-v1` | `julia/src/InnovationValue.jl` | `61178d46cc66ed0ee1dcd2f2b1969509d6f3810c4d4340a98001de607d6308d9` | exact finite F6/F7 passive/full values, insertion decomposition, gaps, gap sums, discounted occupancy, and T7 frontier--closure interaction surface; package and Aqua checks pass |
| `SVE-CODE-v1` | `julia/scripts/generate_strategy_value_figure.jl` | `91e8ede222682d752c130851f2cc71dae842fda59d928ebc6454e16b92462bda` | exact-rational CSV/TikZ producer with semantic validation and non-mutating `--check` |
| `SVE-TEST-v1` | `julia/test/test_innovation_value.jl` | `677845e6cb2b83ce8143af82c960117aec245d033247005f8b720037c394b366` | 22 exact decomposition, generative-only, delayed-gap, occupancy, diminishing-return, and figure-contract checks |
| `SVE-CONFIG-v1` | `experiments/configs/strategy_value_figure.toml` | `6920f98312daeac97154f3bfd5ed28cb0712aa60fb143fa7757959dfd7b1b36b` | committed five-belief frontier, candidate, transition kernel, horizon, discount, labels, and output contract; no randomness |
| `SVE-DATA-v1` | `experiments/results/summaries/strategy_value_equation_figure.csv` | `dc143dc05f93986eb5a7141bdc2c4c622a823d984398ff727a2d3db3ea63fd5f` | exact frontier, candidate, positive gap, and discounted occupancy data; operational value is `3891/2048` by three independent package paths |
| `SVE-FIG-v1` | `manuscript/figures/strategy_innovation_equation.tex` | `491a6ab82f781e4174ba163f95a1b18ae0504ff8651eecbf75cf635fa0a83827` | dependency-free TikZ figure generated from the committed exact data and visually inspected in the manuscript PDF |

These artifacts computationally mirror the verified F6/F7 finite definitions
and exact examples. The figure is an exact finite illustration, not a new
theorem, an infinite-horizon result, or an implementation of T5's unified raw
process. T5's proof artifact is the Lean module listed below.

## Frontier--closure interaction artifacts

| Artifact ID | Path | SHA-256 | Producer and validation |
|---|---|---|---|
| `SYSINT-CODE-v2` | `julia/scripts/run_system_interaction_surface.jl` | `f3ee1a4ff0212b76c2a7a2ae09c2e9cb7aecf538821929935d6ce4d0a886c749` | dependency-light exact-rational legacy grid, five-fixture, and realizability-gated response producer with nonmutating `--check` |
| `SYSINT-TEST-v2` | `julia/test/test_system_interaction.jl` | `e79d37d88f42f0e43d88748689627ffb6dca76f2f3761a6ac179a108251ac905` | 80 exact definitions, fixture, response-axis, realizability, primitive-boundary, drift, and output-contract checks |
| `SYSINT-CONFIG-v2` | `experiments/configs/system_interaction_surface.toml` | `57a36b67307310ed99750c008a838f447a44adb5b9170a4e4b5b3ac0c624bc6c` | committed legacy grid plus frontier, closure-richness, cost, admission, descendant, incumbent-reward, duration, and generator-dependence response axes |
| `SYSINT-SURFACE-v1` | `experiments/results/summaries/system_interaction_surface.csv` | `7cc72e1796b082bd27e678c18c054b200957583ac91d78c6cd831bcb89f72012` | 2,430 exact constructed-realizable rows: 553 substitutes, 1,865 separable cases, and 12 complements |
| `SYSINT-FIXTURES-v2` | `experiments/results/summaries/system_interaction_exact_fixtures.csv` | `ef0c0631d18bd6e091a3fc21aabb5caaa3c7b630e2716a542405ccd0c88a27f6` | five exact canonical sign fixtures with four corner policies, realizability, and primitive-condition certificates |
| `SYSINT-RESPONSE-v2` | `experiments/results/summaries/system_interaction_response_surface.csv` | `9459d513fa65c1e8bd16818946c4f0d2dffc8836029abd134e4233426d322c82` | 3,456 exact response rows; 576 four-corner-realizable rows enter sign counts and 2,880 diagnostic rows are excluded |
| `SYSINT-SUMMARY-v2` | `experiments/results/summaries/system_interaction_summary.json` | `5c4e1be6b789a3647d7b6f12f278402d78a25ce706c82dd776ad7570ac8243db` | five exact witnesses, explicit realizability/aggregation rule, 156/237/183 eligible substitute/separable/complement counts, and 16 passing producer checks |
| `RRECT-CORE-v1` | `julia/src/RealizableRectangles.jl` | `5831c8a0b53e08cb201f1d1be5812f4fae609287e49135afa13c5ddaf723d037` | reusable raw-only rectangle carrier, commuting additions, derived states/menus/transitions/values, and two exact deterministic generators |
| `RRECT-TEST-v1` | `julia/test/test_realizable_rectangles.jl` | `88d3a607636693f93045c8c8444c9f2408ffa3f64e8f1497278470875330bc70` | 63 exact shared-catalog, plural-addition, raw-edge, nontrivial-closure, derived-law, transition-pushforward, and value-policy checks |
| `PRIMSUB-CODE-v1` | `julia/scripts/search_primitive_substitution.jl` | `80d1f551a0cac3d9bc5fed9cc0772712e3ccb5b200247df739a8f35b5647b7d2` | exact common-gap counterexample search and nonmutating `--check` producer |
| `PRIMSUB-TEST-v1` | `julia/test/test_primitive_substitution.jl` | `34badb66e3fbcb8de3f77d6061e035325d3e804cc801c4bc557c7b894d3735ed` | 38 exact search, theorem-boundary, optimizer-switch, render, and artifact-drift checks |
| `PRIMSUB-CONFIG-v1` | `experiments/configs/primitive_substitution_search.toml` | `dfcb43f055b1a44937122c643cdbab49bd80ecdfb94f96e1be24db9aa1132e77` | committed exact frontier, candidate, success, cost, discount, witness, and output contract |
| `PRIMSUB-SURFACE-v1` | `experiments/results/summaries/primitive_substitution_search.csv` | `6fd7262e56c56e64748857111650c6a1c37bf1c55b993578f4126560dd24820f` | 2,430 exact rows: 648 broad exposure-order failures and zero failures in 810 zero-poor-exposure rows |
| `PRIMSUB-SUMMARY-v1` | `experiments/results/summaries/primitive_substitution_summary.json` | `aedd4d3463c6c7f03b6fa22f0b754dc20db74f78f754109076566ff109a8f118` | exact counts, strict-substitution witness, Continue-pair counterexample, preserved optimizer switch, and passing validation flags |

The interaction and primitive-search surfaces map a one-period finite
opportunity-menu family, search the common-gap subclass, and validate the exact
Lean examples. They do not prove the T7 relative-saturation theorem or its
primitive sufficient condition; the Lean module below supplies those proofs.
Complement cells in the frontier-independent grid expose project switching,
and the Continue-pair search exposes why positive poor exposure defeats the
broader proposal. Expanded response signs are aggregated only when all four
constructed compressed corners are realizable. The RRECT layer supplies two
separate raw-process realizability witnesses and a reusable constructor; it
does not change the registered SYSINT surfaces or their sign counts.

## Coverage-potential geometry artifacts

| Artifact ID | Path | SHA-256 | Producer and validation |
|---|---|---|---|
| `COV-CORE-v1` | `julia/src/Coverage.jl` | `23186cfcedf3ef6501cdf2991a1c8c71f21f5419b9a95776880eb7065944e19a` | exact/Float64 occupation, gap, potential, finite discount--survival interaction, S7 persistence response surface, one-shot cost-covering, topology, boundary, and sensitivity API; package and Aqua checks pass |
| `COV-CODE-v1` | `julia/scripts/run_coverage_geometry.jl` | `c0b56b74ab53cb2003af35374e2a0b2bea374fbf4d25b2622169fc2344e775a7` | deterministic exact-fixture/Float64 geometry and dependency-free SVG producer |
| `COV-TEST-v1` | `julia/test/test_coverage.jl` | `8787aaefcaa2550cef0acebbd175a485d923998a940bc9b85da84e53b734b1bd` | 266 solve, finite interaction, Lean-fixture, cutoff-comparative-static, assumption-boundary, topology, refinement, seeded-property, sensitivity, and output checks |
| `COV-CONFIG-v1` | `experiments/configs/coverage_geometry.toml` | `e0487615c03ffdb3aa1cd1947003952ccfe704a22b9048277cc7a9f1a540ba7f` | committed arithmetic modes, 121-point geometry, six sensitivity axes, and output contract |
| `COV-SUMMARY-v1` | `experiments/results/summaries/coverage_geometry_summary.json` | `d174d4910c2859532cfc4d5ef555519f73486273196affd91becb2d785a1e973` | exact S4/S5/C2 checks, smooth component/threshold/boundary diagnostics, and artifact inventory |
| `COV-DATA-FRONTIER-v1` | `experiments/results/summaries/coverage_frontier_gap.csv` | `bfd74fadba3fc10ea6330d5e30688d9700f23ce3e0c9586224426ac5423d069d` | complete source data for the frontier/candidate/gap figure |
| `COV-DATA-OCCUPATION-v1` | `experiments/results/summaries/coverage_occupation_distribution.csv` | `ecb95f5b45d236add1a5d48b072e9e71403ca3fc456afb8d5694890d5cf20deb` | full discounted occupation row and normalized shares |
| `COV-DATA-POTENTIAL-v1` | `experiments/results/summaries/coverage_potential.csv` | `40a97998c2657adb5262f847c152b6f840645dfd856e9a73c22f5570869dee00` | full smooth gap, potential, cost, net value, region, and component table |
| `COV-DATA-BOUNDARY-v1` | `experiments/results/summaries/coverage_research_boundaries.csv` | `40e25677fd9735225e2fc19577fef909aa9016ee2af6fd25d1697541a0a6a65d` | full research-boundary plotting table |
| `COV-DATA-TOPOLOGY-v1` | `experiments/results/summaries/coverage_connected_disconnected.csv` | `a887455c1223fd63b5cb72cdbc1474fa2cc801f4184c86bd57e2a1a3d4cb070d` | smooth connected and exact C2 disconnected comparison data |
| `COV-DATA-SENSITIVITY-v1` | `experiments/results/summaries/coverage_sensitivity.csv` | `9f787b84eed6d00823f863622e927a9266552826ecb60ec000402df2e905a87a` | every belief row for 19 baseline/one-at-a-time sensitivity scenarios |
| `COV-FIG-FRONTIER-v1` | `manuscript/figures/coverage_frontier_candidate_gap.svg` | `4dfbaf2a526de4c56e3b43b1d8000b146def63a696a474e0f90d0c2dedc82e80` | publication SVG rendered and visually inspected |
| `COV-FIG-OCCUPATION-v1` | `manuscript/figures/coverage_discounted_occupation.svg` | `4d76ddcf90517a4f0d306cf891a1449a18e60af84100cfae7a7a1fab0dc6c1ad` | publication SVG rendered and visually inspected |
| `COV-FIG-POTENTIAL-v1` | `manuscript/figures/coverage_potential.svg` | `cfc5478c4882827a7607eae11c43f0b76e3ea87cc758fea8e59540c6cb2ec177` | publication SVG rendered and visually inspected |
| `COV-FIG-BOUNDARY-v1` | `manuscript/figures/coverage_research_region_boundaries.svg` | `54384bac251de196de2fe52f4a8f759d39cf4183606995e7e1312f138631ae76` | publication SVG rendered and visually inspected |
| `COV-FIG-TOPOLOGY-v1` | `manuscript/figures/coverage_connected_disconnected.svg` | `d39ae96f5b166acd0cbcecd623ef1e9e1940fd5d04c39089332ea3177f3ca389` | publication SVG rendered and visually inspected |

The exact fixture fields computationally mirror Lean S4/S5/C2 and do not
replace kernel verification. The Markov resolvent, delayed-lifetime values,
Float64 smooth geometry, sensitivity rows, interpolated transversality, and
figures are numerical diagnostics only and establish no raw T6 theorem.

## Belief-kernel persistence response artifacts

| Artifact ID | Path | SHA-256 | Producer and validation |
|---|---|---|---|
| `KPR-CODE-v1` | `julia/scripts/run_kernel_persistence_response.jl` | `4b4a7d7dc05ef3135d808646b0b58a255849414a4f116a8d159d98f18f4f463a` | deterministic exact-rational S7 response-surface producer with nonmutating `--check` |
| `KPR-TEST-v1` | `julia/test/test_kernel_persistence_response.jl` | `b5824d4d4b669c4a1d1c992d057fd1ae094060f02e3e4824cd3ef68ea2073129` | 35 exact witness, direction, invalid-input, rendering, and artifact checks |
| `KPR-CONFIG-v1` | `experiments/configs/kernel_persistence_response.toml` | `9d0bc558edbb07e44d25aabf38c05f3139732e27cca0aa214461bbd41ab1edea` | exact persistence/effective-discount grids, witness, horizon, and output contract; no randomness |
| `KPR-SURFACE-v1` | `experiments/results/summaries/kernel_persistence_response_surface.csv` | `898a25ed999c5a1ef70180a2e65235dcdabd9348b54e2d48518b1c5f5efb5e7d` | 135 exact rows containing advantage-region occupation and gap-weighted coverage |
| `KPR-SUMMARY-v1` | `experiments/results/summaries/kernel_persistence_response_summary.json` | `95110b415f7c9b40fb4087b91c4d82805685c1e68e70ff2904a625e20b7bba8a` | exact Lean-matched raise/lower/no-effect witnesses and full-surface invariants |

These artifacts validate the exact S7 witness family and expose the occupation
channel behind each sign. The general alignment implication is Lean verified;
the finite grid is not its proof and supplies no universal persistence order.

## Controlled theorem-mechanism experiment artifacts

| Artifact ID | Path | SHA-256 | Producer and validation |
|---|---|---|---|
| `TM-CODE-v2` | `julia/scripts/run_theorem_mechanism_experiments.jl` | `b49112a11b73523235dd615326f972fe94143cfa1737beb73e6aeae82eb76cb0` | exact A--F and seeded Float64 G compatibility runner, prospective S4 ranking fixture, gated output producer, and platform-stable `--check` implementation |
| `TM-TEST-v2` | `julia/test/test_theorem_mechanisms.jl` | `fc078fe1d2bea0a5a29e962f7adffee824bda1688a706af4cd4e6d2e50eca0ce` | 65 family, exact-ranking, determinism, identity-gate, artifact-generation, and Float64 comparison-boundary checks |
| `TM-CONFIG-v2` | `experiments/configs/theorem_mechanisms.toml` | `d4d87ac7707ed426f4c8cb8a7c79d62c95250614459205175de32f26f5b797bb` | committed A--G parameters, six prospective candidate gaps, perturbations, expected rankings/selections, seed, and complete output contract |
| `TM-RAW-v2` | `experiments/results/raw/theorem_mechanism_observations.csv` | `260a08d80b0755335fd0fa6373f2546464f785a5effede049fc1cbe27f130062` | 850 regenerated long-form observations; ignored but checksum-validated by metadata |
| `TM-REPORT-v2` | `experiments/results/SYNTHETIC_REPORT.md` | `8d199ba68d150d792f80fc3bc5f1a763193f990bfbd42be9e4bb4ef2a33d80ad` | generated answer-first synthetic report with prospective-design and theorem-scope boundaries |
| `TM-SUMMARY-JSON-v2` | `experiments/results/summaries/theorem_mechanism_summary.json` | `d95e102a742a7685bd655020e3c70d0c78e64afa10f47f4973a3b12e0523d8fa` | seven family results, exact ranking/selection summaries, and twelve compatibility policy scenarios with Bellman diagnostics |
| `TM-SUMMARY-CSV-v2` | `experiments/results/summaries/theorem_mechanism_summary.csv` | `567084269d5dd68d8e58ce4df375bfee5569ca5bf9399657b8eddbe451c03468` | compact family-level table with expected and observed patterns |
| `TM-RANKING-CSV-v2` | `experiments/results/summaries/theorem_mechanism_coverage_ranking.csv` | `41d62fdaa1b39f7169dcbb0f924d00d6290eb95b3cd236d864e9cf558ace5f2a` | six exact gap vectors, independent targets, comparator scores/ranks, and bounded/stress perturbations |
| `TM-RANKING-SUMMARY-v2` | `experiments/results/summaries/theorem_mechanism_coverage_ranking_summary.csv` | `685fd66cdd981e88934b842bafa2622ea3731e4b31a9499a72a518c2a9437a8a` | exact rank correlations, selected candidates, values, and top-one regrets |
| `TM-SELECTION-CSV-v2` | `experiments/results/summaries/theorem_mechanism_coverage_selection.csv` | `8cca0cbd6b7bc3c272977ed2f3d6d7a11f3f3c09fec49dce2d040ddb2d6cf18b` | individual and sequential-marginal top-two selections with exact marginal and union values |
| `TM-POLICY-CSV-v2` | `experiments/results/summaries/theorem_mechanism_policy_summary.csv` | `e8c4c39996029211eece8b9a15c61280384358f8f8a1f454871a38985a748192` | preserved cost/delay/persistence/discount compatibility regions; Appendix-D regression input only |
| `TM-METADATA-v2` | `experiments/results/summaries/theorem_mechanism_metadata.json` | `d2c0ff9f6b9dc8cf3c459e6fee363a0657970a6edfd46f6674f6080baa3e1a9b` | command, environment, RNG, arithmetic, current source/config/manifest hashes, and full artifact checksum map |
| `TM-FIG-PRUNING-v2` | `manuscript/figures/theorem_mechanism_pruning_loss.svg` | `49f55dd5a0d96f0b7ff751762b809b90798ed5a98ce56242fa8402445440a284` | exact loss-scaling figure generated from committed CSV |
| `TM-FIG-DECOMPOSITION-v2` | `manuscript/figures/theorem_mechanism_value_decomposition.svg` | `b7e00fd6646913b82ba92e1b7b5599028edb40ec87d6108af256e1ca12a8a397` | exact stacked decomposition figure generated from committed CSV |
| `TM-FIG-COVERAGE-v2` | `manuscript/figures/theorem_mechanism_coverage_geometry.svg` | `65f1d113de04967729d354a7d155f83bb11dd266a51feae827c4723a23c5a18a` | four-panel exact preservation/failure comparison generated from committed CSV |
| `TM-FIG-RANKING-v2` | `manuscript/figures/theorem_mechanism_coverage_ranking.svg` | `1039c227c631ad6c8cf37bf96360004b1397b482597724c3739551fccde357da` | exact correlation and set-value comparison generated from committed ranking/selection CSVs |
| `TM-FIG-POLICY-v2` | `manuscript/figures/theorem_mechanism_policy_map.svg` | `e7dec3b79aafa2f1d4557123b88b35494b063416d3953b08836fb4450561d4af` | preserved twelve-scenario compatibility heatmap; Appendix-D regression artifact only |
| `UCS-POLICY-TEX-CODE-v2` | `julia/scripts/generate_dynamic_policy_figure.jl` | `900e90dc606700f17ee0e53ad30afd86e199de21ac2a924a2d701c8ec5768502` | unified-surface compact-view generator with raw-source, positive-duration, sparse-mode, convergence, gate, region, and direction validation plus `--check` |
| `UCS-POLICY-TEX-v2` | `manuscript/figures/dynamic_research_policy_regions.tex` | `8df3b8f2d9ebfbfadaaa468327bc03dc56ef565bb4cb27f4202886383309ba33` | Section 7 TikZ view of nine registered unified positive-duration policy slices; Float64 numerical observation |

The metadata file records SHA-256 for the additional decomposition and figure-
data tables. Families A--F are exact mechanism validation; family G and its
figure are seeded Float64 numerical diagnostics. The prospective ranking
fixture targets S4's fixed-candidate gross value by construction and does not
reinterpret the locked adverse ETF result. None is a new Lean theorem or an
implementation of the accepted raw T1--T6 model. Version 1 is retained in Git
history.

## Terminal financial-audit artifacts

| Artifact ID | Path | SHA-256 | Producer and validation |
|---|---|---|---|
| `FTA-PREP-v1` | `julia/scripts/prepare_financial_terminal_audit_data.jl` | `877cbedc11e3430fccebf4cceacf29afd36fa433c84e654979574b9b80a2d83b` | read-only CRSP extractor, optional ORATS-inventory audit, identifier audit, and ignored provenance writer; performs no download |
| `FTA-CODE-v1` | `julia/scripts/run_financial_terminal_audit.jl` | `e7186438e361697132ba86811f073923fb017d6f5ed91199d742aca1560bb1e4` | finite grammar, lagged backtest, pruning/ranking/decomposition gates, StableRNG uncertainty, reports, and SVG producer |
| `FTA-TEST-v1` | `julia/test/test_financial_terminal_audit.jl` | `14adf43c2e5621ed915fdfe2513a38237a84a705c50fb27330eb8641d7183f99` | grammar, provenance-state, safe-compression, decomposition, ranking, uncertainty, and cost checks |
| `FTA-CONFIG-v1` | `experiments/configs/financial_terminal_audit.toml` | `4eacad83bdeeff9b01e2cd812123845662fd7bae9748c9b74443f8a365aea2da` | fixed 25-ETF/PERMNO universe, finite 2,400-strategy grammar, periods, timing, costs, seed, access model, and complete output contract |
| `FTA-STATUS-v1` | `experiments/results/summaries/financial_terminal_audit_status.json` | `2b915f97e48152dd349f33f58d0746fa7227f6e4bc81fabb49c816388eccb2d6` | source/config/data/decision identity, separate raw/aggregate and point-in-time gates, reviewer access, RNG, period/cost settings, and SHA-256 of every other generated artifact |
| `FTA-REPORT-v1` | `experiments/financial_terminal_audit/DRAFT_RESULTS.md` | `dfa3ab8d911d301830bfc01232c0cedb9dbbd6d6b780dfa83aa210150ae1ff1a` | generated 2--3 page mechanism-results draft retaining the adverse coverage-ranking result |
| `FTA-LIMITATIONS-v1` | `experiments/financial_terminal_audit/EMPIRICAL_LIMITATIONS.md` | `2f4ee0da3d7205ba59552ebd5c0827ef02d781e4e6e19ff1d92d3fb6aef50abb` | generated empirical, licensing, point-in-time, survivorship, cost, inference, and finite-grammar boundary |
| `FTA-FIG-PRUNING-v1` | `manuscript/figures/financial_terminal_audit_frontier_pruning.svg` | `a5f35f967eeee607f650547592a43dc0257c2c15bce5abbad0ee3ac4248e2bc9` | frozen frontier-preservation/ex post opportunity-quality figure linked to committed CSV data; legacy embedded wording is retained for hash lineage |
| `FTA-FIG-RANKING-v1` | `manuscript/figures/financial_terminal_audit_candidate_ranking.svg` | `631fbc075fc49a37e3f99383b2c905ead9cc8f3c59a5d5510e55eccb0c9fc779` | frozen-ranking comparison linked to committed CSV data |
| `FTA-FIG-DECOMP-v1` | `manuscript/figures/financial_terminal_audit_decomposition.svg` | `94cbd9719820bc392b1960a357baafb48d4663a5ce267148a53ca07a2a47ac66` | operational/generative component figure linked to committed CSV data |

The ignored local panel has 106,975 rows, 25 funds, 4,279 complete common
dates, and SHA-256
`8fad82e719a97160072835b5c4d02a5581283473919aad67cf2346ea8da17af4`.
It is nonredistributable. The status JSON is the generated manifest for all
remaining candidate, pruning, ranking, decomposition, uncertainty, cost,
figure-data, and manuscript-section artifacts. The locked terminal audit is
mechanism evidence only and is not Lean verification or an alpha claim. The
aggregate artifacts are publishable under D-0041; that classification does
not extend to the ignored licensed rows.

## Annual walk-forward financial-audit artifacts

| Artifact ID | Path | SHA-256 | Producer and validation |
|---|---|---|---|
| `FWA-AUDIT-v1` | `julia/scripts/audit_financial_annual_universe.jl` | `ed59c143c0490c421e219573cf7e1bc0842a60bf65d49b68405d563513f4f5ff` | outcome-blind CRSP identity/liquidity audit; parses no return outcome |
| `FWA-FREEZE-v1` | `julia/scripts/freeze_financial_annual_walkforward_audit.jl` | `2df27f535184860ac5c727c76530a84720f543667b5dd7d172bcfabe2842b0e1` | completed-implementation hash and immutable amendment-chain verifier |
| `FWA-PREP-v1` | `julia/scripts/prepare_financial_annual_walkforward_audit_data.jl` | `e3e15350d361c3e8f61b0582230bdbc58f618983a07abf6a94dfc8225bfbd40c` | read-only selected-universe extractor and ignored provenance writer; performs no download |
| `FWA-CODE-v1` | `julia/scripts/run_financial_annual_walkforward_audit.jl` | `3033e7ee2e77ed7baeb279b1cb720132b98bd988d52c5214dbbe324e0c257512` | 9,600-strategy walk-forward compression, ranking, uncertainty, reports, and SVG producer |
| `FWA-TEST-v1` | `julia/test/test_financial_annual_walkforward_audit.jl` | `890ddd0bd9a57cd3fffe32a585571f0cdf61255774c50892becbec8a8c7fa568` | grammar, sufficient-statistic, marginal-set, and occupation tests; 11/11 pass |
| `FWA-AUDIT-CONFIG-v1` | `experiments/configs/financial_annual_universe_audit.toml` | `fc78e1ee7b454c5c00689fddd76827e054a8f38a679d62c82d4bf06e45f93194` | endpoint, history, liquidity, complex-product, and top-100 selection gates |
| `FWA-CONFIG-v1` | `experiments/configs/financial_annual_walkforward_audit.toml` | `fb7e965acf29100a04b382bb24e55b3a9adbf95a1466782ae67b00458d9b18fd` | periods, grammar, state/occupation estimands, costs, seed, lock chain, and output contract |
| `FWA-LOCK-v1` | `experiments/financial_annual_walkforward_audit/DESIGN_LOCK.json` | `857db487085d809e1e504f65f65bb57afb4581e516ad797519d09ad76c7644fa` | active taxonomy-migration envelope; the original registered lock is retained separately |
| `FWA-REGISTERED-LOCK-v1` | `experiments/financial_annual_walkforward_audit/DESIGN_LOCK_REGISTERED.json` | `45350297243e447b7bb26a888dbe8b67c55085878f987de642fdd37c4a1a2451` | immutable registered analytical lock retained under the professional namespace |
| `FWA-UNIVERSE-v1` | `experiments/financial_annual_walkforward_audit/universe_selection.toml` | `52abd208b146449c626f377f692c828542b62ca1673e1a442d827690f620009d` | exact 100 ticker/PERMNO selections fixed before return extraction |
| `FWA-STATUS-v1` | `experiments/results/summaries/financial_annual_walkforward_audit_status.json` | `4417fec431fa6f0832c994ef34a2f288c23c4f57291e9681df85ce0f6668d421` | data/config/design/decision identities and SHA-256 for every generated annual-audit artifact |
| `FWA-REPORT-v1` | `experiments/financial_annual_walkforward_audit/DRAFT_RESULTS.md` | `56999b6d748b93add5f8c7abe69248eda3f1b98367148b7e856804c990a49afe` | generated 2--3 page walk-forward mechanism results with uncertainty and negative-year disclosure |
| `FWA-LIMITATIONS-v1` | `experiments/financial_annual_walkforward_audit/EMPIRICAL_LIMITATIONS.md` | `6a4952c44e594b98b38a8e103b9a4957e67013fae316b1e21fa5219c0a2be141` | licensing, survivorship, retrospective-lock, amendment, inference, cost, and theorem boundaries |
| `FWA-FIG-UNIVERSE-v1` | `manuscript/figures/financial_annual_walkforward_audit_universe.svg` | `3e0cbff957fc529abe1a85c29271a844b0d2566c6e6035886d2d1f958be6579c` | outcome-blind 427-to-100 universe funnel linked to committed CSV |
| `FWA-FIG-RANKING-v1` | `manuscript/figures/financial_annual_walkforward_audit_ranking.svg` | `f87865a223f9dfa02d860b633b05a56675951d436f3c97b7b9f8c23dac7e68c8` | four-rule realized set-coverage comparison linked to committed CSV |
| `FWA-FIG-MECHANISM-v1` | `manuscript/figures/financial_annual_walkforward_audit_mechanisms.svg` | `1f7da63cde5b0b10aa50ae6cf85e79717d1ec5a0eb92b996ac132c244647e2f8` | frozen current-frontier/ex post opportunity-quality comparison linked to committed CSV; legacy embedded wording is retained for hash lineage |

The ignored annual-audit panel has 427,900 rows, 100 funds, 4,279 complete dates, and
SHA-256 `029b623b18836190d196e6543539380582e0ec046671d6f0d9a4db026e207ffc`.
It is nonredistributable. The self-checksummed status JSON covers every
remaining candidate, pruning, annual ranking, selection, decomposition,
uncertainty, cost, figure-data, report, and manuscript artifact. The annual
walk-forward audit is mechanism evidence only; it is neither Lean verification
nor an alpha claim, and it does not replace the adverse locked terminal result.

## Cross-audit financial resource-optimization artifacts

| Artifact ID | Path | SHA-256 | Producer and validation |
|---|---|---|---|
| `FAT-TAXONOMY-v1` | `FINANCIAL_AUDIT_TAXONOMY.md` | `1d0249a82582ec79d41425ea268c8a5353968497dad12f35b448cf5971d8681e` | reader-facing namespace map and taxonomy-only migration boundary |
| `FRO-CONFIG-v1` | `experiments/configs/financial_resource_optimization.toml` | `b10dc9ec8dfdc70ff1fb9ade802b0ebb38569b160502972f0e14ede8a1f0ef64` | exact arithmetic, two registered audit IDs, burden schedules, gates, and descriptive output paths |
| `FRO-REGISTERED-LOCK-v1` | `experiments/financial_resource_optimization/DESIGN_LOCK_REGISTERED.json` | `85d9687c54d2d21030abfdc47919897be6c051a55ab12819665dcbbc2b00c6f9` | immutable registered pre-taxonomy lock retained under the professional namespace |
| `FRO-LOCK-v1` | `experiments/financial_resource_optimization/DESIGN_LOCK.json` | `c0a6791827ce488ae8daaa344104e58f52de702412305fa75656e1391321938d` | active taxonomy-migration envelope linked to the preserved registered lock |
| `FRO-LOCK-CODE-v1` | `julia/scripts/lock_financial_resource_optimization.jl` | `d4b30bb8a59070b491f4c738426cf4ac9504b3007530985a1dac0d26b1ddec27` | immutable registration checks plus taxonomy-migration and nonmutating verification modes |
| `FRO-CODE-v1` | `julia/scripts/run_financial_resource_optimization.jl` | `f14b8f38ad25c94df5054593e46df6417abe0500158de205b919cca41f1428c1` | exact resource-model construction, HiGHS search, exact post-solve certification, and artifact renderer |
| `FRO-VERIFY-v1` | `julia/scripts/verify_financial_resource_optimization_outputs.jl` | `a594af3540de206e74c03ecc24bb6bc79cb6680651c8309073fdd374d8cf6508` | independent aggregate-output and parent-hash verifier; does not rerun licensed-data analysis |
| `FRO-TEST-v1` | `julia/test/test_financial_resource_optimization.jl` | `92884f6cb76d1feab08c0292f45c6f8badb7247f001047e8de5ee7c44279ec88` | exact fixture, burden, closure, certification, and output checks |
| `FRO-STATUS-v1` | `experiments/results/summaries/financial_resource_optimization_status.json` | `4e1c042447227ce4f365c11e326d04a82a301d1f90d99f310c89df2af3bb1be8` | design identity, solver/equality gates, and generated/parent artifact hash maps |
| `FRO-WEIGHTS-v1` | `experiments/results/summaries/financial_resource_optimization_weights.csv` | `47386bc4cce4604aa4d0a1faa56b16f5bf151d47f6c0478e6a6e0017cd9d1c36` | exact registered burden schedules |
| `FRO-SOLUTIONS-v1` | `experiments/results/summaries/financial_resource_optimization_solutions.csv` | `653dc5bb061ce1f82de823ebc7760be64ae80bda97f7cf471a8eb42d40d3e2f4` | exact solution-level burden and certificate summary |
| `FRO-LIBRARIES-v1` | `experiments/results/summaries/financial_resource_optimization_libraries.csv` | `ef90508f15c049148fd888692270b4ebba1c14cd2e2cfef99b20e44b4c8afb8c` | complete selected-library membership certificates |
| `FRO-FRONTIERS-v1` | `experiments/results/summaries/financial_resource_optimization_frontier_certificates.csv` | `fa0ff4ccc05be6003026df772bfc3506fb45281e8a6c38e593451c28c536bc69` | exact source/selected frontier coordinate checks |
| `FRO-SUMMARY-v1` | `experiments/results/summaries/financial_resource_optimization_summary.csv` | `7cb1c7ce33a7d71036f2a64542b6cccb89fee0f23fb69949a8e42e3bb7da6a70` | two-audit exact compression and opportunity-quality summary |
| `FRO-REPORT-v1` | `FINANCIAL_RESOURCE_OPTIMIZATION.md` | `e296ceb2386febf9f3ed00724881991abbb402df5381144eb40e96ad9f9e2090` | reader-facing exact results and claim boundary |

## Exact multi-gap topology-audit artifacts

| Artifact ID | Path | SHA-256 | Producer and validation |
|---|---|---|---|
| `MG-CODE-v1` | `julia/scripts/search_multi_gap_topology.jl` | `b76d2126e4395422674ae5d127d7633ce0a1208fcca061d171f32e8e418aab8a` | reviewed exact Julia source; package regressions pass |
| `MG-CONFIG-v1` | `experiments/configs/multi_gap_topology.toml` | `d7823f1bfa3a8ba16fffc1f83750c5d8268de99ab3ce101cf4f81eb6fe83c908` | committed search grids and exact witness configuration |
| `MG-RESULT-v1` | `experiments/results/multi_gap_topology.json` | `290c37101886346fb6f0a4f33000c0c98cb71d9093552c528c5640c91a0cbab9` | generated by `MG-CODE-v1` under Julia 1.12.6 using `Rational{BigInt}` |
| `MG-LEAN-DATA-v1` | `formal/StrategyInnovation/Fixtures/MultiGapRegion.lean` | `9918854f55769968bd721da2bc60085fae04e35b0126187091d000e0b0eae594` | generated by `MG-CODE-v1`; consumed by the typed Lean counterexample |

The result records the exact C2 witness, all 251 square-minor checks, 3,125
sign-variation checks, 28,125 strict-superlevel component checks, and the
arbitrary-cost topology counterexample. Only the propositions proved in
`Counterexamples/MultiGapRegion.lean` receive Lean-verified status; the bounded
variation/component searches remain numerical evidence.

## Foundational Lean artifacts

| Artifact class | Paths | Validation |
|---|---|---|
| finite carriers | `formal/StrategyInnovation/Basic/Model.lean` | included in successful full `lake build` |
| exact distributions | `formal/StrategyInnovation/Basic/Probability.lean` | finite-support rational distribution laws included in the successful build |
| strategy and library model | `formal/StrategyInnovation/Library/{Strategy,Library}.lean` | included in successful full `lake build` |
| frontier and closure calculus | `formal/StrategyInnovation/Library/{Frontier,Closure}.lean` | F0 declarations build without prohibited placeholders |
| compressed state | `formal/StrategyInnovation/Library/InnovationState.lean` | component-projection lemmas kernel checked |
| examples | `formal/StrategyInnovation/Library/Examples.lean` | concrete `example` declarations compile |
| proof audit | `formal/StrategyInnovation/Audit/Foundations.lean` | focused linter passes and exact foundational dependencies are recorded in `THEOREM_LEDGER.md` |
| raw admission and local update | `formal/StrategyInnovation/Raw/` | exact generation/admission interfaces, normalized admitted law, raw update, local compressed update, and RC1 kernel checked |
| raw-model proof audit | `formal/StrategyInnovation/Audit/RawModel.lean` | focused linter passes and exact R0 dependencies are recorded in `THEOREM_LEDGER.md` |
| raw-to-compressed T1 projection | `formal/StrategyInnovation/Projection/RawToCompressed.lean` | derived exact transition, embedded semi-Markov law, finite calendar value identity, fixed-point bridge, and selector lift kernel checked |
| T1 proof audit | `formal/StrategyInnovation/Audit/RawToCompressed.lean` | all principal T1 declarations print only `propext`, `Classical.choice`, and `Quot.sound`; focused namespace linter passes |
| unified cost-sensitive DI quotient | `formal/StrategyInnovation/Quotient/UnifiedDynamicInnovation.lean` | five-observation equivalence, finite/infinite value preservation, quotient finiteness/factorization, compressed-state sufficiency, and restricted refinement kernel checked |
| unified DI proof audit | `formal/StrategyInnovation/Audit/UnifiedDynamicInnovation.lean` | all ten principal UDI declarations print only `propext`, `Classical.choice`, and `Quot.sound`; focused namespace linter passes |
| abstract DI quotient | `formal/StrategyInnovation/Quotient/DynamicInnovation.lean` | deprecated cost-free primitive equivalence retained for F1--F4 compatibility; legacy quotient/value/refinement results remain kernel checked |
| DI proof audit | `formal/StrategyInnovation/Audit/DynamicInnovation.lean` | focused linter passes and exact F1 dependencies are recorded in `THEOREM_LEDGER.md` |
| frontier--closure characterization | `formal/StrategyInnovation/Quotient/FrontierClosure.lean` | modular factorization, identifiable iff, value sufficiency, and two finite counterexamples kernel checked |
| frontier--closure proof audit | `formal/StrategyInnovation/Audit/FrontierClosure.lean` | focused linter passes and exact F2 dependencies are recorded in `THEOREM_LEDGER.md` |
| abstract safe deletion | `formal/StrategyInnovation/Compression/SafeDeletion.lean` | single and repeated deletion, innovation-safe sublibraries, exact examples, and the value-only converse counterexample kernel checked |
| safe-deletion proof audit | `formal/StrategyInnovation/Audit/SafeDeletion.lean` | focused linter passes and exact F3 dependencies are recorded in `THEOREM_LEDGER.md` |
| sharp scaled pruning loss | `formal/StrategyInnovation/Counterexamples/FrontierPruningLoss.lean` | explicit finite construction, exact loss, arbitrary scaled target, and sharp capped-reward theorem kernel checked |
| pruning-loss proof audit | `formal/StrategyInnovation/Audit/FrontierPruningLoss.lean` | focused linter passes and exact F4 dependencies are recorded in `THEOREM_LEDGER.md` |
| sharp normalized pruning loss T4 | `formal/StrategyInnovation/Compression/NormalizedPruningLoss.lean` | raw survival/admission construction, exact `β^d ρ^d π C - κ`, sharp cap, ratio one, unit normalization, scaling corollary, and operation adjustment kernel checked |
| normalized pruning-loss proof audit | `formal/StrategyInnovation/Audit/NormalizedPruningLoss.lean` | all 23 publication-facing declarations are axiom-audited and the focused namespace linter passes |
| finite-state value calculus | `formal/StrategyInnovation/Value/FiniteHorizon.lean` | exact F5 expectation, Bellman, boundedness, equivalence, factorization, and optimizer results kernel checked |
| insertion decomposition | `formal/StrategyInnovation/Value/Decomposition.lean` | exact F6 decomposition, scoped monotonicity, and bridge example kernel checked |
| passive innovation equation | `formal/StrategyInnovation/Value/InnovationEquation.lean` | exact F7 gap equation, reachability zero criterion, antitonicity, and delayed example kernel checked |
| unified raw insertion decomposition T5 | `formal/StrategyInnovation/Value/UnifiedDecomposition.lean` | T1 raw/compressed passive/full value bridge, exact insertion decomposition, silence consequences, operational antitonicity, explicit unified project dominance, and raw generation/admission bridge witness kernel checked |
| unified T5 proof audit | `formal/StrategyInnovation/Audit/UnifiedDecomposition.lean` | all 20 publication-facing declarations print only the accepted standard foundations and the focused namespace linter passes |
| generative retained-carrier lower bound T6 | `formal/StrategyInnovation/Value/GenerativeLowerBound.lean` | cost-adjusted raw-project lower bound, explicit operating/passive adjustment, finite occupation form, sign and comparative statics, and exact one-belief carrier example kernel checked |
| T6 proof audit | `formal/StrategyInnovation/Audit/GenerativeLowerBound.lean` | all 63 publication-facing declarations print only the accepted standard foundations and the focused namespace linter passes |
| joint descendant-event T6 interface | `formal/StrategyInnovation/Value/JointDescendantLowerBound.lean` | unit-interval terminal joint mass, exact cost/operating/frozen-passive/joint/remaining commitment identity, no-independence bound, product corollary, mass/gain/cost orders, exact one- and two-belief fixtures, and no-unconditional-duration-sign witness kernel checked |
| joint descendant-event T6 audit | `formal/StrategyInnovation/Audit/JointDescendantLowerBound.lean` | all 31 dedicated-interface declarations print only the accepted standard foundations |
| finite sign-definite comparative statics CS1 | `formal/StrategyInnovation/Value/ComparativeStatics.lean` | frontier/value monotonicity and saturation, cost antitonicity, binary admission/survival monotonicity, corrected unified-delay result, closure dominance, exact action-region inclusion, and seven exact assumption-boundary counterexamples kernel checked |
| CS1 proof audit | `formal/StrategyInnovation/Audit/ComparativeStatics.lean` | all 39 main declarations print only the accepted standard foundations and the focused namespace linter passes |
| discounted Bellman contraction | `formal/StrategyInnovation/Bellman/Contraction.lean` | exact-data real completion, contraction, fixed point, convergence, error bound, and DI invariance kernel checked |
| unified Bellman and stationary policy S2 | `formal/StrategyInnovation/Bellman/Unified.lean` | exact finite-horizon action attainment, raw/compressed monotonicity and derived contraction, unique value, geometric convergence, T1/UDI value equalities, stationary selector, and policy-evaluation equation kernel checked |
| unified Bellman proof audit | `formal/StrategyInnovation/Audit/UnifiedBellman.lean` | all 31 principal declarations print only the accepted standard foundations |
| unified Bellman exact fixture | `formal/StrategyInnovation/Fixtures/UnifiedBellman.lean` | positive-duration raw carrier instantiates finite/infinite projection and stationary policy-evaluation theorems |
| unified canonical exact fixture | `formal/StrategyInnovation/Fixtures/UnifiedCanonical.lean` | raw-derived two-belief/three-state benchmark checks normalized laws, full-duration paths, exact reward blocks, raw/compressed finite values, the stationary value/action table, lifted raw policy evaluation, zero residual, and unique actions |
| unified canonical proof audit | `formal/StrategyInnovation/Audit/UnifiedCanonical.lean` | all 36 fixture theorems print either no axioms or only the accepted standard foundations |
| finite coverage potential | `formal/StrategyInnovation/Coverage/Potential.lean` | S4 representation, monotonicities, no-value condition, bounds, delayed example, and frontier antitonicity kernel checked |
| finite patience--survival complementarity S6 | `formal/StrategyInnovation/Coverage/DiscountSurvivalInteraction.lean` | truncated exact matrix resolvent, finite-sum identity, discount/survival monotonicity, factorized increasing differences, equivalent cross inequality, and negative-gap boundary kernel checked |
| S6 proof audit | `formal/StrategyInnovation/Audit/DiscountSurvivalInteraction.lean` | all 22 main definitions and declarations print only the accepted standard foundations and the focused namespace linter passes |
| belief-kernel comparative statics S7 | `formal/StrategyInnovation/Coverage/KernelComparativeStatics.lean` | exact discounted occupation representation, gap-alignment implication and tailored order, stochastic persistence family, and raise/lower/no-effect counterexamples kernel checked |
| S7 proof audit | `formal/StrategyInnovation/Audit/KernelComparativeStatics.lean` | all 19 main definitions and declarations print only the accepted standard foundations and the focused namespace linter passes |
| frontier--closure system interaction T7 | `formal/StrategyInnovation/Value/SystemInteraction.lean` | realizable T1 compressed rectangles, closure increment and cross difference, corrected relative-saturation substitution theorem, primitive common-gap sufficient condition, and strict substitute/complement/separable/menu-switch/Continue-pair examples kernel checked |
| T7 proof audit | `formal/StrategyInnovation/Audit/SystemInteraction.lean` | all 37 publication-facing declarations print only the accepted standard foundations and the focused namespace linter passes |
| primitive frontier--closure substitution | `formal/StrategyInnovation/Interaction/PrimitiveSubstitution.lean` | fixed-kernel descendant-gap recursion, finite-horizon preservation, common-gap and general-T7 adapters, canonical substitution, and exact complement/separable boundaries kernel checked |
| primitive substitution proof audit | `formal/StrategyInnovation/Audit/PrimitiveSubstitution.lean` | all 12 recursion, adapter, substitution, and boundary declarations print only the accepted standard foundations and the focused namespace linter passes |
| finite monotone-gap threshold | `formal/StrategyInnovation/Coverage/SingleGap.lean` | S5 one-shot cost-covering definition, upper-threshold theorem, cutoff comparative statics, and boundary counterexamples kernel checked; no Bellman-region claim |
| multi-gap limitation | `formal/StrategyInnovation/Counterexamples/MultiGapRegion.lean` | C2 exact two-gap potential, disconnected cost-covering set, and unrestricted-cost topology boundary kernel checked |
| raw T2 characterization | `formal/StrategyInnovation/Quotient/RawFrontierClosure.lean` | raw factorization consequences, T1-projected transition equality, detectable UDI iff, and both exact boundary counterexamples kernel checked |
| raw T2 proof audit | `formal/StrategyInnovation/Audit/RawFrontierClosure.lean` | all 16 principal declarations print only the accepted standard foundations and the focused linter passes |
| raw T3 safe deletion | `formal/StrategyInnovation/Compression/{UnifiedSafeDeletion,UnifiedSafeDeletionExamples}.lean` | unified single/rechecked deletion, pruning specification, finite/infinite value and action preservation, detectable converse, and exact recheck boundaries kernel checked |
| raw T3 proof audit | `formal/StrategyInnovation/Audit/UnifiedSafeDeletion.lean` | every publication-facing T3 declaration prints only the accepted standard foundations and the focused linter passes |
| finite penalized affine envelope | `formal/StrategyInnovation/Optimization/PenalizedEnvelope.lean` | fixed nonempty finite family, attained real-price maximum, continuity, convexity, nonincrease, finite switching candidates, local affine slopes, and antitone optimal burden kernel checked |
| finite penalized-envelope proof audit | `formal/StrategyInnovation/Audit/PenalizedEnvelope.lean` | every manuscript-facing PEN-core declaration prints only `propext`, `Classical.choice`, and `Quot.sound`; focused namespace linter passes |
| real-parameter elasticity core | `formal/StrategyInnovation/{Optimization/Elasticity,Compression/BridgeMarginElasticity,Coverage/InnovationDuration,Value/ChannelElasticity}.lean` | shared point-elasticity algebra, positive bridge-loss derivatives and fragility limits, finite duration/variance identities, signed channel contributions, positive-channel weighted average, actual derivative corollaries, and exact finite examples kernel checked |
| real elasticity proof audit | `formal/StrategyInnovation/Audit/Elasticity.lean` | shared elasticity algebra, BEM, IDCV, CED, exact examples, and actual-breakpoint local envelope slope print only `propext`, `Classical.choice`, and `Quot.sound`; focused namespace linters pass |
| value/coverage proof audits | `formal/StrategyInnovation/Audit/{FiniteHorizon,Decomposition,InnovationEquation,Contraction,CoveragePotential,DiscountSurvivalInteraction,KernelComparativeStatics,SingleGap,MultiGapRegion}.lean` | focused linters pass and exact F5--F8/S4--S7/C2 dependencies are recorded in `THEOREM_LEDGER.md` |

These are source artifacts rather than generated experiment outputs, so no
artifact checksum is assigned. The focused Git commit is their provenance.

## Absent substantive artifact classes

| Class | Expected future location or form | Current status |
|---|---|---|
| remaining primary research theorem declarations | future extensions under `formal/StrategyInnovation/` | none in the adopted T1--T7 package; F0, F1--F8, S4--S7, C2, and CS1 are supporting results |
| higher-level Julia research algorithms | `julia/src/{Compression,InnovationValue,DynamicProgramming,Coverage,RawDynamicProgramming,ComparativeStatics,ApproximateCompression}.jl` | safe and approximate compression, raw generation/admission, unified timing and Bellman operators, exact/Float64 comparative statics, reusable S4/S5/S6/S7/C2 coverage algorithms, exact T6 scalar bound/fixture, and exact T7 interaction surfaces exist |
| additional experiment configurations | immutable committed configs | theorem-feasibility, single-gap geometry, multi-gap topology, safe and approximate compression, dynamic-program, coverage, kernel-persistence response, system interaction, controlled theorem-mechanism, and limited financial configs exist |
| empirical outputs | generated, checksummed data | separate locked-terminal and annual walk-forward aggregate mechanism summaries and derived compression-characteristic tables exist and are publishable under D-0041/D-0043/D-0068; licensed rows remain excluded |
| figures and tables | Julia-generated artifacts | eighteen SVGs have complete source CSVs and generated metadata; six financial figures are publication artifacts |
| empirical data | licensed/provenanced inputs, if used | ignored local CRSP panel exists with complete source and license audit; raw and row-level redistribution is prohibited |
| general raw-model theorem fixture adapters | future mappings from the shared exact records into every accepted raw Lean structure | the version-1 transparent exact bridge exists, but no universal raw-model adapter theorem exists |
| generated theorem exports and machine-readable axiom reports | generated audited metadata in `shared/` | absent; source-level F0 audit exists |
| release bundle | `release/v0.1.1-arxiv/` | main and supplement PDFs, minimal two-document arXiv source package, hashes, and archive-expanded source-commit metadata are present; executable research projects, deprecated internal records, and licensed rows are excluded from the arXiv source archive |

## Manifest policy

Every generated or external artifact must record:

- stable artifact ID;
- repository path;
- producing command or source provenance;
- input artifact IDs;
- relevant code commit;
- environment identifier;
- checksum;
- generated timestamp when relevant;
- validation status;
- manuscript consumers.

Generated large-file storage and retention policy must be decided before large
outputs are committed.
