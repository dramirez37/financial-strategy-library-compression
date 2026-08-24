# Terminal Financial Audit: Data Audit

- Audit date: 2026-07-21
- Protocol base commit: `cbbedfd`
- Source-repository commit: `3146029aa71dfe7639ede9ca79f81602165125e8`
- Disposition: **aggregate mechanism outputs are suitable for publication; licensed raw and row-level data are not redistributable**

## Repository search and source choice

The audit first searched this repository and its reachable Git history. No
dated market observation was present: the existing result tables were exact or
synthetic theorem-mechanism outputs. A read-only search of sibling local Julia
projects outside this repository then found CRSP ETF histories and an ORATS
options master in the `curv-risk` project.

The local ORATS master contains directories for 25 ETFs and four index
products. It is used only to define a transparent covered-instrument inventory;
no option quote or surface enters the illustration. Returns come from the CRSP
US Stock Database daily-security extract and its date-varying security-history
table at:

```text
../curv-risk/curvrisk/research/bachelier_revision/data/raw/crsp_a_stock/
```

This choice avoids expanding the paper's finite action and execution model to
options. No network request or data download was made. The extraction script
reads the existing licensed files, selects the committed PERMNOs, and writes a
local ignored derivative. It never copies source rows into a tracked artifact.

## Source and license

| Item | Finding |
|---|---|
| Provider | CRSP through WRDS |
| Product | CRSP US Stock Database daily security and security history extracts |
| Local delivery evidence | Sibling-repository inventory dated 2026-05-18; latest source-file modification time 2026-04-30 |
| License record | `LICENSE_DATA`, `docs/license_notes.md`, and `docs/data_sources.md` in the source repository |
| Research use | Existing licensed research workspace; local research use recorded as permitted |
| Redistribution | Raw and row-level CRSP/WRDS and ORATS data are explicitly nonredistributable |
| Aggregate publication | Project-authored aggregate tables, figures, reports, and metadata are cleared for manuscript and replication-package use under D-0041 |
| Reviewer reproduction | Reviewers supply their own licensed CRSP/WRDS extract; ORATS access is optional because the ticker/PERMNO universe is frozen in the configuration |

The tracked repository therefore retains code, the input contract, checksums,
aggregate mechanism summaries, figures, and documentation. The extracted ETF
panel, extraction audit, completed provenance record, and every row-level
licensed derivative remain ignored.

## Source integrity

| Source file | Bytes | SHA-256 |
|---|---:|---|
| `security_history/stksecurityinfohist.csv` | 42,986,400 | `53f901bd5da9ee29ccef6d20f0b6736068b1f0d764b3ec9b46e1680d5e79de31` |
| `daily_security/stkdlysecuritydata_00_10.csv.gz` | 966,971,582 | `41bfacfc95745234452398395424a646996351d71a0156218340d42a877aa143` |
| `daily_security/stkdlysecuritydata_10_20.csv.gz` | 1,010,422,667 | `0ac85fc83f07c6c9726157049f041f5f49ade7edf033770bec7492acbcfe7a00` |
| `daily_security/stkdlysecuritydata_20_25.csv.gz` | 806,431,932 | `275d58921e806ecb2e588dc9a1e8ae87b692045d75ac2c78b401186909dd46b0` |

The ignored 106,975-row extracted panel has SHA-256
`8fad82e719a97160072835b5c4d02a5581283473919aad67cf2346ea8da17af4`.
Both preparation and analysis fail if the recorded hashes or input schemas do
not match.

## Universe and identifier audit

The fixed universe contains all 24 ORATS-covered ETFs with a single continuous
CRSP fund identity over the extraction window, plus the liquid short-Treasury
ETF SHY from the wider CRSP universe. SMH is excluded rather than silently
spliced: the security-history table maps its ticker to old HOLDRS PERMNO 88236
through 2011-12-20 and VanEck PERMNO 13132 from 2011-12-21. QQQ remains one fund
(PERMNO 86755) and its historical `QQQQ` alias is explicitly allowed.

