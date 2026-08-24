# Raw-to-Compressed Process Specification

## Status and consistency verdict

This document fixes the target raw financial strategy-library process and
derives its compressed semi-Markov transition. It supplements
`UNIFIED_TIMING_SPEC.md`. Its generation--verification composition and local
raw-to-compressed update now have the R0 Lean counterparts recorded in
`THEOREM_LEDGER.md`. The finite realizable carrier, derived transition,
controlled projection, zero-terminal finite-horizon value factorization,
stationary fixed-point agreement under explicit contraction certificates,
and policy lift now have T1 Lean counterparts in
`StrategyInnovation/Projection/RawToCompressed.lean`.

The convention is internally consistent under three qualifications that are
binding throughout this document:

1. the admitted-candidate law \(\Gamma(q,b,C)\) determines the marginal law
   of the admitted outcome, but it does not determine that outcome's coupling
   with the belief path;
2. the joint belief/outcome coupling is therefore declared as a raw primitive
   and is then pushed forward through the derived local update; and
3. \((B_t,K_t)\) is controlled Markov when \(t\) indexes decision epochs.
   At every calendar date, a project with duration greater than one requires
   an explicit in-progress state.

No conditional independence between the next belief and the next compressed
state is assumed. Independence is an optional specialization in Section 6.4.
The four results below are derived from the stated raw primitives; none is
inserted as an assumption called “factorization.”

## 1. Finite raw objects

Let \(B,S,M,Q\) be the finite belief, strategy, module, and project types. Let
\(s_0\in S\) be the inactive strategy. An admissible raw library is a finite
set \(L\subseteq S\) containing \(s_0\).

Each catalog strategy \(s\in S\) has immutable data

\[
  j_s:B\to\mathbb Q,
  \qquad
  \operatorname{mods}(s)\subseteq M.
\]

The operational frontier, raw module union, and generative closure are

\[
\begin{aligned}
  F_L(b)&:=\max_{s\in L}j_s(b),\\
  U_L&:=\bigcup_{s\in L}\operatorname{mods}(s),\\
  C_L&:=\operatorname{cl}(U_L),
\end{aligned}
\]

where \(\operatorname{cl}\) is extensive, monotone, and idempotent. The
compressed library state is

\[
  K_L:=(F_L,C_L).
\]

Write

\[
  \mathcal K:=\{K_L:L\text{ is an admissible library}\}
\]

for the finite set of realizable compressed states. The ambient pair type may
be larger than \(\mathcal K\), but the derived transition below maps every
realizable state to a realizable state.

The admitted-outcome type is

\[
  \mathcal O:=\operatorname{Option}(S).
\]

Raw admission updates the library by

\[
  L\oplus\operatorname{none}=L,
  \qquad
  L\oplus\operatorname{some}(s)=L\cup\{s\}.
  \tag{RC-raw-update}
\]

## 2. Raw generation, verification, and admission

For each project \(q\), initiation belief \(b\), and declared closure \(C\),
the raw candidate-generation law is

\[
  G(q,b,C)\in\Delta_{\mathbb Q}(\mathcal O).
\]

`none` means that no candidate was generated. If a project prerequisite is
not contained in \(C\), then \(G(q,b,C)=\delta_{\operatorname{none}}\).
For a generated candidate \(s\), the verification-pass probability is

\[
  \nu(q,b,C,s)\in[0,1]\cap\mathbb Q.
\]

The admitted-candidate law is not a new free transition. It is the following
composition of the declared raw generator and verification rule:

\[
\begin{aligned}
  \Gamma(q,b,C)(\operatorname{some}(s))
    &:=G(q,b,C)(\operatorname{some}(s))\nu(q,b,C,s),\\
  \Gamma(q,b,C)(\operatorname{none})
    &:=G(q,b,C)(\operatorname{none})\\
    &\quad+\sum_{s\in S}G(q,b,C)(\operatorname{some}(s))
                       \bigl(1-\nu(q,b,C,s)\bigr).
  \tag{RC-Gamma}
\end{aligned}
\]

Every term is nonnegative, and

