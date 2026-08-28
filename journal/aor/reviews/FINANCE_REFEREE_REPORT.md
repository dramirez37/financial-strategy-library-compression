# Skeptical quantitative-finance and stochastic-control referee report

**Manuscript:** *Innovation-Safe Compression of Financial Strategy Libraries under Partial Information: Complexity, Algorithms, and Financial Evidence*  
**Journal context:** intended *Annals of Operations Research* special issue on quantitative finance and risk modeling  
**Review date:** 2026-08-27  
**Recommendation:** **REJECT IN PRESENT FORM; invite a substantially narrowed resubmission.** A major revision is defensible only if the special-issue editors are willing to accept a paper whose finance evidence is explicitly a pair of stylized, retrospective governance demonstrations rather than a quantitative-finance validation.

## Scope of review

I reviewed the compiled 38-page journal article at
`journal/aor/manuscript/build/aor-journal-manuscript.pdf` and the compiled
97-page Online Resource 1 at
`journal/aor/online_resource/build/aor-online-resource-1.pdf`, with particular
attention to the abstract, introduction, literature review, stochastic-control
model, economic interpretation, financial case studies, conclusion, Sections
S1--S3 and S8--S9, and the complete financial record in Section S13. I traced
the most consequential timing and measurement assertions to the cited public
protocols, configuration, information-set audit, and aggregate result inputs.
No raw licensed observation was accessed or printed.

This report distinguishes mathematical validity from economic specification,
historical-data timing from genuine prospective validation, and exact equality
of committed numerical tables from equality of unknown economic quantities.

## Overall assessment

The manuscript has a legitimate operations-research idea: a maintained
research catalog can contain entries that are unimportant for the current
operating envelope but important as carriers of reusable components. Exact
preservation of a declared operating frontier and a declared component
inventory is an intelligible governance contract. The positive-duration
semi-Markov proof and the joint terminal belief--admission construction are
mathematically careful. The terminal and annual outcomes are not pooled, and I
found no evidence that held-out returns or target-year diagnostics entered the
retention algorithms, weights, or pruning decisions.

The finance case is nevertheless not established. The empirical “strategy
libraries” are fully enumerated Cartesian grammars of technical-rule fields.
The modules include the instrument identifier and each grammar choice, and a
capability is assumed to disappear when no retained strategy row carries its
tag. In an actual research platform, instrument identifiers, signal functions,
sizers, risk controls, tests, and documentation normally exist as separate
versioned objects; deleting the last strategy row using `instrument:GLD` does
not ordinarily erase the firm's ability to research GLD. The paper offers no
organizational evidence that its row-carried module ontology matches a real
financial model inventory. Identity closure then assumes frictionless
recombination of these fields, and the held-out “descendant” catalog is the same
pre-enumerated grammar rather than output from the modeled generation,
verification, and admission process.

Partial information is also not essential to the optimization or the financial
audits. The empirical regimes are observed SPY-signal quantile bins, not
posterior distributions over an estimated hidden state. The financial studies
do not instantiate the generation law, verification probability, admission
law, project duration, or terminal belief--admission dependence. Those objects
support a conditional stochastic-control theorem, but they are disconnected
from the empirical evidence and currently make the title sound more financial
and dynamic than the case studies are.

The claimed resource savings are computed under uncalibrated indices. The
“validation-computation” weights are a hand-coded formula in lookback and rule
indicators; the “governance” weights count deviations from an arbitrary baseline
template. Neither represents measured compute time, validation hours, staff
cost, monitoring burden, or regulatory capital. These schedules are acceptable
as sensitivity scenarios, not as empirical resource savings.

Finally, the held-out evidence is weaker than the rhetoric. The diagnostic
`Q_a` is the maximum realized quality over an enabled catalog. Equality of
`Q_a` for two innovation-safe libraries is mechanically implied by equality
of their enabled sets. A frontier-only library that deletes options can lose the
ex-post winner by construction. With one terminal split and five annual target
years, survivorship-biased endpoint-stable universes, a current data snapshot,
and no correction for the extreme-value search implicit in `Q_a`, these facts
do not validate the economic value of closure. They illustrate the declared
mechanism.

