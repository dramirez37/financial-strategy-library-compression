# Skeptical combinatorial-optimization referee report

**Manuscript:** *Innovation-Safe Compression of Financial Strategy Libraries under Partial Information: Complexity, Algorithms, and Financial Evidence*  
**Journal:** *Annals of Operations Research*  
**Review date:** 2026-08-27  
**Recommendation:** **MAJOR REVISION, bordering on reject-and-resubmit.** If the editorial process cannot accommodate a new preregistered computational run, the defensible recommendation is reject and invite resubmission.

## Materials reviewed

I reviewed the compiled 38-page article at
`journal/aor/manuscript/build/aor-journal-manuscript.pdf`, the compiled 97-page
Online Resource 1 at
`journal/aor/online_resource/build/aor-online-resource-1.pdf`, their LaTeX
sources, `THEOREM_LEDGER.md`, the tagged-cover, preprocessing, exact-DP,
greedy, deletion, MIP, audit, and generator implementations under `julia/`, the
v2 design and analysis records under
`experiments/algorithmic_compression_v2/`, the preserved incomplete v1 record,
the committed v2 results and result audit, and the public financial-algorithm
and weight-robustness records.

This is a validity and contribution review, not a code-style review. I treated
human proof, Lean kernel verification, exact finite computation, Julia tests,
mixed-integer solver evidence, synthetic evidence, and retrospective financial
evidence as distinct evidence classes.

## Bottom line

The central finite combinatorial mathematics is mostly correct. I found no
fatal error in the tagged-cover equivalence, the restricted NP-completeness
proof, the weighted-greedy transfer, the requirement-mask DP recurrence, the
preprocessing rules, or the heaviest-safe-first counterexample. The repository
also distinguishes exact rechecking from a solver's `OPTIMAL` status unusually
well.

That is not enough for acceptance. The identity-closure optimization problem is
weighted set cover after the tagged representation; the NP-completeness,
greedy, DP, and covering-preprocessing components are consequently standard or
near-standard. The paper must earn its contribution through the dynamic
frontier--closure semantics and through convincing computational and financial
evidence. At present, the projection theorem assumes the decisive
library-invariance factorization, while the registered benchmark has four
serious design defects: cold Julia compilation is inside the timing estimand,
the performance profile compares different success criteria, sixteen
structured cells are deterministically ungeneratable, and most generated
structured cases collapse to an empty residual under preprocessing. The
prespecified regression analysis also treats repeated algorithm observations
on an instance as independent when applying HC3 standard errors. These defects
invalidate the strongest runtime, scaling, and structural-driver claims.

The two financial cases are useful audited demonstrations, but they are not a
broad financial algorithm comparison: both reduce to an empty residual model,
their weights are auditable proxies rather than measured resource costs, and
closure preservation makes the common postdecision diagnostic equality
mechanical. The current paper is therefore too broad for the strength of its
evidence.

## Answers to the requested referee questions

