import xarray as xr
import numpy as np
import sys

def assign_lon_and_save(input_path, output_path):
    ds = xr.open_dataset(input_path)
    lon = np.linspace(-179.75, 179.75, 720)
    ds = ds.assign_coords(lon=("lon", lon))
    ds = ds.transpose(..., 'lat', 'lon')
    ds.to_netcdf(output_path)

if __name__ == "__main__":
    input_path = sys.argv[1]
    output_path = sys.argv[2]
    assign_lon_and_save(input_path, output_path)