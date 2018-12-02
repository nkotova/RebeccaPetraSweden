*Preparing unemp. spells data
use "D:\NK\Input (stuff you generate)\Insper2014_clean.dta"
drop month
bysort dnr2015227 year: drop if _n!=1
save "D:\NK\Input (stuff you generate)\intermediate\Insper2014_clean_for_graph.dta", replace



use "D:\NK\Input (stuff you generate)\unemp_emp_data.dta", clear
*CHECKCHECK RUN AGAIN TO HAVE NET_EMP INCLUDED
keep firm year tot_emp tot_left tot_hired tot_layoff frac_fired frac_left frac_hired net_emp net_emp_frac 
bysort firm year: gen tag=(_n==1)
drop if tag!=1
drop tag
save "D:\NK\Input (stuff you generate)\intermediate\firm_unemp_emp_data.dta", replace

use "D:\NK\Input (stuff you generate)\unemp_emp_data.dta", clear
keep dnr2015227 year firm fired emp_spell 
save "D:\NK\Input (stuff you generate)\intermediate\short_unemp_emp_data.dta", replace

use "D:\NK\Input (stuff you generate)\intermediate\short_unemp_emp_data.dta", replace
keep dnr2015227 year firm fired 
bysort dnr2015227 year firm (fired): keep if _n==_N 
save "D:\NK\Input (stuff you generate)\intermediate\short_unemp_emp_data2.dta", replace

use "D:\NK\Input (stuff you generate)\unemp_emp_data.dta", clear

keep firm dnr2015227 year emp_spell fired left hired quant tot_emp tot_left tot_hired net_emp net_emp_frac frac_hired frac_left

*drop if quant>=0.4
drop if firm==.

*gen net_emp=tot_hired-tot_left
*gen net_emp_frac=net_emp/tot_emp
*gen frac_hired=tot_hired/tot_emp
*gen frac_left=tot_left/tot_emp

gen layoff=0
replace layoff=1 if net_emp_frac<-0.05 & frac_hired<0.05 & tot_emp>50 & tot_emp<4000 & frac_left<0.95

gen layoff_year=year if layoff==1

bysort firm year: gen tag=(_n==1)
bysort tag firm (year): gen temp=1 if layoff[_n+1]==1 & tag==1
bysort firm year (temp): replace temp=temp[_n-1] if _n>1

drop if temp!=1

*drop if layoff!=1
*drop layoff

*drop if hired==1
*drop hired


rename year before_year

*gen treat=net_emp_frac<-0.25

*keep firm layoff_year dnr2015227 emp_spell treat 
keep firm before_year dnr2015227 emp_spell quant 

gen exp=30
expand exp
bysort firm before_year dnr2015227 emp_spell: gen year=1985 if _n==1
bysort firm before_year dnr2015227 emp_spell (year): replace year=year[_n-1]+1 if _n>1

drop if year>2013

merge m:1 dnr2015227 year using "D:\NK\Input (stuff you generate)\temp\Insper2014_clean_for_graph.dta", keep(match master)
gen unemp=(_merge==3)
drop if _merge==2
drop _merge

merge m:1 dnr2015227 year using "D:\NK\Input (stuff you generate)\initial\inc_clean.dta", keep(match master)
drop _merge

merge m:1 firm year using "D:\NK\Input (stuff you generate)\intermediate\firm_unemp_emp_data.dta", keep(match master)
drop _merge

merge m:1 dnr2015227 firm year emp_spell using "D:\NK\Input (stuff you generate)\intermediate\short_unemp_emp_data.dta", keep(match master)
gen infirm_samespell=(_merge==3)
drop _merge

merge m:1 dnr2015227 firm year using "D:\NK\Input (stuff you generate)\intermediate\short_unemp_emp_data2.dta", keep(match master)
gen infirm=(_merge==3)
drop _merge


egen firm_id=group(firm before_year)
egen id=group(dnr firm before_year)

order firm before_year tot_emp tot_left tot_hired frac_left year dnr2015227 infirm infirm_samespell emp_spell unemp kon fodar loneink fink akassa dispink

save "D:\NK\Input (stuff you generate)\temp\layoff_treatment_data_with_hired_before.dta", replace
*save "D:\NK\Input (stuff you generate)\temp\layoff_treatment_data.dta", replace

use "D:\NK\Input (stuff you generate)\temp\layoff_treatment_data_with_hired_before.dta"
*use "D:\NK\Input (stuff you generate)\temp\layoff_treatment_data.dta", clear

*egen total_fired=total(fired), by(firm_id year)
*gen frac_fired=total_fired/tot_emp

*INSERT DEFINITION OF TREATMENT AND ALSO WHICH DATA TO KEEP

gen diff=year-before_year
keep if diff<7 & diff>-5
gen check=1
gen check2=1 if year>=1990
bysort firm before_year dnr2015227: egen years_in_panel=total(check)
bysort firm before_year dnr2015227: egen years_in_panel2=total(check2)
drop if years_in_panel!=11
gen ind=(years_in_panel2==11)

*drop tag
bysort firm year: gen tag=(_n==1)
*gen treat=(frac_fired>=0.1)

sysdir set PLUS "D:\NK"

bysort year tag: egen size=xtile(tot_emp), nquantiles(10)
sum size
replace size=. if tag!=1
bysort firm year (size): replace size=size[_n-1] if _n!=1

gen size_layoff=size if year==before_year+1
bysort firm (size_layoff): replace size_layoff=size_layoff[_n-1] if _n!=1

save "D:\NK\Input (stuff you generate)\intermediate\treat_control_data_with_hired_before.dta", replace
*save "D:\NK\Input (stuff you generate)\temp\layoff_treatment_data.dta", replace
use "D:\NK\Input (stuff you generate)\intermediate\treat_control_data_with_hired_before.dta", replace

