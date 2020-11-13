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

atlas_folder=${DATA_ROOT}/multi_atlas/atlas_thr
#label_folder=${DATA_ROOT}/multi_atlas/label_refine
affine_scan_folder=${DATA_ROOT}/affine/scans
in_img_folder=${DATA_ROOT}/data_1

mkdir -p ${affine_scan_folder}

run_one_atlas () {
  local scan_name=$1

  local out_scan_root=${affine_scan_folder}/${scan_name}
  local config_sh=${out_scan_root}/bash_config.sh

  set -o xtrace
  ${AFFINE_SRC_ROOT}/run_reg.sh ${config_sh}
  set +o xtrace
}

for file_path in "${atlas_folder}"/*.nii.gz
do
  file_base_name="$(basename -- $file_path)"
  atlas_image_name_no_ext="${file_base_name%%.*}"

  run_one_atlas ${atlas_image_name_no_ext}
done
