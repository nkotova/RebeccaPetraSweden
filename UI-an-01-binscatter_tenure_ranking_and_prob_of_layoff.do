*Manually chosen bins:

use "D:\NK\Input (stuff you generate)\unemp_emp_data.dta"

gen layoff=0
replace layoff=1 if tot_emp>50 & frac_fired>0.15 & frac_left<0.6

keep if layoff==1 & hired==0

gen dist_thres_left=(quant-frac_left)/frac_left if (quant-frac_left<=0)
replace dist_thres_left=(quant-frac_left)/(1-frac_left) if (quant-frac_left>=0)

gen on_thres_left=0 
replace on_thres_left=1 if quant>frac_left & quant_lower<frac_left


egen bins = cut(dist_thres_left), at(-1.01,-.8,-.6,-.4,-.2,0.00001,.2,.4,.6,.8,1.01) icodes
replace bins=bins+1

binscatter fired dist_thres if on_thres==0, rd(0) xq(bins) 
graph export "D:\NK\Output (graphs and tables)\meetings\fired_dist_thres.png", as(png) replace
binscatter fired dist_thres if on_thres==0, rd(0) xq(bins) absorb(firm)
graph export "D:\NK\Output (graphs and tables)\meetings\fired_dist_thres_firm_FE.png", as(png) replace
binscatter left dist_thres_left if on_thres_left==0, rd(0) absorb(firm)
graph export "D:\NK\Output (graphs and tables)\meetings\left_dist_thres_firm_FE.png", as(png) replace







binscatter fired dist_thres if layoff==1 & hired==0, rd(0) xq(bins)
graph export "D:\NK\Output (graphs and tables)\meetings\fired_dist_thres.png", as(png) replace
binscatter fired dist_thres_year if layoff==1 & hired==0, rd(0)
graph export "D:\NK\Output (graphs and tables)\meetings\fired_dist_year.png" , as(png) replace
binscatter fired dist_thres_unemp if layoff==1 & hired==0, rd(0)
graph export "D:\NK\Output (graphs and tables)\meetings\fired_dist_unemp.png", as(png) replace



*** Last year income

use "D:\NK\Input (stuff you generate)\unemp_emp_data.dta", replace

bysort firm dnr2015227 year: egen earnings_yr=total(tot_earnings)
sort firm dnr2015227 emp_spell year
bysort firm dnr2015227 emp_spell: gen earnings_yr_last=earnings_yr[_n-1]

keep if layoff==1 & hired==0
drop _merge

joinby dnr2015227 year using "D:\NK\Input (stuff you generate)\initial\inc_full.dta", unmatched(master)

save "D:\NK\Input (stuff you generate)\intermediate\unemp_emp_educ_age_gender_small.dta", replace

gen age=year-fodar

drop bins bins_unemp
egen bins = cut(dist_thres), at(-1.01,-.9,-.8,-.7,-.6,-.5,-.4,-.3,-.2,-.1,0.00001,0.1,.2,.3,.4,.5,.6,.7,.8,.9,1.01) icodes
egen bins_unemp = cut(dist_thres_unemp), at(-1.01,-.9,-.8,-.7,-.6,-.5,-.4,-.3,-.2,-.1,0.00001,0.1,.2,.3,.4,.5,.6,.7,.8,.9,1.01) icodes
replace bins_unemp=bins_unemp+1
replace bins=bins+1

binscatter kon dist_thres_unemp if layoff==1 & hired==0, rd(0) xq(bins_unemp)
graph export "D:\NK\Output (graphs and tables)\meetings\gender_dist_thres_unemp.png", as(png) replace
binscatter kon dist_thres if layoff==1 & hired==0, rd(0) xq(bins)
graph export "D:\NK\Output (graphs and tables)\meetings\gender_dist_thres.png", as(png) replace

binscatter age dist_thres_unemp if layoff==1 & hired==0, rd(0)  xq(bins_unemp)
graph export "D:\NK\Output (graphs and tables)\meetings\age_dist_thres_unemp.png", as(png) replace
binscatter age dist_thres if layoff==1 & hired==0, rd(0)  xq(bins)
graph export "D:\NK\Output (graphs and tables)\meetings\age_dist_thres.png", as(png) replace

binscatter earnings_yr_last dist_thres_unemp if layoff==1 & hired==0, rd(0) xq(bins_unemp)
graph export "D:\NK\Output (graphs and tables)\meetings\income_dist_thres_unemp.png", as(png) replace
binscatter earnings_yr_last dist_thres if layoff==1 & hired==0, rd(0) xq(bins)
graph export "D:\NK\Output (graphs and tables)\meetings\income_dist_thres.png", as(png) replace

binscatter fired dist_thres_unemp if layoff==1 & hired==0, rd(0)  xq(bins_unemp)
graph export "D:\NK\Output (graphs and tables)\meetings\fired_dist_thres_unemp.png", as(png) replace
binscatter fired dist_thres if layoff==1 & hired==0, rd(0) xq(bins)
graph export "D:\NK\Output (graphs and tables)\meetings\fired_dist_thres.png", as(png) replace
