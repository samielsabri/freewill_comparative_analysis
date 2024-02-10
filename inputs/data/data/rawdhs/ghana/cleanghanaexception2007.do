*note: this program processes the raw data from the 2007 Ghana DHS
*input dataset: GHIQ51FL.dta
*output dataset: ghanaexception2007.dta

*open and describe raw dataset
use GHIQ51FL.DTA,clear

*woman-level variables
gen caseid = _n
label var caseid "person identifier"
gen surveycode = "GH7"
label var surveycode "country code and phase"
ren qcluster cluster
ren qnumhh hhnumber
ren qline womanid
ren qweight smpwt
ren qinty year 
ren q104 age
ren q103y yob
replace yob=. if yob>9000
gen rural=qurbrur-1
label var rural "rural residence"
*gen child_rur = (v103==3) if v103<9
*label var child_rur "rural residence in childhood"

****
* Calculate asset index
****
preserve 
*This info isn't in the individual recode (as in the standard surveys)
*gen domestic = 0
*gen land = 0
*gen house = 0
*collapse domestic land house, by(surveycode cluster hhnumber)

*Read in the wealth data
use GHHB51FL.DTA, clear

*Rename PR ID variables to match IR ID variable names
gen surveycode = "GH7"
ren qhclust cluster
ren qhnumber hhnumber
ren qhwlthf assetindex
ren qhwlthi assetcat

keep surveycode cluster hhnumber assetindex assetcat

tempfile assetdat
save `assetdat'
restore

merge m:1 surveycode cluster hhnumber using `assetdat'
drop if _merge == 2 //HHs without eligible women
drop _merge

ren qh10 water
recode water (10/19=1) (20/89=0) (90/.=.)
label var water "piped water"
ren qh11 toilet
recode toilet (10/19=1) (20/89=0) (90/.=.)
label var water "flush toilet"
recode qh13* qh17* (2=0) (9=.)
ren qh13a electricity
ren qh13b radio
ren qh13c tele
ren qh13g fridge
ren qh17b bike
ren qh17c moto
ren qh17e car
ren qh15 floor
recode floor (10/19=0) (20/89=1) (90/.=.)
label var floor "improved floor"
/*no wall or roof*/

ren q107 edyrs
replace edyrs=. if edyrs>=90 /*recode all values of education above 90 to missing (.)*/ 
replace edyrs = 0 if q105 == 2 //Frances added 09/10/2020: recode edyrs to 0 if respondent never attended school
gen nevermar = (q702==3) if q702<9 /*3 is coded for the response "no"*/
replace nevermar = 0 if q701 < 3 //Frances added 09/10/2020: recode if current married status is never married /*3 is coded for the response "no"*/
label var nevermar "never married"
ren q707c agemar
replace agemar=. if agemar>90
*ren v212 agebirth
*ren q801 evborn // FL note: don't uncomment; wrong variable
egen evborn_m = rowtotal(q203a q205a q207a) 
*replace evborn_m = 0 if evborn==0 /*no kids*/
label var evborn_m "sons ever born"
egen evborn_f =  rowtotal(q203b q205b q207b)
egen evborn = rowtotal(evborn_m evborn_f) //FL added 8/21/2020: generate ever born variable
*replace evborn_f = 0 if evborn==0 /*no kids*/
label var evborn_f "daughters ever born"
ren q207a evdied_m
ren q207b evdied_f
recode evdied_m evdied_f (.=0)
*ren v437 weight
*ren v438 height
*ren v445 bmi
*ren v715 husb_edyrs
*ren v730 husb_age 

*child-level variables: keep twin status, month of birth, year of birth, sex, survival, age at death, age

