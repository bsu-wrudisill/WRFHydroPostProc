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
	dataPath <- '/scratch/leaf/WHv5_NWM_Tutorial/run_output/WH_SIM_channel_routing_00/'
    } else{
	dataPath <- args[1]
    }

#--------------------------------------
# ~~~~~~~ 1. Read Files  
#------------------------------------
lsmFiles <- list.files(path=dataPath, pattern='LDASOUT_DOMAIN', full.names=TRUE)
hydroFiles <- list.files(path=dataPath, pattern='LSMOUT_DOMAIN', full.names=TRUE)
flList <- list(lsm=lsmFiles, hydro=hydroFiles)

# variable list 
lsmVars   <- list(SWE='SNEQV', ACCET='ACCET')
#hydroVars <- list(streamflow='qlink1', smc1='sh2ox1', smc2='sh2ox2', smc3='sh2ox3', smc4='sh2ox4')

hydroVars <- list(smc1='sh2ox1', smc2='sh2ox2', smc3='sh2ox3', smc4='sh2ox4')
# overland flow excess (ofexs), volumetric soil moisture in layers 1-4 (smc-)

# list of vars 
varList <- list(lsm=lsmVars, hydro=hydroVars)

# function to apply 
basSum = function(var) sum(var) 
basMax = function(var) max(var) 
basAvg = function(var) mean(var) 

## indices to read; this step is very confusing and not well documented
# the indices are x,y,time
# each file has only one time step--so the last integer must be 1 for start and end 
# the first two integers (start, end) correspond with the min and max indices of the grid 

#
maxX <- 66   #!! CHANGE ME !! this is the maximum x dimension of the grid 
maxY <- 49   #!! CHANGE ME !! same, but Y dimensions. 
             # These can be found by doing ncdump -h <name of file>/ 
             # The indices are in the reverse order 

lsmInds   <- list(SNEQV=list(start=c(1,1,1), end=c(maxX,maxY,1), stat='basAvg'),  
		  ACCET=list(start=c(1,1,1), end=c(maxX,maxY,1), stat='basAvg')) 
#
#
#
hydroInds <- list(smc1=list(start=c(1,1,1), end=c(maxX,maxY,1), stat='basAvg'),
                  smc2=list(start=c(1,1,1), end=c(maxX,maxY,1), stat='basAvg'),
                  smc3=list(start=c(1,1,1), end=c(maxX,maxY,1), stat='basAvg'),
                  smc4=list(start=c(1,1,1), end=c(maxX,maxY,1), stat='basAvg'))

indList <- list(lsm=lsmInds, hydro=hydroInds)           # list of indices to pass into GetMuliNcdf
fileData <- GetMultiNcdf(file=flList,var=varList, ind=indList, parallel=FALSE)  # read netcdf files 
#
#
#--------------------------------------
# ~~~~~~~ 2. Create Plots 
#------------------------------------

ggplot(fileData, aes(x=POSIXct, y=value, color=fileGroup)) +
          geom_line() + geom_point() +
          facet_wrap(~variableGroup, scales='free_y', ncol=1) +
          scale_x_datetime(breaks = date_breaks("1 month")) + theme_bw()
