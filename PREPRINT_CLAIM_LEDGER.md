# Fourth-Draft Preprint Claim Ledger

Audit date: 2026-08-19
Audited commit: `48b8bcaa0244f62769fdd4522e2632f394ca6c62`
Frozen manuscript baseline: tag `preprint-fourth-draft-2026-08-19`
Manuscript source: `manuscript/main.tex` and the files it inputs

## Audit conventions

This ledger inventories substantive claims in the abstract, introduction,
four-item contribution list, all 33 theorem/proposition/corollary environments,
the main numerical and experimental discussion, the financial audit, and the
conclusion. Repeated claims are consolidated only when every repeated location
is listed. Literature-summary claims are outside this claim audit; their source
accuracy is handled by the literature and novelty audit.

The columns answer the ten requested questions. `Human` means a complete
human-readable proof exists for a mathematical statement; `N/A (computed)`
means the claim is an artifact-backed computation rather than a proof claim.
`Lean claimed` records what the manuscript or validation table represents as
Lean verified. `Lean exists` records this audit's finding in the current source,
not a stale planning status. `Julia` distinguishes a reusable validation from a
registered instance-only calculation. `Timing` is `N/A`, `registered synthetic`,
`retrospective`, or `prospective`; none of the current empirical evidence is
prospective. `Overstatement` is the release judgment, not a truth-value label.

Claim classes use the requested vocabulary: theorem, corollary, exact finite
computation, randomized synthetic evidence, numerical approximation, financial
retrospective diagnostic, interpretation, and conjecture/future work.

## Severity summary

| Severity | Count | Release meaning |
|---|---:|---|
| BLOCKER | 2 | Two reproducibility/presentation gates fail and must be repaired before release. |
| MAJOR | 2 | Two formal-correspondence wordings should be reconciled before release. |
| MINOR | 4 | Four qualification or governance-status issues should be cleaned up, but they do not reverse a result. |
| CLEAN | 97 | Claims are supported and scoped at their stated evidentiary level. |

## BLOCKER

Neither blocker is evidence that a displayed numerical outcome is false. Both
are nevertheless release blockers under the paper's own requirement that all
presentation and generated-artifact checks pass.

| ID | Exact manuscript location | Claim text or concise paraphrase | Class | Supporting theorem/code/artifact | Human | Lean claimed | Lean exists | Julia | Timing | Overstatement |
|---|---|---|---|---|---|---|---|---|---|---|
| B-01 | Main financial section `manuscript/sections/10_financial_compression_audit.tex:5-76`; required qualifications are present only in `manuscript/appendices/e_financial_information_audit.tex:40-56,67-81`; failing contract at `julia/test/test_financial_compression_focus.jl:263-270` | The public-facing financial information set must say that neither pruning rule tests candidate-set equality and that coverage scores are post-compression ranking inputs, not pruning inputs. | financial retrospective diagnostic | Locked E1/E2 design; Appendix E information audit; financial presentation test | N/A | No | N/A | **Fail:** 93/95 presentation assertions pass; these two required main-section qualifications are absent | retrospective | The current main text still says held-out quality is ex post and not a pruning input, so it does not assert alpha or forecasting. But it fails the locked presentation contract and leaves the candidate-set/coverage-score distinction less explicit than required. Release should remain blocked until the test and intended prose are reconciled. |
| B-02 | `manuscript/appendices/e_experiment_protocol.tex:10-19` claims check-mode byte stability; drift is in `experiments/results/summaries/theorem_mechanism_metadata.json` | All theorem-mechanism figures/tables/metadata regenerate byte-for-byte from source artifacts. | exact finite computation / reproducibility claim | `run_theorem_mechanism_experiments.jl --check`; ARTIFACT_MANIFEST `TM-METADATA-v2` | N/A | No | N/A | **Fail:** only metadata drifts; current committed metadata stores `manifest_sha256=ce93...`, while current `julia/Manifest.toml` hashes to `4f75...`; source/config hashes and substantive test families pass | N/A | Yes as a current reproducibility claim. The theorem-mechanism values and their 55/55 family tests pass, but the committed provenance metadata is stale, so the generated package is not presently byte reproducible. |

## MAJOR

| ID | Exact manuscript location | Claim text or concise paraphrase | Class | Supporting theorem/code/artifact | Human | Lean claimed | Lean exists | Julia | Timing | Overstatement |
|---|---|---|---|---|---|---|---|---|---|---|
| M-01 | `manuscript/main.tex:70-72`; `manuscript/sections/05_innovation_safe_compression.tex:74-86`; `manuscript/sections/06_operational_generative_value.tex:161-166`; `manuscript/sections/09_canonical_finite_model.tex:51-53,105-106,119-121`; `manuscript/sections/11_limitations_conclusion.tex:36-44`; Appendix F line 24 | Capacity value “need not be concave,” with the profile `(0,0,1)` and unit increments `0,1`. | theorem plus exact finite computation | CAP; `Optimization/CapacityValue.lean`; `Optimization/CapacityCounterexample.lean`; `CX-OPT-CAPACITY-NONCONCAVE-01`; resource and randomized optimization artifacts | Yes, including the elementary midpoint implication | Yes, as part of the capacity theorem family | Partial exact match: Lean proves the three values and failure of diminishing discrete increments, but does not name ordinary real `ConcaveOn` failure; D-0128 explicitly separates these notions | Yes, exact enumeration and registered counts | N/A / registered synthetic where frequencies are quoted | **Yes under the paper's strict exact-counterpart rule.** The substantive claim is true, but the manuscript labels ordinary nonconcavity inside a Lean-complete theorem while the registered Lean declaration is the discrete-increment witness. Add the exact analytic declaration or narrow the Lean-facing wording to failure of diminishing unit increments. |
| M-02 | `manuscript/sections/01_introduction.tex:139-145`; `manuscript/sections/07_belief_space_coverage.tex:31-58`; Appendix F line 25 | The displayed log-derivative identities identify innovation duration with `d log Psi / d log alpha` and innovation convexity with the second log derivative/timing variance. | theorem | IDCV; `Coverage/InnovationDuration.lean`; `INNOVATION_DURATION_SPEC.md`; FG-0040; D-0129 | Yes | Yes, broadly, through “fixed-exposure duration” in Appendix F | Partial exact match: Lean proves the finite polynomial derivatives and scaled identities `alpha Psi' = ...` and `alpha D' = C`; FG-0040 says the separate log-composition derivative declarations remain open | Instance-only registered exact calculations; no reusable generic Julia evaluator | N/A | **Yes under the exact-counterpart rule.** The prose says “chain-rule interpretation,” which is mathematically correct, but the display itself states the unformalized log-composition identities while the family is marked Lean complete. Display the scaled verified form and retain the log form as interpretation, or formalize the compositions. |

