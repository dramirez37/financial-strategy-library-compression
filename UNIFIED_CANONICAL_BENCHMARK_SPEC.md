# Unified Canonical Benchmark Specification

## Status and implementation gate

This document fixes the proposed replacement for the legacy six-state
compatibility benchmark. It is a specification of the exact finite instance
of the unified positive-duration raw path law used by the manuscript and
`experiments/configs/unified_canonical_benchmark.toml`.

The benchmark passed the internal consistency audit in Section 13 before this
file was added. This run does **not** implement the instance in Julia or Lean,
change the manuscript, replace the legacy benchmark, regenerate an artifact,
or alter any locked negative or mixed result. The specification is not a
theorem and is not a Lean-verification claim.

The binding design has:

- two belief states;
- four raw catalog strategies and eight admissible raw libraries;
- exactly three realizable compressed library states;
- one discovery project, one capability-gated descendant project, and
  Continue;
- strictly positive project durations;
- exact raw generation and verification laws;
- exact full-path/admitted-outcome completion couplings, including a
  non-product coupling for the two-period project;
- deterministic raw and compressed updates;
- exact raw/compressed Bellman agreement; and
- a strictly separated, nonconstant stationary policy on six
  belief--library states.

## 1. Economic stages

The three compressed states are

\[
\begin{aligned}
  K_0&=((0,0),\varnothing),
    &&\text{weak zero-floor frontier; capability missing},\\
  K_1&=((0,0),\{m\}),
    &&\text{same frontier; capability acquired},\\
  K_2&=((2,4),\{m\}),
    &&\text{improved frontier; capability retained}.
\end{aligned}
\]

The first coordinate lists the frontier at beliefs
\((\ell,h)\). The weak frontier in \(K_0\) is deliberately the inactive
zero floor. This choice makes the benchmark compatible with the repository's
binding inactive-zero catalog rule while ensuring that **all** admissible raw
sublibraries, not only a hand-selected reachable subset, compress to exactly
the three displayed states.

Discovery is a one-shot program that can admit one of two operationally
silent carriers of \(m\). Scale requires \(m\) and can admit the profitable
descendant. Thus the intended sequence is

\[
  K_0
  \xrightarrow{\text{discover}}
  K_1
  \xrightarrow{\text{scale}}
  K_2,
\]

with failure self-loops and Continue available at every state.

## 2. Beliefs, discounting, and module closure

Let

\[
  B=\{\ell,h\},\qquad
  P=
  \begin{pmatrix}
    3/4&1/4\\
    1/4&3/4
  \end{pmatrix},
  \qquad
  \beta=\frac12.
\]

The rows and columns of \(P\) are ordered \((\ell,h)\). The two-period
kernel is

\[
  P^2=
  \begin{pmatrix}
    5/8&3/8\\
    3/8&5/8
  \end{pmatrix}.
  \tag{B-P2}
\]

The module universe is \(M=\{m\}\), where \(m\) is the scale capability.
Closure is the identity:

\[
  \operatorname{cl}(D)=D,\qquad D\subseteq M.
\]

## 3. Raw catalog

The finite raw catalog is \(S=\{s_0,c_A,c_B,g\}\).

| Raw identifier | Profile \((j_s(\ell),j_s(h))\) | Module row | Economic role |
|---|---:|---|---|
| \(s_0\) | \((0,0)\) | \(\varnothing\) | mandatory inactive policy |
| \(c_A\) | \((0,0)\) | \(\{m\}\) | verified carrier A |
| \(c_B\) | \((0,0)\) | \(\{m\}\) | verified carrier B |
| \(g\) | \((2,4)\) | \(\{m\}\) | profitable scale descendant and retained carrier |

Both \(c_A\) and \(c_B\) are operationally silent, so their admission changes
closure without changing the frontier. Strategy \(g\) improves the frontier
and itself carries \(m\), so capability is retained at \(K_2\).

Every admissible raw library contains \(s_0\). The complete raw carrier and
its compression are:

| Raw library | Members | Compressed state |
|---|---|---|
| \(L_0\) | \(\{s_0\}\) | \(K_0\) |
| \(L_A\) | \(\{s_0,c_A\}\) | \(K_1\) |
| \(L_B\) | \(\{s_0,c_B\}\) | \(K_1\) |
| \(L_{AB}\) | \(\{s_0,c_A,c_B\}\) | \(K_1\) |
| \(L_g\) | \(\{s_0,g\}\) | \(K_2\) |
| \(L_{Ag}\) | \(\{s_0,c_A,g\}\) | \(K_2\) |
| \(L_{Bg}\) | \(\{s_0,c_B,g\}\) | \(K_2\) |
| \(L_{ABg}\) | \(\{s_0,c_A,c_B,g\}\) | \(K_2\) |

These are all \(2^3=8\) subsets of the three noninactive rows. Hence the
realizable compressed carrier is exactly
\(\mathcal K=\{K_0,K_1,K_2\}\), rather than a selected subset of a larger
ambient carrier. The multiple raw representatives of \(K_1\) and \(K_2\)
make raw-to-compressed equality nonvacuous.

## 4. Projects, menus, timing, costs, and operation flags

Let \(q_D\) denote Discover and \(q_S\) denote Scale.

| Project | Module prerequisite | Availability rule | Duration | Initiation cost | Operation flag |
|---|---|---|---:|---:|---:|
| Discover \(q_D\) | \(\varnothing\) | \(C=\varnothing\) | \(d_D=1\) | \(\kappa_D(\ell)=1/16,\ \kappa_D(h)=1\) | \(o_D=1\) |
| Scale \(q_S\) | \(\{m\}\) | \(m\in C\) | \(d_S=2\) | \(\kappa_S=1/8\) | \(o_S=1\) |

Discover has no module prerequisite, but its program closes once the
capability exists. This one-shot availability rule is compressed-state
observable and prevents redundant rediscovery. Scale is enabled if and only
if the capability is present. Therefore

\[
\begin{aligned}
  A(K_0)&=\{\text{Continue},q_D\},\\
  A(K_1)&=\{\text{Continue},q_S\},\\
  A(K_2)&=\{\text{Continue},q_S\}.
\end{aligned}
\]

Both projects have strictly positive calendar duration and keep the incumbent
operating. For \(q_S\), the operating block uses beliefs \(B_0,B_1\), belief
then moves a second time, the outcome is admitted at date \(2\), and
continuation is discounted by \(\beta^2=1/4\). The terminal marginal is
\(P^2\), not \(P\), and there is no extra lag.

## 5. Raw candidate generation and verification

Write \(\bot\) for the null candidate or admitted failure.
Generation is total on every project--belief--closure input, even where the
project is unavailable. It is belief-independent in this benchmark.

### 5.1 Candidate-generation law \(G\)

| Project and closure | \(G(\bot)\) | \(G(c_A)\) | \(G(c_B)\) | \(G(g)\) |
|---|---:|---:|---:|---:|
| Discover, \(C=\varnothing\) | \(0\) | \(1/2\) | \(1/2\) | \(0\) |
| Discover, \(C=\{m\}\) | \(1\) | \(0\) | \(0\) | \(0\) |
| Scale, \(C=\varnothing\) | \(1\) | \(0\) | \(0\) | \(0\) |
| Scale, \(C=\{m\}\) | \(0\) | \(0\) | \(0\) | \(1\) |

The Scale row at \(C=\varnothing\) is the required prerequisite-failure law.

### 5.2 Verification law \(\nu\)

Verification is belief-, project-, and closure-independent in this benchmark:

| Candidate row \(s\) | \(s_0\) | \(c_A\) | \(c_B\) | \(g\) |
|---|---:|---:|---:|---:|
| \(\nu(q,b,C,s)\) | \(1\) | \(1\) | \(1/2\) | \(3/4\) |

Only \(c_A,c_B\) have positive generation mass under Discover, and only \(g\)
has positive generation mass under available Scale. The other verification
entries are explicit but do not affect the admitted law.

The admitted laws derived from \(G\) and \(\nu\) are therefore

\[
\begin{aligned}
  \Gamma_D(\cdot\mid b,K_0)
    &=\tfrac14\delta_\bot
      +\tfrac12\delta_{c_A}
      +\tfrac14\delta_{c_B},\\
  \Gamma_S(\cdot\mid b,K_i)
    &=\tfrac14\delta_\bot+\tfrac34\delta_g,
      \qquad i\in\{1,2\}.
  \tag{B-Gamma}
\end{aligned}
\]