| No. | Question | Referee assessment |
|---:|---|---|
| 1 | Is this merely a relabeled weighted set-cover application? | **Not entirely, but too close in its current presentation.** Once identity closure and the tagged universe are imposed, the optimization layer is exactly weighted set cover. The only potentially distinctive foundation is the dynamic reason for preserving both tags; that foundation is currently conditional on a strong factorization assumption. See OR-01 and OR-02. |
| 2 | Does the frontier--closure projection create a genuine semantic contribution? | **Potentially, not yet convincingly.** The local compressed update and semi-Markov timing are meaningful, but the theorem assumes that every relevant primitive already factors through the proposed state. The paper needs primitive sufficient conditions or a sharper operational derivation. See OR-01. |
| 3 | Is the NP-completeness proof correct and necessary? | **Correct and useful as a boundary, but standard.** Membership, encoding, construction size, threshold preservation, and the full-union normalization are handled correctly. It should remain, but it cannot carry the novelty claim. |
| 4 | Is the approximation guarantee stated correctly? | **Yes.** Under positive weights and identity closure, the residual weighted-greedy guarantee is the harmonic bound using the maximum residual set size; mandatory cost is added back, and reverse deletion cannot increase burden. The manuscript correctly refuses to transfer the guarantee to arbitrary closure. |
| 5 | Is the unbounded deletion-gap theorem correct? | **Yes.** The ratio is (k/(1+\varepsilon)); the bundle is uniquely heaviest, its deletion leaves an inclusion-wise irreducible singleton library, and the result concerns the specified heaviest-safe-first rule, not all deletion orders. |
| 6 | Are the preprocessing propositions valid? | **Yes under the stated pure-cover assumptions.** Forced carriers, dominance, duplicate columns, empty columns, duplicate rows, and fixed-point propagation preserve the claimed objects. The paper generally distinguishes preservation of an optimum from preservation of all optimizer identities. |
| 7 | Is the DP complexity statement accurate? | **Yes.** The recurrence takes (O(n2^r)) mask transitions, with (O(2^r)) value memory or reconstruction-aware additional memory. It is FPT in (r), not polynomial in the full input size. |
| 8 | Are algorithms compared fairly? | **No for runtime; mostly yes for certified burden.** Cold compilation dominates many recorded times, the performance profile gives heuristics and exact methods different success conditions, and two named deletion methods are identical. See OR-03, OR-04, and OR-10. |
| 9 | Are exact and solver claims distinguished? | **Yes.** The manuscript, ledger, and audit consistently label HiGHS `OPTIMAL` as solver evidence plus exact post-check, not exhaustive or formal proof. Lean is not claimed for NP-completeness or the external greedy theorem. This is a strength. |
| 10 | Does the computational experiment follow OR standards? | **Not yet.** Registration, immutable failure records, exact certificates, hashes, and explicit evidence classes are strong. The timing, generator feasibility, instance difficulty, and dependence problems are nevertheless central failures. See OR-03--OR-07. |
| 11 | Are the generators too tailored to favorable conclusions? | **There is no evidence of outcome tuning, but the realized design is structurally favorable to preprocessing.** Median structured reductions are complete in every size cell, and some requested cells are impossible by construction. This is inadequate coverage of difficult residual cover problems. See OR-05 and OR-06. |
| 12 | Are baselines missing? | **A relevant local-search and lower-bound baseline is missing.** The existing exact, MIP, greedy, deletion, and multi-start grid is broad, but a certified exchange neighborhood or LP-relaxation baseline would clarify whether the deletion gap is specific to one-deletion local optimality. A second open-source solver would be useful but is not mandatory. See OR-12. |
| 13 | Are timed-out runs handled correctly? | **Yes in principle, but no timeout occurred.** All unsuccessful records remain in the denominators and the timeout-bound table is correctly empty. The study therefore provides no empirical evidence about timeout incumbent or bound behavior. |
| 14 | Are the financial cases operationally meaningful? | **As two audited workflow demonstrations, yes; as general evidence, no.** Both residual problems are empty after exact preprocessing, the cost schedules are proxies, and the held-out equality for safe endpoints follows from closure equality. See OR-08. |
| 15 | Is the paper too broad? | **Yes.** The main paper combines a projection theorem, covering complexity and algorithms, a large economic-results section, two generations of synthetic studies, and two financial audits. The coherent OR paper is buried inside this scope. See OR-09. |
| 16 | Are the contributions significant enough for AoOR? | **Borderline and not sufficient in the present version.** They could become sufficient if the semantic reduction is derived rather than assumed, the paper is narrowed, and a new valid benchmark demonstrates nontrivial residual optimization. Without those revisions, this is a careful set-cover application with an overextended evidence package. |

## Mathematical and algorithmic validity audit

### Results I regard as established

- **Tagged-cover equivalence.** The theorem in
  `journal/aor/manuscript/04_cover_complexity.tex` correctly uses a disjoint
  frontier/module tag universe. Frontier ties, zero-frontier beliefs, mandatory
  inactivity, and multiply carried modules are handled. The theorem is an exact
  equivalence only for identity closure.
- **NP-completeness.** The restricted zero-profile, one-belief,
  identity-closure subclass is correctly shown NP-complete. The source problem
  normalization and excluded stronger claims are recorded at
  `THEOREM_LEDGER.md:620-690`. This is a human complexity proof, not a Lean
  theorem.
- **Greedy approximation.** The transferred weighted-cover guarantee uses
  positive costs and residual maximum set size. Mandatory selections and
  reverse deletion are treated correctly. The guarantee is not claimed for
  arbitrary closure.
