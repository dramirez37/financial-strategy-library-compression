# Empirical Information-Set Audit

Last updated: 2026-07-28

## Scope and governing rule

This audit classifies every quantity reported in the two locked retrospective
financial audits:

- the locked terminal audit; and
- the annual walk-forward audit.

The classification concerns information timing, not merely whether a quantity
could be reconstructed later from committed artifacts. A quantity can be
structurally computable before the holdout yet still be a retrospective
description if the locked pipeline did not compute or use it when making a
decision.

The governing pruning rule is exact:

- frontier-only deletion accepts a removal when the validation-frontier vector
  is unchanged within the registered tolerance;
- innovation-safe deletion accepts a removal when both that frontier vector
  and the module closure are unchanged.

No held-out outcome, candidate-quality measure, coverage-ranking score,
compression statistic, policy-characteristic statistic, or oracle quantity
enters either acceptance test.

## Classification convention

The five classifications are:

1. **Available at pruning time.** The quantity is in the pruning information
   set. The table separately states whether the pruning rule actually uses it.
2. **Available during validation.** The quantity is formed from validation or
   pre-target estimation data after compression, and may be used for candidate
   ranking, but is not a pruning input.
3. **Available only in the held-out audit.** The quantity requires locked-period
   or target-year outcomes first accessed after the applicable decision hash is
   fixed.
4. **Retrospective descriptive statistic.** The quantity is computed after the
   relevant library or decision is fixed to describe the realized audit. It is
   not a decision criterion. Some such statistics use only structural or
   validation-era inputs; their retrospective status records actual pipeline
   use, not logical impossibility of earlier computation.
5. **Oracle comparator.** The quantity deliberately uses held-out outcomes to
   construct an infeasible benchmark. It is necessarily unavailable to the
   pruning and candidate-selection procedures.

For the annual audit, "during validation" includes the trailing estimation
window ending at year $y-1$ for the decision targeting year $y$. A prior
target year may therefore enter a later year's training window, but the
current target year's outcomes never enter its own score, selection, or
decision hash.

## Decision chronology

### Locked terminal audit

1. Development data determine the initial library and the innovation-safe
   deletion order; validation data determine the frontier-only deletion order.
2. Both pruning routines run on validation profiles and structural module
   closures.
3. Validation-only candidate scores, rankings, selections, and the joint
   decision hash are fixed.
4. Locked 2020-2024 returns are first accessed to compute locked net utility,
   ex post opportunity quality, rank diagnostics, and reported outcomes.
5. Compression and retained-policy characteristics are summarized
   retrospectively.

### Annual walk-forward audit

1. The initial library and both compressed libraries are fixed from the
   development/validation information set.
2. For each target year $y$, trailing data through $y-1$ determine the
   candidate scores and selections.
3. The year-specific decision hash is fixed.
4. Target-year profiles, realized occupation, realized coverage, the greedy
   oracle, and regret are first computed.
5. Five-year averages, intervals, opportunity quality, and retained-policy
   characteristics are summarized retrospectively.

## Quantity-by-quantity classification

