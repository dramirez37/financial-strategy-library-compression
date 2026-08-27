# Registered Algorithmic Compression Benchmark v2 — analysis plan

V2 retains the v1 burden, exactness, preprocessing, failure, and finite-design
estimands, but all computational performance claims are conditional on the
fixed eight-worker environment. V1 and v2 runtime, memory, timeout, solved
fraction, node, and batch-throughput measurements are not pooled.

Primary outcomes are relative burden gap, optimum-attainment frequency, solved
fraction, per-run wall-clock time, batch throughput, MIP node count, DP state
count, preprocessing reduction, and frontier/closure evaluation count. Exact
finite optima are used only where complete enumeration or DP finishes and
agrees. Elsewhere an exactly feasible HiGHS incumbent with `OPTIMAL` status is a
MIP reference, not an exhaustive proof.

Runtime summaries report median PAR-2 and paired PAR-2 differences within v2,
stratified by family and size. Models include registered structural factors and
fixed lane identity; descriptive sensitivity also reports launch wave. No
unsuccessful row is removed. Timeout uses the registered cap, and unavailable
diagnostics are distinct from zero.

The final analysis begins only after the v2 lock verifies and all final run
records are terminal. No interim burden, solver, runtime, node, or ranking
summary may alter the grid, algorithms, worker count, limits, seeds, or models.
Pilot and v1 outputs are excluded from v2 final analysis.