There is no **FATAL** proof error and no detected hidden use of held-out outcomes
inside compression. There are, however, enough **MAJOR** economic-validity and
special-issue-fit problems that the current version is not publishable as a
quantitative-finance paper.

## Answers to the requested questions

| No. | Question | Referee assessment |
|---:|---|---|
| 1 | Is “financial strategy library” economically credible or merely an AI metaphor? | **Credible only as a stylized rule catalog.** The repository contains concrete strategies, identifiers, modules, and validation profiles, so it is not empty AI vocabulary. But the row-carried capability ontology and frictionless grammar recombination are not shown to describe an actual financial research organization. See FIN-01 and FIN-03. |
| 2 | Is partial information essential? | **No, not to the tagged-cover optimization or either financial audit.** Finite regime/scenario rows suffice. The empirical “beliefs” are observable SPY-signal bins, not a filtering model. Partial information matters only to the conditional projection theorem. See FIN-02. |
| 3 | Are frontier and closure economically interpretable? | **The frontier is interpretable but incompletely documented; closure is much less secure.** A regime-indexed best net-utility row is meaningful once its utility formula and estimation error are stated. Closure represents reusable capabilities only if components truly live exclusively in retained strategy rows and can be recombined as declared. See FIN-03, FIN-04, and FIN-06. |
| 4 | Are generation, verification, and admission clear? | **Mathematically yes; financially no.** `G`, `nu`, `Gamma`, and the insertion rule are explicit. The paper does not say what real project population, verification gate, false-discovery control, approval body, or admission threshold they represent, and the audits do not estimate them. See FIN-05. |
| 5 | Are positive duration and correlated terminal belief/admission handled correctly? | **Yes mathematically.** Positive integer duration supports the horizon induction, and the joint law fixes marginals without assuming independence. The issue is relevance: neither feature is instantiated in the financial cases. See FIN-05. |
| 6 | Does exact preservation have a meaningful governance interpretation? | **Only narrowly.** It is a strong, auditable contract relative to a frozen table and ontology. It is not proof that economic performance, model risk, legal retention, operational resilience, or future research value is preserved under estimation error and drift. See FIN-06 and FIN-13. |
| 7 | Are retention weights defensible? | **As transparent scenario indices, yes; as economic costs, no.** The coefficients and baseline template are not calibrated to observed resource use. See FIN-07. |
| 8 | Do the audits use information available at decision time? | **The compression routines appear to do so.** Validation profiles, module tags, and predeclared weights enter retention; target outcomes are read later. The universe construction still uses endpoint survival and a non-revision-timestamped snapshot. See FIN-08. |
| 9 | Is there hidden look-ahead leakage? | **No hidden candidate-outcome leakage was found, but there is disclosed universe-level look-ahead.** Endpoint-stable surviving ETFs are selected using end-of-sample identity, and the current CRSP snapshot is not point-in-time certified. See FIN-08. |
| 10 | Are held-out diagnostics oversold? | **Yes.** The safe-library equality is mechanical once enabled-set equality holds, and the frontier-only loss uses an ex-post maximum over a large candidate catalog. See FIN-09. |
| 11 | Are there implicit alpha or forecasting claims despite disclaimers? | **The disclaimers are explicit and repeated, but the narrative still invites that reading.** “Highest-quality descendant,” named GLD/UNG carriers, “worth retaining,” and “financial evidence” create performance implications that the design cannot support. See FIN-10. |
| 12 | Are terminal and annual cases improperly pooled? | **No.** Their held-out units, designs, and results are explicitly separated. Side-by-side burden tables are acceptable only because the columns remain schedule- and audit-labeled. See FIN-11 for a minor presentation safeguard. |
| 13 | Is the financial evidence sufficient for the special issue? | **No.** There are two source instances, both solved by empty-residual preprocessing; one fixed retrospective split; five annual targets; and no observed organizational cost or generation process. See FIN-12. |
| 14 | Would a finance reader understand the managerial implication? | **At a slogan level, yes; at an implementable governance level, no.** “Preserve current opportunities and future capabilities at minimum burden” is clear. The paper does not distinguish active maintenance from archival retention, legal recordkeeping, decommissioning, model ownership, or independent validation obligations. See FIN-13. |
| 15 | Are important references missing? | **Yes.** The bibliography omits central data-snooping, multiple-testing, backtest-overfitting, post-publication decay, financial filtering, and model-lifecycle work directly relevant to the empirical design. See FIN-14. |
| 16 | Is the OR material overwhelming the financial question? | **Yes.** The financial object is introduced rhetorically, disappears for most of the theory and algorithm sections, and returns in two thin cases near the end. See FIN-15. |