**loops to rename variables (need two loops because need leading zeros for 1-9 but not 10-20)
forvalues i=1/9 {
  gen ch_twin_`i' = q219_0`i'-1
  label var ch_twin_`i' "single or multiple birth"
  ren q224m_0`i' ch_mob_`i'
  replace ch_mob_`i'=. if ch_mob_`i'>12
  ren q224y_0`i' ch_yob_`i'
  replace ch_yob_`i'=. if ch_yob_`i'>9000
  gen ch_male_`i' = (q223_0`i'==1) if q223_0`i'<3
  label var ch_male_`i' "child is male"
  gen ch_dead_`i' = q225_0`i'-1
  label var ch_dead_`i' "child is dead"
  ren q227c_0`i' ch_agedeath_`i'
  replace ch_agedeath_`i' =. if ch_agedeath_`i'>900 /*missing code*/
  ren q226_0`i' ch_age_`i'
}
forvalues i=10/20 {
  capture{/*use the capture command because not all surveys go up to 20 kids*/
  gen ch_twin_`i' = q219_`i'-1
  label var ch_twin_`i' "single or multiple birth"
  ren q224m_`i' ch_mob_`i'
  replace ch_mob_`i'=. if ch_mob_`i'>12
  ren q224y_`i' ch_yob_`i'
  replace ch_yob_`i'=. if ch_yob_`i'>9000
  gen ch_male_`i' = (q223_`i'==1) if q223_`i'<3
  label var ch_male_`i' "child is male"
  gen ch_dead_`i' = q225_`i'-1
  label var ch_dead_`i' "child is dead"
  ren q227c_`i' ch_agedeath_`i'
  replace ch_agedeath_`i' =. if ch_agedeath_`i'>900 /*missing code*/
  ren q226_`i' ch_age_`i'
}
}

*sibling-level variables
gen numsibs =q801-1
replace numsibs =. if numsibs>=90
label var numsibs "number of siblings"
gen b_order = q803+1 
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
label var u1_fsibs_tw "females same yob dead before 1r"
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
  gen sib_male_`i' = (q805_0`i'==1) if q805_0`i'<9
  label var sib_male_`i' "sex of sibling"
  gen sib_yob_`i' = floor((q807c_0`i'+12*1900)/12) /*q807c is in cmc format, where cmc = 12*year + month - 12*1900*/
  label var sib_yob_`i' "sibling year of birth"
  gen sib_dead_`i' = (q806_0`i'==2) if q806_0`i'<3
  label var sib_dead_`i' "sibling is dead"
  gen sib_agedeath_`i' = q809_0`i' if q809_0`i'<95
  replace sib_agedeath_`i' = floor((q808c_0`i'-q807c_0`i')/12) if sib_agedeath_`i'==. /*if missing age at death, generate it from dates at birth/death*/
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
  gen sib_male_`i' = (q805_`i'==1) if q805_`i'<9
  label var sib_male_`i' "sex of sibling"
  gen sib_yob_`i' = floor((q807c_`i'+12*1900)/12) /*q807c is in cmc format, where cmc = 12*year + month - 12*1900*/
  label var sib_yob_`i' "sibling year of birth"
  gen sib_dead_`i' = (q806_`i'==2) if q806_`i'<3
  label var sib_dead_`i' "sibling is dead"
  gen sib_agedeath_`i' = q809_`i' if q809_`i'<95
  replace sib_agedeath_`i' = floor((q808c_`i'-q807c_`i')/12) if sib_agedeath_`i'==. /*if missing age at death, generate it from dates at birth/death*/
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
  
*drop variables, reorder, and save
drop q* 
drop sib* /*if we want to add info on individual siblings back into the dataset, take out this line*/


***
* Merge in respondent's coresident mom ID variable 
***
preserve
use GHIQ51FL.DTA,clear
gen momcaseid = _n
label var momcaseid "person identifier"


*Rename variable
ren qcluster cluster
ren qnumhh hhnumber
ren qline momid
	
*Some datasets have a small number of duplicates - drop them
duplicates drop cluster hhnumber momid, force

forvalues i=1/9 {
  ren q218_0`i' womanid_`i'
}
forvalues i=10/20 {
  capture {/*use the capture command because not all surveys go up to 20 kids*/
  ren q218_`i' womanid_`i'
}
}

keep cluster hhnumber momid momcaseid womanid_*

*Reshape into birth-level data to get the merge IDs for the children in the PR 
reshape long womanid_, i(momcaseid) j(mom_ch_num)
rename womanid_ womanid

drop if womanid == 0 | missing(womanid) // drop missing values

*Some datasets have a small number of duplicates - drop them
duplicates drop cluster hhnumber womanid, force
drop mom_ch_num

tempfile mergedat
save `mergedat'
restore

merge 1:1 cluster hhnumber womanid using `mergedat'
drop if _merge == 2
drop _merge 



order surveycode caseid smpwt year cluster womanid momid momcaseid rural yob age edyrs nevermar agemar ///
      evborn* evdied* ch_twin_* ch_mob_* ch_yob_* ch_agedeath_* ch_dead_* ch_male* ch_age_* numsibs b_order msibs_o-fsibs_dk u1* u5* miss*

save ghanaexception2007.dta, replace