## MINOR

| ID | Exact manuscript location | Claim text or concise paraphrase | Class | Supporting theorem/code/artifact | Human | Lean claimed | Lean exists | Julia | Timing | Overstatement |
|---|---|---|---|---|---|---|---|---|---|---|
| m-01 | `manuscript/sections/07_belief_space_coverage.tex:63-89` and proposition at lines 71-89 | Differentiating `I=O+G` gives signed channel contributions that sum to total elasticity; the positive-channel form is share weighted. | theorem | CED; `Value/ChannelElasticity.lean`; `CHANNEL_ELASTICITY_SPEC.md`; FG-0041 | Yes | Yes | Yes, conditional on neighborhood equality and derivatives along one common path | Registered model instances only; no reusable CED evaluator | N/A | Slightly. The surrounding prose supplies `I=O+G`, but the proposition's displayed hypotheses mention differentiability and not the Lean-critical neighborhood identity. Restating that assumption in the proposition would make the manuscript/Lean match self-contained. |
| m-02 | `manuscript/sections/08_dynamic_research_control.tex:270-287` | The canonical rows `D_beta=beta V_beta/V` are called exact local innovation durations. | exact finite computation | `run_unified_elasticity_switching_experiment.jl`; `unified_canonical_resource_channel_elasticities.csv`; registered exact derivative systems | N/A (computed) | No model-specific Lean claim is explicit | No named T1/T5-to-IDCV adapter; FG-0040 leaves it open | Yes, exact instance with zero residual and fixed selected policy | N/A | Slightly. “Local” and “fixed-exposure” are stated, but the model-specific adapter to the abstract nonnegative exposure sequence is not formalized or reusable. Keep this as a Julia instance diagnostic, not a Lean consequence. |
| m-03 | `manuscript/main.tex:75`; `manuscript/sections/01_introduction.tex:145-146`; `manuscript/sections/09_canonical_finite_model.tex:4-12` | Exact and randomized experiments “test” or “exercise” theorem mechanisms. | interpretation | Registered exact fixtures, randomized v2 registry, hard gates, and audit scripts | N/A | No | N/A | Yes | registered synthetic | Slightly. “Exercise” is safest; “test” can sound inferential. Later text correctly limits frequencies to the frozen generator, so this is a wording polish rather than a substantive defect. |
| m-04 | `ASSUMPTIONS.md:297-299,321-324,351-354` (governance, not manuscript prose) | BEM, CED, and IDCV status says Lean formalization is absent. | interpretation | Current Lean files, THEOREM_LEDGER BEM/CED/IDCV, FG-0039--FG-0041, D-0129 | N/A | Manuscript Appendix F says complete | Yes for the stated finite real-calculus cores | BEM/CED/IDCV generic reusable Julia evaluators remain absent | N/A | Governance inconsistency. The assumption text predates completed formalization and conflicts with the actual source and current ledger. It does not invalidate the proofs, but it weakens reproducibility and should be synchronized before release. |

## CLEAN

### Abstract

| ID | Exact manuscript location | Claim text or concise paraphrase | Class | Supporting theorem/code/artifact | Human | Lean claimed | Lean exists | Julia | Timing | Overstatement |
|---|---|---|---|---|---|---|---|---|---|---|
| A-01 | `manuscript/main.tex:59-63` | Retained strategies are operational and generative assets, so exact compression must preserve frontier and module closure. | interpretation | Model definitions; T1--T3; bridge fixture | N/A | No | N/A | Yes, exact examples | N/A | No; this is the paper's finite-model interpretation. |
| A-02 | `manuscript/main.tex:63-65` | A finite minimum-resource safe optimum exists and preserves productive value and optimal actions. | theorem | OPT-FND; T1; `Optimization/SafeCompression.lean`; `Bellman/Unified.lean` | Yes | Yes | Yes | Yes, exact enumeration | N/A | No. |
| A-03 | `manuscript/main.tex:65-67` | Rechecked safe deletion preserves safety but its endpoint need not be globally resource minimal. | theorem | T3; OPT-T2T4; exact `(2,2,3)` fixture | Yes | Yes | Yes | Yes | N/A | No. |
| A-04 | `manuscript/main.tex:67-69` | Frontier-only pruning can lose the entire attainable delayed bridge margin, sharply. | theorem | T4; `Compression/NormalizedPruningLoss.lean`; exact unit bridge | Yes | Yes | Yes | Yes | N/A | No; normalization and worthwhile-action domain are explicit. |
| A-05 | `manuscript/main.tex:71-72` | Penalized value is a continuous convex piecewise-affine envelope and optimal burden is nonincreasing in price. | theorem | PEN; `Optimization/PenalizedEnvelope.lean`; exact active-branch sweeps | Yes | Yes | Yes in the locally-affine-off-finite-breakpoint form | Yes | N/A | No. |
| A-06 | `manuscript/main.tex:72-74` | Productive value and named-path elasticities split into operational and generative channels. | theorem | T5; CED; `Value/UnifiedDecomposition.lean`; `Value/ChannelElasticity.lean` | Yes | Yes | Yes | Exact model instances | N/A | No, subject to the common-path/positive-denominator conditions stated later. |
| A-07 | `manuscript/main.tex:75-78` | Financial audits are locked, retrospective, use held-out quality only ex post, and support no causal, forecasting, or performance claim. | financial retrospective diagnostic | E1/E2 locks, information-set audit, financial resource audit | N/A | No | N/A | Yes, hashes and rechecks | retrospective | No; appropriately explicit. |

### Introduction and contribution list

