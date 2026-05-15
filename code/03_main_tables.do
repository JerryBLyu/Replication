/*============================================================
  File:    03_main_tables.do
  Role:    Main estimation outputs (Table 2-5 + summary csvs)
============================================================*/

version 16
clear
set more off

use "$proc/analysis_sample.dta", clear
tempfile main_sample
save `main_sample'

* Export summary moments for Python slide figures.
preserve
    collapse (sum) nobs (mean) treatment aedu [aw=pondera], by(male)
    tostring male, replace force
    gen male_code = cond(lower(male)=="hombre" | lower(male)=="male" | male=="1", 1, 0)
    gen male_label = cond(male_code==1, "Male", "Female")
    order male_code male_label nobs treatment aedu
    export delimited using "$tables/mean_stats_by_gender.csv", replace
restore

tempname sepost
postfile `sepost' str6 group str8 outcome double b_treat se_treat mean_treat mean_outcome using "$tables/treat_se_by_gender.dta", replace

foreach sexflag in 0 1 {
    use `main_sample', clear
    keep if male==`sexflag'
    local suffix = cond(`sexflag'==1, "MalS", "FemS")

    collapse (sum) nobs ///
        (mean) treatment pa_days_lost pbi_pc ///
        sec_com supc aedu unemployed nilf nini ///
        log_ila log_wage ila_tot index1 hstrt informal_prod ///
        independent casado nro_kids kid_older ipcf edu_partner ///
        parent_not_delayed parent_gap_aedu ///
        (p10) log_wage_10 (p20) log_wage_20 (p30) log_wage_30 (p40) log_wage_40 (p50) log_wage_50 ///
        (p60) log_wage_60 (p70) log_wage_70 (p80) log_wage_80 (p90) log_wage_90 ///
        (p10) ila_tot_10 (p20) ila_tot_20 (p30) ila_tot_30 (p40) ila_tot_40 (p50) ila_tot_50 ///
        (p60) ila_tot_60 (p70) ila_tot_70 (p80) ila_tot_80 (p90) ila_tot_90 ///
        (p10) aedu_10 (p20) aedu_20 (p30) aedu_30 (p40) aedu_40 (p50) aedu_50 ///
        (p60) aedu_60 (p70) aedu_70 (p80) aedu_80 (p90) aedu_90 ///
        [aw=pondera], by(birthyear surveyyear province male)

    local rhs "treatment i.surveyyear i.birthyear i.province i.birthyear*surveyyear i.province*surveyyear pa_days_lost pbi_pc"
    egen cluster_id = group(province)

    local mA
    foreach y in sec_com supc aedu {
        quietly xi: reg `y' `rhs' [aw=nobs], cluster(cluster_id)
        estimates store `y'
        local mA "`mA' `y'"
    }
    esttab `mA' using "$tables/Table2_PanelA_`suffix'.csv", csv replace noomitted ///
        keep(treatment _cons) mtitles se star(* 0.10 ** 0.05 *** 0.01) se(4) b(4)
    estimates clear

    local mB
    foreach y in unemployed nilf nini {
        quietly xi: reg `y' `rhs' [aw=nobs], cluster(cluster_id)
        estimates store `y'
        local mB "`mB' `y'"
    }
    esttab `mB' using "$tables/Table2_PanelB_`suffix'.csv", csv replace noomitted ///
        keep(treatment _cons) mtitles se star(* 0.10 ** 0.05 *** 0.01) se(4) b(4)
    estimates clear

    local mC
    foreach y in log_ila log_wage ila_tot {
        quietly xi: reg `y' `rhs' [aw=nobs], cluster(cluster_id)
        estimates store `y'
        local mC "`mC' `y'"
    }
    esttab `mC' using "$tables/Table2_PanelC_`suffix'.csv", csv replace noomitted ///
        keep(treatment _cons) mtitles se star(* 0.10 ** 0.05 *** 0.01) se(4) b(4)
    estimates clear

    local mD
    foreach y in index1 hstrt informal_prod {
        quietly xi: reg `y' `rhs' [aw=nobs], cluster(cluster_id)
        estimates store `y'
        local mD "`mD' `y'"
    }
    esttab `mD' using "$tables/Table2_PanelD_`suffix'.csv", csv replace noomitted ///
        keep(treatment _cons) mtitles se star(* 0.10 ** 0.05 *** 0.01) se(4) b(4)
    estimates clear

    local m3
    foreach y in ila_tot_10 ila_tot_20 ila_tot_30 ila_tot_40 ila_tot_50 ila_tot_60 ila_tot_70 ila_tot_80 ila_tot_90 ///
                 log_wage_10 log_wage_20 log_wage_30 log_wage_40 log_wage_50 log_wage_60 log_wage_70 log_wage_80 log_wage_90 ///
                 aedu_10 aedu_20 aedu_30 aedu_40 aedu_50 aedu_60 aedu_70 aedu_80 aedu_90 {
        quietly xi: reg `y' `rhs' [aw=nobs], cluster(cluster_id)
        estimates store `y'
        local m3 "`m3' `y'"
    }
    esttab `m3' using "$tables/Table3_`suffix'.csv", csv replace noomitted ///
        keep(treatment _cons) mtitles se star(* 0.10 ** 0.05 *** 0.01) se(4) b(4)
    estimates clear

    local m4
    foreach y in independent casado nro_kids kid_older ipcf edu_partner {
        quietly xi: reg `y' `rhs' [aw=nobs], cluster(cluster_id)
        estimates store `y'
        local m4 "`m4' `y'"
    }
    esttab `m4' using "$tables/Table4_`suffix'.csv", csv replace noomitted ///
        keep(treatment _cons) mtitles se star(* 0.10 ** 0.05 *** 0.01) se(4) b(4)
    estimates clear

    local m5
    foreach y in parent_not_delayed parent_gap_aedu {
        quietly xi: reg `y' `rhs' [aw=nobs], cluster(cluster_id)
        estimates store `y'
        local m5 "`m5' `y'"
    }
    esttab `m5' using "$tables/Table5_`suffix'.csv", csv replace noomitted ///
        keep(treatment _cons) mtitles se star(* 0.10 ** 0.05 *** 0.01) se(4) b(4)
    estimates clear

    quietly summarize treatment [aw=nobs]
    local mt = r(mean)
    quietly summarize log_wage [aw=nobs]
    local myw = r(mean)
    quietly summarize aedu [aw=nobs]
    local mye = r(mean)
    quietly xi: reg log_wage `rhs' [aw=nobs], cluster(cluster_id)
    local bw = _b[treatment]
    local sew = _se[treatment]
    quietly xi: reg aedu `rhs' [aw=nobs], cluster(cluster_id)
    local be = _b[treatment]
    local see = _se[treatment]
    post `sepost' ("`suffix'") ("log_wage") (`bw') (`sew') (`mt') (`myw')
    post `sepost' ("`suffix'") ("aedu") (`be') (`see') (`mt') (`mye')
}

postclose `sepost'
use "$tables/treat_se_by_gender.dta", clear
export delimited using "$tables/treat_se_by_gender.csv", replace
erase "$tables/treat_se_by_gender.dta"
di "✓ 03_main_tables.do complete"
