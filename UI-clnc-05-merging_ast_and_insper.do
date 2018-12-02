use "D:\NK\Input (stuff you generate)\ast_panel_clean.dta", clear

* Generating their years of tenure and first/last indicators and emp_start:

*sort pairid emp_spell year

*bysort pairid emp_spell: gen first=_n==1
bysort pairid emp_spell (year): gen last=_n==_N

bysort pairid emp_spell (year): gen emp_start=12*year[1]+manfran[1]

keep if last==1
keep dnr2015227 firm pairid year manfran mantill emp_spell emp_start

save "D:\NK\Input (stuff you generate)\intermediate\ast_panel_clean_only_last.dta", replace

joinby dnr2015227 using "D:\NK\Input (stuff you generate)\Insper2014_clean.dta"
save "D:\NK\Input (stuff you generate)\intermediate\joinby_both.dta", replace

*joinby dnr2015227 using "D:\NK\Input (stuff you generate)\Insper2014_clean.dta", unmatched(both)
*save "D:\NK\Input (stuff you generate)\intermediate\joinby_full.dta",replace
*keep if _merge==1
*save "D:\NK\Input (stuff you generate)\intermediate\joinby_only_master.dta", replace
*use "D:\NK\Input (stuff you generate)\intermediate\joinby_full.dta", clear
*keep if _merge==2
*save "D:\NK\Input (stuff you generate)\intermediate\joinby_only_using.dta", replace
*use "D:\NK\Input (stuff you generate)\intermediate\joinby_full.dta", clear
*keep if _merge==3
*save "D:\NK\Input (stuff you generate)\intermediate\joinby_both.dta", replace

