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

flo_img_name=00000301time20160622.nii.gz
flo_img_name_no_ext=00000301time20160622

affine_inv_label_folder=${DATA_ROOT}/non_rigid/${flo_img_name_no_ext}/affine_inverted_label
out_vote_label_img=${DATA_ROOT}/non_rigid/${flo_img_name_no_ext}/label_maj_vote.nii.gz

set -o xtrace
${PYTHON_ENV} ${SRC_ROOT}/tools/majority_vote.py \
  --in-folder ${affine_inv_label_folder} \
  --out ${out_vote_label_img} \
  --num-class 13
set +o xtrace