| ID | Exact manuscript location | Claim text or concise paraphrase | Class | Supporting theorem/code/artifact | Human | Lean claimed | Lean exists | Julia | Timing | Overstatement |
|---|---|---|---|---|---|---|---|---|---|---|
| I-01 | `manuscript/sections/01_introduction.tex:4-17` | Strategy research is cumulative; retained libraries grow and consume storage, validation, maintenance, monitoring, and governance resources. | interpretation | Motivating finite resource model; literature boundary | N/A | No | N/A | No | N/A | No as motivation; not presented as an estimated fact. |
| I-02 | `manuscript/sections/01_introduction.tex:19-25` | A currently dominated strategy can uniquely carry a module needed for a profitable descendant. | exact finite computation / interpretation | T4 bridge catalog and canonical bridge | Yes for existence construction | Yes for construction | Yes | Yes | N/A | No. |
| I-03 | `manuscript/sections/01_introduction.tex:27-40` | Raw research projects to `K=(F,C)` without changing productive values/actions; exact safe compression has an attained finite optimum but can have ties, complementarities, and order dependence. | theorem | T1; OPT-FND; OPT-T2T4; CAP counterexample | Yes | Yes | Yes | Yes | N/A | No. |
| I-04 | `manuscript/sections/01_introduction.tex:42-50` | Rechecking gives a safe path; one-deletion irreducibility does not imply global optimality. | theorem | T3; OPT-T2T4 | Yes | Yes | Yes | Yes | N/A | No. |
| I-05 | `manuscript/sections/01_introduction.tex:52-74` | Safe compression, capacity selection, and penalized selection are distinct finite outer problems; retention resources do not alter the Bellman recursion. | interpretation / theorem definitions | A-RESOURCE-OUTER; OPT-FND; CAP; PEN | Yes for finite results | Yes | Yes | Yes | N/A | No. |
| I-06 | `manuscript/sections/01_introduction.tex:76-83` | Finite value-burden points yield a stepwise capacity path and piecewise-affine penalized envelope without concavity, divisibility, or smoothness assumptions. | theorem | CAP; PEN | Yes | Yes | Yes | Yes | N/A | No; does not assert capacity concavity. |
| I-07 | `manuscript/sections/01_introduction.tex:85-91` | Optimal libraries can switch discretely; within a fixed policy, value sensitivities decompose and duration summarizes generative timing exposure. | interpretation | PEN/CAP; CED; IDCV; registered switching map | Yes for fixed-branch identities | Partly | Yes for PEN/CED/IDCV cores; general switching is not claimed | Yes | N/A | No, because fixed-policy scope is stated. |
| I-08 | `manuscript/sections/01_introduction.tex:93-105` | Insertion value equals operating-frontier contribution plus research-option contribution; at switches use margins/envelopes, not a within-policy derivative. | theorem / interpretation | T5; CED; PEN | Yes | Yes for level/channel identities and the finite PEN envelope | Yes for T5/CED/PEN | Exact switch diagnostics | N/A | No. |
| C-01 | `manuscript/sections/01_introduction.tex:109-117` | Raw/compressed dynamics agree; finite safe libraries preserve state/value/actions and attain a minimum-resource member. | theorem | T1; OPT-FND | Yes | Yes | Yes | Yes | N/A | No. |
| C-02 | `manuscript/sections/01_introduction.tex:119-127` | Rechecked pruning is safe but can miss the global optimum; dropping closure attains the sharp bridge-loss bound. | theorem | T3; OPT-T2T4; T4 | Yes | Yes | Yes | Yes | N/A | No. |
| C-03 | `manuscript/sections/01_introduction.tex:129-137` | Capacity is attained/nondecreasing/stepwise with possible increasing returns; PEN is continuous, nonincreasing, convex, piecewise affine, and all optimizer burdens fall with price. | theorem | CAP; PEN | Yes | Yes | Yes for the exact listed finite properties | Yes | N/A | No apart from M-01's promotion to ordinary nonconcavity elsewhere. |
| C-04 | `manuscript/sections/01_introduction.tex:139-150` | Value/channel sensitivity decomposes; fixed-exposure duration is an effective-discount elasticity; experiments preserve evidence boundaries; held-out quality is never a pruning input. | theorem plus empirical qualification | T5; CED; IDCV; E1/E2 information-set records | Yes for mathematics | Yes | Yes subject to M-02 | Yes | retrospective for financial portion | No apart from M-02. |
| I-09 | `manuscript/sections/01_introduction.tex:153-160` | Exact enumeration checks finite identities; randomized frequencies are generator-specific; MILP status is separate from exact selected-library rechecking; financial outcomes are read after decisions. | interpretation / evidence classification | Reproducibility gates; N5/N7; E1/E2 | N/A | No | N/A | Yes | registered synthetic / retrospective | No. |
| I-10 | `manuscript/sections/01_introduction.tex:161-162` | A general set-valued switching theory is beyond the present finite-envelope results and is left for future work. | conjecture/future work | D-0139; FG-0042 closed by scope | No current-paper proof claim | No | No current-paper declaration is required | Exact diagnostics remain separate from the future theory | N/A | No; the unfinished theorem has been removed from the current claim architecture. |

### Other substantive mathematical discussion

| ID | Exact manuscript location | Claim text or concise paraphrase | Class | Supporting theorem/code/artifact | Human | Lean claimed | Lean exists | Julia | Timing | Overstatement |
|---|---|---|---|---|---|---|---|---|---|---|
| E-01 | `manuscript/sections/05_innovation_safe_compression.tex:128-165` | In the optional outer admission/replacement problem, additive burden determines the release requirement and the least-loss feasible deletion set yields a candidate-value-minus-displacement-loss accounting. | conjecture/future work / interpretation | REP; `REPLACEMENT_OPTIMIZATION_SPEC.md`; exact replacement fixture | Yes | No; the section calls it supporting and optional | No REP Lean declaration | Exact registered boundary instance; no complete reusable theorem validator | N/A | No; the text explicitly keeps this outside the verified central theorem package. |
| E-02 | `manuscript/sections/06_operational_generative_value.tex:147-168` | Exact capacity shadows are nonnegative; complementarity can make unit shadows increase, while sorted additive equal-unit gains give weakly decreasing grid shadows; normalized arcs require positive bases. | theorem / interpretation | CAP; `Optimization/CapacityValue.lean`; `Optimization/CapacityDiminishingReturns.lean`; complementarity fixture | Yes | Yes for the stated CAP witness and additive sufficient condition | Yes | Yes, exact profiles | N/A | No apart from M-01 if translated into ordinary real nonconcavity. |
| E-03 | `manuscript/sections/07_belief_space_coverage.tex:2-29` | On the positive-margin fixed-duration real bridge, elasticities have the displayed formulas; magnitudes diverge only as normalized margin tends to zero; zero-margin elasticity is undefined. | theorem | BEM; `Compression/BridgeMarginElasticity.lean`; FG-0039 | Yes | Yes | Yes | No generic Julia BEM evaluator; registered exact instance exists | N/A | No; the positive-domain and vanishing-gross counterexample boundaries are explicit. |
| E-04 | `manuscript/sections/07_belief_space_coverage.tex:110-134` | Strict price branches inherit slope \(-W\); pairwise intersections require global filtering; unequal-burden ties use one-sided slopes or finite changes; optimizer margins and adjacent-grid action brackets are diagnostics rather than exact primitive roots. | theorem / exact finite computation / interpretation | PEN; registered canonical switching map and Bellman gap table | Yes for the finite PEN claims | Yes for the finite PEN envelope only | Yes for the finite PEN envelope; no general switching theory is claimed | Yes, exact finite candidates, globally active breakpoints, margins, action gaps, and brackets | N/A | No; the statement is confined to proved finite-envelope results and computed diagnostics. |

### All theorem, proposition, and corollary environments

