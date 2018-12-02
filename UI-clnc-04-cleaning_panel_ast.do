use "D:\NK\Input (stuff you generate)\initial\ast_panel.dta" 

*Dropping self-employed
drop if manfran==0 & year>1990
drop if dnr2015227==ftglopnrdnr2015227 & year<1991

replace manfran=1 if year<1991 & manfran==0
replace mantill=12 if year<1991 & mantill==0

*Create pairid:

egen long firm=group(cfarlopnrs ftglopnrdnr2015227)

egen long pairid=group(firm dnr2015227)

drop if pairid==.
*Creating pairid for those that have missing cfarlopnrs or ftglopnrdnr2015227 
*gen tag=0
*replace tag = 1 if pairid==.
*gen num = sum(tag)
*sum pairid
*gen a=r(max)
*replace pairid=a+num if pairid==.

*Dealing with overlapping spells and gaps in employment:

sort dnr2015227 year manfran mantill

*Creating rolling max mantill:
bysort pairid year: generate max= mantill[1] if _n == 1 
bysort pairid year: replace max = max(mantill, max[_n - 1]) if missing(max)
bysort pairid year: generate max2=max[_n-1] if _n>1
bysort pairid year: replace max2=mantill[1] if _n==1

*Identifying gaps in employment within same year:
gen skip=0
replace skip=1 if manfran>max2

*Numbering terms of employment within same year:
bysort pairid year: gen term=sum(skip)

*Calculating total earnings within each term:
bysort pairid year term: egen tot_earnings=total(lonfink)
*Merging overlaping employment spells and dropping extra ones:
bysort pairid year term: replace mantill=max[_N] if _n==1
bysort pairid year term: drop if _n!=1

*Creating employment spells at this particular employer:
sort pairid year manfran mantill

gen gap=0
replace gap=1 if skip==1
replace gap=1 if pairid[_n]==pairid[_n-1] & year[_n]==year[_n-1]+1 & (manfran[_n]!=1 | mantill[_n-1]!=12)
replace gap=1 if pairid[_n]==pairid[_n-1] & year[_n]>year[_n-1]+1
by pairid: gen emp_spell=sum(gap)
replace emp_spell=emp_spell+1


*Calculating average number of jobs per month:

gen length=mantill-manfran+1
bysort dnr2015227 year: egen tot_length=total(length)
gen month_job=tot_length/12


bysort dnr2015227: egen max_month_job=max(month_job)

*drop tag
*bysort dnr2015227: gen tag=_n==1

*hist max_month_job if tag==1


*Flag people who have manfran==1 in 1985
gen before_1985=0
replace before_1985=1 if manfran==1 & year==1985

*Flag people who have max_job>3

gen flag_max_job=0
replace flag_max_job=1 if max_month_job>3

save "D:\NK\Input (stuff you generate)\intermediate\ast_panel_full.dta", replace

drop max max2 skip term gap length tot_length 



save "D:\NK\Input (stuff you generate)\ast_panel_clean.dta", replace





