*note: this program processes the raw data from the 2010 Afghanistan DHS
*input dataset: HOUSEHOLDS.dta, WOMEN.dta 
*output dataset: afghanistanexception2010.dta

*open household-level dataset
use HOUSEHOLDS.DTA,clear

ren qhwlthi assetcat
label define aclab 1 "poorest" 2 "poorer" 3 "middle" 4 "rich" 5 "richer"
label value assetcat aclab
label var assetcat "household asset score quintile"
ren qhwlthf assetindex
label var assetindex "household asset pca score"
ren qhclust cluster
ren qhnumber hhnumber
ren qh601 water
recode water (10/19=1) (20/89=0) (90/.=.)
label var water "piped water"
ren qh602 toilet
recode toilet (10/19=1) (20/89=0) (90/.=.)
label var toilet "flush toilet"
recode qh604* qh610* (2=0) (9=.)
ren qh604a electricity
ren qh604b radio
ren qh604c tele
ren qh604j fridge
ren qh610b bike
ren qh610d moto
ren qh610f car
ren qh606 floor
recode floor (10/19=0) (20/89=1) (90/.=.)
label var floor "improved floor"
ren qh608 wall
recode wall (10/29=0) (30/89=1) (90/.=.)
label var wall "improved wall"
ren qh607 roof
recode roof (10/19=0) (20/89=1) (90/.=.)
label var roof "improved roof"

keep cluster hhnumber ///
     assetcat assetindex water toilet electricity radio tele fridge bike moto car floor wall roof

save afghanistanexception2010,replace

*open woman-level dataset
use WOMEN.DTA,clear

ren qhclust cluster
ren qhnumber hhnumber

merge m:1 cluster hhnumber using afghanistanexception2010
drop if _merge==2 //households without eligible women
drop _merge

*woman-level variables
gen caseid = _n
label var caseid "person identifier"
gen surveycode = "AF1"
label var surveycode "country code and phase"
ren qline womanid
ren qweight smpwt
ren qintyg year
ren q103 age
ren q102yg yob
replace yob=. if yob>9000
replace yob = 2010 - age if missing(yob) //added by Frances (3/8/2021) - reduce missingness in yob
gen rural=qtype-1
label var rural "rural residence"
*gen child_rur = (v103==3) if v103<9
*label var child_rur "rural residence in childhood"
ren q106 edyrs
replace edyrs=. if edyrs>=90 /*recode all values of education above 90 to missing (.)*/ 
replace edyrs = 0 if q104 == 2 //Frances added 09/10/2020: recode edyrs to 0 if respondent never attended school
/*gen nevermar = (q202==2) if q202<.
replace nevermar = 0 if (q201 == 1) //Frances added 09/10/2020: recode nevermar = 0 if respondent is currently married
 Tom took this out 9/15/2020 because all women in the sample are evermarried*/
gen nevermar = 0
label var nevermar "never married"
ren q207c agemar
replace agemar=. if agemar>=90
*ren v212 agebirth
ren q310 evborn
replace evborn=. if evborn>90
egen evborn_m = rowtotal(q303a q305a q307a) 
replace evborn_m = 0 if evborn==0 /*no kids*/
label var evborn_m "sons ever born"
egen evborn_f =  rowtotal(q303b q305b q307b)
replace evborn_f = 0 if evborn==0 /*no kids*/
replace evborn = 0 if missing(evborn) //Frances added: 8/21/2020 - these are indeed cases with no ferility
label var evborn_f "daughters ever born"
ren q307a evdied_m
ren q307b evdied_f
recode evdied_m evdied_f (.=0)
*ren v437 weight
*ren v438 height
*ren v445 bmi
*ren v715 husb_edyrs
*replace husb_edyrs=. if husb_edyrs>=90
*ren v730 husb_age

**loops to rename variables (need two loops because need leading zeros for 1-9 but not 10-20)
forvalues i=1/9 {
  gen ch_twin_`i'= q316_0`i'-1
  label var ch_twin_`i' "single or multiple birth"
  ren q317mg_0`i' ch_mob_`i'
  replace ch_mob_`i'=. if (ch_mob_`i'>12) /*unknown month of birth*/
  recode ch_mob_`i' (1=4)(2=5)(3=6)(4=7)(5=8)(6=9)(7=10)(8=11)(9=12)(10=1)(11=2)(12=3)/*convert to gregorian months*/
  ren q317yg_0`i' ch_yob_`i'
  replace ch_yob_`i'=. if (ch_yob_`i'>9000)
  gen ch_male_`i' = (q315_0`i'==1) if q315_0`i'<.
  label var ch_male_`i' "child is male"
  gen ch_dead_`i' = (q318_0`i'==2) if q318_0`i'<.
  label var ch_dead_`i' "child is dead"
  ren q323c_0`i' ch_agedeath_`i'
  replace ch_agedeath_`i'=. if ch_agedeath_`i'>900
  ren q319_0`i' ch_age_`i'
}
forvalues i=10/24 {
  capture {
  gen ch_twin_`i'= q316_`i'-1
  label var ch_twin_`i' "single or multiple birth"
  ren q317mg_`i' ch_mob_`i'
  replace ch_mob_`i'=. if (ch_mob_`i'>12) /*unknown month of birth*/
  recode ch_mob_`i' (1=4)(2=5)(3=6)(4=7)(5=8)(6=9)(7=10)(8=11)(9=12)(10=1)(11=2)(12=3)/*convert to gregorian months*/
  ren q317yg_`i' ch_yob_`i'
  replace ch_yob_`i'=. if (ch_yob_`i'>9000)
  gen ch_male_`i' = (q315_`i'==1) if q315_`i'<.
  label var ch_male_`i' "child is male"
  gen ch_dead_`i' = (q318_`i'==2) if q318_`i'<.
  label var ch_dead_`i' "child is dead"
  ren q323c_`i' ch_agedeath_`i'
  replace ch_agedeath_`i'=. if ch_agedeath_`i'>900
  ren q319_`i' ch_age_`i'
}
}

