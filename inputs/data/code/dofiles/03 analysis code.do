*************************************************************************
* PROJECT :         Intergenerational mortality
* AUTHOR :          Tom Vogl, Frances Lu
* MODIFIED BY :		
* PURPOSE :         Analysis file for submitted draft
* DATA FROM:        DHS,UN
* DATA TO:            
* DATE WRITTEN :   	
*************************************************************************
set more off
clear all
eststo clear
clear matrix
set maxvar 10000
set matsize 10000


*************************************************************************

**********
* Table of contents
* 0. Set up analysis datasets for moms and births
* Table 1: Summary statistics
* Figure 1: Share with Any Child Death, by Any Sibling Death
* Table 2. Pooled Estimates of Mortality Persistence
* Table 3. Adding covariates
* Table 4. Panel Analyses of Mortality Persistence over the Mortality Transition

* Table A.1: Demographic and Health Surveys in the Sample (Not statistical, no code)
* Table A.2: Partial Correlations of Sibling and Child Under-5 Mortality, Women Aged 45-49
* Table A.3: Mothers' vs. Daughters' Reports of Any Under-5 Death
* Table A.4: Mothers' vs. Daughters' Reports of Any Under-5 Death
* Table A.5: Pooled Birth-Level Logit Estimations by Gender

* Figure A.1: Sibship Size and Sibling Mortality
* Figure A.2: Log Odds of Any Child Death, by Any Sibling Death
* Figure A.3: Mother-Level Logit Results by Age
* Figure A.4: Comparison with Other Under-5 Mortality Differentials
* Figure A.5: Robustness to Survey-by-Age Group Effects (note: this is computationally intensive)
* Figure A.6: Monte Carlo Simulations of Measurement Error (note: this is computationally intensive)
* Figure A.7:  Mortality Persistence by Country
* Figure A.8: Absolute Versus Proportional Mortality Persistence for a Binary Risk Factor
* Figure A.9: Under-5 Mortality Rate over Time, by Country
* Figure A.10: Semi-Parametric Panel Analyses
* Figure A.11: Leave-One-Out Panel Analyses
**********

*****
* 0. Set up analysis datasets for moms and births
*****
//MOMS
use "data/moms.dta",clear
count
drop if numsibs==0 //only children are irrelevant for our analysis
keep if age>=20&age<50 //20+ so sibship info is complete, <50 so age range same for all svys
drop if edyrs==. //drop obs with missing vals
count

replace yob = year - age //a few observations were missing year of birth

egen global_cluster = group(surveycode cluster) //unique cluster after combining surveys
encode surveycode,gen(surveynum) //numeric survey code

label var u5_sibs "Sibs deceased under 5"
label var numsibs "Sibs ever born"
label var evborn "Children ever born"

save "data/mom_analysis.dta",replace

//BIRTHS
use "data/births.dta",clear
count
drop if numsibs==0 //only children are irrelevant for our analysis
keep if age>=20&age<50 //20+ so sibship info is complete, <50 so age range same for all svys
drop if edyrs==. //drop obs with missing vals
drop if ch_yob==. //drop obs with missing vals
count

replace yob = year - age //a few observations were missing year of birth

egen global_cluster = group(surveycode cluster) //unique cluster after combining surveys
encode surveycode,gen(surveynum) //numeric survey code
gen u5 = (ch_agedeath<60) if ch_yob+5<year //for under-5, consider kids born > 5 calendar yrs before svy

label var u5_sibs "Sibs deceased under 5"
label var numsibs "Sibs ever born"
label var evborn "Children ever born"

*birth recall period -- note that u5 is missing if period <=5yrs by construction
gen diff = year-ch_yob
tab diff
tab diff if u5<.
*diff<=20y is 87 percent of all births and 82 percent of births with non-missing u5
*also, diff<=20y gives us a 15y period of births with nonmissing u5 for each survey
*so drop diff>20
drop if diff>20|u5==.

save "data/birth_analysis.dta",replace

************
* Table 1: Summary statistics
************

use "data/mom_analysis.dta",clear
*adjust sampling weights for so that each survey 
*contributes weight proportional to its sample size
bysort surveycode: egen weight = pc(smpwt),prop
bysort surveycode: egen n_svy = count(smpwt)
replace weight = n_svy*weight
*any death variables
gen anysib = u5_sibs>0
gen anykid = ev_u5>0
*labels
label var age "Age"
label var edyrs "Years of education"
label var rural "Rural residence"
label var numsibs "Siblings ever born"
label var u5_sibs "Siblings deceased under 5"
label var ev_u5 "Children deceased under 5"
label var anysib "At least one sibling deceased under 5"
label var anykid "At least one child deceased under 5"
*summarize
eststo clear
eststo: quietly estpost sum age edyrs rural numsibs u5_sibs anysib evborn ev_u5 anykid [aw=weight]
esttab using "output/sumstat.tex", replace ///
	cells("mean(fmt(2)) sd(fmt(2))") label booktab nonumber nomtitles
eststo clear


*****
* Figure 1. Share with Any Child Death, by Any Sibling Death
*****

use "data/mom_analysis.dta",clear
gen anysib = u5_sibs>0
gen anykid = ev_u5>0
gen agecat = floor(age/5)*5

//adjust sampling weights for so that each survey contributes weight proportional to its sample size
bysort surveycode: egen weight = pc(smpwt),prop
bysort surveycode: egen n_svy = count(smpwt)
replace weight = n_svy*weight

//summary stats
table agecat [aw=weight],statistic(mean anykid anysib)

//sample sizes and shares
count if anysib==0
local n_nosib = r(N)
count if anysib==1
local n_anysib = r(N)
local pct_nosib = round(100*`n_nosib'/(`n_nosib'+`n_anysib'))
local pct_anysib = 100-`pct_nosib'

//collapse by survey and age, weighting using sampling weights (now rescaling doesn't matter)
gen anykid_nosib = anykid if anysib==0
gen anykid_anysib = anykid if anysib==1
collapse anykid_nosib anykid_anysib ///
         (count) n=anykid n_nosib=anykid_nosib n_anysib=anykid_anysib ///
		 [aw=weight],by(agecat surveycode)
gen within_diff = anykid_anysib-anykid_nosib

//collapse by age, weighting by variable-specific sample size
preserve
collapse within_diff [aw=n],by(agecat)
tempfile temp
save `temp'
restore
preserve
collapse anykid_nosib [aw=n_nosib],by(agecat)
merge 1:1 agecat using `temp'
drop _merge
save `temp',replace
restore
collapse anykid_anysib [aw=n_anysib],by(agecat)
merge 1:1 agecat using `temp'
drop _merge
gen anykid_plus = anykid_nosib + within_diff

//list shares and differences
gen total_diff = anykid_anysib - anykid_nosib
gen ratio_within_total = within_diff/total_diff
list agecat anykid_nosib anykid_anysib total_diff within_diff ratio_within_total

//graph of rates
twoway (rarea anykid_plus anykid_nosib agecat,color(gs12%50)) ///
	   (connected anykid_nosib agecat,color(orange_red) lpattern(solid) msymbol(S)) ///
       (connected anykid_anysib agecat,color(dknavy) lpattern(solid) msymbol(O)) ///
	   ,scheme(plotplain) legend(off) aspect(1) ///
	    xtitle("Age group") ytitle("Share with {&ge} 1 child death") ///
		xlabel(20 "20-24" 25 "25-29" 30 "30-34" 35 "35-39" 40 "40-44" 45 "45-49",labsize(medsmall) nogrid) ///
	    ylabel(,labsize(medsmall) nogrid) ///
	    text(.44 37.5 "            Within-" "      survey" "component",color(gs10) place(se) just(left)) ///
	    text(.27 32.5 "Women w/ no sibling" "under-5 deaths" "N =`:di %9.0gc `n_nosib'' (`pct_nosib'%)",color(orange_red) place(se) just(left)) ///
	    text(.365 32 "Women w/ {&ge} 1 sibling" "under-5 death" "N =`:di %9.0gc `n_anysib'' (`pct_anysib'%)",color(dknavy) place(nw) just(right))
graph export "output/summary_plot_shares.pdf",replace


*************
* Table 2. Pooled Estimates of Mortality Persistence
*************

***
* Covariate is any siblings dead
***
eststo clear

use "data/mom_analysis.dta",clear
gen anyu5 = (ev_u5 > 0)
gen anyu5_sibs = (u5_sibs > 0)

*adjust sampling weights
bysort surveycode: egen weight = pc(smpwt),prop
bysort surveycode: egen n_svy = count(smpwt)
replace weight = n_svy*weight

