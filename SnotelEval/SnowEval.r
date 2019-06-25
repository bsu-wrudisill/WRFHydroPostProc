#-----------------------------------------------------------------------------
# PlotMultiNetCDF. 
# Description: create timeseries graphs of radiation, soil moisture, and SWE 
#              from WRFHydro output files. The script takes advantage of the 
#              'GetMultiNcdf' function from rwrfhydro which makes reading multiple
#              .nc files convenient 
# 
# Requirements: 'ncdf4','doMC', and 'ggplot' libraries to be installed in addition to 
# rwrfhydro 
# 
# Usage: Rscript WaterBalance.r <path_to_model_files>   (include trailing slash /) 
#-----------------------------------------------------------------------------

# Required Libraries 
library("rwrfhydro")
library("doMC")
library(ggplot2)
library(scales)


#--------------------------------------
# ~~~~~~~ 0. User input arguments ~~~~~~
#------------------------------------
args = commandArgs(trailingOnly=TRUE)
# test if there is at least one argument: if not, return an error
if (length(args)==0){
	print("usage: Rscript evalQcustom.R <dataPath>")
        print('No input arguments provided. using defaults')
	dataPath <- '/home/wrudisill/scratch/WRF_HYDRO-R2_WILLDEV/wy2010_SFPayette/ModelOut/'
	# dataPath <- '/scratch/wrudisill/WRFHydroPostProc/WRFHydro_TutorialData/'
	requestedLat <- 44.330000
	requestedLon <- -115.340000
    } else{
	dataPath <- args[1]
    	requestedLat <- args[2]
	requestedLon <- args[3]
	}

# --------------------------------------------------------------
# ~~~~~~~~~~~~~~ 1. Read local SNOTEL files ~~~~~~~~~~~~~~~~~~ # 
# --------------------------------------------------------------

df <- read.csv("439_26_WATERYEAR=2010.csv",skip=4,header=T,sep=",")
colnames(df) <- c('site','Time','NA','SWE1','SWE2')
#df$value <-  mean(df$SWE1, df$SWE2) # assing; this snotel has 2 sensors... for some reason
df$variableGroup <- 'snotelSWE'
df$POSIXct <- as.POSIXct(as.Date(df$Time, format="%Y-%m-%d"))
df$value <- df$SWE1
# --------------------------------------------------------------
# ~~~~~~~~~~~~~~ 2. Read Model SWE from LSM ~~~~~~~~~~~~~~~~~~~#  
# --------------------------------------------------------------

#
lsmFiles <- list.files(path=dataPath, pattern='LDASOUT_DOMAIN', full.names=TRUE)
flList <- list(lsm=lsmFiles)

# variable list 
lsmVars   <- list(SWE='SNEQV')

# list of vars 
varList <- list(lsm=lsmVars)

# function to apply 
basAvg = function(var) mean(var) 
basMax = function(var) max(var) 

#----  NOTE -------------------------------------------------------------------------------
# indices to read; this step is very confusing and not well documented
# the indices are x,y,time
# each file has only one time step--so the last integer must be 1 for start and end 
# the first two integers (start, end) correspond with the min and max indices of the grid 
#------------------------------------------------------------------------------------------


if(file.exists('modelSWE.csv')){
	print('file exists')
} else{
	domainPath<-'/home/wrudisill/scratch/WRF_HYDRO-R2_WILLDEV/wy2010_SFPayette/DOMAIN/'
	# ~~ Find the correct index the corresponds w/ the gauge location lat/lon
	# using a simple minimum distance formula
	SampleFile <- GetNcdfFile(paste0(domainPath,'wrfinput_d01.nc'), quiet=TRUE)  #
	distance <- sqrt((SampleFile$XLAT - requestedLat)^2 + (SampleFile$XLONG - requestedLon)^2)
	GaugeGridCell <- which(distance==min(distance), arr.ind = TRUE)
	xloc = GaugeGridCell[1]
	yloc = GaugeGridCell[2]	
	buffer = 2
	print(xloc)	
	print(yloc)
	# now read in the data at thost locations 
	lsmInds   <- list(SNEQV=list(start=c(xloc-buffer,yloc-buffer,1), end=c(xloc+buffer,yloc+buffer,1), stat='basAvg')) 
	indList <- list(lsm=lsmInds)
	fileData <- GetMultiNcdf(file=flList,var=varList, ind=indList, parallel=FALSE)  # read netcdf files 
	write.csv(fileData, file='modelSWE.csv')
}
#
#
#
modelColnams <-c('index','POSIXct','inds','stat','statArg','variable','value','variableGroup')
modelSWE<-read.csv('modelSWE.csv', header=T, sep=',')
modelSWE$POSIXct <- as.POSIXct(modelSWE$POSIXct)
modelSWE$variableGroup <- 'modelSWE'

selectCols <-c('POSIXct','value','variableGroup')


#------------------------------------------
# ~~~~~~~~~~~ 4. Merge Dataframeso ~~~~~~~~
#------------------------------------------
merged <- rbind(modelSWE[,selectCols], df[,selectCols])
merged$site_no <- 443
print(merged)


#------------------------------------------
# ~~~~~~~~~~~ 3. Create Plots ~~~~~~~~~~~~~
#------------------------------------------
ggplot(data = merged) + geom_line(aes(POSIXct, value, color=variableGroup)) + facet_wrap(~site_no, ncol = 1) + ylim(0,80)
