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
roi_mask=${DATA_ROOT}/multi_atlas/roi_mask.nii.gz
flo_img_name=00000301time20160622.nii.gz
out_masked_folder=${DATA_ROOT}/masked
out_clipped_folder=${DATA_ROOT}/clipped

mkdir -p ${out_masked_folder}
mkdir -p ${out_clipped_folder}

apply_mask_to_img () {
  local scan_name=$1

  echo "Apply z mask ${scan_name}"

  local in_img=${affine_root}/${scan_name}/interp/ori/${flo_img_name}
  local mask_img=${roi_mask}
  local out_masked_img=${out_masked_folder}/${scan_name}.nii.gz

  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/apply_mask.py \
    --ori ${in_img} \
    --mask ${mask_img} \
    --out ${out_masked_img}
  set +o xtrace
}

apply_clip_img () {
  local scan_name=$1

  echo "Apply clipping image ${scan_name}"

  local in_img=${out_masked_folder}/${scan_name}.nii.gz
  local out_img=${out_clipped_folder}/${scan_name}.nii.gz

  intensity_clip ${in_img} ${out_img}
}

process_scan () {
  local scan_name=$1

  apply_mask_to_img ${scan_name}
  apply_clip_img ${scan_name}
}

for file_path in "${affine_root}"/*
do
  file_base_name="$(basename -- $file_path)"

  process_scan ${file_base_name} &
done

wait