*Mother-level regression
eststo: logistic anyu5 anyu5_sibs i.surveynum i.age [pw = weight],cluster(global_cluster)
margins,dydx(anyu5_sibs) at(age==49)
matrix define MARG = r(table)
estadd scalar marg = MARG[1,1]
loc tempn = e(N)
loc Nf: display string(`tempn', "%12.2g")

eststo: logistic anyu5 anyu5_sibs numsibs i.surveynum i.age [pw = weight],cluster(global_cluster)
margins,dydx(anyu5_sibs) at(age==49)
matrix define MARG = r(table)
estadd scalar marg = MARG[1,1]
loc tempn = e(N)
loc Nf: display string(`tempn', "%12.2g")

*Poisson 
eststo: poisson ev_u5 anyu5_sibs i.age i.surveynum [pw = weight],cluster(global_cluster) irr
margins,dydx(anyu5_sibs) at(age==49)
matrix define MARG = r(table)
estadd scalar marg = MARG[1,1]
loc tempn = e(N)
loc Nf: display string(`tempn', "%12.2g")

eststo: poisson ev_u5 anyu5_sibs numsibs i.age i.surveynum [pw = weight],cluster(global_cluster) irr
margins,dydx(anyu5_sibs) at(age==49)
matrix define MARG = r(table)
estadd scalar marg = MARG[1,1]
loc tempn = e(N)
loc Nf: display string(`tempn', "%12.2g")		

*Birth-level logit
use "data/birth_analysis.dta",clear
gen anyu5_sibs = (u5_sibs > 0)

*adjust sampling weights
bysort surveycode: egen weight = pc(smpwt),prop
bysort surveycode: egen n_svy = count(smpwt)
replace weight = n_svy*weight

eststo: logistic u5 anyu5_sibs i.surveynum [pw = weight],cluster(global_cluster)
margins,dydx(anyu5_sibs)
matrix define MARG = r(table)
estadd scalar marg = MARG[1,1]

eststo: logistic u5 anyu5_sibs numsibs i.surveynum [pw = weight],cluster(global_cluster)
margins,dydx(anyu5_sibs)
matrix define MARG = r(table)
estadd scalar marg = MARG[1,1]

label var anyu5_sibs "Any sibling U5 death"
esttab using "output/u5_anysibs_full_nostar", ///
        replace nodepvar booktabs compress nonotes nogaps nolz ///
	    eqlabels(none) nomtitles keep(anyu5_sibs numsibs) ///
		label eform b(%12.3f) se(%12.2g) brackets ///
		stats(marg N,fmt(%12.3f %12.3g) ///
		labels( "AME(any sib. death)" "Observations")) ///
		nostar ///
		mgroups("\shortstack{ Logit (Woman)\\Any child death}" "\shortstack{Poisson (Woman)\\ \# child deaths}" "\shortstack{Logit (Birth)\\Child death}"	, ///
			pattern(1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
			
			
***
* Covariate is # of siblings dead
***

eststo clear

use "data/mom_analysis.dta",clear
gen anyu5 = (ev_u5 > 0)

*adjust sampling weights
bysort surveycode: egen weight = pc(smpwt),prop
bysort surveycode: egen n_svy = count(smpwt)
replace weight = n_svy*weight

*Mother-level regression
eststo: logistic anyu5 u5_sibs i.surveynum i.age [pw = weight],cluster(global_cluster)
margins,dydx(u5_sibs) at(age==49)
matrix define MARG = r(table)
estadd scalar marg = MARG[1,1]

eststo: logistic anyu5 u5_sibs numsibs i.surveynum i.age [pw = weight],cluster(global_cluster)
margins,dydx(u5_sibs) at(age==49)
matrix define MARG = r(table)
estadd scalar marg = MARG[1,1]

*Poisson
eststo: poisson ev_u5 u5_sibs i.age i.surveynum [pw = weight],cluster(global_cluster) irr
margins,dydx(u5_sibs) at(age==49)
matrix define MARG = r(table)
estadd scalar marg = MARG[1,1]

eststo: poisson ev_u5 u5_sibs numsibs i.age i.surveynum [pw = weight],cluster(global_cluster) irr
margins,dydx(u5_sibs) at(age==49)
matrix define MARG = r(table)
estadd scalar marg = MARG[1,1]


*Birth-level logit
use "data/birth_analysis.dta",clear

*adjust sampling weights
cap drop weight
bysort surveycode: egen weight = pc(smpwt),prop
bysort surveycode: egen n_svy = count(smpwt)
replace weight = n_svy*weight

eststo: logistic u5 u5_sibs i.surveynum [pw = weight],cluster(global_cluster)
margins,dydx(u5_sibs)
matrix define MARG = r(table)
estadd scalar marg = MARG[1,1]

eststo: logistic u5 u5_sibs numsibs i.surveynum [pw = weight],cluster(global_cluster)
margins,dydx(u5_sibs)
matrix define MARG = r(table)
estadd scalar marg = MARG[1,1]
			
label var u5_sibs "\# sibling U5 deaths"
esttab using "output/u5_numsibs_full_nostar", ///
        replace nodepvar booktabs compress nonotes nogaps nolz ///
	    eqlabels(none) nomtitles keep(u5_sibs numsibs) ///
		label eform b(%12.3f) se(%12.2g) brackets ///
		stats(marg N,fmt(%12.3f %12.3g) ///
		labels( "AME(\# sib. deaths)" "Observations")) ///
		nostar ///
		mgroups("\shortstack{ Logit (Mother)\\Any child death}" "\shortstack{Poisson (Mother)\\ \# child deaths}" "\shortstack{Logit (Birth)\\Child death}"	, ///
			pattern(1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

*************
* Table 3. Adding Covariates
************

use "data/birth_analysis.dta",clear

//Standardize PCA within each survey 
sort surveynum
by surveynum: egen assetindex_mean = mean(assetindex)
by surveynum: egen assetindex_sd = sd(assetindex)
gen assetindex_std = (assetindex - assetindex_mean)/assetindex_sd

//adjust sampling weights
bysort surveycode: egen weight = pc(smpwt),prop
bysort surveycode: egen n_svy = count(smpwt)
replace weight = n_svy*weight
svyset[pw=weight]

//restrict to sample with intracluster variation in deaths
bysort global_cluster: egen clustwt = mean(weight) //clogit does not allow weights to vary within cluster
bysort global_cluster: egen max = max(u5)
bysort global_cluster: egen min = min(u5)
drop if max==min //clogit can only analyze clusters with outcome variation
drop max min

//baseline estimates
preserve
keep if assetindex_std<. //so sample size is the same in all estimations
eststo clear
eststo: logit u5 u5_sibs numsibs i.surveynum [pw=clustwt],cluster(global_cluster) or
estadd local hassibs "Yes"
estadd local hasses "No"
eststo: clogit u5 u5_sibs numsibs [pw=clustwt],group(global_cluster) cluster(global_cluster) or
estadd local hassibs "Yes"
estadd local hasses "No"
eststo: clogit u5 u5_sibs numsibs edyrs assetindex_std [pw=clustwt],group(global_cluster) cluster(global_cluster) or
estadd local hassibs "Yes"
estadd local hasses "Yes"
esttab using "output/covariates_full.tex", ///
        replace	nodepvar booktabs compress nonotes nogaps nolz ///
	    nomtitles keep(u5_sibs) ///
		label eform b(%12.3f) se(%12.2g) brackets nostar ///
		scalars("hassibs Sibs ever born" "hasses SES variables") ///
		mgroups("\shortstack{Logit with\\survey effects}" "\shortstack{Conditional logit\\with cluster effects}", ///
			pattern(1 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
restore
		
//role of place: non-migrant
codebook surveycode if nonmigrant<.
tab nonmigrant [aw=weight]
preserve
keep if nonmigrant==1&assetindex_std<. //nonmigrants with non-missing covariates
bysort global_cluster: egen max = max(u5)
bysort global_cluster: egen min = min(u5)
drop if max==min //clogit can only analyze clusters with outcome variation
*for table: just focus on non-migrants in intracluster sample
eststo clear
eststo: logit u5 u5_sibs numsibs i.surveynum [pw=clustwt],cluster(global_cluster) or
estadd local hassibs "Yes"
estadd local hasses "No"
eststo: clogit u5 u5_sibs numsibs [pw=clustwt],group(global_cluster) cluster(global_cluster) or
estadd local hassibs "Yes"
estadd local hasses "No"
eststo: clogit u5 u5_sibs numsibs edyrs assetindex_std [pw=clustwt],group(global_cluster) cluster(global_cluster) or
estadd local hassibs "Yes"
estadd local hasses "Yes"
esttab using "output/covariates_nonmigrants.tex", ///
        replace	nodepvar booktabs compress nonotes nogaps nolz ///
	    nomtitles keep(u5_sibs) ///
		label eform b(%12.3f) se(%12.2g) brackets nostar ///
		scalars("hassibs Sibs ever born" "hasses SES variables") ///
		mgroups("\shortstack{Logit with\\survey effects}" "\shortstack{Conditional logit\\with cluster effects}", ///
			pattern(1 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
restore

//role of health: sample with height
codebook surveycode if height<.
preserve
sum height,d
replace height = . if height<500&height>3000 //drop heights less than 50cm and more than 3m
replace height = height/10 //weird units - convert to cm
keep if height<.
bysort global_cluster: egen max = max(u5)
bysort global_cluster: egen min = min(u5)
drop if max==min //clogit can only analyze clusters with outcome variation
eststo clear
eststo: logit u5 u5_sibs numsibs i.surveynum [pw = weight], cluster(global_cluster) or
estadd local hassibs "Yes"
estadd local hasheight "No"
eststo: clogit u5 u5_sibs numsibs [pw=clustwt],group(global_cluster) cluster(global_cluster) or
estadd local hassibs "Yes"
estadd local hasheight "No"
eststo: clogit u5 u5_sibs numsibs height [pw=clustwt],group(global_cluster) cluster(global_cluster) or
estadd local hassibs "Yes"
estadd local hasheight "Yes"
//for comparison with Bhalotra and Rawlings
clogit
margins,dydx(height)
//
esttab using "output/covariates_height.tex", ///
        replace	nodepvar booktabs compress nonotes nogaps nolz ///
	    nomtitles keep(u5_sibs) ///
		label eform b(%12.3f) se(%12.2g) brackets nostar ///
		scalars("hassibs Sibs ever born" "hasheight Height") ///
		mgroups("\shortstack{Logit with\\survey effects}" "\shortstack{Conditional logit\\with cluster effects}", ///
			pattern(1 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
restore					

************
* Table 4. Panel Analyses of Mortality Persistence over the Mortality Transition
************		

use "data/birth_analysis.dta",clear

//adjust sampling weights for representative country/midperiod-level estimates
bysort surveycode midperiod: egen weight = pc(smpwt),prop
bysort surveycode midperiod: egen n_svy = count(smpwt)
bysort country midperiod: egen n_tot = count(smpwt)
replace weight = (n_svy/n_tot)*weight

//define cells
egen ct = group(midperiod country)

//count cells
sort ct
sum ct 
local max_ct = r(max)
di `max_ct'

//initiate and run loop
gen obsnum = _n
gen or = .
gen marg = .
gen n = .
forvalues i=1/`max_ct' {
  qui sum obs if ct==`i'
  local min = r(min)
  local max = r(max)
  qui logistic u5 u5_sibs numsibs i.surveynum in `min'/`max' [pw=weight],cluster(global_cluster)
  qui replace n = e(N) in `min'/`max'
  qui replace or = el(r(table),1,1) in `min'/`max'
  qui margins,dydx(u5_sibs) nose
  qui replace marg = el(r(table),1,1) in `min'/`max'
}
keep country midperiod q5 lngdppc gini_reported conflict n or marg
order country midperiod q5 lngdppc gini_reported conflict n or marg
bysort country midperiod: keep if _n==1
encode country,gen(countrynum)

//rescale q5 from 0-1000 to 0-1
replace q5 = q5/1000
sum q5,d //summarize overall distribution - interquartile range .11
reg q5 i.midperiod i.countrynum,cluster(countrynum) //summarize within-country changes - .2 over 50 years

//categorical q5
egen q5_cat = cut(q5),icodes at(0 .075 .1 .15 .2 .25 .41) /*roughly 10, 25, 50, 75, 90 %iles*/

//relabel vars for regression table
label var q5 "Under-5 mortality [0-1] (UN)"
label var lngdppc "Log GDPpc (PWT)"
label var conflict "Conflict [0/1] (UCDP/PRIO)"
save "data/country_cohort",replace

//regressions

use "data/country_cohort",clear
*Rwanda 1990-4 genocide: large mortality event 
*consensus estimate: 500-600k deaths, which is 7-9% of pop
*see https://www.tandfonline.com/doi/abs/10.1080/14623528.2019.1703252?journalCode=cjgr20
*no other genocide like it in our sample (Cambodia late 70s not in sample)
*only comptetitor is Darfur, which had killed less than 2% over a much longer period.
tab midperiod if country=="Rwanda",sum(q5)
drop if (country=="Rwanda"&midperiod==1993) // drop genocide period 

eststo clear

eststo: reg marg q5 i.midperiod i.countrynum if lngdppc<.,cluster(countrynum)
sum marg if e(sample)
estadd scalar mean = r(mean)
estadd scalar sd = r(sd)

eststo: reg marg lngdppc i.midperiod i.countrynum ,cluster(countrynum)
sum marg if e(sample)
estadd scalar mean = r(mean)
estadd scalar sd = r(sd)

eststo: reg marg conflict i.midperiod i.countrynum if lngdppc<.,cluster(countrynum)
sum marg if e(sample)
estadd scalar mean = r(mean)
estadd scalar sd = r(sd)

eststo: reg marg q5 lngdppc conflict i.midperiod i.countrynum ,cluster(countrynum)
sum marg if e(sample)
estadd scalar mean = r(mean)
estadd scalar sd = r(sd)

eststo: reg or q5 i.midperiod i.countrynum if lngdppc<. ,cluster(countrynum)
sum or if e(sample)
estadd scalar mean = r(mean)
estadd scalar sd = r(sd)

eststo: reg or lngdppc i.midperiod i.countrynum,cluster(countrynum)
sum or if e(sample)
estadd scalar mean = r(mean)
estadd scalar sd = r(sd)

eststo: reg or conflict i.midperiod i.countrynum if lngdppc<.,cluster(countrynum)
sum or if e(sample)
estadd scalar mean = r(mean)
estadd scalar sd = r(sd)

eststo: reg or q5 lngdppc conflict i.midperiod i.countrynum,cluster(countrynum)
sum or if e(sample)
estadd scalar mean = r(mean)
estadd scalar sd = r(sd)

//for reference: mortality on country and period FE 
reg q5 lngdppc conflict i.midperiod i.countrynum if e(sample),cluster(countrynum)
reg lngdppc i.midperiod i.countrynum if e(sample),cluster(countrynum)
reg conflict i.midperiod i.countrynum if e(sample),cluster(countrynum)


esttab using "output/aggregates" ///
       ,replace booktabs compress nonotes ///
	    eqlabels(none) keep(q5 lngdppc conflict) b(a2) se(a2) ///
		stats(mean sd N,fmt(%12.3f %12.3f %12.0fc) labels("Mean of estimated parameter" "Std. dev. of estimated parameter"  "Country-period cells")) ///
		star(* 0.10 ** 0.05 *** 0.01) ///
		nomtitles label brackets ///
		mgroups("Average marginal effect" "Odds ratio", ///
			pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

		
esttab using "output/aggregates_nostar" ///
       ,replace booktabs compress nonotes ///
	    eqlabels(none) keep(q5 lngdppc conflict) b(a2) se(a2) ///
		stats(mean sd N,fmt(%12.3f %12.3f %12.0fc) labels("Mean of estimated parameter" "Std. dev. of estimated parameter"  "Country-period cells")) ///
		nostar nomtitles label brackets ///
		mgroups("Average marginal effect" "Odds ratio", ///
			pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

************
* Table A.1: Demographic and Health Surveys in the Sample
************			
*Not statistical, no code

************
* Table A.2: Partial Correlations of Sibling and Child Under-5 Mortality, Women Aged 45-49
************
*build this table by hand
use "data/mom_analysis.dta",clear
keep if age>=45 // focus on older women because the models below are not proportional
gen ev_u5_any = (ev_u5>0)
gen u5_sibs_any = (u5_sibs>0)

*adjust sampling weights
bysort surveycode: egen weight = pc(smpwt),prop
bysort surveycode: egen n_svy = count(smpwt)
replace weight = n_svy*weight

*partial correlations, net of survey dummies
pcorr ev_u5_any u5_sibs_any i.surveynum [aw=weight] //0.0770 
pcorr ev_u5 u5_sibs i.surveynum [aw=weight] //0.0738

************
* Table A.3: Mothers' vs. Daughters' Reports of Any Under-5 Death
************
use "data/moms.dta",clear
keep if age>=15&age<20 //teen sample
tab surveycode //two letters are a country, the next number is DHS phase
gen hasmomid = (momid<.)
tab hasmomid //100k out of 340k teenagers have momid's, but some of this is due to surveys that didn't collect
bysort surveycode: egen svyhasmomid = max(hasmomid) //does survey collect mother-child linkage?
codebook surveycode //119 surveys

keep if svyhasmomid==1
codebook surveycode //85 surveys with mother-child linkage
tab hasmomid //100k out of 275k teenagers have momid's, i.e. live with their moms
bysort surveycode: egen weight = pc(smpwt),prop //set up weights to get weighted mean
bysort surveycode: egen n_svy = count(smpwt) //set up weights to get weighted mean
replace weight = n_svy*weight //set up weights to get weighted mean
sum hasmomid [aw=weight] //weighted mean is same as unweighted: 38% of teenage girls live with their moms
keep if hasmomid==1 //relevant sample

keep u5_sibs surveycode cluster hhnumber momid smpwt age
tempfile teens
save `teens'

use "data/moms.dta",clear
keep if age>=30&age<50 //keep 30-49 year old mothers
drop momid
rename respid momid
rename age momage
duplicates tag surveycode cluster hhnumber momid,gen(dup)
drop if dup==1 //two duplicate IDs in Bangladesh - remove
keep ev_u5 surveycode cluster hhnumber momid momage
merge 1:m surveycode cluster hhnumber momid using `teens'
//not matched from master - women who do not live with their teenage daughters
//not matched from using - teenagers who live with moms over 49 in the surveys that have older women
keep if _merge==3

//adjust sampling weights for so that each survey contributes weight proportional to its sample size
bysort surveycode: egen weight = pc(smpwt),prop
bysort surveycode: egen n_svy = count(smpwt)
replace weight = n_svy*weight

//rename variables
rename ev_u5 mom_ev_u5
rename u5_sibs daughter_ev_u5

//daughter and mom age
sum age momage [aw=weight]

//mom's report of mom's ANY u5 death vs. daughter's report of mom's ANY u5 death
gen mom_any_u5 = mom_ev_u5>0
gen daughter_any_u5 = daughter_ev_u5>0
corr mom_any_u5 daughter_any_u5 [aw=weight]
tab mom_any_u5 daughter_any_u5 [aw=weight],row

label define lbl 0 "0" 1 "1+"
label values mom_any_u5 lbl

label var mom_any_u5 "Mother's report"
label var daughter_any_u5 "Daughter's report"
tabout mom_any_u5 daughter_any_u5 if mom_ev_u5<=4 [aw=weight] using "output/momdaughter_any.tex" ///
       ,cells(row) ptotal(none) npos(col) h3(nil) style(tex) bt replace

************
* Table A.4: Mothers' vs. Daughters' Reports of Any Under-5 Death
************
//rely on dataset from Table A.3
sum mom_ev_u5 [aw=weight]
local mom = r(sum)
sum daughter_ev_u5 [aw=weight]
local daughter = r(sum)
di 1 - `daughter'/`mom' // fraction of total mom reported deaths not recalled by daughters
corr mom_ev_u5 daughter_ev_u5 [aw=weight]
tab mom_ev_u5 // 99% of observations have 4 or fewer deaths, so tabulate those
tab mom_ev_u5 daughter_ev_u5 [aw=weight] if mom_ev_u5<=4,row nofreq
recode daughter_ev_u5 (6/20=6) // compress tail on daughter report to "6+"
tab mom_ev_u5 daughter_ev_u5 [aw=weight] if mom_ev_u5<=4,row

label var mom_ev_u5 "Mother's report"
label var daughter_ev_u5 "Daughter's report"
tabout mom_ev_u5 daughter_ev_u5 if mom_ev_u5<=4 [aw=weight] using "output/momdaughter_count.tex" ///
       ,cells(row) ptotal(none) npos(col) h3(nil) style(tex) bt replace

************
* Table A.5: Pooled Birth-Level Logit Estimations by Gender
************
eststo clear
*Birth-level logit
use "data/birth_analysis.dta",clear

*adjust sampling weights
bysort surveycode: egen weight = pc(smpwt),prop
bysort surveycode: egen n_svy = count(smpwt)
replace weight = n_svy*weight

*Main birth-level logit
eststo: logistic u5 u5_sibs numsibs i.surveynum if ch_male == 0 [pw = weight],cluster(global_cluster)
margins,dydx(u5_sibs)
matrix define MARG = r(table)
estadd scalar marg = MARG[1,1]

eststo: logistic u5 u5_sibs numsibs i.surveynum if ch_male == 1 [pw = weight],cluster(global_cluster)
margins,dydx(u5_sibs)
matrix define MARG = r(table)
estadd scalar marg = MARG[1,1]

*Siblings by gender
eststo: logistic u5 u5_fsibs fsibs u5_msibs msibs i.surveynum if ch_male == 0 [pw = weight],cluster(global_cluster)
margins,dydx(u5_fsibs)
matrix define MARGF = r(table)
estadd scalar margf = MARGF[1,1]
margins,dydx(u5_msibs)
matrix define MARGM = r(table)
estadd scalar margm = MARGM[1,1]

eststo: logistic u5 u5_fsibs fsibs u5_msibs msibs i.surveynum if ch_male == 1 [pw = weight],cluster(global_cluster)
margins,dydx(u5_fsibs)
matrix define MARGF = r(table)
estadd scalar margf = MARGF[1,1]
margins,dydx(u5_msibs)
matrix define MARGM = r(table)
estadd scalar margm = MARGM[1,1]

label var u5_sibs "\# sibling U5 deaths"
label var u5_fsibs "\# female sibling U5 death"
label var u5_msibs "\# male sibling U5 death"
label var fsibs "Female sibs ever born"
label var msibs "Male sibs ever born"

esttab using "output/u5_bygender", ///
        replace nodepvar booktabs compress nonotes nogaps nolz ///
	    eqlabels(none) nomtitles keep(*u5_*sibs numsibs fsibs msibs) ///
		order(u5_sibs numsibs u5_fsibs fsibs u5_msibs msibs) ///
		label eform b(%12.2f) se(%12.2g) brackets ///
		stats(marg margf margm N,fmt(%12.3f %12.3f %12.3f %12.3g) ///
		labels( "AME(\# sib. deaths)"  "AME(\# female sib. deaths)"  "AME(\# male sib. deaths)" "Observations")) ///
		star(* 0.10 ** 0.05 *** 0.01) ///
		mgroups("Female" "Male" "Female" "Male", ///
			pattern(1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

eststo clear
	   

	   
	   
************
* Figure A.1: Sibship Size and Sibling Mortality
************
use "data/mom_analysis.dta",clear
egen countrynum = group(country)
collapse u5_sibs (count) n=u5_sibs [aw=smpwt],by(numsibs surveynum countrynum)
tab numsibs,sum(n)
gen u5 = u5_sibs/numsibs
reg u5 numsibs [aw=n]
reg u5 numsibs i.surveynum [aw=n]

tab numsibs //topcode at 9+ so that all surveys have all categories
recode numsibs (9/20=9),gen(numsibs_top)
reg u5 i.numsibs_top i.surveynum [aw=n],cluster(countrynum)
gen x = _n if _n<=9
gen coef = 0
gen lb = .
gen ub = .
forvalues i=2/9 {
  replace coef = el(r(table),1,`i') if x==`i'
  replace lb = el(r(table),5,`i') if x==`i'
  replace ub = el(r(table),6,`i') if x==`i'
  }
twoway (connected coef x,color(black) msymbol(O) lwidth(medthick)) ///
       (rspike lb ub x,lcolor(black) lwidth(medthick)) ///
	   ,scheme(plotplainblind) legend(off) aspect(1) ///
	    xtitle("Number of siblings") xlabel(1/8 9 "9+",labsize(medsmall)) ///
	    ytitle("Sibling mortality risk, rel. to 1 sibling families") ylabel(0(.025).125,labsize(medsmall) gmax)
graph export "output/sibsize_mort.pdf",replace

*************
* Figure A.2: Log Odds of Any Child Death, by Any Sibling Death
*************
use "data/mom_analysis.dta",clear
gen anysib = u5_sibs>0
gen anykid = ev_u5>0
gen agecat = floor(age/5)*5

//adjust sampling weights for so that each survey contributes weight proportional to its sample size
bysort surveycode: egen weight = pc(smpwt),prop
bysort surveycode: egen n_svy = count(smpwt)
replace weight = n_svy*weight

//sample sizes and shares
count if anysib==0
local n_nosib = r(N)
count if anysib==1
local n_anysib = r(N)
local pct_nosib = round(100*`n_nosib'/(`n_nosib'+`n_anysib'))
local pct_anysib = 100-`pct_nosib'

//collapse by survey and age, weighting using sampling weights (now rescaling doesn't matter)
gen anykid_nosib = anykid if anysib==0
gen anykid_anysib = anykid if anysib==1
collapse anykid_nosib anykid_anysib ///
         (count) n=anykid n_nosib=anykid_nosib n_anysib=anykid_anysib ///
		 [aw=weight],by(agecat surveycode)
gen within_diff = anykid_anysib-anykid_nosib

//collapse by age, weighting by variable-specific sample size
preserve
collapse within_diff [aw=n],by(agecat)
tempfile temp
save `temp'
restore
preserve
collapse anykid_nosib [aw=n_nosib],by(agecat)
merge 1:1 agecat using `temp'
drop _merge
save `temp',replace
restore
collapse anykid_anysib [aw=n_anysib],by(agecat)
merge 1:1 agecat using `temp'
drop _merge
gen anykid_plus = anykid_nosib + within_diff

//log odds
gen logit_nosib = ln(anykid_nosib/(1-anykid_nosib))
gen logit_anysib = ln(anykid_anysib/(1-anykid_anysib))
gen logit_plus = ln(anykid_plus/(1-anykid_plus))

//list logits and differences
gen total_reldiff = exp(logit_anysib - logit_nosib)-1
gen within_reldiff = exp(logit_plus - logit_nosib)-1
gen ratio_within_total_reldiff = within_reldiff/total_reldiff
list agecat logit_nosib logit_anysib total_reldiff within_reldiff ratio_within_total_reldiff
//graph of logits
twoway (rarea logit_plus logit_nosib agecat,color(gs12%50)) ///
	   (connected logit_nosib agecat,color(orange_red) lpattern(solid) msymbol(S)) ///
       (connected logit_anysib agecat,color(dknavy) lpattern(solid) msymbol(O)) ///
	   ,scheme(plotplain) legend(off) aspect(1) ///
	    xtitle("Age group") ytitle("Log odds of {&ge} 1 child death") ///
		xlabel(20 "20-24" 25 "25-29" 30 "30-34" 35 "35-39" 40 "40-44" 45 "45-49",labsize(medsmall) nogrid) ///
	    ylabel(,labsize(medsmall) nogrid) ///
	    text(-.43 35 "                  Within-" "         survey" "component",color(gs10) place(e) just(left)) ///
		text(-.95 33.3 "Women w/ no sibling" "under-5 deaths",color(orange_red) place(se) just(left)) ///
	    text(-.45 33.3 "Women w/ {&ge} 1 sibling" "under-5 death",color(dknavy) place(nw) just(right))
graph export "output/summary_plot_logodds.pdf",replace

************
* Figure A.3: Mother-Level Logit Results by Age
************

use "data/mom_analysis.dta",clear
gen anyu5 = (ev_u5 > 0)
gen anyu5_sibs = (u5_sibs > 0)

//adjust sampling weights
bysort surveycode: egen weight = pc(smpwt),prop
bysort surveycode: egen n_svy = count(smpwt)
replace weight = n_svy*weight
svyset[pw=weight]

//generate variables to save results
gen agegp = 15+_n*5 if _n<=6
gen marg_pooled = .
gen marg_se_pooled = .
gen or_agegp = .
gen or_se_agegp = .
gen marg_agegp = .
gen marg_se_agegp = .

//pooled
logistic anyu5 anyu5_sibs i.surveynum i.age [pw = weight],cluster(global_cluster)
gen or_pooled = el(r(table),1,1) if _n<=6
gen or_se_pooled = el(r(table),2,1) if _n<=6
margins,dydx(anyu5_sibs) at(age==(24 29 34 39 44 49))
forvalues i=1/6 {
  replace marg_pooled = el(r(table),1,`i') if _n==`i'
  replace marg_se_pooled = el(r(table),2,`i') if _n==`i'
  }
  
//age groups
forvalues i=20(5)45 {
  local j = `i'+4
  logistic anyu5 anyu5_sibs i.surveynum i.age [pw = weight] if age>=`i'&age<=`j',cluster(global_cluster)
  replace or_agegp = el(r(table),1,1) if agegp==`i'
  replace or_se_agegp = el(r(table),2,1) if agegp==`i'
  margins,dydx(anyu5_sibs) at(age==`j')
  replace marg_agegp = el(r(table),1,1) if agegp==`i'
  replace marg_se_agegp = el(r(table),2,1) if agegp==`i'
  }

//CIs
gen or_pooled_lb = or_pooled - 1.96*or_se_pooled
gen or_pooled_ub = or_pooled + 1.96*or_se_pooled
gen marg_pooled_lb = marg_pooled - 1.96*marg_se_pooled
gen marg_pooled_ub = marg_pooled + 1.96*marg_se_pooled
gen or_agegp_lb = or_agegp - 1.96*or_se_agegp
gen or_agegp_ub = or_agegp + 1.96*or_se_agegp
gen marg_agegp_lb = marg_agegp - 1.96*marg_se_agegp
gen marg_agegp_ub = marg_agegp + 1.96*marg_se_agegp

//graphs
twoway (rarea or_pooled_lb or_pooled_ub agegp,color(orange_red*.25)) ///
       (rspike or_agegp_lb or_agegp_ub agegp,color(dknavy) lwidth(medthick) lpattern(solid)) ///
       (connected or_pooled agegp,color(orange_red) msymbol(Oh) lwidth(medthick) lpattern(solid)) ///
       (connected or_agegp agegp,color(dknavy) msymbol(S) lwidth(medthick) lpattern(solid)) ///
	   ,name(or,replace) scheme(s1mono) legend(off) plotregion(lstyle(none)) fxsize(67) graphregion(margin(tiny)) ///
	    subtitle("A. Odds ratio",ring(0) box fcolor(none)) xtitle("") ytitle("OR") ///
		xlabel(20 "20-24" 25 "25-29" 30 "30-34" 35 "35-39" 40 "40-44" 45 "45-49",labsize(medsmall)) ///
		ylabel(,labsize(medsmall) angle(90) nogmax) ///
		text(1.375 45 "Pooled",place(9) color(orange_red)) ///
		text(1.45 45 "Age-specific",place(10) color(dknavy))
twoway (rarea marg_pooled_lb marg_pooled_ub agegp,color(orange_red*.25)) ///
       (rspike marg_agegp_lb marg_agegp_ub agegp,color(dknavy) lwidth(medthick) lpattern(solid)) ///
       (connected marg_pooled agegp,color(orange_red) msymbol(Oh) lwidth(medthick) lpattern(solid)) ///
       (connected marg_agegp agegp,color(dknavy) msymbol(S) lwidth(medthick) lpattern(solid)) ///
	   ,name(marg,replace) scheme(s1mono) legend(off) plotregion(lstyle(none)) fxsize(67) graphregion(margin(tiny)) ///
	    subtitle("B. Average marginal effect",ring(0) box fcolor(none)) ///
		xtitle("") ytitle("AME in final year of age interval") ///
		xlabel(20 "20-24" 25 "25-29" 30 "30-34" 35 "35-39" 40 "40-44" 45 "45-49",labsize(medsmall)) ///
		ylabel(,labsize(medsmall) angle(90) nogmax) ///
		text(.069 45 "Pooled",place(9) color(orange_red)) ///
		text(.083 45 "Age-specific",place(9) color(dknavy))
	   
graph combine or marg,rows(2) imargin(0 0) b1("            Age group",size(small))
graph export "output/logit_by_age.pdf",replace

*****
* Figure A.4: Comparison with Other Under-5 Mortality Differentials
*****
use "data/mom_analysis.dta",clear
gen anyu5 = (ev_u5 > 0)
gen anyu5_sibs = (u5_sibs > 0)
recode u5_sibs (8/17=8),gen(u5_sibs_top) //top coded
gen ltprim = (edyrs<6)

*adjust sampling weights
bysort surveycode: egen weight = pc(smpwt),prop
bysort surveycode: egen n_svy = count(smpwt)
replace weight = n_svy*weight

*initialize variables to save results
gen result_num = _n-3 if _n<=18
gen or = .
gen lb = .
gen ub = .
gen share = .

*Mother-level regression
logistic anyu5 anyu5_sibs i.surveynum i.age [pw = weight],cluster(global_cluster)
replace or = 1.00001 if result_num==-2 //ref category
replace or = el(r(table),1,1) if result_num==-1
replace lb = el(r(table),5,1) if result_num==-1
replace ub = el(r(table),6,1) if result_num==-1
sum anyu5_sibs [aw = weight]
replace share = r(mean) if result_num==-1
replace share = 1-r(mean) if result_num==-2
logistic anyu5 i.u5_sibs_top i.surveynum i.age [pw = weight],cluster(global_cluster)
replace or = 1.00001 if result_num==1 //ref category
forvalues i=2/9 {
  replace or = el(r(table),1,`i') if result_num==`i'
  replace lb = el(r(table),5,`i') if result_num==`i'
  replace ub = el(r(table),6,`i') if result_num==`i'
  }
tab u5_sibs_top,gen(dum)  
forvalues i=1/9 {
  sum dum`i' [aw = weight]
  replace share = r(mean) if result_num==`i'
  }
logistic anyu5 rural i.surveynum i.age [pw = weight],cluster(global_cluster)
replace or = 1.00001 if result_num==11 //ref category
replace or = el(r(table),1,1) if result_num==12
replace lb = el(r(table),5,1) if result_num==12
replace ub = el(r(table),6,1) if result_num==12
sum rural [aw = weight]
replace share = r(mean) if result_num==12
replace share = 1-r(mean) if result_num==11
logistic anyu5 ltprim i.surveynum i.age [pw = weight],cluster(global_cluster)
replace or = 1.00001 if result_num==14 //ref category
replace or = el(r(table),1,1) if result_num==15
replace lb = el(r(table),5,1) if result_num==15
replace ub = el(r(table),6,1) if result_num==15
sum ltprim [aw = weight]
replace share = r(mean) if result_num==15
replace share = 1-r(mean) if result_num==14

*summarize results
list result_num or lb ub share if result_num<.

*graph
twoway (bar or result_num,color(gs3*.5)) ///
       (rspike lb ub result_num,lcolor(gs3)) ///
	   ,plotregion(lstyle(none)) graphregion(margin(none)) ///
	    legend(off) name(top,replace) ///
	    ylabel(,labsize(medsmall)) ///
		xlabel(none) ///
		ytitle("Odds ratio for any child death") xtitle("") ///
		text(2.9 -1.5 "Binary" "deaths") ///
		text(2.9 5.5 "Multicategoried" "deaths") ///
		text(2.9 11.5 "Mother's" "residence") ///
		text(2.9 14.5 "Mother's" "schooling")
		
twoway (bar share result_num,color(gs3*.5)) ///
	   ,plotregion(lstyle(none)) graphregion(margin(none)) ///
	    legend(off) name(bottom,replace) ///
	    ylabel(0 .25 .5 .75,labsize(medsmall)) ///
		xlabel(-2 "No sib deaths (ref)" -1 "Any sib death" ///
		       1 "No sib deaths (ref)" 2 "1 sib death" 3 "2 sib deaths" ///
		       4 "3 sib deaths" 5 "4 sib deaths" 6 "5 sib deaths" ///
		       7 "6 sib deaths" 8 "7 sib deaths" 9 "8+ sib deaths" ///
			   11 "Urban (ref)" 12 "Rural" ///
			   14 "Complete primary (ref)" 15 "Less than comp prim",labsize(medsmall) angle(90)) ///
		ytitle("Share") xtitle("")
		
graph combine top bottom,rows(2)		
		
graph export "output/gradients.pdf",replace

************
* Figure A.5: Robustness to Survey-by-Age Group Effects
************
*initialize results dataset
clear
set obs 6
gen model = _n
forvalues i=1/4 {
  gen est`i' = .
  gen lb`i' = .
  gen ub`i' = .
}
tempfile results
save `results'

*Mother-level results
use "data/mom_analysis.dta",clear
gen anyu5 = (ev_u5 > 0)
gen anyu5_sibs = (u5_sibs > 0)
gen agecat = floor(age/5)*5

*adjust sampling weights
bysort surveycode: egen weight = pc(smpwt),prop
bysort surveycode: egen n_svy = count(smpwt)
replace weight = n_svy*weight

logistic anyu5 anyu5_sibs i.surveynum i.age [pw = weight],cluster(global_cluster)
preserve
use `results',clear
replace est1 = el(r(table),1,1) if model==1
replace lb1 = el(r(table),5,1) if model==1
replace ub1 = el(r(table),6,1) if model==1
save `results',replace
restore
logistic anyu5 anyu5_sibs i.surveynum##i.agecat i.age [pw = weight],cluster(global_cluster)
preserve
use `results',clear
replace est2 = el(r(table),1,1) if model==1
replace lb2 = el(r(table),5,1) if model==1
replace ub2 = el(r(table),6,1) if model==1
save `results',replace
restore
logistic anyu5 anyu5_sibs numsibs i.surveynum i.age [pw = weight],cluster(global_cluster)
preserve
use `results',clear
replace est3 = el(r(table),1,1) if model==1
replace lb3 = el(r(table),5,1) if model==1
replace ub3 = el(r(table),6,1) if model==1
save `results',replace
restore
logistic anyu5 anyu5_sibs numsibs i.surveynum##i.agecat i.age [pw = weight],cluster(global_cluster)
preserve
use `results',clear
replace est4 = el(r(table),1,1) if model==1
replace lb4 = el(r(table),5,1) if model==1
replace ub4 = el(r(table),6,1) if model==1
save `results',replace
restore

logistic anyu5 u5_sibs i.surveynum i.age [pw = weight],cluster(global_cluster)
preserve
use `results',clear
replace est1 = el(r(table),1,1) if model==4
replace lb1 = el(r(table),5,1) if model==4
replace ub1 = el(r(table),6,1) if model==4
save `results',replace
restore
logistic anyu5 u5_sibs i.surveynum##i.agecat i.age [pw = weight],cluster(global_cluster)
preserve
use `results',clear
replace est2 = el(r(table),1,1) if model==4
replace lb2 = el(r(table),5,1) if model==4
replace ub2 = el(r(table),6,1) if model==4
save `results',replace
restore
logistic anyu5 u5_sibs numsibs i.surveynum i.age [pw = weight],cluster(global_cluster)
preserve
use `results',clear
replace est3 = el(r(table),1,1) if model==4
replace lb3 = el(r(table),5,1) if model==4
replace ub3 = el(r(table),6,1) if model==4
save `results',replace
restore
logistic anyu5 u5_sibs numsibs i.surveynum##i.agecat i.age [pw = weight],cluster(global_cluster)
preserve
use `results',clear
replace est4 = el(r(table),1,1) if model==4
replace lb4 = el(r(table),5,1) if model==4
replace ub4 = el(r(table),6,1) if model==4
save `results',replace
restore

poisson ev_u5 anyu5_sibs i.surveynum i.age [pw = weight],cluster(global_cluster) irr
preserve
use `results',clear
replace est1 = el(r(table),1,1) if model==2
replace lb1 = el(r(table),5,1) if model==2
replace ub1 = el(r(table),6,1) if model==2
save `results',replace
restore
poisson ev_u5 anyu5_sibs i.surveynum##i.agecat i.age [pw = weight],cluster(global_cluster) irr
preserve
use `results',clear
replace est2 = el(r(table),1,1) if model==2
replace lb2 = el(r(table),5,1) if model==2
replace ub2 = el(r(table),6,1) if model==2
save `results',replace
restore
poisson ev_u5 anyu5_sibs numsibs i.surveynum i.age [pw = weight],cluster(global_cluster) irr
preserve
use `results',clear
replace est3 = el(r(table),1,1) if model==2
replace lb3 = el(r(table),5,1) if model==2
replace ub3 = el(r(table),6,1) if model==2
save `results',replace
restore	
poisson ev_u5 anyu5_sibs numsibs i.surveynum##i.agecat i.age [pw = weight],cluster(global_cluster) irr
preserve
use `results',clear
replace est4 = el(r(table),1,1) if model==2
replace lb4 = el(r(table),5,1) if model==2
replace ub4 = el(r(table),6,1) if model==2
save `results',replace
restore	

poisson ev_u5 u5_sibs i.surveynum i.age [pw = weight],cluster(global_cluster) irr
preserve
use `results',clear
replace est1 = el(r(table),1,1) if model==5
replace lb1 = el(r(table),5,1) if model==5
replace ub1 = el(r(table),6,1) if model==5
save `results',replace
restore
poisson ev_u5 u5_sibs i.surveynum##i.agecat i.age [pw = weight],cluster(global_cluster) irr
preserve
use `results',clear
replace est2 = el(r(table),1,1) if model==5
replace lb2 = el(r(table),5,1) if model==5
replace ub2 = el(r(table),6,1) if model==5
save `results',replace
restore
poisson ev_u5 u5_sibs i.surveynum i.age [pw = weight],cluster(global_cluster) irr
preserve
use `results',clear
replace est3 = el(r(table),1,1) if model==5
replace lb3 = el(r(table),5,1) if model==5
replace ub3 = el(r(table),6,1) if model==5
save `results',replace
restore	
poisson ev_u5 u5_sibs numsibs i.surveynum##i.agecat i.age [pw = weight],cluster(global_cluster) irr
preserve
use `results',clear
replace est4 = el(r(table),1,1) if model==5
replace lb4 = el(r(table),5,1) if model==5
replace ub4 = el(r(table),6,1) if model==5
save `results',replace
restore	

*Birth-level results
use "data/birth_analysis.dta",clear
gen anyu5_sibs = (u5_sibs > 0)
gen agecat = floor(age/5)*5

*adjust sampling weights
bysort surveycode: egen weight = pc(smpwt),prop
bysort surveycode: egen n_svy = count(smpwt)
replace weight = n_svy*weight

logistic u5 anyu5_sibs i.surveynum [pw = weight],cluster(global_cluster)
preserve
use `results',clear
replace est1 = el(r(table),1,1) if model==3
replace lb1 = el(r(table),5,1) if model==3
replace ub1 = el(r(table),6,1) if model==3
save `results',replace
restore
logistic u5 anyu5_sibs i.surveynum##i.agecat [pw = weight],cluster(global_cluster)
preserve
use `results',clear
replace est2 = el(r(table),1,1) if model==3
replace lb2 = el(r(table),5,1) if model==3
replace ub2 = el(r(table),6,1) if model==3
save `results',replace
restore
logistic u5 anyu5_sibs numsibs i.surveynum [pw = weight],cluster(global_cluster)
preserve
use `results',clear
replace est3 = el(r(table),1,1) if model==3
replace lb3 = el(r(table),5,1) if model==3
replace ub3 = el(r(table),6,1) if model==3
save `results',replace
restore
logistic u5 anyu5_sibs numsibs i.surveynum##i.agecat [pw = weight],cluster(global_cluster)
preserve
use `results',clear
replace est4 = el(r(table),1,1) if model==3
replace lb4 = el(r(table),5,1) if model==3
replace ub4 = el(r(table),6,1) if model==3
save `results',replace
restore

logistic u5 u5_sibs i.surveynum [pw = weight],cluster(global_cluster)
preserve
use `results',clear
replace est1 = el(r(table),1,1) if model==6
replace lb1 = el(r(table),5,1) if model==6
replace ub1 = el(r(table),6,1) if model==6
save `results',replace
restore
logistic u5 u5_sibs i.surveynum##i.agecat [pw = weight],cluster(global_cluster)
preserve
use `results',clear
replace est2 = el(r(table),1,1) if model==6
replace lb2 = el(r(table),5,1) if model==6
replace ub2 = el(r(table),6,1) if model==6
save `results',replace
restore
logistic u5 u5_sibs numsibs i.surveynum [pw = weight],cluster(global_cluster)
preserve
use `results',clear
replace est3 = el(r(table),1,1) if model==6
replace lb3 = el(r(table),5,1) if model==6
replace ub3 = el(r(table),6,1) if model==6
save `results',replace
restore
logistic u5 u5_sibs numsibs i.surveynum##i.agecat [pw = weight],cluster(global_cluster)
preserve
use `results',clear
replace est4 = el(r(table),1,1) if model==6
replace lb4 = el(r(table),5,1) if model==6
replace ub4 = el(r(table),6,1) if model==6
save `results',replace
restore

*Graph results
use `results',clear
save results
use results,clear
//generate new variables for x axis
forvalues v=1/4 {
  gen variant`v' = `v'
  }
//label models
label define model_lbl 1 `" "Woman-level logit:" "any child death on any sib deaths" "' ///
                       2 `" "Woman-level Poisson:" "# child deaths on any sib deaths" "' ///
                       3 `" "Birth-level logit:" "child death on any sib deaths" "' ///
				       4 `" "Woman-level logit:" "any child death on # sib deaths" "' ///
                       5 `" "Woman-level Poisson:" "# child deaths on # sib deaths" "' ///
                       6 `" "Birth-level logit:" "child death on # sib deaths" "'
label values model model_lbl
//graph  
twoway (scatter est1 variant1,mcolor(black*.33) msymbol(o)) ///
       (rspike ub1 lb1 variant1,lcolor(black)) ///
	   (scatter est2 variant2,mcolor(gs10*.33) msymbol(s)) ///
       (rspike ub2 lb2 variant2,lcolor(gs10)) ///
	   (scatter est3 variant3,mcolor(turquoise*.33) msymbol(t)) ///
       (rspike ub3 lb3 variant3,lcolor(turquoise)) ///
	   (scatter est4 variant4,mcolor(vermillion*.33) msymbol(d)) ///
       (rspike ub4 lb4 variant4,lcolor(vermillion)) ///
	   ,legend(order (- "Model:" 1 "w/o sibs ever born" 3 "w/ sibs + survey*age group" ///
	                  5 "w/ sibs" 7 "w/ sibs + survey*age group") rows(1)) ///
		ytitle("Exponentiated coefficient",size(small)) ylabel(,labsize(medsmall)) ///
		xtick(1 2 3 4,grid) xlabel(none) ///
		by(model,note("")) subtitle(,nobox) scheme(plotplain) 
graph export "output/surveyXagegroup.pdf",replace
erase results.dta

************
* Figure A.6: Monte Carlo Simulations of Measurement Error
************

set seed 124262349
*Mother-level regressions		
use "data/mom_analysis.dta",clear
gen anyu5_sibs = (u5_sibs > 0)
gen anyu5 = (ev_u5 > 0)
*adjust sampling weights
cap drop weight
bysort surveycode: egen weight = pc(smpwt),prop
bysort surveycode: egen n_svy = count(smpwt)
replace weight = n_svy*weight
*initialize probabilities
gen p = (_n-1) if _n<=26
*any-any regression
logistic anyu5 anyu5_sibs i.surveynum i.age [pw = weight],cluster(global_cluster)	
gen or_anyany = el(r(table),1,1) if p==0
logistic anyu5 anyu5_sibs numsibs i.surveynum i.age [pw = weight],cluster(global_cluster)	
gen or_anyany_ctrl = el(r(table),1,1) if p==0
*num-any regression
poisson ev_u5 anyu5_sibs i.surveynum i.age [pw = weight],cluster(global_cluster) irr	
gen irr_numany = el(r(table),1,1) if p==0
poisson ev_u5 anyu5_sibs numsibs i.surveynum i.age [pw = weight],cluster(global_cluster) irr	
gen irr_numany_ctrl = el(r(table),1,1) if p==0
*any-num regression
logistic anyu5 u5_sibs i.surveynum i.age [pw = weight],cluster(global_cluster)	
gen or_anynum = el(r(table),1,1) if p==0
logistic anyu5 u5_sibs numsibs i.surveynum i.age [pw = weight],cluster(global_cluster)	
gen or_anynum_ctrl = el(r(table),1,1) if p==0
*num-num regression
poisson ev_u5 u5_sibs i.surveynum i.age [pw = weight],cluster(global_cluster) irr	
gen irr_numnum = el(r(table),1,1) if p==0
poisson ev_u5 u5_sibs numsibs i.surveynum i.age [pw = weight],cluster(global_cluster) irr	
gen irr_numnum_ctrl = el(r(table),1,1) if p==0
*loop through p = .01 to .20, 100 simulations for each increment
local sim = 50 //number of simulations
forvalues p = 5(5)25 {
  local anyany = 0
  local anyany_ctrl = 0
  local numany = 0
  local numany_ctrl = 0
  local anynum = 0
  local anynum_ctrl = 0
  local numnum = 0
  local numnum_ctrl = 0
  forvalues i=1/`sim' {
    preserve
    *simulate reporting errors
	local probability = .01*`p'
    gen forget = rbinomial(u5_sibs,`probability')
	replace forget = 0 if forget==.
	replace u5_sibs = u5_sibs-forget
	replace anyu5_sibs = (u5_sibs > 0)
	replace numsibs = numsibs-forget
	drop if numsibs==0	
    *adjust sampling weights
    cap drop weight n_svy
    bysort surveycode: egen weight = pc(smpwt),prop
	bysort surveycode: egen n_svy = count(smpwt)
	replace weight = n_svy*weight
	*regressions
    logistic anyu5 anyu5_sibs i.surveynum i.age [pw = weight],cluster(global_cluster)	
	local anyany = `anyany'+el(r(table),1,1)
    logistic anyu5 anyu5_sibs numsibs i.surveynum i.age [pw = weight],cluster(global_cluster)	
	local anyany_ctrl = `anyany_ctrl'+el(r(table),1,1)
	poisson ev_u5 anyu5_sibs i.surveynum i.age [pw = weight],cluster(global_cluster) irr	
    local numany = `numany'+el(r(table),1,1)
	poisson ev_u5 anyu5_sibs numsibs i.surveynum i.age [pw = weight],cluster(global_cluster) irr	
    local numany_ctrl = `numany_ctrl'+el(r(table),1,1)
    logistic anyu5 u5_sibs i.surveynum i.age [pw = weight],cluster(global_cluster)	
	local anynum = `anynum'+el(r(table),1,1)
    logistic anyu5 u5_sibs numsibs i.surveynum i.age [pw = weight],cluster(global_cluster)	
	local anynum_ctrl = `anynum_ctrl'+el(r(table),1,1)
	poisson ev_u5 u5_sibs i.surveynum i.age [pw = weight],cluster(global_cluster) irr	
    local numnum = `numnum'+el(r(table),1,1)
	poisson ev_u5 u5_sibs numsibs i.surveynum i.age [pw = weight],cluster(global_cluster) irr	
    local numnum_ctrl = `numnum_ctrl'+el(r(table),1,1)
	restore
	}
  replace or_anyany = `anyany'/`sim' if p==`p'
  replace or_anyany_ctrl = `anyany_ctrl'/`sim' if p==`p'
  replace irr_numany = `numany'/`sim' if p==`p'
  replace irr_numany_ctrl = `numany_ctrl'/`sim' if p==`p'
  replace or_anynum = `anynum'/`sim' if p==`p'
  replace or_anynum_ctrl = `anynum_ctrl'/`sim' if p==`p'
  replace irr_numnum = `numnum'/`sim' if p==`p'
  replace irr_numnum_ctrl = `numnum_ctrl'/`sim' if p==`p'
  }
replace p = p/100
keep if or_anyany<.
keep p or* irr*
save "data/simulation.dta",replace
		
*Birth-level regressions
use "data/birth_analysis.dta",clear
gen anyu5_sibs = (u5_sibs > 0)
*adjust sampling weights
cap drop weight
bysort surveycode: egen weight = pc(smpwt),prop
bysort surveycode: egen n_svy = count(smpwt)
replace weight = n_svy*weight
*initialize probabilities
gen p = (_n-1) if _n<=26
*birth-any regression
logistic u5 anyu5_sibs i.surveynum [pw = weight],cluster(global_cluster)
gen or_birthany = el(r(table),1,1) if p==0
logistic u5 anyu5_sibs numsibs i.surveynum [pw = weight],cluster(global_cluster)
gen or_birthany_ctrl = el(r(table),1,1) if p==0
*birth-num regression
logistic u5 u5_sibs i.surveynum [pw = weight],cluster(global_cluster)
gen or_birthnum = el(r(table),1,1) if p==0
logistic u5 u5_sibs numsibs i.surveynum [pw = weight],cluster(global_cluster)
gen or_birthnum_ctrl = el(r(table),1,1) if p==0
*loop through p = .01 to .25, 50 simulations for each increment
local sim = 50 //number of simulations
forvalues p = 5(5)25 {
  local birthany = 0
  local birthany_ctrl = 0
  local birthnum = 0
  local birthnum_ctrl = 0
  forvalues i=1/`sim' {
    preserve
    *simulate reporting errors
	local probability = .01*`p'
    gen forget = rbinomial(u5_sibs,`probability')
	replace forget = 0 if forget==.
	replace u5_sibs = u5_sibs-forget
	replace anyu5_sibs = (u5_sibs > 0)
	replace numsibs = numsibs-forget
	drop if numsibs==0
    *adjust sampling weights
    cap drop weight n_svy
    bysort surveycode: egen weight = pc(smpwt),prop
	bysort surveycode: egen n_svy = count(smpwt)
	replace weight = n_svy*weight
	*regression
    logistic u5 anyu5_sibs i.surveynum [pw = weight],cluster(global_cluster)
    local birthany = `birthany'+el(r(table),1,1)
    logistic u5 anyu5_sibs numsibs i.surveynum [pw = weight],cluster(global_cluster)
    local birthany_ctrl = `birthany_ctrl'+el(r(table),1,1)
    *birth-num regression
    logistic u5 u5_sibs i.surveynum [pw = weight],cluster(global_cluster)
    local birthnum = `birthnum'+el(r(table),1,1)
    logistic u5 u5_sibs numsibs i.surveynum [pw = weight],cluster(global_cluster)
    local birthnum_ctrl = `birthnum_ctrl'+el(r(table),1,1)
	restore
	}
  replace or_birthany = `birthany'/`sim' if p==`p'
  replace or_birthany_ctrl = `birthany_ctrl'/`sim' if p==`p'
  replace or_birthnum = `birthnum'/`sim' if p==`p'
  replace or_birthnum_ctrl = `birthnum_ctrl'/`sim' if p==`p'
  }
replace p = p/100  
keep if or_birthany<.
keep p or*
merge 1:1 p using "data/simulation.dta"
drop _merge
save "data/simulation.dta",replace

//graph all together
use "data/simulation.dta",clear

twoway (connected or_birthany p) ///
       (connected or_birthany_ctrl p) ///
       ,scheme(plotplainblind) name(birthany,replace) ///
	    legend(rows(1) order(- "Includes sibs ever born?" 1 "No" 2 "Yes")) ///
		subtitle("Birth-level logit:" "child death on any sib death") xtitle("") ytitle("") ///
		ylabel(,labsize(medium)) xlabel(,labsize(medium)) 
		
twoway (connected or_birthnum p) ///
       (connected or_birthnum_ctrl p) ///
       ,scheme(plotplainblind) name(birthnum,replace) ///
	    legend(rows(1) order(- "Includes sibs ever born?" 1 "No" 2 "Yes")) ///
		subtitle("Birth-level logit:" "child death on # sib deaths") xtitle("") ytitle("") ///
		ylabel(,labsize(medium)) xlabel(,labsize(medium))  
		
twoway (connected or_anyany p) ///
       (connected or_anyany_ctrl p) ///
       ,scheme(plotplainblind) name(anyany,replace) ///
	    legend(rows(1) order(- "Includes sibs ever born?" 1 "No" 2 "Yes")) ///
		subtitle("Woman-level logit:" "any child death on any sib death") xtitle("") ytitle("") ///
		ylabel(,labsize(medium)) xlabel(,labsize(medium)) 
		
twoway (connected or_anynum p) ///
       (connected or_anynum_ctrl p) ///
       ,scheme(plotplainblind) name(anynum,replace) ///
	    legend(rows(1) order(- "Includes sibs ever born?" 1 "No" 2 "Yes")) ///
		subtitle("Woman-level logit:" "any child death on # sib deaths") xtitle("") ytitle("") ///
		ylabel(,labsize(medium)) xlabel(,labsize(medium)) 	
		
twoway (connected irr_numany p) ///
       (connected irr_numany_ctrl p) ///
       ,scheme(plotplainblind) name(numany,replace) ///
	    legend(rows(1) order(- "Includes sibs ever born?" 1 "No" 2 "Yes")) ///
		subtitle("Woman-level Poisson:" "# child deaths on any sib death") xtitle("") ytitle("") ///
		ylabel(,labsize(medium)) xlabel(,labsize(medium)) 
		
twoway (connected irr_numnum p) ///
       (connected irr_numnum_ctrl p) ///
       ,scheme(plotplainblind) name(numnum,replace) ///
	    legend(rows(1) order(- "Includes sibs ever born?" 1 "No" 2 "Yes")) ///
		subtitle("Woman-level Poisson:" "# child deaths on # sib deaths") xtitle("") ytitle("") ///
		ylabel(,labsize(medium)) xlabel(,labsize(medium)) 
		
grc1leg	anyany numany birthany anynum numnum birthnum ///
        ,rows(2) ycommon ring(1) ///
		l1("Mean exponentiated coefficient",size(small)) ///
		b1("Probability of omitting deceased sibling",size(small))
		
graph export "output/simulation.pdf",replace			

//look at main odds ratios of interest
list p or_anyany or_birthnum_ctrl

//compare p=.25 with p=0
keep if p==0|p==.25
sort p
foreach var of varlist or* irr* {
  replace `var' = (`var'[_n+1]-`var')
  }
keep if p==0
list or* irr*	
		

************
* Figure A.7:  Mortality Persistence by Country
************
use "data/birth_analysis.dta",clear

//adjust sampling weights
bysort surveycode: egen weight = pc(smpwt),prop
bysort surveycode: egen n_svy = count(smpwt)
replace weight = n_svy*weight
svyset[pw=weight]

replace country = "DRC" if country=="Democratic Republic of the Congo"
replace country = "CAR" if country=="Central African Republic"
egen countrynum = group(country)
gen or = .
gen lb = .
gen ub = .
forvalues i=1/44 {
  logistic u5 u5_sibs numsibs i.surveynum [pw = weight] if countrynum==`i',cluster(global_cluster)
  replace or = el(r(table),1,1) if countrynum==`i'
  replace lb = el(r(table),5,1) if countrynum==`i'
  replace ub = el(r(table),6,1) if countrynum==`i'
  }
bysort countrynum: keep if _n==1
sort or
gen country_order = _n
labmask country_order,values(country)
twoway (scatter country_order or,mcolor(black) msymbol(o)) ///
	   (rspike lb ub country_order,lcolor(black) horizontal) ///
	   ,legend(off) aspect(2) xline(1) scheme(s1mono) ///
	    ytitle("") xtitle("Odds ratio",size(vsmall)) ///
		xlabel(,labsize(vsmall)) ///
		ylabel(1(1)44,valuelabel angle(0) grid gstyle(dot) labsize(vsmall))
graph export "output/dot_whiskers.pdf",replace

*****
* Figure A.8: Absolute Versus Proportional Mortality Persistence for a Binary Risk Factor
*****	
clear all
set obs 104

gen m = .05 if _n<=1/4*_N
replace m = .1 if _n<=1/2*_N & m==.
replace m = .15 if _n<=3/4*_N & m==.
replace m = .2 if m==.

gen or = 1 + mod(_n-1,26)*.01
gen m1 = (or*m/(1-m))/(or*m/(1-m) + 1) //since m = odds/(odds+1)
gen me = m1-m

list

twoway (line me or if _n<=1/4*_N,lpattern(solid) lwidth(medthick)) ///
       (line me or if _n<=1/2*_N & _n>1/4*_N,lpattern(solid) lwidth(medthick)) ///
	   (line me or if _n<=3/4*_N & _n>1/2*_N,lpattern(solid) lwidth(medthick)) ///
	   (line me or if _n>3/4*_N,lpattern(solid) lwidth(medthick)) ///
	   (pcarrowi .0156863 1.1 .0137 1.0935,color(black) barbsize(1)) ///
	   (pcarrowi .0156863 1.1 .0132 1.1,color(black) barbsize(1)) ///
	   (pcarrowi .0156863 1.1 .0137 1.1065,color(black) barbsize(1)) ///
	   (pcarrowi .0156863 1.1 .0146 1.1125,color(black) barbsize(1)) ///
	   (pcarrowi .0156863 1.1 .0156863 1.1145,color(black) barbsize(1)) ///
	   (pcarrowi .0156863 1.1 .0167 1.1125,color(black) barbsize(1)) ///
	   ,scheme(plotplainblind) legend(off) aspect(1) ///
	    ylabel(,labsize(medium)) xlabel(,labsize(medium)) ///
		ytitle("Marginal effect") xtitle("Odds ratio") ///
	    text(.0094059 1.2 ".05",color(black) place(se)) ///
	    text(.0176471 1.2 ".1",color(gs10) place(se)) ///
	    text(.0247573 1.2 ".15",color(sky) place(se)) ///
	    text(.0307692 1.2 "Baseline risk = .2",color(turquoise) place(nw)) ///
		text(.0156863 1.1 "Mortality decline" "trajectories",color(black) place(nw) just(right))
graph export "output/me_vs_or.pdf",replace

*****
* Figure A.9: Under-5 Mortality Rate over Time, by Country
*****		
use "data/country_cohort",clear 
replace country = "DRC" if country=="Democratic Republic of the Congo" //to make more compact
replace country = "CAR" if country=="Central African Republic" //to make more compact
replace country = "Sao Tome" if country=="Sao Tome and Principe" //to make more compact
twoway connected q5 midperiod, ///
       scheme(s1mono) by(country,rows(4) note("") compact) legend(off) ///
	   xtitle("Period",size(small)) ytitle("Under-5 Mortality Rate (UN)",size(small)) ///
	   ylabel(0(.1).5,labsize(medlarge) grid gstyle(dot)) ///
	   xlabel(,angle(90) labsize(medlarge) grid gstyle(dot))
graph export "output/q5_series.pdf",replace

*****	
* Figure A.10: Semi-Parametric Panel Analyses
*****
use "data/country_cohort",clear 
drop if (country=="Rwanda"&midperiod==1993) // drop genocide period 
gen x = _n-1 if _n<=6
gen coef = 0 if x==0
gen lb = .
gen ub = .
reg or i.q5_cat i.midperiod i.countrynum,cluster(countrynum)	
forvalues i=1/5 {
  replace coef = _b[`i'.q5_cat] if x==`i'
  replace lb = _b[`i'.q5_cat] - 1.96*_se[`i'.q5_cat] if x==`i'
  replace ub = _b[`i'.q5_cat] + 1.96*_se[`i'.q5_cat] if x==`i'
  }
twoway (connected coef x,color(black) msymbol(O)) ///
       (rspike lb ub x,lcolor(black)) ///
	   ,plotregion(lstyle(none)) fxsize(67) graphregion(margin(tiny)) ///
	    legend(off) name(or,replace) ///
	    subtitle("A. Odds ratio",ring(0) box fcolor(none)) ///
	    ytitle("OR") xtitle("") ///
		yline(0,lpattern(solid) lcolor(gs10)) ///
	    xlabel(0 "< .075" 1 ".075-.1" 2 ".1-.15" 3 ".15-.2" 4 ".2-.25" 5 "> .25")

reg marg i.q5_cat i.midperiod i.countrynum,cluster(countrynum)	
forvalues i=1/5 {
  replace coef = _b[`i'.q5_cat] if x==`i'
  replace lb = _b[`i'.q5_cat] - 1.96*_se[`i'.q5_cat] if x==`i'
  replace ub = _b[`i'.q5_cat] + 1.96*_se[`i'.q5_cat] if x==`i'
  }
twoway (connected coef x,color(black) msymbol(O)) ///
       (rspike lb ub x,lcolor(black)) ///
	   ,plotregion(lstyle(none)) fxsize(67) graphregion(margin(tiny)) ///
	    legend(off) name(marg,replace) ///
	    subtitle("B. Average marginal effect",ring(0) box fcolor(none)) ///
	    ytitle("AME") xtitle("") ///
		yline(0,lpattern(solid) lcolor(gs10)) ///
	    xlabel(0 "< .075" 1 ".075-.1" 2 ".1-.15" 3 ".15-.2" 4 ".2-.25" 5 "> .25")
graph combine or marg,rows(2) b1("        Under-5 mortality rate",size(small)) imargin(0 0)
graph export "output/semiparametric_cells.pdf",replace

*****
* Figure A.11: Leave-One-Out Panel Analyses
*****
use "data/country_cohort",clear 
drop if (country=="Rwanda"&midperiod==1993) // drop genocide period 
gen coef_or = .
gen lb_or = .
gen ub_or = .
gen coef_marg = .
gen lb_marg = .
gen ub_marg = .
forvalues i=1/44 {
  qui reg or q5 i.midperiod i.countrynum if countrynum!=`i',cluster(countrynum)
  qui replace coef_or = _b[q5] if countrynum==`i'
  qui replace lb_or = _b[q5]-1.96*_se[q5] if countrynum==`i'
  qui replace ub_or = _b[q5]+1.96*_se[q5] if countrynum==`i'
  qui reg marg q5 i.midperiod i.countrynum if countrynum!=`i',cluster(countrynum)
  qui replace coef_marg = _b[q5] if countrynum==`i'
  qui replace lb_marg = _b[q5]-1.96*_se[q5] if countrynum==`i'
  qui replace ub_marg = _b[q5]+1.96*_se[q5] if countrynum==`i'
  }
bysort countrynum: keep if _n==1
twoway (rspike ub_or lb_or countrynum,horizontal) ///
       (scatter countrynum coef_or,msymbol(o) mcolor(black)) ///
	   ,ylabel(1(1)44,valuelabel labsize(small) angle(0) grid gstyle(dot) nogmin) yscale(reverse alt) ///
	    xlabel(,labsize(small)) xline(0,lcolor(black)) ///
		ytitle("") xtitle("Coefficient on U5 mortality",size(small)) ///
		subtitle("Dependent variable: OR",size(small)) ///
		legend(off) name(or,replace) graphregion(margin(tiny) color(none)) scheme(s1mono)
twoway (rspike ub_marg lb_marg countrynum,horizontal) ///
       (scatter countrynum coef_marg,msymbol(o) mcolor(black)) ///
	   ,ylabel(1(1)44,valuelabel labsize(small) angle(0) grid gstyle(dot) nogmin) yscale(reverse) ///
	    xlabel(,labsize(small)) xline(0,lcolor(black)) ///
		ytitle("") xtitle("Coefficient on U5 mortality",size(small)) ///
		subtitle("Dependent variable: AME",size(small)) ///
		legend(off) name(marg,replace) graphregion(margin(tiny) color(none)) scheme(s1mono)
graph combine or marg,imargin(0 0) rows(1)
graph export "output/leave_one_out.pdf",replace