On the unavailable inputs, the admitted law is \(\delta_\bot\). Every row is
normalized, and the failure mass in each available row is exactly the failed
verification mass.

## 6. Exact joint laws over belief paths and admitted outcomes

For a path \(\mathbf b=(b_0,\ldots,b_d)\), write

\[
  p(\mathbf b\mid b_0)
  =\prod_{t=0}^{d-1}P(b_t,b_{t+1}).
\]

### 6.1 Discover: one-period product coupling

At \(K_0\), Discover uses the explicit product coupling

\[
  \Lambda_D((b_0,b_1),o\mid b_0,K_0)
  =P(b_0,b_1)\Gamma_D(o\mid b_0,K_0).
  \tag{B-Lambda-D}
\]

Its complete positive support is:

| Initial belief | Path | Path mass | \(\Lambda_D(\bot)\) | \(\Lambda_D(c_A)\) | \(\Lambda_D(c_B)\) |
|---|---|---:|---:|---:|---:|
| \(\ell\) | \(\ell\ell\) | \(3/4\) | \(3/16\) | \(3/8\) | \(3/16\) |
| \(\ell\) | \(\ell h\) | \(1/4\) | \(1/16\) | \(1/8\) | \(1/16\) |
| \(h\) | \(h\ell\) | \(1/4\) | \(1/16\) | \(1/8\) | \(1/16\) |
| \(h\) | \(hh\) | \(3/4\) | \(3/16\) | \(3/8\) | \(3/16\) |

Each row over outcomes sums to its path mass, and each two-row initial-belief
block has admitted marginal
\((1/4,1/2,1/4)\). On capability-present inputs, where Discover is
unavailable, its total completion law is
\(P(b_0,b_1)\delta_\bot\).

### 6.2 Scale: two-period correlated coupling

At \(K_1\) and \(K_2\), Scale uses a non-product coupling. Conditional on the
full Markov path, its admitted-success probability depends on the initiation
and terminal beliefs:

\[
  a(b_0,b_2):=
  \Pr(g\text{ admitted}\mid b_0,b_2)
  =
  \begin{cases}
    3/5,&(b_0,b_2)=(\ell,\ell),\\
    1/3,&(b_0,b_2)=(h,\ell),\\
    1,&b_2=h.
  \end{cases}
  \tag{B-scale-coupling}
\]

For every length-two path,

\[
\begin{aligned}
  \Lambda_S(\mathbf b,g\mid b_0,K_i)
    &=p(\mathbf b\mid b_0)a(b_0,b_2),\\
  \Lambda_S(\mathbf b,\bot\mid b_0,K_i)
    &=p(\mathbf b\mid b_0)\bigl(1-a(b_0,b_2)\bigr),
    \qquad i\in\{1,2\}.
  \tag{B-Lambda-S}
\end{aligned}
\]

The complete positive and zero support is:

| Initial belief | Path | Path mass | \(\Lambda_S(\bot)\) | \(\Lambda_S(g)\) |
|---|---|---:|---:|---:|
| \(\ell\) | \(\ell\ell\ell\) | \(9/16\) | \(9/40\) | \(27/80\) |
| \(\ell\) | \(\ell\ell h\) | \(3/16\) | \(0\) | \(3/16\) |
| \(\ell\) | \(\ell h\ell\) | \(1/16\) | \(1/40\) | \(3/80\) |
| \(\ell\) | \(\ell hh\) | \(3/16\) | \(0\) | \(3/16\) |
| \(h\) | \(h\ell\ell\) | \(3/16\) | \(1/8\) | \(1/16\) |
| \(h\) | \(h\ell h\) | \(1/16\) | \(0\) | \(1/16\) |
| \(h\) | \(hh\ell\) | \(3/16\) | \(1/8\) | \(1/16\) |
| \(h\) | \(hhh\) | \(9/16\) | \(0\) | \(9/16\) |

For each path, the two outcome cells sum to the Markov path mass. For each
initial belief, admitted success sums to \(3/4\) and failure to \(1/4\), as
required by \(\Gamma_S\). The terminal-belief marginal is the corresponding
row of \(P^2\). The law is genuinely non-product because, for example,
failure has zero mass on a terminal-\(h\) path but positive unconditional
mass.

