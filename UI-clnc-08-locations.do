** Reading AST files and merging them into a single data file

* Adding year variable to each data file:
local files : dir "D:\NK\Input (stuff you generate)\original_inc" files "*.dta"

foreach file in `files' {
    cd "D:\NK\Input (stuff you generate)\original_inc"
	insheet using `file', comma clear
	use `file', replace
	local i =substr("`file'",-8,4)
	gen year=`i'
	destring year kon fodar, replace
	keep dnr2015227 lan kommun forsamling year
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

sort dnr year

bysort dnr year: drop if _n==1 & _N>1 & year==1985

save "D:\NK\Input (stuff you generate)\initial\locations.dta", replace
