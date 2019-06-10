from netCDF4 import Dataset
import xarray as xr
import glob
from matplotlib import pyplot as plt 

dirc=glob.glob('/scratch/wrudisill/WRF_HYDRO-R2_WILLDEV/wy2010_SFPayette/*.CHRTOUT_DOMAIN2')
mf = xr.open_mfdataset(dirc)

#index = 1
##oneStation = mf['streamflow'][:,index]
#plt.plot(oneStation)
##plt.savefig('test')
