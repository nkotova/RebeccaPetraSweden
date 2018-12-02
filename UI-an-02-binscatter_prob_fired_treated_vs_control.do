*Preparing unemp. spells data
use "D:\NK\Input (stuff you generate)\Insper2014_clean.dta"
drop month
bysort dnr2015227 year: drop if _n!=1
save "D:\NK\Input (stuff you generate)\intermediate\Insper2014_clean_for_graph.dta", replace

*Preparing income data
*use "D:\NK\Input (stuff you generate)\initial\inc_clean.dta", clear
*keep dnr2015227 year loneink akassa fink dispink kon fodar
*save "D:\NK\Input (stuff you generate)\intermediate\inc_clean_for_graph.dta", replace

use "D:\NK\Input (stuff you generate)\unemp_emp_data.dta", clear
keep dnr2015227 year firm fired emp_spell 
save "D:\NK\Input (stuff you generate)\intermediate\short_unemp_emp_data.dta", replace

use "D:\NK\Input (stuff you generate)\intermediate\short_unemp_emp_data.dta", replace
keep dnr2015227 year firm fired 
bysort dnr2015227 year firm (fired): keep if _n==_N 
save "D:\NK\Input (stuff you generate)\intermediate\short_unemp_emp_data2.dta", replace

use "D:\NK\Input (stuff you generate)\unemp_emp_data.dta", clear
*CHECKCHECK RUN AGAIN TO HAVE NET_EMP INCLUDED
keep firm year tot_emp tot_left tot_hired tot_layoff frac_fired frac_left frac_hired net_emp net_emp_frac 
bysort firm year: gen tag=(_n==1)
drop if tag!=1
drop tag
save "D:\NK\Input (stuff you generate)\intermediate\firm_unemp_emp_data.dta", replace


use "D:\NK\Input (stuff you generate)\unemp_emp_data.dta", clear

keep firm dnr2015227 year emp_spell quant fired left hired tot_emp tot_left tot_hired net_emp net_emp_frac frac_hired frac_left

*gen net_emp=tot_hired-tot_left
*gen net_emp_frac=net_emp/tot_emp
*gen frac_hired=tot_hired/tot_emp
*gen frac_left=tot_left/tot_emp

gen layoff=0
replace layoff=1 if net_emp_frac<-0.05 & frac_hired<0.05 & tot_emp>50 & tot_emp<4000 & frac_left<0.95

drop if layoff!=1
drop layoff

*drop if hired==1
*drop hired

*drop if quant>=0.4
drop if firm==.

rename year layoff_year

*gen treat=net_emp_frac<-0.25

*keep firm layoff_year dnr2015227 emp_spell treat 
keep firm layoff_year dnr2015227 emp_spell quant

gen exp=30
expand exp
bysort firm layoff_year dnr2015227 emp_spell: gen year=1985 if _n==1
bysort firm layoff_year dnr2015227 emp_spell (year): replace year=year[_n-1]+1 if _n>1

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


egen firm_id=group(firm layoff_year)
egen id=group(dnr firm layoff_year)

order firm layoff_year tot_emp tot_left tot_hired frac_left year dnr2015227 infirm infirm_samespell emp_spell unemp kon fodar loneink fink akassa dispink

save "D:\NK\Input (stuff you generate)\temp\layoff_treatment_data_with_hired.dta", replace
*save "D:\NK\Input (stuff you generate)\temp\layoff_treatment_data.dta", replace

use "D:\NK\Input (stuff you generate)\temp\layoff_treatment_data_with_hired.dta"
*use "D:\NK\Input (stuff you generate)\temp\layoff_treatment_data.dta", clear

*egen total_fired=total(fired), by(firm_id year)
*gen frac_fired=total_fired/tot_emp



*INSERT DEFINITION OF TREATMENT AND ALSO WHICH DATA TO KEEP

gen diff=year-layoff_year
keep if diff<6 & diff>-6
gen check=1
gen check2=1 if year>=1990
bysort firm layoff_year dnr2015227: egen years_in_panel=total(check)
bysort firm layoff_year dnr2015227: egen years_in_panel2=total(check2)
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

gen size_layoff=size if year==layoff_year
bysort firm (size_layoff): replace size_layoff=size_layoff[_n-1] if _n!=1

save "D:\NK\Input (stuff you generate)\intermediate\treat_control_data_with_hired.dta", replace
*save "D:\NK\Input (stuff you generate)\temp\layoff_treatment_data.dta", replace
use "D:\NK\Input (stuff you generate)\intermediate\treat_control_data_with_hired.dta", replace

