#!/bin/bash

###################### Change Log ################
# 3/2/2020 - Kaiwen
# Apply [0, 1000] threshold to a folder of scans
# Input is the nifryreg result with manual z landmark.
##################################################

BASH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_ROOT=${BASH_DIR}/..
bash_config_file=${SRC_ROOT}/bash_config/20200225_deeds_reverse_label_multi_atlas.sh

echo "Generate sagittal slices"
echo "Loading bash config from ${bash_config_file}"
source ${bash_config_file}
source ${SRC_ROOT}/tools/reg_preprocess_functions.sh

DATA_ROOT=/home/local/VANDERBILT/xuk9/cur_data_dir/registration/label_propagation/20200304_9_atlas_affine

scan_folder=${DATA_ROOT}/multi_atlas/atlas
out_folder=${DATA_ROOT}/multi_atlas/atlas_thr

mkdir -p ${out_folder}

run_single_scan () {
  local scan_name=$1

  local in_img=${scan_folder}/${scan_name}.nii.gz
  local out_img=${out_folder}/${scan_name}.nii.gz

  intensity_clip ${in_img} ${out_img}
}

for file_path in "${scan_folder}"/*.nii.gz
do
  file_base_name="$(basename -- $file_path)"
  target_image_name_no_ext="${file_base_name%%.*}"

  run_single_scan ${target_image_name_no_ext} &
done

wait