# Annals of Operations Research — Online Resource 1

This directory is the independently compilable source tree for:

> **Online Resource 1: Proofs, Extended Results, Computational Records, and
> Reproducibility Materials**

It accompanies *Innovation-Safe Compression of Financial Strategy Libraries:
Semantics, Complexity, and Algorithms*.
The journal is *Annals of Operations Research*. David Ramirez is the sole and
corresponding author (Independent Researcher, Orlando, FL, USA; ORCID
0009-0000-3128-5123).

Build from this directory with:

```sh
./build.sh
```

The build reads only local committed public-safe tables, figures, and canonical
CSV extracts, but does not rerun a solver, simulation, registered benchmark, or
licensed workflow. Raw CRSP/WRDS rows are neither inputs to the LaTeX build nor
part of this tree. The Springer Nature class and author--year bibliography
style are included locally, so the editable source compiles independently.

Evidence provenance is explicit:

- Section S11 is the frozen preprint-era N=1024 randomized-library study.
- Section S12 is the separate Registered Algorithmic Compression Benchmark v2.
- Section S13 reports retrospective financial evidence using only
  redistributable aggregate outputs.
- Section S14 separates exact postchecks from MIP solver statuses.
- Section S15 maps every journal theorem to its precise evidence status.

The source-level migration and provenance audit is `SOURCE_PROVENANCE.md`.
