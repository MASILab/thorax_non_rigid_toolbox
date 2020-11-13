#!/bin/bash

###################### Change Log ################
# 3/2/2020 - Kaiwen
# Non-rigid register to reference (701), then propagate back label map
# Test with niftyreg.reg_f3d
# Input folder is the affine result with manual z roi mask.
##################################################

BASH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_ROOT=${BASH_DIR}/..
bash_config_file=${SRC_ROOT}/bash_config/20200225_deeds_reverse_label_multi_atlas.sh

echo "Create source images on atlas space"
echo "Loading bash config from ${bash_config_file}"
source ${bash_config_file}
source ${SRC_ROOT}/tools/reg_preprocess_functions.sh

DATA_ROOT=/home/local/VANDERBILT/xuk9/cur_data_dir/registration/label_propagation/20200228_niftyreg_affine
source_folder=${DATA_ROOT}/affine_niftyreg_manual_z_roi/affine_niftyreg/interp/masked_std_roi
reference_img=${DATA_ROOT}/atlas/atlas.nii.gz
#idendity_mat_txt=${DATA_ROOT}/atlas/idendity_matrix.txt
label_img=${DATA_ROOT}/atlas/label_header_reset.nii.gz

non_rigid_out_root=${DATA_ROOT}/20200302_02_non_rigid_niftyreg/non_rigid
reg_out_scan_folder=${non_rigid_out_root}/scans
label_folder=${non_rigid_out_root}/label

mkdir -p ${reg_out_scan_folder}
mkdir -p ${label_folder}

run_single_image () {
  local scan_name=$1
  local out_label_img=$2

  # 1. Registration
  local scan_folder=${reg_out_scan_folder}/${scan_name}
  mkdir -p ${scan_folder}
  local flo_img=${source_folder}/${scan_name}.nii.gz
  local ref_img=${reference_img}
  local cpp_img=${scan_folder}/cpp.nii.gz
  local res_img=${scan_folder}/res.nii.gz

  if [ ! -f "${cpp_img}" ]; then
    set -o xtrace
    ${NIFYREG_ROOT}/reg_f3d \
      -maxit 1000 \
      -ref ${ref_img} \
      -flo ${flo_img} \
      -cpp ${cpp_img} \
      -res ${res_img}
    set +o xtrace
  fi

  # 2. Revert transformation
  local inv_in_ref=${flo_img}
  local inv_in_trans=${cpp_img}
  local inv_in_flo=${label_img}
  local inv_out_trans=${scan_folder}/inv_cpp.nii.gz
  if [ ! -f "${inv_out_trans}" ]; then
    set -o xtrace
    ${NIFYREG_ROOT}/reg_transform \
      -ref ${inv_in_ref} \
      -invNrr ${inv_in_trans} ${inv_in_flo} ${inv_out_trans}
    set +o xtrace
  fi

  # 3. Propagate label map.
  if [ ! -f "${out_label_img}" ]; then
    set -o xtrace
    ${NIFYREG_ROOT}/reg_resample \
     -ref ${inv_in_ref} \
     -flo ${label_img} \
     -trans ${inv_out_trans} \
     -res ${out_label_img} \
     -inter 0 \
     -pad 0
    set +o xtrace
  fi
}

for file_path in "${source_folder}"/*.nii.gz
do
  start=`date +%s`

  file_base_name="$(basename -- $file_path)"
  target_image_name_no_ext="${file_base_name%%.*}"

  out_label_img=${label_folder}/${target_image_name_no_ext}.nii.gz
  if [ ! -f "${out_label_img}" ]; then
    run_single_image ${target_image_name_no_ext} ${out_label_img}
  fi

  end=`date +%s`
  runtime=$((end-start))
  echo "${file_path}"
  echo "Complete! Total ${runtime} (s)"
done
