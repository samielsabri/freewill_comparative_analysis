/*Note: This program processes the Standard DHS format data. It does not
however, process the Nepal, Ethiopia, and Afghanistan 2015 datasets (which are 
in the Standard DHS format but they have different calendars) or Special DHS rounds. The exceptions 
 are integrated at the very end of this do file.*/

cd data/rawdhs

clear all
set maxvar 10000
cap log close

clear all
set more off


************
*Cleaning program 
************

cap program drop cleanup
program define cleanup

clear

******
* 1. Clean woman-level ID variables from the Individual Recode
*****
use `1'FL.DTA,clear

foreach var in ssect sstruct sqnumber sconces s026{
 capture confirm var `var'
 if _rc{
 gen `var'=.
  }
 }

keep b* v* mm* ssect sstruct sqnumber sconces s026

d v*
gen caseid = _n
label var caseid "person identifier"
ren v000 surveycode
ren v001 cluster
ren v002 hhnumber
ren v003 womanid
ren v005 smpwt
ren v007 year 
recode year (0=2000)(1=2001) if surveycode=="GA3"/*2000 is coded as 0 and 2001 is coded as 1 for GA3*/
replace year=year+1900 if year<=99 /*change to four digit years*/
ren v012 age
ren v010 yob
replace yob=yob+1900 if yob<=99 /*change to four digit years*/
ren v101 region
gen rural=v102-1
label var rural "rural residence"
egen residence = group(region rural)
gen child_rur = (v103==3) if v103<9
label var child_rur "rural residence in childhood"
gen nonmigrant = (v104 == 95) if (v104 != 96 & v104 < .)
label var nonmigrant "nonmigrant"


******
* 2. Clean asset index data (the cleaning depends on the DHS survey version; 3 cases)
******

***
*Case 1: Clean wealth index vars for women-level datasets that have it in the women-level file
***
if "`2'" == "NA" {
display "NA - in women-level file"
*The wealth index variables are missing from some datasets - generate placeholder variables 
 foreach var in v190 v191{
 capture confirm var `var'
 if _rc{
 gen `var'=.
  }
 }
ren v190 assetcat
label define aclab 1 "poorest" 2 "poorer" 3 "middle" 4 "rich" 5 "richer"
label value assetcat aclab
label var assetcat "household asset score quintile"
ren v191 assetindex
label var assetindex "household asset pca score"
} 

***
*Case 2: Generate wealth index vars for women-level datasets using PR files
***
if "`2'" == "CALC" {
display "CALC"

*Generate dummies for the member-level data that needs to be aggregated into the HH level data
gen domestic = 0
gen land = 0
gen house = 0

if "`1'" == "IDIR31" {

preserve 

*Collapse in potential data from the women dataset (domestic, land, house) to merge in the HH data
* Domestic
* No information in the household file 
* IR variable v717 // respondent occupation; no code for domestic worker so ignore
* No men's recode

* v740 //land where respondent works: own land; no men's recode to merge in
* s026 //ownership of building
replace land = 1 if (v740 == 0)
replace house = 1 if (s026 == 1)

collapse (max) domestic land house, by(surveycode cluster hhnumber)

tempfile aggdat
save `aggdat'

*No men's recode to merge in

*Use person recode data
use `3'FL.DTA,clear //read in the HH dataset

*Keep only one observation per HH
duplicates drop hhid, force


*Rename PR ID variables to match IR ID variable names
ren hv000 surveycode
ren hv001 cluster
ren hv002 hhnumber

*Merge in aggregated data
merge 1:1 surveycode cluster hhnumber using `aggdat'
drop if _merge ==2 
drop _merge

*All asset variables:hv201 hv206 hv207 hv208 hv209 hv210 hv211 hv212 hv213 hv214 hv215 sh17 sh19 sh20d sh20e sh20f sh23 sh26

*Recode binary variables (missing to zero; if 1-2 and not 0-1 recode)
foreach var in hv206 hv207 hv208 hv209 hv210 hv211 hv212 {
recode `var' (. = 0)
}

*Recode drinking water sources (combine surface water sources): not needed here

*Recode categorical variables (missing to zero; drop missing indicator)
foreach var in hv201 hv213 hv214 hv215 sh17 {
recode `var' (. = 0)
tabulate `var', generate(`var'_)
drop `var'_1 //this is an indicator for missing valuesdicator for missing values
}

*Calculate PCA index
pca hv206 hv207 hv208 hv209 hv210 hv211 hv212 hv201_* hv213_* hv214_* hv215_* sh17_* domestic land house
predict pc1, score
gen assetindex = pc1

*Calculate wealth quintile weighted by HHmember
gen HHMEMWT = hv012*hv005
replace HHMEMWT = hv013*hv005 if hv012 == 0
xtile assetcat = assetindex [fweight = HHMEMWT], n(5)

 
keep hhid surveycode cluster hhnumber assetindex assetcat

tempfile assetdat
save `assetdat'
restore

*Merge asset data with IR
merge m:1 surveycode cluster hhnumber using `assetdat'
drop if _merge ==2 // HHs who don't have women in IR
drop _merge
}

if "`1'" == "MDIR21" {
preserve

*Collapse in potential data from the women dataset (domestic, land, house) to merge in the HH data
* Domestic: no information in household file; no information in individual file  (v707)
* no housing variable
replace land = 1 if (v707 == 1)


collapse (max) domestic land house, by(surveycode cluster hhnumber)

tempfile aggdat
save `aggdat'

*Use person recode data
use `3'FL.DTA,clear //read in the HH dataset

*Rename PR ID variables to match IR ID variable names
ren hv000 surveycode
ren hv001 cluster
ren hv002 hhnumber


*Keep only one observation per HH
duplicates drop hhid, force

*Merge in aggregated data
merge 1:1 surveycode cluster hhnumber using `aggdat'
drop if _merge ==2 
drop _merge


*All asset variables: hv201 hv205 hv206 hv207 hv208 hv209 hv210 hv211 hv212 hv213 hv216 sh21a1 sh24a0

*Recode binary variables (missing to zero; if 1-2 and not 0-1 recode)
foreach var in  hv206 hv207 hv208 hv209 hv210 hv211 hv212 sh21a1 sh24a0{
recode `var' (. = 0)
}

*Recode drinking water sources (combine surface water sources)
recode hv201 (33 = 32) (34 = 32)

*Recode categorical variables (missing to zero; drop missing indicator)
foreach var in hv201 hv213 {
recode `var' (. = 0)
tabulate `var', generate(`var'_)
drop `var'_1 //this is an indicator for missing valuesdicator for missing values
}

*Number of members per sleeping room
* hv012 //number of de jure members
* hv013 //number of de facto members
* hv216 //number of sleeping rooms - recode to 1 if 0
gen memsleep = hv012/hv216 
egen memsleep_mean = mean(memsleep)
replace memsleep = memsleep_mean  if missing(memsleep) //missing values are replaced using mean imputation

*Calculate PCA
pca hv206 hv207 hv208 hv209 hv210 hv211 hv212 sh21a1 sh24a0 hv201_* hv213_* sh21a1 sh24a0 domestic land house memsleep
predict pc1, score
gen assetindex = pc1

*Calculate wealth quintile weighted by HHmember
gen HHMEMWT = hv012*hv005
replace HHMEMWT = hv013*hv005 if hv012 == 0
xtile assetcat = assetindex [fweight = HHMEMWT], n(5)

 
keep hhid surveycode cluster hhnumber assetindex assetcat

tempfile assetdat
save `assetdat'
restore