On \(K_0\), where Scale's prerequisite is absent and the project is
unavailable, its total completion law is the length-two Markov path law
coupled with \(\delta_\bot\).

## 7. Deterministic raw and compressed updates

The raw update is set insertion:

\[
  L\oplus\bot=L,\qquad
  L\oplus s=L\cup\{s\}.
  \tag{B-raw-update}
\]

The compressed update is the unified local update

\[
  \operatorname{addK}((F,C),s)
  =
  \left(\max\{F,j_s\},
    \operatorname{cl}(C\cup\operatorname{mods}(s))\right),
\]

with \(\operatorname{addK}(K,\bot)=K\). On the three-state carrier:

| Current state | \(\bot\) | \(c_A\) | \(c_B\) | \(g\) |
|---|---|---|---|---|
| \(K_0\) | \(K_0\) | \(K_1\) | \(K_1\) | \(K_2\) |
| \(K_1\) | \(K_1\) | \(K_1\) | \(K_1\) | \(K_2\) |
| \(K_2\) | \(K_2\) | \(K_2\) | \(K_2\) | \(K_2\) |

The off-menu \(K_0\xrightarrow{g}K_2\) entry is part of the total
deterministic update, but it has zero probability because Scale is
unavailable and its raw generator is \(\delta_\bot\) at \(K_0\).

For every one of the eight raw libraries and every
\(o\in\{\bot,c_A,c_B,g\}\),

\[
  K_{L\oplus o}=\operatorname{addK}(K_L,o).
  \tag{B-RC1}
\]

## 8. Derived terminal laws

Pushing the joint completion laws through the deterministic updates gives the
following exact terminal belief/compressed-state laws.

### Discover from \(K_0\)

| Initial belief | Positive terminal masses |
|---|---|
| \(\ell\) | \((\ell,K_0):3/16,\ (h,K_0):1/16,\ (\ell,K_1):9/16,\ (h,K_1):3/16\) |
| \(h\) | \((\ell,K_0):1/16,\ (h,K_0):3/16,\ (\ell,K_1):3/16,\ (h,K_1):9/16\) |

### Scale from \(K_1\)

| Initial belief | Positive terminal masses |
|---|---|
| \(\ell\) | \((\ell,K_1):1/4,\ (\ell,K_2):3/8,\ (h,K_2):3/8\) |
| \(h\) | \((\ell,K_1):1/4,\ (\ell,K_2):1/8,\ (h,K_2):5/8\) |

### Scale from \(K_2\)

Because every \(K_2\) raw representative already contains \(g\), admission
and failure both leave the raw library and compressed state unchanged. The
terminal law is therefore

\[
\begin{aligned}
  \overline{\mathcal Q}_S(\cdot\mid \ell,K_2)
    &=\tfrac58\delta_{(\ell,K_2)}
      +\tfrac38\delta_{(h,K_2)},\\
  \overline{\mathcal Q}_S(\cdot\mid h,K_2)
    &=\tfrac38\delta_{(\ell,K_2)}
      +\tfrac58\delta_{(h,K_2)}.
\end{aligned}
\]

Continue has holding time one, reward \(F_K(b)\), and transition
\[
  \overline{\mathcal Q}_{\mathrm C}(b',K'\mid b,K)
  =P(b,b')\mathbf 1\{K'=K\}.
\]

## 9. Exact expected reward blocks

For research project \(q\), define the expected discounted incumbent block
and the cost-adjusted block by

\[
\begin{aligned}
  O_q(b,K)
    &:=\mathbb E\!\left[
      \sum_{t=0}^{d_q-1}\beta^t o_qF_K(B_t)
    \right],\\
  r_q(b,K)&:=-\kappa_q(b,K)+O_q(b,K).
\end{aligned}
\]

The complete available-action blocks are:

| State and belief | Action | Holding time | Expected incumbent block | Cost-adjusted block |
|---|---|---:|---:|---:|
| \(K_0,\ell\) | Continue | \(1\) | \(0\) | \(0\) |
| \(K_0,h\) | Continue | \(1\) | \(0\) | \(0\) |
| \(K_0,\ell\) | Discover | \(1\) | \(0\) | \(-1/16\) |
| \(K_0,h\) | Discover | \(1\) | \(0\) | \(-1\) |
| \(K_1,\ell\) | Continue | \(1\) | \(0\) | \(0\) |
| \(K_1,h\) | Continue | \(1\) | \(0\) | \(0\) |
| \(K_1,\ell\) | Scale | \(2\) | \(0\) | \(-1/8\) |
| \(K_1,h\) | Scale | \(2\) | \(0\) | \(-1/8\) |
| \(K_2,\ell\) | Continue | \(1\) | \(2\) | \(2\) |
| \(K_2,h\) | Continue | \(1\) | \(4\) | \(4\) |
| \(K_2,\ell\) | Scale | \(2\) | \(13/4\) | \(25/8\) |
| \(K_2,h\) | Scale | \(2\) | \(23/4\) | \(45/8\) |

The nonzero Scale operating blocks are

\[
\begin{aligned}
  O_S(\ell,K_2)
    &=2+\tfrac12\left(\tfrac34\,2+\tfrac14\,4\right)
      =\frac{13}{4},\\
  O_S(h,K_2)
    &=4+\tfrac12\left(\tfrac14\,2+\tfrac34\,4\right)
      =\frac{23}{4}.
\end{aligned}
\]

These calculations use rewards at \(B_0\) and \(B_1\). They do not award a
research-period reward at \(B_2\), where continuation begins. Thus the
operating flag is applied through the unified reward block rather than by a
second timing convention.

## 10. Exact compressed Bellman problem

Write

\[
  \ell_i:=V(\ell,K_i),\qquad h_i:=V(h,K_i).
\]

Continue is

\[
\begin{aligned}
  C_{\ell i}(V)
    &=F_{K_i}(\ell)+\tfrac38\ell_i+\tfrac18h_i,\\
  C_{h i}(V)
    &=F_{K_i}(h)+\tfrac18\ell_i+\tfrac38h_i.
  \tag{B-C}
\end{aligned}
\]

The Discover actions at \(K_0\) are

\[
\begin{aligned}
  D_\ell(V)
    &=-\tfrac1{16}
      +\tfrac3{32}\ell_0+\tfrac1{32}h_0
      +\tfrac9{32}\ell_1+\tfrac3{32}h_1,\\
  D_h(V)
    &=-1
      +\tfrac1{32}\ell_0+\tfrac3{32}h_0
      +\tfrac3{32}\ell_1+\tfrac9{32}h_1.
  \tag{B-D}
\end{aligned}
\]

The Scale actions at \(K_1\) use the correlated two-period terminal law and
\(\beta^2=1/4\):

\[
\begin{aligned}
  S_{\ell 1}(V)
    &=-\tfrac18
      +\tfrac1{16}\ell_1
      +\tfrac3{32}\ell_2+\tfrac3{32}h_2,\\
  S_{h1}(V)
    &=-\tfrac18
      +\tfrac1{16}\ell_1
      +\tfrac1{32}\ell_2+\tfrac5{32}h_2.
  \tag{B-S1}
\end{aligned}
\]

At \(K_2\), both Scale outcomes leave the library unchanged:

\[
\begin{aligned}
  S_{\ell2}(V)
    &=\tfrac{25}{8}
      +\tfrac5{32}\ell_2+\tfrac3{32}h_2,\\
  S_{h2}(V)
    &=\tfrac{45}{8}
      +\tfrac3{32}\ell_2+\tfrac5{32}h_2.
  \tag{B-S2}
\end{aligned}
\]

The six stationary equations are

\[
\begin{aligned}
  \ell_0&=\max\{C_{\ell0},D_\ell\},&
  h_0&=\max\{C_{h0},D_h\},\\
  \ell_1&=\max\{C_{\ell1},S_{\ell1}\},&
  h_1&=\max\{C_{h1},S_{h1}\},\\
  \ell_2&=\max\{C_{\ell2},S_{\ell2}\},&
  h_2&=\max\{C_{h2},S_{h2}\}.
  \tag{B-Bellman}
\end{aligned}
\]

All continuation exponents count elapsed calendar periods: \(1/2\) for
Continue and Discover, \(1/4\) for Scale.

## 11. Expected exact value and stationary policy

Exact rational policy iteration from the all-Continue policy is expected to
terminate after three evaluation/improvement iterations with zero policy
equation and Bellman residuals. The fixed-point values are

