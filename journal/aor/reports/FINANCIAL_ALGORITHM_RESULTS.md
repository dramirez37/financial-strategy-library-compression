# Financial algorithm comparison results

Status: **NOT RUN — NO NEW FINANCIAL ALGORITHM-COMPARISON RESULTS**.

The locked terminal and annual financial inputs are locally present. A
pre-lock licensed preflight recomputed validation profiles for only the
committed source memberships and verified exact equality with the committed
frontier, closure, weight, and historical-stepwise certificates. It did not
dispatch a new comparison algorithm, evaluate a new comparison outcome, or
update a public aggregate. Existing committed financial-resource results remain
historical parent artifacts and are not relabeled as results from the new suite.

The public-safe workflow layer was tested only with exact synthetic fixtures.
Those tests establish schema behavior, deterministic algorithm dispatch,
postselection held-out timing, exact endpoint rechecking, MIP/DP agreement on
the fixture, explicit DP inapplicability, and explicit second-solver
unavailability. They are implementation tests, not financial findings and not
substitutes for either retrospective audit.

After this commit, the local licensed run is:

```sh
make aor-financial-algorithm-tests
make aor-financial-algorithm-lock
make aor-financial-algorithms
make aor-financial-algorithm-audit
make aor-financial-algorithm-promote
```

The licensed run and audit write only ignored local artifacts under
`experiments/financial_algorithm_comparison_v1/local_results/`. A later,
explicit promotion validates the fixed aggregate schema and writes only the
rights-cleared summary, its public status, and this mechanically generated
report. Those aggregate outputs must be committed separately.
