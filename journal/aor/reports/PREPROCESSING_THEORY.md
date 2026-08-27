# Exact preprocessing for the tagged identity-closure cover

## Status and scope

This report gives human-readable propositions and proofs for exact
preprocessing of the source-relative tagged covering formulation under
identity closure. The implementation is in
`julia/src/TaggedCoverPreprocessing.jl`. The propositions are human proofs;
the Julia tests are exact finite validation, not Lean kernel verification and
not a substitute for the proofs.

The semantic starting point is the already established identity-closure
equivalence. The tagged requirement set is frozen from the source library:
one frontier-attainment tag for every declared belief and one raw-module tag
for every module in the source identity closure. Preprocessing never
recomputes this universe from a reduced library.

Write the covering model as

\[
  \min \sum_{s\in S} w_s x_s
  \quad\text{subject to}\quad
  \sum_{s:u\in R_s}x_s\geq 1\quad(u\in U),
  \qquad x_s\in\{0,1\}.
\]

The mandatory set `M` is fixed to one and contains the inactive strategy. In
the current strategy-library model the inactive strategy has weight zero;
every nonmandatory strategy has a strictly positive exact rational weight.
The propositions below also allow a nonnegative exact weight for another
explicitly mandatory column. No floating-point comparison is used.

At a preprocessing stage, `Q` denotes the residual requirements not already
satisfied by fixed selections, `A` denotes the residual available columns,
and

\[
  R_s^Q := R_s\cap Q
\]

is a strategy's residual tagged coverage. All subset, equality, carrier-count,
and weight comparisons are exact.

## Meaning of the preservation claims

The guarantees are deliberately separated.

- **Feasibility** means that the original instance has a feasible selection
  if and only if the reduced residual instance has one after fixed selections
  are restored. It does not mean that every nonoptimal feasible binary vector
  remains literally present in the reduced variable space.
- **Optimum value** includes the exact objective offset contributed by fixed
  selections.
- **At least one optimum** means every reduced optimum has a deterministic
  lift to an original optimum, and at least one original optimum has a reduced
  counterpart.
- **All optimizer identities** means every optimal binary selection over the
  original source strategy identifiers can be recovered. A representative
  model can lose literal identities while an explicit reconstruction map
  still recovers them; the table below records that distinction.

## Rule 0: mandatory initialization

Before applying the requested rules, every explicitly mandatory strategy is
fixed to one, its exact weight is added to the objective offset, and every
requirement it covers is removed from the residual requirement set. Mandatory
columns are then absent from the pool eligible for empty-column, duplicate, or
dominance deletion. In particular, the inactive strategy cannot be eliminated
by a generic dominance rule.

This initialization is an exact substitution of fixed binary variables. It
preserves feasibility, optimum value after the offset, at least one optimum,
and all optimizer identities.

## Proposition P1: mandatory residual carrier

**Statement.** Suppose a residual requirement `u` has exactly one available
carrier `s`:

\[
  \{t\in A:u\in R_t^Q\}=\{s\}.
\]

Then every feasible residual selection sets `x_s=1`. The strategy, or its
equal-coverage representative class described under P3, may be fixed to one;
`w_s` is added to the objective offset.

**Assumptions.**

1. The tagged universe is fixed from the source identity-closure instance.
2. Previously fixed selections and the requirements they satisfy have already
   been propagated.
3. `s` is still available and the carrier count is computed on the current
   residual incidence matrix.
4. If `s` represents equal-weight duplicate identities, the representative
   map is retained.

**Proof.** The row for `u` requires at least one selected carrier. By
assumption, `s` is the only available carrier. Hence every feasible residual
selection has `x_s=1`. Substituting that equality leaves a residual feasible
selection if and only if adjoining `s` gives a feasible selection before the
substitution. The objective decomposes exactly into `w_s` plus the residual
objective. Therefore feasibility and optimum value are preserved, every
residual optimum lifts, and every original optimum contains the forced column.
If the column is a representative for equal-weight duplicates, the original
statement is that exactly one identity from that class is required; P3's map
recovers those identities. ∎

**Guarantees.** Feasibility: yes. Optimum value: yes. At least one optimum:
yes. All optimizer identities: yes for an original unique carrier; yes through
the P3 map for a forced representative class.

