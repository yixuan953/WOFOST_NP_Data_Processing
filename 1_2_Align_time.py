import xarray as xr
import numpy as np

# Define helper function to expand variable over missing years
def fill_and_reindex(var, orig_years):
    # Reindex to target years, using nearest fill (bfill then ffill)
    var_expanded = var.reindex(year=target_years, method='nearest', tolerance=None)
    return var_expanded

crop_types = ["secondrice", "soybean", "maize", "springwheat", "winterwheat"] # ["mainrice", "secondrice", "soybean", "maize", "springwheat", "winterwheat"]

for crop in crop_types:
    # Load the original NetCDF
    ds = xr.open_dataset(f"/lustre/nobackup/WUR/ESG/zhou111/WOFOST-NPcycling/Data/Temp/{crop}_merged_NPinput.nc")

    # Target year range
    target_years = np.arange(1981, 2021)

    # Output dataset
    output_ds = xr.Dataset()
    lat = ds.lat
    lon = ds.lon

    # Process each variable by its time dimension
    for var_name in ds.data_vars:
        var = ds[var_name]
        
        if 'year' in var.dims:
            var = var.rename({'year': 'year'})
            orig_years = ds['year'].values
            var = fill_and_reindex(var, orig_years)
        elif 'year_2' in var.dims:
            var = var.rename({'year_2': 'year'})
            orig_years = ds['year_2'].values
            var = fill_and_reindex(var, orig_years)
        elif 'year_3' in var.dims:
            var = var.rename({'year_3': 'year'})
            orig_years = ds['year_3'].values
            var = fill_and_reindex(var, orig_years)
        elif 'time' in var.dims:
            # Convert time to datetime then extract year
            var = var.copy()
            ds['time'] = xr.decode_cf(ds).time
            years = ds['time'].dt.year
            var = var.assign_coords(year=('time', years.data))
            var = var.swap_dims({'time': 'year'})
            var = var.groupby('year').mean(dim='year')  # optional aggregation
            var = var.reindex(year=target_years, method='nearest')
        else:
            # Variable has no time dimension; copy as-is
            output_ds[var_name] = var
            continue

        output_ds[var_name] = var

    # Add coordinate
    output_ds['year'] = ('year', target_years)
    output_ds['lat'] = lat
    output_ds['lon'] = lon

    # Save result
    output_ds.to_netcdf(f"/lustre/nobackup/WUR/ESG/zhou111/WOFOST-NPcycling/Data/Temp/{crop}_NPinput_1981_2020.nc")