*Merge asset data with IR
merge m:1 surveycode cluster hhnumber using `assetdat'
drop if _merge ==2 // HHs who don't have women in IR
drop _merge 
}

if "`1'" == "MWIR22" {
preserve 

*Collapse in potential data from the women dataset (domestic, land, house) to merge in the HH data
* domestic: no info in HH file; respondent occupation; code 1 for domestic worker (v717 == 6) who is not related to HH head (v150 == 12)
* v707//land where respondent works: own land
replace domestic = 1 if (v717 == 6 & v150 == 12)
replace land = 1 if (v707 == 1)
collapse (max) domestic land house, by(surveycode cluster hhnumber)

tempfile aggdat
save `aggdat'

*Clean men's recode 
use MWMR21FL.DTA,clear
ren mv000 surveycode
ren mv001 cluster
ren mv002 hhnumber

gen domestic_m = 0
gen land_m = 0
gen house_m = 0
replace domestic_m = 1 if (mv717 == 6 & mv150 == 12)
replace land = 1 if (mv740 == 1)

collapse (max) domestic_m land_m house_m, by(surveycode cluster hhnumber)

tempfile aggdatm
save `aggdatm'

*Use person recode data
use `3'FL.DTA,clear //read in the HH dataset

*Rename PR ID variables to match IR ID variable names
ren hv000 surveycode
ren hv001 cluster
ren hv002 hhnumber


*Keep only one observation per HH
duplicates drop hhid, force

*Merge in aggregated data
merge 1:1 surveycode cluster hhnumber using `aggdat'
drop if _merge ==2 
drop _merge

merge 1:1 surveycode cluster hhnumber using `aggdatm'
drop if _merge ==2 
drop _merge

replace domestic = 1 if domestic_m == 1
replace land = 1 if land_m == 1
replace house = 1 if house_m == 1


*Asset variables: hv201 hv205 hv206 hv207 hv210 hv211 hv212 hv213 hv215 hv216 sh34c sh36d


*Recode binary variables (missing to zero; if 1-2 and not 0-1 recode)
foreach var in hv206 hv207 hv208 hv209 hv210 hv211 hv212 sh34c sh36d{
recode `var' (. = 0)
}

*Recode drinking water sources (combine surface water sources)
recode hv201 (34 = 32) (33 = 32)

*Recode categorical variables (missing to zero; drop missing indicator)
foreach var in hv201 hv213 hv215 {
recode `var' (. = 0)
tabulate `var', generate(`var'_)
drop `var'_1 //this is an indicator for missing valuesdicator for missing values
}

*Number of members per sleeping room
* hv012 //number of de jure members
* hv013 //number of de facto members
* hv216 //number of sleeping rooms - recode to 1 if 0
gen memsleep = hv012/hv216 
egen memsleep_mean = mean(memsleep)
replace memsleep = memsleep_mean  if missing(memsleep) //missing values are replaced using mean imputation

*Calculate PCA
pca hv206 hv207 hv208 hv209 hv210 hv211 hv212 sh34c sh36d hv201_* hv213_* hv215_* domestic land house memsleep
predict pc1, score
gen assetindex = pc1

*Calculate wealth quintile weighted by HHmember
gen HHMEMWT = hv012*hv005
replace HHMEMWT = hv013*hv005 if hv012 == 0
xtile assetcat = assetindex [fweight = HHMEMWT], n(5)

 
keep hhid surveycode cluster hhnumber assetindex assetcat

tempfile assetdat
save `assetdat'
restore

*Merge asset data with IR
merge m:1 surveycode cluster hhnumber using `assetdat'
drop if _merge ==2 // HHs who don't have women in IR
drop _merge
}

if "`1'" == "NIIR22" {
preserve 

*Collapse in potential data from the women dataset (domestic, land, house) to merge in the HH data
* Domestic
* No information in the household file  (NIHR22)
* IR variable v717 // respondent occupation
* No men's recode
replace domestic = 1 if (v717 == 6 & v150 == 12)

* v707 //land where respondent works: own land; no men's recode to merge in
replace land = 1 if (v707 == 0)

collapse (max) domestic land house, by(surveycode cluster hhnumber sstruct)

tempfile aggdat
save `aggdat'

*Use person recode data
use `3'FL.DTA,clear //read in the HH dataset

*Rename PR ID variables to match IR ID variable names
ren hv000 surveycode
ren hv001 cluster
ren hv002 hhnumber
ren shstruct sstruct


*Keep only one observation per HH
duplicates drop hhid, force

*Merge in aggregated data
merge 1:1 surveycode cluster hhnumber sstruct using `aggdat'
drop if _merge ==2 
drop _merge

*Asset variables: hv201 hv205 hv206 hv207 hv208 hv209 hv210 hv211 hv212 hv213 hv215 hv216

*Recode binary variables (missing to zero; if 1-2 and not 0-1 recode)
foreach var in hv206 hv207 hv208 hv209 hv210 hv211 hv212{
recode `var' (. = 0)
}

*Recode drinking water sources (combine surface water sources)
recode hv201 (34 = 32) (33 = 32)

*Recode categorical variables (missing to zero; drop missing indicator)
foreach var in hv201 hv205 hv213 hv215 {
recode `var' (. = 0)
tabulate `var', generate(`var'_)
drop `var'_1 //this is an indicator for missing valuesdicator for missing values
}

*Number of members per sleeping room
* hv012 //number of de jure members
* hv013 //number of de facto members
* hv216 //number of sleeping rooms - recode to 1 if 0
gen memsleep = hv012/hv216 
egen memsleep_mean = mean(memsleep)
replace memsleep = memsleep_mean  if missing(memsleep) //missing values are replaced using mean imputation

*Calculate PCA
pca hv206 hv207 hv208 hv209 hv210 hv211 hv212 hv201_* hv205_* hv213_* hv215_* domestic land house memsleep
predict pc1, score
gen assetindex = pc1

*Calculate wealth quintile weighted by HHmember
gen HHMEMWT = hv012*hv005
replace HHMEMWT = hv013*hv005 if hv012 == 0
xtile assetcat = assetindex [fweight = HHMEMWT], n(5)

 
keep hhid surveycode cluster hhnumber sstruct assetindex assetcat
tempfile assetdat
save `assetdat'
restore

*Merge asset data with IR
merge m:1 surveycode cluster hhnumber sstruct using `assetdat'
drop if _merge ==2 // HHs who don't have women in IR


*Combine household and structure ID so that IDs are consistent with other datasets
egen temp = group(hhnumber sstruct)
destring temp, replace
drop hhnumber
gen hhnumber = temp
drop temp sstruct


}


if "`1'" == "SNIR21" {
preserve

*Collapse in potential data from the women dataset (domestic, land, house) to merge in the HH data
* Domestic: no information in household file (SNHR21); no information in individual file  (v717)
* no housing variable
replace land = 1 if (v707 == 1)
collapse (max) domestic land house, by(surveycode cluster hhnumber)
tempfile aggdat
save `aggdat'

*Get same information from men's recode (SNMR21FL) // checked - there is no information in this file

*Use person recode data
use `3'FL.DTA,clear //read in the HH dataset

*Rename PR ID variables to match IR ID variable names
ren hv000 surveycode
ren hv001 cluster
ren hv002 hhnumber