| ID | Exact manuscript location | Claim text or concise paraphrase | Class | Supporting theorem/code/artifact | Human | Lean claimed | Lean exists | Julia | Timing | Overstatement |
|---|---|---|---|---|---|---|---|---|---|---|
| T-01 | `manuscript/sections/03_model.tex:130-151` | Raw laws normalize; equal compressed states give equal action primitives/laws; the decision-epoch process projects; finite/stationary values and lifted selectors agree. | theorem | T1; `Projection/RawToCompressed.lean`; `Bellman/Unified.lean` | Yes | Yes | Yes | Reusable exact raw/compressed oracle and fixtures | N/A | No; decision-epoch and no-independence boundaries are explicit. |
| T-02 | `manuscript/sections/04_dynamic_innovation_equivalence.tex:28-36` | The finite safe family is nonempty; minimum burden is attained; safe representations preserve finite/stationary value and all stationary optimal actions. | theorem | OPT-FND; T1; S2 | Yes | Yes | Yes | Exact enumeration | N/A | No. |
| T-03 | `manuscript/sections/04_dynamic_innovation_equivalence.tex:110-133` | Frontier-closure equality implies DI; detectability gives the converse; single deletion is safe exactly when frontier and closure are unchanged; values/actions are preserved. | theorem | T2; T3 | Yes | Yes | Yes | Exact gauntlet and counterexamples | N/A | No; converse assumption is explicit. |
| T-04 | `manuscript/sections/04_dynamic_innovation_equivalence.tex:156-167` | A rechecked deletion trace preserves state, DI, and value; a complete failed final scan certifies one-deletion irreducibility. | corollary | T3; OPT-T2T4 | Yes | Yes | Yes | Exact trace audit | N/A | No. |
| T-05 | `manuscript/sections/04_dynamic_innovation_equivalence.tex:177-181` | A pruning certificate must include its rechecked trace. | theorem | T3 certificate API | Yes | Yes | Yes | Reusable Julia trace checks | N/A | No. |
| T-06 | `manuscript/sections/04_dynamic_innovation_equivalence.tex:197-204` | Positive-weight global minima are locally irreducible, but locally irreducible/heaviest-first endpoints need not be global minima. | theorem | OPT-T2T4; `Optimization/SafeCompression.lean`; `Optimization/SafeCompressionCounterexample.lean` | Yes | Yes | Yes | Exact `(2,2,3)` fixture | N/A | No. |
| T-07 | `manuscript/sections/05_innovation_safe_compression.tex:18-39` | Frontier-only bridge loss equals the net delayed margin, is sharp under the reward cap, has normalized loss one, and requires scaling for unbounded additive loss. | theorem | T4; `Compression/NormalizedPruningLoss.lean` | Yes | Yes | Yes | Exact fixtures | N/A | No. |
| T-08 | `manuscript/sections/05_innovation_safe_compression.tex:45-50` | A specified scaling fixture realizes any nonnegative additive loss `M`. | corollary | T4 scaling declaration | Yes | Yes | Yes | Exact fixture | N/A | No. |
| T-09 | `manuscript/sections/05_innovation_safe_compression.tex:74-86` | Capacity maximum is attained, monotone, locally constant between attainable burdens, changes only at attainable burdens, and has nonnegative forward increments. | theorem | CAP; `Optimization/CapacityValue.lean` | Yes | Yes | Yes | Exact enumeration | N/A | No for these clauses; ordinary nonconcavity clause is M-01. |
| T-10 | `manuscript/sections/05_innovation_safe_compression.tex:105-114` | Finite PEN maximum is attained; envelope is continuous/nonincreasing/convex/piecewise affine; switch candidates are finite; optimizer burden is ordered; strict branches have slope `-W`. | theorem | PEN; `Optimization/PenalizedEnvelope.lean` | Yes | Yes | Yes | Exact branch enumeration | N/A | No; pairwise candidates are not called active kinks. |
| T-11 | `manuscript/sections/06_operational_generative_value.tex:40-47` | Finite-horizon insertion value is exactly operational plus generative value. | theorem | T5; `Value/UnifiedDecomposition.lean` | Yes | Yes | Yes | Exact recursion fixtures | N/A | No. |
| T-12 | `manuscript/sections/06_operational_generative_value.tex:56-61` | Frontier-silent insertion has zero operational contribution; frontier-and-closure-silent insertion has zero total value. | corollary | T5/T1 | Yes | Yes | Yes | Exact fixtures | N/A | No. |
| T-13 | `manuscript/sections/06_operational_generative_value.tex:97-120` | Under the displayed joint-event, comparator, insertion, and passive-retention assumptions, the carrier's generative value obeys the operating-adjusted lower bound. | theorem | T6; `Value/JointDescendantLowerBound.lean`; joint-carrier fixture | Yes | Yes | Yes | Exact joint-law fixture | N/A | No; cost, operation, and supportwise gain assumptions are visible. |
| T-14 | `manuscript/sections/06_operational_generative_value.tex:130-139` | Under event factorization the terminal term is a product; the guarantee has the stated one-way signs, while total descendant mass alone is sign-ambiguous. | corollary | T6; CS1 | Yes | Yes | Yes | Exact comparative-static fixture | N/A | No. |
| T-15 | `manuscript/sections/07_belief_space_coverage.tex:71-89` | Common-path operational and generative scaled contributions sum to total elasticity; positive levels permit a share-weighted form. | theorem | CED; `Value/ChannelElasticity.lean` | Yes | Yes | Yes | Instance-only exact rows | N/A | No except m-01's self-contained-hypothesis polish. |
| T-16 | `manuscript/sections/07_belief_space_coverage.tex:159-167` | In the explicitly supporting frozen-library process, passive operational insertion value equals the discounted finite gap sum. | theorem | F7 supporting primitive adapter; `Value/InnovationEquation.lean` | Yes | Yes as supporting only | Yes | No separate generic validation | N/A | No; it is not presented as T5/T6. |
| T-17 | `manuscript/sections/07_belief_space_coverage.tex:181-185` | A two-period deterministic move to a gap-two state yields operational insertion value one. | corollary | F7 exact Lean example | Yes | Yes | Yes | Direct exact calculation | N/A | No. |
| T-18 | `manuscript/sections/07_belief_space_coverage.tex:187-194` | A fixed candidate's passive operational insertion value weakly decreases as the incumbent library expands. | theorem | Frontier monotonicity and passive-value insertion declarations | Yes | Yes | Yes | Exact set-function checks | N/A | No; scope is operational/passive, not total generative value. |
| T-19 | `manuscript/sections/08_dynamic_research_control.tex:56-72` | Finite maxima are attained; raw/compressed stationary Bellman operators are monotone contractions; fixed points/selectors exist, project, evaluate, and satisfy the geometric bound. | theorem | S2; `Bellman/Unified.lean`; canonical Lean fixture | Yes | Yes | Yes | Exact and Float64 solves | N/A | No. |
| T-20 | `manuscript/appendices/a_additional_formal_definitions.tex:150-154` | Dynamic innovation equivalence is an equivalence relation. | theorem | UDI quotient declarations | Yes | Yes | Yes | Exact signature checks | N/A | No. |
| T-21 | `manuscript/appendices/a_additional_formal_definitions.tex:161-172` | DI equality preserves finite/stationary values; the finite quotient exists; values factor through it; frontier-closure equality implies DI. | theorem | UDI/T1/T2 | Yes | Yes | Yes | Exact oracle | N/A | No; no coarsest-quotient claim. |
| T-22 | `manuscript/appendices/a_additional_formal_definitions.tex:195-201` | Any representation whose equality preserves all five observations refines DI. | theorem | UDI restricted-refinement declaration | Yes | Yes | Yes | Signature checks | N/A | No; restricted comparison class is explicit. |
| T-23 | `manuscript/appendices/b_long_proofs.tex:67-80` | Under complete project-action dominance, research-option premium is monotone; a frontier-silent insertion then has nonnegative generative value. | theorem | CS1; `Value/ComparativeStatics.lean` | Yes | Yes | Yes | Existing exact canonical checks | N/A | No; dominance is strong and explicit. |
| T-24 | `manuscript/appendices/c_coverage_and_interactions.tex:37-48` | Finite coverage potential equals the date-by-date discounted occupation-gap sum. | theorem | S4; `Coverage/Potential.lean` | Yes | Yes | Yes | Exact occupation routines | N/A | No; gross fixed-candidate interpretation is explicit. |
| T-25 | `manuscript/appendices/c_coverage_and_interactions.tex:56-63` | Attained gap extrema times appropriate occupation give finite lower/upper bounds. | corollary | S4 | Yes | Yes | Yes | Exact fixture | N/A | No. |
| T-26 | `manuscript/appendices/c_coverage_and_interactions.tex:95-107` | Under stochastic monotonicity, increasing nonnegative gap/survival, nonnegative discount, and antitone cost, one-shot cost coverage is empty or an upper threshold. | theorem | S5; `Coverage/SingleGap.lean` | Yes | Yes | Yes | Exact counterexample and positive fixture | N/A | No; not called a Bellman policy region. |
| T-27 | `manuscript/appendices/c_coverage_and_interactions.tex:192-199` | One-shot coverage/cutoff moves in the stated directions with cost, survival, admission, and frontier. | theorem | S5/CS1 cutoff declarations | Yes | Yes | Yes | Exact regressions | N/A | No. |
| T-28 | `manuscript/appendices/c_coverage_and_interactions.tex:209-224` | Finite nonnegative coverage is monotone in discount/survival and has increasing differences in the two. | theorem | S6; `Coverage/DiscountSurvivalInteraction.lean` | Yes | Yes | Yes | Exact rational matrix fixture | N/A | No; no infinite-resolvent derivative is claimed. |
| T-29 | `manuscript/appendices/c_coverage_and_interactions.tex:243-257` | In the exact two-state family, greater scalar persistence can raise, lower, or leave coverage unchanged. | theorem / exact finite computation | S7; `Coverage/KernelComparativeStatics.lean` | Yes | Yes | Yes | 135-row exact response surface | N/A | No. |
| T-30 | `manuscript/appendices/c_coverage_and_interactions.tex:268-282` | Advantage-region discounted-occupation dominance implies larger finite coverage potential. | theorem | S7 | Yes | Yes | Yes | Exact response surface | N/A | No. |
| T-31 | `manuscript/appendices/c_coverage_and_interactions.tex:318-344` | On a realizable four-state rectangle, frontier-independent primitives, menu inclusion, and all-pairs relative saturation imply frontier-closure substitution. | theorem | T7; `Value/SystemInteraction.lean`; `Interaction/PrimitiveSubstitution.lean` | Yes | Yes | Yes | Exact four-corner fixtures | N/A | No; relative saturation is explicit. |
| T-32 | `manuscript/appendices/c_coverage_and_interactions.tex:350-374` | A common-gap, nonnegative-rich-exposure, zero-poor-exposure primitive structure implies relative saturation and substitution. | theorem | T7 primitive adapter | Yes | Yes | Yes | Exact canonical specialization | N/A | No. |
| T-33 | `manuscript/appendices/c_coverage_and_interactions.tex:432-450` | Frontier independence and individual saturation do not suffice; project switching produces exact complementarity `J=1/2`. | theorem / exact finite computation | T7 counterexample declarations | Yes | Yes | Yes | Exact fixture | N/A | No. |

