/*============================================================
  File:    00_master.do
  Role:    One-click entry for independent replication code
============================================================*/

version 16
clear all
set more off

* User can set this once on local machine.
global root "C:/path/to/Replication"

* Respect an explicitly set root. Only auto-detect when placeholder/empty/invalid.
capture confirm file "$root/code/00_master.do"
local root_valid = (_rc==0)

if "$root"=="C:/path/to/Replication" | "$root"=="" | `root_valid'==0 {
    local _pwd = subinstr(c(pwd),"\","/",.)
    local _detected_root "`_pwd'"
    if substr("`_pwd'", max(1, length("`_pwd'")-4), 5)=="/code" {
        local _detected_root = substr("`_pwd'", 1, length("`_pwd'")-5)
    }

    capture confirm file "`_detected_root'/code/00_master.do"
    if _rc==0 {
        global root "`_detected_root'"
        di as txt "Auto root from current working directory: $root"
    }
    else {
        di as err "Root path invalid. Set global root to your local Replication folder."
        exit 198
    }
}

global code    "$root/code"
global raw     "$root/data/raw"
global proc    "$root/data/processed"
global output  "$root/output"
global tables  "$output/tables"
global figures "$output/figures"
global slides  "$output/slides"
global appendix "$tables/appendix"
global legacy_raw "$root/../Data files"

* Pick data source folder: repo raw first, then external fallback.
capture confirm file "$raw/edited_data.dta"
if _rc != 0 {
    capture confirm file "$legacy_raw/edited_data.dta"
    if _rc != 0 {
        di as err "Cannot find edited_data.dta in data/raw or ../Data files"
        exit 601
    }
    global raw "$legacy_raw"
}

foreach d in "$proc" "$output" "$tables" "$figures" "$slides" "$appendix" {
    capture mkdir "`d'"
}

* Install core dependencies automatically.
foreach pkg in estout reghdfe ftools csdid {
    capture which `pkg'
    if _rc != 0 {
        di as txt "Installing missing package: `pkg'"
        capture ssc install `pkg', replace
        capture which `pkg'
        if _rc != 0 {
            di as err "Installation failed for `pkg'"
            exit 199
        }
    }
}

* Optional packages: warn only if unavailable.
foreach pkg in event_plot binscatter {
    capture which `pkg'
    if _rc != 0 {
        di as txt "Installing optional package: `pkg'"
        capture ssc install `pkg', replace
        capture which `pkg'
        if _rc != 0 di as err "Warning: optional package unavailable: `pkg'"
    }
}

capture log close _all
log using "$output/replication_log.txt", text replace

local pipeline ///
    "01_clean.do" ///
    "02_descriptive.do" ///
    "03_main_tables.do" ///
    "04_robustness.do" ///
    "05_appendix.do"

foreach f of local pipeline {
    di as result "Running: `f'"
    capture noisily do "$code/`f'"
    if _rc != 0 {
        di as err "Pipeline stopped at `f' with rc=" _rc
        log close
        exit _rc
    }
}

log close
di as result "All replication stages completed successfully."