*Keep only one observation per HH
duplicates drop hhid, force

*Merge in aggregated data
merge 1:1 surveycode cluster hhnumber using `aggdat'
drop if _merge ==2 
drop _merge

*Asset variables: hv201 hv205 hv206 hv207 hv208 hv209 hv210 hv211 hv212 hv213 hv216 sh22e

*Recode binary variables (missing to zero; if 1-2 and not 0-1 recode)
foreach var in hv206 hv207 hv208 hv209 hv210 hv211 hv212 sh22e{
recode `var' (. = 0)
}

*Recode drinking water sources (combine surface water sources)
recode hv201 (34 = 32) (33 = 32)

*Recode categorical variables (missing to zero; drop missing indicator)
foreach var in hv201 hv205 hv213 {
recode `var' (. = 0)
tabulate `var', generate(`var'_)
drop `var'_1 //this is an indicator for missing valuesdicator for missing values
}

*Number of members per sleeping room
* hv012 //number of de jure members
* hv013 //number of de facto members
* hv216 //number of sleeping rooms - recode to 1 if 0
gen memsleep = hv012/hv216 
egen memsleep_mean = mean(memsleep)
replace memsleep = memsleep_mean  if missing(memsleep) //missing values are replaced using mean imputation

*Calculate PCA
pca hv206 hv207 hv208 hv209 hv210 hv211 hv212 sh22e hv201_* hv205_* hv213_* domestic land house memsleep
predict pc1, score
gen assetindex = pc1

*Calculate wealth quintile weighted by HHmember
gen HHMEMWT = hv012*hv005
replace HHMEMWT = hv013*hv005 if hv012 == 0
xtile assetcat = assetindex [fweight = HHMEMWT], n(5)

 
keep hhid surveycode cluster hhnumber assetindex assetcat
tempfile assetdat
save `assetdat'
restore

*Merge asset data with IR
merge m:1 surveycode cluster hhnumber using `assetdat'
drop if _merge ==2 // HHs who don't have women in IR
drop _merge


}

}

***
*Case 3: Clean wealth index vars for datasets with separate weath data files
***
if "`2'" != "NA" & "`2'" != "CALC" {


*Get hhid variable from the person-recode files
preserve 
use `3'FL.DTA,clear

foreach var in shsec shstruct shnumber shconces{
 capture confirm var `var'
 if _rc{
 gen `var'= 0
  }
 }

ren hv000 surveycode
ren hv001 cluster
ren hv002 hhnumber
ren shsec ssect
ren shstruct sstruct
ren shnumber sqnumber
ren shconces sconces

gen temp = trim(hhid)
drop hhid
ren temp hhid

keep hhid surveycode cluster hhnumber ssect sstruct sqnumber sconces

duplicates drop
tempfile hhid
save `hhid'
restore 

if "`1'" != "BOIR31" & "`1'" != "CMIR31" & "`1'" != "TDIR31" & "`1'" != "MLIR32" & "`1'" != "MLIR41" & "`1'" != "TGIR31" {
merge m:1 surveycode cluster hhnumber using `hhid'
tab _merge
drop if _merge == 2
drop _merge ssect sstruct sqnumber sconces
}

if "`1'" == "BOIR31" {
merge m:1 surveycode cluster hhnumber ssect using `hhid'
tab _merge
drop if _merge == 2


*Combine hh and sect ID so that IDs are consistent with other datasets
egen temp = group(hhnumber ssect)
destring temp, replace
drop hhnumber
gen hhnumber = temp
drop temp

drop _merge ssect sstruct sqnumber sconces

}

if "`1'" == "CMIR31" | "`1'" == "TDIR31"  {
merge m:1 surveycode cluster hhnumber sstruct using `hhid'
tab _merge
drop if _merge == 2


*Combine hh and struct ID so that IDs are consistent with other datasets
egen temp = group(hhnumber sstruct)
destring temp, replace
drop hhnumber
gen hhnumber = temp
drop temp

drop _merge ssect sstruct sqnumber sconces
}


if "`1'" == "MLIR32" {
merge m:1 surveycode cluster hhnumber sqnumber using `hhid'
tab _merge
drop if _merge == 2

*Combine hh and sqnumber ID so that IDs are consistent with other datasets
egen temp = group(hhnumber sqnumber)
destring temp, replace
drop hhnumber
gen hhnumber = temp
drop temp

drop _merge ssect sstruct sqnumber sconces
}

if "`1'" == "MLIR41" | "`1'" == "TGIR31"{
merge m:1 surveycode cluster hhnumber sconces using `hhid'
tab _merge
drop if _merge == 2

if "`1'" == "TGIR31"{ // this is done later for the MLIR41 data
*Combine hh and sconces ID so that IDs are consistent with other datasets
egen temp = group(hhnumber sconces)
destring temp, replace
drop hhnumber
gen hhnumber = temp
drop temp
}

drop _merge ssect sstruct sqnumber
}



*Get wealth data
preserve
use `2'FL.DTA,clear

ren wlthind5 assetcat
label define aclab 1 "poorest" 2 "poorer" 3 "middle" 4 "rich" 5 "richer"
label value assetcat aclab
label var assetcat "household asset score quintile"
ren wlthindf assetindex
label var assetindex "household asset pca score"
gen hhid  = trim(whhid)
drop whhid
tempfile wealthdat
save `wealthdat'
restore

