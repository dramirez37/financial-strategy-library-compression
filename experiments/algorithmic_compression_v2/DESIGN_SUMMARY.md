# Registered Algorithmic Compression Benchmark v2 — design summary

V2 is the non-pooled successor to the incomplete v1 final execution. It retains
the same structural families and algorithm definitions but uses new identifiers
and seeds. Eight fixed supervisor lanes execute independent run units
concurrently. Every algorithm subprocess remains deterministic and isolated with
one Julia, BLAS, and HiGHS thread.

The registered final matrix contains 173 instances and 3,907 run units. Runtime
and resource findings are conditional on the declared eight-worker environment.
All returned solutions receive exact original-coordinate feasibility and burden
checks. Exact finite methods, MIP evidence, heuristic evidence, and synthetic
experimental evidence remain distinctly labeled.
