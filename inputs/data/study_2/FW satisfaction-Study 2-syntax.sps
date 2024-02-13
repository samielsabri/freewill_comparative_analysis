* Encoding: UTF-8.
* Free will scales - time 1.
recode fw_16 fw_17 fw_21  fw_22 (1=6) (2=5) (3=4) (4=3) (5=2) (6=1) into fw_16r fw_17r fw_21r fw_22r.

RELIABILITY
  /VARIABLES=fw_1 to fw_9
  /SCALE('free will FWagency - T1') ALL
  /MODEL=ALPHA
  /STATISTICS=SCALE
  /SUMMARY=TOTAL.

* all the subscles, the most conceptually relevant are the free-will and personal agency.
compute FWDfw=mean(fw_1 to fw_5).
compute FWDagency=mean(fw_6 to fw_9).
compute FWDmoral=mean (fw_10,fw_11, fw_12, fw_13, fw_14, fw_15).
compute FWDpower=mean(fw_16r, fw_17r, fw_18).
compute FWDresp=mean(fw_19, fw_20).
compute FWDlimit=mean(fw_21r, fw_22r).
compute FWDall=mean(fw_1 to fw_9, fw_10 to fw_15, fw_19, fw_20, fw_16r, fw_17r, fw_18, fw_19, fw_20, fw_21r, fw_22r).
compute FWDfwagency=mean(fw_1 to fw_9).
EXECUTE.

variable labels
FWDfw 'FW T1 Free will subscale'
FWDagency 'FW T1 personal agency subscale'
FWDmoral 'FW T1 Moral responsibility subscale' 
FWDpower 'FW T1 Higher power control subscale'
FWDresp 'FW T1 Personal responsibility subscale'
FWDlimit 'FW T1 Personal limitations subscale'
FWDall 'FW T1 both scales'
FWDfwagency 'FW T1 agency and free will subscales'.

RELIABILITY
  /VARIABLES=fw_6,  fw_18, fw_8, fw_21r, fw_3, fw_7, fw_22r, fw_9
  /SCALE('free will personal - T1') ALL
  /MODEL=ALPHA
  /STATISTICS=SCALE
  /SUMMARY=TOTAL.

RELIABILITY
  /VARIABLES=fw_1, fw_2, fw_4, fw_5, fw_10, fw_11, fw_12, fw_13, fw_14, fw_15, fw_16r, fw_17r, fw_19, fw_20
  /SCALE('free will general - T1') ALL
  /MODEL=ALPHA
  /STATISTICS=SCALE
  /SUMMARY=TOTAL.

compute FWself=mean(fw_6,  fw_18, fw_8, fw_21r, fw_3, fw_7, fw_22r, fw_9).
compute FWgeneral=mean(fw_1, fw_2, fw_4, fw_5, fw_10, fw_11, fw_12, fw_13, fw_14, fw_15, fw_16r, fw_17r, fw_19, fw_20).

variable labels
FWself  'Free will beliefs - personal T1'
FWgeneral  'Free will beliefs - general T1'.

*****************.
* Job satisfaction
*****************.
recode jobsat_3 jobsat_5 (1=7) (2=6) (3=5) (4=4) (5=3) (6=2) (7=1) into jobsat_3r jobsat_5r.
RELIABILITY
  /VARIABLES=jobsat_1, jobsat_2, jobsat_3r, jobsat_4, jobsat_5r
  /SCALE('ALL VARIABLES') ALL
  /MODEL=ALPHA
  /STATISTICS=SCALE
  /SUMMARY=TOTAL.
compute jobsat1=mean(jobsat_1, jobsat_2, jobsat_3r, jobsat_4, jobsat_5r).
EXECUTE.
* Time 2.
recode jobsat2_3 jobsat2_5 (1=7) (2=6) (3=5) (4=4) (5=3) (6=2) (7=1) into jobsat2_3r jobsat2_5r.
RELIABILITY
  /VARIABLES=jobsat2_1, jobsat2_2, jobsat2_3r, jobsat2_4, jobsat2_5r
  /SCALE('ALL VARIABLES') ALL
  /MODEL=ALPHA
  /STATISTICS=SCALE
  /SUMMARY=TOTAL.
compute jobsat2=mean(jobsat2_1, jobsat2_2, jobsat2_3r, jobsat2_4, jobsat2_5r).
EXECUTE.


variable labels
jobsat1 'Job satisfaction T1'
jobsat2 'Job satisfaction T2'.

