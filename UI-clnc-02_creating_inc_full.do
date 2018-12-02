** Reading AST files and merging them into a single data file

* Adding year variable to each data file:
local files : dir "D:\NK\Input (stuff you generate)\original_inc" files "*.dta"

foreach file in `files' {
    cd "D:\NK\Input (stuff you generate)\original_inc"
	insheet using `file', comma clear
	use `file', replace
	local i =substr("`file'",-8,4)
	gen year=`i'
	destring year kon fodar loneink, replace
	cd "D:\NK\Input (stuff you generate)\original_inc\temp"
	save `file',replace
}

*destring year kon fodar loneink, replace
*keep dnr2015227 kon fodar loneink

cd "D:\NK\Input (stuff you generate)\original_inc\temp"

* Appending files to "ast_1985". Note that all obs for 1985 will appear twice:
use "inc1985", replace

foreach file in `files' {
	append using `file', force
}

save "D:\NK\Input (stuff you generate)\initial\inc_data_full", replace

use "D:\NK\Input (stuff you generate)\initial\inc_data_full"

keep dnr2015227 year kon fodar loneink fink inkfnetto akassa dispink

gen fink2=fink
replace fink2= max(inkfnetto,0) if missing(fink)
drop fink inkfnetto
rename fink2 fink

* Sorting data:
bysort dnr2015227 year: drop if _n!=1
bysort dnr2015227 (kon): replace kon=kon[_n-1] if missing(kon)
bysort dnr2015227 (fodar): replace fodar=fodar[_n-1] if missing(fodar)

replace loneink=loneink/100 if year<1990
replace fink=fink/100 if year<1990


cd "D:\NK\Input (stuff you generate)\initial"
save "inc_clean.dta", replace
