sysdir set PLUS "D:\NK"
use "D:\NK\Input (stuff you generate)\unemp_emp_data.dta", clear

*drop dist_thres quant_lower on_thres layoff

***CHECKCHECK SHOULD PUT ALL OF THIS IN THE PREVIOUS DO-FILE AND DELETE DIST_THRES ETC FROM THERE
*gen net_emp=tot_hired-tot_left
*gen net_emp_frac=net_emp/tot_emp
*gen frac_hired=tot_hired/tot_emp
*gen frac_left=tot_left/tot_emp

*Define layoff and threshold:
gen layoff=0
replace layoff=1 if net_emp_frac<-0.15 & net_emp_frac>-0.45 & frac_hired<0.02 & tot_emp>50 & tot_emp<3500 & frac_left<0.95
drop if layoff==0


bysort firm year: gen tag=(_n==1)
bysort year tag: egen size=xtile(tot_emp), nquantiles(10)
sum size
replace size=. if tag!=1
bysort firm year (size): replace size=size[_n-1] if _n!=1


gen thres=-net_emp_frac
gen below_thres=(quant-thres<=0)


*Generating distances to the firing threshold:
gen dist_thres=(quant-thres)/thres if below_thres==1
replace dist_thres=(quant-thres)/(1-thres) if below_thres==0

gen quant_lower=(rank-1)/(tot_emp-tot_hired)
gen on_thres=0
replace on_thres=1 if quant>thres & quant_lower<thres


egen bin=xtile(dist_thres) if below_thres==1, nquantiles(5)
egen bin1=xtile(dist_thres) if below_thres==0, nquantiles(10)

replace bin=bin1+5
drop bin1

egen firmyear=group(firm year)

reghdfe left ib5.bin, absorb(firmyear) vce(cluster firmyear)
reghdfe left ib5.bin, vce(cluster firmyear)
