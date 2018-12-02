sysdir set PLUS "D:\NK"

use "D:\NK\Input (stuff you generate)\initial\inc_clean.dta", clear

egen long id=group(dnr)
tsset id year
tsfill 

gen check=(dnr=="")
bysort id (check): replace dnr=dnr[_n-1] if check==1

bysort dnr (year): gen loneink_L2=loneink[_n-2]
bysort dnr (year): gen loneink_L1=loneink[_n-1]
bysort dnr (year): gen loneink_F1=loneink[_n+1]
bysort dnr (year): gen loneink_F2=loneink[_n+2]

bysort dnr (year): gen akassa_L2=akassa[_n-2]
bysort dnr (year): gen akassa_L1=akassa[_n-1]
bysort dnr (year): gen akassa_F1=akassa[_n+1]
bysort dnr (year): gen akassa_F2=akassa[_n+2]

bysort dnr (year): gen fink_L2=fink[_n-2]
bysort dnr (year): gen fink_L1=fink[_n-1]
bysort dnr (year): gen fink_F1=fink[_n+1]
bysort dnr (year): gen fink_F2=fink[_n+2]

save "D:\NK\Input (stuff you generate)\intermediate\inc_L_and_F.dta", replace

***RERUN THIS LATER

use "D:\NK\Input (stuff you generate)\Insper2014_clean.dta"
drop month

bysort dnr2015227 year: drop if _n!=1

gen unemp=1
egen long id=group(dnr)
tsset id year
tsfill, full

gen check=(dnr=="")
bysort id (check): replace dnr=dnr[_n-1] if check==1

replace unemp=0 if unemp==.

bysort dnr (year): gen unemp_L2=unemp[_n-2]
bysort dnr (year): gen unemp_L1=unemp[_n-1]
bysort dnr (year): gen unemp_F1=unemp[_n+1]
bysort dnr (year): gen unemp_F2=unemp[_n+2]

rename year_start year


save "D:\NK\Input (stuff you generate)\intermediate\Insper2014_L_and_F.dta", replace



use "D:\NK\Input (stuff you generate)\unemp_emp_data.dta", clear

keep if hired==0

drop _merge

merge m:1 dnr2015227 year using "D:\NK\Input (stuff you generate)\intermediate\inc_L_and_F.dta", keep(match master)
drop _merge

merge m:1 dnr2015227 year using "D:\NK\Input (stuff you generate)\intermediate\Insper2014_L_and_F.dta", keep(match master)
drop _merge

replace unemp=0 if unemp==.
replace unemp_L2=0 if unemp_L2==.
replace unemp_L1=0 if unemp_L1==.
replace unemp_F1=0 if unemp_F1==.
replace unemp_F2=0 if unemp_F2==.


merge m:1 dnr2015227 year using "D:\NK\Input (stuff you generate)\education.dta", keep(match master)
drop _merge

bysort firm year (loneink_L1): gen income_quant5=floor((_n-1)*5/_N)
bysort firm year (loneink_L1): gen income_quant10=floor((_n-1)*10/_N)
bysort firm year (loneink_L1): gen income_quant15=floor((_n-1)*15/_N)
bysort year (loneink_L1): gen income_pop_quant20=floor((_n-1)*20/_N)

save "D:\NK\Input (stuff you generate)\temp\unemp_emp_data_with_ink_educ.dta", replace


use "D:\NK\Input (stuff you generate)\temp\unemp_emp_data_with_ink_educ.dta", replace

*bysort firm dnr emp_spell (year): gen year_hired=year[1]

*Define layoff and threshold:
gen layoff=0


*Different layoff options:

*replace layoff=1 if net_emp_frac<-0.15 & net_emp_frac>-0.45 & frac_hired<0.02 & tot_emp>50 & tot_emp<3500 & frac_left<0.95
*replace layoff=1 if net_emp_frac<-0.15 & frac_hired<0.02 & tot_emp>50 & tot_emp<3500 & frac_left<0.95
replace layoff=1 if net_emp_frac<-0.10 & frac_hired<0.05 & tot_emp>50 & tot_emp<3500 & frac_left<0.95
*replace layoff=1 if net_emp_frac<-0.10 & fired_to_left>0.2 & frac_hired<0.03 & tot_emp>50 & tot_emp<3500 & frac_left<0.95
*replace layoff=1 if net_emp_frac<-0.10 & fired_to_left>0.2 & frac_hired<0.03 & tot_emp>150 & tot_emp<3500 & frac_left<0.95

drop if layoff==0

egen firmyear=group(firm year)


*reghdfe left i.income_pop_quant20, absorb(firmyear) vce(cluster firmyear)

