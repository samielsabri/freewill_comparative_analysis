# mini meta analyses correlations functions


# Installing all the required packages for this analysis (if not already installed)
list.of.packages <- c("car", "foreign", "metafor", "Hmisc", "pequod", "openxlsx", "readxl")

new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, dependencies = TRUE)

lapply(list.of.packages, library, character.only = TRUE)


PrintMetaResult  <- function (metadataframe) {
  print(summary(metadataframe))

}

PrintPlotMetaR  <- function (metadataframe) {
  forest(metadataframe, xlab="Correlation", alim=c(-1,1))
}

PrintFunnelMetaR  <- function (metadataframe) {

  
  funnel(metadataframe,
         level=0.95, 
         xlim=c(-1,1))
  legend(-.6, 0.0,
         c("0.1 > p > 0.05", "0.05 > p > 0.01", "< 0.01"),
         fill=c("darkgrey", "grey", "lightgrey"))
  
}

CorMeta <- function (Correlation, SampleSize, StudyName) {

  set.seed(513131)
  dat <- escalc(measure = "COR", ri = Correlation, ni = SampleSize, append = TRUE)
  mod <- rma(Correlation, vi, method = "REML", data = dat)
  
  return (mod)
}

CorMetaES <- function (Correlation, SampleSize, StudyName) {

  set.seed(513131)
  dat <- escalc(measure = "COR", ri = Correlation, ni = SampleSize, append = TRUE)
  mod <- rma(Correlation, vi, method = "REML", data = dat)
  
  return (mod$b[1])
}

CorMetaESlow <- function (Correlation, SampleSize, StudyName) {
  
  set.seed(513131)
  dat <- escalc(measure = "COR", ri = Correlation, ni = SampleSize, append = TRUE)
  mod <- rma(Correlation, vi, method = "REML", data = dat)
  
  return (mod$ci.lb)
}

CorMetaEShigh <- function (Correlation, SampleSize, StudyName) {
  
  set.seed(513131)
  dat <- escalc(measure = "COR", ri = Correlation, ni = SampleSize, append = TRUE)
  mod <- rma(Correlation, vi, method = "REML", data = dat)
  
  return (mod$ci.ub)
}