\[
\begin{aligned}
  \sum_{o\in\mathcal O}\Gamma(q,b,C)(o)
  &=G(q,b,C)(\operatorname{none})\\
  &\quad+\sum_{s\in S}G(q,b,C)(\operatorname{some}(s))
     \left[\nu(q,b,C,s)+1-\nu(q,b,C,s)\right]\\
  &=1.
\end{aligned}
\]

Thus \(\Gamma(q,b,C)\in\Delta_{\mathbb Q}(\mathcal O)\) is derived from
\(G\) and \(\nu\). The primitive restriction is that \(G\) and \(\nu\) may
inspect \(q,b,C\), but not the identities, provenance, multiplicities, ages,
or admission order hidden behind a library with closure \(C\).

This restriction is a statement about the inputs of two raw mechanisms. It is
not an assumption that a value function or controlled transition already
factors through \(K\).

The exact finite statements that the displayed mass is nonnegative and sums
to one are Lean verified as
`Raw.admittedCandidateDistribution_nonnegative` and
`Raw.admittedCandidateDistribution_totalMass`.

## 3. The local compressed update

For \(K=(F,C)\), define one function on admitted outcomes:

\[
  \operatorname{addK}(K,\operatorname{none})=K,
  \tag{RC-addK-none}
\]

and

\[
  \operatorname{addK}((F,C),\operatorname{some}(s))
  =
  \left(
    b\mapsto\max\{F(b),j_s(b)\},
    \operatorname{cl}\bigl(C\cup\operatorname{mods}(s)\bigr)
  \right).
  \tag{RC-addK-some}
\]

The former split between `addK` for a candidate and `addK?` for an optional
outcome is retired in the target notation. The canonical `addK` consumes an
admitted outcome \(o\in\mathcal O\).

### 3.1 Closure absorption

The closure axioms imply, for finite module sets \(A,D\),

\[
  \operatorname{cl}\bigl(\operatorname{cl}(A)\cup D\bigr)
  =\operatorname{cl}(A\cup D).
  \tag{RC-closure-absorb}
\]

Indeed, extensivity gives
\(A\cup D\subseteq\operatorname{cl}(A)\cup D\), so monotonicity gives
\[
  \operatorname{cl}(A\cup D)
  \subseteq\operatorname{cl}(\operatorname{cl}(A)\cup D).
\]
Conversely,
\(\operatorname{cl}(A)\subseteq\operatorname{cl}(A\cup D)\) and
\(D\subseteq\operatorname{cl}(A\cup D)\). Monotonicity followed by
idempotence gives the reverse inclusion.

## 4. Result 1: raw update identity

**Proposition RC1 (raw update identity).** For every admissible library \(L\)
and admitted outcome \(o\in\mathcal O\),

\[
  K_{L\oplus o}=\operatorname{addK}(K_L,o).
  \tag{RC1}
\]

**Proof.** If \(o=\operatorname{none}\), both raw and compressed updates are
identities. If \(o=\operatorname{some}(s)\), then pointwise

\[
  F_{L\cup\{s\}}(b)=\max\{F_L(b),j_s(b)\}.
\]

For the closure component,

\[
\begin{aligned}
  C_{L\cup\{s\}}
    &=\operatorname{cl}\bigl(U_L\cup\operatorname{mods}(s)\bigr)\\
    &=\operatorname{cl}\bigl(C_L\cup\operatorname{mods}(s)\bigr),
\end{aligned}
\]

where the second equality is (RC-closure-absorb). These are exactly the two
components of (RC-addK-some). \(\square\)

This finite-set proof is Lean verified as
`Raw.compressedLibraryState_rawLibraryUpdate`, using the separately audited
frontier, raw-union, closure-insertion, and closure-absorption lemmas.

## 5. Semi-Markov belief and outcome law

Let \(d_q\in\mathbb N_0\) be the full calendar duration of project \(q\).
For a belief path

\[
  \mathbf b=(b_0,\ldots,b_{d_q}),\qquad b_0=b,
\]

define its Markov marginal