- **Worst-case deletion gap.** The bundle-versus-singleton construction proves
  the asserted unbounded ratio for heaviest-safe-first. It does not prove a gap
  for every deletion order or for every inclusion-wise irreducible endpoint.
- **Preprocessing.** The propositions are correct for the exact tagged-cover
  model without additional identity-sensitive side constraints. The
  reconstruction audit is essential because dominance and duplicate-column
  elimination preserve at least one optimum, not all optimizer identities.
- **Exact DP and enumeration.** The recurrence, exact burden comparison,
  deterministic reconstruction, and (O(n2^r)) recurrence count are correct.
- **Deletion feasibility.** The implementation recomputes safety after accepted
  deletions and performs a final irreducibility scan. Feasibility is proved and
  exactly checked; approximation quality is not inferred from that invariant.

### Evidence classification is mostly disciplined

The result audit at
`experiments/algorithmic_compression_v2/RESULT_AUDIT.md:5-22` rechecks 3,526
returned libraries and records zero audit errors. Lines 24--40 retain 381
unsuccessful results in their status categories and explicitly refuse to turn
HiGHS `OPTIMAL` into formal or exhaustive proof. The theorem ledger likewise
does not call NP-completeness or the classical approximation theorem Lean
verified. These distinctions should be preserved.

## Classified objections

### OR-01 — The semantic projection is obtained by assuming the conclusion's factorization

**Severity:** **MAJOR**  
**Exact location:** `journal/aor/manuscript/03_model_projection.tex:119-160`,
especially Assumption 1 at lines 124--130 and the proof sketch at lines
150--157; Online Resource 1, `sections/01_probability_normalization.tex` and
`sections/02_productive_equivalence.tex`, especially the detectability-based
converse.  
**Why a referee would object:** The manuscript claims a dynamic semantic
reduction, but it assumes that generation and verification depend on the raw
library only through closure and that every other relevant primitive depends
only through the proposed frontier--closure state. The projection then follows
by a standard lumpability/factorization argument. The converse is similarly
made true through a detectability condition that names closure differences.
This is not false, but it is weaker and more conditional than the paper's
contribution language suggests.  
**Required evidence or revision:** Give primitive, operationally checkable
conditions under which the factorization follows from the research process, or
state plainly that the result is a representation theorem conditional on a
declared information architecture. Provide at least one nontrivial model class
where those primitive conditions are verified and one countermodel where the
projection fails. Do not call (K_L) minimal unless a genuine minimality theorem
is proved.  
**Change surface:** theory and prose.

### OR-02 — Most of the optimization contribution is standard weighted set cover

**Severity:** **MAJOR**  
**Exact location:** `journal/aor/manuscript/04_cover_complexity.tex` and
`05_algorithms.tex`; contribution claims in `01_introduction.tex`; theorem
entries SC-TAG, SC-COMP, SC-DP, and SC-GREEDY in `THEOREM_LEDGER.md`.  
**Why a referee would object:** After the tagged equivalence, the MIP, DP,
weighted greedy bound, column dominance, duplicate rows/columns, and forced-row
propagation are standard covering machinery. The NP-completeness reduction is
correct but immediate. Packaging these results carefully does not make them new
combinatorial-optimization theory.  
**Required evidence or revision:** Reallocate novelty explicitly: semantic
modeling and the preservation object may be new; set cover and its classical
algorithms are not. Identify the genuinely nonstandard theorem or algorithmic
consequence produced by frontier--closure structure. If none exists, narrow the
paper and present the covering layer as a rigorous computational reduction and
implementation contribution.  
**Change surface:** theory positioning and prose; possibly new theory.

### OR-03 — Recorded runtimes are dominated by first-call Julia compilation