The covered-ticker list and all PERMNOs are frozen in the committed
configuration. Reproduction therefore requires CRSP/WRDS access but does not
require ORATS; an available ORATS directory is checked only as an independent
re-audit of the original inventory boundary.

| Ticker | PERMNO | Selection basis | Ticker | PERMNO | Selection basis |
|---|---:|---|---|---:|---|
| DIA | 85765 | ORATS | EEM | 89730 | ORATS |
| EFA | 89129 | ORATS | EMB | 92491 | ORATS |
| EWZ | 88396 | ORATS | FXE | 91047 | ORATS |
| FXI | 90383 | ORATS | GDX | 91232 | ORATS |
| GLD | 90448 | ORATS | HYG | 91933 | ORATS |
| IEF | 89469 | ORATS | IWM | 88222 | ORATS |
| IYR | 88294 | ORATS | KRE | 91315 | ORATS |
| LQD | 89467 | ORATS | QQQ | 86755 | ORATS; `QQQQ` alias |
| SHY | 89470 | CRSP addition | SLV | 91202 | ORATS |
| SPY | 84398 | ORATS | TLT | 89468 | ORATS |
| UNG | 91947 | ORATS | USO | 91208 | ORATS |
| UUP | 91758 | ORATS | XLE | 86454 | ORATS |
| XLF | 86455 | ORATS |  |  |  |

Every included fund has 4,279 observations from 2008-01-02 through
2024-12-31. The date-valid security-history audit classifies every included
PERMNO as `FUND`/`ETF` at both endpoints. The universe is liquid and
transparent, but is selected ex post from funds surviving through 2024. It is
not a survivorship-free historical opportunity set.

## Timestamp and point-in-time conventions

- `dlycaldt` is the exchange trading date and `dlyclose` is the session close.
- `dlyret` is compounded within each PERMNO to form the total-return index.
- A signal formed with observations through close `t` is not filled at that
  close. The position first earns the close-to-close return from `t+1` to
  `t+2`.
- Development (2009–2014) fixes thresholds and the initial library; validation
  (2015–2019) fixes all pruning and rankings. A SHA-256 decision record is
  formed before any locked-period score is accessed. The 2020–2024 period is a
  retrospective locked illustration, not a prospective trial.
- The CRSP files are a current snapshot. Provider corrections and
  corporate-action revisions are not revision-timestamped in the supplied
  files. The evidence is point-in-time-conscious but not point-in-time
  certified.

## Missingness and transformation audit

The extractor fails on a blank or nonnumeric required return or volume. It
does not interpolate or forward-fill. Across all 25 funds it found:

- zero duplicate `(date,ticker)` keys;
- zero missing required values;
- zero delisting-flag rows;
- zero nonblank CRSP return-missing flags;
- 4,279 complete common trading dates and zero cross-sectional dates removed;
  and
- one documented price fallback: EMB on 2008-02-20 has no positive
  `dlyclose`, so the extractor uses absolute `dlyprc` for the retained audit
  field. Returns still come from `dlyret`.

The total-return index is initialized to an arbitrary positive scale and
compounded from `dlyret`; only relative changes are used. Closing price and
volume are retained for audit. The source is trimmed at 2024-12-31 so later
observations cannot enter the run.

## Transaction costs

The base illustration charges 5 basis points one way on absolute position
turnover, or 10 basis points for a full round trip. Frozen sensitivity tables
use 1 and 10 basis points one way. These are transparent reduced-form ETF cost
assumptions, not historical spread estimates. They omit time-varying spreads,
market impact, capacity, taxes, and other implementation constraints. The
grammar is long-only, so borrow costs are outside scope.

## Gate decision

The source is adequate for a bounded, publishable mechanism audit. Raw
CRSP/WRDS rows, the local ETF panel, and other row-level licensed derivatives
must not be distributed. The aggregate tables, figures, reports, metadata,
configuration, and scripts may be included in the manuscript and replication
package. This project classification does not sublicense provider data:
reviewers reproduce the analysis with independently licensed CRSP/WRDS files.

The evidence remains inadequate for a market-alpha, prospective-validation,
survivorship-free, or fully point-in-time claim. Those are scientific design
limitations, not publication-rights blockers.
