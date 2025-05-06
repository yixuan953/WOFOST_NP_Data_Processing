# This code is used to transform the gridtype from generic to lonlat
import xarray as xr
import numpy as np
import sys

def generic_to_lonlat(input_path, output_path):
   ds = xr.open_dataset(input_path)
   gridtype = ds.attrs.get('gridtype', None)

   lon = np.linspace(-179.75, 179.75, 720)  # Longitude in [-180, 180]
   ds = ds.assign_coords(lon=("lon", lon))  # Ensure lon is assigned to the correct dim (lon)

   # List of possible time dimension names
   time_dims = ['time', 'month', 'year', 'years']

   # Check if any of the time dimension names exist in the dataset
   time_dim_found = None
   for time_dim in time_dims:
      if time_dim in ds.dims:
         time_dim_found = time_dim
         break

   # If time dimension is found, transpose accordingly
   if time_dim_found:
      ds = ds.transpose(time_dim_found, 'lat', 'lon', ...)  # Use the first found time dimension
   else:
      # If no time dimension, just transpose with lat, lon
      ds = ds.transpose('lat', 'lon', ...)

   # Ensure 'grid_type' attribute is retained (if CDO didn't do this)
   ds.attrs['gridtype'] = gridtype if gridtype else 'lonlat'  # This is the key part to keep the grid type as lonlat
   ds.to_netcdf(output_path)
   print(f"{output_path} has been saved")

if __name__ == "__main__":
    input_path = sys.argv[1]
    output_path = sys.argv[2]
    generic_to_lonlat(input_path, output_path)