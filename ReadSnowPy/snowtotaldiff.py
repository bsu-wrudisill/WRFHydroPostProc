from matplotlib import pyplot as plt
import numpy as np
import matplotlib as mpl
import sys
from netCDF4 import Dataset 
import glob

#
#uncoupled="/home/wrudisill/WRF_HYDRO-R2/WRF_HydroRun_ControlControlForcing/Model_Out/199803270000.LDASOUT_DOMAIN2"
#coupled="/home/wrudisill/scratch/WRF_PROJECTS/MSthesisRuns/wrf_cfsr_1998-03-19_00__1998-03-27_00/wrf_out/wrfout_d02_1998-03-27_00:00:00"

print sys.argv[1],sys.argv[2]
def ReadSnow(fname):
    try:
        var="SNOW"
        ds = Dataset(fname)[var][0,:,:] 
    except:
        var="SNEQV"
        ds = Dataset(fname)[var][0,:,:] 
    finally: 
        return ds        

diff = ReadSnow(sys.argv[1]) - ReadSnow(sys.argv[2]) 

'''
Positive Regions (red in the centered bwr colorscheme) mean that the SWE (on the ground) is greater in the WRF-coupled case than in the uncoupled case which was forced by the control forcings. Generally for the HS scenario, positive regions lie on the Western side and negative regions are to the East. There are also areas with red pixels in the 
'''


plt.imshow(diff[::-1,:], cmap="bwr")
plt.colorbar()
#plt.savefig("diff_finalsnow.png")
#plt.savefig('Ebudget_Whole_D02', dpi=500)
#plt.show()
plt.savefig(sys.argv[3])