## Findings that should be preserved

- **No direct held-out leakage found.** The chronology in
  `EMPIRICAL_INFORMATION_SET_AUDIT.md:57-82,123-158` records decision hashes
  before the first access to terminal or target-year quantities. Main-text
  Section 8 states the same firewall at
  `journal/aor/manuscript/08_financial_case_studies.tex:24-31`.
- **The terminal and annual quantities are not pooled.** The manuscript states
  their distinct units at `08_financial_case_studies.tex:15-22,111-119`, and
  Online Resource 1 repeats the boundary at
  `sections/13_financial_secondary_tests.tex:10-13,79-92`.
- **Positive-duration stochastic-control logic is correct.** The model states
  `d_q >= 1` and permits a correlated path/outcome law at
  `03_model_projection.tex:83-89`; the full normalization and induction appear
  at `online_resource/sections/01_probability_normalization.tex:29-69,88-132`.
- **Nonclaims are explicit.** The abstract, introduction, Section 8, Online
  Resource 1, and conclusion repeatedly deny causal, forecasting, alpha, and
  deployable-performance claims.
- **The licensed-data boundary is clear.** The manuscript reports aggregate
  artifacts and requires independent CRSP/WRDS access for row-level
  reproduction.

These strengths prevent a fatal leakage finding. They do not solve the economic
specification and external-validity problems below.

## Classified issues

### FIN-01 — The empirical “capability carrier” assumption is economically unconvincing

**Severity:** **MAJOR**  
**Exact location:** `journal/aor/manuscript/01_introduction.tex:5-23` and
`03_model_projection.tex:34-55`; Online Resource 1,
`sections/13_financial_secondary_tests.tex:29-35,56-77`; the actual module rows
in `experiments/results/summaries/financial_*_strategy_grammar.csv`; module and
enablement declarations in `experiments/configs/financial_terminal_audit.toml:92-119`
and `financial_annual_walkforward_audit.toml:61-91`.  
**Substantive concern:** Each strategy carries tags for the instrument,
directional signal, entry filter, holding horizon, sizing rule, exit rule, and
risk constraint. The paper assumes that deleting every strategy carrying a tag
destroys the corresponding capability. That is not an innocuous description of
a modern research platform. Signal code, risk-control code, instrument masters,
tests, documentation, and data connectors normally persist independently of
strategy rows. Treating `instrument:GLD` as a capability that survives only if a
GLD strategy is actively retained effectively forces one strategy per
instrument and helps explain the 25- and 100-strategy endpoints. The paper has
not shown that this is the governance problem faced by a fund, bank, or research
team.  
**Required fix:** Define the physical and organizational ontology. State which
artifacts are deleted, archived, versioned, or independently stored; who owns
each module; and why a strategy row is its carrier. The strongest fix is a
bipartite model with separately retainable strategy and module artifacts and
separate burdens. If the current ontology is retained, label the cases as a
stylized tuple-grammar catalog rather than an observed strategy-library
inventory.  
**Is new analysis necessary?** **Yes** for a real-world finance or governance
claim. **No** only if the manuscript narrows the claim to a stylized illustration.

### FIN-02 — Partial information is ornamental in the empirical contribution

