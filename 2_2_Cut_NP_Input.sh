#!/bin/bash
#-----------------------------Mail address-----------------------------

#-----------------------------Required resources-----------------------
#SBATCH --time=600
#SBATCH --mem=250000

#-----------------------------Output files-----------------------------
#SBATCH --output=./HPC_Report/output_%j.txt
#SBATCH --error=./HPC_Report/error_output_%j.txt

#--------------------Environment, Operations and Job steps-------------
module load cdo

CropTypes=('mainrice' 'secondrice' 'springwheat' 'winterwheat' 'soybean' 'maize')
StudyAreas=('Indus' 'LaPlata' 'Rhine' 'Yangtze')

input_dir="/lustre/nobackup/WUR/ESG/zhou111/WOFOST-NPcycling/Data"
output_dir="/lustre/nobackup/WUR/ESG/zhou111/WOFOST-NPcycling/Data/CaseStudy_NPInput"
temp_dir="/lustre/nobackup/WUR/ESG/zhou111/WOFOST-NPcycling/Data/Temp"

Cut_NP_input(){

    for StudyArea in "${StudyAreas[@]}"; do
       example_mask_file="/lustre/nobackup/WUR/ESG/zhou111/Model_Results/1_Yp_WOFOST/${StudyArea}/${StudyArea}_maize_Yp_mask.nc" # Using maize as common crop 
       # Skip if example mask file doesn't exist
       if [[ ! -f "${example_mask_file}" ]]; then
           echo "Warning: Example mask file ${example_mask_file} not found. Skipping ${StudyArea}."
           continue
       fi

       echo "Processing study area: ${StudyArea}"
       
       mask_output_dir="${output_dir}/${StudyArea}"
       mkdir -p "${mask_output_dir}"

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
        echo "Cropping background values for ${StudyArea} with: ${lonlat}"

        for croptype in "${CropTypes[@]}"; do
            input_file="${input_dir}/${croptype}_NPinput_1980_2020.nc"
            output_file="${mask_output_dir}/${StudyArea}_${croptype}_NPinput_1980-2020.nc"

            if [[ -f "${input_file}" ]]; then
                echo "Processing ${croptype} for ${StudyArea}..."
                # Cut the NP input for the study area
                cdo ${lonlat} "${input_file}" "${output_file}" # Cut the NP input file
                echo "Saved NP input for ${StudyArea}, ${croptype} to ${output_file}"
            else
                echo "${StudyArea} does not plant ${croptype}, skipping..."
            fi
        done

    done
}

Cut_NP_input