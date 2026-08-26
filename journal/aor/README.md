# Annals of Operations Research journal version

This tree is the journal-only wrapper and revision layer for the special issue
*Advances in Quantitative Finance and Risk Modeling*. The scientific baseline
is the immutable `v0.1.1-arxiv` release commit; no file in that release tree is
rewritten here.

Build the draft and Online Resource 1 from the repository root:

```sh
make journal
```

Run the targeted scientific, source, and PDF gate:

```sh
make journal-check
```

The development gate permits visible author-confirmation placeholders. The
submission-ready gate rejects them:

```sh
make journal-submission-check
```

After the author confirmations are resolved, create the flattened submission
directory with:

```sh
./journal/aor/build_submission_bundle.sh
```

The long N=1024 randomized replay and any new large algorithmic benchmark are
deliberately outside these targets.
