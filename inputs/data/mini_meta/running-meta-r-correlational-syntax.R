# this.dir <- dirname(rstudioapi::getActiveDocumentContext()$path)
# setwd(this.dir)
source("minimetacor.R")

idataset1 <- read.table("summary-time1.csv", header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
str(idataset1)
idataset1$Study

odataset1<-CorMeta(idataset1$R, idataset1$N,idataset1$Study)
str(odataset1)
PrintMetaResult(odataset1)
PrintPlotMetaR(odataset1)
PrintFunnelMetaR(odataset1)
predict(odataset1)
confint(odataset1)
baujat(odataset1)

idataset2 <- read.table("summary-time2.csv", header=TRUE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)
str(idataset2)
idataset2$Study

odataset2<-CorMeta(idataset2$R, idataset2$N,idataset2$Study)
str(odataset2)
PrintMetaResult(odataset2)
PrintPlotMetaR(odataset2)
PrintFunnelMetaR(odataset2)
predict(odataset2)
confint(odataset2)
baujat(odataset2)

