# Replication: Jaume & Willén (2019)
**"The Long-Run Effects of Teacher Strikes: Evidence from Argentina"**

ECC5591 Replication Assignment

## Replication Summary
| Metric | Score |
|---|---|
| Runnability | 8/10 |
| Result consistency | 8/10 |
| Portability | 8/10 |
| Documentation | 8/10 |
| **Overall** | **8/10** |

Core claims replicate in sign and magnitude.  
Approximate average-exposure wage effects: male `-2.64%` vs paper `-3.2%`, female `-1.57%` vs paper `-1.9%`.

## Requirements
- **Stata** >= 16 (tested on 19.5)
- Stata packages: `estout`, `reghdfe`, `ftools`, `csdid`, `event_plot` (optional), `binscatter` (optional)
- **Python** >= 3.9
- Python packages: `pandas`, `matplotlib`, `seaborn`, `numpy`, `openpyxl`

Install missing Stata packages:
```stata
ssc install estout
ssc install reghdfe
ssc install ftools
ssc install csdid
ssc install event_plot
ssc install binscatter
```

## How to Run

### Step 1: set path
Open `code/00_master.do` and edit:
```stata
global root "C:/path/to/Replication"
```
If you run from Stata GUI (File -> Do), set `global root` to your actual local path manually before execution.

### Step 2: put data
Place source files in `data/raw/` (or keep them in parent `../Data files` and use built-in fallback).

### Step 3: run Stata pipeline
```stata
do "code/00_master.do"
```

Outputs:
- tables: `output/tables/`
- figures: `output/figures/`
- log: `output/replication_log.txt`

### Step 4: build visualization-ready outputs
```bash
python code/viz/build_slides_figures.py
```

Outputs:
- `output/slides/fig_summary_effects.png`
- `output/slides/fig_distributional_wage_*.png`
- `output/final/compact_tables/Table1.xlsx` ... `Table8.xlsx`
- `output/final/latex/paper_style_report_v2.tex`
- `output/final/latex/paper_style_report_v2.pdf` (if `pdflatex` is installed)

## Output Map
- `output/tables/Table1.xls` — descriptive summary statistics by sex
- `output/tables/Table2_*.csv` to `Table8_*.csv` — main and robustness tables
- `output/tables/appendix/TA*.csv|xls` — appendix outputs
- `output/figures/Figure2A.png`, `Figure2B.png`, `FigureA1.png`
- `output/slides/*` — presentation-ready figures

## Project Structure
```text
Replication/
  code/       Stata pipeline + Python viz
  data/raw/   source datasets (not tracked)
  data/processed/
  output/     generated artifacts
  docs/       environment and notes
```

## Minimal teammate workflow (download-and-run)
1. Put raw data in `data/raw/` (or keep `../Data files` as fallback).
2. Run Stata:
   ```stata
   do "code/00_master.do"
   ```
3. Run Python:
   ```bash
   python code/viz/build_slides_figures.py
   ```
4. Use these downstream-ready files:
   - `output/tables/` (machine-readable regression tables for custom viz)
   - `output/slides/` (ready-made chart assets)
   - `output/final/compact_tables/` (8 compact table workbooks)
   - `output/final/latex/paper_style_report_v2.pdf` (final paper-style report)

## References used for visualization ideas
- [Econtech textbook Stata replications](https://github.com/Econtech/-Econometric-textbook-stata-replication)