**Severity:** **MAJOR**  
**Exact location:**
`julia/scripts/run_algorithmic_compression_final_worker_v1.jl:491-520`; the
worker performs no algorithm-specific warm-up before `@timed _execute`.
Representative committed records are
`results/raw_runs/V2-B-N064-R064-C01-X01/jump_highs_tagged_cover__mandatory_only.toml:37-59`
and
`weighted_greedy__full_fixed_point_then_reconstruct.toml:35-52`. The former
records 1.629 s of compilation inside 1.655 s of algorithm time; the latter
records 3.852 s inside 3.890 s. The analysis script contains no compilation-time
adjustment. Runtime claims appear at
`journal/aor/manuscript/07_computational_study.tex:71-94` and 124--131.  
**Why a referee would object:** These data measure cold process startup and JIT
specialization far more than algorithm execution for many cells. The resulting
profiles, scaling summaries, and preprocessing-runtime comparison cannot be
interpreted as algorithm performance. Full preprocessing induces different
specializations and is especially penalized.  
**Required evidence or revision:** Run a new, prospectively locked timing study
with explicit warm-up outside the measured region, or use a reproducible
precompiled system image and document it. Record compile time separately and
take repeated steady-state measurements with a declared aggregation rule. The
current locked results may remain as cold-start latency evidence, but the
manuscript must not use them for algorithmic runtime rankings or scaling.
Changing the analysis of the existing locked data cannot recover an unobserved
steady-state timing estimand.  
**Change surface:** experiments, code, and prose.

### OR-04 — The performance profile compares methods solving different problems

**Severity:** **MAJOR**  
**Exact location:**
`experiments/algorithmic_compression_v1/ANALYSIS_PLAN.md:102-114`,
`julia/scripts/analyze_algorithmic_compression_v2.jl:1579-1600`, and
`journal/aor/figures/performance_profile.svg`. The common `solved` field is
defined at `journal/aor/reports/ALGORITHMIC_RESULTS.md:63-67`: a heuristic needs
only an exactly feasible candidate, while exact methods must complete search.  
**Why a referee would object:** A Dolan--Moré-style ratio is meaningful only
when methods are compared on the same success target. Here a fast feasible
heuristic competes against an exact proof of optimality. The denominator can
therefore reward a lower-quality solution and cannot support an exact-solver
performance conclusion.  
**Required evidence or revision:** Separate feasibility-construction profiles
from exact-optimization profiles, or define a quality-qualified target such as
reaching a specified certified relative gap. Never pool a feasible heuristic
and a completed exact solve under one unqualified `solved` criterion. Treat any
new profile definition as a new or explicitly exploratory analysis.  
**Change surface:** analysis code, figures, and prose; likely experiment design.

### OR-05 — Sixteen structured registry cells are deterministically impossible

**Severity:** **MAJOR**  
**Exact location:** v2 registry rows for C09 and C13, e.g.
`experiments/algorithmic_compression_v2/registry/INSTANCE_REGISTRY.csv:56-57,
64-65,88-89,96-97,120-121,128-129,152-153,160-161`;
`julia/src/AlgorithmicCompressionGenerators.jl:574-639`; example failure record
`results/generation/V2-B-N064-R032-C09-X01.toml:1-80`; census at
`RESULT_AUDIT.md:24-35`.  
**Why a referee would object:** The bundle construction fills every nonunique
row in all bundle columns and then enforces at least two carriers per remaining
row. For the registered one-eighth density/bundle combinations, this lower
bound already exceeds the target incidence count. All 128 attempts therefore
fail with the same structural reason. The 352 failed run units are not random
failures; complete factor combinations are absent.  
**Required evidence or revision:** Supply a mathematical feasibility audit for
every requested factor cell before locking a replacement design. Either use a
new feasible registered grid or limit claims to the realized, aliased design.
Report which effects and interactions are not estimable because whole cells are
missing. Retaining failed rows in denominators is correct but does not cure the
design defect.  
**Change surface:** generators, experimental design, statistical analysis, and
prose.

### OR-06 — The structured benchmark mostly tests preprocessing certificates, not hard covering

**Severity:** **MAJOR**  
**Exact location:** `journal/aor/tables/preprocessing_summary.csv:11-14` and
`journal/aor/manuscript/07_computational_study.tex:124-131`. In every structured
size cell, median variable and requirement reduction is 1.0; mean variable
reduction ranges from 0.8968 to 0.9859. The result census contains 106
`SOLVED_BY_EXACT_PREPROCESSING` records (`RESULT_AUDIT.md:24-35`).  
**Why a referee would object:** A benchmark advertised as identifying scaling
and structural difficulty should leave substantial residual search in a
meaningful fraction of cases. Here the principal empirical finding is that the
generator produces abundant forced structure. Small node counts and absence of
timeouts then say little about MIP or DP scalability on nontrivial safe-
compression instances.  
**Required evidence or revision:** Add a new registered family conditioned on a
nonempty residual after preprocessing, with graded residual requirement counts,
LP gaps, symmetry, and overlap. Keep the current study as evidence about
preprocessing prevalence only. Remove or sharply narrow general scaling and
hardness language until such evidence exists.  
**Change surface:** experimental design, generators, experiments, and prose.

