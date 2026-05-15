/*============================================================
  File:    04_robustness.do
  Role:    Robustness and short-run results (Table 6-8)
============================================================*/

version 16
clear
set more off

capture program drop robust_export
program define robust_export
    syntax , OUTFILE(string) VARS(string) RHS(string) KEEP(string)
    local mlist
    foreach y of local vars {
        quietly xi: reg `y' `rhs' [aw=nobs], cluster(cid)
        estimates store r_`y'
        local mlist "`mlist' r_`y'"
    }
    esttab `mlist' using "`outfile'", csv replace noomitted ///
        keep(`keep' _cons) mtitles se star(* 0.10 ** 0.05 *** 0.01) se(4) b(4)
    estimates clear
end

* --------------------------- *
* Table 6: early vs late grade *
* --------------------------- *
use "$proc/analysis_sample.dta", clear
rename birthyear cohort
gen strike_early = .
gen strike_late  = .
forvalues c = 1971/1995 {
    local g1 = `c'+6
    local g2 = `c'+7
    local g3 = `c'+8
    local g4 = `c'+9
    local g5 = `c'+10
    local g6 = `c'+11
    local g7 = `c'+12
    replace strike_early = (days_lost_`g1'+days_lost_`g2'+days_lost_`g3'+days_lost_`g4')/10 if cohort==`c'
    replace strike_late  = (days_lost_`g5'+days_lost_`g6'+days_lost_`g7')/10 if cohort==`c'
}
rename cohort birthyear
tempfile t6
save `t6'

foreach g in 0 1 {
    use `t6', clear
    keep if male==`g'
    local suffix = cond(`g'==1,"MalS","FemS")
    collapse (sum) nobs (mean) strike_early strike_late pa_days_lost pbi_pc aedu index1 log_wage ila_tot unemployed nini [aw=pondera], ///
        by(birthyear surveyyear province male)
    egen cid = group(province)
    local rhs "strike_early strike_late i.surveyyear i.birthyear i.province i.birthyear*surveyyear i.province*surveyyear pa_days_lost pbi_pc"
    robust_export, outfile("$tables/Table6_`suffix'.csv") ///
        vars("aedu index1 log_wage ila_tot unemployed nini") rhs("`rhs'") keep("strike_early strike_late")
}

* ----------------------------------------- *
* Table 7: selected sample and placebo tests *
* ----------------------------------------- *
use "$proc/analysis_sample.dta", clear
tempfile base
save `base'

forvalues s = 1/4 {
    use `base', clear
    if `s'==1 {
        keep if male==0
        local out "Table7_PA_FemS_with_caba"
    }
    if `s'==2 {
        keep if male==1
        local out "Table7_PA_MalS_with_caba"
    }
    if `s'==3 {
        keep if male==0 & provincia!=5 & provincia!=1
        local out "Table7_PB_FemS_no_bs_as"
    }
    if `s'==4 {
        keep if male==1 & provincia!=5 & provincia!=1
        local out "Table7_PB_MalS_no_bs_as"
    }
    collapse (sum) nobs (mean) treatment pa_days_lost pbi_pc aedu index1 log_wage ila_tot unemployed nini [aw=pondera], ///
        by(birthyear surveyyear province male)
    egen cid = group(province)
    local rhs "treatment i.surveyyear i.birthyear i.province i.birthyear*surveyyear i.province*surveyyear pa_days_lost pbi_pc"
    robust_export, outfile("$tables/`out'.csv") ///
        vars("aedu index1 log_wage ila_tot unemployed nini") rhs("`rhs'") keep("treatment")
}

