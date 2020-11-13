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
data_10_2_folder=${DATA_ROOT}/data_10_2

atlas_folder=${DATA_ROOT}/multi_atlas_rename/atlas
affine_root=${DATA_ROOT}/20200305_10_atlas_20_data/scans_2
output_root=${DATA_ROOT}/20200305_10_atlas_20_data/output
atlas_roi_mask=${DATA_ROOT}/multi_atlas_rename/roi_mask.nii.gz

process_for_one_target_img () {
  local target_name=$1

  local target_output_root=${output_root}/${target_name}
  local interp_folder=${target_output_root}/interp
  local masked_folder=${target_output_root}/masked
  local clipped_folder=${target_output_root}/clipped

  mkdir -p ${interp_folder}
  mkdir -p ${masked_folder}
  mkdir -p ${clipped_folder}

  for folder_path in "${atlas_folder}"/*
  do
    local atlas_name_base="$(basename -- $folder_path)"
    local atlas_name="${atlas_name_base%%.*}"
    local affine_interp_img=${affine_root}/${atlas_name}/interp/ori/${target_name}.nii.gz
    local interp_img=${interp_folder}/${atlas_name}.nii.gz
    local masked_img=${masked_folder}/${atlas_name}.nii.gz
    local clipped_img=${clipped_folder}/${atlas_name}.nii.gz

    set -o xtrace
    ln -s ${affine_interp_img} ${interp_img}

    ${PYTHON_ENV} ${SRC_ROOT}/tools/apply_mask.py \
      --ori ${interp_img} \
      --mask ${atlas_roi_mask} \
      --out ${masked_img}

    intensity_clip ${masked_img} ${clipped_img}
    set +o xtrace
  done
  reg_save_clip_slice ${masked_folder}
}

for file_path in "${data_10_2_folder}"/*.nii.gz
do
  file_base_name="$(basename -- $file_path)"
  target_name_no_ext="${file_base_name%%.*}"

  process_for_one_target_img ${target_name_no_ext} &
#  process_for_one_target_img ${target_name_no_ext}
done

wait