**Severity:** **MAJOR**  
**Exact location:** title and abstract at `journal/aor/manuscript/main.tex:54-97`;
`03_model_projection.tex:12-32`; financial belief controls at
`financial_terminal_audit.toml:100-111` and
`financial_annual_walkforward_audit.toml:69-83`.  
**Substantive concern:** The theoretical model defines an exact posterior belief
`mu_b` over a hidden market state. The audits instead partition an observed
SPY signal into terciles or quintiles. They estimate no hidden-state model, no
filter, and no posterior. The cover formulation requires only a finite index set
of operating rows; “belief” can be replaced by “regime” or “scenario” without
changing any compression theorem, algorithm, or financial result. Partial
information is therefore not essential to the empirical contribution and is
not established as a financial mechanism.  
**Required fix:** Either remove “under Partial Information” from the title and
present the rows as declared operating regimes, or add an actual filtered-state
financial model and show why the retention decision differs from an observed-
regime formulation. Explain which results truly use the filtration rather than
only finite row indexing.  
**Is new analysis necessary?** **Conditional.** No if the title and claims are
narrowed; yes if partial information remains a principal finance contribution.

### FIN-03 — Identity closure assumes frictionless and universal module recombination

**Severity:** **MAJOR**  
**Exact location:** `03_model_projection.tex:34-45`;
`04_cover_complexity.tex` identity-closure boundary; Online Resource 1,
`sections/13_financial_secondary_tests.tex:63-77`; configuration rules
`module_closure = "identity union"` and `candidate_enablement = "all candidate
modules must belong"` at the paths cited in FIN-01.  
**Substantive concern:** In the audits, possession of the individual tags is
treated as sufficient to generate any catalog candidate containing them. This
ignores interface compatibility, parameter interactions, data dependencies,
implementation ownership, validation history, correlated model failures, and
the fact that some combinations require integration knowledge not contained in
the union of labels. Identity closure is mathematically convenient and creates
the set-cover subclass, but it is the least convincing financial closure model.
The paper's own general-closure counterexamples show why this matters.  
**Required fix:** Provide a domain audit of candidate enablement: for each module
class, explain why independent retention is necessary and sufficient for
recombination. Report how often candidate feasibility would change under at
least one compatibility-aware or dependency-aware closure. If this cannot be
done, state that the financial audits validate only the identity-union grammar,
not generative capability in an actual research organization.  
**Is new analysis necessary?** **Yes** for the claimed financial interpretation.

### FIN-04 — The financial operating frontier is not defined transparently in the submission

**Severity:** **MAJOR**  
**Exact location:** `03_model_projection.tex:21-32` calls `j_s(b)` an operating
payoff; Online Resource 1,
`sections/13_financial_secondary_tests.tex:39-61` defines empirical profile
aggregation but not the underlying utility; the actual implementation is
`julia/scripts/run_financial_terminal_audit.jl:439-443` and
`run_financial_annual_walkforward_audit.jl:97-101`, where annualized sample mean
minus one-half times risk aversion times annualized sample variance is used.  
**Substantive concern:** A finance reader cannot reconstruct the economic
meaning or units of the frontier from the article or Online Resource. The risk-
aversion value, variance convention, transaction-cost treatment, position
normalization, and relationship between validation utility and “operating now”
are material. A maximum across estimated mean--variance scores is not an exact
economic opportunity; it is an estimated ranking functional.  
**Required fix:** Put the complete net-utility formula, units, sampling
convention, turnover-cost rule, annualization, and risk-aversion calibration in
Online Resource 1 and summarize them in Section 8. Explain why the frontier is
the appropriate operational decision object. Add prespecified sensitivity to
risk aversion and plausible cost models if economic conclusions rely on it.  
**Is new analysis necessary?** **No** for complete disclosure. **Yes** for a
claim robust to investor preferences or implementation costs.

### FIN-05 — Generation, verification, admission, and duration are not instantiated financially