### Numerical discussion and exact finite computations

| ID | Exact manuscript location | Claim text or concise paraphrase | Class | Supporting theorem/code/artifact | Human | Lean claimed | Lean exists | Julia | Timing | Overstatement |
|---|---|---|---|---|---|---|---|---|---|---|
| N-01 | `manuscript/sections/08_dynamic_research_control.tex:78-124` | The canonical benchmark is a raw-derived six-state, two-belief, three-library-state exact process with the displayed frontier, closure, project, timing, and joint-law structure. | exact finite computation | Canonical TOML; `solve_unified_canonical_benchmark.jl`; raw-law CSVs; canonical Lean fixture | N/A (computed) | Selected fixture certificates are Lean claimed | Yes for registered exact fixture declarations | Yes, authoritative exact rationals | N/A | No. |
| N-02 | `manuscript/sections/08_dynamic_research_control.tex:135-160` | The six exact stationary values, actions, and winning margins are as displayed; rational policy iteration has zero residual. | exact finite computation | Canonical summary/value/action artifacts; Lean fixture | N/A (computed) | Yes for canonical certificates | Yes | Yes | N/A | No. |
| N-03 | `manuscript/sections/08_dynamic_research_control.tex:163-201` | Complete eight-library enumeration yields the displayed minimum-safe libraries and burden reductions; the full source uniquely compresses to `I+D`. | exact finite computation | `run_unified_resource_benchmark.jl`; exact resource summaries | N/A (computed) | No additional Lean instance claim needed | Generic theorem exists; selected numeric optimum is Julia | Yes, exhaustive | N/A | No. |
| N-04 | `manuscript/sections/08_dynamic_research_control.tex:203-237` | The three capacity paths and listed exact switch prices are globally active and retain all ties. | exact finite computation | Resource optimizer exact correspondence and CSVs | N/A (computed) | No | Generic CAP/PEN exists | Yes, exhaustive eight-library enumeration | N/A | No. |
| N-05 | `manuscript/sections/08_dynamic_research_control.tex:240-267` | Only `I+D` and `I` are globally active at positive price; exact breakpoints and right-continuous minimum-burden selections are as displayed. | exact finite computation | Penalized branch/selection artifacts | N/A (computed) | No instance-specific claim | Generic PEN exists | Yes | N/A | No. |
| N-06 | `manuscript/sections/08_dynamic_research_control.tex:283-287` | At margin `1/16`, duration three, bridge elasticities are exactly `48,16,-15`, and no switch is differentiated through. | exact finite computation | BEM; registered elasticity rows | N/A (computed) | BEM generic formulas are claimed | Yes for BEM | Yes, instance | N/A | No. |
| N-07 | `manuscript/sections/08_dynamic_research_control.tex:289-301`; `manuscript/appendices/d_numerical_convergence.tex:29-107` | Float64 converges in 42 iterations with the displayed increment, residual, exact-error comparison and a-posteriori bound, selecting the same six actions. | numerical approximation | Canonical Float64 convergence CSV; solver residual checks | N/A | No | N/A | Yes, including error diagnostics | N/A | No. |
| N-08 | `manuscript/appendices/d_numerical_convergence.tex:100-107` | The implementation passes the listed raw/compressed transition, horizon-value/action, stationary-value/action, duration/path, and generated-table checks. | exact finite computation / numerical approximation | Canonical test suite and generated summaries | N/A | No | Canonical subset also Lean checked | Yes | N/A | No. |
| N-09 | `manuscript/appendices/d_numerical_convergence.tex:133-138` | The resource optimizer exhausts all eight libraries, retains ties, exactly recomputes all certificates, and does not use solver status as an exact certificate. | exact finite computation | Resource optimizer and tests | N/A | No | Generic finite claims only | Yes | N/A | No. |

