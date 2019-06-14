# Evaluate streamflow observations
library(dataRetrieval)
library(data.table)
library(ggplot2)
library(foreach)
library(rwrfhydro)

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#
#~~~~~~~~~~~~~~~ Part 0 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~# 
#  User Parameters 
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#

dataPath <- '/scratch/wrudisill/WRF_HYDRO-R2_WILLDEV/wy2010_SFPayette'    # location of model output files. this will only be read in if a CSV does not yet exist for the gauge point 
startDate <- "2009-10-01"
endDate <- "2010-09-30"
gageID        <- c("13235000")
modelOutputCSV <- "discharge.csv"        # this will either be read in (if it exists) or created. Perhaps create a better name for this file 
#GaugeGridCell <- 1   # this is the index point of the river grid cell. 1 is the channel outlet.


#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#
#~~~~~~~~~~~~~~~ Part 2 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~# 
# read the USGS data and station information 
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#

obsDF <- readNWISuv(siteNumbers=gageID, parameterCd="00060", startDate=startDate, endDate=endDate)  #discharge
stationInfo <- readNWISsite(siteNumbers=gageID)
requestedLat <- stationInfo$dec_lat_va         #44.080834 latitude of gauge point
requestedLon <- stationInfo$dec_lon_va         #-115.618558 longitude of gauge point 


#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#
#~~~~~~~~~~~~~~~ Part 2 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~# 
# Create a CSV file of discharge for the grid cell that corresponds 
# w/ the guage we are interested in. 
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#

# Check if a csv od model outputs exists 
if(file.exists(modelOutputCSV)){
	print("file exists")

} else{
	# if the csv does not exist, then read the files and write the csv
	print("file does not exist. Reading from...")
	print(dataPath)
       
       	# format the date ... this is just so we can pick out a (single) file to read 
	# gauge locations and lat/lon points 
	dateSplit = unlist(strsplit(startDate, "-"))
	yr=dateSplit[1]
	mo=dateSplit[2]
	day=dateSplit[3]

	# ~~ Find the correct index the corresponds w/ the gauge location lat/lon
	# using a simple minimum distance formula
	SampleFile <- GetNcdfFile(paste0(yr,mo,day,'0000.CHRTOUT_DOMAIN2'), quiet=TRUE)  #
	distance <- sqrt((SampleFile$lat - requestedLat)^2 + (SampleFile$lon - requestedLon)^2)
	GaugeGridCell <- which(distance==min(distance))
	
	# create lists to pass into the multinc function
	chFiles <- list.files(path=dataPath, pattern='CHRTOUT_DOMAIN2', full.names=TRUE)
	hydroVars <- list(Q='streamflow') # lat='latitude',lon='longitude')
	hydroInds <- list(streamflow=GaugeGridCell)

	# construct lists
	fileList <- list(hydro=chFiles)
	varList  <- list(hydro=hydroVars)
	indList  <- list(hydro=hydroInds)
	fileData <- GetMultiNcdf(file=fileList,var=varList, ind=indList, parallel=FALSE)

	# write CSV file 
	write.csv(fileData, file=modelOutputCSV)
}

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#
#~~~~~~~~~~~~~~~ Part 3 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~# 
# Update the data frames that we have read/created above.
# Create plots comparing model and obs
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#

colnames(obsDF) <- c("agency","site_no","dateTime","streamflow_cfs","quality_flag", "time_zone")
obsDF$q_cms <- obsDF$streamflow_cfs/35.31 

#Read the model output CSV
colNames <- c("","dateTime","inds","stat","statArg","variable","q_cms","variableGroup","fileGroup")
simQ <- read.csv(modelOutputCSV, col.names =colNames) 
simQ$site_no <- gageID


# Create a ggplot of the observations versus the model simulation ~~~~~~~# 
obsDF$run <- "Observation"
simQ$run <- "Gridded Baseline"
selected_cols<-c("dateTime", "site_no", "q_cms","run")

# merge data 
merged <- rbind(obsDF[,selected_cols], simQ[,selected_cols])

# plot the data
ggplot(data = merged) + geom_line(aes(dateTime, q_cms, color=run)) + facet_wrap(~site_no, ncol = 1)
