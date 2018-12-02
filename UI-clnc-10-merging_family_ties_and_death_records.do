use "D:\NK\Input (stuff you generate)\initial\death_records.dta", clear
rename dnr mom_id 
drop fodar
save "D:\NK\Input (stuff you generate)\temp\death_records_mom.dta", replace

use "D:\NK\Input (stuff you generate)\initial\death_records.dta", clear
rename dnr dad_id 
drop fodar
save "D:\NK\Input (stuff you generate)\temp\death_records_dad.dta", replace

use "D:\NK\Input (stuff you generate)\initial\locations.dta", clear
rename dnr mom_id 
rename lan mom_county 
keep mom_id mom_county year
save "D:\NK\Input (stuff you generate)\temp\locations_mom.dta", replace

use "D:\NK\Input (stuff you generate)\initial\locations.dta", clear
rename dnr dad_id 
rename lan dad_county 
keep dad_id dad_county year
save "D:\NK\Input (stuff you generate)\temp\locations_dad.dta", replace

use "D:\NK\Input (stuff you generate)\original_other\family_ties4", clear

order dnr2015227 gender birthyear birthmonth country_child mom_id birthyear_mom country_mom parity_mom completed_fert_mom dad_id birthyear_dad country_dad parity_dad completed_fert_dad

destring birthyear_mom, replace

merge m:1 mom_id using "D:\NK\Input (stuff you generate)\temp\death_records_mom.dta"
drop _merge
rename dodar mom_dodar 

merge m:1 dad_id using "D:\NK\Input (stuff you generate)\temp\death_records_dad.dta"
drop _merge
rename dodar dad_dodar

drop if missing(dnr)

save "D:\NK\Input (stuff you generate)\initial\family_ties", replace

use "D:\NK\Input (stuff you generate)\initial\locations.dta", clear

drop if missing(dnr)



*    Result                           # of obs.
*    -----------------------------------------
*    not matched                     8,419,141
*        from master                 7,445,476  (_merge==1)
*        from using                    973,665  (_merge==2)
*
*    matched                       168,098,953  (_merge==3)
*    -----------------------------------------



merge m:1 dnr using "D:\NK\Input (stuff you generate)\initial\family_ties", keep(match master)
drop _merge

merge m:1 mom_id year using "D:\NK\Input (stuff you generate)\temp\locations_mom.dta", keep(match master)
drop _merge

merge m:1 dad_id year using "D:\NK\Input (stuff you generate)\temp\locations_dad.dta", keep(match master)
drop _merge

save "D:\NK\Input (stuff you generate)\intermediate\family_and_location.dta", replace

gen loc_mom=(lan==mom_county & !missing(lan))
gen loc_dad=(lan==dad_county & !missing(lan))

*gen mom_alive=(year<mom_dodar & !missing(mom_dodar))
*gen mom_alive=(year<dad_dodar & !missing(dad_dodar))

keep dnr year loc_mom loc_dad

save "D:\NK\Input (stuff you generate)\temp\loc_family_indicator.dta", replace








