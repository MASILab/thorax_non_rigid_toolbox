#!/bin/bash

###################### Change Log ################
# 2/29/2020 - Kaiwen
# Apply the reference roi mask to interpolated ori images.
##################################################

BASH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_ROOT=${BASH_DIR}/..
bash_config_file=${SRC_ROOT}/bash_config/20200225_deeds_reverse_label_multi_atlas.sh

echo "Create source images on atlas space"
echo "Loading bash config from ${bash_config_file}"
source ${bash_config_file}
source ${SRC_ROOT}/tools/reg_preprocess_functions.sh

DATA_ROOT=/home/local/VANDERBILT/xuk9/cur_data_dir/registration/label_propagation/20200228_niftyreg_affine
roi_mask_img=/home/local/VANDERBILT/xuk9/cur_data_dir/registration/label_propagation/20200228_niftyreg_affine/atlas/nan_mask/padded_iso.nii.gz

target_data_folder=${DATA_ROOT}/affine_niftyreg_10/interp/ori
output_folder=${DATA_ROOT}/affine_niftyreg_10/preprocessed_for_non_rigid

mkdir -p ${output_folder}

run_single_image () {
  local scan_name=$1

  local ori_img=${target_data_folder}/${scan_name}.nii.gz
  local out_img=${output_folder}/${scan_name}.nii.gz

  # Check if file exists.
  if [ ! -f "${out_img}" ]; then
    apply_mask ${ori_img} ${roi_mask_img} ${out_img}
  fi
}

for file_path in "${target_data_folder}"/*.nii.gz
do
  start=`date +%s`

  file_base_name="$(basename -- $file_path)"
  target_image_name_no_ext="${file_base_name%%.*}"

  run_single_image ${target_image_name_no_ext}

  end=`date +%s`
  runtime=$((end-start))
  echo "${file_path}"
  echo "Complete! Total ${runtime} (s)"
done
