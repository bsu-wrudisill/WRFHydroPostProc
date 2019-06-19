#-----------------------------------------------------------------------------
# PlotMultiNetCDF. 
# Description: create timeseries graphs of precipitation. Precipitation comes from the forcing files
#               (it cannot be found in the model output files!) 
# 
# Requirements: 'ncdf4','doMC', and 'ggplot' libraries to be installed in addition to 
# rwrfhydro 
# 
# Usage: Rscript PrecipEval.r <path_to_forcing_files>   (include trailing slash /) 
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
	#dataPath <- '/home/wrudisill/scratch/WRFHydroForcings/wy2010/d02'
	dataPath <-'/home/wrudisill/scratch/WRF_HYDRO-R2_WILLDEV/example_case/FORCING'
    } else{
	dataPath <- args[1]
    }

#--------------------------------------
# ~~~~~~~ 1. Read Files  
#------------------------------------
forcFiles <- list.files(path=dataPath, pattern='LDASIN', full.names=TRUE)
flList <- list(forc=forcFiles)

# variable list 
forcVars   <- list(RAINRATE='RAINRATE')
varList <- list(forc=forcVars) 

# function to apply 
basMean= function(var) mean(var) 

## indices to read; this step is very confusing and not well documented
## still trying to decipher what is going on here  
forcInds   <- list(forcVars=list(start=c(1,1,1), end=c(3,2,1), stat='basMean'))
#

indList <- list(forc=forcInds) 
fileData <- GetMultiNcdf(file=flList,var=varList, ind=indList, parallel=FALSE)  # read netcdf files 
head(fileData)

#--------------------------------------
# ~~~~~~~ 2. Create Plots 
#------------------------------------


ggplot(fileData, aes(x=POSIXct, y=value, color=fileGroup)) +
          geom_line() + geom_point() +
          facet_wrap(~variableGroup, scales='free_y', ncol=1) +
          scale_x_datetime(breaks = date_breaks("1 month")) + theme_bw()
