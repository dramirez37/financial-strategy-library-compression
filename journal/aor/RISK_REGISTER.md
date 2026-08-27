# AOR journal risk register

Ratings are qualitative planning judgments grounded in inspected repository
behavior. They are not runtime forecasts, solver guarantees, or journal-policy
statements.

## Scientific and mathematical risks

| ID | Risk | Likelihood | Impact | Repository evidence | Required control or stop condition |
|---|---|---:|---:|---|---|
| M-01 | A tagged-cover theorem is stated for general closure even though the inspected equivalence is identity-closure only. | Medium | Critical | `IdentitySafeCover` and the SC-COMP proof use belief-attainer and module-carrier obligations under identity closure. General closure is modeled through minimal generators instead. | State the theorem for identity closure. If extending it, prove a separate general-closure characterization. Stop if the obligation system is not equivalent in both directions. |
| M-02 | Exact safe feasibility, dynamic equivalence, and value preservation are conflated. | Low | High | Lean requires `RawClosureDetectable` only for the converse DI characterization; exact compressed-state equality implies value equality without that converse. | Reuse theorem-ledger assumptions verbatim. Do not shorten prose by changing the direction or assumptions of an existing theorem. |
| M-03 | A fixed local/global counterexample is promoted to an arbitrary worst-case gap family. | Medium | High | Julia and Lean prove fixed cardinality and `(2,2,3)` witnesses only. No parametric family or unbounded-gap statement was found. | Define the gap metric and parameterized family first. Prove the formula by hand, test exact instances, and stop if the family does not scale as claimed. |
| M-04 | A generic greedy optimality or approximation ratio is claimed. | High | Critical | The repository contains an exact strict-heaviest-first counterexample and repeatedly disclaims a generic approximation guarantee. | Seek a theorem only under explicit structural assumptions. If proof fails or counterexamples survive those assumptions, publish the limitation and heuristic evidence, not a forced guarantee. |
| M-05 | Preprocessing removes an apparently dominated strategy that is still needed for frontier ties, module closure, or optimizer ties. | Medium | Critical | Strategies have two roles; exact closure can depend on dominated operating strategies. | Every rule needs a bidirectional optimum-preservation proof and a deterministic lifting certificate. Exhaustively compare reduced and unreduced optimum/tie sets on small instances. |
| M-06 | A full DP is described as implemented when only subset enumeration or the operational-cover lower-bound DP exists. | High | High | `operational_ip_cardinality_lower_bound` ignores the full generative constraint; complete subset enumeration is exponential search, not the proposed obligation DP. | Use distinct names and result fields. Require DP-versus-two-oracle agreement before manuscript use. |
| M-07 | Complexity validation is called Lean verification. | Medium | Critical | SC-COMP has a human proof and exact Julia fixtures but no Lean declaration or axiom audit. | Preserve the theorem-ledger status. Formalize only if explicitly selected; otherwise say “human proof with exact finite validation.” |
| M-08 | Finite exhaustive validation is presented as universal proof. | Medium | High | The SC-COMP check covers 5,565 budgeted three-set/three-element full-union instances and 44,520 selected masks; other fixture grids are also bounded exact computations. | State the searched class and counts. Keep universal claims attached to human or Lean proof only. |

## Algorithm and implementation risks

| ID | Risk | Likelihood | Impact | Repository evidence | Required control or stop condition |
|---|---|---:|---:|---|---|
| I-01 | Large identity instances instantiate `GenerativeClosure` and exhaust memory. | High | Critical | The constructor enumerates all `2^m` module subsets and performs pairwise monotonicity checks. The financial amendments record interruption when identity closure was materialized for 113 modules. | Use a sparse tagged-obligation representation for identity closure. Never call the powerset constructor in the scaling or financial study. |
| I-02 | Exact bitmask DP exhausts time or memory as the number of obligations grows. | High | High | Every proposed state represents a subset of obligations; existing bitmask fixtures cap carriers at 62. | Register an obligation-count cap, memory/time limit, and censored status. Preprocess first; use DP only as a bounded oracle. Do not promise large-instance coverage. |
| I-03 | Objective rational scaling exceeds exact Float64 integer representation in JuMP/HiGHS. | Medium | High | `SafeCompressionSolver.jl:76-90` rejects scaled integer objectives beyond `2^53`. | Retain fail-closed scaling. Register allowed weight denominators or fall back to exact enumeration/DP; never round an exact objective silently. |
| I-04 | A solver `OPTIMAL` status is reported as exhaustive or formal global proof. | Medium | Critical | For instances above the exact-enumeration limit, solver and exact safety certificates are separate; the financial report explicitly keeps them separate. | Keep `solver_claimed_optimal`, `exact_safety_verified`, and `exact_global_optimality_by_enumeration` as separate required fields. |
| I-05 | A solver candidate passes the model but fails the original problem. | Low | Critical | Existing code deliberately recomputes original frontier, general closure, burden, formulation, and inactive retention. | All algorithms, not only MILP, must call an independent original-problem certificate before export. Fail the entire run on one invalid returned library. |
| I-06 | Refactoring removes oracle independence. | Medium | High | The package model, `ResourceOptimization`, and MILP internal enumeration currently provide distinct implementations. | Preserve at least two independent exact small-instance oracles until the journal algorithms and schemas are locked. |
| I-07 | Standalone modules and package types diverge semantically. | Medium | High | `ResourceOptimization.jl` uses implicit inactive and identity masks; `SafeCompressionComplexity.jl` uses its own decision type; neither is included in `StrategyInnovation.jl`. | Choose a canonical package type plus explicit adapters. Add integration tests before promoting either module into the public API. |
| I-08 | Nondeterministic ordering changes ties, selected IDs, hashes, or result rows. | Medium | High | Existing code fixes deletion order, stable masks, HiGHS seed zero, and single-thread defaults. | Register stable instance/algorithm ordering and exact tie policy. Serialize all tie sets or name a deterministic presentation selector separately. |
| I-09 | Runtime measurements include compilation, warm-up, output rendering, or different scopes. | High | Medium | Existing scaling prototypes use different timing scopes; committed Float64 rows contain host-dependent `runtime_ns`. | Lock separate construction, solve, certificate, and end-to-end timing definitions; warm up before measured repetitions; retain environment metadata. |
| I-10 | Schema fragmentation prevents cross-algorithm comparison. | High | Medium | Current scripts implement several private JSON/CSV writers and no common algorithmic result schema. | Lock one versioned schema and validator before outcomes. Store exact values canonically and runtime fields separately. |

