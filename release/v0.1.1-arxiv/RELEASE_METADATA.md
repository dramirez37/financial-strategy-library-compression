# Preprint Release Metadata

- Release identifier: `v0.1.1-arxiv`
- Release date: 2026-08-25
- Repository: https://github.com/dramirez37/financial-strategy-library-compression
- Release commit: `$Format:%H$`
- Main PDF: `financial-strategy-library-compression-preprint.pdf`
- Main PDF SHA-256: 6f4097b450b3dcb0413513f8fbf9d2f7c4c91091a996cf38a988d1d230a4fde1
- Supplement PDF: `financial-strategy-library-compression-online-supplement.pdf`
- Supplement PDF SHA-256: 85e4e28a52aaad72edcca2a1611be927b65f69c76c0836030b0abf7ae384f481
- arXiv source archive: `financial-strategy-library-compression-arxiv-source.tar.gz`
- arXiv source archive SHA-256: d7270f2aad722cd6560c4d549624a988fe1658c035d8a1f8d3ad1f10b8272606
- Status: release candidate; no tag or publication action has been performed

The Git format placeholder in a working checkout is expanded to the exact
source commit by `git archive` because this file is marked `export-subst` in
`.gitattributes`. The two PDFs are built from the manuscript sources in that
same commit by `make manuscript`. `make arxiv-bundle` assembles the minimal
two-document TeX package from those sources and the resulting `main.bbl`.