*****************.
* Job autonomy
*****************.
* Time 1.
* The first two items were from Barrick & Mount (1993, JAP) and aren't about autonomy "There is a lot of autonomy in doing the job", "The job is quite simple and repetitive".
RELIABILITY
  /VARIABLES=jobaut_3 to jobaut_5
  /SCALE('Job autonomy - Time 1') ALL
  /MODEL=ALPHA.
compute jobaut=mean(jobaut_3 to jobaut_5).
EXECUTE.
* Time 2.
RELIABILITY
  /VARIABLES=jobaut2_3 to jobaut2_5
  /SCALE('Job autonomy - Time 2') ALL
  /MODEL=ALPHA.
compute jobaut2=mean(jobaut2_3 to jobaut2_5).
EXECUTE.

variable labels
jobaut 'Job autonomy - T1 '
jobaut2 'Job autonomy - T2'.

*****************.
* Lay theories
*****************.
* the Quatrics coding got a bit messed up, correcting below.
* higher score is more essentialist entitst, less incremental.
RECODE laytheory_1 laytheory_2 laytheory_3 laytheory_4  (MISSING=SYSMIS) (20=1) 
    (21=2) (22=3) (23=4) (24=5) (25=6) INTO lay_1 lay_2 lay_3 lay_4 .
RECODE laytheory_5 laytheory_6 laytheory_7 laytheory_8 (MISSING=SYSMIS) (20=6) 
    (21=5) (22=4) (23=3) (24=2) (25=1) INTO lay_5r lay_6r lay_7r lay_8r.
RELIABILITY
  /VARIABLES=lay_1, lay_2, lay_3, lay_4, lay_5r, lay_6r, lay_7r, lay_8r
  /SCALE('Lay theories - Time 1') ALL
  /MODEL=ALPHA.
COMPUTE ess_kind=MEAN(lay_1, lay_2, lay_3, lay_4, lay_5r, lay_6r, lay_7r, lay_8r).
EXECUTE.

variable labels
ess_kind 'implicit theories T1'.



*****************.
* Self esteem
*****************.
* Time 1.
recode selfest_3 selfest_5 selfest_8 selfest_9 selfest_10  (1=7) (2=6) (3=5) (4=4) (5=3) (6=2) (7=1) into selfest_3r selfest_5r selfest_8r selfest_9r selfest_10r .
RELIABILITY
  /VARIABLES=selfest_1, selfest_2, selfest_3r, selfest_4, selfest_5r, selfest_6, selfest_7, selfest_8r, selfest_9r, selfest_10r
  /SCALE('Self esteem - Time 1') ALL
  /MODEL=ALPHA.
compute selfest = mean (selfest_1, selfest_2, selfest_3r, selfest_4, selfest_5r, selfest_6, selfest_7, selfest_8r, selfest_9r, selfest_10r).
EXECUTE.

variable labels
selfest 'Self-esteem T1'.


*****************.
* Self efficiacy
*****************.
* Time 1.
compute selfeff=mean(selfeff_1 to selfeff_3).
RELIABILITY
  /VARIABLES=selfeff_1 to selfeff_3
  /SCALE('Self efficacy - Time 1') ALL
  /MODEL=ALPHA.
EXECUTE.

variable labels
selfeff 'Self-efficacy T1'.


*****************.
* Self control
*****************.
* Time1.
recode selfcon_2 selfcon_3 selfcon_4 selfcon_5 selfcon_7 selfcon_9 selfcon_10 selfcon_12 selfcon_13 (1=5) (2=4) (3=3) (4=2) (5=1) into selfcon_2r selfcon_3r selfcon_4r selfcon_5r selfcon_7r selfcon_9r selfcon_10r selfcon_12r selfcon_13r.
RELIABILITY
  /VARIABLES=selfcon_1, selfcon_2r, selfcon_3r, selfcon_4r, selfcon_5r, selfcon_6, selfcon_7r, selfcon_8, selfcon_9r, selfcon_10r,selfcon_11, selfcon_12r, selfcon_13r
  /SCALE('Self control - Time 1') ALL
  /MODEL=ALPHA.
compute selfcontrol=mean( selfcon_1, selfcon_2r, selfcon_3r, selfcon_4r, selfcon_5r, selfcon_6, selfcon_7r, selfcon_8, selfcon_9r, selfcon_10r,selfcon_11, selfcon_12r, selfcon_13r).
EXECUTE.

variable labels
selfcontrol 'Trait self-control T1'.

*****************.
* Locus of control
*****************.
* Time 1.
recode lc2 lc6 lc7 lc8 lc9 (1=2) (2=1) into lc2r lc6r lc7r lc8r lc9r.
RELIABILITY
  /VARIABLES=lc1 lc2r lc3 lc4 lc5 lc6r lc7r lc8r lc9r lc10 lc11 lc12 lc13
  /SCALE('Locus of control - Time 1') ALL
  /MODEL=ALPHA.
