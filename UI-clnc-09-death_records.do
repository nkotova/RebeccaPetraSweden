use "D:\NK\Input (stuff you generate)\original_other\Dod_6104", clear

gen fodar=substr(fdat,1,4)

destring fodar, replace

keep dnr dodar fodar

save "D:\NK\Input (stuff you generate)\temp\Dod_6104_clean.dta", replace


use "D:\NK\Input (stuff you generate)\original_other\Dod_0507", clear

gen fodar=substr(fdat,1,4)

destring fodar, replace

keep dnr dodar fodar

destring dodar, replace

save "D:\NK\Input (stuff you generate)\temp\Dod_0507_clean.dta", replace


use "D:\NK\Input (stuff you generate)\original_other\Avlidna_0814", clear

gen dodar=substr(doddatum,1,4)

destring dodar, replace

keep dnr dodar

gen fodar=.

save "D:\NK\Input (stuff you generate)\initial\death_records_0814.dta", replace


use "D:\NK\Input (stuff you generate)\temp\Dod_6104_clean.dta", clear

append using "D:\NK\Input (stuff you generate)\temp\Dod_0507_clean.dta"

append using "D:\NK\Input (stuff you generate)\initial\death_records_0814.dta"

sort dodar dnr

use "D:\NK\Input (stuff you generate)\initial\death_records.dta", clear
bysort dnr: gen check=_N
browse if check>1
drop if check>1
drop check

save "D:\NK\Input (stuff you generate)\initial\death_records.dta", replace