## Experimental and empirical risks

| ID | Risk | Likelihood | Impact | Repository evidence | Required control or stop condition |
|---|---|---:|---:|---|---|
| E-01 | The new algorithmic study changes or reuses frozen N=1024 seeds, registry, locks, or outputs. | Low | Critical | The randomized-v2 design fixes 1,024 trials, 4,096 component seeds, lock hashes, and result prefixes. | Use only `experiments/algorithmic_compression_v1/`, new seeds, new registry, new config, new lock, and new outputs. Treat N=1024 only as immutable prior evidence. |
| E-02 | Outcome-aware tuning occurs before the algorithmic design is locked. | Medium | Critical | Existing studies distinguish pre-outcome locks and amendments. | Freeze families, factors, seeds, algorithms, tuning, tie rules, limits, estimands, schemas, and exclusions before the first registered outcome. Record any pre-outcome amendment. |
| E-03 | Easy set-cover-like instances make scaling conclusions uninformative. | High | High | The current MILP probe uses one deterministic structured family and the older pruning diagnostics repeat a small number of prototypes. | Register multiple justified instance families and hardness controls before running. Do not select families based on favorable algorithm outcomes. |
| E-04 | Timed MILP failures disappear from summaries. | Medium | High | No registered scaling schema currently defines timeouts or censored rows. | Every instance/algorithm pair must emit a row, including timeout, memory failure, invalid-candidate, and no-candidate statuses. |
| E-05 | A bounded scaling run is generalized beyond tested sizes or hardware. | Medium | High | Existing runtime fields are explicitly host-dependent and no long safe-compression study is committed. | Report the registered size grid, hardware/software, repetitions, and censoring only. Make no asymptotic empirical claim from finite timings. |
| E-06 | Held-out financial information affects pruning, preprocessing, weights, tuning, algorithm choice, or optimization. | Medium | Critical | Current lock says held-out quality may not define weights and is reported ex post only. | Construct all algorithm inputs from the frozen compression-time objects. Hash decisions before any held-out read. Add a column-level information-set test and fail closed. |
| E-07 | Raw CRSP/WRDS rows or derivatives enter tracked results or logs. | Low | Critical | `DATA_ACCESS.md` excludes raw rows, row derivatives, completed provenance, and extraction audits. | Run only existing licensed wrappers when explicitly authorized. Track aggregate/certificate outputs only; run the public disclosure audit before commit. |
| E-08 | Financial algorithm comparisons alter frozen parent selections or result meaning. | Medium | Critical | Existing parent artifacts and pruning rules are hash-locked; the resource extension was separately registered. | Create a new comparison lock referencing parent hashes. Do not overwrite parent reports, tables, or selectors. Compare new algorithms on the same compression-time inputs. |
| E-09 | Financial raw replay exceeds memory or is killed. | High | High | Resource amendments document a roughly 24 GB annual heap, hour-long GC scans, and an exit-137 process kill before the final child-process design. | Prefer public aggregate/certificate replay for development. If licensed replay is explicitly requested, reuse the child-extraction design and register resource monitoring. |
| E-10 | Retrospective outcomes are described as causal, predictive, alpha, or deployable performance. | Medium | Critical | The repository explicitly rejects all four interpretations. | Preserve the nonclaims in captions, abstract, results, discussion, and cover letter. |

## Provenance, release, and submission risks