*drop if quant==0

bysort firm layoff_year: gen treat=1 if layoff_year==year & net_emp_frac<-0.1 &  net_emp_frac>-0.15
bysort firm layoff_year (treat): replace treat=treat[_n-1] if _n>1

bysort firm layoff_year: gen control=1 if layoff_year==year & net_emp_frac<-0.05 &  net_emp_frac>-0.1
bysort firm layoff_year (control): replace control=control[_n-1] if _n>1

drop if treat!=1 & control!=1
replace treat=0 if control==1

gen age=year-fodar
gen diff_reg=diff+6

gen treat_event=diff_reg*treat
*areg unemp ib5.treat_event i.size##i.year, absorb(id) vce(cluster firm_id)

egen temp_yob=mode(fodar), by (dnr)
replace fodar=temp
drop temp_yob

egen temp_gender=mode(kon), by (dnr)
replace kon=temp_gender
drop temp_gender

bysort firm_id dnr: egen loneink_bal=count(loneink)
bysort firm_id dnr: egen akassa_bal=count(akassa)
bysort firm_id dnr: egen disp_bal=count(disp)
bysort firm_id dnr: egen fink_bal=count(fink)

*** UNEMP and INFIRM

reghdfe unemp ib5.treat_event, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\1_unemp_treat_vs._control.png", as(png) replace

reghdfe unemp ib5.treat_event if quant>0, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\1_unemp_treat_vs._control_noh.png", as(png) replace

reghdfe unemp ib5.treat_event if quant<0.3, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\1_unemp_treat_vs._control_30p.png", as(png) replace

reghdfe unemp ib5.treat_event if quant<0.3 & quant>0 , absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\1_unemp_treat_vs._control_30p_noh.png", as(png) replace



reghdfe infirm ib6.treat_event, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\infirm_treat_vs._control.png", as(png) replace

reghdfe infirm ib6.treat_event if quant>0, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\infirm_treat_vs._control_noh.png", as(png) replace

reghdfe infirm ib6.treat_event if quant<0.3, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\infirm_treat_vs._control_30p.png", as(png) replace

reghdfe infirm ib6.treat_event if quant<0.3 & quant>0, absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
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




