* Panel C: low migration provinces.
foreach g in 0 1 {
    use `base', clear
    keep if male==`g' & !inlist(provincia,3,7,14,16,20)
    local suffix = cond(`g'==1,"MalS","FemS")
    collapse (sum) nobs (mean) treatment pa_days_lost pbi_pc aedu index1 log_wage ila_tot unemployed nini [aw=pondera], ///
        by(birthyear surveyyear province male)
    egen cid = group(province)
    local rhs "treatment i.surveyyear i.birthyear i.province i.birthyear*surveyyear i.province*surveyyear pa_days_lost pbi_pc"
    robust_export, outfile("$tables/Table7_PC_`suffix'_low_mig_prov.csv") ///
        vars("aedu index1 log_wage ila_tot unemployed nini") rhs("`rhs'") keep("treatment")
}

* Panel D: 2010+ survey years.
foreach g in 0 1 {
    use `base', clear
    keep if male==`g' & surveyyear>=2010
    local suffix = cond(`g'==1,"MalS","FemS")
    collapse (sum) nobs (mean) treatment pa_days_lost pbi_pc aedu index1 log_wage ila_tot unemployed nini [aw=pondera], ///
        by(birthyear surveyyear province male)
    egen cid = group(province)
    local rhs "treatment i.surveyyear i.birthyear i.province i.birthyear*surveyyear i.province*surveyyear pa_days_lost pbi_pc"
    robust_export, outfile("$tables/Table7_PD_`suffix'_2010_over.csv") ///
        vars("aedu index1 log_wage ila_tot unemployed nini") rhs("`rhs'") keep("treatment")
}

* Panel F: province-specific cohort trends excluding Buenos Aires.
foreach g in 0 1 {
    use `base', clear
    keep if male==`g' & provincia!=5
    local suffix = cond(`g'==1,"MalS","FemS")
    collapse (sum) nobs (mean) treatment pa_days_lost pbi_pc aedu index1 log_wage ila_tot unemployed nini [aw=pondera], ///
        by(birthyear surveyyear province male)
    egen cid = group(province)
    local rhs "treatment i.surveyyear i.birthyear i.province i.birthyear*surveyyear i.province*surveyyear i.province*birthyear pa_days_lost pbi_pc"
    robust_export, outfile("$tables/Table7_PF_`suffix'.csv") ///
        vars("aedu index1 log_wage ila_tot unemployed nini") rhs("`rhs'") keep("treatment")
}

* Panel G: cap high treatment at p99.
foreach g in 0 1 {
    use `base', clear
    keep if male==`g'
    local suffix = cond(`g'==1,"MalS","FemS")
    collapse (sum) nobs (mean) treatment pa_days_lost pbi_pc aedu index1 log_wage ila_tot unemployed nini [aw=pondera], ///
        by(birthyear surveyyear province male)
    quietly summarize treatment, detail
    drop if treatment > r(p99)
    egen cid = group(province)
    local rhs "treatment i.surveyyear i.birthyear i.province i.birthyear*surveyyear i.province*surveyyear pa_days_lost pbi_pc"
    robust_export, outfile("$tables/Table7_PG_`suffix'_treatment_lower_than_200.csv") ///
        vars("aedu index1 log_wage ila_tot unemployed nini") rhs("`rhs'") keep("treatment")
}

* Panel E: falsification on 36-48 cohorts.
use "$proc/analysis_sample_36_48.dta", clear
keep if inrange(birthyear,1964,1978)
rename birthyear cohort
drop treatment pa_days_lost pbi_pc
merge m:1 provincia using "$raw/prov_pbg_pc_wide.dta", nogen keep(master match)
gen fake_treat = .
gen fake_pa = .
gen fake_gdp = .
forvalues c = 1964/1978 {
    local y1 = `c'+13
    local y2 = `c'+14
    local y3 = `c'+15
    local y4 = `c'+16
    local y5 = `c'+17
    local y6 = `c'+18
    local y7 = `c'+19
    replace fake_treat = (days_lost_`y1'+days_lost_`y2'+days_lost_`y3'+days_lost_`y4'+days_lost_`y5'+days_lost_`y6'+days_lost_`y7')/10 if cohort==`c'
    replace fake_pa    = (dlpa_`y1'+dlpa_`y2'+dlpa_`y3'+dlpa_`y4'+dlpa_`y5'+dlpa_`y6'+dlpa_`y7')/10 if cohort==`c'
    replace fake_gdp   = (pbgpc`y1'+pbgpc`y2'+pbgpc`y3'+pbgpc`y4'+pbgpc`y5'+pbgpc`y6'+pbgpc`y7')/7 if cohort==`c'
}
rename cohort birthyear
tempfile fake
save `fake'

foreach g in 0 1 {
    use `fake', clear
    keep if male==`g'
    local suffix = cond(`g'==1,"MalS","FemS")
    collapse (sum) nobs (mean) fake_treat fake_pa fake_gdp aedu index1 log_wage ila_tot unemployed nini [aw=pondera], ///
        by(birthyear surveyyear province male)
    egen cid = group(province)
    local rhs "fake_treat i.surveyyear i.birthyear i.province i.birthyear*surveyyear i.province*surveyyear fake_pa fake_gdp"
    robust_export, outfile("$tables/Table7_PE_`suffix'_falsification.csv") ///
        vars("aedu index1 log_wage ila_tot unemployed nini") rhs("`rhs'") keep("fake_treat fake_pa fake_gdp")
}

* Panel H: pre-school placebo with corrected 5-year GDP mean.
use "$proc/analysis_sample.dta", clear
keep if birthyear>=1980
rename birthyear cohort
drop pbi_pc pa_days_lost treatment
merge m:1 provincia using "$raw/prov_pbg_pc_wide.dta", nogen keep(master match)
gen pre_treat = .
gen pre_pa = .
gen pre_gdp = .
gen sch_treat = .
gen sch_pa = .
gen sch_gdp = .
forvalues c = 1980/1985 {
    local a0 = `c'
    local a1 = `c'+1
    local a2 = `c'+2
    local a3 = `c'+3
    local a4 = `c'+4
    local s1 = `c'+6
    local s2 = `c'+7
    local s3 = `c'+8
    local s4 = `c'+9
    local s5 = `c'+10
    local s6 = `c'+11
    local s7 = `c'+12
    replace pre_treat = (days_lost_`a0'+days_lost_`a1'+days_lost_`a2'+days_lost_`a3'+days_lost_`a4')/10 if cohort==`c'
    replace pre_pa    = (dlpa_`a0'+dlpa_`a1'+dlpa_`a2'+dlpa_`a3'+dlpa_`a4')/10 if cohort==`c'
    replace pre_gdp   = (pbgpc`a0'+pbgpc`a1'+pbgpc`a2'+pbgpc`a3'+pbgpc`a4')/5 if cohort==`c'
    replace sch_treat = (days_lost_`s1'+days_lost_`s2'+days_lost_`s3'+days_lost_`s4'+days_lost_`s5'+days_lost_`s6'+days_lost_`s7')/10 if cohort==`c'
    replace sch_pa    = (dlpa_`s1'+dlpa_`s2'+dlpa_`s3'+dlpa_`s4'+dlpa_`s5'+dlpa_`s6'+dlpa_`s7')/10 if cohort==`c'
    replace sch_gdp   = (pbgpc`s1'+pbgpc`s2'+pbgpc`s3'+pbgpc`s4'+pbgpc`s5'+pbgpc`s6'+pbgpc`s7')/7 if cohort==`c'
}
rename cohort birthyear
keep if inrange(age,30,40)
tempfile hbase
save `hbase'

foreach g in 0 1 {
    use `hbase', clear
    keep if male==`g'
    local suffix = cond(`g'==1,"MalS","FemS")
    collapse (sum) nobs (mean) pre_treat sch_treat sch_pa sch_gdp pre_pa pre_gdp aedu index1 log_wage ila_tot unemployed nini [aw=pondera], ///
        by(birthyear surveyyear province male)
    egen cid = group(province)
    local rhs "pre_treat sch_treat i.surveyyear i.birthyear i.province i.birthyear*surveyyear i.province*surveyyear sch_pa sch_gdp pre_pa pre_gdp"
    robust_export, outfile("$tables/Table7_PH_`suffix'.csv") ///
        vars("aedu index1 log_wage ila_tot unemployed nini") rhs("`rhs'") keep("pre_treat")
}

* --------------------------- *
* Table 8: young cohorts block *
* --------------------------- *
use "$proc/analysis_sample_young.dta", clear
rename birthyear cohort
drop treatment pa_days_lost
gen treatment = .
gen pa_days_lost = .
forvalues c = 1986/2003 {
    local y1 = `c'+6
    local y2 = `c'+7
    local y3 = `c'+8
    local y4 = `c'+9
    local y5 = `c'+10
    local y6 = `c'+11
    replace treatment = (days_lost_`y1'+days_lost_`y2'+days_lost_`y3'+days_lost_`y4'+days_lost_`y5'+days_lost_`y6')/10 if cohort==`c'
    replace pa_days_lost = (dlpa_`y1'+dlpa_`y2'+dlpa_`y3'+dlpa_`y4'+dlpa_`y5'+dlpa_`y6') if cohort==`c'
}
rename cohort birthyear
keep if inrange(birthyear,1991,2003)
tempfile young
save `young'

foreach g in 0 1 {
    use `young', clear
    keep if male==`g' & inrange(age,12,17)
    local suffix = cond(`g'==1,"MalS","FemS")
    replace asiste = 1 if aedu>=12
    gen drop_out = (asiste==0 & aedu<12)
    replace drop_out = 0 if asiste==1
    forvalues q = 1/4 {
        gen tq_`q' = cond(qipcf_prov==`q', treatment, 0)
    }
    forvalues e = 1/5 {
        gen te_`e' = cond(max_edu_parents==`e', treatment, 0)
    }
    egen cid = group(province)

    local c1 "treatment i.surveyyear i.birthyear i.province i.birthyear*surveyyear i.province*surveyyear pa_days_lost"
    local c2 "treatment i.surveyyear i.birthyear i.province i.birthyear*surveyyear i.province*surveyyear av_wage unemp i.qipcf i.max_edu_parents pa_days_lost"
    local c3 "i.surveyyear i.birthyear i.province i.birthyear*surveyyear i.province*surveyyear av_wage unemp i.max_edu_parents te_* pa_days_lost"
    local c4 "i.surveyyear i.birthyear i.province i.birthyear*surveyyear i.province*surveyyear av_wage unemp i.qipcf tq_* pa_days_lost"

    local t8m
    local ta8m
    foreach y in edu_pub aedu nini drop_out {
        quietly xi: reg `y' `c1' [aw=pondera], cluster(cid)
        estimates store `y'1
        quietly xi: reg `y' `c2' [aw=pondera], cluster(cid)
        estimates store `y'2
        quietly xi: reg `y' `c3' [aw=pondera], cluster(cid)
        estimates store `y'3
        quietly xi: reg `y' `c4' [aw=pondera], cluster(cid)
        estimates store `y'4
        local t8m "`t8m' `y'1 `y'2"
        local ta8m "`ta8m' `y'3 `y'4"
    }
    esttab `t8m' using "$tables/Table8_`suffix'_12_17.csv", csv replace noomitted ///
        keep(treatment pa_days_lost _cons) mtitles se star(* 0.10 ** 0.05 *** 0.01) se(4) b(4)
    esttab `ta8m' using "$appendix/TA8_`suffix'_12_17.csv", csv replace noomitted ///
        keep(te_* tq_* pa_days_lost _cons) mtitles se star(* 0.10 ** 0.05 *** 0.01) se(4) b(4)
    estimates clear
}
di "✓ 04_robustness.do complete"