**Severity:** **MAJOR**  
**Exact location:** `03_model_projection.tex:61-89,119-160`; Online Resource 1,
`sections/01_probability_normalization.tex:12-69`; the financial study starts
from a fixed candidate grammar at
`sections/13_financial_secondary_tests.tex:15-35,63-77`.  
**Substantive concern:** The stochastic model clearly defines `G`, verification
probability, admission, positive research duration, and a correlated completion
law. The audits do not estimate or use any of them. All candidates already exist
in a fixed Cartesian catalog, verification is not a statistical testing or
approval process, no project consumes positive research time, and no candidate
is admitted into a subsequently operated library. Consequently, the most
distinctive stochastic-control mechanism has no financial evidence.  
**Required fix:** Map every primitive to a concrete research process: project
proposal, generated candidate, validation protocol including false-discovery
control, admission authority, duration, costs, and terminal information. Either
instantiate a small calibrated example from documented workflow records or
separate the stochastic theorem from the financial audits and stop presenting
the latter as evidence for the dynamic process.  
**Is new analysis necessary?** **Yes** if the dynamic financial mechanism remains
a principal contribution; no if it is explicitly only a theoretical motivation.

### FIN-06 — Exact table preservation is being asked to carry an economic-equivalence claim

**Severity:** **MAJOR**  
**Exact location:** `01_introduction.tex:25-45`;
`03_model_projection.tex:162-180`; `08_financial_case_studies.tex:33-42,55-67`;
Online Resource 1, `sections/13_financial_secondary_tests.tex:56-61,131-150`.
The original financial configurations use registered numerical tolerances at
`financial_terminal_audit.toml:111` and
`financial_annual_walkforward_audit.toml:80`.  
**Substantive concern:** Exact equality is exact relative to frozen profile and
module tables. The profiles are estimated from finite historical samples and
were originally compared under numerical tolerances. Exact reconstruction does
not eliminate sampling error, state misspecification, nonstationarity, or model
drift. A governance committee cannot infer that future operating opportunity is
unchanged merely because two retained sets tie on an estimated validation
frontier.  
**Required fix:** State “artifact-exact” or “table-exact” whenever discussing the
financial cases. Separate semantic preservation conditional on the declared
model from statistical uncertainty about the declared model. Add a robustness
analysis over profile uncertainty or a conservative dominance band if the paper
wants to claim economically robust preservation.  
**Is new analysis necessary?** **No** to correct the claim boundary. **Yes** for
economically robust preservation.

### FIN-07 — Retention weights are uncalibrated indices, not resource costs

**Severity:** **MAJOR**  
**Exact location:** `03_model_projection.tex:162-173`;
`08_financial_case_studies.tex:71-98`; Online Resource 1,
`sections/13_financial_secondary_tests.tex:173-205`; formulas in
`experiments/financial_resource_optimization/WEIGHT_ROBUSTNESS_PROTOCOL.md:27-79`.
  
**Substantive concern:** Equal weights are a cardinality benchmark. The
validation-computation schedule
`1 + L/5 + 20 I_trend + 4 I_vol + I_flip` is not measured computation or validation
labor. The governance schedule assigns one unit per deviation from an arbitrary
baseline; it is not observed documentation, approval, monitoring, or review
cost. Calling reductions in these indices “resource savings” gives them an
economic status they do not possess.  
**Required fix:** Relabel the schedules as transparent burden indices and report
index reduction, not resource savings. To retain the economic wording, calibrate
weights prospectively to logged CPU time, test counts, staff hours, review tiers,
or another auditable resource measure and show how additive aggregation is
justified.  
**Is new analysis necessary?** **Yes** for empirical resource-savings claims;
no for an index-sensitivity illustration.

### FIN-08 — The decision firewall is credible, but the universes use end-of-sample survival

**Severity:** **MAJOR**  
**Exact location:** Online Resource 1,
`sections/13_financial_secondary_tests.tex:15-34`; terminal data audit
`experiments/financial_terminal_audit/DATA_AUDIT.md:63-113,153-155`; annual data
audit `experiments/financial_annual_walkforward_audit/DATA_AUDIT.md:5-11`; main
Section 8 does not disclose survivorship in `08_financial_case_studies.tex:13-31`.
  
