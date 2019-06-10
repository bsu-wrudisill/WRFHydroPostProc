## See the vignette "WRF Hydro Domain and Channel Visualization", for details.
## Not run:
library('rwrfhydro')
dataPath <- '/scratch/wrudisill/WRF_HYDRO-R2_WILLDEV/wy2010_SFPayette'

# ....
chFiles = list.files(path=dataPath, pattern='CHRTOUT_DOMAIN2', full.names=TRUE)
hydroVars <- list(Q='streamflow') # lat='latitude',lon='longitude')
hydroInds<- list(streamflow=1)

# construct lists
fileList <- list(hydro=chFiles)
varList <- list(hydro=hydroVars)
indList <- list(hydro=hydroInds)

fileData <- GetMultiNcdf(file=fileList,var=varList, ind=indList, parallel=FALSE)
print(fileData)

# write CSV file 
write.csv(fileData, file="qTest.csv")
