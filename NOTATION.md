# Notation and Naming Registry

## Authority

This file is the source of truth for the accepted finite model's mathematical
notation and Lean/Julia identifiers. Some names are implemented and others
remain planned; the status is recorded in `FORMALIZATION_MAP.md`. The entries
are definition locks. Any semantic change requires a new decision record and
synchronized updates to the model, assumptions, formalization map, and theorem
ledger.

## Finite carriers and probability objects

| Canonical concept | Manuscript notation | Planned Lean name | Planned Julia name | Accepted definition |
|---|---|---|---|---|
| hidden market state | \(X=\operatorname{Fin}(m)\), \(x\in X\) | `HiddenState` | `HiddenState` | finite hidden state, with \(2\le m\) |
| belief-grid type | \(B\), \(b\in B\) | `Belief` | `Belief` | nonempty finite information-state type |
| exact rational distribution | \(\Delta_{\mathbb Q}(A)\) | `RatProb` | `RatProb` | nonnegative rational mass function summing to one |
| belief interpretation | \(\mu_b\) | `beliefMass` | `belief_mass` | exact distribution on \(X\) associated with \(b\) |
| belief transition kernel | \(P_B(b,b')\) | `beliefKernel` | `belief_kernel` | rational Markov kernel \(B\to\Delta_{\mathbb Q}(B)\) |
| discount factor | \(\beta\) | `discount` | `discount` | rational number satisfying \(0\le\beta<1\) |
| finite horizon | \(h,H\in\mathbb N\) | `calendarHorizon` | `calendar_horizon` | number of remaining calendar reward dates; Continue consumes one and research consumes \(d_q\) |

`Belief` is a grid label, not an arbitrary probability vector. The map
\(b\mapsto\mu_b\) provides its hidden-state interpretation.

## Strategy and library objects

| Canonical concept | Manuscript notation | Planned Lean name | Planned Julia name | Accepted definition |
|---|---|---|---|---|
| strategy identifier | \(S\), \(s\in S\) | `StrategyId` | `StrategyId` | nonempty finite identifier type |
| module identifier | \(M\), \(m\in M\) | `ModuleId` | `ModuleId` | nonempty finite capability type |
| strategy data | \(\sigma_s=(s,u_s,\operatorname{mods}(s))\) | `StrategyData` | `StrategyData` | immutable payoff and module row indexed by `StrategyId` |
| hidden-state payoff | \(u_s(x)\) | `statePayoff` | `state_payoff` | rational payoff of strategy \(s\) in hidden state \(x\) |
| operational profile | \(j_s(b)\) | `operationalProfile` | `operational_profile` | \(\sum_x\mu_b(x)u_s(x)\) |
| strategy modules | \(\operatorname{mods}(s)\) | `strategyModules` | `strategy_modules` | finite module set attached to \(s\) |
| inactive baseline strategy | \(s_0\) | `inactiveStrategy` | `inactive_strategy` | zero-profile, empty-module identifier present in every library |
| raw verified library | \(L\) | `Raw.Library` | `Library` | finite set of strategy identifiers containing \(s_0\) |
| admitted-outcome type | \(\mathcal O=\operatorname{Option}(S)\) | `Raw.CandidateOutcome` | `AdmissionOutcome` | `none` or one verified catalog strategy identifier |
| candidate admission | \(L\oplus o\) | `Raw.rawLibraryUpdate` | `admit_outcome` | no change for `none`; set union for admitted `some(s)` |

A `Strategy` in prose means the catalog row \(\sigma_s\), not a mutable
library object, research project, or raw candidate.

The inactive baseline is an actual strategy row: \(j_{s_0}=0\) and
\(\operatorname{mods}(s_0)=\varnothing\). It is not an empty-maximum default.

## Retention resources

| Canonical concept | Manuscript notation | Planned Lean name | Planned Julia name | Accepted definition |
|---|---|---|---|---|
| strategy resource weight | \(w_s\) | `StrategyResourceWeights.resourceWeight` | `ExactRetentionProblem.weights` | immutable rational catalog primitive with \(w_{s_0}=0\) and \(w_s>0\) for every active \(s\ne s_0\) |
| additive library burden | \(W(L)\) | `Optimization.libraryBurden` | `library_weight` | exact sum \(\sum_{s\in L}w_s\) |
| optional nonadditive burden | \(M(L)\) | `nonadditiveResourceBurden` | `nonadditive_resource_burden` | reserved exact nonnegative set functional with \(M(\{s_0\})=0\); no additivity or monotonicity is implicit |
| optional total burden | \(\widetilde W(L)\) | `totalResourceBurden` | `total_resource_burden` | \(W(L)+M(L)\); extension-only, with Paper 1's primary layer setting \(M\equiv0\) |
| productive parameter bundle | \(\theta\) | planned problem parameter structure | planned optimization configuration | fixed finite raw process, eligible catalog, finite calendar horizon, and terminal-value convention; \(B,\lambda\) remain separate |
| outer-certified retention-eligible catalog | \(S_\theta^{\mathrm{elig}}\) | `EligibleStrategySet` | `eligible_strategy_ids` | finite selectable identifiers containing \(s_0\); outer certification is distinct from raw stochastic verification, and mere raw generation is insufficient |
| admissible library family | \(\mathfrak L(A)\) | `AdmissibleLibrariesOn` | `admissible_libraries` | \(\{L'\subseteq A:s_0\in L'\}\) |
| retained-library domain | \(\mathcal R(L)\) | `Optimization.SublibraryFeasible` | `retained_sublibraries` | admissible sublibraries \(L'\subseteq L\) containing \(s_0\) |
| exact safe-feasible family | \(\mathfrak F_{\mathrm{safe}}(L)\) | `Optimization.SafeCompressionFeasible` | `safe_sublibraries` | \(L'\in\mathcal R(L)\) with \(F_{L'}=F_L\) and \(C_{L'}=C_L\); no local or global optimality condition |
| exact safe-compression problem | \(P_{\mathrm{safe}}(L)\) | `Optimization.MinimumWeightSafeCompression`; `Optimization.exists_minimumWeightSafeCompression` | `minimum_safe_weight_masks` | globally minimize \(W(L')\) over all of \(\mathfrak F_{\mathrm{safe}}(L)\), retaining ties |
| active single deletion | \(K^{-s}\) | existing library erasure | `delete_strategy` | \(K\setminus\{s\}\) for \(s\in K\setminus\{s_0\}\) |
| safe deletion certificate | \(\mathsf{SafeDel}(K,s)\) | `Optimization.ExactSafeDeletion` | planned `SafeDeletionCertificate` | membership/noninactive evidence plus \(F_{K^{-s}}=F_K\) and \(C_{K^{-s}}=C_K\), checked at the current \(K\) |
| feasible safe reduction | \(K'\prec_{\mathrm{safe},L}K\) | planned | planned | \(K',K\in\mathfrak F_{\mathrm{safe}}(L)\) and \(K'\subsetneq K\) |
| one-deletion irreducible library | \(K\in\operatorname{Irr}^{(1)}_{\mathrm{safe}}\) | `Optimization.OneDeletionIrreducible` | `inclusion_irreducible` | no represented active strategy has a current-library `ExactSafeDeletion` certificate; this is local and does not imply global minimality |
| globally minimum-weight safe library | \(K^\star\in\operatorname{Opt}_{\mathrm{safe}}(L)\) | `Optimization.MinimumWeightSafeCompression` | `minimum_safe_weight_masks` | safe-feasible global minimizer of \(W\) over the full family; optimizer set may contain ties |
| hard resource capacity | \(B\) | `Optimization.ResourceBudget`, `Optimization.CapacityFeasible` | `resource_capacity` | nonnegative rational bound \(W(L')\le B\) at the one-time retention decision |
| resource price | \(\lambda\) | real argument of `FinitePenalizedProblem.branch` | `resource_price` | nonnegative rational penalty in the exact problem; arbitrary real argument in the canonical envelope extension |
| productive value | \(V_\theta(b,L)\) | existing finite/stationary value declarations | existing finite/stationary solvers | dynamic value before any retention-resource penalty |
| net retained-library value | \(J_{\theta,\lambda}(b,L)\) | `Optimization.FinitePenalizedProblem.branch` | `net_retention_value` | \(V_\theta(b,L)-\lambda W(L)\), abbreviated \(J_\lambda=V-\lambda W\) when other arguments are fixed |
| capacity-constrained optimal value | \(V^\star(B;b,\theta)\) | `capacityOptimalValue` | `capacity_value` | maximum productive value over \(\mathfrak L(S_\theta^{\mathrm{elig}})\) subject to \(W(L')\le B\) |
| capacity optimizer correspondence | \(\operatorname{Opt}_B(b,\theta)\) | planned | `capacity_optimal_masks` | all value-maximizing feasible libraries; set-valued at ties |
| discrete capacity marginal | \(\Delta_\delta V^\star(B)\) | planned | `discrete_capacity_profile` | \(V^\star(B+\delta)-V^\star(B)\) on a declared rational budget grid; fixtures 5--6 use \(\delta=1\) |
| per-unit capacity shadow | \(s_B^\delta\) | planned | direct exact expression | \([V^\star(B+\delta)-V^\star(B)]/\delta\); nonnegative finite slope, not an ordinary derivative or automatic multiplier |
| forward capacity arc elasticity | \(\varepsilon_{B,\delta}^{V^\star}\) | planned | direct exact expression | \([\Delta_B^\delta V^\star/V^\star(B)][B/\delta]\) for \(B>0\) and positive base value; distinct from midpoint arc elasticity |
| attainable burden set | \(\Omega=\{W(L):L\in\mathcal F\}\) | planned | exact enumeration | finite rational set supporting every capacity threshold |
| best exact-burden value | \(\bar v(\omega)\) | planned | exact enumeration | \(\max\{V_\theta(b,L):L\in\mathcal F,\ W(L)=\omega\}\) |
| capacity-value breakpoint set | \(\mathcal B_C\) | planned | exact filtering pending | positive attainable burdens where \(V^\star(B)>V^\star(B^-)\); optimizer-only tie changes are excluded |
| penalized optimal value | \(J^\star(\lambda;b,\theta)\) | `Optimization.FinitePenalizedProblem.envelope` | `penalized_value` | maximum of \(V_\theta(b,L')-\lambda W(L')\) over one fixed nonempty finite family |
| penalized optimizer correspondence | \(\operatorname{Opt}_\lambda(b,\theta)\) | `Optimization.FinitePenalizedProblem.IsOptimizer`, `.optimizerSet` | `penalized_optimal_masks` | all maximizers at price \(\lambda\); no uniqueness or raw-inclusion nesting is implicit |
| optimal burden selection | \(W^\star_{\mathrm{sel}}(\lambda)\) | `Optimization.FinitePenalizedProblem.selectedOptimizer`, `.selectedBurden_antitone` | exact selection from `penalized_optimal_masks` | burden of one classically chosen optimizer; weakly nonincreasing because every cross-price optimizer pair obeys the burden order |
| forward resource-demand arc elasticity | \(\varepsilon_{\lambda,\delta}^{W^\star}\) | planned | direct exact expression | \([W^\star(\lambda+\delta)-W^\star(\lambda)]/W^\star(\lambda)\times\lambda/\delta\), defined only for positive base price/demand and singleton endpoint burden sets |
| individual penalized branch | \(J_L(\lambda)\) | `Optimization.FinitePenalizedProblem.branch` | direct exact expression | \(V_\theta(b,L)-\lambda W(L)\); affine with slope \(-W(L)\) |
| pairwise switching price | \(\lambda_{12}\) | `Optimization.FinitePenalizedProblem.switchingPrice`, `.pairwiseSwitchingPrices` | enumerated by `penalty_breakpoints` | \([V(L_1)-V(L_2)]/[W(L_1)-W(L_2)]\) when burdens differ; a finite candidate intersection, not necessarily an envelope breakpoint |
| envelope breakpoint set | \(\mathcal B\) | planned | candidate filtering pending | positive prices where globally optimal unequal-burden branches tie and \(J^\star\) has a kink |
| one-sided envelope slopes | \((J^\star)'_-,(J^\star)'_+\) | planned | exact fixture fields | at an interior price, minus the maximum and minimum burdens in \(\operatorname{Opt}_\lambda\), respectively |
| supporting price interval | \(\Lambda(L)\) | planned | `supporting_price_interval` | nonnegative prices at which \(L\) is penalized-optimal; may be empty |
| named level elasticity | \(\varepsilon_x^\mu\) | extension-only | exact fixture formula or separately named routine | \((x/\mu(x))\,d\mu/dx\) only for a declared scalar path and \(\mu(x)>0\); no closure-cardinality shorthand |
| operational channel elasticity | \(\varepsilon_x^{\mathrm{op}}\) | planned | not assigned | \(x(\Delta^{\mathrm{op}})'/\Delta^{\mathrm{op}}\) on a common differentiable T5 path, used only when the operational level is positive |
| generative channel elasticity | \(\varepsilon_x^{\mathrm{gen}}\) | planned | not assigned | \(x(\Delta^{\mathrm{gen}})'/\Delta^{\mathrm{gen}}\) on the same path, used only when the generative level is positive |
| operational elasticity contribution | \(C_x^{\mathrm{op}}\) | planned | not assigned | \([x/I(x)]\,d\Delta^{\mathrm{op}}(x)/dx\) with \(I(x)>0\); remains defined at zero or negative operational level |
| generative elasticity contribution | \(C_x^{\mathrm{gen}}\) | planned | not assigned | \([x/I(x)]\,d\Delta^{\mathrm{gen}}(x)/dx\); \(C_x^{\mathrm{op}}+C_x^{\mathrm{gen}}=\varepsilon_x^I\) |
| library-objective margin | \(\Gamma_{\mathcal L}(x)\) | planned | not assigned | best minus second-best library objective, counting one branch per raw library; positive exactly at a unique optimizer |
| Bellman action margin | \(\Gamma_{\mathcal A}(x)\) | planned | not assigned | best minus second-best feasible action value; positive exactly at a unique current action |
| library/action switching boundaries | \(\mathcal B_{\mathcal L},\mathcal B_{\mathcal A}\) | planned | actual-breakpoint filter not assigned | parameter points where the corresponding optimizer set is not locally constant; zero margin is necessary but persistent identical-branch ties are excluded |
| left/right elasticity | \(\varepsilon_{x,-}^{Y},\varepsilon_{x,+}^{Y}\) | planned | exact finite probes only | \(xD_-Y/Y\) and \(xD_+Y/Y\) at a positive common value |
| midpoint arc elasticity | \(\varepsilon_{[x_-,x_+]}^{\mathrm{arc}}[Y]\) | planned | direct exact expression | symmetric percentage finite change \([(x_++x_-)/(Y_++Y_-)] [(Y_+-Y_-)/(x_+-x_-)]\), with positive endpoints for ordinary interpretation |
| switching distance | \(r_{\mathcal L}(x),r_{\mathcal A}(x)\) | planned | actual-breakpoint distance not assigned | distance to the nearest globally active library or action boundary; \(+\infty\) when none exists |
| normalized switching fragility | \(\mathcal F_{\mathcal L}^{\mathrm{sw}},\mathcal F_{\mathcal A}^{\mathrm{sw}}\) | planned | not assigned | \(x/r(x)\), infinite at a breakpoint and zero when no breakpoint exists; distinct from innovation-margin fragility |
| conditional replacement library | \(L^{c,D}\) | `replacementLibrary` | `replacement_library` | \((L\setminus D)\cup\{c\}\), with outer-certified \(c\notin L\) and \(D\subseteq L\setminus\{s_0\}\) |
| replacement capacity deficit | \(\kappa_c(L,B)\) | planned | direct exact expression | \([W(L)+w_c-B]_+\); feasible deletion sets satisfy \(W(D)\ge\kappa_c\) |
| capacity-feasible deletion family | \(\mathcal D_c(B;L)\) | planned | exact enumeration in audit script | active-incumbent deletion sets \(D\) with \(W(L^{c,D})\le B\) |
| optimal deletion correspondence | \(\mathcal D_c^\star(b,L,B)\) | planned | exact enumeration in audit script | all capacity-feasible \(D\) maximizing \(V_\theta(b,L^{c,D})\) |
| unconstrained candidate gain | \(G_c(b,L)\) | planned | direct exact expression | \(V_\theta(b,L\cup\{c\})-V_\theta(b,L)\) |
| candidate-relative displacement loss | \(\ell_c(b,L;D)\) | planned | direct exact expression | \(V_\theta(b,L\cup\{c\})-V_\theta(b,L^{c,D})\) |
| least required displacement loss | \(\ell_c^\star(b,L,B)\) | planned | exact enumeration | minimum \(\ell_c(D)\) over \(\mathcal D_c(B;L)\) |
| net admission value | \(A_c(b,L,B)\) | planned | direct exact expression | \(V_\theta(b,L^{c,D^\star})-V_\theta(b,L)=G_c-\ell_c^\star\); acceptance test only when retaining \(L\) is the declared feasible outside option |
| resource-augmented outer summary | \(K_L^W\) | `ResourceAugmentedInnovationState` | `ResourceAugmentedInnovationState` | \((F_L,C_L,W(L))\), used by the outer optimizer and not by the raw transition |
| canonical bridge gross opportunity | \(A_{\mathrm{br}}=\beta^d\rho^d\pi C\) | existing T4 scalar expression | direct exact expression | gross attainable descendant value in the T4 bridge construction; abbreviated \(A\) only inside BRIDGE_ELASTICITY_SPEC.md |
| signed bridge innovation margin | \(M_{\mathrm{br}}=A_{\mathrm{br}}-\kappa\) | existing T4 scalar expression before the positive-part envelope | direct exact expression | latent research-versus-Continue action gap; abbreviated \(M\) only inside BRIDGE_ELASTICITY_SPEC.md; realized pruning loss is \([M_{\mathrm{br}}]_+\) |
| normalized bridge margin | \(m_{\mathrm{br}}=M_{\mathrm{br}}/A_{\mathrm{br}}\) | extension-only | direct exact expression | signed gross-normalized action margin when \(A_{\mathrm{br}}>0\); ordinary margin elasticity additionally requires \(M_{\mathrm{br}}>0\) |
| innovation-margin fragility | \(\mathcal F_{\mathrm{br}}=1/m_{\mathrm{br}}=A_{\mathrm{br}}/M_{\mathrm{br}}\) | extension-only | not assigned | dimensionless positive-margin elasticity-amplification factor, defined only for \(M_{\mathrm{br}}>0\); distinct from optimizer-switching fragility |

The symbol \(W(L)\) is reserved for retention burden when its argument is a
library. It is not the abstract value \(W_h(b,K)\), the abstract library value
\(W_h(b,L)\), or a discounted occupation matrix \(W_H^{\beta,\rho}\).
Arguments and subscripts must remain visible whenever those objects occur near
one another.

The module carrier \(M\) and the optional set functional \(M(L)\) are
distinguished by syntax. In a display where the distinction is not immediate,
write the latter as \(M_{\mathrm{na}}(L)\).

The bare scalar symbols \(A,M,m\) in BRIDGE_ELASTICITY_SPEC.md are local
abbreviations for \(A_{\mathrm{br}},M_{\mathrm{br}},m_{\mathrm{br}}\).
Use the decorated forms outside that specification so the bridge margin is not
confused with the module carrier \(M\), the nonadditive burden \(M(L)\), or the
replacement admission value \(A_c\).

## Frontier, closure, and compression

| Canonical concept | Manuscript notation | Planned Lean name | Planned Julia name | Accepted definition |
|---|---|---|---|---|
| operational frontier | \(F_L(b)\) | `operationalFrontier` | `operational_frontier` | upper-envelope value \(\max_{s\in L}j_s(b)\) |
| raw module union | \(U_L\) | `rawModuleUnion` | `raw_module_union` | \(\bigcup_{s\in L}\operatorname{mods}(s)\) |
| module closure operator | \(\operatorname{cl}\) | `moduleClosure` | `module_closure` | extensive, monotone, idempotent map on finite module sets |
| generative closure | \(C_L\) | `generativeClosure` | `generative_closure` | \(\operatorname{cl}(U_L)\) |
| compressed innovation state | \(K_L=(F_L,C_L)\) | `InnovationState` | `InnovationState` | frontier/closure pair |
| realizable compressed states | \(\mathcal K\) | `RealizableInnovationState` | `RealizableInnovationState` | finite image of `Library` under \(K\) |
| realizable frontier--closure predicate | \((F,C)\in\mathcal K\) | `RealizableFrontierClosure` | not assigned | existence of an admissible library with frontier \(F\) and closure \(C\) |
| admitted-outcome state update | \(\operatorname{addK}(K,o)\) | `Raw.addCompressedState` | `apply_innovation_outcome` | identity for `none`; for `some(s)`, pointwise frontier maximum and closure of current closure union \(\operatorname{mods}(s)\) |
| semi-Markov innovation signature | \(\Sigma_L^{\mathrm{SM}}\) | `semiMarkovInnovationSignature` | `semi_markov_innovation_signature` | frontier plus project availability, initiation cost, duration, operation flag, and terminal joint belief/admission law \(\Xi_q\); the Markov path marginal is common data |
| marginal compressed transition | \(\overline T_q(K'\mid b,K)\) | `compressedOutcomeTransition` | `compressed_outcome_transition` | pushforward of \(\Gamma(q,b,C)\) through \(o\mapsto\operatorname{addK}(K,o)\) |
| joint compressed completion law | \(\overline{\mathcal Q}_q(b',K'\mid b,K)\) | `compressedCompletionTransition` | `compressed_completion_transition` | pushforward of the terminal belief/outcome law through `addK`; not generally a product law |
| abstract research kernel | \(T(b,K,q)\) | `FiniteResearchSemantics.researchTransition` | not assigned | exact finite-support distribution on next ambient compressed states |
| modular generator | \(g(b,F,C,q)\) | `ModularGenerator.candidateTransition` | not assigned | abstract next-state law with frontier and closure as its only library summaries |
| generator factorization | \(T(b,(F,C),q)=g(b,F,C,q)\) | `GeneratorFactorsThroughFrontierClosure` | not assigned | exact factorization through the two compressed-state components |
| closure identifiability | \(C\ne C'\Rightarrow\exists b,q:g(b,F,C,q)\ne g(b,F,C',q)\) | `ClosureIdentifiable` | not assigned | project separation of distinct realizable closures at a common frontier |
| operational equivalence | \(L\sim_{\mathrm{op}}L'\) | `OperationallyEquivalent` | not assigned | equal frontier values at every belief |
| unified dynamic innovation equivalence | \(L\sim_{\mathrm{DI}}L'\) | `Projection.Model.DynamicInnovationEquivalent` | not assigned | equality of frontier and availability-tagged cost, duration, joint terminal belief/compressed-state law, and expected operating-reward observations |
| unified dynamic innovation class | \([L]_{\mathrm{DI}}\) | `Projection.Model.DynamicInnovationQuotient` | not assigned | finite quotient of admissible raw libraries by unified \(\sim_{\mathrm{DI}}\) |
| deprecated primitive DI equivalence | \(L\sim_{\mathrm{DI}}^{\mathrm{prim}}L'\) | `StrategyInnovation.DynamicInnovationEquivalent` | not assigned | legacy F1 equality of frontier and cost-free primitive research kernels; superseded as a final-model interface |

The frontier stores values, not maximizing identifiers. The closure stores
capabilities, not strategies. The compressed state is not called a generic
minimal bisimulation quotient.

## Research, generation, and verification

| Canonical concept | Manuscript notation | Planned Lean name | Planned Julia name | Accepted definition |
|---|---|---|---|---|
| research-project type | \(Q\), \(q\in Q\) | `ResearchProject` | `ResearchProject` | nonempty finite project type |
| idle action | \(\bot\) | `ResearchAction.idle` | `IdleResearch` | zero-cost, no-candidate action |
| project prerequisite | \(\operatorname{req}(q)\) | `projectRequirements` | `project_requirements` | finite module set required by \(q\) |
| raw candidate kernel | \(G(q,b,C)\) | `Raw.CandidateGenerationDistributions.distribution` | `candidate_kernel` | exact distribution on `Option StrategyId` before verification |
| raw candidate | \(\operatorname{some}(s)\) under \(G\) | `RawCandidate` | `RawCandidate` | generated strategy identifier not yet admitted |
| verification probability | \(\nu(q,b,C,s)\) | `Raw.AdmissionProbabilities.probability` | `verification_prob` | exact rational pass probability |
| verified candidate | \(\operatorname{some}(s)\) under \(\Gamma\) | `VerifiedCandidate` | `VerifiedCandidate` | candidate that passed verification and may be admitted |
| admitted-candidate kernel | \(\Gamma(q,b,C)\) | `Raw.admittedCandidateDistribution` | `admitted_kernel` | generation kernel composed with verification |
| project/verification cost | \(\kappa_q(b,K)\) | `projectCost` | `project_cost` | nonnegative rational total cost paid once at project initiation |
| available projects | \(Q(K)\) | `availableProjects` | `available_projects` | finite projects selectable at compressed decision state \(K\) |
| research duration | \(d_q\in\mathbb N_0\) | `researchDuration` | `research_duration` | full elapsed calendar periods from initiation through completion |
| operation flag | \(o_q\in\{0,1\}\) | `incumbentOperates` | `incumbent_operates` | one by default; zero only for explicitly suspending research |
| belief-path law | \(\mathbb P_b^{(d_q)}(\mathbf b)\) | `beliefPathProb` | `belief_path_prob` | product of the one-period belief kernel along a length-\(d_q\) path |
| joint raw completion coupling | \(\Lambda_q(\mathbf b,o\mid b,K)\) | `rawCompletionCoupling` | `raw_completion_coupling` | joint belief-path/admitted-outcome law with marginals \(\mathbb P_b^{(d_q)}\) and \(\Gamma(q,b,C)\) for \(K=(F,C)\) |
| terminal belief/outcome law | \(\Xi_q(b',o\mid b,K)\) | `terminalOutcomeLaw` | `terminal_outcome_law` | terminal marginal of \(\Lambda_q\); no independence is implicit |
| raw decision dates | \(\tau_n\) | `decisionTime` | `decision_time` | embedded calendar dates at which Continue or a new project may be selected |
| raw embedded state | \(Y_n=(B_{\tau_n},L_n)\) | `RawDecisionState` | `RawDecisionState` | belief and raw library at a decision epoch |
| compressed embedded state | \(Z_n=(B_{\tau_n},K_{L_n})\) | `CompressedDecisionState` | `CompressedDecisionState` | controlled semi-Markov projection of the raw decision state |

`RawCandidate`, `VerifiedCandidate`, and `StrategyId` may share a finite
payload in the implementation, but they have different semantic wrappers and
must not be silently identified.

The admitted law \(\Gamma\) is a marginal derived from \(G\) and \(\nu\).
The coupling \(\Lambda_q\), and hence the joint terminal law \(\Xi_q\), is
separate declared data. The notation never makes
\(B_{d_q}\perp O_q\mid(b,K,q)\) implicit. Under the optional independence
specialization only,
\(\overline{\mathcal Q}_q=P_B^{d_q}\otimes\overline T_q\).

## Value and coverage

| Canonical concept | Manuscript notation | Planned Lean name | Planned Julia name | Accepted definition |
|---|---|---|---|---|
| raw finite-horizon value | \(V_h^{\mathrm{raw}}(b,L)\) | `rawCalendarValue` | `raw_calendar_value` | unified semi-Markov Bellman recursion on belief and raw library with \(h\) calendar dates remaining |
| compressed finite-horizon value | \(\bar V_h(b,K)\) | `compressedCalendarValue` | `compressed_calendar_value` | pushforward Bellman recursion on belief and realizable \(K\) with \(h\) calendar dates remaining |
| abstract compressed value | \(W_h(b,K)\) | `compressedFiniteHorizonValue` | not assigned | cost-free supporting recursion under primitive abstract research transitions |
| abstract library value | \(W_h(b,L)\) | `dynamicLibraryValue` | not assigned | abstract compressed value evaluated at `compressedLibraryState` |
| T5 passive library value | \(P_n(b,L)\) | `Projection.Model.UnifiedDecomposition.passiveValue` | `passive_value` (supporting primitive adapter only) | unified Continue-only value with the raw library frozen |
| T5 full library value | \(U_n(b,L)\) | `Projection.Model.UnifiedDecomposition.fullValue` | `full_value` (supporting primitive adapter only) | optimized T1 raw value |
| T5 research-option premium | \(\Omega_n(b,L)\) | `Projection.Model.UnifiedDecomposition.researchOptionPremium` | `research_option_premium` (supporting primitive adapter only) | \(U_n(b,L)-P_n(b,L)\) |
| T5 total insertion value | \(\mathcal I_n(s\mid b,L)\) | `Projection.Model.UnifiedDecomposition.totalInsertionValue` | `total_innovation` (supporting primitive adapter only) | \(U_n(b,L\cup\{s\})-U_n(b,L)\) |
| T5 operational insertion value | \(\Delta^{\mathrm{op}}_n(s\mid b,L)\) | `Projection.Model.UnifiedDecomposition.operationalInsertionValue` | `operational_innovation` (supporting primitive adapter only) | passive-value insertion difference |
| T5 generative insertion value | \(\Delta^{\mathrm{gen}}_n(s\mid b,L)\) | `Projection.Model.UnifiedDecomposition.generativeInsertionValue` | `generative_innovation` (supporting primitive adapter only) | research-premium insertion difference |
| T6 operating-timing adjustment | \(A^{\mathrm{op}}_{q,h}(b,L)\) | `Projection.Model.GenerativeLowerBound.operatingResearchAdjustment` | `generative_strategy_lower_bound` keyword `operating_adjustment` | expected incumbent reward plus discounted frozen passive continuation, less current passive value |
| T6 joint descendant mass | \(\eta_{q,g}(b'\mid b,K)\) | `Projection.Model.GenerativeLowerBound.jointDescendantMass` | `search_joint_descendant_bound.jl` joint-law matrices | terminal pushforward probability of \(B_d=b'\) and admitted outcome `some g`; no independence required |
| T6 expected joint descendant gain | \(\sum_{b'}\eta_{q,g}(b')G(b')\) | `Projection.Model.GenerativeLowerBound.expectedJointDescendantGain` | `joint_bound` | exact distinguished-event expectation under the unified completion coupling |
| T6 terminal expected gain | \(\overline G_{q,d}(b)\) | `Projection.Model.GenerativeLowerBound.expectedTerminalGain` | exact fixture field `expected_completion_gain` | finite Markov path expectation, equal to the terminal-occupation-weighted sum |
| T6 joint generative guarantee | \(\underline\Delta^{\mathrm{gen,joint}}_{q,h}\) | `Projection.Model.GenerativeLowerBound.jointGenerativeLowerBound` | `joint_bound` | \(\max\{-\kappa+A^{op}+\beta^d\sum_{b'}\eta_{q,g}(b')G(b'),0\}\) |
| T6 product-specialized guarantee | \(\underline\Delta^{\mathrm{gen}}_{q,h}\) | `Projection.Model.GenerativeLowerBound.generativeLowerBound` | `generative_strategy_lower_bound` | independence corollary \(\max\{-\kappa+A^{op}+\beta^d\pi\rho^d\overline G,0\}\) |
| F7 frontier gap | \(\Delta_{s,L}(b)\) | `InnovationEquation.frontierGap` | `frontier_gap` | \(\max\{j_s(b)-F_L(b),0\}\) |
| F7 discounted gap sum | \(G_n(b;L,s)\) | `InnovationEquation.discountedGapSum` | `discounted_gap_sum` | exact finite recursive form of \(\mathbb E_b[\sum_{t<n}\beta^t\Delta_{s,L}(B_t)]\) |
| F7 passive operational innovation | \(\Delta^{\mathrm{op}}_n(s\mid b,L)\) | `InnovationEquation.passiveOperationalInnovation` | `passive_operational_innovation` | supporting primitive-adapter analogue of the T5 operational insertion value |
| unified Continue operator | \(\mathcal C\) | `SemiMarkov.continueValue` | `semi_markov_continue_value` | current frontier plus one-period discounted continuation at unchanged \(K\) |
| unified research operator | \(\mathcal R_q\) | `SemiMarkov.researchValue` | `semi_markov_research_value` | initiation cost, full incumbent reward path, and duration-discounted joint completion value |
| unified Bellman operator | \(\mathcal T\) | `SemiMarkov.bellmanOperator` | `semi_markov_bellman_operator` | finite maximum of unified Continue and available research actions |
| legacy F5/F8 continue operator | \(\mathsf C^{\mathrm{old}}\) | `BellmanContraction.continueOperator` | `continue_action_value` | existing implemented primitive-timing operator; retained only until migration |
| legacy F5/F8 research operator | \(\mathsf R_q^{\mathrm{old}}\) | `BellmanContraction.researchOperator` | `research_action_value` | existing cost-plus-\(\beta^{\ell_q+1}\) operator that omits incumbent research-period rewards |
| legacy F5/F8 Bellman operator | \(\mathsf T^{\mathrm{old}}\) | `BellmanContraction.bellmanOperator` | `bellman_operator` | existing implemented maximum under the pre-migration convention |
| F8 infinite-horizon value | \(V_\infty\) | `BellmanContraction.infiniteHorizonValue` | `value_iteration` output | unique real fixed point of the primitive finite-state Bellman operator |
| S4 occupation weight | \(\omega_t(b,b')\) | `Coverage.OccupationWeights.weight` | not assigned | exact nonnegative date-\(t\) occupation of \(b'\) from \(b\) |
| S4 discounted occupation | \(W_H^{\beta,\rho}(b,b')\) | `Coverage.discountedOccupationWeight` | not assigned | \(\sum_{t<H}\beta^t\rho^t\omega_t(b,b')\) |
| S4 coverage potential | \(\Psi_H(q,K,b)\) | `Coverage.coveragePotential` | not assigned | exact finite sum \(\sum_{b'}W_H^{\beta,\rho_q}(b,b')\Delta(q,K,b')\) |
| S6 effective discount | \(\alpha=\beta\rho\) | `Coverage.DiscountSurvivalInteraction.effectiveDiscount` | local `effective_discount` | product of patience and candidate survival |
| S6 truncated resolvent | \(U_{\alpha,H}\) | `Coverage.DiscountSurvivalInteraction.finiteResolvent` | `finite_discounted_occupation` | \(\sum_{t<H}\alpha^tP^t\); not the infinite inverse |
| S6 finite matrix potential | \(\Psi_H(\beta,\rho)\) | `Coverage.DiscountSurvivalInteraction.finiteHorizonPotential` | `finite_coverage_potential` | \(U_{\beta\rho,H}g\) for a nonnegative gap vector |
| S7 parameterized persistence kernel | \(P(\theta)\) | `Coverage.KernelComparativeStatics.persistenceKernel` | `persistence_adjusted_kernel` | exact symmetric two-state family \(\theta I+(1-\theta)P_{\mathrm{switch}}\) in the sign witnesses |
| S7 discounted kernel occupation | \(W^P_{H,\alpha}(b,b')\) | `Coverage.KernelComparativeStatics.discountedOccupation` | response-surface field `advantage_occupation` | \(\sum_{t<H}\alpha^t(P^t)(b,b')\) |
| S7 gap-tailored kernel order | \(P_1\succeq_gP_0\) | `Coverage.KernelComparativeStatics.GapOccupationDominates` | response-surface coverage comparison | pointwise order of \(\sum_{t<H}\alpha^tP^tg\); not a scalar persistence order |
| T7 closure value increment | \(\Delta_CV_h(F;C_1,C_0)\) | `Projection.Model.SystemInteraction.compressedClosureIncrement` | `closure_increment` / `closure_increment0,1` | \(V_h(F,C_1)-V_h(F,C_0)\) on realizable compressed states |
| T7 frontier--closure interaction | \(J_h\) | `Projection.Model.SystemInteraction.compressedInteractionCrossDifference` | `interaction_cross_difference` / `interaction` | high-frontier closure increment minus low-frontier closure increment; \(J\le0\) substitution, \(J\ge0\) complementarity |
| T7 relative action saturation | equation \((\mathrm{RS})\) | `Projection.Model.SystemInteraction.RelativeActionSaturation` | canonical witnesses and exact surface classifications | pairwise Bellman-action single crossing; stronger than individual candidate saturation |
| S5 expected certified gap | \((P\Delta)(b)\) | `Coverage.expectedGap` | `gross_coverage_value` input | exact finite expectation \(\sum_{b'}P(b,b')\Delta(b')\) on the ordered grid |
| S5 gross single-gap value | \(G(b)\) | `Coverage.grossCoverageValue` | `gross_coverage_value` | \(\beta p(b)(P\Delta)(b)\) before research cost |
| S5 one-shot cost-covering set | \(\mathcal C\) | `Coverage.oneShotCostCoveringSet` | `cost_covering_set` | \(\{b:\kappa(b)\le G(b)\}\); not the optimal Bellman research region |
| S5 finite upper cutoff | \(b^*\) | existential witness in `Coverage.monotoneGap_upperThreshold` | `extract_threshold` | when \(\mathcal C\ne\varnothing\), the finite-grid representation \(\mathcal C=\operatorname{Ici}(b^*)\) |
| frozen operational baseline | \(O_h(b,K)\) | `operationalBaseline` | `operational_baseline` | Continue-only value with the current compressed library state fixed |
| innovation premium | \(I_h(b,K)\) | `innovationPremium` | `innovation_premium` | \(V_h(b,K)-O_h(b,K)\) |
| legacy incumbent research prefix | \(A_q(b,K)\) | `incumbentRewardPrefix` | `incumbent_reward_prefix` | pre-T6 planning symbol; superseded by the exact unified `operatingResearchAdjustment` |
| legacy descendant-event operational gain | \(D_{q,g,h}(b,K)\) | `descendantEventGain` | `descendant_event_gain` | pre-T6 planning symbol; superseded by `completionContinuationGain` and `expectedTerminalGain` |
| primitive generator independence | \(\mathsf{GI}\) | `PrimitiveFrontierIndependent` | `primitive_frontier_independent` | availability, cost, duration, operation flag, and joint completion coupling depend on \((q,b,C)\), not frontier \(F\), at every descendant state |
| frontier--closure substitutability | \(F^-\le F^+\Rightarrow I_h(b,(F^+,C))\le I_h(b,(F^-,C))\) | `innovationPremium_antitone_frontier` | `innovation_premium_antitone_frontier` | T7's precise value-order conclusion under primitive generator independence |
| candidate gap | \(\Delta_{g,L}(b)\) | `candidateGap` | `candidate_gap` | \(F_{L\cup\{g\}}(b)-F_L(b)\) |
| project success probability | \(p_q(b,C)\) | `projectSuccessProb` | `project_success_prob` | admitted probability of the unique T6 candidate |
| legacy one-gap coverage region | \(\mathcal C_{q,g}(L)\) | `coverageRegion` | `coverage_region` | supporting pre-revision set of beliefs where forced project weakly beats Continue; not current publication-facing T6 |
| IDCV scalar fixed-exposure potential | \(\Psi_H(\alpha;z)\) | planned scalar real extension | not assigned | \(\sum_{t=0}^{H-1}\alpha^tz_t\) with \(H\ge1\), \(\alpha>0\), fixed \(z_t\ge0\), and nonempty positive support |
| IDCV normalized timing weight | \(\omega_t^\Psi\) | planned | not assigned | \(\alpha^tz_t/\Psi_H(\alpha;z)\); abbreviated \(\omega_t\) only inside INNOVATION_DURATION_SPEC.md and distinct from S4 occupation weight |
| innovation duration | \(D_\Psi\) | planned | not assigned | \(\sum_tt\omega_t^\Psi\), the contribution-weighted mean date in \([0,H-1]\) |
| innovation convexity | \(C_\Psi\) | planned | not assigned | \(\sum_t\omega_t^\Psi(t-D_\Psi)^2\), the timing variance and log-effective-discount curvature |

## Equality and tie conventions

- Functions \(F:B\to\mathbb Q\) are equal extensionally.
- Finite module sets and libraries use set equality.
- Operational ties are absorbed by the upper-envelope value.
- Coverage includes equality; strict coverage is a separate predicate if
  later required.
- Project-action ties may select any maximizer. No deterministic tie breaker is
  part of the value theorem.
- Resource weights and burdens use exact rational equality.
- Productive dynamic innovation equivalence does not identify \(W(L)\);
  equality of net value additionally requires equal burden.
- Optimization maxima and minima are set-valued at ties. A selected optimizer
  requires an explicit tie breaker if uniqueness has not been proved.

The abstract \(W_h\), \(\sim_{\mathrm{DI}}\), modular generator, legacy F5--F8
value interfaces, and S4 gross coverage potential belong to supporting or
pre-migration results. They are not aliases for the target raw value
\(V_h^{\mathrm{raw}}\), compressed value \(\bar V_h\), unified operators, or
primary T1--T7 definitions.

## Reserved extension notation

| Extension concept | Reserved notation | Status |
|---|---|---|
| full probability simplex | \(\Delta(X)\) | extension-only |
| hidden transition kernel | \(P_X\) | extension-only |
| observation kernel | \(O\) | extension-only |
| infinite-horizon value | \(V_\infty\) | extension-only |
| stationary compressed policy | \(\pi^\star_K\) | extension-only |
| continuous coverage region | \(\widetilde{\mathcal C}_{q,g}\) | extension-only |
| belief-, age-, usage-, or time-dependent resource weight | \(w_s(b,a,u,t)\) | extension-only |
| statewise capacity enforcement after admission | \(W(L_t)\le B\) for every \(t\) | extension-only |

No reserved extension symbol may be used in a finite-core theorem without a
new assumption and decision record.

## Naming rules

- Manuscript sets use uppercase Roman or calligraphic symbols; elements use
  lowercase symbols.
- Lean types use `UpperCamelCase`; declarations use `lowerCamelCase`.
- Julia types use `UpperCamelCase`; functions and variables use `snake_case`.
- “Frontier” always means the value envelope \(F_L\).
- “Closure” always means module closure \(C_L\).
- “Candidate” must be qualified as raw or verified when admission matters.
- “Resource burden” means \(W(L)\); “project cost” means
  \(\kappa_q(b,K)\); neither term may be used as an alias for the other.

## Change protocol

1. Add a decision record explaining the semantic need.
2. Update this registry and `MODEL_SPEC.md`.
3. Update the exact assumption IDs and theorem-ledger records.
4. Update `FORMALIZATION_MAP.md` before implementation.
5. Add counterexamples for any weakened or rejected claim.