*coefplot, vertical drop(_cons) keep(*income_pop_quant20) yline(0) omitted baselevels

*reghdfe left i.income_quant15, absorb(firmyear) vce(cluster firmyear)
*coefplot, vertical drop(_cons) keep(*income_quant15) yline(0) omitted baselevels
*graph export "D:\NK\Output (graphs and tables)\meetings\income_left_15.png", as(png) replace

*reghdfe left i.income_quant10, absorb(firmyear) vce(cluster firmyear)
*coefplot, vertical drop(_cons) keep(*income_quant10) yline(0) omitted baselevels
*graph export "D:\NK\Output (graphs and tables)\meetings\income_left_10.png", as(png) replace

*reghdfe left i.income_quant5, absorb(firmyear) vce(cluster firmyear)
*coefplot, vertical drop(_cons) keep(*income_quant5) yline(0) omitted baselevels
*graph export "D:\NK\Output (graphs and tables)\meetings\income_left_5.png", as(png) replace

*reghdfe left i.educ, absorb(firmyear) vce(cluster firmyear)
*coefplot, vertical drop(_cons) keep(*educ) yline(0) omitted baselevels
*graph export "D:\NK\Output (graphs and tables)\meetings\educ_left.png", as(png) replace


*Calculating the firing threshold:
gen thres=-net_emp_frac
gen below_thres=(quant-thres<=0)


*egen firmyear=group(firm year)
bysort firm year: egen tot_below_thres=total(below_thres)


**NORMALIZED DESIGN
*Generating distances to the firing threshold:
gen dist_thres=(quant-thres)/thres if below_thres==1
replace dist_thres=(quant-thres)/(1-thres) if below_thres==0

gen quant_lower=(rank-1)/(tot_emp-tot_hired)
gen on_thres=0
replace on_thres=1 if quant>thres & quant_lower<thres
gen thres_quant=quant if on_thres==1
bysort firm year (thres_quant): replace  thres_quant=thres_quant[_n-1] if _n>1
replace thres_quant=max(thres_quant,thres)
gen thres_diff=thres_quant-thres

gen dist_quant=(quant-thres)/thres if below_thres==1 
replace dist_quant=(quant-thres_quant)/(1-thres_quant) if below_thres==0 & on_thres==0

gen above_thres=(quant>thres_quant)
bysort firm year: egen tot_above_thres=total(above_thres)


gen age=year-fodar

bysort firm year below_thres quant: gen rand=uniform()
*bysort firm year below_thres (quant age): gen position_below=_n
*bysort firm year above_thres (quant age): gen position_above=_N-_n+1
bysort firm year below_thres (quant rand): gen position_below=_n
bysort firm year above_thres (quant rand): gen position_above=_N-_n+1

*gen age=year-fodar

*bysort firm year below_thres (position): egen bin1=cut(position), group(5)

*bysort firm year below_thres: gen bin=ceil(float(position_below*6/_N))
*bysort firm year above_thres: gen bin_above=ceil(float(position_above*10/_N))  
*replace bin=bin_above if above_thres==1
*replace bin=bin+6 if above_thres==1
*replace bin=23-bin if above_thres==1
*replace bin=. if on_thres==1


*Maybe should also exclude on_thres people from the analysis. CHECKCHECKCHECK



bysort firm year below_thres (quant rand): gen position_b=_N-_n
bysort firm year above_thres (quant rand): gen position_a=_n-1

gen bin=floor(float(position_a*15/tot_above))+6 if above_thres==1
replace bin=5-floor(float(position_b*6/tot_below)) if below_thres==1


gen bin20=floor(float(position_a/4))+5 if above_thres==1
replace bin20=4-floor(float(position_b/4)) if below_thres==1

*gen bin20=floor(position/4)+5 if below_thres==0
*replace bin20=4-floor(position_inverse/4) if below_thres==1

gen bin25=floor(position_a/5)+5 if above_thres==1
replace bin25=4-floor(position_b/5) if below_thres==1

*gen bin30=floor(position/6)+5 if below_thres==0
*replace bin30=4-floor(position_inverse/6) if below_thres==1

*gen bin40=floor(position/8)+5 if below_thres==0
*replace bin40=4-floor(position_inverse/8) if below_thres==1

gen bin40=floor(position_a/8)+5 if above_thres==1
replace bin40=4-floor(position_b/8) if below_thres==1

gen insample20=(tot_below_thres>20 & tot_above_thres>20 & ((position_b<20 & below_thres==1) | (position_a<20 & above_thres==1))) & on_thres==0
replace bin20=100 if insample20==0

