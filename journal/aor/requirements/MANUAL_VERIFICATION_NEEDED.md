# Manual verification needed before AoOR submission

Author update, September 13, 2026: David Ramirez confirmed no financial or
non-financial competing interests. The corresponding declaration in
`manuscript/author_metadata.tex` is finalized. This resolves A3 only; it does
not imply completion of unrelated journal-specific portal confirmations.

## Status

Internet access was available on 2026-08-26. This is therefore not an
offline fallback. It records matters that official pages leave unresolved,
facts the repository cannot establish, and requirements that cannot be proven
by a release script.

Use the following labels exactly:

- `UNVERIFIED`: the official sources accessed do not establish the answer;
- `OFFICIAL / MANUAL`: the rule is verified, but compliance needs human or
  live-system review;
- `AUTHOR CONFIRMATION`: the fact is personal or disclosure information that
  must not be inferred from repository contents.

The source IDs below refer to
`journal/aor/requirements/OFFICIAL_REQUIREMENTS.md`.

## Unverified official fields

| ID | Status | Field | What must be verified | Acceptable authority |
|---|---|---|---|---|
| U1 | UNVERIFIED | Full-manuscript word limit | Whether Original Research in this special issue has a word, page, table, or figure cap not displayed in S1/S2. | Live official AoOR instructions, live submission system, or written journal response |
| U2 | UNVERIFIED | Exact LaTeX style option | Whether AoOR mandates a specific `sn-jnl` option or `.bst` beyond the author–year rules shown in S2. | Live official AoOR instructions or written journal response |
| U3 | UNVERIFIED | Public-code deposit | Whether this special issue imposes a public repository, archive, DOI, licence, or separate Code Availability Statement beyond S2's applicability language. | Official special-issue/journal page or written journal response |
| U4 | UNVERIFIED | Existing-preprint disclosure procedure | Whether the existing preprint DOI/version must appear in Editorial Manager, the cover letter, acknowledgments, or another manuscript section. Preprint eligibility itself is verified; the disclosure route is not. | Live submission system or written journal response |
| U5 | UNVERIFIED | Current guest-editor assignment | Whether all five guest editors in S1 remain assigned on the actual upload date. | Live official call/submission system or written journal response |
| U6 | UNVERIFIED | AI-disclosure location precedence | Whether S2's Methods-or-equivalent wording or S3's Introduction/Preface/Acknowledgements wording controls when reportable use occurred. | Updated official policy or written journal response |

Do not convert U1–U6 into manuscript claims or hard-coded release thresholds
without retaining the official URL, page title, access date, and exact policy
effect in a new audit revision.

## Official requirements requiring manual execution

| ID | Status | Manual verification | Pass condition | Source |
|---|---|---|---|---|
| M1 | OFFICIAL / MANUAL | Special issue remains open | On upload day the live system accepts the exact title and has not superseded the January 15, 2027 deadline. | S1 |
| M2 | OFFICIAL / MANUAL | Submission routing | Editorial Manager shows **Original Research**; Additional Information is answered yes; the exact special-issue title is selected. | S1, S2 |
| M3 | OFFICIAL / MANUAL | Cover letter | Final upload includes a cover letter and manuscript. | S1 |
| M4 | OFFICIAL / MANUAL | Corresponding-author ORCID | The corresponding author's ORCID is entered before the submission proceeds. | S2 |
| M5 | OFFICIAL / MANUAL | Title-page accuracy | Names, affiliation or allowed unaffiliated location, corresponding-author designation, and active email are accurate. | S2 |
| M6 | OFFICIAL / MANUAL | Data statement truth | Every access claim and repository link resolves; licensed CRSP/WRDS restrictions and reuse conditions are described accurately; no raw or row-level licensed data are uploaded. | S2 |
| M7 | OFFICIAL / MANUAL | Code statement truth | Repository URL, tagged version, Julia/Lean versions, environments, commands, and artifact-availability claims match the released files. | S2 |
| M8 | OFFICIAL / MANUAL | Figure accessibility | Each figure has a descriptive caption, does not rely on color alone, and has lettering contrast of at least 4.5:1. | S2 |
| M9 | OFFICIAL / MANUAL | Supplement accessibility and metadata | Every Online Resource has a descriptive caption and contains article title, journal name, author name, affiliation, and corresponding email; any video meets the flash limit. | S2 |
| M10 | OFFICIAL / MANUAL | Editable source completeness | The actual upload contains every LaTeX, class, style, bibliography, and figure dependency plus the compiled PDF; the uploaded files open successfully. | S2 |
| M11 | OFFICIAL / MANUAL | References | Author–year citations render correctly; the list is alphabetical; only cited published/accepted works appear; DOI links are present when available. | S2 |
| M12 | OFFICIAL / MANUAL | Permissions | Permission evidence accompanies any reused figure, table, or text for both print and online publication. | S2 |
| M13 | OFFICIAL / MANUAL | AI inventory | Authors identify whether any use exceeded exempt AI-assisted copy editing; no AI system is an author; no disallowed generative-AI figure is included. | S2, S3, S5 |

