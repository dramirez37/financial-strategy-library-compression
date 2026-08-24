# Annual Walk-Forward Financial Audit: Data Audit

**Disposition:** aggregate mechanism outputs are publishable; licensed raw and row-level inputs are not redistributed.

The annual universe audit found 427 ETFs classified `FUND`/`ETF` at both endpoint dates and admitted 159 after predeclared identity, history, price, liquidity, flag, and complex-product gates. It selected the top 100 by 2009--2014 median dollar volume. The selection script parsed no return outcome, and the immutable selection manifest was included in the initial analytical lock `2af8b413e2b37eea94cb9a5ded6b48d6ca268be7d92fcaf0823be9830be994bc` before the return panel was prepared.

The source is the same existing CRSP/WRDS daily-security and security-history snapshot used by the terminal audit, at sibling commit `3146029aa71dfe7639ede9ca79f81602165125e8`. No network request or download occurred. Dates use CRSP `dlycaldt`; signals use information through close `t`; the two-return-index lag prevents contemporaneous execution. `dlyret` is compounded within PERMNO. Prices and volumes are never interpolated.

The local derivative has 427900 rows and 4279 complete common dates from 2008-01-02 through 2024-12-31; 0 union dates were removed. The snapshot is point-in-time-conscious but not revision-timestamped, and the endpoint-stable universe remains survivorship-biased.

The base turnover charge is 5.0 basis points one way, with frozen 1.0/5.0/10.0-basis-point sensitivities. These are reduced-form costs, not reconstructed historical spreads. Reviewers reproduce the row-level stage with independently licensed CRSP/WRDS files. This design supports mechanism validation only, never a market-alpha claim.
