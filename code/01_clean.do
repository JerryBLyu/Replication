/*============================================================
  File:    01_clean.do
  Role:    Build canonical samples used across all estimations
============================================================*/

version 16
clear
set more off

* Ensure required sources exist.
foreach f in edited_data.dta edited_data_young.dta edited_data_36_48.dta all_years.dta occ_classification.dta {
    capture confirm file "$raw/`f'"
    if _rc != 0 {
        di as err "Missing source file: $raw/`f'"
        exit 601
    }
}

* Adult sample (main analysis window).
use "$raw/edited_data.dta", clear
keep if inrange(age,30,40)
keep if inrange(birthyear,1971,1985)
save "$proc/analysis_sample.dta", replace

* Young sample for short-run outcomes.
use "$raw/edited_data_young.dta", clear
save "$proc/analysis_sample_young.dta", replace

* Older cohorts used by placebo/falsification blocks.
use "$raw/edited_data_36_48.dta", clear
save "$proc/analysis_sample_36_48.dta", replace

* Keep supporting snapshots in processed.
use "$raw/all_years.dta", clear
save "$proc/all_years.dta", replace
use "$raw/occ_classification.dta", clear
save "$proc/occ_classification.dta", replace
use "$raw/edited_data.dta", clear
save "$proc/edited_data.dta", replace

foreach out in analysis_sample.dta analysis_sample_young.dta analysis_sample_36_48.dta all_years.dta occ_classification.dta edited_data.dta {
    capture confirm file "$proc/`out'"
    if _rc != 0 {
        di as err "Failed to create: $proc/`out'"
        exit 603
    }
}

use "$proc/analysis_sample.dta", clear
count
di as txt "Main sample rows: " r(N)
di "✓ 01_clean.do complete"
