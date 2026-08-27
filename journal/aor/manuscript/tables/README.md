# Table input policy

This directory is the manuscript-facing table input layer. Scientific values
must come from committed machine-readable artifacts and enter the manuscript
through generated `.tex` inputs. Values must not be manually transcribed into
section prose or table bodies.

`generated_inputs.tex` currently renders explicit DRAFT placeholders. Replacing
a placeholder requires a source row in `SOURCE_MIGRATION_MANIFEST.csv`, a
machine-readable artifact identifier, and a nonmutating regeneration check.
