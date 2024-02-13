********************
* a173 - How much freedom of choice and control
*
*  c033 - Job satisfaction
*  Overall, how satisfied or dissatisfied are you with your job? 
*  1 Dissatisfied
*  10 Satisfied
* c034 - Job autonomy/choice.
********************.

USE ALL.
COMPUTE filter_$=(~missing(c034)) & (~missing(c033)) & (~missing(a173)).
VALUE LABELS filter_$ 0 'Not Selected' 1 'Selected'.
FORMATS filter_$ (f1.0).
FREQUENCIES filter_$.
FILTER BY filter_$.
EXECUTE.

FREQUENCIES VARIABLES=a173 c033  c034  
/STATISTICS mean STDDEV
  /ORDER=ANALYSIS.

CORRELATIONS
  /VARIABLES=a173 c033  c034 
  /PRINT=TWOTAIL NOSIG
  /STATISTICS DESCRIPTIVES
  /MISSING=PAIRWISE.

PARTIAL CORR
  /VARIABLES= a173 c033  BY c034
  /SIGNIFICANCE=TWOTAIL
  /MISSING=LISTWISE.

SORT CASES  BY s003.
SPLIT FILE LAYERED BY s003.
CORRELATIONS
  /VARIABLES=a173  c033 c034 
  /PRINT=TWOTAIL NOSIG
  /STATISTICS DESCRIPTIVES
  /MISSING=PAIRWISE.
SPLIT FILE OFF.

means tables= a173  by s003 .
