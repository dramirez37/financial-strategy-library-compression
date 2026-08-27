# Official Annals of Operations Research special-issue requirements

## Audit status

- Intended special issue: *Advances in Quantitative Finance and Risk Modeling*.
- Journal: *Annals of Operations Research*.
- Audit date: 2026-08-26.
- Authority rule: only official Springer Nature and official Springer Nature
  special-issue material was consulted.
- Internet status: available. The special-issue call and journal instructions
  were read successfully.
- Scope: requirements visible in the sources below on the audit date. The live
  submission system can change after this audit and must be checked again at
  upload.

For journal-policy claims in this repository, this evidence ledger takes
precedence over the older implementation summary in
`journal/aor/SUBMISSION_REQUIREMENTS.md`. That summary may remain useful as a
local build contract, but it cannot promote an `UNVERIFIED` item below into an
official requirement.

`VERIFIED` means the stated requirement is supported by an official source in
the source register. `UNVERIFIED` means the accessed official sources do not
establish the claimed rule. It does not mean that the rule is false.

## Official source register

| ID | Official page title | URL | Accessed |
|---|---|---|---|
| S1 | *Call for Papers — Annals of Operations Research — Special Issue: Advances in Quantitative Finance and Risk Modeling* | <https://cms-resources.apps.public.k8s.springernature.io/springer-cms/rest/v1/content/27853658/data/v3> | 2026-08-26 |
| S2 | *Submission guidelines \| Annals of Operations Research \| Springer Nature Link* | <https://link.springer.com/journal/10479/submission-guidelines> | 2026-08-26 |
| S3 | *AI for our communities \| Springer Nature Group \| Springer Nature* | <https://group.springernature.com/gp/group/ai/ai-guidance-for-our-researchers-and-communities> | 2026-08-26 |
| S4 | *Preprints : Springer Nature Support* | <https://support.springernature.com/en/support/solutions/articles/6000258807-preprints> | 2026-08-26 |
| S5 | *Editorial policies \| Policies \| Springer Nature* | <https://www.springernature.com/gp/policies/editorial-policies> | 2026-08-26 |

The S1 page is an official two-page PDF. Its visible document heading is used
as the page title because the PDF metadata has no Title field.

## Special-issue identity and routing

| Requirement | Status | Authoritative result | Source |
|---|---|---|---|
| Exact title | VERIFIED | *Advances in Quantitative Finance and Risk Modeling* | S1, accessed 2026-08-26 |
| Deadline | VERIFIED | January 15, 2027. The call prints “January, 15, 2027”; this audit normalizes only the punctuation. Manuscripts received later may not be considered for the special issue and may, if accepted, be transferred to a regular issue. | S1, accessed 2026-08-26 |
| Required submission items | VERIFIED | Submit both a cover letter and a manuscript. | S1, accessed 2026-08-26 |
| Submission system | VERIFIED | Use the journal's online submission site, Editorial Manager. S2's “Submit your manuscript” link routes to `https://www.editorialmanager.com/anor`. | S1 and S2, accessed 2026-08-26 |
| Article type | VERIFIED | Select **Original Research** when prompted for article type. | S1, accessed 2026-08-26 |
| Special-issue routing | VERIFIED | On the Additional Information screen, answer yes when asked whether the manuscript belongs to a special issue, then select *Advances in Quantitative Finance and Risk Modeling*. | S1, accessed 2026-08-26 |

## Manuscript form and front matter

