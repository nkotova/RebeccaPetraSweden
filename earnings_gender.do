use "D:\NK\Input (stuff you generate)\temp\unemp_emp_data_with_ink_educ.dta", replace

bysort dnr year: egen earnings=total(tot_earnings)
bysort dnr year: gen tag=(_n==1)
keep if tag==1
keep dnr year earnings

save "D:\NK\Input (stuff you generate)\temp\dnr_year_earnings.dta", replace

use "D:\NK\Input (stuff you generate)\intermediate\treat_control_data_with_hired_before.dta", replace

*replace layoff=1 if net_emp_frac<-0.10 & frac_hired<0.05 & tot_emp>50 & tot_emp<3500 & frac_left<0.95

bysort firm before_year: gen treat=1 if before_year==year-1 & net_emp_frac<-0.10 & frac_hired<0.05 & tot_emp>50 & tot_emp<3500 & frac_left<0.95
bysort firm before_year (treat): replace treat=treat[_n-1] if _n>1

drop if treat!=1 
drop treat

gen diff_reg=diff+5

merge m:1 dnr year using "D:\NK\Input (stuff you generate)\temp\dnr_year_earnings.dta", keep(match master)
drop _merge

bysort firm before_year dnr (year): gen left=1 if before_year==year-1 & infirm==1 & infirm[_n+1]==0

bysort firm before_year dnr (year): gen treat=1 if before_year==year-1 & left==1
bysort firm before_year dnr (treat): replace treat=treat[_n-1] if _n>1
replace treat=0 if treat==.

gen diff_reg=diff+5

gen age=year-fodar
gen gender=(kon==2)

gen treat_event=diff_reg*treat
gen gender_event=diff_reg*gender

gen layoff_year=before_year+1


bysort firm_id dnr: egen earn_bal=count(earnings)

save "D:\NK\Input (stuff you generate)\temp\earnings_graph.dta", replace
use "D:\NK\Input (stuff you generate)\temp\earnings_graph.dta", replace

reghdfe earnings ib5.treat_event if earn_bal==11, absorb(firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\earnings.png", as(png) replace


reghdfe earnings i.diff_reg gender ib5.gender_event if treat==1 & earn_bal==11, absorb(firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*gender_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\earnings_gender.png", as(png) replace

