# Annals of Operations Research submission checklist

This checklist translates the official audit into release-gate inputs. The
TOML block is canonical and is deliberately limited to types supported by
Julia's standard-library `TOML` parser. A later script can extract the text
between the markers and evaluate `automatic` entries; `manual` entries require
recorded human sign-off. `UNVERIFIED` entries must never be promoted to errors
without a new official-source audit.

<!-- BEGIN AOR_REQUIREMENTS_TOML -->
```toml
schema_version = "aor-submission-checklist-v1"
journal = "Annals of Operations Research"
special_issue = "Advances in Quantitative Finance and Risk Modeling"
article_type = "Original Research"
official_audit_date = "2026-08-26"
deadline = "2027-01-15"
authority_file = "journal/aor/requirements/OFFICIAL_REQUIREMENTS.md"
manual_file = "journal/aor/requirements/MANUAL_VERIFICATION_NEEDED.md"

[status_vocabulary]
verified = "Supported by an official source in OFFICIAL_REQUIREMENTS.md"
partly_verified = "Some, but not all, of the claimed rule is official"
unverified = "Not established by the official sources accessed"

[[checks]]
id = "special_issue_title"
authority_status = "VERIFIED"
origin = "official_special_issue_call"
execution = "automatic"
severity = "error"
path = "journal/aor/cover_letter.md"
check_kind = "literal_present"
expected = "Advances in Quantitative Finance and Risk Modeling"
source_ids = ["S1"]

[[checks]]
id = "cover_letter_exists"
authority_status = "VERIFIED"
origin = "official_special_issue_call"
execution = "automatic"
severity = "error"
path = "journal/aor/cover_letter.md"
check_kind = "file_exists"
source_ids = ["S1"]

[[checks]]
id = "article_type"
authority_status = "VERIFIED"
origin = "official_special_issue_call"
execution = "automatic"
severity = "error"
path = "journal/aor/main.tex"
check_kind = "literal_present"
expected = "\\articletype{Original Research}"
source_ids = ["S1"]

[[checks]]
id = "submission_deadline_recheck"
authority_status = "VERIFIED"
origin = "official_special_issue_call"
execution = "manual"
severity = "error"
check_kind = "live_portal_confirmation"
expected = "Special issue remains open with deadline 2027-01-15"
source_ids = ["S1"]

[[checks]]
id = "editorial_manager_routing"
authority_status = "VERIFIED"
origin = "official_special_issue_call"
execution = "manual"
severity = "error"
check_kind = "submission_ui_selection"
expected = "Editorial Manager; article type Original Research; Additional Information special-issue answer yes; select exact special-issue title"
source_ids = ["S1", "S2"]

[[checks]]
id = "main_source_exists"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic"
severity = "error"
path = "journal/aor/main.tex"
check_kind = "file_exists"
source_ids = ["S2"]

[[checks]]
id = "springer_class_exists"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic"
severity = "error"
path = "journal/aor/template/sn-jnl.cls"
check_kind = "file_exists"
source_ids = ["S2"]

[[checks]]
id = "bibliography_source_exists"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic"
severity = "error"
path = "manuscript/bibliography/references.bib"
check_kind = "file_exists"
source_ids = ["S2"]

[[checks]]
id = "bibliography_style_exists"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines_and_local_template_choice"
execution = "automatic"
severity = "error"
path = "journal/aor/template/bst/sn-mathphys-ay.bst"
check_kind = "file_exists"
source_ids = ["S2"]

[[checks]]
id = "all_tex_dependencies_resolve"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic"
severity = "error"
path = "journal/aor/main.tex"
check_kind = "latex_dependency_closure"
expected = "Every input, include, bibliography, class, style, and figure dependency resolves to a submitted editable source or figure"
source_ids = ["S2"]

[[checks]]
id = "compiled_main_pdf_exists"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic"
severity = "error"
path = "journal/aor/build/main/aor-journal.pdf"
check_kind = "file_exists_after_build"
source_ids = ["S2"]

[[checks]]
id = "submission_source_is_editable_and_complete"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic"
severity = "error"
path = "journal/aor/submission/manuscript.tex"
check_kind = "flattened_latex_source_complete"
forbidden_literals = ["\\input{", "\\include{"]
required_sibling_paths = ["journal/aor/submission/sn-jnl.cls", "journal/aor/submission/sn-mathphys-ay.bst", "journal/aor/submission/references.bib", "journal/aor/submission/manuscript.pdf"]
source_ids = ["S2"]

[[checks]]
id = "abstract_word_count"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic"
severity = "error"
path = "journal/aor/main.tex"
check_kind = "latex_macro_word_count"
macro = "abstract"
minimum = 150
maximum = 250
source_ids = ["S2"]

[[checks]]
id = "abstract_content_hygiene"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "manual"
severity = "error"
path = "journal/aor/main.tex"
check_kind = "content_review"
expected = "No undefined abbreviation and no unspecified reference in abstract"
source_ids = ["S2"]

[[checks]]
id = "keyword_count"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic"
severity = "error"
path = "journal/aor/main.tex"
check_kind = "latex_comma_list_count"
macro = "keywords"
minimum = 4
maximum = 6
source_ids = ["S2"]

[[checks]]
id = "title_present"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic"
severity = "error"
path = "journal/aor/main.tex"
check_kind = "nonempty_latex_macro"
macro = "title"
source_ids = ["S2"]

[[checks]]
id = "author_names_present"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic"
severity = "error"
path = "journal/aor/main.tex"
check_kind = "nonempty_latex_macro"
macro = "author"
source_ids = ["S2"]

[[checks]]
id = "corresponding_author_email_present"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic"
severity = "error"
path = "journal/aor/main.tex"
check_kind = "nonempty_latex_macro"
macro = "email"
source_ids = ["S2"]

[[checks]]
id = "affiliation_complete"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic_then_manual"
severity = "error"
path = "journal/aor/author_metadata.tex"
check_kind = "no_placeholders_and_author_confirmation"
forbidden_literals = ["AUTHOR CONFIRMATION REQUIRED", "pending author confirmation"]
expected = "Institution, optional department, city, optional state, and country; or journal-compliant unaffiliated details"
source_ids = ["S2"]

[[checks]]
id = "corresponding_author_orcid"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "manual"
severity = "error"
check_kind = "submission_ui_confirmation"
expected = "Corresponding author ORCID provided before submission proceeds"
source_ids = ["S2"]

[[checks]]
id = "heading_depth"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic"
severity = "error"
path = "journal/aor/main.tex"
check_kind = "latex_heading_depth"
maximum = 3
source_ids = ["S2"]

[[checks]]
id = "author_year_citations"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic_then_manual"
severity = "error"
path = "journal/aor/main.tex"
check_kind = "citation_style_review"
expected = "Author-year text citations; alphabetized reference list; DOI links where available"
source_ids = ["S2"]

[[checks]]
id = "declarations_heading"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic"
severity = "error"
path = "journal/aor/main.tex"
check_kind = "one_literal_present"
accepted_literals = ["\\section*{Declarations}", "\\section*{Statements and Declarations}"]
source_ids = ["S2"]

[[checks]]
id = "funding_statement"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic_then_manual"
severity = "error"
path = "journal/aor/main.tex"
check_kind = "heading_present_and_author_confirmation"
heading = "Funding"
source_ids = ["S2"]

[[checks]]
id = "competing_interests_statement"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic_then_manual"
severity = "error"
path = "journal/aor/main.tex"
check_kind = "heading_present_and_author_confirmation"
heading = "Competing interests"
source_ids = ["S2"]

[[checks]]
id = "data_availability_statement"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic_then_manual"
severity = "error"
path = "journal/aor/main.tex"
check_kind = "heading_present_and_claim_audit"
heading = "Data availability"
expected = "Access routes, public artifact links or citations, and any licensed-data access/reuse conditions are accurate"
source_ids = ["S2"]

[[checks]]
id = "licensed_data_boundary"
authority_status = "VERIFIED"
origin = "official_data_policy_and_repository_policy"
execution = "automatic_then_manual"
severity = "error"
paths = ["journal/aor/main.tex", "journal/aor/supplement.tex", "journal/aor/submission"]
check_kind = "no_raw_or_row_level_licensed_data"
expected = "Only redistributable aggregate outputs and access conditions; no raw CRSP/WRDS rows"
source_ids = ["S2"]

[[checks]]
id = "code_availability_statement"
authority_status = "PARTLY_VERIFIED"
origin = "journal_submission_guidelines_and_repository_policy"
execution = "automatic_then_manual"
severity = "error"
path = "journal/aor/main.tex"
check_kind = "heading_present_and_claim_audit"
heading = "Code availability"
expected = "Repository URL, versions, environments, and availability claims resolve and are true"
source_ids = ["S2"]

[[checks]]
id = "author_contribution_statement"
authority_status = "VERIFIED_WITH_WORDING_DIFFERENCE"
origin = "journal_guideline_recommendation_and_publisher_policy"
execution = "automatic_then_manual"
severity = "error"
path = "journal/aor/main.tex"
check_kind = "heading_present_and_author_confirmation"
heading = "Author contributions"
source_ids = ["S2", "S5"]

[[checks]]
id = "no_author_confirmation_placeholders"
authority_status = "VERIFIED"
origin = "official_declarations_and_repository_policy"
execution = "automatic"
severity = "error"
paths = ["journal/aor/author_metadata.tex", "journal/aor/cover_letter.md"]
check_kind = "literals_absent"
forbidden_literals = ["AUTHOR CONFIRMATION REQUIRED", "Author confirmation required", "pending author confirmation"]
source_ids = ["S2"]

[[checks]]
id = "generative_ai_authorship"
authority_status = "VERIFIED"
origin = "journal_and_publisher_ai_policy"
execution = "automatic_then_manual"
severity = "error"
paths = ["journal/aor/main.tex", "journal/aor/author_metadata.tex"]
check_kind = "no_ai_system_as_author_and_human_confirmation"
source_ids = ["S2", "S3", "S5"]

[[checks]]
id = "generative_ai_disclosure"
authority_status = "VERIFIED_WITH_OFFICIAL_WORDING_CONFLICT"
origin = "journal_and_publisher_ai_policy"
execution = "manual"
severity = "error_if_reportable_use_occurred"
check_kind = "author_use_inventory_and_disclosure_review"
expected = "If use exceeded AI-assisted copy editing, disclose in a methodologically suitable location and in Introduction or Acknowledgements, or retain written journal guidance"
source_ids = ["S2", "S3", "S5"]

[[checks]]
id = "generative_ai_figures"
authority_status = "VERIFIED"
origin = "journal_and_publisher_ai_policy"
execution = "manual"
severity = "error"
check_kind = "figure_provenance_review"
expected = "No generative-AI image except an official-policy exception with required label and documentation"
source_ids = ["S2", "S3"]

[[checks]]
id = "preprint_eligibility"
authority_status = "VERIFIED"
origin = "publisher_preprint_policy"
execution = "manual"
severity = "info"
check_kind = "policy_acknowledgment"
expected = "Existing preprint is not treated as prior publication by Springer Nature"
source_ids = ["S4", "S5"]

[[checks]]
id = "preprint_disclosure_procedure"
authority_status = "UNVERIFIED"
origin = "official_sources_silent"
execution = "manual"
severity = "block_until_verified"
check_kind = "live_portal_or_editorial_office_confirmation"
expected = "Confirm whether and where AoOR requires the existing preprint DOI/version to be disclosed"
source_ids = ["S1", "S2", "S4"]

[[checks]]
id = "figure_captions"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic_then_manual"
severity = "error"
paths = ["journal/aor/main.tex", "journal/aor/sections", "manuscript/sections", "manuscript/appendices"]
check_kind = "every_figure_in_latex_dependency_closure_has_descriptive_caption"
source_ids = ["S2"]

[[checks]]
id = "figure_noncolor_encoding"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "manual"
severity = "error"
check_kind = "visual_accessibility_review"
expected = "Patterns or another noncolor channel supplements every color encoding"
source_ids = ["S2"]

[[checks]]
id = "figure_lettering_contrast"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "manual"
severity = "error"
check_kind = "contrast_measurement"
minimum_ratio = 4.5
source_ids = ["S2"]

[[checks]]
id = "supplement_source_exists"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic"
severity = "error"
path = "journal/aor/supplement.tex"
check_kind = "file_exists"
source_ids = ["S2"]

[[checks]]
id = "supplement_dependencies_resolve"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic"
severity = "error"
path = "journal/aor/supplement.tex"
check_kind = "latex_dependency_closure"
expected = "Every input, include, bibliography, style, and figure dependency needed to compile Online Resource 1 resolves"
source_ids = ["S2"]

[[checks]]
id = "supplement_pdf_exists"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic"
severity = "error"
path = "journal/aor/build/supplement/ESM_1.pdf"
check_kind = "file_exists_after_build"
source_ids = ["S2"]

[[checks]]
id = "supplement_metadata"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic_then_manual"
severity = "error"
path = "journal/aor/supplement.tex"
check_kind = "supplement_identity_fields"
required_fields = ["article_title", "journal_name", "author_names", "affiliation", "corresponding_author_email"]
source_ids = ["S2"]

[[checks]]
id = "supplement_citation"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic"
severity = "error"
path = "journal/aor/main.tex"
check_kind = "literal_present"
expected = "Online Resource~1"
source_ids = ["S2"]

[[checks]]
id = "supplement_caption"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic_then_manual"
severity = "error"
path = "journal/aor/main.tex"
check_kind = "supplement_caption_present_and_descriptive"
expected = "A concise description accompanies Online Resource 1"
source_ids = ["S2"]

[[checks]]
id = "supplement_filename"
authority_status = "VERIFIED"
origin = "journal_submission_guidelines"
execution = "automatic"
severity = "error"
path = "journal/aor/submission/ESM_1.pdf"
check_kind = "file_exists_after_bundle"
source_ids = ["S2"]

[[checks]]
id = "full_manuscript_word_limit"
authority_status = "UNVERIFIED"
origin = "official_sources_silent"
execution = "manual"
severity = "do_not_enforce"
check_kind = "live_portal_or_editorial_office_confirmation"
expected = "Do not invent or enforce a full-manuscript word limit without a new official source"
source_ids = ["S1", "S2"]

[[checks]]
id = "exact_latex_style_option"
authority_status = "UNVERIFIED"
origin = "official_sources_silent"
execution = "manual"
severity = "warning"
path = "journal/aor/main.tex"
check_kind = "template_choice_review"
expected = "Current sn-mathphys-ay choice remains consistent with author-year examples; do not call it an official named mandate"
source_ids = ["S2"]
```
<!-- END AOR_REQUIREMENTS_TOML -->

## Release semantics

- An `automatic` check may be implemented as a deterministic release-script
  assertion.
- An `automatic_then_manual` check first verifies structure and then requires a
  named human confirmation of truth or quality.
- A `manual` check is never satisfied by file existence alone.
- `severity = "block_until_verified"` means the issue must be resolved from an
  official source or editorial response before upload.
- `authority_status = "UNVERIFIED"` is not permission to guess a value.

The existing `journal/aor/check.sh` already implements several checks above,
including branch identity, immutable historical surfaces, abstract length,
keyword count, source validation, build success, and placeholder rejection in
submission-ready mode. This inventory is a contract for extending that gate in
a later, separately requested task; it does not modify the release script now.