| ID | Risk | Likelihood | Impact | Repository evidence | Required control or stop condition |
|---|---|---:|---:|---|---|
| P-01 | Current source/artifact lineage is represented by stale hashes. | Certain | High | Twenty-five standard Artifact-ID rows in `ARTIFACT_MANIFEST.md` do not hash to the file at the listed path. | Resolve by versioning historical paths or issuing new IDs/current hashes with an explicit decision record. Never mutate the frozen release to make a mutable path agree. |
| P-02 | The public audit fails on journal submission files. | Certain | Medium | The audit rejects email addresses in three existing journal files as requiring publication review. | Decide whether journal submission metadata is deliberately outside the public-release policy or adapt the policy/package after author approval. Keep this separate from mathematical gates. |
| P-03 | `make preprint-check` is used as a journal gate and attempts to rebuild a frozen bundle from mutable bibliography. | Certain under current branch | High | `journal/aor/REVISION_LEDGER.md:24-31` records the failure. | Keep the release tree immutable. Define a journal gate that checks release hashes without regenerating it; later repair the preprint gate by an explicit provenance decision. |
| P-04 | Journal-only SC-COMP prose is mistaken for the frozen preprint's claim set. | Medium | High | SC-COMP is in the journal-specific section and ledger, not the immutable release. | Version the journal manuscript and claim matrix explicitly. Do not backport by altering the release bundle. |
| P-05 | Every displayed manuscript scalar is assumed traced although only selected artifact checks were run. | Medium | High | Source references and selected producers pass; this baseline audit did not execute the full artifact/manuscript gate. | At the declared manuscript gate, generate all journal macros/tables from committed artifacts and fail on literal untraced result numbers. |
| P-06 | Indexed repository-only supplement records are omitted from the submitted supplement without clear disclosure. | Medium | Medium | Four records are indexed but not compiled by `online_supplement/main.tex`. | Decide the submitted supplement graph explicitly and update its inventory; do not imply repository-only files are pages in the compiled PDF. |
| P-07 | Package/release version `0.1.0`, preprint `v0.1.1`, and journal branch `v0.2.0` are conflated. | Medium | Medium | Julia and Lean projects say `0.1.0`; README names `v0.1.1-arxiv`; branch names `v0.2.0`. | Adopt a version table in journal release metadata. Change package versions only in a later scoped task with tests. |
| P-08 | Current journal requirements are asserted from an unverified template snapshot. | Medium | High | The repository vendors a Springer template, but this baseline task did not verify the live special-issue instructions. | Before submission packaging, verify current requirements from authoritative journal pages and record the access date. Do not invent requirements in the manuscript or cover letter. |

## Estimated computational risk by proposed work item

No wall-clock value is estimated here. “Computational risk” means risk of
state-space, memory, solver, or licensed-workflow failure relative to ordinary
targeted tests.

| Proposed work item | Computational risk | Basis and safe development gate |
|---|---|---|
| Tagged-cover equivalence fixtures | Low | Incidence and obligation equality are exact finite scans. Exhaust small carriers first; no solver needed. |
| Complexity reduction regression | Low | The current exhaustive three-by-three audit completes quickly. Expand bounds only deliberately; this is validation, not proof. |
| Parametric local/global gap family fixtures | Low to medium | Each parameter value can be exact and small, but a broad exhaustive search can grow exponentially. Prove the family first, then test a bounded grid. |
| Preprocessing equivalence audit | Medium | Requires unreduced/reduced optimum and tie-set enumeration on many small instances. Cap carriers and run targeted properties before any scale work. |
| Exact full bitmask DP | High | Time and memory grow exponentially in obligation count, even after preprocessing. Register a state cap and treat DP as a bounded oracle. |
| Greedy construction benchmark | Medium | Candidate construction is expected to be cheaper than exact optimization, but exact certification and oracle gaps remain required. No guarantee is assumed. |
| Synthetic multi-algorithm scaling study | High | NP-hard MILPs, exponential DP, preprocessing variability, repetitions, and censored runs create substantial compute and design risk. Smoke only until the design is locked; long run requires explicit request. |
| Public aggregate financial algorithm comparison | Medium | The compressed source sizes are 80 and 202 and sparse identity incidence already exists; exact certification is tractable in current tests. Governance risk remains high. |
| Licensed annual financial replay | Very high | The amendment record documents roughly 24 GB peak behavior, long garbage collection, and an exit-137 failure before the child-process workaround. Run only when explicitly requested and licensed inputs are present. |
| Frozen N=1024 replay | Prohibited for this program | It is long and immutable, and is not a valid way to generate new algorithmic outcomes. Use existing committed results only. |
| Lean tagged-cover theorem | Low computational / medium formalization | Kernel checking should be modest once the finite statement is right, but proof-engineering risk is nontrivial. Do not formalize complexity theory merely for appearance. |

## Highest-priority gates

Before any new outcome-bearing run:

1. resolve the exact theorem and contribution boundary;
2. prove and test preprocessing/DP correctness on small exact instances;
3. preserve independent certification;
4. create and lock the new experiment registry and schema;
5. verify that no held-out financial variable is an algorithm input; and
6. obtain an explicit request before the long final benchmark.

If a theorem is false, underspecified, or unproved, the correct outcome is a
documented boundary or counterexample, not a rewritten conclusion.
