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

non_rigid_root=${DATA_ROOT}/non_rigid/${flo_img_name_no_ext}/scans

atlas_folder=${DATA_ROOT}/multi_atlas/atlas
atlas_thr_folder=${DATA_ROOT}/multi_atlas/atlas_thr

deformed_folder=${DATA_ROOT}/non_rigid/${flo_img_name_no_ext}/deformed

mkdir -p ${deformed_folder}

reset_header_and_copy () {
  local scan_name=$1
#  local atlas_folder=$3

  local deformed_img=${non_rigid_root}/${scan_name}/deformable_deformed.nii.gz
  local atlas_img=${atlas_folder}/${scan_name}.nii.gz
  local deformed_out_img=${deformed_folder}/${scan_name}.nii.gz

  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/reset_header_with_ref.py \
    --in-img ${deformed_img} \
    --out-img ${deformed_out_img} \
    --ref-img ${atlas_img}
  set +o xtrace
}

for file_path in "${atlas_folder}"/*
do
  file_base_name="$(basename -- $file_path)"
  atlas_image_name_no_ext="${file_base_name%%.*}"

  reset_header_and_copy ${atlas_image_name_no_ext} &
done

wait


