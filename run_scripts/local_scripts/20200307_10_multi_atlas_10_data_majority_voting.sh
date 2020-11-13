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
out_target_scans_root=${DATA_ROOT}/20200306_10_atlas_1_data/vertebrae_12

majority_vote_one_target () {
  local target_name=$1

  local target_root=${out_target_scans_root}/${target_name}
  local affine_inv_label_folder=${target_root}/affine_inverted_label
  local vote_result_img=${target_root}/label_majority.nii.gz

  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/majority_vote.py \
    --in-folder ${affine_inv_label_folder} \
    --out ${vote_result_img} \
    --num-class 13
  set +o xtrace
}

for file_path in "${out_target_scans_root}"/*
do
  target_image_name_no_ext="$(basename -- $file_path)"

  majority_vote_one_target ${target_image_name_no_ext} &
done

wait