### OR-07 — Prespecified HC3 regressions ignore within-instance dependence

**Severity:** **MAJOR**  
**Exact location:**
`experiments/algorithmic_compression_v1/ANALYSIS_PLAN.md:116-151`;
`julia/scripts/analyze_algorithmic_compression_v2.jl:1265-1355`; diagnostics at
`journal/aor/tables/registered_model_diagnostics.csv:2-24`. The joint Family B
gap fit uses 1,096 algorithm rows from the same 111 reference-available
instances, and runtime/solved models likewise repeat each instance across
algorithms and preprocessing variants.  
**Why a referee would object:** HC3 handles heteroskedasticity, not correlation
among repeated observations on the same generated instance. Standard errors,
multiplicity-adjusted probabilities, and structural-driver statements are
therefore not calibrated for the design. The duplicate heaviest/release method
adds exact duplicated outcomes, and missing entire generator cells further
undermines interpretation.  
**Required evidence or revision:** Use instance-clustered uncertainty, an
instance/block effect, or paired within-instance contrasts consistent with the
declared experimental unit. Publish an estimability and alias audit. Because
the registered analysis fixed HC3, label any corrected model exploratory unless
it is part of a new prospectively locked analysis. The finite-design descriptive
tables may remain.  
**Change surface:** statistical analysis and prose.

### OR-08 — The financial evidence is too narrow to support a broad algorithmic claim

**Severity:** **MAJOR**  
**Exact location:**
`journal/aor/reports/FINANCIAL_ALGORITHM_RESULTS.md:13-20,22-59,61-100` and
`journal/aor/manuscript/08_financial_case_studies.tex:33-42,46-67,71-127`.
The terminal instance has 80 active strategies and reduces from 81 variables to
zero; the annual instance has 202 active strategies and reduces from 203 to
zero.  
**Why a referee would object:** Both financial optima are certified by forced
selection and propagation without residual search. The validation-computation
and documented-complexity schedules are rule-based proxies, not observed money,
staff hours, or governance effort. Equality of the held-out enabled-descendant
diagnostic across safe solutions follows mechanically from exact closure
preservation and is not independent empirical validation. Two instances cannot
establish general financial algorithm performance or managerial savings.  
**Required evidence or revision:** Reframe these as two retrospective audited
case demonstrations. Calibrate at least one burden measure to observable
resource consumption if a managerial cost claim is retained, or use explicit
scenario units without implying realized savings. Add further independently
defined source libraries with nonempty residual covers if permitted; otherwise
make the limited external validity unmistakable. Preserve separate terminal
and annual units and the no-alpha/no-forecasting boundary.  
**Change surface:** financial experiment and prose.

### OR-09 — The article is overextended

**Severity:** **MAJOR**  
**Exact location:** the 38-page main article, especially Sections 6--8, plus the
97-page Online Resource. Section 6 contains bridge loss, hard-capacity geometry,
resource-price envelopes, and complementarity alongside the dynamic reduction,
covering theory, benchmark, frozen preprint study, and financial cases.  
**Why a referee would object:** The paper reads as several papers joined
together. The broad economic theory is not needed to establish the cover model,
and the frozen (N=1024) study competes with the new algorithmic benchmark for
attention. Breadth magnifies the novelty problem because no one component is
developed deeply enough to dominate.  
**Required evidence or revision:** Center the main article on (i) the semantic
preservation state, (ii) the tagged optimization reduction and limits, and
(iii) one credible computational/financial evaluation. Move secondary economic
comparative statics and the legacy randomized study to the Online Resource or
repository and reduce the main contribution list accordingly.  
**Change surface:** manuscript architecture and prose.

### OR-10 — Two benchmark “algorithms” are mathematically and computationally identical

