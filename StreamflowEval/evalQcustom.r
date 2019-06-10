# Evaluate streamflow observations
library(dataRetrieval)
library(data.table)
library(ggplot2)
library(foreach)
library(rwrfhydro)


#~~~~~~ Download USGS streamflow to evaluate. Uses the USGS 'data retrieval' package~~~~~~
# we already know the USGS gauge IDs that match the forecast points we have modelled

gageID <- c("13235000")
obsDF <- readNWISuv(siteNumbers=gageID, parameterCd="00060", startDate="2009-10-01", endDate="2010-09-30")
# for some reason I'm getting a "error 503 not found error some times... but not evety time... when i try to run the above line. wtf.

colnames(obsDF) <- c("agency","site_no","dateTime","streamflow_cfs","quality_flag", "time_zone")
obsDF$q_cms <- obsDF$streamflow_cfs/35.31 

#find the "reference file" from the test case. This file contains the index number of the gauge (i.e. 1, 2, 3, etc)
modelOutputPath <- "./qTest.csv"

# rename 
colNames <- c("","dateTime","inds","stat","statArg","variable","q_cms","variableGroup","fileGroup")
simQ <- read.csv(modelOutputPath, col.names =colNames) 
simQ$site_no <- gageID


#~~~~~~ Create a ggplot of the observations versus the model simulation ~~~~~~~# 
obsDF$run <- "Observation"
simQ$run <- "Gridded Baseline"
selected_cols<-c("dateTime", "site_no", "q_cms","run")


#head(obsDF[,selected_cols])
#head(simQ[,selected_cols])
# merge the observations and model data frames w/ only the most important columns
merged <- rbind(obsDF[,selected_cols], simQ[,selected_cols])
#
# make sure that the station number is numeric, not a character
#merged$station <- as.numeric(merged$station)

tail(merged)


# plot the data
ggplot(data = merged) + geom_line(aes(dateTime, q_cms, color=run)) + facet_wrap(~site_no, ncol = 1)