gen insample25=(tot_below_thres>25 & tot_above_thres>25 & ((position_b<25 & below_thres==1) | (position_a<25 & above_thres==1))) & on_thres==0
replace bin25=100 if insample25==0

*gen insample30=(tot_below_thres>30 & tot_above_thres>30 & ((position_inverse<30 & below_thres==1) | (position<30 & below_thres==0)))
*replace bin30=100 if insample30==0

*gen insample40=(tot_below_thres>40 & tot_above_thres>40 & ((position_inverse<40 & below_thres==1) | (position<40 & below_thres==0)))
*replace bin40=100 if insample40==0

gen insample40=(tot_below_thres>40 & tot_above_thres>40 & ((position_b<40 & below_thres==1) | (position_a<40 & above_thres==1))) & on_thres==0
replace bin40=100 if insample40==0

gen balanced_loneink=0
replace balanced_loneink=1 if loneink_L2!=. & loneink_L1!=. & loneink_F1!=. & loneink_F2!=.

gen balanced_akassa=0
replace balanced_akassa=1 if akassa_L2!=. & akassa_L1!=. & akassa_F1!=. & akassa_F2!=.

gen balanced_fink=0
replace balanced_fink=1 if fink_L2!=. & fink_L1!=. & fink_F1!=. & fink_F2!=.

bysort firm year: gen firmyear_tag=(_n==1)

save "D:\NK\Input (stuff you generate)\temp\tenure_graphs_data.dta", replace

use "D:\NK\Input (stuff you generate)\temp\tenure_graphs_data.dta"

*****Normalized Design*****


reghdfe age ib5.bin if thres_diff<0.1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin) xline(6.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\fodar_dist_thres_FE.png", as(png) replace

reghdfe kon ib5.bin, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin) xline(6.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\kon_dist_thres_FE.png", as(png) replace


reghdfe left ib5.bin, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin) xline(6.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\left_dist_thres_FE.png", as(png) replace

reghdfe left ib5.bin, noabsorb vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin) xline(6.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\left_dist_thres.png", as(png) replace

reghdfe unemp ib5.bin if thres_diff==0, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin) xline(6.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\unemp_dist_thres_FE.png", as(png) replace


reghdfe loneink_F1 ib5.bin if balanced_loneink==1 & thres_quant<1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin) xline(6.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_F1_dist_thres_FE.png", as(png) replace

reghdfe loneink_F2 ib5.bin if balanced_loneink==1 & thres_quant<1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin) xline(6.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_F2_dist_thres_FE.png", as(png) replace

reghdfe loneink ib5.bin if balanced_loneink==1 & thres_quant<1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin) xline(6.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_0_dist_thres_FE.png", as(png) replace

reghdfe loneink_L1 ib5.bin if balanced_loneink==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin) xline(6.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_L1_dist_thres_FE.png", as(png) replace

reghdfe loneink_L2 ib5.bin if balanced_loneink==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin) xline(6.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_L2_dist_thres_FE.png", as(png) replace

reghdfe akassa_F1 ib5.bin if balanced_akassa==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin) xline(6.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\akassa_F1_dist_thres_FE.png", as(png) replace

reghdfe akassa_F2 ib5.bin if balanced_akassa==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin) xline(6.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\akassa_F2_dist_thres_FE.png", as(png) replace

reghdfe akassa_L1 ib5.bin if balanced_akassa==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin) xline(6.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\akassa_L1_dist_thres_FE.png", as(png) replace

reghdfe akassa_L2 ib5.bin if balanced_akassa==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin) xline(6.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\akassa_L2_dist_thres_FE.png", as(png) replace

reghdfe fink_F1 ib5.bin if fink>0 & balanced_fink==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin) xline(6.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\fink_F1_dist_thres_FE.png", as(png) replace

reghdfe fink_F2 ib5.bin if fink>0 & balanced_fink==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin) xline(6.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\fink_F2_dist_thres_FE.png", as(png) replace

reghdfe fink_L1 ib5.bin if fink>0 & balanced_fink==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin) xline(6.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\fink_L1_dist_thres_FE.png", as(png) replace

reghdfe fink_L2 ib5.bin if fink>0 & balanced_fink==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin) xline(6.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\fink_L2_dist_thres_FE.png", as(png) replace


reghdfe age ib5.bin, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin) xline(6.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\fodar_dist_thres_FE.png", as(png) replace

reghdfe kon ib5.bin, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin) xline(6.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\kon_dist_thres_FE.png", as(png) replace


*****Fixed number of workers Design*****

reghdfe left i.bin20 if insample20==1, noabsorb vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin20) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\left_20_workers.png", as(png) replace
reghdfe left i.bin20 if insample20==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin20) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\left_20_workers_FE.png", as(png) replace

