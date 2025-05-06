#!/bin/bash
#-----------------------------Mail address-----------------------------

#-----------------------------Output files-----------------------------
#SBATCH --output=./HPC_Report/output_%j.txt
#SBATCH --error=./HPC_Report/error_output_%j.txt

#--------------------Environment, Operations and Job steps-------------
module load cdo
module load nco
module load netcdf

CropTypes=('mainrice' 'secondrice' 'springwheat' 'winterwheat' 'soybean' 'maize')
StudyAreas=('Indus' 'LaPlata' 'Rhine' 'Yangtze')

input_dir=""
output_dir="/lustre/nobackup/WUR/ESG/zhou111/WOFOST-NPcycling/Data/CaseStudy_NPInput"
temp_dir="/lustre/nobackup/WUR/ESG/zhou111/WOFOST-NPcycling/Data/Temp"