### Exact fixtures and registered randomized experiment

| ID | Exact manuscript location | Claim text or concise paraphrase | Class | Supporting theorem/code/artifact | Human | Lean claimed | Lean exists | Julia | Timing | Overstatement |
|---|---|---|---|---|---|---|---|---|---|---|
| X-01 | `manuscript/sections/09_canonical_finite_model.tex:14-64` | The seven exact fixture outcomes are: canonical safe optimum `I+D`; greedy burden 4 versus global burden 3; normalized bridge loss 1; price tie at 1; capacity profile `0,0,1`; elasticities `48,16,-15`; channel sums close. | exact finite computation | Resource fixture registry; theorem-mechanism and elasticity scripts | N/A (computed) | Generic theorem counterparts are claimed where applicable | Yes except no general switching or CPEL claim is inferred | Yes, exact rational complete enumeration | N/A | No. |
| X-02 | `manuscript/sections/09_canonical_finite_model.tex:67-72` | Rechecking certifies only the greedy path; exhaustive comparison certifies the smaller endpoint; candidate crossings require global-envelope filtering; monotone capacity need not have decreasing increments. | interpretation / exact finite computation | OPT-T2T4; PEN; CAP; fixture registry | Yes for theorem parts | Yes | Yes | Yes | N/A | No. |
| R-01 | `manuscript/sections/09_canonical_finite_model.tex:74-82`; Appendix E lines 78-89 | The resource extension uses all registered `N=1024` exact trials from the frozen `2^7` factorial and all 4,096 distinct component seeds. | randomized synthetic evidence | D-0095--D-0098; D-0132--D-0133; registry/config; randomized scripts | N/A | No | N/A | Yes, registry audit | registered synthetic | No. |
| R-02 | `manuscript/sections/09_canonical_finite_model.tex:78-82,93-96` | Mean global safe-compression ratios are `31/160` by burden and `1/8` by cardinality; registered greedy mean/max gap is zero in `0/1024` positive cases. | randomized synthetic evidence | Randomized optimization exact summaries | N/A | No | N/A | Yes | registered synthetic | No; explicitly not a greedy-optimality theorem. |
| R-03 | `manuscript/sections/09_canonical_finite_model.tex:97-101` | Frontier-only loss is positive in `199/512`; normalized loss has the displayed mean, conditional mean, median zero, and exact maximum. | randomized synthetic evidence | Randomized optimization summary/artifacts | N/A | No | N/A | Yes, exact fractions authoritative | registered synthetic | No. |
| R-04 | `manuscript/sections/09_canonical_finite_model.tex:102-106,119-121` | Mean normalized capacity values follow the displayed path; grid nonconcavity occurs in `97/1024` and attainable-grid increasing increments in `921/1024`. | randomized synthetic evidence | Randomized capacity profiles | N/A | No | N/A | Yes | registered synthetic | No; frequencies are generator-specific. |
| R-05 | `manuscript/sections/09_canonical_finite_model.tex:107-109` | Mean total and positive resource-price breakpoint counts are `1043/256` and `787/256`. | randomized synthetic evidence | Exact globally active breakpoint summaries | N/A | No | N/A | Yes | registered synthetic | No. |
| R-06 | `manuscript/sections/09_canonical_finite_model.tex:126-145` | Across four price intervals, demand and productive-value arc elasticities have the displayed means and operational plus generative contributions close exactly before rendering. | randomized synthetic evidence | Randomized optimization price/channel CSVs; CPEL/CED arithmetic | N/A | No general CPEL Lean claim | CED algebra exists; CPEL generic adapter does not | Yes, exact trial-level arcs | registered synthetic | No; these are finite arcs, not derivatives. |
| R-07 | `manuscript/appendices/e_experiment_protocol.tex:153-177` | All raw witnesses/value equalities and zero safe-loss gates pass; the exact interaction counts are 256 substitution, 141 complementarity, 627 zero, and positive interaction occurs only where the stated independence conditions fail. | randomized synthetic evidence | Randomized v2 audit; 47,458 witness rows; exact interaction outputs | N/A | No | T1/T7 theorem boundaries exist | Yes | registered synthetic | No; factor slices are expressly noncausal. |
| R-08 | `manuscript/appendices/e_experiment_protocol.tex:179-223` | Registered cumulative counts, Wilson intervals, MCSEs, and sparse-event warnings have the displayed values; early prefixes never choose the final sample. | randomized synthetic evidence | Stability amendment and exact cumulative artifacts | N/A | No | N/A | Yes | registered synthetic | No; intervals are descriptive simulation diagnostics, not population inference. |
| R-09 | `manuscript/appendices/e_experiment_protocol.tex:250-282` | The frozen `N=90` pilot and `N=1024` v2 outcomes differ as displayed and are not pooled or read as a trend. | randomized synthetic evidence | Frozen pilot and v2 records | N/A | No | N/A | Yes | registered synthetic | No. |
| R-10 | `manuscript/appendices/e_experiment_protocol.tex:293-300` | The Float64 policy-map rows are converged, raw derived, positive duration, use `P_B^d`, and respect the operation flag. | numerical approximation | Unified comparative-statics scripts and residual gates | N/A | No | N/A | Yes | registered synthetic | No. |

