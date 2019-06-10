library('rwrfhydro')

requestedLat = 44.10402 
requestedLon = -115.59

foo <- GetNcdfFile('/scratch/wrudisill/WRF_HYDRO-R2_WILLDEV/wy2010_SFPayette/201009300000.CHRTOUT_DOMAIN2', quiet=TRUE)

distance = sqrt((foo$lat - requestedLat)^2 + (foo$lon - requestedLon)^2)
which(distance==min(distance))
