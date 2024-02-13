* Encoding: UTF-8.
variable labels
E_AGE 'Age'
E_SEX 'Gender'
W2SD 'Social desirability'
W2JS 'Job satisfaction Time 2'
JS 'Job satisfaction Time 1'
FW 'Free will beliefs'.

* compute freewill scale.
compute freewill=mean(A11 to A18).
EXECUTE.

**************
* Time 1
**************.
USE ALL.
FREQUENCIES VARIABLES=freewill JS W2JS E_AGE E_SEX
  /STATISTICS=MEAN STDDEV MINIMUM MAXIMUM 
  /ORDER=ANALYSIS.

* Time 1.
USE ALL.
CORRELATIONS
  /VARIABLES=freewill JS
  /PRINT=TWOTAIL NOSIG
  /STATISTICS DESCRIPTIVES
  /MISSING=PAIRWISE.

**************
* Time 2
**************.

USE ALL.
COMPUTE filter_$=(~missing(W2JS)).
VARIABLE LABELS filter_$ '~missing(W2JS) (FILTER)'.
VALUE LABELS filter_$ 0 'Not Selected' 1 'Selected'.
FORMATS filter_$ (f1.0).
freq filter_$.
FILTER BY filter_$.
EXECUTE.

FREQUENCIES VARIABLES=freewill JS W2JS E_AGE E_SEX
  /STATISTICS=STDDEV MINIMUM MAXIMUM MEAN MEDIAN
  /ORDER=ANALYSIS.

CORRELATIONS
  /VARIABLES= freewill JS W2JS E_AGE E_SEX  
  /PRINT=TWOTAIL NOSIG
  /MISSING=PAIRWISE.