**Severity:** **MODERATE**  
**Exact location:** `journal/aor/manuscript/05_algorithms.tex:226-243` admits
that maximum immediate burden release equals heaviest-safe-first under additive
burden; `julia/src/CertifiedDeletionJournalCompression.jl:238-255` dispatches
both symbols through the same sort key. They nevertheless appear as separate
rows in `journal/aor/reports/ALGORITHMIC_RESULTS.md:27-53` and as separate
regression categories in `registered_model_diagnostics.csv:5,7`.  
**Why a referee would object:** Duplicating an algorithm inflates the method
grid, creates redundant comparisons, and makes cold-runtime noise look like
method variation. It also worsens the dependence problem in the joint model.  
**Required evidence or revision:** Treat the second name as an alias, report one
row, and remove it as an independent statistical category. Preserve the API
alias if useful, but not as a distinct scientific baseline.  
**Change surface:** analysis and prose; code documentation only.

### OR-11 — The exact-capable registry overstates enumeration applicability

**Severity:** **MODERATE**  
**Exact location:**
`journal/aor/tables/exact_method_agreement.csv:27,30,33,35,37,39` and
`RESULT_AUDIT.md:16-18`. Six adversarial rows marked for exact comparison report
enumeration `IMPLEMENTATION_ERROR` because the residual optional count exceeds
the declared enumeration limit, while DP and both MIPs solve.  
**Why a referee would object:** This is not a mysterious computational failure;
it is a registry/applicability mismatch. Calling all 38 instances
“exact-capable” obscures that only 31 furnished the registered all-method check
and that six comparison jobs were infeasible by declared policy before launch.  
**Required evidence or revision:** Reclassify these rows as enumeration not
applicable under the locked limit, distinguish policy inapplicability from
implementation error, and report method-specific exact-capable denominators. A
future registry should validate applicability against limits before locking.  
**Change surface:** schema/reporting code and prose; no theorem change.

### OR-12 — Missing baselines leave the local/global narrative incomplete

**Severity:** **MODERATE**  
**Exact location:** algorithm grid in
`journal/aor/manuscript/07_computational_study.tex:30-37` and Section 5.  
**Why a referee would object:** The paper proves that one-deletion
irreducibility can be arbitrarily poor but compares no certified exchange
neighborhood that can undo a bundle/singleton mistake. It also reports no LP
relaxation lower-bound diagnostic, which is a natural set-cover benchmark. A
second solver is absent, though transparently so.  
**Required evidence or revision:** Add a precisely defined certified 1-for-
many or bounded exchange improvement baseline and an LP-relaxation/bound
diagnostic in a new registered comparison, or explain why they are out of
scope. A second open-source solver is desirable for medium cases but should not
be made a proprietary requirement.  
**Change surface:** algorithms, experiment, and prose.

### OR-13 — Runtime reproducibility is conditional and not precise enough for ranking

**Severity:** **MODERATE**  
**Exact location:**
`experiments/algorithmic_compression_v2/EXECUTION_RECORD.md:10-45` and
`journal/aor/manuscript/07_computational_study.tex:39-49`. The run used eight
concurrent isolated one-thread processes, one observation per run unit, and a
dirty worktree.  
**Why a referee would object:** Fixed lanes and complete provenance make the run
auditable, but concurrent co-runners create varying cache and memory-bandwidth
contention. A single cold measurement cannot distinguish algorithm differences
from launch-wave and compilation variation. The dirty execution tree weakens
source-to-result reproducibility even though its status hash is recorded.  
**Required evidence or revision:** After fixing OR-03, use a clean committed
tree, repeated randomized/blocked runs or declared medians, and record both
isolated steady-state and concurrent-throughput estimands if throughput matters.
Do not rank close methods from the present timings.  
**Change surface:** experiment and prose.

### OR-14 — “Prospective” needs a complete chronology disclosure

**Severity:** **MODERATE**  
**Exact location:**
`experiments/algorithmic_compression_v1/INCOMPLETE_EXECUTION_NOTICE.md:3-17`
versus Online Resource 1,
`sections/12_registered_algorithmic_benchmark_v2.tex:4-10`. V1 was stopped after
1,634 of 3,907 terminal records and 68 generated instances; v2 then used new
identifiers and seeds.  
**Why a referee would object:** The repository transparently says that no v1
outcome changed v1 or v2 scientific settings, but a reader seeing only the
paper/Online Resource may understand “prospectively registered” as a pristine
first attempt. The prior partial run is relevant context even if it was not
pooled or used for tuning.  
**Required evidence or revision:** Put a concise chronology in the Online
Resource: why v1 stopped, which information was visible, which v2 elements
changed, and the evidence that changes were infrastructure-only. Preserve both
registrations and never pool them.  
**Change surface:** prose and provenance reporting.

