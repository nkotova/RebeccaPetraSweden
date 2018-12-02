** Reading AST files and merging them into a single data file

* Adding year variable to each data file:
local files : dir "D:\NK\Input (stuff you generate)\original" files "*.dta"

cd "D:\NK\Input (stuff you generate)\original"
foreach file in `files' {
	insheet using `file', comma clear
	use `file', replace
	local i =substr("`file'",-8,4)
	gen year=`i'
	destring yrkstalln,replace
	save `file',replace
}

* Appending files to "ast_1985". Note that all obs for 1985 will appear twice:
use "ast_1985", replace

foreach file in `files' {
	append using `file'
}
* Sorting data:
destring year,replace
sort dnr2015227 year manfran mantill
	
* Dropping all obs before 1992:
*drop if year<1992

*egen pairid=group(cfarlopnrs dnr2015227)
*sort pairid year manfran mantill

duplicates drop if year==1985
cd "D:\NK\Input (stuff you generate)\initial"
save "ast_panel.dta", replace