\[
  \mathbb P_b^{(d_q)}(\mathbf b)
  :=\prod_{t=0}^{d_q-1}P_B(b_t,b_{t+1}).
  \tag{RC-belief-path}
\]

For \(d_q=0\), the path contains only \(b_0=b\) and the empty product is one.

The marginal laws \(\mathbb P_b^{(d_q)}\) and \(\Gamma(q,b,C)\) do not
determine their dependence. Declare a joint raw completion coupling

\[
  \Lambda_q(\mathbf b,o\mid b,K)
\]

on belief paths and admitted outcomes, subject to

\[
\begin{aligned}
  \sum_{o\in\mathcal O}\Lambda_q(\mathbf b,o\mid b,K)
    &=\mathbb P_b^{(d_q)}(\mathbf b),\\
  \sum_{\mathbf b}\Lambda_q(\mathbf b,o\mid b,K)
    &=\Gamma(q,b,C)(o).
  \tag{RC-coupling-marginals}
\end{aligned}
\]

The coupling can represent common shocks between market-information evolution
and research success. It may depend on \(q,b,K=(F,C)\), but not on raw library
features hidden behind \(K\). Allowing dependence on \(F\) is harmless for
compression and is weaker than requiring the coupling itself to be
closure-only; only its admitted-outcome marginal is fixed by the closure-only
law \(\Gamma(q,b,C)\). A coupling always exists because the product coupling
satisfies these marginal restrictions, but the product is not selected unless
independence is separately declared.

The terminal belief/outcome law induced by \(\Lambda_q\) is