*drop if quant==0

bysort firm before_year: gen treat=1 if before_year==year-1 & net_emp_frac<-0.15 & net_emp_frac>-0.2
bysort firm before_year (treat): replace treat=treat[_n-1] if _n>1

bysort firm before_year: gen control=1 if before_year==year-1 & net_emp_frac<-0.1 &  net_emp_frac>-0.15
bysort firm before_year (control): replace control=control[_n-1] if _n>1

drop if treat!=1 & control!=1
replace treat=0 if control==1

gen diff_reg=diff+5

gen treat_event=diff_reg*treat

gen layoff_year=before_year+1

gen age=year-fodar

bysort firm_id dnr: egen loneink_bal=count(loneink)
bysort firm_id dnr: egen akassa_bal=count(akassa)
bysort firm_id dnr: egen disp_bal=count(disp)
bysort firm_id dnr: egen fink_bal=count(fink)

*** UNEMP and INFIRM *****RUN SEPARATELY FROM LAYOFF YEAR COHORT GRAPHS BC THESE GRAPHS HAVE THE SAME NAMES... FIX IT LATER

reghdfe unemp ib5.treat_event, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\unemp_treat_vs._control.png", as(png) replace

reghdfe unemp ib5.treat_event if quant>0, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\unemp_treat_vs._control_noh.png", as(png) replace

reghdfe unemp ib5.treat_event if quant<0.3, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\unemp_treat_vs._control_30p.png", as(png) replace

reghdfe unemp ib5.treat_event if quant<0.3 & quant>0 , absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\unemp_treat_vs._control_30p_noh.png", as(png) replace



reghdfe infirm ib5.treat_event, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\infirm_treat_vs._control.png", as(png) replace

reghdfe infirm ib5.treat_event if quant>0, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\infirm_treat_vs._control_noh.png", as(png) replace

reghdfe infirm ib5.treat_event if quant<0.3, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\infirm_treat_vs._control_30p.png", as(png) replace

reghdfe infirm ib5.treat_event if quant<0.3 & quant>0, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\infirm_treat_vs._control_30p_noh.png", as(png) replace




*** AGE and GENDER


reghdfe kon i.treat_event, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\gender_treat_vs._control.png", as(png) replace

reghdfe kon i.treat_event if quant>0, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\gender_treat_vs._control_noh.png", as(png) replace

reghdfe kon i.treat_event if quant<0.3, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\gender_treat_vs._control_30p.png", as(png) replace

reghdfe kon i.treat_event if quant<0.3 & quant>0, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\gender_treat_vs._control_30p_noh.png", as(png) replace




reghdfe age i.treat_event, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\age_treat_vs._control.png", as(png) replace

reghdfe age i.treat_event if quant>0, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\age_treat_vs._control_noh.png", as(png) replace

reghdfe age i.treat_event if quant<0.3, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\age_treat_vs._control_30p.png", as(png) replace

reghdfe age i.treat_event if quant<0.3 & quant>0, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\age_treat_vs._control_30p_noh.png", as(png) replace


*** LONEINK, AKASSA, DISP and FINK

*egen lonink_bal=count(loneink), by(dnr firm_id)

reghdfe loneink ib5.treat_event if lonink_bal==11, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_treat_vs._control.png", as(png) replace

reghdfe loneink ib5.treat_event if lonink_bal==11 & quant>0, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_treat_vs._control_noh.png", as(png) replace

reghdfe loneink ib5.treat_event if quant<0.3 &  lonink_bal==11 , absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_treat_vs._control_30p.png", as(png) replace

reghdfe loneink ib5.treat_event if quant<0.3 & lonink_bal==11 & quant>0, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_treat_vs._control_30p_noh.png", as(png) replace





reghdfe akassa ib5.treat_event if ind==1 & akassa_bal==11, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\akassa_treat_vs._control.png", as(png) replace

reghdfe akassa ib5.treat_event if ind==1 & akassa_bal==11 & quant>0, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\akassa_treat_vs._control_noh.png", as(png) replace

reghdfe akassa ib5.treat_event if ind==1 & akassa_bal==11 & quant<0.3, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\akassa_treat_vs._control_30p.png", as(png) replace

reghdfe akassa ib5.treat_event if ind==1 & akassa_bal==11 & quant<0.3 & quant>0, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\akassa_treat_vs._control_30p_noh.png", as(png) replace




reghdfe disp ib5.treat_event if ind==1 & disp_bal==11, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\disp_treat_vs._control.png", as(png) replace

reghdfe disp ib5.treat_event if ind==1 & disp_bal==11 & quant>0, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\disp_treat_vs._control_noh.png", as(png) replace

reghdfe disp ib5.treat_event if ind==1 & disp_bal==11 & quant<0.3, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\disp_treat_vs._control_30p.png", as(png) replace

reghdfe disp ib5.treat_event if ind==1 & disp_bal==11 & quant<0.3 & quant>0, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\disp_treat_vs._control_30p_noh.png", as(png) replace



reghdfe fink ib5.treat_event if ind==1 & fink>0 & fink_bal==11, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\fink_treat_vs._control.png", as(png) replace

reghdfe fink ib5.treat_event if ind==1 & fink>0 & fink_bal==11 & quant>0, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\fink_treat_vs._control_noh.png", as(png) replace

reghdfe fink ib5.treat_event if ind==1 & fink>0 & fink_bal==11 & quant<0.3, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\fink_treat_vs._control_30p.png", as(png) replace

reghdfe fink ib5.treat_event if ind==1 & fink>0 & fink_bal==11 & quant<0.3 & quant>0, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\fink_treat_vs._control_30p_noh.png", as(png) replace











