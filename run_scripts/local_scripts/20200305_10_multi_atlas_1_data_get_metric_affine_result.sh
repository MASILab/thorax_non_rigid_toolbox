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

affine_root=${DATA_ROOT}/affine/scans
flo_img_name=00000301time20160622.nii.gz
flo_img_name_no_ext=00000301time20160622

affine_masked_folder=${DATA_ROOT}/affine/output/${flo_img_name_no_ext}/masked
affine_clipped_folder=${DATA_ROOT}/affine/output/${flo_img_name_no_ext}/clipped

atlas_folder=${DATA_ROOT}/multi_atlas/atlas
atlas_thr_folder=${DATA_ROOT}/multi_atlas/atlas_thr

compute_metric_msq () {
  local scan_name=$1
  local affine_wrapped_folder=$2
  local atlas_folder=$3

  local scan_img=${affine_wrapped_folder}/${scan_name}.nii.gz
  local atlas_img=${atlas_folder}/${scan_name}.nii.gz

  ${C3D_ROOT}/c3d ${scan_img} ${atlas_img} -msq
}

compute_metric_nmi () {
  local scan_name=$1
  local affine_wrapped_folder=$2
  local atlas_folder=$3

  local scan_img=${affine_wrapped_folder}/${scan_name}.nii.gz
  local atlas_img=${atlas_folder}/${scan_name}.nii.gz

  ${C3D_ROOT}/c3d ${scan_img} ${atlas_img} -nmi
}



for file_path in "${affine_masked_folder}"/*
do
  file_base_name="$(basename -- $file_path)"
  atlas_image_name_no_ext="${file_base_name%%.*}"

  compute_metric_msq \
    ${atlas_image_name_no_ext} \
    ${affine_masked_folder} \
    ${atlas_folder}
done


