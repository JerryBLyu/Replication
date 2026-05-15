/*============================================================
  File:    05_appendix.do
  Role:    Appendix tables and Figure A1
============================================================*/

version 16
clear
set more off

capture program drop app_export
program define app_export
    syntax , OUTFILE(string) VARS(string) RHS(string) KEEP(string)
    local ml
    foreach y of local vars {
        quietly xi: reg `y' `rhs' [aw=nobs], cluster(cid)
        estimates store a_`y'
        local ml "`ml' a_`y'"
    }
    esttab `ml' using "`outfile'", csv replace noomitted ///
        keep(`keep' _cons) mtitles se star(* 0.10 ** 0.05 *** 0.01) se(4) b(4)
    estimates clear
end

* TA1: stay-in-province share at age 13.
use "$proc/all_years.dta", clear
keep if edad==13
gen stay = (old_provincia==provincia)
collapse (sum) nobs=pondera (mean) stay [aw=pondera], by(provincia)
gen stay_share = 100*stay
keep provincia stay_share
export excel using "$appendix/TA1.xls", replace firstrow(variables)

* TA2: weighted means by sex.
use "$proc/analysis_sample.dta", clear
collapse (sum) nobs ///
    (mean) sec_com aedu supc unemployed nilf nini informal_prod hstrt index1 ///
    log_ila ila_tot log_wage independent casado nro_kids ipcf edu_partner ///
    kid_older2 parent_not_delayed parent_gap_aedu [aw=pondera], ///
    by(birthyear surveyyear province male)
preserve
    keep if male==1
    collapse (mean) sec_com aedu supc unemployed nilf nini informal_prod hstrt index1 ///
        log_ila ila_tot log_wage independent casado nro_kids ipcf edu_partner ///
        kid_older2 parent_not_delayed parent_gap_aedu [aw=nobs]
    gen sex = "Male"
    tempfile male_means
    save `male_means'
restore
keep if male==0
collapse (mean) sec_com aedu supc unemployed nilf nini informal_prod hstrt index1 ///
    log_ila ila_tot log_wage independent casado nro_kids ipcf edu_partner ///
    kid_older2 parent_not_delayed parent_gap_aedu [aw=nobs]
gen sex = "Female"
append using `male_means'
order sex
export excel using "$appendix/TA2.xls", replace firstrow(variables)

* TA3 and TA5 from alternative FE/control sets.
use "$proc/analysis_sample.dta", clear
tempfile base
save `base'

foreach g in 0 1 {
    use `base', clear
    keep if male==`g'
    local suffix = cond(`g'==1,"MalS","FemS")
    collapse (sum) nobs ///
        (mean) treatment pa_days_lost pbi_pc ///
        sec_com supc aedu unemployed nilf nini log_ila log_wage ila_tot index1 hstrt informal_prod ///
        [aw=pondera], by(birthyear surveyyear province male)
    egen cid = group(province)

    local rhs_ta3 "treatment i.surveyyear*i.birthyear i.province*i.surveyyear pa_days_lost pbi_pc"
    app_export, outfile("$appendix/TA3PanelA_`suffix'.csv") vars("sec_com supc aedu") rhs("`rhs_ta3'") keep("treatment pa_days_lost pbi_pc")
    app_export, outfile("$appendix/TA3PanelB_`suffix'.csv") vars("unemployed nilf nini") rhs("`rhs_ta3'") keep("treatment pa_days_lost pbi_pc")
    app_export, outfile("$appendix/TA3PanelC_`suffix'.csv") vars("log_ila log_wage ila_tot") rhs("`rhs_ta3'") keep("treatment pa_days_lost pbi_pc")
    app_export, outfile("$appendix/TA3PanelD_`suffix'.csv") vars("index1 hstrt informal_prod") rhs("`rhs_ta3'") keep("treatment pa_days_lost pbi_pc")

    local rhs_a "treatment i.surveyyear i.birthyear i.province i.birthyear*surveyyear i.province*surveyyear"
    local rhs_b "treatment i.surveyyear i.birthyear i.province i.birthyear*surveyyear i.province*surveyyear pa_days_lost pbi_pc"
    app_export, outfile("$appendix/TA5Panel_A_`suffix'.csv") vars("aedu index1 log_wage ila_tot unemployed nini") rhs("`rhs_a'") keep("treatment")
    app_export, outfile("$appendix/TA5Panel_B_`suffix'.csv") vars("aedu index1 log_wage ila_tot unemployed nini") rhs("`rhs_b'") keep("treatment pa_days_lost pbi_pc")
}

* TA6 local labor market predictors.
use "$proc/all_years.dta", clear
rename ano year
gen nobs = 1
gen tot_days_lost = .
gen pa_days_lost = .
forvalues y = 2003/2014 {
    replace tot_days_lost = days_lost_`y' if year==`y'
    replace pa_days_lost  = dlpa_`y' if year==`y'
}
keep if inrange(edad,41,50)
collapse (sum) nobs (mean) tot_days_lost pa_days_lost desocupa wage ipcf [aw=pondera], by(provincia year)
egen cid = group(provincia)
replace desocupa = 100*desocupa
xi: reg tot_days_lost desocupa wage ipcf [aw=nobs], cluster(cid)
estimates store l1
xi: reg tot_days_lost pa_days_lost desocupa wage ipcf i.provincia i.year i.provincia*year [aw=nobs], cluster(cid)
estimates store l2
esttab l1 l2 using "$appendix/TA6_local_labor_markets.csv", csv replace noomitted ///
    keep(pa_days_lost desocupa wage ipcf _cons) mtitles se star(* 0.10 ** 0.05 *** 0.01) se(4) b(4) r2
estimates clear

* TA7 + Figure A1.
use "$raw/Teacher_wages_and_strikes.dta", clear
gen inflation = .
replace inflation = 1 if year==1995
replace inflation = 1.001556769 if year==1996
replace inflation = 1.006850878 if year==1997
replace inflation = 1.016160876 if year==1998
replace inflation = 1.004305547 if year==1999
replace inflation = 0.994874047 if year==2000
replace inflation = 0.984273636 if year==2001
replace inflation = 1.238890895 if year==2002
replace inflation = 1.405436795 if year==2003
replace inflation = 1.467500698 if year==2004
replace inflation = 1.609002954 if year==2005
replace inflation = 1.784326972 if year==2006
replace inflation = 2.07803654 if year==2007
replace inflation = 2.579663032 if year==2008
replace inflation = 3.01975879 if year==2009
gen real_wage = Wage/inflation
sort provincia year
gen wage_l1 = real_wage[_n-1] if provincia==provincia[_n-1]
gen wage_f1 = real_wage[_n+1] if provincia==provincia[_n+1]
gen wage_change_96_09 = (real_wage[_n]-real_wage[_n-13])/real_wage[_n-13]*100 if provincia==provincia[_n-13] & year==2009
egen strike_sum_96_09 = sum(days_teacher_strike) if inrange(year,1996,2009), by(province)
twoway (scatter wage_change_96_09 strike_sum_96_09 if strike_sum_96_09>50) ///
       (lfit wage_change_96_09 strike_sum_96_09 if strike_sum_96_09>50), ///
       xtitle("Total strike days (1996-2009)") ///
       ytitle("Change in teacher real wages (1996-2009)") ///
       legend(off) graphregion(color(white))
graph export "$figures/FigureA1.png", replace width(2400)
xi: reg days_teacher_strike real_wage wage_l1 wage_f1, cluster(province)
estimates store w1
xi: reg days_teacher_strike real_wage wage_l1 wage_f1 i.province i.year i.province*year days_pa_strike, cluster(province)
estimates store w2
esttab w1 w2 using "$appendix/TA7_Regressions_wages_strikes.csv", csv replace noomitted ///
    keep(real_wage wage_l1 wage_f1 _cons) mtitles se star(* 0.10 ** 0.05 *** 0.01) se(4) b(4) r2
estimates clear

* TA9: split treatment into primary and secondary windows.
use "$proc/edited_data.dta", clear
rename birthyear cohort
rename age age_years
drop treatment
gen treat_primary = .
gen treat_secondary = .
forvalues c = 1971/1995 {
    local p1 = `c'+6
    local p2 = `c'+7
    local p3 = `c'+8
    local p4 = `c'+9
    local p5 = `c'+10
    local p6 = `c'+11
    local p7 = `c'+12
    local s1 = `c'+13
    local s2 = `c'+14
    local s3 = `c'+15
    local s4 = `c'+16
    local s5 = `c'+17
    replace treat_primary = (days_lost_`p1'+days_lost_`p2'+days_lost_`p3'+days_lost_`p4'+days_lost_`p5'+days_lost_`p6'+days_lost_`p7')/10 if cohort==`c'
    replace treat_secondary = (days_lost_`s1'+days_lost_`s2'+days_lost_`s3'+days_lost_`s4'+days_lost_`s5')/10 if cohort==`c' & age_years>=13
}
gen pa_primary = .
gen pa_secondary = .
forvalues c = 1971/1985 {
    local p1 = `c'+6
    local p2 = `c'+7
    local p3 = `c'+8
    local p4 = `c'+9
    local p5 = `c'+10
    local p6 = `c'+11
    local p7 = `c'+12
    local s1 = `c'+13
    local s2 = `c'+14
    local s3 = `c'+15
    local s4 = `c'+16
    local s5 = `c'+17
    replace pa_primary = (dlpa_`p1'+dlpa_`p2'+dlpa_`p3'+dlpa_`p4'+dlpa_`p5'+dlpa_`p6'+dlpa_`p7')/10 if cohort==`c'
    replace pa_secondary = (dlpa_`s1'+dlpa_`s2'+dlpa_`s3'+dlpa_`s4'+dlpa_`s5')/10 if cohort==`c' & age_years>=13
}
rename cohort birthyear
rename age_years age
keep if inrange(age,30,40)
drop if treat_primary==.
tempfile ta9
save `ta9'
foreach g in 0 1 {
    use `ta9', clear
    keep if male==`g'
    local suffix = cond(`g'==1,"MalS","FemS")
    collapse (sum) nobs (mean) treat_primary treat_secondary pa_primary pa_secondary aedu unemployed nini log_wage ila_tot index1 [aw=pondera], ///
        by(birthyear surveyyear province male)
    egen cid = group(province)
    local rhs "treat_primary treat_secondary pa_primary pa_secondary i.surveyyear i.birthyear i.province i.birthyear*surveyyear i.province*surveyyear"
    app_export, outfile("$appendix/TA9`suffix'.csv") vars("aedu index1 log_wage ila_tot unemployed nini") rhs("`rhs'") keep("treat_primary treat_secondary")
}

* TA10: treatment intensity vs duration.
use "$proc/edited_data.dta", clear
rename birthyear cohort
forvalues y = 1977/1982 {
    capture gen n_strike_`y' = 0
    capture gen ns_public_ad_`y' = 0
}
gen n_strike_total = .
gen n_pa_total = .
forvalues c = 1971/1995 {
    local s1 = `c'+6
    local s2 = `c'+7
    local s3 = `c'+8
    local s4 = `c'+9
    local s5 = `c'+10
    local s6 = `c'+11
    local s7 = `c'+12
    replace n_strike_total = n_strike_`s1'+n_strike_`s2'+n_strike_`s3'+n_strike_`s4'+n_strike_`s5'+n_strike_`s6'+n_strike_`s7' if cohort==`c'
    replace n_pa_total = ns_public_ad_`s1'+ns_public_ad_`s2'+ns_public_ad_`s3'+ns_public_ad_`s4'+ns_public_ad_`s5'+ns_public_ad_`s6'+ns_public_ad_`s7' if cohort==`c'
}
rename cohort birthyear
gen avg_duration = treatment / n_strike_total * 10
gen avg_duration_pa = pa_days_lost / n_pa_total
keep if inrange(age,30,40) & birthyear>=1971
tempfile ta10
save `ta10'
foreach g in 0 1 {
    use `ta10', clear
    keep if male==`g'
    local suffix = cond(`g'==1,"MalS","FemS")
    collapse (sum) nobs (mean) treatment avg_duration avg_duration_pa pa_days_lost pbi_pc aedu index1 log_wage ila_tot unemployed nini [aw=pondera], ///
        by(birthyear surveyyear province male)
    egen cid = group(province)
    local rhs "treatment avg_duration avg_duration_pa i.surveyyear i.birthyear i.province i.birthyear*surveyyear i.province*surveyyear pa_days_lost pbi_pc"
    app_export, outfile("$appendix/TA10_`suffix'.csv") vars("aedu index1 log_wage ila_tot unemployed nini") rhs("`rhs'") keep("treatment avg_duration")
}
di "✓ 05_appendix.do complete"
