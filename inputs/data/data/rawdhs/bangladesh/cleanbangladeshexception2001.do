*note: this program processes the raw data from the 2001 Bangladesh DHS
*input dataset: BDIQ4AFL.dta; BDHH4AFL.DTA
*output dataset: bangladeshexception2001.dta

*open and describe raw household-level dataset
use BDHH4AFL.DTA,clear


ren qhquint assetcat
label define aclab 1 "poorest" 2 "poorer" 3 "middle" 4 "rich" 5 "richer"
label value assetcat aclab
label var assetcat "household asset score quintile"
ren qhscore assetindex
label var assetindex "household asset pca score"


*no water
ren qh16 toilet
recode toilet (10/29=1) (30/89=0) (90/.=.)
label var toilet "flush toilet"
recode qh17* (2=0) (9=.)
ren qh17a electricity
ren qh17g radio
ren qh17h tele
*no fridge
ren qh17i bike
ren qh17j moto
*no car 
ren qh18b floor
recode floor (10/19=0) (20/89=1) (90/.=.)
label var floor "improved floor"
ren qh18a wall
recode wall (10/19=0) (20/89=1) (90/.=.)
label var wall "improved wall"
ren qh18 roof
recode roof (10/19=0) (20/89=1) (90/.=.)
label var roof "improved roof"


keep qhregion qhclust qhnumber ///
     assetcat assetindex toilet electricity radio tele bike moto floor wall roof
	 
ren qhregion qregion
ren qhclust qcluster
ren qhnumber qnumber
	 
save bangladeshexception2001.dta, replace


*open and describe raw women-level dataset
use BDIQ4AFL.DTA,clear

merge m:1 qregion qclust qnumber using bangladeshexception2001
drop if _merge==2 //households without eligible women
drop _merge

*woman-level variables
gen caseid = _n
label var caseid "person identifier"
gen surveycode = "BA1"
label var surveycode "country code and phase"
ren qregion region
ren qcluster cluster
ren qnumber hhnumber
ren qline womanid
ren qweight smpwt
ren qinty year 
ren q106 age
tab q105y /*basically nobody reported year of birth, so just use 2001-age*/
gen yob = 2001-age
gen rural=qtype2-1
label var rural "rural residence"
gen child_rur = (q102==2) if q102<.
label var child_rur "rural residence in childhood"

/*these variables are correct, but only available for a few women.
  we need to get the rest from the household file, I think.
*no water
ren q117 toilet
recode toilet (10/19=1) (20/89=0) (90/.=.)
label var water "flush toilet"
recode q118* (2=0)
ren q118a electricity
ren q118g radio
ren q118h tele
*no fridge
ren q118i bike
ren q118j moto
*no car
ren q119b floor
recode floor (10/19=0) (20/89=1) (90/.=.)
label var floor "improved floor"
ren q119a wall
recode wall (10/19=0) (20/89=1) (90/.=.)
label var wall "improved wall"
ren q119 roof
recode roof (10/19=0) (20/89=1) (90/.=.)
label var roof "improved roof"
*/

ren q109b edyrs
replace edyrs=. if edyrs>=90 /*recode all values of education above 90 to missing (.)*/ 
replace edyrs = 0 if q109 == 2 //Frances added 09/10/2020: recode to 0 if never attended school
gen nevermar = 0 if !missing(q107) //Frances added 09/10/2020: all values of q107 indicate that respondents have all been married
label var nevermar "never married"
*ren v511 agemar
*ren v212 agebirth
ren q308 evborn
egen evborn_m = rowtotal(q303a q305a q307a) 
replace evborn_m = 0 if evborn==0 /*no kids*/
label var evborn_m "sons ever born"
egen evborn_f =  rowtotal(q303b q305b q307b)
replace evborn_f = 0 if evborn==0 /*no kids*/
label var evborn_f "daughters ever born"
ren q307a evdied_m
ren q307b evdied_f
recode evdied_m evdied_f (.=0)
*ren v437 weight
*ren v438 height
*ren v445 bmi
*ren v715 husb_edyrs
*ren v730 husb_age 

*child-level variables: keep twin status, month of birth, year of birth, sex, survival, age at death