### Retrospective financial audit

| ID | Exact manuscript location | Claim text or concise paraphrase | Class | Supporting theorem/code/artifact | Human | Lean claimed | Lean exists | Julia | Timing | Overstatement |
|---|---|---|---|---|---|---|---|---|---|---|
| F-01 | `manuscript/sections/10_financial_compression_audit.tex:5-13` | Terminal and annual source libraries contain `(80,38,1558)` and `(202,113,3508)` strategies/modules/burden; outcomes are revealed only after compression. | financial retrospective diagnostic | E1/E2 locked source summaries and information-set table | N/A | No | N/A | Yes, locked hashes | retrospective | No. |
| F-02 | `manuscript/sections/10_financial_compression_audit.tex:21-32` | Stepwise, reported global min-cardinality, reported global min-weight, and frontier-only libraries have the displayed cardinalities and burdens. | financial retrospective diagnostic | Financial resource optimization summaries; exact vector/burden/frontier/closure verifier | N/A | No | N/A | Yes; exact selected-vector rechecks plus numerical HiGHS status | retrospective | No; “reported global optimum” is explicitly numerical evidence. |
| F-03 | `manuscript/sections/10_financial_compression_audit.tex:36-46` | Solver reports stepwise endpoints attain minimum cardinality; minimum-weight alternatives reduce burden by the displayed amounts/percentages while all safe libraries preserve frontier, closure, and ex post opportunity quality. | financial retrospective diagnostic | Financial MILP records and exact post-solve certificates | N/A | No | N/A | Yes | retrospective | No; solver and exact-certificate roles are separated. |
| F-04 | `manuscript/sections/10_financial_compression_audit.tex:48-54` | Frontier-only retains 3/5 strategies and 12/38 or 14/113 modules; the ex post diagnostic falls by 0.0016/0.1020 and the best enabled held-out opportunity is lost in both audits. | financial retrospective diagnostic | E1/E2 aggregate opportunity-quality artifacts | N/A | No | N/A | Yes | retrospective | No; outcome timing and distinct units are stated. |
| F-05 | `manuscript/sections/10_financial_compression_audit.tex:59-64` | Safe pruning preserves closure and ex post enabled-descendant opportunity quality; the diagnostic is not a pruning input, forecast, or policy score. | financial retrospective diagnostic | Exact closure certificates and information-set audit | N/A | No | N/A | Yes | retrospective | No. |
| F-06 | `manuscript/sections/10_financial_compression_audit.tex:69-76`; `manuscript/appendices/e_financial_information_audit.tex:127-133` | Coverage ranking is adverse in the terminal audit and mixed/noisy annually, with the displayed utilities, correlations, coverage, and regret; it identifies neither expected return nor alpha. | financial retrospective diagnostic | Locked secondary financial summaries | N/A | No | N/A | Yes | retrospective | No; adverse and mixed results remain visible. |
| F-07 | `manuscript/appendices/e_financial_information_audit.tex:47-71` | `Q_a` is evaluated only after decisions and is neither forecast, policy score, nor deployable criterion; safe/frontier pruning never sees it. | financial retrospective diagnostic | Information-set definitions and hashes | N/A | No | N/A | Yes | retrospective | No. |
| F-08 | `manuscript/appendices/e_financial_information_audit.tex:83-108` | Both audits preserve the validation frontier; only safe pruning preserves full identity closure, and each safe library has one positive ex post generative carrier with the displayed contributions. | financial retrospective diagnostic | Exact frontier/closure and contribution summaries | N/A | No | N/A | Yes | retrospective | No; the two-carrier sample is called descriptive. |
| F-09 | `manuscript/appendices/e_experiment_protocol.tex:391-400,482-489` | The target outcome and greedy oracle are post-decision/infeasible diagnostics; neither is a deployable selection rule. | financial retrospective diagnostic | Locked design and information-set classification | N/A | No | N/A | Yes | retrospective | No. |
| F-10 | `manuscript/appendices/e_experiment_protocol.tex:303-317`; `manuscript/appendices/e_financial_information_audit.tex:12-16` | The audits share a licensed CRSP/WRDS snapshot; the terminal design fixes 25 date-valid ETFs and 2,400 strategies, the annual design fixes 100 ETFs and 9,600 strategies, and neither universe is survivorship-free nor either holdout prospective. | financial retrospective diagnostic | Locked terminal and annual design/config/provenance records | N/A | No | N/A | Yes, design hashes | retrospective | No; the two material data limitations are explicit. |
| F-11 | `manuscript/appendices/e_experiment_protocol.tex:336-365`; `manuscript/appendices/e_financial_information_audit.tex:111-133` | Coverage scores are validation/pre-target, post-compression ranking inputs rather than pruning inputs; selected sets are hashed before held-out outcomes; rank associations, intervals, and oracle regret are retrospective. | financial retrospective diagnostic | Empirical information-set audit; decision hashes; secondary audit artifacts | N/A | No | N/A | Yes | retrospective | No in the appendix. B-01 records that this locked clarification is missing from the main financial section. |

### Conclusion

| ID | Exact manuscript location | Claim text or concise paraphrase | Class | Supporting theorem/code/artifact | Human | Lean claimed | Lean exists | Julia | Timing | Overstatement |
|---|---|---|---|---|---|---|---|---|---|---|
| K-01 | `manuscript/sections/11_limitations_conclusion.tex:5-13` | A strategy can improve the current action frontier and carry modules for descendants, so frontier-only compression can discard inventive capacity. | interpretation | Model; T4 bridge construction | N/A | No | Exact construction exists | Yes | N/A | No. |
| K-02 | `manuscript/sections/11_limitations_conclusion.tex:15-26` | Exact safe compression globally minimizes burden in a projection fiber; safe deletion is local; irreducibility and global optimality differ; order/search can matter. | theorem / interpretation | T1; OPT-FND; T3; OPT-T2T4 | Yes | Yes | Yes | Yes | N/A | No. |
| K-03 | `manuscript/sections/11_limitations_conclusion.tex:28-34` | Frontier-only compression can preserve current actions but destroy all attainable descendant bridge value, so current payoff equivalence is not innovation safety. | theorem / interpretation | T4 | Yes | Yes | Yes | Yes | N/A | No. |
| K-04 | `manuscript/sections/11_limitations_conclusion.tex:36-41` | Capacity and price changes switch finite optimal libraries at discrete breakpoints, and selected raw libraries need not be nested. | theorem / exact finite computation | CAP; PEN; exact nonnested PEN fixture | Yes | Lean claimed for steps/burden order, not raw nonnesting | Yes for steps/burden order; nonnesting is exact Julia counterexample | Yes | N/A | No; “need not” is supported by a counterexample. |
| K-05 | `manuscript/sections/11_limitations_conclusion.tex:46-55` | Duration/channel elasticities describe within-fixed-library sensitivity; contributions/finite changes replace elasticity at zero or switching thresholds. | interpretation | BEM; CED; IDCV; PEN; registered exact diagnostics | Yes for the fixed-branch algebra | Partly | Yes for the fixed-branch cores; no general switching claim is made | Exact diagnostics | N/A | No; denominator and switch qualifications are explicit. |
| K-06 | `manuscript/sections/11_limitations_conclusion.tex:57-62` | The three evidence layers illustrate mechanisms; financial comparisons expose the retrospective tradeoff and make no causal, forecasting, or alpha claim. | interpretation / financial retrospective diagnostic | Exact fixtures, registered random study, E1/E2 | N/A | No | N/A | Yes | retrospective | No. |
| K-07 | `manuscript/sections/11_limitations_conclusion.tex:63-68` | Approximate compression, endogenous information processing, continuous beliefs, and endogenous verification are future extensions. | conjecture/future work | None claimed | No claim of completed proof | No | No | No | prospective future work only | No; clearly labeled as extensions. |