| Requirement | Status | Authoritative result | Source |
|---|---|---|---|
| Manuscript format | VERIFIED | The journal says manuscripts should be submitted in LaTeX and recommends the Springer Nature LaTeX template. Include the original source, all style files and figures, and a PDF of the compiled output. Word files are also accepted. | S2, accessed 2026-08-26 |
| Heading hierarchy | VERIFIED | Use decimal headings with no more than three levels. | S2, accessed 2026-08-26 |
| Abstract length | VERIFIED | 150–250 words. The abstract should not contain undefined abbreviations or unspecified references. | S2, accessed 2026-08-26 |
| Keywords | VERIFIED | Supply 4–6 indexing keywords. | S2, accessed 2026-08-26 |
| Citation style | VERIFIED | Use author–year citations in the text. The reference list is alphabetical by first-author surname, includes only cited works that are published or accepted, italicizes journal and book titles, and should include DOI links when available. APA 7 treatment of author counts is encouraged, not stated as mandatory. | S2, accessed 2026-08-26 |
| Specific LaTeX class option or `.bst` | UNVERIFIED | S2 recommends the Springer Nature template and specifies author–year references, but it does not name `sn-mathphys-ay` or another exact class option/bibliography file. The repository's use of `sn-mathphys-ay` is therefore an implementation choice consistent with the visible author–year rule, not an independently verified journal mandate. | S2, accessed 2026-08-26 |
| Full-manuscript word limit | UNVERIFIED | No general article word limit was found in S1 or S2. Only the abstract has an explicit word range. | S1 and S2, accessed 2026-08-26 |

### Title page

S2 requires a concise, informative title and the following author information:

- every author's name;
- every author's affiliation: institution, optional department, city, optional
  state, and country;
- a clear indication of the corresponding author and an active email address;
- each author's 16-digit ORCID if available.

Separately, S2 states that the corresponding author must provide an ORCID
before proceeding with submission. An ORCID is therefore mandatory in the
submission workflow for the corresponding author, while display of an ORCID
on the title page is worded as conditional on availability.

S2 places acknowledgments of people, grants, and funds in a separate title-page
section and asks that funding-organization names be written in full.

## Statements, data, code, and supplementary material

### Statements and declarations

S2 says relevant statements must appear under a **Statements and
Declarations** heading and warns that submissions lacking relevant
declarations will be returned as incomplete. Its detailed competing-interest
instructions place a Declarations section before the references, with
**Funding** and/or **Competing interests** headings. Ethics, consent, data,
material and/or code availability, and author-contribution statements are
listed as other declarations, according to applicability.

The journal's author-contribution subsection recommends a contribution
statement; S5 describes author-contribution statements as publisher-wide
required practice. Including a contribution statement is the conservative
submission rule. This difference in wording is retained rather than silently
resolved.

### Data availability

Status: **VERIFIED**. All Original Research articles must include a Data
Availability Statement. It must explain how readers can access the data that
support the results and analysis, including links or citations for publicly
archived data. If public sharing is impossible, the statement must explain
access and any reuse conditions. Public repository deposit is strongly
encouraged but is not stated as universally mandatory. Authors must have the
rights needed to share any deposited data. [S2, accessed 2026-08-26]

For this project, an accurate statement may distinguish redistributable exact,
synthetic, and aggregate artifacts from licensed CRSP/WRDS source data. The
official policy permits a statement that explains why data cannot be shared
publicly and how access is conditioned; it does not authorize redistribution
of licensed rows.

### Code availability

Status: **PARTLY VERIFIED**. S2 asks authors to ensure that custom code and
software support the published claims and comply with field standards. It also
lists Code availability among declarations that may apply. Neither S1 nor S2
states a universal public-code-deposit mandate or an unconditional standalone
Code Availability Statement requirement. Those stronger claims remain
**UNVERIFIED**. [S2, accessed 2026-08-26]

### Supplementary Information

Status: **VERIFIED** when supplementary files are supplied. S2 requires:

- standard file formats;
- article title, journal name, author names, affiliation, and corresponding
  author email within each supplementary file;
- an explicit citation to every supplementary item in the manuscript;
- consecutive names such as `ESM_3.mpg` and `ESM_4.pdf`;
- a concise caption for every item;
- PDF for text/presentation material, CSV or XLSX for spreadsheets, and ZIP or
  GZ when collecting multiple files.

Supplementary files are published as received, without conversion, editing,
or reformatting. The journal encourages repository deposit rather than using
Supplementary Information as the default home for research datasets. [S2,
accessed 2026-08-26]

## Competing interests

