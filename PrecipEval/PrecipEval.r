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
if (length(args)!=5){
	print("usage: Rscript evalQcustom.R <dataPath>")
        print('No input arguments provided. using defaults')
#	dataPath <-'/home/wrudisill/scratch/WRF_HYDRO-R2_WILLDEV/example_case/FORCING'
	dataPath <-'scratch/leaf/WHv5_NWM_Tutorial/input_data/'
	baseName <-'wrfout_d01'
	yy <- 2010
	mm <- 06
	dd <- 01
} else{
	dataPath <- args[1]
	baseName <- args[2]
	yy <- args[3]
	mm <- args[4]
	dd <- args[5]
    }

#--------------------------------------
# ~~~~~~~ 1. Read Files  
#------------------------------------
forcFiles <- list.files(path=dataPath, pattern='wrfout_d01', full.names=TRUE)
flList <- list(forc=forcFiles)


# variable list 
forcVars   <- list(ACCRAIN='RAINNC')
varList <- list(forc=forcVars) 

# function to apply 
basMean= function(var) mean(var) 

## indices to read (this step is very confusing and not well documented)
## apply mean to the chosen indices
forcInds   <- list(forcVars=list(start=c(1,1,1), end=c(49,49,1), stat='basMean'))
#
indList <- list(forc=forcInds) 
fileData <- GetMultiNcdf(file=flList,var=varList, ind=indList, parallel=FALSE)  # read netcdf files 
fileData$POSIXct <- seq.POSIXt(from=ISOdate(yy,mm,dd), by='hour', length.out=length(forcFiles))

#
#--------------------------------------

# ~~~~~~~ 2. Create Plots 
#------------------------------------

ggplot(fileData, aes(x=POSIXct, y=value, color=fileGroup)) +
          geom_line() + geom_point() +
          facet_wrap(~variableGroup, scales='free_y', ncol=1) +
          scale_x_datetime(breaks = date_breaks("1 day")) + theme_bw()
