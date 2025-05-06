#!/bin/bash
#-----------------------------Mail address-----------------------------

#-----------------------------Output files-----------------------------
#SBATCH --output=./HPC_Report/output_%j.txt
#SBATCH --error=./HPC_Report/error_output_%j.txt

#-----------------------------Required resources-----------------------
#SBATCH --time=600
#SBATCH --mem=250000

#--------------------Environment, Operations and Job steps-------------
# module load cdo

CropTypes=('mainrice' 'secondrice' 'springwheat' 'winterwheat' 'soybean' 'maize')

# The N, P input .nc file will contain 7 variables
N_manure_dir="/lustre/nobackup/WUR/ESG/zhou111/Data/Fertilization/N_Fert_Man_Inorg_1961-2020/N_Manure_app_rate_05d"
N_inorganic_dir="/lustre/nobackup/WUR/ESG/zhou111/Data/Fertilization/N_Fert_Man_Inorg_1961-2020/N_Inorg_app_rate_05d" # Contains Urea + Others

P_manure_dir="/lustre/nobackup/WUR/ESG/zhou111/Data/Fertilization/N_Fert_Man_Inorg_1961-2020/P_Manure_app_rate_05d"
P_inorganic_dir="/lustre/nobackup/WUR/ESG/zhou111/Data/Fertilization/P_Fert_Inorg_1961-2019/P_Inorg_AppRate_05d"

N_EF_NOX="/lustre/nobackup/WUR/ESG/zhou111/Data/Para_N_Cycling/EF_NOx.nc"
Res_return_ratio="/lustre/nobackup/WUR/ESG/zhou111/Data/Fertilization/NP_Fert_Res/Return_ratio_05d_latCorr.nc"

output_dir="/lustre/nobackup/WUR/ESG/zhou111/WOFOST-NPcycling/Data"
temp_dir="/lustre/nobackup/WUR/ESG/zhou111/WOFOST-NPcycling/Data/Temp"


Get_global_NP_input(){

    for CropName in "${CropTypes[@]}"; do
    # Here we assume that wheat (or rice) that is planted in different seasons have the same fertilizer application rate
        if [[ "$CropName" == "springwheat" || "$CropName" == "winterwheat" ]]; then
            Crop="wheat"
        elif [[ "$CropName" == "mainrice" || "$CropName" == "secondrice" ]]; then
            Crop="rice"
        else
            Crop="$Crop"      
        fi
        
        CropCap="${Crop^}"  # Capitalize first letter
        

        # List of all of the background variables
        # orig_var new_var src_file
        declare -a VAR_LIST=(
            "Manure_N_application_rate,Manure_N_appRate,${N_manure_dir}/N_manure_app_rate_${CropCap}_1961-2020.nc" # Grid type: generic
            "Inorg_N_application_rate,Other_inorg_N_appRate,${N_inorganic_dir}/N_inorg_app_rate_${CropCap}_1961-2020.nc" # Grid type: generic
            "Urea_N_application_rate,Urea_inorg_N_appRate,${N_inorganic_dir}/N_urea_app_rate_${CropCap}_1961-2020.nc" # Grid type: generic

            "Manure_P_application_rate,Manure_P_appRate,${P_manure_dir}/P_manure_app_rate_${CropCap}_1961-2020.nc" # Grid type: generic
            "P_application_rate,Inorg_P_appRate,${P_inorganic_dir}/${CropCap}_P_AppRate_1961-2020.nc" # Grid type: generic

            "EF_NOx,EF_NOx,${N_EF_NOX}" # Grid type: generic
            "Return_Ratio,Res_return_ratio,${Res_return_ratio}" # Grid type: generic
        )

        TMP_FILES=()

        for entry in "${VAR_LIST[@]}"; do
            IFS=',' read -r orig_var new_var src_file <<< "$entry"
            tmp_file="${temp_dir}/tmp_${new_var}.nc"
            # tmp_file_lonlat="${temp_dir}/tmp_${new_var}_lonlat.nc"
            echo "Processing $orig_var from $src_file → $new_var"
            
            # Change variable name
            cdo chname,${orig_var},${new_var} -selvar,${orig_var} ${src_file} ${tmp_file}

            # Call the Python script to assign longitude and save
            # python /lustre/nobackup/WUR/ESG/zhou111/WOFOST-NPcycling/Code/0_Assign_lonlat.py "${tmp_file}" "${tmp_file_lonlat}"

            TMP_FILES+=("${tmp_file}")

        done

        # Merge and move output
        cdo merge "${TMP_FILES[@]}" "${temp_dir}/${CropName}_merged_NPinput.nc"
        # mv "${temp_dir}/${Crop}_merged_NPinput.nc" "${output_dir}/${CropName}_NPinput.nc"
        rm -f "${temp_dir}/tmp_"*.nc
    done 

}

# Get_global_NP_input


# Align the time dimension (1980 - 2020)
module load python/3.12.0
python /lustre/nobackup/WUR/ESG/zhou111/WOFOST-NPcycling/Code/1_2_Align_time.py