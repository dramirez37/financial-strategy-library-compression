# AoOR source-migration manifest

Status: PARTIAL MIGRATION. The title, abstract, keywords, and Sections 1--5
are journal-draft prose; Sections 6--9 and the compiled appendices remain
scaffolded. Long proof, normalization, certificate, and secondary
comparative-statics material is assigned to Online Resource 1.

The row-level authority is `SOURCE_MIGRATION_MANIFEST.csv`. Every paragraph in
the scaffold that summarizes existing material has a paragraph row. Planned
theorems, proofs, tables, and figures have separate rows even though the
scaffold currently renders placeholders instead of their content.

Reuse states are:

- `MIGRATED_PARAPHRASE`: journal-draft prose derived from the named committed
  sources; no source paragraph was copied verbatim;
- `SCAFFOLD_PARAPHRASE`: new summary prose derived from the named sources; no
  source paragraph was copied verbatim;
- `EXACT_METADATA_COPY`: verified bibliographic metadata copied without a
  scientific claim;
- `EXACT_GENERATED_COPY`: a committed generated input was copied without
  altering its numbers and its generator remains named in the row;
- `PLANNED_MIGRATION`: the object is assigned a destination but is not yet
  inserted;
- `PLACEHOLDER_ONLY`: the scaffold reserves an input location and contains no
  result values or scientific graphic.

The manifest intentionally records both the historical editable source and the
journal overlay when both contribute to a planned object. The immutable
`release/v0.1.1-arxiv/` tree is never a migration source: the editable
`manuscript/` files are used for provenance, while the historical release
remains untouched.

No theorem or proof is duplicated in this scaffold. `LABEL_MAP.csv` reserves
the destination label for each retained mathematical object. During the prose
migration, a theorem is instantiated once in the mapped destination and any
long proof is attached to that label from the appendix or Online Resource.

Tables and figures are inputs, never manually transcribed values. Replacing a
DRAFT placeholder requires a committed machine-readable source, a generator or
nonmutating drift check, an artifact-manifest entry, and an updated row in the
CSV. Licensed CRSP/WRDS rows are prohibited sources; only permitted audited
aggregates may enter the journal tree.
