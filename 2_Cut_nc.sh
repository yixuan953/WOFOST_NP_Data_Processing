#!/bin/bash
#-----------------------------Mail address-----------------------------

#-----------------------------Output files-----------------------------
#SBATCH --output=./HPC_Report/output_%j.txt
#SBATCH --error=./HPC_Report/error_output_%j.txt

#-----------------------------Required resources-----------------------
#SBATCH --time=600
#SBATCH --mem=250000

#--------------------Environment, Operations and Job steps-------------
module load cdo
module load nco

CropTypes=('mainrice' 'secondrice' 'springwheat' 'winterwheat' 'soybean' 'maize')
StudyAreas=('Indus' 'LaPlata' 'Rhine' 'Yangtze')

input_dir="/lustre/nobackup/WUR/ESG/zhou111/Model_Results/1_Yp_WOFOST"
output_dir="/lustre/nobackup/WUR/ESG/zhou111/WOFOST-NPcycling/Data/CaseStudy_Mask"

#!/bin/bash
#-----------------------------Mail address-----------------------------

#-----------------------------Output files-----------------------------
#SBATCH --output=./HPC_Report/output_%j.txt
#SBATCH --error=./HPC_Report/error_output_%j.txt

#-----------------------------Required resources-----------------------
#SBATCH --time=600
#SBATCH --mem=250000

#--------------------Environment, Operations and Job steps-------------
module load cdo
module load nco
module load netcdf

CropTypes=('mainrice' 'secondrice' 'springwheat' 'winterwheat' 'soybean' 'maize')
StudyAreas=('Indus' 'LaPlata' 'Rhine' 'Yangtze')

input_dir="/lustre/nobackup/WUR/ESG/zhou111/Model_Results/1_Yp_WOFOST"
output_dir="/lustre/nobackup/WUR/ESG/zhou111/WOFOST-NPcycling/Data/CaseStudy_Mask"
temp_dir="/lustre/nobackup/WUR/ESG/zhou111/WOFOST-NPcycling/Data/Temp"

Cut_merge_nc(){

    background_value="/lustre/nobackup/WUR/ESG/zhou111/WOFOST-NPcycling/Data/Background_Values.nc" # The global background values .nc file
    
    # regridded_bg="${temp_dir}/regridded_background.nc"
    
    # # Create a reference grid file directly using the example mask file
    # echo "Setting up reference grid..."
    # example_mask="/lustre/nobackup/WUR/ESG/zhou111/Data/Crop_Mask/SPAM2005/maize_mask.nc"
    
    # # Check if we have the example mask for reference
    # if [[ ! -f "${example_mask}" ]]; then
    #     echo "ERROR: Cannot find example mask file. Please check paths."
    #     exit 1
    # fi
    
    # # Simple direct regridding without time dimension
    # echo "Regridding background values..."
    # cdo remapbil,${example_mask} ${background_value} ${regridded_bg}

    for StudyArea in "${StudyAreas[@]}"; do
       echo "Processing study area: ${StudyArea}"
       
       example_mask_file="${input_dir}/${StudyArea}/${StudyArea}_maize_Yp_mask.nc" # Using maize as common crop
       mask_output_dir="${output_dir}/${StudyArea}"
       mkdir -p "${mask_output_dir}"
       
       # Skip if example mask file doesn't exist
       if [[ ! -f "${example_mask_file}" ]]; then
           echo "Warning: Example mask file ${example_mask_file} not found. Skipping ${StudyArea}."
           continue
       fi

       cropped_bg="${mask_output_dir}/temp_cropped.nc"
       
       # Extract bounding box coordinates from the example mask file
       echo "Extracting bounding box for ${StudyArea}..."
       lonlat=$(cdo -s griddes "${example_mask_file}" | awk '
            /xfirst/ {xfirst=$3}
            /xinc/   {xinc=$3}
            /xsize/  {xsize=$3}
            /yfirst/ {yfirst=$3}
            /yinc/   {yinc=$3}
            /ysize/  {ysize=$3}
            END {
                xlast = xfirst + (xsize - 1) * xinc
                ylast = yfirst + (ysize - 1) * yinc

                if (xfirst > xlast) {
                    temp = xfirst; xfirst = xlast; xlast = temp;
                }
                if (yfirst > ylast) {
                    temp = yfirst; yfirst = ylast; ylast = temp;
                }

                printf "sellonlatbox,%f,%f,%f,%f", xfirst, xlast, yfirst, ylast;
            }'
        )

                
        echo "Cropping background values with: ${lonlat}"
        cdo ${lonlat} "${background_value}" "${cropped_bg}" # Cut the range

        for croptype in "${CropTypes[@]}"; do
            mask_file="${input_dir}/${StudyArea}/${StudyArea}_${croptype}_Yp_mask.nc"
            output_file="${mask_output_dir}/${StudyArea}_${croptype}_mask.nc"

            if [[ -f "${mask_file}" ]]; then
                echo "Processing ${croptype} for ${StudyArea}..."
                cdo merge "${cropped_bg}" "${mask_file}" "${output_file}"
                echo "Saved mask for ${StudyArea}, ${croptype} to ${output_file}"
            else
                echo "${StudyArea} does not plant ${croptype}, skipping..."
            fi
        done
        
        # Clean up temporary files
    done
    
    # Clean up global temporary files
    echo "All processing complete!"
}

Cut_merge_nc