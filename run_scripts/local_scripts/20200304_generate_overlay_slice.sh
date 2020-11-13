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

in_img_folder=${DATA_ROOT}/affine/output/00000301time20160622/interp
ref_img_folder=${DATA_ROOT}/multi_atlas/atlas
out_png_folder=${DATA_ROOT}/affine/output/00000301time20160622/overlap_slices

mkdir -p ${out_png_folder}

generate_overlap_slice () {
  local scan_name=$1

  local in_img=${in_img_folder}/${scan_name}.nii.gz
  local ref_img=${ref_img_folder}/${scan_name}.nii.gz
  local out_png=${out_png_folder}/${scan_name}.png

  echo "Generate overlap sagittal slice ${scan_name}"

  set -o xtrace
  ${PYTHON_ENV} ${AFFINE_SRC_ROOT}/tools/save_overlay_img_sagittal_single_image.py \
    --in-img ${in_img} \
    --ref-img ${ref_img} \
    --out-png ${out_png}
  set +o xtrace
}

for file_path in "${in_img_folder}"/*.nii.gz
do
  file_base_name="$(basename -- $file_path)"
  target_image_name_no_ext="${file_base_name%%.*}"

  generate_overlap_slice ${target_image_name_no_ext} &

done

wait