*Merge in wealth data using HHid
merge m:1 hhid using `wealthdat'
tab _merge
drop if _merge == 2
drop _merge
}


******
* 3. Continue to clean variables in the IR
******
ren v113 water
recode water (10/19=1) (20/89=0) (90/.=.)
label var water "piped water"
ren v116 toilet
recode toilet (10/19=1) (20/89=0) (90/.=.)
label var toilet "flush toilet"
recode v119-v125 (7=.)
recode v119-v125 (9=.)
ren v119 electricity
ren v120 radio
ren v121 tele
ren v122 fridge
ren v123 bike
ren v124 moto
ren v125 car
ren v127 floor
recode floor (10/19=0) (20/89=1) (90/.=.)
label var floor "improved floor"
ren v128 wall
recode wall (1/2 = 0) (3/7 = 1) (10/29=0) (30/89=1) (90/.=.) // for TZ5, 1/2 is earthen materials; 3-7 is "improved"
label var wall "improved wall"
ren v129 roof
recode roof (1 = 0) (2/5 = 1) (10/19=0) (20/89=1) (90/.=.) // for survey TZ5, 1 is earthen materials; 2-5 is "improved"
label var roof "improved roof"
ren v133 edyrs
replace edyrs=. if edyrs>=90 /*recode all values of education above 90 to missing (.)*/ 
rename v149 edattain
replace edattain = . if edattain >= 90 /*recode all values of education above 90 to missing (.)*/ 
gen nevermar = (v501==0) if v501<.
label var nevermar "never married"
ren v511 agemar
ren v212 agebirth
ren v201 evborn
egen evborn_m = rowtotal(v202 v204 v206) 
replace evborn_m = 0 if evborn==0 /*no kids*/
label var evborn_m "sons ever born"
egen evborn_f =  rowtotal(v203 v205 v207)
replace evborn_f = 0 if evborn==0 /*no kids*/
label var evborn_f "daughters ever born"
ren v206 evdied_m
ren v207 evdied_f
recode evdied_m evdied_f (.=0) 
ren v437 weight
replace weight=. if weight>=9000
ren v438 height
replace height=. if height>=9000
ren v445 bmi
replace bmi=. if bmi>=9000
ren v715 husb_edyrs
replace husb_edyrs=. if husb_edyrs>=90
rename v729 husb_edattain
replace husb_edattain = . if husb_edattain >= 90 /*recode all values of education above 90 to missing (.)*/ 
capture{/*capture is used here since madagascar lacks the variable v730*/
ren v730 husb_age 
replace husb_age=. if husb_age >=97 /*above 97 is missing*/
}
drop v*


********
* 4. Clean birth-level variables: keep twin status, month of birth, year of birth, sex, survival, age at death, age
********
d b*
**loops to rename variables (need two loops because need leading zeros for 1-9 but not 10-20)
forvalues i=1/9 {
  ren bord_0`i' ch_bord_`i'
  ren b0_0`i' ch_twin_`i'
  replace ch_twin_`i'=1 if (ch_twin_`i' != 0)&(ch_twin_`i'<.)
  ren b1_0`i' ch_mob_`i'
  ren b2_0`i' ch_yob_`i'
  recode ch_yob_`i' (0=2000) /*some data sets have the year 2000 as the value 0*/
  replace ch_yob_`i'= ch_yob_`i'+1900 if ch_yob_`i' <=99 /*change to four digit years*/
  gen ch_male_`i' = 2-b4_0`i'
  label var ch_male_`i' "child is male"
  gen ch_dead_`i' = 1-b5_0`i'
  label var ch_dead_`i' "child is dead"
  ren b7_0`i' ch_agedeath_`i'
  replace ch_agedeath_`i'=. if ch_agedeath_`i'>900 /*missing code*/
  ren b8_0`i' ch_age_`i'
}
forvalues i=10/20 {
  capture {/*use the capture command because not all surveys go up to 20 kids*/
  ren bord_`i' ch_bord_`i'
  ren b0_`i' ch_twin_`i'
  replace ch_twin_`i'=1 if (ch_twin_`i' != 0)&(ch_twin_`i'<.)
  ren b1_`i' ch_mob_`i'
  ren b2_`i' ch_yob_`i'
  recode ch_yob_`i' (0=2000) /*some data sets have the year 2000 as the value 0*/
  replace ch_yob_`i'= ch_yob_`i'+1900 if ch_yob_`i' <=99 /*change to four digit years*/
  gen ch_male_`i' = 2-b4_`i'
  label var ch_male_`i' "child is male"
  gen ch_dead_`i' = 1-b5_`i'
  label var ch_dead_`i' "child is dead"
  ren b7_`i' ch_agedeath_`i'
  replace ch_agedeath_`i'=. if ch_agedeath_`i'>900 /*missing code*/
  ren b8_`i' ch_age_`i'
}
}

drop bidx* b*_*

********
*5. Clean sibling-level variables
********
d mm*
rename mmc1 numsibs
replace numsibs =. if numsibs>=90
gen b_order = mmc2+1
replace b_order = 1 if numsibs==0 /*only child*/
replace b_order=. if b_order>=99 /*missing code*/
label var b_order "self-reported birth order of resp."

**initialize variables to count all siblings
gen msibs_o = 0
label var msibs_o "older male siblings"
gen fsibs_o = 0
label var fsibs_o "older female siblings"
gen msibs_tw = 0
label var msibs_tw "male siblings born in same year"
gen fsibs_tw = 0
label var fsibs_tw "female siblings born in same year"
gen msibs_y = 0
label var msibs_y "younger male siblings"
gen fsibs_y = 0
label var fsibs_y "younger female siblings"
gen msibs_dk = 0
label var msibs_dk "male siblings w/ unknown yob"
gen fsibs_dk = 0
label var fsibs_dk "female siblings w/ unknown yob"

**initialize variables to count deceased siblings
***under 1 mortality
gen u1_msibs_o = 0
label var u1_msibs_o "older males dead before 1"
gen u1_fsibs_o = 0
label var u1_fsibs_o "older females dead before 1"
gen u1_msibs_tw = 0
label var u1_msibs_tw "males same yob dead before 1"
gen u1_fsibs_tw = 0
label var u1_fsibs_tw "females same yob dead before 1"
gen u1_msibs_y = 0
label var u1_msibs_y "younger males dead before 1"
gen u1_fsibs_y = 0
label var u1_fsibs_y "younger females dead before 1"
gen u1_msibs_dk = 0
label var u1_msibs_dk "males unknown yob dead before 1"
gen u1_fsibs_dk = 0
label var u1_fsibs_dk "females unknown yob dead before 1"
***under 5 mortality
gen u5_msibs_o = 0
label var u5_msibs_o "older males dead before 5"
gen u5_fsibs_o = 0
label var u5_fsibs_o "older females dead before 5"
gen u5_msibs_tw = 0
label var u5_msibs_tw "males same yob dead before 5"
gen u5_fsibs_tw = 0
label var u5_fsibs_tw "females same yob dead before 5"
gen u5_msibs_y = 0
label var u5_msibs_y "younger males dead before 5"
gen u5_fsibs_y = 0
label var u5_fsibs_y "younger females dead before 5"
gen u5_msibs_dk = 0
label var u5_msibs_dk "males unknown yob dead before 5"
gen u5_fsibs_dk = 0
label var u5_fsibs_dk "females unknown yob dead before 5"

**initialize variables to count siblings with unknown survival status (alive/dead AND age at death)
gen miss_msibs_o = 0
label var miss_msibs_o "older males missing survival"
gen miss_fsibs_o = 0
label var miss_fsibs_o "older females missing survival"
gen miss_msibs_tw = 0
label var miss_msibs_tw "males same yob missing survival"
gen miss_fsibs_tw = 0
label var miss_fsibs_tw "females same yob missing survival"
gen miss_msibs_y = 0
label var miss_msibs_y "younger males missing survival"
gen miss_fsibs_y = 0
label var miss_fsibs_y "younger females missing survival"
gen miss_msibs_dk = 0
label var miss_msibs_dk "males unknown yob missing survival"
gen miss_fsibs_dk = 0
label var miss_fsibs_dk "females unknown yob missing survival"

