***************
* Process intermediate data for analysis 
***************

set more off
clear all
eststo clear
clear matrix
set maxvar 10000
set matsize 10000
*Set root:


*open master raw dataset
use data/intermediatedat,clear

*count number of surveys - 119
*codebook surveycode

*missing values for on sibling survival status - quite rare
d miss*
sum miss*
*how many have any sibling survival info missing? less than .5% of sample.
gen any_miss = 0
foreach var of varlist miss* {
  replace any_miss = 1 if `var'==1
  }
tab any_miss

*unknown year of birth (kids and sibs) - quite rare
d *dk
sum *dk
*how many have dk yob? "approximately zero"
gen any_dk = 0
foreach var of varlist *dk {
  replace any_dk = 1 if `var'==1
  }
tab any_dk

*drop missing survival and yob
drop if any_miss==1|any_dk==1
drop any_miss miss* *dk

*cumulative mortality variables
gen evdied = evdied_m+evdied_f
gen ev_u1 = 0
gen ev_u5 = 0

foreach var of varlist ch_agedeath* {
  replace ev_u1 = ev_u1 + (`var'<12)
  replace ev_u5 = ev_u5 + (`var'<60)
  }
 
gen ev_u1_m = 0
gen ev_u5_m = 0
gen ev_u1_f = 0
gen ev_u5_f = 0
foreach i of num 1/24 {
  replace ev_u1_m = ev_u1_m + (ch_agedeath_`i'<12 & ch_male_`i' == 1) 
  replace ev_u5_m = ev_u5_m + (ch_agedeath_`i'<60 & ch_male_`i' == 1)
  replace ev_u1_f = ev_u1_f + (ch_agedeath_`i'<12 & ch_male_`i' == 0) 
  replace ev_u5_f = ev_u5_f + (ch_agedeath_`i'<60 & ch_male_`i' == 0)
  } 
  
  
egen u1_sibs = rowtotal(u1*)
egen u5_sibs = rowtotal(u5*)

egen u1_msibs = rowtotal(u1_msibs*)
egen u5_msibs = rowtotal(u5_msibs*)

egen u1_fsibs = rowtotal(u1_fsibs*)
egen u5_fsibs = rowtotal(u5_fsibs*)

*alt sibs count
*this should be the same as numsibs, and it is extremely close
gen numsibs_alt = msibs_o+msibs_tw+msibs_y+fsibs_o+fsibs_tw+fsibs_y
reg numsibs_alt numsibs
tab numsibs_alt numsibs,col nofreq

*alt birth order - number older sibs + 1
*this should be the same as b_order, but it is a little different
gen b_order_alt = msibs_o+fsibs_o+1
reg b_order_alt b_order
tab b_order_alt b_order,col nofreq

*use the counts based on the roster, not the numbers reported
*by the respondent before the detailed roster
replace numsibs = numsibs_alt
replace b_order = b_order_alt
drop *_alt


*younger sibling counts
gen numsibs_y = msibs_y+fsibs_y
gen u1_sibs_y = u1_msibs_y+u1_fsibs_y
gen u5_sibs_y = u5_msibs_y+u5_fsibs_y

*older sibling counts
gen numsibs_o = msibs_o+fsibs_o
gen u1_sibs_o = u1_msibs_o+u1_fsibs_o
gen u5_sibs_o = u5_msibs_o+u5_fsibs_o

*sibling counts by gender
egen msibs = rowtotal(msibs_*)
egen fsibs = rowtotal(fsibs_*)

*marriage age
gen agemar_u20 = (agemar < 20) if !missing(agemar)
replace agemar_u20 = 0 if nevermar == 1

//region codes
gen africa= 0
gen lac = 0
gen asia = 0

replace asia = 1 if country=="Afghanistan"
replace asia = 1 if country=="Bangladesh"
replace africa = 1 if country=="Benin"
replace lac = 1 if country=="Bolivia"
replace africa = 1 if country=="Burkina Faso"
replace africa = 1 if country=="Burundi"
replace asia = 1 if country=="Cambodia"
replace africa = 1 if country=="Cameroon"
replace africa = 1 if country=="Central African Republic"
replace africa = 1 if country=="Chad"
replace africa = 1 if country=="Congo"
replace africa = 1 if country=="Côte d'Ivoire"
replace africa = 1 if country=="Democratic Republic of the Congo"
replace lac = 1 if country=="Dominican Republic"
replace africa = 1 if country=="Eswanti"|country=="Eswatini"
replace africa = 1 if country=="Ethiopia"
replace africa = 1 if country=="Gabon"
replace africa = 1 if country=="Ghana"
replace africa = 1 if country=="Guinea"
replace lac = 1 if country=="Haiti"
replace asia = 1 if country=="Indonesia"
replace africa = 1 if country=="Jordan"
replace africa = 1 if country=="Kenya"
replace africa = 1 if country=="Lesotho"
replace africa = 1 if country=="Madagascar"
replace africa = 1 if country=="Malawi"
replace africa = 1 if country=="Mali"
replace africa = 1 if country=="Morocco"
replace africa = 1 if country=="Mozambique"
replace africa = 1 if country=="Namibia"
replace asia = 1 if country=="Nepal"
replace africa = 1 if country=="Niger"
replace africa = 1 if country=="Nigeria"
replace lac = 1 if country=="Peru"
replace asia = 1 if country=="Philippines"
replace africa = 1 if country=="Rwanda"
replace africa = 1 if country=="Sao Tome and Principe"
replace africa = 1 if country=="Senegal"
replace africa = 1 if country=="Sierra Leone"
replace africa = 1 if country=="South Africa"
replace africa = 1 if country=="Tanzania"
replace africa = 1 if country=="Togo"
replace africa = 1 if country=="Zambia"
replace africa = 1 if country=="Zimbabwe"

*save mother-level dataset
preserve
gen midperiod = floor(yob/5)*5+3
keep  surveycode country caseid smpwt year cluster hhnumber respid momid africa asia lac ///
      rural nonmigrant child_rur yob midperiod age ///
      edyrs height bmi agemar agemar_u20 nevermar husb_edyrs husb_age ///
	  evborn evborn_m evborn_f ///
	  ev_u1 ev_u5  ev_u1_m ev_u5_m ev_u1_f ev_u5_f ///
	  evdied evdied_m evdied_f ///
	  numsibs numsibs_y numsibs_o msibs msibs_o msibs_y fsibs fsibs_o fsibs_y b_order ///
	  u1_sibs u5_sibs u1_sibs_y u1_sibs_o u5_sibs_y u5_sibs_o ///
	  u1_msibs u5_msibs u1_msibs_y u1_msibs_o u5_msibs_y u5_msibs_o ///
	  u1_fsibs u5_fsibs u1_fsibs_y u1_fsibs_o u5_fsibs_y u5_fsibs_o ///
	  asset* water toilet electricity radio tele fridge bike moto car floor wall roof

order surveycode country caseid smpwt year cluster hhnumber respid momid rural child_rur yob midperiod age ///
      edyrs height bmi agemar agemar_u20 nevermar husb_edyrs husb_age ///
	  numsibs numsibs_y numsibs_o msibs msibs_o msibs_y fsibs fsibs_o fsibs_y b_order ///
	  u1_sibs u5_sibs u1_sibs_y u1_sibs_o u5_sibs_y u5_sibs_o ///
	  u1_msibs u5_msibs u1_msibs_y u1_msibs_o u5_msibs_y u5_msibs_o ///
	  u1_fsibs u5_fsibs u1_fsibs_y u1_fsibs_o u5_fsibs_y u5_fsibs_o ///
	  evborn evborn_m evborn_f ///
	  evdied evdied_m evdied_f ///
	  ev_u1 ev_u5 ev_u1_m ev_u5_m ev_u1_f ev_u5_f ///
	  asset* water toilet electricity radio tele fridge bike moto car floor wall roof

save data/moms,replace

*read in under-5 mortality rates from UN, merge on MOTHER's birth period
insheet using data/aggregates/WPP2019_Period_Indicators_Medium.csv,clear
keep location midperiod tfr imr q5
keep if midperiod<2020 //drop projections
ren location country
replace country = "Bolivia" if country=="Bolivia (Plurinational State of)"
replace country = "Tanzania" if country=="United Republic of Tanzania"
merge m:m country midperiod using data/moms //should be 1:m but there are some duplicate world regions in the UN dataset
drop if _merge==1 //location-years that are not in the DHS dataset
drop _merge 
save data/moms,replace

*save birth-level dataset
restore
keep  surveycode country caseid smpwt year cluster hhnumber respid africa asia lac ///
      rural nonmigrant child_rur yob age ///
      edyrs height bmi agemar agemar_u20 nevermar husb_edyrs husb_age ///
	  evborn evborn_m evborn_f ///
	  ev_u1 ev_u5  ev_u1_m ev_u5_m ev_u1_f ev_u5_f ///
	  evdied evdied_m evdied_f ///
	  numsibs numsibs_y numsibs_o msibs msibs_o msibs_y fsibs fsibs_o fsibs_y b_order ///
	  u1_sibs u5_sibs u1_sibs_y u1_sibs_o u5_sibs_y u5_sibs_o ///
	  u1_msibs u5_msibs u1_msibs_y u1_msibs_o u5_msibs_y u5_msibs_o ///
	  u1_fsibs u5_fsibs u1_fsibs_y u1_fsibs_o u5_fsibs_y u5_fsibs_o ///
	  b_order ///
	  evborn evborn_m evborn_f ///
	  ch_* ///
	  asset* water toilet electricity radio tele fridge bike moto car floor wall roof

reshape long ch_bord_ ch_twin_ ch_mob_ ch_yob_ ch_agedeath_ ch_dead_ ch_male_ ch_age_,i(caseid) j(ch_num)
drop ch_num
foreach var in ch_bord ch_twin ch_mob ch_yob ch_agedeath ch_dead ch_male ch_age {
  rename `var'_ `var'
  }	  
keep if ch_twin<. //remove observations that do not correspond to births
replace ch_age = . if ch_age>90 //inconsistent, DK, missing
//create birth order variables for the datasets that did not have them
  tab surveycode if ch_bord==.
  gen ch_date = ch_yob+(ch_mob-1)/12 if ch_bord==.
  bysort caseid (ch_date): replace ch_bord = _n if ch_bord==.
  //bysort caseid (ch_date): replace ch_bord = ch_bord[_n-1] /// Frances Lu 8/21/2020: commented out b/c this is not how twins in other data are documented
  ///                         if (ch_date==ch_date[_n-1])&ch_date<.
  tab surveycode if ch_bord==.
  drop ch_date						   
//
gen midperiod = floor(ch_yob/5)*5+3 //for merging with UN pop data
keep  surveycode country caseid smpwt year cluster hhnumber respid rural nonmigrant child_rur yob age ///
      edyrs height bmi agemar agemar_u20 nevermar husb_edyrs husb_age ///
	  evdied evdied_m evdied_f ///
	  numsibs msibs fsibs ///
	  b_order ///
	  u1_sibs u5_sibs u1_msibs u5_msibs u1_fsibs u5_fsibs ///
	  evborn evborn_m evborn_f ///
	  ch_* midperiod ///
	  asset* water toilet electricity radio tele fridge bike moto car floor wall roof

order surveycode country caseid smpwt year midperiod cluster hhnumber respid rural nonmigrant child_rur yob age ///
      edyrs height bmi agemar agemar_u20 nevermar husb_edyrs husb_age ///
	  evdied evdied_m evdied_f ///
	  numsibs msibs fsibs ///
	  b_order ///
	  u1_sibs u5_sibs u1_msibs u5_msibs u1_fsibs u5_fsibs ///
	  evborn  evborn_m evborn_f ///
	  ch_* midperiod ///
	  asset* water toilet electricity radio tele fridge bike moto car floor wall roof

save data/births,replace

*****
* Merge in aggregates data on the CHILD's birth period
*****
*read in under-5 mortality rates from UN, merge on CHILD's birth period
insheet using data/aggregates/WPP2019_Period_Indicators_Medium.csv,clear
keep location midperiod tfr imr q5
keep if midperiod<2020 //drop projections
ren location country
replace country = "Bolivia" if country=="Bolivia (Plurinational State of)"
replace country = "Tanzania" if country=="United Republic of Tanzania"
merge m:m country midperiod using data/births //should be 1:m but there are some duplicate world regions in the UN dataset
drop if _merge==1 //location-years that are not in the DHS dataset
tab country if _merge==2 //these obs have missing birth year, leave them in for now
drop _merge 
save data/births,replace


*read in GDP per capita from PWT
use data/aggregates/pwt91.dta,clear
gen gdppc = cgdpe/pop
gen missing = (gdppc==.)
gen midperiod = floor(year/5)*5+3 //for merging
collapse gdppc missing,by(country midperiod)
drop if missing==1 //these cells have no gdppc data available
tab midperiod missing //these cells have 1-4 years with missing data
*drop if missing>0 //drop cells with any years missing. comment out to not.
gen lngdppc = ln(gdppc)
label var lngdppc "Log mean GDPpc"
drop missing gdppc
replace country = "Bolivia" if country=="Bolivia (Plurinational State of)"
replace country = "Tanzania" if country=="U.R. of Tanzania: Mainland"
replace country = "Democratic Republic of the Congo" if country=="D.R. of the Congo"
replace country = "Eswatini" if country=="Eswanti"
merge 1:m country midperiod using data/births
drop if _merge==1 //location-years that are not in the DHS dataset
drop _merge 
save data/births,replace



*read in war data
use "data/aggregates/ucdp_prio/ucdp-prio-acd-201.dta",clear
keep year intensity_level type_of_conflict location
d
//conflict-year level, so countries are grouped together
tab location
//split up locations into separate variables and reshape to country-year
split location,p(", ")
drop location
gen obs = _n
reshape long location,i(obs) j(num)
drop obs num
ren location country
//edit country names
replace country = "Cambodia" if country=="Cambodia (Kampuchea)"
replace country = "Côte d'Ivoire" if country=="Ivory Coast"
replace country = "Democratic Republic of the Congo" if country=="DR Congo (Zaire)"
replace country = "Madagascar" if country=="Madagascar (Malagasy)"
replace country = "Zimbabwe" if country=="Zimbabwe (Rhodesia)"
//generate conflict variables
gen conflict = 1
gen intrastate = 1 if type_of_conflict>2
gen war = 1 if intensity==2
//collapse to country/midperiod
gen midperiod = floor(year/5)*5+3
collapse (max) conflict intrastate war,by(country midperiod)
label var conflict "Any conflict (>=250d/yr)"
label var intrastate "Any intrastate conflict"
label var war "Any war (>=1000d/yr)"
//merge
merge 1:m country midperiod using data/births
drop if _merge==1 //location-years that are not in the DHS dataset
drop _merge 
foreach var of varlist conflict intrastate war {
  replace `var' = 0 if `var'==.
  }
save data/births,replace