reghdfe left i.bin25 if insample25==1, noabsorb vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin25) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\left_25_workers.png", as(png) replace
reghdfe left i.bin25 if insample25==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin25) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\left_25_workers_FE.png", as(png) replace

reghdfe left i.bin30 if insample30==1, noabsorb vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin30) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\left_30_workers.png", as(png) replace
reghdfe left i.bin30 if insample30==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin30) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\left_30_workers_FE.png", as(png) replace

reghdfe left i.bin40 if insample40==1, noabsorb vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin40) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\left_40_workers.png", as(png) replace
reghdfe left i.bin40 if insample40==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin40) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\left_40_workers_FE.png", as(png) replace


reghdfe loneink_L2 i.bin25 if insample25==1 & balanced_loneink==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin25) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_L2_25_workers_FE.png", as(png) replace

reghdfe loneink_L1 i.bin25 if insample25==1 & balanced_loneink==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin25) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_L1_25_workers_FE.png", as(png) replace


reghdfe loneink_F1 i.bin25 if insample25==1 & balanced_loneink==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin25) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_F1_25_workers_FE.png", as(png) replace

reghdfe loneink_F2 i.bin25 if insample25==1 & balanced_loneink==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin25) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_F2_25_workers_FE.png", as(png) replace


reghdfe akassa_F1 i.bin25 if insample25==1 & balanced_akassa==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin25) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\akassa_F1_25_FE.png", as(png) replace

reghdfe akassa_F2 i.bin25 if insample25==1 & balanced_akassa==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin25) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\akassa_F2_25_FE.png", as(png) replace

reghdfe akassa_L1 i.bin25 if insample25==1 & balanced_akassa==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin25) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\akassa_L1_25_FE.png", as(png) replace

reghdfe akassa_L2 i.bin25 if insample25==1 & balanced_akassa==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin25) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\akassa_L2_25_FE.png", as(png) replace







reghdfe loneink_L2 i.bin40 if insample40==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin40) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_L2_40_workers_FE.png", as(png) replace

reghdfe loneink_L1 i.bin40 if insample40==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin40) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_L1_40_workers_FE.png", as(png) replace


reghdfe loneink_F1 i.bin40 if insample40==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin40) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_F1_40_workers_FE.png", as(png) replace

reghdfe loneink_F2 i.bin40 if insample40==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin40) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_F2_40_workers_FE.png", as(png) replace





reghdfe loneink_L2 i.bin30 if insample30==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin30) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_L2_30_workers_FE.png", as(png) replace

reghdfe loneink_L1 i.bin30 if insample30==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin30) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_L1_30_workers_FE.png", as(png) replace


reghdfe loneink_F1 i.bin30 if insample30==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin30) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_F1_30_workers_FE.png", as(png) replace

reghdfe loneink_F2 i.bin30 if insample30==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin30) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\loneink_F2_30_workers_FE.png", as(png) replace



reghdfe age i.bin20 if insample20==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin20) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\fodar_20_workers_FE.png", as(png) replace

reghdfe age i.bin25 if insample25==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin25) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\fodar_25_workers_FE.png", as(png) replace

reghdfe age i.bin30 if insample30==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin30) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\fodar_30_workers_FE.png", as(png) replace

reghdfe age i.bin40 if insample40==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin40) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\fodar_40_workers_FE.png", as(png) replace


reghdfe kon i.bin20 if insample20==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin20) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\kon_20_workers_FE.png", as(png) replace

reghdfe kon i.bin25 if insample25==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin25) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\kon_25_workers_FE.png", as(png) replace

reghdfe kon i.bin30 if insample30==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin30) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\kon_30_workers_FE.png", as(png) replace

reghdfe kon i.bin40 if insample40==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin40) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\kon_40_workers_FE.png", as(png) replace






reghdfe left i.bin30 if insample30==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin30) xline(6.5) yline(0) omitted baselevels

reghdfe left i.bin30 if insample40==1, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin30) xline(6.5) yline(0) omitted baselevels


egen bin=xtile(dist_thres) if below_thres==1, nquantiles(5)
egen bin1=xtile(dist_thres) if below_thres==0, nquantiles(15)

replace bin=bin1+7 if below_thres==0
drop bin1


reghdfe left i.bin if on_thres==0, absorb(firmyear) vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\4_left_FE_layoff.png", as(png) replace

reghdfe left ib5.bin, noabsorb vce(cluster firmyear)
coefplot, vertical drop(_cons) keep(*bin) xline(5.5) yline(0) omitted baselevels
graph export "D:\NK\Output (graphs and tables)\meetings\4_left_layoff.png", as(png) replace


