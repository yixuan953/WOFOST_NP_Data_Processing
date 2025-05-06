# This code is used to transform the gridtype of slope .nc file from generic to lonlat

import xarray as xr
import numpy as np

# Open generic file
ds = xr.open_dataset('/lustre/nobackup/WUR/ESG/zhou111/Data/Raw/Slope/ddm30_slope_05d.nc')

# Create longitude array to match the known grid
lon = np.linspace(-179.75, 179.75, 720)
ds = ds.assign_coords(lon=("lon", lon))

# Rearrange dimensions if necessary
ds = ds.transpose(..., 'lat', 'lon')  # Ensure order if needed

# Save to new file
ds.to_netcdf('/lustre/nobackup/WUR/ESG/zhou111/Data/Raw/Slope/ddm30_slope_05d_lonlat.nc')