compute locus=((lc1=1)+(lc2=2)+(lc3=1)+(lc4=1)+(lc5=1)+(lc6=2)+(lc7=2)+(lc8=2)+(lc9=2)+(lc10=1)+(lc11=1)+(lc12=1)+(lc13=1)).
EXECUTE.

variable labels
locus 'locus of control T1'.

*****************.
*****************.
* Start here for analyses.
*****************.
*****************.

USE ALL.

* the main variables.
FREQUENCIES VARIABLES=jobsat1 jobsat2  FWDfwagency jobaut jobaut2 locus ess_kind selfest selfeff selfcontrol
  /STATISTICS=STDDEV MINIMUM MAXIMUM MEAN SKEWNESS SESKEW KURTOSIS SEKURT
  /ORDER=ANALYSIS.

* the main correlations.
CORRELATIONS
  /VARIABLES=jobsat1 jobsat2  FWDfwagency jobaut jobaut2 locus ess_kind selfest selfeff selfcontrol
  /PRINT=TWOTAIL NOSIG
  /MISSING=PAIRWISE.

* job satisfaction with controls.
PARTIAL CORR
  /VARIABLES= jobsat1 FWDfwagency  BY selfest selfeff selfcontrol ess_kind locus 
  /SIGNIFICANCE=TWOTAIL
  /MISSING=LISTWISE.

PARTIAL CORR
  /VARIABLES= jobsat2 FWDfwagency  BY selfest selfeff selfcontrol ess_kind locus
  /SIGNIFICANCE=TWOTAIL
  /MISSING=LISTWISE.

* job autonomy  with controls.
PARTIAL CORR
  /VARIABLES= jobaut FWDfwagency  BY selfest selfeff selfcontrol ess_kind locus 
  /SIGNIFICANCE=TWOTAIL
  /MISSING=LISTWISE.

PARTIAL CORR
  /VARIABLES= jobaut2 FWDfwagency  BY selfest selfeff selfcontrol ess_kind locus
  /SIGNIFICANCE=TWOTAIL
  /MISSING=LISTWISE.

* first step for a mediation model fw->jobaut->satisfaction.
PARTIAL CORR
  /VARIABLES= jobsat1 FWDfwagency  BY jobaut 
  /SIGNIFICANCE=TWOTAIL
  /MISSING=LISTWISE.

PARTIAL CORR
  /VARIABLES= jobsat2 FWDfwagency  BY jobaut2
  /SIGNIFICANCE=TWOTAIL
  /MISSING=LISTWISE.

* stepwise comparison to other agency constructs (Stillman et al., 2010).
REGRESSION
  /MISSING LISTWISE
  /DESCRIPTIVES MEAN  STDDEV
  /STATISTICS COEFF OUTS R ANOVA CHANGE CI(95) TOL
  /CRITERIA=PIN(.05) POUT(.10)
  /NOORIGIN 
  /DEPENDENT jobsat1
  /METHOD=STEPWISE selfest selfeff selfcontrol FWDfwagency ess_kind locus.

REGRESSION
  /MISSING LISTWISE
  /DESCRIPTIVES MEAN  STDDEV
  /STATISTICS COEFF OUTS R ANOVA CHANGE CI(95) TOL
  /CRITERIA=PIN(.05) POUT(.10)
  /NOORIGIN 
  /DEPENDENT jobsat2
  /METHOD=STEPWISE selfest selfeff selfcontrol FWDfwagency ess_kind locus.

* controlling for other agency constructs (Stillman et al., 2010).
REGRESSION
  /MISSING LISTWISE
  /DESCRIPTIVES MEAN  STDDEV
  /STATISTICS COEFF OUTS R ANOVA CHANGE CI(95) TOL
  /CRITERIA=PIN(.05) POUT(.10)
  /NOORIGIN 
  /DEPENDENT jobsat1
  /METHOD=ENTER selfest selfeff selfcontrol ess_kind locus
  /METHOD=ENTER FWDfwagency .

REGRESSION
  /MISSING LISTWISE
  /DESCRIPTIVES MEAN  STDDEV
  /STATISTICS COEFF OUTS R ANOVA CHANGE CI(95)
  /CRITERIA=PIN(.05) POUT(.10)
  /NOORIGIN 
  /DEPENDENT jobsat2
  /METHOD=ENTER selfest selfeff selfcontrol ess_kind locus
  /METHOD=ENTER FWDfwagency.