| Quantity | Primary classification | Used by pruning? | Audit-specific timing and role |
|---|---|---:|---|
| **Current frontier** $\widehat F_a(\cdot;L')$ | **Available at pruning time** (validation-derived) | Yes | Computed from validation policy profiles before each proposed deletion. Frontier equality is the frontier-only acceptance test and one component of the innovation-safe test. The weighted scalar $\overline F_a$ is reported afterward; the full vector is the gate. |
| **Module closure** $C_a(L')$ | **Available at pruning time** | Innovation-safe only | Computed from the declared modules carried by the current retained library. Closure equality is the second innovation-safe acceptance condition. Frontier-only pruning computes the closure for audit rows but does not condition acceptance on it. |
| **Compression ratio** $r_a(L')=1-|L'|/|L_a|$ | **Retrospective descriptive statistic** | No | Known once a pruning run terminates. It uses library cardinalities and no held-out outcome. It describes how much compression occurred; it does not determine any deletion. |
| **Enabled candidate set** $E_a(L')=\{c\in\mathcal G_a:M(c)\subseteq C_a(L')\}$ | **Available at pruning time** | No | The candidate catalog, module requirements, and current closure are structural and fixed before the holdout. The set can be derived without outcome data, but neither deletion rule tests candidate-set equality; innovation-safe pruning tests closure equality directly. |
| **Ex post enabled-descendant opportunity quality** $Q_a(L')$ | **Available only in the held-out audit** | No | Takes the maximum held-out quality over $E_a(L')$. Terminal quality is locked net utility; annual quality is mean realized target-year coverage. It is an ex post mechanism diagnostic, not a forecast, policy score, or deployable criterion. |
| **Coverage ranking score** $x$ | **Available during validation** | No | Terminal scores use validation-state gaps and a development-estimated transition kernel. Annual scores use trailing data through $y-1$ and predicted occupation. They are fixed before the applicable holdout and used only for candidate ranking/selection after pruning. |
| **Locked net utility** $u_{\mathrm T}(c)$ | **Available only in the held-out audit** | No | Computed from locked 2020-2024 returns after the terminal library, pruning decisions, candidate rankings, and decision hash are fixed. It supplies the terminal outcome and $q_{\mathrm T}(c)$, not a compression input. |
| **Annual realized coverage** $Z_y(S)$ and $z_{cy}$ | **Available only in the held-out audit** | No | Computed from target-year profiles and realized belief occupation only after the year-$y$ score, selection, and decision hash are fixed. It supplies the annual outcome and $q_{\mathrm A}(c)$. |
| **Greedy-oracle regret** $G_{\mathrm A}(m)$ | **Oracle comparator** | No | Uses target-year realized gaps and occupation to construct $S_y^\star$, then compares its realized set value with the frozen selected set. It is an infeasible held-out benchmark, not a score available to either algorithm. |
| **Module uniqueness** $H_{ai}$ | **Retrospective descriptive statistic** | No | Computed after the safe library is fixed from the multiplicity of its structural modules. It uses no held-out return or coverage outcome. Although structurally computable, it was not an ordering rule or deletion condition. |
| **Descendant dependence** $D_{ai}$ | **Retrospective descriptive statistic** | No | Computed after the safe library is fixed by counting enabled candidates that would lose structural enablement if policy $i$ were removed. It uses module requirements, not candidate outcome quality, and was not a pruning criterion. |

## Other reported empirical quantities

| Quantity | Classification | Information boundary |
|---|---|---|
| Operational deletion contribution $\widehat O_{ai}$ | **Retrospective descriptive statistic** | Computed after compression from validation-frontier loss under a one-policy deletion. It is not the stepwise pruning decision record. |
| Ex post generative deletion contribution $\widehat G_{ai}$ | **Available only in the held-out audit** | Computed retrospectively from the change in $Q_a$ after deleting one safely retained policy. It inherits $Q_a$'s held-out-only status. |
| Frontier-sparsity indicator $S_{ai}$ | **Retrospective descriptive statistic** | Derived from the post-compression operational deletion contribution and validation profiles. |
| Support for the best descendant | **Available only in the held-out audit** | Structural dependence is combined with the identity of the candidate attaining held-out $Q_a$. This is stronger than descendant dependence and is ex post. |
| Candidate-level rank association | **Available only in the held-out audit** | Correlates a frozen pre-holdout ranking score with locked net utility or annual realized coverage. |
| Reported set payoff and best prespecified comparator | **Available only in the held-out audit** and **retrospective descriptive statistic** | Every method is fixed before the outcome, but its payoff is held out. The reported "best comparator" is the best realized result among prespecified methods; it is not a deployable selector and is not the greedy candidate oracle. |
| Block or annual-unit resampling interval | **Retrospective descriptive statistic** | Computed after the held-out outcomes from locked-session blocks or the five realized annual values. It quantifies only the declared descriptive resampling variation. |

## Algorithm-use matrix

| Quantity family | Frontier-only deletion | Innovation-safe deletion | Candidate ranking/selection | Ex post reporting |
|---|---:|---:|---:|---:|
| Validation-frontier vector | Yes | Yes | Used to form candidate gaps after pruning | Yes |
| Module closure | No acceptance role | Yes | Determines structural enablement | Yes |
| Coverage ranking score | No | No | Yes | Yes |
| Held-out net utility or realized coverage | No | No | No | Yes |
| $Q_a$, oracle regret, and ex post generative contribution | No | No | No | Yes |
| Compression ratio, module uniqueness, and descendant dependence | No | No | No | Yes |

## Implementation evidence

- `julia/scripts/run_financial_terminal_audit.jl`, function `_prune_library`,
  implements frontier equality and optional closure equality. Function
  `_run_ready` fixes the terminal pruning/ranking decision hash before its
  explicit first access to locked-period values.
- `julia/scripts/run_financial_annual_walkforward_audit.jl`, function `_prune_library`,
  implements the same acceptance tests. Function `_episode_rankings` fixes
  each annual decision hash before its explicit first access to target-year
  profiles or return statistics.
- `julia/scripts/generate_manuscript_numerical_artifacts.jl`, functions
  `_audit_characteristics` and `financial_compression_analysis`, reconstructs
  compression ratios, module uniqueness, descendant dependence, support for
  the best descendant, and ex post opportunity-quality changes from committed
  aggregate artifacts. It does not rerun either scoring engine.

Legacy locked fields, frozen SVG text, and the two inactive generated
audit-source fragments
`manuscript/sections/financial_terminal_audit{,_v2}.tex` contain names such as
`locked_candidate_quality_change`, `future_candidate_quality_change`, or
"future candidate quality." They remain outside the active manuscript and
unchanged solely to preserve registered artifact hashes and lineage. Their
governing interpretation is the held-out-only classification above. No such
field or frozen label is evidence that future outcomes entered a compression
decision.

## Audit conclusion

The compression decision has a two-object information set: the validation
frontier, plus module closure for innovation-safe deletion. Coverage scores
belong to the later candidate-ranking stage. Locked net utility, annual
realized coverage, $Q_a$, ex post generative contribution, rank association,
and oracle regret belong to the held-out audit. Compression ratios, module
uniqueness, descendant dependence, and related structural summaries are
post-decision descriptions. Therefore no reported held-out candidate-quality
quantity informed either compression decision.
