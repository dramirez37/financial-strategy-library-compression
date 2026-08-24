# Unified Semi-Markov Timing Specification

## Status and phase gate

This document fixes the target timing convention for *Dynamic Strategy
Innovation under Partial Information*. It is a mathematical specification and
migration audit, not an implementation claim. The current manuscript, Lean
project, Julia package, fixtures, and generated results continue to encode
their pre-existing conventions until the migration described below is
completed and checked.

The convention passed an internal-consistency review on 2026-07-22 subject to
the following binding conditions:

1. research duration is elapsed **calendar time**, not an extra discount lag;
2. belief follows the declared kernel at every elapsed period;
3. the pre-completion compressed state remains fixed and its frontier supplies
   rewards unless the selected project is declared suspending;
4. the completion outcome and compressed-state update occur at the end of the
   duration, before continuation is evaluated;
5. continuation at completion is evaluated at the terminal belief and updated
   compressed state;
6. no recurrent zero-duration research cycle is permitted; and
7. the ordinary contraction and calendar-horizon results are stated for
   positive-duration research. Zero-duration research requires the separate
   well-founded closure specified below.

No Lean, Julia, manuscript, experiment, or generated-artifact implementation
is changed by adopting this specification alone. In particular, none of the
new statements below is Lean-verified at this phase.

## 1. Primitives and declared information

Let:

- \(B\) be the finite belief state space;
- \(K\) be a compressed library state;
- \(F_K(b)\) be the one-period frontier reward at belief \(b\);
- \(P(b,b')\) be the one-period belief kernel;
- \(0\leq\beta<1\) be the per-calendar-period discount factor;
- \(Q(K)\) be the finite set of research projects available at \(K\);
- \(d_q\in\mathbb N_0\) be project \(q\)'s declared duration;
- \(\kappa_q(b,K)\) be its initiation cost; and
- \(o_q\in\{0,1\}\) be its operation flag, with \(o_q=1\) by default and
  \(o_q=0\) only for a project explicitly declared to suspend the incumbent
  library.

The state at a decision time is \((b,K)\). Only one project can be in progress,
and there are no new control choices between its initiation and completion.
If concurrent research is later desired, the in-progress portfolio must be
included explicitly in the compressed state; it cannot be hidden in the
transition kernel.

### Completion law

Starting from \(B_0=b\), belief evolves according to

\[
  B_{t+1}\mid B_t\sim P(B_t,\cdot),\qquad t=0,\ldots,d_q-1.
\]

At date \(d_q\), the project produces an admitted-candidate outcome
\(Z_q\). Its declared completion kernel is

\[
  \Gamma_q^{\mathrm{comp}}(dz\mid b,K,B_{d_q}).
\]

The kernel is allowed to use the initiation belief, initiation state, and
terminal belief. This single declaration covers both a design frozen at
initiation and an outcome assessed using terminal information without hiding
which information is used. If an outcome genuinely depends on more of the
belief path, the necessary path statistic must be added to the state so that
the completion law remains Markov.

The updated compressed state is

\[
  K'=U_q(K,Z_q),
\]

where \(U_q\) includes admission, rejection, and the null outcome. The joint
duration-\(d\) completion kernel is therefore

\[
\begin{aligned}
  \mathcal Q_q^{(d)}(b',K'\mid b,K)
  ={}& P^d(b,b')
       \int
       \mathbf 1\{U_q(K,z)=K'\}
       \Gamma_q^{\mathrm{comp}}(dz\mid b,K,b').
\end{aligned}
\]

All expectations below use the belief path and this completion law. The
notation \(\mathbb E_{b,K}^q\) makes that dependence explicit.

For the raw financial library model, `RAW_TO_COMPRESSED_SPEC.md` is the
binding instantiation of this abstract completion law. It derives the admitted
outcome marginal \(\Gamma(q,b,C)\) from raw generation and verification, then
declares a joint belief-path/outcome coupling \(\Lambda_q\). Its terminal
joint law \(\Xi_q\) is pushed through `addK` to obtain
\(\mathcal Q_q^{(d)}\). A conditional
\(\Gamma_q^{\mathrm{comp}}(\cdot\mid b,K,b')\) is a disintegration of that
joint law where defined; it is not an implicit product or independence
assumption.

## 2. Calendar and event order

At a decision date labelled \(0\):

1. the controller chooses Continue or initiates one available project;
2. if research is chosen, \(\kappa_q(b,K)\) is paid immediately;
3. for each research date \(t=0,\ldots,d_q-1\), the incumbent state is still
   \(K\), the belief is \(B_t\), and reward \(o_qF_K(B_t)\) is received;
4. after each such date the belief takes one transition under \(P\);
5. at date \(d_q\), the project completes, \(Z_q\) is realized, and \(K'\) is
   formed; and
6. continuation begins at \((B_{d_q},K')\).

Thus the reward at date \(d_q\) is not included in the project reward stream.
It belongs to the action selected by the continuation problem at that date.
This prevents double counting. For \(d_q=1\), an operational project pays its
cost and earns \(F_K(b)\) now, belief moves once, the project completes, and
continuation starts one period later.

## 3. Unified value operators

### Continue

Continue consumes one calendar period:

\[
  (\mathcal C V)(b,K)
  =F_K(b)+\beta\sum_{b'}P(b,b')V(b',K).
  \tag{U-C}
\]

### Research

The general research operator is

\[
\begin{aligned}
  (\mathcal R_q V)(b,K)
  ={}&-\kappa_q(b,K)\\
     &+\mathbb E_{b,K}^q\!\left[
       \sum_{t=0}^{d_q-1}\beta^t o_qF_K(B_t)
       +\beta^{d_q}V(B_{d_q},K')
     \right].
  \tag{U-R}
\end{aligned}
\]

The requested default convention is \(o_q=1\):

\[
  (\mathcal R_q V)(b,K)
  =-\kappa_q(b,K)
   +\mathbb E_{b,K}^q\!\left[
      \sum_{t=0}^{d_q-1}\beta^tF_K(B_t)
      +\beta^{d_q}V(B_{d_q},K')
    \right].
  \tag{U-R-active}
\]

A suspending project is not a second timing convention. It is the declared
special case \(o_q=0\) of the same operator.

### Bellman operator

\[
  (\mathcal T V)(b,K)
  =\max\left\{
      (\mathcal C V)(b,K),
      \max_{q\in Q(K)}(\mathcal R_qV)(b,K)
    \right\}.
  \tag{U-T}
\]

For the infinite-horizon model, \(V=\mathcal TV\). The maximization contains
no separate idle/research timing convention: Continue and every research
project are evaluated on the same calendar.

## 4. The case \(d_q=0\)

The indexing convention is binding:

\[
  \sum_{t=0}^{-1}(\cdot)=0,\qquad P^0=I,\qquad B_0=b,
  \qquad \beta^0=1.
\]

Consequently,

\[
  (\mathcal R_qV)(b,K)
  =-\kappa_q(b,K)
    +\mathbb E_{b,K}^q[V(b,K')]
  \qquad(d_q=0).
  \tag{U-R0}
\]

An instantaneous project receives no incumbent reward: a duration-zero
interval contains no reward dates. If the intended action pays cost, earns the
current frontier reward, and completes one period later, its duration is
\(d_q=1\), not \(0\). The convention \(\beta^0=1\) also applies when
\(\beta=0\). After the instantaneous update, the continuation may choose an
action at that same date and earn the frontier of \(K'\); (U-R0) does not award
the old and new frontiers both.

Equation (U-R0) can call the value at the same calendar date. Unrestricted
zero-duration cycles would permit infinitely many choices before time moves,
can make the Bellman map merely nonexpansive, and invalidate the ordinary
finite-horizon induction. Therefore one of the following must hold:

- **primary model:** every recurrently available project has \(d_q\ge1\); or
- **instantaneous extension:** the state includes a well-founded rank \(r\)
  and every zero-duration outcome with further choices strictly decreases
  that rank. The zero-duration actions are solved as a finite inner closure at
  fixed calendar time before Continue or positive-duration research is
  evaluated.

A null or rejected outcome that leaves the same state cannot satisfy the
second condition unless initiating the project also consumes an opportunity
recorded in the state. No implementation may accept an unranked zero-duration
cycle.

## 5. Finite calendar horizon

Let \(V_h(b,K)\) denote value with \(h\) calendar reward dates remaining, and
let \(V_0=g\) be a declared terminal payoff (zero in the current finite-horizon
comparisons). Under the primary positive-duration model,

\[
\begin{aligned}
  \mathcal C_hV_{h-1}(b,K)
    &=F_K(b)+\beta\mathbb E_b[V_{h-1}(B_1,K)],\\
  \mathcal R_{q,h}V_{h-d_q}(b,K)
    &=-\kappa_q(b,K)
      +\mathbb E_{b,K}^q\!\left[
        \sum_{t=0}^{d_q-1}\beta^t o_qF_K(B_t)
        +\beta^{d_q}V_{h-d_q}(B_{d_q},K')
      \right],
\end{aligned}
\]

and

\[
  V_h(b,K)=\max\left\{
    \mathcal C_hV_{h-1}(b,K),
    \max_{q\in Q(K):\,1\le d_q\le h}
      \mathcal R_{q,h}V_{h-d_q}(b,K)
  \right\}.
  \tag{U-FH}
\]

A project with \(d_q>h\) is unavailable; rewards are not silently truncated
and its cost is not charged. If instantaneous projects are enabled, (U-FH) is
preceded at each \(h\) by the well-founded fixed-date closure over the rank
described above. It must not be implemented as the old iteration
\(V_{n+1}=\mathcal TV_n\), because that iteration counts decision epochs rather
than calendar periods.

## 6. Raw and compressed formulations

For a raw library \(L\), write \(K=\phi(L)\). The raw form of (U-R) replaces
\(K'\) by the admitted raw library \(L'\), and then applies \(\phi\) when the
continuation is represented in compressed state. A raw-to-compressed theorem
under unified timing must preserve, for every admissible project:

1. the current frontier reward \(F_L=F_{\phi(L)}\);
2. availability and duration \(d_q\);
3. initiation cost \(\kappa_q\);
4. operation flag \(o_q\);
5. the entire belief path law through date \(d_q\); and
6. the joint terminal law of \((B_{d_q},\phi(L'))\).

Preserving only a primitive one-step compressed-state transition is no longer
sufficient for a positive-duration project. Dynamic innovation equivalence and
the safe-deletion value corollaries must be restated against these
semi-Markov action laws.

## 7. Operational and generative value under unified timing

With zero terminal payoff, let the finite frozen-library operational value
satisfy

\[
  O_0(b,K)=0,\qquad
  O_h(b,K)=F_K(b)+\beta\mathbb E_b[O_{h-1}(B_1,K)].
  \tag{U-Oh}
\]

For \(0\le d\le h\), finite unrolling gives

\[
  O_h(b,K)=\mathbb E_b\!\left[
    \sum_{t=0}^{d-1}\beta^tF_K(B_t)
    +\beta^d O_{h-d}(B_d,K)
  \right].
  \tag{U-Ohd}
\]

The infinite frozen-library operational value solves

\[
  O(b,K)=F_K(b)+\beta\mathbb E_b[O(B_1,K)].
  \tag{U-O}
\]

For every integer \(d\ge0\), unrolling gives

\[
  O(b,K)=\mathbb E_b\!\left[
    \sum_{t=0}^{d-1}\beta^tF_K(B_t)
    +\beta^d O(B_d,K)
  \right].
  \tag{U-Od}
\]

Writing \(I=V-O\), the Continue premium is

\[
  (\mathcal CV)(b,K)-O(b,K)
  =\beta\mathbb E_b[I(B_1,K)].
\]

For an operational project \((o_q=1)\), (U-Od) cancels the incumbent reward
stream exactly:

\[
\begin{aligned}
  (\mathcal R_qV)(b,K)-O(b,K)
  ={}&-\kappa_q(b,K)\\
     &+\beta^{d_q}\mathbb E_{b,K}^q\!\left[
       I(B_{d_q},K')+O(B_{d_q},K')-O(B_{d_q},K)
     \right].
  \tag{U-I-active}
\end{aligned}
\]

For a suspending project, the same expression includes the foregone incumbent
stream:

\[
\begin{aligned}
  (\mathcal R_qV)(b,K)-O(b,K)
  ={}&-\kappa_q(b,K)
      +(o_q-1)\mathbb E_b\!\left[
        \sum_{t=0}^{d_q-1}\beta^tF_K(B_t)
      \right]\\
     &+\beta^{d_q}\mathbb E_{b,K}^q\!\left[
       I(B_{d_q},K')+O(B_{d_q},K')-O(B_{d_q},K)
     \right].
  \tag{U-I}
\end{aligned}
\]

This is the revised mathematical basis for the operational--generative
decomposition. Existing passive gap identities remain valid as identities for
\(O_h\) or \(O\); their connection to a research decision must use (U-Ih) or
(U-I), not the old research operator.

The exact finite-horizon counterparts use \(I_h=V_h-O_h\). For \(d_q\le h\),

\[
\begin{aligned}
  \mathcal C_hV_{h-1}(b,K)-O_h(b,K)
    &=\beta\mathbb E_b[I_{h-1}(B_1,K)],\\
  \mathcal R_{q,h}V_{h-d_q}(b,K)-O_h(b,K)
    &=-\kappa_q(b,K)
      +(o_q-1)\mathbb E_b\!\left[
        \sum_{t=0}^{d_q-1}\beta^tF_K(B_t)
      \right]\\
    &\quad+\beta^{d_q}\mathbb E_{b,K}^q\!\left[
      I_{h-d_q}(B_{d_q},K')
      +O_{h-d_q}(B_{d_q},K')-O_{h-d_q}(B_{d_q},K)
    \right].
  \tag{U-Ih}
\end{aligned}
\]

## 8. Well-posedness and consistency proof obligations

Assume finite state and project sets, normalized kernels, bounded frontier
rewards and costs, \(0\le\beta<1\), and \(d_q\ge1\) for every research action.
For bounded \(V,W\),

\[
  \|\mathcal CV-\mathcal CW\|_\infty
  \le\beta\|V-W\|_\infty,
\]

and

\[
  \|\mathcal R_qV-\mathcal R_qW\|_\infty
  \le\beta^{d_q}\|V-W\|_\infty
  \le\beta\|V-W\|_\infty.
\]

The path reward and initiation cost cancel from each difference. Since a
finite maximum preserves the common Lipschitz bound,

\[
  \|\mathcal TV-\mathcal TW\|_\infty
  \le\beta\|V-W\|_\infty.
  \tag{U-contraction}
\]

Thus the positive-duration infinite-horizon Bellman operator has a unique
bounded fixed point and value iteration has the usual geometric error bound.
When durations differ, this operator iteration counts Bellman applications and
is not identical to the calendar-horizon recursion (U-FH). The old theorem
identifying decision-epoch finite horizons with iterates from zero therefore
does not carry over unchanged.
When \(d_q=0\), the research modulus is \(1\), so this proof does not apply;
that is why the instantaneous closure is a separate construction.

The convention is internally consistent because:

- **units match:** every exponent counts elapsed calendar periods;
- **belief timing matches reward timing:** reward at date \(t\) uses \(B_t\),
  and the terminal continuation uses \(B_{d_q}\);
- **state timing is explicit:** \(K\) remains fixed before completion and
  becomes \(K'\) only at completion;
- **there is no reward double count:** the research stream stops at
  \(d_q-1\);
- **cost timing is explicit:** the entire \(\kappa_q(b,K)\) is paid at
  initiation;
- **suspension is explicit:** it is the flag \(o_q=0\), not a different
  recursion;
- **horizon timing is explicit:** the finite horizon decreases by \(d_q\), not
  by one decision epoch; and
- **instantaneous cycles are excluded:** positive-duration contraction and
  zero-duration closure have separate hypotheses.

## 9. Mapping every old recursive family

The table maps the distinct recursive semantics currently present in the
repository. “Exact” means equality after the listed parameter restriction,
not merely a qualitative analogy.

| Existing family | Current semantics | Unified mapping | Status |
|---|---|---|---|
| Raw A-TIMING recursion in `MODEL_SPEC.md` and `ASSUMPTIONS.md` | Current frontier is outside the action maximum; research pays cost; belief and library each move once | Set \(d_q=1\), \(o_q=1\), and let \(\Gamma_q^{\mathrm{comp}}\) ignore terminal belief and equal the old initiation-belief admission law | Exact special case |
| Abstract F1 recursion in `manuscript/sections/04_dynamic_innovation_equivalence.tex` and `formal/StrategyInnovation/Quotient/DynamicInnovation.lean` | Current frontier outside the max; no research cost; one primitive belief/state transition | Raw mapping above with \(\kappa_q=0\) and the old transition as \(\mathcal Q_q^{(1)}\) | Exact special case |
| F5 Continue in model, manuscript, Lean, and Julia | Earn current frontier and take one belief step | Equation (U-C) | Unchanged formula |
| F5/F8 research in model, manuscript, Lean, and Julia | Pay cost, forgo all incumbent reward, take one belief transition, and discount by \(\beta^{\ell_q+1}\) | Set \(d_q=\ell_q+1\), \(o_q=0\), and require the unified terminal joint law \(\mathcal Q_q^{(d_q)}\) to equal the old one-step product law | Exact only under the terminal-law restriction; otherwise intentionally replaced |
| Old delay-zero research | One calendar period because the exponent is \(\beta^{0+1}\) | New duration \(d_q=1\), not \(0\) | Exact after relabelling and the operation/law restrictions above |
| Old positive-delay research | Extra discount but only one belief step | New duration \(d_q=\ell_q+1\) produces \(P^{d_q}\) and a full path reward stream | Not generally a special case |
| Old finite-horizon F5 recursion | Horizon counts decision epochs; every action indexes \(V_n\) | Equation (U-FH), with horizon measured in calendar periods and research indexing \(V_{h-d_q}\) | Must be replaced |
| Frozen passive-value recursion F6 | Continue for a finite horizon with fixed library | Equation (U-Oh), and (U-O) for its infinite counterpart | Unchanged |
| Discounted-gap and passive innovation recursions F7 | Difference of two frozen passive values | Difference of two copies of (U-Oh), or of (U-O) at infinite horizon | Unchanged as passive identities |
| Unified T5 insertion values in `MODEL_SPEC.md` and `Value/UnifiedDecomposition.lean` | Passive value freezes the raw library; full value is the accepted raw calendar-horizon recursion | Equations (U-FH) and (U-Oh), with T1 projecting full value to \(K_L\) | Exact final timing; the insertion identity is an algebraic difference of these values |
| S4 coverage occupation/potential | Post-admission discounted occupation of a fixed candidate gap | Retain the occupation operator; a project completing at duration \(d\) contributes the terminal shift \(\beta^dP^d\) together with its declared completion/admission law before post-completion occupation | Retain, add explicit completion shift |
| Legacy T6 one-step single-gap value | \(G(b)=\beta p(b)(P\Delta)(b)\) before cost | \(d_q=1\), \(o_q=1\), one candidate, and no further generative premium; incumbent rewards cancel against Continue | Exact one-period supporting corollary; not current publication-facing T6 |
| F8 delay comparative static | Increasing old lag changes only \(\beta^{\ell+1}\) | Increasing new duration changes the reward path, terminal belief law, completion law, and continuation date | Not valid without new sign/coupling assumptions |
| Script-local raw oracle in `julia/scripts/search_counterexamples.jl` | Old A-TIMING recursion | Same \(d=1,o=1\) mapping as the raw model | Exact special case, then refactor to shared operator |
| Compression oracle in `julia/scripts/run_compression_experiments.jl` | Old cost-free F1 recursion | Same \(d=1,o=1,\kappa=0\) mapping as F1 | Exact special case, then refactor to shared operator |
| Canonical and mechanism Julia solvers | Old F5/F8 process | Rebuild from (U-R), calendar-horizon semantics, and duration kernels | Values, policies, delay comparisons, and outputs must be regenerated |

### Delay notation

The old primitive \(\ell_q\) was an **additional lag**, so its continuation
factor was \(\beta^{\ell_q+1}\). The new primitive \(d_q\) is the full elapsed
duration and its factor is \(\beta^{d_q}\). Therefore

\[
  d_q=\ell_q+1
\]

when translating an old input. New configurations and prose must use
“duration,” not reuse “delay” with the old meaning.

## 10. Algebraic reduction to the old special cases

These are mathematical reductions of the specification. They are not yet Lean
proofs.

### 10.1 Old raw A-TIMING

Let \(d_q=1\), \(o_q=1\), and let the completion law reproduce the old
one-step joint law of \((B_1,K')\). Then

\[
  \mathcal R_qV(b,K)
  =F_K(b)-\kappa_q(b,K)
   +\beta\mathbb E[V(B_1,K')].
\]

Together with (U-C),

\[
\begin{aligned}
  \mathcal TV(b,K)
  &=\max\left\{
      F_K(b)+\beta\mathbb E[V(B_1,K)],
      \max_q\{F_K(b)-\kappa_q(b,K)
                    +\beta\mathbb E[V(B_1,K')]\}
    \right\}\\
  &=F_K(b)+\max\left\{
      \beta\mathbb E[V(B_1,K)],
      \max_q\{-\kappa_q(b,K)
                    +\beta\mathbb E[V(B_1,K')]\}
    \right\},
\end{aligned}
\]

which is exactly the accepted raw recursion.

### 10.2 Old abstract F1 recursion

Under the preceding restriction, additionally set \(\kappa_q=0\) and identify
the old primitive compressed transition with the one-period completion law.
Factoring out \(F_K(b)\) gives

\[
  F_K(b)+\beta\max\left\{
    \mathbb E[V(B_1,K)],
    \max_q\mathbb E[V(B_1,K')]
  \right\},
\]

which is the old cost-free F1 recursion.

### 10.3 Old suspending F5/F8 recursion

Let the old additional lag be \(\ell_q\), set \(d_q=\ell_q+1\) and \(o_q=0\),
and suppose

\[
  \mathcal L(B_{d_q},K'\mid b,K)
  =\widehat Q_q^{\mathrm{old}}(\cdot\mid b,K),
\]

where the right side is the old one-step product transition. Then

\[
  \mathcal R_qV(b,K)
  =-\kappa_q(b,K)
   +\beta^{\ell_q+1}
      \mathbb E_{\widehat Q_q^{\mathrm{old}}}[V(B',K')],
\]

exactly the old F5/F8 research value. For \(\ell_q=0\), the terminal-law
condition follows from using the same one-step law. For \(\ell_q>0\), genuine
belief evolution instead gives \(P^{\ell_q+1}\); equality with the old
one-step law requires a special kernel identity such as
\(P^{\ell_q+1}=P\) on the relevant states. It is not true in general.

### 10.4 One-project single-gap condition

Take an operational one-period project, so \(d_q=1\) and \(o_q=1\). Compare
research with Continue. Their shared \(F_K(b)\) cancels. If admission succeeds
with probability \(p(b)\), creates next-period operational gap \(\Delta\), and
there is no further generative premium, research is weakly preferred exactly
when

\[
  \beta p(b)(P\Delta)(b)\ge\kappa_q(b,K),
\]

which is the old T6 region. Thus the legacy one-gap result is a \(d=1\)
corollary, not current T6 or a general duration formula.

### 10.5 Immediate completion

For \(d_q=0\), (U-R0) follows directly from the empty-sum, identity-kernel,
and zero-exponent conventions. It is not the old “delay zero” case: the latter
consumes one period and therefore maps to \(d_q=1\).

### 10.6 Continue-only and passive value

Equation (U-C) is literally the existing Continue operator. Starting from
zero terminal value and allowing only Continue gives (U-Oh). Induction on
\(h\) therefore reproduces the old passive recursion at every finite horizon;
bounded fixed-point uniqueness gives (U-O) at infinite horizon. Hence the
passive discounted-gap equations survive unchanged even though their bridge
to an active research decision changes.

### 10.7 Old one-period innovation premium

In (U-Ih), set \(d_q=1\) and \(o_q=1\). The reward-stream correction vanishes
and the project branch becomes

\[
  -\kappa_q(b,K)+\beta\mathbb E_{b,K}^q\!\left[
    I_{h-1}(B_1,K')+O_{h-1}(B_1,K')-O_{h-1}(B_1,K)
  \right].
\]

The Continue branch is \(\beta\mathbb E_b[I_{h-1}(B_1,K)]\), which is the
same expression with zero cost and \(K'=K\). Taking their maximum exactly
recovers the old accepted-raw T5 target recursion after aligning the horizon
index.

## 11. Manuscript equations and passages requiring replacement

### Replace or consolidate

| Location | Existing equation/passage | Required replacement |
|---|---|---|
| `manuscript/sections/04_dynamic_innovation_equivalence.tex` | `eq:abstract-bellman` and the prose saying the current frontier is received before the idle/research maximum | Use (U-C), (U-R), and (U-FH); state F1 only as the \(d=1,o=1,\kappa=0\) corollary |
| same section | `eq:di-definition`, `eq:factorization`, and `eq:closure-detectability`, which observe only a primitive one-step state law | Replace the transition signature by the full semi-Markov action signature: availability, cost, duration, operation flag, and joint terminal law |
| `manuscript/sections/06_operational_generative_value.tex` | Former `eq:f5-continue`, `eq:f5-research`, and `eq:f5-full-recursion` timing block | Replaced by T1/T5 calendar-horizon prose and the exact unified action value |
| same section | Former sentence that delay only changes \(\beta^{d+1}\) | Replaced by positive duration, joint completion, and operation-flag timing |
| same section | Former primitive-F5 decomposition discussion | Replaced by T5 raw full/passive values and T1 projection |
| `manuscript/sections/08_dynamic_research_control.tex` | `eq:control-continue`, `eq:control-research`, and `eq:control-bellman-operator` as a competing convention | Keep one reference to (U-C); replace the displayed research block by (U-R) and define (U-T) once |
| same section | Unlabelled finite recursion \(V_{n+1}=\mathcal TV_n\) and decision-epoch interpretation | Replace by (U-FH) and the calendar-horizon feasibility rule |
| same section and `manuscript/appendices/b_long_proofs.tex` | Contraction proof using \(\beta^{d+1}\le\beta\) | Use \(d\ge1\) and \(\beta^d\le\beta\); state that \(d=0\) is outside this theorem |
| same section | Dynamic policy figure and caption asserting monotone movement with old delay | Regenerate under full durations and report only the new finite-grid observation; do not inherit the old monotonicity conclusion |
| `manuscript/sections/09_canonical_finite_model.tex` | Delay declarations “0” and “2,” the interpretation of `eq:canonical-discover-kernel` and `eq:canonical-scale-kernel`, and all values/policies computed from them | Declare positive full durations and completion kernels, then regenerate the exact model |
| `manuscript/appendices/d_numerical_convergence.tex` | Old canonical values, policies, residual history, and stopping iteration | Regenerate after the solver migration |
| `manuscript/appendices/c_counterexamples.tex` | Research-region examples imported from the old gross-coverage bridge | Retain only as explicitly scoped \(d=1\) corollaries and re-audit every cost comparison |
| `manuscript/online_supplement/lean_correspondence.tex` | Rows mapping F1/F5/F8/T6 to old declarations | Replace only after new declarations build and their axioms are audited |

`eq:f5-continue` and `eq:control-continue` are algebraically correct but must
not remain as two independently introduced conventions. One becomes the
canonical Continue definition and the other becomes a reference.

### Retain, but update the timing bridge or hypotheses

The following equations do not themselves encode the conflicting action
timing:

- `eq:introduction-strategy-innovation-equation` in Section 1;
- `eq:library-dynamics-frontier`, `eq:total-innovation`,
  `eq:operational-innovation`, and `eq:generative-innovation` in Section 6;
- `eq:passive-value`, `eq:discounted-gap-recursion`,
  `eq:passive-innovation-equation`, `eq:value-decomposition`, and
  `eq:strategy-innovation-equation` in Section 6;
- `eq:discounted-coverage-occupation`, `eq:coverage-potential`, and
  `eq:coverage-representation` in Section 7;
- `eq:finite-upper-threshold` as a one-period single-gap corollary;
- `eq:frontier-closure-characterization` after the equivalence relation and
  its factorization/detectability hypotheses are replaced;
- `eq:control-bellman-equation` as fixed-point notation, subject to the new
  operator and positive-duration hypotheses;
- `eq:control-geometric-bound` under those hypotheses;
- `eq:canonical-belief-kernel`; and
- `eq:numerical-stopping-rule`, `eq:numerical-apriori-bound`, and
  `eq:numerical-posterior-bound` after their inputs are regenerated.

Section 7 must add the completion shift \(\beta^dP^d\), composed with the
declared completion/admission law, when a passive coverage potential is used
to value a project initiated \(d\) periods earlier. The
introduction's Strategy Innovation Equation remains an accounting identity,
but its generative term must point to (U-I).

Candidate survival in S4 begins after the candidate is admitted at completion.
It therefore belongs inside the post-completion occupation operator, not in
the research-period shift. Any pre-completion attrition or failure probability
must instead be declared in \(\Gamma_q^{\mathrm{comp}}\); it cannot be inserted
implicitly as a factor \(\rho_q^d\).

### Non-manuscript mathematical sources requiring synchronization

- `MODEL_SPEC.md`: within-period timing, F1, F5, F8, T1's preserved action
  law, S4's project bridge, verified T5, and current T6--T7 statements;
- `ASSUMPTIONS.md`: A-TIMING, A-HORIZON, A-DI-ABSTRACT, A-FH-VALUE,
  A-F8-DELAY, and the assumptions supporting T1--T7;
- `NOTATION.md`: duration, horizon, completion kernel, operation flag, and
  research operator rows;
- `FORMALIZATION_MAP.md`: dependency order and declaration targets;
- `FORMALIZATION_GAPS.md`: FG-0017 and FG-0020 remain open until all old
  implementations are removed;
- `THEOREM_LEDGER.md` and `PREPRINT_LEAN_AUDIT.md`: exact statements,
  assumptions, declaration names, and axiom outputs after re-proving; and
- `REPRODUCIBILITY.md`, `ARTIFACT_MANIFEST.md`, and the relevant READMEs after
  regenerated artifacts are accepted.

## 12. Lean files requiring change or re-audit

### Direct semantic changes

- `formal/StrategyInnovation/Value/FiniteHorizon.lean`: redefine the process
  fields, duration completion law, path reward, research value, and calendar
  finite-horizon recursion; encode or explicitly exclude instantaneous
  closure.
- `formal/StrategyInnovation/Bellman/Contraction.lean`: replace the old
  \(\beta^{\text{delay}+1}\) action, prove the duration-\(d\) expectation
  bound, and require positive duration.
- `formal/StrategyInnovation/Quotient/DynamicInnovation.lean`: replace the
  cost-free one-step recursion and strengthen equivalence to preserve each
  semi-Markov action law.
- `formal/StrategyInnovation/Value/Decomposition.lean`: rebuild full value and
  the operational/generative bridge from (U-I).
- `formal/StrategyInnovation/Value/InnovationEquation.lean`: reconnect the
  passive gap identity and delayed-benefit example to duration-based research.
- `formal/StrategyInnovation/Coverage/Potential.lean`: state the duration
  completion shift for the delayed-coverage bridge and update the example.
- `formal/StrategyInnovation/Coverage/SingleGap.lean`: identify gross coverage
  explicitly as a supporting \(d=1\) case; it is no longer the target T6.
- `formal/StrategyInnovation/Fixtures/Generated.lean`: replace the old `delay`
  field/meaning and regenerate exact fixtures.

### Dependent proofs and audit surfaces

These files depend on the changed value semantics or export its claims and
must at least be recompiled and re-audited; theorem statements or proofs will
need edits where their hypotheses mention the old primitive transition:

- `formal/StrategyInnovation/Quotient/FrontierClosure.lean`;
- `formal/StrategyInnovation/Compression/SafeDeletion.lean`;
- `formal/StrategyInnovation/Counterexamples/FrontierPruningLoss.lean`;
- `formal/StrategyInnovation/Counterexamples/MultiGapRegion.lean`;
- `formal/StrategyInnovation/Fixtures/MultiGapRegion.lean`;
- `formal/StrategyInnovation/Fixtures/SingleGapGeometry.lean`;
- `formal/StrategyInnovation/Audit/DynamicInnovation.lean`;
- `formal/StrategyInnovation/Audit/FiniteHorizon.lean`;
- `formal/StrategyInnovation/Audit/Contraction.lean`;
- `formal/StrategyInnovation/Audit/Decomposition.lean`;
- `formal/StrategyInnovation/Audit/CoveragePotential.lean`;
- `formal/StrategyInnovation/Audit/InnovationEquation.lean`;
- `formal/StrategyInnovation/Audit/SingleGap.lean`;
- `formal/StrategyInnovation/Audit/FrontierClosure.lean`;
- `formal/StrategyInnovation/Audit/SafeDeletion.lean`;
- `formal/StrategyInnovation/Audit/FrontierPruningLoss.lean`;
- `formal/StrategyInnovation/Audit/MultiGapRegion.lean`;
- `formal/StrategyInnovation/Audit/AxiomAudit.lean`;
- `formal/StrategyInnovation/Audit/README.md`;
- `formal/StrategyInnovation.lean`; and
- `formal/README.md` and `shared/LEAN_JULIA_BRIDGE.md`.

No migrated manuscript theorem may be called Lean-verified until its exact new
declaration builds without placeholders and its `#print axioms` result is
recorded in `THEOREM_LEDGER.md`.

## 13. Julia implementation and compatibility status

### Package implementation

- `julia/src/RawDynamicProgramming.jl` implements duration powers/path
  rewards, completion kernels, operation flags, calendar finite-horizon
  evaluation, positive-duration validation, and raw/compressed exact policy
  evaluation. This is the reusable final-model API.
- `julia/src/DynamicProgramming.jl` retains the old `delay+1` primitive
  process only as a warning-emitting F5/F8 compatibility API.
- `julia/src/InnovationValue.jl`: rebuild total/generative values and insertion
  comparisons against the migrated solver and (U-I).
- `julia/src/Coverage.jl`: change delayed coverage from the old
  \(\text{delay}+1\) convention to the shift \(\beta^dP^d\); candidate
  survival begins in the post-completion occupation unless completion failure
  is separately declared. Retain gross one-step coverage as an explicit
  \(d=1\) helper or generalize it.
- `julia/src/StrategyInnovation.jl` exports the raw duration, completion-law,
  transition, Bellman, and policy APIs.

### Solvers, exporters, and figure/table generators

- `julia/scripts/solve_canonical_model.jl`;
- `julia/scripts/run_theorem_mechanism_experiments.jl`;
- `julia/scripts/run_compression_experiments.jl`;
- `julia/scripts/search_counterexamples.jl`;
- `julia/scripts/run_coverage_geometry.jl`;
- `julia/scripts/search_single_gap_geometry.jl`;
- `julia/scripts/search_multi_gap_topology.jl`;
- `julia/scripts/export_exact_fixtures.jl`;
- `julia/scripts/generate_strategy_value_figure.jl`;
- `julia/scripts/generate_dynamic_policy_figure.jl`; and
- `julia/scripts/generate_manuscript_numerical_artifacts.jl`.

The two script-local value oracles must be removed or made thin calls to the
shared unified operator so that a third timing convention cannot reappear.
The single-gap and multi-gap search scripts may retain their algebra, but their
research-region metadata and exports must declare that the gross value is the
\(d=1\) corollary.
`julia/README.md` and `julia/scripts/README.md` must be synchronized with the
new API and clock after the code migration.

### Tests

- `julia/test/test_dynamic_programming.jl`;
- `julia/test/test_innovation_value.jl`;
- `julia/test/test_coverage.jl`;
- `julia/test/test_compression.jl`;
- `julia/test/test_exact_fixture_bridge.jl`; and
- `julia/test/test_theorem_mechanisms.jl`.

Tests must cover at least active \(d=1\), active \(d>1\), suspending research,
belief evolution by \(P^d\), calendar-horizon infeasibility, completion-law
dependence, the old exact special cases, and rejection of an unranked
\(d=0\) project.

### Configurations and outputs

The timing fields and expected values in these configurations require
migration:

- `experiments/configs/canonical_discounted_dp.toml`;
- `experiments/configs/theorem_mechanisms.toml`;
- `experiments/configs/coverage_geometry.toml`;
- `experiments/configs/single_gap_geometry.toml` and
  `experiments/configs/multi_gap_topology.toml` for explicit \(d=1\) scope;
- `experiments/configs/strategy_value_figure.toml`; and
- `experiments/configs/compression_experiments.toml` where the F1 oracle is
  selected.

`experiments/configs/README.md` and
`experiments/results/summaries/README.md` must record the new duration field
and distinguish regenerated outputs from the immutable revision baseline.

The canonical summaries/policies/convergence history, theorem-mechanism policy
maps and delay sensitivities, coverage-duration summaries, exact bridge
fixtures, strategy-value figure, dynamic-policy figure, and manuscript
numerical tables must then be regenerated and re-registered. The locked
financial decisions and their empirical outcomes are not to be rewritten or
reinterpreted; they require only a dependency review where manuscript prose
links their passive coverage estimand to research timing.

## 14. Migration order and implementation gate

Implementation must proceed in dependency order:

1. synchronize `MODEL_SPEC.md`, `ASSUMPTIONS.md`, and `NOTATION.md` with this
   specification;
2. define iterated belief and completion kernels and the positive-duration
   semi-Markov operator in Lean;
3. prove the calendar finite-horizon recursion, contraction, raw/compressed
   preservation, and special-case reductions;
4. rebuild dependent compression, decomposition, coverage, and audit
   declarations and update the theorem ledger;
5. migrate the Julia process and exact tests against the same equations;
6. regenerate fixtures, canonical results, mechanism experiments, figures,
   tables, and manifests;
7. replace the listed manuscript equations and proofs; and
8. run the full Lean, Julia, artifact-drift, financial-replay, and manuscript
   gates before promoting any revised claim.

The consistency gate is passed for this specification. The implementation
gate remains closed for the present specification run: existing source and
results are preserved until the migration begins as a separate, checked
change set.