*sibling-level variables
gen numsibs = q601-1
replace numsibs =. if numsibs>=90
label var numsibs "number of siblings of resp."
gen b_order = q603+1
replace b_order = 1 if numsibs==0 /*only child*/
replace b_order =. if b_order>=99 /*missing code*/
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
  gen sib_male_`i' = (q605_0`i'==1) if q605_0`i'<9
  label var sib_male_`i' "sex of sibling"
  replace q607c_0`i'=q607c_0`i'+255 /*cmc correction for afghanistan*/
  gen sib_yob_`i' = floor((q607c_0`i'+12*1900)/12) /*q607c is in cmc format, where cmc = 12*year + month - 12*1900*/
  label var sib_yob_`i' "sibling year of birth"
  gen sib_dead_`i' = (q606_0`i'==2) if q606_0`i'<3
  label var sib_dead_`i' "sibling is dead"
  gen sib_agedeath_`i' = q611_0`i' if q611_0`i'<95
  replace q610c_0`i'=q610c_0`i'+255 /*cmc correction for afghanistan*/
  replace sib_agedeath_`i' = floor((q610c_0`i'-q607c_0`i')/12) if sib_agedeath_`i'==. /*if missing age at death, generate it from dates at birth/death*/
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
  gen sib_male_`i' = (q605_`i'==1) if q605_`i'<9
  label var sib_male_`i' "sex of sibling"
  replace q607c_`i'=q607c_`i' + 255 /*cmc correction for afghanistan*/
  gen sib_yob_`i' = floor((q607c_`i'+12*1900)/12) /*q607cg is in cmc format, where cmc = 12*year + month - 12*1900*/
  label var sib_yob_`i' "sibling year of birth"
  gen sib_dead_`i' = (q606_`i'==2) if q606_`i'<3
  label var sib_dead_`i' "sibling is dead"
  gen sib_agedeath_`i' = q611_`i' if q611_`i'<95
  replace q610c_`i'=q610c_`i'+255 /*cmc correction for afghanistan*/
  replace sib_agedeath_`i' = floor((q610c_`i'-q607c_`i')/12) if sib_agedeath_`i'==. /*if missing age at death, generate it from dates at birth/death*/
  label var sib_agedeath_`i' "sibling age at death"
 
  replace msibs_o = msibs_o + 1 if (sib_male_`i'==1)&(sib_yob_`i'<yob)
  replace fsibs_o = fsibs_o + 1 if (sib_male_`i'==0)&(sib_yob_`i'<yob)
  replace msibs_tw = msibs_tw + 1 if (sib_male_`i'==1)&(sib_yob_`i'==yob)
  replace fsibs_tw = fsibs_tw + 1 if (sib_male_`i'==0)&(sib_yob_`i'==yob)
  replace msibs_y = msibs_y + 1 if (sib_male_`i'==1)&(sib_yob_`i'>yob&sib_yob_`i'<.)
  replace fsibs_y = fsibs_y + 1 if (sib_male_`i'==0)&(sib_yob_`i'>yob&sib_yob_`i'<.)
  replace msibs_dk = msibs_dk + 1 if (sib_male_`i'==1)&(sib_yob_`i'==.)
  replace fsibs_dk = fsibs_dk + 1 if (sib_male_`i'==0)&(sib_yob_`i'==.)
 
  replace u1_msibs_o = u1_msxibs_o + 1 if (sib_male_`i'==1)&(sib_yob_`i'<yob)&(sib_agedeath_`i'==0)
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
drop sib_* /*if we want to add info on individual siblings back into the dataset, take out this line*/


***
* Merge in respondent's coresident mom ID variable 
***
preserve
use WOMEN.DTA,clear
gen momcaseid = _n
label var momcaseid "person identifier"


*Rename variable
ren qhclust cluster
ren qhnumber hhnumber
ren qline momid
	
*Some datasets have a small number of duplicates - drop them
duplicates drop cluster hhnumber momid, force

forvalues i=1/9 {
  ren q321_0`i' womanid_`i'
}
forvalues i=10/20 {
  capture {/*use the capture command because not all surveys go up to 20 kids*/
  ren q321_`i' womanid_`i'
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



order surveycode caseid smpwt year cluster rural yob age edyrs nevermar agemar ///
      evborn* evdied* ch_twin_* ch_mob_* ch_yob_* ch_agedeath_* ch_dead_* ch_male* numsibs b_order msibs_o-fsibs_dk u1* u5* miss*

save afghanistanexception2010.dta, replace