If a residual requirement has zero available carriers, the implementation
fails closed and marks the residual model infeasible. A valid reduction of a
feasible source cover should never create this condition.

## Proposition P2: strict coverage dominance

**Statement.** Let `s,t` be distinct available, nonfixed strategies. Suppose

\[
  R_s^Q\subseteq R_t^Q,
  \qquad w_t\leq w_s,
\]

and `s` is not mandatory. Then `s` may be deleted while preserving feasibility
existence, the optimum value, and at least one optimum. When `w_t<w_s`, no
original optimum contains `s`, so all optimizer identities are preserved. When
`w_t=w_s` and the containment is strict, all optimizer identities are not
preserved in general.

The implementation routes equal coverage to P3, so P2 is applied only to
strict residual containment.

**Assumptions.**

1. The model is a pure positive-weight covering model after mandatory and
   forced selections are propagated.
2. `s` is not mandatory and both columns are currently available.
3. There are no additional side constraints referring to strategy identity,
   group membership, exact cardinality, or mutual exclusion.
4. The residual subset and exact rational weight comparisons hold.

**Proof.** Consider a feasible selection containing `s`. If it does not
contain `t`, replace `s` by `t`. Every requirement covered by `s` remains
covered because `R_s^Q` is contained in `R_t^Q`; the objective does not
increase because `w_t\leq w_s`. If the selection already contains `t`, remove
`s`; residual coverage is unchanged and the objective strictly falls because
`w_s>0`. Thus every feasible selection has a no-more-expensive feasible image
without `s`. The reduced feasible set is itself a subset of the original
feasible set, so the two optimum values are equal and a reduced optimum lifts
directly.

If `w_t<w_s`, a feasible selection containing `s` is either strictly improved
by the replacement or, when it already contains `t`, by deleting `s`.
Therefore no optimum contains `s`, and deleting the column loses no optimizer
identity. If `w_t=w_s`, replacement can be objective-neutral. For example,
with

\[
 R_s=\{a\},\quad R_t=\{a,b\},\quad
 R_u=\{b,c\},\quad R_v=\{c\}
\]

and unit weights, both `{s,u}` and selections using `t` are optimal. Removing
`s` preserves the optimum value but loses `{s,u}`. Hence no general
all-identities claim is valid for equal-weight strict dominance. ∎

**Guarantees.** Feasibility: yes. Optimum value: yes. At least one optimum:
yes. All optimizer identities: yes under strict weight improvement; no general
claim under equal weight and strict containment.

The audit records the dominator, exact weight relation, and any identity class
whose complete reconstruction is no longer certified.

## Proposition P3: duplicate residual coverage

**Statement.** Suppose a nonmandatory group `D` has identical residual
coverage:

\[
  R_s^Q=R_t^Q\quad(s,t\in D).
\]

Retain the stable minimum-weight representative. Every strictly heavier member
may be deleted. If several minimum-weight members tie, retain one stable
representative and store the full equal-weight substitution class.

**Assumptions.**

1. Every group member is nonfixed and has strictly positive exact weight.
2. Coverage equality is computed on the current residual requirement set.
3. Previously removed requirements are already covered by selections that are
   fixed in every feasible lift.
4. No side constraint distinguishes identities within the duplicate class.

**Proof.** Any one member of `D` covers exactly the same residual rows as any
other. Replacing a selected member by a minimum-weight representative preserves
feasibility and cannot increase the objective. Because all group weights are
positive, no optimum selects two group members: deleting either one would
leave the same residual coverage and strictly reduce cost.

A strictly heavier member therefore belongs to no optimum, so removing it
preserves all optimizer identities. For equal-weight minimum members,
substitution in either direction preserves coverage and objective exactly.
The reduced variable loses literal source identities, but every original
optimizer is recovered by replacing a selected representative with each
member of its recorded equal-weight class. The choices for disjoint duplicate
classes combine by Cartesian product. ∎

**Guarantees.** Feasibility: yes. Optimum value: yes. At least one optimum:
yes. Strictly heavier duplicates: all optimizer identities preserved without
reconstruction. Equal-weight duplicates: literal reduced identities are not
preserved, but all original optimizer identities are recoverable through the
explicit map.