Status: **VERIFIED**. Authors must disclose financial and non-financial
interests directly or indirectly related to the work. Interests within the
three years before the work began should be reported; older interests must
also be disclosed if they could reasonably be perceived as influential.
Primary research articles require a disclosure statement. Funding information
must also be entered in the peer-review system and included in the manuscript's
Declarations section. [S2, accessed 2026-08-26]

The repository cannot determine an author's personal funding or competing-
interest facts. Those assertions require author confirmation.

## Generative-AI rules

Status: **VERIFIED WITH AN OFFICIAL WORDING CONFLICT**.

The rules consistently established by S2, S3, and S5 are:

- an AI system or LLM cannot be an author;
- humans remain accountable for the manuscript and must verify AI-assisted
  output;
- generative use must be disclosed transparently;
- AI-assisted copy editing limited to readability, grammar, spelling,
  punctuation, tone, wording, or formatting of human-generated text does not
  need disclosure;
- generative AI images are generally not permitted, except for the specific
  exceptions described by Springer Nature, and qualifying use must be clearly
  labelled.

The official pages disagree on disclosure location. S2 says LLM use should be
documented in Methods or a suitable alternative section. S3 says AI that helped
generate text, data analysis, or content should be acknowledged in the
Introduction, Preface, or Acknowledgements. Until Springer Nature clarifies
which current wording controls, a non-copy-editing use should be disclosed in
both a methodologically suitable location and an Introduction or
Acknowledgements location, or the author should obtain written journal
guidance. This audit does not infer whether any reportable AI use occurred.
[S2, S3, and S5, accessed 2026-08-26]

## Preprint policy

Status: **VERIFIED IN PART**. Springer Nature defines a preprint as an author
version deposited publicly before formal journal peer review. It permits
posting at any time during peer review and states that a preprint is not prior
publication and does not jeopardize consideration by Springer Nature journals.
S5 also describes a unified policy that encourages preprint posting, citation,
and open licensing. [S4 and S5, accessed 2026-08-26]

Neither S1 nor S2 states how an existing preprint must be disclosed to this
special issue. S4 does not impose a cover-letter or manuscript disclosure
format. The exact AoOR disclosure procedure for the existing arXiv release is
therefore **UNVERIFIED** and should be confirmed in the live submission system
or with the editorial office.

## Figures and accessibility

Status: **VERIFIED**. S2 requires that:

- every figure have a descriptive caption;
- patterns be used instead of, or in addition to, color when color carries
  information;
- figure lettering have a contrast ratio of at least 4.5:1.

For supplementary files, the manuscript must provide a descriptive caption
for each item, and video must not flash more than three times per second. S2
also asks for electronic figure submission, embedded fonts in vector graphics,
`Fig`-number filenames, and captions in the manuscript source rather than the
figure file. [S2, accessed 2026-08-26]

## Editable-source requirement

Status: **VERIFIED**. A complete set of relevant editable source files is
required at every submission and revision. S2 states that an incomplete set
will prevent the article from being considered for review. For LaTeX, this
means the original source, style files, figures, and compiled PDF. [S2,
accessed 2026-08-26]

## Guest editors officially listed

S1 lists the following Guest Editors:

- Rosella Giacometti — University of Bergamo, Italy;
- Zari Rachev — Texas Tech University, Texas;
- Sergio Ortobelli Lozza — University of Bergamo, Italy;
- Aaron Kim — Stony Brook University, NY;
- Gabriele Torri — University of Bergamo, Italy.

Status: **VERIFIED AS LISTED IN THE OFFICIAL CALL ACCESSED 2026-08-26**. The
live submission system should still be checked for later editorial changes.

## Authoritative gaps and non-inferences

The accessed official sources do **not** establish any of the following:

- a full-manuscript word limit;
- a mandatory exact `sn-jnl` option or `.bst` filename;
- a universal requirement to make code public;
- an AoOR-specific procedure for disclosing the existing preprint;
- that every listed guest editor will remain assigned through submission;
- that an `OPTIMAL` solver status, computation, or experiment has any formal-
  proof status.

No requirement in this audit changes the manuscript, scientific claims,
licensed-data boundary, frozen studies, or historical release artifacts.
