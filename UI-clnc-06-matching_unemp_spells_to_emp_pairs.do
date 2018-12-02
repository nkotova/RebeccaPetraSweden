use "D:\NK\Input (stuff you generate)\intermediate\joinby_both.dta"

destring month_start, replace 
*gen month_start=month
*gen year_start=year

*Generating difference between unemp start date and emp start date:
gen diff_start=12*year_start+month_start-emp_start
*Drop if started later than unemp spell began:
drop if diff_start<0

*gen abs_diff=abs(diff)


*Generating tag for min abs_difference:
*sort dnr2015227 year_start month_start abs_diff
*gen tag=0
*bysort dnr2015227 year_start month_start: egen min_abs_diff=min(abs_diff)
*bysort dnr2015227 year_start month_start: replace tag=1 if abs_diff==min_abs_diff

*hist diff if tag==1
*graph export "D:\NK\Output (graphs and tables)\meetings\hist_diff_0.png", as(png) replace

*hist abs_diff if tag==1
*graph export "D:\NK\Output (graphs and tables)\meetings\hist_abs_diff_0.png", as(png) replace

*Generating which_year variable that is 0 if a person left his job the same year 
*as unemp. spell began, -1 if he left last year, 1 if he left the year after. 
*I am going to delete all obs. where a person left his job more than 2 years ago or after.

gen which_year=9
replace which_year=0 if year_start==year
replace which_year=1 if year_start==year+1
*replace which_year=1 if year_start==year-1

drop if which_year==9


*Calculating the number of links:

bysort dnr2015227 year_start month_start (which_year): gen number_links=_N
bysort dnr2015227 year_start month_start which_year: gen number_links_year=_N

*gen number_links_minus=0
gen number_links_plus=0
gen number_links_0=0
*sort dnr2015227 year_start month_start which_year
bysort dnr2015227 year_start month_start (which_year): replace number_links_plus=number_links_year[_N] if which_year[_N]==1
*bysort dnr2015227 year_start month_start (which_year): replace number_links_minus=number_links_year[1] if which_year[1]==-1
bysort dnr2015227 year_start month_start (which_year): replace number_links_0=number_links_year[1] if which_year[1]==0

*Indicator for the closest positive difference:
*sort dnr2015227 year_start month_start abs_diff
*gen diff_plus=0
*replace diff_plus=diff if diff>0 | diff==0
*replace diff_plus=9999 if diff<0
*gen tag_plus=0
*bysort dnr2015227 year_start month_start: egen min_pos_diff=min(diff_plus)
*bysort dnr2015227 year_start month_start: replace tag_plus=1 if diff_plus==min_pos_diff


*Generating difference between unemp start date and last month of work:
gen diff=12*(year_start-year)+(month_start-mantill)

*Linkability criteria:

gen linkable=0
replace linkable=1 if which_year==0 & number_links_0==1
replace linkable=1 if which_year==1 & number_links_0==0 & number_links_plus==1 & diff<13
*replace linkable=1 if tag==1 & which_year==1 & number_links_0==0 & number_links_plus==1 & diff>-3

save "D:\NK\Input (stuff you generate)\temp\linkable_unemp_spells.dta", replace

*Cleaning the dataset to leave only linkable unemp. spells.

keep if linkable==1

bysort pairid year emp_spell: gen check=_N
drop if check>1
gen fired=1

keep pairid year year_start month_start emp_spell fired
save "D:\NK\Input (stuff you generate)\intermediate\linkable_for_merging.dta", replace

use "D:\NK\Input (stuff you generate)\ast_panel_clean.dta"
merge 1:1 pairid year emp_spell using "D:\NK\Input (stuff you generate)\intermediate\linkable_for_merging.dta"
save "D:\NK\Input (stuff you generate)\intermediate\ast_merged_with_linkable_for_merging.dta", replace

