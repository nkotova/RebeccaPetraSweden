import delimited C:\Users\nkotova\Downloads\LRHUTTTTSEA156S.csv, clear 

gen year=substr(date,-10,4)
destring year, replace
rename lrhuttttsea156s unemprate
save "D:\NK\Input (stuff you generate)\other\unemp_rate.dta", replace


use "D:\NK\Input (stuff you generate)\unemp_emp_data.dta" 
drop _merge

merge m:1 dnr year using "D:\NK\Input (stuff you generate)\initial\inc_clean" 

egen firmyear=group(firm year)

bysort dnr (year): gen first_year=year[1]
gen exp=year-year[1]
gen exp2=exp*exp
gen age=year-fodar
gen age2=age*age

*Wage equation:

areg tot_earnings i.educ i.kon age age2 exp exp2 tenure, absorb(firmyear)
predict wage_resid, residuals

save "D:\NK\Input (stuff you generate)\other\merged_data.dta" 

drop if _merge!=3
bysort dnr: egen person_fe=mean(wage_resid)

bysort year: egen mean_left=mean(person_fe) if left==1
bysort year: egen yearly_hire=total(tot_hired)

bysort year: gen year_ind=_n==1

save "D:\NK\Input (stuff you generate)\other\merged_data_2.dta" 

use "D:\NK\Input (stuff you generate)\other\merged_data_2.dta"

drop _merge

merge m:1 year using "D:\NK\Input (stuff you generate)\other\unemp_rate.dta" 

save "D:\NK\Input (stuff you generate)\other\merged_data_2.dta", replace


gen log_tot_earnings=log(max(tot_earnings,1))

gen tenure2=tenure*tenure
gen quant2=quant*quant

gen year2=year*year
gen year3=year*year*year


areg log_tot_earnings i.educ i.kon age age2 year2 year3 tenure tenure2 hired fired left quant, absorb(firmyear)
predict log_wage_resid, residuals
bysort dnr: egen log_person_fe=mean(log_wage_resid)

gen urate_person_fe=unemprate*log_person_fe

reg left unemprate log_person_fe urate_person_fe, r

save "D:\NK\Input (stuff you generate)\other\merged_data_2.dta", replace

