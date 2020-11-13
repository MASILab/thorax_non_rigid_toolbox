#!/bin/bash

###################### Change Log ################
# 3/2/2020 - Kaiwen
# Non-rigid register to reference (701), then propagate back label map
# Add intensity clipping to the non-rigid pipeline.
##################################################

BASH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_ROOT=${BASH_DIR}/..
bash_config_file=${SRC_ROOT}/bash_config/20200225_deeds_reverse_label_multi_atlas.sh

echo "Create source images on atlas space"
echo "Loading bash config from ${bash_config_file}"
source ${bash_config_file}
source ${SRC_ROOT}/tools/reg_preprocess_functions.sh

DATA_ROOT=/home/local/VANDERBILT/xuk9/cur_data_dir/registration/label_propagation/20200228_niftyreg_affine
source_folder=${DATA_ROOT}/20200302_01_intensity_th_deeds/intensity_th
reference_img=${DATA_ROOT}/atlas/atlas_thres.nii.gz
idendity_mat_txt=${DATA_ROOT}/atlas/idendity_matrix.txt
label_img=${DATA_ROOT}/atlas/label_header_reset.nii.gz

non_rigid_out_root=${DATA_ROOT}/20200302_01_intensity_th_deeds/non_rigid
reg_out_scan_folder=${non_rigid_out_root}/scans
label_folder=${non_rigid_out_root}/label

mkdir -p ${reg_out_scan_folder}
mkdir -p ${label_folder}

run_single_image () {
  local scan_name=$1
  local out_label_img=$2

  local scan_folder=${reg_out_scan_folder}/${scan_name}
  mkdir -p ${scan_folder}
  local flo_img=${source_folder}/${scan_name}.nii.gz
  local ref_img=${reference_img}
  local deformable_path=${scan_folder}/${scan_name}
  local inv_label_img=${scan_folder}/inv_label_img.nii.gz

  set -o xtrace
  ${DEEDS_ROOT}/deedsBCVwinv \
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
