/*============================================================
  File:    02_descriptive.do
  Role:    Descriptives and strike-trend figures
============================================================*/

version 16
clear
set more off

* ------------------------------ *
* Table 1: descriptive statistics *
* ------------------------------ *
use "$proc/analysis_sample.dta", clear

collapse ///
    (sum) nobs ///
    (mean) sec_com supc aedu unemployed nilf nini log_wage ila_tot index1 hstrt ///
    (sd) sec_com_sd=sec_com supc_sd=supc aedu_sd=aedu unemployed_sd=unemployed ///
        nilf_sd=nilf nini_sd=nini log_wage_sd=log_wage ila_tot_sd=ila_tot ///
        index1_sd=index1 hstrt_sd=hstrt ///
    [aw=pondera], by(male)

gen sex_label = cond(male==1, "Male", "Female")
order sex_label male nobs
export excel using "$tables/Table1.xls", replace firstrow(variables)

* ------------------------------ *
* Figure 2A: strike days by year *
* ------------------------------ *
use "$raw/Day_lost_by_year_1983_2014_no_national_strikes.dta", clear
reshape long days_lost_, i(provincia province) j(year)
drop if province=="National Strikes"
twoway line days_lost_ year, ///
    by(province, compact note("")) ///
    yline(0, lpattern(dash) lcolor(gs10)) ///
    xline(1998, lcolor(navy)) ///
    xtitle("Year") ///
    ytitle("Teacher strike days") ///
    graphregion(color(white))
graph export "$figures/Figure2A.png", replace width(2400)

* ---------------------------------- *
* Figure 2B: number of strike events *
* ---------------------------------- *
use "$raw/number_teacher_strikes_1983_2014_no_national_strikes.dta", clear
reshape long n_strike_, i(provincia province) j(year)
drop if province=="National Strikes"
twoway line n_strike_ year, ///
    by(province, compact note("")) ///
    yline(0, lpattern(dash) lcolor(gs10)) ///
    xline(1998, lcolor(navy)) ///
    xtitle("Year") ///
    ytitle("Number of strike events") ///
    graphregion(color(white))
graph export "$figures/Figure2B.png", replace width(2400)
di "✓ 02_descriptive.do complete"
