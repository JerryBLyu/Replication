# Environment Audit

Date: 2026-05-15  
Project root: `Replication/`

## Stata
- Version: `19.5` (via `display c(stata_version)`)

### Installed ados (checked)
- `reghdfe`: installed
- `ftools`: installed
- `csdid`: installed
- `estout`: installed
- `event_plot`: missing
- `binscatter`: missing

### Install commands for missing Stata packages
```stata
ssc install event_plot
ssc install binscatter
```

## Python
- Version: `Python 3.13.2`

### Required packages status
- `pandas`: installed (`2.3.1`)
- `matplotlib`: installed (`3.10.5`)
- `seaborn`: installed (`0.13.2`)
- `numpy`: installed (`2.3.1`)
- `openpyxl`: installed (`3.1.5`)
- `jupyterlab`: installed (`4.4.5`)

### Reinstall command (if needed)
```bash
pip install pandas matplotlib seaborn numpy openpyxl jupyterlab
```

## Notes
- The Stata pipeline runs without `event_plot`, but full visual appendix compatibility and optional event-study plotting are cleaner after installing it.
- `binscatter` is required if you want to reproduce the original Figure 3 script directly.
