# Annals of Operations Research — Online Resource 1

This directory is the independently compilable source tree for:

> **Online Resource 1: Proofs, Extended Results, Computational Records, and
> Reproducibility Materials**

It accompanies *Innovation-Safe Compression of Financial Strategy Libraries
under Partial Information: Complexity, Algorithms, and Financial Evidence*.
The journal is *Annals of Operations Research*. David Ramirez is the sole and
corresponding author (Independent Researcher, Orlando, FL, USA; ORCID
0009-0000-3128-5123).

Build from this directory with:

```sh
./build.sh
```

The build reads committed public-safe tables and figures but does not rerun a
solver, simulation, registered benchmark, or licensed workflow. Raw CRSP/WRDS
rows are neither inputs to the LaTeX build nor part of this tree.

Evidence provenance is explicit:

- Section S11 is the frozen preprint-era N=1024 randomized-library study.
- Section S12 is the separate Registered Algorithmic Compression Benchmark v2.
- Section S13 reports retrospective financial evidence using only
  redistributable aggregate outputs.
- Section S14 separates exact postchecks from MIP solver statuses.
- Section S15 maps every journal theorem to its precise evidence status.

The source-level migration and provenance audit is `SOURCE_PROVENANCE.md`.
