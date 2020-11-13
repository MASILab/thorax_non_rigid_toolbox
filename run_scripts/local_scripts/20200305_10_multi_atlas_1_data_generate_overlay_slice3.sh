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

DATA_ROOT=/home/local/VANDERBILT/xuk9/cur_data_dir/registration/label_propagation/20200304_10_atlas_affine

affine_img_folder=${DATA_ROOT}/affine/output/00000301time20160622/interp
deformed_img_folder=${DATA_ROOT}/non_rigid/00000301time20160622/deformed
label_img_folder=${DATA_ROOT}/multi_atlas/label_refine
inv_label_folder=${DATA_ROOT}/non_rigid/00000301time20160622/label
ref_img_folder=${DATA_ROOT}/multi_atlas/atlas
out_png_folder=${DATA_ROOT}/non_rigid/00000301time20160622/overlap_slices

mkdir -p ${out_png_folder}

generate_overlap_slice () {
  local scan_name=$1

  local affine_img=${affine_img_folder}/${scan_name}.nii.gz
  local deformed_img=${deformed_img_folder}/${scan_name}.nii.gz
  local inv_label_img=${inv_label_folder}/${scan_name}.nii.gz
  local label_img=${label_img_folder}/${scan_name}.nii.gz
  local ref_img=${ref_img_folder}/${scan_name}.nii.gz
  local out_png=${out_png_folder}/${scan_name}.png

  echo "Generate overlap sagittal slice ${scan_name}"

  set -o xtrace
  ${PYTHON_ENV} ${AFFINE_SRC_ROOT}/tools/save_overlay_img_sagittal_single_image3.py \
    --affine-img ${affine_img} \
    --deformed-img ${deformed_img} \
    --inv-label-img ${inv_label_img} \
    --label-img ${label_img} \
    --ref-img ${ref_img} \
    --out-png ${out_png}
  set +o xtrace
}

for file_path in "${affine_img_folder}"/*.nii.gz
do
  file_base_name="$(basename -- $file_path)"
  target_image_name_no_ext="${file_base_name%%.*}"

  generate_overlap_slice ${target_image_name_no_ext} &

done

wait
