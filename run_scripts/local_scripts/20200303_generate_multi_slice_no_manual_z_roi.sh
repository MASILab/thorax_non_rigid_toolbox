#!/bin/bash

###################### Change Log ################
# 3/2/2020 - Kaiwen
# Generate multiple sagittal slice
##################################################

BASH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_ROOT=${BASH_DIR}/..
bash_config_file=${SRC_ROOT}/bash_config/20200225_deeds_reverse_label_multi_atlas.sh

echo "Generate sagittal slices"
echo "Loading bash config from ${bash_config_file}"
source ${bash_config_file}

DATA_ROOT=/home/local/VANDERBILT/xuk9/cur_data_dir/registration/label_propagation/20200228_niftyreg_affine

scan_folder=${DATA_ROOT}/affine_niftyreg_10/preprocessed_for_non_rigid
label_folder=${DATA_ROOT}/20200303_02_4_ln_deeds_no_manual_label/non_rigid/label

out_slice_folder=${DATA_ROOT}/20200303_02_4_ln_deeds_no_manual_label/multi_slice

mkdir -p ${out_slice_folder}

${PYTHON_ENV} ${AFFINE_SRC_ROOT}/tools/save_label_overlay_sagittal.py \
  --nii-folder ${scan_folder} \
  --label-folder ${label_folder} \
  --out-folder ${out_slice_folder} \
  --num-processes 10
