#!/bin/bash

###################### Change Log ################
# 3/4/2020 - Kaiwen
# Write out affine pipeline configuration files for subject to subject reg.
##################################################

BASH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_ROOT=${BASH_DIR}/..
bash_config_file=${SRC_ROOT}/bash_config/20200225_deeds_reverse_label_multi_atlas.sh

echo "Generate sagittal slices"
echo "Loading bash config from ${bash_config_file}"
source ${bash_config_file}
source ${SRC_ROOT}/tools/reg_preprocess_functions.sh

DATA_ROOT=/home/local/VANDERBILT/xuk9/cur_data_dir/registration/label_propagation/20200304_10_atlas_affine
affine_out_root=${DATA_ROOT}/20200305_10_atlas_20_data/scans

out_target_scans_root=${DATA_ROOT}/20200306_10_atlas_1_data/vertebrae_12

process_one_target_scan () {
  local target_name=$1

  local target_root=${DATA_ROOT}/20200306_10_atlas_1_data/vertebrae_12/${target_name}
  local non_rigid_inv_label_folder=${target_root}/label
  local out_inv_affine_mat_folder=${target_root}/inv_omat
  local out_affine_inv_label_folder=${target_root}/affine_inverted_label
  mkdir -p ${out_inv_affine_mat_folder}
  mkdir -p ${out_affine_inv_label_folder}

  local ref_img=${DATA_ROOT}/20200305_10_atlas_20_data/target_space/${target_name}.nii.gz

  revert_single_label () {
    local atlas_name=$1

    local affine_mat=${affine_out_root}/${atlas_name}/omat/${target_name}.txt
    local inv_affine_mat=${out_inv_affine_mat_folder}/${atlas_name}.txt
    local flo_img=${non_rigid_inv_label_folder}/${atlas_name}.nii.gz
    local res_img=${out_affine_inv_label_folder}/${atlas_name}.nii.gz

    # 1. Revert the affine
    set -o xtrace
    ${NIFYREG_ROOT}/reg_transform \
      -invAff ${affine_mat} ${inv_affine_mat}
    set +o xtrace

    # 2. Apply the inv affine then resample to the resampled origin reset space.
    set -o xtrace
    ${NIFYREG_ROOT}/reg_resample \
      -ref ${ref_img} \
      -flo ${flo_img} \
      -trans ${inv_affine_mat} \
      -res ${res_img} \
      -inter 0 \
      -pad 0
    set +o xtrace
  }

  for file_path in "${non_rigid_inv_label_folder}"/*.nii.gz
  do
    file_base_name="$(basename -- $file_path)"
    atlas_image_name_no_ext="${file_base_name%%.*}"

    revert_single_label ${atlas_image_name_no_ext} &
  done
  wait
}

for file_path in "${out_target_scans_root}"/*
do
  start=`date +%s`

  target_image_name_no_ext="$(basename -- $file_path)"

  process_one_target_scan ${target_image_name_no_ext}

  end=`date +%s`
  runtime=$((end-start))
  echo "${file_path}"
  echo "Complete! Total ${runtime} (s)"
done
