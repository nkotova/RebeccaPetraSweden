** Cleaning Insper2014.dta:

use "D:\NK\Input (stuff you generate)\original\Insper2014.dta"
keep dnr2015227 akt_dat av_dat uttr_dat intr_dat

replace av_dat="2014-12-31" if av_dat==""
replace uttr_dat ="2014-12-31" if uttr_dat ==""

* Splitting dates of unemployment spells into separate year, month and day variables:
split akt_dat, p("-")
split av_dat, p("-")

split intr_dat, p("-")
*split uttr_dat, p("-")

*destring akt_dat1 akt_dat2 akt_dat3 av_dat1 av_dat2 av_dat3 intr_dat1 intr_dat2 intr_dat3 uttr_dat1 uttr_dat2 uttr_dat3

sort dnr2015227 akt_dat av_dat
bysort dnr2015227 akt_dat: drop if _n!=_N

destring intr_dat1 intr_dat2 akt_dat1 akt_dat2 av_dat1, replace

gen tag=0
replace tag=1 if av_dat1<1990

replace  av_dat1=1992 if tag==1


drop if akt_dat1<1992

gen diff= 12*(intr_dat1- akt_dat1)+ intr_dat2-akt_dat2

gen tag2=0
replace tag2=1 if akt_dat>av_dat & diff<-110 & diff>-130

replace akt_dat1=akt_dat1-10 if tag2==1

tostring intr_dat1 intr_dat2 akt_dat1 akt_dat2 av_dat1, replace

replace av_dat=av_dat1+"-"+av_dat2+"-"+av_dat3 if tag==1

replace akt_dat=akt_dat1+"-"+akt_dat2+"-"+akt_dat3 if tag2==1

drop if akt_dat>av_dat

keep dnr2015227 akt_dat1 akt_dat2

duplicates drop

rename akt_dat1 year_start
rename akt_dat2 month_start

save "D:\NK\Input (stuff you generate)\Insper2014_clean.dta", replace


