#!/bin/bash

###################### Change Log ################
# 2/29/2020 - Kaiwen
# Check the overlay of niftyreg affine pipeline.
##################################################

BASH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_ROOT=${BASH_DIR}/..
bash_config_file=${SRC_ROOT}/bash_config/20200225_deeds_reverse_label_multi_atlas.sh

echo "Create source images on atlas space"
echo "Loading bash config from ${bash_config_file}"
source ${bash_config_file}

DATA_ROOT=/home/local/VANDERBILT/xuk9/cur_data_dir/registration/label_propagation/20200228_niftyreg_affine

#IMAGE_ATLAS=${DATA_ROOT}/atlas_full_resolution/atlas.nii.gz
#IMAGE_LABEL=${DATA_ROOT}/atlas/rib_and_spine.nii.gz
IMAGE_LABEL=${DATA_ROOT}/atlas/label_header_reset.nii.gz

#target_data_folder=/nfs/masi/xuk9/SPORE/registration/label_propagation/20200228_niftyreg_affine/affine_niftyreg/temp/interp/ori/padding
target_data_folder=/nfs/masi/xuk9/SPORE/registration/label_propagation/20200228_niftyreg_affine/affine_niftyreg/preprocess
omat_folder=/home/local/VANDERBILT/xuk9/cur_data_dir/registration/label_propagation/20200228_niftyreg_affine/affine_niftyreg/omat

affine_label_root=${DATA_ROOT}/affine_label
inverted_affine_folder=${affine_label_root}/inv_mat
inverted_label_folder=${affine_label_root}/inv_label

mkdir -p ${inverted_affine_folder}
mkdir -p ${inverted_label_folder}

run_invert_label () {
  local scan_name=$1

  # 1. Create the inverted matrix.
  local omat_path=${omat_folder}/${scan_name}.txt
  local inv_mat_path=${inverted_affine_folder}/${scan_name}.txt
  set -o xtrace
  ${NIFYREG_ROOT}/reg_transform -invAff ${omat_path} ${inv_mat_path}
  set +o xtrace

  # 2. Invert and resample the image.
  local ref_img=${target_data_folder}/${scan_name}.nii.gz
  local flo_img=${IMAGE_LABEL}
  local res_img=${inverted_label_folder}/${scan_name}.nii.gz
  set -o xtrace
  ${NIFYREG_ROOT}/reg_resample \
    -inter 0 -pad 0 \
    -ref ${ref_img} \
    -flo ${flo_img} \
    -res ${res_img} \
    -trans ${inv_mat_path}
  set +o xtrace
}

# only run second half,
#for file_path in "${target_data_folder}"/*.nii.gz
for file_path in "${target_data_folder}"/{00000010time20170118.nii.gz,00000022time20170918.nii.gz}
do
  start=`date +%s`

  file_base_name="$(basename -- $file_path)"
  target_image_name_no_ext="${file_base_name%%.*}"

  run_invert_label ${target_image_name_no_ext}

  end=`date +%s`
  runtime=$((end-start))
  echo "${file_path}"
  echo "Complete! Total ${runtime} (s)"
done