The implementation exposes this map as `equal_coverage_choices` and the
function `reconstruct_equal_coverage_ties`. That function deliberately does
not claim to reconstruct identities lost by P2's equal-weight strict
dominance.

## Proposition P4: forced-selection propagation

**Statement.** After a strategy or representative class is fixed to one,
remove every residual requirement it covers, add its exact weight to the
objective offset, and recompute P1, P2, P3, P5, and P6 on the resulting
residual incidence matrix. Repeating this process to a fixed point preserves
the guarantees of the constituent rules.

**Assumptions.** Each fixed selection is justified by mandatory semantics or
P1, and all reconstruction maps accumulated before propagation are retained.

**Proof.** Every removed row is already satisfied by a strategy fixed in every
feasible lifted solution. Removing such a row cannot admit an infeasible lift.
Conversely, every residual feasible solution becomes feasible for the prior
model when the fixed strategy is restored. Exact additive objective accounting
gives the offset identity. Recomputing rules is necessary because residual
coverage equalities, empty columns, duplicate carrier rows, and dominance
relations can change when satisfied rows disappear. Composition of the valid
single-step correspondences preserves feasibility, optimum value, and a
liftable optimum. Optimizer-identity recovery is the composition of the stored
maps, subject only to P2's explicit equal-weight boundary. ∎

**Guarantees.** Feasibility: yes. Optimum value: yes. At least one optimum:
yes. All optimizer identities: exactly to the extent certified by the rules
that fired; equal-weight strict dominance remains the only accepted rule here
without a complete identity reconstruction guarantee.

## Proposition P5: empty residual contribution

**Statement.** If a nonmandatory available strategy has

\[
 R_s^Q=\varnothing,
\]

then it may be deleted.

**Assumptions.** The strategy is not fixed or mandatory, all requirements
removed from `Q` are covered by fixed selections, and `w_s>0` exactly.

**Proof.** Selecting `s` covers no residual requirement. Removing it from any
feasible selection preserves feasibility and lowers the objective by the
strictly positive amount `w_s`. Hence no optimum contains `s`. ∎

**Guarantees.** Feasibility: yes. Optimum value: yes. At least one optimum:
yes. All optimizer identities: yes, because no optimizer contains the removed
column.

## Proposition P6: duplicate carrier rows

**Statement.** If two residual tagged requirements `u,v` have identical
carrier sets over the current available columns,

\[
 \{s\in A:u\in R_s^Q\}
 =
 \{s\in A:v\in R_s^Q\},
\]

then one row may be retained as a stable representative and the other merged
into it.

**Assumptions.** Previously fixed selections have been propagated; hence no
remaining row is already satisfied by a fixed column. Carrier equality is
exact and is evaluated on the same available variable set.

**Proof.** The two covering inequalities have the same left-hand side and the
same unit lower bound. They are logically identical. Removing either one
leaves the feasible binary selections unchanged, so objectives and optimizer
identities are also unchanged. ∎

**Guarantees.** Feasibility: yes, with the complete feasible selection set
unchanged. Optimum value: yes. At least one optimum: yes. All optimizer
identities: yes. The requirement reconstruction map records every merged tag
and its retained representative.

## Guarantee summary

| Rule | Feasibility | Optimum value | At least one optimum | All original optimizer identities |
|---|---|---|---|---|
| Mandatory initialization | Yes | Yes, with offset | Yes | Yes |
| P1 unique residual carrier | Yes | Yes, with offset | Yes | Yes; duplicate identity classes use P3 map |
| P2 dominance, `w_t < w_s` | Yes | Yes | Yes | Yes |
| P2 dominance, `w_t = w_s`, strict coverage | Yes | Yes | Yes | No general claim |
| P3 duplicate, heavier member | Yes | Yes | Yes | Yes |
| P3 duplicate, equal minimum weight | Yes | Yes | Yes | Recoverable through explicit map; not literal in reduced variables |
| P4 forced propagation | Yes | Yes, with offset | Yes | Inherits constituent-rule boundary |
| P5 empty residual contribution | Yes | Yes | Yes | Yes |
| P6 duplicate carrier rows | Yes; exact feasible set | Yes | Yes | Yes |

## Fixed-point theorem

**Proposition P7.** The implemented preprocessing algorithm terminates and its
residual model is a fixed point of P1--P6.