## Cross-cutting special-attention verdicts

### Global optimality

The mathematical global-minimum existence and local/global separation claims
are human complete, Lean verified, and exactly exercised. The financial word
“global” is always attributed to the mixed-integer solver; exact post-solve
checks certify feasibility and objective reconciliation but are not passed off
as a proof of solver globality. No greedy approximation guarantee is claimed.

### Capacity concavity and nonconcavity

Attainment, monotonicity, attainable-burden constancy, finite breakpoints, and
nonnegative discrete shadows have exact Lean counterparts. The `(0,0,1)`
complementarity witness is also kernel checked. The release issue is semantic:
the manuscript calls this ordinary nonconcavity inside a Lean-complete theorem,
while the named formal statement proves failure of diminishing discrete unit
increments and D-0128 explicitly distinguishes it from ordinary real
concavity. This is M-01, not a false numerical result.

### Resource-price envelopes

The manuscript correctly distinguishes pairwise intersection candidates from
globally active breakpoints, retains optimizer ties, states burden antitonicity
for every cross-price optimizer pair, and limits slope claims to locally active
branches. It does not claim that all candidates are kinks, that optimizers are
unique, that libraries are inclusion nested, or that the envelope is
differentiable at ties.

### Elasticity and switching

BEM and CED have exact Lean real-calculus cores with the necessary positive
margin/denominator and common-path qualifications. IDCV has exact scaled
derivative and variance declarations, but the displayed log-composition form
needs the M-02 reconciliation. CPEL is not presented as a completed general
theorem. Resource-demand values are exact finite arcs; switch locations in
primitive grids are brackets rather than exact roots. Under D-0139, general
set-valued switching theory is outside the current claim package and appears
only as future work.

### Descendant quality and financial usefulness

Every held-out descendant-quality statement is retrospective, evaluated after
the compression decision, and absent from pruning objectives and constraints.
The paper claims preservation or loss of access to realized opportunities in
two audits, not expected returns, forecasting skill, deployability, causal
effects, population frequencies, or alpha. The adverse terminal ranking result
and mixed annual ranking result remain visible.

## Validation executed for this audit

| Check | Result |
|---|---|
| Start-of-run Git status/diff | Clean on `codex/optimization-revision` at `48b8bcaa0244f62769fdd4522e2632f394ca6c62`. |
| Prohibited Lean marker scan | Passed through `make verify`: no `sorry`, `admit`, user `axiom`, or proof-critical `unsafe`. |
| `cd formal && lake clean && lake build` | Passed; 3,212 jobs. The subsequent non-clean build in the full gate also passed. |
| Full Julia/package/artifact/manuscript gate | **Failed.** The package suite reached the financial presentation test with 93/95 assertions passing and the two B-01 assertions failing. Because the script is fail-fast, later checks were run separately where claim-relevant. |
| Theorem-mechanism artifact check | **Failed.** `theorem_mechanism_metadata.json` drifts because its recorded Julia manifest hash is stale (B-02). |
| Exact fixture bridge | Passed; 18 fixtures and zero file changes. |
| Canonical resource benchmark | Passed; 3 schedules, 24 safe problems, 30 capacity rows, and 24 penalized cells are current. |
| Registered elasticity/switching experiment | Passed; 45 bridge, 25 duration, 75 robustness, and 118 Bellman rows are current. |
| Registered randomized optimization extension | Passed all 1,024 trials; artifacts and pre-outcome lock are current. |
| Generated manuscript numerical/financial presentation artifacts | Passed for the checked tables and figures. |
| Financial resource design/output certificates | Passed; design lock current and all 40 parent artifact hashes rechecked. |
| `manuscript/build.sh` | Passed after the D-0139 scope revision; BibTeX and pdfLaTeX produced a 63-page PDF. No undefined-reference, citation, missing-file, overfull/underfull-box, or duplicate-label warning appears in the final log. The ignored rebuilt `main.pdf` has SHA-256 `302822555a5c047f678a194154243e2a2505ec6b806c5636489d63d7f6979030`; its layout-text hash is `7e29ace05a8c70c53d7e18a67719b4526d722d8fd68b0fae3167e239c0e3b95b`. |

The D-0139 scope revision changes only switching-scope manuscript prose,
Appendix F, and governance/roadmap classification.  It changes no theorem
environment, Lean or Julia source, locked experiment, figure, table, or result
artifact.

## Unresolved release issues

1. Repair B-01 by reconciling the two locked financial-presentation assertions
   with the intended main-text information-set wording; do not weaken the test
   silently.
2. Repair B-02 by regenerating and reviewing the theorem-mechanism provenance
   metadata against the current pinned Julia manifest, confirming that no
   substantive result artifact changes.
3. Reconcile M-01: either formalize ordinary real nonconcavity of the capacity
   step function or narrow the Lean-facing claim to failure of diminishing
   discrete capacity increments.
4. Reconcile M-02: state the Lean-verified scaled derivative identities in the
   display or add the exact log-composition declarations.
5. Restate the CED neighborhood identity in the proposition for a completely
   self-contained manuscript/Lean assumption match.
6. Update stale BEM/CED/IDCV status lines in `ASSUMPTIONS.md` after substantive
   editing is authorized.
7. Keep canonical `D_beta` and all switching/resource arcs labeled as exact
   fixed-policy/finite-instance diagnostics, not general Lean theorems.
