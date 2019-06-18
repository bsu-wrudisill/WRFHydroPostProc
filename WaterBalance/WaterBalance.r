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
	dataPath <- '/scratch/wrudisill/WRF_HYDRO-R2_WILLDEV/wy2010_SFPayette/ModelOut/'
    } else{
	dataPath <- args[1]
    }

#--------------------------------------
# ~~~~~~~ 1. Read Files  
#------------------------------------
lsmFiles <- list.files(path=dataPath, pattern='LDASOUT_DOMAIN', full.names=TRUE)
hydroFiles <- list.files(path=dataPath, pattern='HYDRO_RST', full.names=TRUE)
flList <- list(lsm=lsmFiles, hydro=hydroFiles)

# variable list 
lsmVars   <- list(SWE='SNEQV', ACCET='ACCET')
hydroVars <- list(streamflow='qlink1', smc1='sh2ox1', smc2='sh2ox2', smc3='sh2ox3', smc4='sh2ox4')
varList <- list(lsm=lsmVars, hydro=hydroVars)

# function to apply 
basSum = function(var) sum(var) 
basMax = function(var) max(var) 

## indices to read; this step is very confusing and not well documented
## still trying to decipher what is going on here  
lsmInds   <- list(SNEQV=list(start=c(1,1,1), end=c(3,2,1), stat='basSum'),
		  ACCET=list(start=c(1,1,1), end=c(3,2,1), stat='basSum'))
                 
#
hydroInds <- list(qlink1=1,
                  smc1=list(start=c(1,1), end=c(2,2), stat='basSum'),
                  smc2=list(start=c(1,1), end=c(2,2), stat='basSum'),
                  smc3=list(start=c(1,1), end=c(2,2), stat='basSum'),
                  smc4=list(start=c(1,1), end=c(2,2), stat='basSum'))


indList <- list(lsm=lsmInds, hydro=hydroInds)           # list of indices to pass into GetMuliNcdf
fileData <- GetMultiNcdf(file=flList,var=varList, ind=indList, parallel=FALSE)  # read netcdf files 
head(fileData)

#--------------------------------------
# ~~~~~~~ 2. Create Plots 
#------------------------------------


ggplot(fileData, aes(x=POSIXct, y=value, color=fileGroup)) +
          geom_line() + geom_point() +
          facet_wrap(~variableGroup, scales='free_y', ncol=1) +
          scale_x_datetime(breaks = date_breaks("1 month")) + theme_bw()