**Proof.** Mandatory initialization is performed once. Every subsequent
successful rule application removes at least one available strategy or one
residual requirement; forced selection removes a strategy and then at least
its triggering requirement. The source carriers are finite, so only finitely
many successful applications are possible. After each application the stable
scan restarts. Termination without an infeasibility certificate therefore
means no duplicate carrier row, unique residual carrier, empty contribution,
duplicate coverage class, or valid strict dominance pair remains. Running the
preprocessor on that residual model performs no transformation and has zero
additional objective offset. ∎

The deterministic rule order is:

1. initialize and propagate explicitly mandatory strategies;
2. merge duplicate residual requirement rows;
3. fail closed on a zero-carrier row;
4. force the first stable unique residual carrier and propagate it;
5. remove the first stable empty-contribution column;
6. reduce the first stable duplicate-coverage class; and
7. remove the first stable strictly coverage-dominated column, preferring the
   lowest exact dominator weight, then broader coverage, then source order.

The scan restarts after every transformation. This is fixed-point iteration,
not a single pass.

## Implementation and audit contract

`ExactTaggedCoverModel` stores the exact incidence matrix, exact rational
weights, strategy identifiers, requirement tags, and mandatory flags.
`exact_tagged_cover_model` constructs it from the identity-closure
`TaggedCoverRepresentation`. Nonmandatory zero or negative weights and all
floating-point weights are rejected.

`preprocess_tagged_cover` returns:

- the residual exact covering model;
- original indices for every retained row and column;
- the mandatory and P1-forced original strategy indices;
- the exact objective offset;
- equal-weight duplicate reconstruction classes;
- a status and immediate elimination target for every original strategy;
- a status and representative for every original requirement;
- a feasibility flag;
- a conservative flag stating whether all optimizer identities are
  reconstructable by the declared maps; and
- a machine-readable audit with schema
  `tagged-cover-preprocessing-audit-v1`.

The audit records applications, variables removed, and requirements removed
separately for:

- `mandatory_strategy`;
- `mandatory_strategy_propagation`;
- `redundant_requirement`;
- `mandatory_requirement_carrier`;
- `forced_selection_propagation`;
- `empty_contribution`;
- `duplicate_coverage`;
- `coverage_dominance`; and
- `infeasible_requirement`.

Every event records original indices and labels plus rule-specific details.
`lift_preprocessed_tagged_selection` restores forced strategies and retained
residual selections in original source order. The lifted library must still be
passed through the existing exact original-problem certificate before a
solver or algorithm result is reported: mandatory inactive retention, exact
frontier equality, exact identity closure, and exact burden remain separate
postchecks. Preprocessing certifies no solver status or global optimality by
itself.

## Exact validation

`julia/test/test_tagged_cover_preprocessing.jl` contains adversarial fixtures
for every rule and the equal-weight dominance nonpreservation boundary. It
exhaustively enumerates both the original and reduced binary models, compares
exact optimum values, lifts every reduced optimum, reconstructs duplicate
ties, and—whenever the audit claims complete reconstruction—compares the full
original optimizer identity set.

The seeded randomized audit uses a fixed `MersenneTwister` seed and 512 small
exact instances. Each incidence system is realizable as a zero-frontier,
identity-closure module cover: the mandatory inactive column covers the
frontier row, while positive-weight active columns carry the module rows.
Every original and residual binary selection is enumerated. The targeted test
run passes 9,433 assertions. This is exact bounded computation, not a
universal proof or runtime study.

## Claim boundary and remaining risks

- The semantic result applies to identity closure because the tagged
  per-module representation does. It does not establish preprocessing rules
  for complementary nonidentity closure.
- Requirement tags remain source-defined. Recomputing the source frontier or
  source closure after column removal would change the problem and is not part
  of these rules.
- Equal-weight strict dominance has no all-optimizer-identity guarantee. The
  implementation marks that loss rather than manufacturing a reconstruction.
- The rules assume a pure covering objective with additive positive
  nonmandatory weights. Identity-sensitive side constraints require separate
  proofs.
- No held-out financial information, solver tolerance, floating-point weight,
  randomized-study result, or licensed row enters preprocessing.
- The tests establish correctness on declared finite instances. The universal
  claims rest on the human proofs above; no Lean formalization is asserted.