\[
  V^\star=
  \begin{pmatrix}
    113/288 & 16/15 & 14/3\\[2pt]
    113/1440 & 37/30 & 22/3
  \end{pmatrix},
  \tag{B-value}
\]

where rows are \((\ell,h)\) and columns are \((K_0,K_1,K_2)\).

The stationary policy is

\[
  \pi^\star=
  \begin{pmatrix}
    \text{Discover} & \text{Scale} & \text{Continue}\\
    \text{Continue} & \text{Scale} & \text{Continue}
  \end{pmatrix}.
  \tag{B-policy}
\]

This map has the intended interpretation:

- at \(K_0\), low discovery cost makes Discover optimal at \(\ell\), while at
  \(h\) the controller waits for the cheaper discovery state;
- at \(K_1\), the newly acquired capability makes Scale optimal at both
  beliefs; and
- at \(K_2\), the descendant frontier is already present, so paying to repeat
  Scale is inferior to Continue.

The exact action values and optimizer gaps are:

| State | Belief | Continue value | Research value | Optimizer | Best-minus-second gap |
|---|---|---:|---:|---|---:|
| \(K_0\) | \(\ell\) | \(113/720\) | \(113/288\) | Discover | \(113/480\) |
| \(K_0\) | \(h\) | \(113/1440\) | \(-3073/5760\) | Continue | \(235/384\) |
| \(K_1\) | \(\ell\) | \(133/240\) | \(16/15\) | Scale | \(41/80\) |
| \(K_1\) | \(h\) | \(143/240\) | \(37/30\) | Scale | \(51/80\) |
| \(K_2\) | \(\ell\) | \(14/3\) | \(109/24\) | Continue | \(1/8\) |
| \(K_2\) | \(h\) | \(22/3\) | \(173/24\) | Continue | \(1/8\) |

The minimum separation is exactly \(1/8\). There are no ties or near ties at
the declared rational calibration.

## 12. Exact raw/compressed Bellman agreement

For a raw value function that factors through compression,

\[
  V^{\mathrm{raw}}(b,L)=V^{\mathrm{comp}}(b,K_L),
\]

the local update identity (B-RC1), common path/outcome coupling, common costs,
durations, flags, and frontier rewards give action by action

\[
\begin{aligned}
  C^{\mathrm{raw}}V^{\mathrm{raw}}(b,L)
    &=C^{\mathrm{comp}}V^{\mathrm{comp}}(b,K_L),\\
  R_q^{\mathrm{raw}}V^{\mathrm{raw}}(b,L)
    &=R_q^{\mathrm{comp}}V^{\mathrm{comp}}(b,K_L).
\end{aligned}
\]

The available menus also agree because availability is a function of
\(C_L\). Taking the same finite maximum gives

\[
  T^{\mathrm{raw}}V^{\mathrm{raw}}(b,L)
  =T^{\mathrm{comp}}V^{\mathrm{comp}}(b,K_L).
  \tag{B-intertwine}
\]

Consequently the expected stationary solution satisfies, for every raw
representative listed in Section 3,

\[
\begin{aligned}
  V_{\mathrm{raw}}^\star(b,L)
    &=V_{\mathrm{comp}}^\star(b,K_L),\\
  \pi_{\mathrm{raw}}^\star(b,L)
    &=\pi_{\mathrm{comp}}^\star(b,K_L).
  \tag{B-raw-compressed}
\end{aligned}
\]

In particular, the three distinct raw representatives of \(K_1\) and four
distinct representatives of \(K_2\) have identical exact action rankings and
values within their compression fibers.

## 13. Internal consistency audit

Before this specification was written, the proposed primitives were
instantiated in memory through the existing exact
`RawInnovationProcess` API. No source or registered output was created.
The constructor checked every belief--compressed-state--project combination
for:

- strictly positive duration;
- resolved prerequisites and catalog outcomes;
- normalized raw generation;
- verification probabilities in \([0,1]\);
- exact Markov belief-path marginals; and
- exact agreement between the completion-law admitted marginal and the
  \(G\)-plus-\(\nu\) admitted law.

The explicit pre-edit audit then passed 122 exact assertions:

| Audit block | Exact assertions |
|---|---:|
| eight raw libraries, three compressed states, and their profiles/closures | 4 |
| all \(8\times4\) raw/compressed local updates | 32 |
| all available raw/compressed embedded action laws at two beliefs | 32 |
| one arbitrary factorized raw/compressed Bellman step on all raw states | 16 |
| raw and compressed convergence plus zero residual certificates | 2 |
| exact stationary value and policy equality on all raw fibers | 32 |
| expected policy map, value map, gap vector, and \(P^2\) row | 4 |
| **Total** | **122** |

Both exact policy-iteration solves terminated after three iterations. Both
policy-equation residuals and Bellman residuals were zero. The minimum
best-versus-second action gap was \(1/8\).

This is exact implementation-level validation of the proposed finite
instance, not a new proof, theorem, Lean declaration, or empirical result.

## 14. Expected qualitative comparative statics

These are benchmark expectations and future regression targets, not new
unconditional theorems.

1. **Discovery cost.** Raising \(\kappa_D(\ell)\) weakens Discover at
   \((\ell,K_0)\); lowering \(\kappa_D(h)\) can expand discovery to
   \((h,K_0)\). The calibrated high-belief policy waits because the current
   high-belief research disadvantage is \(235/384\).
2. **Scale cost.** Raising \(\kappa_S\) weakens Scale at \(K_1\) and makes
   repeat Scale still less attractive at \(K_2\). The calibrated Scale
   advantages at \(K_1\) are \(41/80\) and \(51/80\).
3. **Verification and admission.** A first-order shift of the admitted Scale
   outcome from \(\bot\) to \(g\), holding the belief-path marginal and an
   ordered coupling fixed, raises Scale value at \(K_1\) because every
   \(K_2\) continuation exceeds its \(K_1\) counterpart. This also raises the
   upstream value of acquiring \(m\).
4. **Descendant quality.** Increasing either component of \(j_g=(2,4)\)
   raises \(K_2\)'s operating value and the value of Scale, and therefore
   raises the option value of Discover. It does not create a current
   operational gain when moving from \(K_0\) to \(K_1\).
5. **Capability retention.** Removing the sole retained carrier of \(m\)
   from a \(K_1\) raw library removes Scale from the menu. Replacing one silent
   carrier by the other does not change any compressed action law or value.
6. **Operating flag.** Changing \(o_S\) from one to zero removes the exact
   \(13/4\) and \(23/4\) incumbent blocks at \(K_2\). At \(K_1\), where the
   frontier is zero, the immediate Scale block is unchanged; belief still
   evolves for two periods and continuation remains discounted by \(1/4\).
7. **Duration and belief dynamics.** Changing \(d_S\) must recompute the full
   path law, \(P^{d_S}\), the operating block, and \(\beta^{d_S}\). It must
   never be implemented as one belief transition plus an extra discount.
   No unconditional duration or persistence sign is expected under a changed
   joint coupling.
8. **Local policy stability.** The positive minimum gap and continuity of a
   finite discounted Bellman problem imply a nonempty neighborhood of the
   declared primitives with the same six-state policy map. A future
   implementation should report exact or certified perturbation ranges rather
   than infer them from floating-point pictures.

## 15. Future implementation acceptance criteria

Implementation may begin only as a separate, versioned change set. It must:

1. instantiate the existing unified raw API rather than
   `DiscountedResearchProcess`;
2. preserve the four-row raw catalog and all eight raw libraries;
3. derive exactly the three compressed states in Section 1;
4. derive \(\Gamma\) from the displayed \(G\) and \(\nu\), not enter it as a
   primitive compressed transition;
5. encode the complete joint path/outcome tables in Section 6;
6. verify \(P^2\), the two-period operating blocks, and discount
   \(\beta^2\);
7. exhaust all local raw/compressed updates and embedded transitions;
8. reproduce (B-value), (B-policy), every action value, the \(1/8\) minimum
   gap, three policy iterations, and zero exact residuals;
9. use a new schema and new artifact names, leaving the legacy canonical
   configuration and outputs byte-for-byte unchanged;
10. add proportionate Julia tests and artifact-drift checks before any
    manuscript replacement; and
11. make no Lean-verification claim unless a corresponding exact declaration
    is separately added, built, audited for axioms and placeholders, and
    reconciled in `THEOREM_LEDGER.md`.