\[
  \Xi_q(b',o\mid b,K)
  :=\sum_{\mathbf b:\,b_{d_q}=b'}
      \Lambda_q(\mathbf b,o\mid b,K).
  \tag{RC-Xi}
\]

It has marginals

\[
  \sum_o\Xi_q(b',o\mid b,K)=P_B^{d_q}(b,b'),
  \qquad
  \sum_{b'}\Xi_q(b',o\mid b,K)=\Gamma(q,b,C)(o).
  \tag{RC-Xi-marginals}
\]

The path coupling is stronger data than the terminal joint law. Under the
present timing it is needed only when the completion mechanism or an audit
records path dependence. The Bellman reward stream depends on the belief-path
marginal, while continuation depends on \(\Xi_q\). If a future model permits
intermediate decisions or makes pre-completion rewards outcome-dependent, the
full path coupling must remain in the controlled state description.

## 6. Derived compressed transitions

### 6.1 Marginal compressed transition

For a realizable \(K=(F,C)\), define the pushforward of the admitted law:

\[
  \boxed{
  \overline T_q(K'\mid b,K)
  :=\sum_{o:\,\operatorname{addK}(K,o)=K'}
       \Gamma(q,b,C)(o).
  }
  \tag{RC-Tbar}
\]

This is the requested law of the next compressed library state, marginal over
the terminal belief. Because \(\Gamma\) is normalized and `addK` is a total
deterministic map, its fibers partition \(\mathcal O\), so

\[
  \sum_{K'}\overline T_q(K'\mid b,K)
  =\sum_{o\in\mathcal O}\Gamma(q,b,C)(o)=1.
\]

If \(K=K_L\) is realizable, RC1 gives
\(\operatorname{addK}(K,o)=K_{L\oplus o}\), so the law is supported on
\(\mathcal K\).

### 6.2 Joint terminal transition

The semi-Markov Bellman continuation requires the joint law, not merely the
marginal (RC-Tbar). Define

\[
  \boxed{
  \overline{\mathcal Q}_q(b',K'\mid b,K)
  :=\sum_{o:\,\operatorname{addK}(K,o)=K'}
       \Xi_q(b',o\mid b,K).
  }
  \tag{RC-Qbar}
\]

Its marginals are

\[
\begin{aligned}
  \sum_{K'}\overline{\mathcal Q}_q(b',K'\mid b,K)
    &=P_B^{d_q}(b,b'),\\
  \sum_{b'}\overline{\mathcal Q}_q(b',K'\mid b,K)
    &=\overline T_q(K'\mid b,K).
  \tag{RC-Qbar-marginals}
\end{aligned}
\]

Summing either marginal shows that
\(\overline{\mathcal Q}_q(\cdot,\cdot\mid b,K)\) is normalized.

For the Continue action, which consumes one calendar period and changes no
library state,

\[
  \overline{\mathcal Q}_{\mathrm C}(b',K'\mid b,K)
  :=P_B(b,b')\mathbf 1\{K'=K\}.
  \tag{RC-Qcontinue}
\]

### 6.3 Raw terminal transition

For comparison, the raw terminal law under project \(q\) is

\[
  \mathcal Q_q^{\mathrm{raw}}(b',L'\mid b,L)
  :=\sum_{o:\,L\oplus o=L'}
       \Xi_q(b',o\mid b,K_L).
  \tag{RC-Qraw}
\]

Pushing (RC-Qraw) through \((b',L')\mapsto(b',K_{L'})\) and applying RC1
gives (RC-Qbar).

### 6.4 Optional independence specialization

Conditional independence of the terminal belief and admitted outcome is the
additional assumption

\[
  \Xi_q(b',o\mid b,K)
  =P_B^{d_q}(b,b')\Gamma(q,b,C)(o).
  \tag{RC-terminal-independence}
\]

Under this assumption,

\[
  \overline{\mathcal Q}_q(b',K'\mid b,K)
  =P_B^{d_q}(b,b')\overline T_q(K'\mid b,K).
  \tag{RC-product}
\]

The stronger path-level product construction

\[
  \Lambda_q(\mathbf b,o\mid b,K)
  =\mathbb P_b^{(d_q)}(\mathbf b)\Gamma(q,b,C)(o).
  \tag{RC-path-independence}
\]

implies (RC-terminal-independence), but is not necessary for it. Conversely,
the compressed product law could hold even when terminal belief and the raw
outcome remain dependent, if `addK` maps the dependent outcomes to the same
\(K'\). Any of these independence statements must therefore be declared at
the exact level used; none is inferred from the marginal laws.

Neither RC1, RC2, RC3, nor RC4 below requires an independence assumption.

## 7. Result 2: well-defined compressed transition

**Proposition RC2 (well-defined compressed transition).** If
\(K_L=K_{\widetilde L}=K\), then for every \(b,q,K'\),

\[
  \mathbb P(K_{L\oplus O}=K'\mid b,L,q)
  =\mathbb P(K_{\widetilde L\oplus O}=K'\mid b,\widetilde L,q)
  =\overline T_q(K'\mid b,K).
  \tag{RC2-marginal}
\]

With the declared coupling, the same conclusion holds jointly with the
terminal belief:

\[
  \mathbb P(B_{d_q}=b',K_{L\oplus O}=K'\mid b,L,q)
  =\overline{\mathcal Q}_q(b',K'\mid b,K).
  \tag{RC2-joint}
\]

**Proof.** Equality \(K_L=K_{\widetilde L}\) gives equality of both frontiers
and both closures. The declared raw inputs \(G,\nu\), and \(\Lambda_q\) are
therefore identical for the two libraries. Equation (RC-Gamma) makes
\(\Gamma\) identical; (RC-Xi) makes \(\Xi_q\) identical. RC1 replaces each
raw successor compression by the same deterministic
\(\operatorname{addK}(K,o)\). Summing over every outcome in the corresponding
fiber gives (RC2-marginal) and (RC2-joint). \(\square\)

The proof uses restrictions on primitive raw inputs. It does not assume that
the compressed transition is already independent of the raw representative.

## 8. Result 3: controlled Markov projection

Let \(\tau_n\) be decision dates, with \(\tau_0=0\). Continue sets
\(\tau_{n+1}=\tau_n+1\); project \(q\) sets
\(\tau_{n+1}=\tau_n+d_q\). Define the raw and compressed embedded states

\[
  Y_n=(B_{\tau_n},L_n),
  \qquad
  Z_n=(B_{\tau_n},K_{L_n}).
\]

At a decision epoch, the action signature consists of:

- the available set \(Q(K)\);
- the initiation cost \(\kappa_q(b,K)\);
- duration \(d_q\) and operation flag \(o_q\in\{0,1\}\);
- the belief-path/outcome coupling \(\Lambda_q(\cdot\mid b,K)\); and
- the deterministic raw admission update (RC-raw-update).

The incumbent library stays fixed until completion. It earns
\(o_qF_L(B_t)\) at dates \(t=0,\ldots,d_q-1\), and no new control is selected
between initiation and completion.

**Proposition RC3 (controlled Markov projection).** Conditional on the current
embedded compressed state \(Z_n=(b,K)\) and selected action, the joint law of
the holding time, research-period rewards, and next embedded state \(Z_{n+1}\)
does not depend on the raw representative \(L_n\). In particular,
\(Z_n\) is a controlled Markov, more precisely controlled semi-Markov,
process with research transition (RC-Qbar) and Continue transition
(RC-Qcontinue).

**Proof.** The holding time and operation flag are declared project data; the
cost, availability, and current frontier are functions of \((b,K)\). The
belief path has the declared Markov marginal, and its coupling with the outcome
depends only on \((q,b,K)\). By RC2, the next joint belief/compressed-state law
is (RC-Qbar). Hence the conditional law of every component of the
decision-epoch transition and reward block depends on the raw history only
through the current \((b,K)\) and selected action. \(\square\)

### Calendar-time boundary

If \(d_q>1\), the unaugmented pair \((B_t,K_t)\) at every calendar date is not
generally controlled Markov. The same pair can occur while no project is in
progress or while different projects have different remaining durations and
completion laws. A calendar-time Markov representation must add, at minimum,
the active project, remaining duration, and every sufficient statistic needed
by its declared completion coupling. With only one-period projects, or only at
the embedded dates \(\tau_n\), that augmentation is unnecessary.

## 9. Result 4: value factorization

The primary result uses the positive-duration calendar-horizon convention in
`UNIFIED_TIMING_SPEC.md`. Let \(h\) be the number of remaining calendar reward
dates and let \(1\le d_q\le h\) for an available research action. The exact
Lean recursion has zero terminal payoff. A general terminal payoff that
factors through \(K_L\) is a mathematically immediate extension, but is not
part of the audited declaration.

Define the raw project action by

\[
\begin{aligned}
  \mathcal R_{q,h}^{\mathrm{raw}}V_{h-d_q}^{\mathrm{raw}}(b,L)
  :={}&-\kappa_q(b,K_L)\\
  &+\sum_{\mathbf b,o}\Lambda_q(\mathbf b,o\mid b,K_L)
    \left[
      \sum_{t=0}^{d_q-1}\beta^t o_qF_L(b_t)
      +\beta^{d_q}V_{h-d_q}^{\mathrm{raw}}(b_{d_q},L\oplus o)
    \right].
  \tag{RC-Rraw}
\end{aligned}
\]

Define the compressed action using exactly the same path/outcome coupling and
the derived update:

\[
\begin{aligned}
  \mathcal R_{q,h}^{\mathrm{comp}}\bar V_{h-d_q}(b,K)
  :={}&-\kappa_q(b,K)\\
  &+\sum_{\mathbf b,o}\Lambda_q(\mathbf b,o\mid b,K)
    \left[
      \sum_{t=0}^{d_q-1}\beta^t o_qF(b_t)
      +\beta^{d_q}\bar V_{h-d_q}
        (b_{d_q},\operatorname{addK}(K,o))
    \right].
  \tag{RC-Rcomp}
\end{aligned}
\]

The raw and compressed Continue actions are

\[
\begin{aligned}
  \mathcal C_h^{\mathrm{raw}}V_{h-1}^{\mathrm{raw}}(b,L)
    &=F_L(b)+\beta\sum_{b'}P_B(b,b')V_{h-1}^{\mathrm{raw}}(b',L),\\
  \mathcal C_h^{\mathrm{comp}}\bar V_{h-1}(b,K)
    &=F(b)+\beta\sum_{b'}P_B(b,b')\bar V_{h-1}(b',K).
  \tag{RC-Continue}
\end{aligned}
\]

At each positive horizon, both Bellman recursions take the maximum of Continue
and all \(q\in Q(K)\) with \(1\le d_q\le h\).

**Proposition RC4 (finite calendar-horizon value factorization).** Under the
assumptions in Section 10, for every \(h,b,L\),

\[
  V_h^{\mathrm{raw}}(b,L)=\bar V_h(b,K_L).
  \tag{RC4}
\]

**Proof.** Use strong induction on \(h\). At \(h=0\), both values are zero.
Assume the result holds at every smaller calendar horizon. The two
Continue values agree because \(F_L=F_{K_L}\) and the induction hypothesis
applies at \(h-1\). For an available project \(q\), the induction hypothesis
applies at \(h-d_q<h\). RC1 gives

\[
  K_{L\oplus o}=\operatorname{addK}(K_L,o)
\]

inside every continuation term. The cost, operation flag, reward path,
duration, and coupling are otherwise identical by their declared inputs, so
(RC-Rraw) equals (RC-Rcomp). The feasible action sets agree because they are
functions of \(K_L\). Taking the same finite maximum proves the claim at
\(h\). \(\square\)

RC4 concerns the optimal value. Every compressed policy lifts to a raw policy
by \((b,L)\mapsto(b,K_L)\), and every raw Markov policy that is constant on
compression fibers projects back with the same value. An arbitrary policy
that deliberately chooses different actions for raw representatives with the
same \(K\) need not have a factorized policy-value function; no such claim is
needed for equality of the Bellman optima.

### 9.1 Infinite-horizon corollary

In the audited Lean stationary model, \(0\le\beta<1\), the state and action
carriers are finite, every research action has \(d_q\ge1\), and contraction
of the raw and compressed Bellman operators with declared modulus \(\beta\)
is supplied explicitly. The lift of the unique compressed fixed point by
\(L\mapsto K_L\) is a raw fixed point by the same RC1 substitution. Raw
fixed-point uniqueness therefore yields

\[
  V_\infty^{\mathrm{raw}}(b,L)
  =\bar V_\infty(b,K_L).
  \tag{RC4-infinite}
\]

This fixed-point identity is Lean verified as
`Projection.Model.DiscountedContractionModel.raw_fixedPoint_value_eq_compressed`.
The same finite-maximum construction gives a stationary maximizing compressed
selector, and its raw lift is Bellman-optimal by
`Projection.Model.DiscountedContractionModel.liftedRawPolicy_optimal`. The
module does not derive the two analytic contraction certificates merely from
boundedness; they are explicit hypotheses of the contraction model.

### 9.2 Duration zero

RC1, RC2, and the embedded transition part of RC3 remain valid at \(d_q=0\).
The belief path is \((b)\), \(P_B^0=I\), and the reward sum is empty. RC4 does
not follow by strong induction because its continuation remains at horizon
\(h\). A duration-zero extension must add a well-founded opportunity/rank
component preserved by compression and prove factorization by lexicographic
induction on \((h,r)\). An unranked zero-time action with a null outcome can
cycle and is excluded.

## 10. Exact assumptions by result

The assumptions are intentionally separated so that no result imports value
or transition factorization as a premise.

| Result | Exact assumptions needed | Not needed |
|---|---|---|
| RC1 raw update identity | immutable \(j_s\) and \(\operatorname{mods}(s)\); set-valued library; union admission; definitions of \(F_L,U_L,C_L,K_L\); closure extensivity, monotonicity, and idempotence | probabilities, costs, belief dynamics, discount, independence |
| RC2 well-defined compressed transition | RC1; normalized finite \(G\); declared \(\nu\); composition (RC-Gamma); \(G\) and \(\nu\) depend on raw library only through \(C_L\); for the joint claim, a normalized coupling \(\Lambda_q\) with (RC-coupling-marginals) that depends on the raw library only through \(K_L\) | costs, rewards, discount; belief/outcome independence |
| RC3 controlled Markov projection | RC2 joint claim; Markov belief-path marginal; project availability, duration, operation flag, cost, and completion coupling are functions of the displayed compressed inputs; no intermediate decisions; raw library fixed until completion | product coupling; infinite horizon |
| RC4 finite value factorization | RC1--RC3; frontier reward; identical compressed action sets; finite calendar horizon; zero terminal payoff; common discount; positive feasible durations for the strong induction; finite maxima | closure identifiability; minimality; belief/outcome independence |
| RC4 infinite corollary | RC4 structural inputs; \(0\le\beta<1\); finite actions and states; every research duration positive; explicit contraction certificates for both stationary Bellman operators | product coupling; an old primitive compressed transition |

In the assumption registry, these correspond to A-STRATEGY, A-PROFILE,
A-LIBRARY, A-CLOSURE, A-FRONTIER, A-GEN-FACTOR, A-VERIFY, A-COST,
A-TIMING, A-DISCOUNT, and A-HORIZON as indicated by the finer map added
there. The historical ID `A-GEN-FACTOR` names a raw input restriction; its
revised wording does not assume RC2 or RC4.

## 11. Why each restriction matters

- If strategy profiles or module sets change with library history, RC1 can
  fail because a candidate identifier no longer determines its local update.
- If closure is not idempotent and monotone, the closure absorption step in
  RC1 is unavailable.
- If \(G\) or \(\nu\) sees provenance after \(C_L\) is fixed, equal compressed
  states can have different \(\Gamma\), so RC2 fails.
- Even if the marginal \(\Gamma\) is identical, a provenance-dependent
  coupling \(\Lambda_q\) can give different joint laws of
  \((B_{d_q},K')\), so the joint part of RC2 and RC3 fails.
- If availability, costs, duration, or operation suspension sees raw
  provenance, the state transition may still project while the controlled
  reward problem and RC4 fail.
- If terminal payoff sees discarded raw-library information, the induction
  fails already at \(h=0\).
- If calendar-time progress is omitted during multi-period research,
  \((B_t,K_t)\) alone does not reveal the next decision date or completion
  law.

These are direct failure mechanisms, not generic claims that \(K\) is a
minimal quotient.

## 12. Special-case reductions

1. **Independent one-period completion.** With \(d_q=1\) and
   (RC-terminal-independence),
   \(\overline{\mathcal Q}_q=P_B\otimes\overline T_q\). This recovers the old
   product transition, while the unified operational research action also
   earns the incumbent frontier at date zero.
2. **Deterministic belief evolution.** If \(P_B^{d_q}(b,\cdot)\) is a point
   mass, every terminal coupling has the same belief marginal and the joint
   transition is determined by \(\overline T_q\) at that terminal belief.
3. **No admission.** If \(\Gamma=\delta_{\operatorname{none}}\), then
   \(\overline T_q=\delta_K\), although the project can still have duration,
   cost, and a belief path.
4. **Already-present candidate.** If \(s\in L\), then
   \(L\cup\{s\}=L\), and RC1 implies
   \(\operatorname{addK}(K_L,\operatorname{some}(s))=K_L\).
5. **Suspending research.** Setting \(o_q=0\) changes only the reward stream;
   RC1--RC3 and the transition part of RC4 are unchanged.

## 13. Implementation and proof boundary

R0 implements closure absorption, normalization of (RC-Gamma), raw
failure/success updates, the frontier/module/closure insertion formulas, and
RC1. T1 adds the finite realizable-state subtype, exact pushforward
normalization, RC2 representative invariance, equality of the complete
embedded raw pushforward and compressed law in RC3, and the zero-terminal
strong calendar-horizon induction in RC4. It also proves stationary Bellman
intertwining, fixed-point equality under explicit raw and compressed
contraction certificates, and optimal-selector lifting. The focused audit
prints the axioms of all 15 principal declarations; the ledger reconciles
their binders and records only `[propext, Classical.choice, Quot.sound]`.

The implementation deliberately leaves the old primitive abstract transition
and its theorems unchanged. It does not encode the stronger general-terminal
payoff extension, derive contraction certificates from boundedness, claim
generic minimality, or claim unaugmented calendar-time Markovity while a
multi-period project is in progress.