reghdfe infirm_samespell ib6.treat_event , absorb(i.size_layoff##i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\infirm_samespell_treat_vs._control.png", as(png) replace

reghdfe fired ib5.treat_event , absorb(i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\fired_treat_vs._control.png", as(png) replace

reghdfe loneink ib5.treat_event , absorb(i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_treat_vs._control.png", as(png) replace

reghdfe akassa ib5.treat_event if ind==1, absorb(i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\akassa_treat_vs._control.png", as(png) replace

reghdfe disp ib5.treat_event if ind==1, absorb(i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\disp_treat_vs._control.png", as(png) replace

reghdfe fink ib5.treat_event if ind==1 & fink>0, absorb(i.layoff_year##i.year firm_id) vce(cluster firm_id)
coefplot, drop(_cons 0.*) keep(*treat_event*) yline(6) xline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\fink_treat_vs._control.png", as(png) replace


reg unemp treat##ib5.diff_reg i.size##i.year,r absorb(dnr2015227)
coefplot, drop(_cons) keep(1.treat#*) yline(6) xline(0) omitted baselevels
*graph export "D:\NK\Output (graphs and tables)\meetings\frac_unemp_treat_vs_control_coefplot.png", as(png) replace
graph export "D:\NK\Output (graphs and tables)\meetings\net_emp\frac_unemp_treat_vs_control_coefplot.png", as(png) replace

areg fired treat##ib5.diff_reg i.size##i.year, absorb(id) vce(cluster firm_id)
*reg fired treat##ib5.diff_reg i.size##i.year,r absorb(dnr2015227)
coefplot, drop(_cons) keep(1.treat#*) yline(6) xline(0) omitted baselevels
*graph export "D:\NK\Output (graphs and tables)\meetings\frac_fired_treat_vs_control_coefplot.png", as(png) replace
graph export "D:\NK\Output (graphs and tables)\meetings\net_emp\frac_fired_treat_vs_control_coefplot.png", as(png) replace

reg left treat##ib5.diff_reg i.size##i.year,r absorb(dnr2015227)
coefplot, drop(_cons) keep(1.treat#*) yline(6) xline(0) omitted baselevels
*graph export "D:\NK\Output (graphs and tables)\meetings\frac_left_treat_vs_control_coefplot.png", as(png) replace
graph export "D:\NK\Output (graphs and tables)\meetings\net_emp\frac_left_treat_vs_control_coefplot.png", as(png) replace

gen inter=unemp*left

reg inter treat##ib5.diff_reg i.size##i.year,r absorb(dnr2015227)
coefplot, drop(_cons) keep(1.treat#*) yline(6) xline(0) omitted baselevels
*graph export "D:\NK\Output (graphs and tables)\meetings\frac_unemp_and_left_treat_vs_control_coefplot.png", as(png) replace
graph export "D:\NK\Output (graphs and tables)\meetings\net_emp\frac_unemp_and_left_treat_vs_control_coefplot.png", as(png) replace


reg loneink treat##ib5.diff_reg i.size##i.year,r absorb(dnr2015227)
coefplot, drop(_cons) keep(1.treat#*) yline(6) xline(0) omitted baselevels
*graph export "D:\NK\Output (graphs and tables)\meetings\loneink_treat_vs_control_coefplot.png", as(png) replace
graph export "D:\NK\Output (graphs and tables)\meetings\net_emp\loneink_treat_vs_control_coefplot.png", as(png) replace


reg akassa treat##ib5.diff_reg i.size##i.year,r absorb(dnr2015227)
coefplot, drop(_cons) keep(1.treat#*) yline(6) xline(0) omitted baselevels
*graph export "D:\NK\Output (graphs and tables)\meetings\akassa_treat_vs_control_coefplot.png", as(png) replace
graph export "D:\NK\Output (graphs and tables)\meetings\net_emp\akassa_treat_vs_control_coefplot.png", as(png) replace


reg fink treat##ib5.diff_reg i.size##i.year,r absorb(dnr2015227)
coefplot, drop(_cons) keep(1.treat#*) yline(6) xline(0) omitted baselevels
*graph export "D:\NK\Output (graphs and tables)\meetings\fink_treat_vs_control_coefplot.png", as(png) replace
graph export "D:\NK\Output (graphs and tables)\meetings\net_emp\fink_treat_vs_control_coefplot.png", as(png) replace

reg dispink treat##ib5.diff_reg i.size##i.year,r absorb(dnr2015227)
coefplot, drop(_cons) keep(1.treat#*) yline(6) xline(0) omitted baselevels
*graph export "D:\NK\Output (graphs and tables)\meetings\dispink_treat_vs_control_coefplot.png", as(png) replace
graph export "D:\NK\Output (graphs and tables)\meetings\net_emp\dispink_treat_vs_control_coefplot.png", as(png) replace

*bysort diff treat: egen frac_unemp=mean(unemp)
*bysort diff treat: egen mean_loneink=mean(loneink)
*bysort diff treat: egen mean_fink=mean(fink) if fink>0
*bysort diff treat: egen mean_disp=mean(dispink)
*bysort diff treat: egen mean_akassa=mean(akassa)

*twoway (scatter frac_unemp diff if treat==0, mcolor("blue")) (scatter frac_unemp diff if treat==1,  mcolor("red")), legend(label(1 "Control") label(2 "Treatment"))
*graph export "D:\NK\Output (graphs and tables)\meetings\frac_unemp_treat_vs_control.png", as(png) replace
*twoway (scatter mean_loneink diff if treat==0, mcolor("blue")) (scatter mean_loneink diff if treat==1,  mcolor("red")),  legend(label(1 "Control") label(2 "Treatment"))
*graph export "D:\NK\Output (graphs and tables)\meetings\loneink_treat_vs_control.png", as(png) replace

*twoway (scatter mean_fink diff if treat==0, mcolor("blue")) (scatter mean_fink diff if treat==1,  mcolor("red")),  legend(label(1 "Control") label(2 "Treatment"))
*graph export "D:\NK\Output (graphs and tables)\meetings\fink_treat_vs_control.png", as(png) replace


*twoway (scatter mean_disp diff if treat==0 & ind==1, mcolor("blue")) (scatter mean_disp diff if treat==1 & ind==1,  mcolor("red")),  legend(label(1 "Control") label(2 "Treatment"))
*graph export "D:\NK\Output (graphs and tables)\meetings\disp_treat_vs_control.png", as(png) replace

*twoway (scatter mean_akassa diff if treat==0 & ind==1, mcolor("blue")) (scatter mean_akassa diff if treat==1 & ind==1,  mcolor("red")),  legend(label(1 "Control") label(2 "Treatment"))
*graph export "D:\NK\Output (graphs and tables)\meetings\akassa_treat_vs_control.png", as(png) replace