**loops to count siblings (need two loops because need leading zeros for 1-9 but not 10-20)
forvalues i=1/9 {
  gen sib_male_`i' = mm1_0`i'==1 if mm1_0`i'<8
  label var sib_male_`i' "sex of sibling"
  gen sib_yob_`i' = floor((mm4_0`i'+12*1900)/12) /*mm4 is in cmc format, where cmc = 12*year + month - 12*1900*/
  label var sib_yob_`i' "sibling year of birth"
  gen sib_dead_`i' = mm2_0`i'==0 if mm2_0`i'<3
  label var sib_dead_`i' "sibling is dead"
  gen sib_agedeath_`i' = mm7_0`i' if mm7_0`i'<95
  replace sib_agedeath_`i' = floor((mm8_0`i'-mm4_0`i')/12) if sib_agedeath_`i'==. /*if missing age at death, generate it from dates at birth/death*/
  label var sib_agedeath_`i' "sibling age at death"
 
  replace msibs_o = msibs_o + 1 if (sib_male_`i'==1)&(sib_yob_`i'<yob)
  replace fsibs_o = fsibs_o + 1 if (sib_male_`i'==0)&(sib_yob_`i'<yob)
  replace msibs_tw = msibs_tw + 1 if (sib_male_`i'==1)&(sib_yob_`i'==yob)
  replace fsibs_tw = fsibs_tw + 1 if (sib_male_`i'==0)&(sib_yob_`i'==yob)
  replace msibs_y = msibs_y + 1 if (sib_male_`i'==1)&(sib_yob_`i'>yob&sib_yob_`i'<.)
  replace fsibs_y = fsibs_y + 1 if (sib_male_`i'==0)&(sib_yob_`i'>yob&sib_yob_`i'<.)
  replace msibs_dk = msibs_dk + 1 if (sib_male_`i'==1)&(sib_yob_`i'==.)
  replace fsibs_dk = fsibs_dk + 1 if (sib_male_`i'==0)&(sib_yob_`i'==.)
 
  replace u1_msibs_o = u1_msibs_o + 1 if (sib_male_`i'==1)&(sib_yob_`i'<yob)&(sib_agedeath_`i'==0)
  replace u1_fsibs_o = u1_fsibs_o + 1 if (sib_male_`i'==0)&(sib_yob_`i'<yob)&(sib_agedeath_`i'==0)
  replace u1_msibs_tw = u1_msibs_tw + 1 if (sib_male_`i'==1)&(sib_yob_`i'==yob)&(sib_agedeath_`i'==0)
  replace u1_fsibs_tw = u1_fsibs_tw + 1 if (sib_male_`i'==0)&(sib_yob_`i'==yob)&(sib_agedeath_`i'==0)
  replace u1_msibs_y = u1_msibs_y + 1 if (sib_male_`i'==1)&(sib_yob_`i'>yob)&(sib_yob_`i'<.)&(sib_agedeath_`i'==0)
  replace u1_fsibs_y = u1_fsibs_y + 1 if (sib_male_`i'==0)&(sib_yob_`i'>yob)&(sib_yob_`i'<.)&(sib_agedeath_`i'==0)
  replace u1_msibs_dk = u1_msibs_dk + 1 if (sib_male_`i'==1)&(sib_yob_`i'==.)&(sib_agedeath_`i'==0)
  replace u1_fsibs_dk = u1_fsibs_dk + 1 if (sib_male_`i'==0)&(sib_yob_`i'==.)&(sib_agedeath_`i'==0)
  
  replace u5_msibs_o = u5_msibs_o + 1 if (sib_male_`i'==1)&(sib_yob_`i'<yob)&(sib_agedeath_`i'<5)
  replace u5_fsibs_o = u5_fsibs_o + 1 if (sib_male_`i'==0)&(sib_yob_`i'<yob)&(sib_agedeath_`i'<5)
  replace u5_msibs_tw = u5_msibs_tw + 1 if (sib_male_`i'==1)&(sib_yob_`i'==yob)&(sib_agedeath_`i'<5)
  replace u5_fsibs_tw = u5_fsibs_tw + 1 if (sib_male_`i'==0)&(sib_yob_`i'==yob)&(sib_agedeath_`i'<5)
  replace u5_msibs_y = u5_msibs_y + 1 if (sib_male_`i'==1)&(sib_yob_`i'>yob)&(sib_yob_`i'<.)&(sib_agedeath_`i'<5)
  replace u5_fsibs_y = u5_fsibs_y + 1 if (sib_male_`i'==0)&(sib_yob_`i'>yob)&(sib_yob_`i'<.)&(sib_agedeath_`i'<5)
  replace u5_msibs_dk = u5_msibs_dk + 1 if (sib_male_`i'==1)&(sib_yob_`i'==.)&(sib_agedeath_`i'<5)
  replace u5_fsibs_dk = u5_fsibs_dk + 1 if (sib_male_`i'==0)&(sib_yob_`i'==.)&(sib_agedeath_`i'<5)
 
  replace miss_msibs_o = miss_msibs_o + 1 if (sib_male_`i'==1)&(sib_yob_`i'<yob)&(sib_dead_`i'==.|(sib_dead_`i'==1)&(sib_agedeath_`i'==.))
  replace miss_fsibs_o = miss_fsibs_o + 1 if (sib_male_`i'==0)&(sib_yob_`i'<yob)&(sib_dead_`i'==.|(sib_dead_`i'==1)&(sib_agedeath_`i'==.))
  replace miss_msibs_tw = miss_msibs_tw + 1 if (sib_male_`i'==1)&(sib_yob_`i'==yob)&(sib_dead_`i'==.|(sib_dead_`i'==1)&(sib_agedeath_`i'==.))
  replace miss_fsibs_tw = miss_fsibs_tw + 1 if (sib_male_`i'==0)&(sib_yob_`i'==yob)&(sib_dead_`i'==.|(sib_dead_`i'==1)&(sib_agedeath_`i'==.))
  replace miss_msibs_y = miss_msibs_y + 1 if (sib_male_`i'==1)&(sib_yob_`i'>yob)&(sib_yob_`i'<.)&(sib_dead_`i'==.|(sib_dead_`i'==1)&(sib_agedeath_`i'==.))
  replace miss_fsibs_y = miss_fsibs_y + 1 if (sib_male_`i'==0)&(sib_yob_`i'>yob)&(sib_yob_`i'<.)&(sib_dead_`i'==.|(sib_dead_`i'==1)&(sib_agedeath_`i'==.))
  replace miss_msibs_dk = miss_msibs_dk + 1 if (sib_male_`i'==1)&(sib_yob_`i'==.)&(sib_dead_`i'==.|(sib_dead_`i'==1)&(sib_agedeath_`i'==.))
  replace miss_fsibs_dk = miss_fsibs_dk + 1 if (sib_male_`i'==0)&(sib_yob_`i'==.)&(sib_dead_`i'==.|(sib_dead_`i'==1&sib_agedeath_`i'==.))
  }
forvalues i=10/20 {
  capture{ /*use the capture command because not all surveys go up to 20 siblings*/
  gen sib_male_`i' = mm1_`i'==1 if mm1_`i'<8
  label var sib_male_`i' "sex of sibling"
  gen sib_yob_`i' = floor((mm4_`i'+12*1900)/12) /*mm4 is in cmc format, where cmc = 12*year + month - 12*1900*/
  label var sib_yob_`i' "sibling year of birth"
  gen sib_dead_`i' = mm2_`i'==0 if mm2_`i'<3
  label var sib_dead_`i' "sibling is dead"
  gen sib_agedeath_`i' = mm7_`i' if mm7_`i'<95
  replace sib_agedeath_`i' = floor((mm8_`i'-mm4_`i')/12) if sib_agedeath_`i'==. /*if missing age at death, generate it from dates at birth/death*/
  label var sib_agedeath_`i' "sibling age at death"
 
  replace msibs_o = msibs_o + 1 if (sib_male_`i'==1)&(sib_yob_`i'<yob)
  replace fsibs_o = fsibs_o + 1 if (sib_male_`i'==0)&(sib_yob_`i'<yob)
  replace msibs_tw = msibs_tw + 1 if (sib_male_`i'==1)&(sib_yob_`i'==yob)
  replace fsibs_tw = fsibs_tw + 1 if (sib_male_`i'==0)&(sib_yob_`i'==yob)
  replace msibs_y = msibs_y + 1 if (sib_male_`i'==1)&(sib_yob_`i'>yob&sib_yob_`i'<.)
  replace fsibs_y = fsibs_y + 1 if (sib_male_`i'==0)&(sib_yob_`i'>yob&sib_yob_`i'<.)
  replace msibs_dk = msibs_dk + 1 if (sib_male_`i'==1)&(sib_yob_`i'==.)
  replace fsibs_dk = fsibs_dk + 1 if (sib_male_`i'==0)&(sib_yob_`i'==.)
 
  replace u1_msibs_o = u1_msibs_o + 1 if (sib_male_`i'==1)&(sib_yob_`i'<yob)&(sib_agedeath_`i'==0)
  replace u1_fsibs_o = u1_fsibs_o + 1 if (sib_male_`i'==0)&(sib_yob_`i'<yob)&(sib_agedeath_`i'==0)
  replace u1_msibs_tw = u1_msibs_tw + 1 if (sib_male_`i'==1)&(sib_yob_`i'==yob)&(sib_agedeath_`i'==0)
  replace u1_fsibs_tw = u1_fsibs_tw + 1 if (sib_male_`i'==0)&(sib_yob_`i'==yob)&(sib_agedeath_`i'==0)
  replace u1_msibs_y = u1_msibs_y + 1 if (sib_male_`i'==1)&(sib_yob_`i'>yob)&(sib_yob_`i'<.)&(sib_agedeath_`i'==0)
  replace u1_fsibs_y = u1_fsibs_y + 1 if (sib_male_`i'==0)&(sib_yob_`i'>yob)&(sib_yob_`i'<.)&(sib_agedeath_`i'==0)
  replace u1_msibs_dk = u1_msibs_dk + 1 if (sib_male_`i'==1)&(sib_yob_`i'==.)&(sib_agedeath_`i'==0)
  replace u1_fsibs_dk = u1_fsibs_dk + 1 if (sib_male_`i'==0)&(sib_yob_`i'==.)&(sib_agedeath_`i'==0)
  
  replace u5_msibs_o = u5_msibs_o + 1 if (sib_male_`i'==1)&(sib_yob_`i'<yob)&(sib_agedeath_`i'<5)
  replace u5_fsibs_o = u5_fsibs_o + 1 if (sib_male_`i'==0)&(sib_yob_`i'<yob)&(sib_agedeath_`i'<5)
  replace u5_msibs_tw = u5_msibs_tw + 1 if (sib_male_`i'==1)&(sib_yob_`i'==yob)&(sib_agedeath_`i'<5)
  replace u5_fsibs_tw = u5_fsibs_tw + 1 if (sib_male_`i'==0)&(sib_yob_`i'==yob)&(sib_agedeath_`i'<5)
  replace u5_msibs_y = u5_msibs_y + 1 if (sib_male_`i'==1)&(sib_yob_`i'>yob)&(sib_yob_`i'<.)&(sib_agedeath_`i'<5)
  replace u5_fsibs_y = u5_fsibs_y + 1 if (sib_male_`i'==0)&(sib_yob_`i'>yob)&(sib_yob_`i'<.)&(sib_agedeath_`i'<5)
  replace u5_msibs_dk = u5_msibs_dk + 1 if (sib_male_`i'==1)&(sib_yob_`i'==.)&(sib_agedeath_`i'<5)
  replace u5_fsibs_dk = u5_fsibs_dk + 1 if (sib_male_`i'==0)&(sib_yob_`i'==.)&(sib_agedeath_`i'<5)
 
  replace miss_msibs_o = miss_msibs_o + 1 if (sib_male_`i'==1)&(sib_yob_`i'<yob)&(sib_dead_`i'==.|(sib_dead_`i'==1)&(sib_agedeath_`i'==.))
  replace miss_fsibs_o = miss_fsibs_o + 1 if (sib_male_`i'==0)&(sib_yob_`i'<yob)&(sib_dead_`i'==.|(sib_dead_`i'==1)&(sib_agedeath_`i'==.))
  replace miss_msibs_tw = miss_msibs_tw + 1 if (sib_male_`i'==1)&(sib_yob_`i'==yob)&(sib_dead_`i'==.|(sib_dead_`i'==1)&(sib_agedeath_`i'==.))
  replace miss_fsibs_tw = miss_fsibs_tw + 1 if (sib_male_`i'==0)&(sib_yob_`i'==yob)&(sib_dead_`i'==.|(sib_dead_`i'==1)&(sib_agedeath_`i'==.))
  replace miss_msibs_y = miss_msibs_y + 1 if (sib_male_`i'==1)&(sib_yob_`i'>yob)&(sib_yob_`i'<.)&(sib_dead_`i'==.|(sib_dead_`i'==1)&(sib_agedeath_`i'==.))
  replace miss_fsibs_y = miss_fsibs_y + 1 if (sib_male_`i'==0)&(sib_yob_`i'>yob)&(sib_yob_`i'<.)&(sib_dead_`i'==.|(sib_dead_`i'==1)&(sib_agedeath_`i'==.))
  replace miss_msibs_dk = miss_msibs_dk + 1 if (sib_male_`i'==1)&(sib_yob_`i'==.)&(sib_dead_`i'==.|(sib_dead_`i'==1)&(sib_agedeath_`i'==.))
  replace miss_fsibs_dk = miss_fsibs_dk + 1 if (sib_male_`i'==0)&(sib_yob_`i'==.)&(sib_dead_`i'==.|(sib_dead_`i'==1&sib_agedeath_`i'==.))
  }
  }
drop mm* 
*drop sib_* /*if we want to add info on individual siblings back into the dataset, take out this line*/


********
* 7. Merge in respondent's coresident mom ID variable for relevant surveys (DHS version 4 or later)
********

if inlist(`4',4,5,6,7) {
preserve
use `1'FL.DTA, clear

d v*
drop caseid
gen momcaseid = _n
label var momcaseid "person identifier"


*Rename variable
rename v000 surveycode //survey code
rename v001 cluster //cluster id
rename v002 hhnumber // hhid
rename v003 momid //person id 

*Fix ID variables
if inlist("`1'","MLIR41","SNIR4H") {
egen temp = group(hhnumber sconces)
destring temp, replace
drop hhnumber
gen hhnumber = temp
drop temp
}

if inlist("`1'","RWIR61") {
egen temp = group(hhnumber sstruct)
destring temp, replace
drop hhnumber
gen hhnumber = temp
drop temp
}
	
*Some datasets have a small number of duplicates - drop them
duplicates drop surveycode cluster hhnumber momid, force

forvalues i=1/9 {
  ren b16_0`i' womanid_`i'
}
forvalues i=10/20 {
  capture {/*use the capture command because not all surveys go up to 20 kids*/
  ren b16_`i' womanid_`i'
}
}

keep surveycode cluster hhnumber momid momcaseid womanid_*

*Reshape into birth-level data to get the merge IDs for the children in the PR 
reshape long womanid_, i(momcaseid) j(mom_ch_num)
rename womanid_ womanid

drop if womanid == 0 | missing(womanid) // drop missing values

*Some datasets have a small number of duplicates - drop them
duplicates drop surveycode cluster hhnumber womanid, force
drop mom_ch_num

tempfile mergedat
save `mergedat'
restore

*Fix ID variables and merge
if inlist("`1'","MLIR41","SNIR4H") {
egen temp = group(hhnumber sconces)
destring temp, replace
drop hhnumber
gen hhnumber = temp
drop temp sconces

merge m:1 surveycode cluster hhnumber womanid using `mergedat' //we've dropped duplicates in the using data, so should not have m:1 matches
drop if _merge == 2
drop _merge 

}

if inlist("`1'","RWIR61") {
egen temp = group(hhnumber sstruct)
destring temp, replace
drop hhnumber
gen hhnumber = temp
drop temp sstruct
}
	

*Main merge case
if !inlist("`1'","MLIR41","SNIR4H") {
merge 1:1 surveycode cluster hhnumber womanid using `mergedat'
drop if _merge == 2
drop _merge 

}


}

if inlist(`4',4,5,6,7) {
order surveycode cluster hhnumber womanid caseid momid momcaseid smpwt year cluster region ///
rural residence child_rur nonmigrant yob age edyrs edattain weight height bmi nevermar agemar agebirth husb_edyrs husb_edattain asset* ///
evborn* evdied* ch_bord_* ch_twin_* ch_mob_* ch_yob_* ch_agedeath_* ch_dead_* ch_male* ch_age* numsibs b_order msibs_o-fsibs_dk u1* u5* miss*
	
} 

if !inlist(`4',4,5,6,7) {
order surveycode cluster hhnumber womanid caseid smpwt year cluster region ///
rural residence child_rur nonmigrant yob age edyrs edattain weight height bmi nevermar agemar agebirth husb_edyrs husb_edattain asset* ///
evborn* evdied* ch_bord_* ch_twin_* ch_mob_* ch_yob_* ch_agedeath_* ch_dead_* ch_male* ch_age* numsibs b_order msibs_o-fsibs_dk u1* u5* miss*

}


	  
	  
end


***********
* Read in and clean individual survey datasets; then append into single intermadiate data file
***********
*afghanistan 
*afghanistan is processed in a separate do file at end

*bangladesh
*bangladesh is processed in a separate do file at end


*benin 
cd benin
qui cleanup BJIR31 BJWI31 BJPR31 3
save ../../intermediatedat,replace
qui cleanup BJIR51 NA NA 5
qui append using ../../intermediatedat
gen country = "Benin"
save ../../intermediatedat, replace
cd .. 


*bolivia
cd bolivia
qui cleanup BOIR31 BOWI31 BOPR31 3
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup BOIR41 NA NA 4
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup BOIR51 NA NA 5
qui append using ../../intermediatedat
replace country = "Bolivia" if country==""
save ../../intermediatedat, replace
cd ..


*burkina 
cd burkina
qui cleanup BFIR31 BFWI31 BFPR31 3
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup BFIR62 NA NA 6
qui append using ../../intermediatedat
replace country = "Burkina Faso" if country==""
save ../../intermediatedat, replace
cd ..

*burundi
cd burundi
qui cleanup BUIR61 NA NA 6
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup BUIR70 NA NA 7
qui append using ../../intermediatedat
replace country = "Burundi" if country==""
save ../../intermediatedat, replace
cd ..

*caf
cd caf
qui cleanup CFIR31 CFWI31 CFPR31 3
qui append using ../../intermediatedat
replace country = "Central African Republic" if country==""
save ../../intermediatedat, replace
cd ..

*cambodia
cd cambodia 
qui cleanup KHIR42 KHWI41 KHPR42 4
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup KHIR51 NA NA 5
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup KHIR61 NA NA 6
replace surveycode = "KH5-1"
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup KHIR73 NA NA 7
qui append using ../../intermediatedat
replace country = "Cambodia" if country==""
save ../../intermediatedat, replace
cd ..

*cameroon 
cd cameroon
qui cleanup CMIR31 CMWI31 CMPR31 3
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup CMIR44 NA NA 4
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup CMIR61 NA NA 6
qui append using ../../intermediatedat
replace country = "Cameroon" if country==""
save ../../intermediatedat, replace
cd ..

*chad
cd chad
qui cleanup TDIR31 TDWI31 TDPR31 3
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup TDIR41 NA NA 0 //this survey is missing the b16 variables
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup TDIR71 NA NA 7
qui append using ../../intermediatedat
replace country = "Chad" if country==""
save ../../intermediatedat, replace
cd ..


*congo
cd congo
qui cleanup CGIR51 NA NA 5
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup CGIR60 NA NA 6
qui append using ../../intermediatedat
replace country = "Congo" if country==""
save ../../intermediatedat, replace
cd ..

*cote divore 
cd cote_divore
qui cleanup CIIR35 CIWI34 CIPR35 3
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup CIIR62 NA NA 6
qui append using ../../intermediatedat
replace country = "Côte d'Ivoire" if country==""
save ../../intermediatedat, replace
cd ..

*dr 
cd dr
qui cleanup DRIR4A DRWI4A DRPR4B 4
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup DRIR52 NA NA 5
qui append using ../../intermediatedat
replace country = "Dominican Republic" if country==""
save ../../intermediatedat, replace
cd ..

*drc 
cd drc
qui cleanup CDIR50 NA NA 5
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup CDIR61 NA NA 6
qui append using ../../intermediatedat
replace country = "Democratic Republic of the Congo" if country==""
save ../../intermediatedat, replace
cd ..

*ethiopia
*ethiopia is processed in a seperate do file

*gabon
cd gabon
qui cleanup GAIR41 GAWI41 GAPR41 0 //this survey is missing the b16 variables
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup GAIR60 NA NA 6
qui append using ../../intermediatedat
replace country = "Gabon" if country==""
save ../../intermediatedat, replace
cd ..

*ghana
*ghana is processed in a seperate do file

*guinea
cd guinea
qui cleanup GNIR41 GNWI41 GNPR41 0 //this survey is missing the b16 variables
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup GNIR52 NA NA 5
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup GNIR62 NA NA 6
qui append using ../../intermediatedat
replace country = "Guinea" if country==""
save ../../intermediatedat, replace
cd ..

*haiti
cd haiti
qui cleanup HTIR42 HTWI42 HTPR42 4
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup HTIR52 NA NA 5
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup HTIR70 NA NA 7
qui append using ../../intermediatedat
replace country = "Haiti" if country==""
save ../../intermediatedat, replace
cd ..


*indonesia 
cd indonesia
qui cleanup IDIR3A IDWI3A IDPR3A 3
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup IDIR31 CALC IDPR31 3 //calculated the asset index manually
replace surveycode = "ID3-1"
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup IDIR41 NA NA 4
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup IDIR51 NA NA 5 
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup IDIR61 NA NA 6
qui append using ../../intermediatedat
replace country = "Indonesia" if country==""
save ../../intermediatedat, replace
cd ..

*jordan
cd jordan
qui cleanup JOIR31 JOWI31 JOPR31 3
qui append using ../../intermediatedat
replace country = "Jordan" if country==""
save ../../intermediatedat, replace
cd ..

*kenya
cd kenya
qui cleanup KEIR3A KEWI3A KEPR3A 3
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup KEIR41 NA NA 4
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup KEIR52 NA NA 5
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup KEIR71 NA NA 7
qui append using ../../intermediatedat
replace country = "Kenya" if country==""
save ../../intermediatedat, replace
cd ..

*lesotho
cd lesotho
qui cleanup LSIR41 NA NA 4
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup LSIR60 NA NA 6
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup LSIR71 NA NA 7
qui append using ../../intermediatedat
replace country = "Lesotho" if country==""
save ../../intermediatedat, replace
cd ..

*madagascar
cd madagascar
qui cleanup MDIR21 CALC MDPR21 2 //calculated the asset index manually
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup MDIR31 MDWI31 MDPR31 3
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup MDIR41 NA NA 4
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup MDIR51 NA NA 5
qui append using ../../intermediatedat
replace country = "Madagascar" if country==""
save ../../intermediatedat, replace
cd ..


*malawi
cd malawi
qui cleanup MWIR22 CALC MWPR22 2 //calculated the asset index manually; uses men's recode file
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup MWIR4C NA NA 4
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup MWIR41 MWWI42 MWPR41 4
replace surveycode = "MW4-1"
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup MWIR61 NA NA 6
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup MWIR7H NA NA 7
qui append using ../../intermediatedat
replace country = "Malawi" if country==""
save ../../intermediatedat, replace
cd ..



*mali
cd mali
qui cleanup MLIR32 MLWI32 MLPR32 3
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup MLIR41 MLWI42 MLPR41 4
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup MLIR52 NA NA 5
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup MLIR6A NA NA 6
qui append using ../../intermediatedat
replace country = "Mali" if country==""
save ../../intermediatedat, replace
cd ..

*morocco
cd morocco
qui cleanup MAIR21 MAWI21 MAPR21 2
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup MAIR43 NA NA 4
qui append using ../../intermediatedat
replace country = "Morocco" if country==""
save ../../intermediatedat, replace
cd ..

*mozambique
cd mozambique
qui cleanup MZIR31 MZWI31 MZPR31 3
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup MZIR41 NA NA 4
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup MZIR62 NA NA 6
qui append using ../../intermediatedat
replace country = "Mozambique" if country==""
save ../../intermediatedat, replace
cd ..

*namibia
cd namibia
qui cleanup NMIR21 NMWI21 NMPR21 2
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup NMIR41 NMWI41 NMPR41 4
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup NMIR61 NA NA 6
qui append using ../../intermediatedat
replace country = "Namibia" if country==""
save ../../intermediatedat, replace
cd ..

*nepal
*nepal is processed in a seperate do file 

*niger
cd niger
qui cleanup NIIR22 CALC NIPR22 2 //calculated the asset index manually
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup NIIR51 NA NA 5
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup NIIR61 NA NA 6
qui append using ../../intermediatedat
replace country = "Niger" if country==""
save ../../intermediatedat, replace
cd ..

*nigeria
cd nigeria
qui cleanup NGIR51 NA NA 5
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup NGIR6A NA NA 6
qui append using ../../intermediatedat
replace country = "Nigeria" if country==""
save ../../intermediatedat, replace
cd ..

*peru
cd peru
qui cleanup PEIR21 PEWI21 PEPR21 2
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup PEIR31 PEWI31 PEPR31 3
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup PEIR41 PEWI41 PEPR41 0 //there are no b16 variables
qui append using ../../intermediatedat
replace country = "Peru" if country==""
save ../../intermediatedat, replace
cd ..

*philippines
cd philippines
qui cleanup PHIR3A PHWI3A PHPR3B 3
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup PHIR31 PHWI31 PHPR31 3
qui append using ../../intermediatedat
replace country = "Philippines" if country==""
save ../../intermediatedat, replace
cd ..

*rwanda
cd rwanda
qui cleanup RWIR41 RWWI42 RWPR41 4
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup RWIR52 NA NA 5
replace surveycode = "RW4-1"
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup RWIR61 NA NA 6
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup RWIR70 NA NA 7
replace surveycode = "RW6-1"
qui append using ../../intermediatedat
replace country = "Rwanda" if country==""
save ../../intermediatedat, replace
cd ..

*sao_tome
cd sao_tome
qui cleanup STIR50 NA NA 5
qui append using ../../intermediatedat
replace country = "Sao Tome and Principe" if country==""
save ../../intermediatedat, replace
cd ..

*senegal
cd senegal
qui cleanup SNIR21 CALC SNPR21 2 //calculated the asset index manually
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup SNIR4H NA NA 4
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup SNIR61 NA NA 6
qui append using ../../intermediatedat
replace country = "Senegal" if country==""
save ../../intermediatedat, replace
cd ..

*sierra_leone
cd sierra_leone
qui cleanup SLIR51 NA NA 5
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup SLIR61 NA NA 6
qui append using ../../intermediatedat
replace country = "Sierra Leone" if country==""
save ../../intermediatedat, replace
cd ..

*south_africa
cd south_africa
qui cleanup ZAIR31 ZAWI31 ZAPR31 3
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup ZAIR71 NA NA 7
qui append using ../../intermediatedat
replace country = "South Africa" if country==""
save ../../intermediatedat, replace
cd ..

*swazi
cd swazi
qui cleanup SZIR51 NA NA 5
qui append using ../../intermediatedat
replace country = "Eswatini" if country==""
save ../../intermediatedat, replace
cd ..

*tanzania
cd tanzania
qui cleanup TZIR3A TZWI3A TZPR3A 3
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup TZIR4I NA NA 4
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup TZIR63 NA NA 6
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup TZIR7A NA NA 7
qui append using ../../intermediatedat
replace country = "Tanzania" if country==""
save ../../intermediatedat, replace
cd ..

*togo
cd togo
qui cleanup TGIR31 TGWI31 TGPR31 3
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup TGIR61 NA NA 6
qui append using ../../intermediatedat
replace country = "Togo" if country==""
save ../../intermediatedat, replace
cd ..

*zambia
cd zambia
qui cleanup ZMIR31 ZMWI31 ZMPR31 3
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup ZMIR42 ZMWI41 ZMPR43 4
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup ZMIR51 NA NA 5
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup ZMIR61 NA NA 6
qui append using ../../intermediatedat
replace country = "Zambia" if country==""
save ../../intermediatedat, replace
cd ..

*zimbabwe
cd zimbabwe
qui cleanup ZWIR31 ZWWI31 ZWPR31 3
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup ZWIR42 ZWWI42 ZWPR42 4
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup ZWIR51 NA NA 5
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup ZWIR62 NA NA 6
qui append using ../../intermediatedat
save ../../intermediatedat, replace
qui cleanup ZWIR71 NA NA 7
qui append using ../../intermediatedat
replace country = "Zimbabwe" if country==""
save ../../intermediatedat, replace
cd ..


*append the exception data and save
cd nepal // cleaned seperately due to different time coding
run cleannepalexception.do
qui append using ../../intermediatedat
replace country = "Nepal" if country==""
save ../../intermediatedat, replace
cd ..

cd ethiopia // cleaned seperately due to different time coding
run cleanethiopiaexception.do
qui append using ../../intermediatedat
replace country = "Ethiopia" if country==""
save ../../intermediatedat, replace
cd ..

cd afghanistan 
run cleanafghanistanexception2010.do
qui append using ../../intermediatedat
save ../../intermediatedat, replace
run cleanafghanistanexception2015.do
qui append using ../../intermediatedat
replace country = "Afghanistan" if country==""
save ../../intermediatedat, replace
cd ..

cd ghana 
run cleanghanaexception2007.do
qui append using ../../intermediatedat
replace country = "Ghana" if country==""
save ../../intermediatedat, replace
cd ..

cd bangladesh 
run cleanbangladeshexception2001.do
qui append using ../../intermediatedat
replace country = "Bangladesh" if country==""
save ../../intermediatedat, replace
cd ..


*A few data alterations
replace caseid = _n /*case id's are not unique*/
drop momcaseid
ren womanid respid //rename this variable to avoid confusion

save ../intermediatedat.dta, replace