**loops to rename variables (need two loops because need leading zeros for 1-9 but not 10-20)
forvalues i=1/9 {
  gen ch_twin_`i'= (q313_0`i' == 1) if q313_0`i'<.
  label var ch_twin_`i' "single or multiple birth"
  ren q315m_0`i' ch_mob_`i'
  replace ch_mob_`i'=. if ch_mob_`i'>12
  ren q315y_0`i' ch_yob_`i'
  replace ch_yob_`i'=. if ch_yob_`i'>9000
  gen ch_male_`i' = (q314_0`i'==1) if q314_0`i'<.
  label var ch_male_`i' "child is male"
  gen ch_dead_`i' = q316_0`i'-1
  label var ch_dead_`i' "child is dead"
  ren q320c_0`i' ch_agedeath_`i'
  replace ch_agedeath_`i'=. if ch_agedeath_`i'>900 
  ren q317_0`i' ch_age_`i'
}
forvalues i=10/24 {
  capture {/*use the capture command because not all surveys go up to 20 kids*/
  gen ch_twin_`i'= (q313_`i' == 1) if q313_`i'<.
  label var ch_twin_`i' "single or multiple birth"
  ren q315m_`i' ch_mob_`i'
  replace ch_mob_`i'=. if ch_mob_`i'>12
  ren q315y_`i' ch_yob_`i'
  replace ch_yob_`i'=. if ch_yob_`i'>9000
  gen ch_male_`i' = (q314_`i'==1) if q314_`i'<.
  label var ch_male_`i' "child is male"
  gen ch_dead_`i' = q316_`i'-1
  label var ch_dead_`i' "child is dead"
  ren q320c_`i' ch_agedeath_`i'
  replace ch_agedeath_`i' =. if ch_agedeath_`i'>900 
  ren q317_0`i' ch_age_`i'
}
}

*sibling-level variables
gen numsibs = q201a-1
replace numsibs = . if numsibs>=90
label var numsibs "number of siblings"
gen b_order = q203+1 
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
  gen sib_male_`i' = q205_0`i'==1 if q205_0`i'<3
  label var sib_male_`i' "sex of sibling"
  gen sib_yob_`i' = floor((q207c_0`i'+12*1900)/12) /*q207c is in cmc format, where cmc = 12*year + month - 12*1900*/
  label var sib_yob_`i' "sibling year of birth"
  gen sib_dead_`i' = q206_0`i'==2 if q206_0`i'<3
  label var sib_dead_`i' "sibling is dead"
  gen sib_agedeath_`i' = q209_0`i' if q209_0`i'<95
  replace sib_agedeath_`i' = floor((q208c_0`i'-q207c_0`i')/12) if sib_agedeath_`i'==. /*if missing age at death, generate it from dates at birth/death*/
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
  gen sib_male_`i' = q205_`i'==1 if q205_`i'<3
  label var sib_male_`i' "sex of sibling"
  gen sib_yob_`i' = floor((q207c_`i'+12*1900)/12) /*q207c is in cmc format, where cmc = 12*year + month - 12*1900*/
  label var sib_yob_`i' "sibling year of birth"
  gen sib_dead_`i' = q206_`i'==2 if q206_`i'<3
  label var sib_dead_`i' "sibling is dead"
  gen sib_agedeath_`i' = q209_`i' if q209_`i'<95
  replace sib_agedeath_`i' = floor((q208c_`i'-q207c_`i')/12) if sib_agedeath_`i'==. /*if missing age at death, generate it from dates at birth/death*/
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
  
*drop variables, order, and save
drop q* aw* v101a_01-v900
drop sib* /*if we want to add info on individual siblings back into the dataset, take out this line*/


***
* Merge in respondent's coresident mom ID variable 
***
preserve
use BDIQ4AFL.DTA,clear
gen momcaseid = _n
label var momcaseid "person identifier"


*Rename variable
ren qregion region
ren qcluster cluster
ren qnumber hhnumber
ren qline momid
	
*Some datasets have a small number of duplicates - drop them
duplicates drop region cluster hhnumber momid, force

forvalues i=1/9 {
  ren q319_0`i' womanid_`i'
}
forvalues i=10/20 {
  capture {/*use the capture command because not all surveys go up to 20 kids*/
  ren q319_`i' womanid_`i'
}
}

keep region cluster hhnumber momid momcaseid womanid_*

*Reshape into birth-level data to get the merge IDs for the children in the PR 
reshape long womanid_, i(momcaseid) j(mom_ch_num)
rename womanid_ womanid

drop if womanid == 0 | missing(womanid) // drop missing values

*Some datasets have a small number of duplicates - drop them
duplicates drop region cluster hhnumber womanid, force
drop mom_ch_num

tempfile mergedat
save `mergedat'
restore

merge m:1 region cluster hhnumber womanid using `mergedat' // 1 duplicate in main data; dropped in using data so will be missing momid
drop if _merge == 2
drop _merge 

*Combine region and cluster ID so that IDs are consistent with other datasets
egen temp = group(region cluster)
destring temp, replace
drop cluster
gen cluster = temp
drop temp


order surveycode caseid smpwt year cluster womanid momid momcaseid rural child_rur yob age edyrs nevermar evborn* ///
 evdied* ch_twin_* ch_mob_* ch_yob_* ch_agedeath_* ch_dead_* ch_male* ch_age* numsibs b_order msibs_o-fsibs_dk u1* u5* miss*

save bangladeshexception2001.dta, replace
