#!/bin/bash

###################### Change Log ################
# 3/1/2020 - Kaiwen
# Non-rigid register to reference (701), then propagate back label map
# Input is niftyreg affine result with manual z-roi
##################################################

BASH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_ROOT=${BASH_DIR}/..
bash_config_file=${SRC_ROOT}/bash_config/20200225_deeds_reverse_label_multi_atlas.sh

echo "Create source images on atlas space"
echo "Loading bash config from ${bash_config_file}"
source ${bash_config_file}
source ${SRC_ROOT}/tools/reg_preprocess_functions.sh

DATA_ROOT=/home/local/VANDERBILT/xuk9/cur_data_dir/registration/label_propagation/20200304_10_atlas_affine
idendity_mat_txt=${DATA_ROOT}/multi_atlas_rename/idendity_matrix.txt

out_target_scans_root=${DATA_ROOT}/20200306_10_atlas_1_data/vertebrae_13

preprocess_one_target_scan () {
  local target_scan_name=$1

  local in_img_folder=${DATA_ROOT}/20200305_10_atlas_20_data/output/${target_scan_name}/masked
  local ref_img_folder=${DATA_ROOT}/multi_atlas_rename/atlas
  local label_img_folder=${DATA_ROOT}/multi_atlas_rename/label_refine

  local target_non_rigid_root=${out_target_scans_root}/${target_scan_name}
  local reg_out_scan_folder=${target_non_rigid_root}/scans
  local out_label_folder=${target_non_rigid_root}/label

  mkdir -p ${target_non_rigid_root}
  mkdir -p ${reg_out_scan_folder}
  mkdir -p ${out_label_folder}

  run_single_image () {
    local atlas_name=$1
    local out_label_img=$2

    local scan_folder=${reg_out_scan_folder}/${atlas_name}
    mkdir -p ${scan_folder}
    local flo_img=${in_img_folder}/${atlas_name}.nii.gz
    local ref_img=${ref_img_folder}/${atlas_name}.nii.gz
    local label_img=${label_img_folder}/${atlas_name}.nii.gz
    local deformable_path=${scan_folder}/deformable
    local inv_label_img=${scan_folder}/inv_label_img.nii.gz

    set -o xtrace
    ${DEEDS_ROOT}/deedsBCVwinv \
      -ln 4 -G 7x6x5x4 -L 7x6x5x4 -Q 4x3x2x1 \
      -F ${ref_img} \
      -M ${flo_img} \
      -O ${deformable_path} \
      -A ${idendity_mat_txt}
    set +o xtrace

    echo "Registration complete, start the label inversion."
    set -o xtrace
    ${DEEDS_ROOT}/applyBCVinv \
      -M ${label_img} \
      -O ${deformable_path} \
      -D ${inv_label_img} \
      -A ${idendity_mat_txt}
    set +o xtrace

    set -o xtrace
    cp ${inv_label_img} ${out_label_img}
    set +o xtrace
  }

  for file_path in "${in_img_folder}"/*.nii.gz
  do
    start=`date +%s`

    file_base_name="$(basename -- $file_path)"
    atlas_image_name_no_ext="${file_base_name%%.*}"

    out_label_img=${out_label_folder}/${atlas_image_name_no_ext}.nii.gz
    if [ ! -f "${out_label_img}" ]; then
      run_single_image ${atlas_image_name_no_ext} ${out_label_img}
    fi

    end=`date +%s`
    runtime=$((end-start))
    echo "${file_path}"
    echo "Complete! Total ${runtime} (s)"
  done
}

for file_path in "${out_target_scans_root}"/*
do
  start=`date +%s`

  target_image_name_no_ext="$(basename -- $file_path)"

  preprocess_one_target_scan ${target_image_name_no_ext}

  end=`date +%s`
  runtime=$((end-start))
  echo "${file_path}"
  echo "Complete! Total ${runtime} (s)"
done
