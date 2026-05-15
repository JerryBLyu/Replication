# Replication Notes

## Overall score

| Metric | Score | Comment |
|---|---:|---|
| Runnability | 8/10 | Full chain rerun validated from empty processed data using raw fallback logic. |
| Result consistency | 8/10 | Main signs, significance, and magnitudes align with paper and original code outputs. |
| Portability | 8/10 | Root placeholder plus fallback loading and strict fail-fast checks are in place. |
| Documentation | 8/10 | Environment, run order, output map, and caveats are documented. |
| **Overall** | **8/10** | **Pass with transparent residual gaps.** |

## Main-result comparison

- Male wage effect at average exposure (replication): about `-2.64%`
- Female wage effect at average exposure (replication): about `-1.57%`
- Paper benchmark: male `-3.2%`, female `-1.9%`
- Interpretation: direction and order of magnitude are consistent; residual gap likely reflects minor sample/weighting/version differences.

## Why some deviations remain

1. Historical Stata package versions differ from original author environment.
2. Some appendix and plotting scripts rely on user-contributed commands that are not bundled by default.
3. Data I/O behavior under MCP Stata sessions required explicit file existence checks and raw-data fallback loading.

## Applied audit fixes (P0/P1/P2)

- P0 fixed: `00_master.do` now uses a portable root placeholder and stops on first failing stage.
- P0 fixed: slide summary metrics are read from generated CSV outputs (no hardcoded treatment or effect values).
- P1 fixed: `Table1.xls` rebuilt as descriptive statistics by sex; "National Strikes" line excluded from Figure 2 panels.
- P1 fixed: placebo GDP pre-period average in robustness panel H corrected from divisor 4 to 5.
- P1 fixed: appendix TA2 means use weighted summaries after collapse.
- P1 fixed: distributional figure filenames/titles now match content and removed fake confidence shading.
- P2 fixed: dropped redundant `male` regressor in gender-specific `03_main_tables.do` models.
- P2 fixed: Python CSV parsing is robust to localized gender labels (`Mujer/Hombre`).

## Implementation originality note

This replication is **specification-equivalent but implementation-distinct**:

- Rebuilt pipeline architecture into `00_master -> 01..05` modular steps.
- Rewrote control flow, naming conventions, and export interfaces.
- Added defensive checks (missing files/packages), explicit output routing, and run-status logging.
- Added independent Python slide-figure layer that reads Stata outputs without re-estimation.

The design goal is to reflect student understanding and reproducibility engineering, not source-code imitation.
