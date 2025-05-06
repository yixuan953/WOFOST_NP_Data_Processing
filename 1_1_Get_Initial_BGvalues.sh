#!/bin/bash
#-----------------------------Mail address-----------------------------

#-----------------------------Output files-----------------------------
#SBATCH --output=./HPC_Report/output_%j.txt
#SBATCH --error=./HPC_Report/error_output_%j.txt

#-----------------------------Required resources-----------------------
#SBATCH --time=600
#SBATCH --mem=250000

#--------------------Environment, Operations and Job steps-------------

# Step 1: Transform the gridtype from generic to lonlat (to avoid double lon in further steps)
# cdo setgrid,/lustre/nobackup/WUR/ESG/zhou111/Data/Raw/General/global.txt /lustre/nobackup/WUR/ESG/zhou111/Data/Raw/Slope/ddm30_slope_05d.nc /lustre/nobackup/WUR/ESG/zhou111/Data/Raw/Slope/ddm30_slope_05d_lonlat.nc

# Step 2: Merge all of the background values to one .nc file
module load cdo
module load nco
input_dir="/lustre/nobackup/WUR/ESG/zhou111/Data"
temp_dir="/lustre/nobackup/WUR/ESG/zhou111/WOFOST-NPcycling/Data/Temp"
output_dir="/lustre/nobackup/WUR/ESG/zhou111/WOFOST-NPcycling/Data"

# List of all of the background variables
declare -a VAR_LIST=(
  "oc,SOC,${input_dir}/Raw/Soil/hwsd_soil_data_on_cropland.nc"
  "bulk_density,bulk_density,${input_dir}/Raw/Soil/hwsd_soil_data_on_cropland.nc"
  "clay,clay_content,${input_dir}/Raw/Soil/hwsd_soil_data_on_cropland.nc"
  "NC_ratio,NC_ratio,${input_dir}/Para_N_Cycling/NCratio_05d.nc"
  "PC_ratio,PC_ratio,${input_dir}/Para_P_Cycling/PC_Ratio_05d.nc"
  "slope,slope,${input_dir}/Raw/Slope/ddm30_slope_05d_lonlat.nc"
  "texture_class,texture_class,${input_dir}/Raw/Soil/hwsd_soil_data_on_cropland.nc"
  "Al_Fe_ox,Al_Fe_ox,${input_dir}/Para_P_Cycling/Al_Fe_ox_05d.nc"
  "P_Olsen,P_Olsen,${input_dir}/Para_P_Cycling/POlsen_05d.nc"
  "TSMD_max,TSMD_max,${input_dir}/Para_N_Cycling/TSMD_max.nc"
  "Climate_Zone,Climate_Zone,${input_dir}/Para_N_Cycling/EF_N2O_Climate_Zone.nc"
)

Get_global_background_variable(){
    TMP_FILES=()
    for entry in "${VAR_LIST[@]}"; do
        IFS=',' read -r orig_var new_var src_file <<< "$entry"
        tmp_file="${temp_dir}/tmp_${new_var}.nc"
        echo "Processing $orig_var from $src_file → $new_var"
        cdo chname,${orig_var},${new_var} -selvar,${orig_var} ${src_file} ${tmp_file}
        TMP_FILES+=("${tmp_file}")
    done
    cdo merge "${TMP_FILES[@]}" ${temp_dir}/merged.nc
    mv ${temp_dir}/merged.nc ${output_dir}/Background_Values.nc

    # I am doing this because the slope is using its own lon for the reason that I don't know:
        # ncks -v slope ${temp_dir}/merged.nc ${temp_dir}/slope_only.nc
        # ncks -v lon ${temp_dir}/merged.nc ${temp_dir}/lon_only.nc
        # cdo sellonlatbox,-180,180,90,-90 ${temp_dir}/slope_only.nc ${temp_dir}/slope_fixed.nc
        # ncks -C -x -v lon_2 ${temp_dir}/slope_fixed.nc -O ${temp_dir}/slope_fixed.nc
        # ncks -A -v lon ${temp_dir}/lon_only.nc ${temp_dir}/slope_fixed.nc
        # # I replaced the ugly previous slope with the fixed one
        # ncks -C -x -v slope,lon_2 ${temp_dir}/merged.nc -O ${temp_dir}/other_vars.nc
        # ncks -A ${temp_dir}/slope_fixed.nc ${temp_dir}/other_vars.nc
        # mv ${temp_dir}/other_vars.nc ${output_dir}/Background_Values.nc

    # I fixed the lon of slope from the very beginning. Slope.nc file is using its own lon as its gridtype is generic, while others are lonlat. 

}
Get_global_background_variable