**Substantive concern:** The pruning and weight code do not appear to read held-
out outcomes before decisions. However, both universes require ETF identity at
the endpoint and therefore condition on survival through 2024. The CRSP files
are a current snapshot without revision timestamps. This is disclosed in the
Online Resource and data audits, so it is not hidden misconduct, but it is
look-ahead at the population-construction level and weakens every empirical
finance interpretation. The main article buries the limitation.  
**Required fix:** Put survivorship, endpoint selection, snapshot revision, and
retrospective-holdout limitations in Section 8 itself. Do not call the annual
study prospectively out-of-sample. A stronger study requires a point-in-time,
date-eligible universe reconstructed separately at each decision origin.  
**Is new analysis necessary?** **No** for honest mechanism-only reporting;
**yes** for general financial evidence or prospective language.

### FIN-09 — The held-out opportunity diagnostic is an ex-post extreme and its safe equality is mechanical

**Severity:** **MAJOR**  
**Exact location:** Online Resource 1,
`sections/13_financial_secondary_tests.tex:63-92,131-155`; main
`08_financial_case_studies.tex:111-127`; generated figure
`manuscript/figures/financial_innovation_safe_compression.tex:55-64`.  
**Substantive concern:** `Q_a(L')` is the maximum realized quality over the
enabled catalog. If closure equality makes the enabled sets identical, then
`Q_a` equality is an algebraic consequence, not held-out corroboration. If
frontier-only pruning removes candidates, an ex-post maximum can fall simply
because the option set shrank; choosing the best realized descendant from a
large grammar introduces an extreme-value/data-snooping effect. The two named
positive carriers are selected through this same ex-post maximum. No uncertainty
for the primary `Q_a` difference addresses candidate-catalog search or design
choice.  
**Required fix:** Describe `Q_a` as an ex-post witness that a removed option
happened to be the realized maximizer, not as evidence that closure has economic
value. Report the number of candidates, the distribution of quality changes,
and multiplicity-aware or predesignated descendant diagnostics if an empirical
validation claim is retained. The safe-library zero difference should be
labeled a deterministic consequence of enablement equality.  
**Is new analysis necessary?** **No** to narrow the language. **Yes** for an
empirical claim about generative economic value.

### FIN-10 — Disclaimers do not fully neutralize implicit performance rhetoric

**Severity:** **MODERATE**  
**Exact location:** abstract `main.tex:73-97`; `01_introduction.tex:83-92`;
`08_financial_case_studies.tex:58-67,121-127`; Online Resource 1,
`sections/13_financial_secondary_tests.tex:73-77,146-155`; conclusion
`09_conclusion.tex:40-47`.  
**Substantive concern:** The text repeatedly denies alpha and forecasting
claims, which is appropriate. It nevertheless uses “highest-quality enabled
descendant,” “worth retaining,” “financial evidence,” and named GLD/UNG
carriers. A reader can reasonably infer that safe retention protects profitable
future research. The design shows only that a predeclared option set contained
the ex-post maximizer under an audit-specific score.  
**Required fix:** Replace performance-inflected language with “ex-post catalog
witness” or similarly neutral terminology. Keep named strategies in the Online
Resource unless their identities are necessary. State once, next to the primary
figure, that the result does not estimate expected value of retention.  
**Is new analysis necessary?** **No.**

### FIN-11 — Terminal and annual units are correctly separated, but side-by-side display still needs guardrails

**Severity:** **MINOR**  
**Exact location:** `08_financial_case_studies.tex:15-22,69-119`; Online Resource
1, `sections/13_financial_secondary_tests.tex:10-13,79-92`; generated financial
tables and figure.  
**Substantive concern:** The manuscript does not pool held-out levels, which is
correct. However, adjacent columns with the labels “terminal” and “annual” can
still invite magnitude comparison, especially for validation/governance burden
indices that have the same formulas but different source composition.  
**Required fix:** Keep separate panels, state the unit and source denominator in
every caption, and avoid cross-audit statements such as one case having a
“larger” effect unless normalized under a common, justified estimand.  
**Is new analysis necessary?** **No.**