### OR-15 — Online Resource 1 contains unresolved evidence macros as literal text

**Severity:** **MODERATE**  
**Exact location:**
`journal/aor/online_resource/sections/12_registered_algorithmic_benchmark_v2.tex:12-26,41-45`.
The compiled PDF prints `(AORBenchmarkInstances)`, `(AORBenchmarkRuns)`,
`(AORWorkerCount)`, and related tokens instead of generated numbers.  
**Why a referee would object:** This is a visible source-completeness and
traceability failure in the compiled submission. It contradicts the claim that
all manuscript numbers come from generated inputs.  
**Required evidence or revision:** Use the actual generated LaTeX commands,
recompile Online Resource 1, and run a literal-placeholder audit on both PDFs.
Do not hand-transcribe the values.  
**Change surface:** prose/source integration.

### OR-16 — The theorem ledger points to obsolete migration files

**Severity:** **MODERATE**  
**Exact location:** `THEOREM_LEDGER.md:437-447` points SC-TAG to
`04_tagged_cover_equivalence.tex`; lines 620--625 point SC-COMP to
`05_identity_closure_complexity.tex`; lines 693--699 point SC-DP to
`07_exact_requirement_mask_algorithms.tex`. The compiled statements are now in
`journal/aor/manuscript/04_cover_complexity.tex` and `05_algorithms.tex`.  
**Why a referee would object:** Evidence status may be correct, but the formal-
to-manuscript correspondence is not authoritative if it points to migration
sources rather than the compiled article.  
**Required evidence or revision:** Update every active theorem location and
retain old paths only as explicit migration provenance. Run an automated check
that each ledger label occurs exactly once in the compiled source tree.  
**Change surface:** theorem ledger and release checks.

### OR-17 — Generated v2 instances carry v1 provenance text

**Severity:** **MINOR**  
**Exact location:**
`julia/src/AlgorithmicCompressionGenerators.jl:510-525`, especially line 514,
which hard-codes “Registered Algorithmic Compression Benchmark v1 registry.”  
**Why a referee would object:** A v2 instance should not claim v1 provenance.
The mismatch is small but unnecessary in an evidence package built around
machine-readable provenance.  
**Required evidence or revision:** Parameterize the study name/schema in future
generation and document the mismatch for immutable v2 instances. Do not rewrite
locked raw artifacts silently.  
**Change surface:** code and provenance note.

### OR-18 — Supplementary registry presentation is not usable at article scale

**Severity:** **MINOR**  
**Exact location:** Online Resource 1, Section S12, landscape realized-registry
table (compiled page around S68), sourced by
`online_resource/tables/registered_design_realized.tex`.  
**Why a referee would object:** The full registry is too dense for practical
reading in the PDF and risks clipping or illegible type. A machine-readable CSV
already serves the audit function better.  
**Required evidence or revision:** Keep a compact factor/design summary in the
Online Resource and cite the complete registry CSV as the authoritative record.
  
**Change surface:** supplementary presentation only.

## Editorial recommendation

There is no **FATAL** theorem defect in the inspected core. There are, however,
eight **MAJOR** validity or contribution problems before breadth is even
considered. The present version should not be accepted. A credible revision
would:

1. recast or strengthen the semantic theorem so that the sufficient state is
   not simply assumed;
2. state openly that the identity-closure computation is weighted set cover;
3. run a new registered, warm-timed benchmark with feasible and genuinely
   nontrivial residual instances;
4. compare methods on common success targets and analyze repeated-instance data
   accordingly;
5. present the two financial studies as limited audited cases unless broader,
   nontrivial instances and defensible cost calibration are added; and
6. cut the main article substantially.

Without those changes, the paper is a careful and reproducible implementation
of known covering machinery around a conditional state representation. That is
not yet a sufficiently strong *Annals of Operations Research* contribution.