## Author confirmations

The following cannot be inferred or automatically certified. Each must be
approved by the author after reviewing the final manuscript and upload files.

| ID | Status | Confirmation |
|---|---|---|
| A1 | AUTHOR CONFIRMATION | Correct institutional affiliation, including institution, department if used, city, state if used, and country; or the journal-compliant unaffiliated city/country form. |
| A2 | AUTHOR CONFIRMATION | Correct funding/support statement and matching Editorial Manager funding entry. |
| A3 | AUTHOR CONFIRMATION | Complete financial and non-financial competing-interest disclosure, including potentially influential older interests when applicable. |
| A4 | AUTHOR CONFIRMATION | Correct author-contribution statement. |
| A5 | AUTHOR CONFIRMATION | All authors approve submission, relevant institutions approve publication, and the manuscript is not under consideration elsewhere. |
| A6 | AUTHOR CONFIRMATION | Existing-preprint identifier, version, licence, and disclosure wording are accurate after U4 is resolved. |
| A7 | AUTHOR CONFIRMATION | Generative-AI use inventory is complete and any required disclosure accurately describes tools and roles without assigning accountability to AI. |
| A8 | AUTHOR CONFIRMATION | All code, data, supplementary-material, and reproducibility availability claims are true at the release commit. |

## Upload-day sequence

1. Re-open S1 and S2 and record the upload-day access date. If either page has
   changed materially, revise the audit before submission.
2. Resolve U1–U6 from official evidence. A written journal response should be
   preserved as private submission correspondence, not fabricated or
   paraphrased from memory.
3. Obtain A1–A8 and remove all visible confirmation placeholders.
4. Run the repository's declared submission-ready gate and build the bundle.
5. Inspect the compiled manuscript and Online Resource visually, including all
   figures and title-page/declaration content.
6. Compare the bundle manifest with the files accepted by Editorial Manager.
7. Perform M1–M13 and retain a dated sign-off record tied to the submitted
   commit.

## Conservative handling of the AI-policy conflict

If no reportable generative-AI use occurred, record that conclusion in the
private author sign-off; do not insert a disclosure merely to appear complete.
If reportable use occurred before U6 is resolved, satisfy both current official
wordings by documenting it in a methodologically suitable location and in the
Introduction or Acknowledgements, or obtain written instructions from the
journal. AI-assisted copy editing, as narrowly defined by S2/S3, does not
require disclosure, but the authors remain accountable for the final text.

## Stop conditions

Do not upload if any of the following remains true:

- the special issue or article-type choice is absent from the live system;
- a required author confirmation is unresolved;
- the Data Availability Statement overstates access or would expose licensed
  rows;
- editable sources are incomplete;
- a figure fails the official accessibility criteria;
- reportable AI use exists but its disclosure is absent or unresolved;
- a preprint-disclosure answer would have to be guessed;
- the bundle differs from the tested release commit.