### FIN-12 — Two empty-residual cases are insufficient financial evidence

**Severity:** **MAJOR**  
**Exact location:** `08_financial_case_studies.tex:33-42`;
`online_resource/tables/financial_instance_summary.tex:9-16`; Online Resource 1,
`sections/13_financial_secondary_tests.tex:173-214`. The terminal case has 80
active strategies and reduces to 25; the annual case has 202 and reduces to 100;
both preprocessing residuals are empty.  
**Substantive concern:** There are only two source instances derived from one
ETF grammar and one licensed snapshot. Both global optima follow from forced
structure and propagation, so neither tests difficult financial optimization.
The terminal evidence is one retrospective split; the annual evidence has five
target years. Resampling five annual units 2,000 times does not create more than
five independent temporal observations. The cases cannot support a general
claim about finance research libraries, algorithm choice, or governance savings.
  
**Required fix:** Recast the cases as two mechanism illustrations. For a genuine
special-issue empirical contribution, add independently sourced libraries with
different module ontologies, asset classes, research processes, nonempty
residual covers, and point-in-time decision origins. Prespecify the population
and estimands before observing outcomes.  
**Is new analysis necessary?** **Yes** for special-issue sufficiency; no if the
finance evidence is explicitly demoted to illustration.

### FIN-13 — The governance action is underspecified: active maintenance is not the same as deletion

**Severity:** **MODERATE**  
**Exact location:** `01_introduction.tex:5-13`;
`03_model_projection.tex:164-180`; `08_financial_case_studies.tex:139-147`;
governance discussion `02_literature.tex:149-170`.  
**Substantive concern:** Financial institutions distinguish active use,
monitoring, validation, decommissioning, cold archival, legal-record retention,
code retention, data retention, and disaster recovery. The model has one binary
retention decision and a zero-cost inactive strategy. It does not represent
mandatory records, owners, model-risk tiers, audit history, dependencies,
exceptions, or costs of reactivation. Exact frontier/closure equality is not by
itself a compliant model-retirement policy.  
**Required fix:** Define the managerial decision as active-maintenance
compression unless physical deletion is genuinely intended. Add mandatory
regulatory/contractual retention constraints and explain reconstruction,
archival, and reactivation. A simple multi-tier burden model would be more
credible than a delete/retain metaphor.  
**Is new analysis necessary?** **No** for a conceptual clarification; yes if the
paper claims quantified governance savings.

### FIN-14 — The finance literature review omits the research-design risks created by the paper's own grammar

**Severity:** **MODERATE**  
**Exact location:** `journal/aor/manuscript/02_literature.tex:149-181` and
`bibliography/references.bib:223-289`.  
**Substantive concern:** The finance review cites automated trading rules, two
model-risk papers, one supervisory document, and one recent portfolio-policy
paper. It omits the literature most directly relevant to enumerating thousands
of rules and reporting the ex-post best enabled descendant. At minimum the
authors must engage:

- Sullivan, Timmermann, and White (1999), “Data-Snooping, Technical Trading Rule
  Performance, and the Bootstrap,” *Journal of Finance*,
  DOI `10.1111/0022-1082.00163`;
- White (2000), “A Reality Check for Data Snooping,” *Econometrica*,
  DOI `10.1111/1468-0262.00152`;
- Harvey, Liu, and Zhu (2016), “… and the Cross-Section of Expected Returns,”
  *Review of Financial Studies*, DOI `10.1093/rfs/hhv059`;
- Bailey, Borwein, López de Prado, and Zhu (2016/2017), “The Probability of
  Backtest Overfitting,” *Journal of Computational Finance*,
  DOI `10.21314/JCF.2016.322`;
- McLean and Pontiff (2016), “Does Academic Research Destroy Stock Return
  Predictability?”, *Journal of Finance*, DOI `10.1111/jofi.12365`;
- Lakner (1998), “Optimal Trading Strategy for an Investor: The Case of Partial
  Information,” *Stochastic Processes and their Applications*,
  DOI `10.1016/S0304-4149(98)00032-5`; and
