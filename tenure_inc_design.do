sysdir set PLUS "D:\NK"
use "D:\NK\Input (stuff you generate)\temp\unemp_emp_data_with_ink_educ.dta", replace

****NORMALIZED INCOME DESIGN********

bysort firm year income_quant5: gen tot_emp_inc = _N
bysort firm year income_quant5: egen tot_layoff_inc = total(fired)
bysort firm year income_quant5: egen tot_left_inc = total(left)
bysort firm year income_quant5: egen tot_hired_inc = total(hired)

gen net_emp_inc=tot_hired_inc-tot_left_inc
gen net_emp_frac_inc=net_emp_inc/tot_emp_inc
gen frac_hired_inc=tot_hired_inc/tot_emp_inc

gen frac_fired_inc=max(0,(tot_layoff_inc-tot_hired_inc)/(tot_emp_inc-tot_hired_inc)) 
gen frac_left_inc=max(0,(tot_left_inc-tot_hired_inc)/(tot_emp_inc-tot_hired_inc)) 

*Layoff

gen layoff=0
replace layoff=1 if net_emp_frac_inc<-0.1 & frac_hired_inc<0.05 & tot_emp_inc>30 & tot_emp_inc<3500 & frac_left_inc<0.95
drop if layoff==0

*Generating ranking of workers based on their experience:
bysort firm year income_quant5 hired: egen rank_inc=rank(adj_tenure), track
replace rank_inc=0 if hired==1

bysort firm year rank_inc: gen n_same_inc=_N

*Generating quantiles:
gen quant_inc=(rank_inc-1+n_same_inc)/(tot_emp_inc-tot_hired_inc)
replace quant_inc=0 if hired==1

*Calculating the firing threshold:
gen thres_inc=-net_emp_frac_inc
gen below_thres_inc=(quant_inc-thres_inc<=0)

*egen firmyear=group(firm year)
bysort firm year income_quant5: egen tot_below_thres_inc=total(below_thres_inc)
gen tot_above_thres=tot_emp-tot_below_thres

*Generating distances to the firing threshold:
gen dist_thres_inc=(quant_inc-thres_inc)/thres_inc if below_thres_inc==1
replace dist_thres_inc=(quant_inc-thres_inc)/(1-thres_inc) if below_thres_inc==0

gen quant_lower_inc=(rank_inc-1)/(tot_emp_inc-tot_hired_inc)
gen on_thres_inc=0
replace on_thres_inc=1 if quant_inc>thres_inc & quant_lower_inc<thres_inc


egen bin_inc=xtile(dist_thres_inc) if below_thres_inc==1, nquantiles(5)
egen bin1_inc=xtile(dist_thres_inc) if below_thres_inc==0, nquantiles(5)

replace bin_inc=bin1_inc+5 if below_thres_inc==0
drop bin1_inc


egen firmyearinc=group(firm year income_quant5)
gen age=year-fodar

save "D:\NK\Input (stuff you generate)\temp\unemp_emp_data_tenure_inc_design.dta", replace
use "D:\NK\Input (stuff you generate)\temp\unemp_emp_data_tenure_inc_design.dta"

reghdfe left ib5.bin_inc, absorb(firmyearinc) vce(cluster firmyearinc)
coefplot, vertical drop(_cons) keep(*bin_inc) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\left_dist_thres_FE.png", as(png) replace

reghdfe left ib5.bin_inc, noabsorb vce(cluster firmyearinc)
graph export "D:\NK\Output (graphs and tables)\meetings\left_dist_thres.png", as(png) replace

reghdfe loneink_F1 ib5.bin_inc, absorb(firmyearinc) vce(cluster firmyearinc)
coefplot, vertical drop(_cons) keep(*bin) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_F1_dist_thres_FE.png", as(png) replace

reghdfe loneink_F2 ib5.bin_inc, absorb(firmyearinc) vce(cluster firmyearinc)
coefplot, vertical drop(_cons) keep(*bin) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_F2_dist_thres_FE.png", as(png) replace

reghdfe loneink_L1 ib5.bin_inc, absorb(firmyearinc) vce(cluster firmyearinc)
coefplot, vertical drop(_cons) keep(*bin) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_L1_dist_thres_FE.png", as(png) replace

reghdfe loneink_L2 ib5.bin_inc, absorb(firmyearinc) vce(cluster firmyearinc)
coefplot, vertical drop(_cons) keep(*bin_inc) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_L2_dist_thres_FE.png", as(png) replace

reghdfe age ib5.bin_inc, absorb(firmyearinc) vce(cluster firmyearinc)
coefplot, vertical drop(_cons) keep(*bin) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\fodar_dist_thres_FE.png", as(png) replace

reghdfe kon ib5.bin_inc, absorb(firmyearinc) vce(cluster firmyearinc)
coefplot, vertical drop(_cons) keep(*bin_inc) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\kon_dist_thres_FE.png", as(png) replace

