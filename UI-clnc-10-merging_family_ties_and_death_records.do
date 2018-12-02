*There are people with incorrect death recordings: 
*use "D:\NK\Input (stuff you generate)\initial\death_records.dta", clear
*bysort dnr: gen check=_N
*browse if check>1
*count if check>1

*use "D:\NK\Input (stuff you generate)\initial\death_records_6107.dta", clear
*rename dnr mom_id 
*rename fodar birthyear_mom
*save "D:\NK\Input (stuff you generate)\temp\death_records_mom_6107.dta", replace

*use "D:\NK\Input (stuff you generate)\initial\death_records_6107.dta", clear
*rename dnr dad_id 
*rename fodar birthyear_dad
*save "D:\NK\Input (stuff you generate)\temp\death_records_dad_6107.dta", replace

*use "D:\NK\Input (stuff you generate)\initial\death_records_0814.dta", clear
*rename dnr mom_id 
*drop fodar
*save "D:\NK\Input (stuff you generate)\temp\death_records_mom_0814.dta", replace

*use "D:\NK\Input (stuff you generate)\initial\death_records_0814.dta", clear
*rename dnr dad_id 
*drop fodar
*save "D:\NK\Input (stuff you generate)\temp\death_records_dad_0814.dta", replace

use "D:\NK\Input (stuff you generate)\initial\death_records.dta", clear
rename dnr mom_id 
drop fodar
save "D:\NK\Input (stuff you generate)\temp\death_records_mom.dta", replace

use "D:\NK\Input (stuff you generate)\initial\death_records.dta", clear
rename dnr dad_id 
drop fodar
save "D:\NK\Input (stuff you generate)\temp\death_records_dad.dta", replace


use "D:\NK\Input (stuff you generate)\original_other\family_ties4", clear

order dnr2015227 gender birthyear birthmonth country_child mom_id birthyear_mom country_mom parity_mom completed_fert_mom dad_id birthyear_dad country_dad parity_dad completed_fert_dad

destring birthyear_mom, replace

merge m:1 mom_id using "D:\NK\Input (stuff you generate)\temp\death_records_mom.dta"
drop _merge
rename dodar mom_dodar 

merge m:1 dad_id using "D:\NK\Input (stuff you generate)\temp\death_records_dad.dta"
drop _merge
rename dodar dad_dodar