- model-lifecycle guidance that explicitly discusses version control,
  modification, and decommissioning, if the governance interpretation remains.

These references do not imply that the paper makes an alpha claim. They explain
why the ex-post maximum, grammar selection, retrospective holdout, and model
retirement interpretation require tighter boundaries.  
**Required fix:** Add a problem-oriented finance subsection covering research
multiplicity, backtest selection, decay, point-in-time universes, filtering in
portfolio control, and model lifecycle. Relate each source to an actual design
choice rather than adding a citation catalog.  
**Is new analysis necessary?** **No** for the literature correction, though the
literature exposes the need for FIN-08 and FIN-09 analyses if stronger claims
remain.

### FIN-15 — The operations-research program overwhelms the financial question

**Severity:** **MAJOR**  
**Exact location:** article architecture in `journal/aor/manuscript/main.tex:104-116`;
Sections 4--7 occupy most of the article before the two financial cases in
Section 8; Online Resource 1 devotes Sections S4--S12 to theory, algorithms, and
synthetic studies before the financial material in S13.  
**Substantive concern:** A quantitative-finance reader must traverse state
projection, covering complexity, preprocessing, enumeration, DP, greedy bounds,
deletion heuristics, capacity geometry, and two synthetic experimental programs
before encountering a finance application that does not instantiate the
dynamic process. The paper's strongest content is OR methodology; its weakest
content is the finance identity promised by the title.  
**Required fix:** Choose one paper. For the special issue, lead with an actual
financial model-inventory problem, define the organizational and economic
objects concretely, and retain only the OR machinery needed to solve it. If the
current general algorithmic program remains, submit it as an OR methodology
paper with financial illustrations rather than “financial evidence.”  
**Is new analysis necessary?** **No** to restructure and narrow. **Yes** if the
special-issue finance identity is to remain as strong as the title suggests.

### FIN-16 — “Prospectively locked weight robustness” is technically qualified but still misleading

**Severity:** **MODERATE**  
**Exact location:** subsection title and text at
`08_financial_case_studies.tex:71-87`; Online Resource 1 says “three
prospectively locked schedules” at
`sections/13_financial_secondary_tests.tex:191-197`; the governing protocol
states the contrary history at
`experiments/financial_resource_optimization/WEIGHT_ROBUSTNESS_PROTOCOL.md:3-23`.
  
**Substantive concern:** The protocol correctly discloses that all three
schedules and earlier algorithm outcomes predated the dedicated robustness lock.
The prospective element is only the restricted replay and reporting schema. The
subsection title and Online Resource shorthand can be read as outcome-blind
selection of weights, which is false.  
**Required fix:** Rename the subsection “Locked retrospective weight replay” and
repeat the prior-outcome disclosure in Online Resource 1. Reserve “prospective”
for the newly fixed subset, outputs, and rules.  
**Is new analysis necessary?** **No.**

## Recommendation to the editors

The paper is not making a hidden alpha claim, and I do not find direct
held-out-outcome leakage into compression. Those are important negatives. They
do not make the finance evidence sufficient.

The current work is best understood as an operations-research paper about a
declared finite catalog whose rows jointly cover payoff and component tags. Its
dynamic finance interpretation is conditional; its partial-information layer is
not used empirically; its module ontology is constructed; its burdens are
uncalibrated; and its two financial examples are forced, retrospective, and
survivorship-biased. For the intended special issue, this is too little finance
under too much algorithmic machinery.

A resubmission could become credible by doing one of two things:

1. **Narrow honestly:** remove the strong partial-information and financial-
   evidence framing, call the ETF exercises stylized retrospective mechanism
   audits, relabel costs as indices, and submit a focused OR reduction paper; or
2. **Build the finance paper:** document a real model/research inventory,
   separate modules from strategy rows, calibrate resource costs, reconstruct
   point-in-time universes, instantiate the generation/verification/admission
   process, and validate on multiple nontrivial source libraries.

The present manuscript attempts to claim the first paper's rigor and the second
paper's relevance without supplying the evidence required for the latter.
